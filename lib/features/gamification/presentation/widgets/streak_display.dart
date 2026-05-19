import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/features/gamification/data/models/reading_streak.dart';

/// Displays the child's current reading streak.
///
/// Two visual modes are available:
/// - **Full** (default): a centred [Column] with a large flame emoji, the
///   streak count in [displayLarge], a "day streak" label, and the
///   [ReadingStreak.motivationalMessage].
/// - **Compact** (`isCompact: true`): a tight [Row] suitable for embedding
///   inside list tiles or app-bar subtitles.
///
/// Colors shift from muted warm-grey (streak == 0) to amber / orange
/// (streak > 0) to communicate momentum visually.
class StreakDisplay extends StatelessWidget {
  const StreakDisplay({
    super.key,
    required this.streak,
    this.isCompact = false,
  });

  /// The current reading streak data to display.
  final ReadingStreak streak;

  /// When `true` renders a compact row; otherwise renders the full column.
  final bool isCompact;

  // ---------------------------------------------------------------------------
  // Theming helpers
  // ---------------------------------------------------------------------------

  bool get _hasStreak => streak.currentStreak > 0;

  Color get _primaryColor =>
      _hasStreak ? Colors.orange : TaleColors.warmGrey400;

  Color get _numberColor =>
      _hasStreak ? const Color(0xFFE65100) : TaleColors.warmGrey400;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return isCompact ? _buildCompact(context) : _buildFull(context);
  }

  // ---------------------------------------------------------------------------
  // Full layout
  // ---------------------------------------------------------------------------

  Widget _buildFull(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flame emoji
        Text(
          '🔥',
          style: TextStyle(
            fontSize: _hasStreak ? 72 : 64,
          ),
        ),
        const SizedBox(height: 8),

        // Streak count
        Text(
          '${streak.currentStreak}',
          style: theme.textTheme.displayLarge?.copyWith(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            color: _numberColor,
          ),
        ),

        // "day streak" label
        Text(
          streak.currentStreak == 1 ? 'day streak' : 'day streak',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Motivational message
        Text(
          streak.motivationalMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: TaleColors.warmGrey500,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Compact layout
  // ---------------------------------------------------------------------------

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Flame emoji — smaller in compact mode
        const Text('🔥', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 4),

        // Count
        Text(
          '${streak.currentStreak}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            color: _numberColor,
          ),
        ),
        const SizedBox(width: 4),

        // "days" label
        Text(
          streak.currentStreak == 1 ? 'day' : 'days',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _primaryColor,
          ),
        ),
      ],
    );
  }
}
