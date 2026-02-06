# {{PROJECT_NAME}} Development Infrastructure

This document describes the local infrastructure services required by MCP servers and the {{PROJECT_NAME}} platform, and how agents should manage them.

## Services

| Service    | Container Name            | Port(s)      | Purpose                          |
|------------|---------------------------|--------------|----------------------------------|
| PostgreSQL | {{PROJECT_NAME}}-postgres | 5432         | Primary database                 |
| Redis      | {{PROJECT_NAME}}-redis    | 6379         | L2 cache layer                   |
| NATS       | {{PROJECT_NAME}}-nats     | 4222, 8222   | Message bus (JetStream enabled)  |

### Credentials

| Service    | Connection String                                                      |
|------------|------------------------------------------------------------------------|
| PostgreSQL | `postgresql://{{PROJECT_NAME}}:{{PROJECT_NAME}}@localhost:5432/{{PROJECT_NAME}}` |
| Redis      | `redis://localhost:6379`                                               |
| NATS       | `nats://localhost:4222`                                                |

## Agent Startup Checklist

Before using MCP servers that depend on infrastructure (postgres, redis), agents should verify services are running. Run these commands from the repo root:

### 1. Start services (if not already running)

```bash
docker compose -f docs/spec/.llm/docker-compose.yml up -d
```

### 2. Verify all services are healthy

```bash
docker compose -f docs/spec/.llm/docker-compose.yml ps
```

All services should show `healthy` status. If a service shows `starting`, wait a few seconds and check again.

### 3. Quick connectivity checks

```bash
# PostgreSQL
docker exec {{PROJECT_NAME}}-postgres pg_isready -U {{PROJECT_NAME}} -d {{PROJECT_NAME}}

# Redis
docker exec {{PROJECT_NAME}}-redis redis-cli ping

# NATS
curl -s http://localhost:8222/healthz
```

### 4. If services are unhealthy or missing

```bash
# Restart all services
docker compose -f docs/spec/.llm/docker-compose.yml restart

# Or recreate from scratch
docker compose -f docs/spec/.llm/docker-compose.yml down
docker compose -f docs/spec/.llm/docker-compose.yml up -d
```

## MCP Server Dependencies

| MCP Server           | Requires Infrastructure | Package / Transport              | Notes                           |
|----------------------|------------------------|----------------------------------|---------------------------------|
| github               | No                     | `@modelcontextprotocol/server-github` (stdio)      | Requires `GITHUB_PERSONAL_ACCESS_TOKEN` env var |
| postgres             | PostgreSQL             | `@bytebase/dbhub` (stdio)                         | Queries via DSN connection string |
| redis                | Redis                  | `@modelcontextprotocol/server-redis` (stdio)       | Key-value operations            |
| sequential-thinking  | No                     | `@modelcontextprotocol/server-sequential-thinking` (stdio) | In-process reasoning            |
| context7             | No                     | `@upstash/context7-mcp` (stdio)                   | Up-to-date library documentation |
| playwright           | No                     | `@playwright/mcp` (stdio)                          | Browser automation & E2E testing |

**Note**: The `git`, `filesystem`, and `memory` MCP servers are omitted because Claude Code has built-in equivalents. The `github` MCP server uses a Personal Access Token for authentication.

## Data Persistence

All service data is persisted to local directories under `docs/spec/.llm/data/`:

```
docs/spec/.llm/data/
├── postgres/    # PostgreSQL data files
├── redis/       # Redis AOF and RDB snapshots
└── nats/        # NATS JetStream file store
```

This directory is excluded from git via `.gitignore`.

Data survives container restarts and recreation (`docker compose down` / `up`). Only an explicit volume removal destroys data.

## Cleanup

### Stop services (preserves data)

```bash
docker compose -f docs/spec/.llm/docker-compose.yml down
```

### Full reset (destroys all data)

```bash
docker compose -f docs/spec/.llm/docker-compose.yml down
rm -rf docs/spec/.llm/data
```

### Remove downloaded images

```bash
docker compose -f docs/spec/.llm/docker-compose.yml down --rmi all
rm -rf docs/spec/.llm/data
```

## Resource Limits

Services are configured with resource limits suitable for local development:

| Service    | CPU Limit | Memory Limit | Memory Reservation |
|------------|-----------|--------------|-------------------|
| PostgreSQL | 2.0 cores | 1 GB         | 512 MB            |
| Redis      | 1.0 core  | 512 MB       | 256 MB            |
| NATS       | 1.0 core  | 512 MB       | 256 MB            |

**Total maximum**: 4 CPU cores, 2 GB RAM.

### PostgreSQL tuning

Tuned for a local development workload:
- `shared_buffers`: 256 MB (buffer cache)
- `work_mem`: 16 MB (per-operation sort/hash memory)
- `maintenance_work_mem`: 128 MB (vacuum, index creation)
- `effective_cache_size`: 512 MB (planner hint for OS cache)
- `random_page_cost`: 1.1 (optimized for SSD/NVMe)

### Redis tuning

- Max memory: 256 MB with LRU eviction
- AOF persistence enabled
- RDB snapshots: every 60s if 1000+ changes, every 300s if 10+ changes

### NATS tuning

- JetStream enabled with file-based storage
- Max memory store: 128 MB
- Max file store: 1 GB
- HTTP monitoring on port 8222

## GitHub Authentication

The GitHub MCP server uses a Personal Access Token (PAT) for authentication:

1. Create a PAT at [github.com/settings/tokens](https://github.com/settings/tokens) with appropriate scopes (repo, read:org, etc.)
2. Set the environment variable before starting Claude Code:
   ```bash
   export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
   ```
3. Optionally add it to your shell profile (`~/.bashrc`, `~/.zshrc`) or a `.env` file

The token is referenced in `.mcp.json` as `${GITHUB_PERSONAL_ACCESS_TOKEN}` and expanded at runtime.
