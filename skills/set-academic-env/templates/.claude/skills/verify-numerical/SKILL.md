---
name: verify-numerical
description: Use to check numerical solvability of the paper's model. Translates from paper/main.tex to Dynare (NK/RBC) or Julia (HANK), runs the solver, reports steady state + Blanchard-Kahn verdict + optional IRFs. ALWAYS approval-gated. Refuses model classes not supported in MVP.
allowed-tools: Read Write Edit Bash mcp__pal__chat
metadata:
  version: "0.1.0"
---

# /verify-numerical [target]

Numerical solvability check. **Always triggers heavy-task approval** (Phase 7 hook) — numerical solves can take minutes.

**Target formats:**
- `block:model` — the model block
- `section:3` — a section containing model equations
- (omit) — full model from `paper/main.tex`

## Step 0 — Check system dependencies

Before doing anything else:
```bash
command -v dynare &>/dev/null || echo "DYNARE_MISSING"
command -v julia &>/dev/null || echo "JULIA_MISSING"
```

If Dynare is missing and the model class is NK-DSGE or RBC, refuse:
> "Dynare is not installed. Install it before running /verify-numerical:
> - macOS: `brew install dynare` (or via Octave/MATLAB)
> - See SETUP.md §'Optional (only if you'll use /verify-numerical)'
> Aborting."

If Julia is missing and model class is HANK, warn that HANK verification is experimental and will fail at solve time.

## Step 1 — Read model class

Read `THEORY_PRIORS.md`'s Declared block. Extract `model_class`.

**Supported in MVP:**
- `NK-DSGE` (any variant, including two-country NK, NK-FTPL) → Dynare path
- `RBC` → Dynare path
- `HANK` → Julia path (experimental — warn user)
- Anything else → refuse:
  > "Model class '<class>' is not supported by /verify-numerical in MVP. Supported: NK-DSGE, RBC (Dynare), HANK (experimental, Julia). Manual replication required."

## Step 2 — Translate to solver format (LLM-assisted)

Resolve the manuscript path from `paper_config.yaml` `paths:` (default `paper/main.tex`); do not assume the repo root.

For Dynare path:
1. Read the target section from `paper/main.tex`.
2. Using `mcp__pal__chat` with `deepseek-v4-flash`, translate to Dynare `.mod` format:
   - Extract variable declarations (`var`, `varexo`, `parameters`)
   - Extract model equations block
   - Extract steady-state values if present
   - Mark any uncertain translations with `% TRANSLATION-UNCERTAIN: <reason>`
3. Write draft `.mod` to `worklog/review/verify-numerical-<timestamp>.mod`.
4. Report to user: "<N> TRANSLATION-UNCERTAIN markers. Review before interpreting results."

For Julia/HANK path: follow the same pattern with Julia syntax; flag as experimental in the report.

## Step 3 — Run solver with timeout

**5-minute timeout** on the solver call.

For Dynare:
```bash
timeout 300 dynare worklog/review/verify-numerical-<timestamp>.mod 2>&1
```

For Julia:
```bash
timeout 300 julia -e "using Pkg; Pkg.activate(\".\"); include(\"worklog/review/verify-numerical-<timestamp>.jl\")" 2>&1
```

Capture ALL output — both stdout and stderr.

If timeout fires: report "Dynare/Julia solve timed out after 5 minutes." Include partial output if any.

## Step 4 — Write report

Write `worklog/review/verify-numerical-<timestamp>.md`:

```markdown
# Numerical Verification Report
**Target:** <target>
**Timestamp:** <ISO>
**Model class:** <class>
**Solver:** Dynare <version> | Julia <version> (experimental)

## Translation
**TRANSLATION-UNCERTAIN markers:** <N>
<list uncertain translations, if any>

## Solver output (verbatim)
```
<full raw Dynare/Julia output — do NOT summarize or interpret here>
```

## Blanchard-Kahn conditions
<extract B-K verdict from Dynare output, or "not determined" if timed out>

## Steady state
<extract steady-state values if reported, or "not computed">

## IRFs
<if computed; "not requested" otherwise>

## Verdict
<pass if solve succeeded + B-K satisfied | fail if B-K violated | error if Dynare crashed>
```

Print to conversation: "Numerical verification complete. Report at `worklog/review/verify-numerical-<timestamp>.md`. B-K verdict: <verdict>."
