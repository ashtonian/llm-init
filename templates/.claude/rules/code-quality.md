# Code Quality Standards

Quantitative thresholds and conventions for maintaining code quality across the codebase. These are enforced during code review and quality gates.

## Complexity Limits

| Metric | Threshold | Action When Exceeded |
|--------|-----------|---------------------|
| **Cyclomatic complexity** | Max 10 per function | Split into smaller functions |
| **Function length** | Max 60 lines | Extract helper functions |
| **Nesting depth** | Max 3 levels | Use early returns, extract conditions |
| **Parameters** | Max 4 per function | Introduce parameter object/options struct |
| **File length** | Max 500 lines | Split into focused modules |
| **Type methods** | Max 10 per type/class | Split into focused types |

### Measuring Complexity

**Go:**
```bash
# gocyclo for cyclomatic complexity
gocyclo -over 10 ./...

# gocognit for cognitive complexity
gocognit -over 15 ./...
```

**TypeScript:**
```bash
# ESLint complexity rule
# .eslintrc: { "rules": { "complexity": ["error", 10] } }
npx eslint --rule 'complexity: ["error", 10]' src/
```

## Duplication Thresholds

| Scope | Threshold | Action |
|-------|-----------|--------|
| Exact duplicate blocks | 0 tolerance | Extract shared function immediately |
| Similar blocks (>80% match) | Max 2 occurrences | Extract on 3rd occurrence |
| Similar patterns across packages | Assess case-by-case | Extract shared utility if pattern is stable |

### When NOT to Deduplicate

- Test setup code: Some duplication in tests is OK for readability
- Generated code: Don't manually deduplicate generated code
- Coincidental similarity: Two blocks that happen to look similar but serve different purposes and may diverge

## Naming Conventions

### Go

| Element | Convention | Example |
|---------|-----------|---------|
| Package | Short, lowercase, singular noun | `user`, `auth`, `billing` |
| Exported function | PascalCase, verb phrase | `CreateUser`, `ValidateToken` |
| Unexported function | camelCase, verb phrase | `parseInput`, `buildQuery` |
| Interface | PascalCase, "-er" suffix for single-method | `Reader`, `UserRepository` |
| Struct | PascalCase, noun | `User`, `OrderItem`, `Config` |
| Constant | PascalCase (exported), camelCase (unexported) | `MaxRetries`, `defaultTimeout` |
| Error variable | `Err` prefix | `ErrNotFound`, `ErrUnauthorized` |
| Test function | `Test{Type}_{Method}` or `Test{Type}_{Scenario}` | `TestUserService_Create` |
| File name | snake_case | `user_service.go`, `order_handler.go` |

### TypeScript

| Element | Convention | Example |
|---------|-----------|---------|
| File name | kebab-case or PascalCase for components | `user-service.ts`, `UserCard.tsx` |
| Class | PascalCase | `UserService`, `OrderRepository` |
| Interface | PascalCase (no `I` prefix) | `UserRepository`, `Config` |
| Function | camelCase, verb phrase | `createUser`, `validateInput` |
| Constant | UPPER_SNAKE_CASE for true constants | `MAX_RETRIES`, `API_BASE_URL` |
| React component | PascalCase | `UserProfile`, `DashboardLayout` |
| Hook | `use` prefix, camelCase | `useAuth`, `useUserProfile` |
| Type | PascalCase | `CreateUserInput`, `PaginatedResponse<T>` |
| Enum | PascalCase name, PascalCase members | `UserRole.Admin`, `OrderStatus.Pending` |

### Universal Naming Rules

- **Be descriptive**: `usersByTenantID` not `data`, `isEmailVerified` not `flag`
- **Avoid abbreviations**: `configuration` not `cfg`, `repository` not `repo` (exception: widely known abbreviations like `id`, `url`, `http`)
- **Boolean variables**: Use `is`, `has`, `can`, `should` prefix: `isActive`, `hasPermission`, `canEdit`
- **Collections**: Use plural nouns: `users`, `orderItems`, `activeConnections`
- **Functions that return booleans**: Use `is`, `has`, `can` prefix or question form: `isValid()`, `hasAccess()`, `canRetry()`

## Test Coverage Targets

| Layer | Minimum Coverage | Notes |
|-------|-----------------|-------|
| **Service/business logic** | 80%+ | All business rules, edge cases, error paths |
| **API handlers** | 75%+ | Happy path, validation errors, auth errors, not-found |
| **Repository/data access** | 70%+ | CRUD operations, constraint violations, not-found |
| **Utility packages** | 90%+ | Pure functions, parsing, formatting |
| **Generated code** | N/A | Don't measure coverage on generated code |
| **Configuration/startup** | 50%+ | Validate config parsing, fail-fast on bad config |

### What to Prioritize in Testing

1. **Business rules**: The core logic that makes the application valuable
2. **Error handling paths**: Every `if err != nil` or `catch` block
3. **Boundary conditions**: Empty inputs, max values, nil/null, concurrent access
4. **Integration points**: API contracts, database queries, external service calls

### What NOT to Test

- Trivial getters/setters with no logic
- Framework/library internals (test YOUR code, not theirs)
- Private methods directly (test through public API)
- Implementation details that may change

## Code Review Criteria

Every code change should be reviewed against these criteria:

### Must Pass (blocking)

- [ ] All tests pass (including new tests for new code)
- [ ] No lint warnings or errors
- [ ] No hardcoded secrets, credentials, or PII
- [ ] Error handling: every error checked and handled
- [ ] Input validation at system boundaries
- [ ] No N+1 queries introduced
- [ ] Function complexity within limits (cyclomatic <= 10, length <= 60 lines)

### Should Pass (strong preference)

- [ ] New code has test coverage >= layer threshold
- [ ] Naming follows conventions
- [ ] No code duplication introduced
- [ ] Public API documented with doc comments
- [ ] Logging follows structured logging standards
- [ ] Context propagated correctly (Go: context.Context first param; TS: AsyncLocalStorage)

### Nice to Have

- [ ] Improves existing code quality (boy scout rule)
- [ ] Adds missing tests for touched code paths
- [ ] Updates PROGRESS.md with notable decisions

## Refactoring Triggers

When any of these thresholds are exceeded, create a refactoring task:

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Function exceeds line limit | >60 lines | Split into smaller functions |
| Cyclomatic complexity too high | >10 | Simplify conditions, extract methods |
| Duplicated code | 3+ occurrences | Extract shared utility |
| Parameter list too long | >4 parameters | Introduce options struct/parameter object |
| File exceeds limit | >500 lines | Split into focused modules |
| Test coverage drops | Below layer threshold | Add missing tests before next feature |
| Multiple unhandled TODOs | >3 TODOs in one file | Address or create task files for each |

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Correct Pattern |
|--------------|-------------|----------------|
| Magic numbers | Unclear intent, hard to change | Named constants with descriptive names |
| God function (>100 lines) | Hard to understand, test, and maintain | Extract focused helper functions |
| Stringly typed | No compiler help, easy to typo | Use enums, constants, or domain types |
| Comments explaining WHAT | Comments get stale, code should be self-documenting | Rename for clarity, comment WHY not WHAT |
| Premature abstraction | Complexity without proven need | Wait for 3 occurrences before abstracting |
| Dead code (commented out) | Clutters codebase, available in git history | Delete it. Git remembers. |
| Boolean parameters | Unclear at call site | Use options struct or separate functions |
| Deep inheritance hierarchy | Rigid, fragile, hard to reason about | Prefer composition over inheritance |
| Catch-all error handling | Hides bugs, prevents specific recovery | Catch specific error types |
| Global mutable state | Race conditions, testing difficulty | Dependency injection, immutable config |
