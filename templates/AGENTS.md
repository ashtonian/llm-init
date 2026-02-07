# Codex CLI Instructions for {{PROJECT_NAME}}

> This file is the Codex CLI entry point. For Claude Code, see `CLAUDE.md`.

## Execution Modes

| Mode | When | How |
|------|------|-----|
| **Parallel** (default) | Multi-step features, build work, any task with 2+ independent subtasks | Decompose -> task files -> execute tasks |
| **Interactive** | Complex decisions, ambiguous requirements, user wants to pair, initial project setup | Plan file workflow, step-by-step with user |
| **Quick** | Trivial fixes, one-liners, small edits | Just do it -- no plans or tasks needed |
| **Idea Pipeline** | Starting from scratch, 0->100 | Interactive for Research/Spec/Plan, then Parallel for Build |

---

## Skills

Skills are available in `.agents/skills/`. Codex discovers them automatically.

| Skill | What It Does |
|-------|-------------|
| `decompose` | Break a request into parallel tasks (75-150 turns each) |
| `new-task` | Create a single task file in the backlog |
| `status` | Task queue dashboard with analysis |
| `launch` | Pre-flight checks + launch execution |
| `plan` | Select and create the right plan template |
| `review` | Run quality gates and review current work |
| `shelve` | Checkpoint work with structured handoff |
| `requirements` | Iterative requirement gathering -> package spec |
| `architecture-review` | Assess decisions, tradeoffs, edge cases |
| `adr` | Create an Architecture Decision Record |
| `security-review` | Security assessment of codebase or feature |
| `prd` | Interactive PRD -> sized task files in backlog |
| `release` | Release preparation with checklist and changelog |
| `api-design` | Design API contracts with OpenAPI specifications |
| `data-model` | Design database schemas, migrations, and data access layers |
| `performance-audit` | Profile and optimize performance bottlenecks |
| `incident-response` | Structured incident investigation and resolution |
| `refactor` | Analyze codebase for technical debt and plan refactoring |
| `migrate` | Plan and execute database schema migrations safely |
| `dependency-audit` | Audit dependencies for vulnerabilities and plan upgrades |

---

## Execution Principles

- **Spec-First**: Before writing non-trivial code, verify a technical spec exists. If not, create one first. Cross-reference implementation against spec at each step.
- **Concurrency**: Execute tasks concurrently where possible.
- **User Approval**: Always get user approval before implementing significant changes. Present your plan first.
- **Quality Gates**: Run quality gates defined in `.claude/rules/agent-guide.md` after every significant change. Never skip tests.

---

## Key Files

| File | Purpose |
|------|---------|
| `.claude/rules/agent-guide.md` | Project-specific configuration, tech stack, quality gates |
| `.claude/rules/spec-first.md` | When and how to create technical specs |
| `docs/spec/.llm/STRATEGY.md` | Task decomposition and dependency ordering |
| `docs/spec/.llm/PROGRESS.md` | Decisions, patterns, and learnings log |
| `docs/spec/.llm/tasks/backlog/` | Task queue |
| `docs/spec/.llm/templates/` | Plan templates for different task types |
| `docs/spec/biz/` | Business specifications and PRDs |
