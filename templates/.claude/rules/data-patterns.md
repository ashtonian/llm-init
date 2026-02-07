---
paths:
  - "**/repository*"
  - "**/repo*"
  - "**/store*"
  - "**/model*"
  - "**/migration*"
  - "**/schema*"
  - "**/*_repo.*"
  - "**/db/**"
---

# Data Access Patterns

Mandatory patterns for database schema design, repository implementation, migrations, and query optimization in multi-tenant SaaS applications.

## Repository Pattern

### Interface-Based Design

Every data access layer MUST be defined as an interface. Implementations are injected via dependency injection.

```go
// Domain layer -- defines the interface
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*User, error)
    FindByEmail(ctx context.Context, email string) (*User, error)
    List(ctx context.Context, filter UserFilter) (*PagedResult[User], error)
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id uuid.UUID) error  // Soft delete
    HardDelete(ctx context.Context, id uuid.UUID) error  // GDPR compliance
}

// Infrastructure layer -- PostgreSQL implementation
type pgUserRepository struct {
    db *sql.DB
}

// Test layer -- in-memory implementation
type memUserRepository struct {
    mu    sync.RWMutex
    users map[uuid.UUID]*User
}
```

### One Repository Per Aggregate Root

- An **aggregate root** is the top-level entity that owns a cluster of related entities
- Child entities are accessed THROUGH the aggregate root's repository
- Example: `OrderRepository` manages `Order` + `OrderItem` + `OrderStatus` -- you don't create a separate `OrderItemRepository`

### Method Naming Conventions

| Method | Purpose | Returns |
|--------|---------|---------|
| `FindByID(ctx, id)` | Single lookup by primary key | `(*T, error)` -- returns `ErrNotFound` if missing |
| `FindBy{Field}(ctx, value)` | Single lookup by unique field | `(*T, error)` |
| `List(ctx, filter)` | Paginated, filtered list | `(*PagedResult[T], error)` |
| `Create(ctx, entity)` | Insert new entity | `error` |
| `Update(ctx, entity)` | Update existing entity | `error` -- returns `ErrNotFound` if missing |
| `Delete(ctx, id)` | Soft delete (set deleted_at) | `error` |
| `HardDelete(ctx, id)` | Permanent deletion (GDPR) | `error` |
| `Exists(ctx, id)` | Check existence | `(bool, error)` |
| `Count(ctx, filter)` | Count matching entities | `(int64, error)` |

## Base Entity Fields

Every table MUST include these columns:

```sql
CREATE TABLE {entities} (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL REFERENCES tenants(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ,
    created_by  UUID        REFERENCES users(id),
    updated_by  UUID        REFERENCES users(id)
);
```

### Corresponding Go Struct

```go
type BaseEntity struct {
    ID        uuid.UUID  `json:"id" db:"id"`
    TenantID  uuid.UUID  `json:"tenant_id" db:"tenant_id"`
    CreatedAt time.Time  `json:"created_at" db:"created_at"`
    UpdatedAt time.Time  `json:"updated_at" db:"updated_at"`
    DeletedAt *time.Time `json:"deleted_at,omitempty" db:"deleted_at"`
    CreatedBy uuid.UUID  `json:"created_by" db:"created_by"`
    UpdatedBy uuid.UUID  `json:"updated_by" db:"updated_by"`
}

// Embed in all domain entities
type User struct {
    BaseEntity
    Email    string `json:"email" db:"email"`
    Name     string `json:"name" db:"name"`
    Role     Role   `json:"role" db:"role"`
}
```

## Soft Deletes

**Default behavior**: All deletes are soft deletes (`SET deleted_at = now()`).

Every query MUST include `AND deleted_at IS NULL` (enforced in the repository layer):

```go
func (r *pgUserRepo) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
    tenantID := tenant.FromContext(ctx)
    row := r.db.QueryRowContext(ctx,
        `SELECT id, tenant_id, email, name, role, created_at, updated_at
         FROM users
         WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL`,
        id, tenantID,
    )
    // ...
}
```

### Hard Delete (GDPR Compliance)

For right-to-erasure requests:
1. Hard delete the user record AND all associated data
2. Anonymize audit logs (replace user details with "deleted-user-{hash}")
3. Remove from search indexes, caches, and external systems
4. Log the deletion event (for compliance audit, without PII)

## Audit Trail

For compliance-critical entities, maintain a full audit trail:

```sql
CREATE TABLE audit_log (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL,
    entity_type TEXT        NOT NULL,
    entity_id   UUID        NOT NULL,
    action      TEXT        NOT NULL CHECK (action IN ('create', 'update', 'delete', 'hard_delete')),
    actor_id    UUID,
    actor_type  TEXT        NOT NULL DEFAULT 'user' CHECK (actor_type IN ('user', 'system', 'api_key')),
    changes     JSONB,
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for common query patterns
CREATE INDEX idx_audit_log_entity ON audit_log (tenant_id, entity_type, entity_id, created_at DESC);
CREATE INDEX idx_audit_log_actor ON audit_log (tenant_id, actor_id, created_at DESC);
CREATE INDEX idx_audit_log_time ON audit_log (tenant_id, created_at DESC);
```

### Changes Format

```json
{
  "name": { "old": "John", "new": "Jonathan" },
  "email": { "old": "john@old.com", "new": "john@new.com" }
}
```

### Metadata Format

```json
{
  "request_id": "uuid",
  "ip_address": "192.168.1.1",
  "user_agent": "Mozilla/5.0...",
  "source": "api"
}
```

## Migration Best Practices

### File Naming

```
migrations/
  20240115103000_create_users.up.sql
  20240115103000_create_users.down.sql
  20240115110000_add_user_avatar.up.sql
  20240115110000_add_user_avatar.down.sql
```

Format: `YYYYMMDDHHMMSS_description.{up|down}.sql`

### Safe Migration Patterns

| Operation | Safe Pattern |
|-----------|-------------|
| Add column | `ALTER TABLE t ADD COLUMN c TYPE DEFAULT val` (Postgres 11+ doesn't rewrite) |
| Add NOT NULL column | Step 1: Add nullable. Step 2: Backfill. Step 3: Add NOT NULL constraint |
| Drop column | Step 1: Remove code references. Step 2: Drop column in later migration |
| Rename column | Step 1: Add new column. Step 2: Backfill. Step 3: Remove old column |
| Add index | `CREATE INDEX CONCURRENTLY` (doesn't lock table) |
| Change column type | Step 1: Add new column. Step 2: Backfill. Step 3: Swap. Step 4: Drop old |

### Migration Testing

Every migration must pass this sequence:
1. `up` (apply migration)
2. Verify data integrity
3. `down` (reverse migration)
4. Verify data integrity
5. `up` again (re-apply -- must be idempotent-safe)

## Connection Management

### Pool Configuration

```go
db.SetMaxOpenConns(25)              // Match pgbouncer pool size
db.SetMaxIdleConns(10)              // Keep warm connections
db.SetConnMaxLifetime(5 * time.Minute)  // Rotate connections
db.SetConnMaxIdleTime(1 * time.Minute)  // Close idle connections
```

Rule of thumb for pool size: `(num_cores * 2) + effective_spindle_count`

### PgBouncer Configuration

```ini
[pgbouncer]
pool_mode = transaction          ; Release connection after transaction
max_client_conn = 1000           ; Accept many client connections
default_pool_size = 25           ; Limit actual DB connections
reserve_pool_size = 5            ; Emergency pool
reserve_pool_timeout = 3         ; Seconds before using reserve
server_idle_timeout = 300        ; Close idle server connections
```

## Query Optimization

### N+1 Prevention

```go
// BAD: N+1 queries
users, _ := userRepo.List(ctx, filter)
for _, user := range users {
    roles, _ := roleRepo.FindByUserID(ctx, user.ID)  // N queries!
    user.Roles = roles
}

// GOOD: Batch load with JOIN
users, _ := userRepo.ListWithRoles(ctx, filter)

// GOOD: Batch load with IN clause
userIDs := extractIDs(users)
roleMap, _ := roleRepo.FindByUserIDs(ctx, userIDs)  // Single query
for _, user := range users {
    user.Roles = roleMap[user.ID]
}

// GOOD: DataLoader pattern for GraphQL
loader := dataloader.NewBatchedLoader(func(keys []string) []*dataloader.Result {
    roles, err := roleRepo.FindByUserIDs(ctx, keys)
    // ...
})
```

### EXPLAIN ANALYZE

Before shipping any query that runs on tables with >1000 rows:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.id, u.name, u.email
FROM users u
WHERE u.tenant_id = $1
  AND u.deleted_at IS NULL
  AND u.role = $2
ORDER BY u.created_at DESC
LIMIT 50;
```

Red flags:
- `Seq Scan` on a large table (missing index)
- `Sort` with `external merge Disk` (sort spilling to disk)
- `Nested Loop` with high row counts (should be Hash Join)
- `Buffers: shared read` much higher than `shared hit` (cold cache or bad index)

### Index Recommendations

```sql
-- Every foreign key MUST have an index
CREATE INDEX idx_users_tenant_id ON users (tenant_id);

-- Composite for common query patterns (most selective column first)
CREATE INDEX idx_users_tenant_role ON users (tenant_id, role) WHERE deleted_at IS NULL;

-- Covering index (includes data columns to avoid table lookup)
CREATE INDEX idx_users_tenant_email ON users (tenant_id, email)
    INCLUDE (name, role) WHERE deleted_at IS NULL;

-- Unique constraints
CREATE UNIQUE INDEX idx_users_tenant_email_unique
    ON users (tenant_id, email) WHERE deleted_at IS NULL;

-- Full text search
CREATE INDEX idx_users_search ON users
    USING gin(to_tsvector('english', name || ' ' || email));
```

## Caching Patterns

### Cache-Aside Pattern (Default)

```go
func (s *UserService) GetByID(ctx context.Context, id uuid.UUID) (*User, error) {
    tenantID := tenant.FromContext(ctx)
    cacheKey := fmt.Sprintf("tenant:%s:user:%s", tenantID, id)

    // Try cache first
    cached, err := s.cache.Get(ctx, cacheKey)
    if err == nil {
        return cached.(*User), nil
    }

    // Cache miss -- load from DB
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    // Populate cache
    s.cache.Set(ctx, cacheKey, user, 5*time.Minute)
    return user, nil
}
```

### Cache Key Convention

```
tenant:{tenant_id}:entity:{entity_id}          # Single entity
tenant:{tenant_id}:entity:list:{filter_hash}    # List/query result
tenant:{tenant_id}:config                        # Tenant configuration
```

ALWAYS scope cache keys by tenant. NEVER use a cache key without tenant_id for tenant data.

### Cache Invalidation

```go
func (s *UserService) Update(ctx context.Context, user *User) error {
    if err := s.repo.Update(ctx, user); err != nil {
        return err
    }
    // Invalidate specific entry
    s.cache.Delete(ctx, fmt.Sprintf("tenant:%s:user:%s", user.TenantID, user.ID))
    // Invalidate list caches (they might include this entity)
    s.cache.DeletePattern(ctx, fmt.Sprintf("tenant:%s:user:list:*", user.TenantID))
    return nil
}
```

## Event Sourcing (When Applicable)

Use for entities requiring full history (billing, permissions, audit-critical):

```sql
CREATE TABLE events (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL,
    stream_id   UUID        NOT NULL,        -- Aggregate ID
    stream_type TEXT        NOT NULL,        -- e.g., "subscription", "permission"
    version     INTEGER     NOT NULL,        -- Monotonically increasing per stream
    event_type  TEXT        NOT NULL,        -- e.g., "SubscriptionCreated"
    payload     JSONB       NOT NULL,
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (stream_id, version)
);
```

## Transaction Management

Transactions belong at the **service layer**, NOT the repository layer:

```go
// Service layer manages transactions
func (s *OrderService) PlaceOrder(ctx context.Context, input OrderInput) (*Order, error) {
    return s.txManager.WithTransaction(ctx, func(tx Transaction) error {
        order := &Order{...}
        if err := s.orderRepo.WithTx(tx).Create(ctx, order); err != nil {
            return err
        }
        for _, item := range input.Items {
            if err := s.inventoryRepo.WithTx(tx).Decrement(ctx, item.ProductID, item.Qty); err != nil {
                return err  // Transaction rolls back automatically
            }
        }
        return s.auditRepo.WithTx(tx).Log(ctx, "order_placed", order.ID)
    })
}
```

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| `SELECT *` in repositories | Select specific columns |
| Query inside a loop (N+1) | JOINs or batch load with `WHERE id = ANY($1)` |
| Transactions in repository layer | Transaction management at service layer |
| No tenant_id in cache keys | ALWAYS scope cache keys by tenant_id |
| DROP COLUMN in single migration | Multi-step: remove code, then drop column |
| No index on foreign keys | Index every foreign key column |
| String concatenation for queries | Parameterized queries ONLY |
| Unbounded SELECT (no LIMIT) | Always paginate, always LIMIT |
| Hard delete as default | Soft delete (deleted_at) as default |
| Shared repository for child entities | One repository per aggregate root |
