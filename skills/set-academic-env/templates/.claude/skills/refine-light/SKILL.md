---
name: refine-light
description: Use for user-scoped review or feedback on an existing section. Light-touch — runs integrity gate and Lane 1 checks, surfaces flags, but never halts and never auto-loops. Rewriting is opt-in based on the [guidance] argument.
allowed-tools: Read Write Edit Bash mcp__zotero__* mcp__pal__*
metadata:
  version: "0.1.0"
---

# /refine-light [section] [guidance] [--variant <name>]

User-scoped review and optional targeted rewrite. Light-touch variant of `/refine-heavy`.

**Arguments:**
- `[section]` — section to review (e.g., `section:3`, `label:sec:model`). Required.
- `[guidance]` — free-text instruction for what to do. Optional; if omitted, defaults to review-only.
- `[--variant <name>]` — optional. Target a named variant instead of the active default.

**Examples:**
- `/refine-light section:3 "tighten the introduction paragraph"`
- `/refine-light section:4 "review only; don't rewrite — I want to know what's broken"`
- `/refine-light section:2.1` (no guidance → review-only)
- `/refine-light section:2 --variant empirical "tighten"`

---

You may consult `logs/operations.jsonl` for prior runs on this paper before starting.

## Phase 1 — Load context (same as heavy)

Read `paper_config.yaml` first. Then resolve the target manuscript using the **Variant-resolution rule**:

**Variant-resolution rule:**
1. If `--variant <name>` was given: look up `manuscripts.variants[name].file` in `paper_config.yaml`. If the `manuscripts:` block is absent or `<name>` is not found, refuse with: "Unknown variant '<name>'. Known variants: <list keys from manuscripts.variants, or 'none registered'>." Stop.
2. Else: use `paths.manuscript` (default `paper/main.tex`).
3. Always report which manuscript you are acting on: "Acting on variant: <name> (<file>)" or "Acting on default manuscript: <file>".

Resolve the bibliography path from `paper_config.yaml` `paths:` (default `paper/references.bib`); do not assume the repo root.

Read without prompting:
1. `THEORY_PRIORS.md` (full)
2. `CONSTITUTION.md` (full)
3. `paper_config.yaml`
4. The resolved manuscript file — target section only
5. `worklog/research/*.md` — TL;DR + "Papers added to Zotero" ONLY

No "proceed?" gate needed in light mode — proceed immediately.

---

## Phase 2 — Parse guidance and decide on rewrite

Parse the `[guidance]` argument:

**Review-only signals** (no rewrite step, regardless of what follows):
- "review only", "review-only"
- "don't rewrite", "do not rewrite", "no rewrite"
- "what's broken", "what issues", "identify issues"
- No guidance argument at all

**Rewrite signals** (targeted rewrite of the specified scope):
- "tighten", "rewrite", "rephrase", "strengthen", "shorten"
- Specific targets: "rewrite paragraph 2", "fix the last sentence"

If the guidance is ambiguous, default to **review-only** and surface a note: "Guidance was ambiguous; defaulting to review-only. Re-run with explicit rewrite instructions to make changes."

For **review-only**: skip Phase 3 entirely. Proceed to Phase 4.
For **rewrite**: note the exact scope (which paragraph/sentence/subsection) before proceeding to Phase 3.

There is **no user-approval gate** in light mode. The `[guidance]` argument IS the approval.

---

## Phase 3 — Targeted rewrite (opt-in only)

Only runs if guidance was unambiguously a rewrite instruction AND the scope is specific.

Rewrite ONLY the identified scope — a paragraph, a sentence, a subsection. Do not expand the scope.

Honor all CONSTITUTION.md rules. Add `% AI:` markers. Mark unknowns with `% TKTK:`.

---

## Phase 4 — Integrity gate (light mode)

Invoke the `integrity-gate` skill in `light` mode on the section (full section, whether or not it was rewritten).

**Light mode discipline:**
- NEVER halt on gate failure. Always surface flags and continue.
- No auto-loop. Report the failure and move on.

Write the gate output to `worklog/review/refine-<timestamp>.md`. The integrity-gate skill will
also write the lean JSON sidecar `worklog/review/refine-<timestamp>.json` per its sidecar step.

---

## Phase 5 — Lane 1 checks

Same as heavy: invoke all four Lane 1 skills on the section. Append to `worklog/review/refine-<timestamp>.md`.

---

## Phase 6 — Hand back

Print a summary in conversation. **Never block on any flag status in light mode.**

```
/refine-light §<section> complete
─────────────────────────────────────────────────────────
  Guidance:        <review-only | rewrite: <scope>>
  Integrity gate:  layer-2 flags: <N>  |  layer-3 uncertain: <M>  |  overall: <status>
  Lane 1:          citation mismatches: <K>  |  AI-tells flagged: <J>
  Review report:   worklog/review/refine-<timestamp>.md
```

If flags exist: "Flags are surfaced in the report. Address them at your discretion — light mode never blocks."
