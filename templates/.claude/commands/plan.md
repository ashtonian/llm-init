Help select the right plan template and create a plan file.

## Instructions

1. Read the available templates in `docs/spec/.llm/templates/`:

   | Template | Use When |
   |----------|----------|
   | `idea.plan.llm` | Starting from scratch — idea to working project |
   | `fullstack.plan.llm` | Full-stack feature (DB → API → UI → E2E) |
   | `feature.plan.llm` | Backend-focused feature (6 phases) |
   | `review.plan.llm` | Review/iteration cycle with quality gates |
   | `bugfix.plan.llm` | Bug investigation and fix |
   | `self-review.plan.llm` | Audit the LLM orchestration system |
   | `plan.template.llm` | Generic — anything else |

2. Based on the user's description, recommend the best template.
3. Create the plan file:
   ```
   cp docs/spec/.llm/templates/<template> docs/spec/.llm/plans/<name>.plan.llm
   ```
4. Pre-fill the plan with:
   - Metadata (timestamp, status: planning)
   - Objective from the user's description
   - Initial implementation steps
5. Present the plan to the user for review before proceeding.

## Description

$ARGUMENTS
