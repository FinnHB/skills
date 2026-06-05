# grill-with-docs

A grilling session like [grill-me](../grill-me/), but anchored to the project's documented domain model. Challenges your plan against existing terminology and decisions, sharpens language, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill instructions |
| `CONTEXT-FORMAT.md` | Expected structure of the project's CONTEXT.md |
| `ADR-FORMAT.md` | Template for Architecture Decision Records |

## Usage examples

```
/grill-with-docs I want to split the ingestion pipeline into fetch and transform stages
```

```
/grill-with-docs
[describe the plan; Claude will check it against CONTEXT.md and existing ADRs]
```

## When to use

- Stress-testing a plan in a project that maintains CONTEXT.md / ADRs
- When new work might redefine or collide with established terminology
- When decisions made during the discussion should be captured as documentation, not lost in chat
