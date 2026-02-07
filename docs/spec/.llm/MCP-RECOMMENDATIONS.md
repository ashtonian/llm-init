# MCP Server Recommendations for test-project Development

This document recommends MCP (Model Context Protocol) servers to install for LLMs working on the test-project platform.

## What LLMs Will Do With This Repo

Based on the specs, LLMs working on test-project will:

1. **Navigate & Read Specs** - Markdown files across multiple folders
2. **Write Code** - Backend, frontend, migrations
3. **Create Plan Files** - Coordination and progress tracking
4. **Execute Commands** - Build, test, lint, deploy
5. **Access External Services** - Databases, APIs, cloud services
6. **Work Concurrently** - Multiple LLMs on different features

---

## Recommended MCP Servers

### Tier 1: Development Workflow

| MCP Server | Purpose | Why Needed |
|------------|---------|------------|
| **github** | Issues, PRs, reviews | Track work, code review |
| **postgres** | Database queries | Query schemas, test data |
| **sequential-thinking** | Complex planning | Multi-step task decomposition |

#### github
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

#### postgres
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub", "--transport", "stdio", "--dsn", "postgresql://test-project:test-project@localhost:5432/test-project?sslmode=disable"]
    }
  }
}
```

#### sequential-thinking
```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

---

### Tier 1.5: Enhanced Development

| MCP Server | Purpose | Why Needed |
|------------|---------|------------|
| **context7** | Up-to-date library docs | Gets current documentation for any library/framework, avoids outdated patterns |
| **playwright** | Browser automation & testing | E2E testing, visual verification, web scraping for research |

#### context7
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

#### playwright
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

---

### Tier 2: Platform-Specific

Based on your technology stack, consider adding:

| MCP Server | Purpose | Use Case |
|------------|---------|----------|
| **redis** | Cache queries | L2 caching layer |
| **nats** | Message bus | Event streaming |
| **aws** | Cloud resources | S3, Secrets Manager |
| **sentry** | Error tracking | Monitor production errors |
| **linear** | Project management | Track issues and sprints |

---

## Configuration Template

Complete `.mcp.json` for test-project development:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub", "--transport", "stdio", "--dsn", "postgresql://test-project:test-project@localhost:5432/test-project?sslmode=disable"]
    },
    "redis": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-redis", "redis://localhost:6379"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

---

## Use Cases by Task

### Building a New Feature

**Required MCPs**: sequential-thinking
**Optional**: github (for PR creation), postgres (for schema work)

**Workflow**:
1. Use sequential-thinking to decompose the feature
2. Use Claude Code's built-in Read/Write/Edit tools for specs and code
3. Use github to create PR

### Debugging Database Issues

**Required MCPs**: postgres
**Optional**: redis

**Workflow**:
1. Use Claude Code's built-in Read tool for relevant specs
2. Use postgres to query data
3. Use Claude Code's auto-memory or PROGRESS.md to track investigation state

---

## Installation Priority

For a new LLM starting work on test-project:

1. **Day 1**: github, sequential-thinking, context7
2. **Week 1**: postgres, redis (when infrastructure is set up)
3. **As needed**: playwright, custom MCPs

---

## Notes

- Environment variables should be set in your shell or .env file
- Test MCP connections before starting complex tasks
- The `git` MCP server is omitted because Claude Code has built-in git capabilities
- The `filesystem` and `memory` MCP servers are omitted because Claude Code has built-in equivalents (Read/Write/Edit/Glob/Grep for files, auto-memory for persistence)
- The `github` MCP uses a Personal Access Token (set `GITHUB_PERSONAL_ACCESS_TOKEN` env var)
- **context7** provides up-to-date documentation for libraries — useful when working with frameworks where the agent's training data may be outdated
- **playwright** enables browser-based testing and visual verification of frontend features
