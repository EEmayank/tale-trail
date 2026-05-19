# Tasks: Content, World Browser & Growth

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 15 |
| **Total Estimated Effort** | ~51h |
| **Phase** | Post-MVP |
| **Sprint** | 19-20 |
| **Status** | ⬜ Not Started (post-MVP features) |

---

## Phase 1: Indian Folklore Collection (~4h)

- [ ] **Task 1:** Folklore collection screen — Dedicated screen for Indian folklore stories. Category tabs for Panchatantra, Jataka, Tenali Raman, Akbar-Birbal. Filtered by CMS tag `folklore:indian`. Illustrated header. *(3h)* — **Note:** mock stories include Tenali Raman story as placeholder.
- [ ] **Task 2:** CMS folklore tags — Add `folklore` tag category in Strapi with sub-tags for each collection. Seed metadata for planned stories. *(1h)*

## Phase 2: Storybook-World Browser (~15h)

- [ ] **Task 3:** World map data model — Define `WorldLocation` model: storyId, normalized x/y coordinates (0-1), location type enum (treehouse, cave, castle, river, mountain), label, isNew flag, idle animation reference. *(2h)*
- [ ] **Task 4:** World browser screen — Full-screen `InteractiveViewer` with illustrated SVG landscape background. Pan and zoom with boundaries. Overlay positioned `StoryHotspot` widgets. *(6h)*
- [ ] **Task 5:** Story hotspot widget — Positioned widget: animated location icon (SVG idle bounce), "New" badge overlay, tap → story detail. *(4h)*
- [ ] **Task 6:** World browser provider — Load world map config from Firestore `config/worldMap`. Resolve story IDs to metadata. Manage selected location state. *(3h)*

## Phase 3: Download Animation (~5h)

- [ ] **Task 7:** Download character animation — Lottie: character picks up book, walks, places on bookshelf. Overlay during active downloads. *(3h)*
- [ ] **Task 8:** Download animation integration — Layer Lottie animation with existing download progress indicator. Fallback to standard progress bar. *(2h)*

## Phase 4: Weekly Story Drops (~5h)

- [ ] **Task 9:** Weekly drop scheduler — Cloud Function on Cloud Scheduler (Friday 9AM IST): trigger publish for first pending story, send new story notification. *(3h)*
- [ ] **Task 10:** "New This Week" badge — `BadgeChip.new()` variant with glow animation. Display on stories published within last 7 days. Auto-expire by `publishedAt`. *(2h)*

## Phase 5: Family Referral Program (~14h)

- [ ] **Task 11:** Referral code generation — Unique 8-character alphanumeric codes via `nanoid`. Firestore `parents/{parentId}/referral`. Lazy generation. *(2h)*
- [ ] **Task 12:** Referral redemption — Validate code, prevent self-referral, max 10 redemptions. On valid: grant 1 free month to both via RevenueCat promotional entitlement. *(5h)*
- [ ] **Task 13:** Referral screen — In parent settings: personal code display, "Share" button (WhatsApp deep link priority), redemption count, rewards history. *(3h)*
- [ ] **Task 14:** Referral provider — Riverpod provider managing referral code state, share triggers, redemption count. *(2h)*
- [ ] **Task 15:** Referral in onboarding — "Have a referral code?" optional input during onboarding. Validate and auto-apply reward. Skip button. *(2h)*
