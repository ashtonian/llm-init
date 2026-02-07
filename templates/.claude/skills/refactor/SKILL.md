---
name: refactor
description: Analyze codebase for technical debt and plan targeted refactoring
allowed-tools: Read, Write, Glob, Grep, Bash
---

# Refactoring Skill

Structured workflow for identifying refactoring opportunities, assessing impact, and executing safe refactors that preserve behavior. Produces a refactoring plan with before/after examples and generates task files for large refactors.

## Workflow

### Step 1: Identify Refactoring Opportunities

Scan the codebase for common refactoring signals:

| Signal | Detection Method |
|--------|-----------------|
| **Code duplication** | Search for repeated patterns across files (similar function signatures, copy-paste blocks) |
| **High complexity** | Functions exceeding 60 lines, deeply nested conditionals (>3 levels), high cyclomatic complexity |
| **Code smells** | Long parameter lists (>4 params), god objects, feature envy, primitive obsession |
| **Naming issues** | Inconsistent naming conventions, misleading names, abbreviations without context |
| **Dead code** | Unused exports, unreachable branches, commented-out code blocks |
| **Tight coupling** | Concrete type dependencies where interfaces should be used, circular imports |
| **Missing abstractions** | Repeated patterns that could be extracted into shared utilities or interfaces |

For each opportunity found, record:
- **File and line range**: Exact location
- **Category**: Which signal it matches
- **Severity**: High (blocks new features), Medium (increases maintenance cost), Low (cosmetic)
- **Estimated effort**: Small (< 1 hour), Medium (1-4 hours), Large (> 4 hours)

Output: Refactoring opportunity inventory sorted by severity then effort.

### Step 2: Impact Analysis

For each candidate refactoring, assess:

1. **Blast radius**: How many files/packages are affected?
2. **Test coverage**: Are the affected areas well-tested? Check coverage reports.
3. **Active development**: Is anyone currently working on these files? Check recent git history.
4. **Risk level**: Could this break existing behavior?

```
Impact Matrix:
| Refactoring | Files Affected | Test Coverage | Risk | Priority |
|-------------|---------------|---------------|------|----------|
| Extract X   | 3             | 85%           | Low  | High     |
| Rename Y    | 12            | 40%           | Med  | Medium   |
```

Rules:
- **Never refactor code with < 50% test coverage** without adding tests first
- **Never refactor during active incident response**
- **Prefer small, focused refactors** over large sweeping changes

### Step 3: Create Refactoring Plan

For each approved refactoring, document:

```markdown
## Refactoring: {Description}

### Motivation
Why this refactoring is needed (not just "code is messy" -- concrete impact on development).

### Before
{Actual code snippet showing the current state}

### After
{Code snippet showing the target state}

### Steps
1. {Concrete step with file paths}
2. {Next step}
3. ...

### Behavior Preservation
- [ ] All existing tests pass before starting
- [ ] No test modifications needed (tests validate behavior, not implementation)
- [ ] All existing tests pass after refactoring
- [ ] No new warnings or lint errors introduced

### Rollback
If the refactoring introduces issues: `git revert {commit}`. Each refactoring is a single commit.
```

Present the plan to the user for approval before proceeding.

### Step 4: Execute Refactoring

For each approved refactoring item:

1. **Verify tests pass** before starting: Run the full quality gates
2. **Make the change** in a single, focused commit
3. **Run tests** after each change -- stop immediately if anything fails
4. **Run linters** to catch any regressions
5. **Verify behavior preservation**: Compare test results before and after

Rules:
- **One refactoring per commit** -- never mix refactorings
- **Never change behavior** -- if a test needs to change, that's a behavior change, not a refactoring
- **Leave the code better than you found it** -- but only within the defined scope

### Step 5: Generate Task Files for Large Refactors

If a refactoring is too large for a single session (Large effort, >10 files affected):

1. Break it into independent, sequentially-executable chunks
2. Create task files in `docs/spec/.llm/tasks/backlog/` using the task template
3. Set `## Dependencies:` to enforce ordering where needed
4. Each task should be independently verifiable (tests pass after each task)
5. Update `docs/spec/.llm/STRATEGY.md` with the refactoring plan

### Step 6: Update Knowledge Base

After completing refactoring:

1. Update `docs/spec/.llm/PROGRESS.md` with:
   - Patterns discovered or established
   - Decisions made and rationale
   - Any issues encountered
2. If the refactoring establishes a new pattern, consider adding or updating a rule in `.claude/rules/`

## Common Refactoring Patterns

| Pattern | When to Apply | Example |
|---------|--------------|---------|
| **Extract Function** | Duplicated logic, long functions | Pull repeated validation into `validateInput()` |
| **Extract Interface** | Testing difficulty, tight coupling | Create `Repository` interface from concrete `PgRepo` |
| **Rename** | Misleading names, inconsistent conventions | `data` -> `userProfiles`, `handleStuff` -> `processPayment` |
| **Move** | Feature envy, wrong package/module | Move `FormatCurrency()` from `user` to `billing` package |
| **Inline** | Over-abstraction, single-use wrappers | Remove wrapper that just delegates to one function |
| **Replace Conditional with Polymorphism** | Long switch/if-else chains | Strategy pattern for payment processors |
| **Introduce Parameter Object** | Functions with >4 parameters | Group related params into a struct/type |

## Anti-Patterns

| Anti-Pattern | Why It's Bad |
|--------------|-------------|
| Refactoring without tests | No way to verify behavior preservation |
| "While I'm here" refactoring | Scope creep makes reviews harder and increases risk |
| Renaming in a large codebase without tooling | Partial renames cause build failures |
| Refactoring and adding features in the same commit | Impossible to isolate regressions |
| Refactoring code you don't understand | Read and understand first, then refactor |

## Arguments

$ARGUMENTS
