# Tasks: Gamification & Collections

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 14 |
| **Total Estimated Effort** | ~56h |
| **Phase** | Post-MVP |
| **Sprint** | 15-16 |
| **Status** | 🚧 Partially Complete (9 tasks done, 5 pending) |

---

## Phase 1: Endings Collection (~11h)

- [ ] **Task 1:** Endings repository — Firestore CRUD for ending discovery records. Methods: `addEnding()`, `getEndings()`, `isEndingDiscovered()`, `getEndingCount()`. *(3h)* — **Not implemented yet.**
- [ ] **Task 2:** Endings collection screen — Grid layout: unlocked endings show illustration thumbnail + title, locked endings show silhouette + "???". Progress ring header showing "X of Y endings discovered". *(6h)* — **Not implemented yet.**
- [ ] **Task 3:** Player→Endings integration — On ending step reached, record ending in repository. Detect new vs repeated discovery. Trigger celebration overlay for new endings. *(2h)* — **Not implemented yet.**

## Phase 2: Story Map Trail (~12h)

- [ ] **Task 4:** Story map trail widget — Scrollable horizontal dotted trail with circular nodes for story steps, forking lines at decision points, visited (solid) vs unvisited (dotted) path coloring, pulsing glow animation on current position. *(8h)* — **Not implemented yet.**
- [ ] **Task 5:** Story map provider — Compute visible map structure from story tree data + current path history. Determine fork visibility, visited/unvisited state, and current position. *(4h)* — **Not implemented yet.**

## Phase 3: Reading Streaks (~9h)

- [x] **Task 6:** Streak repository — `gamification_repository.dart`: `recordDailyRead()`, `getReadingStreak()`. `reading_streak.dart`: `recordRead()` calculates same-day no-op, yesterday = increment, older = reset, updates `longestStreak`. Persists to Firestore. *(3h)*
- [x] **Task 7:** Streak widgets — `streak_display.dart`: flame emoji scales with streak (🔥 for active, fades for 0). Full/compact display modes. Flame color shifts orange/amber for active streaks. `streaks_screen.dart`: 30-day 7-column calendar grid. *(4h)*
- [x] **Task 8:** Streak provider — `gamificationNotifierProvider`: loads streak on profile selection via `readingStreakProvider` FutureProvider, records activity via `checkAndUpdateStreak()`. *(2h)*

## Phase 4: Achievement Badges (~15h)

- [x] **Task 9:** Badge definitions — `achievement.dart`: `AchievementType` enum (9 types: firstStory, storiesRead5/10/25, endingsFound, streakDays7/30, genresExplored3, nightOwl). `Achievement.allAchievements()` returns full catalogue with emoji, description, threshold. *(2h)*
- [x] **Task 10:** Badge evaluator — `gamification_repository.dart`: `recordStoryCompletion()` determines newly unlocked achievements from current stats, returns list of newly earned achievement IDs. *(4h)*
- [x] **Task 11:** Badge repository — `gamification_repository.dart`: `getAchievements()`, `getStats()`, `recordStoryCompletion()` (mutates in-memory, writes with merge). `GamificationException` typed error. *(2h)*
- [x] **Task 12:** Badge showcase screen — `achievements_screen.dart`: `CustomScrollView` + floating `SliverAppBar`, `StreakDisplay`, 3-column `AchievementBadge` grid (earned first, locked after), stats row (total stories, endings, days active). *(4h)*
- [x] **Task 13:** Badge unlock overlay — `completion_celebration.dart`: scale-in `SlideTransition` with `elasticOut`, `ConfettiWidget` (explosive, 6 brand colors), badge display, 3 action buttons. Also: `achievement_badge.dart` with warmGold earned / warmGrey200 locked states. *(4h)*

## Phase 5: Integration (~3h)

- [x] **Task 14:** Event→Badge integration — `GamificationNotifier.recordCompletion()` calls `gamificationRepository.recordStoryCompletion()`, sets `newlyEarnedAchievementsProvider` for overlay trigger, invalidates all gamification providers. *(3h)*
