# Error Handling Patterns

Comprehensive error management standards for production systems. Every error must be classified, wrapped with context, and handled appropriately.

## Error Classification

Every error falls into one of three categories. Classification determines how the error is handled, logged, and communicated.

| Category | Description | Retry? | User-Facing? | Log Level |
|----------|-------------|--------|-------------|-----------|
| **Transient** | Temporary failure that may resolve on retry (network timeout, DB connection lost, rate limited) | Yes | Generic message ("Please try again") | WARN |
| **Permanent** | Will not resolve on retry (invalid input, not found, unauthorized, business rule violation) | No | Specific message explaining what's wrong | INFO/WARN |
| **System** | Infrastructure failure or bug (nil pointer, OOM, disk full, configuration error) | Maybe | Generic message ("Something went wrong") | ERROR |

## Error Wrapping with Context

Every error must be wrapped with context as it propagates up the call stack. The goal: reading the error message alone should tell you what happened and where.

### Go Patterns

```go
// GOOD: Wrap with context at every layer
func (s *UserService) CreateUser(ctx context.Context, input CreateUserInput) (*User, error) {
    user, err := s.repo.Create(ctx, &User{Name: input.Name, Email: input.Email})
    if err != nil {
        return nil, fmt.Errorf("creating user %q: %w", input.Email, err)
    }
    return user, nil
}

func (r *pgUserRepo) Create(ctx context.Context, user *User) (*User, error) {
    _, err := r.db.ExecContext(ctx, "INSERT INTO users ...", user.Name, user.Email)
    if err != nil {
        return nil, fmt.Errorf("inserting into users table: %w", err)
    }
    return user, nil
}

// Result: "creating user "alice@example.com": inserting into users table: duplicate key value"
// You know: what operation, what entity, what went wrong at the database level
```

```go
// BAD: No context
if err != nil {
    return nil, err  // What failed? Where? Unknown.
}

// BAD: Losing the original error
if err != nil {
    return nil, fmt.Errorf("something failed")  // Original error lost
}

// BAD: Over-wrapping (adds noise, not context)
if err != nil {
    return nil, fmt.Errorf("error: %w", err)  // "error" adds nothing
}
```

### TypeScript Patterns

```typescript
// GOOD: Custom error classes with context
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number,
    public readonly cause?: Error,
    public readonly isRetryable: boolean = false,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string, cause?: Error) {
    super(`${resource} with id ${id} not found`, 'NOT_FOUND', 404, cause);
  }
}

class ValidationError extends AppError {
  constructor(
    public readonly fields: Record<string, string>,
    cause?: Error,
  ) {
    super('Validation failed', 'VALIDATION_ERROR', 422, cause);
  }
}

// Usage
async function getUser(id: string): Promise<User> {
  const user = await userRepo.findById(id);
  if (!user) {
    throw new NotFoundError('User', id);
  }
  return user;
}
```

## Retry Strategies

### Exponential Backoff with Jitter

Only retry transient errors. Never retry permanent errors.

```go
// Go: Retry with exponential backoff and jitter
func RetryWithBackoff(ctx context.Context, maxAttempts int, fn func() error) error {
    var lastErr error
    for attempt := 0; attempt < maxAttempts; attempt++ {
        lastErr = fn()
        if lastErr == nil {
            return nil
        }
        if !IsTransient(lastErr) {
            return lastErr  // Don't retry permanent errors
        }
        if attempt < maxAttempts-1 {
            backoff := time.Duration(1<<uint(attempt)) * 100 * time.Millisecond  // 100ms, 200ms, 400ms, 800ms...
            jitter := time.Duration(rand.Int63n(int64(backoff / 2)))             // 0-50% jitter
            select {
            case <-time.After(backoff + jitter):
            case <-ctx.Done():
                return ctx.Err()
            }
        }
    }
    return fmt.Errorf("max retries (%d) exceeded: %w", maxAttempts, lastErr)
}
```

### Circuit Breaker

Prevent cascading failures when a downstream service is unhealthy.

```go
// States: Closed (normal) -> Open (failing) -> Half-Open (testing recovery)
type CircuitBreaker struct {
    maxFailures   int           // Failures before opening
    resetTimeout  time.Duration // How long to stay open before trying again
    failures      int
    state         State
    lastFailure   time.Time
}

// Usage: Wrap calls to external services
result, err := breaker.Execute(func() (interface{}, error) {
    return httpClient.Get(ctx, externalServiceURL)
})
```

| Parameter | Recommended Value | Notes |
|-----------|------------------|-------|
| Max failures before open | 5 | Adjust based on traffic volume |
| Reset timeout | 30 seconds | Time in Open state before trying Half-Open |
| Half-open max attempts | 1 | Number of test requests in Half-Open |
| Timeout per request | 5 seconds | Individual request timeout |

## Graceful Degradation

When a dependency fails, degrade gracefully rather than failing completely.

| Dependency | Degradation Strategy |
|-----------|---------------------|
| Cache (Redis) | Fall through to database (slower but functional) |
| Search service | Return recently cached results or empty results with a message |
| Email service | Queue for retry, don't block the user operation |
| Analytics | Drop analytics events, don't affect user-facing operations |
| External API | Return cached data with a staleness indicator |

```go
func (s *Service) GetUserProfile(ctx context.Context, id string) (*Profile, error) {
    // Try cache first
    profile, err := s.cache.Get(ctx, id)
    if err != nil {
        // Cache failure: log warning, continue to database
        slog.WarnContext(ctx, "cache read failed, falling back to database",
            "error", err, "user_id", id)
    }
    if profile != nil {
        return profile, nil
    }

    // Fall through to database
    profile, err = s.repo.GetProfile(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("getting user profile: %w", err)
    }

    // Best-effort cache write (don't fail if cache is down)
    if cacheErr := s.cache.Set(ctx, id, profile); cacheErr != nil {
        slog.WarnContext(ctx, "cache write failed", "error", cacheErr, "user_id", id)
    }

    return profile, nil
}
```

## Sentinel vs Typed Errors

### Go: Use Sentinel Errors for Well-Known Conditions

```go
// Define sentinel errors at the package level
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrConflict     = errors.New("conflict")
    ErrRateLimited  = errors.New("rate limited")
)

// Wrap sentinel errors with context
func (r *repo) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
    row := r.db.QueryRowContext(ctx, "SELECT ...", id)
    if err := row.Scan(&user); err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, fmt.Errorf("user %s: %w", id, ErrNotFound)
        }
        return nil, fmt.Errorf("querying user %s: %w", id, err)
    }
    return &user, nil
}

// Check with errors.Is (works through wrapping)
if errors.Is(err, ErrNotFound) {
    // Handle not found
}
```

### Go: Use Typed Errors for Structured Error Data

```go
// Typed error when you need to carry structured data
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s: %s", e.Field, e.Message)
}

// Check with errors.As
var validationErr *ValidationError
if errors.As(err, &validationErr) {
    // Access validationErr.Field, validationErr.Message
}
```

## Panic vs Error Return

| Use `panic` | Use `error` return |
|-------------|-------------------|
| Programmer error (bug) that should never happen in correct code | All recoverable situations |
| Violated invariant in a constructor (nil required dependency) | Network failures, timeouts |
| Index out of bounds in internal logic | Invalid user input |
| **Never** in library code for recoverable situations | File not found, permission denied |

```go
// Panic: programmer error (nil dependency = bug)
func NewService(repo Repository) *Service {
    if repo == nil {
        panic("NewService: repo must not be nil")
    }
    return &Service{repo: repo}
}

// Error return: everything else
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    if id == "" {
        return nil, fmt.Errorf("get user: %w", ErrInvalidInput)
    }
    // ...
}
```

## Logging Without Leaking Secrets

```go
// GOOD: Log the operation and error, not the sensitive data
slog.Error("authentication failed",
    "user_email", email,           // OK: email is not a secret
    "error", err,                  // OK: error message
    "ip", remoteAddr,              // OK: for security audit
)

// BAD: Logging secrets
slog.Error("authentication failed",
    "password", password,          // NEVER log passwords
    "token", authToken,            // NEVER log tokens
    "api_key", apiKey,             // NEVER log API keys
)

// GOOD: Mask sensitive values if you must reference them
slog.Info("API key rotated",
    "key_prefix", apiKey[:8]+"...",  // Only log a prefix
    "key_id", keyID,                 // Log the ID, not the value
)
```

## User-Facing Error Messages

| Internal Error | User-Facing Message |
|---------------|-------------------|
| `pq: duplicate key value violates unique constraint "users_email_key"` | "An account with this email already exists." |
| `context deadline exceeded` | "The request took too long. Please try again." |
| `connection refused` | "We're experiencing technical difficulties. Please try again in a few minutes." |
| `pq: value too long for type character varying(255)` | "The name must be 255 characters or fewer." |
| Nil pointer dereference | "Something went wrong. Our team has been notified." |

Rules:
- **Never expose internal error messages** to users (stack traces, SQL errors, file paths)
- **Be specific when the user can fix it** ("Email is required" not "Bad request")
- **Be vague when it's a system error** ("Something went wrong" not "Database connection pool exhausted")
- **Include action guidance** ("Please try again" or "Contact support if this persists")

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Correct Pattern |
|--------------|-------------|----------------|
| Swallowing errors (`_ = doSomething()`) | Silent failures lead to data corruption | Handle or propagate every error |
| Bare returns (`return err`) | No context for debugging | Wrap with `fmt.Errorf("doing X: %w", err)` |
| String matching on error messages | Fragile, breaks when messages change | Use `errors.Is()` / `errors.As()` |
| Logging and returning the same error | Error gets logged at every layer (noise) | Log once at the top, wrap at each layer |
| Generic catch-all (`catch (e) {}`) | Hides bugs, prevents recovery | Catch specific error types |
| Retrying permanent errors | Wastes resources, delays user feedback | Classify before retrying |
| Panicking for recoverable errors | Crashes the process | Return errors for recoverable situations |
| Exposing internal errors to users | Security risk, confusing UX | Map to user-friendly messages |
