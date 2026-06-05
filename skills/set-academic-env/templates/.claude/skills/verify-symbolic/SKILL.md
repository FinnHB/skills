---
name: verify-symbolic
description: Use for deeper SymPy verification of a specific equation, equation range, or section. Goes beyond the integrity-gate's layer-3 spot-checks by pulling in the full derivation chain context. Approval-gated for scope > 10 equations.
allowed-tools: Read Write Edit Bash mcp__pal__chat
metadata:
  version: "0.1.0"
---

# /verify-symbolic [target]

Deeper SymPy verification beyond the integrity-gate's layer-3 spot-checks. Pulls the full prior derivation chain as context for each equation.

**Target formats:**
- Single equation: `eq:euler` (equation label)
- Range: `eq:foc..eq:market-clearing`
- Section: `section:3.2`

If no target specified, ask the user which equation(s) to verify.

## Step 1 — Scope check

Count the target equations:
- If target is a single equation → proceed without approval gate.
- If target is a range or section with > 10 equations → the Phase 7 heavy-task approval hook will fire automatically. Do not bypass it.

## Step 2 — Load derivation chain

Resolve the manuscript path from `paper_config.yaml` `paths:` (default `paper/main.tex`); do not assume the repo root.

For each target equation:
1. Read `paper/main.tex` and identify the equation by its label.
2. Walk backward through `paper/main.tex` to collect the full prior derivation chain: all equations and prose that the target equation references or derives from, going back to the household/firm problem setup or the stated identification assumption.
3. Read the relevant Declared block from `THEORY_PRIORS.md` (model class, parameter list).
4. Include context: 500 chars before and after each target equation.

This is the key difference from the integrity-gate layer-3 spot-checks (which use only ~300 chars of context). Full chain context reduces false `uncertain` results.

## Step 3 — Invoke theory-verify per equation

For each target equation, invoke the `theory-verify` skill with the full derivation chain context.

Apply the single-equation-per-Bash-call discipline from `theory-verify/SKILL.md`. Chain the verifications step-by-step for multi-step derivations.

## Step 4 — Write report

Write a verification report to `worklog/review/verify-symbolic-<timestamp>.md`:

```markdown
# Symbolic Verification Report
**Target:** <target>
**Timestamp:** <ISO>
**Mode:** /verify-symbolic (deep chain context)

## Results

### <equation-label>
**Claim:** <what the equation claims>
**Chain context:** <brief description of derivation path>
**SymPy status:** verified | uncertain | disagrees | not_applicable
**Reason:** <explanation>

<repeat for each target equation>

## Summary
- Verified: <N>
- Uncertain: <M>
- Disagrees: <K>
- Not applicable: <J>

**Overall: <pass if no disagrees | warn if any uncertain | fail if any disagrees>**
```

Print to conversation: "Verification complete. Report at `worklog/review/verify-symbolic-<timestamp>.md`. Status: <overall>."
