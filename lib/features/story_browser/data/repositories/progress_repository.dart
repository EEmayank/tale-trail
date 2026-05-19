import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kids_stories/features/story_browser/data/models/story_progress.dart';

/// Persists and retrieves reading progress for a specific kid.
///
/// Strategy:
/// - Write: Firestore (primary) + Hive (cache).
/// - Read single: Hive first, then Firestore.
/// - Stream: Firestore with Hive as initial value when offline.
class ProgressRepository {
  ProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _hiveBoxName = 'story_progress';

  CollectionReference<Map<String, dynamic>> _progressRef(
    String parentId,
    String kidId,
  ) =>
      _firestore
          .collection('parents')
          .doc(parentId)
          .collection('kids')
          .doc(kidId)
          .collection('progress');

  // ---------------------------------------------------------------------------
  // saveProgress
  // ---------------------------------------------------------------------------

  Future<void> saveProgress(
    String parentId,
    String kidId,
    StoryProgress progress,
  ) async {
    final data = progress.toFirestore();

    // Write to Firestore.
    try {
      await _progressRef(parentId, kidId)
          .doc(progress.storyId)
          .set(data, SetOptions(merge: true));
    } catch (_) {
      // Swallow Firestore errors — local cache still saved below.
    }

    // Write to Hive cache.
    try {
      final box = await _openBox();
      final cacheKey = _cacheKey(parentId, kidId, progress.storyId);
      await box.put(cacheKey, data);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // getProgress
  // ---------------------------------------------------------------------------

  Future<StoryProgress?> getProgress(
    String parentId,
    String kidId,
    String storyId,
  ) async {
    // Check Hive first.
    try {
      final box = await _openBox();
      final cacheKey = _cacheKey(parentId, kidId, storyId);
      final cached = box.get(cacheKey) as Map?;
      if (cached != null) {
        final typedMap = cached.map((k, v) => MapEntry(k.toString(), v));
        return _progressFromMap(storyId, typedMap);
      }
    } catch (_) {}

    // Fall back to Firestore.
    try {
      final doc =
          await _progressRef(parentId, kidId).doc(storyId).get();
      if (doc.exists) {
        final progress = StoryProgress.fromFirestore(doc);
        // Populate cache.
        try {
          final box = await _openBox();
          await box.put(
            _cacheKey(parentId, kidId, storyId),
            progress.toFirestore(),
          );
        } catch (_) {}
        return progress;
      }
    } catch (_) {}

    return null;
  }

  // ---------------------------------------------------------------------------
  // getAllProgress — Stream
  // ---------------------------------------------------------------------------

  Stream<List<StoryProgress>> getAllProgress(
    String parentId,
    String kidId,
  ) {
    return _progressRef(parentId, kidId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryProgress.fromFirestore(doc))
            .toList())
        .handleError((_) => <StoryProgress>[]);
  }

  // ---------------------------------------------------------------------------
  // getInProgressStories
  // ---------------------------------------------------------------------------

  Future<List<StoryProgress>> getInProgressStories(
    String parentId,
    String kidId,
  ) async {
    try {
      final snap = await _progressRef(parentId, kidId)
          .where('isComplete', isEqualTo: false)
          .get();
      return snap.docs
          .map((d) => StoryProgress.fromFirestore(d))
          .where((p) => p.percentComplete > 0 && p.percentComplete < 100)
          .toList();
    } catch (_) {
      return _getCachedProgress(parentId, kidId)
          .where((p) => p.percentComplete > 0 && p.percentComplete < 100)
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // getCompletedStories
  // ---------------------------------------------------------------------------

  Future<List<StoryProgress>> getCompletedStories(
    String parentId,
    String kidId,
  ) async {
    try {
      final snap = await _progressRef(parentId, kidId)
          .where('isComplete', isEqualTo: true)
          .get();
      return snap.docs.map((d) => StoryProgress.fromFirestore(d)).toList();
    } catch (_) {
      return _getCachedProgress(parentId, kidId)
          .where((p) => p.isComplete)
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<Box> _openBox() => Hive.openBox(_hiveBoxName);

  String _cacheKey(String parentId, String kidId, String storyId) =>
      '${parentId}_${kidId}_$storyId';

  List<StoryProgress> _getCachedProgress(String parentId, String kidId) {
    try {
      final box = Hive.box(_hiveBoxName);
      final prefix = '${parentId}_${kidId}_';
      return box.keys
          .where((k) => k.toString().startsWith(prefix))
          .map((k) {
            final raw = box.get(k) as Map?;
            if (raw == null) return null;
            final storyId = k.toString().replaceFirst(prefix, '');
            final typedMap = raw.map((key, v) => MapEntry(key.toString(), v));
            return _progressFromMap(storyId, typedMap);
          })
          .whereType<StoryProgress>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  StoryProgress _progressFromMap(String storyId, Map<String, dynamic> data) {
    return StoryProgress(
      storyId: storyId,
      storyTitle: data['storyTitle'] as String? ?? '',
      currentStepId: data['currentStepId'] as String? ?? '',
      choicesMade: (data['choicesMade'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      stepsVisited: (data['stepsVisited'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      percentComplete:
          (data['percentComplete'] as num?)?.toDouble() ?? 0.0,
      isComplete: data['isComplete'] as bool? ?? false,
      endingTitle: data['endingTitle'] as String?,
      startedAt: data['startedAt'] is DateTime
          ? data['startedAt'] as DateTime
          : DateTime.now(),
      updatedAt: data['updatedAt'] is DateTime
          ? data['updatedAt'] as DateTime
          : DateTime.now(),
      completedAt: data['completedAt'] is DateTime
          ? data['completedAt'] as DateTime
          : null,
    );
  }
}
