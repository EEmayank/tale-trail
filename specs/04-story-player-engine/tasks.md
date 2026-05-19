# Tasks: Story Player Engine

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 16 |
| **Total Estimated Effort** | ~62h |
| **Phase** | MVP |
| **Sprint** | 3-4 |
| **Status** | ✅ Complete |

---

## Phase 1: Data & State Layer (~19h)

- [x] **Task 1:** Story tree models — `StoryTree`, `StoryStep`, `StoryChoice` model classes with `fromJson`/`toJson`. `Map<String, StoryStep>` for O(1) step lookup. `getStep(id)` helper on `StoryTree`. *(3h)*
- [x] **Task 2:** Player repository — `player_repository.dart`: checks Hive/local first, then Firestore. Includes `getMockStoryTree()` (6-step branching sample story). `saveProgress()` and `getProgress()` to Firestore subcollection. *(4h)*
- [x] **Task 3:** Player state provider — `PlayerNotifier extends StateNotifier<StoryPlayerState>` with `loadStory()`, `selectChoice()` (push history + load audio), `goBack()` (pop history), `revealChoices()`, `saveProgress()`, `_handleEnding()`. `storyPlayerProvider` exposed. *(6h)*
- [x] **Task 4:** Audio player provider — `AudioNotifier` using `just_audio` `AudioPlayer`. `AudioSession` integration for phone call interruptions. 2x retry with 300ms backoff on error. `audioPlayerProvider` and `audioProgressProvider` streams exposed. *(6h)*

## Phase 2: Core UI Widgets (~18h)

- [x] **Task 5:** Player screen layout — Full-screen `Stack` in `story_player_screen.dart` (628 lines): `IllustrationPanel` top 65%, `ParchmentTextPanel` bottom 40%, `ProgressTrail` overlay, `AudioControls` floating pill, `ChoiceButtonsPanel`, back button. Saves progress on `AppLifecycleState.paused`. Locks orientation to portrait. *(6h)*
- [x] **Task 6:** Illustration panel — `illustration_panel.dart`: `flutter_svg` as primary renderer, `Image.network` / `Image.file` fallback for raster, shimmer loading placeholder, error fallback with landscape icon. *(4h)*
- [x] **Task 7:** Parchment text panel — `parchment_text_panel.dart`: semi-transparent warm overlay, scrollable transcript text, drag handle, expand/collapse gesture, animated height transition. *(4h)*
- [x] **Task 8:** Audio controls — `audio_controls.dart`: floating pill with play/pause toggle + position text. `speaking_indicator.dart`: 3 bouncing dots with staggered 150ms animation. *(4h)*

## Phase 3: Choices & Interaction (~15.5h)

- [x] **Task 9:** Choice buttons panel — `choice_buttons_panel.dart`: container for 2–4 `IllustratedChoiceButton` widgets with staggered `SlideTransition` entrance (80ms delay per button, `Curves.elasticOut`). Rounded pill shape, text label, optional icon. *(6h)*
- [x] **Task 10:** Haptic feedback — `HapticFeedback.lightImpact()` on every choice button tap in `illustrated_choice_button.dart`. *(0.5h)*
- [x] **Task 12:** Choice reveal animation — Staggered slide-up from `Offset(0, 1)` with `elasticOut` spring physics, 80ms stagger per button. Triggered after audio ends or user taps (`revealChoices()`). 600ms debounce on tap to prevent double-fire. *(3h)*
- [x] **Task 14:** Back navigation — `goBack()` in `PlayerNotifier` pops `stepHistory` stack, restores previous step state, triggers audio reload for that step. *(2h)*

## Phase 4: Transitions & Polish (~9.5h)

- [x] **Task 11:** Page turn transition — `AnimatedSwitcher` with `transitionBuilder` in `story_player_screen.dart`: simultaneous `FadeTransition` + `SlideTransition`, 600ms duration, `Curves.easeInOutCubic`. *(6h)*
- [x] **Task 13:** Progress trail — `progress_trail.dart`: horizontal row of step dots connected by lines. Fork dots at decision points. Current position with warmGold background + glow shadow. *(4h)*

## Phase 5: Completion & Error Handling (~5h)

- [x] **Task 15:** Ending handling — Detects `isEnding` flag. Dark overlay with `endingTitle` + "✨ The End ✨" text. "Read Again" / "Back to Library" action buttons. Triggers `CompletionCelebration` (confetti + slide-up card). *(3h)*
- [x] **Task 16:** Audio error recovery — 2x retry with 300ms backoff in `AudioNotifier`. On final failure: `error` set in `AudioState`; UI falls back gracefully (play button disabled, text-only mode). *(2h)*
