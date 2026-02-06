# {{PROJECT_NAME}} — Agent Guide

> This file is inlined into every autonomous agent prompt. Keep it concise — agents have limited context.

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

## Key Documentation
- **CLAUDE.md** — Claude Code instructions and permissions (auto-loaded)
- **docs/spec/LLM.md** — Orchestration guide, execution order, review loops
- **docs/spec/.llm/PROGRESS.md** — Cross-iteration memory, codebase patterns
- **docs/spec/.llm/SKILLS.md** — Full capabilities catalog (commands, MCP, scripts, models)
- **docs/spec/framework/** — Code convention guides (Go, TypeScript, performance)
- **docs/spec/biz/** — Business specs and feature requirements

Read `CLAUDE.md` and `docs/spec/LLM.md` if you need orchestration context.
Read framework guides before writing code in that language.

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

## Constraints
- Follow conventions in `docs/spec/framework/` guides
- Do not modify files outside your task's scope
- Do not skip tests or ignore failures
- Commit your changes before signaling completion — do NOT push
- If blocked, signal TASK_BLOCKED with a clear reason rather than guessing
