APP_NAME := {{PROJECT_NAME}}
MODULE   := {{PROJECT_MODULE}}

# Build
.PHONY: build
build:
	go build -o bin/$(APP_NAME) ./cmd/$(APP_NAME)

# Run
.PHONY: run
run: build
	./bin/$(APP_NAME)

# Test
.PHONY: test
test:
	go test -race -cover ./...

# Test with coverage report
.PHONY: coverage
coverage:
	go test -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

# Lint
.PHONY: lint
lint:
	golangci-lint run ./...

# Format
.PHONY: fmt
fmt:
	gofumpt -w .
	goimports -w .

# Vet
.PHONY: vet
vet:
	go vet ./...

# Clean
.PHONY: clean
clean:
	rm -rf bin/ dist/ coverage.out coverage.html

# Snapshot release (local only)
.PHONY: snapshot
snapshot:
	goreleaser release --snapshot --clean

# All checks
.PHONY: check
check: fmt vet lint test
