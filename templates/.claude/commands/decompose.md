Break the following request into parallel tasks for the agent harness.

## Instructions

1. Read `docs/spec/.llm/PROGRESS.md` for codebase patterns and prior context.
2. Read `docs/spec/.llm/STRATEGY.md` for the current project decomposition.
3. Read `docs/spec/.llm/AGENT_GUIDE.md` for tech stack and quality gates.
4. Verify a technical spec exists for this work. If no spec exists, the **first task** must be "Create technical specification" using `codegen.plan.llm` as a reference for spec contents.
5. Decompose the request into 2-8 independent subtasks following these rules:
   - Each task should take **75-150 Claude turns**
   - Prefer **wide not deep** — maximize independent tasks, minimize dependency chains
   - Use `## Dependencies: Tasks NN, NN` format for ordering
   - Each task must have its own `## Verification` commands
   - Each task must be self-contained (an agent with no prior context can execute it)
6. For each task, create a file in `docs/spec/.llm/tasks/backlog/` using the template:
   `docs/spec/.llm/templates/task.template.md`
7. Update `docs/spec/.llm/STRATEGY.md` with the decomposition.
8. Present the task list with dependencies to the user for approval.

## Request

$ARGUMENTS
