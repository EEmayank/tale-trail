import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_stories/features/gamification/data/models/achievement.dart';
import 'package:kids_stories/features/gamification/data/models/reading_streak.dart';
import 'package:kids_stories/features/gamification/data/repositories/gamification_repository.dart';
import 'package:kids_stories/features/profile/presentation/providers/profile_provider.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the singleton [GamificationRepository] instance.
final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepository(),
  name: 'gamificationRepositoryProvider',
);

// ---------------------------------------------------------------------------
// Helper — current parent / kid IDs
// ---------------------------------------------------------------------------

/// Returns the current Firebase Auth user UID, or `null` when signed out.
String? _currentParentId() => FirebaseAuth.instance.currentUser?.uid;

// ---------------------------------------------------------------------------
// achievementsProvider
// ---------------------------------------------------------------------------

/// Async provider that resolves to the full achievement catalogue with
/// progress annotated for the currently active kid profile.
///
/// Returns an empty list when no kid profile is active or when the parent
/// is not authenticated.
final achievementsProvider = FutureProvider<List<Achievement>>(
  (ref) async {
    final profile = ref.watch(activeKidProfileProvider);
    final parentId = _currentParentId();

    if (profile == null || parentId == null) {
      return [];
    }

    final repo = ref.read(gamificationRepositoryProvider);
    return repo.getAchievements(parentId, profile.id);
  },
  name: 'achievementsProvider',
);

// ---------------------------------------------------------------------------
// readingStreakProvider
// ---------------------------------------------------------------------------

/// Async provider that resolves to the current [ReadingStreak] for the active
/// kid profile.
///
/// Returns [ReadingStreak.empty] when no kid profile is active.
final readingStreakProvider = FutureProvider<ReadingStreak>(
  (ref) async {
    final profile = ref.watch(activeKidProfileProvider);
    final parentId = _currentParentId();

    if (profile == null || parentId == null) {
      return ReadingStreak.empty;
    }

    final repo = ref.read(gamificationRepositoryProvider);
    return repo.getReadingStreak(parentId, profile.id);
  },
  name: 'readingStreakProvider',
);

// ---------------------------------------------------------------------------
// gamificationStatsProvider
// ---------------------------------------------------------------------------

/// Async provider that resolves to the raw stats map for the active kid.
///
/// Keys: `storiesRead`, `endingsFound`, `currentStreak`, `longestStreak`,
/// `themesExplored`.
final gamificationStatsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final profile = ref.watch(activeKidProfileProvider);
    final parentId = _currentParentId();

    if (profile == null || parentId == null) {
      return {
        'storiesRead': 0,
        'endingsFound': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'themesExplored': <String>[],
      };
    }

    final repo = ref.read(gamificationRepositoryProvider);
    return repo.getStats(parentId, profile.id);
  },
  name: 'gamificationStatsProvider',
);

// ---------------------------------------------------------------------------
// newlyEarnedAchievementsProvider
// ---------------------------------------------------------------------------

/// Holds the list of [Achievement]s that were just earned in the most recent
/// story completion.
///
/// The [CompletionCelebration] widget (or any achievement overlay) should
/// watch this provider and clear it after displaying the unlock notification.
final newlyEarnedAchievementsProvider =
    StateProvider<List<Achievement>>(
  (ref) => const [],
  name: 'newlyEarnedAchievementsProvider',
);

// ---------------------------------------------------------------------------
// GamificationNotifier
// ---------------------------------------------------------------------------

/// Notifier that owns gamification side-effect operations.
///
/// Widgets trigger [recordCompletion] (at the end of a story) and
/// [checkAndUpdateStreak] (on app foreground / story session start).
class GamificationNotifier extends StateNotifier<AsyncValue<void>> {
  GamificationNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  GamificationRepository get _repo =>
      _ref.read(gamificationRepositoryProvider);

  String? get _parentId => _currentParentId();

  String? get _kidId =>
      _ref.read(activeKidProfileProvider)?.id;

  // ---------------------------------------------------------------------------
  // recordCompletion
  // ---------------------------------------------------------------------------

  /// Records a story completion and publishes any newly earned achievements to
  /// [newlyEarnedAchievementsProvider].
  ///
  /// Also triggers a streak update so that completing a story counts as a daily
  /// read.
  Future<void> recordCompletion({
    required String storyId,
    required String theme,
    required String endingTitle,
  }) async {
    final parentId = _parentId;
    final kidId = _kidId;
    if (parentId == null || kidId == null) return;

    state = const AsyncValue.loading();
    try {
      // Record completion and streak in parallel.
      final results = await Future.wait([
        _repo.recordStoryCompletion(
          parentId: parentId,
          kidId: kidId,
          storyId: storyId,
          theme: theme,
          endingTitle: endingTitle,
        ),
        _repo.recordDailyRead(parentId, kidId),
      ]);

      final newlyEarned = results[0] as List<Achievement>;
      if (newlyEarned.isNotEmpty) {
        _ref.read(newlyEarnedAchievementsProvider.notifier).state =
            newlyEarned;
      }

      // Invalidate downstream providers so UI refreshes.
      _ref.invalidate(achievementsProvider);
      _ref.invalidate(readingStreakProvider);
      _ref.invalidate(gamificationStatsProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // checkAndUpdateStreak
  // ---------------------------------------------------------------------------

  /// Updates the reading streak for today's calendar date.
  ///
  /// Call this when the app comes to the foreground or when the child starts
  /// a reading session, so the streak is maintained even if a story isn't
  /// fully completed.
  Future<void> checkAndUpdateStreak() async {
    final parentId = _parentId;
    final kidId = _kidId;
    if (parentId == null || kidId == null) return;

    try {
      await _repo.recordDailyRead(parentId, kidId);
      _ref.invalidate(readingStreakProvider);
      _ref.invalidate(gamificationStatsProvider);
    } catch (_) {
      // Streak update is best-effort; do not surface errors to the user.
    }
  }
}

// ---------------------------------------------------------------------------
// gamificationNotifierProvider
// ---------------------------------------------------------------------------

/// [StateNotifierProvider] exposing [GamificationNotifier].
final gamificationNotifierProvider =
    StateNotifierProvider<GamificationNotifier, AsyncValue<void>>(
  (ref) => GamificationNotifier(ref),
  name: 'gamificationNotifierProvider',
);
