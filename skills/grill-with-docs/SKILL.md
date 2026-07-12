---
name: grill-with-docs
description: Grilling session that grills a plan against the project's documented domain model — challenging terminology against CONTEXT.md and capturing decisions as ADRs and glossary updates inline as they crystallise. Use when the user wants to stress-test a plan against their project's documented language and decisions, not just in the abstract. (For a plain grilling with no project docs, use grill-me.)
---

<what-to-do>

Run the shared interview loop in [../grill-me/interview-loop.md](../grill-me/interview-loop.md) — the relentless, one-question-at-a-time grilling that `grill-me` also uses (this skill requires `grill-me` to be installed alongside it). Everything below adds a domain-model layer on top of that loop.

</what-to-do>

<supporting-info>

## Domain awareness

During codebase exploration, look for existing documentation. How `CONTEXT.md` / `CONTEXT-MAP.md` are laid out (single vs multi-context repos), how to infer which context the current topic belongs to, and when to create these files lazily all live in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md) — read it before writing any context file.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up — capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` is a glossary and nothing else — terms and their relationships, kept free of implementation detail.

### Offer ADRs sparingly

Offer an ADR only when it meets all three criteria in [ADR-FORMAT.md](./ADR-FORMAT.md) — meaningful reversal cost, a future reader would question the approach, and a real trade-off was made. If any is missing, skip it. Use that file's format when you do write one.

</supporting-info>
