# Proposal: Inspired Improvements to llm-init

## Inspirations

This proposal draws from two sources that demonstrate effective patterns for LLM-assisted development at scale:

1. **[Building a C Compiler with Claude](https://www.anthropic.com/engineering/building-c-compiler)** — Anthropic's engineering blog post describing how parallel Claude agents built a 100,000-line C compiler across 2,000+ sessions. Key contributions: agent specialization, grep-friendly output, context pollution prevention, pre-computed statistics, and oracle-based testing.

2. **[Ralph](https://github.com/snarktank/ralph)** (snarktank/ralph, 9.6k stars) — A minimal autonomous agent loop that repeatedly spawns fresh Claude/Amp instances to work through a PRD one user story at a time. Key contributions: fresh-context-per-iteration, append-only curated knowledge base, story sizing discipline, completion sentinels, automatic archiving, and distributed CLAUDE.md files.

---

## Proposed Changes

### 1. Curated "Codebase Patterns" Section in PROGRESS.md

**Inspiration:** Ralph's `progress.txt` has a structured "Codebase Patterns" section at the top that agents read first and contribute back to. Over many iterations, this becomes a distilled, deduplicated knowledge base.

**Current state:** PROGRESS.md is a flat iteration log. Knowledge accumulates but isn't curated.

**Change:** Restructure the PROGRESS.md template to have two distinct sections:
- **Top: Codebase Patterns** — Curated, deduplicated patterns that every agent reads before starting work. Agents consolidate repeated learnings here.
- **Bottom: Iteration Log** — Chronological record (existing behavior).

Add instructions in AGENT_GUIDE.md and run-agent.sh prompt to: (a) always read the Patterns section first, (b) after completing work, consolidate any reusable learnings from the iteration log into the Patterns section, removing duplicates.

**Impact:** High. Prevents knowledge rot and repeated mistakes. Each iteration gets smarter.

---

### 2. Fresh-Context Loop Mode

**Inspiration:** Both Ralph and the C Compiler project use a "lobotomized loop" — each iteration spawns a completely new agent with zero in-process state. This avoids context window exhaustion and hallucination drift.

**Current state:** `run-agent.sh` runs a loop but maintains the same session (with `--resume`). This is good for continuity but risks context degradation on long runs.

**Change:** Add a `run-fresh-loop.sh` script (or a `--fresh` flag to `run-agent.sh`) that:
- Spawns a new Claude instance per iteration (no `--resume`)
- Each iteration reads PROGRESS.md, picks one task, completes it, commits, updates PROGRESS.md, exits
- The loop continues until no tasks remain in backlog or a max iteration count is hit
- Complements (not replaces) the existing resume-based approach

**Impact:** Medium-high. Provides an alternative execution strategy for long-running autonomous work where context freshness matters more than session continuity.

---

### 3. Completion Sentinel Signal

**Inspiration:** Ralph uses `<promise>COMPLETE</promise>` as a machine-parseable stop signal. The outer loop greps for this exact string.

**Current state:** `run-agent.sh` checks for empty backlog to determine completion, which requires file system inspection between iterations.

**Change:** Define a completion sentinel (e.g., `RALPH_COMPLETE` or `ALL_TASKS_COMPLETE`) that agents output when they determine all tasks are done. Update `run-agent.sh` / `run-fresh-loop.sh` to:
- Capture agent stdout
- Grep for the sentinel as an early exit signal
- Fall back to file system check if no sentinel detected

Add the sentinel instruction to the agent prompt template.

**Impact:** Low-medium. Cleaner loop termination, especially in fresh-context mode where the agent can't maintain state about previous iterations.

---

### 4. Agent Role Specialization

**Inspiration:** The C Compiler project used specialized agents: core implementation, duplicate elimination, performance optimization, refactoring, and documentation maintenance. Each role had different prompts and priorities.

**Current state:** All agents use the same generic prompt. Specialization happens only through task assignment.

**Change:** Add role templates in `docs/spec/.llm/templates/roles/`:
- `implementer.md` — Focus on feature implementation, spec compliance
- `reviewer.md` — Focus on code quality, pattern consistency, spec drift
- `optimizer.md` — Focus on performance, duplication, dead code
- `docs.md` — Focus on documentation accuracy, spec updates, PROGRESS.md curation

Update `run-parallel.sh` to optionally accept role assignments:
```bash
./run-parallel.sh 4 --roles implementer,implementer,reviewer,docs
```

The role template gets appended to the standard agent prompt.

**Impact:** Medium. Enables more effective parallel execution for mature codebases where different concerns need simultaneous attention.

---

### 5. Grep-Friendly Output Standards

**Inspiration:** The C Compiler article emphasizes: "Use grep-friendly error formatting (`ERROR` keyword on same line as reason)." Verbose output pollutes context windows; structured output enables automation.

**Current state:** No standard output format for agent scripts. `status.sh` outputs human-readable text.

**Change:**
- Update `status.sh` to output pre-computed statistics summary (not just counts) with machine-parseable lines: `STAT: tasks_total=12 completed=8 blocked=1 in_progress=2 backlog=1`
- Add output format guidelines to AGENT_GUIDE.md: errors as `ERROR: <reason>`, warnings as `WARN: <reason>`, completion as `DONE: <task-id> <summary>`
- Update `run-agent.sh` to log verbose output to files (`docs/spec/.llm/logs/`) instead of stdout, keeping stdout clean for status and sentinels

**Impact:** Medium. Reduces context pollution when agents or scripts consume each other's output. Enables better automation and monitoring.

---

### 6. Task Sizing Guidance

**Inspiration:** Ralph is extremely opinionated: "If you cannot describe the change in 2-3 sentences, it is too big." Right-sized: "Add a database column and migration." Too big: "Build the entire dashboard."

**Current state:** The `/decompose` command mentions 75-150 turns per task but doesn't give concrete sizing heuristics.

**Change:** Add explicit sizing guidance to `task.template.md` and the `/decompose` command:
- **Rule of thumb:** Each task should be completable in one fresh context window
- **Size test:** If you can't describe the change in 2-3 sentences, split it
- **Good examples:** "Add user model and migration", "Create GET /users endpoint with tests", "Add login form component"
- **Bad examples:** "Build the user management system", "Implement authentication", "Create the dashboard"
- **Acceptance criteria test:** Each criterion should be independently verifiable

**Impact:** Medium. Better-sized tasks lead to higher completion rates and cleaner commits, especially in fresh-context mode.

---

### 7. Automatic Run Archiving

**Inspiration:** Ralph automatically archives `prd.json` and `progress.txt` to `archive/YYYY-MM-DD-feature-name/` when switching features (detected by `branchName` change).

**Current state:** Completed tasks move to `completed/` but there's no concept of "run archiving" — old completed tasks accumulate indefinitely.

**Change:** Add an `archive.sh` script (or flag on `reset.sh`) that:
- Moves all `completed/` tasks, the current PROGRESS.md iteration log, and `logs/` contents to `docs/spec/.llm/archive/YYYY-MM-DD-description/`
- Preserves the "Codebase Patterns" section of PROGRESS.md (carries forward)
- Resets the iteration log section
- Optionally triggered automatically by `run-parallel.sh` when all tasks complete

**Impact:** Low-medium. Keeps the working directories clean between feature cycles while preserving history.

---

### 8. Distributed CLAUDE.md Convention

**Inspiration:** Ralph encourages agents to update CLAUDE.md files in the directories they modify. Since Claude Code auto-reads these files, this creates self-improving directory-level documentation.

**Current state:** Single root-level CLAUDE.md. No convention for subdirectory-level files.

**Change:** Add guidance to AGENT_GUIDE.md and LLM.md encouraging agents to:
- Create `CLAUDE.md` files in significant subdirectories (e.g., `internal/auth/CLAUDE.md`, `src/components/CLAUDE.md`)
- Document directory-specific patterns, conventions, gotchas
- Keep them concise (under 30 lines)
- These are NOT documentation — they're LLM context hints

Add `.claude.md` and `CLAUDE.md` patterns to `.gitignore` template as optional (commented out) entries, with a note that teams can choose whether to commit them.

**Impact:** Medium. Creates an emergent, self-improving context system that scales with codebase complexity. Each directory carries its own institutional knowledge.

---

### 9. PRD-to-Tasks Pipeline Skill

**Inspiration:** Ralph's two-skill pipeline: (1) interactive Q&A generates a structured PRD, (2) converter skill transforms PRD into sized, dependency-ordered task JSON. This is elegant and reusable.

**Current state:** `/requirements` does iterative Q&A but outputs a spec document. `/decompose` breaks work into tasks. These are separate commands with no structured intermediate format.

**Change:** Add a `/prd` command (or enhance `/requirements`) that:
- Phase 1: Interactive Q&A with lettered multiple-choice options (Ralph's "1A, 2C, 3B" quick-response pattern)
- Phase 2: Generates structured PRD with user stories, acceptance criteria, and priority ordering
- Phase 3: Converts PRD into task files in `backlog/` with proper dependency headers
- Enforces sizing discipline (each story completable in one iteration)
- Enforces dependency ordering (data layer first, then logic, then UI, then integration)

This bridges the gap between requirements gathering and task execution.

**Impact:** Medium-high. Streamlines the requirements-to-execution pipeline, reducing manual task creation.

---

### 10. Context Pollution Prevention Guidelines

**Inspiration:** The C Compiler article identifies context window pollution as a major failure mode: "Minimize context pollution — log comprehensively to files instead." They also pre-compute aggregate statistics rather than forcing Claude to recalculate.

**Current state:** No explicit guidance on managing context pollution. Agent prompts can grow large.

**Change:** Add a "Context Hygiene" section to AGENT_GUIDE.md:
- **Log to files, not stdout:** Redirect verbose build/test output to `docs/spec/.llm/logs/`
- **Summarize, don't dump:** When reporting results, provide 3-5 line summaries, not full output
- **Pre-compute stats:** Scripts should output summaries, not raw data for Claude to process
- **Limit file reads:** Read only the sections you need (use line ranges), not entire large files
- **One task focus:** Don't read unrelated task files or specs. Read only what's needed for the current task.

Update `run-agent.sh` prompt to include: "Redirect verbose command output to log files. Keep your working context focused on the current task."

**Impact:** Medium. Directly addresses a known failure mode in long-running agent sessions.

---

## Summary Table

| # | Change | Inspiration | Impact | Effort |
|---|--------|-------------|--------|--------|
| 1 | Curated Codebase Patterns in PROGRESS.md | Ralph | High | Low |
| 2 | Fresh-Context Loop Mode | Ralph + C Compiler | Medium-High | Medium |
| 3 | Completion Sentinel Signal | Ralph | Low-Medium | Low |
| 4 | Agent Role Specialization | C Compiler | Medium | Medium |
| 5 | Grep-Friendly Output Standards | C Compiler | Medium | Low |
| 6 | Task Sizing Guidance | Ralph | Medium | Low |
| 7 | Automatic Run Archiving | Ralph | Low-Medium | Low |
| 8 | Distributed CLAUDE.md Convention | Ralph | Medium | Low |
| 9 | PRD-to-Tasks Pipeline Skill | Ralph | Medium-High | High |
| 10 | Context Pollution Prevention | C Compiler | Medium | Low |

## Recommended Implementation Order

**Phase 1 — Quick wins (low effort, immediate value):**
1. Curated Codebase Patterns in PROGRESS.md (#1)
5. Grep-Friendly Output Standards (#5)
6. Task Sizing Guidance (#6)
10. Context Pollution Prevention Guidelines (#10)

**Phase 2 — Core improvements:**
3. Completion Sentinel Signal (#3)
7. Automatic Run Archiving (#7)
8. Distributed CLAUDE.md Convention (#8)

**Phase 3 — Structural additions:**
2. Fresh-Context Loop Mode (#2)
4. Agent Role Specialization (#4)
9. PRD-to-Tasks Pipeline Skill (#9)
