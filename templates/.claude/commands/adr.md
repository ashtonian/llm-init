Create an Architecture Decision Record (ADR) for a design choice.

## Instructions

1. Read existing ADRs in `docs/spec/biz/` (files matching `adr-*.md`).
2. Determine the next ADR number (e.g., `adr-001`, `adr-002`).
3. Discuss the decision with the user:
   - What is the context? What forces are at play?
   - What options were considered?
   - What was decided and why?
   - What are the consequences (positive and negative)?

4. Create the ADR at `docs/spec/biz/adr-{NNN}-{slug}.md`:

```markdown
# ADR-{NNN}: {Title}

| Field | Value |
|-------|-------|
| **Status** | proposed / accepted / deprecated / superseded |
| **Date** | {date} |
| **Deciders** | {who was involved} |
| **Supersedes** | {ADR number, if applicable} |

## Context

{What is the issue that we're seeing that is motivating this decision or change?
What forces are at play (technical, business, organizational)?}

## Decision

{What is the change that we're proposing and/or doing?}

## Options Considered

### Option 1: {Name}
- **Pros**: {list}
- **Cons**: {list}
- **Effort**: {low/medium/high}

### Option 2: {Name}
- **Pros**: {list}
- **Cons**: {list}
- **Effort**: {low/medium/high}

## Consequences

### Positive
- {benefit 1}
- {benefit 2}

### Negative
- {tradeoff 1}
- {tradeoff 2}

### Risks
- {risk 1} — mitigation: {how}

## Related
- {Links to specs, issues, other ADRs}
```

5. Present the ADR to the user for review. Iterate until approved.
6. Update `docs/spec/.llm/PROGRESS.md` with a note about the new ADR.

## Decision Topic

$ARGUMENTS
