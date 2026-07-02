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

- **Blinded handoffs** — agents get the artifact and the brief, never the reasoning, confidence, or conversation history. Prompts are assembled from fill-in-the-blank templates (`references/spawn-templates.md`) so a dropped canary line is a visible hole; the brief is built mechanically (verbatim user statements with locators, not recall). The cold start is the mechanism.
- **Symmetric evidence standard** — objections need file/line, command output, or a redone computation to count; rebuttals are held to the same bar. The Skeptic's substantiated/soft classification is binding (the orchestrator can't launder an objection down to a "soft concern"), and a contested objection is settled by a fresh Adjudicator or booked as dissent — never by the orchestrator's own authority.
- **Cross-lineage adjudication** — the Adjudicator routes through [ask-the-panel](../ask-the-panel/) (`adjudicate` mode) by default, because self-preference bias in LLM judges tracks fluency, not labels — it survives blinding, so a same-lineage judge tilts toward the orchestrator's own rebuttal. The Adjudicator is the one role this works for: it judges only presented evidence and needs no tools. Falls back to a local agent (recorded as a same-lineage caveat) when there's no OpenRouter key, the user declines the privacy confirmation, or the content can't leave the machine.
- **Bounded loop** — max 3 rounds (2 in light mode), fresh agents per re-check (a reused agent carries the debate history, recreating the bias the skill removes). Unresolved dissent is reported, not argued into submission; final-round revisions ship flagged as un-rechecked. This matches the multi-agent-debate literature: quality degrades over rounds, and agreement pressure flips correct answers more often than wrong ones.
- **Receipts, not vibes** — full mode is the default (the author choosing "light" is the one judgment the skill says the author can't make neutrally — downgrades must be argued), a cost pre-flight runs before the first spawn, and the report's Stats quote the harness's actual per-spawn token/duration returns. A report that can't list its spawns describes a check that didn't run.
- **Cost control** — every spawn passes `model: sonnet` (inheriting the parent model means paying flagship rates for fetch-and-compare work), and re-check Verifiers check only the claims a revision changed. When the session itself runs on sonnet, the report flags zero model diversity. These defaults exist because the v0.2.0 self-run cost ~330k subagent tokens at the opus rate.
- **Staleness fails loud** — every harness-specific fact the skill leans on (injection behavior, fork mode, model resolution, spawn receipts) lives in one dated catalog, `references/harness-assumptions.md`, checked pre-flight: if a named knob no longer exists, the check halts rather than proceeding on a stale assumption.

Provenance: v0.2.0 is the output of running the skill on itself — full mode, 3 rounds, 7 agents, 17 substantiated objections, 16 conceded. v0.5.0 is the output of an orchestrated external review (literature research, harness-fact verification, red-team) plus its own validation run; the CHANGELOG entry's run record carries the receipts.

See also:
- [grill-me](../grill-me/) — the same philosophy pointed the other way: grill-me adversarially interviews *you* about *your* plan; adversarial-check adversarially interviews *Claude* about *its* output.
- [ask-the-panel](../ask-the-panel/) — reasoning-level second opinions from non-Anthropic models; adversarial-check uses it for cross-lineage adjudication, and suggests it as a follow-up when a check ends in suspiciously unanimous sign-off.
