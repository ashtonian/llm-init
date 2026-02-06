# LLM Coordination Folder

This folder coordinates work between multiple LLM agents working on the {{PROJECT_NAME}} platform.

## Folder Structure

```
.llm/
├── README.md           # This file
├── PROGRESS.md         # Accumulated knowledge and iteration log (READ FIRST)
├── STRATEGY.md         # Project decomposition into phases and tasks
├── AGENT_GUIDE.md      # Project context inlined into every agent prompt
├── plans/              # Active plan.llm files (work in progress)
├── completed/          # Archived completed plans
├── templates/          # Plan + task templates
│   ├── *.plan.llm      # Plan templates (idea, fullstack, feature, bugfix, review)
│   └── task.template.md # Task file template for the parallel agent queue
├── scripts/            # Utility and agent harness scripts
├── tasks/              # Parallel agent task queue
│   ├── backlog/        # Tasks ready to be claimed
│   ├── in_progress/    # Currently being worked on
│   ├── completed/      # Successfully finished
│   ├── blocked/        # Failed or blocked tasks
│   └── .locks/         # Atomic mkdir-based locks
├── logs/               # Agent execution logs
└── worktrees/          # Git worktrees (created at runtime, gitignored)
```

## How It Works

### Before Starting Work

1. **Read `PROGRESS.md`** — the Codebase Patterns section contains accumulated knowledge from all previous iterations
2. Check `plans/` for existing work on your feature
3. If none exists, copy the appropriate template to `plans/{feature-name}.plan.llm`
4. Fill in the metadata and claim the plan

### Starting Work

1. Update plan status to `in_progress`
2. Read relevant specs per your task type (see `../LLM.md` for execution order)
3. Work on the highest-priority incomplete item
4. Run quality gates after each significant change

### Claiming Work

Add your agent ID to the plan file's metadata:
```markdown
## Metadata
- **Agent ID**: your-agent-id-here
- **Status**: in_progress
```

### Avoiding Conflicts

Before modifying files listed in another plan:
1. Check if that plan is `in_progress`
2. If yes, coordinate or work on non-conflicting files
3. If completed/abandoned, you can proceed

### Completing Work

1. Update all checkboxes in your plan
2. **Update `PROGRESS.md`** — add new codebase patterns and an iteration log entry
3. Change status to `completed`
4. Move the plan file to `completed/` folder

## Plan File Conventions

- **Naming**: `{feature-name}.plan.llm` (lowercase, hyphens)
- **Status values**: `planning`, `in_progress`, `blocked`, `completed`, `abandoned`
- **Timestamps**: ISO 8601 format (e.g., `2024-01-15T10:30:00Z`)

## Plan Templates

| Template | Use Case |
|----------|----------|
| `templates/idea.plan.llm` | **Start here for new projects** — idea to working project (research → spec → plan → build) |
| `templates/fullstack.plan.llm` | Full-stack feature (DB → Service → API → Frontend → E2E) with parallel execution strategy |
| `templates/feature.plan.llm` | Backend-focused feature implementation (6 phases) |
| `templates/review.plan.llm` | Review/iteration cycle with quality gates and escape hatch |
| `templates/bugfix.plan.llm` | Bug investigation and fix (3 phases) |
| `templates/self-review.plan.llm` | System self-review — audit and improve the LLM orchestration system itself |
| `templates/plan.template.llm` | Generic task |

## Progress & Knowledge Accumulation

`PROGRESS.md` is the persistent memory across all agent iterations. It has two sections:

1. **Codebase Patterns** (top) — Curated, deduplicated patterns and conventions. Read this before starting any work.
2. **Iteration Log** — Chronological record of what each iteration accomplished and learned.

Every agent should:
- Read the Codebase Patterns section before starting
- Add new patterns when discovered
- Append to the Iteration Log when completing work

## Scratch Workspace

Agents can create a `.llm-scratch/` directory at the project root for temporary working files. This directory is gitignored and should be cleaned up after use.

```bash
mkdir -p .llm-scratch
# Use for temp scripts, data, drafts
# Clean up when done
```

## Utility Scripts

### move_nav_to_top.py

Moves LLM Navigation Guide sections from the end of files to the top (after the title).

**Usage:**
```bash
# Dry run (see what would change)
python3 .llm/scripts/move_nav_to_top.py --dry-run

# Process all files
python3 .llm/scripts/move_nav_to_top.py

# Process specific files
python3 .llm/scripts/move_nav_to_top.py path/to/file.md
```

**When to use:**
- After creating new spec files with LLM Navigation at the end
- When migrating existing docs to the LLM-friendly format
- To verify all specs follow the standard

## Parallel Agent Harness

The parallel agent harness provides autonomous batch execution of tasks using a file-based queue.

### Two Execution Modes

| Mode | Best For | Entry Point |
|------|----------|-------------|
| **Interactive (plan files)** | Complex features, user-guided sessions, decisions | `plans/*.plan.llm` |
| **Autonomous batch (task queue)** | Well-defined tasks, parallel execution, fire-and-forget | `tasks/backlog/*.md` |

Both modes share `PROGRESS.md` for cross-iteration knowledge accumulation.

### Quick Start

```bash
# 1. Edit project context (customize for your project)
#    docs/spec/.llm/STRATEGY.md     — project decomposition
#    docs/spec/.llm/AGENT_GUIDE.md  — agent context (tech stack, quality gates)

# 2. Create task files from the template
cp docs/spec/.llm/templates/task.template.md docs/spec/.llm/tasks/backlog/01-my-task.md
# Edit the task file with specifics...

# 3. Launch parallel agents
bash docs/spec/.llm/scripts/run-parallel.sh 3

# 4. Monitor progress
bash docs/spec/.llm/scripts/status.sh
```

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/run-parallel.sh [N]` | Launch N autonomous agents in parallel |
| `scripts/run-agent.sh [name]` | Single autonomous agent loop |
| `scripts/run-single-task.sh <file>` | Run one specific task autonomously |
| `scripts/run-interactive.sh <file>` | Interactive Claude Code session with task context |
| `scripts/status.sh` | Task queue dashboard (counts, PIDs, per-task details) |
| `scripts/reset.sh` | Move all tasks back to backlog, clear locks |

### Task File Format

Task files live in `tasks/backlog/` and follow `templates/task.template.md`:

```markdown
# Task NN — Title
## Phase: N — Phase Name
## Priority: High | Medium | Low
## Dependencies: None | Tasks 01, 02
## Objective
...
## Steps
...
## Verification
...
## Acceptance Criteria
- [ ] ...
```

The harness parses `## Dependencies:` to determine execution order. Tasks with unmet dependencies are skipped until their dependencies are in `tasks/completed/`.

### Architecture

Each agent runs in an isolated git worktree. Tasks are claimed atomically via `mkdir` locks. On completion, changes are merged to master with `--no-ff`. The agent appends a summary to `PROGRESS.md` so future agents inherit context.

Agents use `--dangerously-skip-permissions` by default for autonomous operation. Set `SKIP_PERMISSIONS=0` to use `.claude/settings.json` permissions instead. Set `SKIP_API_KEY_UNSET=1` to keep your `ANTHROPIC_API_KEY` for API-key-based auth. For interactive mode, use `run-interactive.sh` which always respects project permissions.

### Resilience

- **Task claiming**: Atomic via `mkdir` — two agents cannot claim the same task
- **Agent failure**: Task stays in `in_progress/` with a lock. Manual recovery: move back to `backlog/`, delete the lock
- **Merge conflicts**: If merge fails, task moves to `blocked/` for manual resolution
- **Idle shutdown**: Agents exit after ~10 minutes with no available tasks (configurable via `MAX_EMPTY_WAITS`)

## Related Documentation

- [LLM Orchestration Guide](../LLM.md) - Master entry point for LLMs
- [LLM Style Guide](../LLM-STYLE-GUIDE.md) - Standard format for LLM navigation sections
- [Progress & Learnings](./PROGRESS.md) - Accumulated knowledge from all iterations
