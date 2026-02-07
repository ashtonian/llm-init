---
name: dependency-audit
description: Audit dependencies for vulnerabilities and plan upgrades
allowed-tools: Read, Write, Bash, Glob, Grep
---

# Dependency Audit Skill

Structured workflow for scanning dependencies, checking for CVEs, assessing upgrade difficulty, generating upgrade task files with compatibility testing plans, and tracking deprecation timelines.

## Workflow

### Step 1: Inventory Dependencies

Scan the project for all dependency manifests:

| File | Ecosystem | Scan Command |
|------|-----------|-------------|
| `go.mod` / `go.sum` | Go | `go list -m all` |
| `package.json` / `package-lock.json` | Node.js | `npm ls --all` |
| `yarn.lock` | Node.js (Yarn) | `yarn list` |
| `pnpm-lock.yaml` | Node.js (pnpm) | `pnpm ls --depth Infinity` |
| `requirements.txt` / `pyproject.toml` | Python | `pip list` |
| `Cargo.toml` / `Cargo.lock` | Rust | `cargo tree` |
| `Dockerfile` | Container base images | Parse FROM lines |
| `docker-compose.yml` | Service images | Parse image fields |
| `.github/workflows/*.yml` | GitHub Actions | Parse uses fields |

For each dependency, record:
- **Name**: Package/module name
- **Current version**: What's installed
- **Latest version**: What's available
- **Version gap**: How many major/minor/patch versions behind
- **Direct vs transitive**: Is it a direct dependency or pulled in transitively?
- **License**: License type (MIT, Apache-2.0, GPL, etc.)

Output: Dependency inventory table sorted by version gap (largest first).

### Step 2: Vulnerability Scan

Run vulnerability scanners for each ecosystem:

**Go:**
```bash
# Built-in vulnerability database
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# Module verification
go mod verify
```

**Node.js:**
```bash
# npm audit with JSON output for parsing
npm audit --json

# Or with yarn
yarn audit --json

# Or with Snyk (if available)
snyk test --json
```

**Container Images:**
```bash
# Trivy for container scanning (if available)
trivy image {image-name}

# Or grype
grype {image-name}
```

**GitHub Actions:**
```bash
# Check for pinned versions vs floating tags
# Grep for uses: without @sha
```

For each vulnerability found, record:

| Field | Description |
|-------|------------|
| **CVE ID** | CVE-YYYY-NNNNN |
| **Severity** | Critical / High / Medium / Low |
| **Affected package** | Package name and vulnerable version range |
| **Fixed version** | Minimum version that fixes the vulnerability |
| **CVSS Score** | Numeric severity score |
| **Exploitability** | Is there a known exploit? Is it remotely exploitable? |
| **Impact** | What can an attacker do? (RCE, data leak, DoS) |
| **Affected code paths** | Does our code actually call the vulnerable function? |

Output: Vulnerability report sorted by severity, with affected code path analysis.

### Step 3: Assess Upgrade Difficulty

For each dependency that needs upgrading, assess the effort:

| Factor | Low Effort | Medium Effort | High Effort |
|--------|-----------|---------------|-------------|
| **Version jump** | Patch (1.2.3 -> 1.2.4) | Minor (1.2 -> 1.3) | Major (1.x -> 2.x) |
| **Breaking changes** | None | Deprecations to address | API changes, removed features |
| **Usage scope** | Used in 1-2 files | Used across a package | Used everywhere |
| **Test coverage** | >80% on affected code | 50-80% | <50% |
| **Changelog quality** | Clear migration guide | Release notes only | Minimal docs |

Categorize each upgrade:

```
Upgrade Assessment:
| Package | Current | Target | Difficulty | Breaking Changes | Effort |
|---------|---------|--------|-----------|-----------------|--------|
| chi     | v5.0.0  | v5.1.0 | Low       | None            | 1 hour |
| gorm    | v1.25   | v2.0   | High      | Major API change | 2 days |
```

### Step 4: Prioritize Upgrades

Assign priority based on risk and effort:

| Priority | Criteria | Action |
|----------|----------|--------|
| **P0 - Immediate** | Critical/High CVE with known exploit, or CVE in code path we use | Upgrade now, create hotfix task |
| **P1 - This Sprint** | High CVE without known exploit, or medium CVE in critical path | Create task for current sprint |
| **P2 - Next Sprint** | Medium CVE, or major version behind with useful features | Schedule for next sprint |
| **P3 - Backlog** | Low CVE, or minor version behind with no security impact | Add to backlog, batch with other upgrades |
| **P4 - Monitor** | No CVE, but approaching end-of-life or deprecation | Track timeline, plan before EOL |

### Step 5: Generate Upgrade Task Files

For each P0-P2 upgrade, create a task file in `docs/spec/.llm/tasks/backlog/`:

```markdown
# Task: Upgrade {package} from {current} to {target}

## Priority: {P0/P1/P2}
## Reason: {CVE-YYYY-NNNNN / End-of-life / Feature needed}
## Estimated Effort: {hours/days}

## Context
- Current version: {current}
- Target version: {target}
- Breaking changes: {list or "None"}
- Changelog: {URL}
- Migration guide: {URL or "Not available"}

## Steps
1. Read the changelog and migration guide
2. Update version in {manifest file}
3. Address breaking changes:
   - {specific change 1}
   - {specific change 2}
4. Run build to identify compile errors
5. Fix compile errors
6. Run tests to identify behavioral changes
7. Fix test failures
8. Run linter to catch deprecation warnings
9. Address deprecation warnings
10. Run full quality gates

## Compatibility Testing Plan
- [ ] Build succeeds with no new warnings
- [ ] All existing tests pass
- [ ] No new deprecation warnings
- [ ] Integration tests pass (if applicable)
- [ ] Performance benchmark shows no regression (if applicable)

## Rollback
Revert the version change in {manifest file} and re-run dependency install.
```

Set `## Dependencies:` headers to enforce upgrade ordering (e.g., upgrade shared libraries before dependent packages).

### Step 6: Track Deprecation Timelines

Create a deprecation tracking document:

```markdown
## Deprecation Timeline

| Package | Current | EOL Date | Replacement | Upgrade Deadline | Status |
|---------|---------|----------|-------------|-----------------|--------|
| Node 18 | 18.x   | 2025-04  | Node 22     | 2025-02          | TODO   |
| Go 1.21 | 1.21    | 2025-08  | Go 1.23     | 2025-06          | TODO   |
| React 17| 17.x   | N/A      | React 19    | When convenient   | Watch  |
```

Write to: `docs/spec/.llm/completed/dependency-audit-YYYY-MM-DD.md`

### Step 7: Generate Audit Report

Produce a summary report:

```markdown
## Dependency Audit Report -- {Date}

### Summary
- Total dependencies: {N}
- Direct dependencies: {N}
- Vulnerabilities found: {N critical, N high, N medium, N low}
- Upgrades needed: {N}
- License issues: {N}

### Critical Actions Required
1. {P0 item}
2. {P1 item}

### Upgrade Plan
| Priority | Count | Estimated Total Effort |
|----------|-------|----------------------|
| P0       | {N}   | {hours}              |
| P1       | {N}   | {hours}              |
| P2       | {N}   | {hours}              |
| P3       | {N}   | {hours}              |

### License Compliance
| License | Count | Status |
|---------|-------|--------|
| MIT     | {N}   | OK     |
| Apache-2.0 | {N} | OK   |
| GPL-3.0 | {N}   | REVIEW -- may conflict with proprietary code |

### Next Audit
Schedule next audit for: {Date + 30 days}
```

Present the report to the user and create task files for all P0-P2 items.

## Key Principles

- **Audit regularly**: Monthly for active projects, quarterly for maintenance mode
- **Fix critical vulnerabilities immediately**: P0 items should not wait for a sprint boundary
- **Batch minor upgrades**: Combine P3 upgrades into a single "dependency update" task
- **Pin versions**: Use exact versions in lock files, not floating ranges
- **Verify before upgrading**: Check that the upgrade doesn't introduce new vulnerabilities
- **Test after every upgrade**: Never assume an upgrade is safe without running the test suite

## Arguments

$ARGUMENTS
