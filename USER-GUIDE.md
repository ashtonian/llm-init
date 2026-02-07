# LLM Init User Guide

This guide explains the system that `llm-init` sets up, how to use it day-to-day with Claude Code, and how to extend it for your project.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [First Session with Claude Code](#first-session-with-claude-code)
- [Permissions](#permissions)
- [Architecture Overview](#architecture-overview)
- [Skills](#skills)
- [Agents](#agents)
- [Rules](#rules)
- [Agent Teams](#agent-teams)
- [Plan Files and Multi-Agent Work](#plan-files-and-multi-agent-work)
- [Review Loops and Iteration](#review-loops-and-iteration)
- [Knowledge Accumulation](#knowledge-accumulation)
- [Writing Spec Files](#writing-spec-files)
- [Software Lifecycle](#software-lifecycle)
- [Self-Improvement](#self-improvement)
- [Infrastructure](#infrastructure)
- [MCP Servers](#mcp-servers)
- [Experimental Features](#experimental-features)
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

### Optional: Go project scaffolding

Add the `--go` flag to scaffold a complete Go project (Makefile, Dockerfile, CI, GoReleaser, linter):

```bash
bash llm-init/setup.sh --go acme-api github.com/acmecorp/acme-api
```

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

1. Claude loads `.claude/settings.json` (pre-approved permissions -- no prompts for standard dev commands)
2. Claude reads `CLAUDE.md` (auto-loaded at every session start)
3. Claude loads all matching rules from `.claude/rules/` based on the files being worked on
4. Claude now understands your execution modes, available skills, and coding conventions

Because permissions are pre-configured, Claude can immediately build, test, and run code without asking for approval on every command. See [Permissions](#permissions) for details.

### Your first prompt

Try something like:

```
Build a REST API for managing users with CRUD endpoints
```

Claude will:
1. Load the relevant rules (api-design, go-patterns or typescript-patterns, testing, etc.)
2. Create a plan file at `docs/spec/.llm/plans/user-api.plan.llm`
3. Implement the feature following all documented patterns
4. Run quality gates after implementation

### Verify it's working

You can tell the system is working when Claude:
- References rules and patterns by name (e.g., "per the api-design rule...")
- Creates plan files before starting significant work
- Follows the coding patterns defined in `.claude/rules/`
- Runs quality gates after making changes

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
| **Subagents** | `claude` CLI for spawning sub-sessions and agent teams |
| **All file tools** | Read, Edit, Write, Glob, Grep, WebFetch, WebSearch, Task |
| **MCP server tools** | github, postgres, redis, context7, playwright, memory, terraform, eslint, aws-documentation |

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

1. **`.claude/settings.local.json`** -- Your personal overrides (gitignored)
2. **`.claude/settings.json`** -- Shared project settings (committed to git)
3. **`~/.claude/settings.json`** -- Your global defaults

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

## Architecture Overview

llm-init sets up four directories inside `.claude/` that define how Claude Code operates in your project, plus a spec and task management system under `docs/spec/`.

```
.claude/
  skills/          17 skills (slash commands for common workflows)
  agents/          15 agents (specialized roles for team execution)
  rules/           15 rules (auto-loaded coding and architecture guides)
  settings.json    Pre-approved permissions

docs/spec/
  biz/             Business specs (features, PRDs, decisions)
  .llm/
    PROGRESS.md    Persistent knowledge across sessions
    STRATEGY.md    Project decomposition into phases and tasks
    tasks/         Task queue (backlog, in_progress, completed, blocked)
    plans/         Plan files for complex work
    templates/     Plan and task templates
    scripts/       Utility scripts (run-team.sh, status.sh, reset.sh, archive.sh)

CLAUDE.md          Session bootstrap (read at every session start)
.mcp.json          MCP server configuration
```

### How the pieces fit together

- **CLAUDE.md** is the entry point. Claude reads it at every session start. It defines execution modes (Parallel, Interactive, Quick, Idea Pipeline) and lists available skills.
- **Rules** are auto-loaded based on context. When Claude works on Go files, the `go-patterns` rule activates. When working on API endpoints, `api-design` activates. This is handled by Claude Code natively.
- **Skills** are slash commands you type to trigger specific workflows (e.g., `/decompose`, `/requirements`, `/launch`).
- **Agents** are specialized roles that the team-lead agent spawns during parallel execution. You do not invoke agents directly -- the team-lead orchestrates them.
- **Specs** in `docs/spec/biz/` provide business context. Rules provide technical conventions. Together they tell Claude both _what_ to build and _how_ to build it.

---

## Skills

Skills are project-level slash commands that live in `.claude/skills/`. Each skill is a directory containing a `SKILL.md` file with instructions that Claude follows when the skill is invoked.

### Available Skills

**Task Management:**

| Skill | Purpose |
|-------|---------|
| `/prd <description>` | Interactive PRD pipeline: discovery Q&A, PRD document, sized task files |
| `/decompose <description>` | Break a request into 2-8 parallel tasks with dependency ordering |
| `/new-task <description>` | Create a single task file in the backlog |
| `/status` | Task queue dashboard with analysis |
| `/launch` | Pre-flight checks + launch team-lead agent for parallel execution |
| `/plan <description>` | Select and create the right plan template |
| `/review` | Run quality gates and review current work |
| `/shelve` | Checkpoint work with structured handoff for later resumption |

**Software Lifecycle:**

| Skill | Purpose |
|-------|---------|
| `/requirements <topic>` | Iterative requirement gathering producing a technical specification |
| `/architecture-review [scope]` | Assess architecture decisions, tradeoffs, and edge cases |
| `/adr <decision topic>` | Create an Architecture Decision Record in `docs/spec/biz/` |
| `/security-review [scope]` | Systematic security assessment (input validation, auth, data, deps) |
| `/release [version]` | Release preparation with checklist, changelog, and validation |
| `/api-design <description>` | Design API contracts with OpenAPI specifications |
| `/data-model <description>` | Design database schemas, migrations, and data access layers |
| `/performance-audit [scope]` | Profile and optimize performance bottlenecks |
| `/incident-response <issue>` | Structured incident investigation and resolution |

### How skills work

When you type `/decompose Build a user management system`, Claude Code:

1. Loads `.claude/skills/decompose/SKILL.md`
2. Substitutes your text after the command into `$ARGUMENTS`
3. Follows the instructions in the skill file step by step

### Creating your own skills

Add a directory under `.claude/skills/` with a `SKILL.md` file:

```bash
mkdir -p .claude/skills/my-workflow
```

Create `.claude/skills/my-workflow/SKILL.md`:

```markdown
---
name: my-workflow
description: One-line description of what this skill does
allowed-tools: Read, Write, Bash, Grep, Glob
---

Instructions for Claude to follow when this skill is invoked.

## Steps

1. Do the first thing
2. Do the second thing

## Arguments

$ARGUMENTS
```

Now type `/my-workflow some input` in Claude Code.

### Skill frontmatter

| Field | Purpose |
|-------|---------|
| `name` | Skill identifier (matches the directory name) |
| `description` | Shown when listing available skills |
| `allowed-tools` | Restrict which tools the skill can use |

---

## Agents

Agents are specialized roles defined in `.claude/agents/`. Each agent is a markdown file with a frontmatter header specifying its model, turn budget, and available tools. Agents are spawned by the team-lead during parallel execution -- you do not invoke them directly.

### Agent Roster

| Agent | Turns | Role |
|-------|-------|------|
| **team-lead** | 500 | Orchestrates parallel task execution, manages dependencies, spawns teammates, merges branches |
| **implementer** | 150 | Builds features with spec compliance and production-quality code |
| **reviewer** | 75 | Reviews code for quality, pattern consistency, and spec drift |
| **security** | 75 | Security auditor for vulnerability detection, input validation, and auth review |
| **debugger** | 100 | Root cause analysis and bug fixing |
| **tester** | 100 | Test coverage specialist for edge cases and failure modes |
| **frontend** | 150 | Frontend/UI implementation (React, Next.js, TypeScript components) |
| **api-designer** | 100 | API contract design and implementation (REST, gRPC, GraphQL) |
| **data-modeler** | 100 | Database schema design, migrations, repositories, query optimization |
| **architect** | 100 | System architecture, design decisions, service boundaries, tradeoff analysis |
| **benchmarker** | 100 | Performance profiling, benchmarking, load testing, regression detection |
| **ux-researcher** | 75 | User flow analysis, accessibility audits, usability heuristic evaluation |
| **release-engineer** | 75 | Release planning, changelog generation, version management, deployment validation |
| **devops** | 100 | Infrastructure, Docker, Kubernetes, Terraform, CI/CD, monitoring |
| **requirements-analyst** | 150 | Deep requirement gathering, user stories, acceptance criteria, domain modeling |

All agents use the Opus model.

### How agent selection works

The team-lead reads each task file and selects the appropriate agent based on the task type:

| Task Type | Agent |
|-----------|-------|
| Implementation / feature building | implementer |
| Code review | reviewer |
| Security audit or fix | security |
| Bug investigation and fix | debugger |
| Writing tests | tester |
| Frontend/UI work | frontend |
| API contract design | api-designer |
| Database schema work | data-modeler |
| Architecture review | architect |
| Performance optimization | benchmarker |
| Default (when unsure) | implementer |

### Agent file format

Agent files use YAML frontmatter:

```markdown
---
name: implementer
description: Implements features with spec compliance and production-quality code.
tools: Read, Edit, Write, Bash, Grep, Glob, Task
model: opus
maxTurns: 150
---

## Your Role: Implementer

Instructions for the agent...
```

| Field | Purpose |
|-------|---------|
| `name` | Agent identifier |
| `description` | What this agent does |
| `tools` | Which tools the agent can use |
| `model` | Which Claude model to use |
| `maxTurns` | Maximum number of turns before the agent stops |
| `permissionMode` | (team-lead only) `delegate` to spawn other agents |

### Customizing agents

Edit the agent files in `.claude/agents/` to adjust behavior. Common customizations:

- **Turn budget**: Increase `maxTurns` if agents run out of turns on complex tasks
- **Instructions**: Add project-specific guidance to the agent's instructions
- **Tool access**: Add or remove tools based on what the agent should be able to do

---

## Rules

Rules are auto-loaded guides that live in `.claude/rules/`. Unlike skills (which you invoke explicitly), rules are loaded automatically by Claude Code based on context -- the files you are working on, the task at hand, or the patterns being used.

### Available Rules

| Rule | What It Covers |
|------|----------------|
| **agent-guide** | Project description, tech stack, quality gate commands, production code checklist |
| **spec-first** | Spec-first protocol: when to create specs, what they contain, compliance verification |
| **go-patterns** | Go coding conventions (functional options, small interfaces, error handling, etc.) |
| **typescript-patterns** | TypeScript/React patterns (components, hooks, state management, accessibility) |
| **performance** | Performance budgets, latency targets, memory allocation, caching, profiling |
| **testing** | Testing patterns, fixtures, mocking strategies, coverage requirements |
| **security** | Input validation, SQL injection prevention, XSS, CSRF, secret protection, rate limiting |
| **observability** | Structured logging, distributed tracing, metrics (RED/USE), alerting, health checks |
| **multi-tenancy** | Tenant isolation, data scoping, context propagation, cross-tenant access rules |
| **infrastructure** | Docker Compose services, connection details, resource limits |
| **api-design** | REST conventions, API versioning, request/response patterns, pagination |
| **auth-patterns** | Authentication and authorization patterns (JWT, OAuth2, RBAC, API keys) |
| **data-patterns** | Data access patterns, repository layer, migrations, query optimization |
| **frontend-architecture** | Frontend component architecture, routing, state management, build pipeline |
| **ux-standards** | UX patterns, accessibility standards, design system conventions |

### How rules work

Claude Code automatically loads rules based on the context of the current task. For example:

- Editing a `.go` file triggers `go-patterns`
- Editing a `.tsx` file triggers `typescript-patterns` and `frontend-architecture`
- Working on API endpoints triggers `api-design` and `security`
- The `agent-guide` rule is always loaded (it contains quality gates and project metadata)

You do not need to reference rules manually. They are part of the Claude Code rules system and activate based on file-path patterns and task context.

### The agent-guide rule

The `agent-guide` rule (`.claude/rules/agent-guide.md`) is the most important rule to customize. It contains:

- **Project description**: What you are building
- **Goal**: Current milestone or objective
- **Tech stack**: Languages, frameworks, databases
- **Quality gates**: Build/test/lint commands that must pass after every change
- **Production code quality checklist**: Standards for error handling, validation, testing, documentation, and code structure
- **Constraints**: Rules all agents must follow

Customize this file immediately after running `setup.sh`.

### Creating your own rules

Add a markdown file to `.claude/rules/`:

```bash
# Create a rule for your specific domain
cat > .claude/rules/billing.md << 'EOF'
# Billing Patterns

Rules for implementing billing features in this project.

## Conventions
- All monetary amounts stored as cents (integer, not float)
- Use Stripe as the payment processor
- ...
EOF
```

Claude Code will auto-load this rule when working on billing-related code.

---

## Agent Teams

Agent Teams replace the old shell-script parallel harness. Instead of launching separate processes, the team-lead agent orchestrates teammate agents natively within Claude Code, using branch isolation and dependency ordering.

### How it works

1. **You** create task files in `docs/spec/.llm/tasks/backlog/` (via `/decompose`, `/prd`, or `/new-task`)
2. **You** launch the team lead (via `/launch` or `run-team.sh`)
3. **The team-lead agent** reads all backlog tasks, builds a dependency graph, and spawns teammate agents in parallel
4. **Teammate agents** work on isolated git branches (`agent/<task-slug>`), each completing one task
5. **The team-lead** monitors progress, handles failures, and spawns newly-unblocked tasks
6. **On completion**, the team-lead merges all branches, runs final quality gates, and updates `PROGRESS.md`

### Setup

1. **Edit `.claude/rules/agent-guide.md`** -- Add your project description, tech stack, and quality gate commands
2. **Edit `docs/spec/.llm/STRATEGY.md`** -- Decompose your project into phases and tasks
3. **Create task files** from the template:
   ```bash
   cp docs/spec/.llm/templates/task.template.md docs/spec/.llm/tasks/backlog/01-my-task.md
   # Edit the task with specifics...
   ```
   Or use skills to generate tasks:
   ```
   /prd Build a user management system with roles and invite flow
   /decompose Build the billing integration
   ```
4. **Launch the team**:
   ```bash
   # From the command line:
   bash docs/spec/.llm/scripts/run-team.sh

   # Or from inside Claude Code:
   /launch
   ```

### Task file format

Task files follow `docs/spec/.llm/templates/task.template.md`. The team-lead parses:
- `## Dependencies:` to determine execution order (tasks with unmet dependencies wait)
- `## Verification` for quality gate commands specific to this task
- `## Acceptance Criteria` checkboxes for completion tracking

### Task sizing

- **Target 75-150 Claude turns per task.** Too small = startup overhead; too large = context exhaustion.
- **2-3 sentence test**: If you can't describe a task in 2-3 sentences, split it further.
- Each task should be independently verifiable (its own build/test commands).
- Prefer many independent tasks (wide graph) over long dependency chains (deep graph).

| Good (right-sized) | Bad (too big) |
|---------------------|---------------|
| Add user model and migration | Build the user management system |
| Create GET /users endpoint with tests | Implement the REST API |
| Add login form component | Build authentication |

### Scripts reference

| Script | Purpose |
|--------|---------|
| `run-team.sh` | Launch team-lead agent for parallel task execution |
| `status.sh` | Task queue dashboard (counts, per-task details, active agents) |
| `reset.sh` | Move all tasks back to backlog, clear locks |
| `archive.sh [desc]` | Archive completed tasks and logs to a timestamped directory |

### Monitoring and recovery

```bash
# Check progress
bash docs/spec/.llm/scripts/status.sh

# Reset everything for a fresh run
bash docs/spec/.llm/scripts/reset.sh

# Archive completed work before starting a new phase
bash docs/spec/.llm/scripts/archive.sh "phase-1-foundation"
```

If the team-lead fails mid-execution, tasks in `in_progress/` retain their lock files. To recover: use `reset.sh` to move everything back to backlog, then re-launch.

### Configuration

Set environment variables before launching:

| Variable | Default | Purpose |
|----------|---------|---------|
| `SKIP_API_KEY_UNSET` | _(unset)_ | Set to `1` to keep `ANTHROPIC_API_KEY` (for API-key auth) |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` (set by run-team.sh) | Required for native agent teams. See [Experimental Features](#experimental-features). |

---

## Plan Files and Multi-Agent Work

Plan files (`.plan.llm`) are how Claude tracks complex work. They live in `docs/spec/.llm/plans/`.

### When Claude creates plan files

Claude creates a plan file when starting any significant task (more than a quick fix). The plan tracks:

- What specs and rules were read
- What files will be modified or created
- Implementation steps and their status
- Decisions made and why
- Blockers encountered

### Plan templates

Templates are provided for common workflows:

| Template | Use Case |
|----------|----------|
| `idea.plan.llm` | Start here for new projects -- idea to working project (research, spec, plan, build) |
| `fullstack.plan.llm` | Full-stack feature (DB, Service, API, Frontend, E2E) with parallel execution |
| `feature.plan.llm` | Backend-focused feature implementation (6 phases) |
| `codegen.plan.llm` | Spec-first code generation (requires spec before code) |
| `requirements.plan.llm` | Multi-session requirement gathering producing a spec |
| `review.plan.llm` | Review/iteration cycle with quality gates and escape hatch |
| `bugfix.plan.llm` | Bug investigation, fix, and regression test |
| `self-review.plan.llm` | System self-review -- audit and improve the LLM orchestration system |
| `plan.template.llm` | Generic -- any task |
| `task.template.md` | Task file for the agent team queue (not a plan file) |

### Reviewing plan files

Plan files are committed to git, so you can:
- Review what Claude planned before it starts
- See the decision log after work is complete
- Understand the rationale behind implementation choices
- Track which specs and rules were consulted

---

## Review Loops and Iteration

The review loop protocol ensures quality through repeated assessment and improvement cycles. This is inspired by iterative agent patterns where each cycle focuses on one task, verifies it, and records learnings.

### How it works

1. **Read**: Load PROGRESS.md and relevant rules for context
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

`PROGRESS.md` in the `.llm/` directory is the persistent memory across all agent sessions. It solves the problem of LLMs losing context between sessions.

### Sections

1. **Codebase Patterns** -- Curated, deduplicated patterns and conventions. Every agent reads this before starting work.
2. **Architecture Decisions** -- Significant design choices with context and rationale.
3. **Known Issues** -- Tracked bugs and tech debt.
4. **Failed Approaches** -- Approaches that were tried and did not work, preventing repeated mistakes.
5. **Environment Quirks** -- Platform-specific gotchas and workarounds.

### How agents use it

- **Before work**: Read Codebase Patterns to inherit institutional knowledge
- **During work**: Note patterns and gotchas as they are discovered
- **After work**: Update relevant sections with learnings

### Benefits

- Prevents repeated mistakes across sessions
- Builds a knowledge base that improves over time
- New agents instantly inherit context from all previous work
- Patterns are consolidated and deduplicated, not just appended

---

## Writing Spec Files

Spec files are markdown documents that tell Claude (and other LLMs) how your system works. They replace the need to explain the same things over and over in prompts.

### Where specs live

```
docs/spec/
└── biz/                # Business specs (features, PRDs, decisions, ADRs)
```

Technical patterns and coding conventions that were formerly in `docs/spec/framework/` now live in `.claude/rules/`, where they are auto-loaded by Claude Code based on context.

### What to put in specs

Specs should document **decisions, patterns, and constraints** -- the things Claude needs to know but can't infer from code alone:

- Feature requirements and PRDs
- Business rules (validation logic, workflow steps)
- User stories and acceptance criteria
- Market and competitive analysis
- Architecture Decision Records (ADRs)

### What NOT to put in specs

- Generic coding patterns (put those in `.claude/rules/` instead)
- Auto-generated documentation (let tools generate that)
- Code snippets that could become stale (reference the source instead)
- Implementation details that change frequently

### Creating a new spec

1. Create the file in `docs/spec/biz/`
2. Or use a skill: `/requirements`, `/prd`, or `/adr`

---

## Software Lifecycle

llm-init supports a complete software development lifecycle. Each phase has dedicated skills.

### The Lifecycle

```
Requirements    Design         Implement      Review            Release
    |              |               |              |                |
/requirements   /plan          /decompose     /review          /release
/prd            /adr           /launch        /architecture-review
                /api-design    /new-task       /security-review
                /data-model                    /performance-audit
```

### Phase 1: Requirements Gathering

Use `/requirements` to start an interactive Q&A session. Claude will:

1. Ask broad discovery questions (purpose, users, use cases)
2. Narrow scope and boundaries (in/out of scope, inputs/outputs)
3. Present design decisions with tradeoffs (storage, API style, auth)
4. Explore edge cases and failure modes
5. Produce a formal specification document
6. Iterate with you until the spec is approved

The output is a spec document in `docs/spec/biz/` that drives all subsequent work.

Alternatively, use `/prd` for a streamlined pipeline: interactive discovery (2-4 rounds of lettered-choice Q&A) produces a PRD document and then converts it directly into sized task files ready for parallel execution.

### Phase 2: Design & Architecture

Use `/plan` with the `codegen.plan.llm` template to create a technical spec from the requirements. Use `/adr` to document major architecture decisions as Architecture Decision Records. Use `/api-design` to design API contracts and `/data-model` to design database schemas.

ADRs capture:
- **Context**: What forces are at play
- **Decision**: What was chosen
- **Options**: What else was considered
- **Consequences**: What we gain and sacrifice

ADRs live in `docs/spec/biz/adr-NNN-*.md` and prevent decisions from being re-litigated.

### Phase 3: Implementation

Use `/decompose` to break the approved spec into parallel tasks, then `/launch` to execute them with the agent team. The spec-first protocol (defined in the `spec-first` rule) ensures every implementation references the approved spec.

### Phase 4: Review

Use complementary review skills:
- `/review` -- Quality gates (build, test, lint) + code quality audit
- `/architecture-review` -- Assess decisions, tradeoffs, edge cases, consistency
- `/security-review` -- Systematic security assessment (input validation, auth, data protection, dependencies)
- `/performance-audit` -- Profile and optimize performance bottlenecks

### Phase 5: Release

Use `/release` to generate a checklist, changelog, and validation steps. Claude will:
1. Run all quality gates
2. Generate a changelog from commits
3. Walk through the pre-release checklist
4. Create the tag after your approval

---

## Self-Improvement

Claude is encouraged to improve the LLM orchestration system itself. This means:

- **Fixing rules**: If a rule is wrong or incomplete, Claude updates it
- **Recording patterns**: New conventions go into PROGRESS.md
- **Improving templates**: Better plan templates for common workflows
- **Proposing changes**: If the orchestration workflow could be better, Claude can modify it

### Guard rails

- Rule/spec improvements are committed separately from feature code
- Information is added, not replaced (unless clearly wrong)
- Existing functionality is not broken when improving documentation

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

MCP (Model Context Protocol) servers give Claude direct tool access to external systems. They are configured in `.mcp.json` at the project root.

### Included servers

| Server | What Claude Can Do |
|--------|--------------------|
| **github** | Create issues, PRs, read reviews, manage repositories |
| **postgres** | Query the database, inspect schemas |
| **redis** | Read/write cache entries (official `@redis/mcp`) |
| **context7** | Look up current library/framework documentation |
| **playwright** | Browser automation, E2E testing, visual verification |
| **memory** | Local knowledge graph for cross-session entity tracking (`@modelcontextprotocol/server-memory`) |
| **terraform** | Query Terraform Registry for provider docs, resource schemas, module metadata |
| **eslint** | Run ESLint analysis, get lint rule documentation and fix suggestions |
| **aws-documentation** | Access latest AWS documentation, API references, and getting started guides |

### Authenticating GitHub

The GitHub MCP server uses a Personal Access Token (PAT):

1. Create a PAT at [github.com/settings/tokens](https://github.com/settings/tokens) with appropriate scopes (`repo`, `read:org`, etc.)
2. Set the environment variable before starting Claude Code:
   ```bash
   export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
   ```
3. Optionally add it to your shell profile (`~/.bashrc`, `~/.zshrc`) or a `.env` file

### Adding/removing servers

Edit `.mcp.json` to add or remove MCP servers. Each server entry specifies the command to start it and any required environment variables.

### Servers that don't need infrastructure

`github`, `context7`, `playwright`, `memory`, `terraform`, `eslint`, and `aws-documentation` work without Docker. Only `postgres` and `redis` require the Docker infrastructure to be running.

**Note:** The `aws-documentation` server requires `uvx` (install via `pip install uv`). All other servers use `npx`.

---

## Codex CLI Compatibility

This project works with both **Claude Code** and **OpenAI Codex CLI** out of the box.

### How it works

| Component | Claude Code | Codex CLI |
|-----------|-------------|-----------|
| **Entry point** | `CLAUDE.md` | `AGENTS.md` |
| **Configuration** | `.claude/settings.json` | `.codex/config.toml` |
| **Skills** | `.claude/skills/*/SKILL.md` | `.agents/skills/*/SKILL.md` (mirrored copy) |
| **MCP servers** | `.mcp.json` | `[mcp_servers]` in `.codex/config.toml` |
| **Agents** | `.claude/agents/*.md` | Not applicable (Codex uses Agents SDK) |
| **Rules** | `.claude/rules/*.md` | Referenced in `AGENTS.md` |

The SKILL.md format is **identical** between Claude Code and Codex CLI. The `allowed-tools` frontmatter field used by Claude Code is simply ignored by Codex.

### Using with Codex CLI

```bash
# Codex reads AGENTS.md automatically
codex

# Or if AGENTS.md is missing, it falls back to CLAUDE.md
# (configured via project_doc_fallback_filenames in .codex/config.toml)
```

### Customizing for Codex

Edit `.codex/config.toml` to change:
- `model`: The default model (e.g., `o4-mini`, `gpt-5-codex`)
- `approval_policy`: `"suggest"`, `"auto-edit"`, or `"full-auto"`
- MCP server configuration

---

## Experimental Features

Some features used by llm-init require experimental flags in Claude Code. These flags enable capabilities that may become stable in future releases.

### Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`)

The native Agent Teams feature -- where the team-lead agent orchestrates teammate agents -- requires this environment variable:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

**How it is used:**
- `run-team.sh` sets this automatically, so launching from the script requires no manual setup
- The `/launch` skill invokes the team-lead agent via `claude --agent team-lead`, which also requires this flag
- If you invoke team-lead manually, you must set this variable yourself

**What it enables:**
- The team-lead agent can spawn teammate agents using the Task tool
- Teammate agents run with their own turn budgets, tool sets, and instructions
- The team-lead can monitor teammate progress, handle failures, and coordinate dependencies

**Without this flag:**
- Agent definitions in `.claude/agents/` are ignored
- `claude --agent <name>` will fail
- Skills and rules still work normally

**Current status:** This is an experimental feature. The flag name and behavior may change as Claude Code evolves. When Agent Teams becomes a stable feature, this flag will no longer be required and `run-team.sh` will be updated accordingly.

---

## Customization Guide

After running `setup.sh`, here is what to customize and in what order.

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

### Step 2: Edit the agent guide

Customize `.claude/rules/agent-guide.md` with your project specifics:

- **Project description**: What you are building
- **Goal**: Current milestone
- **Tech stack**: Your actual stack (remove/replace the defaults)
- **Quality gates**: Uncomment or write the build/test/lint commands for your project

This is the most important customization step. The agent guide is read by every agent before starting work.

### Step 3: Edit `CLAUDE.md`

Add any project-specific instructions. This is read by Claude at every session start, so keep it concise. Good additions:

- Tech stack summary (e.g., "This is a Go backend with a React frontend")
- Build/test commands (e.g., "Run tests with `make test`")
- Project-specific rules (e.g., "Always use the `tenant` package for multi-tenancy")

### Step 4: Customize rules

Review the rules in `.claude/rules/` and customize them for your project:

- **Remove** rules that do not apply (e.g., `go-patterns` if you are not using Go)
- **Edit** rules to match your conventions (e.g., adjust performance budgets in `performance.md`)
- **Add** new rules for your domain (e.g., `billing.md`, `search.md`)

### Step 5: Add business specs

Create specs in `docs/spec/biz/` for your features and business requirements. Use the skills to help:

```
/requirements User management system with roles and invite flow
/prd Build a billing integration with Stripe
/adr Switch from session tokens to JWT for stateless auth
```

### Step 6: Adjust infrastructure

- Remove services you don't need from `docker-compose.yml`
- Remove corresponding MCP servers from `.mcp.json`
- Update connection strings in `docs/spec/.llm/INFRASTRUCTURE.md`

### Step 7: Customize agents (optional)

Review `.claude/agents/` and adjust:
- Turn budgets if agents run out of turns on complex tasks
- Agent instructions for project-specific guidance
- Add new specialized agents for your domain

---

## Day-to-Day Workflow

### Starting a coding session

```bash
cd your-project
claude
```

Claude reads `CLAUDE.md` automatically and loads relevant rules. You're ready to go.

### Asking Claude to build something

Just describe what you want. The rules and specs handle the rest:

```
Add a REST API for managing billing plans with CRUD endpoints,
including validation and proper error handling.
```

Claude will load relevant rules, create a plan, and implement.

### Full lifecycle (requirements to release)

```
/requirements User management system with roles and invite flow
# Answer questions interactively, approve the spec
/decompose Build user management from the approved spec
# Review the decomposition, approve
/launch
/status
/architecture-review
/security-review
/release 1.0.0
```

### Quick PRD-to-execution pipeline

```
/prd Build a notification system for email and in-app alerts
# Answer discovery questions (lettered choices: A, B, C, D)
# Review the generated PRD, provide feedback
# Tasks are created automatically
/launch
```

### Working interactively

```
/plan Redesign the authentication system
# Fill in the plan, get approval, implement
/review
```

### Architecture review and ADR

```
/architecture-review Authentication and authorization system
# Review findings, then document key decisions:
/adr Switch from session tokens to JWT for stateless auth
```

### Pausing and resuming

```
/shelve
# Later, in a new session:
/status
```

### Reviewing what Claude did

After Claude completes work:
1. Check the plan file in `docs/spec/.llm/plans/` for decisions and rationale
2. Review the code changes with `git diff`
3. Move the plan to `completed/` when satisfied

### When Claude doesn't follow conventions

If Claude generates code that does not match your expectations:
1. Point it to the specific rule: "Please follow the patterns in the api-design rule"
2. If it happens repeatedly, strengthen the language in the relevant rule file
3. Add specific anti-patterns to the appropriate rule

---

## Troubleshooting

### Claude doesn't seem to read the rules

- Verify `CLAUDE.md` exists at the project root
- Verify `.claude/rules/` contains the rule files
- Try explicitly: "Read the agent-guide rule and follow its instructions"

### Agent Teams won't start

- Verify `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set in your environment
- Use `run-team.sh` which sets this automatically
- Verify task files exist in `docs/spec/.llm/tasks/backlog/`
- Run `/launch` which performs pre-flight checks before launching

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

Archive completed plans:

```bash
bash docs/spec/.llm/scripts/archive.sh "phase-1-complete"
```

Or ask Claude: "Archive all completed plan files."

### Tasks stuck in `in_progress`

If the team-lead was interrupted mid-execution:

```bash
# Reset all tasks back to backlog
bash docs/spec/.llm/scripts/reset.sh

# Re-launch
bash docs/spec/.llm/scripts/run-team.sh
```

### Setup script skips files

The setup script won't overwrite existing files. If you need to regenerate:

```bash
# Remove the specific file, then re-run
rm .claude/rules/agent-guide.md
bash llm-init/setup.sh my-project github.com/myorg/my-project
```

### Go module path is wrong

If you ran setup without specifying the Go module path, the agent guide will have `github.com/yourorg/<project-name>` as placeholders. Find and replace:

```bash
grep -r "github.com/yourorg" .claude/ docs/spec/
# Then update to your actual module path
```
