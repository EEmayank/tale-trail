import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kids_stories/features/gamification/data/models/achievement.dart';
import 'package:kids_stories/features/gamification/data/models/reading_streak.dart';

/// Exception thrown by [GamificationRepository] on failure.
class GamificationException implements Exception {
  const GamificationException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'GamificationException: $message';
}

/// Repository that handles all gamification reads and writes in Firestore.
///
/// Data lives at:
///   `parents/{parentId}/kids/{kidId}/gamification/stats`
class GamificationRepository {
  GamificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Firestore path helpers
  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _statsDoc(
    String parentId,
    String kidId,
  ) =>
      _firestore
          .collection('parents')
          .doc(parentId)
          .collection('kids')
          .doc(kidId)
          .collection('gamification')
          .doc('stats');

  // ---------------------------------------------------------------------------
  // Default / empty stats
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _defaultStats() => {
        'storiesRead': 0,
        'endingsFound': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastReadDate': null,
        'streakDates': <dynamic>[],
        'themesExplored': <String>[],
        'earnedAchievements': <String>[],
      };

  // ---------------------------------------------------------------------------
  // getAchievements
  // ---------------------------------------------------------------------------

  /// Returns the full achievement catalogue annotated with current progress
  /// and earned state for the given kid.
  Future<List<Achievement>> getAchievements(
    String parentId,
    String kidId,
  ) async {
    try {
      final snap = await _statsDoc(parentId, kidId).get();
      final data =
          snap.exists ? (snap.data() ?? _defaultStats()) : _defaultStats();

      return _buildAchievements(data);
    } catch (e) {
      throw GamificationException(
        'Failed to load achievements.',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // getReadingStreak
  // ---------------------------------------------------------------------------

  /// Returns the current [ReadingStreak] for the given kid.
  Future<ReadingStreak> getReadingStreak(
    String parentId,
    String kidId,
  ) async {
    try {
      final snap = await _statsDoc(parentId, kidId).get();
      if (!snap.exists || snap.data() == null) {
        return ReadingStreak.empty;
      }
      return ReadingStreak.fromFirestore(snap.data()!);
    } catch (e) {
      throw GamificationException(
        'Failed to load reading streak.',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // recordStoryCompletion
  // ---------------------------------------------------------------------------

  /// Records a completed story and returns any newly earned [Achievement]s.
  ///
  /// Steps:
  /// 1. Fetch current stats (or use defaults if document doesn't exist).
  /// 2. Increment [storiesRead] and [endingsFound].
  /// 3. Add [theme] to [themesExplored] if not already present.
  /// 4. Determine which achievements are newly unlocked in this call.
  /// 5. Write updated stats back to Firestore.
  /// 6. Return the list of newly earned [Achievement] objects.
  Future<List<Achievement>> recordStoryCompletion({
    required String parentId,
    required String kidId,
    required String storyId,
    required String theme,
    required String endingTitle,
  }) async {
    try {
      final ref = _statsDoc(parentId, kidId);
      final snap = await ref.get();
      final data = snap.exists && snap.data() != null
          ? Map<String, dynamic>.from(snap.data()!)
          : _defaultStats();

      // --- Mutate in memory ---
      final int prevStoriesRead = (data['storiesRead'] as num?)?.toInt() ?? 0;
      final int prevEndingsFound = (data['endingsFound'] as num?)?.toInt() ?? 0;
      final List<String> prevThemes =
          List<String>.from(data['themesExplored'] as List? ?? []);
      final List<String> earnedIds =
          List<String>.from(data['earnedAchievements'] as List? ?? []);

      final int newStoriesRead = prevStoriesRead + 1;
      final int newEndingsFound = prevEndingsFound + 1;
      final List<String> newThemes = List<String>.from(prevThemes);
      if (!newThemes.contains(theme)) {
        newThemes.add(theme);
      }
      final int currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;

      // --- Determine newly unlocked achievements ---
      final List<Achievement> newlyEarned = [];
      final allDefs = Achievement.allAchievements();

      for (final def in allDefs) {
        if (earnedIds.contains(def.id)) continue; // already earned

        bool nowEarned = false;
        switch (def.type) {
          case AchievementType.firstStory:
            nowEarned = newStoriesRead >= 1;
          case AchievementType.storiesRead5:
            nowEarned = newStoriesRead >= 5;
          case AchievementType.storiesRead10:
            nowEarned = newStoriesRead >= 10;
          case AchievementType.firstCompletion:
            nowEarned = newEndingsFound >= 1;
          case AchievementType.streak3:
            nowEarned = currentStreak >= 3;
          case AchievementType.streak7:
            nowEarned = currentStreak >= 7;
          case AchievementType.explorerAllThemes:
            nowEarned = newThemes.length >= def.requirement;
          case AchievementType.endings3:
            nowEarned = newEndingsFound >= 3;
          case AchievementType.endings10:
            nowEarned = newEndingsFound >= 10;
        }

        if (nowEarned) {
          earnedIds.add(def.id);
          newlyEarned.add(def.copyWith(
            isEarned: true,
            earnedAt: DateTime.now(),
            currentProgress: def.requirement,
          ));
        }
      }

      // --- Persist ---
      final updatedData = <String, dynamic>{
        ...data,
        'storiesRead': newStoriesRead,
        'endingsFound': newEndingsFound,
        'themesExplored': newThemes,
        'earnedAchievements': earnedIds,
        'lastCompletedStoryId': storyId,
        'lastCompletedEndingTitle': endingTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await ref.set(updatedData, SetOptions(merge: true));

      return newlyEarned;
    } catch (e) {
      throw GamificationException(
        'Failed to record story completion.',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // recordDailyRead
  // ---------------------------------------------------------------------------

  /// Records a reading session for today and returns the updated [ReadingStreak].
  ///
  /// If the child has already read today the streak is returned unchanged.
  Future<ReadingStreak> recordDailyRead(
    String parentId,
    String kidId,
  ) async {
    try {
      final ref = _statsDoc(parentId, kidId);
      final snap = await ref.get();
      final data = snap.exists && snap.data() != null
          ? snap.data()!
          : _defaultStats();

      final current = ReadingStreak.fromFirestore(data);
      final updated = current.recordRead();

      // Only write if something changed.
      if (updated != current) {
        await ref.set(
          {
            'currentStreak': updated.currentStreak,
            'longestStreak': updated.longestStreak,
            'lastReadDate': updated.lastReadDate != null
                ? Timestamp.fromDate(updated.lastReadDate!)
                : null,
            'streakDates':
                updated.streakDates.map(Timestamp.fromDate).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      return updated;
    } catch (e) {
      throw GamificationException(
        'Failed to record daily read.',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // getStats
  // ---------------------------------------------------------------------------

  /// Returns a summary stats map for display in the achievements screen.
  ///
  /// Keys: `storiesRead`, `endingsFound`, `currentStreak`, `longestStreak`,
  /// `themesExplored`.
  Future<Map<String, dynamic>> getStats(
    String parentId,
    String kidId,
  ) async {
    try {
      final snap = await _statsDoc(parentId, kidId).get();
      final data =
          snap.exists ? (snap.data() ?? _defaultStats()) : _defaultStats();

      return {
        'storiesRead': (data['storiesRead'] as num?)?.toInt() ?? 0,
        'endingsFound': (data['endingsFound'] as num?)?.toInt() ?? 0,
        'currentStreak': (data['currentStreak'] as num?)?.toInt() ?? 0,
        'longestStreak': (data['longestStreak'] as num?)?.toInt() ?? 0,
        'themesExplored':
            List<String>.from(data['themesExplored'] as List? ?? []),
      };
    } catch (e) {
      throw GamificationException(
        'Failed to load stats.',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Constructs the full achievement list from a raw Firestore [data] map,
  /// injecting progress values and earned state.
  List<Achievement> _buildAchievements(Map<String, dynamic> data) {
    final int storiesRead = (data['storiesRead'] as num?)?.toInt() ?? 0;
    final int endingsFound = (data['endingsFound'] as num?)?.toInt() ?? 0;
    final int currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
    final List<String> themesExplored =
        List<String>.from(data['themesExplored'] as List? ?? []);
    final List<String> earnedIds =
        List<String>.from(data['earnedAchievements'] as List? ?? []);

    return Achievement.allAchievements().map((def) {
      final earned = earnedIds.contains(def.id);

      int progress;
      switch (def.type) {
        case AchievementType.firstStory:
        case AchievementType.storiesRead5:
        case AchievementType.storiesRead10:
          progress = storiesRead;
        case AchievementType.firstCompletion:
        case AchievementType.endings3:
        case AchievementType.endings10:
          progress = endingsFound;
        case AchievementType.streak3:
        case AchievementType.streak7:
          progress = currentStreak;
        case AchievementType.explorerAllThemes:
          progress = themesExplored.length;
      }

      return def.copyWith(
        isEarned: earned,
        currentProgress: progress,
        earnedAt: earned ? DateTime.now() : null,
      );
    }).toList();
  }
}
