# Spec 14: Analytics & Remote Config

| Field | Value |
|-------|-------|
| **Feature** | Analytics & Remote Config |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | Post-MVP |
| **Features Covered** | #40 Analytics Pipeline, #45 Feature Flags / Remote Config |
| **Estimated Effort** | ~39h (5 days) |

---

## Overview

Privacy-safe anonymized analytics pipeline for story engagement metrics (no child PII, daily-rotating session IDs). Firebase Remote Config for feature flags, percentage rollouts, A/B testing, maintenance mode, and forced app updates.

### Acceptance Criteria

1. **Analytics:** Events tracked: `story_started`, `story_completed`, `step_viewed`, `choice_selected`, `story_downloaded`. Batched client-side, processed hourly into daily summaries. Raw events deleted after 24h.
2. **Privacy:** No child PII in analytics. Session IDs rotate daily (UUID v4). Aggregated data only. COPPA/DPDP compliant.
3. **CMS Dashboard:** Story popularity, completion funnels, choice distribution heatmap, drop-off points.
4. **Feature Flags:** `enable_bedtime_mode`, `enable_streaks`, `enable_ambient_particles`, `maintenance_mode`, `min_app_version`. Percentage rollout using Firebase Installation ID percentile.

---

## Architecture

### Analytics Events

| Event | Properties | When |
|-------|-----------|------|
| `story_started` | storyId, ageGroup, language, isFree | Story player opens |
| `story_completed` | storyId, endingId, durationMs, stepCount | Ending step reached |
| `step_viewed` | storyId, stepId, durationMs | Step displayed |
| `choice_selected` | storyId, stepId, choiceId | Choice button tapped |
| `story_downloaded` | storyId, sizeBytes | Download completes |

### Session ID

```dart
// Rotates daily — no persistent user tracking
String get anonymousSessionId {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final cached = _prefs.getString('session_$today');
  if (cached != null) return cached;
  final newId = Uuid().v4();
  _prefs.setString('session_$today', newId);
  _cleanOldSessions(); // Remove sessions older than today
  return newId;
}
```

### Feature Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `enable_bedtime_mode` | bool | false | Toggle bedtime mode feature |
| `enable_streaks` | bool | false | Toggle reading streaks |
| `enable_ambient_particles` | bool | false | Toggle ambient particles |
| `maintenance_mode` | bool | false | Show maintenance screen |
| `min_app_version` | string | "1.0.0" | Force update if below |
| `free_story_rotation_enabled` | bool | true | Toggle free story weekly rotation |

### Data Pipeline

```
Client (batch events, 30s flush)
  → Firestore: analytics/raw/{date}/{batchId}
  → Cloud Function (hourly): process raw → daily aggregates
  → Firestore: analytics/daily/{date}/stories/{storyId}
  → Cloud Function (daily): daily → weekly/monthly rollups
  → Firestore: analytics/weekly/{weekId}, analytics/monthly/{monthId}
  → CMS API: read aggregated data for dashboard
```

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Anonymous session ID | Daily-rotating UUID. Stored in SharedPreferences. Auto-cleanup of old IDs. | 1h |
| 2 | Analytics service | Event logging: `trackEvent(name, properties)`. Queue events in memory. | 3h |
| 3 | Event batching | Batch events locally. Flush to Firestore every 30s or on app background. Max batch size: 50 events. | 3h |
| 4 | Event processor Function | Hourly Cloud Function: read raw events, aggregate per story (starts, completions, choice distributions), write daily summary. Delete raw events. | 6h |
| 5 | Aggregation service | Daily → weekly → monthly rollups. Compute: popularity ranking, completion rates, average duration, choice distribution percentages, drop-off step identification. | 5h |
| 6 | Analytics API for CMS | REST endpoints for CMS dashboard: `GET /analytics/stories`, `GET /analytics/stories/:id/funnel`, `GET /analytics/stories/:id/choices`. | 4h |
| 7 | CMS analytics dashboard | Strapi admin panel plugin: story popularity chart, completion funnel visualization, choice distribution heatmap, drop-off point indicators. | 6h |
| 8 | Remote Config setup | Initialize Firebase Remote Config in Flutter app. Set fetch interval (12h production, 0 debug). | 2h |
| 9 | Feature flag definitions | Define all flags in Firebase Console with defaults. Create `FeatureFlags` class wrapping Remote Config values. | 2h |
| 10 | Flag integration across app | Gate features behind `FeatureFlags` checks: bedtime mode, streaks, particles, maintenance screen, force update dialog. | 4h |
| 11 | Percentage rollout | Use Firebase Installation ID percentile (0-99) for gradual rollouts. Flag config includes `rollout_percentage` parameter. | 2h |

### Dependencies

`firebase_remote_config`, `uuid`, `shared_preferences`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Analytics batch fails to flush | Retry on next interval. Persist undelivered batches to local storage. Cap at 500 events. |
| Clock manipulation (session ID) | Accept device clock. No security-critical dependency on session ID. |
| Remote Config fetch fails | Use cached values. If no cache, use hardcoded defaults. |
| Maintenance mode activated | Show full-screen maintenance message. Block all navigation. Allow force-dismiss after 24h. |
| Forced update | Compare `min_app_version` with current. Show non-dismissible update dialog if below minimum. |
| Analytics volume spike | Hourly processor has 540s timeout. If exceeded, process in chunks. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Session ID rotation logic. Event batching (flush timing, max size). Aggregation math. Flag evaluation with percentile. |
| **Integration** | Track events → verify raw documents → run processor → verify aggregates. Remote Config fetch → flag values applied. |
| **Manual** | CMS dashboard visual verification. Maintenance mode display. Force update dialog. |

---

## Effort Estimate

**Total: ~39h (5 days)**
