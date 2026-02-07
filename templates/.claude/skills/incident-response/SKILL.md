---
name: incident-response
description: Structured incident investigation and resolution
allowed-tools: Read, Edit, Write, Bash, Glob, Grep
---

# Incident Response Skill

Structured workflow for investigating production incidents, identifying root causes, implementing fixes, and writing post-mortems. Speed matters -- follow the steps in order but don't over-analyze before acting.

## Workflow

### Step 1: Assess Impact

Immediately determine the scope and severity of the incident:

| Question | How to Answer |
|----------|--------------|
| Which tenants are affected? | Check error logs filtered by tenant_id, check monitoring dashboards |
| What functionality is broken? | Check health endpoints, test critical paths, review error types |
| When did it start? | Check deploy timestamps, metric anomaly detection, first error log |
| Is it getting worse? | Check error rate trend over last 15 minutes |
| Is there a workaround? | Assess if affected users can use alternative paths |

**Severity Classification:**

| Severity | Criteria | Response |
|----------|----------|----------|
| **SEV-1** | Service down, data loss, security breach, all tenants affected | All hands, continuous updates every 15 min |
| **SEV-2** | Major feature broken, significant tenant subset affected | Dedicated team, updates every 30 min |
| **SEV-3** | Minor feature degraded, few tenants affected | Next business day, update on resolution |
| **SEV-4** | Cosmetic issue, no functionality impact | Backlog, fix in next sprint |

Output: Impact assessment with severity, affected tenants/features, and timeline.

### Step 2: Collect Evidence

Gather all available diagnostic data BEFORE making changes:

**Logs:**
```bash
# Recent error logs (adjust for your logging system)
# Filter by time window, error level, and affected service
```

Look for:
- Error messages and stack traces
- Request IDs for failing requests
- Tenant IDs of affected users
- Timestamps of first and most recent errors

**Metrics:**
- Error rate (overall and per-endpoint)
- Latency percentiles (p50, p95, p99)
- Resource utilization (CPU, memory, connections)
- Deployment markers (did a deploy happen before the incident?)

**Traces:**
- Sample failing request traces
- Compare with successful request traces
- Identify which service/component is failing

**Recent Changes:**
```bash
# Recent deployments
git log --oneline --since="24 hours ago"

# Recent config changes
# Check deployment pipeline logs

# Recent infrastructure changes
# Check Terraform/Kubernetes change logs
```

Output: Evidence document with logs, metrics, traces, and timeline.

### Step 3: Identify Root Cause (5 Whys)

Use the 5 Whys methodology to dig past symptoms to the root cause:

```
Problem: Users getting 500 errors on /api/v1/projects
  Why? -> Project service is returning errors
    Why? -> Database queries are timing out
      Why? -> Connection pool is exhausted
        Why? -> A migration added a long-running query without an index
          Why? -> Migration review process didn't include EXPLAIN ANALYZE
Root Cause: Missing index on new column, migration review gap
```

Rules:
- Don't stop at the first "why" -- symptoms are not root causes
- Check: "If we fix this, would the incident still have happened?" If yes, dig deeper
- Consider contributing factors (multiple things may have aligned to cause the incident)

Common root cause categories:
- **Code bug**: Logic error, race condition, missing error handling
- **Configuration**: Wrong setting, missing environment variable, expired credential
- **Infrastructure**: Resource exhaustion, network issue, dependency failure
- **Data**: Corrupt data, unexpected volume, schema drift
- **Deployment**: Bad deploy, missing migration, incompatible version

Output: Root cause analysis with 5 Whys chain and contributing factors.

### Step 4: Implement Fix (Minimal, Targeted)

Apply the MINIMUM change needed to resolve the incident:

Rules:
- **Smallest possible fix**: Don't refactor during an incident. Fix the immediate problem.
- **Rollback if possible**: If a deploy caused it, rollback first, investigate second.
- **Feature flag**: If possible, disable the broken feature rather than deploying a code fix.
- **Test the fix**: Verify in staging (or locally) before deploying to production.
- **Don't break other things**: Run the test suite. Check that the fix doesn't introduce new issues.

```
Fix Checklist:
[ ] Fix is minimal and targeted (no refactoring, no extra changes)
[ ] Fix addresses the root cause (not just the symptom)
[ ] Test suite passes with the fix
[ ] Fix has been tested in staging
[ ] Rollback plan documented
```

### Step 5: Verify Fix in Staging

Before deploying to production:

1. **Deploy fix to staging**
2. **Reproduce the incident**: Attempt to trigger the same error
3. **Verify resolution**: Confirm the error no longer occurs
4. **Check side effects**: Verify no new errors or regressions
5. **Load test** (if applicable): Verify the fix holds under load

If the fix can't be verified in staging (data-specific issue), document the risk and get approval before deploying to production.

### Step 6: Deploy with Monitoring

Deploy the fix to production with enhanced monitoring:

```
Deployment Checklist:
[ ] Fix deployed to production
[ ] Enhanced monitoring in place (watch error rate, latency)
[ ] Watch for 15 minutes post-deploy
[ ] Error rate returned to baseline
[ ] Latency returned to baseline
[ ] No new error types appearing
[ ] Affected tenants verified working
```

Watch period: Minimum 15 minutes for SEV-1/SEV-2, 5 minutes for SEV-3/SEV-4.

### Step 7: Write Post-Mortem

Create a blameless post-mortem document:

```markdown
## Post-Mortem: [Incident Title]

### Date: YYYY-MM-DD
### Severity: SEV-X
### Duration: X hours Y minutes
### Author: [Name]

### Summary
[1-2 sentence description of what happened]

### Impact
- **Tenants affected**: X (Y% of total)
- **Duration**: HH:MM to HH:MM UTC
- **User-facing impact**: [What users experienced]
- **Data impact**: [Any data loss or corruption]

### Timeline (UTC)
| Time | Event |
|------|-------|
| HH:MM | First error logged |
| HH:MM | Alert fired |
| HH:MM | Investigation started |
| HH:MM | Root cause identified |
| HH:MM | Fix deployed to staging |
| HH:MM | Fix deployed to production |
| HH:MM | Incident resolved |

### Root Cause
[5 Whys analysis]

### Contributing Factors
- [Factor 1]
- [Factor 2]

### What Went Well
- [Positive aspect 1: e.g., "Alerting caught the issue within 2 minutes"]
- [Positive aspect 2]

### What Could Be Improved
- [Improvement 1]
- [Improvement 2]

### Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| Add missing index | @dev | YYYY-MM-DD | TODO |
| Add EXPLAIN ANALYZE to migration review checklist | @team | YYYY-MM-DD | TODO |
| Add monitoring for connection pool exhaustion | @devops | YYYY-MM-DD | TODO |
| Add integration test for this scenario | @tester | YYYY-MM-DD | TODO |

### Lessons Learned
[Key takeaways for the team]
```

Write post-mortem to `docs/spec/.llm/completed/postmortem-YYYY-MM-DD-short-description.md`.

## Key Principles

- **Speed over perfection**: A quick rollback is better than a perfect fix that takes 2 hours.
- **Communicate continuously**: Update stakeholders at regular intervals.
- **Blameless culture**: Post-mortems focus on systems and processes, not individuals.
- **Every incident is a learning opportunity**: Action items from post-mortems prevent recurrence.
- **Don't heroize**: If the same person is always fixing incidents, the system is fragile.
