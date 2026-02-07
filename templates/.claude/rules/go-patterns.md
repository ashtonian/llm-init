---
paths: ["**/*.go", "go.mod", "go.sum", "Makefile"]
---

# Go Code Generation Guide

Guidelines for LLMs generating Go code for this platform. This document defines the idioms, patterns, and conventions that all generated Go code must follow. It serves as the single source of truth for code style decisions and references cross-cutting concerns.

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
| **Errors are values** | Return errors, don't panic; classify as transient/permanent |
| **Context flows down** | First parameter is `context.Context` for any I/O or cancellable operation |
| **Zero-value useful** | Types should be usable without explicit initialization when possible |

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

All logging uses `slog`. Never use `fmt.Println`, `log.Printf`, or third-party loggers directly.

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

### Struct initialization

Always use named fields. Never rely on positional initialization.

## Functional Options Pattern

Use functional options when a constructor has more than 2 configurable parameters.

```go
type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func New(addr string, opts ...Option) *Server {
    s := &Server{addr: addr, port: 8080, logger: slog.Default(), timeout: 30 * time.Second}
    for _, opt := range opts { opt(s) }
    return s
}
```

### When to Use Options vs Config Struct

| Situation | Use |
|-----------|-----|
| 0-2 required params, 0+ optional | Functional options |
| All params required, no defaults | Positional arguments or a config struct |
| Configuration loaded from YAML/env | Config struct with `Validate() error` method |
| Public API / library boundary | Functional options (extensible without breaking) |

## Generics

Use generics when they **eliminate duplication without sacrificing readability**. Do not add type parameters speculatively.

### When to Use Generics

| Use Case | Example |
|----------|---------|
| Type-safe collections | `Set[T comparable]`, `SyncMap[K, V]` |
| Algorithm functions | `Map[T, U]`, `Filter[T]`, `Reduce[T, U]` |
| Typed wrappers | `TypedCache[T]`, `Result[T]`, `Ref[T]` |
| Registry factories | `Registry[T]` with typed `New` |

## Interface Design

### Keep interfaces small (1-3 methods)

```go
type Reader interface {
    Read(ctx context.Context, id string) (*Entity, error)
}
type Writer interface {
    Create(ctx context.Context, e *EntityCreate) (*Entity, error)
    Update(ctx context.Context, id string, patch *EntityPatch) (*Entity, error)
}
```

### Define interfaces at the consumer

Interfaces belong where they are used, not where they are implemented.

### Accept interfaces, return structs

```go
func NewService(store EntityStore, opts ...Option) *EntityService { ... }
```

## Registry Pattern

When a package supports multiple implementations, use the registry pattern with `init()` self-registration and a mandatory `memory` backend for testing.

## Concurrency Patterns

- Prefer channels for communication, mutexes for state
- Use `errgroup` for parallel work with error handling
- Use `sync.Pool` on hot paths

## Code Organization

| File | Contents |
|------|----------|
| `{entity}.go` | Type definitions, constructor, core methods |
| `{entity}_options.go` | Functional options |
| `{entity}_test.go` | Tests |
| `registry.go` | Registry and factory functions |

### Package naming
- Short, lowercase, single-word: `cache`, `notify`, `tenant`
- No stuttering: `cache.New()` not `cache.NewCache()`

### Import ordering: stdlib, third-party, internal

### Constructor conventions
| Pattern | When |
|---------|------|
| `New(opts ...Option) *T` | Standard, most types |
| `New(required, opts ...Option) (*T, error)` | When construction can fail |

## Anti-Patterns

| Anti-Pattern | Instead |
|--------------|---------|
| God struct with all fields | Intent-specific types (Create/Patch/Response/Row) |
| `panic` in library code | Return `error` |
| Global mutable state | Dependency injection |
| `init()` for business logic | Explicit initialization in `main` |
| Interface pollution | Define at consumer, keep to 1-3 methods |
| Returning `interface` from constructor | Return `*ConcreteType` |
| Deep struct embedding | Explicit composition |
| `context.Value` for required data | Function parameters |
| Premature abstraction | Wait until duplication is real |

## Quick Decision Tree

```
Does the type have multiple backend implementations?
-> Yes -> Registry pattern
-> No
    Does the constructor have >2 optional parameters?
    -> Yes -> Functional options
    -> No
        Is the logic a transformation/pipeline?
        -> Yes -> Function types + Pipeline pattern
        -> No -> Simple struct with New() constructor
```
