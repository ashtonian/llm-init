---
name: performance-audit
description: Systematic performance audit with profiling and benchmarks
allowed-tools: Read, Write, Bash, Glob, Grep
---

# Performance Audit Skill

Structured workflow for conducting a systematic performance audit of the application. Identifies bottlenecks, measures baselines, and produces actionable recommendations.

## Workflow

### Step 1: Profile CPU and Memory

Run profiling tools to identify hot paths and allocation sites.

**Go:**
```bash
# CPU profile
go test -bench=. -cpuprofile=cpu.prof -benchtime=30s ./...
go tool pprof -http=:8080 cpu.prof

# Memory profile
go test -bench=. -memprofile=mem.prof -benchmem ./...
go tool pprof -http=:8080 mem.prof

# Goroutine profile (for concurrency issues)
curl http://localhost:8080/debug/pprof/goroutine?debug=2
```

**Node.js:**
```bash
# CPU profile
node --cpu-prof --cpu-prof-dir=./profiles app.js
# Then: chrome://inspect -> Open dedicated DevTools for Node

# Memory
node --heap-prof --heap-prof-dir=./profiles app.js
```

**Frontend (Chrome DevTools):**
- Performance tab: Record user interaction flow
- Memory tab: Heap snapshots before/after interaction
- Lighthouse: Overall performance score

Capture:
- Top 10 CPU-consuming functions
- Top 10 memory-allocating functions
- Goroutine/thread count under load
- GC pause times and frequency

### Step 2: Identify Hot Paths and Allocation Sites

From profiling data, identify:

| Category | What to Find |
|----------|-------------|
| CPU hot paths | Functions consuming >5% of total CPU |
| Memory allocations | Functions with >1000 allocs/op or >1MB/op |
| GC pressure | Allocation rate causing frequent GC pauses |
| Contention | Lock contention in concurrent code |
| I/O bottlenecks | Functions blocked on network/disk I/O |

For each finding, document:
- Function name and call chain
- Current metric (CPU%, allocs/op, bytes/op)
- Potential optimization approach
- Estimated improvement

### Step 3: Benchmark Critical Endpoints

Use HTTP load testing tools to measure endpoint performance:

```bash
# Quick benchmark with hey
hey -n 10000 -c 50 -H "Authorization: Bearer $TOKEN" \
    http://localhost:8080/api/v1/users

# Detailed benchmark with wrk
wrk -t4 -c100 -d30s -s scripts/post-user.lua \
    http://localhost:8080/api/v1/users

# Multi-tenant load simulation with k6
k6 run --vus 100 --duration 60s scripts/multi-tenant-load.js
```

Record for each endpoint:
- Throughput (requests/second)
- Latency: p50, p95, p99
- Error rate
- Resource usage during load (CPU, memory, connections)

Compare against performance budgets from `.claude/rules/performance.md`:
| Endpoint Type | p50 Target | p99 Target |
|---------------|-----------|-----------|
| Simple CRUD read | <10ms | <100ms |
| Simple CRUD write | <20ms | <250ms |
| List with pagination | <50ms | <500ms |

### Step 4: Analyze Database Queries

Identify slow queries and missing indexes:

```sql
-- Find slow queries (if pg_stat_statements enabled)
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Analyze specific queries
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT ...;
```

Check for:
- [ ] Sequential scans on large tables (>10K rows) -- needs an index
- [ ] High buffer reads vs hits -- cold cache or bad index
- [ ] Nested loop joins on large tables -- should be hash join
- [ ] Sort with disk spill -- needs more work_mem or index
- [ ] N+1 query patterns -- search code for queries in loops

For each slow query:
- Current execution time (mean, p99)
- Query plan analysis
- Recommended fix (add index, rewrite query, add caching)
- Estimated improvement

### Step 5: Check for N+1 Queries and Missing Indexes

Search the codebase for N+1 patterns:

```
# Look for database queries inside loops
# Go: QueryRow/Query inside for/range loops
# TypeScript: await inside for/map loops
```

Search for tables missing foreign key indexes:

```sql
-- Find foreign keys without indexes
SELECT
    tc.table_name, kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = tc.table_name
    AND indexdef LIKE '%' || kcu.column_name || '%'
);
```

### Step 6: Assess Tenant Isolation Performance

Test for noisy neighbor effects:

1. **Baseline**: Measure performance for Tenant A under normal load
2. **Stress**: Generate heavy load for Tenant B (10x normal)
3. **Measure**: Re-measure Tenant A's performance during Tenant B's stress
4. **Compare**: Degradation should be <10%

Test scenarios:
- Large tenant with heavy query load
- Tenant with large data volume (>1M rows)
- Tenant with high write throughput
- Concurrent operations across many tenants

Document:
- Per-tenant connection pool usage
- Per-tenant query latency distribution
- Resource contention points
- Noisy neighbor mitigation effectiveness

### Step 7: Generate Audit Report

Produce a comprehensive performance report:

```markdown
## Performance Audit Report

### Date: YYYY-MM-DD
### Scope: [What was audited]
### Environment: [Hardware, software versions, data volumes]

### Executive Summary
[2-3 sentence overview of findings and key recommendations]

### Critical Findings (Fix immediately)
| Finding | Current | Target | Impact | Effort |
|---------|---------|--------|--------|--------|
| ... | ... | ... | High/Medium/Low | Small/Medium/Large |

### Performance Baselines
| Endpoint | p50 | p95 | p99 | Throughput | Status |
|----------|-----|-----|-----|-----------|--------|
| GET /users | Xms | Xms | Xms | X/s | OK/WARN/FAIL |

### Database Analysis
| Query | Avg Time | Calls/min | Fix |
|-------|----------|-----------|-----|
| ... | Xms | N | Add index on X |

### Tenant Isolation
| Metric | Baseline | Under Load | Degradation |
|--------|----------|-----------|-------------|
| Tenant A p99 | Xms | Xms | X% |

### Recommendations (Prioritized)
1. [Highest impact, lowest effort first]
2. ...

### Benchmark Regression Tests Added
[List of new benchmark tests to prevent regressions]
```

Write the report to `docs/spec/.llm/plans/performance-audit-YYYY-MM-DD.md`.
