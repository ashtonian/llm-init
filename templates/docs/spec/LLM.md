# LLM Orchestration Guide

> **START HERE**: This is the entry point for any LLM working on the {{PROJECT_NAME}} platform. Read this document first before any other.

---

## Quick Start for LLMs

### 1. Understand Your Task Type

| Task Type | Action |
|-----------|--------|
| **Multi-step feature or build work** | **Default: Parallel mode.** Decompose → task files → launch agents. See [Parallel Agent Harness](#parallel-agent-harness) |
| **Starting from an idea (0→100)** | See [Idea to Project Pipeline](#idea-to-project-pipeline) — Interactive for Research/Spec/Plan, then Parallel for Build |
| **Writing any Go code** | Read `framework/go-generation-guide.md` first (mandatory) |
| **Writing any frontend/UI code** | Read `framework/typescript-ui-guide.md` first (mandatory) |
| **Performance-sensitive work** | Read `framework/performance-guide.md` first (mandatory) |
| **Complex decisions / guided session** | Use Interactive mode — create a plan.llm file, work step-by-step with user |
| **Bug fix / small change** | Quick mode — read relevant spec, make the fix, no plan needed |
| **Creating a new spec** | Read `SPEC-WRITING-GUIDE.md` for templates and depth expectations |
| **Business feature planning** | Read `biz/README.md` for business spec templates |
| **Research / exploration** | Use the [Navigation Index](#navigation-index) |
| **Review / iteration cycle** | See [Review Loop Protocol](#review-loop-protocol) |
| **Improve the LLM system itself** | See [Self-Improvement Protocol](#self-improvement-protocol) + `.llm/templates/self-review.plan.llm` |

### 2. Read Previous Learnings

Before starting work, **always read `docs/spec/.llm/PROGRESS.md`** — specifically the **Codebase Patterns** section at the top. This contains accumulated knowledge from previous iterations that will save you time and prevent repeated mistakes.

### 3. Create or Claim a Plan File

Before starting work on any significant task:

```bash
# Create: docs/spec/.llm/plans/{feature-name}.plan.llm
# Or claim an existing plan by adding your agent ID
```

See [Plan File Format](#plan-file-format) for template.

### 4. Follow Execution Order

For new features, specs must be read in a specific order. See [Execution Order](#execution-order).

### 5. Update Progress When Done

After completing work, **always update `docs/spec/.llm/PROGRESS.md`**:
- Add discovered patterns to the **Codebase Patterns** section
- Append an entry to the **Iteration Log** with what you did and what you learned

---

## Repository Structure

```
docs/spec/
├── LLM.md                    # <- YOU ARE HERE (start point for LLMs)
├── LLM-STYLE-GUIDE.md        # How to format LLM navigation sections
├── SPEC-WRITING-GUIDE.md     # How to write specification documents
├── README.md                 # Human-readable index
├── llms.txt                  # Quick navigation index
├── .llm/                     # LLM coordination (plans, tasks, status)
│   ├── README.md             # Coordination guide
│   ├── PROGRESS.md           # Accumulated knowledge and iteration log
│   ├── STRATEGY.md           # Project decomposition for parallel agents
│   ├── AGENT_GUIDE.md        # Agent context (inlined into every prompt)
│   ├── INFRASTRUCTURE.md     # Docker services documentation
│   ├── MCP-RECOMMENDATIONS.md # MCP server recommendations
│   ├── SKILLS.md             # Agent skills and capabilities catalog
│   ├── docker-compose.yml    # PostgreSQL 16, Redis 7, NATS 2
│   ├── nats.conf             # NATS JetStream config
│   ├── plans/                # Active plan.llm files
│   ├── completed/            # Completed plan files (archive)
│   ├── templates/            # Plan + task templates
│   ├── scripts/              # Utility + agent harness scripts
│   ├── tasks/                # Parallel agent task queue
│   │   ├── backlog/          # Tasks ready to be claimed
│   │   ├── in_progress/      # Currently being worked on
│   │   ├── completed/        # Successfully finished
│   │   └── blocked/          # Failed or blocked
│   └── logs/                 # Agent execution logs
├── framework/                # Generic patterns (read first)
│   ├── README.md             # Framework spec index
│   ├── go-generation-guide.md
│   ├── typescript-ui-guide.md
│   ├── performance-guide.md
│   ├── testing-guide.md
│   └── llms.txt              # Framework navigation index
└── biz/                      # Business specs (features, research, decisions)
```

### Spec Layers (Read Order)

```
+-----------------------------------------------------------------+
| Framework Specs (framework/)                                     |
|   Foundations: API design, auth, models, errors, data access     |
|   READ FIRST - all other specs depend on these                   |
+-----------------------------------------------------------------+
                              | informs
                              v
+-----------------------------------------------------------------+
| Business Specs (biz/)                                            |
|   Feature requirements, market research, business decisions      |
|   READ AS NEEDED for business context                            |
+-----------------------------------------------------------------+
```

---

## Idea to Project Pipeline

When the user gives you just an idea and wants to go from 0 to a working project, follow this pipeline. **User approval is required at each checkpoint.**

```
┌─────────────────────────────────────────────────────────┐
│ 1. RESEARCH: Understand the domain, competitors,        │
│    technology options. Summarize findings.               │
│                                                         │
│    >>> USER CHECKPOINT: Present research, get feedback   │
├─────────────────────────────────────────────────────────┤
│ 2. SPEC: Create business spec (biz/), technical         │
│    architecture, framework specs as needed.              │
│                                                         │
│    >>> USER CHECKPOINT: Review specs, approve approach   │
├─────────────────────────────────────────────────────────┤
│ 3. PLAN: Break into milestones, create plan.llm files,  │
│    define execution order and parallel work strategy.    │
│                                                         │
│    >>> USER CHECKPOINT: Approve implementation plan      │
├─────────────────────────────────────────────────────────┤
│ 4. SCAFFOLD: Initialize project, set up tooling,        │
│    configure infrastructure, verify builds clean.        │
├─────────────────────────────────────────────────────────┤
│ 5. BUILD: Execute plans using the Review Loop Protocol.  │
│    One focused item per iteration. Quality gates at      │
│    each step.                                           │
│                                                         │
│    >>> USER CHECKPOINT: Review at each milestone         │
└─────────────────────────────────────────────────────────┘
```

### Mode Transitions

Phases 1-3 (Research, Spec, Plan) = **Interactive** mode. Phase 4 (Scaffold) = **Quick** mode. Phase 5 (Build) = switch to **Parallel** mode — decompose the build plan into task files and launch agents.

### Using the Idea Template

```bash
cp docs/spec/.llm/templates/idea.plan.llm docs/spec/.llm/plans/{idea-name}.plan.llm
```

### User Feedback Gates

**Every plan template includes user approval checkpoints.** The agent must:

1. **Present** — Show the user what was planned/researched/built
2. **Wait** — Do not proceed until the user confirms
3. **Incorporate** — Apply any feedback before moving forward
4. **Record** — Document user decisions in the plan file

This applies at every major transition: research→spec, spec→plan, plan→build, and at milestone completions.

---

## Execution Order

### Foundation Specs (Read First for Any Task)

These specs define conventions used throughout. Read them once at session start.

| Order | Spec | Why |
|-------|------|-----|
| 0 | `framework/go-generation-guide.md` | **Mandatory** Go code patterns, idioms, and conventions |
| 0 | `framework/typescript-ui-guide.md` | **Mandatory** TypeScript/UI patterns (if doing frontend work) |
| 0 | `framework/performance-guide.md` | **Mandatory** Performance and code quality standards |

> **Note**: As you create additional framework specs (see `SPEC-WRITING-GUIDE.md`), add them to this table. Suggested specs to create:
>
> | Order | Spec to Create | Purpose |
> |-------|----------------|---------|
> | 1 | `framework/api-design.md` | REST conventions, model patterns, pagination |
> | 2 | `framework/error-handling.md` | Error codes, HTTP status mapping |
> | 3 | `framework/models.md` | Entity patterns, soft delete, versioning |
> | 4 | `framework/data-access.md` | Repository patterns, database integration |

### Feature-Specific Execution Orders

<!-- Add execution orders as you create specs. Example:

#### Building API Endpoints

```
1. framework/api-design.md        -> Conventions
2. framework/routes.md            -> Route patterns
3. framework/error-handling.md    -> Error responses
4. framework/data-access.md       -> Database layer
```

#### Building UI Features

```
1. framework/typescript-ui-guide.md -> Component patterns, accessibility
2. framework/performance-guide.md   -> Performance budgets
3. framework/api-design.md          -> API shapes to consume
```

-->

---

## Concurrent Execution

Multiple LLMs can work simultaneously. **Prefer concurrent execution whenever possible.**

### Concurrency Rules

1. **Claim before work**: Create or claim a plan.llm file before starting
2. **Lock files in use**: Add your agent ID to files you're modifying
3. **Check for conflicts**: Read active plans before starting
4. **Update status**: Mark progress in your plan.llm file
5. **Use parallel tool calls**: When making multiple independent reads, searches, or operations, execute them simultaneously
6. **Spawn subagents**: Use the Task tool to handle independent workstreams in parallel
7. **Use feature branches**: Each agent/plan should work on its own git branch (`feature/{plan-name}`)
8. **Heartbeat**: Update `last_active` timestamp in your plan metadata when starting each iteration

### Work Division Strategies

| Strategy | When to Use | Example |
|----------|-------------|---------|
| **By Layer** | Building full stack | One agent on API, one on frontend, one on tests |
| **By Feature** | Multiple independent features | Each agent implements a complete vertical slice |
| **By Component** | Single large feature | Split: database, service, API handler, tests |
| **By Phase** | Sequential pipeline | Design -> implement -> test -> document |

### Parallel Execution Patterns

```
# Independent tasks — run simultaneously
Agent A: Implement user service
Agent B: Implement device service
Agent C: Write integration test framework

# Pipeline tasks — run sequentially
Phase 1: Database migrations (Agent A)
Phase 2: Service layer (Agent A + B, split by entity)
Phase 3: API handlers (Agent A + B, split by entity)
Phase 4: Tests (Agent C)
```

### Branching Strategy

Each plan should work on its own feature branch to avoid merge conflicts:

```bash
# Create a branch for your plan
git checkout -b feature/{plan-name}

# When done, create a PR or merge
git checkout main && git merge feature/{plan-name}
```

This allows multiple agents to work simultaneously without stepping on each other's files.

### Agent Identity

When claiming a plan, use a descriptive agent ID:
- Format: `{task-type}-{short-hash}` (e.g., `feature-a1b2c3`, `review-x4y5z6`)
- The ID must be unique across all active plans
- Add it to the plan's Metadata section

### Conflict Prevention

```
# In your plan.llm file, declare files you'll modify:
## Files to Modify
- [ ] path/to/file (CLAIMED by agent-abc123)
```

---

## Parallel Agent Harness

For fire-and-forget batch execution, the parallel agent harness provides task queue management, git worktree isolation, and automatic merging.

### When to Use

| Mode | When | How |
|------|------|-----|
| **Parallel** (default) | Multi-step features, build work, 2+ independent subtasks | Decompose → task files in `tasks/backlog/` → `run-parallel.sh` |
| **Interactive** | Complex decisions, ambiguous requirements, user-guided sessions | Create a `.plan.llm` file, work step-by-step with user |
| **Quick** | Bug fixes, one-liners, trivial edits | Just do it — no plans or tasks needed |

**Auto-escalate to Interactive when**: requirements are ambiguous, can't decompose into 2+ subtasks, irreversible external actions needed, user expresses uncertainty, or project has empty `AGENT_GUIDE.md`.

Both modes share `PROGRESS.md` for cross-iteration memory.

### Setup Steps

1. **Edit `STRATEGY.md`** — Decompose your project into phases and tasks
2. **Edit `AGENT_GUIDE.md`** — Add project description, tech stack, quality gates
3. **Create task files** — Copy `templates/task.template.md` to `tasks/backlog/NN-name.md`
4. **Launch agents** — `bash docs/spec/.llm/scripts/run-parallel.sh 3`

### Task Design Guidelines

- **Size tasks for 75-150 Claude turns.** Too small = overhead; too large = context exhaustion.
- **Explicit dependencies** — Use `## Dependencies: Tasks 01, 02` format. Tasks with unmet dependencies are skipped.
- **Independent verification** — Each task should have its own `## Verification` commands.
- **Wide not deep** — Prefer many independent tasks over long dependency chains to maximize parallelism.

### Architecture

```
run-parallel.sh
  └── spawns N instances of run-agent.sh (staggered by 5s)
        └── each agent loops:
              1. Scan tasks/backlog/ for next eligible task (dependencies met)
              2. Claim atomically via mkdir lock
              3. Move task to tasks/in_progress/
              4. Create/sync git worktree
              5. Build prompt: agent identity + AGENT_GUIDE.md + PROGRESS.md + task content
              6. Spawn: claude --print --max-turns N --dangerously-skip-permissions
              7. On TASK_COMPLETE: commit, merge --no-ff to master, update PROGRESS.md, move to tasks/completed/
              8. On TASK_SHELVED: write handoff state to task, commit WIP, return to tasks/backlog/
              9. On TASK_BLOCKED or failure: move to tasks/blocked/, release lock, continue
              10. Repeat until no tasks remain or idle timeout
```

### Scripts Reference

| Script | Purpose | Default Turns |
|--------|---------|--------------|
| `run-parallel.sh [N]` | Launch N autonomous agents | 150 |
| `run-agent.sh [name]` | Single agent loop | 150 |
| `run-single-task.sh <file>` | One-shot single task | 75 |
| `run-interactive.sh <file>` | Interactive session with task context | — |
| `status.sh` | Task queue dashboard | — |
| `reset.sh` | Move all tasks back to backlog | — |

### Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `BRANCH_PREFIX` | `task/` | Git branch prefix for task branches |
| `MAX_TURNS` | `150` | Maximum Claude Code turns per task |
| `WAIT_INTERVAL` | `10` | Seconds between polling when no tasks available |
| `MAX_EMPTY_WAITS` | `60` | Idle cycles before agent shuts down (~10 min) |
| `SKIP_API_KEY_UNSET` | _(unset)_ | Set to `1` to keep `ANTHROPIC_API_KEY` (for API-key auth) |
| `SKIP_PERMISSIONS` | `1` | Set to `0` to use `.claude/settings.json` permissions instead of `--dangerously-skip-permissions` |

### Cross-Iteration Memory

Completed tasks append a summary to `PROGRESS.md`. Future agents read this at the start of every task, creating a continuous knowledge chain across all iterations and agents.

### Stale Plan Detection

Plans are considered stale if `last_active` hasn't been updated in 30 minutes. Before claiming a stale plan:
1. Check if the agent's branch has uncommitted work
2. If yes, preserve the branch and create a new plan
3. If no, you may reclaim the plan

### PROGRESS.md Write Protocol

Since multiple agents may write to PROGRESS.md:
1. **Read** the current content
2. **Append** your entry (don't modify existing content)
3. **Write** immediately (don't batch with other changes)
4. If you encounter a write conflict, re-read and retry

---

## Review Loop Protocol

Inspired by iterative agent patterns, the review loop ensures quality through repeated assessment and improvement cycles.

### How It Works

```
┌─────────────────────────────────────────┐
│ 1. READ: Load PROGRESS.md + relevant    │
│    specs for context                     │
├─────────────────────────────────────────┤
│ 2. ASSESS: Pick highest-priority        │
│    incomplete item from plan             │
├─────────────────────────────────────────┤
│ 3. IMPLEMENT: Make the change           │
│    (one focused item per iteration)      │
├─────────────────────────────────────────┤
│ 4. VERIFY: Run quality gates            │
│    (build, test, lint, type-check)       │
├─────────────────────────────────────────┤
│ 5. RECORD: Update PROGRESS.md with      │
│    learnings and iteration log           │
├─────────────────────────────────────────┤
│ 6. COMMIT: If quality gates pass,       │
│    commit the change                     │
├─────────────────────────────────────────┤
│ 7. NEXT: Return to step 2 for the next  │
│    item, or complete the plan            │
└─────────────────────────────────────────┘
```

### Key Principles

1. **One focused item per iteration**: Don't try to do everything at once. Implement one user story, one fix, or one component per cycle. This fits within context limits and isolates failures.

2. **Quality gates are mandatory**: Every iteration must pass build + test + lint before the item is marked complete. If gates fail, the item stays incomplete for the next iteration to address.

3. **Always record learnings**: Before completing an iteration, update `PROGRESS.md` with:
   - Patterns discovered
   - Gotchas and pitfalls encountered
   - Conventions that should be followed
   - What worked and what didn't

4. **Fresh context is an advantage**: Each new agent session starts clean but inherits accumulated knowledge from `PROGRESS.md`. This prevents context pollution and stale assumptions.

5. **Priority-based selection**: Always work on the highest-priority incomplete item. This ensures dependency ordering is respected naturally.

6. **Escape hatch**: If quality gates fail 3+ times on the same item with no progress, or if you exceed the plan's Max Iterations, **stop and escalate to the human**. Don't loop forever.

### Using the Review Template

For review/iteration work, use the review plan template:

```bash
cp docs/spec/.llm/templates/review.plan.llm docs/spec/.llm/plans/{task-name}.plan.llm
```

---

## Self-Improvement Protocol

The agent is encouraged to improve the LLM orchestration system itself.

### What You Can Improve

| Artifact | What to Improve |
|----------|-----------------|
| **Specs** | Fix errors, add missing patterns, improve examples, fill TODOs |
| **PROGRESS.md** | Add codebase patterns, consolidate learnings |
| **Plan templates** | Add new templates, improve existing ones |
| **LLM.md** (this file) | Add execution orders, navigation entries, improve workflows |
| **llms.txt** | Add new document references, update task flows |
| **CLAUDE.md** | Add project-specific instructions as they're discovered |
| **Custom Commands** | Add or improve custom commands in `.claude/commands/` |
| **SKILLS.md** | Update capabilities catalog when adding features |
| **Settings** | Suggest permission additions for new tools |

### How to Improve

1. **During work**: If you notice a spec is wrong or incomplete, fix it as part of your current task
2. **After work**: Update PROGRESS.md with learnings that would help future iterations
3. **Dedicated improvement**: Create a plan.llm for systematic spec improvement
4. **System self-review**: Periodically run a full system self-review using the self-review template:
   ```bash
   cp docs/spec/.llm/templates/self-review.plan.llm docs/spec/.llm/plans/self-review.plan.llm
   ```
   This checks cross-references, workflow consistency, documentation completeness, context efficiency, and overall effectiveness. Run this when you notice confusion, after adding many new specs, or when the system feels like it could work better.

### Guard Rails

- Don't break existing functionality when improving specs
- Don't remove information unless it's clearly wrong
- Add to the Codebase Patterns section in PROGRESS.md (don't replace it)
- Commit spec improvements separately from feature code

---

## Plan File Format

Create plan files at: `docs/spec/.llm/plans/{feature-name}.plan.llm`

```markdown
# Plan: {Feature Name}

## Metadata
- **Created**: {ISO timestamp}
- **Agent ID**: {your-agent-id}
- **Last Active**: {ISO timestamp — update each iteration}
- **Status**: planning | in_progress | blocked | completed
- **Branch**: feature/{plan-name}
- **Depends On**: {other plan files if any}

## Objective
{One sentence describing what this plan accomplishes}

## Specs Read
- [ ] framework/go-generation-guide.md
- [ ] {other specs as needed}

## Implementation Steps
- [ ] Step 1: {description}
- [ ] Step 2: {description}
- [ ] Step 3: {description}

## Files to Modify
- [ ] path/to/file (CLAIMED)

## Files Created
- [ ] path/to/new/file

## Decisions Made
- {Decision 1}: {rationale}

## Blockers
- {None | description of blocker}

## Progress Log
### {timestamp}
- {What was done}
- {Current status}

## Learnings
- {Patterns discovered during implementation}
- {Captured in PROGRESS.md: yes/no}
```

---

## Navigation Index

### By Task

| I want to... | Read these specs |
|--------------|------------------|
| Build a feature (default: parallel) | `.llm/templates/task.template.md` -> `.llm/STRATEGY.md` -> `.llm/README.md` (harness section) |
| Start from just an idea | `.llm/templates/idea.plan.llm` -> [Idea to Project Pipeline](#idea-to-project-pipeline) |
| Build a full-stack feature | `.llm/templates/fullstack.plan.llm` |
| Write any Go code | `framework/go-generation-guide.md` (always read first) |
| Write any frontend/UI code | `framework/typescript-ui-guide.md` (always read first) |
| Write performance-sensitive code | `framework/performance-guide.md` |
| Write tests | `framework/testing-guide.md` |
| Create a new spec | `SPEC-WRITING-GUIDE.md` |
| Write a business feature spec | `biz/README.md` |
| Understand spec patterns | `framework/README.md` -> `SPEC-WRITING-GUIDE.md` |
| Start a review/iteration cycle | `.llm/templates/review.plan.llm` -> `.llm/PROGRESS.md` |
| Improve the LLM orchestration system | `.llm/templates/self-review.plan.llm` |
| Check infrastructure status | `.llm/INFRASTRUCTURE.md` |
| Configure MCP servers | `.llm/MCP-RECOMMENDATIONS.md` |
| Run parallel autonomous agents | `.llm/README.md` (harness section) -> `.llm/STRATEGY.md` -> `.llm/AGENT_GUIDE.md` |
| Decompose a project into tasks | `.llm/STRATEGY.md` -> `.llm/templates/task.template.md` |
| Use a custom command | `.claude/commands/` -> `docs/spec/.llm/SKILLS.md` |

<!-- Add rows as you create framework specs. Suggested entries:
| Add an API endpoint | `framework/api-design.md` -> `framework/routes.md` |
| Add a new entity/model | `framework/models.md` -> `framework/data-access.md` |
| Handle errors properly | `framework/error-handling.md` |
| Add logging/metrics | `framework/observability.md` |
-->

### By Folder

| Folder | Purpose | Entry Point |
|--------|---------|-------------|
| `framework/` | Generic patterns | `framework/README.md` |
| `biz/` | Business specs | `biz/README.md` |
| `.llm/` | Agent coordination | `.llm/README.md` |

---

## Document Structure Convention

All spec files follow this structure:

```markdown
# {Title}

> **LLM Navigation**: {One-line summary for quick scanning}

## LLM Quick Reference
{Moved to TOP - task mapping, key sections, context loading}

---

## {Main Content Sections}
...

## Related Documentation
{Cross-references to other specs}
```

**Important**: LLM Navigation sections are at the TOP of each file, immediately after the title.

---

## Key Conventions Reference

| Aspect | Convention | Example |
|--------|------------|---------|
| IDs | UUIDv7 (time-ordered) | `018f6b1a-0b3c-7d4e-8f9a-1b2c3d4e5f6a` |
| Timestamps | RFC 3339, UTC | `2024-01-15T10:30:00Z` |
| Updates | JSON Patch (RFC 6902) | `[{"op": "replace", "path": "/name", "value": "new"}]` |
| Pagination | Cursor-based, bidirectional | `?cursor=abc&limit=50` |
| Errors | Structured with E-codes | `{"code": "E3001", "message": "..."}` |

---

## Updating Specs

When requirements change:

1. **Update the spec file** with new requirements
2. **Add a changelog entry** at the bottom of the spec
3. **Update related specs** that reference the changed content
4. **Update your plan.llm** to document the decision
5. **Update PROGRESS.md** if the change represents a new codebase pattern

### Changelog Format

```markdown
## Changelog

### {date} - {summary}
- Added: {new content}
- Changed: {modifications}
- Removed: {deprecated content}
- Reason: {why this change was made}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't find the right spec | Start with `llms.txt` or this file's Navigation Index |
| Specs seem contradictory | Framework specs are authoritative; business specs adapt them |
| Feature needs new spec | Create it following `SPEC-WRITING-GUIDE.md` and `LLM-STYLE-GUIDE.md` |
| Blocked by another agent | Check `.llm/plans/` for the blocking plan, coordinate or wait |
| Requirements unclear | Document questions in your plan.llm, mark as blocked |
| Quality gates failing | Check PROGRESS.md for known issues, fix before proceeding |
| Context feels stale | Re-read PROGRESS.md and relevant specs, start a fresh iteration |

---

## Related Documentation

- [Quick Nav](./llms.txt) - Compact navigation for quick lookups
- [Spec Writing Guide](./SPEC-WRITING-GUIDE.md) - How to write detailed specification files
- [Navigation Guide Standard](./LLM-STYLE-GUIDE.md) - How to format LLM navigation sections
- [Progress & Learnings](./.llm/PROGRESS.md) - Accumulated knowledge from all iterations
- [Business Specs](./biz/README.md) - Business feature documentation guide
- [Infrastructure](./.llm/INFRASTRUCTURE.md) - Docker services, ports, health checks
- [MCP Recommendations](./.llm/MCP-RECOMMENDATIONS.md) - Available MCP servers and setup
- [Skills Reference](./.llm/SKILLS.md) - Agent capabilities, commands, MCP servers, workflow decision tree
