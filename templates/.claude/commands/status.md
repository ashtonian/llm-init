Show the current task queue status and provide analysis.

## Instructions

1. Run `bash docs/spec/.llm/scripts/status.sh` to get the task queue dashboard.
2. Read `docs/spec/.llm/PROGRESS.md` for the latest iteration log entries.
3. Check for any running agent processes (`ps aux | grep run-agent`).
4. Provide a summary including:
   - **Queue counts**: backlog, in_progress, completed, blocked
   - **Blocked tasks**: why they're blocked and what to do
   - **Progress**: what's been completed since the last check
   - **Recommendations**: next actions (launch more agents, unblock tasks, etc.)
5. If there are completed tasks, highlight key learnings from PROGRESS.md.

$ARGUMENTS
