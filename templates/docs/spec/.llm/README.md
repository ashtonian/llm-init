# LLM Coordination Folder

This folder coordinates work between multiple LLM agents working on the {{PROJECT_NAME}} platform.

## Folder Structure

```
.llm/
├── README.md           # This file
├── PROGRESS.md         # Accumulated knowledge and iteration log (READ FIRST)
├── plans/              # Active plan.llm files (work in progress)
├── completed/          # Archived completed plans
├── templates/          # Plan templates (feature, bugfix, review)
└── scripts/            # Utility scripts for LLM documentation
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

## Related Documentation

- [LLM Orchestration Guide](../LLM.md) - Master entry point for LLMs
- [LLM Style Guide](../LLM-STYLE-GUIDE.md) - Standard format for LLM navigation sections
- [Progress & Learnings](./PROGRESS.md) - Accumulated knowledge from all iterations
