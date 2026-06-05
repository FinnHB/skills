# AcademicPaperWriter — Workflow map

## Tracks

```
GREENFIELD    /start-paper → /scope-paper → /draft-paper ──────────────────┐
EXISTING DRAFT /onboard-paper ─────────────────────────────────────────────┤
                                                                            ↓
REFINE                                                 /refine-light | /refine-heavy
                                                                            │
ANYTIME       /research  /find-cite  /sync-zotero  /verify-symbolic|numerical  /match-journal
EMPIRICAL     /add-module <name> → (edit code/<name>/src, bash run.sh) → /review-structure
                                                                            │
FINISH                                    … → /signoff → /export-coauthor ─┘
```

## Where am I → what next?

| If… | You are at | Do next |
|-----|-----------|---------|
| No `worklog/IDEA.md`, no existing draft | Pre-scope (greenfield) | `/start-paper` |
| No `worklog/IDEA.md`, draft in `source/` | Onboarding | `/onboard-paper` |
| `worklog/IDEA.md` exists, no `worklog/RESEARCH_BRIEF.md` | Scoping | `/scope-paper` |
| `worklog/RESEARCH_BRIEF.md` exists, `THEORY_PRIORS.md` `model_class_status: declared`, no `paper/main.tex` | Ready to draft | `/draft-paper` |
| `paper/main.tex` exists | Drafting / refining | `/refine-light` or `/refine-heavy`; `/add-module` (empirical); `/match-journal` |
| Reviews clean, ready to submit | Finishing | `/signoff` → `/export-coauthor` |

## Command reference

### Greenfield track
- `/start-paper` — elicit idea, write `worklog/IDEA.md` + `worklog/CONTEXT.md`
- `/scope-paper` — develop research plan, write `worklog/RESEARCH_BRIEF.md`
- `/draft-paper` — produce first full `paper/main.tex` from the brief

### In-progress / onboarding
- `/onboard-paper` — import existing `.docx` draft, extract citations, align with harness layout

### Refine
- `/refine-light` — light revision pass (framing, clarity, Lane 1 checks)
- `/refine-heavy` — heavy revision with integrity gate + Lane 1/2 verification

### Research & citations
- `/research [topic]` — deep literature search, writes report to `worklog/research/`
- `/find-cite` — locate citation for a claim; returns Zotero key
- `/sync-zotero` — pull Zotero collection → `paper/references.bib`

### Verification (approval-gated)
- `/verify-symbolic` — SymPy spot-checks of model equations
- `/verify-numerical` — numerical calibration check

### Empirical (on demand)
- `/add-module <name> [--lang python|julia|r]` — scaffold `code/<name>/` with pipeline provenance
- `/review-structure` — holistic review of repo organization (advisory, no changes)

### Finishing
- `/match-journal` — score paper against target journals, write `worklog/review/` report
- `/signoff` — final integrity gate, SHA-pin manuscript, write `SIGNOFF.md`
- `/export-coauthor` — produce clean co-author package

### Modular manuscript
- Modularize an existing `main.tex` with `/split-sections`.

### Variants
- `/add-variant <name> --from base` → edit its `\input` list in `paper/main_<name>.tex` → use `--variant <name>` on `/refine-light`, `/refine-heavy`, `/signoff`, `/export-coauthor`, `/match-journal`.
- See what a variant adds over another: `.claude/scripts/diff_variants.sh paper/main.tex paper/main_<name>.tex`
- `paths.manuscript` in `paper_config.yaml` is always the active/default variant; `--variant` overrides per run only.

---
*Paths are declared in `paper_config.yaml` → `paths:`; never hardcode `./main.tex`.*
*Logs: `logs/operations.jsonl`. Provenance: `code/<module>/pipeline_state.json`.*
