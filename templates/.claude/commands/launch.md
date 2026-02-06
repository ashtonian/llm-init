Run pre-flight checks and launch parallel agents.

## Instructions

1. **Pre-flight checks** — verify all of these before launching:
   - [ ] Task files exist in `docs/spec/.llm/tasks/backlog/`
   - [ ] `docs/spec/.llm/AGENT_GUIDE.md` has been customized (not just template placeholders)
   - [ ] `docs/spec/.llm/STRATEGY.md` has been filled in
   - [ ] Task dependencies are valid (referenced tasks exist)
   - [ ] Quality gate commands in AGENT_GUIDE.md are runnable
   - [ ] Git working tree is clean (no uncommitted changes)
2. **Report** any issues found. Do NOT launch if there are blocking issues.
3. If all checks pass, ask the user to confirm the number of agents (default: 3).
4. Launch with: `bash docs/spec/.llm/scripts/run-parallel.sh N`
5. After launching, run `bash docs/spec/.llm/scripts/status.sh` to confirm agents started.

## Arguments

$ARGUMENTS
