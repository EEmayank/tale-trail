# Spec 10: Gamification & Collections

| Field | Value |
|-------|-------|
| **Feature** | Gamification & Collections |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | Post-MVP |
| **Features Covered** | #27 Story Endings Collection, #28 Visual Story Map, #29 Reading Streaks, #30 Achievement Badges |
| **Estimated Effort** | ~56h (7 days) |

---

## Overview

Retention mechanics to drive replay and daily engagement: collect story endings ("3 of 5 discovered!"), treasure-map trail showing branching path in the player, consecutive-day reading streaks with visual flame, and achievement badges for milestones.

### Acceptance Criteria

1. **Endings Collection:** "X of Y" progress ring per story. Grid of ending cards — unlocked show illustration + title, locked show silhouette + "???".
2. **Story Map:** Horizontal dotted trail in story player. Fork indicators at decision points. Visited vs unvisited paths distinguished. Current position glows.
3. **Reading Streaks:** Consecutive-day tracking. Lottie flame visual that grows with streak length. Resets on missed day. Shown on profile screen.
4. **Achievement Badges:** Unlock milestones — First Story, Explorer (3 genres), Completionist (all endings of a story), Bookworm (10 stories), Week Warrior (7-day streak), Night Owl (3 bedtime stories). Celebration overlay on unlock.

---

## Architecture

### Firestore Schema

```
parents/{parentId}/kids/{kidId}/endings/{storyId}
  discoveredEndings: array<string>   // ending step IDs
  totalEndings: number
  lastDiscoveredAt: timestamp

parents/{parentId}/kids/{kidId}/streak
  currentStreak: number
  longestStreak: number
  lastReadDate: string (YYYY-MM-DD)
  streakHistory: array<string>       // date strings

parents/{parentId}/kids/{kidId}/badges/{badgeId}
  unlockedAt: timestamp
  seen: boolean                      // dismiss celebration
```

### Badge Definitions

| Badge | Condition | Icon Theme |
|-------|-----------|------------|
| First Story | Complete 1 story | Open book |
| Explorer | Complete stories in 3 different genres | Compass |
| Completionist | Discover all endings of any story | Crown |
| Bookworm | Complete 10 stories | Stack of books |
| Week Warrior | Achieve 7-day reading streak | Shield + flame |
| Night Owl | Complete 3 stories tagged "bedtime" | Owl + moon |

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Endings repository | Firestore CRUD for ending records. Add/check ending. Count. | 3h |
| 2 | Endings collection screen | Grid layout: unlocked endings (illustration + title), locked (silhouette + "???"). Progress ring header showing X/Y. | 6h |
| 3 | Player→Endings integration | On ending step, record ending. Detect new vs repeated ending. Trigger celebration for new. | 2h |
| 4 | Story map trail (enhanced) | Scrollable horizontal trail with nodes for steps, fork lines for choices, visited/unvisited path coloring, pulsing glow on current position. | 8h |
| 5 | Story map provider | Compute visible map from story tree + current path history. Determine fork visibility and visited state. | 4h |
| 6 | Streak repository | Compare `lastReadDate`: same day = no-op, yesterday = increment streak, older = reset to 1. Update `longestStreak`. | 3h |
| 7 | Streak widgets | Lottie flame animation (scales visually with streak length). Streak counter text. Profile section integration. | 4h |
| 8 | Streak provider | Load streak on profile selection. Record reading activity. Expose streak state. | 2h |
| 9 | Badge definitions | Static list of badge configs: id, name, description, SVG icon path, unlock condition type, threshold. | 2h |
| 10 | Badge evaluator | Condition checking logic per badge type. Accepts current kid stats, returns newly unlocked badges. | 4h |
| 11 | Badge repository | Firestore CRUD for badge records. Check unlock status. Mark as seen. | 2h |
| 12 | Badge showcase screen | Grid layout: unlocked badges (colored + unlock date), locked badges (grayscale + hint text). | 4h |
| 13 | Badge unlock overlay | Scale-in animation, sparkles, confetti, badge name + description, dismiss button. | 4h |
| 14 | Event→Badge integration | After story completions, new endings, and streak updates: evaluate all badge conditions, trigger unlock overlay for any new badges. | 3h |

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Timezone changes affect streak | Use device local date. Consistent timezone per profile. |
| Story endings count changes (CMS update) | Re-sync `totalEndings` from server. Don't revoke discovered endings. |
| Badge condition met offline | Queue badge unlock. Celebrate on next app open. |
| Repeated ending discovery | Show "Already discovered" toast. No duplicate celebration. |
| Streak across midnight | Reading session that spans midnight counts for the start date. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Streak logic: same day, next day, gap day, midnight boundary. Badge evaluator conditions. Ending deduplication. |
| **Widget** | Endings grid: locked vs unlocked rendering. Streak flame scaling. Badge overlay animation. |
| **Integration** | Complete story → ending recorded → badge evaluated → celebration shown → profile reflects changes. |

---

## Effort Estimate

**Total: ~56h (7 days)**
