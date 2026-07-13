# Changelog

## 2026-07-13 — v0.1.0

Initial release. A user-invoked procedural skill that makes the session model a pure orchestrator.

Design settled in a grill-me session and grounded in a research brief (Anthropic's multi-agent
research system, the MAST failure taxonomy, model-routing and LLM-judge literature). Key decisions:

- **User-invoked** (`disable-model-invocation: true`) — orchestration is a deliberate, expensive
  act; the model should not reach for it autonomously.
- **Shaping gate** with authority to push back (`Y/N`) when a task doesn't warrant orchestration —
  over-decomposition is the documented #1 orchestrator failure.
- **Split by object of work, never by phase** — the anti-telephone-game rule.
- **Tier routing by task property** with canonical model IDs pinned in `references/model-routing.md`;
  Sonnet default, Opus for hard reasoning, Haiku for low-risk/checkable, Fable orchestrator-only.
  Prefer a tier upgrade over a token-budget increase.
- **Five-field spawn brief** (objective / output format / tools / boundaries / model+effort);
  boundaries are the load-bearing anti-overlap field.
- **Diagnose-cause-first remediation ladder** — ~79% of failures are spec/coordination, not
  capability, so richer spec precedes bigger model.
- **Proportional three-rung verification** — fresh verifier (everyday), `/adversarial-check`
  (reserved, "might be wrong", requires a strong stated argument), `/ask-the-panel --council`
  (reserved, "might be blinkered").
- **Autonomous to the end** with a non-binding pre-flight plan for oversight, live per-stage
  narration, and a final report table built from real `subagent_tokens` / `duration_ms` receipts.
- Interactive `Agent`-tool choreography is the spine; `Workflow` is an escape hatch for big uniform
  fan-outs. `references/harness-assumptions.md` records the spawn mechanics as a dated quarantine —
  notably that `effort` is a Workflow opt, not an Agent-tool param.
