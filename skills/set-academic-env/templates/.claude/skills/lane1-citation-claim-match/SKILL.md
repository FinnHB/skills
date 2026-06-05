---
name: lane1-citation-claim-match
description: Use after any prose change to verify that each \cite{} is followed by a claim the cited paper actually supports. DeepSeek-only judge; Claude is forbidden as judge here because Claude is the source of both the claim and the citation.
allowed-tools: Read mcp__pal__chat mcp__zotero__zotero_get_item_metadata mcp__zotero__zotero_get_item_fulltext
metadata:
  version: "0.1.0"
---

# lane1-citation-claim-match

**Lane 1 — DeepSeek-only.** No Claude call. Per ADR 0003 (explicitly cited): Claude is the source of both the claim and the citation. Having Claude judge the match reintroduces the exact bias Lane 1 is designed to catch. DeepSeek is the neutral evaluator here.

## Purpose

For each `\cite{key}` in the diff scope, verify that the cited paper's content actually supports the prose claim the citation is attached to. Uses Zotero metadata (abstract) or full text as the evidence base; DeepSeek (`deepseek-v4-flash`) as the judge.

## Inputs

The calling command provides:
- A **diff scope** — list of paragraph texts that changed in the current turn (provided by the Stop hook or calling skill). If no diff scope is provided, scan all paragraphs in `paper/main.tex` (resolved from `paper_config.yaml` `paths.manuscript`) that contain a `\cite{}` command.
- `ALLOWED_KEYS` — from `references-management`, to scope Zotero lookups to this paper's collection.

## Manuscript flattening (always first)

Analyze the **flattened** manuscript: run `.claude/scripts/flatten_tex.py <paths.manuscript>` and use its output (so `\input`'d sections are included). On a single-file manuscript this is identical to the file.

## Step-by-step

### Step 1 — Identify cite-bearing sentences in scope

For each paragraph in the diff scope:
- Find every `\cite{key}`, `\citep{key}`, `\citet{key}` occurrence.
- Extract the **full sentence** containing the cite command (sentence = text ending at the nearest `.`, `!`, or `?`, or the paragraph boundary). For multi-cite `\cite{key1,key2}`, create one check per key using the same sentence.
- Deduplicate (same key + same sentence = one check).

### Step 2 — Fetch cited paper evidence from Zotero

For each (key, sentence) pair:
1. Confirm `key` is in `ALLOWED_KEYS`. If not, skip and note in output as `match: "no_zotero_item"`.
2. Call `mcp__zotero__zotero_get_item_metadata` with the item key. Extract `title` and `abstractNote`.
3. If `abstractNote` is empty or very short (< 50 characters), call `mcp__zotero__zotero_get_item_fulltext` to get the full text. Use the first 3000 characters of full text as the evidence base.
4. Evidence base = abstract if available; truncated full text otherwise.

### Step 3 — Call DeepSeek to judge claim-evidence match

For each (key, sentence, evidence) triple, call `mcp__pal__chat` with model `deepseek-v4-flash`:

**Exact prompt:**
```
Given the in-text claim: '<sentence>' and the cited paper's <abstract or fulltext>, does the cited paper actually support the claim? Output JSON: {"match": "strong"|"weak"|"none"|"unclear", "reason": "<one sentence>"}
```

Where:
- `<sentence>` is replaced with the extracted prose sentence (with the `\cite{...}` command stripped from the text for readability).
- `<abstract or fulltext>` is replaced with the literal text of the abstract or full-text excerpt.

Collect the DeepSeek JSON response. Parse `match` and `reason`.

### Step 4 — Build report

Assemble all checks into the output JSON. Compute summary counts. Set status per rules below.

## Output JSON contract

```json
{
  "checks": [
    {
      "citekey": "gali2008monetary",
      "claim": "Monetary policy shocks generate persistent output gaps under nominal rigidities.",
      "evidence_source": "abstract",
      "match": "strong",
      "reason": "The abstract explicitly states that the model generates persistent output dynamics following monetary shocks under Calvo pricing."
    },
    {
      "citekey": "smith2024capital",
      "claim": "Capital flows respond asymmetrically to global risk appetite.",
      "evidence_source": "fulltext",
      "match": "weak",
      "reason": "The paper studies risk appetite and capital flows but the asymmetry finding is in a sub-sample appendix, not the main result."
    },
    {
      "citekey": "jones2023rates",
      "claim": "Interest rate differentials are the primary driver of exchange rate dynamics.",
      "evidence_source": "abstract",
      "match": "none",
      "reason": "The cited paper argues that risk premia dominate interest rate differentials in driving exchange rates."
    }
  ],
  "summary": {
    "strong": 1,
    "weak": 1,
    "none": 1,
    "unclear": 0,
    "no_zotero_item": 0
  },
  "status": "fail"
}
```

`status` values:
- `"fail"` — `summary.none > 0` (a citation actively contradicts or is unrelated to the claim).
- `"warn"` — `summary.none == 0` AND (`summary.weak > 0` OR `summary.unclear > 0`).
- `"pass"` — all checks are `"strong"`.

## Notes

- **No Claude call anywhere in this skill.** Claude wrote the claims and chose the citations; it cannot be the neutral evaluator. This is non-negotiable per ADR 0003.
- The `deepseek_verdict` field in the Stop-hook AI-tell scan uses the same pattern. Keep the two skills' DeepSeek prompt formats consistent.
- Per ADR 0009, `mcp__pal__chat` routes to DeepSeek directly via `CUSTOM_API_URL`. Ensure `.env` is populated.
- Zotero fulltext availability depends on the paper having an attached PDF and the Zotero MCP's full-text extraction working. If fulltext is unavailable and abstract is short, the check will produce `match: "unclear"` — expected behavior, not a skill error.
- The diff scope is provided by the calling hook (Stop hook for every turn, or the calling refine command). If no scope is provided, the skill falls back to all cite-bearing paragraphs — this is the slower but correct fallback.
