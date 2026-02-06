# Go Code Generation Guide

Guidelines for LLMs generating Go code for this platform. This document defines the idioms, patterns, and conventions that all generated Go code must follow. It serves as the single source of truth for code style decisions and references cross-cutting concerns defined throughout the `framework/` specifications.

> **LLM Quick Reference**: Go code generation patterns, idioms, and mandatory conventions.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Writing any new Go code (packages, services, handlers, tests)
- Reviewing generated Go code for compliance
- Deciding between implementation approaches
- Understanding which patterns to apply for a given problem

### Key Sections

| Section | Purpose |
|---------|---------|
| **Core Principles** | Mandatory rules for all generated Go code |
| **Functional Options Pattern** | How to configure types and services |
| **Generics** | When and how to use type parameters |
| **Functional Patterns** | Prefer functions over method-heavy types |
| **Registry Pattern** | Plugin architecture for multiple implementations |
| **Interface Design** | Small, composable, consumer-defined interfaces |
| **Cross-Cutting Concerns** | References to framework/ specs for errors, observability, etc. |
| **Code Organization** | File structure, naming, package layout |
| **Testing** | Test patterns aligned with the testing guide |

### Context Loading

1. For **Go generation rules**: This doc is sufficient
2. For **API handler code**: Also load `./api-design.md`
3. For **database code**: Also load `./data-access.md`
4. For **error handling code**: Also load `./error-handling.md`
5. For **test code**: Also load `./testing-guide.md`
6. For **package code**: Also load `../pkg-specs/README.md`

---

## Core Principles

These rules are mandatory. Every piece of generated Go code must comply.

| Principle | Rule |
|-----------|------|
| **Simplicity** | Write the least code that solves the problem correctly |
| **Explicit over implicit** | No magic; a reader should understand behavior from the call site |
| **Composition over inheritance** | Compose via interfaces and functions, not struct embedding hierarchies |
| **Functional over OOP** | Prefer pure functions, closures, and higher-order functions over stateful method receivers |
| **Options over config structs** | Use functional options for anything with more than 2 configuration parameters |
| **Small interfaces** | 1-3 methods; let consumers define the interface they need |
| **Errors are values** | Return errors, don't panic; classify as transient/permanent per `error-handling.md` |
| **Context flows down** | First parameter is `context.Context` for any I/O or cancellable operation |
| **Zero-value useful** | Types should be usable without explicit initialization when possible |

---

## Modern Go Idioms

### Use `any` not `interface{}`

```go
// Good
func Process(data any) error { ... }
type Metadata map[string]any

// Bad
func Process(data interface{}) error { ... }
```

### Structured logging with `log/slog`

All logging uses `slog`. Never use `fmt.Println`, `log.Printf`, or third-party loggers directly. See [observability.md](./observability.md) for full conventions.

```go
slog.InfoContext(ctx, "entity registered",
    "entity_id", entityID,
    "tenant_id", tenantID,
)
```

### Error wrapping with `%w`

```go
if err != nil {
    return fmt.Errorf("loading entity %s: %w", id, err)
}
```

For API boundaries, use structured error types. See [error-handling.md](./error-handling.md).

### Multi-error handling

Use `errors.Join` for collecting independent errors:

```go
var errs []error
for _, item := range items {
    if err := validate(item); err != nil {
        errs = append(errs, err)
    }
}
return errors.Join(errs...)
```

### Range over integers (Go 1.22+)

```go
for i := range 10 {
    process(i)
}
```

### Loop variable capture (Go 1.22+)

Go 1.22+ fixes loop variable semantics. Do **not** add `tt := tt` in new code when the minimum Go version is 1.22+.

```go
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()
        // tt is correctly captured in Go 1.22+
    })
}
```

### Struct initialization

Always use named fields. Never rely on positional initialization.

```go
// Good
cfg := Config{
    Host:    "localhost",
    Port:    8080,
    Timeout: 30 * time.Second,
}

// Bad
cfg := Config{"localhost", 8080, 30 * time.Second}
```

---

## Functional Options Pattern

Use functional options when a constructor has more than 2 configurable parameters. This is the **standard configuration pattern** for this codebase.

### Basic Pattern

```go
// Option configures a Server.
type Option func(*Server)

// WithPort sets the listening port.
func WithPort(port int) Option {
    return func(s *Server) {
        s.port = port
    }
}

// WithLogger sets the logger.
func WithLogger(logger *slog.Logger) Option {
    return func(s *Server) {
        s.logger = logger
    }
}

// WithTimeout sets the request timeout.
func WithTimeout(d time.Duration) Option {
    return func(s *Server) {
        s.timeout = d
    }
}

// New creates a Server with sensible defaults, then applies options.
func New(addr string, opts ...Option) *Server {
    s := &Server{
        addr:    addr,
        port:    8080,
        logger:  slog.Default(),
        timeout: 30 * time.Second,
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

### Options with Validation

When options can fail, return an error:

```go
type Option func(*Client) error

func WithTLS(certFile, keyFile string) Option {
    return func(c *Client) error {
        cert, err := tls.LoadX509KeyPair(certFile, keyFile)
        if err != nil {
            return fmt.Errorf("loading TLS cert: %w", err)
        }
        c.tlsCert = &cert
        return nil
    }
}

func New(opts ...Option) (*Client, error) {
    c := &Client{/* defaults */}
    for _, opt := range opts {
        if err := opt(c); err != nil {
            return nil, err
        }
    }
    return c, nil
}
```

### Generic Options

When multiple types share similar configuration, use a generic option:

```go
// Configurable is satisfied by types that expose an apply method.
type Option[T any] func(*T)

func WithName[T any](name string, set func(*T, string)) Option[T] {
    return func(t *T) {
        set(t, name)
    }
}
```

### When to Use Options vs Config Struct

| Situation | Use |
|-----------|-----|
| 0-2 required params, 0+ optional | Functional options |
| All params required, no defaults | Positional arguments or a config struct |
| Configuration loaded from YAML/env | Config struct with `Validate() error` method |
| Public API / library boundary | Functional options (extensible without breaking) |

---

## Generics

Use generics when they **eliminate duplication without sacrificing readability**. Do not add type parameters speculatively.

### When to Use Generics

| Use Case | Example |
|----------|---------|
| Type-safe collections | `Set[T comparable]`, `SyncMap[K, V]` |
| Algorithm functions | `Map[T, U]`, `Filter[T]`, `Reduce[T, U]` |
| Typed wrappers | `TypedCache[T]`, `Result[T]`, `Ref[T]` |
| Registry factories | `Registry[T]` with typed `New` |
| Functional combinators | `Pipe[T]`, `Compose[A, B, C]` |

### When NOT to Use Generics

| Situation | Why |
|-----------|-----|
| Only one concrete type exists | Premature abstraction |
| The generic version is harder to read | Readability wins |
| `any` constraint everywhere | You're just hiding `interface{}` |
| Method sets differ per type | Use interfaces instead |

### Patterns

#### Type-safe result wrapper

```go
// Result wraps a value or error, useful for channel returns and batch operations.
type Result[T any] struct {
    Value T
    Err   error
}

func OK[T any](v T) Result[T]    { return Result[T]{Value: v} }
func Fail[T any](err error) Result[T] { return Result[T]{Err: err} }
```

#### Typed cache

```go
type TypedCache[T any] struct {
    cache  Cache
    prefix string
    codec  Codec[T]
}

func NewTypedCache[T any](cache Cache, prefix string) *TypedCache[T] {
    return &TypedCache[T]{
        cache:  cache,
        prefix: prefix,
        codec:  JSONCodec[T]{},
    }
}

func (tc *TypedCache[T]) Get(ctx context.Context, key string) (T, error) {
    data, err := tc.cache.Get(ctx, tc.prefix+key)
    if err != nil {
        var zero T
        return zero, err
    }
    return tc.codec.Decode(data)
}
```

#### Generic Map/Filter/Reduce

```go
func Map[T, U any](items []T, fn func(T) U) []U {
    result := make([]U, len(items))
    for i, v := range items {
        result[i] = fn(v)
    }
    return result
}

func Filter[T any](items []T, fn func(T) bool) []T {
    result := make([]T, 0, len(items))
    for _, v := range items {
        if fn(v) {
            result = append(result, v)
        }
    }
    return result
}

func Reduce[T, U any](items []T, initial U, fn func(U, T) U) U {
    acc := initial
    for _, v := range items {
        acc = fn(acc, v)
    }
    return acc
}
```

#### Generic registry

```go
type Factory[T any] func(cfg map[string]any) (T, error)

type Registry[T any] struct {
    mu        sync.RWMutex
    factories map[string]Factory[T]
}

func NewRegistry[T any]() *Registry[T] {
    return &Registry[T]{factories: make(map[string]Factory[T])}
}

func (r *Registry[T]) Register(name string, f Factory[T]) {
    r.mu.Lock()
    defer r.mu.Unlock()
    r.factories[name] = f
}

func (r *Registry[T]) New(name string, cfg map[string]any) (T, error) {
    r.mu.RLock()
    f, ok := r.factories[name]
    r.mu.RUnlock()
    if !ok {
        var zero T
        return zero, fmt.Errorf("unknown backend: %s", name)
    }
    return f(cfg)
}
```

---

## Functional Patterns

Prefer functional patterns over OOP-style class hierarchies. Go is not Java.

### First-class functions and closures

Use functions as values for pluggable behavior instead of method dispatch on interface hierarchies.

```go
// Good: function types for pluggable behavior
type Middleware func(http.Handler) http.Handler
type KeyFunc func(r *http.Request) string
type TransformFunc func(ctx context.Context, msg *Message) (*Message, error)

// Compose middleware via function composition
func Chain(middlewares ...Middleware) Middleware {
    return func(next http.Handler) http.Handler {
        for i := len(middlewares) - 1; i >= 0; i-- {
            next = middlewares[i](next)
        }
        return next
    }
}
```

### Higher-order functions

Return functions from functions to capture configuration:

```go
// NewRateLimiter returns a middleware configured with the given limits.
func NewRateLimiter(rps float64, burst int) Middleware {
    limiter := rate.NewLimiter(rate.Limit(rps), burst)
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow() {
                http.Error(w, "rate limited", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

### Pipeline pattern

Chain transformations as a pipeline of functions:

```go
type Stage[T any] func(context.Context, T) (T, error)

func Pipeline[T any](stages ...Stage[T]) Stage[T] {
    return func(ctx context.Context, input T) (T, error) {
        var err error
        current := input
        for _, stage := range stages {
            current, err = stage(ctx, current)
            if err != nil {
                return current, err
            }
        }
        return current, nil
    }
}

// Usage
process := Pipeline(
    validate,
    enrich,
    transform,
    store,
)
result, err := process(ctx, input)
```

### Prefer closures over single-method interfaces

When an interface would have exactly one method, consider using a function type instead:

```go
// Prefer this
type Validator func(ctx context.Context, value any) error

// Over this (when only one method)
type Validator interface {
    Validate(ctx context.Context, value any) error
}
```

Exception: when the implementation needs state cleanup (e.g., `Close()`), an interface with multiple methods is appropriate.

### Avoid unnecessary receivers

If a function doesn't read or modify struct state, make it a standalone function:

```go
// Good: standalone function, easier to test and compose
func FormatEntityKey(tenantID, entityID string) string {
    return tenantID + ":" + entityID
}

// Bad: receiver adds nothing
func (s *EntityService) FormatEntityKey(tenantID, entityID string) string {
    return tenantID + ":" + entityID
}
```

---

## Registry Pattern

When a package supports multiple implementations of an interface (e.g., different storage backends), use the registry pattern. This keeps binaries lean by only linking imported backends.

### Directory Layout

```
pkg/{package}/
├── {package}.go       # Core interface and public types
├── registry.go        # Register() and New() functions
├── options.go         # Functional options
├── backend/
│   ├── memory/
│   │   ├── memory.go  # In-memory implementation (always available for tests)
│   │   └── init.go    # Calls Register() in init()
│   ├── postgres/
│   │   ├── postgres.go
│   │   └── init.go
│   └── redis/
│       ├── redis.go
│       └── init.go
```

### Registration via `init()`

Each backend self-registers in its `init()` function:

```go
// pkg/cache/backend/redis/init.go
package redis

import "{{PROJECT_MODULE}}/pkg/cache"

func init() {
    cache.Register("redis", func(cfg map[string]any) (cache.Cache, error) {
        return New(cfg)
    })
}
```

### Consumer imports only what it needs

```go
import (
    "{{PROJECT_MODULE}}/pkg/cache"
    _ "{{PROJECT_MODULE}}/pkg/cache/backend/redis" // register redis backend
)

func main() {
    c, err := cache.New("redis", cfg)
}
```

### Memory backend for testing

Every registry-based package must include a `memory` backend that requires no external dependencies. Tests import only the memory backend.

```go
import (
    "{{PROJECT_MODULE}}/pkg/cache"
    _ "{{PROJECT_MODULE}}/pkg/cache/backend/memory"
)

func TestCacheBehavior(t *testing.T) {
    c, err := cache.New("memory", nil)
    require.NoError(t, err)
    // ... test cache behavior
}
```

---

## Interface Design

### Keep interfaces small

Interfaces with 1-3 methods are vastly preferred. If an interface grows beyond 3 methods, consider splitting it.

```go
// Good: focused interfaces
type Reader interface {
    Read(ctx context.Context, id string) (*Entity, error)
}

type Writer interface {
    Create(ctx context.Context, e *EntityCreate) (*Entity, error)
    Update(ctx context.Context, id string, patch *EntityPatch) (*Entity, error)
}

type Deleter interface {
    Delete(ctx context.Context, id string) error
}

// Compose when needed
type Repository interface {
    Reader
    Writer
    Deleter
}
```

### Define interfaces at the consumer

Interfaces belong where they are used, not where they are implemented:

```go
// In the service package that needs storage
package service

type EntityStore interface {
    Get(ctx context.Context, id string) (*Entity, error)
    Save(ctx context.Context, e *Entity) error
}

type EntityService struct {
    store EntityStore // depends on abstraction
}
```

### Accept interfaces, return structs

```go
// Good: accept interface, return concrete
func NewService(store EntityStore, opts ...Option) *EntityService { ... }

// Bad: return interface (hides concrete type, makes debugging harder)
func NewService(store EntityStore) EntityStore { ... }
```

---

## Flexibility Guidelines

Write code that adapts without modification.

### Use dependency injection

All external dependencies are injected, never constructed internally:

```go
type Service struct {
    store  Store
    cache  Cache
    bus    MessageBus
    logger *slog.Logger
}

func NewService(store Store, opts ...Option) *Service {
    s := &Service{
        store:  store,
        logger: slog.Default(),
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

### Use function parameters for strategy

When behavior needs to vary, accept a function:

```go
func Retry(ctx context.Context, fn func() error, opts ...RetryOption) error {
    cfg := defaultRetryConfig()
    for _, opt := range opts {
        opt(&cfg)
    }
    // ... retry loop using cfg
}
```

### Prefer `io.Reader`/`io.Writer` over concrete types

```go
// Good: works with files, buffers, HTTP bodies, gzip streams
func ProcessData(r io.Reader) error { ... }

// Bad: tied to specific type
func ProcessData(data []byte) error { ... }
```

### Design for extension

Use the decorator/wrapper pattern to add behavior:

```go
// Wrap a Store to add caching without modifying the original
type CachedStore struct {
    inner Store
    cache Cache
}

func (s *CachedStore) Get(ctx context.Context, id string) (*Entity, error) {
    if v, err := s.cache.Get(ctx, id); err == nil {
        return v, nil
    }
    v, err := s.inner.Get(ctx, id)
    if err != nil {
        return nil, err
    }
    _ = s.cache.Set(ctx, id, v)
    return v, nil
}
```

---

## Cross-Cutting Concern References

These framework specifications define mandatory patterns. All generated Go code must comply with them. Create these specs as you build out your project.

| Concern | Spec | Key Rules |
|---------|------|-----------|
| **Error handling** | [error-handling.md](./error-handling.md) | Structured errors with codes; classify transient vs permanent; never panic in library code |
| **Observability** | [observability.md](./observability.md) | `slog` for logging; OpenTelemetry for traces; Prometheus for metrics; correlate via `trace_id` |
| **API design** | [api-design.md](./api-design.md) | Intent-specific types (Create/Patch/Response/Row); JSON Patch for updates; cursor pagination |
| **Models** | [models.md](./models.md) | UUIDv7 IDs; RFC 3339 timestamps; soft delete; tenant isolation on all entities |
| **Data access** | [data-access.md](./data-access.md) | Repository pattern; context-based tenant filtering |
| **Validation** | [validation.md](./validation.md) | Struct tags for validation; layer-appropriate validation |
| **Testing** | [testing-guide.md](./testing-guide.md) | Table-driven tests; `require`/`assert`; integration-first; parallel by default |
| **Auth** | [authentication.md](./authentication.md) | Bearer tokens; API keys; session management |
| **Permissions** | [permission-policy-system.md](./permission-policy-system.md) | Three-layer authorization (route, service, repository) |
| **Tenancy** | [tenant-model.md](./tenant-model.md) | All data is tenant-scoped; extract tenant from context |

### Applying Cross-Cutting Concerns

When generating code for a new service or package, apply these in order:

1. **Define interfaces** (small, consumer-side)
2. **Implement with functional options** for configuration
3. **Add error handling** with appropriate error codes
4. **Add observability** (structured logging, trace spans, metrics)
5. **Add validation** using struct tags and the validation layer rules
6. **Add tenant isolation** (context-based tenant ID on all queries)
7. **Write tests** following the testing guide

---

## Code Organization

### File naming

| File | Contents |
|------|----------|
| `{entity}.go` | Type definitions, constructor, core methods |
| `{entity}_options.go` | Functional options for the entity's constructor |
| `{entity}_test.go` | Tests for the entity |
| `registry.go` | Registry and factory functions (if applicable) |
| `middleware.go` | HTTP or gRPC middleware |
| `helpers.go` | Internal unexported helper functions |

### Package naming

- Short, lowercase, single-word names: `cache`, `notify`, `tenant`
- No stuttering: `cache.New()` not `cache.NewCache()`
- No utility grab-bags: split `utils` into focused packages

### Import ordering

```go
import (
    // 1. Standard library
    "context"
    "fmt"
    "time"

    // 2. Third-party
    "github.com/google/uuid"
    "go.opentelemetry.io/otel"

    // 3. Internal packages
    "{{PROJECT_MODULE}}/pkg/errutil"
    "{{PROJECT_MODULE}}/pkg/tenant"
)
```

### Constructor conventions

| Pattern | When |
|---------|------|
| `New(opts ...Option) *T` | Standard, most types |
| `New(required, opts ...Option) (*T, error)` | When construction can fail |
| `Must(opts ...Option) *T` | Convenience for tests/init; panics on error |

---

## Concurrency Patterns

### Prefer channels for communication, mutexes for state

```go
// Channel: coordinating goroutines
results := make(chan Result[*Entity], len(ids))
for _, id := range ids {
    go func(id string) {
        entity, err := store.Get(ctx, id)
        results <- Result[*Entity]{Value: entity, Err: err}
    }(id)
}

// Mutex: protecting shared state
type SafeCounter struct {
    mu    sync.RWMutex
    count map[string]int
}
```

### Use `errgroup` for parallel work with error handling

```go
g, ctx := errgroup.WithContext(ctx)
for _, id := range ids {
    g.Go(func() error {
        return process(ctx, id)
    })
}
if err := g.Wait(); err != nil {
    return err
}
```

### Use `sync.Pool` on hot paths

```go
var responsePool = sync.Pool{
    New: func() any { return &EntityResponse{} },
}

func acquireResponse() *EntityResponse {
    return responsePool.Get().(*EntityResponse)
}

func releaseResponse(r *EntityResponse) {
    *r = EntityResponse{} // zero out before returning
    responsePool.Put(r)
}
```

---

## Anti-Patterns

Do **not** generate code with these patterns:

| Anti-Pattern | Why | Instead |
|--------------|-----|---------|
| God struct with all fields | Impossible to validate per-intent | Intent-specific types (Create/Patch/Response/Row) |
| `panic` in library code | Crashes callers | Return `error` |
| Global mutable state | Racy, untestable | Dependency injection |
| `init()` for business logic | Hidden execution order | Explicit initialization in `main` or bootstrap |
| `init()` for anything except registry registration | Side effects at import time | Only use `init()` for backend `Register()` calls |
| Interface pollution | Too many interfaces nobody implements | Define at consumer, keep to 1-3 methods |
| Returning `interface` from constructor | Hides concrete type, breaks debugging | Return `*ConcreteType` |
| Deep struct embedding | Fragile, confusing method promotion | Explicit composition |
| `context.Value` for passing required data | Invisible dependencies | Function parameters |
| `context.Value` for tenant ID | Exception to above: tenant ID is a cross-cutting concern | Use `tenant.FromContext(ctx)` pattern |
| Premature abstraction | Three similar lines > one unnecessary helper | Wait until duplication is real |
| Feature flags for unreleased code | Complexity tax | Feature branches |

---

## Quick Decision Tree

Use this when unsure which pattern to apply:

```
Does the type have multiple backend implementations?
├── Yes -> Registry pattern
└── No
    Does the constructor have >2 optional parameters?
    ├── Yes -> Functional options
    └── No
        Is the logic a transformation/pipeline?
        ├── Yes -> Function types + Pipeline pattern
        └── No
            Is the behavior pluggable/swappable?
            ├── Yes -> Accept a function parameter or small interface
            └── No -> Simple struct with New() constructor
```

---

## Related Documentation

- [API Design](./api-design.md) - REST conventions, model patterns, pagination
- [Error Handling](./error-handling.md) - Error codes, classification, retry behavior
- [Models](./models.md) - Entity patterns, soft delete, versioning
- [Data Access](./data-access.md) - Repository patterns, database integration
- [Observability](./observability.md) - Logging, tracing, metrics
- [Validation](./validation.md) - Input validation, custom validators
- [Testing Guide](./testing-guide.md) - Test organization, patterns, coverage
- [Package Design](../pkg-specs/README.md) - Registry pattern, package principles
