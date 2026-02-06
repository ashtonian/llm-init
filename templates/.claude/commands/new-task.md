Create a single task file in the backlog.

## Instructions

1. Read `docs/spec/.llm/templates/task.template.md` for the task format.
2. Read `docs/spec/.llm/AGENT_GUIDE.md` for tech stack and quality gates.
3. Determine the next task number by checking existing files in:
   - `docs/spec/.llm/tasks/backlog/`
   - `docs/spec/.llm/tasks/in_progress/`
   - `docs/spec/.llm/tasks/completed/`
   - `docs/spec/.llm/tasks/blocked/`
4. Create the task file at `docs/spec/.llm/tasks/backlog/NN-<slug>.md` where:
   - `NN` is the zero-padded task number
   - `<slug>` is a short kebab-case description
5. Fill in: Phase, Priority, Dependencies, Objective, Steps, Verification, and Acceptance Criteria.
6. Verification commands should use the quality gates from `AGENT_GUIDE.md`.
7. Show the created task file to the user for review.

## Task Description

$ARGUMENTS
