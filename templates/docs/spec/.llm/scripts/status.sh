#!/usr/bin/env bash
set -euo pipefail

# status.sh — Task queue dashboard
#
# Usage:
#   bash docs/spec/.llm/scripts/status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TASKS_DIR="${HARNESS_DIR}/tasks"
PID_FILE="${HARNESS_DIR}/.agent-pids"

# Count tasks in each state
count_tasks() {
    local dir="$1"
    local count=0
    for f in "${TASKS_DIR}/${dir}/"*.md; do
        [[ -f "$f" ]] && count=$((count + 1))
    done
    echo "$count"
}

BACKLOG=$(count_tasks "backlog")
IN_PROGRESS=$(count_tasks "in_progress")
COMPLETED=$(count_tasks "completed")
BLOCKED=$(count_tasks "blocked")
TOTAL=$((BACKLOG + IN_PROGRESS + COMPLETED + BLOCKED))

echo "============================================"
echo "  Task Queue Status"
echo "============================================"
echo ""
printf "  Backlog:      %3d\n" "$BACKLOG"
printf "  In Progress:  %3d\n" "$IN_PROGRESS"
printf "  Completed:    %3d\n" "$COMPLETED"
printf "  Blocked:      %3d\n" "$BLOCKED"
echo "  ─────────────────"
printf "  Total:        %3d\n" "$TOTAL"
echo ""

if [[ $TOTAL -gt 0 ]]; then
    PROGRESS_PCT=$((COMPLETED * 100 / TOTAL))
    echo "  Progress: $COMPLETED/$TOTAL completed (${PROGRESS_PCT}%)"
else
    PROGRESS_PCT=0
    echo "  No tasks found. Create tasks in: docs/spec/.llm/tasks/backlog/"
fi
echo ""
echo "STAT: tasks_total=${TOTAL} backlog=${BACKLOG} in_progress=${IN_PROGRESS} completed=${COMPLETED} blocked=${BLOCKED} progress_pct=${PROGRESS_PCT}"
echo ""

# Show active agents
if [[ -f "$PID_FILE" ]] && [[ -s "$PID_FILE" ]]; then
    echo "── Active Agents ──────────────────────────"
    echo ""
    while read -r pid name; do
        if kill -0 "$pid" 2>/dev/null; then
            printf "  %-12s PID %-8s RUNNING\n" "$name" "$pid"
        else
            printf "  %-12s PID %-8s STOPPED\n" "$name" "$pid"
        fi
    done < "$PID_FILE"
    echo ""
fi

# Show per-task details
if [[ $TOTAL -gt 0 ]]; then
    echo "── Task Details ───────────────────────────"
    echo ""

    for state in backlog in_progress completed blocked; do
        for task_file in "${TASKS_DIR}/${state}/"*.md; do
            [[ -f "$task_file" ]] || continue
            task_name="$(basename "$task_file" .md)"
            title=$(head -1 "$task_file" | sed 's/^# //')

            case "$state" in
                backlog)     icon="○" ;;
                in_progress) icon="◐" ;;
                completed)   icon="●" ;;
                blocked)     icon="✗" ;;
            esac

            printf "  %s %-12s %s\n" "$icon" "[$state]" "$title"

            # Show dependency info for backlog tasks
            if [[ "$state" == "backlog" ]]; then
                deps=$(grep "^## Dependencies:" "$task_file" 2>/dev/null | sed 's/## Dependencies: //' || true)
                if [[ -n "$deps" ]] && [[ "$deps" != "None" ]]; then
                    printf "                    └─ depends on: %s\n" "$deps"
                fi
            fi

            # Show lock owner for in_progress tasks
            if [[ "$state" == "in_progress" ]]; then
                lock_file="${TASKS_DIR}/.locks/${task_name}.lock"
                if [[ -f "$lock_file/owner" ]]; then
                    owner=$(cat "$lock_file/owner")
                    printf "                    └─ claimed by: %s\n" "$owner"
                fi
            fi
        done
    done
    echo ""
fi
