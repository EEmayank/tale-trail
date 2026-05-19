import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/features/gamification/data/models/achievement.dart';

/// A circular badge that represents a single [Achievement].
///
/// - **Earned**: warm-gold background, emoji centred, optional drop-shadow.
/// - **Locked**: muted warm-grey background, semi-transparent emoji, lock icon.
/// - If the achievement has a [requirement] > 1 and is not yet earned, a thin
///   [LinearProgressIndicator] is rendered below the badge circle.
///
/// Two sizes are supported via [isLarge]:
/// - Large (80 px circle, 32 px emoji) — for the achievements grid.
/// - Small (56 px circle, 24 px emoji) — for inline / summary use.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.isLarge = true,
  });

  /// The achievement to display.
  final Achievement achievement;

  /// `true` → 80 px circle; `false` → 56 px circle.
  final bool isLarge;

  // ---------------------------------------------------------------------------
  // Size helpers
  // ---------------------------------------------------------------------------

  double get _circleSize => isLarge ? 80.0 : 56.0;
  double get _emojiFontSize => isLarge ? 32.0 : 24.0;
  double get _lockIconSize => 14.0;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---- Badge circle ----
        _buildCircle(),

        const SizedBox(height: 4),

        // ---- Title (truncated) ----
        SizedBox(
          width: _circleSize,
          child: Text(
            achievement.title.length > 12
                ? '${achievement.title.substring(0, 12)}…'
                : achievement.title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: achievement.isEarned
                  ? TaleColors.warmGrey900
                  : TaleColors.warmGrey500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ---- Progress bar (locked, requirement > 1) ----
        if (!achievement.isEarned && achievement.requirement > 1) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: _circleSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: achievement.progressFraction,
                minHeight: 4,
                backgroundColor: TaleColors.warmGrey200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  TaleColors.warmGold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Circle
  // ---------------------------------------------------------------------------

  Widget _buildCircle() {
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: achievement.isEarned
          ? BoxDecoration(
              shape: BoxShape.circle,
              color: TaleColors.warmGold,
              boxShadow: [
                BoxShadow(
                  color: TaleColors.warmGold.withAlpha(128),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : const BoxDecoration(
              shape: BoxShape.circle,
              color: TaleColors.warmGrey200,
            ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Emoji
          Opacity(
            opacity: achievement.isEarned ? 1.0 : 0.5,
            child: Text(
              achievement.emoji,
              style: TextStyle(fontSize: _emojiFontSize),
            ),
          ),

          // Lock icon overlay (only when locked)
          if (!achievement.isEarned)
            Positioned(
              right: isLarge ? 8 : 5,
              bottom: isLarge ? 8 : 5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: TaleColors.warmGrey100,
                ),
                child: Icon(
                  Icons.lock,
                  size: _lockIconSize,
                  color: TaleColors.warmGrey400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
