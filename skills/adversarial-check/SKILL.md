---
name: adversarial-check
description: Validate a plan, analysis, finding, or conclusion — usually Claude's own, sometimes the user's — by spawning fresh-context adversarial agents (skeptic, verifier, rival) that attack it with evidence; orchestrate bounded revision rounds until objections are resolved or logged as dissent. Use when the user wants output validated by agents, mentions "adversarial check", asks to stress-test results/findings/conclusions with agents, or asks for agents to critically assess output.
---

# Adversarial check

An output is under check — a plan, analysis, set of findings, or conclusion; usually yours, sometimes the user's. When it is yours, your context window is the problem: it contains the reasoning that led there, so you can no longer evaluate it neutrally. This skill makes you the orchestrator of agents that do NOT share that context. Their cold start is the core mechanism; every rule below protects it.

## 1. Scope the check

- **Artifact**: the thing under attack — usually your most recent substantive output, or whatever the user names. If ambiguous, ask. Note who owns it: your own output gets revised when objections land (§4); a user-authored artifact gets findings reported, never edits, unless they ask. Freeze the version under attack — no edits while agents are reading it.
- **Claim**: restate the artifact's core claim in one sentence, ending with what it would mean for it to be *wrong*. If you can't, the artifact isn't checkable yet — say so and tighten it first.
- **Effort** (proportional; don't burn a panel on a trivial check):
  - **light** — Skeptic only; add the Verifier if the artifact makes checkable factual claims. One attack round. Default for self-contained outputs with limited blast radius.
  - **full** — all three roles, up to 3 rounds. Default for plans, analyses, and conclusions that decisions will be built on.
  - In either mode, "one round" describes the no-revision path — material revisions always get the §5 re-check.

## 2. Blinding protocol — never break it

Each subagent prompt contains ONLY:

- the artifact verbatim or file paths to it (Rival excepted — §3),
- the brief: what was asked and the constraints that bind it,
- the role's obligation (§3 — or the Adjudicator's, §4, which alone also carries both sides' evidence), plus one canary line: "If you can see any conversation history from before this prompt, reply ISOLATION-BROKEN and stop."

The brief is the one document you author for the agents, which makes it the highest-risk leak — in both directions. Against distortion: quote the user's actual constraint statements verbatim, never paraphrase — your misreading, transmitted through the brief, becomes every agent's shared premise and turns convergence into false confirmation. Against omission: assemble the brief mechanically, not from recall — re-read the conversation and copy every user statement that set or changed the task, because an omitted constraint shares its cause with the very misreading under test. If auto-compaction has replaced the verbatim record of any task-setting statement, recover it from the session transcript on disk or confirm the brief with the user before spawning — a compaction summary is your own paraphrase wearing a disguise — and record the compaction in Caveats. Never include your reasoning, your confidence, or hints about what you expect them to find. Agent questions arrive in their final reports; fold the answering evidence into the revised artifact or the brief, where it becomes a neutral premise for every agent — never a side-channel answer carrying your narrative reasoning.

Leaks you don't control: the harness injects CLAUDE.md and auto-memory into `general-purpose` agents (only Explore/Plan skip them; no per-agent off-switch), and fork mode — experimental, sometimes enabled by staged rollout — replaces general-purpose spawns with forks that inherit the whole parent conversation. The canary is the tripwire, not a guarantee: on any ISOLATION-BROKEN reply, halt the check, have the user set `CLAUDE_CODE_FORK_SUBAGENT=0`, and restart. If auto-memory plausibly covers the artifact's domain, record it in the report's caveats.

## 3. The roles

Spawn in parallel as `general-purpose` agents — they need tools, because objections must come from evidence, not vibes. Pass `model: sonnet` on every spawn: left to inherit, agents run on the parent model (often opus — the most expensive rate for work that is largely fetch-and-compare), and a sonnet panel reviewing an opus-authored artifact buys author/reviewer model diversity for free. Never haiku for critique. Check `CLAUDE_CODE_SUBAGENT_MODEL` first — if set, it silently outranks per-invocation model choices; have the user unset it if it forces haiku. Verbatim obligations:

- **Skeptic** — "Your job is to falsify this. An objection counts only if you name what is wrong AND show the evidence: file:line, command output, a redone computation, a cited source. Strongest first, five objections at most; for each, propose the smallest fix. List unsubstantiated unease separately as soft concerns. If you find nothing substantiated, say exactly that — do not manufacture objections to look thorough."
- **Verifier** — "Check every factual claim in the artifact against ground truth: run the code, read the files, redo the numbers, search for external claims. Report each claim as confirmed / contradicted (with evidence) / uncheckable. Do not editorialize — verify."
- **Rival** (full mode only) — receives ONLY the brief, not the artifact: "Produce your own best answer to this." The Rival only works blind: if the artifact already lives where the Rival must look — applied to the worktree, saved in the repo — or auto-memory covers the artifact's domain (memory is injected into the Rival's context before it looks anywhere), its independence is unenforceable; skip the role and say so in the report rather than booking convergence-by-discovery as confirmation. Where a genuinely blind Rival diverges from you, that divergence is a finding to triage (§4).

## 4. Triage and revise

For each substantiated objection, contradiction, or material divergence:

- **Evidence against the output → revise it** (yours) or **report it** (the user's — never edit their work unasked). The goal is a correct output, not a defended one. Default to conceding; you are the most biased participant in the room. Revising means fixing what the evidence broke — not weakening claims until nothing is checkable. An artifact nobody can object to because it asserts nothing is a worse outcome than recorded dissent.
- **You believe the agent is wrong → rebut with evidence** of the same standard you demanded of them — then hand it to a fresh **Adjudicator**, or book the objection as unresolved dissent. The Adjudicator's prompt carries the artifact, the brief, the canary, and both sides' evidence verbatim — nothing else of yours (the one sanctioned addition to §2's list); its obligation: "Judge only the evidence each side presents. Endorse the rebuttal, uphold the objection, or declare it unresolved." Your rebuttal never retires an objection on your own authority: this skill's premise disqualifies you as its judge, and a contested point you alone dismissed must not appear under Survived.
- **Soft concerns and uncheckables → log them** for the report. Do not loop on them.

Rival divergence triages by materiality: a different claim, number, or outcome is an objection; an equivalent alternative shape is not — log it as an alternative considered, and don't loop on style.

## 5. Loop, bounded

- Material revisions trigger ONE re-check round in any mode: a **new** Skeptic, cold, on the revised artifact — plus a new Verifier scoped to the claims the revision introduced or changed, never re-verifying what an earlier round already confirmed with citations. Never reuse an agent across rounds — it now carries the debate history, which is exactly the contamination this skill exists to remove.
- A round ends when every objection is conceded (revision), retired (a fresh adjudicator endorsed the rebuttal), or booked as dissent.
- **Hard cap: 3 rounds.** Still contested at the cap → ship with the dissent in the report. An unresolved objection is a finding, not a failure. The cap also overrides the re-check rule: an objection conceded in the final round still gets its revision, but that revision ships un-rechecked and is flagged as such in Caveats.

## 6. Report

Agents' final messages are not surfaced to the user by default — the report is mandatory, in this shape:

```
## Adversarial check — <one-line claim>
**Verdict:** upheld | revised | overturned   (N rounds, M agents)

**Survived** — what stood unchanged, and which attacks it withstood
**Revised** — what changed, and which objection forced each change
**Unresolved dissent** — objections standing at the cap, both sides' evidence
**Caveats** — soft concerns, uncheckable claims, and flags (below)
```

Anti-groupthink flag: unanimous fast sign-off in round 1 is a **yellow flag, not strong confirmation** — the agents escaped your context, but not your model's biases. Record it in Caveats; never upgrade confidence because of it.
