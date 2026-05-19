import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/illustrated_empty_state.dart';
import 'package:kids_stories/features/gamification/data/models/reading_streak.dart';
import 'package:kids_stories/features/gamification/presentation/providers/gamification_provider.dart';
import 'package:kids_stories/features/gamification/presentation/widgets/streak_display.dart';

/// Screen displaying the child's reading streak, a 30-day calendar heatmap,
/// and their personal-best streak record.
class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(readingStreakProvider);

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      appBar: AppBar(
        title: const Text('Reading Streak 🔥'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: streakAsync.when(
        data: (streak) => _buildBody(context, streak),
        loading: () => _buildShimmer(context),
        error: (error, _) => IllustratedEmptyState(
          title: 'Could not load streak',
          subtitle: 'Pull down to try again.',
          action: TextButton(
            onPressed: () => ref.invalidate(readingStreakProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main body
  // ---------------------------------------------------------------------------

  Widget _buildBody(BuildContext context, ReadingStreak streak) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: TaleColors.terracotta,
      onRefresh: () async {
        // Returning immediately is fine — the provider will rebuild via
        // invalidation from GamificationNotifier when needed.
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Large streak display ----
            Center(
              child: StreakDisplay(streak: streak),
            ),

            const SizedBox(height: 32),

            // ---- Calendar heading ----
            Text(
              'Last 30 Days',
              style: theme.textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            // ---- 30-day calendar grid ----
            _buildCalendarGrid(context, streak),

            const SizedBox(height: 24),

            // ---- Personal best card ----
            _buildPersonalBestCard(context, streak),

            const SizedBox(height: 16),

            // ---- Motivational message ----
            Text(
              streak.motivationalMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: TaleColors.warmGrey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 30-day calendar grid
  // ---------------------------------------------------------------------------

  Widget _buildCalendarGrid(BuildContext context, ReadingStreak streak) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build list of the last 30 calendar days, oldest first.
    final days = List.generate(30, (i) {
      return today.subtract(Duration(days: 29 - i));
    });

    // Normalise streakDates to calendar-day precision for O(1) lookup.
    final readDays = streak.streakDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final wasRead = readDays.contains(day);
        final isToday = day.isAtSameMomentAs(today);

        return _DayCell(
          day: day,
          wasRead: wasRead,
          isToday: isToday,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Personal best card
  // ---------------------------------------------------------------------------

  Widget _buildPersonalBestCard(BuildContext context, ReadingStreak streak) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: TaleColors.parchmentDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Best',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: TaleColors.warmGrey600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${streak.longestStreak} '
                  '${streak.longestStreak == 1 ? 'day' : 'days'}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    color: TaleColors.terracotta,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer
  // ---------------------------------------------------------------------------

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: TaleColors.warmGrey200,
      highlightColor: TaleColors.warmGrey100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Streak placeholder
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TaleColors.warmGrey200,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 48,
                    decoration: BoxDecoration(
                      color: TaleColors.warmGrey200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Calendar placeholder
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: 30,
              itemBuilder: (_, __) => Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: TaleColors.warmGrey200,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: TaleColors.warmGrey200,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day cell widget
// ---------------------------------------------------------------------------

/// A 36×36 [CircleAvatar]-based cell for the 30-day calendar heatmap.
///
/// - **Read**: warm-gold background with a white checkmark.
/// - **Today (not yet read)**: terracotta outline circle.
/// - **Missed**: muted warm-grey background.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.wasRead,
    required this.isToday,
  });

  final DateTime day;
  final bool wasRead;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    if (wasRead) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: TaleColors.warmGold,
        child: const Icon(
          Icons.check,
          size: 16,
          color: Colors.white,
        ),
      );
    }

    if (isToday) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: TaleColors.terracotta,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: const TextStyle(
              fontSize: 11,
              color: TaleColors.terracotta,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Missed / future day
    return CircleAvatar(
      radius: 18,
      backgroundColor: TaleColors.warmGrey200,
      child: Text(
        '${day.day}',
        style: const TextStyle(
          fontSize: 11,
          color: TaleColors.warmGrey500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
