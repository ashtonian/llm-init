#!/usr/bin/env bash
set -euo pipefail

# run-team.sh -- Launch team lead agent for parallel task execution
#
# Usage:
#   bash docs/spec/.llm/scripts/run-team.sh
#
# This replaces run-parallel.sh by using Claude Code's native Agent Teams feature.
# The team-lead agent reads backlog tasks and coordinates teammates to complete them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TASKS_DIR="${HARNESS_DIR}/tasks"

# Enable Agent Teams
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Optionally unset API key (like current harness — forces OAuth)
if [[ "${SKIP_API_KEY_UNSET:-}" != "1" ]]; then
    unset ANTHROPIC_API_KEY 2>/dev/null || true
fi

# Count backlog tasks
BACKLOG_COUNT=0
for f in "${TASKS_DIR}/backlog/"*.md; do
    [[ -f "$f" ]] && BACKLOG_COUNT=$((BACKLOG_COUNT + 1))
done

if [[ "$BACKLOG_COUNT" -eq 0 ]]; then
    echo "No tasks in backlog. Create tasks first:"
    echo "  - Use /decompose to break work into tasks"
    echo "  - Use /prd for interactive PRD -> task pipeline"
    echo "  - Use /new-task to create individual tasks"
    exit 1
fi

echo "============================================"
echo "  Launching Team Lead Agent"
echo "============================================"
echo ""
echo "  Tasks in backlog: ${BACKLOG_COUNT}"
echo "  Agent: team-lead (opus, 300 turns)"
echo "  Mode: delegate (spawns teammate agents)"
echo ""
echo "  The team lead will:"
echo "    1. Read all backlog task files"
echo "    2. Build a dependency graph"
echo "    3. Spawn teammate agents in parallel"
echo "    4. Monitor progress and handle failures"
echo "    5. Merge branches and run final quality gates"
echo ""
echo "============================================"
echo ""

# Launch the team lead agent
claude --agent team-lead \
    --max-turns 300 \
    --print \
    -p "Execute all tasks in docs/spec/.llm/tasks/backlog/. Read each task file and coordinate teammates to complete them in parallel with branch isolation. After all tasks complete, merge branches and run final quality gates."

echo ""
echo "============================================"
echo "  Team execution complete"
echo "============================================"
echo ""

# Show final status
bash "${SCRIPT_DIR}/status.sh"
