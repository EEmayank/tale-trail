# Tasks: Story Browser, Progress & Smart Defaults

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 18 |
| **Total Estimated Effort** | ~60h |
| **Phase** | MVP |
| **Sprint** | 5-6 |
| **Status** | 🚧 Mostly Complete (3 tasks pending) |

---

## Phase 1: Data Layer (~9h)

- [x] **Task 1:** Story summary model — `story_summary.dart`: id, title, coverUrl, description, ageMin, ageMax, themes, isFree, isPremium, durationMinutes, language, endingCount, isNew, isPopular, colorAccent. `fromJson`/`toJson`/`fromFirestore`. *(1h)*
- [x] **Task 2:** Browser repository — `story_repository.dart`: Firestore fetch with filters. Falls back to 6 mock stories (Clever Fox, Raja and the Stars, Ocean Dream, Tenali's Clever Plan, Magic Forest, Journey to the Moon). `fetchStories`, `searchStories`, `getFeaturedStories`, `getStoriesForKid(age)`, `getNewStories`, `getPopularStories`. *(4h)*
- [x] **Task 3:** Browser provider — `story_browser_provider.dart`: `featuredStoriesProvider`, `newStoriesProvider`, `popularStoriesProvider`, `kidsStoriesProvider(int age)`, `inProgressStoriesProvider`, `searchQueryProvider` (StateProvider, debounced 300ms), `selectedThemeProvider`, `activeFiltersProvider` with `StoryFilters` class. *(4h)*

## Phase 2: Browser UI (~22h)

- [x] **Task 4:** Browser screen — `story_browser_screen.dart`: `CustomScrollView` with `SliverAppBar`, `ThemeTabBar`, `ContinueReadingBanner` (if in-progress stories exist), `StorySection` rows for new/popular/curated. Pull-to-refresh. Shimmer loading states. *(6h)*
- [x] **Task 5:** Story card widget — `story_card.dart`: 150×220 card with Hero-tagged cover image, bounce animation (scale 1.0→0.95 on tap), `BadgeChip` rows for age/duration/free-premium, optional progress bar, `HapticFeedback.selectionClick()`. *(4h)*
- [x] **Task 6:** Story section widget — `story_section.dart`: `SectionHeader` + horizontal `ListView` with shimmer loading states, "See All" navigates to collection detail or new-this-week. *(2h)*
- [x] **Task 7:** Theme tab bar — `theme_tab_bar.dart` (283 lines): horizontally scrollable `AnimatedContainer` pills for 7 themes (All, Forest, Space, Ocean, Animals, Folklore, Adventure). Tap animation. Updates `selectedThemeProvider`. *(3h)*
- [x] **Task 8:** Search screen — `search_screen.dart`: autofocused `TextField` in `AppBar`, recent searches from SharedPreferences, theme chips for discovery, debounced results via `searchResultsProvider`, `_SearchResultTile` list items. *(4h)*
- [ ] **Task 9:** Filter sheet — Bottom sheet with age range slider, language multi-select, theme chips. Apply/reset actions. *(3h)* — **Not implemented yet.**

## Phase 3: Story Detail & Progress (~15h)

- [x] **Task 10:** Story detail screen — `story_detail_screen.dart`: `CustomScrollView` with `SliverAppBar` (Hero cover, 300px expandedHeight), story info, theme chips, description, endings count, sticky bottom bar with Start/Continue/ReadAgain CTAs based on progress state. *(4h)*
- [x] **Task 11:** Progress repository — `progress_repository.dart`: CRUD to `parents/{parentId}/kids/{kidId}/progress/{storyId}`. Hive cache with Firestore sync. `getAllProgress()` as Stream. `getInProgressStories()`, `getCompletedStories()`. *(4h)*
- [x] **Task 12:** Progress provider — `inProgressStoriesProvider`, save hooks, progress stream in `story_browser_provider.dart`. *(4h)*
- [x] **Task 18:** Player→Progress integration — `StoryPlayerScreen` calls `saveProgress()` on `AppLifecycleState.paused` and on story ending in `_handleEnding()`. *(2h)*
- [x] **Task 13:** Continue reading banner — `continue_reading_banner.dart`: horizontal card with thumbnail, title, "X% complete" progress bar and percentage, play button. Taps navigates to `/stories/:storyId/play`. *(3h)*

## Phase 4: Smart Defaults & Onboarding (~7h)

- [ ] **Task 14:** Start Here card — Age-matched curated free story displayed as prominent animated card for new users. *(2h)* — **Not implemented yet.**
- [ ] **Task 15:** Smart defaults provider — Age-to-story matching logic, first-story completion tracking, tooltip tour state. *(2h)* — **Not implemented yet.**
- [ ] **Task 17:** Tooltip tour — 3 sequential dismissible tooltips using `showcaseview` package (story cards, search, profile). *(3h)* — **Not implemented yet.**

## Phase 5: Celebration (~5h)

- [x] **Task 16:** Completion celebration — `completion_celebration.dart`: `ConfettiController` (explosive, 6 brand colors), `SlideTransition` from `Offset(0,1)` with `elasticOut`, "✨ The End ✨" overlay, ending title, 3 action buttons (Read Again, Explore Endings, Back to Library). *(5h)*
