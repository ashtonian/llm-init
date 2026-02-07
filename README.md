# LLM Init

Bootstrap your project for LLM-driven development with [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

One command sets up spec-driven documentation, agent teams, plan-based coordination, knowledge accumulation, MCP servers, local infrastructure, and code conventions -- so Claude follows your patterns from the first prompt and improves with every iteration.

Comes with opinionated guides for **Go** and **TypeScript/React**, but the system is designed to be extended to any stack.

**[Full User Guide](./USER-GUIDE.md)** | [Setup](#quick-start) | [What You Get](#what-gets-created)

## Quick Start

```bash
# Clone into your project
git clone https://github.com/ashtonian/llm-init.git

# Enter your project root
cd /path/to/your-project

# Run setup (project-name is required, go-module-path is optional)
bash llm-init/setup.sh my-app github.com/myorg/my-app

# Or with Go project scaffolding (Makefile, Dockerfile, CI, GoReleaser, linter):
bash llm-init/setup.sh --go my-app github.com/myorg/my-app

# Clean up
rm -rf llm-init/

# Start infrastructure (optional -- only needed for database/cache work)
docker compose -f docs/spec/.llm/docker-compose.yml up -d
```

## What Gets Created

```
your-project/
├── CLAUDE.md                              # Claude Code auto-reads this -- entry point
├── .claude/
│   ├── settings.json                      # Pre-approved permissions for autonomous operation
│   ├── skills/                            # Skills (slash commands) for Claude Code
│   │   ├── decompose/SKILL.md            #   /decompose -- Break request into parallel tasks
│   │   ├── new-task/SKILL.md             #   /new-task -- Create a single task file
│   │   ├── status/SKILL.md              #   /status -- Task queue dashboard
│   │   ├── launch/SKILL.md             #   /launch -- Pre-flight checks + launch team lead
│   │   ├── plan/SKILL.md               #   /plan -- Select and create a plan template
│   │   ├── review/SKILL.md             #   /review -- Run quality gates
│   │   ├── shelve/SKILL.md             #   /shelve -- Checkpoint with structured handoff
│   │   ├── requirements/SKILL.md       #   /requirements -- Iterative requirement gathering
│   │   ├── architecture-review/SKILL.md #  /architecture-review -- Assess decisions
│   │   ├── adr/SKILL.md                #   /adr -- Create Architecture Decision Record
│   │   ├── security-review/SKILL.md    #   /security-review -- Security assessment
│   │   ├── prd/SKILL.md                #   /prd -- Interactive PRD -> sized task files
│   │   ├── release/SKILL.md            #   /release -- Release preparation & changelog
│   │   ├── api-design/SKILL.md         #   /api-design -- Design API contracts
│   │   ├── data-model/SKILL.md         #   /data-model -- Design database schemas
│   │   ├── performance-audit/SKILL.md  #   /performance-audit -- Profile & optimize
│   │   ├── incident-response/SKILL.md  #   /incident-response -- Incident investigation
│   │   ├── refactor/SKILL.md           #   /refactor -- Analyze & plan refactoring
│   │   ├── migrate/SKILL.md            #   /migrate -- Plan database migrations
│   │   └── dependency-audit/SKILL.md   #   /dependency-audit -- Audit dependencies
│   ├── agents/                            # Native Claude Code agents
│   │   ├── team-lead.md                  #   Orchestrator (opus, 500 turns, delegates)
│   │   ├── implementer.md               #   Feature builder (opus, 150 turns)
│   │   ├── reviewer.md                  #   Code reviewer (opus, 75 turns)
│   │   ├── security.md                  #   Security auditor (opus, 75 turns)
│   │   ├── debugger.md                  #   Bug fixer (opus, 100 turns)
│   │   ├── tester.md                    #   Test specialist (opus, 100 turns)
│   │   ├── frontend.md                  #   Frontend/UI specialist (opus, 150 turns)
│   │   ├── api-designer.md              #   API contract designer (opus, 100 turns)
│   │   ├── data-modeler.md              #   Database schema designer (opus, 100 turns)
│   │   ├── architect.md                 #   System architect (opus, 100 turns)
│   │   ├── benchmarker.md               #   Performance profiler (opus, 100 turns)
│   │   ├── ux-researcher.md             #   UX research specialist (opus, 75 turns)
│   │   ├── release-engineer.md          #   Release automation (opus, 75 turns)
│   │   ├── devops.md                    #   Infrastructure specialist (opus, 100 turns)
│   │   ├── requirements-analyst.md      #   Requirements gathering (opus, 100 turns)
│   │   ├── refactorer.md               #   Technical debt elimination (opus, 100 turns)
│   │   ├── migration-specialist.md      #   Database schema evolution (opus, 150 turns)
│   │   └── spec-writer.md              #   Technical specification author (opus, 100 turns)
│   └── rules/                             # Auto-loaded context rules
│       ├── agent-guide.md                #   Project tech stack & quality gates
│       ├── spec-first.md                 #   Spec-first protocol
│       ├── go-patterns.md                #   Go conventions (paths: **/*.go)
│       ├── typescript-patterns.md        #   TypeScript patterns (paths: **/*.ts, **/*.tsx)
│       ├── performance.md                #   Performance & code quality standards
│       ├── testing.md                    #   Testing patterns (paths: **/*_test.*, **/*.test.*)
│       ├── security.md                   #   Security standards (OWASP, input validation)
│       ├── observability.md              #   Logging, tracing, metrics, alerting
│       ├── multi-tenancy.md              #   Multi-tenant SaaS patterns
│       ├── infrastructure.md             #   Docker, Kubernetes, deployment patterns
│       ├── api-design.md                 #   REST/gRPC API design conventions
│       ├── auth-patterns.md              #   Authentication & authorization patterns
│       ├── data-patterns.md              #   Database design & data access patterns
│       ├── frontend-architecture.md      #   Component architecture & state management
│       ├── ux-standards.md               #   Accessibility, responsive design, UX patterns
│       ├── error-handling.md             #   Error classification, retry strategies, circuit breakers
│       ├── code-quality.md               #   Complexity limits, naming, coverage targets
│       └── git-workflow.md               #   Branch naming, commits, PR conventions
├── cmd/{project-name}/                    # [--go] Application entry point
│   ├── main.go                            #   Main with run() pattern
│   └── main_test.go                       #   Entry point tests
├── internal/greeter/                      # [--go] Example package -- reference for new packages
│   ├── doc.go                             #   Package docs with usage example
│   ├── model.go                           #   Domain model with validation
│   ├── repository.go                      #   Repository interface + memory implementation
│   ├── service.go                         #   Business logic with functional options
│   └── service_test.go                    #   Table-driven tests
├── Makefile                               # [--go] Build, test, lint, fmt, vet, clean, snapshot
├── Dockerfile                             # [--go] Multi-stage, multi-arch build
├── .goreleaser.yml                        # [--go] Multi-arch release automation
├── .golangci.yml                          # [--go] Linter configuration
├── .github/workflows/                     # [--go] CI/CD pipelines
│   ├── ci.yml                             #   Build, test, lint on PR
│   └── release.yml                        #   GoReleaser on tag push
├── renovate.json                          # [--go] Dependency update automation
├── AGENTS.md                              # Codex CLI entry point (Codex reads this)
├── .codex/
│   └── config.toml                        # Codex CLI configuration with MCP servers
├── .agents/
│   └── skills/                            # Mirrored skills for Codex CLI compatibility
│       └── (same 20 skills as .claude/skills/)
├── .mcp.json                              # 9 MCP servers (github, postgres, redis, context7, playwright, memory, terraform, eslint, aws-documentation)
├── .gitignore                             # Go, TypeScript, Docker, IDE, env, LLM workspace exclusions
└── docs/spec/
    ├── biz/                                # Business specs
    │   └── README.md                       # Business features, PRDs, market research guide
    └── .llm/
        ├── PROGRESS.md                     # Knowledge accumulation: patterns, decisions, issues
        ├── STRATEGY.md                     # Project decomposition for parallel agents
        ├── INFRASTRUCTURE.md               # Docker services documentation
        ├── docker-compose.yml              # PostgreSQL 16, Redis 7, NATS 2
        ├── nats.conf                       # NATS JetStream config
        ├── templates/                      # Plan + task templates
        │   ├── idea.plan.llm              #   Idea -> working project (0->100)
        │   ├── fullstack.plan.llm         #   Full-stack feature (DB->API->UI->E2E)
        │   ├── feature.plan.llm           #   Backend feature
        │   ├── review.plan.llm            #   Review & iteration cycle
        │   ├── bugfix.plan.llm            #   Bug investigation & fix
        │   ├── self-review.plan.llm       #   System self-audit
        │   ├── codegen.plan.llm           #   Spec-first code generation
        │   ├── requirements.plan.llm      #   Multi-session requirement gathering
        │   ├── plan.template.llm          #   Generic task
        │   ├── task.template.md           #   Task template for agent task queue
        │   └── example-task.md            #   Filled-in example task (reference)
        ├── scripts/                        # Utility scripts
        │   ├── run-team.sh                #   Launch team lead agent for parallel execution
        │   ├── status.sh                  #   Task queue dashboard
        │   ├── reset.sh                   #   Reset tasks to backlog
        │   └── archive.sh                 #   Archive completed tasks and logs
        ├── archive/                        # Archived completed runs
        ├── tasks/                          # Agent task queue
        │   ├── backlog/                   #   Tasks ready to be claimed
        │   ├── in_progress/               #   Currently being worked on
        │   ├── completed/                 #   Successfully finished
        │   └── blocked/                   #   Failed or blocked tasks
        ├── plans/                          # Active work plans
        ├── completed/                      # Archived completed plans
        └── logs/                           # Agent execution logs
```

## How It Works

```
You prompt Claude ──> Claude reads CLAUDE.md (automatic)
                           │
                           ▼
                      Rules auto-load based on file paths
                      ├── go-patterns.md (when editing .go files)
                      ├── typescript-patterns.md (when editing .ts/.tsx)
                      ├── testing.md (when editing test files)
                      ├── performance.md (always available)
                      ├── spec-first.md (always available)
                      └── agent-guide.md (always available)
                           │
                           ▼
                      Creates plan file in .llm/plans/
                           │
                           ▼
                      Implements following all spec conventions
                           │
                           ▼
                      Runs quality gates (build, test, lint)
                           │
                           ▼
                      Updates PROGRESS.md with learnings
                           │
                           ▼
                      Commits ──> Next iteration picks up where this left off
```

**The key ideas**:
- **Full software lifecycle.** Requirements gathering -> design -> implementation -> review -> release, with dedicated skills for each phase.
- **Agent Teams.** The team lead agent (opus, 500 turns) orchestrates parallel execution by spawning 17 specialist agents (implementer, reviewer, security, debugger, tester, frontend, api-designer, data-modeler, architect, benchmarker, ux-researcher, release-engineer, devops, requirements-analyst, refactorer, migration-specialist, spec-writer) across feature branches.
- **Rules replace repeated prompt instructions.** Document your patterns once in `.claude/rules/`, Claude auto-loads them based on file paths.
- **Knowledge accumulates across sessions.** Each session reads and writes to PROGRESS.md, building institutional knowledge.
- **User approval at every major step.** Research -> spec -> plan -> build, with human checkpoints at each transition.
- **Review loops ensure quality.** Every change passes quality gates (build, test, lint) before completion.
- **Architecture decisions are documented.** ADRs capture context, options, and rationale so decisions aren't re-litigated.
- **Concurrent execution is encouraged.** Independent tasks run in parallel via agent teams with branch isolation.

## What's Included

| Component | Purpose |
|-----------|---------|
| **CLAUDE.md** | Auto-read by Claude Code. Entry point with execution modes, skill references, principles. |
| **`.claude/settings.json`** | Pre-approved permissions for autonomous operation (Go, TS, Docker, Git, GitHub CLI, npm, linters, test runners, web search, agent teams) |
| **20 Skills** | Slash commands: task management (`/prd`, `/decompose`, `/new-task`, `/status`, `/launch`, `/plan`, `/review`, `/shelve`) + lifecycle (`/requirements`, `/architecture-review`, `/adr`, `/security-review`, `/release`) + design (`/api-design`, `/data-model`, `/performance-audit`, `/incident-response`) + engineering (`/refactor`, `/migrate`, `/dependency-audit`) |
| **18 Agents** | Native Claude Code agents: team-lead (opus orchestrator) + 17 specialists (implementer, reviewer, security, debugger, tester, frontend, api-designer, data-modeler, architect, benchmarker, ux-researcher, release-engineer, devops, requirements-analyst, refactorer, migration-specialist, spec-writer) -- all opus |
| **18 Rules** | Auto-loaded context: agent-guide, spec-first, go-patterns, typescript-patterns, performance, testing, security, observability, multi-tenancy, infrastructure, api-design, auth-patterns, data-patterns, frontend-architecture, ux-standards, error-handling, code-quality, git-workflow |
| **PROGRESS.md** | 5-section knowledge base: patterns, architecture decisions, known issues, failed approaches, environment quirks |
| **Plan Templates** | 9 templates: idea-to-project, full-stack feature, backend feature, review cycle, bugfix, self-review, spec-first codegen, requirements gathering, generic |
| **Docker Compose** | PostgreSQL 16, Redis 7, NATS 2 with health checks, resource limits, data persistence |
| **MCP Config** | 9 pre-configured servers: GitHub, Postgres, Redis (official), Context7 (library docs), Playwright (browser), Memory (knowledge graph), Terraform, ESLint, AWS Documentation |
| **Codex CLI** | AGENTS.md entry point, .codex/config.toml, .agents/skills/ mirror -- works with both Claude Code and OpenAI Codex CLI |
| **.gitignore** | Comprehensive template covering Go, TypeScript, Docker, IDE, env files, LLM workspace |

## Best For

This template is optimized for projects using **Go backends** and **TypeScript/React frontends** with Docker-based infrastructure. The included code guides are specific to these stacks.

**For other languages** (Python, Rust, Java, etc.): the orchestration system, plan templates, review loops, and knowledge accumulation work with any stack. Add language-specific rules in `.claude/rules/` with appropriate path scoping.

## After Setup

1. **Start using Claude** -- it works immediately with the included specs
2. **Customize `.claude/rules/agent-guide.md`** -- set your project name, goal, and tech stack
3. **Add business specs** -- feature requirements, user stories in `docs/spec/biz/`
4. **Add language rules** -- add path-scoped rules in `.claude/rules/` for your stack
5. **Start infrastructure** -- `docker compose -f docs/spec/.llm/docker-compose.yml up -d`
6. **Let Claude improve** -- the agent updates PROGRESS.md and discovers better patterns as it works

See the **[User Guide](./USER-GUIDE.md)** for detailed walkthroughs of each step.

## License

[MIT](./LICENSE)
