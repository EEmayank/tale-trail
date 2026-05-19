# Spec 16: Content, World Browser & Growth

| Field | Value |
|-------|-------|
| **Feature** | Content, World Browser & Growth |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | Post-MVP |
| **Features Covered** | #37 Indian Folklore Collection, #39 Storybook-World Browser, #52 Download Animation, #53 Weekly Story Drops, #54 Family Referral Program |
| **Estimated Effort** | ~51h (6-7 days) |

---

## Overview

Five features spanning content, discovery, delight, and growth: (1) Indian folklore story collection (Panchatantra, Jataka, Tenali Raman, Akbar-Birbal) filling a major cultural gap, (2) storybook-world browser where stories are illustrated locations on a map, (3) charming Lottie download animation (character carrying book to shelf), (4) automated weekly story drop pipeline with notifications, and (5) family referral program with unique codes and WhatsApp sharing (critical for India viral growth).

### Acceptance Criteria

1. **Indian Folklore:** Dedicated collection screen. CMS tag `folklore:indian`. Sub-categories: Panchatantra, Jataka, Tenali Raman, Akbar-Birbal. Interactive branching adaptations.
2. **World Browser:** Illustrated SVG landscape. Stories positioned as interactive locations (treehouse, cave, castle). Tap location → story detail. Idle animations on locations. "New" badge. `InteractiveViewer` for pan/zoom.
3. **Download Animation:** Lottie animation of character carrying book to shelf. Plays during download progress. Replaces or enhances the download progress indicator.
4. **Weekly Drops:** Cloud Function scheduler (Friday 9AM IST). Auto-publish queued story. Push notification. "New This Week" badge visible for 7 days.
5. **Referral Program:** Unique 8-character referral codes. Share via WhatsApp (critical for India). Reward: 1 free month for referrer and referee. Anti-abuse: no self-referral, max 10 redemptions per referrer.

---

## Architecture

### Firestore Schema

```
parents/{parentId}/referral
  code: string (8-char unique)
  referralCount: number
  maxReferrals: number (10)
  createdAt: timestamp

referrals/{code}
  referrerParentId: string
  redemptions: array<{
    redeemerParentId: string,
    redeemedAt: timestamp
  }>

config/worldMap
  locations: array<{
    storyId: string,
    x: number (0-1 normalized),
    y: number (0-1 normalized),
    type: "treehouse" | "cave" | "castle" | "river" | "mountain",
    label: string,
    isNew: boolean,
    idleAnimation: string (Lottie asset name)
  }>
```

### World Browser Layout

```
┌────────────────────────────┐
│  Illustrated SVG Landscape │
│                            │
│  🏰 Castle    🌳 Treehouse │
│         ⛰️                 │
│    🕳️ Cave                  │
│              🏔️ Mountain   │
│  🌊 River                  │
│                            │
│  [Pan/Zoom: InteractiveViewer]
└────────────────────────────┘
```

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Folklore collection screen | Dedicated screen for Indian folklore stories. Category tabs (Panchatantra, Jataka, etc.). Filtered by CMS tag `folklore:indian`. | 3h |
| 2 | CMS folklore tags | Add `folklore` tag category in Strapi. Sub-tags for each collection. Seed metadata for initial stories. | 1h |
| 3 | World map data model | Define `WorldLocation` model: storyId, coordinates (normalized 0-1), location type, label, isNew flag, idle animation reference. | 2h |
| 4 | World browser screen | Full-screen `InteractiveViewer` with illustrated SVG landscape background. Pan and zoom controls. Overlay story hotspot widgets at configured coordinates. | 6h |
| 5 | Story hotspot widget | Positioned widget on world map: location icon (SVG), idle bounce/wiggle animation, "New" badge, tap handler → story detail navigation. | 4h |
| 6 | World browser provider | Load world map configuration from Firestore. Resolve story IDs to metadata. Manage active location state. | 3h |
| 7 | Download character animation | Lottie animation: small character picks up book, walks across screen, places on bookshelf. Integrated into download progress overlay. | 3h |
| 8 | Download animation integration | Replace or layer download character animation alongside existing download progress indicator. Play during active download. | 2h |
| 9 | Weekly drop scheduler | Cloud Function triggered by Cloud Scheduler (Friday 9AM IST). Auto-publish first `pending` story in scheduled queue. Log result. | 3h |
| 10 | "New This Week" badge | Badge component: "New" label with subtle glow. Show on stories published within last 7 days. Auto-expire. | 2h |
| 11 | Referral code generation | Generate unique 8-character alphanumeric codes using `nanoid`. Store in Firestore. Assign to parent on first request. | 2h |
| 12 | Referral redemption | Validate referral code: check existence, anti-self-referral (compare parent IDs), max 10 redemptions. Grant 1 free month to both referrer and referee via RevenueCat promotional entitlement. | 5h |
| 13 | Referral screen | Parent settings: display referral code, share button (WhatsApp deep link, system share), redemption count, earnings history. | 3h |
| 14 | Referral provider | Manage referral code state, share actions, redemption tracking. | 2h |
| 15 | Referral in onboarding | "Have a referral code?" input field during parent onboarding. Optional, skip-able. Auto-apply reward on valid code. | 2h |

### Dependencies

**Backend:** `nanoid`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| World map location for unpublished story | Hide location from map. Only show published stories. |
| No stories on world map | Show empty landscape with "Adventures coming soon!" message. |
| Referral code already used by this parent | "You've already used a referral code" error. |
| Self-referral attempt | Compare parent IDs. Block with clear message. |
| Referrer at max 10 redemptions | "This referral code has reached its limit" error. |
| Referral code not found | "Invalid referral code" with retry option. |
| WhatsApp not installed | Fall back to system share sheet. |
| Weekly drop: no stories in queue | Log "No stories queued for this week." No notification sent. |
| Download animation Lottie fails to load | Fall back to standard progress indicator. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Referral code generation uniqueness. Redemption validation (self-referral, max count, existence). World location coordinate mapping. |
| **Widget** | World map rendering with hotspots. Download animation playback. Referral screen share actions. |
| **Integration** | Referral flow: generate → share → redeem → both parties receive free month. Weekly drop: scheduler fires → story published → notification sent. |
| **Manual** | World browser pan/zoom on physical devices. WhatsApp share link formatting. Download animation visual quality. |

---

## Effort Estimate

**Total: ~51h (6-7 days)**
