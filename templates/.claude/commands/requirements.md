Gather requirements interactively to produce a package specification.

## Instructions

You are entering an interactive requirements-gathering session. Your goal is to iteratively ask questions and make decisions with the user until you have enough information to produce a complete technical specification that can drive code generation.

**Do NOT write code in this session.** The output is a specification document only.

### Phase 1: Discovery (Broad Questions)

Start by understanding the big picture. Ask about:

- What is the purpose of this package/feature? What problem does it solve?
- Who are the users/consumers? (API clients, other services, end users, CLI users)
- What are the key use cases? Walk through 2-3 primary scenarios.
- Are there existing systems this needs to integrate with?
- Any hard constraints? (performance, compatibility, regulatory, timeline)

Ask these one group at a time. Wait for answers before proceeding.

### Phase 2: Scope & Boundaries

Narrow down the scope. Ask about:

- What is explicitly IN scope for v1? What's OUT of scope?
- What are the inputs and outputs for each use case?
- What data does this need to store or manage? What are the key entities?
- What external dependencies are needed? (databases, APIs, message queues)
- Non-functional requirements: latency, throughput, availability, data retention

### Phase 3: Design Decisions

For each major design choice, present the user with 2-4 options including tradeoffs:

- **Data storage**: relational, document, in-memory, file-based, embedded
- **API style**: REST, gRPC, GraphQL, CLI, library/SDK
- **Concurrency model**: synchronous, async/await, event-driven, actor model
- **Error handling**: error codes, typed errors, result types, exceptions
- **Authentication/authorization**: JWT, OAuth2, API keys, mTLS, none
- **Configuration**: env vars, config files, flags, remote config
- **Testing strategy**: unit-heavy, integration-heavy, E2E-heavy, property-based

For each decision:
1. Present available options with 1-sentence description
2. Explain tradeoffs (what you gain vs. sacrifice)
3. State your recommendation and why
4. Ask the user to choose

Record each decision with rationale.

### Phase 4: Edge Cases & Error Scenarios

Ask about failure modes and boundary conditions:

- What happens when inputs are invalid? (malformed, too large, missing fields)
- What happens when external services are unavailable?
- What are the failure modes? How should the system recover?
- Are there rate limits, quotas, or resource constraints?
- What are the security considerations? (injection, auth bypass, data leaks)
- What happens at scale? (10x, 100x current expected load)
- What are the data consistency requirements? (eventual, strong, causal)

### Phase 5: Draft Specification

Based on all gathered information, produce a spec document at `docs/spec/biz/{feature-name}-spec.md`:

```markdown
# {Feature Name} — Technical Specification

## Overview
- **Problem statement**: {what problem this solves}
- **Goals**: {what success looks like}
- **Non-goals**: {what's explicitly out of scope}

## Use Cases
### UC-1: {Name}
- **Actor**: {who}
- **Preconditions**: {what must be true}
- **Flow**: {step-by-step}
- **Postconditions**: {what's true after}
- **Error scenarios**: {what can go wrong}

## Data Models
### {Entity Name}
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUIDv7 | PK | {description} |

## API Contracts
### {Operation Name}
- **Method/Interface**: {details}
- **Input**: {request shape}
- **Output**: {response shape}
- **Errors**: {error codes and conditions}

## Error Handling
| Error Code | Condition | HTTP Status | User Message |
|------------|-----------|-------------|-------------|

## Non-Functional Requirements
- **Latency**: {p50, p99 targets}
- **Throughput**: {requests/sec}
- **Availability**: {SLA}
- **Data retention**: {policy}

## Architecture Decisions
| # | Decision | Rationale |
|---|----------|-----------|

## Dependencies
- {package/service}: {what for}

## Testing Strategy
- **Unit tests**: {what to test, coverage target}
- **Integration tests**: {what to test}
- **Edge cases to cover**: {list}

## Open Questions
- {anything unresolved}
```

### Phase 6: Iteration

Present the draft spec and ask:
- Does this capture everything?
- Anything missing, incorrect, or unclear?
- Any priorities to adjust?
- Ready to move to implementation planning?

If the user has feedback, incorporate it and present the updated spec. **Repeat until the user approves.**

### Completion

When the spec is approved:
1. Save the final spec document
2. Suggest next steps:
   - Use `/plan` with `codegen.plan.llm` for implementation planning
   - Use `/decompose` to break into parallel tasks
3. Update `docs/spec/.llm/PROGRESS.md` with a note about the new spec

## Topic

$ARGUMENTS
