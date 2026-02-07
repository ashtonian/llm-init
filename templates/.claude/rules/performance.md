# Performance & Code Quality Guide

Mandatory standards for writing high-performance, production-grade code.

## Performance Budgets

| Metric | Budget |
|--------|--------|
| API response (p95) | <100ms |
| API response (p99) | <500ms |
| Database query | <50ms |
| Memory per request | <1MB allocated |
| GC pause (Go) | <1ms p99 |
| Frontend FCP | <1.5s |
| Frontend LCP | <2.5s |
| Frontend TBT | <200ms |

## Latency Targets

| Operation | p50 | p95 | p99 |
|-----------|-----|-----|-----|
| Simple CRUD read | <10ms | <50ms | <100ms |
| Simple CRUD write | <20ms | <100ms | <250ms |
| List/search query | <50ms | <200ms | <500ms |
| Complex aggregation | <200ms | <1s | <3s |

## Memory Allocation Strategies

- **Pre-allocate** slices and maps when size is known: `make([]T, 0, len(ids))`
- **Object pooling** (`sync.Pool`) on hot paths with high allocation pressure
- **Stack vs heap**: Return values not pointers when possible
- **Avoid hidden allocations**: Use `strings.Builder` not concatenation, avoid interface boxing on hot paths
- **Bound memory**: Always limit unbounded inputs (`maxBatchSize`, semaphores for goroutines)

## Computational Efficiency

| Data size | Maximum complexity |
|-----------|-------------------|
| <100 items | O(n^2) acceptable |
| 100-10,000 | O(n log n) required |
| >10,000 | O(n) or better |
| Lookups | O(1) expected (maps/indexes) |

## Database Efficiency

- Always use indexes for WHERE, JOIN, ORDER BY
- Always limit result sets
- Use EXPLAIN ANALYZE for complex queries
- Never SELECT * in production
- Never N+1 queries (use JOINs or batch loads)

## Caching Strategy

| Access pattern | Cache layer | TTL |
|---------------|-------------|-----|
| >100 reads/sec, rarely changes | L1 (in-process) | 1-5min |
| Shared across instances | L2 (Redis) | 5-30min |
| Expensive computation | L1 + L2 | Based on staleness |
| Static configuration | L1 (in-process) | Until restart |

## Profiling Discipline

| Trigger | Action |
|---------|--------|
| New hot path code | Benchmark before merging |
| p95 latency increase >20% | Profile immediately |
| Memory growth over time | Heap profile + goroutine count |
| Before major release | Full benchmark suite |

## Code Quality Standards

| Requirement | Standard |
|-------------|----------|
| Test coverage (new code) | >80% line coverage |
| Test coverage (hot paths) | >95% including edge cases |
| Lint | Zero warnings |
| Error handling | Every error checked, classified, handled |
| Concurrency | No data races (go test -race passes) |

## Anti-Patterns

| Anti-Pattern | Instead |
|--------------|---------|
| Premature optimization | Profile first, optimize measured bottlenecks |
| No pre-allocation | `make([]T, 0, expectedSize)` |
| String concatenation in loops | `strings.Builder` |
| HTTP clients per request | Shared client with pool |
| Unbounded goroutines | Semaphore or worker pool |
| Ignoring context cancellation | Check `ctx.Err()`, propagate context |
| N+1 queries | JOINs or batch loading |
| No timeouts on external calls | `context.WithTimeout` |
