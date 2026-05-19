# Spec 13: Content Pipeline Automation

| Field | Value |
|-------|-------|
| **Feature** | Content Pipeline Automation |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | Post-MVP |
| **Features Covered** | #42 Audio Compression Pipeline, #43 SVG Validation & Optimization, #44 Content Versioning, #46 Scheduled Content Publishing, #47 Webhook for Content Events |
| **Estimated Effort** | ~53h (7 days) |

---

## Overview

Cloud Functions automating the content pipeline: auto-compress uploaded audio to multiple quality levels (64kbps/128kbps via ffmpeg), validate and optimize SVGs (SVGO, size checks, embedded raster rejection), content versioning so in-progress readers stay on their version, scheduled publishing for "New Story Friday", and webhook-driven downstream events (CDN invalidation, push notifications, Firestore sync).

### Acceptance Criteria

1. **Audio Compression:** On MP3 upload, Cloud Function generates 64kbps (low) and 128kbps (standard) variants. Admin uploads high-quality, system auto-optimizes.
2. **SVG Validation:** On SVG upload, validate: size < 500KB, no embedded rasters, run SVGO optimization. Return helpful error messages to CMS on failure.
3. **Content Versioning:** Story updates create new version snapshots. Readers mid-story continue on the version they started. New readers get latest.
4. **Scheduled Publishing:** Admin sets future publish date in CMS. Cloud Scheduler checks every 15 minutes. Publishes on schedule.
5. **Content Webhooks:** Story publish/update triggers fan-out: Firestore sync, CDN cache invalidation, push notification to opted-in parents.

---

## Architecture

### Firestore Schema

```
stories/{storyId}/versions/{versionId}
  versionNumber: number
  treeSnapshot: map          // Full story tree at time of version
  assetManifest: map         // URLs to versioned assets
  isLatest: boolean
  createdAt: timestamp

config/scheduledPublishQueue
  items: array<{
    storyId: string,
    publishAt: timestamp,
    status: "pending" | "published" | "failed"
  }>
```

### Cloud Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `compressAudio` | Firebase Storage (audio upload) | Generate 64kbps + 128kbps variants via ffmpeg |
| `validateSvg` | Firebase Storage (SVG upload) | Size check, embedded raster detection, SVGO optimization |
| `createVersion` | Strapi webhook (story update) | Snapshot current tree + assets into version document |
| `scheduledPublisher` | Cloud Scheduler (every 15 min) | Check queue, publish due stories |
| `contentEventDispatcher` | Strapi webhook (story publish) | Fan-out: Firestore sync, CDN invalidate, push notify |

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Audio compression Function | Cloud Function triggered on audio upload. Use `fluent-ffmpeg` to generate 64kbps and 128kbps MP3 variants. Store alongside original. May require Cloud Run for memory/time limits. | 8h |
| 2 | SVG validation Function | Cloud Function triggered on SVG upload. Check file size (< 500KB), parse XML to detect embedded raster images (`<image>` tags), run SVGO optimization, overwrite with optimized version. | 6h |
| 3 | Validation feedback to CMS | Return validation results to Strapi via callback URL or status field. Clear error messages: "SVG too large (623KB, max 500KB)", "Embedded raster image detected". | 3h |
| 4 | Version service | On story update webhook: snapshot current story tree + asset URLs into `versions/{versionId}` document. Increment version number. Mark as latest. | 6h |
| 5 | Version-aware API | Modify story tree endpoint: default returns latest version. Support `?version=N` query parameter for specific version. | 4h |
| 6 | Version migration for readers | When reader resumes mid-story: check if their version still exists. If version removed, attempt seamless migration to latest (map step IDs). If incompatible, show "Story updated" message with option to restart. | 5h |
| 7 | Scheduled publisher Function | Cloud Scheduler (every 15 min): query `scheduledPublishQueue` for items with `publishAt <= now` and status `pending`. Trigger Strapi publish API. Update status. | 5h |
| 8 | Strapi webhook handler | Cloud Function receiving Strapi lifecycle webhooks (publish, update, delete). Validate webhook signature. Route to appropriate handler. | 4h |
| 9 | Content event dispatcher | Fan-out on story publish: (1) sync to Firestore, (2) invalidate CDN cache for story assets, (3) trigger push notification for new story. | 5h |
| 10 | CDN cache invalidation | Programmatic cache invalidation for updated story assets via Firebase Storage metadata update or URL versioning. | 3h |

### Dependencies (Backend)

`fluent-ffmpeg`, `svgo`, `xml2js`

> **Note:** ffmpeg in Cloud Functions may exceed memory/time limits. Budget for Cloud Run deployment if needed.

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| ffmpeg compression fails | Log error, keep original. Admin notified via CMS status field. |
| SVG validation rejects file | Return clear error to CMS. Do not store invalid file. |
| Version snapshot during active edit | Snapshot only on explicit publish/update, not on draft saves. |
| Reader's version deleted | Attempt step-ID mapping to latest version. Fallback: "Story updated" prompt. |
| Scheduled publish fails | Retry once. Mark as "failed" with error. Admin notification. |
| Webhook signature invalid | Reject with 403. Log for security audit. |
| CDN invalidation delay | Accept 5-15 min propagation. Use URL versioning as backup. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | SVG validation rules. Version snapshot creation. Schedule queue logic. |
| **Integration** | Upload audio → verify compressed variants exist. Upload SVG → verify optimized. Publish → verify Firestore sync + notification. |
| **Manual** | End-to-end: CMS publish → scheduled publish fires → Firestore updated → push sent → CDN refreshed. |

---

## Effort Estimate

**Total: ~53h (7 days)**
