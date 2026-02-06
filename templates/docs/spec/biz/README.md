# Business Features & Strategy Guide

Guide for writing business-level documentation, feature specifications, market analysis, and strategic planning documents that LLM agents can consume to understand the business context driving technical decisions.

> **LLM Quick Reference**: How to write business specs, feature requirements, market research, and strategic planning documents.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Writing a new business feature specification
- Creating or reviewing a product requirements document (PRD)
- Documenting market research or competitive analysis
- Understanding the business context behind a technical task
- Prioritizing features or making build-vs-buy decisions
- Writing user stories or acceptance criteria

### Key Sections

| Section | Purpose |
|---------|---------|
| **Business Spec Structure** | Standard format for business documentation |
| **Writing Feature Specs** | How to document feature requirements |
| **Writing User Stories** | Acceptance criteria, priority, sizing |
| **Market & Competitive Analysis** | Templates for research documents |
| **Decision Records** | How to document business decisions |
| **Linking Business to Technical** | Connecting biz specs to framework/platform specs |

### Context Loading

1. For **business documentation**: This doc is sufficient
2. For **technical specs from business requirements**: Load `../SPEC-WRITING-GUIDE.md`
3. For **API design from feature specs**: Load `../framework/api-design.md`
4. For **overall orchestration**: Load `../LLM.md`

---

## Business Spec Structure

Every business document follows this structure to ensure LLM agents can extract actionable information.

```markdown
# {Feature/Topic Name}

> **Business Context**: One-line summary of why this matters.

## Problem Statement
{What problem does this solve? Who has it? How bad is it?}

## Target Users
{Specific user personas and their needs}

## Success Metrics
{How do we know this worked? Measurable KPIs.}

## Requirements
### Must Have (P0)
### Should Have (P1)
### Nice to Have (P2)

## User Stories
{Structured user stories with acceptance criteria}

## Technical Implications
{High-level technical considerations, links to technical specs}

## Competitive Context
{How do competitors handle this? What's our differentiation?}

## Open Questions
{Unresolved decisions that need input}
```

---

## Writing Feature Specs

### The "Job to be Done" framework

Start every feature spec by answering:

1. **Who** is the user? (Be specific: "SaaS admin managing 50+ users" not "user")
2. **What** are they trying to accomplish? (The job, not the feature)
3. **Why** can't they do it today? (The gap)
4. **How** will they know it's done? (Observable outcome)

### Feature spec template

```markdown
# Feature: {Name}

## Job to be Done
When {situation}, I want to {motivation}, so I can {expected outcome}.

## Problem Statement
{2-3 sentences. What pain exists today? Quantify if possible.}

## Target Users

| Persona | Role | Pain Level | Frequency |
|---------|------|------------|-----------|
| {Name} | {Role} | High/Med/Low | Daily/Weekly/Monthly |

## Success Metrics

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| {KPI} | {Baseline} | {Goal} | {How measured} |

## Requirements

### P0 - Must Have
- [ ] {Requirement with clear acceptance criteria}
- [ ] {Another requirement}

### P1 - Should Have
- [ ] {Requirement}

### P2 - Nice to Have
- [ ] {Requirement}

## User Stories

### US-001: {Story Title}
**As a** {persona}, **I want** {action}, **so that** {benefit}.

**Acceptance Criteria:**
- Given {context}, when {action}, then {result}
- Given {context}, when {action}, then {result}

**Priority:** P0 | **Estimate:** S/M/L | **Dependencies:** {list}

## User Flow
{Step-by-step flow, ideally with decision points}

1. User navigates to {page}
2. User sees {initial state}
3. User performs {action}
4. System responds with {feedback}
5. User confirms {outcome}

## Edge Cases
| Scenario | Expected Behavior |
|----------|-------------------|
| {Edge case} | {How it should be handled} |

## Technical Implications
- **API changes**: {New endpoints or modifications needed}
- **Data model**: {New entities or field changes}
- **Performance**: {Expected load, latency requirements}
- **Security**: {Authentication, authorization, data privacy considerations}
- **Integration**: {Third-party services or internal systems affected}

## Out of Scope
{Explicitly state what this feature does NOT include}

## Open Questions
- [ ] {Question that needs answering before implementation}
```

---

## Writing User Stories

### Quality checklist

A good user story is:

| Quality | Test |
|---------|------|
| **Independent** | Can be implemented without other stories |
| **Negotiable** | Details can be discussed, it's not a contract |
| **Valuable** | Delivers value to the user (not just technical work) |
| **Estimable** | Team can estimate the effort |
| **Small** | Completable in one iteration/sprint |
| **Testable** | Has clear acceptance criteria |

### Sizing guide

| Size | Description | Scope |
|------|-------------|-------|
| **S** | Single file change, clear implementation | 1-2 hours |
| **M** | 2-5 files, some design decisions | 1-2 days |
| **L** | Multiple components, cross-cutting | 3-5 days |
| **XL** | Should be broken down further | Split into S/M/L stories |

### Priority definitions

| Priority | Definition | Example |
|----------|-----------|---------|
| **P0** | Must have for launch. Blocking. | User authentication |
| **P1** | Important but launch-viable without | Email notifications |
| **P2** | Nice to have, improves experience | Dark mode |
| **P3** | Future consideration | AI-powered suggestions |

---

## Market & Competitive Analysis

### Competitive analysis template

```markdown
# Competitive Analysis: {Feature/Product Area}

## Market Overview
{Brief description of the market segment}

## Competitor Matrix

| Feature | Us | Competitor A | Competitor B | Competitor C |
|---------|----|----|----|----|
| {Feature 1} | {Status} | {Status} | {Status} | {Status} |
| {Feature 2} | {Status} | {Status} | {Status} | {Status} |
| **Pricing** | {Price} | {Price} | {Price} | {Price} |

Status: ✅ Full | ⚠️ Partial | ❌ Missing | 🔜 Planned

## Differentiation
{What makes our approach unique? Why would someone choose us?}

## Gaps to Address
| Gap | Importance | Effort | Priority |
|-----|-----------|--------|----------|
| {Gap} | High/Med/Low | S/M/L/XL | P0-P3 |

## Key Takeaways
{3-5 bullet points summarizing the competitive landscape}
```

### Market research template

```markdown
# Market Research: {Topic}

## Research Questions
1. {What are we trying to learn?}

## Methodology
{How was the research conducted?}

## Findings

### Finding 1: {Title}
- **Evidence**: {Data/source}
- **Implication**: {What this means for us}

## Recommendations
{Prioritized list of actions based on findings}
```

---

## Decision Records

When a business decision is made, document it for future reference.

```markdown
# Decision: {Title}

## Date
{YYYY-MM-DD}

## Status
Proposed | Accepted | Deprecated | Superseded by {link}

## Context
{What situation prompted this decision?}

## Options Considered

### Option A: {Name}
- **Pros**: {list}
- **Cons**: {list}
- **Cost**: {estimate}

### Option B: {Name}
- **Pros**: {list}
- **Cons**: {list}
- **Cost**: {estimate}

## Decision
{Which option was chosen and why}

## Consequences
- {Expected positive outcomes}
- {Expected tradeoffs or risks}
- {Follow-up actions needed}
```

---

## Linking Business to Technical Specs

### Traceability matrix

Every business requirement should trace to technical implementation:

```markdown
## Traceability

| Business Requirement | Technical Spec | Status |
|---------------------|---------------|--------|
| Users can reset password | framework/authentication.md §Password Reset | Implemented |
| Dashboard loads <2s | framework/performance-guide.md §Latency Targets | In progress |
```

### Spec creation workflow

```
Business Feature Spec (biz/)
    │
    └─→ Framework Spec (framework/) — if new patterns needed
```

When a business feature spec is written:
1. Identify which framework patterns apply
2. Create or update framework specs as needed
3. Link in the traceability matrix

---

## Organizing Business Documentation

```
docs/spec/biz/
├── README.md               # This file - guide for business docs
├── features/               # Feature specifications
│   ├── {feature-name}.md
│   └── ...
├── research/               # Market research and analysis
│   ├── competitive-analysis.md
│   └── ...
├── decisions/              # Business decision records
│   ├── {YYYY-MM-DD}-{decision}.md
│   └── ...
└── planning/               # Strategic planning documents
    ├── roadmap.md
    └── ...
```

---

## Related Documentation

- [Spec Writing Guide](../SPEC-WRITING-GUIDE.md) - Technical spec format and standards
- [LLM Orchestration Guide](../LLM.md) - Overall workflow and navigation
- [LLM Style Guide](../LLM-STYLE-GUIDE.md) - Document formatting standards
