---
name: adversarial-check
description: Validate a plan, analysis, finding, or conclusion Claude produced by spawning fresh-context adversarial agents (skeptic, verifier, rival) that attack it with evidence; orchestrate bounded revision rounds until objections are resolved or logged as dissent. Use when the user wants output validated by agents, mentions "adversarial check", asks to stress-test results/findings/conclusions with agents, or asks for agents to critically assess output.
---

# Adversarial check

You produced an output — a plan, analysis, set of findings, or conclusion — and your context window is now the problem: it contains the reasoning that led there, so you can no longer evaluate it neutrally. This skill makes you the orchestrator of agents that do NOT share that context. Their cold start is the entire mechanism; every rule below protects it.

## 1. Scope the check

- **Artifact**: the thing under attack — usually your most recent substantive output, or whatever the user names. If ambiguous, ask.
- **Claim**: restate the artifact's core claim in one sentence, ending with what it would mean for it to be *wrong*. If you can't, the artifact isn't checkable yet — say so and tighten it first.
- **Effort** (proportional; don't burn a panel on a trivial check):
  - **light** — Skeptic + Verifier, single round. Default for self-contained outputs with limited blast radius.
  - **full** — all three roles, up to 3 rounds. Default for plans, analyses, and conclusions that decisions will be built on.

## 2. Blinding protocol — never break it

Each subagent prompt is self-contained and includes ONLY:

- the artifact verbatim (or file paths to it),
- the original inputs/brief that produced it,
- the role's obligation (§3).

Never include your reasoning, your confidence, the conversation history, or hints about what you expect them to find. "I concluded X because Y — check it" is contaminated; "Here is X — falsify it" is not. If an agent asks why you believe something, that is the debate working: answer with evidence, not narrative.

## 3. The roles

Spawn in parallel as `general-purpose` agents — they need tools, because objections must come from evidence, not vibes. Verbatim obligations:

- **Skeptic** — "Your job is to falsify this. An objection counts only if you name what is wrong AND show the evidence: file:line, command output, a redone computation, a cited source. List unsubstantiated unease separately as soft concerns. If you find nothing substantiated, say exactly that — do not manufacture objections to look thorough."
- **Verifier** — "Check every factual claim in this against ground truth: run the code, read the files, redo the numbers, search for external claims. Report each claim as confirmed / contradicted (with evidence) / uncheckable. Do not editorialize — verify."
- **Rival** (full mode only) — receives ONLY the inputs/brief, not the artifact: "Produce your own best answer to this." Where the Rival's independent answer diverges from yours, that divergence is a finding to triage like any objection.

## 4. Triage and revise

For each substantiated objection, contradiction, or divergence:

- **Evidence against your output → revise it.** The goal is a correct output, not a defended one. Default to conceding; you are the most biased participant in the room.
- **You believe the agent is wrong → rebut with evidence** of the same standard you demanded of them. Assertion is not rebuttal.
- **Soft concerns and uncheckables → log them** for the report. Do not loop on them.

## 5. Loop, bounded

- Material revisions trigger ONE re-check round: a **new** Skeptic, cold, on the revised artifact. Never reuse an agent across rounds — it now carries the debate history, which is exactly the contamination this skill exists to remove.
- A round ends when every agent has signed off or had its objection resolved/rebutted with evidence.
- **Hard cap: 3 rounds.** Still contested at the cap → ship with the dissent in the report. An unresolved objection is a finding, not a failure.

## 6. Report

Agents' final messages are invisible to the user — the report is mandatory, in this shape:

```
## Adversarial check — <one-line claim>
**Verdict:** upheld | revised | overturned   (N rounds, M agents)

**Survived** — what stood unchanged, and which attacks it withstood
**Revised** — what changed, and which objection forced each change
**Unresolved dissent** — objections standing at the cap, both sides' evidence
**Caveats** — soft concerns, uncheckable claims, and flags (below)
```

Anti-groupthink flag: unanimous fast sign-off in round 1 is a **yellow flag, not strong confirmation** — the agents escaped your context, but not your model's biases. Record it in Caveats; never upgrade confidence because of it.
