---
name: review
description: Run quality gates and review current work
allowed-tools: Read, Grep, Glob, Bash
---

Run quality gates and review current work.

## Instructions

1. Read `.claude/rules/agent-guide.md` for project-specific quality gate commands and the Production Code Quality Checklist.
2. Read `docs/spec/.llm/PROGRESS.md` for known patterns and conventions.
3. **Run quality gates** from the agent guide rules (build, test, lint, type-check as applicable).
4. **Check conventions**:
   - Code follows rules in `.claude/rules/` (go-patterns, typescript-patterns, etc.)
   - New files have appropriate structure and documentation
   - No hardcoded credentials, secrets, or environment-specific values
   - Error handling follows project patterns
   - Implementation matches technical spec (if one exists): data models, API contracts, error codes
5. **Spec compliance** (if a technical spec exists for the changed feature):
   - Every data model field matches the spec (types, constraints, nullability)
   - Every API endpoint matches the spec (path, method, request/response shape, status codes)
   - Every error code in the spec is handled in the implementation
   - Edge cases documented in the spec have corresponding code paths and tests
6. **Code quality audit**:
   - All error paths are tested, not just happy paths
   - Input validation exists at system boundaries (handlers, CLI, config parsing)
   - No swallowed errors (`_ = err` without justification)
   - Functions are < 60 lines; complex logic is commented with WHY
   - New public packages have `doc.go` with usage examples
   - README updated if new user-facing functionality was added
7. **Security check**:
   - No secrets, tokens, or passwords in code or config files
   - User input is validated and sanitized before use
   - SQL queries use parameterized statements (no string concatenation)
   - File paths from user input are sanitized
8. **Report results** in a structured format:
   - Quality gates: pass/fail with details
   - Spec compliance: field-by-field match (or N/A if no spec)
   - Code quality: issues found with file:line references
   - Security: issues found or clean
   - Convention issues: list with file and line
   - Recommendations: what to fix and how (prioritized)

$ARGUMENTS
