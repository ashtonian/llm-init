---
paths:
  - "**/auth/**"
  - "**/middleware/**"
  - "**/session*"
  - "**/token*"
  - "**/rbac*"
  - "**/permission*"
---

# Authentication & Authorization Patterns

Mandatory patterns for authentication, authorization, and session management in multi-tenant SaaS applications.

## Authentication: JWT-Based

### Token Strategy

| Token | Lifetime | Storage | Purpose |
|-------|----------|---------|---------|
| Access token | 15 minutes | Memory only (never localStorage) | API authentication |
| Refresh token | 7 days | httpOnly, Secure, SameSite cookie | Token rotation |
| ID token | Session duration | Memory only | User identity claims |

### Access Token Claims

```json
{
  "sub": "user-uuid",
  "tid": "tenant-uuid",
  "org": "org-uuid",
  "roles": ["admin"],
  "permissions": ["users:read", "users:write"],
  "iat": 1705312800,
  "exp": 1705313700,
  "iss": "https://auth.example.com",
  "aud": "https://api.example.com"
}
```

Required claims:
- `sub`: User ID (UUID)
- `tid`: Tenant ID (UUID) -- this is the PRIMARY tenant context
- `roles`: User's roles within the tenant
- `iss`: Token issuer (your auth service)
- `aud`: Intended audience (your API)
- `exp`: Expiration (short-lived, 15 min max)

### Token Refresh Flow

```
1. Client sends request with expired access token
2. Server returns 401 with `WWW-Authenticate: Bearer error="token_expired"`
3. Client sends refresh token to POST /auth/token/refresh
4. Server validates refresh token:
   a. Check signature and expiration
   b. Check token not in revocation list (Redis)
   c. Check user still active and tenant not suspended
5. Server issues new access token + new refresh token (rotation)
6. Old refresh token is invalidated (single-use)
7. Client retries original request with new access token
```

### Token Revocation

Maintain a revocation list in Redis:
- On logout: Add the user's refresh token to the revocation list
- On password change: Revoke ALL refresh tokens for the user
- On role change: Revoke ALL tokens (force re-authentication)
- On tenant suspension: Revoke ALL tokens for all users in the tenant

## Authorization: RBAC with Hierarchical Roles

### Role Hierarchy

```
Super Admin (platform-level)
  └── Tenant Admin (organization-level)
        └── Manager (team-level)
              └── Member (standard access)
                    └── Viewer (read-only)
```

Each role inherits all permissions from roles below it.

### Permission Model

Permissions use a `resource:action` format:

```
users:read          # View user profiles
users:write         # Create/update users
users:delete        # Delete users
users:invite        # Invite new users
billing:read        # View billing info
billing:write       # Update billing/subscription
settings:read       # View org settings
settings:write      # Update org settings
api-keys:manage     # Create/rotate/revoke API keys
```

### Role-Permission Mapping

```go
var rolePermissions = map[Role][]Permission{
    RoleViewer: {
        "users:read", "projects:read", "settings:read",
    },
    RoleMember: {
        // Inherits Viewer +
        "projects:write", "comments:write",
    },
    RoleManager: {
        // Inherits Member +
        "users:invite", "projects:delete", "teams:write",
    },
    RoleTenantAdmin: {
        // Inherits Manager +
        "users:write", "users:delete", "settings:write",
        "billing:read", "billing:write", "api-keys:manage",
    },
}
```

### Permission Check Implementation

```go
// Middleware for route-level permission check
func RequirePermission(perm Permission) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            claims := auth.ClaimsFromContext(r.Context())
            if claims == nil {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }
            if !hasPermission(claims.Roles, perm) {
                http.Error(w, "forbidden", http.StatusForbidden)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}

// Usage
router.Handle("POST /api/v1/users",
    RequirePermission("users:write")(createUserHandler),
)
```

### Resource-Level Permissions

For fine-grained access beyond RBAC:

```go
// Check if user can access a specific resource
type ResourceChecker interface {
    CanAccess(ctx context.Context, userID, resourceID uuid.UUID, action string) (bool, error)
}

// Implementation considers:
// 1. User's role-based permissions
// 2. Resource ownership (created_by)
// 3. Team membership (if resource is team-scoped)
// 4. Explicit resource-level grants
```

## Organization Hierarchy

```
Organization (top-level tenant)
  └── Workspace (optional grouping)
        └── Project (resource container)
              └── Resources (actual data)
```

- **Organization**: Maps to tenant. Has billing, plan, members.
- **Workspace**: Optional subdivision. Useful for departments/teams.
- **Project**: Primary scope for resources. Most permissions are project-level.

### Scoping Rules

| Resource Level | Who Can Access |
|---------------|---------------|
| Organization settings | Tenant admin only |
| Workspace | Workspace members + tenant admin |
| Project | Project members + workspace members (if project in workspace) + tenant admin |
| Resource | Project members with appropriate permission |

## Session Management

### Server-Side Sessions (Redis)

```go
type Session struct {
    ID        string    `json:"id"`
    UserID    uuid.UUID `json:"user_id"`
    TenantID  uuid.UUID `json:"tenant_id"`
    Roles     []string  `json:"roles"`
    IPAddress string    `json:"ip_address"`
    UserAgent string    `json:"user_agent"`
    CreatedAt time.Time `json:"created_at"`
    ExpiresAt time.Time `json:"expires_at"`
    LastSeen  time.Time `json:"last_seen"`
}

// Store in Redis with TTL
// Key: "session:{session_id}"
// TTL: matches refresh token lifetime (7 days)
```

### Session Invalidation Triggers

| Event | Action |
|-------|--------|
| Logout | Delete session, revoke refresh token |
| Password change | Delete ALL sessions for user |
| Role change | Delete ALL sessions (force re-auth) |
| Suspicious activity | Delete ALL sessions, require MFA |
| Tenant suspension | Delete ALL sessions for all tenant users |
| Account deletion | Delete ALL sessions, revoke all tokens |

## API Keys

For programmatic access (integrations, CI/CD):

```go
type APIKey struct {
    ID          uuid.UUID `json:"id"`
    TenantID    uuid.UUID `json:"tenant_id"`
    Name        string    `json:"name"`        // Human-readable label
    Prefix      string    `json:"prefix"`       // First 8 chars (for identification)
    Hash        string    `json:"-"`            // bcrypt hash of the full key
    Permissions []string  `json:"permissions"`  // Scoped permissions
    LastUsed    time.Time `json:"last_used"`
    ExpiresAt   time.Time `json:"expires_at"`   // Optional expiration
    CreatedBy   uuid.UUID `json:"created_by"`
}
```

Rules:
- Show the full key only ONCE at creation time. Store only the hash.
- Prefix the key for identification: `sk_live_abc123...` or `sk_test_abc123...`
- Scope permissions: API keys should have minimal required permissions.
- Track usage: Record `last_used` timestamp and request count.
- Rotation: Support key rotation with overlap period (both old and new work temporarily).

## SSO / Enterprise Authentication

### SAML 2.0

- Service Provider (SP) initiated flow for web application
- Support IdP-initiated flow for enterprise requirements
- Map SAML attributes to user record: email, name, role (if provided)
- JIT (Just-In-Time) provisioning: create user on first SAML login

### OIDC (OpenID Connect)

- Support standard OIDC providers (Google, Microsoft, Okta)
- Store `oidc_provider` and `oidc_subject` on user record for matching
- Validate `id_token` claims: `iss`, `aud`, `exp`, `nonce`

### Tenant-Specific SSO Configuration

```go
type SSOConfig struct {
    TenantID     uuid.UUID `json:"tenant_id"`
    Provider     string    `json:"provider"`      // "saml", "oidc"
    EntityID     string    `json:"entity_id"`     // SAML entity ID
    SSOURL       string    `json:"sso_url"`       // IdP login URL
    Certificate  string    `json:"certificate"`   // IdP signing cert
    DefaultRole  string    `json:"default_role"`  // Role for new SSO users
    EnforceSSO   bool      `json:"enforce_sso"`   // Disable password login
}
```

## Impersonation

Admin-only, fully audited, time-limited:

```go
type ImpersonationSession struct {
    AdminUserID   uuid.UUID `json:"admin_user_id"`
    TargetUserID  uuid.UUID `json:"target_user_id"`
    TargetTenant  uuid.UUID `json:"target_tenant_id"`
    Reason        string    `json:"reason"`        // Required justification
    StartedAt     time.Time `json:"started_at"`
    ExpiresAt     time.Time `json:"expires_at"`    // Max 1 hour
    ActionsLog    []Action  `json:"actions_log"`   // Every action recorded
}
```

Rules:
- Only super admins can impersonate
- Maximum session duration: 1 hour
- Reason/justification is required
- ALL actions during impersonation are logged with both admin and target user IDs
- Impersonation is visible in audit log and to the target user

## Security Headers

Every response MUST include:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0  (rely on CSP instead)
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

### CORS Configuration

```go
cors := cors.Options{
    AllowedOrigins:   []string{"https://app.example.com"},  // Never use "*" in production
    AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
    AllowedHeaders:   []string{"Authorization", "Content-Type", "X-Request-ID", "Idempotency-Key"},
    ExposedHeaders:   []string{"X-Request-ID", "X-RateLimit-Limit", "X-RateLimit-Remaining"},
    AllowCredentials: true,
    MaxAge:           86400,  // Cache preflight for 24 hours
}
```

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| Store tokens in localStorage | httpOnly cookies or memory only |
| Long-lived access tokens (>1hr) | 15-minute access + refresh rotation |
| Shared API keys between services | Service-specific keys with minimal permissions |
| Role check in every handler | Middleware-based permission enforcement |
| Password in URL parameters | Always in request body, over HTTPS |
| Hardcoded secrets | Environment variables or secret manager |
| `CORS: *` in production | Explicit allowed origins |
| No rate limiting on auth endpoints | Strict rate limiting + exponential backoff |
