# Spec-First Protocol

Before writing non-trivial code, verify a technical specification exists. This ensures implementations match requirements and prevents spec drift.

## When to Create a Spec

| Situation | Action |
|-----------|--------|
| New feature with data models or API endpoints | Create spec (use `codegen.plan.llm` template) |
| Bug fix or small change | No spec needed |
| Refactoring with no behavior change | No spec needed |
| New integration or external dependency | Create spec |

## Spec Contents

A technical code spec should define:
- **Data models**: Entities, field types, constraints, relationships
- **API contracts**: Endpoints, request/response shapes, status codes, error codes
- **Error handling**: Error types, recovery strategies, user-facing messages
- **State management**: Transitions, invariants, side effects
- **Testing strategy**: Unit/integration/E2E plan, edge cases, fixtures

## Spec Location

- Feature specs: `docs/spec/biz/{feature-name}-spec.md`
- Technical patterns: `.claude/rules/{topic}.md` (auto-loaded by file path)

## Compliance Verification

After implementation, verify:
1. Every data model matches the spec (fields, types, constraints)
2. Every API endpoint matches the spec (paths, methods, shapes)
3. Every error code matches the spec
4. All edge cases from the spec are handled
5. All test scenarios from the testing strategy are implemented
