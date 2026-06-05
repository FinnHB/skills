---
name: lane1-ai-tell-scan
description: Use on every Stop hook to scan Claude-generated paragraphs for AI-tell vocabulary from the berenslab/llm-excess-vocab list. DeepSeek judges context-appropriateness of each hit. Never fails — AI-tells are stylistic, not correctness issues.
allowed-tools: Read mcp__pal__chat
metadata:
  version: "0.1.0"
---

# lane1-ai-tell-scan

**Lane 1 — DeepSeek-only.** No Claude call. Per ADR 0003: Claude generated the prose being judged; Claude is not the neutral evaluator for its own stylistic choices.

## Purpose

Scan paragraphs produced by Claude in the current turn against the `berenslab/llm-excess-vocab` word list. Flag vocabulary hits. Call DeepSeek to judge whether each hit is genuinely AI-tell in context (some flagged words are occasionally warranted). Report findings for the author to act on. **Never `"fail"` — this is a stylistic advisory, not a correctness gate.**

## Inputs

- A **diff scope**: the text of paragraphs changed or added in the current turn, provided by the Stop hook. Each paragraph is passed as an element of a list.
- The excess-vocab list: read from `excess-vocab.txt` in the same directory as this SKILL.md (`.claude/skills/lane1-ai-tell-scan/excess-vocab.txt`).

## Manuscript flattening (always first)

Analyze the **flattened** manuscript: run `.claude/scripts/flatten_tex.py <paths.manuscript>` and use its output (so `\input`'d sections are included). On a single-file manuscript this is identical to the file.

## Step-by-step

### Step 1 — Load vocabulary list

Read `excess-vocab.txt` (same directory). Strip comment lines (starting with `#`) and blank lines. Build a set of lowercase vocabulary terms. These include single words and some two-word phrases (e.g., "in conclusion", "worth noting").

### Step 2 — Scan each paragraph

For each paragraph in the diff scope:
- Lowercase the paragraph text.
- For each vocabulary term in the excess-vocab set: check whether the term appears as a whole word (or exact phrase for multi-word terms). Use word-boundary matching — do not flag "actually" inside "factually".
- For each hit: record the paragraph index (1-based), the matched word/phrase, and a 60-character context window centered on the match.

If no hits in a paragraph, move to the next. Collect all hits across all paragraphs.

### Step 3 — Call DeepSeek to judge context-appropriateness

For each hit, call `mcp__pal__chat` with model `deepseek-v4-flash`:

```
In an academic economics paper, the word/phrase "<word>" appears in this passage: "<context>". Is this usage a genuine AI writing tell (overused, non-specific, corporate/consultancy tone), or is it warranted by the context? Output JSON only: {"verdict": "remove"|"acceptable"|"unclear", "suggestion": "<replacement word or phrase, or null if acceptable>"}
```

Where:
- `<word>` is the matched vocabulary term.
- `<context>` is the 60-character window (or full sentence if shorter).

Collect the DeepSeek response. Parse `verdict` and `suggestion`.

### Step 4 — Build report

Assemble the output JSON. Count `paragraphs_scanned` (total paragraphs in diff scope). Count `tells_flagged` (hits where `verdict != "acceptable"`). Set `status: "warn"` if any tells were flagged; `status: "pass"` otherwise.

## Output JSON contract

```json
{
  "paragraphs_scanned": 8,
  "tells_flagged": [
    {
      "paragraph": 3,
      "word": "delve",
      "context": "...we delve into the intricate dynamics of...",
      "deepseek_verdict": "remove",
      "suggestion": "examine"
    },
    {
      "paragraph": 5,
      "word": "crucial",
      "context": "...plays a crucial role in determining...",
      "deepseek_verdict": "acceptable",
      "suggestion": null
    },
    {
      "paragraph": 7,
      "word": "leverage",
      "context": "...central banks leverage their balance sheets...",
      "deepseek_verdict": "remove",
      "suggestion": "use"
    }
  ],
  "status": "warn"
}
```

`status` values:
- `"pass"` — no tells flagged (either no hits, or all hits judged `"acceptable"` by DeepSeek).
- `"warn"` — one or more hits judged `"remove"` or `"unclear"` by DeepSeek.

Note: `tells_flagged` includes all hits including `"acceptable"` ones, so the author can review the full picture. Filter to `deepseek_verdict != "acceptable"` for the actionable list.

## Notes

- **Status is never `"fail"`.** AI-tells are stylistic, not correctness issues. The gate is advisory only.
- The `excess-vocab.txt` stub covers ~60 high-frequency AI-tell words. The full `berenslab/llm-excess-vocab` list is ~900 words. Update `excess-vocab.txt` before Phase 10 real-usage validation per the header comment in that file.
- Per Research/06 §B.2: co-occurrence patterns convict more than single words ("delve into the intricate", "underscores the pivotal"). The current scan is unigram-only. Co-occurrence pattern scanning is MVP+1.
- Per ADR 0009, `mcp__pal__chat` routes to DeepSeek via `CUSTOM_API_URL`. Ensure `.env` is populated before running.
- The Stop hook invokes this skill on every turn where Claude edited prose. It does not run on turns where Claude only read files or ran tools without editing `paper/main.tex`.
