import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/badge_chip.dart';
import 'package:kids_stories/core/widgets/illustrated_empty_state.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';
import 'package:kids_stories/features/story_browser/presentation/providers/story_browser_provider.dart';

// ---------------------------------------------------------------------------
// SharedPreferences key
// ---------------------------------------------------------------------------

const _kRecentSearches = 'recentSearches';
const _kMaxRecentSearches = 10;

/// Popular theme chips shown when the search field is empty.
const _kPopularThemes = [
  'Adventure',
  'Friendship',
  'Fantasy',
  'Animals',
  'Science',
  'Magic',
  'Space',
  'Ocean',
];

/// Full-screen search experience.
///
/// - AppBar with autofocus [TextField] and a clear button.
/// - Empty state: recent searches + popular theme chips.
/// - Non-empty state: results from [searchResultsProvider] via
///   [AsyncValue.when].
/// - Successful searches are persisted to [SharedPreferences] (max 10).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  Timer? _debounce;

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SharedPreferences helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kRecentSearches) ?? [];
    if (mounted) {
      setState(() => _recentSearches = saved);
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final updated = [
      trimmed,
      ..._recentSearches.where((s) => s != trimmed),
    ].take(_kMaxRecentSearches).toList();

    await prefs.setStringList(_kRecentSearches, updated);
    if (mounted) {
      setState(() => _recentSearches = updated);
    }
  }

  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final updated =
        _recentSearches.where((s) => s != query).toList();
    await prefs.setStringList(_kRecentSearches, updated);
    if (mounted) {
      setState(() => _recentSearches = updated);
    }
  }

  Future<void> _clearAllRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentSearches);
    if (mounted) {
      setState(() => _recentSearches = []);
    }
  }

  // ---------------------------------------------------------------------------
  // Query handling
  // ---------------------------------------------------------------------------

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = value.trim();
    });
  }

  void _setQuery(String query) {
    _textController.text = query;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    ref.read(searchQueryProvider.notifier).state = query.trim();
  }

  void _navigateToStory(StorySummary story) {
    _saveRecentSearch(_textController.text.trim());
    context.push('/stories/${story.id}');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      appBar: AppBar(
        backgroundColor: TaleColors.parchment,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaleDimensions.paddingMd),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: TaleColors.warmGrey700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Search field
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      _saveRecentSearch(v.trim());
                    }
                  },
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TaleColors.warmGrey900,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Search stories...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TaleColors.warmGrey400,
                        ),
                    filled: true,
                    fillColor: TaleColors.warmGrey100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TaleDimensions.radiusFull),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TaleDimensions.radiusFull),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TaleDimensions.radiusFull),
                      borderSide: const BorderSide(
                        color: TaleColors.terracotta,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: _textController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: TaleColors.warmGrey500,
                            ),
                            onPressed: () {
                              _textController.clear();
                              _onQueryChanged('');
                            },
                          )
                        : const Icon(
                            Icons.search_rounded,
                            color: TaleColors.warmGrey400,
                            size: 20,
                          ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: query.isEmpty
          ? _EmptyQueryBody(
              recentSearches: _recentSearches,
              onSearchTap: _setQuery,
              onRemoveRecent: _removeRecentSearch,
              onClearAll: _clearAllRecentSearches,
            )
          : _ResultsBody(
              query: query,
              onStoryTap: _navigateToStory,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyQueryBody — shown when search field is empty
// ---------------------------------------------------------------------------

class _EmptyQueryBody extends StatelessWidget {
  const _EmptyQueryBody({
    required this.recentSearches,
    required this.onSearchTap,
    required this.onRemoveRecent,
    required this.onClearAll,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onSearchTap;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(TaleDimensions.paddingMd),
      children: [
        // Recent searches section
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: TaleColors.warmGrey800,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  foregroundColor: TaleColors.terracotta,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches
                .map(
                  (s) => _RecentChip(
                    label: s,
                    onTap: () => onSearchTap(s),
                    onRemove: () => onRemoveRecent(s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Popular themes section
        Text(
          'Popular Themes',
          style: theme.textTheme.titleSmall?.copyWith(
            color: TaleColors.warmGrey800,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kPopularThemes
              .map(
                (theme) => ActionChip(
                  label: Text(theme),
                  onPressed: () => onSearchTap(theme),
                  backgroundColor: TaleColors.warmGrey100,
                  side: const BorderSide(color: TaleColors.warmGrey300),
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TaleColors.warmGrey700,
                      ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: TaleColors.warmGrey100,
          borderRadius: BorderRadius.circular(TaleDimensions.radiusFull),
          border: Border.all(color: TaleColors.warmGrey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 14, color: TaleColors.warmGrey500),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TaleColors.warmGrey700,
                  ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  size: 14, color: TaleColors.warmGrey400),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ResultsBody — shown when query is non-empty
// ---------------------------------------------------------------------------

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({
    required this.query,
    required this.onStoryTap,
  });

  final String query;
  final ValueChanged<StorySummary> onStoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return resultsAsync.when(
      loading: () => _SearchShimmer(),
      error: (_, __) => IllustratedEmptyState(
        title: 'Search failed',
        subtitle: 'Try again',
        action: TextButton(
          onPressed: () =>
              ref.invalidate(searchResultsProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (stories) {
        if (stories.isEmpty) {
          return IllustratedEmptyState(
            title: "No results for '$query'",
            subtitle: 'Try different words',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(TaleDimensions.paddingMd),
          itemCount: stories.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: TaleColors.warmGrey200,
          ),
          itemBuilder: (context, index) {
            final story = stories[index];
            return _SearchResultTile(
              story: story,
              onTap: () => onStoryTap(story),
            );
          },
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.story,
    required this.onTap,
  });

  final StorySummary story;
  final VoidCallback onTap;

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
    final accent = _accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TaleDimensions.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(TaleDimensions.radiusSm),
              child: SizedBox(
                width: 60,
                height: 60,
                child: story.coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: story.coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ThumbnailFallback(
                          accent: accent,
                          title: story.title,
                        ),
                        errorWidget: (_, __, ___) => _ThumbnailFallback(
                          accent: accent,
                          title: story.title,
                        ),
                      )
                    : _ThumbnailFallback(accent: accent, title: story.title),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: TaleColors.warmGrey900,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      BadgeChip.age(story.ageMin, isSmall: true),
                      BadgeChip.duration(story.durationMinutes, isSmall: true),
                      if (story.isPremium)
                        BadgeChip.premium(isSmall: true)
                      else
                        BadgeChip.free(isSmall: true),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: TaleColors.warmGrey400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.accent, required this.title});

  final Color accent;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withAlpha(180), accent],
        ),
      ),
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SearchShimmer — loading state for search results
// ---------------------------------------------------------------------------

class _SearchShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LinearProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(TaleColors.terracotta),
          backgroundColor: TaleColors.warmGrey200,
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: TaleColors.warmGrey200,
            highlightColor: TaleColors.warmGrey100,
            child: ListView.separated(
              padding: const EdgeInsets.all(TaleDimensions.paddingMd),
              itemCount: 6,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (_, __) => Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        TaleDimensions.radiusSm,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 120,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
