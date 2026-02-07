# Git Workflow Conventions

Standard conventions for branching, commits, pull requests, and merge strategies. Consistent git practices make history readable and automation reliable.

## Branch Naming

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New functionality | `feature/user-invitations` |
| `fix/` | Bug fixes | `fix/login-timeout-handling` |
| `refactor/` | Code quality improvements (no behavior change) | `refactor/extract-auth-middleware` |
| `docs/` | Documentation only | `docs/api-authentication-guide` |
| `chore/` | Maintenance, dependencies, CI changes | `chore/upgrade-go-1.23` |
| `agent/` | Agent-created task branches | `agent/task-005-user-model` |

### Branch Naming Rules

- Use lowercase with hyphens: `feature/user-invitations` (not `Feature/UserInvitations`)
- Keep it short but descriptive: max ~50 characters after the prefix
- Include ticket/task number when available: `feature/PROJ-123-user-invitations`
- Agent branches use task slug: `agent/task-005-add-user-model-and-migration`

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | When to Use | Example |
|------|------------|---------|
| `feat` | New feature or functionality | `feat(auth): add JWT refresh token rotation` |
| `fix` | Bug fix | `fix(api): handle nil pointer in user lookup` |
| `refactor` | Code change that neither fixes a bug nor adds a feature | `refactor(billing): extract payment processor interface` |
| `test` | Adding or updating tests | `test(user): add table-driven tests for validation` |
| `docs` | Documentation changes | `docs(api): add authentication endpoint examples` |
| `chore` | Maintenance, dependencies, CI | `chore(deps): upgrade chi from v5.0 to v5.1` |
| `perf` | Performance improvement | `perf(query): add index on users.tenant_id` |
| `ci` | CI/CD pipeline changes | `ci: add CodeQL security scanning` |
| `style` | Formatting, missing semicolons (no code change) | `style: run gofmt on billing package` |
| `build` | Build system or external dependency changes | `build: update Dockerfile base image to Go 1.23` |

### Rules

- **Subject line**: Max 72 characters, imperative mood ("add" not "added" or "adds")
- **Scope**: Optional, lowercase, identifies the module/package affected
- **Body**: Explain WHY, not WHAT (the diff shows WHAT). Wrap at 72 characters.
- **Footer**: Reference issues (`Closes #123`), note breaking changes (`BREAKING CHANGE:`)
- **One logical change per commit**: Don't mix features with refactoring

### Good Examples

```
feat(user): add email verification flow

Users now receive a verification email on signup. Unverified users
can log in but cannot create projects until verified.

Closes #45
```

```
fix(billing): prevent duplicate charge on retry

The idempotency key was generated per-attempt instead of per-operation,
causing duplicate charges when the payment gateway timed out and we
retried.

Fixes #123
```

```
refactor(auth): extract token validation into middleware

Token validation was duplicated across 6 handlers. Extracted into a
shared middleware that validates the JWT and populates the context
with tenant and user claims.

No behavior change. All existing tests pass.
```

### Bad Examples

```
# Too vague
fix: fix bug

# Not imperative mood
feat: added user feature

# Too long, multiple changes
feat(auth): add login endpoint, add registration endpoint, add password reset, update user model, add email service
```

## Pull Request Conventions

### PR Title

Follow the same format as commit messages (since PRs are usually squash-merged):

```
feat(auth): add JWT refresh token rotation
```

### PR Description Template

```markdown
## Summary
<!-- 1-3 sentences describing WHAT changed and WHY -->

## Changes
<!-- Bulleted list of specific changes -->
- Added X
- Updated Y
- Removed Z

## Testing
<!-- How was this tested? -->
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing performed: {describe scenario}

## Checklist
- [ ] Tests pass locally
- [ ] Lint passes with no new warnings
- [ ] Documentation updated (if applicable)
- [ ] No secrets or credentials in the diff
- [ ] Migration runbook included (if applicable)

## Related
<!-- Links to issues, tasks, specs -->
- Closes #123
- Task: docs/spec/.llm/tasks/backlog/task-005-*.md
- Spec: docs/spec/biz/feature-name-spec.md
```

### Review Requirements

| Change Type | Minimum Reviews | Reviewer Expertise |
|-------------|----------------|-------------------|
| Feature code | 1 | Domain knowledge of affected area |
| Security-sensitive | 2 | At least 1 security-aware reviewer |
| Database migration | 2 | At least 1 with DBA/data experience |
| Infrastructure/CI | 1 | DevOps or platform experience |
| Documentation only | 1 | Any team member |
| Dependency upgrade | 1 | Familiarity with the dependency |

## Merge Strategy

| Scenario | Strategy | Rationale |
|----------|----------|-----------|
| Feature branch -> main | **Squash merge** | Clean history, one commit per feature |
| Release branch -> main | **Merge commit** | Preserve individual commits for auditability |
| Hotfix -> main | **Squash merge** | Single, traceable fix |
| Agent branch -> feature branch | **Squash merge** | Agent work = one logical change |
| Rebase (local only) | **Rebase** | Keep local branch up to date before PR |

### Why Squash for Features

- Each feature is one commit in main history
- Intermediate "WIP", "fix typo", "address review comments" commits are collapsed
- `git log --oneline` on main tells a clean story
- `git bisect` works effectively (each commit is a complete, working state)

## Protected Branch Rules

### `main` / `master`

| Rule | Setting |
|------|---------|
| Direct push | Disabled |
| Force push | Disabled |
| Require pull request | Yes |
| Require reviews | 1 minimum |
| Require status checks | Build, test, lint must pass |
| Require up-to-date branch | Yes (prevents merging stale branches) |
| Require linear history | Optional (enables with squash merge) |

### Agent Branch Conventions

Agent-created branches follow these rules:

- **Naming**: `agent/<task-slug>` (e.g., `agent/task-005-user-model`)
- **Base**: Branch from `main` (or the feature branch specified in the task)
- **Scope**: One task per branch. Never mix tasks.
- **Commits**: Agents commit but do NOT push. The team lead or human pushes.
- **Cleanup**: Delete agent branches after merge

## Git Hygiene

### Do

- Commit early and often (locally)
- Write meaningful commit messages
- Keep branches short-lived (< 1 week for features)
- Pull/rebase before pushing to avoid merge conflicts
- Use `.gitignore` to keep the repo clean

### Do Not

- Commit secrets, credentials, or `.env` files
- Force push to shared branches
- Commit large binary files (use Git LFS)
- Leave long-running branches unmerged
- Commit generated code that can be reproduced from source
- Use `git add .` without checking `git status` first

## Useful Git Commands

```bash
# See what would be committed
git diff --staged

# Interactive staging (pick specific hunks)
git add -p

# Amend last commit (before pushing)
git commit --amend

# Rebase current branch on main
git rebase main

# Find which commit introduced a bug
git bisect start
git bisect bad HEAD
git bisect good v1.0.0

# See commits on this branch not on main
git log main..HEAD --oneline

# Clean up merged branches
git branch --merged main | grep -v main | xargs git branch -d
```
