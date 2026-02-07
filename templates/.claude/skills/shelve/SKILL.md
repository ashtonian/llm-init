---
name: shelve
description: Checkpoint work with structured handoff state
allowed-tools: Read, Write, Bash
---

Checkpoint current work with a structured handoff state.

## Instructions

1. Assess current work state:
   - What task or plan is currently in progress?
   - What files have been modified? (`git diff --name-only`)
   - What's the current git branch?
2. Record the current Claude Code session ID for potential `--resume` on pickup.
3. Create a structured handoff state with these sections:
   - **Completed Steps** -- what's done
   - **Current Step** -- what was in progress
   - **Files Modified** -- list of changed files
   - **Key Decisions** -- design choices made during this session
   - **Known Issues** -- problems the next agent should know about
   - **Next Actions** -- where to pick up
   - **Session ID** -- current session ID (for `--resume`)
4. If working on a **task file** (in `docs/spec/.llm/tasks/`):
   - Write the handoff state to the task's `## Handoff State` section
   - Commit WIP changes on the task branch
   - Move the task back to `docs/spec/.llm/tasks/backlog/`
5. If working on a **plan file** (in `docs/spec/.llm/plans/`):
   - Update the plan's Progress Log with the handoff state
   - Commit WIP changes
6. Update `docs/spec/.llm/PROGRESS.md` with any learnings from this session.
7. Confirm the shelve to the user with a summary of what was saved.

$ARGUMENTS
