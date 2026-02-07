Interactive PRD-to-tasks pipeline. Generate a Product Requirements Document from a feature description, then convert it into sized task files for the parallel agent harness.

## Instructions

Work through 3 phases. Present options with **lettered choices** (A, B, C, D) for quick user responses.

### Phase 1: Interactive Discovery

Conduct a focused Q&A to understand the feature. Ask 2-3 questions per round, max 4 rounds.

**Round 1 — Scope & Users**
- Who is this for? (A) Internal team, B) End users, C) API consumers, D) All)
- What problem does it solve? (open-ended, 1-2 sentences)
- What's the MVP scope? (A) Minimal — one happy path, B) Standard — happy path + errors, C) Full — complete feature)

**Round 2 — Technical Shape**
- Primary interaction pattern? (A) REST API, B) GraphQL, C) CLI, D) UI form, E) Background job)
- Data storage needs? (A) New table/model, B) Extend existing model, C) No persistence, D) External service)
- Auth requirements? (A) None/public, B) Authenticated only, C) Role-based, D) Custom)

**Round 3 — Dependencies & Constraints** (if needed)
- External dependencies? (APIs, services, libraries)
- Performance constraints? (latency, throughput, data volume)
- Any existing code to build on?

**Round 4 — Edge Cases** (if needed)
- Error handling strategy? (A) Return errors to caller, B) Retry + fallback, C) Queue for later, D) Depends on case)
- Concurrency concerns? (A) Single-user, B) Multi-user but no conflicts, C) Needs locking/transactions)

Adapt questions based on previous answers. Skip rounds that aren't relevant.

### Phase 2: Generate PRD

After the Q&A, generate a structured PRD document:

```markdown
# PRD: {Feature Name}

## Summary
{2-3 sentence description}

## User Stories
- As a {role}, I want {action} so that {benefit}
- ...

## Acceptance Criteria
- [ ] {Criterion with specific, testable condition}
- ...

## Technical Approach
- {Architecture decisions from the Q&A}
- {Data model changes}
- {API contracts}

## Out of Scope
- {What this does NOT include}

## Priority Order
1. {Data layer / models}
2. {Business logic / services}
3. {API / UI layer}
4. {Integration / E2E tests}
```

Present the PRD to the user for review. Incorporate feedback before proceeding.

### Phase 3: Generate Task Files

Convert the PRD into task files in `docs/spec/.llm/tasks/backlog/`:

1. Read `docs/spec/.llm/PROGRESS.md` for codebase patterns
2. Read `docs/spec/.llm/STRATEGY.md` for existing decomposition
3. Read `docs/spec/.llm/AGENT_GUIDE.md` for tech stack
4. Split the PRD into **right-sized tasks** following these rules:
   - Each task describable in **2-3 sentences** (if not, split further)
   - Each task completable in **one fresh context window** (75-150 turns)
   - Each task **independently verifiable** (own build/test commands)
   - Dependency ordering: **data layer → business logic → API/UI → integration tests**
5. Create task files using `docs/spec/.llm/templates/task.template.md`
6. Set `## Dependencies:` headers based on the dependency ordering
7. Update `docs/spec/.llm/STRATEGY.md` with the new tasks
8. Present the task list with dependency graph to the user

### Sizing Discipline

Apply the 2-3 sentence test to every task. Examples:

| Good (right-sized) | Bad (too big) |
|---------------------|---------------|
| Add user model and migration | Build user management |
| Create GET /users endpoint with tests | Implement the REST API |
| Add login form component | Build authentication |

If a task fails the test, split it immediately.

## Feature Description

$ARGUMENTS
