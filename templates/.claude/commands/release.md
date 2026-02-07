Prepare a release with checklist, changelog, and validation.

## Instructions

1. Read `docs/spec/.llm/PROGRESS.md` for recent changes and known issues.
2. Read `docs/spec/.llm/AGENT_GUIDE.md` for quality gates.
3. Determine the version number (ask user if not specified).

### Pre-Release Checklist

- [ ] All quality gates pass (build, test, lint — run from AGENT_GUIDE.md)
- [ ] No known critical bugs
- [ ] All planned features for this release are complete
- [ ] Documentation is up to date (README, API docs, CHANGELOG)
- [ ] Breaking changes are documented with migration instructions
- [ ] Performance benchmarks pass (if applicable)
- [ ] Security review completed (or run `/security-review` now)
- [ ] Dependencies are up to date (no critical CVEs)

### Changelog Generation

Review commits since the last tag (`git log $(git describe --tags --abbrev=0)..HEAD --oneline`) and categorize:

```markdown
## [version] - {date}

### Added
- {new features}

### Changed
- {modifications to existing features}

### Fixed
- {bug fixes}

### Removed
- {removed features}

### Security
- {security fixes}

### Breaking Changes
- {breaking changes with migration instructions}
```

### Release Validation

- [ ] All tests pass on a clean checkout (`git stash && tests && git stash pop`)
- [ ] Application starts successfully
- [ ] Smoke tests pass (key user flows work)
- [ ] No regressions in core functionality
- [ ] Release artifacts build correctly (Docker images, binaries, packages)

### Release Execution

Present the checklist and changelog to the user for approval. Once approved:

1. Create the tag: `git tag -a v{version} -m "{changelog summary}"`
2. If GoReleaser is configured: `goreleaser release` (or push the tag for CI)
3. If npm: `npm publish` (with appropriate flags)
4. Update PROGRESS.md with release note

### Post-Release

- [ ] Verify release artifacts are published
- [ ] Verify container images are available (if applicable)
- [ ] Update any deployment configurations
- [ ] Notify stakeholders

$ARGUMENTS
