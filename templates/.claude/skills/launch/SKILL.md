---
name: launch
description: Pre-flight checks and launch team lead for parallel execution
allowed-tools: Read, Glob, Grep, Bash, Task
---

Run pre-flight checks and launch the team lead agent for parallel execution.

## Instructions

1. **Pre-flight checks** -- verify all of these before launching:
   - [ ] Task files exist in `docs/spec/.llm/tasks/backlog/` (count > 0)
   - [ ] `.claude/rules/agent-guide.md` has been customized (project description is not a placeholder)
   - [ ] Quality Gates section has uncommented commands (not just comment-only examples)
   - [ ] `docs/spec/.llm/STRATEGY.md` has been filled in (not just template placeholders)
   - [ ] Task dependencies are valid (referenced tasks exist in backlog or completed)
   - [ ] Git working tree is clean (no uncommitted changes)
2. **Report** any issues found. Do NOT launch if there are blocking issues.
3. If all checks pass, confirm with the user.
4. Launch the team lead agent: `claude --agent team-lead --max-turns 300 --print -p "Execute all tasks in docs/spec/.llm/tasks/backlog/. Read each task file and coordinate teammates to complete them in parallel with branch isolation."`
5. After launching, run `bash docs/spec/.llm/scripts/status.sh` to confirm execution started.

## Arguments

$ARGUMENTS
