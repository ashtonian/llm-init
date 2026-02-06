# Testing Guide

Comprehensive testing standards and patterns for the platform. Tests should be high-level, well-documented, robust, and provide clear diagnostics when they fail. The goal is full integration testing using standard modern libraries and practices, with test coverage that gives confidence in correctness without being burdensome to maintain.

> **LLM Quick Reference**: Testing Guide specification and patterns.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Writing new tests for a feature
- Understanding the testing conventions and standards
- Debugging test failures
- Setting up test infrastructure for a new package
- Implementing policy or authorization tests
- Testing time-series data queries

### Key Sections

| Section | Purpose |
|---------|---------|
| **Design Principles** | Core testing philosophy |
| **Test Organization** | Directory structure, naming, build tags |
| **Unit Testing Patterns** | Table-driven tests, mocking, helpers |
| **Integration Testing Patterns** | Database setup, multi-tenant scenarios, fixtures |
| **Policy Enforcement Testing** | Testing all three authorization layers |
| **Time-Series Data Testing** | ScyllaDB patterns, time-based assertions |
| **API Testing** | HTTP handler testing, validation, error responses |
| **Test Coverage Standards** | Coverage targets, measurement |
| **Test Tooling** | Library usage, testify, go-cmp, testcontainers |
| **CI/CD Integration** | Pipeline configuration, parallelization |

### Quick Reference: Test Commands

```bash
# Unit tests only
go test -tags unit ./...

# Integration tests
go test -tags integration -timeout 20m ./...

# All tests with coverage
go test -race -cover ./...

# Single test with verbose output
go test -v -run TestDeviceService_Create ./apps/api/service/...

# Generate coverage report
go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out
```

### Quick Reference: Test Structure

```go
func TestComponent_Method(t *testing.T) {
    t.Parallel() // If safe

    tests := []struct {
        name     string
        input    InputType
        expected OutputType
        wantErr  bool
    }{
        // Test cases
    }

    for _, tt := range tests {
        tt := tt
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            result, err := component.Method(tt.input)

            if tt.wantErr {
                require.Error(t, err)
                return
            }

            require.NoError(t, err)
            assert.Equal(t, tt.expected, result)
        })
    }
}
```

### Quick Reference: Assertion Usage

| Scenario | Use |
|----------|-----|
| Must succeed to continue | `require.NoError(t, err)` |
| Multiple checks on result | `assert.Equal(t, expected, actual)` |
| Deep object comparison | `testutil.RequireDeepEqual(t, expected, actual)` |
| Ignore time fields | `testutil.IgnoreTimeFields()` |
| Check error code | `assert.Equal(t, "E3001", apiErr.Code)` |

### Context Loading

1. For **test patterns only**: This doc is sufficient
2. For **Go code patterns**: Also load `./go-generation-guide.md`
3. For **performance testing**: Also load `./performance-guide.md`

---

## Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Integration-First** | Prefer integration tests that exercise real dependencies; unit tests for complex isolated logic |
| **High-Level Testing** | Test behavior through public APIs, not internal implementation details |
| **Robust and Deterministic** | Tests must not be flaky; use explicit waits, not sleeps; control all external state |
| **Self-Documenting** | Test names describe behavior; failures explain what went wrong and why |
| **Parallel by Default** | Tests should be parallelizable; use isolated test data per test |
| **Fast Feedback** | Unit tests run in milliseconds; integration tests minimize setup overhead |
| **Easy Debugging** | Clear error messages with expected vs actual; trace IDs for request correlation |


| **Portable & CI-Agnostic** | Tests run identically on local Mac and in GitHub Actions; no CI-specific test code; use `docker compose` + `go test` as the universal entry point |
| **Local-First Development** | All tests runnable locally on macOS with minimal setup; use testcontainers or `docker compose` for dependencies; no cloud-only test paths |

---

## Test Organization

### Directory Structure

```
apps/
├── api/
│   ├── service/
│   │   ├── devices.go
│   │   └── devices_test.go      # Unit tests (same package)
│   └── tests2/                   # Integration tests (separate package)
│       ├── devices_test.go
│       ├── helpers/
│       │   ├── request.go        # HTTP test client
│       │   └── seed.go           # Test data seeding
│       └── types/
│           └── types.go          # Shared test types
├── evaluator/
│   ├── evaluator.go
│   └── evaluator_test.go
common/
├── testutil/                     # Shared test utilities
│   ├── assertions.go             # Custom assertions with go-cmp
│   ├── http_client.go            # HTTP testing helpers
│   ├── http_opts.go              # Functional options for HTTP client
│   ├── validators.go             # Validation test helpers
│   ├── db/
│   │   └── helpers.go            # Database test helpers
│   └── seed/
│       ├── builder.go            # TenantBuilder for test data
│       ├── cleanup.go            # Test cleanup utilities
│       └── seed.go               # Low-level seeding functions
├── query/
│   └── datapoints/
│       ├── store.go
│       └── store_test.go         # Integration tests for ScyllaDB
```

### Naming Conventions

| Convention | Example | Usage |
|------------|---------|-------|
| **Test Function** | `TestDeviceService_Create` | `Test<Subject>_<Method>` |
| **Subtest** | `t.Run("returns error when name empty", ...)` | Describe expected behavior |
| **Table Test** | `TestValidation/invalid_email` | Slash-separated for table tests |
| **File Suffix** | `*_test.go` | Required by Go |
| **Package** | Same or `_test` | Same package for unit, `_test` for black-box |

### Build Tags

```go
//go:build unit
// +build unit

package mypackage

// Unit tests run with: go test -tags unit ./...
```

```go
//go:build !unit
// +build !unit

package mypackage_test

// Integration tests run with: go test ./...
// Excluded from unit tests
```

| Tag | Usage | Command |
|-----|-------|---------|
| `unit` | Fast tests, no external dependencies | `go test -tags unit ./...` |
| `integration` | Requires running databases | `go test -tags integration ./...` |
| `!unit` | Default for integration tests | `go test ./...` (includes integration) |

---

## Unit Testing Patterns

### Table-Driven Tests

Table-driven tests are the standard pattern for testing multiple input/output combinations.

```go
func TestParseFilter_ValidInputs(t *testing.T) {
    t.Parallel()

    tests := []struct {
        name     string
        input    string
        expected *Filter
        wantErr  bool
    }{
        {
            name:  "simple equality",
            input: `{"status":"active"}`,
            expected: &Filter{
                Field:    "status",
                Operator: OpEquals,
                Value:    "active",
            },
        },
        {
            name:  "nested field",
            input: `{"labels.env":"production"}`,
            expected: &Filter{
                Field:    "labels.env",
                Operator: OpEquals,
                Value:    "production",
            },
        },
        {
            name:    "invalid JSON",
            input:   `{invalid}`,
            wantErr: true,
        },
    }

    for _, tt := range tests {
        tt := tt // Capture range variable for parallel tests
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            result, err := ParseFilter(tt.input)

            if tt.wantErr {
                require.Error(t, err)
                return
            }

            require.NoError(t, err)
            assert.Equal(t, tt.expected, result)
        })
    }
}
```

### Mocking Strategies

Use interfaces for dependencies and provide test implementations.

```go
// Production interface
type DeviceRepository interface {
    Get(ctx context.Context, id string) (*Device, error)
    Create(ctx context.Context, input *DeviceCreate) (*Device, error)
    List(ctx context.Context, opts *ListOptions) ([]*Device, error)
}

// Mock implementation for tests
type MockDeviceRepository struct {
    GetFunc    func(ctx context.Context, id string) (*Device, error)
    CreateFunc func(ctx context.Context, input *DeviceCreate) (*Device, error)
    ListFunc   func(ctx context.Context, opts *ListOptions) ([]*Device, error)
}

func (m *MockDeviceRepository) Get(ctx context.Context, id string) (*Device, error) {
    if m.GetFunc != nil {
        return m.GetFunc(ctx, id)
    }
    return nil, errors.New("GetFunc not implemented")
}

// Usage in test
func TestDeviceService_GetDevice(t *testing.T) {
    expectedDevice := &Device{ID: "dev_123", Name: "Test"}

    repo := &MockDeviceRepository{
        GetFunc: func(ctx context.Context, id string) (*Device, error) {
            assert.Equal(t, "dev_123", id)
            return expectedDevice, nil
        },
    }

    svc := NewDeviceService(repo)
    device, err := svc.GetDevice(context.Background(), "dev_123")

    require.NoError(t, err)
    assert.Equal(t, expectedDevice, device)
}
```

### Test Helpers

Common test helper patterns from `common/testutil/`:

```go
import "github.com/platform2121/lattice/common/testutil"

func TestDeepEquality(t *testing.T) {
    expected := &Device{
        ID:        "dev_123",
        Name:      "Test Device",
        CreatedAt: time.Now(), // Will be different
    }

    actual := getDevice()

    // Use go-cmp for deep comparison with time field ignored
    testutil.RequireDeepEqual(t, expected, actual, testutil.IgnoreTimeFields())
}

func TestSliceComparison(t *testing.T) {
    expected := []string{"b", "a", "c"}
    actual := []string{"a", "b", "c"}

    // Compare slices regardless of order
    testutil.AssertDeepEqual(t, expected, actual,
        testutil.CmpOpts.SortSlices(func(a, b string) bool { return a < b }),
    )
}
```

### Context and Tenant Setup

```go
func TestWithTenantContext(t *testing.T) {
    // Create context with tenant ID
    ctx := context.Background()
    ctx = dal.WithTenantID(ctx, "tenant_123")
    ctx = dal.WithIdentity(ctx, &Identity{
        UserID: "user_456",
        Roles:  []string{"admin"},
    })

    // Use in test
    result, err := svc.DoSomething(ctx)
    require.NoError(t, err)
}
```

---

## Integration Testing Patterns

### Database Setup/Teardown

Integration tests use real databases. The test infrastructure provides shared connections.

```go
//go:build !unit
// +build !unit

package tests2

import (
    "os"
    "testing"

    "github.com/gocql/gocql"
    "github.com/gocraft/dbr/v2"
)

var (
    GlobalPostgres *dbr.Connection
    GlobalScylla   *gocql.Session
    GlobalServer   *http.Server
)

func TestMain(m *testing.M) {
    // Setup shared test infrastructure
    GlobalPostgres = setupPostgresConnection()
    GlobalScylla = setupScyllaSession()
    GlobalServer = setupTestServer()

    // Run tests
    code := m.Run()

    // Cleanup
    GlobalPostgres.Close()
    GlobalScylla.Close()

    os.Exit(code)
}
```

### Multi-Tenant Test Scenarios

Use the TenantBuilder for creating isolated test data.

```go
import "github.com/platform2121/lattice/common/testutil/seed"

func TestDeviceListAcrossTenants(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping integration test")
    }

    // Create two separate tenants with isolated data
    tenant1 := seed.NewTenantBuilder(t, GlobalPostgres, GlobalScylla).
        WithName("tenant1").
        Build()

    tenant2 := seed.NewTenantBuilder(t, GlobalPostgres, GlobalScylla).
        WithName("tenant2").
        Build()

    // Create devices in each tenant
    client1 := helpers.NewClient(GlobalServer, tenant1.URL, tenant1.RootUsername, tenant1.Password)
    client2 := helpers.NewClient(GlobalServer, tenant2.URL, tenant2.RootUsername, tenant2.Password)

    // Create device in tenant1
    resp := client1.Do("POST", "/api/devices", `{"name": "Device1"}`)
    require.Equal(t, http.StatusCreated, resp.Code)

    // Verify tenant2 cannot see tenant1's device
    resp = client2.Do("GET", "/api/devices", "")
    require.Equal(t, http.StatusOK, resp.Code)

    var devices []Device
    json.Unmarshal([]byte(resp.Body), &devices)
    assert.Empty(t, devices, "Tenant2 should not see Tenant1's devices")
}
```

### Context Injection for Tests

```go
func TestServiceWithPolicyContext(t *testing.T) {
    // Setup policy context as middleware would
    ctx := context.Background()
    ctx = dal.WithTenantID(ctx, "tenant_123")
    ctx = policy.WithPolicyContext(ctx, &policy.PolicyContext{
        Identity: &policy.Identity{
            Type:     policy.SubjectTypeUser,
            ID:       "user_456",
            TenantID: "tenant_123",
            Roles:    []string{"operator"},
        },
        ResourceScopes: []policy.ResolvedScope{{
            LabelFilters: []policy.LabelSelector{{
                MatchLabels: map[string]string{"zone": "ops"},
            }},
        }},
    })

    // Service respects the policy context
    devices, err := svc.ListDevices(ctx, &ListOptions{})
    require.NoError(t, err)

    // Verify only devices matching the policy are returned
    for _, d := range devices {
        assert.Equal(t, "ops", d.Labels["zone"])
    }
}
```

### Test Fixtures and Factories

```go
// fixtures.go - Reusable test data creators

type DeviceFactory struct {
    defaults Device
    sequence int
}

func NewDeviceFactory() *DeviceFactory {
    return &DeviceFactory{
        defaults: Device{
            Type:   "sensor",
            Status: "active",
        },
    }
}

func (f *DeviceFactory) Build(overrides ...func(*Device)) *Device {
    f.sequence++
    d := f.defaults
    d.ID = fmt.Sprintf("dev_%d", f.sequence)
    d.Name = fmt.Sprintf("Device %d", f.sequence)

    for _, override := range overrides {
        override(&d)
    }
    return &d
}

func (f *DeviceFactory) WithName(name string) func(*Device) {
    return func(d *Device) {
        d.Name = name
    }
}

func (f *DeviceFactory) WithLabels(labels map[string]string) func(*Device) {
    return func(d *Device) {
        d.Labels = labels
    }
}

// Usage in test
func TestSomething(t *testing.T) {
    factory := NewDeviceFactory()

    device1 := factory.Build(
        factory.WithName("Custom Name"),
        factory.WithLabels(map[string]string{"env": "prod"}),
    )
    device2 := factory.Build() // Uses defaults with incremented sequence
}
```

---

## Policy Enforcement Testing

Testing the three-layer policy system requires validating authorization at each layer.

### Layer 1: Route Authorization Testing

```go
func TestRouteAuthorization(t *testing.T) {
    tests := []struct {
        name       string
        method     string
        path       string
        role       string
        wantStatus int
    }{
        {
            name:       "admin can create devices",
            method:     "POST",
            path:       "/api/v1/devices",
            role:       "admin",
            wantStatus: http.StatusCreated,
        },
        {
            name:       "viewer cannot create devices",
            method:     "POST",
            path:       "/api/v1/devices",
            role:       "viewer",
            wantStatus: http.StatusForbidden,
        },
        {
            name:       "viewer can read devices",
            method:     "GET",
            path:       "/api/v1/devices",
            role:       "viewer",
            wantStatus: http.StatusOK,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            client := createClientWithRole(t, tt.role)
            resp := client.Do(tt.method, tt.path, `{"name": "test"}`)
            assert.Equal(t, tt.wantStatus, resp.Code,
                "Expected %d for %s %s with role %s, got %d: %s",
                tt.wantStatus, tt.method, tt.path, tt.role, resp.Code, resp.Body)
        })
    }
}
```

### Layer 2: Resource Authorization Testing

```go
func TestResourceAuthorization(t *testing.T) {
    // Setup: Create device in a specific folder
    tenant := seed.NewTenantBuilder(t, GlobalPostgres, GlobalScylla).Build()

    // Create user with access to only certain folders
    restrictedUser := createUserWithFolderAccess(t, tenant, []string{"folder_ops"})

    // Create device in different folder
    createDeviceInFolder(t, tenant, "device_1", "folder_ops")
    createDeviceInFolder(t, tenant, "device_2", "folder_admin")

    // Test: Restricted user can access device_1 but not device_2
    client := helpers.NewClient(GlobalServer, tenant.URL, restrictedUser.Email, restrictedUser.Password)

    resp := client.Do("GET", "/api/v1/devices/device_1", "")
    assert.Equal(t, http.StatusOK, resp.Code, "Should access device in allowed folder")

    resp = client.Do("GET", "/api/v1/devices/device_2", "")
    assert.Equal(t, http.StatusForbidden, resp.Code, "Should not access device in restricted folder")
}
```

### Layer 3: Query Filtering Testing

```go
func TestPolicyQueryFiltering(t *testing.T) {
    // Setup: Create devices with different labels
    tenant := seed.NewTenantBuilder(t, GlobalPostgres, GlobalScylla).Build()

    createDevice(t, tenant, "device_ops_1", map[string]string{"zone": "ops"})
    createDevice(t, tenant, "device_ops_2", map[string]string{"zone": "ops"})
    createDevice(t, tenant, "device_prod", map[string]string{"zone": "prod"})

    // Create user with policy limiting to zone=ops
    opsUser := createUserWithLabelPolicy(t, tenant, "zone", "ops")
    client := helpers.NewClient(GlobalServer, tenant.URL, opsUser.Email, opsUser.Password)

    // Test: List should only return ops devices
    resp := client.Do("GET", "/api/v1/devices", "")
    require.Equal(t, http.StatusOK, resp.Code)

    var result struct {
        Items []Device `json:"items"`
    }
    json.Unmarshal([]byte(resp.Body), &result)

    assert.Len(t, result.Items, 2, "Should return only 2 ops devices")
    for _, d := range result.Items {
        assert.Equal(t, "ops", d.Labels["zone"],
            "All returned devices should have zone=ops")
    }
}
```

### Field-Level Access Testing

```go
func TestFieldLevelAccess(t *testing.T) {
    tenant := seed.NewTenantBuilder(t, GlobalPostgres, GlobalScylla).Build()

    // Create user with read-only access to certain fields
    readOnlyUser := createUserWithFieldPolicy(t, tenant, map[string]string{
        "id":       "read",
        "name":     "read",
        "metadata": "write",
        // secret_key not listed = not accessible
    })

    device := createDevice(t, tenant, "device_1", nil)
    client := helpers.NewClient(GlobalServer, tenant.URL, readOnlyUser.Email, readOnlyUser.Password)

    // Test read: secret_key should not be in response
    resp := client.Do("GET", fmt.Sprintf("/api/v1/devices/%s", device.ID), "")
    require.Equal(t, http.StatusOK, resp.Code)

    var result map[string]interface{}
    json.Unmarshal([]byte(resp.Body), &result)

    assert.Contains(t, result, "id")
    assert.Contains(t, result, "name")
    assert.NotContains(t, result, "secret_key", "secret_key should be masked")

    // Test write: Cannot modify name (read-only)
    resp = client.Do("PATCH", fmt.Sprintf("/api/v1/devices/%s", device.ID),
        `[{"op": "replace", "path": "/name", "value": "new name"}]`)
    assert.Equal(t, http.StatusForbidden, resp.Code)

    // Test write: Can modify metadata (write access)
    resp = client.Do("PATCH", fmt.Sprintf("/api/v1/devices/%s", device.ID),
        `[{"op": "replace", "path": "/metadata/notes", "value": "updated"}]`)
    assert.Equal(t, http.StatusOK, resp.Code)
}
```

---

## Time-Series Data Testing

Testing ScyllaDB queries requires careful handling of time-based data.

### ScyllaDB Store Testing

```go
func TestDatapointsStore(t *testing.T) {
    store, err := datapoints.NewStore("scylla", "data")
    require.NoError(t, err)

    // Seed known data
    seedTestDatapoints(t, store)

    t.Run("GetCurrent returns latest values", func(t *testing.T) {
        query := datapoints.NodeInfoCurrent{
            TID:    1,
            NodeID: 4,
            Schema: &types.ChannelSchema{
                "temperature": types.ChannelProperties{Type: "number"},
                "humidity":    types.ChannelProperties{Type: "number"},
            },
        }

        result, err := store.GetCurrent(query)
        require.NoError(t, err)

        assert.Contains(t, result, "temperature")
        assert.Contains(t, result, "humidity")
        assert.Equal(t, 23.5, result["temperature"].Value)
    })

    t.Run("GetHistory returns data in time range", func(t *testing.T) {
        startTime := time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
        endTime := time.Date(2024, 1, 2, 0, 0, 0, 0, time.UTC)

        query := datapoints.NodeInfo{
            TID:       1,
            NodeID:    4,
            Channel:   "temperature",
            StartDate: startTime,
            EndDate:   endTime,
        }

        result, err := store.GetHistory(context.Background(), query)
        require.NoError(t, err)

        // Verify all points are within the time range
        for _, dp := range result {
            assert.True(t, dp.Timestamp.After(startTime) || dp.Timestamp.Equal(startTime),
                "Datapoint timestamp %v should be >= %v", dp.Timestamp, startTime)
            assert.True(t, dp.Timestamp.Before(endTime) || dp.Timestamp.Equal(endTime),
                "Datapoint timestamp %v should be <= %v", dp.Timestamp, endTime)
        }
    })
}
```

### Time-Based Test Data

```go
func seedTestDatapoints(t *testing.T, store *datapoints.Store) {
    t.Helper()

    baseTime := time.Date(2024, 1, 1, 12, 0, 0, 0, time.UTC)

    points := []struct {
        channel   string
        value     interface{}
        timestamp time.Time
    }{
        {"temperature", 22.0, baseTime.Add(-2 * time.Hour)},
        {"temperature", 22.5, baseTime.Add(-1 * time.Hour)},
        {"temperature", 23.5, baseTime},
        {"humidity", 45.0, baseTime.Add(-1 * time.Hour)},
        {"humidity", 48.0, baseTime},
    }

    for _, p := range points {
        err := store.Store(context.Background(), datapoints.StoreInput{
            TID:       1,
            NodeID:    4,
            Channel:   p.channel,
            Value:     p.value,
            Timestamp: p.timestamp,
        })
        require.NoError(t, err)
    }
}
```

### Testing Aggregations

```go
func TestDatapointAggregations(t *testing.T) {
    store := setupTestStore(t)
    seedAggregationTestData(t, store)

    tests := []struct {
        name       string
        aggregation string
        expected   float64
    }{
        {"min", "min", 10.0},
        {"max", "max", 30.0},
        {"avg", "avg", 20.0},
        {"sum", "sum", 60.0},
        {"count", "count", 3.0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := store.Aggregate(context.Background(), AggregateQuery{
                TID:         1,
                NodeID:      4,
                Channel:     "temperature",
                Aggregation: tt.aggregation,
                StartDate:   testStartTime,
                EndDate:     testEndTime,
            })

            require.NoError(t, err)
            assert.InDelta(t, tt.expected, result.Value, 0.001,
                "Aggregation %s expected %v, got %v", tt.aggregation, tt.expected, result.Value)
        })
    }
}
```

---

## API Testing

### HTTP Handler Testing

```go
func TestDeviceAPI(t *testing.T) {
    suite := &DeviceAPISuite{}
    suite.SetupSuite(t)

    t.Run("Create device", suite.TestCreate)
    t.Run("Get device", suite.TestGet)
    t.Run("List devices with filter", suite.TestListWithFilter)
    t.Run("Update device", suite.TestUpdate)
    t.Run("Delete device", suite.TestDelete)
}

type DeviceAPISuite struct {
    client *helpers.HTTPClient
    tenant *helpers.SeedData
}

func (s *DeviceAPISuite) SetupSuite(t *testing.T) {
    s.tenant = helpers.SeedAll(t, GlobalPostgres, GlobalScylla)
    s.client = helpers.NewClient(GlobalServer, s.tenant.URL, s.tenant.RootUsername, s.tenant.Password)
}

func (s *DeviceAPISuite) TestCreate(t *testing.T) {
    body := `{
        "name": "Test Device",
        "type": "sensor",
        "labels": {"zone": "ops"}
    }`

    resp := s.client.Do("POST", "/api/v1/devices", body)

    require.Equal(t, http.StatusCreated, resp.Code,
        "Expected 201 Created, got %d: %s", resp.Code, resp.Body)

    var device Device
    require.NoError(t, json.Unmarshal([]byte(resp.Body), &device))

    assert.NotEmpty(t, device.ID)
    assert.Equal(t, "Test Device", device.Name)
    assert.Equal(t, "sensor", device.Type)
    assert.Equal(t, "ops", device.Labels["zone"])
}

func (s *DeviceAPISuite) TestListWithFilter(t *testing.T) {
    // Create devices to query
    s.createDevice(t, "Device A", map[string]string{"zone": "prod"})
    s.createDevice(t, "Device B", map[string]string{"zone": "prod"})
    s.createDevice(t, "Device C", map[string]string{"zone": "dev"})

    // Query with filter
    resp := s.client.Do("GET", `/api/v1/devices?q={"labels.zone":"prod"}`, "")
    require.Equal(t, http.StatusOK, resp.Code)

    var result ListResponse
    require.NoError(t, json.Unmarshal([]byte(resp.Body), &result))

    assert.Len(t, result.Items, 2, "Should return 2 prod devices")
}
```

### Request/Response Validation

```go
func TestAPIValidation(t *testing.T) {
    client := setupTestClient(t)

    tests := []struct {
        name         string
        method       string
        path         string
        body         string
        wantStatus   int
        wantErrCode  string
        wantErrField string
    }{
        {
            name:        "missing required field",
            method:      "POST",
            path:        "/api/v1/devices",
            body:        `{"type": "sensor"}`,
            wantStatus:  http.StatusBadRequest,
            wantErrCode: "E2002",
            wantErrField: "name",
        },
        {
            name:        "invalid field format",
            method:      "POST",
            path:        "/api/v1/devices",
            body:        `{"name": "", "type": "sensor"}`,
            wantStatus:  http.StatusBadRequest,
            wantErrCode: "E2003",
        },
        {
            name:        "invalid filter syntax",
            method:      "GET",
            path:        `/api/v1/devices?q={invalid}`,
            body:        "",
            wantStatus:  http.StatusBadRequest,
            wantErrCode: "E2005",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            resp := client.Do(tt.method, tt.path, tt.body)

            assert.Equal(t, tt.wantStatus, resp.Code,
                "Expected status %d, got %d: %s", tt.wantStatus, resp.Code, resp.Body)

            var apiErr APIError
            require.NoError(t, json.Unmarshal([]byte(resp.Body), &apiErr))

            assert.Equal(t, tt.wantErrCode, apiErr.Code,
                "Expected error code %s, got %s", tt.wantErrCode, apiErr.Code)

            if tt.wantErrField != "" {
                assert.Contains(t, apiErr.Details, "field")
                assert.Equal(t, tt.wantErrField, apiErr.Details["field"])
            }
        })
    }
}
```

### Testing Error Responses

<!-- See error-handling.md for error code definitions when created. -->

```go
func TestErrorResponses(t *testing.T) {
    client := setupTestClient(t)

    t.Run("not found returns E3001", func(t *testing.T) {
        resp := client.Do("GET", "/api/v1/devices/nonexistent", "")

        require.Equal(t, http.StatusNotFound, resp.Code)

        var apiErr APIError
        require.NoError(t, json.Unmarshal([]byte(resp.Body), &apiErr))

        assert.Equal(t, "E3001", apiErr.Code)
        assert.NotEmpty(t, apiErr.TraceID, "Error should include trace_id for debugging")
        assert.Contains(t, apiErr.Details, "id")
    })

    t.Run("conflict returns E3003 with ETag info", func(t *testing.T) {
        device := createTestDevice(t, client)

        // Update with stale ETag
        resp := client.DoWithHeaders("PUT", "/api/v1/devices/"+device.ID,
            `{"name": "Updated"}`,
            http.Header{"If-Match": []string{"stale-etag"}})

        require.Equal(t, http.StatusPreconditionFailed, resp.Code)

        var apiErr APIError
        require.NoError(t, json.Unmarshal([]byte(resp.Body), &apiErr))

        assert.Equal(t, "E3003", apiErr.Code)
    })
}
```

---

## Test Coverage Standards

### Coverage Expectations

| Component | Target Coverage | Focus Areas |
|-----------|-----------------|-------------|
| **Service Layer** | 80%+ | Business logic, error paths |
| **Repository Layer** | 70%+ | Query correctness, error handling |
| **API Handlers** | 75%+ | Validation, authorization, error responses |
| **Utility Packages** | 90%+ | Edge cases, error conditions |
| **Pipeline Stages** | 80%+ | Happy path, error recovery, DLQ |

### Coverage Measurement

```bash
# Run tests with coverage
go test -cover ./...

# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# Check coverage meets threshold
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//' | \
    xargs -I {} sh -c 'if [ $(echo "{} < 70" | bc) -eq 1 ]; then exit 1; fi'
```

### Coverage Exclusions

Some code is intentionally excluded from coverage requirements:

```go
// Coverage exclusion markers
//go:build ignore

// Or comment-based exclusion
// coverage:ignore - Generated code
// coverage:ignore - Simple delegation
```

| Exclusion Type | Reason |
|----------------|--------|
| Generated code | Auto-generated by tools (goa, sqlc) |
| Simple delegation | One-liner methods that delegate |
| Main functions | Entry points with side effects |
| Test helpers | Testing infrastructure itself |

---

## Test Tooling

### Recommended Libraries

| Library | Purpose | Usage |
|---------|---------|-------|
| **testify/require** | Fatal assertions | `require.NoError(t, err)` - stops test on failure |
| **testify/assert** | Non-fatal assertions | `assert.Equal(t, expected, actual)` - continues on failure |
| **go-cmp** | Deep comparison | Custom comparers, diff output |
| **gomock** | Interface mocking | Complex mock behavior |
| **testcontainers** | Container-based testing | Spin up real databases |

### Using testify Correctly

```go
// Use require for conditions that make continuing pointless
func TestSomething(t *testing.T) {
    result, err := doSomething()
    require.NoError(t, err)              // Stop if error
    require.NotNil(t, result)            // Stop if nil

    // Use assert for multiple checks that should all be reported
    assert.Equal(t, "expected", result.Name)
    assert.Greater(t, result.Count, 0)
    assert.NotEmpty(t, result.Items)
}
```

### Using go-cmp for Complex Comparisons

```go
import (
    "github.com/google/go-cmp/cmp"
    "github.com/google/go-cmp/cmp/cmpopts"
)

func TestComplexComparison(t *testing.T) {
    expected := &Response{
        Items: []Item{{ID: "a"}, {ID: "b"}},
        Pagination: &Pagination{
            Total:    100,
            NextPage: "xyz",
        },
    }

    actual := getResponse()

    // Compare with custom options
    opts := cmp.Options{
        cmpopts.IgnoreFields(Item{}, "CreatedAt", "UpdatedAt"),
        cmpopts.SortSlices(func(a, b Item) bool { return a.ID < b.ID }),
        cmpopts.EquateEmpty(), // Treat nil and empty slices as equal
    }

    if diff := cmp.Diff(expected, actual, opts); diff != "" {
        t.Errorf("Response mismatch (-expected +actual):\n%s", diff)
    }
}
```

### Using testcontainers for Database Tests

```go
import (
    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/wait"
)

func SetupPostgresContainer(t *testing.T) (*dbr.Connection, func()) {
    ctx := context.Background()

    container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: testcontainers.ContainerRequest{
            Image:        "postgres:15",
            ExposedPorts: []string{"5432/tcp"},
            Env: map[string]string{
                "POSTGRES_USER":     "test",
                "POSTGRES_PASSWORD": "test",
                "POSTGRES_DB":       "testdb",
            },
            WaitingFor: wait.ForLog("database system is ready to accept connections"),
        },
        Started: true,
    })
    require.NoError(t, err)

    host, _ := container.Host(ctx)
    port, _ := container.MappedPort(ctx, "5432")

    dsn := fmt.Sprintf("postgres://test:test@%s:%s/testdb?sslmode=disable", host, port.Port())
    conn, err := dbr.Open("postgres", dsn, nil)
    require.NoError(t, err)

    cleanup := func() {
        conn.Close()
        container.Terminate(ctx)
    }

    return conn, cleanup
}
```

---

## CI/CD Integration

### Running Tests in Pipeline

```yaml
# .drone.yml or similar
steps:
  - name: unit-tests
    commands:
      - go test -tags unit -race -cover -coverprofile=unit.out ./...
      - go tool cover -func=unit.out | grep total

  - name: integration-tests
    commands:
      - make clean_test_db
      - go test -tags integration -race -cover -coverprofile=integration.out -timeout 20m ./...
    when:
      event: [push, pull_request]

  - name: coverage-report
    commands:
      - gocov convert coverage.out | gocov-xml > coverage.xml
    when:
      event: pull_request
```

### Parallelization

Tests are parallelized at multiple levels:

```go
// Package-level parallelization (default)
// Each test file runs in parallel

// Test-level parallelization
func TestParallel(t *testing.T) {
    t.Parallel() // Mark test as parallelizable

    t.Run("subtest 1", func(t *testing.T) {
        t.Parallel() // Subtests can also be parallel
        // ...
    })

    t.Run("subtest 2", func(t *testing.T) {
        t.Parallel()
        // ...
    })
}
```

### Test Database Management

```bash
# Reset test databases before integration tests
make clean_test_db

# Run specific test with verbose output
go test -v -run TestDeviceService_Create ./apps/api/service/...

# Run tests with race detection
go test -race ./...
```

### Timeout Handling

```go
func TestWithTimeout(t *testing.T) {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    result, err := slowOperation(ctx)

    if errors.Is(err, context.DeadlineExceeded) {
        t.Fatal("Operation timed out - investigate performance")
    }
    require.NoError(t, err)
}
```

---

## Debugging Test Failures

### Clear Failure Messages

```go
// GOOD: Descriptive failure message
assert.Equal(t, expectedCount, actualCount,
    "Expected %d devices for tenant %s with filter %v, got %d",
    expectedCount, tenantID, filter, actualCount)

// BAD: Generic failure message
assert.Equal(t, expectedCount, actualCount)
```

### Using Trace IDs

```go
func TestWithTracing(t *testing.T) {
    resp := client.Do("GET", "/api/v1/devices", "")

    if resp.Code != http.StatusOK {
        var apiErr APIError
        json.Unmarshal([]byte(resp.Body), &apiErr)

        t.Errorf("Request failed with status %d:\n"+
            "  Trace ID: %s\n"+
            "  Error Code: %s\n"+
            "  Message: %s\n"+
            "  Details: %v\n"+
            "Use trace_id to find related logs",
            resp.Code, apiErr.TraceID, apiErr.Code, apiErr.Message, apiErr.Details)
    }
}
```

### Test Logging

```go
func TestVerbose(t *testing.T) {
    if testing.Verbose() {
        t.Logf("Setting up test with tenant: %s", tenantID)
    }

    // ... test code ...

    if testing.Verbose() {
        t.Logf("Response body: %s", resp.Body)
    }
}

// Run with: go test -v -run TestVerbose ./...
```

---

## Related Documentation

- **[Go Generation Guide](./go-generation-guide.md)** - Mandatory Go code patterns and idioms
- **[Performance Guide](./performance-guide.md)** - Performance standards and profiling

<!-- Add these cross-references as you create the specs:
- **data-access.md** - Repository testing patterns, test database setup
- **permission-policy-system.md** - Testing policy enforcement
- **error-handling.md** - Error code assertions, expected error patterns
- **observability.md** - Test tracing, debugging with trace IDs
-->

