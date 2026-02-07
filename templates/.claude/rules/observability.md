# Observability Standards

Mandatory patterns for structured logging, distributed tracing, metrics, alerting, and health checks. If you can't observe it, you can't operate it.

## Structured Logging

### Format: JSON

Every log entry MUST be a JSON object with these required fields:

```json
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "info",
  "message": "User created",
  "tenant_id": "uuid",
  "request_id": "uuid",
  "user_id": "uuid",
  "trace_id": "hex",
  "span_id": "hex",
  "service": "user-service",
  "component": "handler",
  "duration_ms": 45
}
```

### Required Context Fields

Every log entry MUST include (when available in context):

| Field | Source | Purpose |
|-------|--------|---------|
| `tenant_id` | JWT / context | Tenant scoping for log queries |
| `request_id` | X-Request-ID header | Correlate all logs for one request |
| `user_id` | JWT claims | Attribute actions to users |
| `trace_id` | OpenTelemetry | Link to distributed trace |
| `service` | Config | Identify which service logged |

### Go Implementation

```go
// Create logger with request context
func LoggerFromContext(ctx context.Context) *slog.Logger {
    logger := slog.Default()
    if tid := tenant.FromContext(ctx); tid != uuid.Nil {
        logger = logger.With("tenant_id", tid.String())
    }
    if rid := requestid.FromContext(ctx); rid != "" {
        logger = logger.With("request_id", rid)
    }
    if uid := auth.UserIDFromContext(ctx); uid != uuid.Nil {
        logger = logger.With("user_id", uid.String())
    }
    if span := trace.SpanFromContext(ctx); span.SpanContext().IsValid() {
        logger = logger.With(
            "trace_id", span.SpanContext().TraceID().String(),
            "span_id", span.SpanContext().SpanID().String(),
        )
    }
    return logger
}
```

### Log Levels

| Level | When to Use | Production? | Examples |
|-------|------------|-------------|---------|
| **ERROR** | Something failed that needs investigation | Yes | DB connection failed, external API error, data corruption |
| **WARN** | Degraded but functional, or approaching limits | Yes | Rate limit approaching, deprecated API used, slow query |
| **INFO** | Business events, lifecycle events | Yes | User created, order placed, deployment started, config changed |
| **DEBUG** | Development details, intermediate values | **Never in production** | SQL queries, request/response bodies, cache hit/miss |

### What to Log

```go
// DO: Business events with context
logger.Info("user created",
    "email", user.Email,
    "role", user.Role,
    "invited_by", inviterID,
)

// DO: Errors with full context
logger.Error("failed to create user",
    "error", err,
    "email", user.Email,
    "attempted_role", user.Role,
)

// DO: Performance observations
logger.Warn("slow query detected",
    "query", "FindUsersByTenant",
    "duration_ms", duration.Milliseconds(),
    "row_count", count,
)
```

### What NOT to Log

```go
// NEVER: Sensitive data
logger.Info("login", "password", password)           // NEVER
logger.Info("payment", "card_number", cardNum)        // NEVER
logger.Info("token", "access_token", token)           // NEVER

// NEVER: High-volume debug logs in production
logger.Debug("cache check", "key", key, "hit", true)  // Disable in production

// NEVER: PII without redaction
logger.Info("user", "ssn", user.SSN)                  // NEVER
```

## Distributed Tracing

### OpenTelemetry Setup

```go
func initTracer() (*sdktrace.TracerProvider, error) {
    exporter, err := otlptracehttp.New(context.Background(),
        otlptracehttp.WithEndpoint("otel-collector:4318"),
    )
    if err != nil {
        return nil, err
    }

    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceName("user-service"),
            semconv.DeploymentEnvironment("production"),
        )),
        sdktrace.WithSampler(sdktrace.ParentBased(
            sdktrace.TraceIDRatioBased(0.1),  // Sample 10% of traces
        )),
    )
    return tp, nil
}
```

### Span Creation

```go
func (s *UserService) CreateUser(ctx context.Context, input CreateUserInput) (*User, error) {
    ctx, span := tracer.Start(ctx, "UserService.CreateUser",
        trace.WithAttributes(
            attribute.String("tenant_id", tenant.FromContext(ctx).String()),
            attribute.String("user.email", input.Email),
        ),
    )
    defer span.End()

    // Validate
    if err := input.Validate(); err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, "validation failed")
        return nil, err
    }

    // Create user (child span created automatically by instrumented DB)
    user, err := s.repo.Create(ctx, &User{...})
    if err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, "create failed")
        return nil, err
    }

    span.SetAttributes(attribute.String("user.id", user.ID.String()))
    return user, nil
}
```

### Trace Context Propagation

Pass trace context across service boundaries:

```go
// HTTP client -- inject trace context into outgoing headers
client := &http.Client{
    Transport: otelhttp.NewTransport(http.DefaultTransport),
}

// HTTP server -- extract trace context from incoming headers
handler := otelhttp.NewHandler(mux, "server")
```

## Metrics (RED + USE Methods)

### RED Method (for every endpoint)

| Metric | Description | Type |
|--------|-------------|------|
| **Rate** | Requests per second | Counter |
| **Errors** | Error responses per second | Counter |
| **Duration** | Request latency distribution | Histogram |

```go
var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total HTTP requests",
        },
        []string{"method", "path", "status", "tenant_id"},
    )

    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request latency",
            Buckets: []float64{.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10},
        },
        []string{"method", "path", "tenant_id"},
    )
)
```

### USE Method (for resources)

| Metric | Description | Applies To |
|--------|-------------|-----------|
| **Utilization** | % of resource in use | CPU, memory, disk, connections |
| **Saturation** | Work queued / waiting | Queue depth, connection wait time |
| **Errors** | Error count | Connection errors, OOM events |

```go
var (
    dbConnectionsActive = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "db_connections_active",
            Help: "Active database connections",
        },
        []string{"pool"},
    )

    dbConnectionWaitDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "db_connection_wait_seconds",
            Help:    "Time waiting for a database connection",
            Buckets: prometheus.DefBuckets,
        },
        []string{"pool"},
    )
)
```

### Tenant-Scoped Metrics

Always include `tenant_id` as a label for tenant-attributable metrics:

```go
// Per-tenant request rates
httpRequestsTotal.WithLabelValues("GET", "/api/v1/users", "200", tenantID).Inc()

// Per-tenant latency
httpRequestDuration.WithLabelValues("GET", "/api/v1/users", tenantID).Observe(duration.Seconds())

// Per-tenant resource usage
tenantStorageBytes.WithLabelValues(tenantID).Set(float64(storageUsed))
```

**Warning**: High-cardinality labels (like `user_id`) can cause metric explosion. Use `tenant_id` but NOT `user_id` as metric labels.

## Alerting

### SLO-Based Alerting (not threshold-based)

Define Service Level Objectives and alert on error budget burn rate:

| SLO | Target | Error Budget (30 days) | Alert |
|-----|--------|----------------------|-------|
| Availability | 99.9% | 43 minutes downtime | Page when 1-hour burn rate exceeds 14.4x |
| Latency (p99) | <500ms | 0.1% of requests slow | Page when 1-hour error rate exceeds 14.4x |
| Error rate | <0.1% | 0.1% of requests error | Page when 1-hour error rate exceeds 14.4x |

### Alert Severity

| Severity | Response | Examples |
|----------|----------|---------|
| **P1 - Critical** | Page on-call, immediate response | Service down, data loss, security breach |
| **P2 - High** | Page during business hours | Degraded performance, partial outage |
| **P3 - Medium** | Ticket, address within 24h | Elevated error rate, approaching limits |
| **P4 - Low** | Backlog, address within sprint | Cost anomaly, deprecation warning |

### Alert Rules

```yaml
# Example Prometheus alerting rules
groups:
  - name: slo-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          (sum(rate(http_requests_total{status=~"5.."}[5m]))
          / sum(rate(http_requests_total[5m]))) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate exceeds 1% for 5 minutes"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: high
        annotations:
          summary: "p99 latency exceeds 500ms for 5 minutes"
```

## Health Checks

### Liveness Probe (`/healthz`)

Returns 200 if the process is alive. Should NOT check dependencies.

```go
func healthzHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("ok"))
}
```

### Readiness Probe (`/readyz`)

Returns 200 only if the service can handle requests. Checks critical dependencies.

```go
func readyzHandler(w http.ResponseWriter, r *http.Request) {
    checks := map[string]error{
        "database": checkDB(r.Context()),
        "cache":    checkRedis(r.Context()),
    }

    allHealthy := true
    result := make(map[string]string)
    for name, err := range checks {
        if err != nil {
            allHealthy = false
            result[name] = err.Error()
        } else {
            result[name] = "ok"
        }
    }

    if allHealthy {
        w.WriteHeader(http.StatusOK)
    } else {
        w.WriteHeader(http.StatusServiceUnavailable)
    }
    json.NewEncoder(w).Encode(result)
}
```

## Dashboard Template

Every service should have a Grafana dashboard with:

### Overview Panel
- Request rate (per second, per endpoint)
- Error rate (percentage, per endpoint)
- p50, p95, p99 latency
- Active connections (DB, Redis, HTTP)

### Tenant Drill-Down Panel
- Per-tenant request rate
- Per-tenant error rate
- Per-tenant latency percentiles
- Per-tenant resource usage (storage, API calls)

### Infrastructure Panel
- CPU, memory, disk usage
- Pod count and restart count
- Database connection pool utilization
- Cache hit rate

## Cost Attribution

Tag cloud resources by tenant for billing/chargeback:

```go
// Track per-tenant API usage for billing
func trackUsage(ctx context.Context, endpoint string, responseSize int) {
    tenantID := tenant.FromContext(ctx)
    metrics.APICallsTotal.WithLabelValues(tenantID, endpoint).Inc()
    metrics.ResponseBytesTotal.WithLabelValues(tenantID, endpoint).Add(float64(responseSize))
}
```

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| Unstructured log messages (`fmt.Println`) | Structured JSON logging (`slog`) |
| Logging without tenant/request context | Always include tenant_id, request_id |
| Logging sensitive data (passwords, tokens) | Never log secrets; use struct tags to exclude |
| Alerting on individual errors | Alert on SLO breach / error budget burn |
| No health checks | `/healthz` (liveness) + `/readyz` (readiness) |
| High-cardinality metric labels (`user_id`) | Use `tenant_id`, not `user_id` for metrics |
| Debug logging in production | Only ERROR/WARN/INFO in production |
| No trace context propagation | OpenTelemetry context propagation across services |
