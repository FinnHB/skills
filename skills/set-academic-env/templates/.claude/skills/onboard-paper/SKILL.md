---
name: onboard-paper
description: Use to import an existing draft paper (.docx + parent .pdf in source/). Runs Pandoc + LLM equation rescue, extracts citations to Zotero, regenerates paper/references.bib, proposes THEORY_PRIORS.md content. Refuses non-public data classification (MVP+1).
allowed-tools: Read Write Edit Bash mcp__zotero__* mcp__pal__*
metadata:
  version: "0.1.0"
---

# /onboard-paper

Import an existing draft paper into the harness. Run this once per paper before using `/refine-*`.

## Preconditions

Before starting:
1. Check `paper_config.yaml`'s `data.classification` field. If it is anything other than `public`, refuse immediately:
   > "DATA_CLASSIFICATION wall is MVP+1; cannot onboard restricted/confidential data yet. Set `data.classification: public` in `paper_config.yaml` or wait for MVP+1."
2. Verify `source/` contains at least one `.docx` file. If none found, print:
   > "No .docx found in source/. Place your draft Word document in source/ and re-run."
   And stop.

Resolve the manuscript and bibliography paths from `paper_config.yaml` `paths:` (defaults `paper/main.tex`, `paper/references.bib`); do not assume the repo root.

## Step 1 — Pandoc + equation rescue

Invoke the `pandoc-import` skill:
- Find the `.docx` file in `source/` (if multiple, choose the most recently modified; tell the user which was chosen).
- Run the Pandoc conversion and LLM equation rescue pipeline per `pandoc-import/SKILL.md`.
- If Pandoc fails, print the full error and stop — do not continue to citation extraction on a broken `paper/main.tex`.
- Report the rescue summary (clean / uncertain / broken counts).

## Step 2 — Citation extraction

Invoke the `citation-extract` skill on:
1. The `.docx` source file (paragraph text + footnotes).
2. Any `.pdf` in `source/` (full draft context). If no PDF, skip the PDF pass and note it.

The citation-extract skill includes a **mandatory user confirmation step**. Do NOT skip it. The user must accept or reject each citation candidate before Zotero add proceeds.

## Step 3 — Regenerate `paper/references.bib`

After citation extraction completes, auto-invoke `/sync-zotero` to regenerate `paper/references.bib` from the paper's Zotero collection. Print the sync summary.

## Step 4 — THEORY_PRIORS.md proposal

Read `source/FullDraftPaper.pdf` (or the `.pdf` in `source/` if present; or `paper/main.tex` if no PDF) for context.

Propose draft content for the `THEORY_PRIORS.md` `<!-- BEGIN USER-SPECIFIED -->` block:
- Proposed `model_class` (NK-DSGE, RBC, HANK, other — with rationale)
- Proposed key structural assumptions (e.g., Calvo pricing, GHH preferences)
- Proposed key parameters seen in the paper (list symbol + semantic role)
- Proposed identification assumptions if this is an empirical paper

**Present the proposal to the user.** Do NOT write to `THEORY_PRIORS.md` until the user reviews and approves. Say:
> "Here is my proposed content for THEORY_PRIORS.md. Review and edit as needed, then type `commit priors` to save, or `skip` to leave THEORY_PRIORS.md for manual editing."

On `commit priors`: write the approved content into the `<!-- BEGIN USER-SPECIFIED -->` fence in `THEORY_PRIORS.md` and transition `model_class_status` to `declared`. Append a Decision-log entry.

On `skip`: leave `THEORY_PRIORS.md` unmodified.

## Step 5 — Summary

Print a structured summary:

```
/onboard-paper complete
─────────────────────────────────────────────────────────
  paper/main.tex: generated from source/<docx>
  Equations:   <N> total | <clean> clean | <rescue_needed> need review (% RESCUE-NEEDED:)
  Citations:   <N_added> added to Zotero | <N_unresolved> unresolved (check manually)
  paper/references.bib: synced
  THEORY_PRIORS.md: <committed / pending manual edit>

Next steps:
  • Review all % RESCUE-NEEDED: equation markers in paper/main.tex before refining.
  • Run /refine-light to begin with light-touch review.
  • Run /refine-heavy for a full rewrite of a specific section.
```
