# test-project — Agent Skills & Capabilities

> One-stop reference for all commands, tools, scripts, and workflows available to agents working on test-project.

---

## Custom Commands

Type these as slash commands in Claude Code (e.g., `/decompose Build user management`).

| Command | Purpose | Input |
|---------|---------|-------|
| `/decompose` | Break a request into 2-8 parallel tasks | Feature description |
| `/new-task` | Create a single task file in the backlog | Task description |
| `/status` | Task queue dashboard with analysis | _(none)_ |
| `/launch` | Pre-flight checks + launch parallel agents | Optional: number of agents |
| `/plan` | Select a plan template and create a plan file | Feature or task description |
| `/review` | Run quality gates, check conventions | _(none)_ |
| `/shelve` | Checkpoint work with structured handoff | _(none)_ |
| `/requirements` | Iterative requirement gathering → package spec | Feature or package description |
| `/architecture-review` | Assess decisions, tradeoffs, edge cases | Optional: scope to review |
| `/adr` | Create Architecture Decision Record | Decision topic |
| `/security-review` | Security assessment of codebase/feature | Optional: scope to review |
| `/prd` | Interactive PRD → sized tasks | Feature description |
| `/release` | Release prep with checklist and changelog | Optional: version number |

### Command Selection

```
What do you need to do?
│
├── Quick PRD → task pipeline? ──────> /prd
├── Start a big feature? ──────────> /decompose
├── Add one task to the queue? ────> /new-task
├── Check progress? ───────────────> /status
├── Ready to run agents? ──────────> /launch
├── Need a plan first? ───────────> /plan
├── Done working, check quality? ──> /review
├── Need to pause? ────────────────> /shelve
├── Gather requirements? ──────────> /requirements
├── Review architecture? ──────────> /architecture-review
├── Document a decision? ──────────> /adr
├── Security check? ───────────────> /security-review
└── Prepare a release? ────────────> /release
```

---

## MCP Server Capabilities

Configured in `.mcp.json`. These give agents direct tool access to external systems.

| Server | What It Provides | Requires Infrastructure |
|--------|-----------------|------------------------|
| **github** | Issues, PRs, reviews, repository operations | No (needs `GITHUB_PERSONAL_ACCESS_TOKEN`) |
| **postgres** | SQL queries, schema inspection, data operations | Yes (Docker) |
| **redis** | Cache read/write, key inspection | Yes (Docker) |
| **sequential-thinking** | Step-by-step reasoning for complex problems | No |
| **context7** | Current library/framework documentation lookup | No |
| **playwright** | Browser automation, E2E testing, visual verification | No |

### When to Use MCP vs CLI

| Need | MCP Server | CLI Alternative |
|------|-----------|----------------|
| Query database | `postgres` MCP | `docker exec ... psql` |
| Read/write cache | `redis` MCP | `docker exec ... redis-cli` |
| GitHub operations | `github` MCP | `gh` CLI |
| Library docs | `context7` MCP | Web search |
| Browser testing | `playwright` MCP | `npx playwright test` |

---

## Script Capabilities

All scripts are in `docs/spec/.llm/scripts/`.

| Script | Purpose | Example |
|--------|---------|---------|
| `run-parallel.sh [N]` | Launch N autonomous agents | `bash docs/spec/.llm/scripts/run-parallel.sh 3` |
| `run-agent.sh [name]` | Single autonomous agent loop | `bash docs/spec/.llm/scripts/run-agent.sh agent-01` |
| `run-single-task.sh <file>` | Run one task autonomously (75 turns) | `bash docs/spec/.llm/scripts/run-single-task.sh 01-setup.md` |
| `run-interactive.sh <file>` | Interactive session with task context | `bash docs/spec/.llm/scripts/run-interactive.sh 01-setup.md` |
| `status.sh` | Task queue dashboard | `bash docs/spec/.llm/scripts/status.sh` |
| `reset.sh` | Move all tasks to backlog, clear locks | `bash docs/spec/.llm/scripts/reset.sh` |
| `run-fresh-loop.sh [N]` | Fresh-context loop (new instance per task) | `bash docs/spec/.llm/scripts/run-fresh-loop.sh` |
| `archive.sh [desc]` | Archive completed tasks and logs | `bash docs/spec/.llm/scripts/archive.sh "phase-1"` |
| `move_nav_to_top.py` | Reformat docs (move LLM nav to top) | `python3 docs/spec/.llm/scripts/move_nav_to_top.py` |

---

## Agent Roles

Roles provide specialized focus for agents. Templates are in `templates/roles/`.

| Role | Focus | Use When |
|------|-------|----------|
| `implementer` | Feature implementation, spec compliance, production code | Building new features |
| `reviewer` | Code quality, pattern consistency, spec drift detection | Quality passes, post-implementation |
| `optimizer` | Performance, deduplication, dead code removal | Performance tuning, cleanup |
| `docs` | Documentation accuracy, spec updates, PROGRESS.md curation | Doc maintenance, cross-reference audits |
| `tester` | Test coverage, edge cases, failure modes | Hardening test suite |
| `benchmarker` | Profiling, benchmarks, regression detection | Performance measurement |
| `architect` | System design, boundaries, tradeoff analysis | Design decisions |
| `security` | Vulnerability detection, input validation, auth | Security audits |
| `debugger` | Root cause analysis, failure investigation | Blocked tasks, regressions |

### Usage

```bash
# Single agent with role
AGENT_ROLE=reviewer bash docs/spec/.llm/scripts/run-agent.sh reviewer-01

# Parallel agents with roles
bash docs/spec/.llm/scripts/run-parallel.sh --roles implementer,implementer,reviewer,docs 4
```

### Role Composition Examples

```bash
# Standard build:     implementer,implementer,tester,reviewer
# Performance build:  implementer,benchmarker,optimizer,reviewer
# Design phase:       architect,security,implementer
# Hardening:          tester,security,reviewer,docs
# Investigation:      debugger,implementer
```

When no role is assigned, agents operate as general-purpose (default behavior, unchanged).

---

## Plan Template Selection

Templates are in `docs/spec/.llm/templates/`.

| Template | Use When | Phases |
|----------|----------|--------|
| `idea.plan.llm` | Starting from scratch (0→100) | Research → Spec → Plan → Scaffold → Build |
| `fullstack.plan.llm` | Full-stack feature (DB→API→UI→E2E) | DB → Service → API → Frontend → E2E |
| `feature.plan.llm` | Backend-focused feature | 6 implementation phases |
| `review.plan.llm` | Review/iteration cycle | Read → Assess → Implement → Verify → Record |
| `bugfix.plan.llm` | Bug investigation and fix | Reproduce → Root cause → Fix → Regression test |
| `self-review.plan.llm` | Audit the LLM system itself | Cross-refs → Workflows → Completeness → Efficiency |
| `codegen.plan.llm` | Spec-first code generation | Analyze → Spec → Plan → Implement → Verify |
| `requirements.plan.llm` | Multi-session requirement gathering | Discovery → Use Cases → Data → NFRs → Decisions → Spec |
| `plan.template.llm` | Generic — anything else | Customizable |
| `task.template.md` | Task file for the parallel queue | Single task format (not a plan) |

---

## Quality Gate Patterns

Quality gates are defined per-project in `docs/spec/.llm/AGENT_GUIDE.md`. Common patterns:

```bash
# Go
# go build ./... && go test -race ./... && go vet ./...

# TypeScript
# npm run build && npm run test && npm run lint

# Python
# pytest && mypy . && ruff check .

# Full-stack
# make build && make test && make lint
```

> **Note**: Always check `AGENT_GUIDE.md` for this project's actual quality gates.

---

## Model Selection

| Model | Best For | Turn Budget |
|-------|----------|-------------|
| **Opus** | Complex planning, architecture, ambiguous tasks | 75-100 turns |
| **Sonnet** | Standard implementation, code generation | 100-150 turns |
| **Haiku** | Mechanical tasks, formatting, renaming, simple fixes | 50-75 turns |

Pass `--model` to `claude` in `run-agent.sh` or set in your task file header. Example: `## Model: haiku`

---

## Hooks (Advanced)

Claude Code supports hooks — shell commands that run before/after tool calls. Configure in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse:Write": "npx eslint --fix $FILE_PATH"
  }
}
```

Useful for auto-formatting, auto-linting, or custom validation after file writes. See Claude Code docs for the full hook configuration reference.

---

## Workflow Decision Tree

```
Incoming request
│
├── Trivial fix / one-liner?
│   └── Quick mode ─── just do it, run quality gates, commit
│
├── Ambiguous / needs discussion?
│   └── Interactive mode ─── /plan → create plan file → work step-by-step
│
├── Need to gather requirements first?
│   └── /requirements → iterative Q&A → produce spec → /plan or /decompose
│
├── Multi-step feature?
│   ├── Can decompose into 2+ independent tasks?
│   │   └── Parallel mode ─── /decompose → /launch
│   └── Cannot decompose?
│       └── Interactive mode ─── /plan → work step-by-step
│
├── Starting from an idea (0→100)?
│   └── Idea Pipeline ─── /plan (idea template)
│       Interactive for Research/Spec/Plan → Parallel for Build
│
├── Review / check quality?
│   └── /review
│
├── Review architecture?
│   └── /architecture-review → assess decisions → /adr for documentation
│
├── Security assessment?
│   └── /security-review
│
├── Prepare a release?
│   └── /release → checklist → changelog → tag
│
└── Need to pause?
    └── /shelve
```

---

## Key Documentation Map

| Document | Read When... |
|----------|-------------|
| `CLAUDE.md` | Auto-loaded every session. Entry point. |
| `docs/spec/LLM.md` | Starting any significant task. Master orchestration guide. |
| `docs/spec/.llm/PROGRESS.md` | Before starting any work. Cross-iteration memory. |
| `docs/spec/.llm/STRATEGY.md` | Decomposing work into tasks. Project phases. |
| `docs/spec/.llm/AGENT_GUIDE.md` | Before running agents. Tech stack, quality gates. |
| `docs/spec/framework/go-generation-guide.md` | Before writing any Go code. |
| `docs/spec/framework/typescript-ui-guide.md` | Before writing any frontend code. |
| `docs/spec/framework/performance-guide.md` | For performance-sensitive work. |
| `docs/spec/framework/testing-guide.md` | Before writing tests. |
| `docs/spec/SPEC-WRITING-GUIDE.md` | Creating a new spec document. |
| `docs/spec/LLM-STYLE-GUIDE.md` | Formatting LLM navigation sections. |
| `docs/spec/.llm/INFRASTRUCTURE.md` | Docker services, ports, health checks. |
| `docs/spec/.llm/MCP-RECOMMENDATIONS.md` | Configuring or adding MCP servers. |

---

## Related Documentation

- [CLAUDE.md](../../../CLAUDE.md) — Claude Code instructions (auto-loaded)
- [LLM Orchestration Guide](../LLM.md) — Master entry point for LLMs
- [Progress & Learnings](./PROGRESS.md) — Accumulated knowledge from all iterations
- [Coordination Guide](./README.md) — Plan files, task queue, agent coordination
- [Strategy](./STRATEGY.md) — Project decomposition for parallel agents
- [Agent Guide](./AGENT_GUIDE.md) — Agent context inlined into every prompt
