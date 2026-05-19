import 'dart:math' as math;

/// Enum representing every achievement type in TaleTrail.
enum AchievementType {
  firstStory,
  storiesRead5,
  storiesRead10,
  firstCompletion,
  streak3,
  streak7,
  explorerAllThemes,
  endings3,
  endings10,
}

/// Immutable value object representing a single achievement.
///
/// Progress is tracked separately from the earned state so that the UI can
/// show a progress bar even for locked badges.
class Achievement {
  const Achievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.requirement,
    required this.currentProgress,
    this.earnedAt,
    this.isEarned = false,
  });

  /// Stable identifier (matches the [AchievementType] name).
  final String id;

  /// The category / kind of this achievement.
  final AchievementType type;

  /// Short display title shown in the badge grid (e.g. "Bookworm 🐛").
  final String title;

  /// Supporting description shown in detail views.
  final String description;

  /// Single emoji representing the badge.
  final String emoji;

  /// UTC timestamp of when the achievement was first earned; `null` if locked.
  final DateTime? earnedAt;

  /// Whether the player has unlocked this achievement.
  final bool isEarned;

  /// Total units required to unlock (e.g. 5 stories).
  final int requirement;

  /// How far the player is towards [requirement].
  final int currentProgress;

  // ---------------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------------

  /// Progress as a clamped fraction in [0.0, 1.0] suitable for a progress bar.
  double get progressFraction =>
      math.min(currentProgress / requirement, 1.0);

  // ---------------------------------------------------------------------------
  // CopyWith
  // ---------------------------------------------------------------------------

  Achievement copyWith({
    String? id,
    AchievementType? type,
    String? title,
    String? description,
    String? emoji,
    DateTime? earnedAt,
    bool? isEarned,
    int? requirement,
    int? currentProgress,
    bool clearEarnedAt = false,
  }) {
    return Achievement(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      earnedAt: clearEarnedAt ? null : earnedAt ?? this.earnedAt,
      isEarned: isEarned ?? this.isEarned,
      requirement: requirement ?? this.requirement,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  // ---------------------------------------------------------------------------
  // Static factory — all achievements
  // ---------------------------------------------------------------------------

  /// Returns the full catalogue of [Achievement] objects at zero progress.
  ///
  /// Call [copyWith] to inject actual progress / earned state before displaying.
  static List<Achievement> allAchievements() {
    return [
      const Achievement(
        id: 'firstStory',
        type: AchievementType.firstStory,
        title: 'First Story! 📖',
        description: 'Read your very first story',
        emoji: '📖',
        requirement: 1,
        currentProgress: 0,
      ),
      const Achievement(
        id: 'storiesRead5',
        type: AchievementType.storiesRead5,
        title: 'Bookworm 🐛',
        description: 'Read 5 stories',
        emoji: '🐛',
        requirement: 5,
        currentProgress: 0,
      ),
      const Achievement(
        id: 'storiesRead10',
        type: AchievementType.storiesRead10,
        title: 'Story Champion 🏆',
        description: 'Read 10 stories',
        emoji: '🏆',
        requirement: 10,
        currentProgress: 0,
      ),
      const Achievement(
        id: 'firstCompletion',
        type: AchievementType.firstCompletion,
        title: 'The End! ✨',
        description: 'Complete your first story',
        emoji: '✨',
        requirement: 1,
        currentProgress: 0,
      ),
      const Achievement(
        id: 'streak3',
        type: AchievementType.streak3,
        title: 'On Fire! 🔥',
        description: '3-day reading streak',
        emoji: '🔥',
        requirement: 3,
        currentProgress: 0,
      ),
      const Achievement(
        id: 'streak7',
        type: AchievementType.streak7,
        title: 'Story Master ⭐',
        description: '7-day reading streak',
        emoji: '⭐',
        requirement: 7,
        currentProgress: 0,
      ),
      const Achievement(
        id: 'explorerAllThemes',
        type: AchievementType.explorerAllThemes,
        title: 'World Explorer 🌍',
        description: 'Read stories from all themes',
        emoji: '🌍',
        requirement: 6,
        currentProgress: 0,
      ),
      const Achievement(
        id: 'endings3',
        type: AchievementType.endings3,
        title: 'Fork in the Road 🌿',
        description: 'Discover 3 different endings',
        emoji: '🌿',
        requirement: 3,
        currentProgress: 0,
      ),
      const Achievement(
        id: 'endings10',
        type: AchievementType.endings10,
        title: 'Ending Hunter 🎯',
        description: 'Discover 10 different endings',
        emoji: '🎯',
        requirement: 10,
        currentProgress: 0,
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Achievement(id: $id, isEarned: $isEarned, progress: $currentProgress/$requirement)';
}
