# Tasks: Notifications, Reports & Sharing

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 12 |
| **Total Estimated Effort** | ~51h |
| **Phase** | Post-MVP |
| **Sprint** | 17-18 |
| **Status** | 🚧 Partially Complete (2 tasks done, 10 pending) |

---

## Phase 1: FCM Setup & Settings (~10h)

- [ ] **Task 1:** FCM setup — Add `firebase_messaging` package to Flutter app. Configure iOS APNs certificates + Android FCM. Implement token management (register, refresh, persist). *(4h)* — **Package not added yet; implement when push notifications are prioritized.**
- [ ] **Task 2:** Notification settings repository — CRUD for notification preferences in Firestore (`notifications/settings`). FCM token registration and update. *(3h)* — **Not implemented yet.** Preferences currently saved direct to Firestore in screen.
- [x] **Task 3:** Notification settings screen — `notification_preferences_screen.dart` (279 lines): loads/saves from Firestore `parents/{uid}/settings/notifications`. Switches for newStoryNotifications, streakReminders, weeklyReportEmail, quietHoursEnabled. Time pickers for quiet hours start/end. "Save" action in AppBar. *(3h)*

## Phase 2: Push Notification Cloud Functions (~14h)

- [ ] **Task 4:** Re-engagement Cloud Function — Daily Cloud Scheduler (10AM): query kids with 3+ days since last read, check parent's quiet hours and timezone, send personalized FCM notification via Admin SDK. *(5h)* — **Backend task.**
- [ ] **Task 5:** New story notification Function — Strapi webhook trigger on story publish: fan out to all opted-in parents with "New story available!" notification. *(3h)* — **Backend task.**
- [ ] **Task 6:** Streak risk Cloud Function — Evening Cloud Scheduler (7PM): find kids with active streak who haven't read today, send "Don't break the streak!" notification to parent. *(4h)* — **Backend task.**
- [ ] **Task 7:** Notification templates — Define title/body templates per notification type. Dynamic content insertion: kid name, story title, streak count. *(2h)* — **Backend task.**

## Phase 3: Reading Reports (~15h)

- [ ] **Task 8:** Report aggregation Cloud Function — Weekly scheduler (Sunday 6AM): query all progress data for the week, compute per-kid statistics, write report document to Firestore. *(6h)* — **Backend task.**
- [x] **Task 9:** Report screen — `reading_reports_screen.dart` (315 lines): `FutureBuilder` over Firestore gamification stats. Stats grid (2×2): stories read, endings found, day streak, minutes read. Recent activity list. Favorite theme card. *(5h)* — **Note:** pulls from gamification stats, not a Cloud Function report. Full charting pending backend.
- [ ] **Task 10:** Email digest — SendGrid integration: HTML email template with per-kid stats, "Open TaleTrail" CTA. *(4h)* — **Backend task.**

## Phase 4: Share Endings (~7h)

- [ ] **Task 11:** Share card generator — `RepaintBoundary` to capture widget as image. Illustrated card with cover + ending title + branding. *(5h)* — **Not implemented yet.**
- [ ] **Task 12:** Share button — System share sheet via `share_plus` on story completion and endings screen. *(2h)* — **Not implemented yet.**
