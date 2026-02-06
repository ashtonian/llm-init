# LLM Navigation Guide Standard

> **LLM Quick Reference**: This document defines how to format LLM navigation sections in spec files. Use when creating new specs or updating existing ones to follow the standard.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Creating a new specification document
- Adding LLM navigation to an existing document
- Understanding the standard format for LLM-friendly docs
- Reviewing document structure for LLM optimization

### Key Sections

| Section | Purpose |
|---------|---------|
| **Placement** | Where to put the LLM nav section (TOP of file) |
| **Standard Format** | Template for the navigation section |
| **Section Descriptions** | How to write each subsection |
| **Examples** | Minimal and comprehensive examples |
| **Checklist** | Verification before completing |

### Context Loading

1. For **creating new specs**: This doc is sufficient
2. For **overall LLM strategy**: Load `./LLM.md`
3. For **plan files**: See `./.llm/templates/`

---

## Purpose

LLM Navigation Guides help AI assistants:
1. **Decide when to load** a document based on the task at hand
2. **Navigate quickly** to relevant sections without reading the entire document
3. **Understand context dependencies** between documents
4. **Make quick reference lookups** for common patterns

---

## Placement

> **IMPORTANT**: LLM Navigation sections go at the TOP of the document, immediately after the title and any one-line summary.

### Rationale

Placing navigation at the TOP allows LLMs to:
- Quickly determine if the document is relevant (without reading everything)
- Find key sections immediately
- Load context dependencies before diving into details

### Document Structure

```markdown
# Document Title

> **LLM Quick Reference**: One-line summary of what this document covers.

## LLM Navigation Guide

### When to Use This Document
...

### Key Sections
...

### Quick Reference: [Topic]
...

### Context Loading
...

---

## {Main Content Sections}
...

## Related Documentation
...
```

---

## Standard Format

### Template

```markdown
# {Document Title}

> **LLM Quick Reference**: {One-line summary for quick scanning}

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- [Bullet list of scenarios when this doc is relevant]
- [Be specific about tasks, not vague]
- [Include both implementation and troubleshooting scenarios]

### Key Sections

| Section | Purpose |
|---------|---------|
| **Section Name** | Brief description of what this section covers |
| **Another Section** | What you'll find there |

### Quick Reference: [Topic]

[Include 1-3 quick reference tables or code snippets for the most common lookups]

| Scenario | Answer | Notes |
|----------|--------|-------|
| Common question 1 | Direct answer | Additional context |
| Common question 2 | Direct answer | Additional context |

### Context Loading

1. For **specific subtopic**: This doc is sufficient
2. For **related topic**: Load `./path/to/related.md`
3. For **another topic**: Load `./path/to/another.md`

---

## {First Main Section}
...
```

---

## Section Descriptions

### When to Use This Document

This section helps the LLM decide whether to load the document. Guidelines:

- **Be specific**: "Implementing error handling in a new service" not "Working with errors"
- **Include action verbs**: "Adding", "Implementing", "Configuring", "Debugging", "Choosing between"
- **Cover both creation and troubleshooting**: Include scenarios for both building new features and fixing issues
- **5-8 bullet points** is typical; don't be exhaustive

**Good examples:**
```markdown
Load this document when:
- Implementing error handling in a new service or package
- Adding new error codes for a feature
- Deciding between error codes for a specific failure case
- Understanding retry behavior for different error types
```

**Bad examples:**
```markdown
Load this document when:
- Working with errors (too vague)
- You need to know about error handling (too vague)
- Errors (not a scenario)
```

### Key Sections

A table mapping section names to their purpose. Guidelines:

- **Use exact section names** from the document (matching ## headings)
- **One sentence descriptions**: What problem does this section solve?
- **6-12 rows** is typical; include all major sections
- **Bold the section names** for scanability

**Example:**
```markdown
| Section | Purpose |
|---------|---------|
| **Error Codes** | Complete list of E-codes by category |
| **Error Classification** | Transient vs permanent, retry decisions |
| **HTTP Status Mapping** | Which HTTP status for each error code |
```

### Quick Reference Tables

Include 1-3 tables or code snippets for the most common lookups. Guidelines:

- **Pick the most frequently needed information**: What would someone look up 80% of the time?
- **Keep tables small**: 5-15 rows maximum
- **Include code snippets** when the answer is "how do I do X?"
- **Use descriptive titles**: "Quick Reference: Error Code Selection" not just "Quick Reference"

**Types of quick references:**

1. **Decision tables**: "Given X, choose Y"
```markdown
### Quick Reference: Backend Selection

| Deployment | Backend | Use Case |
|------------|---------|----------|
| Development | SQLite | Local dev, testing |
| Small | PostgreSQL | Small-medium production |
| Large | ScyllaDB | Enterprise, multi-DC |
```

2. **Code patterns**: "How do I do X?"
```markdown
### Quick Reference: Common Patterns

```go
// Create a new error
return ErrNotFound("entity", entityID)

// Check if retryable
if errutil.IsRetryable(err) {
    return retry.WithBackoff(ctx, fn)
}
```
```

3. **Mapping tables**: "X maps to Y"
```markdown
### Quick Reference: Error to HTTP Status

| Error Code | HTTP Status | Meaning |
|------------|-------------|---------|
| E1001 | 401 | Unauthorized |
| E2001 | 400 | Validation failed |
| E3001 | 404 | Not found |
```

### Context Loading

This section tells the LLM which other documents to load for related tasks. Guidelines:

- **Number the items**: Makes it easy to reference
- **Use bold for the subtopic**: Easy scanning
- **Include relative paths**: From the current document's location
- **5-8 items** is typical
- **Start with "This doc is sufficient"** when appropriate

**Example:**
```markdown
### Context Loading

1. For **API error responses**: This doc is sufficient
2. For **parse errors**: Load `../pkg-specs/parse.md` for schema validation patterns
3. For **database errors**: Load `./data-access.md` for repository error mapping
4. For **observability**: Load `./observability.md` for logging/tracing integration
```

---

## Domain-Specific Extensions

Some documents benefit from additional quick reference sections specific to their domain.

### Package Specifications

Package specs (in `pkg-specs/`) should include:

```markdown
### Interface Summary

| Method | Purpose |
|--------|---------|
| `Get(ctx, key)` | Retrieve by key |
| `Put(ctx, key, data)` | Store data |
```

### Platform Specifications

Platform specs (in `platform-specs/`) should include:

```markdown
### Component Interactions

[ASCII diagram or description of how this component interacts with others]

### Configuration Quick Reference

| Setting | Default | Purpose |
|---------|---------|---------|
| `max_retries` | 3 | Maximum retry attempts |
```

### Error Handling Documents

Error handling docs should include:

```markdown
### Error Code Selection

| Scenario | Error Code | HTTP Status |
|----------|------------|-------------|
| Missing auth | E1001 | 401 |

### Retry Decisions

```go
switch ClassifyError(err) {
case ErrorClassTransient:
    return retry.WithBackoff(ctx, fn)
case ErrorClassPermanent:
    return err
}
```
```

---

## Examples

### Minimal Example (for simple docs)

```markdown
# Logging Configuration

> **LLM Quick Reference**: How to configure structured logging in services.

## LLM Navigation Guide

### When to Use This Document

Load this document when:
- Configuring application logging
- Adding structured log fields
- Understanding log levels

### Key Sections

| Section | Purpose |
|---------|---------|
| **Configuration** | Logger setup and options |
| **Structured Fields** | Standard field names |
| **Levels** | When to use each level |

### Context Loading

1. For **logging only**: This doc is sufficient
2. For **full observability**: Load `./observability.md`

---

## Configuration
...
```

---

## Checklist

When adding an LLM Navigation Guide to a document:

- [ ] Section is placed at TOP, immediately after title
- [ ] One-line summary in blockquote after title
- [ ] "When to Use" has 5-8 specific, actionable scenarios
- [ ] "Key Sections" table matches actual ## headings
- [ ] At least one Quick Reference table/snippet included
- [ ] "Context Loading" lists related documents with paths
- [ ] All paths are relative from the current document
- [ ] Quick references cover 80% of common lookups
- [ ] Section names in table are bolded
- [ ] Horizontal rule (---) separates nav from main content

---

## Anti-Patterns

**Don't:**
- Place the LLM Navigation section at the end of the document
- Include the entire document structure in Key Sections (pick the important ones)
- Use vague scenarios like "working with X" or "using X"
- Include more than 3 quick reference sections (keep it focused)
- Duplicate content from the main document (reference sections instead)
- Use absolute paths (use relative paths from current doc)
- Skip the Context Loading section (cross-references are valuable)

**Do:**
- Place LLM Navigation immediately after the title
- Focus on decision-making scenarios
- Include both "how to implement" and "how to troubleshoot" scenarios
- Keep quick references actionable (not just informational)
- Update the guide when adding new sections to the document
- Test that referenced documents exist at the specified paths

---

## Related Documentation

- [LLM Orchestration Guide](./LLM.md) - Master entry point for LLMs
- [Plan Templates](./.llm/templates/) - Templates for plan.llm files
