# SaaS Framework Specifications

> **LLM Quick Reference**: Generic SaaS patterns (auth, API, models, SDK, performance, UI) - foundation specs. Read these first before business specs.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Starting any development task (entry point for framework specs)
- Understanding the framework specification categories
- Finding which framework spec to load for a task

### Key Sections

| Section | Purpose |
|---------|---------|
| **Philosophy** | Framework vs business spec separation |
| **Documentation Categories** | Index of all framework specs by category |
| **Quick Reference: By Task** | Task-to-spec mapping |

### Quick Reference: Framework Specs by Category

| Category | Included | To Be Created |
|----------|----------|---------------|
| **Code Generation** | **go-generation-guide.md** (Go), **typescript-ui-guide.md** (TypeScript/UI) | — |
| **Performance** | **performance-guide.md** (allocation, profiling, quality) | — |
| **Testing** | **testing-guide.md** (unit, integration, fixtures, mocking) | — |
| **Security** | — | authentication.md, permission-policy-system.md, tenant-model.md |
| **API** | — | api-design.md, routes.md, validation.md, error-handling.md |
| **Data** | — | data-access.md, models.md |
| **Observability** | — | observability.md, audit-logging.md |

> Use `../SPEC-WRITING-GUIDE.md` for templates and depth expectations when creating new specs.

### Context Loading

1. For **framework overview**: This doc is sufficient
2. For **writing Go code**: Load `./go-generation-guide.md` (always load first)
3. For **writing frontend/UI code**: Load `./typescript-ui-guide.md` (always load first)
4. For **performance-sensitive work**: Load `./performance-guide.md`
5. For **creating new specs**: Load `../SPEC-WRITING-GUIDE.md`
6. For **business features**: Load `../biz/README.md`
7. For **LLM orchestration**: Load `../LLM.md`

---

Cross-cutting patterns and specifications for building multi-tenant SaaS applications. These guidelines are platform-agnostic and designed to be applied across different domains.

This directory is part of a multi-folder documentation structure:

- **Framework Specs** (this directory) - Generic patterns and cross-cutting concerns applicable to any SaaS application
- **[Business Specs](../biz/README.md)** - Feature requirements, market research, business decisions

---

## Philosophy

This framework separates **generic SaaS patterns** from **business-specific implementations**:

| Layer | Purpose | Examples |
|-------|---------|----------|
| **Framework Specs** | Platform-agnostic patterns | Authentication, API design, multi-tenancy, performance |
| **Business Specs** | Feature requirements | PRDs, market research, competitive analysis |

When building a new SaaS product, use Framework specs as your foundation, then create business specs for your specific domain.

---

## Goals

This folder provides standardized patterns for:
- Authentication and authorization across all services
- API design conventions and REST standards
- Multi-tenant architecture and data isolation
- Error handling, logging, and observability
- Testing strategies and validation patterns
- SDK generation for multiple languages
- High-performance code with deliberate memory management
- Accessible, performant, user-friendly frontends

---

## Documentation Categories

### Code Generation (Included)

| Specification | Description |
|---------------|-------------|
| [Go Generation Guide](./go-generation-guide.md) | **Mandatory Go code patterns**: functional options, generics, registry pattern, functional over OOP, modern idioms, cross-cutting concern references |
| [TypeScript & UI Guide](./typescript-ui-guide.md) | **Mandatory frontend patterns**: component architecture, state management, accessibility, responsive design, performance optimization |

### Performance & Quality (Included)

| Specification | Description |
|---------------|-------------|
| [Performance Guide](./performance-guide.md) | **Mandatory performance standards**: memory allocation strategies, profiling discipline, latency budgets, code quality requirements |

### Testing (Included)

| Specification | Description |
|---------------|-------------|
| [Testing Guide](./testing-guide.md) | Unit tests, integration tests, fixtures, mocking strategies, coverage expectations |

### Suggested Specs to Create

Use `../SPEC-WRITING-GUIDE.md` for templates. As you create specs, update this section and the tables above.

#### Security & Identity

| Specification | Description |
|---------------|-------------|
| ~~authentication.md~~ | Session management, JWT tokens, API keys |
| ~~permission-policy-system.md~~ | Authorization layers (route, service, repository) |
| ~~tenant-model.md~~ | Tenants, users, roles, groups |

#### API & Data

| Specification | Description |
|---------------|-------------|
| ~~api-design.md~~ | REST conventions, pagination, filtering |
| ~~data-access.md~~ | Repository patterns, CRUD operations |
| ~~models.md~~ | Core domain model patterns and field conventions |
| ~~routes.md~~ | Route structure and middleware patterns |
| ~~validation.md~~ | Input validation, schema enforcement |
| ~~error-handling.md~~ | Error codes, classification, retry behavior, HTTP status mapping |

#### Observability & Reliability

| Specification | Description |
|---------------|-------------|
| ~~observability.md~~ | Structured logging, tracing, metrics |
| ~~audit-logging.md~~ | Audit trail patterns, event storage |

> **Strikethrough** indicates specs that don't exist yet — create them as needed for your project.

---

## Quick Reference: By Task

| Task | Primary Spec | Status |
|------|--------------|--------|
| Write any Go code | [go-generation-guide.md](./go-generation-guide.md) | **Included** |
| Write any frontend/UI code | [typescript-ui-guide.md](./typescript-ui-guide.md) | **Included** |
| Performance-sensitive work | [performance-guide.md](./performance-guide.md) | **Included** |
| Write tests | [testing-guide.md](./testing-guide.md) | **Included** |
| Create a new spec | [SPEC-WRITING-GUIDE.md](../SPEC-WRITING-GUIDE.md) | **Included** |
| Write a business feature spec | [biz/README.md](../biz/README.md) | **Included** |

<!-- Add rows as you create specs. Suggested entries:
| Create API endpoint | api-design.md | To be created |
| Add database operation | data-access.md | To be created |
| Handle errors | error-handling.md | To be created |
| Add logging/metrics | observability.md | To be created |
-->

---

## Related Documentation

- [Spec Writing Guide](../SPEC-WRITING-GUIDE.md) - Templates and depth expectations for creating specs
- [Business Specs](../biz/README.md) - Feature requirements, market research, decisions
- [LLM Orchestration Guide](../LLM.md) - Master entry point for LLMs
