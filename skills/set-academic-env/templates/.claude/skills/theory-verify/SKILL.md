---
name: theory-verify
description: Use when the integrity gate's class-aware coherence layer flags a specific derivation as worth verifying. Wraps SymPy execution with macro-economics conventions, tri-state output, and tool_use_id verification discipline.
allowed-tools: Read Write Edit Bash mcp__pal__chat
metadata:
  version: "0.1.0"
  consumes-skill: sympy
---

# theory-verify

Discipline wrapper for LLM-wrapped SymPy spot-checks. Called by `integrity-gate` layer 3 for specific flagged derivations. Assumes the `sympy` skill is loaded for "how to use SymPy" knowledge.

## CONVENTIONS YOU MUST RECOGNIZE when reading equations

```
CONVENTIONS YOU MUST RECOGNIZE when reading equations:
- Time indices: x_t, x_{t-1}, x_{t+1}. Subscript t is time unless context says otherwise.
- E_t[X] or \mathbb{E}_t[X] is conditional expectation given period-t info.
- Hat (\hat x) means log-deviation from steady state in log-linearized models.
- Tilde (\tilde x) usually means detrended; bar (\bar x) usually means steady state.
- Suppressed time indices: "c = (1-\beta) a + w" in a steady-state context omits
  t-subscripts. CONFIRM from context whether dynamic or steady-state.
- \log is natural log. Lower-case Greek (\beta, \sigma, \phi) usually parameters.
- For verification, declare each symbol explicitly with its semantic role before
  writing SymPy code.
```

## Verification procedure

For each equation passed in:

```
For each equation passed in:

1. State in prose what the equation claims.
2. Identify what's being asserted (definition, FOC, equilibrium, log-lin,
   identity, limit, steady-state).
3. Decide if SymPy verification is appropriate. Many cases are not (welfare
   claims, optimality requiring Lagrangians from prose). If not, return
   {"status": "not_applicable", "reason": "..."}.
4. If appropriate, write SymPy code using sympy.simplify / .expand / .series /
   .solve as needed.
5. CALL THE Bash TOOL TO RUN IT. Do NOT write what you think the output will
   be. Wait for the tool result.
6. Interpret the actual returned output.
7. Emit JSON:
   {
     "claim": "...",
     "sympy_code": "...",
     "sympy_output": "<verbatim from tool>",
     "status": "verified" | "uncertain" | "disagrees" | "not_applicable",
     "reason": "..."
   }

CRITICAL DISCIPLINES:
- Single equation per Bash call. Multi-step derivations: verify each step
  standalone, then verify the substitution; chain status = min(steps).
- 5s timeout: wrap the SymPy call with `timeout 5 python -c "..."` or
  signal-based timeout. SymPy can hang on hard simplifications.
- If you "verified" a trivial tautology (0=0 from simplifying both sides
  via the same lemma), return "uncertain" with reason explaining the
  triviality. False verifies are worse than uncertain.
- IF YOU CAUGHT YOURSELF GUESSING THE OUTPUT, STOP AND RE-RUN THE TOOL.
```

## tool_use_id verification note

```
The harness verifies that every "verified" status corresponds to an actual
Bash tool_use_id in this turn's tool-use trace. Inline-looking-correct output
that wasn't produced by a real tool call is discarded post-hoc. Do not
attempt to fool this check — the verification is defensive against your own
biases, not punitive.
```

## Output JSON schema

```json
{
  "claim": "The equation claims ...",
  "sympy_code": "from sympy import ...\n# SymPy code used",
  "sympy_output": "<verbatim stdout from Bash tool call>",
  "status": "verified" | "uncertain" | "disagrees" | "not_applicable",
  "reason": "Explanation of status judgment."
}
```

Status definitions:
- `"verified"` — SymPy confirms the equation holds (requires actual Bash tool_use_id).
- `"uncertain"` — SymPy result is ambiguous, tautological, or inconclusive.
- `"disagrees"` — SymPy result contradicts the equation's claim.
- `"not_applicable"` — Equation type cannot be verified symbolically (welfare, prose-only optimality, etc.).

## Chain status rule

For multi-step derivations, verify each step standalone. Report each step's JSON individually. The chain's aggregate status = min(steps) using the ordering: `verified` > `uncertain` > `disagrees` > `not_applicable`.

## Symbol declaration template

Before writing SymPy code, declare symbols explicitly:

```python
from sympy import symbols, Function, exp, log

# Symbols with semantic roles:
beta   = symbols('beta', positive=True)   # household discount factor
sigma  = symbols('sigma', positive=True)  # inverse EIS
c_t    = symbols('c_t', real=True)        # consumption (log-deviation from SS)
c_tp1  = symbols('c_tp1', real=True)      # next-period consumption (log-dev)
r_t    = symbols('r_t', real=True)        # real interest rate (log-dev)
```

## Example: log-linearized Euler equation

Input equation: `\hat{c}_t = E_t[\hat{c}_{t+1}] - \frac{1}{\sigma}(\hat{r}_t - E_t[\hat{\pi}_{t+1}] - \rho)`

Step 1 — claim: This is the log-linearized household Euler equation. It states that current consumption equals expected future consumption minus the real interest rate gap.

Step 2 — type: log-linearization of a FOC.

Step 3 — SymPy appropriate? Partially. The log-linearization step itself requires showing the Taylor expansion; the LHS-RHS identity after substitution is checkable.

Step 4 — SymPy code:
```python
from sympy import symbols, simplify

c_t, c_tp1, r_t, pi_tp1, rho, sigma = symbols('c_t c_tp1 r_t pi_tp1 rho sigma')

lhs = c_t
rhs = c_tp1 - (1/sigma) * (r_t - pi_tp1 - rho)

# Check that rhs - lhs simplifies to the expected residual form
residual = simplify(lhs - rhs)
print(residual)
```

Step 5 — CALL THE Bash TOOL. Wait for actual output.

Step 6 — interpret actual output (do not predict).
