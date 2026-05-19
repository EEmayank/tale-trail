# Spec 7: Visual Polish & Animations

| Field | Value |
|-------|-------|
| **Feature** | Visual Polish & Animations |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | MVP |
| **Features Covered** | #14a Animated Splash Screen, #14b Bouncy Micro-Interactions, #14c Illustrated Empty States, #14d Avatar Idle Wiggle |
| **Estimated Effort** | ~27h (3-4 days) |

---

## Overview

Visual polish that transforms the app from functional to magical storybook. Animated splash screen (Lottie forest scene), spring-physics bounce on all tappable elements, illustrated empty/error/loading states, and gentle avatar idle wiggle on the profile selector.

### Acceptance Criteria

1. **Splash:** Full-screen Lottie animation (forest path, flickering lanterns, drifting fireflies, logo fade-in). Duration 2-3s. No loading spinner — the animation IS the loading state.
2. **Bouncy taps:** All tappable elements use spring bounce (scale 0.95→1.0, `SpringSimulation`). Duration 200-400ms. Easing: `Curves.easeInOutCubic`.
3. **Empty states:** 5 illustrated SVG states: empty shelf (sleeping fox), no internet (lost in forest), loading (walking character), no results (curious owl), error (tangled yarn).
4. **Avatar wiggle:** Gentle idle animation on profile selector: ±3px Y translate, ±2° rotation, 2s cycle, staggered start offsets per avatar.
5. **Accessibility:** Respect `MediaQuery.disableAnimations` — skip all animations when reduced motion is enabled.

---

## Architecture

### Reusable Components

| Component | Description |
|-----------|-------------|
| `AnimationConstants` | Standard durations, curves, spring configs. Accessibility guard mixin. |
| `BouncyTap` | Reusable wrapper widget: tap down → scale 0.95, tap up → scale 1.0 with spring. |
| `AnimatedScaleButton` | `BouncyTap` + ink splash + optional haptic feedback. |
| `IllustratedEmptyState` | Base widget: SVG illustration, title text, subtitle text, optional action button. |
| `AvatarWiggle` | `AnimationController.repeat` with Y translate + rotation transform. |

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Animation constants | Define standard durations, curves, spring configs. Accessibility guard checking `MediaQuery.disableAnimations`. | 1h |
| 2 | BouncyTap widget | Reusable tap wrapper: `onTapDown` → `AnimatedScale` to 0.95, `onTapUp`/`onTapCancel` → spring back to 1.0 using `SpringSimulation`. | 3h |
| 3 | AnimatedScaleButton | Wrap `BouncyTap` with ink splash ripple effect and optional `HapticFeedback.selectionClick()`. | 2h |
| 4 | Splash screen | Full-screen Lottie animation player. During animation: initialize Firebase, check auth state. Navigate on animation complete (minimum 2s, maximum 5s timeout). | 4h |
| 5 | Empty state base widget | Reusable `IllustratedEmptyState`: SVG asset, title, subtitle, optional `CTA` button. Consistent padding/sizing. | 2h |
| 6 | Empty state: Offline | "Lost in the forest" — fox with a broken compass SVG. Title: "No internet connection". Button: "Try Again". | 1h |
| 7 | Empty state: Empty shelf | "Sweet dreams" — sleeping fox on empty bookshelf SVG. Title: "No stories downloaded yet". Button: "Browse Stories". | 1h |
| 8 | Empty state: Loading | "On the way" — character walking with lantern SVG. Title: "Loading your stories...". No button. | 1h |
| 9 | Empty state: No results | "Hmm..." — curious owl with magnifying glass SVG. Title: "No stories found". Subtitle: "Try different search terms". | 1h |
| 10 | Empty state: Error | "Oops!" — tangled yarn ball SVG. Title: "Something went wrong". Button: "Try Again". | 1h |
| 11 | Avatar wiggle animation | `AnimationController.repeat()` with `Tween` for Y translate (±3px) and rotation (±2°). Staggered start offsets per avatar index. 2s cycle. | 2h |
| 12 | Apply BouncyTap globally | Replace all tappable elements across existing screens with `BouncyTap`/`AnimatedScaleButton` wrappers. | 3h |
| 13 | Accessibility guard | Check `MediaQuery.of(context).disableAnimations`. Skip all custom animations. Provide instant state changes instead. | 1h |

### Dependencies

`lottie`, `flutter_svg`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Lottie file fails to load | Fall back to static SVG splash image with simple fade-in. |
| Low-end device (poor animation perf) | Cap animations at 30fps. Reduce spring iterations. |
| Splash timeout | Maximum 5s before forced navigation regardless of animation state. |
| Reduced motion accessibility setting | All animations skipped. Instant state transitions. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Animation constants values. Accessibility guard flag detection. |
| **Widget** | BouncyTap scale behavior on tap down/up. Empty state rendering with all variants. Splash navigation timing. |
| **Golden** | Screenshot tests for each empty state at standard screen sizes. |
| **Manual** | Animation smoothness on low-end Android. Reduced motion behavior verification. |

---

## Effort Estimate

**Total: ~27h (3-4 days)**
