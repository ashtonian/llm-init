# Performance & Code Quality Guide

Mandatory standards for writing high-performance, production-grade code. This guide sets expectations for memory allocation strategies, computational efficiency, profiling discipline, and overall code quality. Every piece of code generated must meet these standards.

> **LLM Quick Reference**: Performance standards, memory allocation patterns, profiling discipline, and code quality expectations for all generated code.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Writing any performance-sensitive code (hot paths, data pipelines, request handlers)
- Designing data structures or algorithms
- Making memory allocation decisions
- Choosing between implementation approaches based on performance
- Optimizing existing code
- Writing benchmarks or profiling code
- Reviewing code for production readiness

### Key Sections

| Section | Purpose |
|---------|---------|
| **Performance Expectations** | Hard limits and targets all code must meet |
| **Memory Allocation Strategies** | When and how to allocate, pool, and reuse memory |
| **Computational Efficiency** | Algorithm selection, complexity requirements |
| **Go Performance Patterns** | Go-specific optimization patterns |
| **Frontend Performance** | Bundle, render, and interaction budgets |
| **Profiling Discipline** | When and how to measure performance |
| **Code Quality Standards** | Non-negotiable quality requirements |

### Quick Reference: Performance Budgets

| Metric | Budget | Enforcement |
|--------|--------|-------------|
| API response (p95) | <100ms | Load test |
| API response (p99) | <500ms | Load test |
| Database query | <50ms | Query plan review |
| Memory per request | <1MB allocated | Profiling |
| GC pause (Go) | <1ms p99 | Runtime metrics |
| Frontend FCP | <1.5s | Lighthouse CI |
| Frontend LCP | <2.5s | Lighthouse CI |
| Frontend TBT | <200ms | Lighthouse CI |

### Context Loading

1. For **performance patterns only**: This doc is sufficient
2. For **Go code patterns**: Also load `./go-generation-guide.md`
3. For **frontend performance**: Also load `./typescript-ui-guide.md`

---

## Performance Expectations

These are non-negotiable. Code that violates these standards must be fixed before merge.

### Latency targets

| Operation | p50 | p95 | p99 |
|-----------|-----|-----|-----|
| Simple CRUD read | <10ms | <50ms | <100ms |
| Simple CRUD write | <20ms | <100ms | <250ms |
| List/search query | <50ms | <200ms | <500ms |
| Complex aggregation | <200ms | <1s | <3s |
| Background job | N/A | N/A | <30s |

### Throughput targets

| Scenario | Minimum |
|----------|---------|
| API requests/sec (single instance) | >1000 |
| Database queries/sec | >5000 |
| Message bus events/sec | >10,000 |
| WebSocket connections/instance | >10,000 |

### Resource efficiency

| Resource | Expectation |
|----------|-------------|
| Memory growth | Stable under load (no leaks) |
| CPU utilization at idle | <5% |
| Goroutine count at idle (Go) | <100 |
| Connection pools | Bounded with health checks |
| File descriptors | Bounded, explicitly closed |

---

## Memory Allocation Strategies

### Core principle: allocate deliberately, never accidentally

Every allocation should be intentional. Understand where memory comes from, how long it lives, and when it's freed.

### Pre-allocation

Always pre-allocate slices and maps when the size is known or estimatable.

```go
// Good: pre-allocate with known size
users := make([]User, 0, len(ids))
for _, id := range ids {
    user, err := store.Get(ctx, id)
    if err != nil {
        return nil, err
    }
    users = append(users, user)
}

// Bad: grows dynamically, causes multiple allocations
var users []User
for _, id := range ids {
    user, err := store.Get(ctx, id)
    if err != nil {
        return nil, err
    }
    users = append(users, user)
}

// Good: pre-allocate map
index := make(map[string]*User, len(users))
for i := range users {
    index[users[i].ID] = &users[i]
}
```

### Object pooling

Use `sync.Pool` on hot paths where allocation pressure is high.

```go
var bufferPool = sync.Pool{
    New: func() any {
        return bytes.NewBuffer(make([]byte, 0, 4096))
    },
}

func processRequest(data []byte) ([]byte, error) {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()

    // Use buf for temporary work
    buf.Write(data)
    // ... process ...
    return buf.Bytes(), nil
}
```

### When to use pooling

| Scenario | Pool? | Rationale |
|----------|-------|-----------|
| Request/response buffers on hot path | Yes | High frequency, short-lived, uniform size |
| Database result scanners | Yes | Repeated allocation pattern |
| One-time startup initialization | No | Single allocation, not recurring |
| Small structs (<64 bytes) | No | Stack-allocated, GC handles efficiently |
| Variable-size allocations | Maybe | Only if sizes cluster around a few values |

### Stack vs heap awareness

```go
// Good: likely stack-allocated (returned value, not pointer)
func makeConfig() Config {
    return Config{
        Timeout: 30 * time.Second,
        Retries: 3,
    }
}

// Causes heap allocation (pointer escapes)
func makeConfig() *Config {
    return &Config{
        Timeout: 30 * time.Second,
        Retries: 3,
    }
}

// Check escape analysis:
// go build -gcflags="-m" ./...
```

### Avoiding hidden allocations

```go
// String concatenation in loops (BAD: O(n^2) allocations)
var result string
for _, s := range items {
    result += s.Name + ", "
}

// Use strings.Builder (GOOD: amortized O(n))
var b strings.Builder
b.Grow(len(items) * 20) // Estimate capacity
for i, s := range items {
    if i > 0 {
        b.WriteString(", ")
    }
    b.WriteString(s.Name)
}
result := b.String()

// Interface boxing (hidden allocation)
func process(v any) { ... }
process(42) // Allocates to box the int

// Avoid in hot paths. Use type-specific functions or generics.
func processInt(v int) { ... }
```

### Memory limits and back-pressure

```go
// Always bound memory usage for unbounded inputs
const maxBatchSize = 1000

func processBatch(ctx context.Context, items <-chan Item) error {
    batch := make([]Item, 0, maxBatchSize)
    for item := range items {
        batch = append(batch, item)
        if len(batch) >= maxBatchSize {
            if err := flush(ctx, batch); err != nil {
                return err
            }
            batch = batch[:0] // Reuse backing array
        }
    }
    if len(batch) > 0 {
        return flush(ctx, batch)
    }
    return nil
}

// Limit concurrent goroutines
sem := make(chan struct{}, maxConcurrency)
for _, item := range items {
    sem <- struct{}{} // Block if at capacity
    go func(item Item) {
        defer func() { <-sem }()
        process(item)
    }(item)
}
```

---

## Computational Efficiency

### Algorithm complexity requirements

| Data size | Maximum acceptable complexity |
|-----------|-------------------------------|
| <100 items | O(n^2) acceptable |
| 100-10,000 items | O(n log n) required |
| >10,000 items | O(n) or better required |
| Lookup operations | O(1) expected (use maps/indexes) |

### Database query efficiency

```sql
-- Always: use indexes for WHERE, JOIN, ORDER BY columns
-- Always: limit result sets
-- Always: use EXPLAIN ANALYZE for complex queries
-- Never: SELECT * in production code
-- Never: N+1 queries (use JOINs or batch loads)

-- Good: single query with JOIN
SELECT u.id, u.name, d.id as device_id, d.name as device_name
FROM users u
LEFT JOIN devices d ON d.user_id = u.id
WHERE u.tenant_id = $1
ORDER BY u.created_at DESC
LIMIT 50;

-- Bad: N+1 pattern
SELECT * FROM users WHERE tenant_id = $1;
-- Then for each user:
SELECT * FROM devices WHERE user_id = $1;
```

### Caching strategy

| Access pattern | Cache layer | TTL |
|---------------|-------------|-----|
| >100 reads/sec, rarely changes | L1 (in-process) | 1-5min |
| Shared across instances | L2 (Redis) | 5-30min |
| Expensive computation | L1 + L2 | Based on staleness tolerance |
| User session data | L2 (Redis) | Session lifetime |
| Static configuration | L1 (in-process) | Until restart or signal |

---

## Go-Specific Performance Patterns

### Reduce allocations in hot paths

```go
// Use value receivers for small types on hot paths
type Point struct{ X, Y float64 }
func (p Point) Distance(other Point) float64 {
    dx := p.X - other.X
    dy := p.Y - other.Y
    return math.Sqrt(dx*dx + dy*dy)
}

// Use byte slices instead of strings for manipulation
func processData(data []byte) []byte {
    // Avoids string allocation
    return bytes.ToUpper(data)
}

// Avoid defer in tight loops (small overhead per call)
for _, item := range largeSlice {
    mu.Lock()
    process(item)
    mu.Unlock() // Direct unlock, not defer
}
```

### Efficient JSON handling

```go
// Use json.Decoder for streams (avoids buffering entire body)
func decodeRequest(r *http.Request, v any) error {
    dec := json.NewDecoder(io.LimitReader(r.Body, maxBodySize))
    dec.DisallowUnknownFields()
    return dec.Decode(v)
}

// Use jsoniter or sonic for hot paths
// Standard encoding/json is fine for <1000 req/s

// Pre-compute JSON for static responses
var healthJSON = []byte(`{"status":"ok"}`)
func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Write(healthJSON)
}
```

### Connection pooling

```go
// Database connection pool
db, err := sql.Open("postgres", dsn)
db.SetMaxOpenConns(25)              // Match expected concurrency
db.SetMaxIdleConns(10)              // Keep warm connections
db.SetConnMaxLifetime(5 * time.Minute) // Rotate connections
db.SetConnMaxIdleTime(1 * time.Minute) // Close idle connections

// HTTP client reuse (NEVER create per-request)
var httpClient = &http.Client{
    Timeout: 10 * time.Second,
    Transport: &http.Transport{
        MaxIdleConns:        100,
        MaxIdleConnsPerHost: 10,
        IdleConnTimeout:     90 * time.Second,
    },
}
```

### Context and cancellation

```go
// Always propagate context for cancellation
func fetchAll(ctx context.Context, ids []string) ([]*Entity, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([]*Entity, len(ids))

    for i, id := range ids {
        g.Go(func() error {
            entity, err := fetch(ctx, id)
            if err != nil {
                return err
            }
            results[i] = entity
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}

// Set timeouts for external calls
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
result, err := externalService.Call(ctx, request)
```

---

## Profiling Discipline

### When to profile

| Trigger | Action |
|---------|--------|
| New hot path code | Benchmark before merging |
| p95 latency increase >20% | Profile immediately |
| Memory growth over time | Heap profile + goroutine count |
| CPU usage increase | CPU profile for 30s under load |
| Before major release | Full benchmark suite |

### Go profiling tools

```go
// Benchmarks (mandatory for hot paths)
func BenchmarkProcessEvent(b *testing.B) {
    event := createTestEvent()
    b.ResetTimer()
    b.ReportAllocs()
    for b.Loop() {
        processEvent(event)
    }
}

// Memory benchmarks
func BenchmarkAllocations(b *testing.B) {
    b.ReportAllocs()
    for b.Loop() {
        result := transform(input)
        _ = result
    }
}
// Target: 0 allocs/op for hot paths where possible
```

```bash
# CPU profile
go test -cpuprofile cpu.prof -bench BenchmarkProcessEvent ./...
go tool pprof cpu.prof

# Memory profile
go test -memprofile mem.prof -bench BenchmarkProcessEvent ./...
go tool pprof -alloc_space mem.prof

# Trace
go test -trace trace.out -bench BenchmarkProcessEvent ./...
go tool trace trace.out

# Live profiling endpoint (development only)
import _ "net/http/pprof"
go func() { http.ListenAndServe("localhost:6060", nil) }()
```

### Frontend profiling

```bash
# Lighthouse CI
npx lighthouse http://localhost:3000 --output=json --output-path=./report.json

# Bundle analysis
npx vite-bundle-visualizer
# or
npx webpack-bundle-analyzer stats.json

# React DevTools Profiler
# Record, identify wasted renders, fix with memo/useMemo/useCallback
```

---

## Code Quality Standards

### Non-negotiable requirements

| Requirement | Standard |
|-------------|----------|
| Test coverage (new code) | >80% line coverage |
| Test coverage (hot paths) | >95% including edge cases |
| Lint | Zero warnings (golangci-lint / eslint) |
| Type safety | No `any` (TS), no `interface{}` without justification (Go) |
| Error handling | Every error checked, classified, and handled |
| Documentation | Public APIs documented, complex logic commented |
| Security | No SQL injection, XSS, command injection, path traversal |
| Concurrency | No data races (go test -race passes) |

### Code review checklist

Before submitting code, verify:

- [ ] All tests pass, including race detector (`go test -race`)
- [ ] No new lint warnings
- [ ] Benchmarks run for performance-sensitive changes
- [ ] Error paths tested (not just happy path)
- [ ] Resource cleanup confirmed (connections, files, goroutines)
- [ ] No hardcoded secrets, credentials, or PII
- [ ] API changes are backward-compatible (or versioned)
- [ ] Memory allocation profile reviewed for hot paths
- [ ] No N+1 query patterns
- [ ] Timeout/context propagation on all external calls

### Naming quality

```go
// Good: intention-revealing names
func (s *UserService) DeactivateExpiredTrials(ctx context.Context) (int, error)

// Bad: vague names
func (s *UserService) Process(ctx context.Context) (int, error)

// Good: consistent terminology
// "Create" for new entities, "Update" for modifications, "Delete" for removal
// "Get" for single lookups, "List" for collections, "Search" for filtered queries

// Bad: inconsistent terminology
// "Add", "Insert", "Make", "New" used interchangeably for creation
```

---

## Anti-Patterns

| Anti-Pattern | Why | Instead |
|--------------|-----|---------|
| Premature optimization | Wastes time, adds complexity | Profile first, optimize measured bottlenecks |
| No pre-allocation | Repeated slice/map growth | `make([]T, 0, expectedSize)` |
| String concatenation in loops | O(n^2) allocations | `strings.Builder` |
| Creating HTTP clients per request | Connection overhead, fd leak | Shared client with pool |
| Unbounded goroutines | OOM, thundering herd | Semaphore or worker pool |
| Ignoring context cancellation | Wasted work, resource leak | Check `ctx.Err()`, propagate context |
| SELECT * in production | Over-fetching, index bypass | Select specific columns |
| N+1 queries | Linear DB round-trips | JOINs or batch loading |
| No timeouts on external calls | Thread/goroutine leak | `context.WithTimeout` |
| Logging in hot loops | I/O bottleneck | Sample or batch logs |
| Mutex in hot path without profiling | May not be the bottleneck | Profile first, consider lock-free |
| Caching without eviction | Memory leak | Bounded cache with TTL + LRU |

---

## Related Documentation

- [Go Generation Guide](./go-generation-guide.md) - Go code patterns and idioms
- [TypeScript UI Guide](./typescript-ui-guide.md) - Frontend performance standards

<!-- Add these cross-references as you create the specs:
- data-access.md - Database query optimization
- observability.md - Metrics and profiling integration
-->
