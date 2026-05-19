# Tasks: Analytics & Remote Config

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 11 |
| **Total Estimated Effort** | ~39h |
| **Phase** | Post-MVP |
| **Sprint** | 11-12 |
| **Status** | 🚧 Partially Complete (1 task done, 10 pending) |

---

## Phase 1: Client-Side Analytics (~7h)

- [ ] **Task 1:** Anonymous session ID — Daily-rotating UUID v4 stored in SharedPreferences. Auto-cleanup of previous day's session IDs on new day. *(1h)* — **Not implemented yet.**
- [ ] **Task 2:** Analytics service — `AnalyticsService` with `trackEvent(name, properties)`. Queue events in memory buffer. Attach anonymous session ID and timestamp. *(3h)* — **Not implemented yet.**
- [ ] **Task 3:** Event batching — Batch queued events. Flush to Firestore every 30s or on app background. Max batch 50 events. Persist undelivered batches. *(3h)* — **Not implemented yet.**

## Phase 2: Server-Side Processing (~15h)

- [ ] **Task 4:** Event processor Cloud Function — Hourly aggregation of raw event batches per story (start counts, completion counts, choice distributions). Write daily summary documents. *(6h)* — **Backend task.**
- [ ] **Task 5:** Aggregation service — Rollup pipeline: daily → weekly → monthly. Popularity rankings, completion rates, drop-off identification. *(5h)* — **Backend task.**
- [ ] **Task 6:** Analytics API for CMS — `GET /analytics/stories`, `/analytics/stories/:id/funnel`, `/analytics/stories/:id/choices`. *(4h)* — **Backend task.**

## Phase 3: CMS Dashboard (~6h)

- [ ] **Task 7:** CMS analytics dashboard — Strapi admin panel plugin with popularity bar chart, completion funnel, choice distribution heatmap, drop-off indicators. *(6h)* — **Backend task.**

## Phase 4: Feature Flags (~10h)

- [x] **Task 8:** Remote Config setup — `firebase_remote_config` in `pubspec.yaml`. `AppInitializer._fetchRemoteConfig()` initializes with 6 defaults: `parallax_enabled`, `bedtime_mode_enabled`, `max_offline_stories:10`, `content_refresh_interval_hours:6`, `force_update_min_version:"1.0.0"`, `maintenance_mode:false`. Graceful fallback on fetch error. *(2h)*
- [ ] **Task 9:** Feature flag definitions — Typed `FeatureFlags` Dart class wrapping Remote Config values with getters. Define all flags in Firebase Console. *(2h)* — **Partial:** defaults defined in `AppInitializer`; standalone `FeatureFlags` class pending.
- [ ] **Task 10:** Flag integration across app — Gate features behind `FeatureFlags` checks: bedtime mode UI, reading streaks, ambient particles, maintenance mode screen, force update dialog. *(4h)* — **Not implemented yet.**
- [ ] **Task 11:** Percentage rollout — Firebase Installation ID percentile computation for gradual rollouts. *(2h)* — **Not implemented yet.**
