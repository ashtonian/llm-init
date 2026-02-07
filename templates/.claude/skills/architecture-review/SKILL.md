---
name: architecture-review
description: Assess architecture decisions tradeoffs and edge cases
allowed-tools: Read, Write, Glob, Grep
---

Review architecture decisions, assess tradeoffs, and identify edge cases.

## Instructions

Perform a comprehensive architecture and design review of the current codebase or a specified feature area.

### Phase 1: Inventory Decisions

1. Read `docs/spec/.llm/PROGRESS.md` for documented architecture decisions.
2. Read relevant specs in `docs/spec/biz/`.
3. Read existing ADRs (`docs/spec/biz/adr-*.md`) if any exist.
4. Scan the codebase for architectural patterns:
   - Project structure and module organization
   - Dependency injection / configuration patterns
   - Data flow and state management
   - External integrations and boundaries
   - Error handling patterns
   - Concurrency and synchronization patterns
   - API design patterns

### Phase 2: Assess Each Decision

For each architectural decision found, evaluate:

| Criterion | Question |
|-----------|----------|
| **Fitness** | Does this decision serve the current requirements well? |
| **Tradeoffs** | What was gained? What was sacrificed? |
| **Alternatives** | What other approaches could work? Would they be better now? |
| **Scalability** | How does this decision scale with growth (data, traffic, team size)? |
| **Maintainability** | How easy is it to change this later? What's the blast radius of a change? |
| **Risk** | What could go wrong? What's the worst-case scenario? |
| **Edge Cases** | What boundary conditions exist? Are they handled? |
| **Consistency** | Is this pattern applied consistently, or are there deviations? |

### Phase 3: Identify Issues

Look for:

- **Coupling**: Components that are too tightly coupled or have circular dependencies
- **Missing abstractions**: Areas where an interface or abstraction boundary would help
- **Inconsistencies**: Different patterns used for the same concern
- **Over-engineering**: Abstractions that add complexity without clear benefit
- **Under-engineering**: Areas that will break under foreseeable growth
- **Security gaps**: Auth boundaries, input validation, data exposure
- **Performance risks**: N+1 queries, unbounded collections, missing indexes, no caching
- **Testing gaps**: Untested critical paths, missing integration tests
- **Operational gaps**: Missing health checks, no observability, no graceful shutdown

### Phase 4: Report

Present findings in this format:

```
## Architecture Review: {scope}

### Summary
{1-3 sentence executive summary}

### Decisions Inventory
| # | Decision | Status | Risk |
|---|----------|--------|------|
| 1 | {decision} | {sound/questionable/needs-change} | {low/medium/high} |

### Detailed Analysis

#### Decision N: {title}
- **Current approach**: {description}
- **Tradeoffs**: {what was gained vs sacrificed}
- **Alternatives**: {options that could work}
- **Edge cases**: {boundary conditions and whether they're handled}
- **Risk assessment**: {what could go wrong, likelihood, impact}
- **Recommendation**: {keep/modify/replace} -- {rationale}

### Issues Found
| # | Issue | Severity | Category | Recommendation |
|---|-------|----------|----------|----------------|
| 1 | {issue} | {critical/high/medium/low} | {coupling/security/perf/...} | {what to do} |

### Recommendations (Prioritized)
1. **[Critical]** {highest priority recommendation}
2. **[High]** {next recommendation}
3. **[Medium]** ...
```

### Phase 5: ADR Generation (Optional)

If significant decisions lack documentation, offer to create Architecture Decision Records using `/adr`. Well-documented decisions prevent re-litigation and help onboard new team members.

$ARGUMENTS
