# Tasks: Content Pipeline Automation

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 10 |
| **Total Estimated Effort** | ~53h |
| **Phase** | Post-MVP |
| **Sprint** | 11-12 |
| **Status** | ⬜ Not Started (all Cloud Functions / backend — implement after Strapi + Firebase backend is live) |

---

## Phase 1: Asset Processing (~17h)

- [ ] **Task 1:** Audio compression Cloud Function — Triggered on audio file upload to Firebase Storage. Use `fluent-ffmpeg` to generate 64kbps (low quality) and 128kbps (standard quality) MP3 variants. Store alongside original in same directory. Handle Cloud Run deployment if memory/time limits exceeded. *(8h)*
- [ ] **Task 2:** SVG validation Cloud Function — Triggered on SVG file upload. Check file size (reject if > 500KB), parse XML to detect embedded `<image>` tags (raster rejection), run SVGO optimization pipeline, overwrite original with optimized output. *(6h)*
- [ ] **Task 3:** Validation feedback to CMS — Return validation results to Strapi via callback URL or writable status field. Clear error messages: "SVG too large (623KB, max 500KB)", "Embedded raster image found on line 42". *(3h)*

## Phase 2: Content Versioning (~15h)

- [ ] **Task 4:** Version service — On story update webhook: snapshot full story tree + all asset URLs into `stories/{storyId}/versions/{versionId}` document. Increment version number. Set `isLatest` flag. *(6h)*
- [ ] **Task 5:** Version-aware API — Modify story tree API endpoint: default behavior returns latest version. Add `?version=N` query parameter support for fetching specific historical versions. *(4h)*
- [ ] **Task 6:** Version migration for readers — When a reader resumes mid-story: check if their saved version still exists. Attempt seamless step-ID mapping to latest version. If incompatible, show "This story has been updated" with restart option. *(5h)*

## Phase 3: Scheduled Publishing (~9h)

- [ ] **Task 7:** Scheduled publisher Cloud Function — Cloud Scheduler running every 15 minutes: query `config/scheduledPublishQueue` for items with `publishAt <= now` and status `pending`. Call Strapi publish API. Update item status to `published` or `failed`. *(5h)*
- [ ] **Task 8:** Strapi webhook handler — Cloud Function receiving Strapi lifecycle webhooks on publish, update, and delete events. Validate webhook signature for security. Route event to appropriate downstream handler. *(4h)*

## Phase 4: Event System (~8h)

- [ ] **Task 9:** Content event dispatcher — Fan-out logic on story publish event: (1) sync story data to Firestore, (2) invalidate CDN cache for story assets, (3) trigger push notification Cloud Function for new story alerts. *(5h)*
- [ ] **Task 10:** CDN cache invalidation — Implement programmatic cache invalidation for updated story assets. Use Firebase Storage metadata versioning or URL-based cache busting. Accept 5-15 min propagation delay. *(3h)*
