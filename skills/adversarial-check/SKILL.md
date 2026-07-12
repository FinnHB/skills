---
name: adversarial-check
description: Validate a plan, analysis, finding, or conclusion by spawning fresh-context adversarial agents that attack it with evidence. Use when the user mentions "adversarial check", or asks for agents to validate, stress-test, or critically assess an output (Claude's or their own).
metadata:
  version: 0.5.1
---

# Adversarial check

An output is under check — a plan, analysis, set of findings, or conclusion; usually yours, sometimes the user's. When it is yours, your context window is the problem: it contains the reasoning that led there, so you can no longer evaluate it neutrally. This skill makes you the orchestrator of agents that do NOT share that context. Their cold start is the core mechanism; every rule below protects it.

## 1. Scope the check

- **Artifact**: the thing under attack — usually your most recent substantive output, or whatever the user names. If ambiguous, ask. Note who owns it: your own output gets revised when objections land (§4); a user-authored artifact gets findings reported, never edits, unless they ask. Freeze the version under attack — no edits of yours while agents are reading it; if the user edits it mid-check, the results are stale against the new version — say so and offer a re-run.
- **Claim**: restate the artifact's core claim in one sentence, ending with what it would mean for it to be *wrong*. If you can't, the artifact isn't checkable yet — say so and tighten it first.
- **Effort**:
  - **full** — all three roles, up to 3 rounds. The default: "this doesn't need a panel" is exactly the judgment the artifact's author cannot make neutrally.
  - **light** — Skeptic only; add the Verifier if the artifact makes checkable factual claims. One attack round (a material revision still triggers the §5 re-check; capped at 2 rounds). Downgrading to light must be argued to the user in one line: the blast radius, and why it is limited.
- **Pre-flight**: before the first spawn, tell the user the tier, the roles, and a rough cost envelope (light ≈ tens of k subagent tokens, minutes; full ≈ 100k+, longer), and check the knobs in `references/harness-assumptions.md` — if any named env var or behavior there is absent or contradicted, halt and re-derive from current docs rather than trust the catalog.

## 2. Blinding protocol — never break it

Assemble every subagent prompt from `references/spawn-templates.md` — fill every slot, never freehand; a template makes a dropped canary a visible hole instead of a silent one. Each prompt contains ONLY:

- the artifact verbatim, or file paths when it is long (Rival excepted — §3),
- the §1 claim, one sentence (never to the Rival — it would leak the artifact's shape),
- the brief: what was asked and the constraints that bind it,
- the role's obligation (§3 — or the Adjudicator's, §4, which alone also carries both sides' evidence), plus one canary line: "If you can see any conversation history from before this prompt, reply ISOLATION-BROKEN and stop."

The brief is the one document you author for the agents, which makes it the highest-risk leak — in both directions. Its assembly rules (verbatim quotes with locators, mechanical re-read, compaction recovery) live beside the ⟨BRIEF⟩ slot in `references/spawn-templates.md` and bind every spawn. Never include your reasoning, your confidence, or hints about what you expect them to find. Agent questions arrive in their final reports; fold the answering evidence into the revised artifact or the brief, where it becomes a neutral premise for every agent — never a side-channel answer carrying your narrative reasoning.

Leaks you don't control — CLAUDE.md/auto-memory injection, fork mode — and every other harness fact this skill leans on are cataloged, dated, in `references/harness-assumptions.md`. The canary is the tripwire, not a guarantee: on any ISOLATION-BROKEN reply, halt the check, apply the catalog's remediation, and restart. If auto-memory plausibly covers the artifact's domain, record it in the report's caveats.

## 3. The roles

Spawn in parallel as `general-purpose` agents — they need tools, because objections must come from evidence, not vibes. They run in the background: triage only after every panelist has reported. Pass `model: sonnet` on every spawn — left to inherit, agents run on the parent model; if the alias fails to resolve, halt, never silently inherit. Never haiku for critique. When the session's own model is also sonnet, the panel has zero model diversity — record that in Caveats. Verbatim obligations live in the templates (a §5 re-check may append one scope sentence to the Verifier's); what each role owes:

- **Skeptic** — falsifies. An objection counts only with named evidence: file:line, command output, a redone computation, a cited source. Strongest first, five at most, severity ranked by how directly each hits the §1 claim; smallest fix per objection. A saturated budget (cap hit with findings remaining) must be declared — saturation is not clearance. Nothing substantiated must be said outright, never papered over with manufactured objections.
- **Verifier** — checks every factual claim against ground truth, factored: it lists the claims and its check plan *before* reading the artifact's supporting reasoning, so it cannot copy the artifact's own logic into the check. Six dispositions, not three: confirmed / contradicted / no counterexample found (universal and absence claims are never "confirmed") / self-referential (the only available ground truth is the artifact's own effect) / unverified by asymmetry (the author had access the critic lacks) / uncheckable. The last four land in Caveats as distinct classes — asymmetry is the dangerous one: the check is weakest exactly where the author was best provisioned.
- **Rival** (full mode only) — receives ONLY the brief, not the artifact: "Produce your own best answer to this." The Rival only works blind: if the artifact already lives where the Rival must look — applied to the worktree, saved in the repo — or auto-memory covers the artifact's domain (memory is injected into the Rival's context before it looks anywhere), its independence is unenforceable; skip the role and say so in the report rather than booking convergence-by-discovery as confirmation. Where a genuinely blind Rival diverges from you, that divergence is a finding to triage (§4).

## 4. Triage and revise

The Skeptic's classification is binding: an objection it listed as substantiated exits only by concession, adjudicated rebuttal, or booked dissent — never by you relabeling it a soft concern. For each substantiated objection, contradiction, or material divergence:

- **Evidence against the output → revise it** (yours) or **report it** (the user's — never edit their work unasked). Default to conceding; you are the most biased participant in the room. Revising means fixing what the evidence broke — not weakening claims until nothing is checkable. An artifact nobody can object to because it asserts nothing is a worse outcome than recorded dissent.
- **You believe the agent is wrong → rebut with evidence** of the same standard you demanded of them — then hand it to a fresh **Adjudicator**, or book the objection as unresolved dissent. Cross-lineage by default: a same-lineage judge measurably favors the more familiar-sounding side even when blinded, and your rebuttal is the fluent one. Assemble the packet per the template — the objection is the Skeptic's report section in full, never your excerpt; objection and rebuttal in randomized order at comparable length — and send it via ask-the-panel's `adjudicate` mode, subject to that skill's privacy confirmation. No key, no consent, or content that can't leave the machine → a fresh local agent gets the equivalent content via the Local Adjudicator template (canary included), and Caveats records same-lineage adjudication. Either judge's obligation: "Judge only the evidence each side presents. Endorse the rebuttal, uphold the objection, or declare it unresolved." Your rebuttal never retires an objection on your own authority: this skill's premise disqualifies you as its judge, and a contested point you alone dismissed must not appear under Survived.
- **Soft concerns and uncheckables → log them** for the report. Do not loop on them.

Rival divergence triages by materiality: a different claim, number, or outcome is an objection; an equivalent alternative shape is not — log it as an alternative considered, and don't loop on style.

## 5. Loop, bounded

- Material revisions trigger ONE re-check round in any mode: a **new** Skeptic, cold, on the revised artifact — plus a new Verifier scoped to the claims the revision introduced or changed, never re-verifying what an earlier round already confirmed with citations. Never reuse an agent across rounds — it now carries the debate history, which is exactly the contamination this skill exists to remove.
- A round ends when every objection is conceded (revision), retired (a fresh adjudicator endorsed the rebuttal), or booked as dissent.
- **Hard cap: 3 rounds (light mode: 2).** Still contested at the cap → ship with the dissent in the report. An unresolved objection is a finding, not a failure. An objection conceded in the final round still gets its revision, but that revision ships un-rechecked and is flagged as such in Caveats.

## 6. Report

Agents' final messages are not surfaced to the user by default — the report is mandatory, and its Stats are receipts, not estimates: copy each spawn's returned `subagent_tokens` and `duration_ms`. A report that cannot list its spawns describes a check that did not run.

```
## Adversarial check — <one-line claim>
**Verdict:** upheld | revised | overturned
**Stats** — N rounds; each agent: role (model, tokens, time); objections: conceded / rebutted / dissent

**Survived** — what stood unchanged, and which attacks it withstood
**Revised** — what changed, and which objection forced each change
**Unresolved dissent** — objections standing at the cap, both sides' evidence
**Caveats** — soft concerns; no-counterexample-found, uncheckable, asymmetric, and self-referential claims; flags (below)
```

Anti-groupthink flag: unanimous sign-off in round 1 is a **yellow flag, not strong confirmation** — the agents escaped your context, but not (unless adjudication went cross-lineage) your model's biases. Record it in Caveats, offer `/ask-the-panel` as the cross-lineage follow-up, and never upgrade confidence because of it.
