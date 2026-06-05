# grill-me

Relentless interview about a plan or design. Claude walks down each branch of the decision tree, asking one question at a time (with its recommended answer) until you reach shared understanding. Questions answerable from the codebase are answered by exploring it instead.

## Usage examples

```
/grill-me I want to add a caching layer in front of the geocoding API
```

```
/grill-me
[then paste or describe the plan when asked]
```

```
Here's my migration plan: <plan>. Grill me on it.
```

## When to use

- Before committing to an implementation plan
- When a design feels right but hasn't been stress-tested
- To surface hidden assumptions and unresolved dependencies between decisions

See also: [grill-with-docs](../grill-with-docs/) for the variant that also updates project documentation (CONTEXT.md, ADRs) as decisions crystallise.
