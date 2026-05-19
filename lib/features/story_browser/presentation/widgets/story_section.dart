import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/section_header.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';
import 'package:kids_stories/features/story_browser/presentation/widgets/story_card.dart';

/// A horizontal-scrolling section of [StoryCard] widgets under a
/// [SectionHeader]. Uses [AsyncValue.when] to handle loading / error / data
/// states from a Riverpod provider.
class StorySection extends StatelessWidget {
  const StorySection({
    super.key,
    required this.title,
    required this.stories,
    this.onSeeAll,
    this.progresses = const {},
  });

  /// Section heading text.
  final String title;

  /// Async list of stories from a provider.
  final AsyncValue<List<StorySummary>> stories;

  /// Optional callback for the "See All" button.
  final VoidCallback? onSeeAll;

  /// Map of storyId → 0.0–1.0 progress fraction for each card.
  final Map<String, double> progresses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TaleDimensions.paddingMd,
          ),
          child: SectionHeader(title: title, onSeeAll: onSeeAll),
        ),
        const SizedBox(height: 12),
        stories.when(
          loading: () => _ShimmerRow(),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TaleDimensions.paddingMd,
            ),
            child: Text(
              "Couldn't load stories",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TaleColors.warmGrey500,
                  ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TaleDimensions.paddingMd,
                ),
                child: Text(
                  'No stories yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TaleColors.warmGrey400,
                      ),
                ),
              );
            }
            return SizedBox(
              height: 232,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: TaleDimensions.paddingMd,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final story = list[index];
                  final progress = progresses[story.id];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < list.length - 1 ? 12.0 : 0.0,
                    ),
                    child: StoryCard(
                      story: story,
                      onTap: () => context.push('/stories/${story.id}'),
                      showProgress: progress != null,
                      progressFraction: progress ?? 0.0,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder row
// ---------------------------------------------------------------------------

class _ShimmerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: Shimmer.fromColors(
        baseColor: TaleColors.warmGrey200,
        highlightColor: TaleColors.warmGrey100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: TaleDimensions.paddingMd,
          ),
          itemCount: 3,
          itemBuilder: (_, index) => Padding(
            padding: EdgeInsets.only(right: index < 2 ? 12.0 : 0.0),
            child: Container(
              width: 150,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [TaleColors.warmGrey200, TaleColors.warmGrey300],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
