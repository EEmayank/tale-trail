# Tasks: Strapi CMS & Content Management

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 12 |
| **Total Estimated Effort** | ~42h |
| **Phase** | MVP |
| **Sprint** | 1-2 |
| **Status** | ⬜ Not Started (backend infrastructure — implement when server is provisioned) |

---

> **Note:** All tasks require external backend infrastructure (Strapi server, PostgreSQL, Cloud Run). The Flutter client uses 6 mock stories in `story_repository.dart` until the CMS is live.

## Phase 1: Project & Storage Setup (~9h)

- [ ] **Task 1:** Strapi project setup — Create new Strapi v4 app, configure PostgreSQL database, create Docker Compose file for local development. *(3h)*
- [ ] **Task 2:** Firebase Storage upload provider — Build custom Strapi upload provider using `@google-cloud/storage` SDK. Configure bucket access, signed URL generation, and file path conventions. *(6h)*

## Phase 2: Content Type Schemas (~5h)

- [ ] **Task 3:** Story content type — Define Story schema with title, slug, description, coverImage, ageMin/ageMax, language, themes, tags, colorAccent, status, isFree, packId, estimatedDuration, totalSteps, totalEndings, rootStep relation, steps relation, publishedAt. Configure admin panel layout. *(2h)*
- [ ] **Task 4:** StoryStep content type — Define StoryStep schema with stepId, story relation, transcript (richtext), plainText, audioFile, audioDurationMs, illustration, illustrationAlt, isEnding, endingTitle, choices relation, sortOrder. *(2h)*
- [ ] **Task 5:** StoryChoice content type — Define StoryChoice schema with label, description, icon, fromStep relation, toStep relation, sortOrder. *(1h)*

## Phase 3: Validation & API (~13h)

- [ ] **Task 6:** Tree validation service — Implement before-publish lifecycle hook with: root step existence check, valid choice links, ≥1 ending verification, DFS cycle detection, orphan step detection. Clear error messages for each failure. *(6h)*
- [ ] **Task 7:** Tree endpoint — Build `GET /api/stories/:id/tree` custom route returning full denormalized tree with nested steps and choices. *(4h)*
- [ ] **Task 8:** File upload validation — Add lifecycle hooks enforcing file size limits: audio 20MB, SVG 500KB, raster images 2MB. Reject with descriptive messages. *(3h)*

## Phase 4: Admin Tooling & Deployment (~17h)

- [ ] **Task 9:** Tree visualizer plugin — Build React admin panel plugin using `reactflow` library for visual node graph of story branching tree. Nodes represent steps, edges represent choices. *(8h)*
- [ ] **Task 10:** Seed data — Create 2-3 sample branching stories with placeholder audio files and SVG illustrations for development and testing. *(3h)* — **Flutter side:** 6 mock stories already seeded in `story_repository.dart` (Clever Fox, Raja and the Stars, Ocean Dream, Tenali's Clever Plan, Magic Forest, Journey to the Moon).
- [ ] **Task 11:** Dockerfile + deploy — Create production Docker image, configure environment variables, write Cloud Run deployment scripts with health checks. *(4h)*
- [ ] **Task 12:** Admin roles + permissions — Configure public read access for published stories, authenticated admin access for all management operations. *(2h)*
