---
name: migrate
description: Plan and execute database schema migrations safely
allowed-tools: Read, Write, Bash, Glob, Grep
---

# Database Migration Skill

Structured workflow for designing schema changes, generating migration files (up/down), validating backward compatibility, planning deployment order, testing rollback, and creating runbooks for failed migrations.

## Workflow

### Step 1: Analyze Current Schema

Before designing any migration:

1. **Read existing migrations**: Scan `**/migrations/**`, `**/migrate/**`, `**/db/**` for existing migration files to understand current schema state
2. **Read data patterns**: Read `.claude/rules/data-patterns.md` for database conventions
3. **Check active connections**: Understand current table relationships, indexes, and constraints
4. **Identify affected tables**: List all tables that will be modified, created, or dropped

Output: Current schema summary for affected tables with columns, types, constraints, indexes, and relationships.

### Step 2: Design Schema Changes

For each change, classify it and determine the migration strategy:

| Change Type | Strategy | Risk Level |
|-------------|----------|-----------|
| **Add column (nullable)** | Single migration, no deploy coordination | Low |
| **Add column (NOT NULL)** | Add nullable -> backfill -> set NOT NULL | Medium |
| **Drop column** | Stop reading -> deploy -> drop column | Medium |
| **Rename column** | Add new -> copy data -> update code -> drop old | High |
| **Add index** | `CREATE INDEX CONCURRENTLY` (PostgreSQL) | Low |
| **Drop index** | Verify no queries depend on it | Low |
| **Add table** | Single migration | Low |
| **Drop table** | Verify no foreign keys, no code references | High |
| **Change column type** | Add new column -> copy -> swap -> drop old | High |
| **Add foreign key** | Verify referential integrity first | Medium |
| **Add constraint** | Verify all existing data satisfies constraint | Medium |

Design rules:
- **Always backward compatible**: The old code must work with the new schema during deployment
- **Never lock tables**: Use `CONCURRENTLY` for index operations, batch updates for backfills
- **Always reversible**: Every UP migration must have a corresponding DOWN migration
- **Idempotent**: Migrations should be safe to run multiple times (use `IF NOT EXISTS`, `IF EXISTS`)

Output: Schema change design document with change type, strategy, and SQL for each change.

### Step 3: Generate Migration Files

Generate numbered migration files following the project's migration tooling:

```
migrations/
  YYYYMMDDHHMMSS_description.up.sql
  YYYYMMDDHHMMSS_description.down.sql
```

**UP Migration Template:**
```sql
-- Migration: {description}
-- Created: {timestamp}
-- Dependencies: {previous migration number, if any}

BEGIN;

-- {Change description}
{SQL statements}

-- Verify
{Verification queries -- SELECT count, check constraints}

COMMIT;
```

**DOWN Migration Template:**
```sql
-- Rollback: {description}
-- Reverses: {up migration number}

BEGIN;

-- {Reverse change description}
{Reverse SQL statements}

-- Verify rollback
{Verification queries}

COMMIT;
```

Rules:
- **Always wrap in transactions** (BEGIN/COMMIT)
- **Include verification queries** to confirm the migration worked
- **Use IF NOT EXISTS / IF EXISTS** for idempotency
- **Comment every statement** explaining what it does and why
- **Separate DDL and DML** for databases that don't support transactional DDL

### Step 4: Validate Backward Compatibility

For each migration, verify:

1. **Old code + new schema**: The currently deployed code can still function with the new schema
2. **New code + old schema**: If the deploy fails and we rollback the migration, can the new code still function? (Not always required, but ideal)
3. **Data integrity**: Existing data won't violate new constraints

```
Compatibility Matrix:
| Migration | Old Code + New Schema | New Code + Old Schema | Reversible |
|-----------|----------------------|----------------------|------------|
| Add users.avatar_url (nullable) | OK | OK (ignores new column) | Yes |
| Drop users.legacy_field | FAIL (code reads it) | OK | Yes |
```

If backward compatibility fails, use the **expand-contract pattern**:
1. **Expand**: Add new column/table alongside old one
2. **Migrate**: Copy data from old to new
3. **Contract**: Update code to use new column/table
4. **Clean up**: Remove old column/table in a future migration

### Step 5: Plan Deployment Order

Document the deployment sequence for each migration:

```markdown
## Deployment Runbook: {Migration Description}

### Pre-Deployment Checks
- [ ] Migration tested in staging environment
- [ ] Rollback tested in staging environment
- [ ] Backup verified (point-in-time recovery available)
- [ ] Estimated migration time: {X minutes}
- [ ] Lock impact: {None / Brief table lock / Extended lock}
- [ ] Maintenance window required: {Yes/No}

### Deployment Steps
1. Take database backup / verify point-in-time recovery
2. Run migration: `{migration command}`
3. Verify migration: `{verification query}`
4. Deploy new application code
5. Verify application health
6. Monitor for 15 minutes

### Rollback Steps (if anything fails)
1. Stop deployment
2. Run rollback: `{rollback command}`
3. Verify rollback: `{verification query}`
4. Redeploy previous application version
5. Verify application health

### Post-Deployment
- [ ] Monitor error rates for 1 hour
- [ ] Verify data integrity
- [ ] Update schema documentation
```

### Step 6: Test Rollback

Before deploying, verify the rollback works:

1. **Apply UP migration** in a test environment
2. **Insert test data** that exercises new schema features
3. **Apply DOWN migration** to verify clean rollback
4. **Verify data integrity** after rollback (no data loss, no orphaned records)
5. **Re-apply UP migration** to verify it's truly idempotent

If rollback testing reveals issues, fix the DOWN migration before proceeding.

### Step 7: Create Failure Runbook

Document what to do if the migration fails at each step:

```markdown
## Failure Runbook: {Migration Description}

### Failure Scenarios

#### Migration fails mid-execution
- **Symptom**: Migration command returns error
- **Action**: Transaction will auto-rollback. Check error message, fix migration, retry.
- **Data impact**: None (transaction rolled back)

#### Migration succeeds but application errors
- **Symptom**: Increased 500 errors after deploy
- **Action**: Rollback application deploy first, then assess if migration rollback is needed
- **Data impact**: Check if new data was written to new columns/tables

#### Migration succeeds but performance degradation
- **Symptom**: Increased latency, high CPU on database
- **Action**: Check for missing indexes, long-running queries. May need to add indexes concurrently.
- **Data impact**: None (schema is correct, performance is the issue)

#### Rollback fails
- **Symptom**: DOWN migration returns error
- **Action**: Restore from backup (point-in-time recovery to pre-migration timestamp)
- **Data impact**: Data written after migration will be lost
- **Escalation**: Page database team
```

### Step 8: Multi-Tenant Migration Considerations

For multi-tenant systems:

- **RLS policies**: If adding tables, add Row Level Security policies in the same migration
- **Tenant isolation**: Verify tenant_id column exists on all new tables
- **Backfill**: When adding NOT NULL columns, backfill per-tenant to avoid long locks
- **Testing**: Run migration with multiple test tenants, verify isolation preserved

## Key Principles

- **Schema changes and code changes are separate deploys**: Never deploy both at once
- **Expand-contract for breaking changes**: Add new -> migrate data -> update code -> remove old
- **Test rollback as rigorously as the migration itself**: A migration without a tested rollback is a one-way door
- **Lock awareness**: Know which operations lock tables and for how long. Use CONCURRENTLY where available.
- **Zero-downtime by default**: If a migration requires downtime, it needs explicit approval and a maintenance window

## Arguments

$ARGUMENTS
