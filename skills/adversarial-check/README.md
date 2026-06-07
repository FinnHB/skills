# adversarial-check

Validates an output Claude produced — a plan, analysis, set of findings, or conclusion — by making Claude the orchestrator of fresh-context adversarial agents. Because subagents start with an empty context window, they can't inherit the conversational reasoning (and confirmation bias) that produced the output. A Skeptic tries to falsify it, a Verifier checks every factual claim against ground truth, and (in full mode) a Rival independently re-derives an answer from the same brief for comparison. Revision rounds are bounded; whatever is still contested at the cap ships as recorded dissent.

## Usage examples

```
/adversarial-check
[checks Claude's most recent substantive output]
```

```
/adversarial-check the migration plan above
```

```
Spin up agents to critically assess these findings.
```

## When to use

- After Claude produces a plan, analysis, or conclusion that decisions will be built on
- When an answer feels confident but hasn't been attacked from outside the conversation
- As the validation pass before acting on multi-step reasoning or data analysis

## Design notes

- **Blinded handoffs** — agents get the artifact and the brief, never the reasoning, confidence, or conversation history. The brief is assembled mechanically (verbatim user statements, not recall), and every prompt carries a canary line that trips if the harness's experimental fork mode has silently broken isolation. The cold start is the mechanism.
- **Symmetric evidence standard** — objections need file/line, command output, or a redone computation to count; rebuttals are held to the same bar, and the orchestrator never retires a contested objection on its own authority — a fresh Adjudicator rules, or it books as dissent.
- **Bounded loop** — max 3 rounds, fresh agents per re-check (a reused agent carries the debate history, recreating the bias the skill removes). Unresolved dissent is reported, not argued into submission; final-round revisions ship flagged as un-rechecked.
- **Anti-groupthink** — unanimous fast sign-off is flagged as a caveat, not treated as strong confirmation; the agents escape the conversation's bias but not the model's.

Provenance: v0.2.0 is the output of running the skill on itself — full mode, 3 rounds, 7 agents, 17 substantiated objections, 16 conceded. See the CHANGELOG for the round-by-round record.

See also: [grill-me](../grill-me/) — the same philosophy pointed the other way: grill-me adversarially interviews *you* about *your* plan; adversarial-check adversarially interviews *Claude* about *its* output.
