# LLM Init

Bootstrap your project for LLM-driven development with [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

One command sets up spec-driven documentation, iterative review loops, plan-based coordination, knowledge accumulation, MCP servers, local infrastructure, and code conventions — so Claude follows your patterns from the first prompt and improves with every iteration.

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

# Clean up
rm -rf llm-init/

# Start infrastructure (optional — only needed for database/cache work)
docker compose -f docs/spec/.llm/docker-compose.yml up -d
```

## What Gets Created

```
your-project/
├── CLAUDE.md                              # Claude Code auto-reads this — entry point
├── .claude/
│   ├── settings.json                      # Pre-approved permissions for autonomous operation
│   └── commands/                          # Custom slash commands for Claude Code
│       ├── decompose.md                   #   /decompose — Break request into parallel tasks
│       ├── new-task.md                    #   /new-task — Create a single task file
│       ├── status.md                      #   /status — Task queue dashboard
│       ├── launch.md                      #   /launch — Pre-flight checks + launch agents
│       ├── plan.md                        #   /plan — Select and create a plan template
│       ├── review.md                      #   /review — Run quality gates
│       └── shelve.md                      #   /shelve — Checkpoint with structured handoff
├── .mcp.json                              # 6 MCP servers (github, postgres, redis, sequential-thinking, context7, playwright)
├── .gitignore                             # Go, TypeScript, Docker, IDE, env, LLM workspace exclusions
└── docs/spec/
    ├── LLM.md                             # Master orchestration guide for LLMs
    ├── LLM-STYLE-GUIDE.md                 # How to write LLM-friendly spec files
    ├── SPEC-WRITING-GUIDE.md              # How to write specification documents
    ├── README.md                           # Human-readable documentation index
    ├── llms.txt                            # Quick navigation index
    ├── framework/                          # Layer 1: Foundation patterns
    │   ├── README.md                       # Framework spec index
    │   ├── go-generation-guide.md          # Go code conventions
    │   ├── typescript-ui-guide.md          # TypeScript/UI/UX patterns
    │   ├── performance-guide.md            # Performance & code quality standards
    │   ├── testing-guide.md                # Testing patterns, fixtures, mocking
    │   └── llms.txt                        # Framework navigation index
    ├── biz/                                # Business specs
    │   └── README.md                       # Business features, PRDs, market research guide
    └── .llm/
        ├── README.md                       # Coordination guide
        ├── PROGRESS.md                     # Knowledge accumulation & iteration log
        ├── STRATEGY.md                     # Project decomposition for parallel agents
        ├── AGENT_GUIDE.md                  # Agent context (inlined into every prompt)
        ├── INFRASTRUCTURE.md               # Docker services documentation
        ├── MCP-RECOMMENDATIONS.md          # MCP server recommendations
        ├── SKILLS.md                       # Agent skills and capabilities catalog
        ├── docker-compose.yml              # PostgreSQL 16, Redis 7, NATS 2
        ├── nats.conf                       # NATS JetStream config
        ├── plans/                          # Active work plans
        ├── completed/                      # Archived completed plans
        ├── templates/                      # Plan + task templates
        │   ├── idea.plan.llm              #   Idea → working project (0→100)
        │   ├── fullstack.plan.llm         #   Full-stack feature (DB→API→UI→E2E)
        │   ├── feature.plan.llm           #   Backend feature
        │   ├── review.plan.llm            #   Review & iteration cycle
        │   ├── bugfix.plan.llm            #   Bug investigation & fix
        │   ├── self-review.plan.llm       #   System self-audit
        │   ├── plan.template.llm          #   Generic task
        │   └── task.template.md           #   Task template for parallel agent queue
        ├── scripts/                        # Utility + agent harness scripts
        │   ├── move_nav_to_top.py         #   Reformats docs for LLM navigation
        │   ├── run-parallel.sh            #   Launch N parallel autonomous agents
        │   ├── run-agent.sh               #   Single autonomous agent loop
        │   ├── run-single-task.sh         #   Run one task autonomously
        │   ├── run-interactive.sh         #   Interactive session with task context
        │   ├── status.sh                  #   Task queue dashboard
        │   └── reset.sh                   #   Reset tasks to backlog
        ├── tasks/                          # Parallel agent task queue
        │   ├── backlog/                   #   Tasks ready to be claimed
        │   ├── in_progress/               #   Currently being worked on
        │   ├── completed/                 #   Successfully finished
        │   └── blocked/                   #   Failed or blocked tasks
        └── logs/                           # Agent execution logs
```

## How It Works

```
You prompt Claude ──> Claude reads CLAUDE.md (automatic)
                           │
                           ▼
                      Reads PROGRESS.md (prior learnings)
                           │
                           ▼
                      Reads docs/spec/LLM.md (orchestration)
                           │
                           ▼
                      Reads framework specs (execution order)
                      ├── go-generation-guide.md (for Go code)
                      ├── typescript-ui-guide.md (for frontend)
                      ├── performance-guide.md (for perf-sensitive work)
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
- **Specs replace repeated prompt instructions.** Document your patterns once, Claude follows them every time.
- **Knowledge accumulates across sessions.** Each session reads and writes to PROGRESS.md, building institutional knowledge.
- **User approval at every major step.** Research → spec → plan → build, with human checkpoints at each transition.
- **Review loops ensure quality.** Every change passes quality gates (build, test, lint) before completion.
- **Concurrent execution is encouraged.** Independent tasks run in parallel via subagents and feature branches. The parallel agent harness automates this with task queues, git worktrees, and atomic claiming.
- **Self-improvement is built in.** The agent can review and improve specs, templates, and its own orchestration system.

## What's Included

| Component | Purpose |
|-----------|---------|
| **CLAUDE.md** | Auto-read by Claude Code. Entry point to the spec system. |
| **`.claude/settings.json`** | Pre-approved permissions for autonomous operation (Go, TS, Docker, Git, GitHub CLI, npm, linters, test runners, web search, subagents) |
| **LLM.md** | Master orchestration: idea-to-project pipeline, task classification, execution order, review loop, concurrent coordination, self-improvement |
| **Go Generation Guide** | 800+ lines: functional options, generics, registry pattern, interfaces, anti-patterns |
| **TypeScript/UI Guide** | Component architecture, state management, accessibility, performance budgets, responsive design, testing |
| **Performance Guide** | Memory allocation strategies, profiling discipline, latency budgets, code quality standards |
| **Business Features Guide** | Feature specs, user stories, market research templates, competitive analysis, decision records |
| **PROGRESS.md** | 5-section knowledge base: patterns, architecture decisions, known issues, failed approaches, environment quirks |
| **Custom Commands** | 7 slash commands (`/decompose`, `/new-task`, `/status`, `/launch`, `/plan`, `/review`, `/shelve`) |
| **Skills Reference** | SKILLS.md: consolidated catalog of commands, MCP servers, scripts, templates, workflows |
| **Parallel Agent Harness** | Task queue, git worktree isolation, atomic claiming, autonomous batch execution with N parallel agents |
| **Plan Templates** | 7 templates: idea-to-project, full-stack feature, backend feature, review cycle, bugfix, self-review, generic |
| **Docker Compose** | PostgreSQL 16, Redis 7, NATS 2 with health checks, resource limits, data persistence |
| **MCP Config** | 6 pre-configured servers: GitHub, Postgres, Redis, sequential-thinking, Context7 (library docs), Playwright (browser) |
| **.gitignore** | Comprehensive template covering Go, TypeScript, Docker, IDE, env files, LLM workspace |

## Best For

This template is optimized for projects using **Go backends** and **TypeScript/React frontends** with Docker-based infrastructure. The included code guides are specific to these stacks.

**For other languages** (Python, Rust, Java, etc.): the orchestration system, plan templates, review loops, and knowledge accumulation work with any stack. Replace or add language-specific guides in `docs/spec/framework/` following the included `SPEC-WRITING-GUIDE.md`.

## After Setup

1. **Start using Claude** — it works immediately with the included specs
2. **Add framework specs** — API design, error handling, models, auth (see [User Guide: Writing Specs](./USER-GUIDE.md#writing-spec-files))
3. **Add business specs** — feature requirements, user stories in `docs/spec/biz/`
4. **Add platform specs** — your project's specific features and domain logic
5. **Update navigation** — keep `LLM.md` and `llms.txt` current as you add specs
6. **Let Claude improve** — the agent can update specs and orchestration as it discovers better patterns

See the **[User Guide](./USER-GUIDE.md)** for detailed walkthroughs of each step.

## License

[MIT](./LICENSE)
