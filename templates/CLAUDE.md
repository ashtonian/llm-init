# Claude Code Instructions for {{PROJECT_NAME}}

## Mandatory Workflow

**Before starting ANY task, you MUST read and follow `docs/spec/LLM.md`.**

This is the LLM Orchestration Guide — it defines:
- How to understand and classify your task
- The required reading order for spec files (framework -> biz)
- The plan.llm coordination workflow
- Conflict prevention rules for concurrent work
- The review loop and iteration protocol
- Knowledge accumulation via PROGRESS.md

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

### For TODO/Spec Review Tasks

When asked to address TODOs or review specs:
1. Follow the reading order in LLM.md
2. Create a plan.llm tracking which files you'll review/modify
3. Read framework specs, then business specs as needed
4. Address TODOs in context, not in isolation

### Key References

- **LLM Orchestration Guide**: `docs/spec/LLM.md`
- **LLM Style Guide**: `docs/spec/LLM-STYLE-GUIDE.md`
- **Progress & Learnings**: `docs/spec/.llm/PROGRESS.md`
- **Plan Templates**: `docs/spec/.llm/templates/`
- **Go Code Guide**: `docs/spec/framework/go-generation-guide.md` (read before writing ANY Go code)
- **TypeScript/UI Guide**: `docs/spec/framework/typescript-ui-guide.md` (read before writing ANY frontend code)
- **Performance Guide**: `docs/spec/framework/performance-guide.md` (read before writing performance-sensitive code)
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
