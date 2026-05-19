import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/illustrated_empty_state.dart';
import 'package:kids_stories/core/widgets/section_header.dart';
import 'package:kids_stories/features/gamification/data/models/achievement.dart';
import 'package:kids_stories/features/gamification/presentation/providers/gamification_provider.dart';
import 'package:kids_stories/features/gamification/presentation/widgets/achievement_badge.dart';
import 'package:kids_stories/features/gamification/presentation/widgets/streak_display.dart';

/// Screen displaying all achievements, the reading streak, and reading stats.
///
/// Uses three async providers:
/// - [achievementsProvider] — badge grid data.
/// - [readingStreakProvider] — streak widget data.
/// - [gamificationStatsProvider] — stat card data.
///
/// Shows shimmer placeholders while loading and a friendly error state on
/// failure.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final streakAsync = ref.watch(readingStreakProvider);
    final statsAsync = ref.watch(gamificationStatsProvider);

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: CustomScrollView(
        slivers: [
          // ---- SliverAppBar ----
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: TaleColors.parchment,
            title: const Text('My Achievements ⭐'),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),

          // ---- Body ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Streak display ----
                  Center(
                    child: streakAsync.when(
                      data: (streak) => StreakDisplay(streak: streak),
                      loading: _buildStreakShimmer,
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ---- Badges Earned ----
                  const SectionHeader(title: 'Badges Earned'),
                  const SizedBox(height: 12),

                  achievementsAsync.when(
                    data: (achievements) =>
                        _buildBadgeGrid(context, achievements),
                    loading: _buildBadgesShimmer,
                    error: (error, _) => IllustratedEmptyState(
                      title: 'Could not load badges',
                      subtitle: 'Pull down to try again.',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---- Reading Stats ----
                  const SectionHeader(title: 'Reading Stats'),
                  const SizedBox(height: 12),

                  statsAsync.when(
                    data: (stats) => _buildStatCards(context, stats),
                    loading: _buildStatsShimmer,
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Badge grid
  // ---------------------------------------------------------------------------

  Widget _buildBadgeGrid(
    BuildContext context,
    List<Achievement> achievements,
  ) {
    if (achievements.isEmpty) {
      return const IllustratedEmptyState(
        title: 'No achievements yet',
        subtitle: 'Read stories to start earning badges!',
      );
    }

    // Sort: earned first (sorted by earnedAt desc), then locked.
    final sorted = List<Achievement>.from(achievements)
      ..sort((a, b) {
        if (a.isEarned && !b.isEarned) return -1;
        if (!a.isEarned && b.isEarned) return 1;
        return 0;
      });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        return AchievementBadge(
          achievement: sorted[index],
          isLarge: true,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Stat cards
  // ---------------------------------------------------------------------------

  Widget _buildStatCards(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final theme = Theme.of(context);

    final items = [
      _StatItem(
        emoji: '📖',
        value: '${stats['storiesRead'] ?? 0}',
        label: 'Stories',
      ),
      _StatItem(
        emoji: '🌿',
        value: '${stats['endingsFound'] ?? 0}',
        label: 'Endings',
      ),
      _StatItem(
        emoji: '🔥',
        value: '${stats['currentStreak'] ?? 0}',
        label: 'Day Streak',
      ),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item == items.last ? 0 : 12,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                color: TaleColors.parchmentDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                      color: TaleColors.terracotta,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: TaleColors.warmGrey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer placeholders
  // ---------------------------------------------------------------------------

  Widget _buildStreakShimmer() {
    return Shimmer.fromColors(
      baseColor: TaleColors.warmGrey200,
      highlightColor: TaleColors.warmGrey100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 6),
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: TaleColors.warmGrey200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesShimmer() {
    return Shimmer.fromColors(
      baseColor: TaleColors.warmGrey200,
      highlightColor: TaleColors.warmGrey100,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        itemCount: 9,
        itemBuilder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: TaleColors.warmGrey200,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: TaleColors.warmGrey200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsShimmer() {
    return Shimmer.fromColors(
      baseColor: TaleColors.warmGrey200,
      highlightColor: TaleColors.warmGrey100,
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: TaleColors.warmGrey200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private data class
// ---------------------------------------------------------------------------

class _StatItem {
  const _StatItem({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;
}
