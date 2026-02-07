---
name: new-task
description: Create a single task
allowed-tools: Read, Write, TaskCreate
---

Create a single task file in the backlog.

## Instructions

1. Read `docs/spec/.llm/templates/task.template.md` for the task format.
2. Read `.claude/rules/agent-guide.md` for tech stack and quality gates.
3. Determine the next task number by checking existing files in:
   - `docs/spec/.llm/tasks/backlog/`
   - `docs/spec/.llm/tasks/in_progress/`
   - `docs/spec/.llm/tasks/completed/`
   - `docs/spec/.llm/tasks/blocked/`
4. Create the task file at `docs/spec/.llm/tasks/backlog/NN-<slug>.md` where:
   - `NN` is the zero-padded task number
   - `<slug>` is a short kebab-case description
5. Also create a native task using TaskCreate with the same information.
6. Fill in: Phase, Priority, Dependencies, Objective, Steps, Verification, and Acceptance Criteria.
7. Verification commands should use the quality gates from the agent guide rules.
8. Show the created task file to the user for review.

## Task Description

$ARGUMENTS
