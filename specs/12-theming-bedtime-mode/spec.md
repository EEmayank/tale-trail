# Spec 12: Theming & Bedtime Mode

| Field | Value |
|-------|-------|
| **Feature** | Theming & Bedtime Mode |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | Post-MVP |
| **Features Covered** | #34 Bedtime Mode, #35 Sleep Timer, #36 Dynamic Theme System, #38 Cultural Festival Themes, #50 Ambient Particles |
| **Estimated Effort** | ~46h (6 days) |

---

## Overview

Per-story dynamic color theming driven by CMS `colorAccent`, immersive bedtime mode (navy/gold palette, schedulable), sleep timer with audio fade-out and auto-bookmark, cultural festival overlays (Diwali, Holi, Christmas), and ambient particle effects (leaves, stars, fireflies) matched to story themes.

### Acceptance Criteria

1. **Dynamic Theme:** Story player adapts parchment tint, button colors, progress trail color, and accent elements per story's `colorAccent` from CMS.
2. **Bedtime Mode:** Navy background, gold accents, dimmed illustrations (0.7 opacity). Schedulable (e.g., 8PM-7AM) or manual toggle. Surfaces bedtime-tagged stories in browser.
3. **Sleep Timer:** Options: 10/15/20/30 min. Audio fades out over 30s before timer ends. Screen dims gradually. Auto-bookmark at current step. "Goodnight" overlay with sleeping character.
4. **Festival Themes:** CMS-configurable, date-ranged. Home screen ambient effects (floating diyas for Diwali, colored powder for Holi, snowflakes for Christmas).
5. **Ambient Particles:** Theme-matched floating particles (forest → leaves, space → stars, ocean → bubbles). Lightweight Lottie animations. Toggle in settings. Auto-disable on low-end devices.

---

## Architecture

### Firestore Schema

```
parents/{parentId}/kids/{kidId}/settings/theme
  bedtimeEnabled: boolean
  bedtimeScheduleStart: string ("20:00")
  bedtimeScheduleEnd: string ("07:00")
  ambientParticlesEnabled: boolean

config/festivals
  activeFestivals: array<{
    id: string,
    name: string,
    particleType: string,     // "diyas", "colors", "snowflakes"
    startDate: timestamp,
    endDate: timestamp,
    accentColor: string
  }>
```

### Theme Color System

```dart
class StoryTheme {
  final Color accent;         // From story colorAccent
  final Color parchmentTint;  // Derived: accent at 10% opacity
  final Color buttonPrimary;  // Derived: accent
  final Color buttonText;     // Derived: white or dark based on accent luminance
  final Color trailColor;     // Derived: accent at 60% opacity
}

class BedtimeTheme extends StoryTheme {
  // Override: navy background, gold accent, dimmed illustrations
  static const background = Color(0xFF1A1A2E);
  static const accent = Color(0xFFD4AF37);
}
```

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Theme color system | `StoryTheme` class deriving parchment tint, button colors, trail color from hex accent. Luminance-based text contrast. | 3h |
| 2 | Dynamic theme provider | Riverpod provider: load story's `colorAccent`, compute `StoryTheme`, expose to player widgets. | 3h |
| 3 | Apply theme to player | Wire `StoryTheme` colors into parchment panel, choice buttons, progress trail, audio controls. | 3h |
| 4 | Bedtime theme | `BedtimeTheme` class: navy backgrounds, gold accents, illustration dim overlay (0.7 opacity). | 2h |
| 5 | Bedtime provider + schedule | Riverpod provider: manual toggle + schedule check (compare current time to start/end). Persist to Firestore. | 4h |
| 6 | Bedtime toggle UI | Toggle in parent settings. Schedule time pickers. Visual preview of bedtime palette. | 2h |
| 7 | Bedtime story surfacing | Filter/prioritize bedtime-tagged stories when bedtime mode active. "Bedtime Stories" section in browser. | 2h |
| 8 | Sleep timer sheet | Bottom sheet: 10/15/20/30 min options. Active timer display with countdown. Cancel button. | 3h |
| 9 | Sleep timer provider | Countdown timer. At T-30s: begin audio volume fade (1.0 → 0.0 over 30s). Screen brightness dim. Auto-save progress/bookmark. | 5h |
| 10 | Goodnight screen | Full-screen overlay: sleeping character SVG/Lottie, "Goodnight!" text, soft fade-in. Auto-dismiss after 5s or tap. | 2h |
| 11 | Ambient particles widget | Lightweight particle system: random spawn positions, gentle float animation, theme-matched assets (Lottie or custom painter). | 4h |
| 12 | Story-matched particles | Map story themes to particle types: forest → leaves, space → stars, ocean → bubbles, default → fireflies. | 2h |
| 13 | Festival provider | Load active festivals from Firestore. Date-range check. Expose current festival theme. | 2h |
| 14 | Festival overlay | Home screen ambient particles per active festival (diyas, colors, snowflakes). Subtle, non-intrusive. | 3h |
| 15 | Performance optimization | Frame rate monitoring. Auto-disable particles on low-end devices (< 30fps sustained). Settings toggle. | 3h |

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Bedtime schedule across midnight | Handle wrap-around: 8PM-7AM means active if hour >= 20 OR hour < 7. |
| Sleep timer + phone call | Pause timer during call. Resume after. |
| Device brightness API unavailable | Skip screen dimming. Audio fade still works. |
| Multiple festivals overlapping | Show particles for highest-priority festival only. |
| Low-end device performance | Auto-detect sustained low FPS. Disable particles. Show toggle in settings. |
| Invalid colorAccent from CMS | Fallback to default warm accent (#8B7355). Log warning. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Theme color derivation from hex. Bedtime schedule check logic. Sleep timer countdown accuracy. |
| **Widget** | Dynamic theme applied to player widgets. Bedtime mode visual differences. Particle rendering. |
| **Manual** | Sleep timer full flow (fade + dim + bookmark). Festival overlay aesthetics. Performance on budget Android. |

---

## Effort Estimate

**Total: ~46h (6 days)**
