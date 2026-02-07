# Task NN — Title

<!-- SIZING GUIDE: Each task should be completable in one context window.
     Rule of thumb: If you can't describe the change in 2-3 sentences, split it.
     Good: "Add user model and migration", "Create GET /users endpoint with tests"
     Bad: "Build the user management system", "Implement authentication" -->

## Phase: N — Phase Name
## Priority: High | Medium | Low
## Dependencies: None

## Objective
One-paragraph description of what this task accomplishes.

## Technical Spec Reference
- **Spec Path**: `docs/spec/{spec-path}` (or "N/A" if no spec needed)
- **Relevant Sections**: {list sections of the spec this task implements}

## Spec Compliance Checklist
- [ ] Data models match spec definitions
- [ ] API contracts match spec (endpoints, request/response shapes, status codes)
- [ ] Error handling matches spec (error codes, recovery strategies)
- [ ] Edge cases from spec are handled
- [ ] Tests cover spec scenarios

## Specs to Reference
- `.claude/rules/go-patterns.md` — for Go conventions
- `.claude/rules/typescript-patterns.md` — for frontend patterns

## Steps
1. Step one
2. Step two
3. Step three

## Files to Modify
- `path/to/existing-file.go`

## Files to Create
- `path/to/new-file.go`

## Verification
```bash
# Commands to verify the task is complete (customize for your stack)
# Go:      go build ./... && go test -race ./...
# Node/TS: npm run build && npm run test && npm run lint
# Python:  pytest && mypy . && ruff check .
# Rust:    cargo build && cargo test && cargo clippy
```

## Acceptance Criteria
- [ ] Criterion one
- [ ] Criterion two
- [ ] Criterion three
- [ ] Project builds cleanly
- [ ] All tests pass

## Handoff State
<!-- This section is populated by agents when shelving. Do NOT fill in manually. -->
<!-- When an agent shelves this task, it writes its progress here so the next agent can continue. -->
