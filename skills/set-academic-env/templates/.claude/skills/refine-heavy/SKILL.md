---
name: refine-heavy
description: Use for full re-evaluation and possible rewrite of a section. Six-phase loop with user approval gates. Halts on layer-1 integrity failure after 2 auto-retries. Surfaces all Lane 1 flags in a dated review report.
allowed-tools: Read Write Edit Bash mcp__zotero__* mcp__pal__*
metadata:
  version: "0.1.0"
---

# /refine-heavy [section] [--variant <name>]

Full six-phase rewrite loop per session-01 Q8. Takes a `[section]` argument identifying the section to refine (e.g., `section:3.2` or `label:sec:model`). If no section is specified, ask the user which section to work on before starting.

**Arguments:**
- `[section]` — section to refine. Required (if omitted, ask before starting).
- `[--variant <name>]` — optional. Target a named variant instead of the active default.

---

You may consult `logs/operations.jsonl` for prior runs on this paper before starting.

## Phase 1 — Load context (silent)

Read `paper_config.yaml` first. Then resolve the target manuscript using the **Variant-resolution rule**:

**Variant-resolution rule:**
1. If `--variant <name>` was given: look up `manuscripts.variants[name].file` in `paper_config.yaml`. If the `manuscripts:` block is absent or `<name>` is not found, refuse with: "Unknown variant '<name>'. Known variants: <list keys from manuscripts.variants, or 'none registered'>." Stop.
2. Else: use `paths.manuscript` (default `paper/main.tex`).
3. Always report which manuscript you are acting on: "Acting on variant: <name> (<file>)" or "Acting on default manuscript: <file>".

Resolve the bibliography path from `paper_config.yaml` `paths:` (default `paper/references.bib`); do not assume the repo root.

Read the following without prompting the user:
1. `THEORY_PRIORS.md` (full)
2. `CONSTITUTION.md` (full)
3. `paper_config.yaml`
4. `source/FullDraftPaper.pdf` if present (chunked read, focus on the target section's original)
5. The resolved manuscript file — the target section only
6. `related/*/contribution.md` if any `related/` subdirectories exist
7. `worklog/research/*.md` — TL;DR section + "Papers added to Zotero" section ONLY (per ADR 0007; do not read methodology or full analysis from research files)

After loading, confirm in conversation:
> "Loaded paper context. Section to refine: §<section>. Current state: <1-sentence summary of what the section does>. Ready to critique — proceed?"

Wait for user acknowledgment (any response proceeds; this is a "I'm here" gate, not an approval gate).

---

## Phase 2 — Read and critique (user-approval gate)

Read the target section carefully. Produce a structured critique:

```
## Critique — §<section>

**What works:**
- <bullet>

**What's broken or weak:**
- <bullet with specific line/equation reference>

**Proposed direction:**
<1-3 sentence description of the intended rewrite: what changes, what stays>

**Scope of rewrite:**
<conservative | moderate | significant>
```

Surface this to the user. Then explicitly ask:
> "Do you approve this direction? Type `approve` to proceed with the rewrite, or describe changes to the proposed direction. Type `cancel` to exit without rewriting."

**MANDATORY GATE**: Do NOT proceed to Phase 3 until the user types `approve` (or a modified direction). If the user edits the proposed direction, confirm the updated direction before proceeding.

---

## Phase 3 — Rewrite

Only runs after explicit user approval in Phase 2.

Rewrite the target section in `paper/main.tex` per the approved direction:
- Preserve `% AI:` attribution markers (one per paragraph, at paragraph end per ADR 0001).
- Mark unknowns with `% TKTK: <question>` — never re-elicit during this phase.
- Never introduce new citations from `worklog/research/*.md` — only cite keys already in `paper/references.bib`.
- Honor all `CONSTITUTION.md` rules (FX notation, authorship, SymPy discipline, etc.).

The PostToolUse `latexdiff` hook (Phase 7) will auto-snapshot after each Edit call.

---

## Phase 4 — Integrity gate (Lane 2 via PAL)

Invoke the `integrity-gate` skill in `heavy` mode on the rewritten section.

The gate's auto-loop logic (max 2 retries on layer-1 failure) runs inside the gate itself — do not re-implement it here.

Write the gate's aggregate JSON output to `worklog/review/refine-<timestamp>.md` as a formatted
markdown report. The integrity-gate skill will also write the lean JSON sidecar
`worklog/review/refine-<timestamp>.json` per its sidecar step.

```markdown
# Integrity Gate Report — /refine-heavy §<section>
**Run:** <timestamp>  **Mode:** heavy

## Layer 1 — Notational coherence
Status: <pass|fail>
Undefined symbols: <list or "none">
Well-posedness: <N equations, M variables, balanced: true|false>

## Layer 2 — Class-aware coherence
Status: <pass|warn|skipped>
Agreement: <agree|disagree|partial>
Flags: <list or "none">

## Layer 3 — SymPy spot-checks
Status: <pass|warn|fail>
Spot checks: <list with equation labels and verdicts>

## Overall
Status: **<pass|warn|fail>**
Blocks render: <yes|no>
```

If `overall_status: fail` after retries: halt. Print:
> "Integrity gate failed after 2 retries. Review `worklog/review/refine-<timestamp>.md`. Resolve the issues and re-run `/refine-heavy`."
Do not proceed to Phase 5.

---

## Phase 5 — Lane 1 checks

In parallel, invoke all four Lane 1 skills on the rewritten section:
1. `lane1-citation-existence` — are all \cite{} keys in `paper/references.bib`?
2. `lane1-citation-claim-match` — do cited claims match their sources?
3. `lane1-cross-ref-validity` — do all \ref{}, \eqref{} resolve?
4. `lane1-ai-tell-scan` — AI-vocabulary telltales?

Append results to `worklog/review/refine-<timestamp>.md` (the same file as Phase 4):

```markdown
## Lane 1 Results

### Citation existence: <pass|fail>
<unresolved keys, if any>

### Citation–claim match: <pass|warn|fail>
<mismatches, if any>

### Cross-reference validity: <pass|fail>
<unresolved refs, if any>

### AI-tell scan: <pass|warn>
<flagged paragraphs, if any>
```

---

## Phase 6 — Hand back

Print a summary in conversation:

```
/refine-heavy §<section> complete
─────────────────────────────────────────────────────────
  Integrity gate:  layer-2 flags: <N>  |  layer-3 uncertain: <M>  |  overall: <status>
  Lane 1:          citation mismatches: <K>  |  AI-tells flagged: <J>
  Review report:   worklog/review/refine-<timestamp>.md
  Diff:            worklog/transcripts/refine-<timestamp>.diff (auto-saved by hook)
```

If any flags or warns are present, note: "Review the report and address flags before running `/signoff` or sharing with coauthors."
