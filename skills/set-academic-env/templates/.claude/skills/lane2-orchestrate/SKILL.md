---
name: lane2-orchestrate
description: Use when the integrity gate needs cross-model second opinions on math/model content. Routes via pal__consensus with Claude Opus (for) and DeepSeek V4 Pro (against). Returns aggregated verdict with structured rationale. Mandatory claude_downgrade_rationale field whenever a DeepSeek major flag is downgraded.
allowed-tools: Read mcp__pal__consensus
metadata:
  version: "0.1.0"
---

# lane2-orchestrate

**Lane 2 — Both models reason; Claude orchestrates.** Per ADR 0003: used for content where both a blind-spot risk (use DeepSeek) and a synthesis capability requirement (use Claude Opus) are simultaneously present. Reserved for integrity-gate math/model checks and adversarial review in heavy mode.

## Purpose

Route an integrity-gate evaluation prompt through `pal__consensus` with Claude Opus 4.7 arguing `for` (the paper's claims are sound) and DeepSeek V4 Pro arguing `against` (devil's advocate). Synthesize the two independent reads into a structured verdict. Surface any DeepSeek-only flags prominently. Require explicit written rationale whenever Claude downgrades a DeepSeek-flagged issue.

## Inputs

Provided by the calling skill (Phase 4 integrity-gate or `/refine-heavy`):
- `prompt` — the evaluation question (e.g., "Does the log-linearized Euler equation on page 4 follow correctly from the household optimality condition?").
- `context` — the relevant excerpt from `paper/main.tex` (equations, surrounding prose, any declared notation from `CONSTITUTION.md`). Keep to the relevant section; avoid passing the full document (see note on `pal__analyze` issue #446 below).
- `severity_threshold` — optional; defaults to `"major"`. Flags below this threshold are collected but not returned as `major_flags`.

## Step-by-step

### Step 1 — Invoke pal__consensus

Call `mcp__pal__consensus` with:
- Model A: `claude-opus-4-7`, stance `for`
- Model B: `deepseek-v4-pro`, stance `against`
- Prompt: the `prompt` input.
- Context: the `context` input.

PAL routes the prompt to both models independently and returns both verdicts. Capture:
- `claude_verdict` — the full text of Claude Opus's independent read.
- `deepseek_verdict` — the full text of DeepSeek V4 Pro's independent read.

**Do NOT use `pal__planner`** — broken per Research/09 issue #445.
**Do NOT pass long full-document inputs via `pal__analyze`** — intermittent empty_response on long bodies per Research/09 issue #446. Use `pal__consensus` with a scoped excerpt.

### Step 2 — Extract flags from each verdict

Parse each verdict for flagged issues. A flag is:
- **Major:** a claim, derivation, or identification assumption the model believes is incorrect or unsupported.
- **Minor:** a notation inconsistency, missing definition, or presentation issue that does not affect correctness.

For each flag, record:
- `location` — equation number, line range, or section.
- `issue` — one-sentence description.
- `severity` — `"major"` or `"minor"`.
- `deepseek_only` — `true` if the flag appears in DeepSeek's verdict but not Claude's.

### Step 3 — Synthesize (Claude as orchestrator)

Using the calling model's own reasoning (Claude, the agent running this skill), synthesize the two verdicts:

1. Determine `agreement`:
   - `"agree"` — both models flag the same major issues (or neither flags anything major).
   - `"disagree"` — at least one major flag appears in only one verdict.
   - `"partial"` — mixed: agreement on some issues, disagreement on others.

2. Write a `synthesis` — Claude's call on what matters, in one to three sentences.

3. Produce `major_flags` and `minor_flags` lists.

### Step 4 — Apply downgrade discipline (CRITICAL)

Whenever Claude's synthesis demotes a DeepSeek-flagged **major** issue to **minor** (or discards it entirely), the JSON output MUST include a `claude_downgrade_rationale` field explaining why. This is the only defense against the orchestrator-bias failure mode identified in ADR 0003 — Claude rationalizing away a DeepSeek disagreement without surfacing the reasoning.

**There is no exception to this requirement.** If Claude downgrades and does not provide `claude_downgrade_rationale`, the output is malformed and downstream parsing in Phase 4 will reject it.

The `claude_downgrade_rationale` field is:
- Present and non-empty whenever any `major_flags[*].deepseek_only == true` item was downgraded or removed.
- `null` when no DeepSeek-only major flags were downgraded.

## Output JSON contract

```json
{
  "claude_verdict": "<Full text of Claude Opus's independent read>",
  "deepseek_verdict": "<Full text of DeepSeek V4 Pro's independent read>",
  "agreement": "agree" | "disagree" | "partial",
  "synthesis": "<Claude's call on what is material, 1-3 sentences>",
  "major_flags": [
    {
      "location": "Equation (3), line 47",
      "issue": "The log-linearization drops a second-order term that is non-negligible near the zero lower bound.",
      "severity": "major",
      "deepseek_only": true
    }
  ],
  "minor_flags": [
    {
      "location": "Section 2.1, line 23",
      "issue": "Variable \\hat{c}_t is used before it is defined; definition appears three paragraphs later.",
      "severity": "minor",
      "deepseek_only": false
    }
  ],
  "claude_downgrade_rationale": "<Explanation of why Claude demoted or discarded a DeepSeek-only major flag. Required whenever a deepseek_only major flag was downgraded; null otherwise.>"
}
```

### Example with downgrade

If DeepSeek flags "The identification assumption relies on zero contemporaneous correlation between supply and demand shocks, which is not defended" as major, and Claude's synthesis considers this minor (because the paper cites a standard recursive identification structure), then `claude_downgrade_rationale` must appear:

```json
{
  "claude_downgrade_rationale": "DeepSeek flagged the identification assumption as undefended. Claude's synthesis demoted this to minor because the recursive (Cholesky) identification structure is standard in the SVAR literature and is cited explicitly in the preceding paragraph (Christiano et al. 1999). The assumption is not defended with a formal test, which is worth a note to the author but does not rise to a major structural error."
}
```

## Notes

- This skill is called by the Phase 4 integrity-gate orchestrator, not invoked directly by the user in normal workflow.
- `deepseek_only: true` flags are the primary signal from this skill — they represent cases where DeepSeek found something Claude did not, which is exactly the cross-model blind-spot Lane 2 is designed to catch.
- Per ADR 0003: Lane 2 is the expensive lane. Each `pal__consensus` call runs both models. Use scoped excerpts, not full documents.
- Per ADR 0009, `mcp__pal__consensus` routes DeepSeek via `CUSTOM_API_URL=https://api.deepseek.com/v1`. Ensure `.env` is populated.
- The `pal__thinkdeep` tool can be added in a future iteration for extended-reasoning passes on particularly difficult derivations (MVP+1).
