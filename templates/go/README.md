# {{PROJECT_NAME}}

## Development

### Prerequisites

- Go 1.23+
- [golangci-lint](https://golangci-lint.run/welcome/install/)
- [gofumpt](https://github.com/mvdan/gofumpt) (optional, for strict formatting)
- [GoReleaser](https://goreleaser.com/install/) (optional, for releases)

### Build & Run

```bash
make build
make run
```

### Test

```bash
make test          # Run tests with race detector
make coverage      # Generate HTML coverage report
```

### Lint & Format

```bash
make lint          # Run golangci-lint
make fmt           # Run gofumpt + goimports
make vet           # Run go vet
make check         # All of the above
```

### Release

```bash
make snapshot      # Local snapshot build
git tag v0.1.0 && git push --tags   # Trigger release via CI
```

## Project Structure

```
├── cmd/{{PROJECT_NAME}}/    # Application entry point
│   ├── main.go              # Main with run() pattern
│   └── main_test.go         # Entry point tests
├── internal/                # Private application code
│   └── greeter/             # Example package — use as a reference for new packages
│       ├── doc.go           # Package documentation with usage example
│       ├── model.go         # Domain model with validation
│       ├── repository.go    # Repository interface + in-memory implementation
│       ├── service.go       # Business logic with functional options
│       └── service_test.go  # Table-driven tests using memory repo
├── Makefile                 # Build, test, lint, release targets
├── Dockerfile               # Multi-stage, multi-arch build
├── .goreleaser.yml          # Release automation config
├── .golangci.yml            # Linter config
├── .github/workflows/       # CI/CD pipelines
│   ├── ci.yml               # Build, test, lint on PR
│   └── release.yml          # GoReleaser on tag push
└── renovate.json            # Dependency update automation
```

### Adding a New Package

Follow the `internal/greeter/` pattern:

1. **`model.go`** — Domain types with `Validate()` methods
2. **`repository.go`** — Interface + `NewMemoryRepository()` for tests
3. **`service.go`** — Business logic with `NewService(opts ...Option)` constructor
4. **`service_test.go`** — Table-driven tests using the memory backend
5. **`doc.go`** — Package comment with usage example

## License

See [LICENSE](./LICENSE) for details.
