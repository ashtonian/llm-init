#!/usr/bin/env bash
set -euo pipefail

# run-agent.sh — Autonomous agent loop
#
# Picks tasks from backlog, claims them atomically, executes in an isolated
# git worktree, and merges completed work back to master.
#
# Usage:
#   bash docs/spec/.llm/scripts/run-agent.sh [agent-name]
#
# Environment variables:
#   BRANCH_PREFIX        Git branch prefix (default: task/)
#   MAX_TURNS            Max Claude Code turns per task (default: 150)
#   WAIT_INTERVAL        Seconds between polling when no tasks available (default: 10)
#   MAX_EMPTY_WAITS      Max empty polling cycles before shutdown (default: 60)
#   SKIP_API_KEY_UNSET   Set to 1 to keep ANTHROPIC_API_KEY (for API-key auth) (default: unset)
#   SKIP_PERMISSIONS     Set to 1 to use --dangerously-skip-permissions (default: 0, uses .claude/settings.json)

AGENT_NAME="${1:-agent-$(date +%s | tail -c 5)}"

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${HARNESS_DIR}/../../.." && pwd)"

TASKS_DIR="${HARNESS_DIR}/tasks"
LOCK_DIR="${TASKS_DIR}/.locks"
LOG_DIR="${HARNESS_DIR}/logs"
WORKTREE_DIR="${HARNESS_DIR}/worktrees/${AGENT_NAME}"
PROGRESS_FILE="${HARNESS_DIR}/PROGRESS.md"
AGENT_GUIDE="${HARNESS_DIR}/AGENT_GUIDE.md"

# Config
BRANCH_PREFIX="${BRANCH_PREFIX:-task/}"
MAX_TURNS="${MAX_TURNS:-150}"
WAIT_INTERVAL="${WAIT_INTERVAL:-10}"
MAX_EMPTY_WAITS="${MAX_EMPTY_WAITS:-60}"
SKIP_API_KEY_UNSET="${SKIP_API_KEY_UNSET:-}"
SKIP_PERMISSIONS="${SKIP_PERMISSIONS:-0}"

# Ensure directories exist
mkdir -p "${TASKS_DIR}/backlog" "${TASKS_DIR}/in_progress" "${TASKS_DIR}/completed" "${TASKS_DIR}/blocked" "${LOCK_DIR}" "${LOG_DIR}"

# --- Logging ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${AGENT_NAME}] $*"
}

# --- Task Selection ---

check_dependencies() {
    local task_file="$1"
    local deps
    deps=$(grep "^## Dependencies:" "$task_file" | sed 's/## Dependencies: //' || true)

    if [[ -z "$deps" ]] || [[ "$deps" == "None" ]] || [[ "$deps" == "none" ]]; then
        return 0
    fi

    local dep_nums
    dep_nums=$(echo "$deps" | sed 's/[Tt]asks\?//g' | grep -oE '[0-9]+' || true)
    for num in $dep_nums; do
        local padded
        padded=$(printf "%02d" "$num")
        if ! ls "${TASKS_DIR}/completed/"*"${padded}"* >/dev/null 2>&1; then
            return 1
        fi
    done
    return 0
}

get_next_task() {
    for task_file in "${TASKS_DIR}/backlog/"*.md; do
        [[ -f "$task_file" ]] || continue
        if check_dependencies "$task_file"; then
            echo "$task_file"
            return 0
        fi
    done
    return 1
}

# --- Atomic Task Claiming ---

claim_task() {
    local task_file="$1"
    local task_name
    task_name="$(basename "$task_file" .md)"
    local lock_file="${LOCK_DIR}/${task_name}.lock"

    if mkdir "$lock_file" 2>/dev/null; then
        echo "$AGENT_NAME" > "$lock_file/owner"
        echo "$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')" > "$lock_file/claimed_at"
        mv "$task_file" "${TASKS_DIR}/in_progress/"
        log "Claimed task: $task_name"
        return 0
    else
        return 1
    fi
}

release_task() {
    local task_name="$1"
    local lock_file="${LOCK_DIR}/${task_name}.lock"
    rm -rf "$lock_file"
}

# --- Git Worktree ---

setup_worktree() {
    cd "$PROJECT_ROOT"
    if [[ -d "$WORKTREE_DIR" ]]; then
        cd "$WORKTREE_DIR"
        git checkout --detach master 2>/dev/null || git checkout --detach main 2>/dev/null || true
        git reset --hard HEAD
        git clean -fd
    else
        git worktree add --detach "$WORKTREE_DIR" HEAD
    fi
    cd "$PROJECT_ROOT"
}

sync_worktree() {
    cd "$WORKTREE_DIR"
    git checkout --detach master 2>/dev/null || git checkout --detach main 2>/dev/null || true
    git reset --hard HEAD
    git clean -fd
    cd "$PROJECT_ROOT"
}

cleanup_worktree() {
    cd "$PROJECT_ROOT"
    if [[ -d "$WORKTREE_DIR" ]]; then
        git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
    fi
}

# --- Prompt Construction ---

build_prompt() {
    local task_file="$1"
    local task_content
    task_content="$(cat "$task_file")"

    local agent_guide_content=""
    if [[ -f "$AGENT_GUIDE" ]]; then
        agent_guide_content="$(cat "$AGENT_GUIDE")"
    fi

    local progress_content=""
    if [[ -f "$PROGRESS_FILE" ]]; then
        progress_content="$(cat "$PROGRESS_FILE")"
    fi

    cat <<PROMPT
You are an autonomous coding agent working on this project.
You are agent "${AGENT_NAME}". Each task invocation gives you a fresh context window.
You are working in an isolated git worktree. Your changes will be merged to master when complete.

## Project Context (Agent Guide)

${agent_guide_content}

## Cross-Iteration Memory (PROGRESS.md)

${progress_content}

## Your Task

${task_content}

## Working Instructions

1. Read the task carefully and understand ALL steps and acceptance criteria.
2. Read the progress log above to understand what previous iterations accomplished.
3. Read CLAUDE.md and docs/spec/LLM.md if you need orchestration or convention context.
4. Read relevant framework guides (docs/spec/framework/) before writing code.
5. **Spec-first**: Before writing any code, verify a technical spec exists for the feature. Check the task's "Technical Spec Reference" section.
   - If a spec exists, read it and cross-reference your implementation against it at each step.
   - If no spec exists and the task involves non-trivial code, create one first and signal TASK_BLOCKED for review.
6. Implement all steps in the task.
7. **Write production-quality code** — follow the Production Code Quality Checklist in AGENT_GUIDE.md:
   - Error handling: all error paths tested, errors wrapped with context, no swallowed errors
   - Input validation: at all system boundaries (handlers, CLI, config)
   - Testing: table-driven tests, both happy path and error cases, memory backends for unit tests
   - Documentation: doc.go for public packages, doc comments on exports, WHY comments on complex logic
   - Code structure: functions < 60 lines, domain types have Validate(), services accept interfaces
8. Run the verification commands listed in the task.
9. If no verification commands are listed, run the quality gates from docs/spec/.llm/AGENT_GUIDE.md.
10. Verify ALL acceptance criteria checkboxes are satisfied.
11. Commit your changes with a descriptive message. Do NOT push.
12. If you cannot complete the task, signal TASK_BLOCKED with a clear reason.

## Turn Budget

You have a maximum of ${MAX_TURNS} turns. Plan your work accordingly:
- At ~80% of turns used, start wrapping up or preparing to shelve at a clean checkpoint.
- Prefer shelving at a point where all tests pass rather than mid-implementation.
- Signal TASK_SHELVED proactively if you realize the remaining work exceeds your budget.

## Debugging Protocol

If tests fail or code doesn't build:
1. Read the FULL error message — don't guess at the cause.
2. Reproduce in isolation (single test, minimal case).
3. Add targeted logging, re-run, observe.
4. Fix the root cause, not the symptom.
5. Verify the fix doesn't break other tests.
6. Remove debug logging before committing.
7. If stuck after 3 attempts on the same error, signal TASK_BLOCKED with the full error output.

## Completion Protocol

When the task is FULLY complete and ALL acceptance criteria are verified, output EXACTLY this on its own line:

TASK_COMPLETE

Then output a brief summary (2-5 sentences) of what you accomplished for the progress log.

If you are blocked and cannot proceed, output EXACTLY this:

TASK_BLOCKED: <reason why you are blocked>

If you are running low on turns, or need to pause and let another agent continue, output EXACTLY:

TASK_SHELVED

Then output a structured handoff state:
- **Completed Steps**: Which steps from the task are done
- **Current Step**: What you were working on
- **Files Modified**: List of files you changed
- **Key Decisions**: Any design decisions or approaches chosen
- **Known Issues**: Any problems the next agent should know about
- **Next Actions**: What the next agent should do first

The next agent will receive this handoff state and continue from where you left off.
PROMPT
}

# --- Progress Tracking ---

append_progress() {
    local task_name="$1"
    local log_file="$2"

    local summary
    summary=$(sed -n '/TASK_COMPLETE/,$ p' "$log_file" | tail -n +2 | head -20)
    if [[ -z "$summary" ]]; then
        summary="Task completed (no summary provided)"
    fi

    # Append to PROGRESS.md Iteration Log section
    cat >> "$PROGRESS_FILE" <<EOF

### $(date '+%Y-%m-%d %H:%M:%S') — ${AGENT_NAME} — ${task_name}
${summary}

EOF
    log "Updated PROGRESS.md with task summary"
}

# --- Task Execution ---

execute_task() {
    local task_file="$1"
    local task_name
    task_name="$(basename "$task_file" .md)"
    local log_file="${LOG_DIR}/${AGENT_NAME}-${task_name}-$(date '+%Y%m%d-%H%M%S').log"
    local branch_name="${BRANCH_PREFIX}${task_name}"

    log "Starting task: $task_name"

    # Set up worktree and branch
    sync_worktree
    cd "$WORKTREE_DIR"
    git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name"

    # Build prompt
    local prompt
    prompt="$(build_prompt "$task_file")"

    # Check for existing session ID from a previous shelved run
    local resume_id=""
    if grep -q "^**Session ID**:" "$task_file" 2>/dev/null; then
        resume_id=$(grep "^**Session ID**:" "$task_file" | head -1 | sed 's/.*: //')
    fi

    # Run Claude Code
    log "Spawning Claude Code (max turns: $MAX_TURNS)..."
    local exit_code=0
    local claude_args=(--print --output-format text --max-turns "$MAX_TURNS")
    if [[ "$SKIP_PERMISSIONS" == "1" ]]; then
        claude_args+=(--dangerously-skip-permissions)
    fi
    if [[ -n "$resume_id" ]]; then
        claude_args+=(--resume "$resume_id")
        log "Resuming session: $resume_id"
    fi
    echo "$prompt" | claude "${claude_args[@]}" \
        > "$log_file" 2>&1 || exit_code=$?

    # Extract session ID from log for potential future --resume
    local session_id=""
    session_id=$(grep -oE 'session_id=[a-f0-9-]+' "$log_file" | head -1 | sed 's/session_id=//' || true)

    cd "$PROJECT_ROOT"

    # Check result
    if [[ $exit_code -eq 0 ]] && grep -q "TASK_COMPLETE" "$log_file"; then
        log "Task $task_name completed successfully"

        # Merge to master
        if git merge "$branch_name" --no-ff -m "feat: complete ${task_name} [${AGENT_NAME}]" 2>/dev/null; then
            log "Merged $branch_name to master"
            append_progress "$task_name" "$log_file"
            mv "${TASKS_DIR}/in_progress/$(basename "$task_file")" "${TASKS_DIR}/completed/"
            release_task "$task_name"
            git branch -d "$branch_name" 2>/dev/null || true
            log "Task $task_name: done"
        else
            log "ERROR: Merge failed for $branch_name. Moving task to blocked."
            git merge --abort 2>/dev/null || true
            mv "${TASKS_DIR}/in_progress/$(basename "$task_file")" "${TASKS_DIR}/blocked/"
            release_task "$task_name"
        fi

    elif grep -q "TASK_SHELVED" "$log_file"; then
        log "Task $task_name shelved by agent"
        # Extract shelved state from log (everything between TASK_SHELVED and end)
        local shelved_state
        shelved_state=$(sed -n '/TASK_SHELVED/,$ p' "$log_file" | tail -n +2 | head -50)

        # Update the task file with handoff state
        local task_in_progress="${TASKS_DIR}/in_progress/$(basename "$task_file")"
        # Remove existing handoff state content (everything after ## Handoff State)
        if grep -q "^## Handoff State" "$task_in_progress"; then
            sed -i.bak '/^## Handoff State/,$ { /^## Handoff State/!{ /^## /!d; }; }' "$task_in_progress"
            rm -f "$task_in_progress.bak"
        fi
        cat >> "$task_in_progress" <<EOF

## Handoff State
**Shelved by**: ${AGENT_NAME}
**Shelved at**: $(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')
**Branch**: ${branch_name}
**Session ID**: ${session_id:-unknown}

${shelved_state}
EOF

        # Commit WIP on the branch
        cd "$WORKTREE_DIR"
        git add -A
        git commit -m "wip: shelved ${task_name} [${AGENT_NAME}]" --allow-empty 2>/dev/null || true
        cd "$PROJECT_ROOT"

        # Move back to backlog (not blocked) so it gets picked up again
        mv "$task_in_progress" "${TASKS_DIR}/backlog/"
        release_task "$task_name"
        log "Task $task_name shelved and returned to backlog"

    elif grep -q "TASK_BLOCKED" "$log_file"; then
        local reason
        reason=$(grep "TASK_BLOCKED" "$log_file" | head -1 | sed 's/.*TASK_BLOCKED: //')
        log "Task $task_name blocked: $reason"
        mv "${TASKS_DIR}/in_progress/$(basename "$task_file")" "${TASKS_DIR}/blocked/"
        release_task "$task_name"

    else
        local tail_output
        tail_output=$(tail -5 "$log_file" 2>/dev/null || echo "no output")
        log "Task $task_name failed (exit code: $exit_code). Last output:"
        log "$tail_output"
        mv "${TASKS_DIR}/in_progress/$(basename "$task_file")" "${TASKS_DIR}/blocked/"
        release_task "$task_name"
    fi
}

# --- Main Loop ---

log "Starting autonomous agent loop"
log "Config: MAX_TURNS=$MAX_TURNS, WAIT_INTERVAL=$WAIT_INTERVAL, MAX_EMPTY_WAITS=$MAX_EMPTY_WAITS"

# Optionally unset API key to force subscription auth
if [[ -z "$SKIP_API_KEY_UNSET" ]]; then
    unset ANTHROPIC_API_KEY 2>/dev/null || true
fi

setup_worktree

CONSECUTIVE_EMPTY=0

while true; do
    TASK_FILE=$(get_next_task) || true

    if [[ -z "${TASK_FILE:-}" ]]; then
        IN_PROGRESS=$(ls "${TASKS_DIR}/in_progress/"*.md 2>/dev/null | wc -l || echo 0)
        BACKLOG=$(ls "${TASKS_DIR}/backlog/"*.md 2>/dev/null | wc -l || echo 0)

        if [[ "$IN_PROGRESS" -eq 0 ]] && [[ "$BACKLOG" -eq 0 ]]; then
            log "All tasks complete! Agent shutting down."
            break
        fi

        CONSECUTIVE_EMPTY=$((CONSECUTIVE_EMPTY + 1))
        if [[ "$CONSECUTIVE_EMPTY" -ge "$MAX_EMPTY_WAITS" ]]; then
            log "No available tasks for $MAX_EMPTY_WAITS cycles. Shutting down."
            break
        fi

        log "No tasks available (in_progress: $IN_PROGRESS, backlog: $BACKLOG). Waiting ${WAIT_INTERVAL}s... ($CONSECUTIVE_EMPTY/$MAX_EMPTY_WAITS)"
        sleep "$WAIT_INTERVAL"
        continue
    fi

    CONSECUTIVE_EMPTY=0

    if claim_task "$TASK_FILE"; then
        execute_task "${TASKS_DIR}/in_progress/$(basename "$TASK_FILE")"
    else
        log "Failed to claim $(basename "$TASK_FILE"), another agent got it"
    fi
done

cleanup_worktree
log "Agent shutdown complete"
