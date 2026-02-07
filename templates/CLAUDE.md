# Claude Code Instructions for {{PROJECT_NAME}}

## Execution Modes

| Mode | When | How |
|------|------|-----|
| **Parallel** (default) | Multi-step features, build work, any task with 2+ independent subtasks | Decompose -> task files -> launch team lead agent |
| **Interactive** | Complex decisions, ambiguous requirements, user wants to pair, initial project setup | Plan file workflow, step-by-step with user |
| **Quick** | Trivial fixes, one-liners, small edits | Just do it -- no plans or tasks needed |
| **Idea Pipeline** | Starting from scratch, 0->100 | Interactive for Research/Spec/Plan, then Parallel for Build |

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
- Brand-new project with empty agent guide (use Interactive for initial setup)

---

## Skills (slash commands)

| Skill | What It Does |
|-------|-------------|
| `/decompose` | Break a request into parallel tasks (75-150 turns each) |
| `/new-task` | Create a single task file in the backlog |
| `/status` | Task queue dashboard with analysis |
| `/launch` | Pre-flight checks + launch team lead agent |
| `/plan` | Select and create the right plan template |
| `/review` | Run quality gates and review current work |
| `/shelve` | Checkpoint work with structured handoff |
| `/requirements` | Iterative requirement gathering -> package spec |
| `/architecture-review` | Assess decisions, tradeoffs, edge cases |
| `/adr` | Create an Architecture Decision Record |
| `/security-review` | Security assessment of codebase or feature |
| `/prd` | Interactive PRD -> sized task files in backlog |
| `/release` | Release preparation with checklist and changelog |
| `/api-design` | Design API contracts with OpenAPI specifications |
| `/data-model` | Design database schemas, migrations, and data access layers |
| `/performance-audit` | Profile and optimize performance bottlenecks |
| `/incident-response` | Structured incident investigation and resolution |
| `/refactor` | Analyze codebase for technical debt and plan refactoring |
| `/migrate` | Plan and execute database schema migrations safely |
| `/dependency-audit` | Audit dependencies for vulnerabilities and plan upgrades |

---

## Execution Principles

- **Spec-First**: Before writing non-trivial code, verify a technical spec exists. If not, create one first. Cross-reference implementation against spec at each step.
- **Concurrency**: Execute tasks concurrently where possible -- parallel tool calls, subagents, errgroup patterns.
- **User Approval**: Always get user approval before implementing significant changes. Present your plan first.
- **Quality Gates**: Run quality gates defined in `.claude/rules/agent-guide.md` after every significant change. Never skip tests.
