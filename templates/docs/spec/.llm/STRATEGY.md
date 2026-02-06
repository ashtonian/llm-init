# {{PROJECT_NAME}} — Project Strategy & Task Decomposition

> Use this document to decompose your project into phases and tasks for the parallel agent harness.

## Project Goal
<!-- One paragraph describing what you're building -->

## Architecture Overview
<!-- High-level components, data flow, key design decisions -->

## Phases

### Phase 1 — Foundation
<!-- Infrastructure, config, project scaffolding -->

| Task | Priority | Dependencies | Description |
|------|----------|--------------|-------------|
| 01 | High | None | ... |
| 02 | High | None | ... |

### Phase 2 — Core Features
<!-- Primary functionality -->

| Task | Priority | Dependencies | Description |
|------|----------|--------------|-------------|
| 03 | High | Tasks 01, 02 | ... |
| 04 | High | Task 02 | ... |

### Phase 3 — Integration & Polish
<!-- Connecting components, UI, error handling -->

| Task | Priority | Dependencies | Description |
|------|----------|--------------|-------------|
| 05 | Medium | Tasks 03, 04 | ... |
| 06 | Medium | Task 05 | ... |

### Phase 4 — Testing & Documentation
<!-- Comprehensive tests, docs, deployment -->

| Task | Priority | Dependencies | Description |
|------|----------|--------------|-------------|
| 07 | Medium | Task 06 | ... |
| 08 | Low | Task 07 | ... |

## Task Sizing Guidelines

- **Target 75-150 Claude turns per task.** Larger tasks should be split.
- Each task should be independently verifiable (its own build/test commands).
- Tasks within a phase can run in parallel if they have no shared file dependencies.
- Cross-phase dependencies should be explicit (e.g., "Task 05 depends on Tasks 03, 04").

## Creating Task Files

For each row above, create a file in `docs/spec/.llm/tasks/backlog/`:

```bash
# Naming convention: NN-short-description.md (zero-padded, matches task number)
# Example:
cp docs/spec/.llm/templates/task.template.md docs/spec/.llm/tasks/backlog/01-project-scaffolding.md
```

Fill in each task file using the template format. The parallel agent harness reads:
- `## Dependencies:` to determine execution order
- `## Verification` for quality gate commands
- `## Acceptance Criteria` checkboxes for completion tracking

## Dependency Rules

1. Tasks with `Dependencies: None` can run immediately and in parallel
2. A task's dependencies must ALL be in `tasks/completed/` before it can be claimed
3. Keep dependency chains short — deep chains limit parallelism
4. Prefer wide dependency graphs (many independent tasks) over deep ones

## Quality Gates

Define project-wide verification commands here. Individual tasks can override these.

```bash
# Customize these for your stack. Examples:

# Go:
# go build ./... && go test -race ./... && go vet ./...

# TypeScript/Node:
# npm run build && npm run test && npm run lint

# Python:
# pytest && mypy . && ruff check .

# Rust:
# cargo build && cargo test && cargo clippy

# Multi-stack (uncomment the ones you need):
# make test
```
