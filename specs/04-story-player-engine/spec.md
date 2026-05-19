# Spec 4: Story Player Engine

| Field | Value |
|-------|-------|
| **Feature** | Story Player Engine |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | MVP |
| **Features Covered** | #6 Branching Engine, #7 Audio Sync, #8 SVG Rendering, #9 Illustrated Choices, #14e Haptic Feedback, #14f Page Turn Transitions |
| **Estimated Effort** | ~62h (8 days) |

---

## Overview

The heart of TaleTrail — an immersive full-screen story player with SVG illustrations, synced audio narration, text displayed on a parchment panel, illustrated branching choices, haptic feedback, and animated page turn transitions.

### Acceptance Criteria

1. Illustration fills 60-70% of screen (top), text on semi-transparent parchment panel (bottom 30-40%).
2. SVG rendering via `flutter_svg`, edge-to-edge, with raster image fallback for non-SVG assets.
3. Audio auto-plays per step. Play/pause controls. Speaking indicator animation. Buffer <2s on 4G.
4. 2-4 illustrated choice buttons appear after audio completes (or early reveal on tap).
5. Haptic feedback (light impact) on choice tap. Page turn: cross-fade + parallax shift (600ms, easeInOutCubic).
6. Back button navigates to previous step. Progress trail at top. Ending steps show "The End" with celebration trigger.

---

## Architecture

### Player State

```dart
class StoryPlayerState {
  final StoryTree storyTree;
  final String currentStepId;
  final List<String> stepHistory;
  final Map<String, String> choicesMade;
  final bool isLoading;
  final bool isAudioPlaying;
  final bool choicesRevealed;
  final double audioProgress;
  final String? error;
}
```

### Key Widgets

| Widget | File | Responsibility |
|--------|------|---------------|
| `StoryPlayerScreen` | `story_player_screen.dart` | Full-screen Stack orchestrating all panels |
| `IllustrationPanel` | `illustration_panel.dart` | SVG/raster image (top 60-70%) |
| `ParchmentTextPanel` | `parchment_text_panel.dart` | Semi-transparent text overlay (bottom 30-40%) |
| `AudioControls` | `audio_controls.dart` | Play/pause floating pill |
| `SpeakingIndicator` | `speaking_indicator.dart` | 3 bouncing dots during narration |
| `ChoiceButtonsPanel` | `choice_buttons_panel.dart` | Container for branching choices |
| `IllustratedChoiceButton` | `illustrated_choice_button.dart` | Individual choice: pill + label + optional SVG icon |
| `ProgressTrail` | `progress_trail.dart` | Horizontal dotted path with fork indicators |
| `StepTransition` | `step_transition.dart` | Page turn animation (cross-fade + parallax) |

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Story tree models | JSON deserialization for StoryTree, StoryStep, StoryChoice. `Map<String, StoryStep>` for O(1) step lookup by ID. | 3h |
| 2 | Player repository | Fetch story tree from API, cache in memory + Hive for offline. | 4h |
| 3 | Player state provider | Riverpod `StateNotifier`: `loadStory()`, `selectChoice()`, `goBack()`, `revealChoices()`. Manages step history and choice tracking. | 6h |
| 4 | Audio player provider | `just_audio` wrapper: play/pause/resume/stop, position/duration streams, buffering state, error handling. | 6h |
| 5 | Player screen | Full-screen `Stack` layout: illustration panel, parchment panel, progress trail, audio controls. Orchestrates sub-widgets. | 6h |
| 6 | Illustration panel | `flutter_svg` as primary renderer, `Image.network` as fallback for raster images, shimmer loading placeholder. | 4h |
| 7 | Parchment text panel | Semi-transparent overlay with paper texture background. Scrollable text. Expand/collapse gesture. | 4h |
| 8 | Audio controls | Floating pill widget: play/pause toggle + speaking indicator (3 bouncing dots animated). | 4h |
| 9 | Choice buttons panel | Staggered slide-up animation for 2-4 choices. Each choice: rounded pill with label + optional SVG icon. | 6h |
| 10 | Haptic feedback | `HapticFeedback.lightImpact()` on choice button tap. | 0.5h |
| 11 | Page turn transition | `AnimatedSwitcher` with custom transition: simultaneous cross-fade + parallax offset shift, 600ms duration, `Curves.easeInOutCubic`. | 6h |
| 12 | Choice reveal animation | Staggered slide-up from bottom, scale 0.8→1.0 with spring physics. Triggered after audio ends or on tap. | 3h |
| 13 | Progress trail | Horizontal dotted path widget. Fork indicators at decision points. Current position with glow effect. | 4h |
| 14 | Back navigation | Pop from `stepHistory` stack, restore previous step state, replay audio from beginning. | 2h |
| 15 | Ending handling | Detect `isEnding` flag. Display ending title, "The End" screen. Trigger completion celebration. Show "Read Again" / "Back to Library" buttons. | 3h |
| 16 | Audio error recovery | Retry audio load 2x with exponential backoff. On final failure, fallback to text-only mode with user notification. | 2h |

### Dependencies

`flutter_svg`, `just_audio`, `audio_session`, `cached_network_image`, `shimmer`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| SVG fails to load | Fall back to raster `Image.network`. If both fail, show illustrated error placeholder. |
| Audio fails to load | Retry 2x with backoff. Fallback to text-only mode. Show "Audio unavailable" indicator. |
| Phone call interrupts | `audio_session` integration: pause on interruption, resume when call ends. |
| Rapid choice tapping | 600ms debounce on choice selection. Ignore taps during page transition. |
| Back button at root step | Show exit confirmation dialog: "Leave this story?" |
| Device rotation | Lock to portrait orientation for story player. |
| Offline with uncached audio | Show download prompt: "Download this story for offline reading." |
| Very long transcript text | Parchment panel scrollable with expand/collapse. Max height 40% of screen. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Player state transitions: load → play → choose → navigate. Audio state machine. Step history push/pop. |
| **Widget** | Illustration fallback rendering. Choice button count matches data. Parchment scroll behavior. |
| **Integration** | Full flow: load story → play audio → make choice → transition → reach ending. |
| **Golden** | Screenshot tests for player layout at different screen sizes. |

---

## Effort Estimate

**Total: ~62h (8 days)**
