# Spec 2: Strapi CMS & Content Management

| Field | Value |
|-------|-------|
| **Feature** | Strapi CMS & Content Management |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | MVP |
| **Features Covered** | #15 Strapi CMS — Story Builder, #16 Strapi CMS — Asset Pipeline |
| **Estimated Effort** | ~42h (5-6 days) |

---

## Overview

Admin CMS for creating interactive branching stories with audio, illustrations, and branching logic. Assets stored in Firebase Storage via custom upload provider.

### User Stories

- Admin creates stories with metadata (title, description, cover, age range, language, tags).
- Admin builds multi-step stories with text, audio, illustration per step.
- Admin defines 2-4 branching choices per step linking to different next steps (tree structure).
- Admin uploads MP3, SVG/PNG/JPG per step. Sets Draft/Published/Archived status.
- Admin previews story tree as a visual node graph.

### Acceptance Criteria

1. Self-hosted Strapi (Docker on Cloud Run or VM).
2. Story steps: richtext, audio, illustration, 0-4 choices.
3. Each choice: label, optional icon, link to target step.
4. Assets stored in Firebase Storage via custom provider.
5. Draft/Published/Archived statuses.
6. Visual tree graph in admin panel.
7. File limits: audio 20MB, SVG 500KB, raster 2MB.
8. Cover image required for publishing. At least 1 ending required.

---

## Architecture

### Content Types

**Story**

| Field | Type | Constraints |
|-------|------|-------------|
| title | string | max 100 chars |
| slug | uid | auto-generated |
| description | text | max 500 chars |
| coverImage | media | required for publish |
| ageMin | integer | 3-12 |
| ageMax | integer | 3-12, >= ageMin |
| language | enum | en, hi |
| themes | json | array of theme strings |
| tags | json | array of tag strings |
| colorAccent | string | hex color code |
| status | enum | draft, published, archived |
| isFree | boolean | default true |
| packId | string | nullable |
| estimatedDuration | integer | minutes |
| totalSteps | integer | computed |
| totalEndings | integer | computed |
| rootStep | relation | → StoryStep |
| steps | relation | → StoryStep[] |
| publishedAt | datetime | nullable |

**StoryStep**

| Field | Type | Constraints |
|-------|------|-------------|
| stepId | string | unique within story |
| story | relation | → Story |
| transcript | richtext | story text content |
| plainText | text | plain text fallback |
| audioFile | media | audio/mp3, max 20MB |
| audioDurationMs | integer | milliseconds |
| illustration | media | SVG/PNG/JPG |
| illustrationAlt | string | accessibility text |
| isEnding | boolean | marks terminal step |
| endingTitle | string | e.g. "The Brave Path" |
| choices | relation | → StoryChoice[] |
| sortOrder | integer | ordering |

**StoryChoice**

| Field | Type | Constraints |
|-------|------|-------------|
| label | string | max 100 chars |
| description | text | max 200 chars |
| icon | media | optional SVG icon |
| fromStep | relation | → StoryStep |
| toStep | relation | → StoryStep |
| sortOrder | integer | ordering |

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Strapi project setup | Create Strapi app, configure PostgreSQL, Docker Compose file | 3h |
| 2 | Firebase Storage upload provider | Custom provider using `@google-cloud/storage` SDK for Firebase Storage integration | 6h |
| 3 | Story content type | Create Story schema with all metadata fields + admin panel layout | 2h |
| 4 | StoryStep content type | Create StoryStep schema with transcript, audio, illustration fields | 2h |
| 5 | StoryChoice content type | Create StoryChoice schema with label, icon, step relations | 1h |
| 6 | Tree validation service | Before-publish lifecycle hook: validate root exists, all choice links valid, ≥1 ending, no cycles (DFS), no orphan steps | 6h |
| 7 | Tree endpoint | `GET /api/stories/:id/tree` — full denormalized tree with steps and choices nested | 4h |
| 8 | File upload validation | Lifecycle hooks: enforce size limits (audio 20MB, SVG 500KB, raster 2MB) per file type | 3h |
| 9 | Tree visualizer plugin | React admin panel plugin using `reactflow` for visual node graph of story tree | 8h |
| 10 | Seed data | Create 2-3 sample branching stories with audio/illustrations for testing | 3h |
| 11 | Dockerfile + deploy | Production Docker image, environment config, Cloud Run deployment scripts | 4h |
| 12 | Admin roles + permissions | Public read access for published stories, authenticated admin for management operations | 2h |

### Dependencies

`strapi` v4, `pg`, `@google-cloud/storage`, `reactflow`

### Environment Variables

`DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `FIREBASE_STORAGE_BUCKET`, `GOOGLE_APPLICATION_CREDENTIALS`, `STRAPI_ADMIN_JWT_SECRET`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Circular branching (A→B→A) | DFS cycle detection blocks publish with clear error message. |
| Orphan steps (unreachable from root) | Flag unreachable steps. Block on publish. |
| Step has no choices, not marked ending | Validator flags with suggestion to mark as ending or add choices. |
| Admin deletes a referenced step | Cascade check: warn about referencing choices before allowing deletion. |
| Uploading oversized file | Reject with clear message showing limit for that file type. |
| Publishing without cover image | Block publish, show "Cover image required" validation error. |
| Publishing without any ending | Block publish, show "At least one ending step required" error. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Tree validator: cycle detection, orphan detection, ending validation, root validation. |
| **Integration** | Full CRUD: create story → add steps → add choices → publish → fetch tree endpoint. |
| **Manual** | Tree visualizer plugin: visual verification of node graph rendering and interaction. |

---

## Effort Estimate

**Total: ~42h (5-6 days)**
