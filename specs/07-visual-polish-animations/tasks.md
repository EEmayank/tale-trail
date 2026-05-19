# Tasks: Visual Polish & Animations

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 13 |
| **Total Estimated Effort** | ~27h |
| **Phase** | MVP |
| **Sprint** | 9-10 |
| **Status** | 🚧 Partially Complete (5 done, 8 pending) |

---

## Phase 1: Foundation (~6h)

- [x] **Task 1:** Animation constants — Standard durations in `AppConstants`: `shortAnimation` (200ms), `mediumAnimation` (400ms), `longAnimation` (600ms). `Curves.easeInOutCubic` used consistently in router transitions, player transitions, and choice reveal. *(1h)*
- [ ] **Task 2:** BouncyTap widget — Reusable wrapper: `onTapDown` scales to 0.95, `onTapUp`/`onTapCancel` springs back to 1.0 using `SpringSimulation`. Respects accessibility guard. *(3h)* — **Not implemented** as standalone widget; scale animation baked into `TaleButton` and `StoryCard` individually.
- [ ] **Task 3:** AnimatedScaleButton — Extend `BouncyTap` with ink splash ripple overlay and optional `HapticFeedback.selectionClick()`. *(2h)* — **Not implemented** as standalone; covered inline per widget.

## Phase 2: Splash Screen (~4h)

- [x] **Task 4:** Splash screen — `splash_screen.dart`: full-screen Lottie animation (`assets/animations/splash.json`), min 2s display, "Still loading..." message after 5s timeout, navigates to `initResult.initialRoute`. Firebase init + auth check happen concurrently during this window. *(4h)*

## Phase 3: Illustrated Empty States (~7h)

- [x] **Task 5:** Empty state base widget — `illustrated_empty_state.dart`: reusable `IllustratedEmptyState` with Lottie/SVG slot (200px), title (`headlineMedium`), subtitle (`bodyMedium` warmGrey500), optional CTA widget. Consistent padding and sizing. *(2h)*
- [ ] **Task 6:** Empty state: Offline — "Lost in the forest" with fox + broken compass SVG. "No internet connection" + "Try Again" button. *(1h)* — **Pending** SVG assets.
- [ ] **Task 7:** Empty state: Empty shelf — "Sweet dreams" with sleeping fox on bookshelf SVG. "No stories downloaded yet" + "Browse Stories" button. *(1h)* — **Pending** SVG assets.
- [ ] **Task 8:** Empty state: Loading — "On the way" with walking character + lantern SVG. "Loading your stories..." *(1h)* — **Pending** SVG assets.
- [ ] **Task 9:** Empty state: No results — "Hmm..." with curious owl + magnifying glass SVG. *(1h)* — **Pending** SVG assets.
- [ ] **Task 10:** Empty state: Error — "Oops!" with tangled yarn ball SVG. "Something went wrong" + "Try Again" button. *(1h)* — **Pending** SVG assets.

## Phase 4: Avatar Animation (~2h)

- [ ] **Task 11:** Avatar wiggle animation — `AnimationController.repeat()` with Y translate (±3px) and rotation (±2°). Staggered start offsets per avatar index (index × 0.3s). 2s cycle duration. *(2h)* — **Not implemented yet.**

## Phase 5: Global Application (~4h)

- [x] **Task 12:** Apply scale animations globally — Scale animations applied to `TaleButton` (AnimationController 1.0→0.96), `StoryCard` (GestureDetector 1.0→0.95), `IllustratedChoiceButton` (scale on tap). *(3h)*
- [ ] **Task 13:** Accessibility guard — `MediaQuery.of(context).disableAnimations` check. Skip all custom animations when enabled. *(1h)* — **Not implemented yet.**
