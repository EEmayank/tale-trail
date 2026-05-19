import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_provider.dart';
import 'package:kids_stories/features/profile/presentation/providers/profile_provider.dart';
import 'package:kids_stories/features/story_browser/data/models/story_progress.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';
import 'package:kids_stories/features/story_browser/data/repositories/progress_repository.dart';
import 'package:kids_stories/features/story_browser/data/repositories/story_repository.dart';

// ---------------------------------------------------------------------------
// StoryFilters
// ---------------------------------------------------------------------------

class StoryFilters {
  const StoryFilters({
    this.ageMin,
    this.ageMax,
    this.language,
    this.isFreeOnly = false,
    this.themes = const [],
  });

  final int? ageMin;
  final int? ageMax;
  final String? language;
  final bool isFreeOnly;
  final List<String> themes;

  StoryFilters copyWith({
    int? ageMin,
    int? ageMax,
    String? language,
    bool? isFreeOnly,
    List<String>? themes,
    bool clearAgeMin = false,
    bool clearAgeMax = false,
    bool clearLanguage = false,
  }) {
    return StoryFilters(
      ageMin: clearAgeMin ? null : (ageMin ?? this.ageMin),
      ageMax: clearAgeMax ? null : (ageMax ?? this.ageMax),
      language: clearLanguage ? null : (language ?? this.language),
      isFreeOnly: isFreeOnly ?? this.isFreeOnly,
      themes: themes ?? this.themes,
    );
  }

  bool get hasActiveFilters =>
      ageMin != null ||
      ageMax != null ||
      language != null ||
      isFreeOnly ||
      themes.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryFilters &&
          ageMin == other.ageMin &&
          ageMax == other.ageMax &&
          language == other.language &&
          isFreeOnly == other.isFreeOnly &&
          themes.length == other.themes.length;

  @override
  int get hashCode => Object.hash(ageMin, ageMax, language, isFreeOnly, themes.length);
}

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final storyRepositoryProvider = Provider<StoryRepository>(
  (_) => StoryRepository(),
  name: 'storyRepositoryProvider',
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (_) => ProgressRepository(),
  name: 'progressRepositoryProvider',
);

// ---------------------------------------------------------------------------
// Story list providers
// ---------------------------------------------------------------------------

final featuredStoriesProvider = FutureProvider<List<StorySummary>>(
  (ref) => ref.read(storyRepositoryProvider).getFeaturedStories(),
  name: 'featuredStoriesProvider',
);

final newStoriesProvider = FutureProvider<List<StorySummary>>(
  (ref) => ref.read(storyRepositoryProvider).getNewStories(),
  name: 'newStoriesProvider',
);

final popularStoriesProvider = FutureProvider<List<StorySummary>>(
  (ref) => ref.read(storyRepositoryProvider).getPopularStories(),
  name: 'popularStoriesProvider',
);

final kidsStoriesProvider =
    FutureProvider.family<List<StorySummary>, int>((ref, age) {
  return ref.read(storyRepositoryProvider).getStoriesForKid(age);
}, name: 'kidsStoriesProvider');

// ---------------------------------------------------------------------------
// In-progress stories — combines progress data with StorySummary metadata
// ---------------------------------------------------------------------------

final inProgressStoriesProvider = FutureProvider<List<StorySummary>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final profile = ref.watch(activeKidProfileProvider);

  if (user == null || profile == null) return [];

  final progressRepo = ref.read(progressRepositoryProvider);
  final storyRepo = ref.read(storyRepositoryProvider);

  final inProgress =
      await progressRepo.getInProgressStories(user.uid, profile.id);

  final stories = <StorySummary>[];
  for (final progress in inProgress) {
    final story = await storyRepo.getStoryById(progress.storyId);
    if (story != null) stories.add(story);
  }
  return stories;
}, name: 'inProgressStoriesProvider');

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

final searchQueryProvider = StateProvider<String>(
  (_) => '',
  name: 'searchQueryProvider',
);

final searchResultsProvider = FutureProvider<List<StorySummary>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  // 300 ms debounce
  await Future<void>.delayed(const Duration(milliseconds: 300));

  // Check if query changed during debounce.
  final currentQuery = ref.read(searchQueryProvider);
  if (currentQuery != query) return [];

  return ref.read(storyRepositoryProvider).searchStories(query);
}, name: 'searchResultsProvider');

// ---------------------------------------------------------------------------
// Theme / Filter state
// ---------------------------------------------------------------------------

final selectedThemeProvider = StateProvider<String?>(
  (_) => null,
  name: 'selectedThemeProvider',
);

final activeFiltersProvider = StateProvider<StoryFilters>(
  (_) => const StoryFilters(),
  name: 'activeFiltersProvider',
);

// ---------------------------------------------------------------------------
// Single story provider (for detail screen)
// ---------------------------------------------------------------------------

final storyByIdProvider =
    FutureProvider.family<StorySummary?, String>((ref, storyId) {
  return ref.read(storyRepositoryProvider).getStoryById(storyId);
}, name: 'storyByIdProvider');

// ---------------------------------------------------------------------------
// Progress for current kid
// ---------------------------------------------------------------------------

final kidProgressStreamProvider =
    StreamProvider<List<StoryProgress>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final profile = ref.watch(activeKidProfileProvider);

  if (user == null || profile == null) return Stream.value([]);

  return ref
      .read(progressRepositoryProvider)
      .getAllProgress(user.uid, profile.id);
}, name: 'kidProgressStreamProvider');

final storyProgressProvider =
    FutureProvider.family<StoryProgress?, String>((ref, storyId) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final profile = ref.watch(activeKidProfileProvider);
  if (user == null || profile == null) return null;

  return ref
      .read(progressRepositoryProvider)
      .getProgress(user.uid, profile.id, storyId);
}, name: 'storyProgressProvider');
