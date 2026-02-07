Perform a security review of the codebase or a specific feature.

## Instructions

1. Read `docs/spec/.llm/AGENT_GUIDE.md` for project context and tech stack.
2. Read `docs/spec/.llm/PROGRESS.md` for known security considerations.
3. Perform a systematic security assessment covering the categories below.

### Input Validation & Injection

- [ ] All user input is validated at system boundaries (handlers, CLI, config)
- [ ] SQL queries use parameterized statements (no string concatenation)
- [ ] Command execution inputs are properly escaped
- [ ] File paths from user input are sanitized (no path traversal)
- [ ] HTML output is escaped to prevent XSS
- [ ] JSON/XML parsing has size limits and depth limits

### Authentication & Authorization

- [ ] Auth checks exist on all protected endpoints
- [ ] Token/session handling follows best practices (expiry, rotation, secure storage)
- [ ] Password handling uses proper hashing (bcrypt/argon2/scrypt, not MD5/SHA)
- [ ] Rate limiting exists on auth endpoints
- [ ] Privilege escalation paths are checked
- [ ] CORS policy is properly configured

### Data Protection

- [ ] Sensitive data is not logged (passwords, tokens, PII)
- [ ] Secrets are not hardcoded in source (check for API keys, passwords, tokens)
- [ ] Environment variables used for secrets, not config files committed to git
- [ ] Data at rest encryption where required
- [ ] Data in transit uses TLS
- [ ] PII handling complies with requirements (GDPR, CCPA, etc.)

### Dependencies

- [ ] No known vulnerable dependencies (run `go vuln check`, `npm audit`, etc.)
- [ ] Dependencies are pinned to specific versions
- [ ] Minimal dependency surface (no unnecessary packages)
- [ ] No dependencies with concerning permissions or behaviors

### Error Handling & Information Disclosure

- [ ] Error messages don't leak internal details to external users
- [ ] Stack traces are not exposed in production responses
- [ ] Debug endpoints are disabled in production
- [ ] Logging doesn't include sensitive request/response bodies

### Infrastructure

- [ ] Docker images use non-root users
- [ ] Container images are minimal (no unnecessary tools)
- [ ] Network policies limit container communication
- [ ] Health check endpoints don't expose sensitive info
- [ ] Resource limits are set (CPU, memory)

### Report Format

Present findings as:

```
## Security Review: {scope}

### Summary
{overall assessment: clean / issues found / critical issues}

### Findings
| # | Finding | Severity | Category | Location |
|---|---------|----------|----------|----------|
| 1 | {finding} | {critical/high/medium/low/info} | {category} | {file:line} |

### Detailed Findings

#### Finding N: {title}
- **Severity**: {critical/high/medium/low/info}
- **Category**: {input-validation/auth/data-protection/deps/disclosure/infra}
- **Location**: `{file:line}`
- **Description**: {what's wrong}
- **Impact**: {what could happen if exploited}
- **Recommendation**: {how to fix}
- **Example fix**: {code snippet if applicable}

### Recommendations (Prioritized)
1. **[Critical]** {fix immediately}
2. **[High]** {fix before next release}
3. **[Medium]** {fix soon}
4. **[Low]** {fix when convenient}
```

$ARGUMENTS
