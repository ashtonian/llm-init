#!/usr/bin/env bash
set -euo pipefail

# archive.sh — Archive completed tasks and logs from a run
#
# Moves completed tasks and relevant logs to a timestamped archive directory.
# Preserves PROGRESS.md Codebase Patterns section but resets the Iteration Log.
#
# Usage:
#   bash docs/spec/.llm/scripts/archive.sh [description]
#
# Example:
#   bash docs/spec/.llm/scripts/archive.sh "phase-1-foundation"

DESCRIPTION="${1:-$(date '+%Y%m%d-%H%M%S')}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TASKS_DIR="${HARNESS_DIR}/tasks"
LOG_DIR="${HARNESS_DIR}/logs"
PROGRESS_FILE="${HARNESS_DIR}/PROGRESS.md"
ARCHIVE_DIR="${HARNESS_DIR}/archive/$(date '+%Y-%m-%d')-${DESCRIPTION}"

# Check if there's anything to archive
COMPLETED_COUNT=0
for f in "${TASKS_DIR}/completed/"*.md; do
    [[ -f "$f" ]] && COMPLETED_COUNT=$((COMPLETED_COUNT + 1))
done

if [[ "$COMPLETED_COUNT" -eq 0 ]]; then
    echo "Nothing to archive — no completed tasks found."
    exit 0
fi

echo "Archiving ${COMPLETED_COUNT} completed tasks..."

# Create archive structure
mkdir -p "${ARCHIVE_DIR}/tasks"
mkdir -p "${ARCHIVE_DIR}/logs"

# Move completed tasks
for f in "${TASKS_DIR}/completed/"*.md; do
    [[ -f "$f" ]] || continue
    mv "$f" "${ARCHIVE_DIR}/tasks/"
    echo "  Archived task: $(basename "$f")"
done

# Move logs (copy, don't move — logs may be referenced)
for f in "${LOG_DIR}/"*.log; do
    [[ -f "$f" ]] || continue
    mv "$f" "${ARCHIVE_DIR}/logs/"
done
echo "  Archived logs to ${ARCHIVE_DIR}/logs/"

# Snapshot PROGRESS.md into the archive
if [[ -f "$PROGRESS_FILE" ]]; then
    cp "$PROGRESS_FILE" "${ARCHIVE_DIR}/PROGRESS.md"
    echo "  Saved PROGRESS.md snapshot"

    # Reset Iteration Log but keep Codebase Patterns and other sections
    # Find the Iteration Log section and truncate entries after the template comment
    if grep -q "^## Iteration Log" "$PROGRESS_FILE"; then
        # Keep everything up to and including the Iteration Log template END marker
        MARKER_LINE=$(grep -n "^END TEMPLATE -->" "$PROGRESS_FILE" | tail -1 | cut -d: -f1)
        if [[ -n "$MARKER_LINE" ]]; then
            head -n "$MARKER_LINE" "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp"
            echo "" >> "${PROGRESS_FILE}.tmp"
            mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
            echo "  Reset Iteration Log (patterns preserved)"
        fi
    fi
fi

# Restore .gitkeep files
touch "${TASKS_DIR}/completed/.gitkeep"
touch "${LOG_DIR}/.gitkeep"

echo ""
echo "Archive created: ${ARCHIVE_DIR}"
echo "  Tasks: ${COMPLETED_COUNT}"
echo "  Codebase Patterns in PROGRESS.md preserved."
echo "  Iteration Log reset for next run."
