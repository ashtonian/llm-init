# {{PROJECT_NAME}} -- Agent Guide

## Project
<!-- One-line description of what this project is -->
{{PROJECT_NAME}} is ...

## Goal
<!-- What are we building toward right now? Update as the project evolves. -->

## Tech Stack
<!-- Customize for your project. Remove or replace items that don't apply. -->
- **Backend**: Go
- **Frontend**: TypeScript / React
- **Database**: PostgreSQL
- **Cache**: Redis
- **Messaging**: NATS
<!-- Examples for other stacks:
- **Backend**: Python / FastAPI
- **Backend**: Rust / Axum
- **Frontend**: Svelte / SvelteKit
-->

## Quality Gates
```bash
# Customize these for your project. Examples by stack:

# Go:
# go build ./... && go test -race ./... && go vet ./...

# TypeScript/Node:
# npm run build && npm run test && npm run lint

# Python:
# pytest && mypy . && ruff check .

# Rust:
# cargo build && cargo test && cargo clippy
```

## Production Code Quality Checklist

Every piece of non-trivial code must meet these standards:

**Error Handling**
- All error paths tested (not just happy path)
- Errors wrapped with context (`fmt.Errorf("doing X: %w", err)`)
- Errors classified: is this retryable? Should the user see it?
- No swallowed errors (no bare `_ = doSomething()` without reason)

**Input Validation**
- All external input validated at system boundaries (API handlers, CLI args, config)
- Bounds checked (string length, numeric ranges, collection sizes)
- Nil/empty checks on required fields

**Testing**
- Table-driven tests for functions with multiple cases
- Both happy path and error cases covered
- Tests use in-memory backends (no infrastructure dependency for unit tests)
- Test names describe the scenario, not the function (`TestCreate_EmptyName_ReturnsError`)

**Documentation**
- Package-level `doc.go` with usage example for public packages
- Exported functions have doc comments explaining behavior, not implementation
- Complex logic has inline comments explaining WHY, not WHAT
- README updated if adding new user-facing functionality

**Code Structure**
- Functions < 60 lines; split if longer
- One responsibility per function
- Domain types have `Validate()` methods
- Services accept interfaces, not concrete types
- Constructors use functional options for configurability

## Constraints
- Follow conventions in `.claude/rules/` guides
- Do not modify files outside your task's scope
- Do not skip tests or ignore failures
- Commit your changes before signaling completion -- do NOT push
- If blocked, signal TASK_BLOCKED with a clear reason rather than guessing
