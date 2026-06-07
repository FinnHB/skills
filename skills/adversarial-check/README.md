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

- **Blinded handoffs** — agents get the artifact and the original brief, never the reasoning, confidence, or conversation history. The cold start is the mechanism.
- **Symmetric evidence standard** — objections need file/line, command output, or a redone computation to count; rebuttals are held to the same bar. Assertion settles nothing in either direction.
- **Bounded loop** — max 3 rounds, one fresh Skeptic per re-check (a reused agent carries the debate history, recreating the bias the skill removes). Unresolved dissent is reported, not argued into submission.
- **Anti-groupthink** — unanimous fast sign-off is flagged as a caveat, not treated as strong confirmation; the agents escape the conversation's bias but not the model's.

See also: [grill-me](../grill-me/) — the same philosophy pointed the other way: grill-me adversarially interviews *you* about *your* plan; adversarial-check adversarially interviews *Claude* about *its* output.
