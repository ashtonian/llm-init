#!/usr/bin/env bash
set -euo pipefail

# run-interactive.sh — Launch Claude Code interactively with task context
#
# Usage:
#   bash docs/spec/.llm/scripts/run-interactive.sh <task-filename>
#
# Opens an interactive Claude Code session with the task pre-loaded as context.
# Uses project permissions (no --dangerously-skip-permissions).

if [[ $# -lt 1 ]]; then
    echo "Usage: bash docs/spec/.llm/scripts/run-interactive.sh <task-filename>"
    echo "Example: bash docs/spec/.llm/scripts/run-interactive.sh 01-project-scaffolding.md"
    exit 1
fi

TASK_FILENAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TASKS_DIR="${HARNESS_DIR}/tasks"
PROGRESS_FILE="${HARNESS_DIR}/PROGRESS.md"
AGENT_GUIDE="${HARNESS_DIR}/AGENT_GUIDE.md"

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

# Build init prompt with task context
TASK_CONTENT="$(cat "$TASK_FILE")"

AGENT_GUIDE_CONTENT=""
[[ -f "$AGENT_GUIDE" ]] && AGENT_GUIDE_CONTENT="$(cat "$AGENT_GUIDE")"

PROGRESS_CONTENT=""
[[ -f "$PROGRESS_FILE" ]] && PROGRESS_CONTENT="$(cat "$PROGRESS_FILE")"

INIT_PROMPT="$(cat <<PROMPT_END
I'm working on task: ${TASK_NAME}

## Project Context (Agent Guide)

${AGENT_GUIDE_CONTENT}

## Recent Progress (PROGRESS.md)

${PROGRESS_CONTENT}

## Task Details

${TASK_CONTENT}

---

Please help me implement this task. Start by reading the task details above, then ask me any clarifying questions before beginning implementation.
PROMPT_END
)"

echo "Starting interactive Claude Code session for: $TASK_NAME"
echo "Task file: $TASK_FILE"
echo ""

# Launch interactive Claude Code (uses project permissions from .claude/settings.json)
claude --init-prompt "$INIT_PROMPT"
