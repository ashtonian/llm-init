#!/usr/bin/env bash
set -euo pipefail

# run-fresh-loop.sh — Fresh-context loop (new Claude instance per task)
#
# Spawns a new `claude --print` per iteration (no --resume), ensuring each task
# gets a clean context window. The loop continues until no tasks remain or
# MAX_ITERATIONS is reached.
#
# Use this instead of run-agent.sh for long autonomous runs where context
# freshness matters more than session continuity.
#
# Usage:
#   bash docs/spec/.llm/scripts/run-fresh-loop.sh [max-iterations]
#
# Environment variables:
#   MAX_ITERATIONS       Max loop iterations (default: 50, or pass as arg)
#   BRANCH_PREFIX        Git branch prefix (default: task/)
#   MAX_TURNS            Max Claude Code turns per task (default: 150)
#   SKIP_API_KEY_UNSET   Set to 1 to keep ANTHROPIC_API_KEY (default: unset)
#   SKIP_PERMISSIONS     Set to 1 to use --dangerously-skip-permissions (default: 0)

MAX_ITERATIONS="${1:-${MAX_ITERATIONS:-50}}"
AGENT_NAME="fresh-$(date +%s | tail -c 5)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TASKS_DIR="${HARNESS_DIR}/tasks"
LOG_DIR="${HARNESS_DIR}/logs"

mkdir -p "${LOG_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${AGENT_NAME}] $*"
}

log "Starting fresh-context loop (max iterations: ${MAX_ITERATIONS})"

# Optionally unset API key to force subscription auth
SKIP_API_KEY_UNSET="${SKIP_API_KEY_UNSET:-}"
if [[ -z "$SKIP_API_KEY_UNSET" ]]; then
    unset ANTHROPIC_API_KEY 2>/dev/null || true
fi

ITERATION=0
ALL_DONE=0

while [[ $ITERATION -lt $MAX_ITERATIONS ]]; do
    ITERATION=$((ITERATION + 1))

    # Find next available task in backlog
    NEXT_TASK=""
    for task_file in "${TASKS_DIR}/backlog/"*.md; do
        [[ -f "$task_file" ]] || continue
        NEXT_TASK="$(basename "$task_file")"
        break
    done

    if [[ -z "$NEXT_TASK" ]]; then
        IN_PROGRESS=0
        for f in "${TASKS_DIR}/in_progress/"*.md; do
            [[ -f "$f" ]] && IN_PROGRESS=$((IN_PROGRESS + 1))
        done
        if [[ "$IN_PROGRESS" -eq 0 ]]; then
            log "ALL_TASKS_COMPLETE"
            log "DONE: all_tasks_complete iterations=${ITERATION} agent=${AGENT_NAME}"
            ALL_DONE=1
            break
        fi
        log "No backlog tasks but ${IN_PROGRESS} in progress. Waiting 10s..."
        sleep 10
        continue
    fi

    log "Iteration ${ITERATION}/${MAX_ITERATIONS}: running task ${NEXT_TASK}"

    # Delegate to run-single-task.sh (fresh context per task)
    export MAX_TURNS="${MAX_TURNS:-150}"
    export BRANCH_PREFIX="${BRANCH_PREFIX:-task/}"
    export SKIP_API_KEY_UNSET="${SKIP_API_KEY_UNSET:-1}"
    export SKIP_PERMISSIONS="${SKIP_PERMISSIONS:-0}"

    ITER_LOG="${LOG_DIR}/${AGENT_NAME}-iter${ITERATION}-$(date '+%Y%m%d-%H%M%S').log"
    if bash "${SCRIPT_DIR}/run-single-task.sh" "$NEXT_TASK" > "$ITER_LOG" 2>&1; then
        log "DONE: task=${NEXT_TASK} iteration=${ITERATION} agent=${AGENT_NAME}"
    else
        log "WARN: task=${NEXT_TASK} exited non-zero iteration=${ITERATION}"
    fi
done

if [[ $ALL_DONE -eq 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
    log "WARN: max_iterations_reached iterations=${MAX_ITERATIONS} agent=${AGENT_NAME}"
fi

log "Fresh-context loop complete. Ran ${ITERATION} iterations."
bash "${SCRIPT_DIR}/status.sh"
