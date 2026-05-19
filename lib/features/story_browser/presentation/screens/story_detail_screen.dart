import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kids_stories/core/navigation/app_router.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/badge_chip.dart';
import 'package:kids_stories/core/widgets/illustrated_empty_state.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/story_browser/data/models/story_progress.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';
import 'package:kids_stories/features/story_browser/presentation/providers/story_browser_provider.dart';

/// Full-screen detail view for a single story.
///
/// Fetches story metadata and progress for the active kid via Riverpod, then
/// renders a [CustomScrollView] with a pinned [SliverAppBar] hero cover and a
/// sticky bottom CTA bar.
class StoryDetailScreen extends ConsumerStatefulWidget {
  const StoryDetailScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends ConsumerState<StoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyByIdProvider(widget.storyId));
    final progressAsync = ref.watch(storyProgressProvider(widget.storyId));

    return storyAsync.when(
      loading: () => const _LoadingDetail(),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: IllustratedEmptyState(
          title: 'Story not found',
          subtitle: 'Something went wrong. Please go back and try again.',
          action: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Go back'),
          ),
        ),
      ),
      data: (story) {
        if (story == null) {
          return Scaffold(
            appBar: AppBar(),
            body: IllustratedEmptyState(
              title: 'Story not found',
              subtitle: 'This story may have been removed.',
              action: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ),
          );
        }
        return _DetailBody(
          story: story,
          progressAsync: progressAsync,
          storyId: widget.storyId,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailBody
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.story,
    required this.progressAsync,
    required this.storyId,
  });

  final StorySummary story;
  final AsyncValue<StoryProgress?> progressAsync;
  final String storyId;

  Color get _accentColor {
    final accent = story.colorAccent;
    if (accent != null) {
      try {
        final hex = accent.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return TaleColors.terracotta;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = progressAsync.valueOrNull;
    final pct = progress?.percentComplete ?? 0.0;
    final isComplete = progress?.isComplete ?? false;

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: CustomScrollView(
        slivers: [
          // ----------------------------------------------------------------
          // Expandable hero cover + back button
          // ----------------------------------------------------------------
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _accentColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleBackButton(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: _CollapsedTitle(title: story.title),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero-animated cover image
                  Hero(
                    tag: 'story_cover_$storyId',
                    child: story.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: story.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _coverFallback(),
                            errorWidget: (_, __, ___) => _coverFallback(),
                          )
                        : _coverFallback(),
                  ),
                  // Bottom-to-top gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                        stops: [0.0, 0.55],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Story info body
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TaleDimensions.paddingLg,
                TaleDimensions.paddingLg,
                TaleDimensions.paddingLg,
                120, // Clearance for sticky bottom bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    story.title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: TaleColors.warmGrey900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Metadata row: age + duration + tier
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      BadgeChip.age(story.ageMin),
                      BadgeChip.duration(story.durationMinutes),
                      story.isPremium ? BadgeChip.premium() : BadgeChip.free(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Theme chips
                  if (story.themes.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: story.themes
                          .map(
                            (t) => Chip(
                              label: Text(
                                _capitalize(t),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: TaleColors.warmGrey700,
                                ),
                              ),
                              backgroundColor: TaleColors.warmGrey100,
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  Text(
                    story.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: TaleColors.warmGrey700,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Endings card
                  Container(
                    padding: const EdgeInsets.all(TaleDimensions.paddingMd),
                    decoration: BoxDecoration(
                      color: TaleColors.warmGold.withAlpha(38),
                      borderRadius:
                          BorderRadius.circular(TaleDimensions.radiusMd),
                      border: Border.all(
                        color: TaleColors.warmGold.withAlpha(76),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${story.endingCount} different ending${story.endingCount == 1 ? '' : 's'} to discover!',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: TaleColors.warmGrey800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About this story section
                  Text(
                    'About this story',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: TaleColors.warmGrey900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _InfoRow(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    value: story.language.toUpperCase(),
                  ),
                  _InfoRow(
                    icon: Icons.child_care_rounded,
                    label: 'Age range',
                    value: 'Ages ${story.ageMin}–${story.ageMax}',
                  ),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Estimated time',
                    value: '${story.durationMinutes} minutes',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // --------------------------------------------------------------------
      // Sticky bottom CTA bar
      // --------------------------------------------------------------------
      bottomNavigationBar: _BottomCTA(
        pct: pct,
        isComplete: isComplete,
        storyId: storyId,
      ),
    );
  }

  Widget _coverFallback() {
    final accent = _accentColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withAlpha(200),
            accent,
          ],
        ),
      ),
      child: Center(
        child: Text(
          story.title.isNotEmpty ? story.title[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ---------------------------------------------------------------------------
// _CollapsedTitle — visible only when the SliverAppBar is collapsed
// ---------------------------------------------------------------------------

class _CollapsedTitle extends StatelessWidget {
  const _CollapsedTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // FlexibleSpaceBar shows the title only when collapsed; we mirror that
        // by making it always opaque (Flutter handles the fade internally).
        return Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _CircleBackButton
// ---------------------------------------------------------------------------

class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(100),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InfoRow
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TaleColors.warmGrey500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: TaleColors.warmGrey500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: TaleColors.warmGrey800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BottomCTA
// ---------------------------------------------------------------------------

class _BottomCTA extends StatelessWidget {
  const _BottomCTA({
    required this.pct,
    required this.isComplete,
    required this.storyId,
  });

  final double pct;
  final bool isComplete;
  final String storyId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(
          TaleDimensions.paddingMd,
          TaleDimensions.paddingSm,
          TaleDimensions.paddingMd,
          TaleDimensions.paddingMd,
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final playPath = AppRoutes.storyPlayPath(storyId);

    // Not started or fresh start
    if (pct <= 0) {
      return TaleButton(
        onPressed: () => context.push(playPath),
        label: 'Start Story →',
      );
    }

    // In progress
    if (!isComplete) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pct.round()}% complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TaleColors.warmGrey500,
                ),
          ),
          const SizedBox(height: 8),
          TaleButton(
            onPressed: () => context.push(playPath),
            label: 'Continue Story →',
          ),
        ],
      );
    }

    // Completed
    return Row(
      children: [
        Expanded(
          child: TaleButton(
            onPressed: () => context.push(playPath),
            label: 'Read Again',
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TaleButton(
            onPressed: () => context.push(playPath),
            label: 'Explore Endings',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _LoadingDetail — shimmer layout matching the real screen structure
// ---------------------------------------------------------------------------

class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: Column(
        children: [
          // Simulated collapsed app bar
          Shimmer.fromColors(
            baseColor: TaleColors.warmGrey200,
            highlightColor: TaleColors.warmGrey100,
            child: Container(
              height: 300,
              color: TaleColors.warmGrey200,
            ),
          ),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: TaleColors.warmGrey200,
              highlightColor: TaleColors.warmGrey100,
              child: Padding(
                padding: const EdgeInsets.all(TaleDimensions.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(height: 32, width: 240),
                    const SizedBox(height: 12),
                    _shimmerBox(height: 20, width: 180),
                    const SizedBox(height: 16),
                    _shimmerBox(height: 80, width: double.infinity),
                    const SizedBox(height: 16),
                    _shimmerBox(height: 60, width: double.infinity),
                    const SizedBox(height: 24),
                    _shimmerBox(height: 24, width: 150),
                    const SizedBox(height: 12),
                    _shimmerBox(height: 20, width: double.infinity),
                    const SizedBox(height: 8),
                    _shimmerBox(height: 20, width: 200),
                    const SizedBox(height: 8),
                    _shimmerBox(height: 20, width: 220),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TaleDimensions.radiusSm),
      ),
    );
  }
}
