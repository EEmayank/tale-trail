# Spec 11: Notifications, Reports & Sharing

| Field | Value |
|-------|-------|
| **Feature** | Notifications, Reports & Sharing |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | Post-MVP |
| **Features Covered** | #31 Smart Push Notifications, #32 Parent Reading Reports, #33 Share Story Endings |
| **Estimated Effort** | ~51h (6-7 days) |

---

## Overview

FCM push notifications for re-engagement (sent to parent device only, respecting quiet hours). Weekly reading reports with per-kid breakdown (in-app + optional email digest). Shareable illustrated ending cards for viral loops via WhatsApp/Instagram Stories.

### Acceptance Criteria

1. **Push Notifications:** FCM on iOS + Android. Parent device only. Quiet hours (9PM-8AM local). Types: re-engagement (3+ days inactive), new story published, streak at risk (evening before break).
2. **Reading Reports:** Weekly per-kid report: stories read, total time, genre distribution, endings discovered, streak status. In-app report screen with charts. Optional email digest (SendGrid).
3. **Share Endings:** After completing a story, generate illustrated sharing card with story cover + ending title + TaleTrail branding. Share via system share sheet (WhatsApp, Instagram Stories, etc.).

---

## Architecture

### Firestore Schema

```
parents/{parentId}/notifications/settings
  enabled: boolean
  quietHoursStart: string ("21:00")
  quietHoursEnd: string ("08:00")
  reEngagementEnabled: boolean
  newStoryEnabled: boolean
  streakRiskEnabled: boolean
  emailDigestEnabled: boolean
  fcmToken: string
  timezone: string

parents/{parentId}/reports/{weekId}
  weekStart: timestamp
  weekEnd: timestamp
  kids: map<kidId, {
    storiesRead: number,
    totalMinutes: number,
    genreDistribution: map<string, number>,
    endingsDiscovered: number,
    currentStreak: number,
    favoriteGenre: string
  }>
  generatedAt: timestamp
```

### Cloud Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `sendReEngagement` | Cloud Scheduler (daily 10AM) | Find parents with 3+ day inactive kids, send notification |
| `sendNewStoryNotification` | Strapi webhook (story published) | Notify all opted-in parents |
| `sendStreakRisk` | Cloud Scheduler (daily 7PM) | Find kids with active streak who haven't read today |
| `generateWeeklyReport` | Cloud Scheduler (Sunday 6AM) | Aggregate weekly stats per kid per parent |
| `sendEmailDigest` | After report generation | SendGrid email for opted-in parents |

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | FCM setup | Add `firebase_messaging` package. Configure iOS APNs + Android. Token management. | 4h |
| 2 | Notification settings repo | CRUD for notification preferences in Firestore. FCM token registration. | 3h |
| 3 | Notification settings screen | Toggles for each notification type, quiet hours config, email digest opt-in. | 3h |
| 4 | Re-engagement Cloud Function | Daily scheduler: query inactive kids (3+ days), check quiet hours/timezone, send FCM via Admin SDK. | 5h |
| 5 | New story notification Function | Webhook trigger on Strapi publish → fan out to opted-in parents with notification. | 3h |
| 6 | Streak risk Cloud Function | Evening scheduler: find kids with active streak + no reading today → notify parent. | 4h |
| 7 | Notification templates | Title/body templates per type. Dynamic content (kid name, story title, streak count). | 2h |
| 8 | Report aggregation Function | Weekly Cloud Function: query progress data, compute per-kid stats, write report document. | 6h |
| 9 | Report screen | In-app weekly report with charts (bar chart for genres, line for daily activity). Per-kid tabs. | 5h |
| 10 | Email digest | SendGrid integration: HTML email template, per-kid stats table, "Open TaleTrail" CTA. | 4h |
| 11 | Share card generator | `RepaintBoundary` → capture widget as image. Compose card: story cover + ending title + TaleTrail branding. | 5h |
| 12 | Share button | Share button on completion screen + endings collection. System share sheet via `share_plus`. | 2h |

### Dependencies

**Flutter:** `firebase_messaging`, `share_plus`, `screenshot`, `fl_chart`
**Backend:** `@sendgrid/mail`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| FCM token refresh | Re-register on `onTokenRefresh` callback. Update Firestore. |
| Quiet hours across midnight | Handle wrap-around: 9PM-8AM means skip if hour >= 21 OR hour < 8. |
| No reading data for week | Generate report with "No reading this week" message + encouragement. |
| Share image generation fails | Fallback to text-only share: "I just finished [story]! Try TaleTrail." |
| SendGrid rate limit | Batch emails with delay. Retry with backoff. |
| User revokes notification permission | Respect OS setting. Show in-app prompt to re-enable if opted in. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Quiet hours logic. Report aggregation math. Share card composition. |
| **Integration** | Cloud Function triggers → Firestore updates → notification sent (emulator). |
| **Manual** | Push notification display on iOS + Android. Email digest formatting. Share card quality. |

---

## Effort Estimate

**Total: ~51h (6-7 days)**
