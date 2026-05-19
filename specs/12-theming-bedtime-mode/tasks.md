# Tasks: Theming & Bedtime Mode

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 15 |
| **Total Estimated Effort** | ~46h |
| **Phase** | Post-MVP |
| **Sprint** | 15-16 |
| **Status** | 🚧 Partially Complete (3 tasks done, 12 pending) |

---

## Phase 1: Dynamic Theme System (~9h)

- [x] **Task 1:** Theme color system — `StoryPalette` class in `app_theme.dart` (accentColor, backgroundColor, textColor). `TaleColors` with full brand palette including story accent colors (forestGreen, oceanBlue, spacePurple, desertOrange, mountainGrey, sunsetPink). *(3h)*
- [ ] **Task 2:** Dynamic theme provider — Riverpod provider that loads story's `colorAccent`, computes `StoryTheme` instance, exposes theme to all player child widgets. *(3h)* — **Partial:** `themeModeProvider` (StateProvider<AppThemeMode>) exists; per-story dynamic theme in player not yet wired.
- [ ] **Task 3:** Apply theme to player — Wire `StoryTheme` colors into parchment panel background tint, choice button fills, progress trail color, and audio controls accent. *(3h)* — **Not implemented yet.**

## Phase 2: Bedtime Mode (~10h)

- [x] **Task 4:** Bedtime theme — `TaleTheme.bedtimeTheme`: nightNavy (#1B2838) background, warmGold accents, full `ThemeData` with dark colorScheme. Available as `AppThemeMode.bedtime`. *(2h)*
- [ ] **Task 5:** Bedtime provider + schedule — Riverpod provider supporting manual toggle and time-based schedule. Persist preferences to Firestore. *(4h)* — **Not implemented yet.** `themeModeProvider` exists but no schedule logic.
- [ ] **Task 6:** Bedtime toggle UI — Toggle switch in parent settings. Schedule start/end time pickers. Visual preview swatch. *(2h)* — **Not implemented yet.**
- [ ] **Task 7:** Bedtime story surfacing — Filter and prioritize "bedtime" tagged stories in browser when bedtime mode active. "Bedtime Stories" section at top. *(2h)* — **Not implemented yet.**

## Phase 3: Sleep Timer (~10h)

- [ ] **Task 8:** Sleep timer sheet — Bottom sheet with duration options (10/15/20/30 min buttons). Active timer countdown. Cancel button. *(3h)* — **Not implemented yet.**
- [ ] **Task 9:** Sleep timer provider — Countdown timer. At T-30s: fade audio volume to 0.0 over 30s. Dim screen brightness. Auto-save progress. *(5h)* — **Not implemented yet.**
- [ ] **Task 10:** Goodnight screen — Full-screen overlay: sleeping character animation, "Goodnight!" text, fade-in, auto-dismiss after 5s. *(2h)* — **Not implemented yet.**

## Phase 4: Ambient Particles (~6h)

- [ ] **Task 11:** Ambient particles widget — Lightweight particle system: random spawn, gentle downward float, configurable particle asset. *(4h)* — **Not implemented yet.**
- [ ] **Task 12:** Story-matched particles — Map story themes to particle types: forest → leaves, space → stars, ocean → bubbles, default → fireflies. *(2h)* — **Not implemented yet.**

## Phase 5: Festival Themes & Performance (~8h)

- [ ] **Task 13:** Festival provider — Load active festivals from Firestore `config/festivals`. Check current date against festival date ranges. *(2h)* — **Not implemented yet.**
- [ ] **Task 14:** Festival overlay — Render festival particles: floating diyas (Diwali), powder puffs (Holi), snowflakes (Christmas). *(3h)* — **Not implemented yet.**
- [ ] **Task 15:** Performance optimization — Monitor frame rate. Auto-disable particles < 30fps. Manual toggle in settings. *(3h)* — **Not implemented yet.**
