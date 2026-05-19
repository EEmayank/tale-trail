# Spec 5: Story Browser, Progress & Smart Defaults

| Field | Value |
|-------|-------|
| **Feature** | Story Browser, Progress & Smart Defaults |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | MVP |
| **Features Covered** | #5 Story Browser, #10 Story Progress Persistence, #12 Story Completion Celebration, #13 Smart Defaults for New Users, #14g "Continue the Adventure" |
| **Estimated Effort** | ~60h (7-8 days) |

---

## Overview

Discovery layer for browsing stories, tracking per-kid progress, celebrating completions, onboarding new users with a curated first story, and welcoming returning users with story context.

### Acceptance Criteria

1. Sections: "Continue Reading", "Start Here" (new users), "New", "Popular", theme categories.
2. Story cards: cover image, title, age badge, duration. Search with debounce (300ms). Filters: age, language, theme.
3. Per-kid progress: current step, choices made, percentage complete. Syncs to Firestore + local Hive cache.
4. Completion: confetti/Lottie overlay + "The End" card with ending title.
5. First-time kid: curated "Start Here" story matched to age. Returning mid-story: "Welcome back! You were about to..."
6. Parent tooltip tour (3 dismissible tooltips on first open).

---

## Architecture

### Firestore Schema

**Progress Collection:**
```
parents/{parentId}/kids/{kidId}/progress/{storyId}
  storyId: string
  storyTitle: string
  currentStepId: string
  choicesMade: map<string, string>
  stepsVisited: array<string>
  percentComplete: number (0-100)
  isComplete: boolean
  endingTitle: string | null
  startedAt: timestamp
  updatedAt: timestamp
  completedAt: timestamp | null
```

**Preferences:**
```
parents/{parentId}/kids/{kidId}/settings/preferences
  hasCompletedFirstStory: boolean
  tooltipTourSeen: boolean
  lastActiveStoryId: string | null
  lastActiveStepContext: string | null
```

### Key Providers

- `storyBrowserProvider` — State per section (continue, startHere, new, popular, byTheme)
- `storyProgressProvider` — Per-kid progress CRUD with offline sync
- `smartDefaultsProvider` — Age matching, first-story tracking, tooltip state

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Story summary model | Lightweight list model: id, title, coverUrl, age, themes, isFree, duration | 1h |
| 2 | Browser repository | Paginated API fetch, Hive cache, search, filters | 4h |
| 3 | Browser provider | State per section (continue, startHere, new, popular, byTheme) | 4h |
| 4 | Browser screen | ScrollView with horizontal sections, pull-to-refresh | 6h |
| 5 | Story card widget | Cover image, title, badges (age, duration, free/premium), bounce on tap | 4h |
| 6 | Story section widget | Horizontal ListView with "See All" navigation | 2h |
| 7 | Theme tab bar | Illustrated SVG tabs (forest, space, ocean, etc.) | 3h |
| 8 | Search screen | Debounced text input (300ms), results list, recent searches, empty state | 4h |
| 9 | Filter sheet | Bottom sheet: age range slider, language multi-select, theme chips | 3h |
| 10 | Story detail screen | Large cover, full metadata, "Start"/"Continue" button, download button, ending count | 4h |
| 11 | Progress repository | CRUD in Firestore subcollection + Hive offline cache with sync | 4h |
| 12 | Progress provider | `saveProgress()` on each step, `completeStory()`, offline queue sync | 4h |
| 13 | Continue reading banner | Cover thumbnail, title, context text ("You were about to..."), tap to resume | 3h |
| 14 | Start Here card | Age-matched curated free story with prominent animated card | 2h |
| 15 | Smart defaults provider | Age-to-story matching, first-story tracking, tooltip state management | 2h |
| 16 | Completion celebration | Confetti/Lottie overlay, ending title display, "Read Again"/"Explore Endings"/"Back" buttons | 5h |
| 17 | Tooltip tour | 3 sequential dismissible tooltips using `showcaseview` package | 3h |
| 18 | Player→Progress integration | Save progress on each step transition, complete on ending, save on app exit/background | 2h |

### Dependencies

`hive`, `confetti`/`lottie`, `showcaseview`, `easy_debounce`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| No stories available | Illustrated empty state ("No stories yet — check back soon!") |
| All stories are premium | Show lock badges on cards, "Ask a grown-up" message on tap |
| Progress sync conflict | Last-write-wins strategy with timestamp comparison |
| Story removed server-side | Clear local progress, remove from "Continue Reading" |
| Offline with no cached data | Show download prompt with illustrated empty state |
| Search returns no results | Illustrated "No results" state with search suggestions |
| Search pagination | Lazy-load more results on scroll |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Browser section assembly logic. Progress model serialization roundtrip. Age-to-story matching. |
| **Widget** | Story card rendering with all badge variants. Search debounce behavior. Celebration overlay display. |
| **Integration** | Browse → tap story → play → complete → verify progress reflected in browser and "Continue Reading" section. |

---

## Effort Estimate

**Total: ~60h (7-8 days)**
