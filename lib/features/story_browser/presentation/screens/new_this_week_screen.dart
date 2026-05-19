import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/illustrated_empty_state.dart';
import 'package:kids_stories/features/story_browser/presentation/providers/story_browser_provider.dart';
import 'package:kids_stories/features/story_browser/presentation/widgets/story_card.dart';

/// Displays a grid of stories that are flagged as new this week.
class NewThisWeekScreen extends ConsumerWidget {
  const NewThisWeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newStoriesAsync = ref.watch(newStoriesProvider);

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      appBar: AppBar(
        backgroundColor: TaleColors.parchment,
        elevation: 0,
        title: const Text('New This Week 🆕'),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: TaleColors.warmGrey900,
              fontWeight: FontWeight.w700,
            ),
        iconTheme: const IconThemeData(color: TaleColors.warmGrey700),
      ),
      body: newStoriesAsync.when(
        loading: () => _ShimmerGrid(),
        error: (_, __) => IllustratedEmptyState(
          title: 'Could not load stories',
          subtitle: 'Please check your connection and try again.',
          action: TextButton(
            onPressed: () => ref.invalidate(newStoriesProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (stories) {
          if (stories.isEmpty) {
            return const IllustratedEmptyState(
              title: 'No new stories this week',
              subtitle: 'Check back soon! 📖',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(TaleDimensions.paddingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              // 150w:220h ratio ≈ 0.682 → childAspectRatio ≈ 0.68
              childAspectRatio: 150 / 220,
            ),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return StoryCard(
                story: story,
                onTap: () => context.push('/stories/${story.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer grid — mirrors the real grid layout
// ---------------------------------------------------------------------------

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: TaleColors.warmGrey200,
      highlightColor: TaleColors.warmGrey100,
      child: GridView.builder(
        padding: const EdgeInsets.all(TaleDimensions.paddingMd),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 150 / 220,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
          ),
        ),
      ),
    );
  }
}
