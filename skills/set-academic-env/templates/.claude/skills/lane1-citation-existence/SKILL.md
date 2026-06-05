---
name: lane1-citation-existence
description: Use after any change to paper/main.tex to verify every \cite{key} resolves to a Zotero item in the paper's collection. DeepSeek-only judge per Lane 1. Returns JSON with checked/resolved/unresolved counts and per-key detail.
allowed-tools: Read mcp__pal__chat
metadata:
  version: "0.1.0"
---

# lane1-citation-existence

**Lane 1 — DeepSeek-only.** No Claude call. Per ADR 0003: citation existence is a judge of Claude's own work; the neutral party must be DeepSeek.

## Purpose

Verify every `\cite{}`, `\citep{}`, and `\citet{}` key in `paper/main.tex` (resolved from `paper_config.yaml` `paths.manuscript`):
1. Exists in `paper/references.bib` (deterministic file scan).
2. Exists in the paper's Zotero collection (cross-checked against `ALLOWED_KEYS` populated by `references-management` on boot).

## Inputs

The calling command provides:
- Path to `paper/main.tex` (default: resolved from `paper_config.yaml` `paths.manuscript`; do not assume the repo root).
- Path to `paper/references.bib` (default: resolved from `paper_config.yaml` `paths.references`; do not assume the repo root).
- `ALLOWED_KEYS` — the in-memory set of Zotero item keys for this paper's collection, populated by `references-management`. If unavailable, note it in `unresolved[*].in_zotero_collection` as `null`.

## Manuscript flattening (always first)

Analyze the **flattened** manuscript: run `.claude/scripts/flatten_tex.py <paths.manuscript>` and use its output (so `\input`'d sections are included). On a single-file manuscript this is identical to the file.

## Step-by-step

### Step 1 — Extract cite keys from paper/main.tex

Read `paper/main.tex`. Extract every unique key matching any of:
- `\cite{<key>}` — including comma-separated multi-cites: `\cite{key1,key2}`
- `\citep{<key>}` — including multi-cites
- `\citet{<key>}` — including multi-cites
- `\citealt{<key>}`, `\citealp{<key>}`, `\citeauthor{<key>}`, `\citeyear{<key>}` (capture all if present)

Strip whitespace around keys. Deduplicate. Note total count as `checked`.

### Step 2 — Check paper/references.bib

Read `paper/references.bib`. For each extracted key, check whether a `@<type>{<key>,` entry exists. Record `in_bib: true` or `false`.

This is a deterministic string-match operation. No DeepSeek call needed here.

### Step 3 — Check Zotero ALLOWED_KEYS

The `references-management` skill caches `ALLOWED_KEYS` as a set of Zotero item keys (Better BibTeX `author-year-shorttitle` citekeys) for the paper's collection. For each extracted cite key, check whether it appears in `ALLOWED_KEYS`.

Record `in_zotero_collection: true`, `false`, or `null` (if `ALLOWED_KEYS` not available).

### Step 4 — Invoke DeepSeek only for ambiguous citekey style

DeepSeek (`pal__chat`, model `deepseek-v4-flash`) is called **only** when a key is absent from `ALLOWED_KEYS` but present in `paper/references.bib`, and the discrepancy may be a citekey style mismatch rather than a missing item (e.g., `smith_2024_monetary` vs `smith2024monetary`). In that case, call `pal__chat` with:

```
The paper uses citekey "<key>" in paper/main.tex, and paper/references.bib has an entry for it. The Zotero ALLOWED_KEYS set does not contain this key. Could this be a citekey style mismatch (e.g., different separator, capitalization, or year format)? The paper's declared citekey style is Better BibTeX "author-year-shorttitle" (e.g., "gali2008monetary"). Output JSON only: {"style_mismatch": true|false, "suggested_key": "<corrected_key_or_null>", "reason": "<one sentence>"}
```

For all other cases (key missing from bib entirely, or clearly correct citekey format), no DeepSeek call is made.

### Step 5 — Build report

Assemble the output JSON. `status` is `"pass"` if `unresolved` is empty; `"fail"` otherwise.

## Output JSON contract

```json
{
  "checked": 42,
  "resolved": 39,
  "unresolved": [
    {
      "key": "smith2024monetary",
      "in_bib": true,
      "in_zotero_collection": false,
      "deepseek_style_check": {
        "style_mismatch": false,
        "suggested_key": null,
        "reason": "Key appears correctly formatted but is absent from this paper's Zotero collection."
      }
    },
    {
      "key": "fakecite2026",
      "in_bib": false,
      "in_zotero_collection": false,
      "deepseek_style_check": null
    }
  ],
  "status": "fail"
}
```

`status` values:
- `"pass"` — all cite keys resolved (both `in_bib` and `in_zotero_collection` are `true`).
- `"fail"` — one or more keys unresolved.

## Notes

- This skill does **not** check whether the cited paper supports the in-text claim. That is `lane1-citation-claim-match`.
- This skill does **not** check for RefChecker-level fabrication (Crossref / OpenAlex / Semantic Scholar metadata match). That is a Phase 4 integrity-gate layer.
- `ALLOWED_KEYS` is populated by `references-management`. If it has not been run, `in_zotero_collection` will be `null` and the status will be `"pass"` only on the `in_bib` check. The report will note this limitation.
- Multi-cite commands like `\cite{key1,key2,key3}` are split into individual keys before checking.
- Per ADR 0009, `pal__chat` routes to DeepSeek via `CUSTOM_API_URL=https://api.deepseek.com/v1`. Ensure `.env` is populated before running.
