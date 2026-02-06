# Claude Code Instructions for {{PROJECT_NAME}}

## Execution Modes

| Mode | When | How |
|------|------|-----|
| **Parallel** (default) | Multi-step features, build work, any task with 2+ independent subtasks | Decompose → task files → launch agents |
| **Interactive** | Complex decisions, ambiguous requirements, user wants to pair, initial project setup | Plan file workflow, step-by-step with user |
| **Quick** | Trivial fixes, one-liners, small edits | Just do it — no plans or tasks needed |
| **Idea Pipeline** | Starting from scratch, 0→100 | Interactive for Research/Spec/Plan, then Parallel for Build |

### Mode Keywords

| To activate... | User says... |
|----------------|-------------|
| **Parallel** (default) | Any multi-step request, or: "go parallel", "fan out", "batch it", "go wild" |
| **Interactive** | "interactive", "walk me through", "step by step", "let's think about", "guide me", "let's pair" |
| **Quick** | "just do it", "quick fix", "small change", "one-liner", "trivial" |
| **Idea Pipeline** | "I have an idea", "start from scratch", "build me a...", "0 to 100" |
| **Shelve** | "shelve", "save state", "checkpoint", "pause this", "save progress" |

### Auto-Escalation to Interactive

Switch from Parallel to Interactive automatically when:
- Requirements are ambiguous and can't be clarified from specs
- Cannot decompose into 2+ independent subtasks
- Irreversible external actions needed (deployments, migrations)
- User expresses uncertainty ("I'm not sure", "what do you think")
- Brand-new project with empty `AGENT_GUIDE.md` (use Interactive for initial setup)

---

## Parallel Workflow (Default)

**Before starting ANY task, read `docs/spec/LLM.md` and `docs/spec/.llm/PROGRESS.md`.**

### 7-Step Lifecycle

1. **Read context** — `PROGRESS.md` (codebase patterns), relevant specs, `STRATEGY.md`
2. **Decompose** into 2-8 independent subtasks (75-150 turns each, wide not deep, explicit deps)
3. **Create task files** in `docs/spec/.llm/tasks/backlog/` from the template
4. **Prepare agent context** — edit `AGENT_GUIDE.md` (project description, tech stack, quality gates) and `STRATEGY.md` (decomposition)
5. **Present decomposition to user** — show task list, dependencies, estimated scope. Wait for approval
6. **Launch agents** — `bash docs/spec/.llm/scripts/run-parallel.sh N`
7. **Monitor** — `bash docs/spec/.llm/scripts/status.sh`

### Decomposition Rules

- **Size**: 75-150 Claude turns per task. Too small = overhead; too large = context exhaustion
- **Shape**: Wide not deep — prefer many independent tasks over long dependency chains
- **Dependencies**: Use `## Dependencies: Tasks 01, 02` format. Minimize chains
- **Verification**: Each task must have its own `## Verification` commands
- **Completeness**: Every subtask must be self-contained enough that an agent with no prior context can execute it

### Quick Reference

```bash
# Create tasks from template
cp docs/spec/.llm/templates/task.template.md docs/spec/.llm/tasks/backlog/01-my-task.md

# Launch N parallel agents
bash docs/spec/.llm/scripts/run-parallel.sh 3

# Run a single task autonomously
bash docs/spec/.llm/scripts/run-single-task.sh 01-my-task.md

# Run a task interactively (with approval prompts)
bash docs/spec/.llm/scripts/run-interactive.sh 01-my-task.md

# Check task queue status
bash docs/spec/.llm/scripts/status.sh

# Reset all tasks to backlog
bash docs/spec/.llm/scripts/reset.sh
```

See `docs/spec/.llm/README.md` for full harness documentation. Edit `docs/spec/.llm/AGENT_GUIDE.md` and `docs/spec/.llm/STRATEGY.md` before running agents.

---

## Interactive Workflow

Use Interactive mode when auto-escalation triggers or the user explicitly requests it.

### Task Start Checklist

1. **Read `docs/spec/LLM.md`** — the master entry point
2. **Read `docs/spec/.llm/PROGRESS.md`** — learn from previous iterations (Codebase Patterns section)
3. **Classify your task** using the Quick Start table in LLM.md
4. **Read foundation specs in order** as specified in the Execution Order section
5. **Create a plan.llm file** at `docs/spec/.llm/plans/{feature-name}.plan.llm` before starting significant work
6. **Follow the plan file format** defined in LLM.md
7. **Get user approval** before implementing — present your plan and wait for confirmation

### Starting from an Idea (0→100)

If the user gives you just an idea and wants a full project built:
1. Use the idea template: `cp docs/spec/.llm/templates/idea.plan.llm docs/spec/.llm/plans/{idea}.plan.llm`
2. Follow the [Idea to Project Pipeline](docs/spec/LLM.md#idea-to-project-pipeline) in LLM.md
3. **Present findings to the user at each checkpoint** — do not skip approval gates
4. Research → Spec → Plan → Scaffold → Build (with user approval at each transition)

**Mode Transitions**: Phases 1-3 (Research, Spec, Plan) = Interactive. Phase 4 (Scaffold) = Quick. Phase 5 (Build) = switch to Parallel.

### For TODO/Spec Review Tasks

When asked to address TODOs or review specs:
1. Follow the reading order in LLM.md
2. Create a plan.llm tracking which files you'll review/modify
3. Read framework specs, then business specs as needed
4. Address TODOs in context, not in isolation

---

## Quick Mode

For trivial changes — no plans, no task files, no decomposition needed.

Just make the change, run quality gates, and commit.

---

## Agent State Shelving

Agents can checkpoint their progress so work survives restarts. Use shelving when:
- An agent is running low on context/turns
- You need to stop and resume later
- Work should transfer to a different agent

### How It Works

1. Agent outputs `TASK_SHELVED` followed by a structured handoff state
2. The harness writes the handoff into the task file's `## Handoff State` section
3. WIP is committed on the task branch
4. Task returns to `backlog/` — the next agent picks it up with full context

### User Commands

| To... | Say... |
|-------|--------|
| Shelve current work | "shelve", "save state", "checkpoint", "pause this" |
| Resume shelved work | "resume", "pick up where we left off", "continue" |
| Check what's shelved | Run `bash docs/spec/.llm/scripts/status.sh` |

### Handoff State Format

When shelving, the agent records:
- **Completed Steps** — what's done
- **Current Step** — what was in progress
- **Files Modified** — changed files list
- **Key Decisions** — design choices made
- **Known Issues** — problems for the next agent
- **Next Actions** — where to pick up

---

## Key References

- **LLM Orchestration Guide**: `docs/spec/LLM.md`
- **LLM Style Guide**: `docs/spec/LLM-STYLE-GUIDE.md`
- **Progress & Learnings**: `docs/spec/.llm/PROGRESS.md`
- **Plan Templates**: `docs/spec/.llm/templates/`
- **Task Template**: `docs/spec/.llm/templates/task.template.md`
- **Harness Documentation**: `docs/spec/.llm/README.md`
- **Agent Guide**: `docs/spec/.llm/AGENT_GUIDE.md`
- **Strategy (Decomposition)**: `docs/spec/.llm/STRATEGY.md`
- **Go Code Guide**: `docs/spec/framework/go-generation-guide.md` (read before writing ANY Go code)
- **TypeScript/UI Guide**: `docs/spec/framework/typescript-ui-guide.md` (read before writing ANY frontend code)
- **Performance Guide**: `docs/spec/framework/performance-guide.md` (read before writing performance-sensitive code)
- **Testing Guide**: `docs/spec/framework/testing-guide.md` (read before writing tests)
- **Business Features Guide**: `docs/spec/biz/README.md` (read before writing business specs)
- **Infrastructure**: `docs/spec/.llm/INFRASTRUCTURE.md` (Docker services, ports, health checks)
- **MCP Servers**: `docs/spec/.llm/MCP-RECOMMENDATIONS.md` (available MCP servers and config)

## Execution Principles

### Concurrency
- **Execute tasks concurrently where possible.** Use parallel tool calls, parallel subagents, and concurrent operations whenever tasks are independent.
- When tasks have no data dependencies between them, run them simultaneously.
- Use the Task tool to spawn subagents for independent workstreams.
- Prefer `errgroup` patterns in Go code for parallel I/O.

### User Feedback
- **Always get user approval before implementing significant changes.** Present your plan first.
- At major milestones (spec complete, feature complete, etc.), present results for review.
- If unsure about a design decision, ask the user rather than guessing.
- Record user decisions in the plan file for future reference.

### Quality Gates
- Every piece of code must build, pass tests, and pass lint before being considered complete.
- Run `go test -race ./...` for Go code.
- Run `npm run build && npm run test && npm run lint` for TypeScript/frontend code.
- Run quality gates after every significant change, not just at the end.
- Never skip tests or ignore failures.
- If quality gates fail 3+ times on the same issue, stop and escalate to the human.

### Self-Improvement
- If you discover a pattern, convention, or gotcha, **update `docs/spec/.llm/PROGRESS.md`** immediately.
- If a spec is wrong, incomplete, or could be improved, **update the spec**.
- If the LLM orchestration system itself could be better, **propose or make the improvement**.
- You are encouraged to iterate on the documentation and tooling to make future work more efficient.

## Scratch Workspace

You may create a scratch directory for temporary working files:

```bash
mkdir -p .llm-scratch
```

Use `.llm-scratch/` for:
- Temporary scripts, data files, or intermediate outputs
- Debugging artifacts
- Draft content before moving to final locations
- Any working files that don't belong in the source tree

This directory is gitignored. Clean it up when done.

## Infrastructure

- PostgreSQL: `postgresql://{{PROJECT_NAME}}:{{PROJECT_NAME}}@localhost:5432/{{PROJECT_NAME}}`
- Redis: `redis://localhost:6379`
- NATS: `nats://localhost:4222`
- Start infra: `docker compose -f docs/spec/.llm/docker-compose.yml up -d`

## Permissions

You have pre-approved permissions for all standard development operations including:
- Go toolchain, build tools, Docker, Git, GitHub CLI
- Node/npm/pnpm/yarn, TypeScript tools, linters, test runners
- File operations, web fetch, web search, subagent spawning
- MCP server tools (github, postgres, redis, sequential-thinking, context7, playwright)
- Python scripts, curl for localhost, process management

See `.claude/settings.json` for the full list. If you need a command that isn't pre-approved, explain why and ask.
