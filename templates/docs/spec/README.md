# {{PROJECT_NAME}} — Documentation Index

> Human-readable index of all specification documents.

## Quick Links

- **[LLM Orchestration Guide](./LLM.md)** — Start here if you're an LLM agent
- **[llms.txt](./llms.txt)** — Quick navigation index for LLMs
- **[Spec Writing Guide](./SPEC-WRITING-GUIDE.md)** — How to write new spec documents
- **[LLM Style Guide](./LLM-STYLE-GUIDE.md)** — Formatting standards for LLM-friendly docs

## Framework Specs (`framework/`)

Foundation patterns that all code must follow.

| Document | Purpose |
|----------|---------|
| [Go Generation Guide](./framework/go-generation-guide.md) | Mandatory Go code patterns, idioms, and conventions |
| [TypeScript & UI Guide](./framework/typescript-ui-guide.md) | Mandatory frontend patterns: components, accessibility, performance |
| [Performance Guide](./framework/performance-guide.md) | Performance standards: memory, profiling, latency, code quality |
| [Testing Guide](./framework/testing-guide.md) | Testing patterns, fixtures, mocking strategies |

## Business Specs (`biz/`)

Feature requirements, market research, and business decisions.

| Document | Purpose |
|----------|---------|
| [Business Features Guide](./biz/README.md) | How to write feature specs, user stories, competitive analysis |

## LLM Coordination (`.llm/`)

Plans, tasks, progress tracking, and agent orchestration.

| Document | Purpose |
|----------|---------|
| [Coordination Guide](./.llm/README.md) | Plan files, task queue, agent coordination |
| [Progress & Learnings](./.llm/PROGRESS.md) | Accumulated knowledge across iterations |
| [Strategy](./.llm/STRATEGY.md) | Project decomposition for parallel agents |
| [Agent Guide](./.llm/AGENT_GUIDE.md) | Context inlined into every agent prompt |
| [Infrastructure](./.llm/INFRASTRUCTURE.md) | Docker services, ports, health checks |
| [MCP Recommendations](./.llm/MCP-RECOMMENDATIONS.md) | Available MCP servers and setup |
