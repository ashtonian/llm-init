# Multi-Tenancy Patterns

Mandatory patterns for building multi-tenant SaaS applications. Every feature, every endpoint, every query must respect tenant isolation.

## Tenant Isolation Model

**Architecture**: Shared database with `tenant_id` column + Row Level Security (PostgreSQL).

All tenant data lives in the same database. Isolation is enforced at two layers:
1. **Application layer**: Repository pattern scopes every query with `tenant_id`
2. **Database layer**: PostgreSQL Row Level Security (RLS) as a safety net

This provides the best balance of operational simplicity (one database to manage) and security (defense in depth).

### When to Use Dedicated Resources

| Scenario | Isolation Level | Justification |
|----------|----------------|---------------|
| Standard tenant | Shared DB + RLS | Default model, cost-effective |
| Enterprise (compliance) | Dedicated schema or DB | HIPAA, data residency, contractual requirement |
| Extreme scale tenant | Dedicated compute + DB | Noisy neighbor prevention, custom SLAs |

## Data Scoping

Every database query MUST include `tenant_id` in the WHERE clause. This is enforced via the repository layer.

### Go Pattern

```go
// Repository interface -- every method takes context with tenant
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*User, error)
    List(ctx context.Context, filter UserFilter) ([]User, error)
    Create(ctx context.Context, user *User) error
}

// Implementation -- extract tenant from context, scope every query
func (r *pgUserRepo) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
    tenantID := tenant.FromContext(ctx) // NEVER skip this
    var user User
    err := r.db.QueryRowContext(ctx,
        "SELECT * FROM users WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL",
        id, tenantID,
    ).Scan(&user)
    return &user, err
}
```

### TypeScript/Node Pattern

```typescript
// Middleware extracts tenant from JWT
const tenantMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const tenantId = req.auth?.tenantId;
  if (!tenantId) return res.status(401).json({ error: 'No tenant context' });
  req.tenantId = tenantId;
  next();
};

// Repository scopes every query
class UserRepository {
  async findById(tenantId: string, id: string): Promise<User | null> {
    return this.db.query(
      'SELECT * FROM users WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL',
      [id, tenantId]
    );
  }
}
```

### Anti-Patterns (NEVER do these)

```go
// BAD: No tenant scoping
func (r *pgUserRepo) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
    return r.db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = $1", id)
}

// BAD: Tenant from URL parameter (can be spoofed)
func handler(w http.ResponseWriter, r *http.Request) {
    tenantID := r.URL.Query().Get("tenant_id") // NEVER DO THIS
}

// BAD: Tenant from request body for scoping
type Request struct {
    TenantID uuid.UUID `json:"tenant_id"` // NEVER accept for scoping
}
```

## Tenant Context Propagation

### Go: context.Context

```go
package tenant

type contextKey struct{}

func WithTenant(ctx context.Context, tenantID uuid.UUID) context.Context {
    return context.WithValue(ctx, contextKey{}, tenantID)
}

func FromContext(ctx context.Context) uuid.UUID {
    id, ok := ctx.Value(contextKey{}).(uuid.UUID)
    if !ok {
        panic("tenant.FromContext: no tenant in context") // Fail loud, never silently skip
    }
    return id
}
```

### Node.js: AsyncLocalStorage

```typescript
import { AsyncLocalStorage } from 'node:async_hooks';

const tenantStorage = new AsyncLocalStorage<string>();

// Middleware
app.use((req, res, next) => {
  const tenantId = req.auth.tenantId;
  tenantStorage.run(tenantId, () => next());
});

// Anywhere in the call stack
function getCurrentTenant(): string {
  const id = tenantStorage.getStore();
  if (!id) throw new Error('No tenant context');
  return id;
}
```

## Cross-Tenant Access Rules

- **NEVER** allow one tenant to access another tenant's data, even through admin endpoints.
- **Admin access**: Super admins use a separate admin service that explicitly targets a tenant (with full audit logging). The admin service sets the tenant context, not the admin user directly.
- **Impersonation**: Time-limited, fully audited sessions. Record: who impersonated, which tenant, start/end time, all actions taken.
- **Reporting**: Cross-tenant aggregation happens in a separate analytics pipeline with anonymized/aggregated data. Never expose raw cross-tenant data.

## Tenant-Specific Configuration

```go
type TenantConfig struct {
    // Plan-based limits
    MaxUsers       int
    MaxStorage     int64 // bytes
    MaxAPIRequests int   // per minute

    // Feature flags
    Features map[string]bool

    // Custom branding
    LogoURL      string
    PrimaryColor string
    CustomDomain string

    // Compliance
    DataRegion   string // "us", "eu", "ap"
    RetentionDays int
}
```

Configuration hierarchy (each level inherits from above):
1. **System defaults**: Applied to all tenants
2. **Plan defaults**: Per pricing tier (free, pro, enterprise)
3. **Tenant overrides**: Per-tenant customization
4. **User preferences**: Per-user settings within a tenant

## Data Residency

For compliance (GDPR, data sovereignty):

- **Region pinning**: Store tenant's data in the specified region. Enforce at the database routing layer.
- **Region field**: Every tenant has a `data_region` field set at creation time.
- **Cross-region prohibition**: Data must not leave the designated region. This includes caches, logs, and backups.
- **Region-aware routing**: API gateway routes requests to the correct regional deployment based on tenant config.

## Tenant Lifecycle

### Provisioning (< 30 seconds)
1. Create tenant record in the tenants table
2. Create default admin user
3. Seed default configuration (from plan template)
4. Set up tenant-specific resources if needed (dedicated schema, storage bucket)
5. Send welcome email / trigger onboarding flow

### Suspension
1. Set `tenant.status = 'suspended'`
2. Reject all API requests with 403 and a suspension message
3. Preserve all data (do NOT delete)
4. Send notification to tenant admins
5. Allow reactivation within grace period

### Deletion
1. Set `tenant.status = 'pending_deletion'`
2. Grace period (30 days default, configurable)
3. Export data if requested (GDPR data portability)
4. Hard delete all tenant data (all tables with tenant_id)
5. Remove from caches, search indexes, and analytics
6. Log deletion event for audit compliance
7. Deletion is irreversible after grace period

## Testing Multi-Tenancy

Every test must:

1. **Run in a tenant context**: Create a test tenant, set the context, run the test.
2. **Test isolation**: Create data in Tenant A, verify Tenant B cannot see it.
3. **Test boundary enforcement**: Attempt cross-tenant access, verify it's blocked.
4. **Test lifecycle**: Test provisioning, suspension, and deletion flows.

```go
func TestUserCreate_IsolatedBetweenTenants(t *testing.T) {
    tenantA := createTestTenant(t)
    tenantB := createTestTenant(t)

    ctxA := tenant.WithTenant(context.Background(), tenantA.ID)
    ctxB := tenant.WithTenant(context.Background(), tenantB.ID)

    user, err := repo.Create(ctxA, &User{Name: "Alice"})
    require.NoError(t, err)

    // Tenant B cannot see Tenant A's user
    _, err = repo.FindByID(ctxB, user.ID)
    require.ErrorIs(t, err, ErrNotFound)
}
```
