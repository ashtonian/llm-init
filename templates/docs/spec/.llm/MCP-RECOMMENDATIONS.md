# MCP Server Recommendations for {{PROJECT_NAME}} Development

This document recommends MCP (Model Context Protocol) servers to install for LLMs working on the {{PROJECT_NAME}} platform.

## What LLMs Will Do With This Repo

Based on the specs, LLMs working on {{PROJECT_NAME}} will:

1. **Navigate & Read Specs** - Markdown files across multiple folders
2. **Write Code** - Backend, frontend, migrations
3. **Create Plan Files** - Coordination and progress tracking
4. **Execute Commands** - Build, test, lint, deploy
5. **Access External Services** - Databases, APIs, cloud services
6. **Work Concurrently** - Multiple LLMs on different features

---

## Recommended MCP Servers

### Tier 1: Essential (Install First)

| MCP Server | Purpose | Why Needed |
|------------|---------|------------|
| **filesystem** | Read/write files | Core file operations for code and docs |
| **memory** | Persistent context | Remember decisions across sessions |

#### filesystem
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    }
  }
}
```

#### memory
```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

---

### Tier 2: Development Workflow

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
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
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
      "args": ["-y", "@bytebase/dbhub", "--transport", "stdio", "--dsn", "postgresql://{{PROJECT_NAME}}:{{PROJECT_NAME}}@localhost:5432/{{PROJECT_NAME}}?sslmode=disable"]
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

### Tier 2.5: Enhanced Development

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

### Tier 3: Platform-Specific

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

Complete `.mcp.json` for {{PROJECT_NAME}} development:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub", "--transport", "stdio", "--dsn", "postgresql://{{PROJECT_NAME}}:{{PROJECT_NAME}}@localhost:5432/{{PROJECT_NAME}}?sslmode=disable"]
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

**Required MCPs**: filesystem, memory, sequential-thinking
**Optional**: github (for PR creation), postgres (for schema work)

**Workflow**:
1. Use sequential-thinking to decompose the feature
2. Use memory to store decisions and context
3. Use filesystem to read specs and write code
4. Use github to create PR

### Debugging Database Issues

**Required MCPs**: filesystem, postgres, memory
**Optional**: redis

**Workflow**:
1. Use filesystem to read relevant specs
2. Use postgres to query data
3. Use memory to track investigation state

---

## Installation Priority

For a new LLM starting work on {{PROJECT_NAME}}:

1. **Day 1**: filesystem, memory
2. **Week 1**: github, sequential-thinking
3. **As needed**: postgres, redis, custom MCPs

---

## Notes

- Environment variables should be set in your shell or .env file
- Test MCP connections before starting complex tasks
- **Memory MCP limitation**: The `@modelcontextprotocol/server-memory` stores data in-process. Data is **lost when the session ends**. For persistent cross-session memory, use `PROGRESS.md` instead. The Memory MCP is useful for within-session context only.
- The `git` MCP server is omitted because Claude Code has built-in git capabilities
- The `github` MCP uses HTTP/OAuth transport (authenticate via `/mcp` in Claude Code)
- **context7** provides up-to-date documentation for libraries — useful when working with frameworks where the agent's training data may be outdated
- **playwright** enables browser-based testing and visual verification of frontend features
