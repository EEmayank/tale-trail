# Tasks: Player Enhancements

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 13 |
| **Total Estimated Effort** | ~44h |
| **Phase** | Post-MVP |
| **Sprint** | 17-18 |
| **Status** | ⬜ Not Started (post-MVP enhancements) |

---

## Phase 1: Background Pre-fetch (~10h)

- [ ] **Task 1:** Pre-fetch service — Identify all possible next steps from current choices. Pre-download audio files and illustration assets. Manage memory cache with 10-item limit. *(5h)*
- [ ] **Task 2:** Pre-fetch provider — Trigger pre-fetch when step is displayed. Serve pre-cached assets on step transition for instant loading. Track cache hit rate. *(4h)*
- [ ] **Task 3:** Pre-fetch cleanup — Clear all cached assets on story exit. Evict oldest items when cache exceeds 10-item limit. Release memory on system memory pressure callbacks. *(1h)*

## Phase 2: Story Soundtrack (~11h)

- [ ] **Task 4:** Soundtrack provider — Separate `AudioPlayer` for ambient soundtrack. Loop mode. Volume states: 0.30 (solo), 0.15 (ducked during narration), 0.0 (user disabled). 200ms smooth transitions. *(5h)*
- [ ] **Task 5:** Soundtrack controls — Toggle button in player UI. Persist preference per kid profile. *(2h)*
- [ ] **Task 6:** CMS soundtrack field — Optional `soundtrackUrl` media field on Story content type in Strapi. *(1h)*
- [ ] **Task 7:** Narration↔Soundtrack ducking — Duck to 15% when narration starts; unduck to 30% when narration pauses/ends. 200ms fade. *(3h)*

## Phase 3: Parallax Backgrounds (~10h)

- [ ] **Task 8:** Parallax widget — `ParallaxBackground`: 2–3 stacked SVG layers with offset transforms. Per-layer parallax factors (0.33x background, 0.66x midground, 1.0x foreground). *(5h)*
- [ ] **Task 9:** Parallax provider — `sensors_plus` accelerometer stream. Low-pass filter. ±15px layer offsets. 60fps target. Static fallback. *(4h)*
- [ ] **Task 10:** CMS illustration layers — Optional `backgroundLayer` and `foregroundLayer` media fields on StoryStep in Strapi. *(1h)*

## Phase 4: Audio Waveform & Integration (~10h)

- [ ] **Task 11:** Audio waveform widget — 5 vertical bars, randomized heights, animated at ~10fps. Story accent color. Visible during playback only. *(4h)*
- [ ] **Task 12:** Settings toggles — On/off toggles for soundtrack, parallax, audio waveform. Persist per kid profile. *(2h)*
- [ ] **Task 13:** Player integration — Wire pre-fetch service, soundtrack player, parallax background, waveform indicator into story player. Respect Remote Config feature flags. *(4h)*
