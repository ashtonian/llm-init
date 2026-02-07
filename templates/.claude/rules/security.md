# Security Standards

Mandatory security patterns for every feature. Security is not a feature -- it's a constraint on every feature. These rules apply to all code, regardless of path.

## Input Validation

### Validate at System Boundaries

Every point where external data enters the system MUST be validated:

| Entry Point | Validation Required |
|-------------|-------------------|
| API handlers | Request body schema, query params, path params, headers |
| CLI arguments | Type, range, format, allowed values |
| Configuration | Schema validation at startup, fail fast on invalid config |
| File uploads | File type, size limit, content inspection (not just extension) |
| Webhooks | Signature verification, schema validation |
| Database reads | Defensive coding for unexpected nulls or corrupted data |

### Validation Rules

```go
// GOOD: Validate at the boundary, reject early
func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var input CreateUserInput
    if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }
    if err := input.Validate(); err != nil {
        respondError(w, http.StatusUnprocessableEntity, err.Error())
        return
    }
    // Only validated data reaches the service layer
    user, err := h.service.CreateUser(r.Context(), input)
}

// Validation method on the input type
func (i CreateUserInput) Validate() error {
    var errs []string
    if i.Email == "" {
        errs = append(errs, "email is required")
    } else if !isValidEmail(i.Email) {
        errs = append(errs, "email format is invalid")
    }
    if len(i.Name) > 100 {
        errs = append(errs, "name must be 100 characters or fewer")
    }
    if len(errs) > 0 {
        return &ValidationError{Fields: errs}
    }
    return nil
}
```

### Whitelist Over Blacklist

```go
// GOOD: Whitelist allowed values
var allowedRoles = map[string]bool{
    "admin": true, "member": true, "viewer": true,
}
if !allowedRoles[input.Role] {
    return fmt.Errorf("invalid role: %s", input.Role)
}

// BAD: Blacklist dangerous values (always incomplete)
if input.Role == "superadmin" {
    return fmt.Errorf("not allowed")
}
// What about "SuperAdmin", "SUPERADMIN", "super-admin"?
```

### Bounds Checking

```go
// Always bound numeric inputs
const (
    MaxPageSize    = 100
    MaxNameLength  = 255
    MaxBioLength   = 5000
    MaxUploadSize  = 10 * 1024 * 1024  // 10MB
    MaxBatchSize   = 100
)

func (f ListFilter) Validate() error {
    if f.Limit <= 0 || f.Limit > MaxPageSize {
        f.Limit = 50  // Default
    }
    if len(f.Query) > 200 {
        return errors.New("search query too long")
    }
    return nil
}
```

## SQL Injection Prevention

### Parameterized Queries ONLY

```go
// GOOD: Parameterized query
row := db.QueryRowContext(ctx,
    "SELECT * FROM users WHERE email = $1 AND tenant_id = $2",
    email, tenantID,
)

// GOOD: Query builder with parameterization
query := sq.Select("*").From("users").
    Where(sq.Eq{"email": email, "tenant_id": tenantID})

// BAD: String concatenation (SQL injection vulnerability)
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)

// BAD: Even with "sanitization" (never enough)
email = strings.ReplaceAll(email, "'", "''")
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)
```

### Dynamic Query Building

When building dynamic queries (filters, sorts), use safe patterns:

```go
// GOOD: Whitelist allowed columns for sorting
var allowedSortColumns = map[string]string{
    "name":       "name",
    "created_at": "created_at",
    "email":      "email",
}

func buildSort(input string) (string, error) {
    col, ok := allowedSortColumns[input]
    if !ok {
        return "", fmt.Errorf("invalid sort column: %s", input)
    }
    return col, nil
}

// BAD: User input directly in ORDER BY
query := fmt.Sprintf("SELECT * FROM users ORDER BY %s", input.Sort)
```

## XSS Prevention

### Output Encoding

```tsx
// React auto-escapes by default -- this is safe
<p>{user.bio}</p>

// DANGEROUS: Never use dangerouslySetInnerHTML without sanitization
<div dangerouslySetInnerHTML={{ __html: userContent }} />  // XSS risk!

// If you MUST render HTML, sanitize with DOMPurify
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

### Content Security Policy

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self';
  connect-src 'self' https://api.example.com;
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
```

Rules:
- No `'unsafe-eval'` in script-src
- Use nonces for inline scripts instead of `'unsafe-inline'`
- `frame-ancestors 'none'` prevents clickjacking (replaces X-Frame-Options)
- Report violations: `report-uri /api/v1/csp-violations`

## CSRF Prevention

### SameSite Cookies

```go
http.SetCookie(w, &http.Cookie{
    Name:     "session",
    Value:    sessionToken,
    HttpOnly: true,           // Not accessible via JavaScript
    Secure:   true,           // HTTPS only
    SameSite: http.SameSiteLaxMode,  // Prevents CSRF for most cases
    Path:     "/",
    MaxAge:   86400 * 7,      // 7 days
})
```

### CSRF Tokens (for state-changing non-API requests)

For traditional form submissions (not API calls with Bearer tokens):
1. Generate a random CSRF token per session
2. Include in forms as a hidden field
3. Validate on every state-changing request (POST, PUT, PATCH, DELETE)
4. Reject requests with missing or invalid tokens

## Secret Protection

### Never Log Secrets

```go
// Use struct tags to exclude secrets from logging
type Config struct {
    DatabaseURL  string `json:"-" log:"-"`           // Hidden from JSON and logs
    APIKey       string `json:"-" log:"-"`
    RedisURL     string `json:"-" log:"-"`
    Port         int    `json:"port" log:"port"`     // Safe to log
    Environment  string `json:"environment"`         // Safe to log
}

// Implement custom String/Format methods
func (c Config) String() string {
    return fmt.Sprintf("Config{Port: %d, Env: %s}", c.Port, c.Environment)
}

// Mask in error messages
func maskSecret(s string) string {
    if len(s) <= 8 {
        return "****"
    }
    return s[:4] + "****" + s[len(s)-4:]
}
```

### Never in Code

```go
// BAD: Hardcoded secrets
const apiKey = "sk_live_abc123def456"

// BAD: In environment file committed to git
// .env: DATABASE_URL=postgres://user:password@host/db

// GOOD: From environment variable
apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    log.Fatal("API_KEY environment variable is required")
}

// GOOD: From secret manager
secret, err := secretManager.GetSecret(ctx, "api-key")
```

## Dependency Security

### Automated Scanning

| Tool | Purpose | Frequency |
|------|---------|-----------|
| Dependabot / Renovate | Dependency updates | Daily PRs |
| Snyk / Trivy | Vulnerability scanning | Every CI run |
| `go mod verify` / `npm audit` | Integrity verification | Every CI run |
| Gitleaks / TruffleHog | Secret detection in code | Every commit (pre-commit hook) |

### Dependency Rules

| Rule | Description |
|------|------------|
| Pin versions | Use exact versions in go.mod/package-lock.json |
| Review updates | Don't auto-merge dependency updates without review |
| Minimize surface | Fewer dependencies = fewer vulnerabilities |
| Vendoring | Consider vendoring critical dependencies |
| License check | Verify license compatibility (no GPL in proprietary code) |

## Security Headers

Every HTTP response MUST include:

```go
func securityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("X-Frame-Options", "DENY")
        w.Header().Set("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none'")
        w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
        w.Header().Set("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
        w.Header().Set("X-XSS-Protection", "0")  // Disabled; rely on CSP
        next.ServeHTTP(w, r)
    })
}
```

## Rate Limiting

### Per-Tenant, Per-IP, Per-Endpoint

```go
// Layered rate limiting
type RateLimiter struct {
    tenantLimiter  *limiter  // Per tenant, all endpoints
    endpointLimiter *limiter // Per tenant per endpoint
    ipLimiter      *limiter  // Per IP (for unauthenticated endpoints)
    authLimiter    *limiter  // Per IP for auth endpoints (strictest)
}
```

### Auth Endpoint Protection

```go
// Exponential backoff for failed authentication
var authRateLimits = RateConfig{
    MaxAttempts:    5,          // 5 attempts
    Window:         15 * time.Minute,
    BackoffBase:    time.Second,
    BackoffMax:     15 * time.Minute,
    LockoutAfter:   10,         // Lock after 10 failed attempts
    LockoutDuration: time.Hour,
}
```

## Data Encryption

| Data State | Standard |
|-----------|----------|
| In transit | TLS 1.3 minimum. HSTS enabled. Certificate pinning for mobile. |
| At rest (database) | Transparent Data Encryption (TDE) or volume-level encryption |
| At rest (PII) | Application-level AES-256-GCM encryption for sensitive fields |
| At rest (sensitive tenant data) | Tenant-specific encryption keys (key per tenant in KMS) |
| Backups | Encrypted with separate key from production |
| Logs | Sensitive fields redacted before logging |

### Application-Level Encryption for PII

```go
// Encrypt PII fields before storing
type EncryptedField struct {
    Ciphertext string `db:"ciphertext"`
    KeyID      string `db:"key_id"`  // Track which key encrypted this
}

// Per-tenant encryption keys
func encryptForTenant(ctx context.Context, tenantID uuid.UUID, plaintext string) (*EncryptedField, error) {
    key, keyID, err := kms.GetTenantKey(ctx, tenantID)
    if err != nil {
        return nil, fmt.Errorf("getting tenant key: %w", err)
    }
    ciphertext, err := aesGCMEncrypt(key, []byte(plaintext))
    if err != nil {
        return nil, fmt.Errorf("encrypting: %w", err)
    }
    return &EncryptedField{
        Ciphertext: base64.StdEncoding.EncodeToString(ciphertext),
        KeyID:      keyID,
    }, nil
}
```

## Audit Logging

### Log All Security-Relevant Events

| Event | Log Level | Required Fields |
|-------|-----------|----------------|
| Login success | INFO | user_id, tenant_id, ip, user_agent |
| Login failure | WARN | attempted_email, ip, user_agent, failure_reason |
| Password change | INFO | user_id, tenant_id |
| Permission change | INFO | user_id, tenant_id, old_role, new_role, changed_by |
| Data export | INFO | user_id, tenant_id, data_type, record_count |
| Data deletion | INFO | user_id, tenant_id, data_type, record_count |
| API key creation | INFO | user_id, tenant_id, key_prefix, permissions |
| Admin impersonation | WARN | admin_id, target_user_id, target_tenant_id, reason |
| Rate limit hit | WARN | tenant_id, ip, endpoint, limit |
| Suspicious activity | ERROR | details, ip, user_agent, tenant_id |

### Audit Log Retention

- Minimum 1 year for compliance (SOC 2, GDPR)
- Archive to cold storage after 90 days
- Immutable: audit logs cannot be modified or deleted (append-only)

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| String concat for SQL queries | Parameterized queries |
| `dangerouslySetInnerHTML` without DOMPurify | Sanitize all user HTML |
| Secrets in source code | Environment variables or secret manager |
| `CORS: *` in production | Explicit allowed origins |
| No rate limiting on auth | Exponential backoff + lockout |
| Logging passwords/tokens | Exclude secrets via struct tags |
| `eval()` or `Function()` | Never use with user input |
| MD5/SHA1 for passwords | bcrypt/scrypt/argon2 |
| No CSRF protection | SameSite cookies + CSRF tokens |
| HTTP (no TLS) | TLS 1.3 minimum, HSTS enabled |
| Returning stack traces in API errors | Log internally, generic message to client |
| No dependency scanning | Automated scanning in CI |
