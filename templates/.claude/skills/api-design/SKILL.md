---
name: api-design
description: Design API contracts with OpenAPI specifications
allowed-tools: Read, Write, Glob, Grep
---

# API Contract Design Skill

Interactive workflow for designing API contracts. Produces OpenAPI 3.1 specifications and optionally generates typed client code.

## Workflow

### Step 1: Identify Resources and Relationships

Analyze the feature requirements to identify:
- **Resources**: Core entities that need API endpoints (e.g., Users, Projects, Invoices)
- **Relationships**: How resources relate to each other (e.g., Users belong to Organizations, Projects have Members)
- **Actions**: Non-CRUD operations that need endpoints (e.g., activate, archive, export)

Output: Resource inventory table with relationships.

### Step 2: Design URL Structure

For each resource, design the URL following `.claude/rules/api-design.md`:

```
GET    /api/v1/{resources}          # List (paginated)
POST   /api/v1/{resources}          # Create
GET    /api/v1/{resources}/{id}     # Get by ID
PUT    /api/v1/{resources}/{id}     # Full update
PATCH  /api/v1/{resources}/{id}     # Partial update
DELETE /api/v1/{resources}/{id}     # Delete
```

For nested resources: `/api/v1/{parent}/{parentId}/{children}`

For actions: `POST /api/v1/{resources}/{id}/{action}`

Output: Complete URL structure table with HTTP methods and descriptions.

### Step 3: Define Request/Response Schemas

For each endpoint, define:
- **Request body** (POST, PUT, PATCH): Field names, types, required/optional, constraints
- **Response body**: Data envelope structure, field names, types
- **Query parameters** (GET list): Pagination, filtering, sorting options

Rules:
- Field names: `snake_case` in JSON
- IDs: UUIDs
- Dates: ISO 8601 (`2024-01-15T10:30:00Z`)
- Enums: lowercase strings
- Include `tenant_id` in response (from server context, never from request)

Output: Schema definitions for all request/response types.

### Step 4: Specify Error Responses

For each endpoint, define error responses using RFC 7807 Problem Details:
- 400: What constitutes a bad request?
- 401: How is authentication checked?
- 403: What permissions are required?
- 404: When is the resource not found?
- 409: What conflicts can occur?
- 422: What business rule validations exist?
- 429: What rate limits apply?

Output: Error catalog with types, status codes, and example responses.

### Step 5: Generate OpenAPI 3.1 Specification

Generate a complete OpenAPI 3.1 YAML specification file including:
- Info section (title, version, description)
- Server URLs (dev, staging, production)
- Security schemes (Bearer JWT)
- Paths with all endpoints
- Components/schemas for all request/response types
- Components/responses for common error types
- Tags for resource grouping

Write to: `docs/spec/api/openapi.yaml` (or feature-specific file)

### Step 6: Generate Client Types (Optional)

If requested, generate typed client interfaces:

**TypeScript:**
```typescript
// Generated from OpenAPI spec
export interface User {
  id: string;
  tenant_id: string;
  name: string;
  email: string;
  role: 'admin' | 'member' | 'viewer';
  created_at: string;
  updated_at: string;
}

export interface CreateUserInput {
  name: string;
  email: string;
  role: 'admin' | 'member' | 'viewer';
}
```

**Go:**
```go
type User struct {
    ID        uuid.UUID `json:"id"`
    TenantID  uuid.UUID `json:"tenant_id"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    Role      Role      `json:"role"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

### Step 7: Present for Review

Present the complete API design for review:
- Summary table of all endpoints (method, URL, description)
- Key design decisions and alternatives considered
- Pagination and filtering approach
- Error handling approach
- Rate limiting strategy
- Any open questions or recommendations

Ask the user to confirm or request changes before generating the final spec files.
