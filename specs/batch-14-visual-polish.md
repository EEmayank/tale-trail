# SPEC BATCH 14: Visual Polish (Post-MVP)

> TaleTrail Feature Specifications | Batch 14 of 15
> Produced: 2026-05-18 | Status: Draft
> Tech Stack: Flutter (Riverpod), Node.js (Firebase Cloud Functions), Firestore, Firebase Storage, flutter_svg + Lottie, Strapi v4

---

## Batch Overview

This batch covers five Post-MVP features focused on visual refinement, content infrastructure for Indian cultural stories, and a content cadence system. These features elevate TaleTrail from "functional" to "magical" by adding layered depth effects, audio-reactive visualizations, delightful download feedback, a culturally significant story collection framework, and a sustainable content release pipeline.

| # | Feature | Effort | Dependencies |
|---|---------|--------|--------------|
| 49 | Parallax Background Layers | M | Story Player (6), SVG Rendering (8) |
| 51 | Audio Waveform Indicator | S | Audio Narration Sync (7) |
| 52 | Download Animation | S | Offline Story Downloads (11) |
| 37 | Indian Folklore Collection | S (tech) / L (content) | Strapi CMS Story Builder (15), Dynamic Theme System (36) |
| 53 | Weekly New Story Drops | S (tech) / L (content) | Push Notifications (31), Scheduled Content Publishing (46), CMS (15) |

---

## Feature 49: Parallax Background Layers

### A. Overview & Purpose

**What:** Layered SVG scenery in the story player with scroll-linked and tilt-linked positional offsets. Three distinct depth layers — background (slow-moving), midground (medium-moving), and foreground (fast-moving) — create a subtle but immersive sense of depth as the user interacts with the story.

**Why:** The project brief mandates that "Every screen should feel like a page in a beautifully illustrated children's book." Static SVG backgrounds, no matter how beautifully drawn, feel flat. Parallax transforms the story player from a 2D image viewer into a living diorama. This is called out explicitly in the design philosophy (section 10e of the brief) as a key motion treatment. Competitors like Vooks and Lunesia do not offer environmental depth — this positions TaleTrail's visual quality above the field.

**Success metric:** Users who experience parallax-enabled stories should show a measurable increase in session duration (target: +8% avg session time) compared to flat-background stories, measured via anonymized, aggregated analytics.

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B49.1 | Kid | When I tilt my tablet while reading a story, the trees in front move more than the mountains behind, like I'm looking through a window into the story world. | Must |
| B49.2 | Kid | When I scroll through the story text, the background scenery shifts slightly, making the scene feel alive. | Must |
| B49.3 | Parent | The parallax effect does not cause jitter, stutter, or motion sickness for my child. Movement is slow and subtle. | Must |
| B49.4 | Content creator | I can upload three SVG layers (background, midground, foreground) per story scene in the CMS, or fall back to a single flat SVG if parallax assets are not available. | Must |
| B49.5 | Developer | On devices without an accelerometer (or where accelerometer permission is denied), the system degrades gracefully to scroll-only parallax with no errors or visual glitches. | Must |
| B49.6 | Kid | The parallax effect does not obscure the story text, choice buttons, or any interactive UI elements. | Must |
| B49.7 | Developer | Parallax rendering maintains 60fps on devices with at least 2GB RAM and a mid-range chipset (Snapdragon 665 or equivalent). | Should |

**Functional Requirements:**

1. Each story scene supports up to 3 SVG layers stacked in z-order: `bg_layer` (farthest), `mid_layer`, `fg_layer` (nearest).
2. Layers shift position based on two input sources:
   - **Scroll offset:** Vertical scroll position of the story text panel maps to horizontal/vertical layer translation.
   - **Tilt (accelerometer):** Device pitch and roll map to layer translation along X and Y axes.
3. Layer offset maximums are clamped: background +/-5dp, midground +/-10dp, foreground +/-15dp.
4. If only one SVG is provided for a scene (no layer separation), parallax is disabled for that scene and the single SVG renders as a static full-bleed background.
5. Parallax is disabled entirely when the device reports no accelerometer sensor, or when the user has enabled "Reduce Motion" in system accessibility settings.
6. A global setting in Firebase Remote Config (`parallax_enabled`) acts as a kill switch.

### C. Technical Design & Architecture

**Package dependency:**

```yaml
# pubspec.yaml
dependencies:
  sensors_plus: ^4.0.0  # Accelerometer access (cross-platform)
```

**Architecture overview:**

```
┌──────────────────────────────────────┐
│          StoryPlayerScreen           │
│  ┌────────────────────────────────┐  │
│  │      ParallaxSceneWidget       │  │
│  │  ┌──────────┐                  │  │
│  │  │ bg_layer │  offset: ±5dp   │  │
│  │  ├──────────┤                  │  │
│  │  │ mid_layer│  offset: ±10dp  │  │
│  │  ├──────────┤                  │  │
│  │  │ fg_layer │  offset: ±15dp  │  │
│  │  └──────────┘                  │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │   Text Panel + Choice Buttons  │  │ ← No parallax on this layer
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

**Core components:**

1. **`ParallaxController`** (Riverpod `Notifier`)
   - Listens to `sensors_plus` accelerometer event stream.
   - Applies a low-pass filter (exponential moving average, alpha = 0.1) to smooth raw sensor data.
   - Computes normalized offset values (range -1.0 to 1.0) for X and Y axes.
   - Combines scroll-based offset and tilt-based offset into a single `ParallaxOffset` value per layer.
   - Exposes `ParallaxState` containing `bgOffset`, `midOffset`, `fgOffset` (each an `Offset` in dp).

2. **`ParallaxSceneWidget`** (StatelessWidget consuming `ParallaxController`)
   - Renders three `Transform.translate` wrappers, each containing an `SvgPicture.asset` or `SvgPicture.network`.
   - Each wrapper's translation is the corresponding offset from `ParallaxState`.
   - Layers overflow is clipped via `ClipRect` so shifted SVGs do not bleed outside the scene bounds.
   - SVGs are sized to scene dimensions + (2 * max offset) to prevent edge gaps when translated.

3. **`AccelerometerService`** (injected via Riverpod)
   - Wraps `sensors_plus` accelerometer stream.
   - Exposes `Stream<AccelerometerEvent>` and `bool isAvailable`.
   - On platforms/devices without accelerometer, `isAvailable` returns false and no stream is subscribed.

4. **`ParallaxConfig`** (immutable value object)
   ```dart
   class ParallaxConfig {
     final double bgMaxOffset;  // default: 5.0
     final double midMaxOffset; // default: 10.0
     final double fgMaxOffset;  // default: 15.0
     final double smoothingFactor; // default: 0.1
     final bool tiltEnabled;
     final bool scrollEnabled;
   }
   ```

**Scroll-based parallax mapping:**

```dart
// scrollFraction: 0.0 (top) to 1.0 (bottom) of the text panel scroll extent
double layerOffset(double scrollFraction, double maxOffset) {
  return (scrollFraction - 0.5) * 2.0 * maxOffset;
  // At scrollFraction=0.0 → offset = -maxOffset
  // At scrollFraction=0.5 → offset = 0
  // At scrollFraction=1.0 → offset = +maxOffset
}
```

**Tilt-based parallax mapping:**

```dart
// Accelerometer X/Y values typically range -10 to +10 m/s²
// Normalize to -1..1, then scale by maxOffset
double tiltOffset(double accelValue, double maxOffset) {
  final normalized = (accelValue / 9.81).clamp(-1.0, 1.0);
  return normalized * maxOffset;
}
```

**Combined offset:**

```dart
Offset combinedOffset(double scrollX, double tiltX, double scrollY, double tiltY, double maxOffset) {
  final x = (scrollX + tiltX).clamp(-maxOffset, maxOffset);
  final y = (scrollY + tiltY).clamp(-maxOffset, maxOffset);
  return Offset(x, y);
}
```

**Performance considerations:**

- Accelerometer stream is throttled to 30 samples/sec (not the raw 100+ Hz).
- `RepaintBoundary` wraps each SVG layer to isolate repaint regions.
- SVGs are pre-cached on scene load via `precachePicture` from `flutter_svg`.
- On low-end devices (detected via `device_info_plus`), parallax can be auto-disabled by Remote Config targeting.
- `Transform.translate` is a compositing-only operation when the child does not need repaint, keeping the layer tree efficient.

**Accessibility:**

- If `MediaQuery.of(context).disableAnimations` is true (maps to system "Reduce Motion"), parallax is disabled entirely.
- Parallax layers are semantically invisible (`ExcludeSemantics` wrapper) since they are decorative.

### D. Data Models & Schema

**Strapi CMS — Story Step extension:**

Add three optional media fields to the existing `story_step` content type:

```json
{
  "kind": "collectionType",
  "collectionName": "story_steps",
  "attributes": {
    "...existing fields...": {},
    "parallax_bg_layer": {
      "type": "media",
      "allowedTypes": ["images"],
      "multiple": false,
      "pluginOptions": {
        "description": "Background SVG layer (farthest, slowest movement). Optional."
      }
    },
    "parallax_mid_layer": {
      "type": "media",
      "allowedTypes": ["images"],
      "multiple": false,
      "pluginOptions": {
        "description": "Midground SVG layer (medium movement). Optional."
      }
    },
    "parallax_fg_layer": {
      "type": "media",
      "allowedTypes": ["images"],
      "multiple": false,
      "pluginOptions": {
        "description": "Foreground SVG layer (nearest, fastest movement). Optional."
      }
    }
  }
}
```

**Firestore — Story step document extension:**

```
/stories/{storyId}/steps/{stepId}
{
  ...existing fields...,
  "parallaxLayers": {             // null if no parallax for this step
    "bg": "gs://bucket/stories/{storyId}/steps/{stepId}/parallax_bg.svg",
    "mid": "gs://bucket/stories/{storyId}/steps/{stepId}/parallax_mid.svg",
    "fg": "gs://bucket/stories/{storyId}/steps/{stepId}/parallax_fg.svg"
  }
}
```

**Dart model:**

```dart
class ParallaxLayers {
  final String? bgUrl;
  final String? midUrl;
  final String? fgUrl;

  bool get hasParallax => bgUrl != null || midUrl != null || fgUrl != null;
  int get layerCount => [bgUrl, midUrl, fgUrl].whereType<String>().length;
}
```

**Offline cache structure:**

```
app_data/
  stories/
    {storyId}/
      steps/
        {stepId}/
          illustration.svg      ← existing main SVG
          parallax_bg.svg       ← new
          parallax_mid.svg      ← new
          parallax_fg.svg       ← new
```

**SVG asset guidelines for parallax layers:**

| Property | Requirement |
|----------|-------------|
| Dimensions | Scene size + 30dp padding on all sides (to prevent edge gaps at max offset) |
| Max file size | 200KB per layer (600KB total for 3 layers vs. 500KB for a single non-parallax SVG) |
| Transparency | Mid and fg layers must have transparent areas so lower layers show through |
| Naming convention | `{scene_name}_bg.svg`, `{scene_name}_mid.svg`, `{scene_name}_fg.svg` |
| Content separation | bg = sky, distant mountains, sun/moon; mid = trees, buildings, river; fg = grass, rocks, close foliage |

### E. UI/UX Specification

**Visual design:**

- The parallax scene occupies the top 60-70% of the story player screen (matching the existing illustration area).
- Layers are stacked with the background at z-index 0, midground at z-index 1, foreground at z-index 2.
- Story text panel and choice buttons sit above all parallax layers at z-index 3 and are unaffected by parallax movement.
- The overall scene is wrapped in a `ClipRRect` matching the story player's border radius (0dp — full bleed to edges).

**Motion behavior:**

| Input | Axis | Behavior |
|-------|------|----------|
| Scroll down | Y | Layers shift upward (scene pans down) at their respective rates |
| Scroll up | Y | Layers shift downward (scene pans up) at their respective rates |
| Tilt device left | X | Layers shift right (as if looking left into the scene) |
| Tilt device right | X | Layers shift left (as if looking right into the scene) |
| Tilt device forward | Y | Layers shift down slightly |
| Tilt device backward | Y | Layers shift up slightly |

**Transition between steps:**

- When transitioning from one story step to the next, parallax layers cross-fade alongside the main illustration using the existing page turn transition (Feature 14f).
- During cross-fade (400-800ms), parallax offset resets to center (0,0) with an ease-out curve.
- New step's parallax layers begin from center offset and respond to current tilt/scroll normally.

**Fallback states:**

| Condition | Behavior |
|-----------|----------|
| No parallax assets for this step | Render single illustration as static full-bleed (existing behavior) |
| Only 1 or 2 parallax layers provided | Render provided layers with parallax; missing layers are simply absent |
| No accelerometer | Scroll-only parallax; no tilt response |
| "Reduce Motion" enabled | All layers rendered statically at center offset (0,0) |
| Remote Config `parallax_enabled = false` | All layers rendered statically at center offset (0,0) |

**CMS authoring UI (Strapi):**

- In the story step editor, below the main illustration upload, add a collapsible section: "Parallax Layers (Optional)."
- Three upload fields: Background Layer, Midground Layer, Foreground Layer.
- Inline help text: "Upload 2-3 SVG layers to create a depth effect. Background moves slowest, foreground moves fastest. Each layer should be transparent except for its scenery elements."
- A "Preview" button is out of scope for this batch (Strapi does not support live Flutter preview). Content creators should test on a device.

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T49.1 | `ParallaxController` clamps offset to max bounds | `bgOffset` never exceeds +/-5dp, `midOffset` +/-10dp, `fgOffset` +/-15dp |
| T49.2 | `ParallaxController` with no accelerometer data produces zero tilt offset | `tiltOffset` = (0,0) for all layers |
| T49.3 | Scroll fraction 0.0 maps to -maxOffset, 0.5 to 0, 1.0 to +maxOffset | Exact numerical verification |
| T49.4 | Low-pass filter smooths erratic accelerometer spikes | Input sequence [0, 10, 0, 10] produces output that stays below 5 |
| T49.5 | `ParallaxLayers.hasParallax` returns false when all URLs are null | `hasParallax == false` |
| T49.6 | `ParallaxLayers.hasParallax` returns true when any URL is non-null | `hasParallax == true` |

**Widget tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T49.7 | `ParallaxSceneWidget` renders 3 SVG layers when all URLs provided | Three `SvgPicture` widgets found in widget tree |
| T49.8 | `ParallaxSceneWidget` renders 1 SVG when only bg provided | One `SvgPicture` widget found |
| T49.9 | `ParallaxSceneWidget` renders static illustration when `hasParallax` is false | Standard single `SvgPicture`, no `Transform.translate` wrappers |
| T49.10 | Parallax disabled when `MediaQuery.disableAnimations` is true | All `Transform.translate` offsets are `Offset.zero` |

**Integration tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T49.11 | Scroll story text panel and verify layers translate at different rates | Screenshot comparison at scroll 0%, 50%, 100% shows progressive layer shift |
| T49.12 | Story step transition resets parallax to center | After transition completes, all layer offsets are (0,0) |
| T49.13 | Download a story with parallax assets for offline, enter airplane mode, verify parallax works offline | Layers render and respond to scroll from local cache |

**Performance tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T49.14 | Render 3 parallax SVG layers (each 200KB) and scroll continuously for 30 seconds | Frame rate stays above 55fps on a Pixel 4a-class device |
| T49.15 | Memory usage with parallax scene active vs. static illustration | Delta < 15MB |

**Manual QA checklist:**

- [ ] Tilt device in all four directions; layers respond naturally without jitter.
- [ ] Place device flat on table; layers settle at center with no drift.
- [ ] Scroll text panel fully; layers shift smoothly without edge gaps.
- [ ] Switch between parallax and non-parallax story steps; no visual glitch during transition.
- [ ] Test on a device without accelerometer (e.g., some Android TV or emulator); scroll-only parallax works, no crash.
- [ ] Enable "Reduce Motion" in system settings; parallax is static.
- [ ] Set Remote Config `parallax_enabled = false`; parallax is static.

---

## Feature 51: Audio Waveform Indicator

### A. Overview & Purpose

**What:** A dynamic, audio-reactive waveform visualization that displays in the story player while narration is actively playing. This replaces the simple Lottie-based speaking indicator from the MVP with a real-time visualization driven by actual audio amplitude data. The indicator consists of 20 vertical bars with rounded tops, colored to match the current story theme, that rise and fall in sync with the narrator's voice.

**Why:** The MVP's speaking indicator is a canned Lottie loop — it plays the same animation regardless of whether the narrator is whispering, shouting, pausing, or speaking quickly. This disconnect undermines the immersion the story player works hard to build. An audio-reactive waveform creates a truthful visual link between what kids hear and what they see, making the narration feel more alive. It also serves as an essential affordance: kids can glance at the waveform to confirm audio is playing (important in noisy environments or when volume is low).

**Success metric:** The waveform should accurately reflect audio amplitude with no perceptible latency (< 100ms visual lag behind audio).

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B51.1 | Kid | When the narrator is speaking, I see colorful bars dancing up and down that move with the voice — big movements when the voice is loud, small movements when it is quiet. | Must |
| B51.2 | Kid | When the narrator pauses between sentences, the bars settle down to a resting height so I know the story has not stopped, just paused. | Must |
| B51.3 | Kid | When I press pause, the bars stop moving and shrink to their resting state with a smooth animation. | Must |
| B51.4 | Parent | The waveform is small and subtle — it does not distract from the story illustration or text. | Must |
| B51.5 | Developer | The waveform uses the current story's accent color (from Dynamic Theme System, Feature 36) so it looks cohesive with each story's visual identity. | Should |
| B51.6 | Developer | On devices where amplitude data is unavailable, the system falls back to a simple pulsing animation (not the old Lottie — a simpler version of the bar visualization with randomized heights). | Must |

**Functional Requirements:**

1. Waveform consists of 20 vertical bars arranged horizontally with equal spacing.
2. Bar heights are driven by audio amplitude data from `just_audio`'s amplitude stream.
3. Bars update at 30fps (one amplitude sample mapped to bar heights every ~33ms).
4. Each bar has a rounded top cap (border radius equal to half the bar width).
5. Bar color is sourced from the current story's `accentColor` via the Dynamic Theme System. Opacity gradients from 0.6 (shortest bars) to 1.0 (tallest bars) add depth.
6. Minimum bar height (resting state): 4dp. Maximum bar height: 24dp.
7. Height mapping: amplitude (0.0 = silence, 1.0 = max) maps linearly to bar height between min and max, with adjacent bars receiving slightly randomized offsets (damped noise) to avoid a flat uniform appearance.
8. When audio is paused or stopped, bars animate down to resting height over 300ms using `Curves.easeOutCubic`.
9. Total waveform widget size: width ~120dp, height 28dp (including 2dp top/bottom padding).

### C. Technical Design & Architecture

**Package dependency:**

`just_audio` is already in the project (MVP Audio Narration Sync, Feature 7). No new packages required.

**Amplitude data source:**

```dart
// just_audio provides an amplitude stream (Android/iOS only)
// Returns AndroidAmplitude or IosAmplitude with current/max amplitude in dB
final amplitudeStream = audioPlayer.createAmplitudeStream(
  interval: const Duration(milliseconds: 33), // ~30fps
);
```

**Architecture:**

```
┌─────────────────────────────────────────┐
│         AudioWaveformProvider            │
│  (Riverpod StreamProvider)              │
│                                         │
│  Input: just_audio amplitude stream     │
│  Output: List<double> barHeights (20)   │
│                                         │
│  Processing:                            │
│   1. Convert dB amplitude to 0.0–1.0    │
│   2. Apply noise distribution across    │
│      20 bars                            │
│   3. Smooth transitions via lerp        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│       AudioWaveformWidget               │
│  (CustomPainter-based)                  │
│                                         │
│  Consumes: List<double> barHeights      │
│  Renders: 20 rounded-top bars           │
│  Color: story accent color              │
│  Repaint trigger: barHeights changes    │
└─────────────────────────────────────────┘
```

**Core implementation:**

```dart
class AudioWaveformPainter extends CustomPainter {
  final List<double> barHeights; // 20 values, each 0.0–1.0
  final Color accentColor;

  static const int barCount = 20;
  static const double barWidth = 4.0;
  static const double barSpacing = 2.0;
  static const double minHeight = 4.0;
  static const double maxHeight = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < barCount; i++) {
      final height = minHeight + (barHeights[i] * (maxHeight - minHeight));
      final x = i * (barWidth + barSpacing);
      final y = size.height - height;

      final opacity = 0.6 + (barHeights[i] * 0.4);
      final paint = Paint()
        ..color = accentColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, height),
        topLeft: Radius.circular(barWidth / 2),
        topRight: Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(AudioWaveformPainter oldDelegate) {
    return oldDelegate.barHeights != barHeights;
  }
}
```

**Amplitude-to-bars distribution:**

```dart
List<double> distributeAmplitude(double normalizedAmplitude, List<double> previousBars) {
  final random = Random();  // Seeded per-frame for consistency
  final bars = List<double>.generate(20, (i) {
    // Base amplitude with gaussian-like distribution (center bars taller)
    final centerWeight = 1.0 - ((i - 9.5).abs() / 9.5) * 0.3;
    // Random noise factor ±20%
    final noise = 0.8 + random.nextDouble() * 0.4;
    final target = (normalizedAmplitude * centerWeight * noise).clamp(0.0, 1.0);
    // Smooth transition from previous frame (lerp at 40% toward target)
    return lerpDouble(previousBars[i], target, 0.4)!;
  });
  return bars;
}
```

**dB to normalized amplitude conversion:**

```dart
double dbToNormalized(double currentDb, double maxDb) {
  // Typical range: -60dB (silence) to 0dB (max)
  // Clamp and normalize
  final clamped = currentDb.clamp(-60.0, 0.0);
  return (clamped + 60.0) / 60.0; // 0.0 = silence, 1.0 = max
}
```

**Fallback (no amplitude data):**

When `createAmplitudeStream` is unavailable (e.g., web platform, or specific device issues), the provider generates synthetic bar heights using a `Timer.periodic` at 30fps with semi-random values modulated by a sine wave, producing a gentle undulating pattern. The fallback activates only while audio `playerState.playing == true`.

**Performance:**

- `CustomPainter` avoids widget tree rebuilds; only the canvas repaints.
- 20 rounded rectangles per frame at 30fps is trivially lightweight.
- `shouldRepaint` returns false if bar heights have not changed (e.g., during pause after settle).
- `RepaintBoundary` isolates the waveform from the rest of the story player.

### D. Data Models & Schema

This feature requires no Firestore schema changes or CMS changes. It is entirely client-side, driven by runtime audio amplitude data.

**Riverpod providers:**

```dart
// Provider for raw amplitude stream from just_audio
final amplitudeStreamProvider = StreamProvider.autoDispose<Amplitude>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.createAmplitudeStream(
    interval: const Duration(milliseconds: 33),
  );
});

// Provider for processed bar heights
final waveformBarHeightsProvider = StateNotifierProvider.autoDispose<WaveformNotifier, List<double>>((ref) {
  return WaveformNotifier(ref);
});
```

**WaveformNotifier state:**

```dart
class WaveformNotifier extends StateNotifier<List<double>> {
  // State: List<double> of length 20, each value 0.0–1.0
  // Initialized to all zeros (resting state)
  WaveformNotifier(this.ref) : super(List.filled(20, 0.0)) {
    _listenToAmplitude();
  }
}
```

### E. UI/UX Specification

**Placement:**

The waveform indicator is positioned in the story player's text panel area, directly adjacent to the play/pause button. Exact placement:

```
┌──────────────────────────────────────────┐
│                                          │
│           [Story Illustration]           │
│              (60-70% screen)             │
│                                          │
├──────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐ │
│ │  Story text goes here. The narrator  │ │
│ │  reads this text aloud while the     │ │
│ │  waveform pulses below.              │ │
│ │                                      │ │
│ ├──────────────────────────────────────┤ │
│ │  [⏸]  |||||||||||||||||||  ▶ 2:34   │ │
│ │        └── waveform ──┘             │ │
│ └──────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

- Left of waveform: play/pause button (existing).
- Right of waveform: elapsed time display (existing).
- Waveform centered between the two controls.
- Vertical alignment: centered in the controls row.

**Visual details:**

| Property | Value |
|----------|-------|
| Total widget width | ~120dp (20 bars * 4dp + 19 gaps * 2dp) |
| Total widget height | 28dp (24dp max bar + 2dp padding top + 2dp padding bottom) |
| Bar width | 4dp |
| Bar spacing | 2dp |
| Bar min height | 4dp |
| Bar max height | 24dp |
| Bar corner radius (top) | 2dp (half of bar width) |
| Bar color | Story accent color (from `StoryTheme.accentColor`) |
| Bar opacity range | 0.6 (shortest) to 1.0 (tallest) |
| Resting animation (pause/silence) | Bars at 4dp height, no movement |
| Transition to resting | 300ms `easeOutCubic` |

**Bedtime Mode treatment:**

In Bedtime Mode (Feature 34), the waveform uses the bedtime palette's soft gold accent color instead of the story's accent color. Bar max height is reduced to 18dp and opacity is reduced (0.4 to 0.7) to be even more subtle.

**Animation states:**

| Audio State | Waveform Behavior |
|-------------|-------------------|
| Playing (narrator speaking) | Bars move dynamically, heights driven by amplitude |
| Playing (silence between sentences) | Bars settle to near-resting but maintain subtle micro-movement (amplitude hovers near 0) |
| Paused | Bars animate to resting height (4dp) over 300ms |
| Stopped / Audio complete | Bars animate to resting height over 300ms |
| Buffering | Bars display a slow left-to-right wave pattern (loading indicator) at low amplitude |

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T51.1 | `dbToNormalized(-60)` returns 0.0 | Silence maps to zero |
| T51.2 | `dbToNormalized(0)` returns 1.0 | Max volume maps to one |
| T51.3 | `dbToNormalized(-30)` returns 0.5 | Midpoint is correct |
| T51.4 | `distributeAmplitude(0.0, ...)` returns all values near 0.0 | Silence = minimal bar heights |
| T51.5 | `distributeAmplitude(1.0, ...)` returns values distributed around 1.0 | Max amplitude = tall bars |
| T51.6 | All values in `distributeAmplitude` output are clamped to [0.0, 1.0] | No out-of-range values |
| T51.7 | Lerp smoothing produces values between previous and target | Intermediate values for smooth transition |

**Widget tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T51.8 | `AudioWaveformWidget` renders with 20 bars visible in golden file | Visual snapshot match |
| T51.9 | Waveform uses accent color from `StoryTheme` | Paint color matches theme `accentColor` |
| T51.10 | Waveform in bedtime mode uses bedtime gold color | Paint color matches bedtime palette gold |
| T51.11 | `shouldRepaint` returns false for identical bar heights | No unnecessary repaints |
| T51.12 | `shouldRepaint` returns true for different bar heights | Repaint triggered on change |

**Integration tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T51.13 | Play a story narration and verify waveform moves | Bars height > resting state while audio plays |
| T51.14 | Pause narration and verify waveform settles | All bars at resting height within 500ms |
| T51.15 | Switch stories and verify waveform color changes | Accent color matches new story theme |

**Manual QA checklist:**

- [ ] Waveform visually syncs with narration — loud passages produce tall bars, quiet passages produce short bars.
- [ ] No perceptible lag between hearing a loud word and seeing bars respond (< 100ms).
- [ ] Bars settle smoothly when narrator pauses between sentences.
- [ ] Pause button causes bars to settle within ~300ms.
- [ ] Waveform looks correct in both portrait and landscape orientations.
- [ ] Waveform colors match the story's theme palette.
- [ ] Waveform is subtle and does not distract from the story text.
- [ ] On a device where amplitude is unavailable, fallback pulsing animation plays while audio is active.

---

## Feature 52: Download Animation

### A. Overview & Purpose

**What:** A charming Lottie animation that plays during story download for offline storage. A small illustrated character carries a book across the screen toward a bookshelf. The character's progress across the screen is synced to actual download progress — at 0% the character stands at the left, at 100% the character places the book on the shelf at the right. The animation includes frame markers at 0%, 25%, 50%, 75%, and 100% for precise progress mapping.

**Why:** Downloading a story (audio + SVGs + data) can take 10-60 seconds depending on connection speed and story size. The MVP shows a standard progress bar, which is functional but joyless. The project brief explicitly calls out that "every state tells a mini-story" (section 10d, Offline Library) and specifically describes "a little character carrying the book to the shelf" as the download animation. This transforms dead waiting time into a delightful micro-narrative that reinforces TaleTrail's storybook identity.

**Success metric:** Qualitative — download wait time should feel shorter and more enjoyable. Download cancellation rate should not increase (i.e., the animation should not confuse users into thinking the download is complete before it is).

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B52.1 | Kid | When I download a story, I see a little character picking up a book and walking it to a bookshelf. The character walks further as the download gets closer to done. | Must |
| B52.2 | Kid | When the download finishes, the character places the book on the shelf and does a small celebration (jump/wave). | Must |
| B52.3 | Kid | I can still see a percentage or progress indication alongside the animation so I know exactly how far along the download is. | Must |
| B52.4 | Parent | If I cancel the download, the character does a sad/disappointed animation and walks back. | Should |
| B52.5 | Developer | The animation handles download stalls gracefully — if progress stalls, the character pauses and performs an idle animation (e.g., tapping foot, looking around) rather than freezing mid-stride. | Must |
| B52.6 | Developer | The animation works offline-to-online transitions — if connection drops and resumes, the character resumes walking from where they paused. | Must |

**Functional Requirements:**

1. A Lottie animation file is bundled with the app (not downloaded per-story).
2. The Lottie file contains the following named markers:
   - `start` (frame 0): Character standing at left, book in hand.
   - `pickup` (frame ~25% through): Character bends down, picks up book.
   - `walk_quarter` (frame ~35%): Character 25% across screen.
   - `walk_half` (frame ~55%): Character 50% across screen.
   - `walk_three_quarter` (frame ~75%): Character 75% across screen.
   - `arrive` (frame ~90%): Character reaches shelf.
   - `place_book` (frame ~95%): Character places book on shelf.
   - `celebrate` (frame ~100%): Character jumps or waves.
3. An `AnimationController` is driven by the download progress percentage (0.0 to 1.0), not by time.
4. When download progress increases, the controller smoothly animates to the corresponding frame position over 200ms (`Curves.easeInOut`).
5. When download completes (1.0), the controller plays the `celebrate` segment at normal speed (not progress-linked).
6. Download progress percentage text is displayed below the animation: "Downloading... 47%".
7. The animation widget is approximately 200dp tall and full-width, displayed on the download confirmation sheet or within the offline library screen.

### C. Technical Design & Architecture

**Package dependency:**

`lottie` package is already in the project (MVP splash screen). No new dependencies.

**Lottie file specification:**

```
File: assets/animations/download_character.json
Size target: < 150KB
Duration: 3 seconds at 30fps (90 frames total)
Frame markers:
  - "idle_start":      frame 0
  - "pickup":          frame 10
  - "walk_25":         frame 25
  - "walk_50":         frame 45
  - "walk_75":         frame 65
  - "shelf_arrive":    frame 78
  - "place_book":      frame 83
  - "celebrate_start": frame 85
  - "celebrate_end":   frame 90
```

**Progress-to-frame mapping:**

```dart
double downloadProgressToAnimationProgress(double downloadProgress) {
  // Map 0.0–1.0 download progress to 0.0–0.94 animation progress
  // (reserve last 6% of animation for celebration, which plays freely)
  if (downloadProgress >= 1.0) return 0.94; // Triggers celebration segment
  return downloadProgress * 0.94;
}
```

**Controller architecture:**

```dart
class DownloadAnimationController {
  late final AnimationController _lottieController;
  late final AnimationController _progressAnimator;
  double _targetProgress = 0.0;
  bool _isComplete = false;
  bool _isStalled = false;
  Timer? _stallTimer;

  void updateProgress(double progress) {
    _targetProgress = downloadProgressToAnimationProgress(progress);
    _resetStallTimer();

    if (progress >= 1.0 && !_isComplete) {
      _isComplete = true;
      // Animate to shelf position, then play celebrate segment freely
      _animateToProgress(0.94, onComplete: _playCelebration);
    } else {
      _animateToProgress(_targetProgress);
    }
  }

  void _animateToProgress(double target, {VoidCallback? onComplete}) {
    _progressAnimator.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    ).then((_) => onComplete?.call());
  }

  void _playCelebration() {
    // Play frames 85–90 at normal speed (not progress-linked)
    _lottieController.animateTo(1.0,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _resetStallTimer() {
    _stallTimer?.cancel();
    _isStalled = false;
    _stallTimer = Timer(const Duration(seconds: 3), () {
      _isStalled = true;
      // Trigger idle sub-animation (character taps foot)
      // This is handled in the widget by overlaying an idle Lottie
    });
  }

  void cancel() {
    // Play reverse walk segment (or a separate "cancel" animation)
    _lottieController.reverse(from: _lottieController.value);
  }
}
```

**Widget tree:**

```dart
Widget build(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 200,
        width: double.infinity,
        child: Lottie.asset(
          'assets/animations/download_character.json',
          controller: _lottieController,
          fit: BoxFit.contain,
          // Do not auto-play; controller drives frames
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _isComplete
          ? 'Downloaded!'
          : 'Downloading... ${(downloadProgress * 100).toInt()}%',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 4),
      // Thin linear progress bar as secondary indicator
      LinearProgressIndicator(
        value: downloadProgress,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation(storyAccentColor),
        minHeight: 3,
        borderRadius: BorderRadius.circular(1.5),
      ),
    ],
  );
}
```

**Integration with existing download system:**

The existing offline download manager (Feature 11) exposes a `Stream<DownloadProgress>` per story. The `DownloadAnimationWidget` subscribes to this stream via a Riverpod provider:

```dart
final storyDownloadProgressProvider = StreamProvider.family<double, String>((ref, storyId) {
  final downloadManager = ref.watch(downloadManagerProvider);
  return downloadManager.progressStream(storyId);
});
```

### D. Data Models & Schema

No Firestore or CMS schema changes required. This feature is entirely client-side.

**Asset manifest addition:**

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/animations/download_character.json
```

**Lottie file marker schema (documented for the animator):**

| Marker Name | Frame | Description |
|-------------|-------|-------------|
| `idle_start` | 0 | Character standing, book nearby on ground |
| `pickup` | 10 | Character bends, picks up book |
| `walk_25` | 25 | Character carrying book, 25% across screen |
| `walk_50` | 45 | Character carrying book, 50% across screen |
| `walk_75` | 65 | Character carrying book, 75% across screen |
| `shelf_arrive` | 78 | Character reaches bookshelf |
| `place_book` | 83 | Character slides book onto shelf |
| `celebrate_start` | 85 | Character begins jump/wave |
| `celebrate_end` | 90 | Character lands, hands at sides, smile |

### E. UI/UX Specification

**Placement context:**

The download animation replaces the current plain progress bar wherever a story download is in progress. It appears in two places:

1. **Download confirmation bottom sheet:** After the user taps "Download" on a story, a bottom sheet slides up containing the animation and progress text.
2. **Offline library screen:** If the user navigates to the library while a download is active, the downloading story's card shows a compact version (120dp tall) of the animation overlaid on the card.

**Full-size layout (bottom sheet):**

```
┌──────────────────────────────────┐
│                                  │
│  ┌──────────────────────────┐   │
│  │   [Character walks →]    │   │  200dp
│  │   🚶📖 ──────→ 📚      │   │
│  └──────────────────────────┘   │
│                                  │
│     Downloading... 47%           │
│     ━━━━━━━━━━━░░░░░░░░░░░░     │  3dp progress bar
│                                  │
│         [Cancel]                 │
│                                  │
└──────────────────────────────────┘
```

**Compact layout (library card overlay):**

The animation is scaled down and cropped to fit within the story card's cover area. Only the character and book are visible (the shelf is off-screen right). A circular progress indicator replaces the linear bar.

**Visual details:**

| Property | Value |
|----------|-------|
| Full animation height | 200dp |
| Compact animation height | 120dp |
| Background | Transparent (sits on the bottom sheet or card surface) |
| Character art style | Matches TaleTrail's hand-drawn SVG aesthetic |
| Book appearance | Matches the story's cover art colors (passed as Lottie color override if supported, otherwise generic) |
| Progress text font | Nunito, 14sp, `onSurface` at 0.7 opacity |
| Progress bar height | 3dp, rounded caps |
| Progress bar color | Story accent color (fill), grey-200 (track) |
| "Cancel" button | Text button, `onSurface` at 0.5 opacity, 12sp |

**State transitions:**

| State | Visual |
|-------|--------|
| Download starting (0%) | Character stands at left, looks at book on ground |
| Download progressing (1-99%) | Character carries book, walks rightward at pace matching progress |
| Download stalled (no progress for 3s) | Character stops walking, taps foot or looks around (idle loop at current position) |
| Download resumed after stall | Character resumes walking from current position |
| Download complete (100%) | Character places book on shelf, does small celebration jump |
| Download cancelled | Character does brief disappointed gesture, walks back leftward (reverse), bottom sheet dismisses |
| Download error | Character trips/stumbles, error message appears below: "Download failed. Tap to retry." |

**Celebration on completion:**

- Character places book on shelf (200ms).
- Character does a small jump with arms raised (300ms).
- Text changes to "Downloaded!" with a checkmark icon.
- Progress bar fills to 100% with the accent color.
- After 1.5 seconds, the bottom sheet auto-dismisses with a slide-down animation.
- A subtle confetti burst (reuse Story Completion Celebration confetti, Feature 12) plays briefly.

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T52.1 | `downloadProgressToAnimationProgress(0.0)` returns 0.0 | Start of animation |
| T52.2 | `downloadProgressToAnimationProgress(0.5)` returns 0.47 | Mid-animation (0.5 * 0.94) |
| T52.3 | `downloadProgressToAnimationProgress(1.0)` returns 0.94 | Pre-celebration position |
| T52.4 | Stall timer fires after 3 seconds of no progress update | `_isStalled == true` |
| T52.5 | Stall timer resets when progress updates | `_isStalled == false` after progress call |

**Widget tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T52.6 | Widget displays "Downloading... 0%" at start | Text found in widget tree |
| T52.7 | Widget displays "Downloaded!" at 100% | Text found in widget tree |
| T52.8 | Cancel button is present and tappable | `onPressed` callback fires |
| T52.9 | Lottie widget is present in tree | `Lottie` widget found |
| T52.10 | Progress bar value matches download progress | `LinearProgressIndicator.value == downloadProgress` |

**Integration tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T52.11 | Start a real story download; animation progresses from 0 to 100 | Lottie controller value increases monotonically to completion |
| T52.12 | Cancel download mid-progress; animation plays reverse | Lottie controller value decreases; bottom sheet dismisses |
| T52.13 | Download completes; celebration plays; sheet auto-dismisses after 1.5s | Celebration animation plays; sheet dismisses |
| T52.14 | Simulate network drop (airplane mode) during download; animation shows stall state | Character stops walking within 3 seconds; idle animation plays |
| T52.15 | Resume network; download continues; animation resumes from stall position | Character resumes walking; no jump in position |

**Manual QA checklist:**

- [ ] Character walk speed feels natural and proportional to download progress.
- [ ] No visual jumps when download progress arrives in bursts (e.g., 0% → 30% quickly).
- [ ] Celebration animation plays fully before sheet dismisses.
- [ ] Compact version in library card looks good and is not cropped awkwardly.
- [ ] Animation renders correctly on both Android and iOS.
- [ ] Lottie file size is under 150KB.
- [ ] Character art style is consistent with TaleTrail's hand-drawn aesthetic.

---

## Feature 37: Indian Folklore Collection

### A. Overview & Purpose

**What:** A content structure framework — not the stories themselves — for interactive branching stories based on Indian folklore traditions: Panchatantra, Jataka tales, Tenali Raman, and Akbar-Birbal. This spec defines the Strapi CMS content type (`cultural_collection`), metadata schema, regional language infrastructure, and UI treatments (special card frames, cultural motif borders, pronunciation guides) that differentiate folklore stories from standard stories in the app.

**Why:** The competitive analysis identifies Indian cultural content as TaleTrail's single largest market gap. StoryWeaver has 38,000 free Indian-language books, but none are interactive or audio-driven. No global competitor (Epic, Lunesia, Vooks, Calm) offers Indian folklore. The Panchatantra and Jataka tales are inherently branching-friendly — they were originally moral dilemma stories with "what would you do?" structures, making them a perfect fit for TaleTrail's choose-your-own-adventure format. India is the primary market, and cultural relevance is a key engagement driver.

**Scope boundary:** This spec covers the *technical template and infrastructure*, not the story content itself. Story writing, narration recording, and illustration creation are content pipeline operations outside this spec's scope.

**Success metric:** The cultural collection framework should support at least 4 distinct folklore traditions with per-tradition metadata, and the UI should visibly differentiate folklore stories from standard stories in the browse experience.

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B37.1 | Kid | When I browse stories, I can see special "Indian Stories" with beautiful decorative borders that look different from other stories — they feel special and cultural. | Must |
| B37.2 | Kid | When I finish an Indian folklore story, I see the "moral of the story" presented in a special way, like an elder is sharing wisdom. | Must |
| B37.3 | Parent | I can filter stories by cultural tradition (Panchatantra, Jataka, Tenali Raman, Akbar-Birbal) so my child explores specific traditions. | Must |
| B37.4 | Parent | For stories with Hindi or Sanskrit terms, I can see a pronunciation guide so I can help my child with unfamiliar words. | Should |
| B37.5 | Content creator | I can create a folklore story in the CMS with all standard story fields plus additional cultural metadata: origin tradition, moral/lesson, historical period, regional language options, and pronunciation guides. | Must |
| B37.6 | Content creator | I can assign a story to a `cultural_collection` and the app automatically applies the correct visual treatment (border, motifs, typography) without manual per-story styling. | Must |
| B37.7 | Content creator | I can provide the same story in multiple Indian languages (Hindi, Tamil, Bengali, etc.) and the app shows the appropriate version based on user preference. | Should |
| B37.8 | Kid | I can see a collection screen that groups all stories from one tradition together, like a "Panchatantra" section with a unique illustrated header. | Must |

**Functional Requirements:**

1. A new `cultural_collection` content type in Strapi groups folklore stories by tradition.
2. Each collection has: name, description, origin tradition, historical period, representative SVG motif/border, accent color palette, and a cover illustration.
3. Stories belonging to a cultural collection inherit the collection's visual treatment automatically.
4. A `moral_lesson` field on folklore stories displays a stylized "moral" card at story completion.
5. An optional `pronunciation_guide` component allows content creators to define terms with phonetic spellings and audio clips.
6. Stories can have multiple language variants linked to the same branching tree structure.
7. The story browser includes a "Indian Folklore" section with sub-filtering by tradition.

### C. Technical Design & Architecture

**CMS content model architecture:**

```
cultural_collection (new content type)
  ├── name: string
  ├── slug: string (unique)
  ├── description: richtext
  ├── origin_tradition: enum [panchatantra, jataka, tenali_raman, akbar_birbal, regional_folklore, other]
  ├── historical_period: string (e.g., "3rd century BCE")
  ├── accent_color_primary: string (hex)
  ├── accent_color_secondary: string (hex)
  ├── motif_border_svg: media (SVG)
  ├── card_frame_svg: media (SVG)
  ├── collection_header_illustration: media (SVG/PNG)
  ├── icon_svg: media (SVG, small icon for filters)
  ├── stories: relation (one-to-many → story)
  └── display_order: integer

story (extended fields on existing content type)
  ├── ...existing fields...
  ├── cultural_collection: relation (many-to-one → cultural_collection, nullable)
  ├── moral_lesson: component (moral_lesson, optional)
  ├── pronunciation_guide: component (repeatable, pronunciation_entry, optional)
  └── language_variants: relation (one-to-many → story, self-referential)
```

**New Strapi components:**

```json
// components/story/moral-lesson.json
{
  "collectionName": "components_story_moral_lessons",
  "info": {
    "displayName": "Moral Lesson",
    "description": "The moral or teaching from a folklore story"
  },
  "attributes": {
    "moral_text": {
      "type": "text",
      "required": true,
      "maxLength": 500
    },
    "moral_text_hindi": {
      "type": "text",
      "maxLength": 500
    },
    "attribution": {
      "type": "string",
      "maxLength": 200,
      "pluginOptions": {
        "description": "e.g., 'From the Panchatantra, Book III'"
      }
    },
    "display_style": {
      "type": "enumeration",
      "enum": ["scroll", "elder_quote", "wisdom_card"],
      "default": "wisdom_card"
    }
  }
}
```

```json
// components/story/pronunciation-entry.json
{
  "collectionName": "components_story_pronunciation_entries",
  "info": {
    "displayName": "Pronunciation Entry",
    "description": "A term with pronunciation guide for Hindi/Sanskrit words"
  },
  "attributes": {
    "term": {
      "type": "string",
      "required": true,
      "maxLength": 100
    },
    "language": {
      "type": "enumeration",
      "enum": ["hindi", "sanskrit", "tamil", "bengali", "marathi", "telugu", "kannada", "malayalam", "gujarati", "punjabi"],
      "required": true
    },
    "phonetic_spelling": {
      "type": "string",
      "required": true,
      "maxLength": 200,
      "pluginOptions": {
        "description": "IPA or simplified phonetic, e.g., 'dhar-ma' for dharma"
      }
    },
    "meaning": {
      "type": "text",
      "required": true,
      "maxLength": 300
    },
    "audio_clip": {
      "type": "media",
      "allowedTypes": ["audios"],
      "multiple": false
    }
  }
}
```

**Firestore document structure:**

```
/cultural_collections/{collectionId}
{
  "name": "Panchatantra",
  "slug": "panchatantra",
  "description": "Ancient Indian collection of interrelated animal fables...",
  "originTradition": "panchatantra",
  "historicalPeriod": "3rd century BCE",
  "accentColors": {
    "primary": "#C8553D",    // terracotta
    "secondary": "#F4E285"   // warm gold
  },
  "motifBorderSvgUrl": "gs://bucket/collections/panchatantra/motif_border.svg",
  "cardFrameSvgUrl": "gs://bucket/collections/panchatantra/card_frame.svg",
  "headerIllustrationUrl": "gs://bucket/collections/panchatantra/header.svg",
  "iconSvgUrl": "gs://bucket/collections/panchatantra/icon.svg",
  "displayOrder": 1,
  "storyCount": 5,
  "updatedAt": "2026-05-18T00:00:00Z"
}

/stories/{storyId}
{
  ...existing fields...,
  "culturalCollectionId": "panchatantra",  // nullable
  "moralLesson": {                          // nullable
    "text": "True friends stand by each other even in the face of danger.",
    "textHindi": "सच्चे मित्र खतरे में भी एक दूसरे का साथ देते हैं।",
    "attribution": "From the Panchatantra, Book II - Mitra Bheda",
    "displayStyle": "wisdom_card"
  },
  "pronunciationGuide": [                   // empty array if none
    {
      "term": "dharma",
      "language": "sanskrit",
      "phoneticSpelling": "dhar-ma",
      "meaning": "Righteous duty or moral law",
      "audioClipUrl": "gs://bucket/pronunciation/dharma.mp3"
    }
  ],
  "languageVariants": {                     // map of language code → story ID
    "hi": "story_xyz_hindi",
    "ta": "story_xyz_tamil"
  }
}
```

**Dart models:**

```dart
class CulturalCollection {
  final String id;
  final String name;
  final String slug;
  final String description;
  final OriginTradition originTradition;
  final String? historicalPeriod;
  final CulturalAccentColors accentColors;
  final String? motifBorderSvgUrl;
  final String? cardFrameSvgUrl;
  final String? headerIllustrationUrl;
  final String? iconSvgUrl;
  final int displayOrder;
  final int storyCount;
}

enum OriginTradition {
  panchatantra,
  jataka,
  tenaliRaman,
  akbarBirbal,
  regionalFolklore,
  other,
}

class CulturalAccentColors {
  final Color primary;
  final Color secondary;
}

class MoralLesson {
  final String text;
  final String? textHindi;
  final String? attribution;
  final MoralDisplayStyle displayStyle;
}

enum MoralDisplayStyle { scroll, elderQuote, wisdomCard }

class PronunciationEntry {
  final String term;
  final String language;
  final String phoneticSpelling;
  final String meaning;
  final String? audioClipUrl;
}
```

**Riverpod providers:**

```dart
// All cultural collections
final culturalCollectionsProvider = FutureProvider<List<CulturalCollection>>((ref) {
  return ref.watch(culturalCollectionRepositoryProvider).getAll();
});

// Stories for a specific collection
final collectionStoriesProvider = FutureProvider.family<List<Story>, String>((ref, collectionId) {
  return ref.watch(storyRepositoryProvider).getByCollection(collectionId);
});

// Pronunciation guide for current story
final pronunciationGuideProvider = Provider.family<List<PronunciationEntry>, String>((ref, storyId) {
  final story = ref.watch(storyProvider(storyId)).valueOrNull;
  return story?.pronunciationGuide ?? [];
});
```

**Cloud Function — Collection sync (Strapi webhook):**

When a `cultural_collection` is created/updated in Strapi, a webhook triggers a Cloud Function that syncs the data to Firestore:

```typescript
export const syncCulturalCollection = functions.https.onRequest(async (req, res) => {
  const { event, model, entry } = req.body;
  if (model !== 'cultural-collection') return res.status(200).send('ignored');

  const collectionRef = admin.firestore()
    .collection('cultural_collections')
    .doc(entry.slug);

  if (event === 'entry.delete') {
    await collectionRef.delete();
  } else {
    await collectionRef.set({
      name: entry.name,
      slug: entry.slug,
      description: entry.description,
      originTradition: entry.origin_tradition,
      historicalPeriod: entry.historical_period || null,
      accentColors: {
        primary: entry.accent_color_primary,
        secondary: entry.accent_color_secondary,
      },
      motifBorderSvgUrl: entry.motif_border_svg?.url || null,
      cardFrameSvgUrl: entry.card_frame_svg?.url || null,
      headerIllustrationUrl: entry.collection_header_illustration?.url || null,
      iconSvgUrl: entry.icon_svg?.url || null,
      displayOrder: entry.display_order || 0,
      storyCount: entry.stories?.length || 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  res.status(200).send('ok');
});
```

### D. Data Models & Schema

Covered comprehensively in section C above. Summary of all schema additions:

**Strapi additions:**

| Entity | Type | Fields Added |
|--------|------|-------------|
| `cultural_collection` | New content type | name, slug, description, origin_tradition, historical_period, accent_color_primary, accent_color_secondary, motif_border_svg, card_frame_svg, collection_header_illustration, icon_svg, stories (relation), display_order |
| `moral_lesson` | New component | moral_text, moral_text_hindi, attribution, display_style |
| `pronunciation_entry` | New component | term, language, phonetic_spelling, meaning, audio_clip |
| `story` (existing) | Extended | cultural_collection (relation), moral_lesson (component), pronunciation_guide (repeatable component), language_variants (self-relation) |

**Firestore additions:**

| Collection | Document | New Fields |
|------------|----------|-----------|
| `cultural_collections` (new) | `{collectionId}` | Full collection metadata (see section C) |
| `stories` (existing) | `{storyId}` | `culturalCollectionId`, `moralLesson`, `pronunciationGuide`, `languageVariants` |

**Firebase Storage structure:**

```
collections/
  panchatantra/
    motif_border.svg
    card_frame.svg
    header.svg
    icon.svg
  jataka/
    motif_border.svg
    card_frame.svg
    header.svg
    icon.svg
  tenali_raman/
    ...
  akbar_birbal/
    ...
pronunciation/
  dharma.mp3
  panchatantra.mp3
  ...
```

**Default collection definitions (seed data):**

| Collection | Accent Primary | Accent Secondary | Period | Description Summary |
|------------|---------------|-----------------|--------|-------------------|
| Panchatantra | #C8553D (terracotta) | #F4E285 (warm gold) | 3rd century BCE | Animal fables teaching statecraft and wisdom |
| Jataka Tales | #5B8C5A (sage green) | #E8D5B7 (parchment) | 4th century BCE | Stories of Buddha's previous lives |
| Tenali Raman | #8B5CF6 (purple) | #FCD34D (amber) | 16th century CE | Wit and humor of the Vijayanagara court jester |
| Akbar-Birbal | #DC2626 (red) | #FDE68A (light gold) | 16th century CE | Clever solutions from Emperor Akbar's wisest minister |

### E. UI/UX Specification

**Story browser — Folklore section:**

A dedicated horizontal section in the story browser titled "Indian Folklore" with the following layout:

```
┌──────────────────────────────────────────────┐
│  🏛️ Indian Folklore                    See All │
│                                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐     │
│  │ ╔═══════╗│  │ ┌───────┐│  │ ╭───────╮│     │
│  │ ║ cover ║│  │ │ cover ││  │ │ cover ││     │
│  │ ║ image ║│  │ │ image ││  │ │ image ││     │
│  │ ╚═══════╝│  │ └───────┘│  │ ╰───────╯│     │
│  │Panchatntra│  │ Jataka  │  │Tenali   │     │
│  │ 5 stories│  │3 stories│  │4 stories│     │
│  └─────────┘  └─────────┘  └─────────┘     │
│   terracotta     sage green    purple        │
│    border         border       border        │
└──────────────────────────────────────────────┘
```

**Cultural card frame:**

Each folklore tradition has a unique SVG border/frame that wraps its story cards:

- **Panchatantra:** Warm terracotta border with paisley corner motifs and a subtle lotus pattern.
- **Jataka:** Sage green border with Bodhi leaf corner motifs and a gentle vine pattern.
- **Tenali Raman:** Purple border with peacock feather corner motifs.
- **Akbar-Birbal:** Red and gold border with Mughal arch corner motifs.

The card frame SVG is rendered as an overlay on the standard story card. Implementation:

```dart
Stack(
  children: [
    // Standard story card content (cover image, title, etc.)
    StoryCard(story: story),
    // Cultural frame overlay
    if (story.culturalCollectionId != null)
      Positioned.fill(
        child: SvgPicture.network(
          collection.cardFrameSvgUrl!,
          fit: BoxFit.fill,
        ),
      ),
  ],
)
```

**Collection detail screen:**

Tapping "See All" or a collection card opens a dedicated screen:

```
┌──────────────────────────────────────────────┐
│  ← Back                                      │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │     [Collection Header Illustration]  │   │
│  │                                      │   │  150dp
│  │        P A N C H A T A N T R A      │   │
│  │   Ancient animal fables of wisdom    │   │
│  │        3rd century BCE               │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  5 Stories · 12 Endings to Discover          │
│                                              │
│  ┌──────────┐  ┌──────────┐                 │
│  │ [story1] │  │ [story2] │                 │
│  │ The Monkey│  │ The Clever│                 │
│  │ & Croc   │  │  Rabbit  │                 │
│  └──────────┘  └──────────┘                 │
│  ┌──────────┐  ┌──────────┐                 │
│  │ [story3] │  │ [story4] │                 │
│  └──────────┘  └──────────┘                 │
└──────────────────────────────────────────────┘
```

- Header uses the collection's accent colors as a gradient background.
- Collection header illustration SVG is displayed prominently.
- Story cards use the collection's card frame SVG.

**Moral lesson display (story completion):**

After completing a folklore story (before or integrated with the Story Completion Celebration, Feature 12), a "Wisdom Card" is displayed:

```
┌──────────────────────────────────────────────┐
│                                              │
│        ┌────────────────────────┐           │
│        │   ✦ Moral of the Story ✦  │           │
│        │                        │           │
│        │  "True friends stand   │           │
│        │   by each other even   │           │
│        │   in the face of       │           │
│        │   danger."             │           │
│        │                        │           │
│        │  — Panchatantra,       │           │
│        │    Book II             │           │
│        └────────────────────────┘           │
│                                              │
│        [Continue to Celebration →]           │
│                                              │
└──────────────────────────────────────────────┘
```

- The card has the collection's motif border SVG as its frame.
- Background: soft parchment texture (collection's secondary color at low opacity).
- Text: Baloo 2 font, collection's primary accent color.
- If Hindi text is available, it appears below the English text in a slightly smaller size with Devanagari script.
- Attribution text is italic, smaller, and slightly faded.

**Pronunciation guide (in-story):**

When a story has pronunciation entries, terms in the story text are underlined with a dotted line in the collection's primary accent color. Tapping a term shows a tooltip-style popup:

```
┌──────────────────────────────────────────┐
│                                          │
│  "The wise guru taught him about         │
│   d̲h̲a̲r̲m̲a̲ and the path of..."           │
│        ↑                                 │
│   ┌──────────────────┐                  │
│   │ dharma            │                  │
│   │ /dhar-ma/     🔊  │                  │
│   │                   │                  │
│   │ Righteous duty    │                  │
│   │ or moral law      │                  │
│   └──────────────────┘                  │
│                                          │
└──────────────────────────────────────────┘
```

- Popup appears below the tapped word.
- Phonetic spelling in gray, italic.
- Audio button plays the pronunciation clip (< 2 seconds).
- Popup dismisses on tap outside or after 5 seconds.

**Filter integration:**

The story browser's existing filter system gains a new "Tradition" filter:

| Filter | Options |
|--------|---------|
| Tradition | All, Panchatantra, Jataka Tales, Tenali Raman, Akbar-Birbal, Regional Folklore |

Each option shows the tradition's icon SVG next to the name.

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T37.1 | `CulturalCollection.fromJson` parses valid Firestore document | All fields populated correctly |
| T37.2 | `MoralLesson.fromJson` with Hindi text present | `textHindi` is non-null |
| T37.3 | `MoralLesson.fromJson` without Hindi text | `textHindi` is null, no error |
| T37.4 | `PronunciationEntry.fromJson` with audio clip | `audioClipUrl` is non-null |
| T37.5 | `PronunciationEntry.fromJson` without audio clip | `audioClipUrl` is null, no error |
| T37.6 | `Story` with `culturalCollectionId` set properly links to collection | `story.culturalCollectionId == 'panchatantra'` |
| T37.7 | `Story` without `culturalCollectionId` has null collection | `story.culturalCollectionId == null` |

**Widget tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T37.8 | Story card with cultural collection shows frame SVG overlay | `SvgPicture` for card frame found in widget tree |
| T37.9 | Story card without cultural collection shows no frame overlay | No card frame `SvgPicture` in tree |
| T37.10 | Collection detail screen renders header illustration | Header SVG present |
| T37.11 | Moral lesson card renders with correct text | Moral text visible |
| T37.12 | Moral lesson card renders Hindi text when available | Hindi text visible below English |
| T37.13 | Pronunciation popup appears on term tap | Popup widget found after tap |
| T37.14 | Pronunciation popup shows phonetic spelling and meaning | Both text elements present |
| T37.15 | "Indian Folklore" section appears in story browser | Section header and collection cards found |

**Integration tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T37.16 | Create a cultural collection in Strapi; verify it syncs to Firestore | Document appears in `cultural_collections` with correct data |
| T37.17 | Assign a story to a collection in Strapi; verify story document has `culturalCollectionId` | Field is set in Firestore |
| T37.18 | Browse stories filtered by "Panchatantra"; only Panchatantra stories appear | Filter works correctly |
| T37.19 | Complete a folklore story; moral lesson card appears before celebration | Moral displayed, then celebration |
| T37.20 | Tap a pronunciation term in story text; popup appears with audio playback | Audio plays on speaker tap |

**Content validation tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T37.21 | Upload a motif border SVG > 100KB to Strapi | Warning or rejection (max 100KB for decorative SVGs) |
| T37.22 | Create a story without required `moral_text` in moral_lesson component | Strapi validation error |
| T37.23 | Create a pronunciation entry without `phonetic_spelling` | Strapi validation error |

**Manual QA checklist:**

- [ ] Each of the 4 default collections has a visually distinct card frame and color palette.
- [ ] Card frames render correctly on various screen sizes without distortion.
- [ ] Collection detail screen header looks polished with the gradient and illustration.
- [ ] Moral lesson card appears at the right moment in the story completion flow.
- [ ] Hindi/Devanagari text renders correctly (no font fallback issues).
- [ ] Pronunciation audio clips play immediately on tap.
- [ ] Pronunciation popup does not obscure critical UI elements.
- [ ] "Tradition" filter in story browser works and shows correct icon per tradition.
- [ ] A non-folklore story shows no cultural collection UI treatments.
- [ ] Offline: downloaded folklore stories show card frames and moral lessons correctly without network.

---

## Feature 53: Weekly New Story Drops

### A. Overview & Purpose

**What:** A content cadence system ensuring at least one new story is published per week, supported by CMS scheduling, automated detection of new content, a "New This Week" section in the story browser, a "NEW" badge on recently published story cards, and a push notification on drop day. This is the operational and technical infrastructure that makes a regular content drumbeat possible.

**Why:** Consistent content cadence is the single most effective retention lever for content-driven apps. Industry data shows that apps with predictable new content schedules see 30-40% higher weekly retention than those with sporadic updates. The competitive analysis shows that Epic, Vooks, and Calm all release content on a regular cadence. TaleTrail must match this to prevent churn. Push notifications on drop day create a weekly touchpoint that re-engages dormant users. The "New This Week" section creates urgency and discovery.

**Success metric:** Target: 80%+ of weeks have at least one new story published. "New This Week" section click-through rate > 25%. Push notification open rate > 12%.

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B53.1 | Kid | When I open the app, I see a "New This Week" section at the top of the story browser showing stories that were added recently. | Must |
| B53.2 | Kid | New stories have a special "NEW" badge on their card that catches my attention. | Must |
| B53.3 | Parent | I receive a push notification when a new story is available, with the story's title and a short teaser. The notification arrives at an appropriate time (not during sleep hours). | Must |
| B53.4 | Parent | I can opt out of "new story" push notifications without opting out of other notifications. | Should |
| B53.5 | Content creator | I can schedule a story to publish at a specific date and time in the CMS. The story automatically becomes visible in the app at that time. | Must |
| B53.6 | Content creator | I can see a content calendar view in the CMS showing scheduled, published, and draft stories by week. | Should |
| B53.7 | Content creator | If no story is scheduled for the coming week, the CMS shows a warning. | Should |
| B53.8 | Developer | The "New This Week" section is always fresh — it pulls stories published in the last 7 days. If no stories were published this week, the section is hidden (not shown empty). | Must |

**Functional Requirements:**

1. Strapi stories gain a `scheduledPublishAt` datetime field. Stories in "Scheduled" status with a future datetime are not visible to the app until the datetime passes.
2. A Cloud Function runs on a cron schedule (every 15 minutes) to check for stories whose `scheduledPublishAt` has passed and transitions them from "Scheduled" to "Published."
3. When a story transitions to "Published," a Cloud Function triggers a push notification to subscribed parent devices.
4. The story browser includes a "New This Week" section that queries stories with `publishedAt` within the last 7 days, ordered by newest first.
5. Story cards for stories published in the last 7 days display a "NEW" badge.
6. The "NEW" badge automatically disappears after 7 days without any manual action.
7. Push notifications for new stories respect device quiet hours (10PM-7AM local time) and are delayed to the next morning if the story publishes during quiet hours.
8. A notification preference `newStoryNotifications` (default: true) controls whether a parent receives new story drop notifications.

### C. Technical Design & Architecture

**CMS changes (Strapi):**

Add to the `story` content type:

```json
{
  "scheduledPublishAt": {
    "type": "datetime",
    "pluginOptions": {
      "description": "Date and time this story should become visible. Leave empty for immediate publish."
    }
  },
  "publishStatus": {
    "type": "enumeration",
    "enum": ["draft", "scheduled", "published", "archived"],
    "default": "draft"
  }
}
```

**Strapi lifecycle hook — Auto-set status:**

```javascript
// src/api/story/content-types/story/lifecycles.js
module.exports = {
  beforeUpdate(event) {
    const { data } = event.params;
    // If scheduledPublishAt is set and is in the future, set status to 'scheduled'
    if (data.scheduledPublishAt && new Date(data.scheduledPublishAt) > new Date()) {
      data.publishStatus = 'scheduled';
    }
  },
};
```

**Cloud Function — Scheduled publisher (cron):**

```typescript
// functions/src/scheduledPublisher.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const publishScheduledStories = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // Query stories that are scheduled and past their publish time
    const snapshot = await admin.firestore()
      .collection('stories')
      .where('publishStatus', '==', 'scheduled')
      .where('scheduledPublishAt', '<=', now)
      .get();

    if (snapshot.empty) {
      console.log('No stories to publish.');
      return null;
    }

    const batch = admin.firestore().batch();
    const publishedStories: Array<{ id: string; title: string; coverUrl: string }> = [];

    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        publishStatus: 'published',
        publishedAt: now,
      });
      publishedStories.push({
        id: doc.id,
        title: doc.data().title,
        coverUrl: doc.data().coverImageUrl,
      });
    });

    await batch.commit();

    // Trigger push notifications for each published story
    for (const story of publishedStories) {
      await triggerNewStoryNotification(story);
    }

    console.log(`Published ${publishedStories.length} stories.`);
    return null;
  });

async function triggerNewStoryNotification(story: { id: string; title: string; coverUrl: string }) {
  const message: admin.messaging.Message = {
    topic: 'new_story_drops',
    notification: {
      title: 'A New Adventure Awaits!',
      body: `"${story.title}" just arrived in TaleTrail. Tap to start reading!`,
      imageUrl: story.coverUrl,
    },
    data: {
      type: 'new_story',
      storyId: story.id,
    },
    android: {
      notification: {
        channelId: 'new_stories',
        priority: 'default' as const,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          'thread-id': 'new_stories',
        },
      },
    },
  };

  await admin.messaging().send(message);
}
```

**Cloud Function — Content gap warning (weekly cron):**

```typescript
export const checkContentCadence = functions.pubsub
  .schedule('every monday 09:00')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const oneWeekFromNow = new Date();
    oneWeekFromNow.setDate(oneWeekFromNow.getDate() + 7);

    // Check if any stories are scheduled for the next 7 days
    const snapshot = await admin.firestore()
      .collection('stories')
      .where('publishStatus', '==', 'scheduled')
      .where('scheduledPublishAt', '<=', admin.firestore.Timestamp.fromDate(oneWeekFromNow))
      .where('scheduledPublishAt', '>', admin.firestore.Timestamp.now())
      .get();

    if (snapshot.empty) {
      // Send alert to admin (email or Slack webhook)
      console.warn('CONTENT GAP: No stories scheduled for the coming week!');
      // TODO: Integrate with notification channel (email/Slack)
    }

    return null;
  });
```

**Flutter — "New This Week" provider:**

```dart
final newThisWeekStoriesProvider = FutureProvider<List<Story>>((ref) async {
  final storyRepo = ref.watch(storyRepositoryProvider);
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  return storyRepo.getStoriesPublishedAfter(sevenDaysAgo);
});
```

**Repository query:**

```dart
Future<List<Story>> getStoriesPublishedAfter(DateTime since) async {
  final snapshot = await _firestore
    .collection('stories')
    .where('publishStatus', isEqualTo: 'published')
    .where('publishedAt', isGreaterThan: Timestamp.fromDate(since))
    .orderBy('publishedAt', descending: true)
    .limit(10) // Cap at 10 new stories shown
    .get();

  return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
}
```

**Push notification subscription management:**

```dart
class NotificationPreferencesService {
  final FirebaseMessaging _messaging;

  Future<void> setNewStoryNotifications(bool enabled) async {
    if (enabled) {
      await _messaging.subscribeToTopic('new_story_drops');
    } else {
      await _messaging.unsubscribeFromTopic('new_story_drops');
    }
    // Persist preference locally
    await _prefs.setBool('newStoryNotifications', enabled);
  }
}
```

**Deep link handling for notification tap:**

When a user taps the push notification, the app opens and navigates directly to the new story's detail page:

```dart
// In notification handler
void handleNotificationTap(Map<String, dynamic> data) {
  if (data['type'] == 'new_story') {
    final storyId = data['storyId'] as String;
    GoRouter.of(context).go('/stories/$storyId');
  }
}
```

### D. Data Models & Schema

**Strapi — Story content type additions:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `scheduledPublishAt` | datetime | No | null | When to auto-publish. Null = manual publish. |
| `publishStatus` | enum | Yes | "draft" | One of: draft, scheduled, published, archived |

**Firestore — Story document additions:**

```
/stories/{storyId}
{
  ...existing fields...,
  "publishStatus": "published",           // string enum
  "publishedAt": Timestamp,               // server timestamp, set on publish
  "scheduledPublishAt": Timestamp | null   // null if manually published
}
```

**Firestore — Notification preferences (existing user profile):**

```
/users/{userId}/settings/notifications
{
  "newStoryNotifications": true,    // default true
  "streakReminders": true,
  "weeklyReport": true
}
```

**Firestore indexes required:**

```
Collection: stories
Fields: publishStatus ASC, publishedAt DESC
Query: Get published stories ordered by newest
```

```
Collection: stories
Fields: publishStatus ASC, scheduledPublishAt ASC
Query: Find scheduled stories past their publish time
```

**FCM topic:**

| Topic | Description | Subscribes |
|-------|-------------|-----------|
| `new_story_drops` | New story published notifications | All users with `newStoryNotifications: true` |

**Android notification channel:**

| Channel ID | Name | Importance | Description |
|------------|------|-----------|-------------|
| `new_stories` | New Stories | Default | Notifications when new stories are added to TaleTrail |

### E. UI/UX Specification

**"New This Week" section in story browser:**

Position: First section in the story browser, above "Continue Reading" and "Popular" sections.

```
┌──────────────────────────────────────────────┐
│                                              │
│  ✨ New This Week                            │
│                                              │
│  ┌─────────────┐  ┌─────────────┐           │
│  │ ┌───┐       │  │ ┌───┐       │           │
│  │ │NEW│ cover  │  │ │NEW│ cover  │           │
│  │ └───┘ image  │  │ └───┘ image  │           │
│  │              │  │              │           │
│  │ The Dragon's │  │ Akbar's     │           │
│  │ Garden       │  │ Riddle      │           │
│  │ Age 6-8      │  │ Age 8-10    │           │
│  └─────────────┘  └─────────────┘           │
│                                              │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│                                              │
│  📖 Continue Reading                         │
│  ...                                         │
└──────────────────────────────────────────────┘
```

- Section title: "New This Week" with a subtle sparkle icon (SVG, not emoji).
- The section is hidden entirely if there are no stories published in the last 7 days.
- Story cards in this section are horizontally scrollable.
- Maximum 10 cards shown (capped by query).

**"NEW" badge:**

| Property | Value |
|----------|-------|
| Position | Top-left corner of story card, overlapping the cover image by 4dp |
| Background | Solid primary brand color (#C8553D terracotta, or story accent color) |
| Text | "NEW" in white, Nunito Bold, 10sp |
| Shape | Rounded pill, 8dp vertical padding, 12dp horizontal padding |
| Corner radius | 12dp |
| Shadow | Subtle drop shadow (elevation 2) |
| Duration | Automatically hidden after 7 days based on `publishedAt` |

**Implementation logic for badge visibility:**

```dart
bool isNew(Story story) {
  if (story.publishedAt == null) return false;
  return DateTime.now().difference(story.publishedAt!).inDays < 7;
}
```

**Push notification:**

| Property | Value |
|----------|-------|
| Title | "A New Adventure Awaits!" |
| Body | `"${storyTitle}" just arrived in TaleTrail. Tap to start reading!` |
| Image | Story cover image (large notification style on Android, media attachment on iOS) |
| Tap action | Deep link to story detail screen |
| Channel (Android) | "New Stories" (default importance) |
| Sound | Default system notification sound |
| Quiet hours | 10PM-7AM local time — notification queued for 7:05AM |

**Notification preferences (parent dashboard):**

Under Parent Dashboard > Settings > Notifications:

```
┌──────────────────────────────────────────────┐
│  Notifications                               │
│                                              │
│  New Story Alerts              [  ON  ]      │
│  Get notified when new                       │
│  stories are added.                          │
│                                              │
│  Reading Streak Reminders      [  ON  ]      │
│  Gentle reminders to keep                    │
│  the streak going.                           │
│                                              │
│  Weekly Reading Report         [  ON  ]      │
│  Summary of your child's                     │
│  reading activity.                           │
│                                              │
└──────────────────────────────────────────────┘
```

**CMS content calendar (Strapi admin):**

A custom Strapi admin page (or plugin) showing a weekly calendar view:

```
┌──────────────────────────────────────────────────────────────┐
│  Content Calendar — May 2026                                 │
│                                                              │
│  Mon   Tue   Wed   Thu   Fri   Sat   Sun                    │
│  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐               │
│  │     │     │     │     │ 📗  │     │     │  Week 20      │
│  │     │     │     │     │pub'd│     │     │  "Dragon's    │
│  │     │     │     │     │     │     │     │   Garden"     │
│  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤               │
│  │     │     │     │     │ 📘  │     │     │  Week 21      │
│  │     │     │     │     │schd │     │     │  "Akbar's    │
│  │     │     │     │     │     │     │     │   Riddle"    │
│  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤               │
│  │     │     │     │     │ ⚠️  │     │     │  Week 22      │
│  │     │     │     │     │NONE │     │     │  NO STORY    │
│  │     │     │     │     │     │     │     │  SCHEDULED   │
│  └─────┴─────┴─────┴─────┴─────┴─────┴─────┘               │
│                                                              │
│  Legend: 📗 Published  📘 Scheduled  📝 Draft  ⚠️ Gap       │
└──────────────────────────────────────────────────────────────┘
```

- Weeks with no scheduled or published stories show a warning indicator.
- Clicking a story in the calendar navigates to its Strapi edit page.
- The calendar is a nice-to-have enhancement. MVP of this feature works without it (using the standard Strapi list view filtered by `scheduledPublishAt`).

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T53.1 | `isNew(story)` returns true for story published 3 days ago | `true` |
| T53.2 | `isNew(story)` returns false for story published 8 days ago | `false` |
| T53.3 | `isNew(story)` returns false for story with null `publishedAt` | `false` |
| T53.4 | `isNew(story)` returns true for story published today | `true` |
| T53.5 | Notification preference toggle subscribes/unsubscribes from FCM topic | Verify topic subscription call |

**Cloud Function tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T53.6 | `publishScheduledStories` with one story past `scheduledPublishAt` | Story status updated to "published"; `publishedAt` set; notification sent |
| T53.7 | `publishScheduledStories` with no stories past schedule | No updates; no notifications |
| T53.8 | `publishScheduledStories` with story scheduled in the future | Story status remains "scheduled" |
| T53.9 | `checkContentCadence` with no stories scheduled for next week | Warning logged (or alert sent) |
| T53.10 | `checkContentCadence` with a story scheduled for next week | No warning |

**Widget tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T53.11 | "New This Week" section renders when there are new stories | Section visible with correct stories |
| T53.12 | "New This Week" section hidden when no stories in last 7 days | Section not in widget tree |
| T53.13 | "NEW" badge appears on story card for story published 2 days ago | Badge widget present |
| T53.14 | "NEW" badge absent on story card for story published 10 days ago | Badge widget absent |
| T53.15 | Notification preference toggle changes state | Switch reflects new value |

**Integration tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T53.16 | Schedule a story in Strapi for 5 minutes from now; wait; verify it appears in app | Story transitions to published; appears in "New This Week" |
| T53.17 | Publish a story; verify push notification is received on a subscribed device | Notification appears with correct title and story name |
| T53.18 | Tap push notification; app opens to the correct story detail screen | Deep link navigates to story |
| T53.19 | Opt out of new story notifications; publish a story; verify no notification received | No notification on opted-out device |
| T53.20 | Publish a story at 11PM local time; verify notification is delayed until 7:05AM | Notification arrives after quiet hours |

**Manual QA checklist:**

- [ ] "New This Week" section shows only stories from the last 7 days.
- [ ] Section scrolls horizontally if more than 2-3 new stories.
- [ ] "NEW" badge is visually prominent but not garish.
- [ ] "NEW" badge disappears exactly 7 days after publish date.
- [ ] Push notification displays story cover image on Android (expanded view) and iOS.
- [ ] Tapping notification opens the correct story, even if the app was killed.
- [ ] Notification preference toggle in parent dashboard works and persists.
- [ ] CMS `scheduledPublishAt` field accepts date/time input correctly.
- [ ] A story in "Scheduled" status is not visible in the app before its scheduled time.
- [ ] The 15-minute cron job publishes stories within 15 minutes of their scheduled time (max delay).

---

## Batch 14 Summary

| Feature | Effort | New Packages | Firestore Changes | Strapi Changes | Cloud Functions |
|---------|--------|-------------|-------------------|---------------|----------------|
| 49 — Parallax Layers | M | `sensors_plus` | Parallax layer URLs on story steps | 3 optional media fields on story_step | None |
| 51 — Audio Waveform | S | None | None | None | None |
| 52 — Download Animation | S | None | None | None | None |
| 37 — Indian Folklore | S (tech) | None | `cultural_collections` collection; extended story fields | `cultural_collection` content type; `moral_lesson` and `pronunciation_entry` components | `syncCulturalCollection` webhook handler |
| 53 — Weekly Drops | S (tech) | None | `publishStatus`, `scheduledPublishAt`, `publishedAt` on stories; notification prefs | `scheduledPublishAt` and `publishStatus` fields on story | `publishScheduledStories` cron; `checkContentCadence` cron |

**Recommended build order within this batch:**

1. Feature 53 (Weekly Drops) — Enables content scheduling immediately, unblocking content operations.
2. Feature 37 (Indian Folklore) — Schema and CMS work that unblocks content creators to start building folklore stories.
3. Feature 51 (Audio Waveform) — Small, self-contained, quick win for visual polish.
4. Feature 52 (Download Animation) — Small, self-contained, requires Lottie asset creation.
5. Feature 49 (Parallax Layers) — Largest effort, requires per-story SVG layer creation.
