# orchestrate

Turn the session model into a pure **orchestrator**: it decomposes a task into independent
legs, delegates every piece of *execution* to subagents chosen by tier, choreographs the waves,
verifies proportionally, and synthesises the result — but never does the work itself.

User-invoked only (`/orchestrate`). You launch the session in an orchestrator-grade model
(Fable or Opus) and invoke the skill by hand; it routes the **subagents**, not itself.

## When to use it

When a task genuinely wants fan-out — **independent parallel work**, **context isolation**, or
**specialisation/verification** — and you want it run with discipline rather than an ad-hoc
scatter of agents. The skill's first act is a gate: if the task is really one coupled job, it
pushes back and asks whether to orchestrate at all, because multi-agent work costs 3–10× the
tokens and loses to a single agent on tightly-coupled reasoning.

## What it does

1. **Gate** — carves the task into independent *legs* (split by object of work, never by phase);
   pushes back if orchestration isn't warranted.
2. **Plan** — stamps each leg with a model tier (Haiku / Sonnet / Opus; Fable is orchestrator-only)
   and effort, right-sizes the fan-out, and writes a non-binding pre-flight plan for oversight.
3. **Spawn** — every subagent gets a five-field brief: objective, output format, tools/sources,
   boundaries, model+effort.
4. **Run waves** — parallel cohorts with barrier-join-then-replan; budgets and loop caps guard
   against runaway cost.
5. **Diagnose → remediate** — when a leg falls short, diagnose the *cause* before reaching for a
   lever (richer spec / tier-up / split / verify), because most failures are spec, not capability.
6. **Verify** — proportional, three rungs: a fresh blackbox verifier (everyday), `/adversarial-check`
   (reserved, for "might be wrong"), `/ask-the-panel --council` (reserved, for "might be blinkered").
7. **Report** — one synthesis paragraph plus a table of every agent (model, effort, what it did,
   tokens, duration) built from real spawn receipts.

## Files

- `SKILL.md` — the procedure.
- `references/model-routing.md` — tier IDs, defaults, and the counterintuitive routing heuristics.
- `references/harness-assumptions.md` — dated quarantine of the spawn mechanics the skill leans on.

## Related

- [adversarial-check](../adversarial-check/) — verification rung 2 (fresh agents with tools, evidence).
- [ask-the-panel](../ask-the-panel/) — verification rung 3 (cross-lineage council).
- [writing-great-skills](../writing-great-skills/) — the authoring principles this skill follows.
