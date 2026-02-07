---
paths: ["**/*_test.*", "**/*.test.*", "**/*.spec.*"]
---

# Testing Guide

Standards and patterns for writing robust, maintainable tests.

## Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Integration-First** | Prefer integration tests with real dependencies; unit tests for complex isolated logic |
| **High-Level Testing** | Test behavior through public APIs, not internal implementation |
| **Robust and Deterministic** | No flaky tests; use explicit waits, not sleeps; control all external state |
| **Self-Documenting** | Test names describe behavior; failures explain what went wrong |
| **Parallel by Default** | Tests should be parallelizable; use isolated test data per test |
| **Fast Feedback** | Unit tests in milliseconds; integration tests minimize setup overhead |
| **Portable & CI-Agnostic** | Tests run identically on local Mac and in CI |

## Test Structure (Go)

```go
func TestComponent_Method(t *testing.T) {
    t.Parallel()
    tests := []struct {
        name     string
        input    InputType
        expected OutputType
        wantErr  bool
    }{
        // Test cases
    }
    for _, tt := range tests {
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

## Naming Conventions

| Convention | Example |
|------------|---------|
| Test Function | `TestDeviceService_Create` |
| Subtest | `t.Run("returns error when name empty", ...)` |
| Table Test | `TestValidation/invalid_email` |

## Assertion Usage

| Scenario | Use |
|----------|-----|
| Must succeed to continue | `require.NoError(t, err)` |
| Multiple checks on result | `assert.Equal(t, expected, actual)` |
| Deep comparison | `go-cmp` with custom options |

## Coverage Targets

| Component | Target |
|-----------|--------|
| Service Layer | 80%+ |
| Repository Layer | 70%+ |
| API Handlers | 75%+ |
| Utility Packages | 90%+ |

## Mocking Strategy

Use interfaces for dependencies and provide test implementations with function fields:

```go
type MockRepo struct {
    GetFunc    func(ctx context.Context, id string) (*Entity, error)
    CreateFunc func(ctx context.Context, input *EntityCreate) (*Entity, error)
}
```

## Key Rules

- Table-driven tests for multiple input/output combinations
- Both happy path and error cases covered
- Deterministic: no flaky tests, no sleep-based sync
- Use race detector: `go test -race`
- Clear failure messages with expected vs actual context
- Test fixtures and factories for complex test data
