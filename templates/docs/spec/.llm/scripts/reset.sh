#!/usr/bin/env bash
set -euo pipefail

# reset.sh — Reset all tasks back to backlog
#
# Usage:
#   bash docs/spec/.llm/scripts/reset.sh
#
# Moves all tasks from in_progress/, completed/, and blocked/ back to backlog/.
# Removes all lock files. Does NOT remove logs or worktrees.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TASKS_DIR="${HARNESS_DIR}/tasks"
LOCK_DIR="${TASKS_DIR}/.locks"

echo "Resetting task queue..."

# Move tasks back to backlog
MOVED=0
for state in in_progress completed blocked; do
    for task_file in "${TASKS_DIR}/${state}/"*.md; do
        [[ -f "$task_file" ]] || continue
        mv "$task_file" "${TASKS_DIR}/backlog/"
        echo "  Moved: $(basename "$task_file") ($state -> backlog)"
        MOVED=$((MOVED + 1))
    done
done

# Remove locks
if [[ -d "$LOCK_DIR" ]]; then
    rm -rf "${LOCK_DIR:?}"/*
    echo "  Cleared all lock files"
fi

# Clear PID file
PID_FILE="${HARNESS_DIR}/.agent-pids"
if [[ -f "$PID_FILE" ]]; then
    > "$PID_FILE"
    echo "  Cleared PID file"
fi

echo ""
if [[ $MOVED -gt 0 ]]; then
    echo "Reset complete. $MOVED task(s) moved back to backlog."
else
    echo "Reset complete. No tasks to move."
fi
echo ""
echo "Run status to verify:"
echo "  bash docs/spec/.llm/scripts/status.sh"
