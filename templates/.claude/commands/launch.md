Run pre-flight checks and launch parallel agents.

## Instructions

1. **Pre-flight checks** — verify all of these before launching:
   - [ ] Task files exist in `docs/spec/.llm/tasks/backlog/` (count > 0)
   - [ ] `docs/spec/.llm/AGENT_GUIDE.md` has been customized: run `grep -q ' is \.\.\.$' docs/spec/.llm/AGENT_GUIDE.md` — if it matches, the project description is still a placeholder. Warn the user.
   - [ ] `docs/spec/.llm/AGENT_GUIDE.md` Quality Gates section has uncommented commands (not just comment-only examples)
   - [ ] `docs/spec/.llm/STRATEGY.md` has been filled in (not just template placeholders)
   - [ ] Task dependencies are valid (referenced tasks exist in backlog or completed)
   - [ ] Git working tree is clean (no uncommitted changes)
2. **Report** any issues found. Do NOT launch if there are blocking issues.
3. If all checks pass, ask the user to confirm the number of agents (default: 3).
4. Launch with: `bash docs/spec/.llm/scripts/run-parallel.sh N`
5. After launching, run `bash docs/spec/.llm/scripts/status.sh` to confirm agents started.

## Arguments

$ARGUMENTS
