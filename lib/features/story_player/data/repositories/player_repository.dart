import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kids_stories/features/story_player/data/models/story_choice.dart';
import 'package:kids_stories/features/story_player/data/models/story_player_state.dart';
import 'package:kids_stories/features/story_player/data/models/story_step.dart';
import 'package:kids_stories/features/story_player/data/models/story_tree.dart';

/// Data layer for story tree fetching and progress persistence.
///
/// Resolution order for [fetchStoryTree]:
///   1. Hive box `offline_stories` — looks for a JSON file path stored under
///      the key `<storyId>_tree_path`. If found the file is read from disk.
///   2. Firestore — document `stories/{storyId}/tree/data`.
///   3. Mock data — used as a last-resort fallback (development / test).
class PlayerRepository {
  PlayerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _offlineBoxName = 'offline_stories';

  // ---------------------------------------------------------------------------
  // Fetch story tree
  // ---------------------------------------------------------------------------

  /// Returns the [StoryTree] for [storyId].
  ///
  /// Checks offline Hive cache first, then Firestore, then falls back to mock
  /// data so the player is always functional in development / demo builds.
  Future<StoryTree> fetchStoryTree(String storyId) async {
    // ── 1. Check offline Hive cache ──────────────────────────────────────────
    try {
      final tree = await _loadFromHive(storyId);
      if (tree != null) {
        debugPrint('[PlayerRepository] Loaded "$storyId" from offline cache.');
        return tree;
      }
    } catch (e) {
      debugPrint('[PlayerRepository] Hive load failed: $e');
    }

    // ── 2. Firestore ─────────────────────────────────────────────────────────
    try {
      final tree = await _loadFromFirestore(storyId);
      debugPrint('[PlayerRepository] Loaded "$storyId" from Firestore.');
      return tree;
    } on FirebaseException catch (e) {
      debugPrint('[PlayerRepository] Firestore error (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('[PlayerRepository] Unexpected Firestore error: $e');
    }

    // ── 3. Mock data fallback ─────────────────────────────────────────────────
    debugPrint('[PlayerRepository] Using mock story tree for "$storyId".');
    return getMockStoryTree(storyId: storyId);
  }

  /// Attempts to read a cached tree JSON from the path stored in Hive.
  Future<StoryTree?> _loadFromHive(String storyId) async {
    if (!Hive.isBoxOpen(_offlineBoxName)) {
      await Hive.openBox<String>(_offlineBoxName);
    }
    final box = Hive.box<String>(_offlineBoxName);
    final treePath = box.get('${storyId}_tree_path');
    if (treePath == null) return null;

    final file = File(treePath);
    if (!await file.exists()) return null;

    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return StoryTree.fromJson(json);
  }

  /// Fetches the tree document from Firestore.
  Future<StoryTree> _loadFromFirestore(String storyId) async {
    final doc = await _firestore
        .collection('stories')
        .doc(storyId)
        .collection('tree')
        .doc('data')
        .get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Story tree document not found for "$storyId".');
    }

    return StoryTree.fromJson(doc.data()!);
  }

  // ---------------------------------------------------------------------------
  // Save progress
  // ---------------------------------------------------------------------------

  /// Persists the current player state to Firestore under the parent's kid
  /// document so parents can view reading reports.
  ///
  /// Path: `parents/{parentId}/kids/{kidId}/progress/{storyId}`
  Future<void> saveProgress(
    String storyId,
    String kidId,
    StoryPlayerState playerState,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[PlayerRepository] saveProgress: no authenticated user.');
      return;
    }

    final isComplete = playerState.currentStep?.isEnding ?? false;
    final endingTitle =
        isComplete ? playerState.currentStep?.endingTitle : null;

    final data = {
      'currentStepId': playerState.currentStepId,
      'choicesMade': playerState.choicesMade,
      'stepsVisited': playerState.stepHistory,
      'percentComplete': playerState.progressPercent.clamp(0.0, 100.0),
      'isComplete': isComplete,
      if (endingTitle != null) 'endingTitle': endingTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('parents')
          .doc(user.uid)
          .collection('kids')
          .doc(kidId)
          .collection('progress')
          .doc(storyId)
          .set(data, SetOptions(merge: true));
      debugPrint('[PlayerRepository] Progress saved for story "$storyId".');
    } on FirebaseException catch (e) {
      debugPrint('[PlayerRepository] saveProgress Firestore error: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Get progress
  // ---------------------------------------------------------------------------

  /// Returns the previously saved progress map, or `null` if none exists.
  Future<Map<String, dynamic>?> getProgress(
    String storyId,
    String kidId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('parents')
          .doc(user.uid)
          .collection('kids')
          .doc(kidId)
          .collection('progress')
          .doc(storyId)
          .get();

      return doc.exists ? doc.data() : null;
    } on FirebaseException catch (e) {
      debugPrint('[PlayerRepository] getProgress error: ${e.message}');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Save tree to offline cache
  // ---------------------------------------------------------------------------

  /// Writes [tree] to a local JSON file and stores the path in the Hive box.
  /// Called by the offline downloader — not used in the main fetch flow.
  Future<void> cacheTreeLocally(StoryTree tree) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/offline_${tree.storyId}_tree.json');
      await file.writeAsString(jsonEncode(tree.toJson()));

      if (!Hive.isBoxOpen(_offlineBoxName)) {
        await Hive.openBox<String>(_offlineBoxName);
      }
      final box = Hive.box<String>(_offlineBoxName);
      await box.put('${tree.storyId}_tree_path', file.path);
      debugPrint('[PlayerRepository] Tree cached at ${file.path}');
    } catch (e) {
      debugPrint('[PlayerRepository] Failed to cache tree: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Mock story tree
  // ---------------------------------------------------------------------------

  /// Returns a sample 6-step branching story for use in development,
  /// testing, and as a Firestore fallback.
  ///
  /// Structure:
  /// ```
  ///   root (step_0)
  ///   ├── Choice A → step_1a → step_2a → ending_a
  ///   └── Choice B → step_1b → step_2b → ending_b
  /// ```
  static StoryTree getMockStoryTree({String storyId = 'mock_story'}) {
    const rootId = 'step_0';
    const step1aId = 'step_1a';
    const step2aId = 'step_2a';
    const endingAId = 'ending_a';
    const step1bId = 'step_1b';
    const step2bId = 'step_2b';
    const endingBId = 'ending_b';

    const baseIllustration =
        'https://illustrations.taletrail.app/fox-river/';
    const baseAudio =
        'https://audio.taletrail.app/fox-river/';

    final steps = <StoryStep>[
      // ── Root ──────────────────────────────────────────────────────────────
      const StoryStep(
        id: rootId,
        title: 'The Fox and the River',
        text:
            'One misty morning, a young fox named Finn stood at the edge of the '
            'Great Silver River. The current was swift and the far bank was hidden '
            'in fog. Somewhere across the water, a magical golden acorn waited — '
            'said to grant the wish of any heart that was true.\n\n'
            '"I must cross," Finn whispered. "But how?"',
        illustrationUrl: '${baseIllustration}root.svg',
        audioUrl: '${baseAudio}root.mp3',
        choices: [
          StoryChoice(
            id: 'choice_a',
            label: 'Swim across the river',
            nextStepId: step1aId,
            iconUrl: '${baseIllustration}icon_swim.svg',
          ),
          StoryChoice(
            id: 'choice_b',
            label: 'Search for a bridge',
            nextStepId: step1bId,
            iconUrl: '${baseIllustration}icon_bridge.svg',
          ),
        ],
      ),

      // ── Branch A — Swimming ───────────────────────────────────────────────
      const StoryStep(
        id: step1aId,
        title: 'Into the Current',
        text:
            'Finn took a deep breath and leaped into the river. The cold water '
            'rushed around him, but he kicked his paws hard. Halfway across, the '
            'current pulled him off course — he was swept toward a rocky waterfall!\n\n'
            'A family of otters watched from a mossy log.',
        illustrationUrl: '${baseIllustration}step_1a.svg',
        audioUrl: '${baseAudio}step_1a.mp3',
        choices: [
          StoryChoice(
            id: 'choice_1a_a',
            label: 'Call to the otters for help',
            nextStepId: step2aId,
            iconUrl: '${baseIllustration}icon_otter.svg',
          ),
        ],
      ),
      const StoryStep(
        id: step2aId,
        title: 'The Otters\' Kindness',
        text:
            'The otters heard Finn\'s cry and splashed into the river, forming a '
            'living chain. They guided him safely to the far shore. Exhausted but '
            'grateful, Finn found the golden acorn nestled between two ancient '
            'stones, gleaming like a tiny sun.\n\n'
            '"You helped others," it seemed to say, "so others helped you."',
        illustrationUrl: '${baseIllustration}step_2a.svg',
        audioUrl: '${baseAudio}step_2a.mp3',
        choices: [
          StoryChoice(
            id: 'choice_2a_end',
            label: 'Make your wish',
            nextStepId: endingAId,
          ),
        ],
      ),
      const StoryStep(
        id: endingAId,
        title: 'The River Ending',
        text:
            'Finn held the golden acorn tightly and closed his eyes. He didn\'t '
            'wish for gold or power — he wished that the otters\' river would '
            'always flow clear and clean. The acorn glowed, and from that day on, '
            'the Great Silver River sparkled like starlight.\n\n'
            'Finn trotted home, heart full, tail high.',
        illustrationUrl: '${baseIllustration}ending_a.svg',
        audioUrl: '${baseAudio}ending_a.mp3',
        choices: [],
        isEnding: true,
        endingTitle: 'The River Ending',
      ),

      // ── Branch B — Bridge ─────────────────────────────────────────────────
      const StoryStep(
        id: step1bId,
        title: 'The Broken Bridge',
        text:
            'Finn trotted along the riverbank until he found an old wooden bridge. '
            'Half its planks were missing, and the ropes groaned in the wind. A '
            'small hedgehog sat beside it, weeping.\n\n'
            '"I need to cross too," she sniffled, "but I\'m too small to jump the gaps."',
        illustrationUrl: '${baseIllustration}step_1b.svg',
        audioUrl: '${baseAudio}step_1b.mp3',
        choices: [
          StoryChoice(
            id: 'choice_1b_help',
            label: 'Help repair the bridge together',
            nextStepId: step2bId,
            iconUrl: '${baseIllustration}icon_hammer.svg',
          ),
        ],
      ),
      const StoryStep(
        id: step2bId,
        title: 'Building Together',
        text:
            'Finn and the hedgehog, whose name was Hazel, gathered fallen branches '
            'and fixed the broken planks. It took all morning, but together they '
            'built a bridge strong enough for anyone. On the far bank, surrounded '
            'by wildflowers, shone the golden acorn.\n\n'
            '"You put others first," it whispered. "That is the greatest wish of all."',
        illustrationUrl: '${baseIllustration}step_2b.svg',
        audioUrl: '${baseAudio}step_2b.mp3',
        choices: [
          StoryChoice(
            id: 'choice_2b_end',
            label: 'Claim the golden acorn',
            nextStepId: endingBId,
          ),
        ],
      ),
      const StoryStep(
        id: endingBId,
        title: 'The Bridge Ending',
        text:
            'Finn made his wish: that Hazel\'s family would always have a safe '
            'path home. The bridge they had built began to glow, its wood turning '
            'to polished oak that could never rot or break.\n\n'
            'Villagers came from everywhere to cross the wonderful bridge, and '
            'Finn and Hazel became the best of friends forever.',
        illustrationUrl: '${baseIllustration}ending_b.svg',
        audioUrl: '${baseAudio}ending_b.mp3',
        choices: [],
        isEnding: true,
        endingTitle: 'The Bridge Ending',
      ),
    ];

    final stepsMap = {for (final s in steps) s.id: s};

    return StoryTree(
      storyId: storyId,
      title: 'The Fox and the River',
      rootStepId: rootId,
      steps: stepsMap,
      totalStepCount: steps.length,
      version: 1,
    );
  }
}
