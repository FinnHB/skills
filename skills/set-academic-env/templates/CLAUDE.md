# CLAUDE.md

New here? See `WORKFLOW.md` for the map.

This is an AcademicPaperWriter paper repository. See:
- `CONSTITUTION.md` — inviolable rules for this paper.
- `paper_config.yaml` — paper-specific configuration.
- `THEORY_PRIORS.md` — declared model class, hard constraints, decision log.
- `SETUP.md` — human-action checklist for setup.
- `docs/adr/` (in harness source repo) — architectural decisions.
- `CONTEXT.md` (in harness source repo) — vocabulary glossary.

## Repository layout

This repo uses the Phase 12 light default layout. All paths are declared in
`paper_config.yaml` under `paths:` — **never hardcode `./main.tex` or any root
path directly in a skill or hook**. Always resolve from `paths:`.

```
<paper>/
├── paper/                 paper/main.tex, paper/references.bib
├── worklog/               IDEA.md  CONTEXT.md  RESEARCH_BRIEF.md
│   ├── research/          research reports (/research writes here)
│   ├── review/            integrity-gate + journal-target reports
│   └── transcripts/       latexdiff snapshots
├── source/   related/   logs/
├── CONSTITUTION.md  THEORY_PRIORS.md  SIGNOFF.md  CHANGELOG.md  (governance — root)
├── paper_config.yaml  CLAUDE.md  SETUP.md
└── .claude/  .githooks/  .gitignore  .mcp.json  conf/
```

### Canonical map — module-based (grows on demand, never pre-created)

The harness defines this map; each project materializes only the slice it uses.
`code/` and its modules are **never pre-created** — a `/add-module` skill (13b-2)
scaffolds them on demand. Theory-only repos have no `code/` at all.
Create a module with `/add-module <name> [--lang python|julia|r]`.

```
<paper>/
├── paper/                  main.tex, references.bib
│   └── figures/            STATIC figures only (hand-made, tracked)
├── code/                   analysis modules (created on demand by /add-module)
│   └── <module>/           e.g. empirical, quant — standard internal layout:
│       ├── src/            analysis scripts
│       ├── output/         GENERATED figures/tables/numbers (git-ignored)
│       ├── data/           module-scoped data (raw/ read-only; large files git-ignored)
│       ├── tests/          optional
│       ├── requirements.txt  pinned env spec (tracked)
│       ├── .venv/          module analysis env (git-ignored)
│       ├── README.md       what the module does + how to run
│       ├── run.sh          module run-all
│       └── pipeline_state.json  per-step provenance (written by 13b-2 pipeline)
├── worklog/  source/  related/  logs/
├── replication/            submission-ready package (created near signoff)
└── governance + config at root (CONSTITUTION, THEORY_PRIORS, paper_config, CLAUDE, …)
```

**Generated figures** live in `code/<module>/output/` and reach the manuscript via
`\graphicspath` — no copying, no duplication. `paper/figures/` holds **only static**
(hand-made, not code-generated) figures and is tracked.

**Two Python environments — both named `.venv`, separated by location:**
- Root `.venv/` — harness tooling (sympy, pyzotero, grobid-client-python, python-docx).
  Pinned via `conf/harness-requirements.txt`. Git-ignored.
- `code/<module>/.venv/` — each module's analysis env (git-ignored); its
  `requirements.txt` lockfile is tracked. Created by `/add-module` (13b-2).

**Data:** Large data files are git-ignored. Track `data/README.md` + a manifest
(sources, checksums, sizes) + `data/fetch.sh`. No DVC/git-annex by default (opt-in).

**Pipeline:** each module has a `run.sh` (run-all) + numbered scripts in `src/`.
Per-step provenance is recorded in `pipeline_state.json` — the fingerprint-of-record
for git-ignored generated artifacts (presence, tamper detection, staleness checks).

**Replication package:** `replication/README.md` (Social Science Data Editors template)
documents data availability, software + exact versions + runtime, and the code→figure/table
mapping. Required for AER/JPE submission — create it before final `/signoff`.

## Modular manuscript convention (Phase 16-1+)

A manuscript can be a **thin wrapper** over a section library instead of a single monolithic file:

```
paper/
├── main.tex                     % Variant: base — thin wrapper (\input each section)
└── sections/
    ├── _preamble.tex            shared preamble (included before \begin{document})
    ├── 00_front.tex             front-matter (title, abstract, keywords)
    ├── 01_introduction.tex      section files — content lives here
    ├── 02_model.tex
    └── …
```

- `paper/main.tex` (wrapper): `\input{sections/_preamble}`, `\begin{document}`, ordered `\input{sections/NN_…}` lines, bibliography, `\end{document}`.
- **Tectonic builds `\input`-based wrappers natively** — PDF generation needs no change.
- **All content gates** (integrity-gate, lane1-*, ai-tell scan, chktex lint, latexdiff) analyze the **flattened** manuscript by running `.claude/scripts/flatten_tex.py paper/main.tex`, so every section is fully checked even though `main.tex` is a thin wrapper.
- **Backward-compatible**: a monolithic `main.tex` (no `\input`) works exactly as before — `flatten_tex.py` is the identity on files with no includes.
- Migrate an existing monolithic `main.tex` to the modular layout with `/split-sections` (backs up to `main.tex.presplit`; verifies round-trip before finishing).

## Manuscript variants (Phase 16-2+)

A modular manuscript can have **sibling variant wrappers** — each a thin file that shares `paper/sections/` but selects a different `\input` assembly (e.g. theory-only vs. theory+empirics, or a journal-tailored cut):

```
paper/
├── main.tex                     % Variant: base    (paths.manuscript — the active default)
├── main_empirical.tex           % Variant: empirical — adds \input{sections/05_empirics}
├── main_jpe.tex                 % Variant: jpe — Target journal: JPE
└── sections/                    shared — content lives only here, never in the wrappers
```

- **`paths.manuscript` = the active/default variant.** Hooks and gates always resolve it. To change which variant is "active", edit `paths.manuscript` in `paper_config.yaml`.
- **Registry:** `paper_config.yaml` `manuscripts.variants` is the catalog — `{ <name>: { file, journal } }`. The wrapper file is authoritative for *which sections to include*; the registry holds *file path + target journal* only.
- **`--variant <name>`** on `/refine-light`, `/refine-heavy`, `/signoff`, `/export-coauthor`, and `/match-journal` selects a variant for that one run without changing the active default.
- **Create a variant** with `/add-variant <name> [--from base] [--journal J]`. It creates a thin sibling wrapper (header + copied `\input` list, **no content duplication**) and registers it. Diverge it by editing its `\input` list or adding variant-only sections.
- **Diff variants** with `.claude/scripts/diff_variants.sh paper/main.tex paper/main_<name>.tex` — flattens both wrappers and runs latexdiff (or plain diff if latexdiff is absent).

## Action log

`logs/operations.jsonl` is the append-only ledger of command runs — one lean JSON record per
run, no fabricated fields. Per-run detail (integrity gate verdicts, Lane 1 results, diff and
report paths) lives in `worklog/review/*.json` sidecars. Consult `logs/operations.jsonl` to
see what has already been done to this paper.

## Workflow commands

- Greenfield: `/start-paper` → `/scope-paper` → `/draft-paper`
- In-progress: `/onboard-paper` → `/refine-light` or `/refine-heavy`
- Sub-research: `/research [topic]`
- Verification: `/verify-symbolic`, `/verify-numerical` (approval-gated)
- Utilities: `/find-cite`, `/sync-zotero`, `/export-coauthor`, `/signoff`, `/match-journal`, `/review-structure`
