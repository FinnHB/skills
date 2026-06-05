---
name: integrity-gate
description: Use after any change to paper/main.tex's theory or model sections. Runs the three-layer integrity gate (notational, class-aware, SymPy spot-checks). Halts on layer-1 failure in heavy mode; surfaces flags in light mode.
allowed-tools: Read Write mcp__pal__consensus
metadata:
  version: "0.1.0"
  consumes-skills: theory-verify, lane2-orchestrate
---

# integrity-gate

Three-layer integrity gate per ADR 0002. Called by `/refine-heavy`, `/refine-light`, and ad-hoc verification.

## Inputs

- `mode` — `"heavy"` or `"light"`. Heavy mode halts on layer-1 failure (with auto-loop up to 2 retries). Light mode surfaces flags and continues.
- `section` — optional; restricts gate to a named section. If omitted, runs on full `paper/main.tex` (resolved from `paper_config.yaml` `paths.manuscript`; do not assume the repo root).
- `retry_count` — internal; do not set externally. Used by auto-loop logic.

## Manuscript flattening (always first)

Analyze the **flattened** manuscript: run `.claude/scripts/flatten_tex.py <paths.manuscript>` and use its output (so `\input`'d sections are included). On a single-file manuscript this is identical to the file.

## Layer 1 — Notational coherence (always-on, Claude-only)

Parse `paper/main.tex` (or the specified section). Extract every equation environment (`equation`, `align`, `gather`, `multline`, `eqnarray`, and their starred variants).

For each equation:
1. Extract every symbol on the RHS.
2. Check that each symbol is either:
   - Declared in a prior equation or in `THEORY_PRIORS.md`'s Declared block, OR
   - A known primitive: time index (`t`, `t-1`, `t+1`), standard operators (`\mathbb{E}`, `\log`, `\exp`, `\sum`, `\prod`, `\int`), standard Greek parameters (`\alpha`, `\beta`, `\gamma`, `\sigma`, `\phi`, `\theta`, `\lambda`, `\mu`, `\rho`, `\delta`, `\kappa`, `\eta`, `\pi`), or standard math constants (`1`, `0`).
3. Check system well-posedness: count endogenous variables vs. equations. A balanced system has `# equations == # endogenous variables`. Flag imbalance as a warning (not a failure) unless it is severe (off by more than 1).

Layer 1 output:
```json
{
  "layer": 1,
  "status": "pass" | "fail",
  "undefined_symbols": ["\\hat{z}_t", "\\Omega"],
  "wellposedness": {
    "eqns": 5,
    "vars": 5,
    "balanced": true
  },
  "fail_details": ["Symbol \\hat{z}_t used in eq (3) but never declared"]
}
```

`status: fail` if any `undefined_symbols` is non-empty.

## Layer 2 — Class-aware coherence (always-on, Lane 2 via PAL)

**Read `THEORY_PRIORS.md` first.**

If `model_class_status: candidate` → skip layer 2 entirely:
```json
{
  "layer": 2,
  "status": "skipped",
  "reason": "model class not yet declared — THEORY_PRIORS.md model_class_status is candidate"
}
```

Otherwise, invoke `lane2-orchestrate` with:
- `prompt`: `"Given declared model class <class from THEORY_PRIORS.md>, do the equations in this section match the canonical form for that class? Flag any deviation, but do not fail on deviation — the author may be developing a novel variant. Output structured flags."`
- `context`: the relevant section(s) of `paper/main.tex` plus the Declared block from `THEORY_PRIORS.md`.

Wrap the `lane2-orchestrate` JSON output in the layer-2 envelope:
```json
{
  "layer": 2,
  "status": "pass" | "warn" | "fail",
  "claude_verdict": "<from lane2-orchestrate>",
  "deepseek_verdict": "<from lane2-orchestrate>",
  "agreement": "<from lane2-orchestrate>",
  "flags": "<major_flags + minor_flags from lane2-orchestrate>",
  "claude_downgrade_rationale": "<from lane2-orchestrate, null if not applicable>"
}
```

**Status mapping from lane2-orchestrate output:**
- `major_flags` non-empty → `"warn"` (deviation, not failure — layer 2 never returns `"fail"` per ADR 0002).
- `major_flags` empty → `"pass"`.

Note: Layer 2 flags deviations from canonical forms; it does NOT fail on them. The user may be building a novel model variant.

## Layer 3 — LLM-wrapped SymPy spot-checks (always-on, augmentation)

Read layer-2 output. For each item in `major_flags` where `deepseek_only: true` or where the flag concerns a specific equation (has an `equation_label`), invoke `theory-verify` with:
- The specific equation(s) from `paper/main.tex`.
- Surrounding context (2–3 lines of prose before/after).
- The flag's `issue` text as the question to answer.

If layer-2 status was `skipped` or `pass` with no flags, still run spot-checks on equations that involve log-linearization steps or FOC derivations (these are high-value targets). Limit to the 3 most complex equations if the section is long.

Aggregate results:
```json
{
  "layer": 3,
  "status": "pass" | "warn" | "fail",
  "spot_checks": [
    {
      "equation_label": "eq:euler",
      "theory_verify_output": {
        "claim": "...",
        "sympy_code": "...",
        "sympy_output": "...",
        "status": "verified" | "uncertain" | "disagrees" | "not_applicable",
        "reason": "..."
      }
    }
  ]
}
```

**Status aggregation:**
- Any `disagrees` → layer 3 `"fail"`.
- Any `uncertain`, no `disagrees` → layer 3 `"warn"`.
- All `verified` or `not_applicable` → layer 3 `"pass"`.

## Auto-loop on layer-1 failure (heavy mode only)

If `layer_1.status == "fail"` AND `mode == "heavy"` AND `retry_count < 2`:

1. Announce in conversation: `"Layer 1 failed: <fail_details summary>. Retrying with stricter constraints (attempt <retry_count + 1>/2)."`
2. Re-invoke the most recent rewrite step with the `fail_details` as additional guidance: `"The following symbols were used but never declared: <list>. Declare them in THEORY_PRIORS.md or define them in the preceding prose before using them in equations."`
3. Re-run the integrity gate with `retry_count = retry_count + 1`.

After 2 retries with continuing layer-1 failure: halt. Surface the layer-1 failures for human review. Do NOT attempt a third auto-loop.

Light mode: NEVER auto-loop. Surface layer-1 failures as flags and continue.

## Final aggregated output

```json
{
  "run_id": "<ISO timestamp + 4-char random suffix>",
  "timestamp": "<ISO 8601>",
  "mode": "heavy" | "light",
  "layer_1": {
    "layer": 1,
    "status": "pass" | "fail",
    "undefined_symbols": [],
    "wellposedness": {"eqns": 0, "vars": 0, "balanced": true},
    "fail_details": []
  },
  "layer_2": {
    "layer": 2,
    "status": "pass" | "warn" | "skipped",
    "claude_verdict": null,
    "deepseek_verdict": null,
    "agreement": null,
    "flags": [],
    "claude_downgrade_rationale": null
  },
  "layer_3": {
    "layer": 3,
    "status": "pass" | "warn" | "fail",
    "spot_checks": []
  },
  "overall_status": "pass" | "warn" | "fail",
  "blocks_render": true | false
}
```

**`overall_status` logic:**
- `"fail"` if layer_1 is `fail` (after exhausting retries in heavy mode) OR layer_3 is `fail`.
- `"warn"` if layer_2 is `warn` OR layer_3 is `warn` (and no layer is `fail`).
- `"pass"` otherwise.

**`blocks_render`:** `true` if `overall_status == "fail"` AND `mode == "heavy"`. Used by `/signoff` (Phase 9) and render hooks (Phase 7). Light mode never blocks render.

## Quick reference: failure modes and responses

| Situation | Layer | Action |
|---|---|---|
| Symbol used before declaration | L1 fail | Auto-loop (heavy, ≤2) or surface (light) |
| Equation count ≠ variable count by >1 | L1 warn | Surface, never fail |
| Model deviates from declared class | L2 warn | Surface flags, continue |
| Model class not yet declared | L2 skipped | Surface note, continue |
| SymPy disagrees with claimed identity | L3 fail | Surface, blocks_render in heavy |
| SymPy returns ambiguous/trivial result | L3 warn | Surface, continue |
| Equation type not SymPy-verifiable | L3 not_applicable | Skip, no flag |

## Step — emit machine-readable sidecar

After writing the human `.md` review report, also write a lean JSON sidecar at the same path
but with a `.json` extension: `worklog/review/<command>-<ts>.json`.

**Schema (single source of truth):**
```json
{
  "ts": "2026-05-31T14:23:00Z",
  "command": "/refine-heavy",
  "args": {"section": 3},
  "manuscript_sha": "<git rev of paths.manuscript at run end, or omit if no git>",
  "integrity_gate": {"layer_1": "pass|warn|fail", "layer_2": "pass|warn|skipped", "layer_3": "pass|warn|fail", "overall": "pass|warn|fail"},
  "lane_1": {"citation_existence": "pass|fail", "claim_match": "pass|warn|fail", "cross_ref": "pass|fail", "ai_tells": "pass|warn"},
  "open_tktk": 2,
  "report": "worklog/review/refine-20260531-142300.md",
  "diff": "worklog/transcripts/refine-20260531-142300.diff"
}
```

**Rules — strictly follow:**
- Include a key **only** when the run actually produced that value. Omit `lane_1` if Lane 1 did
  not run; omit `diff` if none was produced; omit `manuscript_sha` if the repo has no git HEAD.
- **Never write `null` or `"unknown"` placeholders.** If you don't have a fact, omit the field.
- No token counts, no model list, no per-tool-call entries. One flat record per command run.
- `integrity_gate` values map directly from the gate's `overall_status` and per-layer `status`
  fields computed above.
- `lane_1` values map from each Lane 1 skill's returned verdict.
- `open_tktk` is the count of `% TKTK:` occurrences in `paths.manuscript` at run end (omit
  if you did not scan for them).

Use `python3 -c` to serialize the JSON:
```python
import json, subprocess, datetime

sidecar = {
    "ts": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "command": command,   # e.g. "/refine-heavy"
    "integrity_gate": {
        "layer_1": layer1_status,
        "layer_2": layer2_status,
        "layer_3": layer3_status,
        "overall": overall_status
    },
    "report": report_path
}
# Only add fields you actually have:
if args:
    sidecar["args"] = args
if manuscript_sha:
    sidecar["manuscript_sha"] = manuscript_sha
if lane_1_ran:
    sidecar["lane_1"] = lane1_verdicts
if diff_path:
    sidecar["diff"] = diff_path
if open_tktk is not None:
    sidecar["open_tktk"] = open_tktk

print(json.dumps(sidecar, indent=2))
```

Write the sidecar next to the `.md` report:
```bash
python3 -c "..." > worklog/review/<command>-<ts>.json
```

The sidecar is the **machine source of truth**. The `.md` report is human-facing.
Both are written by the skill; hooks read only the `.json`.

## Notes

- This gate is defensive, not punitive. Layer 2 flags deviations; it never fails on them. Layer 3 `disagrees` is the only path to a hard fail via SymPy.
- `deepseek_only: true` flags from lane2-orchestrate are the highest-value signal from layer 2. Surface them prominently.
- Do NOT cache gate results across runs. The gate runs fresh each time.
- Do NOT call `/verify-symbolic` or `/verify-numerical` from within this gate (those are separate Phase 8 commands invoked by the user).
