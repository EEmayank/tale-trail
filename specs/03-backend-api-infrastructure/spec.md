# Spec 3: Backend API & Infrastructure

| Field | Value |
|-------|-------|
| **Feature** | Backend API & Infrastructure |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | MVP |
| **Features Covered** | #17 REST API — Story Tree Endpoint, #18 CDN-Backed Asset Delivery, #20 Rate Limiting & App Check |
| **Estimated Effort** | ~45h (6 days) |

---

## Overview

Node.js Cloud Functions API serving story data to the Flutter app. CDN-optimized asset delivery via Firebase Storage. Security via Firebase App Check and rate limiting.

### Acceptance Criteria

1. `GET /api/v1/stories` — paginated list (metadata only). `GET /api/v1/stories/:id/tree` — full branching tree.
2. Response <200ms cached. Assets via Firebase Storage CDN (1-week cache). Premium assets use signed URLs (24h expiry).
3. Firebase App Check on all endpoints. Rate limits: 60/min listing, 30/min tree.

---

## Architecture

### API Endpoints

| Method | Path | Description | Rate Limit |
|--------|------|-------------|------------|
| GET | `/api/v1/stories` | Paginated story list (metadata only) | 60/min |
| GET | `/api/v1/stories/:id` | Single story metadata | 60/min |
| GET | `/api/v1/stories/:id/tree` | Full story branching tree | 30/min |
| GET | `/api/v1/stories/featured` | Featured/curated stories | 60/min |

### Response Shapes

**Story List Response:**
```json
{
  "data": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "coverImageUrl": "string",
      "ageMin": 3,
      "ageMax": 8,
      "language": "en",
      "themes": ["forest", "adventure"],
      "tags": ["brave", "animals"],
      "isFree": true,
      "estimatedDuration": 15,
      "totalSteps": 12,
      "totalEndings": 3
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 42
  }
}
```

**Story Tree Response:**
```json
{
  "data": {
    "id": "string",
    "title": "string",
    "colorAccent": "#4CAF50",
    "rootStepId": "step_1",
    "steps": {
      "step_1": {
        "id": "step_1",
        "transcript": "Once upon a time...",
        "plainText": "Once upon a time...",
        "audioUrl": "https://...",
        "audioDurationMs": 45000,
        "illustrationUrl": "https://...",
        "illustrationAlt": "A fox in the forest",
        "isEnding": false,
        "choices": [
          {
            "id": "choice_1",
            "label": "Enter the cave",
            "description": "A dark cave beckons...",
            "iconUrl": "https://...",
            "toStepId": "step_2"
          }
        ]
      }
    }
  }
}
```

### Data Flow

**Strapi → Firestore Sync:** Cloud Function triggered by Strapi webhook on publish. Transforms Strapi content types → optimized Firestore documents for fast client reads.

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Cloud Functions project | Initialize Firebase Cloud Functions with TypeScript + Express | 2h |
| 2 | Firebase Admin init | Configure Firestore + Storage admin clients with service account | 1h |
| 3 | Express routing | Versioned routes (`/api/v1/`), CORS configuration, JSON parsing middleware | 2h |
| 4 | App Check middleware | Verify `X-Firebase-AppCheck` header on all requests. Reject invalid tokens with 401. | 3h |
| 5 | Rate limiting middleware | `express-rate-limit` with per-route limits. Return 429 with `Retry-After` header. | 3h |
| 6 | Story service — list | Query Firestore (status=published), pagination, age/language/theme filters | 4h |
| 7 | Story service — tree | Batch fetch story + steps + choices from Firestore, assemble nested tree structure | 6h |
| 8 | Asset service | Generate public URLs for free content, signed URLs (24h TTL) for premium content | 4h |
| 9 | Story controller | Route handlers with error wrapping and consistent response formatting | 3h |
| 10 | Cache middleware | Set `Cache-Control` headers: list endpoints 5min, tree endpoints 1h | 2h |
| 11 | Error handler | Global error handler with HTTP code mapping and structured error responses | 2h |
| 12 | Validation middleware | Query parameter validation using `zod` schemas | 2h |
| 13 | CDN configuration | Firebase Storage rules, cache headers for assets, CORS for CDN | 2h |
| 14 | Strapi → Firestore sync | Webhook-triggered Cloud Function: receive Strapi publish events, transform data, write to Firestore | 6h |

### Dependencies

`firebase-functions`, `firebase-admin`, `express`, `express-rate-limit`, `zod`, `cors`, `helmet`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Missing or unpublished story | 404 with `{ error: "Story not found" }` |
| Invalid query parameters | 400 with validation details from zod |
| Rate limit exceeded | 429 with `Retry-After` header |
| Firestore timeout | 503 with `{ error: "Service temporarily unavailable" }` |
| Partial tree (missing step references) | Log warning, return tree with available steps, flag broken references |
| Invalid App Check token | 401 with `{ error: "Unauthorized" }` |
| Signed URL generation failure | Fallback to public URL for free content, 500 for premium |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Service layer with mocked Firestore. Zod validators. URL generation. |
| **Integration** | Seeded Firestore → API calls → verify response shapes and pagination. |
| **Load** | Artillery at 100 concurrent users. Verify rate limiting kicks in correctly. |

---

## Effort Estimate

**Total: ~45h (6 days)**
