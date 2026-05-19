# Spec 15: Player Enhancements

| Field | Value |
|-------|-------|
| **Feature** | Player Enhancements |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | Post-MVP |
| **Features Covered** | #41 Background Story Pre-fetch, #48 Story Soundtrack Mode, #49 Parallax Background Layers, #51 Audio Waveform Indicator |
| **Estimated Effort** | ~44h (5-6 days) |

---

## Overview

Four player enhancements that elevate the reading experience: (1) pre-fetch N+1 step assets to eliminate loading between steps, (2) ambient soundtrack loops per story (forest sounds, ocean waves) with narration ducking, (3) parallax depth with accelerometer-driven multi-layer SVG backgrounds, and (4) a stylized audio waveform indicator during narration. All individually toggleable in settings.

### Acceptance Criteria

1. **Pre-fetch:** While displaying step N, pre-download audio + illustrations for all possible N+1 branches. Cache limit: 10 assets. Clean up when story exits.
2. **Soundtrack:** Per-story ambient audio loop at 30% volume. Ducks to 15% during narration. Toggle on/off. Separate from narration audio player.
3. **Parallax:** 2-3 SVG background layers (foreground, midground, background). Offset driven by device accelerometer via `sensors_plus`. Max ±15px offset. 60fps.
4. **Waveform:** 5-bar animated waveform indicator (randomized heights, accent-colored) shown during audio playback. Replaces or complements speaking dots.

---

## Architecture

### Pre-fetch Flow

```
Step N displayed
  → Identify all choices → get toStepId for each
  → For each next step:
    → Pre-download audioUrl (if not cached)
    → Pre-download illustrationUrl (if not cached)
  → Store in memory cache (max 10 items)
  → On step change: serve from cache → instant transition
  → On story exit: clear pre-fetch cache
```

### Soundtrack System

```dart
class SoundtrackProvider {
  final AudioPlayer _soundtrackPlayer;  // Separate from narration

  // Volume states:
  // - Solo:     0.30 (no narration playing)
  // - Ducked:   0.15 (narration active)
  // - Muted:    0.00 (user toggled off)

  void duck();    // Narration started
  void unduck();  // Narration paused/ended
}
```

### Parallax System

```dart
class ParallaxProvider {
  // Accelerometer input (sensors_plus)
  // Low-pass filter to smooth readings
  // Map to ±15px offset per layer
  // Layer offsets: background ±5px, midground ±10px, foreground ±15px
}
```

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Pre-fetch service | Identify next possible steps from current choices. Pre-download audio + illustration URLs. Memory cache with 10-item limit. | 5h |
| 2 | Pre-fetch provider | Trigger pre-fetch on step display. Serve cached assets on step transition. Cache hit tracking for performance monitoring. | 4h |
| 3 | Pre-fetch cleanup | Clear cache on story exit. Evict oldest items when cache exceeds limit. | 1h |
| 4 | Soundtrack provider | Separate `AudioPlayer` for ambient soundtrack. Loop mode. Volume management: 0.30 (solo), 0.15 (ducked), 0.0 (off). Smooth volume transitions (200ms). | 5h |
| 5 | Soundtrack controls | Toggle button in player UI. Volume indicator. Persist preference per kid profile. | 2h |
| 6 | CMS soundtrack field | Add `soundtrackUrl` field to Story content type in Strapi. Optional audio file for ambient loop. | 1h |
| 7 | Narration↔Soundtrack ducking | When narration starts → duck soundtrack to 15%. When narration pauses/ends → unduck to 30%. Smooth fade transitions. | 3h |
| 8 | Parallax widget | `ParallaxBackground` widget rendering 2-3 SVG layers with offset transforms. Stacked with different parallax factors. | 5h |
| 9 | Parallax provider | Subscribe to `sensors_plus` accelerometer stream. Apply low-pass filter for smooth readings. Map sensor values to ±15px layer offsets. 60fps target. | 4h |
| 10 | CMS illustration layers | Add optional `backgroundLayer` and `foregroundLayer` media fields to StoryStep content type for multi-layer illustrations. | 1h |
| 11 | Audio waveform widget | 5 vertical bars with randomized heights animated at ~10fps. Accent-colored (from story theme). Shown during audio playback, hidden when paused/stopped. | 4h |
| 12 | Settings toggles | Individual on/off toggles for: soundtrack, parallax, waveform. Persist per kid profile. | 2h |
| 13 | Player integration | Wire pre-fetch, soundtrack, parallax, and waveform into story player. Respect feature flag gates. | 4h |

### Dependencies

`sensors_plus`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Pre-fetch on slow network | Non-blocking. If asset isn't cached in time, fall back to standard load with shimmer. |
| Soundtrack file missing | Skip soundtrack silently. Player functions normally without ambient audio. |
| Accelerometer unavailable (emulator/desktop) | Disable parallax. Use static centered layers. |
| Device overheating from sensors | Throttle accelerometer reads to 30Hz (from default 100Hz). |
| Two audio players conflicting | `audio_session` configures mixing mode to allow soundtrack + narration simultaneously. |
| Pre-fetch cache memory pressure | 10-item hard limit. Evict on system memory warning callback. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Pre-fetch cache: add, evict, lookup. Soundtrack volume states: duck/unduck/mute. Parallax offset calculation from sensor values. |
| **Widget** | Waveform animation during playback vs hidden when stopped. Parallax layer offset rendering. |
| **Integration** | Step transition with pre-cached assets (instant) vs uncached (shimmer). Soundtrack ducking during narration. |
| **Manual** | Parallax smoothness on physical device. Soundtrack + narration simultaneous playback quality. |

---

## Effort Estimate

**Total: ~44h (5-6 days)**
