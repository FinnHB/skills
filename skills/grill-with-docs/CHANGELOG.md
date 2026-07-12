# Changelog — grill-with-docs

## 2026-07-12
Rubric pass against `writing-great-skills`, part of a repo-wide review.
- **Shared interview loop de-duplicated.** The loop copied verbatim from grill-me now lives once in `../grill-me/interview-loop.md`, which this skill points at (requires grill-me installed alongside it — noted inline and here).
- **Two internal duplications removed.** The `CONTEXT.md`/`CONTEXT-MAP.md` layout + lazy-creation block (already in `CONTEXT-FORMAT.md`) and the three ADR criteria (already in `ADR-FORMAT.md`) are now one-line pointers to those files instead of second copies.
- **Description trimmed** to the docs/domain-model trigger, non-overlapping with grill-me; the "CONTEXT.md is a glossary" guardrail reworded from a three-item prohibition to a positive statement.

## 2026-06-05
- Imported into the Claude_Skills repo from `~/.claude/skills/grill-with-docs` (now the source of truth, symlinked into `~/.claude/skills/`).
