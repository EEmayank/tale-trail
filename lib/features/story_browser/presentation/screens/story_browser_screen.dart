import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_stories/core/navigation/app_router.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/illustrated_empty_state.dart';
import 'package:kids_stories/features/profile/presentation/providers/profile_provider.dart';
import 'package:kids_stories/features/story_browser/data/models/story_progress.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';
import 'package:kids_stories/features/story_browser/presentation/providers/story_browser_provider.dart';
import 'package:kids_stories/features/story_browser/presentation/widgets/continue_reading_banner.dart';
import 'package:kids_stories/features/story_browser/presentation/widgets/story_section.dart';
import 'package:kids_stories/features/story_browser/presentation/widgets/theme_tab_bar.dart';

const _searchRoute = '/search';

StoryProgress _dummyProgress(String storyId) => StoryProgress(
      storyId: storyId,
      storyTitle: '',
      currentStepId: '',
      choicesMade: {},
      stepsVisited: [],
      percentComplete: 0,
      isComplete: false,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

class StoryBrowserScreen extends ConsumerStatefulWidget {
  const StoryBrowserScreen({super.key});

  @override
  ConsumerState<StoryBrowserScreen> createState() =>
      _StoryBrowserScreenState();
}

class _StoryBrowserScreenState extends ConsumerState<StoryBrowserScreen> {
  bool _isRefreshing = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    ref.invalidate(newStoriesProvider);
    ref.invalidate(popularStoriesProvider);
    ref.invalidate(inProgressStoriesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    setState(() => _isRefreshing = false);
  }

  List<StorySummary> _applyThemeFilter(
    List<StorySummary> stories,
    String? theme,
  ) {
    if (theme == null || theme == 'all') return stories;
    return stories.where((s) => s.themes.contains(theme)).toList();
  }

  Widget _errorSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TaleDimensions.paddingMd,
        vertical: 8,
      ),
      child: IllustratedEmptyState(
        title: 'Oops!',
        subtitle: 'Could not load $title. Pull down to try again.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(activeKidProfileProvider);
    final selectedTheme = ref.watch(selectedThemeProvider);

    final newStoriesAsync = ref.watch(newStoriesProvider);
    final popularAsync = ref.watch(popularStoriesProvider);

    final kidsAsync = profile != null
        ? ref.watch(kidsStoriesProvider(profile.age))
        : const AsyncValue<List<StorySummary>>.data([]);

    final inProgressAsync = ref.watch(inProgressStoriesProvider);
    final progressStream = ref.watch(kidProgressStreamProvider);

    final progressMap = progressStream.valueOrNull != null
        ? {
            for (final p in progressStream.valueOrNull!)
              p.storyId: p.percentComplete / 100,
          }
        : <String, double>{};

    final kidName = profile?.name ?? 'explorer';

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: TaleColors.terracotta,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar
            SliverAppBar(
              pinned: true,
              backgroundColor: TaleColors.parchment,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tale',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: TaleColors.warmGrey900,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Baloo2',
                      ),
                    ),
                    TextSpan(
                      text: 'Trail',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: TaleColors.terracotta,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Baloo2',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  color: TaleColors.warmGrey700,
                  onPressed: () => context.push(_searchRoute),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Main content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: TaleDimensions.paddingMd),

                  // Greeting
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TaleDimensions.paddingMd,
                    ),
                    child: Text(
                      '$_greeting, $kidName! 👋',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: TaleColors.warmGrey900,
                      ),
                    ),
                  ),
                  const SizedBox(height: TaleDimensions.paddingMd),

                  // Theme tabs
                  const ThemeTabBar(),
                  const SizedBox(height: TaleDimensions.paddingMd),

                  // Continue reading banner
                  inProgressAsync.when(
                    data: (inProgress) {
                      if (inProgress.isEmpty) return const SizedBox.shrink();
                      final story = inProgress.first;
                      final allProgress = progressStream.valueOrNull ?? [];
                      StoryProgress? progressData;
                      for (final p in allProgress) {
                        if (p.storyId == story.id) {
                          progressData = p;
                          break;
                        }
                      }
                      progressData ??= _dummyProgress(story.id);
                      if (progressData.percentComplete <= 0) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          ContinueReadingBanner(
                            story: story,
                            progress: progressData,
                            onTap: () => context.push(
                              AppRoutes.storyDetailPath(story.id),
                            ),
                          ),
                          const SizedBox(height: TaleDimensions.paddingMd),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // New this week
                  newStoriesAsync.when(
                    data: (stories) => StorySection(
                      title: 'New this week',
                      stories: _applyThemeFilter(stories, selectedTheme),
                      onSeeAll: () => context.push(AppRoutes.newThisWeek),
                      onStoryTap: (s) =>
                          context.push(AppRoutes.storyDetailPath(s.id)),
                    ),
                    loading: () => const StorySection(
                      title: 'New this week',
                      stories: [],
                      isLoading: true,
                    ),
                    error: (_, __) => _errorSection('New this week'),
                  ),
                  const SizedBox(height: TaleDimensions.paddingLg),

                  // Popular
                  popularAsync.when(
                    data: (stories) => StorySection(
                      title: 'Popular',
                      stories: _applyThemeFilter(stories, selectedTheme),
                      onStoryTap: (s) =>
                          context.push(AppRoutes.storyDetailPath(s.id)),
                    ),
                    loading: () => const StorySection(
                      title: 'Popular',
                      stories: [],
                      isLoading: true,
                    ),
                    error: (_, __) => _errorSection('Popular'),
                  ),
                  const SizedBox(height: TaleDimensions.paddingLg),

                  // Just for you (age-matched)
                  kidsAsync.when(
                    data: (stories) => StorySection(
                      title: 'Just for you',
                      stories: _applyThemeFilter(stories, selectedTheme),
                      showProgress: true,
                      progresses: progressMap,
                      onStoryTap: (s) =>
                          context.push(AppRoutes.storyDetailPath(s.id)),
                    ),
                    loading: () => const StorySection(
                      title: 'Just for you',
                      stories: [],
                      isLoading: true,
                    ),
                    error: (_, __) => _errorSection('Just for you'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
