---
name: status
description: Task queue dashboard and progress report
allowed-tools: Read, Glob, Grep, Bash, TaskList
---

Show the current task queue status and provide analysis.

## Instructions

1. Run `bash docs/spec/.llm/scripts/status.sh` to get the file-based task queue dashboard.
2. Also use TaskList to show native task status if any native tasks exist.
3. Read `docs/spec/.llm/PROGRESS.md` for the latest iteration log entries.
4. **Check for stale tasks**: Look at lock files in `docs/spec/.llm/tasks/.locks/` -- if any `claimed_at` timestamp is older than 30 minutes and the agent process is not running, flag it as stale.
5. Provide a summary including:
   - **Queue counts**: backlog, in_progress, completed, blocked
   - **Stale tasks**: Any in_progress tasks with locks older than 30 min (suggest: move back to backlog, delete lock)
   - **Blocked tasks**: Why they're blocked and suggest unblocking strategies (check if dependencies are now met, if the blocker can be resolved manually)
   - **Progress**: What's been completed since the last check
   - **Throughput**: If there are completed tasks with timestamps, estimate tasks-per-hour rate and remaining time
   - **Recommendations**: Next actions (launch more agents, unblock tasks, etc.)
6. If there are completed tasks, highlight key learnings from PROGRESS.md.

$ARGUMENTS
