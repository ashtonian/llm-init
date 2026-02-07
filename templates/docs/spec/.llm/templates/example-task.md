# Task 03 — Add User Service with CRUD Operations

## Phase: 2 — Core Services
## Priority: High
## Dependencies: Tasks 01, 02

## Objective
Implement the user service package (`internal/user/`) with domain model, repository interface, memory-backed implementation, service layer with functional options, and comprehensive tests. This establishes the pattern for all subsequent domain packages.

## Technical Spec Reference
- **Spec Path**: `docs/spec/biz/user-management-spec.md`
- **Relevant Sections**: Data Models (§2.1), Validation Rules (§2.3), Error Codes (§3.1)

## Spec Compliance Checklist
- [ ] Data models match spec definitions (User struct fields, types, constraints)
- [ ] API contracts match spec (Create/Get/List/Update/Delete signatures)
- [ ] Error handling matches spec (ErrNotFound, ErrDuplicateEmail, ErrInvalidInput)
- [ ] Edge cases from spec are handled (empty name, duplicate email, soft delete)
- [ ] Tests cover spec scenarios (§4.1 test matrix)

## Specs to Reference
- `.claude/rules/go-patterns.md` — for Go conventions
- `docs/spec/biz/user-management-spec.md` — for domain requirements
- `internal/greeter/` — for package structure reference

## Steps
1. Create `internal/user/model.go` with User struct and CreateInput/UpdateInput types with Validate() methods
2. Create `internal/user/repository.go` with Repository interface (Store, FindByID, FindByEmail, List, Delete) and MemoryRepository implementation
3. Create `internal/user/service.go` with NewService(opts ...Option) constructor, CRUD methods, and input validation
4. Create `internal/user/service_test.go` with table-driven tests covering: create valid user, create with duplicate email, create with empty name, get existing user, get nonexistent user, list empty, list with items, update fields, delete and verify gone
5. Create `internal/user/doc.go` with package documentation and usage example
6. Verify all error types from spec §3.1 are defined and returned correctly

## Files to Modify
- (none — new package)

## Files to Create
- `internal/user/doc.go`
- `internal/user/model.go`
- `internal/user/repository.go`
- `internal/user/service.go`
- `internal/user/service_test.go`

## Verification
```bash
# Run all tests with race detector
go test -race -v ./internal/user/...

# Run full project tests
go build ./... && go test -race ./... && go vet ./...
```

## Acceptance Criteria
- [ ] User struct matches spec §2.1 (ID, Email, Name, CreatedAt, UpdatedAt, DeletedAt)
- [ ] All CRUD operations implemented and tested
- [ ] Duplicate email detection works (FindByEmail + check in Create)
- [ ] Input validation rejects empty name, invalid email format, name > 200 chars
- [ ] Table-driven tests with ≥ 8 test cases covering happy path + error paths
- [ ] Memory repository is safe for concurrent use (sync.RWMutex)
- [ ] Package doc.go has usage example showing NewService with options
- [ ] All quality gates pass (build, test, vet, lint)
- [ ] Error types match spec §3.1

## Handoff State
<!-- This section is populated by agents when shelving. Do NOT fill in manually. -->
<!-- When an agent shelves this task, it writes its progress here so the next agent can continue. -->
