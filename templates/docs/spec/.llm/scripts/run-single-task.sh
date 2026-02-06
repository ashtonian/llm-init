#!/usr/bin/env bash
set -euo pipefail

# run-single-task.sh — Run a specific task autonomously (one-shot, no loop)
#
# Usage:
#   bash docs/spec/.llm/scripts/run-single-task.sh <task-filename>
#
# The task file is searched in backlog/, in_progress/, and blocked/ directories.
# Uses fewer turns (75) since this is a single focused task.

if [[ $# -lt 1 ]]; then
    echo "Usage: bash docs/spec/.llm/scripts/run-single-task.sh <task-filename>"
    echo "Example: bash docs/spec/.llm/scripts/run-single-task.sh 01-project-scaffolding.md"
    exit 1
fi

TASK_FILENAME="$1"
AGENT_NAME="single-$(date +%s | tail -c 5)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${HARNESS_DIR}/../../.." && pwd)"

TASKS_DIR="${HARNESS_DIR}/tasks"
LOCK_DIR="${TASKS_DIR}/.locks"
LOG_DIR="${HARNESS_DIR}/logs"
WORKTREE_DIR="${HARNESS_DIR}/worktrees/${AGENT_NAME}"
PROGRESS_FILE="${HARNESS_DIR}/PROGRESS.md"
AGENT_GUIDE="${HARNESS_DIR}/AGENT_GUIDE.md"

MAX_TURNS="${MAX_TURNS:-75}"
BRANCH_PREFIX="${BRANCH_PREFIX:-task/}"
SKIP_API_KEY_UNSET="${SKIP_API_KEY_UNSET:-}"
SKIP_PERMISSIONS="${SKIP_PERMISSIONS:-1}"

mkdir -p "${LOG_DIR}" "${LOCK_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${AGENT_NAME}] $*"
}

# Find the task file
TASK_FILE=""
for dir in backlog in_progress blocked; do
    if [[ -f "${TASKS_DIR}/${dir}/${TASK_FILENAME}" ]]; then
        TASK_FILE="${TASKS_DIR}/${dir}/${TASK_FILENAME}"
        break
    fi
done

if [[ -z "$TASK_FILE" ]]; then
    echo "ERROR: Task file '$TASK_FILENAME' not found in backlog/, in_progress/, or blocked/"
    echo ""
    echo "Available tasks:"
    for dir in backlog in_progress blocked completed; do
        for f in "${TASKS_DIR}/${dir}/"*.md; do
            [[ -f "$f" ]] || continue
            echo "  [${dir}] $(basename "$f")"
        done
    done
    exit 1
fi

TASK_NAME="$(basename "$TASK_FILE" .md)"
log "Found task: $TASK_FILE"

# Move to in_progress if needed
if [[ "$(dirname "$TASK_FILE")" != "${TASKS_DIR}/in_progress" ]]; then
    LOCK_FILE="${LOCK_DIR}/${TASK_NAME}.lock"
    if mkdir "$LOCK_FILE" 2>/dev/null; then
        echo "$AGENT_NAME" > "$LOCK_FILE/owner"
        mv "$TASK_FILE" "${TASKS_DIR}/in_progress/"
        TASK_FILE="${TASKS_DIR}/in_progress/${TASK_FILENAME}"
        log "Claimed and moved to in_progress"
    else
        echo "ERROR: Task is locked by another agent"
        exit 1
    fi
fi

# Optionally unset API key to force subscription auth
if [[ -z "$SKIP_API_KEY_UNSET" ]]; then
    unset ANTHROPIC_API_KEY 2>/dev/null || true
fi

# Set up worktree
cd "$PROJECT_ROOT"
if [[ -d "$WORKTREE_DIR" ]]; then
    cd "$WORKTREE_DIR"
    git checkout --detach master 2>/dev/null || git checkout --detach main 2>/dev/null || true
    git reset --hard HEAD
    git clean -fd
else
    git worktree add --detach "$WORKTREE_DIR" HEAD
fi
cd "$WORKTREE_DIR"
BRANCH_NAME="${BRANCH_PREFIX}${TASK_NAME}"
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"

# Build prompt
TASK_CONTENT="$(cat "$TASK_FILE")"
AGENT_GUIDE_CONTENT=""
[[ -f "$AGENT_GUIDE" ]] && AGENT_GUIDE_CONTENT="$(cat "$AGENT_GUIDE")"
PROGRESS_CONTENT=""
[[ -f "$PROGRESS_FILE" ]] && PROGRESS_CONTENT="$(cat "$PROGRESS_FILE")"

PROMPT="$(cat <<PROMPT_END
You are an autonomous coding agent working on this project.
You are agent "${AGENT_NAME}" running a single task.
You are working in an isolated git worktree. Your changes will be merged to master when complete.

## Project Context (Agent Guide)

${AGENT_GUIDE_CONTENT}

## Cross-Iteration Memory (PROGRESS.md)

${PROGRESS_CONTENT}

## Your Task

${TASK_CONTENT}

## Working Instructions

1. Read the task carefully and understand ALL steps and acceptance criteria.
2. Read the progress log above to understand what previous iterations accomplished.
3. Implement all steps in the task.
4. Run the verification commands listed in the task.
5. Verify ALL acceptance criteria are satisfied.
6. Commit your changes with a descriptive message. Do NOT push.

## Completion Protocol

When FULLY complete and ALL acceptance criteria are verified, output EXACTLY:
TASK_COMPLETE

Then output a brief summary (2-5 sentences) of what you accomplished.

If blocked, output EXACTLY:
TASK_BLOCKED: <reason>
PROMPT_END
)"

# Run Claude Code
LOG_FILE="${LOG_DIR}/${AGENT_NAME}-${TASK_NAME}-$(date '+%Y%m%d-%H%M%S').log"
log "Spawning Claude Code (max turns: $MAX_TURNS)..."

EXIT_CODE=0
CLAUDE_ARGS=(--print --output-format text --max-turns "$MAX_TURNS")
if [[ "$SKIP_PERMISSIONS" == "1" ]]; then
    CLAUDE_ARGS+=(--dangerously-skip-permissions)
fi
echo "$PROMPT" | claude "${CLAUDE_ARGS[@]}" \
    > "$LOG_FILE" 2>&1 || EXIT_CODE=$?

cd "$PROJECT_ROOT"

# Check result
if [[ $EXIT_CODE -eq 0 ]] && grep -q "TASK_COMPLETE" "$LOG_FILE"; then
    log "Task completed successfully"

    if git merge "$BRANCH_NAME" --no-ff -m "feat: complete ${TASK_NAME} [${AGENT_NAME}]" 2>/dev/null; then
        log "Merged $BRANCH_NAME to master"

        # Append progress
        SUMMARY=$(sed -n '/TASK_COMPLETE/,$ p' "$LOG_FILE" | tail -n +2 | head -20)
        [[ -z "$SUMMARY" ]] && SUMMARY="Task completed (no summary provided)"
        cat >> "$PROGRESS_FILE" <<EOF

### $(date '+%Y-%m-%d %H:%M:%S') — ${AGENT_NAME} — ${TASK_NAME}
${SUMMARY}

EOF

        mv "${TASKS_DIR}/in_progress/${TASK_FILENAME}" "${TASKS_DIR}/completed/"
        rm -rf "${LOCK_DIR}/${TASK_NAME}.lock"
        git branch -d "$BRANCH_NAME" 2>/dev/null || true
        log "Done. Task moved to completed."
    else
        log "ERROR: Merge failed"
        git merge --abort 2>/dev/null || true
        mv "${TASKS_DIR}/in_progress/${TASK_FILENAME}" "${TASKS_DIR}/blocked/"
        rm -rf "${LOCK_DIR}/${TASK_NAME}.lock"
    fi

elif grep -q "TASK_BLOCKED" "$LOG_FILE"; then
    REASON=$(grep "TASK_BLOCKED" "$LOG_FILE" | head -1 | sed 's/.*TASK_BLOCKED: //')
    log "Task blocked: $REASON"
    mv "${TASKS_DIR}/in_progress/${TASK_FILENAME}" "${TASKS_DIR}/blocked/"
    rm -rf "${LOCK_DIR}/${TASK_NAME}.lock"

else
    log "Task failed (exit code: $EXIT_CODE)"
    tail -5 "$LOG_FILE" 2>/dev/null || true
    mv "${TASKS_DIR}/in_progress/${TASK_FILENAME}" "${TASKS_DIR}/blocked/"
    rm -rf "${LOCK_DIR}/${TASK_NAME}.lock"
fi

# Cleanup worktree
git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
log "Single task execution complete"
