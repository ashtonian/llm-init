# LLM Init User Guide

This guide explains the system that `llm-init` sets up, how to use it day-to-day with Claude Code, and how to extend it for your project.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [First Session with Claude Code](#first-session-with-claude-code)
- [Permissions](#permissions)
- [Writing Spec Files](#writing-spec-files)
- [The Two-Layer Architecture](#the-two-layer-architecture)
- [Plan Files and Multi-Agent Work](#plan-files-and-multi-agent-work)
- [Review Loops and Iteration](#review-loops-and-iteration)
- [Knowledge Accumulation](#knowledge-accumulation)
- [Concurrent Execution](#concurrent-execution)
- [Parallel Agent Harness](#parallel-agent-harness)
- [Custom Commands](#custom-commands)
- [Self-Improvement](#self-improvement)
- [Infrastructure](#infrastructure)
- [MCP Servers](#mcp-servers)
- [Customization Guide](#customization-guide)
- [Day-to-Day Workflow](#day-to-day-workflow)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- [Docker](https://docs.docker.com/get-docker/) (for PostgreSQL, Redis, NATS)
- [Node.js](https://nodejs.org/) 18+ (for MCP servers via `npx`)
- A Git repository for your project

---

## Installation

### 1. Clone `llm-init` into your project

```bash
cd /path/to/your-project
git clone https://github.com/ashtonian/llm-init.git
```

### 2. Run the setup script

```bash
bash llm-init/setup.sh <project-name> [go-module-path]
```

**Arguments:**

| Argument | Required | Example | Used For |
|----------|----------|---------|----------|
| `project-name` | Yes | `my-app` | Database name, container names, credentials |
| `go-module-path` | No | `github.com/myorg/my-app` | Go import paths in code examples |

If you omit `go-module-path`, it defaults to `github.com/yourorg/<project-name>`.

**Example:**

```bash
bash llm-init/setup.sh acme-api github.com/acmecorp/acme-api
```

This replaces all `{{PROJECT_NAME}}` placeholders with `acme-api` and `{{PROJECT_MODULE}}` with `github.com/acmecorp/acme-api` across every generated file.

### 3. Clean up

```bash
rm -rf llm-init/
```

### 4. Commit the scaffolding

```bash
git add .
git commit -m "Add LLM infrastructure and spec scaffolding"
```

### 5. Start the infrastructure (optional)

```bash
docker compose -f docs/spec/.llm/docker-compose.yml up -d
```

This starts PostgreSQL, Redis, and NATS locally. You can skip this until you need database access.

---

## First Session with Claude Code

After installation, start Claude Code in your project directory:

```bash
claude
```

Here's what happens automatically:

1. Claude loads `.claude/settings.json` (pre-approved permissions — no prompts for standard dev commands)
2. Claude reads `CLAUDE.md` (auto-loaded at every session start)
3. `CLAUDE.md` tells Claude to read `docs/spec/LLM.md` before doing anything
4. Claude now understands your spec structure, plan workflow, and coding conventions

Because permissions are pre-configured, Claude can immediately build, test, and run code without asking for approval on every command. See [Permissions](#permissions) for details.

### Your first prompt

Try something like:

```
Build a REST API for managing users with CRUD endpoints
```

Claude will:
1. Read the framework specs (API design, models, error handling)
2. Read the Go generation guide for code conventions
3. Create a plan file at `docs/spec/.llm/plans/user-api.plan.llm`
4. Implement the feature following all documented patterns

### Verify it's working

You can tell the system is working when Claude:
- References spec files by name (e.g., "per `api-design.md`...")
- Creates plan files before starting significant work
- Follows the Go patterns from the generation guide (functional options, small interfaces, etc.)
- Uses structured errors, `slog` logging, and context propagation

---

## Permissions

Claude Code normally prompts you before running shell commands, writing files, etc. The included `.claude/settings.json` pre-approves common development operations so Claude can work autonomously.

### What's pre-approved

The settings file allows Claude to run these without prompting:

| Category | Commands |
|----------|----------|
| **Go toolchain** | `go build`, `go test`, `go run`, `go mod`, `go generate`, etc. |
| **Build tools** | `make`, `npm`, `npx`, `pnpm`, `yarn`, `bun` |
| **TypeScript** | `tsc`, `tsx`, `eslint`, `prettier`, `vitest`, `jest`, `playwright` |
| **Docker** | `docker compose`, `docker exec`, `docker ps`, `docker logs`, `docker build`, `docker run` |
| **Git & GitHub** | All `git` commands, `gh` CLI (issues, PRs, API) |
| **File operations** | `ls`, `mkdir`, `cp`, `mv`, `chmod +x`, `cat`, `head`, `tail`, `sort`, `wc`, `tree`, `find`, `grep`, `diff`, `touch` |
| **Code quality** | `golangci-lint`, `staticcheck`, `gofmt`, `goimports`, `sqlc` |
| **HTTP** | `curl -s`, `curl` to localhost, `wget -q` |
| **Python** | `python3`, `python`, `pip install` |
| **Process mgmt** | `lsof`, `ps`, `kill`, `pkill` |
| **Utilities** | `jq`, `yq`, `sed`, `awk`, `xargs`, `env`, `export`, `brew install/list/info` |
| **Subagents** | `claude` CLI for spawning sub-sessions |
| **All file tools** | Read, Edit, Write, Glob, Grep, WebFetch, WebSearch, Task |
| **MCP server tools** | github, postgres, redis, sequential-thinking, context7, playwright |

### What's blocked

A small deny-list prevents destructive mistakes:

- `rm -rf /`, `rm -rf ~` and variants (catastrophic deletes)
- `sudo` (privilege escalation)
- Piping curl/wget to bash/sh (remote code execution)
- `chmod 777` (insecure permissions)
- `dd`, `mkfs`, device writes (disk destruction)
- Fork bombs

### How it works

Claude Code loads settings in this order (highest priority first):

1. **`.claude/settings.local.json`** — Your personal overrides (gitignored)
2. **`.claude/settings.json`** — Shared project settings (committed to git)
3. **`~/.claude/settings.json`** — Your global defaults

The project `settings.json` is committed to git so everyone on the team gets the same permissions. If you need personal overrides, create `.claude/settings.local.json` (automatically gitignored).

### Tightening permissions

If you want Claude to ask before certain operations, remove them from the `allow` list:

```json
{
  "permissions": {
    "allow": [
      "Bash(go test *)",
      "Read",
      "Edit"
    ]
  }
}
```

Claude will prompt for anything not in the `allow` list.

### Loosening permissions

To allow additional commands, add patterns to the `allow` list:

```json
{
  "permissions": {
    "allow": [
      "Bash(terraform *)",
      "Bash(kubectl *)",
      "Bash(aws *)"
    ]
  }
}
```

### Permission patterns

Patterns use glob-style matching:

| Pattern | Matches |
|---------|---------|
| `Bash(go *)` | Any command starting with `go` |
| `Bash(make)` | Exactly `make` with no arguments |
| `Bash(curl -s http://localhost*)` | Curl to localhost only |
| `Read` | All file reads (no path restriction) |
| `Edit` | All file edits (no path restriction) |

---

## Writing Spec Files

Spec files are markdown documents that tell Claude (and other LLMs) how your system works. They replace the need to explain the same things over and over in prompts.

### Where specs live

```
docs/spec/
├── framework/          # Generic patterns (API design, auth, errors)
└── biz/                # Business specs (features, research, decisions)
```

### Spec file format

Every spec follows the format defined in `LLM-STYLE-GUIDE.md`. The key insight: **put navigation at the top** so Claude can quickly decide if a file is relevant.

```markdown
# API Design

> **LLM Quick Reference**: REST conventions, model patterns, and pagination.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Designing or implementing REST API endpoints
- Understanding request/response model patterns
- Implementing pagination or filtering

### Key Sections

| Section | Purpose |
|---------|---------|
| **URL Conventions** | Path naming and versioning |
| **Model Patterns** | Create/Patch/Response type separation |
| **Pagination** | Cursor-based pagination implementation |

### Context Loading

1. For **API design only**: This doc is sufficient
2. For **error responses**: Also load `./error-handling.md`
3. For **database layer**: Also load `./data-access.md`

---

## URL Conventions

Your actual content starts here...
```

### Creating a new spec

1. Decide which layer it belongs to (framework or biz)
2. Create the file following the template above
3. Update `docs/spec/LLM.md` to reference it in the navigation index
4. Update `docs/spec/llms.txt` with a quick-reference entry
5. Run the nav reformatter if needed: `python3 docs/spec/.llm/scripts/move_nav_to_top.py`

### What to put in specs

Specs should document **decisions, patterns, and constraints** — the things Claude needs to know but can't infer from code alone:

- API conventions (URL patterns, response shapes, error codes)
- Data model decisions (which fields, relationships, constraints)
- Architecture patterns (how services communicate, caching strategy)
- Business rules (validation logic, workflow steps)
- Non-obvious implementation requirements (security, multi-tenancy, audit)

### What NOT to put in specs

- Auto-generated documentation (let tools generate that)
- Code snippets that could become stale (reference the source instead)
- Implementation details that change frequently

---

## The Two-Layer Architecture

The layered structure prevents Claude from having to read everything for every task.

### Framework (`framework/`)

Generic SaaS patterns that apply to any project. These are read first and define the conventions everything else follows.

**Included out of the box:**
- `go-generation-guide.md` — Mandatory Go coding patterns (800+ lines)
- `typescript-ui-guide.md` — Mandatory TypeScript/UI patterns (component architecture, accessibility, performance)
- `performance-guide.md` — Mandatory performance and code quality standards (memory allocation, profiling)
- `testing-guide.md` — Testing patterns, fixtures, mocking strategies
- `README.md` — Framework index and task-to-spec mapping

**You should add specs for:**
- API design conventions
- Error handling and error codes
- Authentication and authorization
- Data access patterns
- Model conventions
- Observability (logging, metrics, tracing)
- Validation rules

### Business Specs (`biz/`)

Feature requirements, market research, competitive analysis, and business decisions. These provide the business context for technical work.

**Examples:**
- Feature specifications (PRDs, user stories)
- Market and competitive analysis
- Business decision records
- Strategic planning documents

### How Claude uses the layers

When Claude gets a task like "add a billing endpoint":

1. Reads framework specs: API design conventions, error handling, model patterns
2. Reads business specs: Billing feature requirements, business rules
3. Implements following all conventions from both layers

---

## Plan Files and Multi-Agent Work

Plan files (`.plan.llm`) are how Claude tracks complex work. They live in `docs/spec/.llm/plans/`.

### When Claude creates plan files

Claude creates a plan file when starting any significant task (more than a quick fix). The plan tracks:

- What specs were read
- What files will be modified or created
- Implementation steps and their status
- Decisions made and why
- Blockers encountered

### Plan templates

Templates are provided for common workflows:

| Template | Use Case |
|----------|----------|
| `idea.plan.llm` | Start here for new projects — idea to working project (research → spec → plan → build) |
| `fullstack.plan.llm` | Full-stack feature (DB → Service → API → Frontend → E2E) with parallel execution |
| `feature.plan.llm` | Backend-focused feature implementation (6 phases) |
| `review.plan.llm` | Review/iteration cycle with quality gates and escape hatch |
| `bugfix.plan.llm` | Bug investigation, fix, and regression test |
| `self-review.plan.llm` | System self-review — audit and improve the LLM orchestration system |
| `plan.template.llm` | Generic — any task |
| `task.template.md` | Task file for the parallel agent queue (not a plan file) |

### Multi-agent coordination

If you run multiple Claude sessions on the same repo, the plan system prevents conflicts:

1. Each session creates or claims a plan file
2. Plans declare which files are being modified (`CLAIMED` status)
3. Before modifying a file, Claude checks if another plan has claimed it
4. Completed plans are moved to `docs/spec/.llm/completed/`

### Reviewing plan files

Plan files are committed to git, so you can:
- Review what Claude planned before it starts
- See the decision log after work is complete
- Understand the rationale behind implementation choices
- Track which specs were consulted

---

## Review Loops and Iteration

The review loop protocol ensures quality through repeated assessment and improvement cycles. This is inspired by iterative agent patterns where each cycle focuses on one task, verifies it, and records learnings.

### How it works

1. **Read**: Load PROGRESS.md and relevant specs for context
2. **Assess**: Pick the highest-priority incomplete item from the plan
3. **Implement**: Make the change (one focused item per cycle)
4. **Verify**: Run quality gates (build, test, lint, type-check)
5. **Record**: Update PROGRESS.md with learnings
6. **Commit**: If quality gates pass, commit the change
7. **Next**: Return to step 2 for the next item

### Key principles

- **One item per iteration**: Focus prevents context overload and isolates failures
- **Quality gates are mandatory**: Build + test + lint must pass before marking complete
- **Record everything**: Update PROGRESS.md so future iterations benefit
- **Priority-based selection**: Always work on the highest-priority incomplete item

### Using the review template

For review/iteration work, Claude uses the review plan template:

```bash
cp docs/spec/.llm/templates/review.plan.llm docs/spec/.llm/plans/{task-name}.plan.llm
```

---

## Knowledge Accumulation

`PROGRESS.md` in the `.llm/` directory is the persistent memory across all agent iterations. It solves the problem of LLMs losing context between sessions.

### Two sections

1. **Codebase Patterns** (top) — Curated, deduplicated patterns and conventions. Every agent reads this before starting work.
2. **Iteration Log** — Chronological record of what each iteration accomplished and learned.

### How agents use it

- **Before work**: Read Codebase Patterns to inherit institutional knowledge
- **During work**: Note patterns and gotchas as they're discovered
- **After work**: Append an iteration log entry with learnings

### Benefits

- Prevents repeated mistakes across sessions
- Builds a knowledge base that improves over time
- New agents instantly inherit context from all previous work
- Patterns are consolidated and deduplicated, not just appended

---

## Concurrent Execution

Claude is instructed to execute tasks concurrently whenever possible. Multiple agents or parallel tool calls are used for independent workstreams.

### Work division strategies

| Strategy | When to Use |
|----------|-------------|
| **By Layer** | One agent per spec layer (framework, biz) |
| **By Feature** | Each agent implements a complete vertical slice |
| **By Component** | Split: database, service, API handler, tests |
| **By Phase** | Design -> implement -> test -> document |

### Conflict prevention

Plan files declare which files are claimed, preventing two agents from modifying the same file simultaneously. Check active plans before starting work.

---

## Parallel Agent Harness

For autonomous batch execution of well-defined tasks, the parallel agent harness automates task claiming, git worktree isolation, and merging — no human in the loop.

### Two execution modes

The system supports two coexisting modes:

| Mode | Best For | Entry Point |
|------|----------|-------------|
| **Interactive (plan files)** | Complex features, user-guided sessions, design decisions | `docs/spec/.llm/plans/*.plan.llm` |
| **Autonomous batch (task queue)** | Well-defined tasks, parallelizable work, fire-and-forget | `docs/spec/.llm/tasks/backlog/*.md` |

Both modes share `PROGRESS.md` for cross-iteration knowledge.

### Setup

1. **Edit `docs/spec/.llm/STRATEGY.md`** — Decompose your project into phases and tasks
2. **Edit `docs/spec/.llm/AGENT_GUIDE.md`** — Add project description, tech stack, quality gate commands
3. **Create task files** from the template:
   ```bash
   cp docs/spec/.llm/templates/task.template.md docs/spec/.llm/tasks/backlog/01-my-task.md
   # Edit the task with specifics...
   ```
4. **Launch agents**:
   ```bash
   bash docs/spec/.llm/scripts/run-parallel.sh 3
   ```

### Task file format

Task files follow `templates/task.template.md`. The harness parses `## Dependencies:` to determine execution order — tasks with unmet dependencies are skipped until their dependencies are in `tasks/completed/`.

### Task sizing

- **Target 75-150 Claude turns per task.** Too small = startup overhead; too large = context exhaustion.
- Each task should have its own verification commands.
- Prefer many independent tasks (wide graph) over long dependency chains (deep graph).

### Scripts reference

| Script | Purpose |
|--------|---------|
| `run-parallel.sh [N]` | Launch N autonomous agents in parallel (staggered 5s apart) |
| `run-agent.sh [name]` | Single autonomous agent loop |
| `run-single-task.sh <file>` | Run one specific task autonomously (75 turns) |
| `run-interactive.sh <file>` | Interactive Claude Code session with task pre-loaded as context |
| `status.sh` | Task queue dashboard (counts, PIDs, per-task details) |
| `reset.sh` | Move all tasks back to backlog, clear locks |

### Monitoring and recovery

```bash
# Check progress
bash docs/spec/.llm/scripts/status.sh

# View agent logs
tail -f docs/spec/.llm/logs/agent-*.log

# Reset everything for a fresh run
bash docs/spec/.llm/scripts/reset.sh
```

If an agent fails mid-task, the task stays in `in_progress/` with a lock. To recover: move the file back to `backlog/`, delete the lock directory under `tasks/.locks/`, and re-run.

### Configuration

Set environment variables before launching:

| Variable | Default | Purpose |
|----------|---------|---------|
| `BRANCH_PREFIX` | `task/` | Git branch prefix |
| `MAX_TURNS` | `150` | Max Claude Code turns per task |
| `WAIT_INTERVAL` | `10` | Seconds between polling when idle |
| `MAX_EMPTY_WAITS` | `60` | Idle cycles before shutdown (~10 min) |
| `SKIP_API_KEY_UNSET` | _(unset)_ | Set to `1` to keep `ANTHROPIC_API_KEY` (for API-key auth) |
| `SKIP_PERMISSIONS` | `0` | Set to `1` to use `--dangerously-skip-permissions` instead of `.claude/settings.json` permissions |

### Permissions mode

By default, autonomous agents use your project's `.claude/settings.json` permissions. To use `--dangerously-skip-permissions` for fully unattended operation instead:

```bash
SKIP_PERMISSIONS=1 bash docs/spec/.llm/scripts/run-parallel.sh 3
```

---

## Custom Commands

Claude Code supports project-level custom commands as slash commands. llm-init includes 7 pre-built commands.

### Available Commands

| Command | Purpose |
|---------|---------|
| `/decompose <description>` | Break a feature into parallel tasks |
| `/new-task <description>` | Create a single task file |
| `/status` | Task queue dashboard with analysis |
| `/launch [N]` | Pre-flight checks + launch N agents |
| `/plan <description>` | Select and create a plan template |
| `/review` | Run quality gates on current work |
| `/shelve` | Checkpoint with structured handoff |

### Example Workflows

**Starting a new feature (parallel):**

```
/decompose Build user management with CRUD, roles, and invite flow
# Review the decomposition, approve
/launch 3
/status
```

**Working interactively:**

```
/plan Redesign the authentication system
# Fill in the plan, get approval, implement
/review
```

**Pausing and resuming:**

```
/shelve
# Later, in a new session:
/status
```

### Creating Your Own Commands

Add `.md` files to `.claude/commands/`:

```bash
# Create a custom command
echo "Your prompt instructions here" > .claude/commands/my-command.md
# Now type /my-command in Claude Code
```

Commands are markdown files containing prompt instructions. When invoked, Claude Code expands the file content as the prompt. User input after the command name is available as `$ARGUMENTS`.

See `docs/spec/.llm/SKILLS.md` for the full capabilities reference.

---

## Self-Improvement

Claude is encouraged to improve the LLM orchestration system itself. This means:

- **Fixing specs**: If a spec is wrong or incomplete, Claude updates it
- **Recording patterns**: New conventions go into PROGRESS.md
- **Improving templates**: Better plan templates for common workflows
- **Updating navigation**: Keep LLM.md and llms.txt current as specs are added
- **Proposing changes**: If the orchestration workflow could be better, Claude can modify it

### Guard rails

- Spec improvements are committed separately from feature code
- Information is added, not replaced (unless clearly wrong)
- Existing functionality isn't broken when improving documentation

---

## Infrastructure

The Docker Compose setup provides three services for local development:

| Service | Port | Purpose | Container Name |
|---------|------|---------|----------------|
| PostgreSQL 16 | 5432 | Primary database | `<project>-postgres` |
| Redis 7 | 6379 | Cache layer | `<project>-redis` |
| NATS 2 | 4222, 8222 | Message bus | `<project>-nats` |

### Common commands

```bash
# Start all services
docker compose -f docs/spec/.llm/docker-compose.yml up -d

# Check health
docker compose -f docs/spec/.llm/docker-compose.yml ps

# Stop (data preserved)
docker compose -f docs/spec/.llm/docker-compose.yml down

# Full reset (data destroyed)
docker compose -f docs/spec/.llm/docker-compose.yml down
rm -rf docs/spec/.llm/data
```

### Resource limits

Default limits are tuned for local development:

| Service | CPU | Memory |
|---------|-----|--------|
| PostgreSQL | 2 cores | 1 GB |
| Redis | 1 core | 512 MB |
| NATS | 1 core | 512 MB |

Adjust in `docs/spec/.llm/docker-compose.yml` if needed.

### Data persistence

Container data persists in `docs/spec/.llm/data/` (gitignored). Data survives `docker compose down` and `up` cycles. Only `rm -rf docs/spec/.llm/data` destroys it.

### Removing services you don't need

If your project doesn't use NATS or Redis, remove them from `docker-compose.yml` and the corresponding MCP server from `.mcp.json`. The system works fine without them.

---

## MCP Servers

MCP (Model Context Protocol) servers give Claude direct tool access to external systems. They're configured in `.mcp.json` at the project root.

### Included servers

| Server | What Claude Can Do |
|--------|--------------------|
| **github** | Create issues, PRs, read reviews |
| **postgres** | Query the database, inspect schemas |
| **redis** | Read/write cache entries |
| **sequential-thinking** | Break down complex problems step-by-step |
| **context7** | Look up current library/framework documentation |
| **playwright** | Browser automation, E2E testing, visual verification |

### Authenticating GitHub

The GitHub MCP server uses a Personal Access Token (PAT):

1. Create a PAT at [github.com/settings/tokens](https://github.com/settings/tokens) with appropriate scopes (`repo`, `read:org`, etc.)
2. Set the environment variable before starting Claude Code:
   ```bash
   export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
   ```
3. Optionally add it to your shell profile (`~/.bashrc`, `~/.zshrc`) or a `.env` file

### Adding/removing servers

Edit `.mcp.json`. See `docs/spec/.llm/MCP-RECOMMENDATIONS.md` for recommendations organized by tier.

### Servers that don't need infrastructure

`github`, `sequential-thinking`, `context7`, and `playwright` work without Docker. Only `postgres` and `redis` require the Docker infrastructure to be running.

---

## Customization Guide

After running `setup.sh`, here's what to customize and in what order.

### Step 1: Review permissions

Check `.claude/settings.json`. The defaults allow common Go/Node/Docker commands. Add commands specific to your stack:

```json
{
  "permissions": {
    "allow": [
      "Bash(terraform *)",
      "Bash(kubectl *)"
    ]
  }
}
```

### Step 2: Edit `CLAUDE.md`

Add any project-specific instructions. This is read by Claude at every session start, so keep it concise. Good additions:

- Tech stack summary (e.g., "This is a Go backend with a React frontend")
- Build/test commands (e.g., "Run tests with `make test`")
- Project-specific rules (e.g., "Always use the `tenant` package for multi-tenancy")

### Step 3: Write framework specs

Three guides are included out of the box (Go, TypeScript/UI, Performance). Add the specs they reference, starting with the most impactful:

1. **`framework/api-design.md`** — How your REST API works
2. **`framework/error-handling.md`** — Your error code system
3. **`framework/models.md`** — Base model patterns (IDs, timestamps, soft delete)
4. **`framework/data-access.md`** — Database access patterns

Each spec follows the format in `LLM-STYLE-GUIDE.md`.

### Step 4: Update navigation

After adding specs, update:
- `docs/spec/LLM.md` — Add to execution orders and navigation index
- `docs/spec/llms.txt` — Add to quick document selection tables
- `docs/spec/framework/README.md` — Add to the category tables

### Step 5: Add business specs

Use `docs/spec/biz/README.md` as a guide for writing feature requirements, user stories, market research, and decision records:

```bash
# Business specs go in the biz directory
docs/spec/biz/features/{feature-name}.md
docs/spec/biz/research/competitive-analysis.md
docs/spec/biz/decisions/{YYYY-MM-DD}-{decision}.md
```

### Step 6: Adjust infrastructure

- Remove services you don't need from `docker-compose.yml`
- Remove corresponding MCP servers from `.mcp.json`
- Update connection strings in `INFRASTRUCTURE.md`

### Step 7: Adjust code conventions

Review and customize the included guides:
- `framework/go-generation-guide.md` — Adjust cross-cutting concerns table, import paths, anti-patterns
- `framework/typescript-ui-guide.md` — Adjust component library choices, state management preferences
- `framework/performance-guide.md` — Adjust latency budgets, profiling requirements for your stack

---

## Day-to-Day Workflow

### Starting a coding session

```bash
cd your-project
claude
```

Claude reads `CLAUDE.md` automatically. You're ready to go.

### Asking Claude to build something

Just describe what you want. The spec system handles the rest:

```
Add a REST API for managing billing plans with CRUD endpoints,
including validation and proper error handling.
```

Claude will consult the relevant specs, create a plan, and implement.

### Asking Claude to follow specific specs

If Claude isn't consulting a spec you care about, be explicit:

```
Add caching to the user service, following the patterns in framework/performance-guide.md
```

### Reviewing what Claude did

After Claude completes work:
1. Check the plan file in `docs/spec/.llm/plans/` for decisions and rationale
2. Review the code changes with `git diff`
3. Move the plan to `completed/` when satisfied

### Adding a new spec mid-project

1. Create the markdown file in the appropriate layer directory
2. Follow the format in `LLM-STYLE-GUIDE.md`
3. Update `LLM.md` and `llms.txt` with references
4. Claude will pick it up in the next session (or tell it to re-read `LLM.md`)

### When Claude doesn't follow conventions

If Claude generates code that doesn't match your specs:
1. Point it to the specific spec: "Please follow the patterns in `framework/api-design.md`"
2. If it happens repeatedly, strengthen the language in `CLAUDE.md`
3. Add specific anti-patterns to `go-generation-guide.md`

---

## Troubleshooting

### Claude doesn't seem to read the specs

- Verify `CLAUDE.md` exists at the project root
- Check that it contains the directive to read `docs/spec/LLM.md`
- Try explicitly: "Read docs/spec/LLM.md and follow its instructions"

### MCP servers won't connect

```bash
# Check if infrastructure is running
docker compose -f docs/spec/.llm/docker-compose.yml ps

# All should show "healthy". If not:
docker compose -f docs/spec/.llm/docker-compose.yml restart
```

For the GitHub MCP, ensure `GITHUB_PERSONAL_ACCESS_TOKEN` is set in your environment.

### Docker services fail to start

```bash
# Check for port conflicts
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :4222  # NATS

# Full reset
docker compose -f docs/spec/.llm/docker-compose.yml down
rm -rf docs/spec/.llm/data
docker compose -f docs/spec/.llm/docker-compose.yml up -d
```

### Plan files pile up

Move completed plans to the archive:

```bash
mv docs/spec/.llm/plans/completed-feature.plan.llm docs/spec/.llm/completed/
```

Or ask Claude: "Archive all completed plan files."

### Setup script skips files

The setup script won't overwrite existing files. If you need to regenerate:

```bash
# Remove the specific file, then re-run
rm docs/spec/LLM.md
bash llm-init/setup.sh my-project github.com/myorg/my-project
```

### Go module path is wrong

If you ran setup without specifying the Go module path, the generation guide will have `github.com/yourorg/<project-name>` as placeholders. Find and replace:

```bash
grep -r "github.com/yourorg" docs/spec/ .mcp.json
# Then update to your actual module path
```
