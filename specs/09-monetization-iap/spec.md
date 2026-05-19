# Spec 9: Monetization & IAP

| Field | Value |
|-------|-------|
| **Feature** | Monetization & In-App Purchases |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | Post-MVP |
| **Features Covered** | #24 Subscription & IAP Backend, #25 Premium Story Packs, #26 Free Story of the Week |
| **Estimated Effort** | ~55h (7 days) |

---

## Overview

RevenueCat-powered subscriptions (monthly/annual) and one-time story pack purchases. All purchase flows gated behind parental PIN. Free Story of the Week rotation for upsell and engagement.

### User Stories

- As a parent, I can subscribe monthly or annually for unlimited access to all stories.
- As a parent, I can buy themed story packs as one-time purchases.
- As a kid, I see a kid-friendly "Ask a grown-up" message when tapping locked content (never a direct purchase prompt).
- As any user, I can enjoy one rotating free premium story each week.
- As a parent, I can restore my purchases on a new device.

### Acceptance Criteria

1. RevenueCat SDK integrated on iOS + Android. Monthly (~₹199/$4.99) + annual (~₹1999/$39.99) subscription tiers.
2. Story packs: themed bundles of 3-5 stories (~₹149/$2.99 one-time). Server-side receipt verification.
3. Entitlements stored in Firestore. Parental gate required before any purchase flow. "Restore Purchases" button in parent settings.
4. Free Story of the Week: rotated weekly, marked in API response. Grace period: 3 days after rotation.

---

## Architecture

### Firestore Schema

```
parents/{parentId}/entitlements/subscription
  type: "monthly" | "annual" | null
  status: "active" | "expired" | "grace_period" | "cancelled"
  expiresAt: timestamp
  store: "app_store" | "play_store"
  revenuecatId: string

parents/{parentId}/entitlements/packs
  purchasedPacks: array<string>  // pack IDs

config/freeStoryOfWeek
  storyId: string
  startsAt: timestamp
  endsAt: timestamp
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/purchases/verify` | RevenueCat webhook for receipt verification |
| GET | `/api/v1/entitlements` | Get user's current entitlements |
| GET | `/api/v1/config/free-story` | Get current Free Story of the Week |

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | RevenueCat project setup | Create RevenueCat project, configure App Store Connect + Google Play Console products | 3h |
| 2 | RevenueCat product config | Define offerings: monthly, annual, story packs. Configure entitlements. | 3h |
| 3 | Purchase repository | RevenueCat SDK wrapper: `getOfferings()`, `purchasePackage()`, `restorePurchases()`, `customerInfo` stream | 6h |
| 4 | Entitlement repository | Check subscription/pack access. Local cache + Firestore + RevenueCat triple-check. | 4h |
| 5 | Monetization provider | Riverpod provider for entitlements, offerings, purchase state, loading/error handling | 4h |
| 6 | Subscription screen | Monthly vs annual comparison. Feature list. Restore link. Parent-aesthetic design (warm, not aggressive). | 6h |
| 7 | Story packs screen | Pack cards: name, story count, price, cover art. Purchase button (gated behind parental PIN). | 4h |
| 8 | Premium badge + upgrade prompt | Lock icon on premium cards. Kid-friendly "Ask a grown-up" message (never a buy button). | 3h |
| 9 | Free Story badge | "Free This Week" banner on story card. Entitlement override logic for free story access. | 2h |
| 10 | Webhook handler | Cloud Function: RevenueCat notifications → parse event → update Firestore entitlements | 6h |
| 11 | Entitlement sync | Server-side entitlement management. Handle grace periods (3 days), cancellations, refunds. | 4h |
| 12 | Story access gating | Check entitlement before loading premium story tree. Block with upgrade prompt if unauthorized. | 3h |
| 13 | Free Story rotation | Admin config in Firestore. Optional Cloud Scheduler for automatic weekly rotation (Friday). | 3h |
| 14 | Restore purchases | Button in parent settings. RevenueCat restore flow. Update local + Firestore state. | 2h |

### Dependencies

`purchases_flutter` (RevenueCat SDK)

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Purchase fails mid-flow | Show error, offer retry. No charge recorded until receipt verified. |
| Subscription expires | Downgrade to free tier. Keep downloaded premium content but block playback. |
| Grace period | 3-day grace period after expiry. Show "Renew soon" banner. |
| Restore on new device | RevenueCat handles cross-device restore via store account. |
| Refund processed | RevenueCat webhook → revoke entitlement → update Firestore. |
| Network down during purchase | Store handles retry. RevenueCat reconciles on next sync. |
| Kid taps premium content | "Ask a grown-up" message. Never show price or purchase button to kids. |
| Family sharing | RevenueCat supports App Store family sharing. Play Store family library. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Entitlement check logic (active, expired, grace period). Pack ownership. Free story date range. |
| **Integration** | Purchase flow (sandbox): select → parental gate → purchase → entitlement updated → content unlocked. |
| **Manual** | Sandbox testing on iOS + Android. Restore purchases. Subscription lifecycle (renew, cancel, expire). |

---

## Effort Estimate

**Total: ~55h (7 days)**
