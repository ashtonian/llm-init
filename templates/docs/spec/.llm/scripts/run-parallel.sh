#!/usr/bin/env bash
set -euo pipefail

# run-parallel.sh — Launch N autonomous agents in parallel
#
# Usage:
#   bash docs/spec/.llm/scripts/run-parallel.sh [num-agents]
#
# Agents are staggered by 5 seconds to reduce git conflicts and API contention.
# All agent PIDs are tracked for monitoring.

NUM_AGENTS="${1:-3}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PID_FILE="${HARNESS_DIR}/.agent-pids"

echo "============================================"
echo "  Parallel Agent Harness"
echo "  Launching $NUM_AGENTS agents"
echo "============================================"
echo ""

# Clear PID file
> "$PID_FILE"

# Launch agents with staggered starts
for i in $(seq 1 "$NUM_AGENTS"); do
    AGENT_NAME="agent-${i}"
    LOG_FILE="${HARNESS_DIR}/logs/${AGENT_NAME}-session-$(date '+%Y%m%d-%H%M%S').log"
    mkdir -p "${HARNESS_DIR}/logs"

    echo "Starting ${AGENT_NAME}..."
    bash "${SCRIPT_DIR}/run-agent.sh" "$AGENT_NAME" > "$LOG_FILE" 2>&1 &
    PID=$!
    echo "$PID $AGENT_NAME" >> "$PID_FILE"
    echo "  PID: $PID | Log: $LOG_FILE"

    if [[ $i -lt $NUM_AGENTS ]]; then
        echo "  Waiting 5s before next agent..."
        sleep 5
    fi
done

echo ""
echo "All $NUM_AGENTS agents launched."
echo "PID file: $PID_FILE"
echo ""
echo "Monitor progress:"
echo "  bash docs/spec/.llm/scripts/status.sh"
echo ""
echo "View agent logs:"
echo "  tail -f docs/spec/.llm/logs/agent-*.log"
echo ""
echo "Stop all agents:"
echo "  cat $PID_FILE | awk '{print \$1}' | xargs kill 2>/dev/null"
echo ""

# Wait for all agents to complete
echo "Waiting for all agents to finish..."
wait
echo ""
echo "All agents have completed."
bash "${SCRIPT_DIR}/status.sh"
