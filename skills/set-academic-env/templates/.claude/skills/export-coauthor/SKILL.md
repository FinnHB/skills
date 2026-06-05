---
name: export-coauthor
description: Use to produce a .docx export from paper/main.tex for coauthor handoff. Pandoc-based; round-trip via /onboard-paper if the coauthor returns edits.
allowed-tools: Bash Read Write
metadata:
  version: "0.1.0"
---

# /export-coauthor [--variant <name>]

Produce a `.docx` export from the manuscript for coauthor handoff. The `.docx` is a Pandoc export format only; the LaTeX source remains canonical (per ADR 0001).

**Arguments:**
- `[--variant <name>]` — optional. Export a named variant instead of the active default.

Read `paper_config.yaml`. Resolve the target manuscript using the **Variant-resolution rule**:

**Variant-resolution rule:**
1. If `--variant <name>` was given: look up `manuscripts.variants[name].file` in `paper_config.yaml`. If the `manuscripts:` block is absent or `<name>` is not found, refuse with: "Unknown variant '<name>'. Known variants: <list keys from manuscripts.variants, or 'none registered'>." Stop.
2. Else: use `paths.manuscript` (default `paper/main.tex`).
3. Always report which manuscript you are acting on: "Acting on variant: <name> (<file>)" or "Acting on default manuscript: <file>".

Resolve the bibliography path from `paper_config.yaml` `paths:` (default `paper/references.bib`); do not assume the repo root.

## Preconditions

1. The resolved manuscript file must exist.
2. `paper/references.bib` must be in sync (run `/sync-zotero` first if unsure). Check: `ls -lt paper/references.bib` — if older than the manuscript file, warn: "paper/references.bib may be out of date. Run /sync-zotero before exporting."
3. CSL file for citation rendering: `.claude/skills/pandoc-import/csl/chicago-author-date.csl`. If missing, run will fail with a clear error.

## Step 1 — Prepare a clean copy for export

Create a temporary export copy of the resolved manuscript with internal markers stripped.
If the manuscript is a modular wrapper (contains `\input{sections/`), flatten it first via
`.claude/scripts/flatten_tex.py <resolved-manuscript>` so Pandoc sees the full prose.

```bash
# Strip % AI: markers (attribution comment for internal use only)
# Replace % TKTK: markers with [NEEDS RESEARCH: <text>] for coauthor visibility
MANUSCRIPT="<resolved manuscript path>"   # set by Variant-resolution rule above
tmpfile=$(mktemp /tmp/export-XXXXXX.tex)
python3 .claude/scripts/flatten_tex.py "$MANUSCRIPT" | \
  sed 's/% AI:[^%]*//' | \
  sed 's/% TKTK: \(.*\)/[NEEDS RESEARCH: \1]/' > "$tmpfile"
```

## Step 2 — Run Pandoc

```bash
mkdir -p export
SLUG=$(grep "slug:" paper_config.yaml | awk -F'"' '{print $2}')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="export/${SLUG}-${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"

pandoc "$tmpfile" \
  --citeproc \
  --bibliography=paper/references.bib \
  --csl=.claude/skills/pandoc-import/csl/chicago-author-date.csl \
  -o "${OUTPUT_DIR}/${SLUG}-${TIMESTAMP}.docx"

rm -f "$tmpfile"
```

If Pandoc exits non-zero: print the full error and stop — do not silently produce a broken `.docx`.

## Step 3 — Bundle with coauthor README

Write `${OUTPUT_DIR}/README.md`:

```markdown
# Coauthor package — <paper title from paper_config.yaml>

**Exported:** <timestamp>

## How to use this package

This `.docx` file was generated from `paper/main.tex` via Pandoc. It is a one-way
export for your review and comments.

**To return edits:** send the edited `.docx` back to the lead author. They will
import it using `/onboard-paper` to merge your changes back into `paper/main.tex`.

**Notes:**
- AI attribution markers (`% AI:`) have been stripped from this export.
- `[NEEDS RESEARCH: ...]` markers indicate sections where the author needs to
  add citations or content. Feel free to suggest papers.
- Citations follow Chicago author-date format in this export.
```

## Step 4 — Report

Print to conversation:

```
/export-coauthor complete
──────────────────────────────────────────────────────────
  Bundle: export/<slug>-<timestamp>/
    <slug>-<timestamp>.docx
    README.md

To import coauthor edits back: place the edited .docx in source/ and run /onboard-paper.
```
