# Tasks: Monetization & IAP

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 14 |
| **Total Estimated Effort** | ~55h |
| **Phase** | Post-MVP |
| **Sprint** | 13-14 |
| **Status** | 🚧 Partially Complete (1 task done, 13 pending) |

---

## Phase 1: Store & SDK Setup (~6h)

- [ ] **Task 1:** RevenueCat project setup — Create RevenueCat project. Configure App Store Connect products (monthly, annual subscriptions) and Google Play Console products. *(3h)* — **External setup.**
- [ ] **Task 2:** RevenueCat product config — Define offerings (monthly, annual, story packs), configure entitlements, set up sandbox testing. *(3h)* — **External setup.**

## Phase 2: Purchase Infrastructure (~14h)

- [ ] **Task 3:** Purchase repository — RevenueCat SDK wrapper: `getOfferings()`, `purchasePackage()`, `restorePurchases()`, `customerInfo` stream. Handle platform differences. *(6h)*
- [ ] **Task 4:** Entitlement repository — Check subscription and pack access with triple verification: local cache → Firestore → RevenueCat. Grace period logic. *(4h)*
- [ ] **Task 5:** Monetization provider — Riverpod provider managing entitlements, offerings, purchase state, loading/error states. *(4h)*

## Phase 3: Purchase UI (~15h)

- [x] **Task 6:** Subscription screen — `subscription_screen.dart`: gradient hero section, feature checklist, Monthly (₹199/mo, free trial) and Annual (₹1,499/yr, "Save 37%") plan cards, "Start Free Trial" button shows "Coming soon" SnackBar (RevenueCat wired later). Gated behind parental PIN. *(6h)*
- [ ] **Task 7:** Story packs screen — Pack cards with name, story count, price, cover art. Purchase button gated behind parental PIN. *(4h)* — **Not implemented yet.**
- [ ] **Task 8:** Premium badge + upgrade prompt — Lock icon overlay on premium story cards. Kid-friendly "Ask a grown-up" message when kid taps locked content. *(3h)* — **Not implemented yet.**
- [ ] **Task 9:** Free Story badge — "Free This Week" banner on eligible story card. Entitlement override logic granting temporary free access. *(2h)* — **Not implemented yet.**

## Phase 4: Server-Side & Sync (~13h)

- [ ] **Task 10:** Webhook handler — Cloud Function receiving RevenueCat server notifications. Parse purchase/renewal/cancellation/refund events → update Firestore entitlements. *(6h)*
- [ ] **Task 11:** Entitlement sync — Server-side entitlement state management. Handle grace periods (3 days), cancellations, refunds, subscription downgrades. *(4h)*
- [ ] **Task 12:** Story access gating — Check entitlement before loading premium story tree. Show upgrade prompt if unauthorized. Redirect to subscription screen on parent action. *(3h)*

## Phase 5: Rotation & Restore (~5h)

- [ ] **Task 13:** Free Story rotation — Admin configuration in Firestore (`config/freeStoryOfWeek`). Optional Cloud Scheduler for automatic weekly rotation on Fridays. *(3h)*
- [ ] **Task 14:** Restore purchases — "Restore Purchases" button in parent settings. RevenueCat restore flow. Update local cache + Firestore state. Confirmation message. *(2h)*
