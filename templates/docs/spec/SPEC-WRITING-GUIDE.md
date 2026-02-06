# Specification Writing Guide

How to write detailed, robust specification files that LLMs can consume effectively. This guide defines the structure, depth, and design principles for every spec in this project.

> **LLM Quick Reference**: How to write specs. Follow this guide when creating any new specification document.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Creating a new specification file for any layer
- Reviewing an existing spec for quality and completeness
- Understanding the expected depth and structure of specs
- Teaching someone how to contribute to the spec system

### Key Sections

| Section | Purpose |
|---------|---------|
| **Anatomy of a Spec** | Required structure every spec must follow |
| **Writing by Layer** | Layer-specific guidance (framework, pkg, platform) |
| **Design Principles** | The "why" behind spec conventions |
| **Quick Reference Tables** | How to write effective decision tables |
| **Code Examples** | Standards for code in specs |
| **Spec Templates** | Copy-paste starters for each layer |

### Context Loading

1. For **spec format only**: This doc is sufficient
2. For **LLM navigation sections**: Load `./LLM-STYLE-GUIDE.md`
3. For **overall orchestration**: Load `./LLM.md`
4. For **Go code patterns**: Load `./framework/go-generation-guide.md`

---

## Anatomy of a Spec

Every spec file follows the same skeleton, regardless of layer. This consistency is what makes the system work at scale.

### Required Structure

```markdown
# Title

[1-2 sentence description of what this spec covers and why it exists.]

> **LLM Quick Reference**: [One-line summary for fast scanning.]

## LLM Navigation Guide

### When to Use This Document
Load this document when:
- [5-8 specific, actionable scenarios]

### Key Sections
| Section | Purpose |
|---------|---------|
| **Section Name** | What it covers |

### Quick Reference: [Most Common Lookup]
[Table or code block — the thing people look up 80% of the time]

### Context Loading
1. For **[use case]**: This doc is sufficient
2. For **[related topic]**: Load `./path.md`

---

## Design Principles
[3-5 bullets: the core decisions driving this spec]

## [Main Content Sections]
[Detailed specification organized by intent, not technology]

## Configuration
[Complete, working YAML/JSON examples]

## Related Documentation
[Cross-references to other specs]
```

### Section Order Matters

The order is intentional and optimized for how LLMs process documents:

1. **Navigation** (top) — Should I read this? What's in it? What else do I need?
2. **Principles** — What mental model should I apply?
3. **Quick references** — Tables and code for the most common operations
4. **Detailed patterns** — Full explanations with complete code
5. **Configuration** — How to wire it up
6. **Cross-references** (bottom) — Where to go next

---

## Design Principles for Specs

These principles apply to every spec you write.

### 1. Write for decision-making, not just description

Bad: "The system supports caching."
Good: "Use L1 (in-process) for data that changes less than once per minute and is read more than 100x/sec. Use L2 (Redis) for data shared across instances."

Every section should help the reader **choose** something — a pattern, an approach, a configuration value.

### 2. Front-load the most useful information

Put the information people need most often at the top. The LLM Navigation Guide is first. Quick Reference tables come before deep dives. Decision matrices come before implementation details.

Think: "If someone could only read the first 50 lines, what should they see?"

### 3. Be concrete, not abstract

Bad: "Errors should be handled appropriately."
Good:

```go
if err != nil {
    return errutil.Wrap(err, errutil.CodeNotFound, "device %s not found", id)
}
```

Every pattern needs a complete, working code example. Not pseudocode. Not abbreviated. Complete.

### 4. Use tables for everything structured

Tables are the most LLM-friendly format for structured information. Use them for:
- Decision matrices (when to use X vs Y)
- Field definitions (name, type, required, description)
- Error code catalogs
- Configuration options
- Comparison of approaches

### 5. Organize by intent, not by technology

Bad section names: "PostgreSQL", "Redis Configuration", "Go Structs"
Good section names: "When to Use Each Cache Layer", "Intent-Specific Types", "Migration Strategies"

The reader comes with a task, not a technology. Organize around what they're trying to accomplish.

### 6. Make every section self-contained

A section should be understandable without reading everything above it. This matters because LLMs may extract individual sections. Include enough context in each section that it stands alone.

### 7. Cross-reference explicitly

Never assume the reader has seen another doc. When referencing patterns from another spec, either:
- Include the essential information inline with a reference
- Use "See [spec.md] for the complete pattern" with a clear path

---

## Writing Quick Reference Tables

Quick Reference tables are the most valuable part of a spec. They answer the most common questions in scannable form.

### Decision Matrix

Use when the reader needs to **choose between options**.

```markdown
### Quick Reference: Backend Selection

| Scenario | Use L1 Only | Use L2 Only | Use L1+L2 |
|----------|-------------|-------------|-----------|
| Single instance, hot data | Yes | - | - |
| Multi-instance, shared state | - | Yes | - |
| Multi-instance, hot + shared | - | - | Yes |
| Session data | - | Yes | - |
| Config/feature flags | Yes | - | - |
```

### Field Reference

Use for **data model documentation**.

```markdown
### Quick Reference: Base Entity Fields

| Field | Type | Required | Auto-Set | Description |
|-------|------|----------|----------|-------------|
| `id` | UUIDv7 | Yes | On create | Time-ordered unique identifier |
| `tenant_id` | UUIDv7 | Yes | From context | Tenant isolation key |
| `created_at` | RFC 3339 | Yes | On create | Creation timestamp |
| `updated_at` | RFC 3339 | Yes | On mutation | Last modification timestamp |
| `deleted_at` | RFC 3339 | No | On soft delete | Soft delete marker |
```

### Error/Code Catalog

Use for **enumerated values** the reader needs to look up.

```markdown
### Quick Reference: Error Codes

| Code | HTTP | Meaning | When to Use |
|------|------|---------|-------------|
| E1001 | 401 | Unauthorized | Missing or invalid token |
| E1002 | 403 | Forbidden | Valid token, insufficient permissions |
| E2001 | 400 | Validation failed | Request body fails validation |
| E3001 | 404 | Not found | Entity doesn't exist or not visible |
| E4001 | 409 | Conflict | Duplicate key or version mismatch |
```

### Scenario-to-Action Mapping

Use when the reader knows **what they want to do** but not **how**.

```markdown
### Quick Reference: Common Patterns

| I want to... | Pattern | Example |
|--------------|---------|---------|
| Create an entity | `POST /api/v1/{entities}` | `POST /api/v1/devices` |
| List with filters | `GET /api/v1/{entities}?filter=...` | `GET /api/v1/devices?status=active` |
| Partial update | `PATCH` with JSON Patch | `[{"op":"replace","path":"/name","value":"new"}]` |
| Soft delete | `DELETE /api/v1/{entities}/:id` | Sets `deleted_at`, doesn't remove |
```

---

## Writing Code Examples

### Rules

1. **Complete, not abbreviated** — Show every field, every import, every error check
2. **Commented** — Explain non-obvious lines
3. **Runnable** — Someone should be able to paste this and have it work (minus project-specific imports)
4. **Consistent** — Follow the patterns in `go-generation-guide.md`

### Struct Definitions

Always show all fields with comments:

```go
// Device represents a physical or virtual device in the platform.
type Device struct {
    ID          uuid.UUID  `json:"id" db:"id"`
    TenantID    uuid.UUID  `json:"tenant_id" db:"tenant_id"`
    Name        string     `json:"name" db:"name"`
    DeviceType  string     `json:"device_type" db:"device_type"`
    Status      string     `json:"status" db:"status"`
    Metadata    Metadata   `json:"metadata,omitempty" db:"metadata"`
    CreatedAt   time.Time  `json:"created_at" db:"created_at"`
    UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
    DeletedAt   *time.Time `json:"deleted_at,omitempty" db:"deleted_at"`
}
```

### Intent-Specific Types

Show the full set — Create, Patch, Response, Row:

```go
// DeviceCreate holds fields for creating a new device.
type DeviceCreate struct {
    Name       string   `json:"name" validate:"required,min=1,max=255"`
    DeviceType string   `json:"device_type" validate:"required"`
    Metadata   Metadata `json:"metadata,omitempty"`
}

// DevicePatch holds fields for partial updates via JSON Patch.
type DevicePatch struct {
    Name     *string  `json:"name,omitempty" validate:"omitempty,min=1,max=255"`
    Metadata Metadata `json:"metadata,omitempty"`
}

// DeviceResponse is the API response representation.
type DeviceResponse struct {
    ID         uuid.UUID  `json:"id"`
    Name       string     `json:"name"`
    DeviceType string     `json:"device_type"`
    Status     string     `json:"status"`
    Metadata   Metadata   `json:"metadata,omitempty"`
    CreatedAt  time.Time  `json:"created_at"`
    UpdatedAt  time.Time  `json:"updated_at"`
}
```

### Interface Definitions

Show small, composable interfaces:

```go
type DeviceReader interface {
    Get(ctx context.Context, id uuid.UUID) (*Device, error)
    List(ctx context.Context, filter Filter) ([]*Device, string, error)
}

type DeviceWriter interface {
    Create(ctx context.Context, d *DeviceCreate) (*Device, error)
    Update(ctx context.Context, id uuid.UUID, patch *DevicePatch) (*Device, error)
}

type DeviceDeleter interface {
    Delete(ctx context.Context, id uuid.UUID) error
}

type DeviceRepository interface {
    DeviceReader
    DeviceWriter
    DeviceDeleter
}
```

### Configuration Examples

Always complete, with comments for every field:

```yaml
cache:
  l1:
    enabled: true
    max_size: 10000          # Maximum number of entries
    ttl: 5m                  # Time-to-live per entry
  l2:
    enabled: true
    backend: redis
    address: localhost:6379
    ttl: 30m
    max_memory: 256mb        # Redis maxmemory setting
    eviction: allkeys-lru    # Eviction policy
```

---

## Writing by Layer

Each layer has different expectations for depth and focus.

### Framework Specs (`framework/`)

**Purpose**: Define patterns that apply to every feature in the project.

**Expected depth**: Deep. These are the foundation. 500-2000 lines is normal.

**Must include**:
- Design principles (the "why")
- Decision matrices (when to use pattern A vs B)
- Complete code patterns with all variants
- Configuration reference with all options
- Error handling integration (which error codes apply)
- Performance considerations (benchmarks, limits)
- Cross-references to every spec that depends on this one

**Example framework specs to create**:

| Spec | What to Document |
|------|------------------|
| `api-design.md` | REST conventions, URL patterns, request/response shapes, pagination, content types, versioning |
| `error-handling.md` | Error code catalog, classification (transient/permanent), HTTP mapping, retry behavior, error response format |
| `models.md` | Base entity fields, intent-specific types (Create/Patch/Response), soft delete, audit trails, versioning |
| `data-access.md` | Repository pattern, query patterns, transaction handling, migration strategy, multi-DB support |
| `authentication.md` | Auth methods (JWT, API key, OIDC), token lifecycle, session management, provider integration |
| `observability.md` | Structured logging conventions, trace propagation, metrics naming, dashboard patterns |
| `validation.md` | Validation rules, struct tags, custom validators, error message format |
| `testing-guide.md` | Test patterns, fixtures, mocking strategy, integration test setup, coverage expectations |

### Package Specs (`pkg-specs/`)

**Purpose**: Document a reusable internal package that could be used across features.

**Expected depth**: Medium-deep. 300-1500 lines. Focus on the interface contract and backend options.

**Must include**:
- Package directory layout (with the registry pattern if multi-backend)
- Core interfaces with full method signatures
- Backend comparison table (when to use each)
- Configuration for each backend
- Usage examples showing the typical call flow
- Error handling (which errors this package returns)
- Metrics/observability integration
- Performance characteristics

**Example package specs**:

| Spec | What to Document |
|------|------------------|
| `caching.md` | L1/L2 layers, cache-aside pattern, invalidation, stampede prevention |
| `messagebus.md` | Publish/subscribe interface, topic conventions, delivery guarantees |
| `blobs.md` | Object storage interface, backends (S3, filesystem), presigned URLs |
| `notify.md` | Notification channels (email, push, webhook), template system, delivery tracking |

### Platform Specs (`platform-specs/`)

**Purpose**: Document features specific to your project's domain.

**Expected depth**: Medium. 200-800 lines. Focus on the domain model and behavior.

**Must include**:
- Domain model with all fields and relationships
- API endpoints table (method, path, description)
- Business rules and validation constraints
- State machines or workflow diagrams (if applicable)
- Integration points with other platform features
- Example API requests and responses

**Example platform specs**:

| Spec | What to Document |
|------|------------------|
| `models.md` | All domain entities, relationships, field definitions |
| `routes.md` | Complete API route table with auth requirements |
| Domain feature specs | One per major feature area (billing, inventory, etc.) |

---

## Spec Templates

### Framework Spec Template

````markdown
# {Feature Name}

{One-two sentence description of what this spec covers and why it matters.}

> **LLM Quick Reference**: {Brief summary for scanning.}

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Implementing {feature} in a new service
- Adding {feature} support to an existing endpoint
- Choosing between {option A} and {option B}
- Debugging {feature}-related issues
- Understanding how {feature} integrates with other systems

### Key Sections

| Section | Purpose |
|---------|---------|
| **Design Principles** | Core decisions and rationale |
| **{Pattern 1}** | {What it covers} |
| **{Pattern 2}** | {What it covers} |
| **Configuration** | All configuration options |

### Quick Reference: {Most Common Lookup}

| Scenario | Approach | Notes |
|----------|----------|-------|
| {Common scenario 1} | {Answer} | {Context} |
| {Common scenario 2} | {Answer} | {Context} |

### Context Loading

1. For **{feature} only**: This doc is sufficient
2. For **error handling**: Also load `./error-handling.md`
3. For **API integration**: Also load `./api-design.md`

---

## Design Principles

| Principle | Rule |
|-----------|------|
| **{Principle 1}** | {Concrete rule} |
| **{Principle 2}** | {Concrete rule} |
| **{Principle 3}** | {Concrete rule} |

---

## {Pattern 1}

### Overview

{2-3 sentences explaining the pattern and when to use it.}

### Implementation

```go
// Complete, working code example
```

### Configuration

```yaml
# Complete configuration with comments
```

---

## {Pattern 2}

{Same structure as Pattern 1}

---

## Related Documentation

- [{Related spec 1}](./{file}.md) - {Why relevant}
- [{Related spec 2}](./{file}.md) - {Why relevant}
````

### Package Spec Template

````markdown
# {Package Name}

{What this package provides and why it exists as a separate package.}

> **LLM Quick Reference**: {Brief summary.}

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Implementing features that need {capability}
- Choosing a {package} backend for your deployment
- Configuring {package} for a new service
- Troubleshooting {package}-related issues

### Key Sections

| Section | Purpose |
|---------|---------|
| **Core Interfaces** | Method signatures and contracts |
| **Backend Selection** | When to use each backend |
| **Configuration** | All configuration options |
| **Usage Examples** | Common integration patterns |

### Quick Reference: Backend Selection

| Scenario | Backend | Rationale |
|----------|---------|-----------|
| {Scenario 1} | {Backend} | {Why} |
| {Scenario 2} | {Backend} | {Why} |

### Quick Reference: Core Interface

```go
type {Package} interface {
    {Method1}(ctx context.Context, ...) (...)
    {Method2}(ctx context.Context, ...) (...)
}
```

### Context Loading

1. For **{package} usage**: This doc is sufficient
2. For **error codes**: Also load `../framework/error-handling.md`
3. For **registry pattern**: Also load `./README.md`

---

## Design Principles

{3-5 principles specific to this package}

---

## Package Structure

```
pkg/{package}/
├── {package}.go       # Core interface and types
├── registry.go        # Register() and New()
├── options.go         # Functional options
├── backend/
│   ├── memory/        # In-memory (always available for tests)
│   └── {backend}/     # Production backend
```

---

## Core Interfaces

```go
// Complete interface definitions with doc comments
```

---

## Backend: {Name}

### When to Use

{Decision criteria}

### Configuration

```yaml
# Complete config
```

### Implementation Notes

{Backend-specific considerations}

---

## Usage Examples

### Basic Usage

```go
// Complete working example
```

---

## Error Handling

| Error | Code | When |
|-------|------|------|
| {Error 1} | {E-code} | {Condition} |

---

## Related Documentation

- [Framework error handling](../framework/error-handling.md)
- [Go generation guide](../framework/go-generation-guide.md)
````

### Platform Spec Template

````markdown
# {Feature Name}

{What this feature does in the context of your platform.}

> **LLM Quick Reference**: {Brief summary.}

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Implementing {feature} endpoints
- Understanding the {feature} domain model
- Integrating {feature} with other platform features
- Debugging {feature} behavior

### Key Sections

| Section | Purpose |
|---------|---------|
| **Domain Model** | Entity definitions and relationships |
| **API Endpoints** | Routes, methods, request/response shapes |
| **Business Rules** | Validation and behavioral constraints |
| **Integration Points** | How this feature connects to others |

### Quick Reference: API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/{entities}` | Create |
| GET | `/api/v1/{entities}` | List (paginated) |
| GET | `/api/v1/{entities}/:id` | Get by ID |
| PATCH | `/api/v1/{entities}/:id` | Partial update |
| DELETE | `/api/v1/{entities}/:id` | Soft delete |

### Context Loading

1. For **{feature} only**: This doc is sufficient
2. For **API conventions**: Also load `../framework/api-design.md`
3. For **model patterns**: Also load `../framework/models.md`

---

## Domain Model

### {Entity Name}

```go
type {Entity} struct {
    // Complete struct definition
}
```

### Relationships

{Diagram or table showing entity relationships}

---

## API Endpoints

### Create {Entity}

**`POST /api/v1/{entities}`**

Request:
```json
{
  "name": "example",
  "type": "standard"
}
```

Response (`201 Created`):
```json
{
  "id": "018f6b1a-...",
  "name": "example",
  "type": "standard",
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

## Business Rules

| Rule | Description | Error Code |
|------|-------------|------------|
| {Rule 1} | {What it enforces} | {E-code} |
| {Rule 2} | {What it enforces} | {E-code} |

---

## Integration Points

| Feature | Integration | Direction |
|---------|-------------|-----------|
| {Feature} | {How they connect} | {Inbound/Outbound} |

---

## Related Documentation

- [Models](./models.md) - Domain model reference
- [Routes](./routes.md) - Complete route table
````

---

## Checklist: Before Committing a Spec

- [ ] Title and one-line description at top
- [ ] `> **LLM Quick Reference**:` blockquote
- [ ] LLM Navigation Guide with all four subsections
- [ ] "When to Use" has 5-8 specific scenarios
- [ ] At least one Quick Reference table
- [ ] Context Loading with numbered cross-references
- [ ] Design Principles section
- [ ] All code examples are complete and runnable
- [ ] Configuration examples include every field with comments
- [ ] All referenced specs exist (or are noted as "to be created")
- [ ] Cross-references use relative paths
- [ ] `---` horizontal rule separates navigation from content

---

## Related Documentation

- [LLM Style Guide](./LLM-STYLE-GUIDE.md) - Detailed format for LLM navigation sections
- [LLM Orchestration Guide](./LLM.md) - Master entry point, execution order, plan workflow
- [Go Generation Guide](./framework/go-generation-guide.md) - Code patterns for Go specs
