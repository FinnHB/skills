---
name: review-structure
description: Use to get a holistic LLM review of repo organization against the module-based canonical map — surfaces duplicated figures, missing module READMEs/lockfiles, loose code/data at root — and suggests concrete "move X → Y" actions. Advisory only; makes no changes without user confirmation.
allowed-tools: Read Bash
metadata:
  version: "0.1.0"
---

# /review-structure

Advisory holistic review of repo organization against the module-based canonical map.
**Makes no changes.** Surfaces issues and suggests concrete moves for the user to confirm.

## Precondition

Resolve the project root from `$CLAUDE_PROJECT_DIR` (or `$PWD`). If `paper_config.yaml`
is absent, warn and continue — the review is best-effort.

## Step 1 — Read the canonical map

Read `CLAUDE.md` (the "Canonical map — module-based" section) to anchor all findings
against the documented map. Note the key rules:
- `code/<module>/output/` = generated figures/tables (git-ignored, referenced via `\graphicspath`)
- `paper/figures/` = static hand-made figures only (tracked)
- Each module must have `requirements.txt`, `README.md`, and `src/`
- Loose `.py`/`.jl`/`.R`/`.do` scripts at repo root or in `paper/` are misplaced
- Large data files belong in `code/<module>/data/` or root `data/`, not at root or in `paper/`

## Step 2 — Gather the tree

Run:
```bash
find . -not -path './.git/*' -not -path './.venv/*' -not -path './code/*/.venv/*' \
  -maxdepth 6 2>/dev/null | sort
```

If `code/` exists, also inspect each module:
```bash
for mod in code/*/; do
  echo "=== $mod ==="
  ls -A "$mod" 2>/dev/null
done
```

Read any `code/*/README.md` and `code/*/pipeline_state.json` files that exist.

## Step 3 — Review against the map

Check each of the following. For each issue found, record: **what**, **why it's a problem**,
and a **concrete "move/rename X → Y"** suggestion.

1. **Duplicated figures:** any file in `paper/figures/` that also exists (same name or
   `fig_`-prefixed variant) in a `code/*/output/` — these should be removed from `paper/figures/`
   and referenced via `\graphicspath` instead.

2. **Module completeness:** for each `code/<module>/`:
   - Missing `requirements.txt` (or `Project.toml`/`renv.lock`) → module env is unpinned.
   - Missing `README.md` → module purpose and run instructions undocumented.
   - Missing `src/` directory → scripts may be loose at `code/<module>/` root (not a hard rule,
     but flag if scripts are at module root with no `src/`).

3. **Loose code at root or in `paper/`:** any `.py`, `.jl`, `.R`, `.do`, `.m` file at
   repo root or under `paper/` — should be in `code/<module>/src/`.

4. **Loose data files at root or in `paper/`:** any `.csv`, `.dta`, `.parquet`, `.xlsx`
   at repo root or under `paper/` — should be in `code/<module>/data/` or root `data/`.

5. **Generated figures in `paper/figures/`:** any `fig*.pdf` or `fig*.png` in
   `paper/figures/` when `code/` exists — these are likely generated and should live in
   `code/<module>/output/` with `\graphicspath` surfacing them.

6. **Stale or mislabeled data:** any directory named `derived/` inside a module's `data/`
   alongside `raw/` that looks like it should be regenerated — flag for review.

7. **`pipeline_state.json` issues:** if a module has scripts in `src/` but no
   `pipeline_state.json`, note that provenance tracking is absent (not blocking, just flagged).

A rule can't catch everything — apply judgment. If the tree is clean, say so clearly.

## Step 4 — Write the report

Print a structured report to the terminal (do not write a file unless the user asks):

```
─────────────────────────────────────────────────────
STRUCTURE REVIEW — <paper slug>
─────────────────────────────────────────────────────

Canonical map: CLAUDE.md (module-based)
Tree scanned: <date>

ISSUES FOUND: <N>  (0 = all good)

[If N > 0:]
  1. <Issue type>
     File/dir: <path>
     Problem:  <why>
     Suggest:  <move X → Y / create Y / remove duplicate>

  2. ...

[If N = 0:]
  Repo organization looks clean. No misplaced files or module gaps found.

─────────────────────────────────────────────────────
Advisory only — no changes made. Confirm each suggestion before acting.
```

## Step 5 — Exit

After printing the report, ask:
> "Would you like me to apply any of these suggestions? List the numbers to apply (e.g. '1 3'), or 'none' to skip."

If the user lists numbers: describe exactly what will change for each, ask for final
confirmation, then apply only the confirmed moves (using `Bash mv` or `Edit`/`Write`
as appropriate). Do not apply changes without explicit user confirmation.

If the user says 'none' or anything non-affirmative: stop.
