---
paths:
  - "**/handler*"
  - "**/route*"
  - "**/endpoint*"
  - "**/api/**"
  - "**/*_handler.*"
  - "**/*_controller.*"
---

# API Design Standards

Mandatory conventions for designing and implementing APIs. Consistency across all endpoints is non-negotiable.

## URL Structure

```
/api/v{major}/{resource}              # Collection
/api/v{major}/{resource}/{id}          # Single item
/api/v{major}/{resource}/{id}/{sub}    # Nested resource
```

Rules:
- **Plural nouns**: `/api/v1/users`, not `/api/v1/user`
- **Lowercase, hyphenated**: `/api/v1/audit-logs`, not `/api/v1/auditLogs`
- **No verbs in URLs**: Use HTTP methods for actions. `/api/v1/users` + POST, not `/api/v1/createUser`
- **Nesting for relationships**: `/api/v1/orgs/{orgId}/members`, max 2 levels deep
- **Actions as sub-resources**: `/api/v1/users/{id}/activate` (POST) for non-CRUD operations

## HTTP Methods

| Method | Purpose | Idempotent | Request Body | Response |
|--------|---------|-----------|--------------|----------|
| GET | Read resource(s) | Yes | No | 200 + data |
| POST | Create resource | No* | Yes | 201 + data + Location header |
| PUT | Full replace | Yes | Yes | 200 + data |
| PATCH | Partial update | No* | Yes (partial) | 200 + data |
| DELETE | Remove resource | Yes | No | 204 (no body) |

*POST and PATCH become idempotent with `Idempotency-Key` header.

## Status Codes

| Code | When to Use |
|------|------------|
| **200 OK** | Successful GET, PUT, PATCH |
| **201 Created** | Successful POST. Include `Location` header with new resource URL |
| **204 No Content** | Successful DELETE. No response body |
| **400 Bad Request** | Malformed JSON, missing required fields, invalid field format |
| **401 Unauthorized** | No authentication provided or token expired |
| **403 Forbidden** | Authenticated but insufficient permissions |
| **404 Not Found** | Resource doesn't exist (or tenant doesn't have access) |
| **409 Conflict** | Duplicate resource (unique constraint violation) |
| **422 Unprocessable Entity** | Valid JSON but business rule violation |
| **429 Too Many Requests** | Rate limit exceeded. Include `Retry-After` header |
| **500 Internal Server Error** | Unexpected server error. Log details, return generic message |

### Important: 404 vs 403

When a resource exists but belongs to another tenant, return **404** (not 403). Returning 403 leaks information about resource existence.

## Response Envelope

### Single Resource
```json
{
  "data": {
    "id": "01234567-89ab-cdef-0123-456789abcdef",
    "type": "user",
    "attributes": {
      "name": "Jane Doe",
      "email": "jane@example.com",
      "created_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

### Collection (Paginated)
```json
{
  "data": [
    { "id": "...", "type": "user", "attributes": { ... } }
  ],
  "meta": {
    "cursor": "eyJpZCI6MTAwfQ==",
    "has_more": true,
    "total_count": 1234
  }
}
```

### Field naming: Always `snake_case` in JSON responses. Never `camelCase`.

## Pagination

### Cursor-Based (Default for most endpoints)

```
GET /api/v1/users?cursor=eyJpZCI6MTAwfQ==&limit=50

Response:
{
  "data": [...],
  "meta": {
    "cursor": "eyJpZCI6MTUwfQ==",
    "has_more": true
  }
}
```

- Cursor is an opaque, base64-encoded token (don't expose internal IDs)
- Default limit: 50. Maximum limit: 100
- When `has_more` is false, no more pages
- Stable even when new items are inserted (unlike offset)

### Offset-Based (Small, stable datasets only)

```
GET /api/v1/plans?offset=0&limit=20

Response:
{
  "data": [...],
  "meta": {
    "offset": 0,
    "limit": 20,
    "total_count": 45
  }
}
```

## Filtering

```
GET /api/v1/users?status=active&role=admin&created_after=2024-01-01
```

Rules:
- Filter parameters use `snake_case`
- Date filters: `created_after`, `created_before`, `updated_after`, `updated_before`
- Enum filters: exact match (`status=active`)
- Text search: `?q=search+term` for full-text search
- Multiple values: `?status=active,pending` (comma-separated)
- Null check: `?deleted_at=null` or `?deleted_at=!null`

## Sorting

```
GET /api/v1/users?sort=created_at&order=desc
GET /api/v1/users?sort=-created_at,name    # Prefix - for descending
```

- Default sort: `-created_at` (newest first)
- Always include a tiebreaker sort field (e.g., `id`) for cursor stability
- Document sortable fields per endpoint

## Error Response Format (RFC 7807)

Every error response MUST follow RFC 7807 Problem Details:

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Validation Failed",
  "status": 422,
  "detail": "The request body contains invalid fields.",
  "instance": "/api/v1/users",
  "errors": [
    {
      "field": "email",
      "code": "invalid_format",
      "message": "Must be a valid email address"
    },
    {
      "field": "name",
      "code": "required",
      "message": "Name is required"
    }
  ]
}
```

Fields:
- `type`: URI identifying the error type (machine-readable)
- `title`: Short human-readable summary
- `status`: HTTP status code
- `detail`: Human-readable explanation specific to this occurrence
- `instance`: The URI of the request that caused the error
- `errors`: Array of field-level errors (for validation)

### Error Type Registry

Maintain a registry of error types:

| Type Suffix | Status | Usage |
|------------|--------|-------|
| `/errors/validation-failed` | 422 | Request validation errors |
| `/errors/not-found` | 404 | Resource not found |
| `/errors/conflict` | 409 | Duplicate/conflict |
| `/errors/rate-limited` | 429 | Rate limit exceeded |
| `/errors/unauthorized` | 401 | Authentication required |
| `/errors/forbidden` | 403 | Insufficient permissions |
| `/errors/internal` | 500 | Unexpected server error |

## Rate Limiting

### Headers on Every Response

```
X-RateLimit-Limit: 1000        # Requests allowed per window
X-RateLimit-Remaining: 994     # Requests remaining in current window
X-RateLimit-Reset: 1705312800  # Unix timestamp when the window resets
```

### 429 Response

```json
{
  "type": "https://api.example.com/errors/rate-limited",
  "title": "Rate Limit Exceeded",
  "status": 429,
  "detail": "You have exceeded 1000 requests per hour. Try again in 300 seconds.",
  "retry_after": 300
}
```

Response MUST include `Retry-After` header (seconds).

### Rate Limit Tiers

| Tier | Read endpoints | Write endpoints | Burst |
|------|---------------|----------------|-------|
| Free | 100/min | 20/min | 10 |
| Pro | 1000/min | 200/min | 50 |
| Enterprise | 10000/min | 2000/min | 200 |

## Idempotency

### Idempotency-Key Header

For POST and PATCH requests:

```
POST /api/v1/orders
Idempotency-Key: unique-client-generated-key-12345
Content-Type: application/json

{ "items": [...] }
```

Server behavior:
1. Hash the request body
2. Check if `idempotency_key` exists in Redis
3. If exists and request hash matches: return cached response
4. If exists and request hash differs: return 422 (key reuse with different request)
5. If not exists: process request, store key + response in Redis with 24h TTL

## Request Tracing

### X-Request-ID

Every request gets a unique request ID:

```
# Client can provide:
X-Request-ID: client-generated-uuid

# Server always returns (generates if not provided):
X-Request-ID: 01234567-89ab-cdef-0123-456789abcdef
```

The request ID MUST be:
- Included in all log entries for this request
- Included in all error responses
- Propagated to downstream service calls
- Returned in the response header

## Versioning Strategy

- **URL path**: `/api/v1/...` for major versions
- **Breaking changes**: Require new major version
- **Non-breaking additions**: Add to current version (new optional fields, new endpoints)
- **Deprecation**: `Deprecation: true` + `Sunset: Sat, 01 Jun 2025 00:00:00 GMT` headers
- **Minimum deprecation period**: 6 months before removal

## Request Validation

All requests MUST be validated at the handler layer before reaching business logic:

1. **Content-Type**: Reject non-JSON requests for JSON endpoints
2. **Schema validation**: Validate against OpenAPI schema (field types, required fields, enums)
3. **Business validation**: Custom validation rules (field relationships, business constraints)
4. **Size limits**: Maximum request body size (default: 1MB, configurable per endpoint)

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| `GET /api/v1/getUsers` | `GET /api/v1/users` |
| `POST /api/v1/users/delete` | `DELETE /api/v1/users/{id}` |
| Return 200 for everything | Use appropriate status codes |
| Expose DB column names in API | Map to API-specific field names |
| Accept `tenant_id` in body | Extract from JWT/auth token |
| Inconsistent field naming | Always `snake_case` |
| No pagination on lists | Always paginate collections |
| Returning stack traces | Log internally, return generic error |
