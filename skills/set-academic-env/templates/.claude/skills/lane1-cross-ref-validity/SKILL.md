---
name: lane1-cross-ref-validity
description: Use after any change to paper/main.tex to verify every \ref{}, \eqref{}, \autoref{}, \Cref{}, and \cref{} resolves to a \label{} defined in the document. DeepSeek-only for fuzzy typo suggestions; existence check is deterministic.
allowed-tools: Read mcp__pal__chat
metadata:
  version: "0.1.0"
---

# lane1-cross-ref-validity

**Lane 1 — DeepSeek-only.** No Claude call. Per ADR 0003: cross-reference validity is a judge of Claude's own edits; DeepSeek is the neutral evaluator.

## Purpose

Verify every cross-reference command in `paper/main.tex` (resolved from `paper_config.yaml` `paths.manuscript`) resolves to a defined `\label{}`. Broken cross-references compile silently in LaTeX (producing "??" in the output) but indicate structural errors. DeepSeek is called only for fuzzy-match suggestions when a reference is unresolved and a likely typo target exists.

## Inputs

- Path to `paper/main.tex` (default: resolved from `paper_config.yaml` `paths.manuscript`; do not assume the repo root).
- For multi-file papers using `\input{}` or `\include{}`, recursively read all included `.tex` files to collect the full label set.

## Manuscript flattening (always first)

Analyze the **flattened** manuscript: run `.claude/scripts/flatten_tex.py <paths.manuscript>` and use its output (so `\input`'d sections are included). On a single-file manuscript this is identical to the file.

## Step-by-step

### Step 1 — Collect all \label{} definitions

Read `paper/main.tex` (and any `\input{}`-included files). Extract every `\label{<key>}` occurrence. Build a set `DEFINED_LABELS`.

For counter-qualified labels (e.g., `\label{eq:euler}`, `\label{fig:irfs}`, `\label{tab:results}`, `\label{sec:model}`), store the full key including prefix.

### Step 2 — Collect all cross-reference commands

Extract every occurrence of:
- `\ref{<key>}`
- `\eqref{<key>}`
- `\autoref{<key>}`
- `\Cref{<key>}` — may be comma-separated: `\Cref{eq:euler,eq:pc}`
- `\cref{<key>}` — may be comma-separated
- `\pageref{<key>}`
- `\nameref{<key>}` (if present)

For comma-separated arguments, split into individual keys. Deduplicate. Build `REFS_USED` set. Total unique keys = `checked`.

### Step 3 — Deterministic resolution check

For each key in `REFS_USED`:
- If key is in `DEFINED_LABELS`: mark `resolved: true`.
- If key is NOT in `DEFINED_LABELS`: mark `resolved: false`, add to unresolved list.

This step requires no DeepSeek call.

### Step 4 — Fuzzy-match suggestions via DeepSeek (unresolved only)

For each unresolved reference key, check whether it is likely a typo of a defined label. If `DEFINED_LABELS` contains a label that differs by 1–3 characters from the unresolved key (common cases: missing/extra prefix separator, transposed characters, wrong counter prefix), call `mcp__pal__chat` with model `deepseek-v4-flash`:

```
The LaTeX document has a cross-reference \ref{<unresolved_key>} that does not match any \label{} in the document. The defined labels are: <comma-separated list of DEFINED_LABELS>. Is this likely a typo? Output JSON only: {"likely_typo": true|false, "suggested_label": "<best_match_or_null>", "reason": "<one sentence>"}
```

Only call DeepSeek if `len(DEFINED_LABELS) <= 200` (to avoid exceeding the prompt context budget with huge label sets; for large documents, skip the suggestion step and note it in the output).

### Step 5 — Build report

Assemble the output JSON. `status` is `"pass"` if `unresolved` is empty; `"fail"` otherwise.

## Output JSON contract

```json
{
  "checked": 24,
  "resolved": 22,
  "unresolved": [
    {
      "ref": "eq:phlilips_curve",
      "ref_command": "\\eqref",
      "suggested_label": "eq:phillips_curve",
      "deepseek_typo_check": {
        "likely_typo": true,
        "suggested_label": "eq:phillips_curve",
        "reason": "Single character transposition ('phlilips' vs 'phillips'); the label eq:phillips_curve is defined on line 47."
      }
    },
    {
      "ref": "fig:nonexistent",
      "ref_command": "\\autoref",
      "suggested_label": null,
      "deepseek_typo_check": {
        "likely_typo": false,
        "suggested_label": null,
        "reason": "No defined label closely matches 'fig:nonexistent'; this appears to reference a figure not yet created."
      }
    }
  ],
  "status": "fail"
}
```

`status` values:
- `"pass"` — all cross-references resolve to defined labels.
- `"fail"` — one or more references are unresolved.

## Notes

- LaTeX compiles silently with unresolved refs (outputs "??"). This skill catches them before compilation.
- For multi-file papers, the skill must follow `\input{sections/intro.tex}` etc. to collect labels from all included files. Read each included path relative to the paper repo root.
- `\Cref` and `\cref` (from `cleveref` package) accept comma-separated key lists; split before checking.
- The `chktex` lint hook (run by PostToolUse) may also flag cross-ref issues. This skill provides the structured JSON output that `chktex` cannot.
- Per ADR 0009, `mcp__pal__chat` routes to DeepSeek via `CUSTOM_API_URL`. Ensure `.env` is populated before running.
