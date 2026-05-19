# Tasks: Backend API & Infrastructure

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 14 |
| **Total Estimated Effort** | ~45h |
| **Phase** | MVP |
| **Sprint** | 3-4 |
| **Status** | ⬜ Not Started (Cloud Functions backend — implement when infrastructure is provisioned) |

---

> **Note:** All tasks are Cloud Functions / Firebase server-side work. The Flutter client reads directly from Firestore with Hive caching and mock data until the backend API is live.

## Phase 1: Project Foundation (~5h)

- [ ] **Task 1:** Cloud Functions project setup — Initialize Firebase Cloud Functions with TypeScript + Express framework. *(2h)*
- [ ] **Task 2:** Firebase Admin initialization — Configure Firestore + Storage admin clients with service account credentials. *(1h)*
- [ ] **Task 3:** Express routing setup — Configure versioned routes (`/api/v1/`), CORS, JSON parsing middleware. *(2h)*

## Phase 2: Security & Middleware (~10h)

- [ ] **Task 4:** App Check middleware — Verify `X-Firebase-AppCheck` header on all requests. Reject invalid tokens with 401 response. *(3h)*
- [ ] **Task 5:** Rate limiting middleware — Implement `express-rate-limit` with per-route limits (60/min listing, 30/min tree). Return 429 with `Retry-After` header. *(3h)*
- [ ] **Task 10:** Cache middleware — Set `Cache-Control` headers: list endpoints 5min TTL, tree endpoints 1h TTL. *(2h)*
- [ ] **Task 12:** Validation middleware — Query parameter validation using `zod` schemas for pagination, filters. *(2h)*

## Phase 3: Core API Services (~17h)

- [ ] **Task 6:** Story list service — Query Firestore for published stories with pagination, age/language/theme filters, sorting. *(4h)*
- [ ] **Task 7:** Story tree service — Batch fetch story + steps + choices from Firestore, assemble into nested tree structure with O(1) step lookup. *(6h)*
- [ ] **Task 8:** Asset URL service — Generate public URLs for free content, signed URLs (24h TTL) for premium content via Firebase Storage. *(4h)*
- [ ] **Task 9:** Story controller — Route handlers with error wrapping, consistent response formatting, and request logging. *(3h)*

## Phase 4: Error Handling & Infrastructure (~10h)

- [ ] **Task 11:** Global error handler — HTTP code mapping, structured error responses, error logging. *(2h)*
- [ ] **Task 13:** CDN configuration — Firebase Storage security rules, cache headers for assets, CORS configuration for CDN access. *(2h)*
- [ ] **Task 14:** Strapi → Firestore sync — Webhook-triggered Cloud Function: receive Strapi publish events, transform content types to Firestore documents, handle updates and deletions. *(6h)*
