---
name: pandoc-import
description: Use during /onboard-paper to convert a .docx source into paper/main.tex with equation rescue. Pandoc handles text/structure/citations; an LLM rescue pass fixes equation blocks that Pandoc mangled, with strict JSON output and tri-state status (clean/uncertain/broken).
allowed-tools: Bash Read Write Edit mcp__pal__chat
metadata:
  version: "0.1.0"
---

# pandoc-import

Implements the Pandoc + Lua filter + LLM equation rescue pipeline per Research/10 §B. Called by `/onboard-paper`.

## Step 1 — Pandoc conversion

The output manuscript path is resolved from `paper_config.yaml` `paths.manuscript` (default `paper/main.tex`); do not assume the repo root.

```bash
pandoc source/<DOCX_FILENAME>.docx -o paper/main.tex \
  --from=docx+styles \
  --to=latex \
  --citeproc=false \
  --extract-media=./media \
  --wrap=preserve \
  --lua-filter=.claude/skills/pandoc-import/fix-math.lua
```

If Pandoc exits non-zero: **fail loud** with the full Pandoc error message. Do NOT attempt equation rescue on a missing or empty `paper/main.tex`.

## Step 2 — `fix-math.lua` (vendored at `.claude/skills/pandoc-import/fix-math.lua`)

The Lua filter tags every math block with a unique ID so the rescue post-pass can locate and replace them unambiguously:

```lua
function Math(el)
  el.text = "% TAG:" .. os.time() .. math.random() .. "\n" .. el.text
  return el
end
```

## Step 3 — Equation rescue post-pass

**Extract tagged blocks:**

Parse `paper/main.tex` for every block matching `% TAG:<id>`. Build a list of rescue records:
```json
{
  "id": "<tag_value>",
  "raw_pandoc_tex": "<LaTeX from Pandoc>",
  "context_before": "<300 chars of text before the equation in paper/main.tex>",
  "context_after": "<300 chars of text after the equation in paper/main.tex>",
  "page_ref": "<paragraph number or section if determinable>"
}
```

**Rescue prompt** (invoke `mcp__pal__chat` with model `deepseek-v4-flash` — cheap, bulk work):

```
You are converting a single equation block from Word/OMML-derived LaTeX
into clean, journal-grade LaTeX. The Pandoc-derived LaTeX is below.

Goals:
1. Preserve mathematical content EXACTLY. If uncertain about a symbol,
   OUTPUT "UNCERTAIN" and explain — do not guess.
2. Use amsmath conventions: align, aligned, align*, equation, gather.
3. Restore numbering if context suggests it.
4. Preserve subscripts/superscripts including time indices.
5. Use \mathbb{E}_t for conditional expectations, \log, \exp.
6. Hat/tilde/bar accents: \hat{x}, \tilde{x}, \bar{x}.

Output strict JSON:
{ "clean_tex": "...", "status": "clean" | "uncertain" | "broken",
  "notes": "..." }
```

**Apply results:**

- `status: clean` → replace the tagged block (including the `% TAG:` line) with `clean_tex` in `paper/main.tex`.
- `status: uncertain` or `status: broken` → leave the original Pandoc output in place AND insert `% RESCUE-NEEDED: <notes>` as a comment immediately above the block. The user reviews these manually before any `/refine-*` run.

## Output

After the rescue pass, report:
- Number of equations processed
- Number cleaned
- Number marked `% RESCUE-NEEDED:` (uncertain or broken)
- List of `% RESCUE-NEEDED` equation IDs + notes for user review

## Author-prep note

If the author can use Zotero/Mendeley citation fields (not hand-typed) and Word equation editor in Professional mode (not Linear), Pandoc behavior improves substantially. Encourage this before running `/onboard-paper` if the author has the opportunity.
