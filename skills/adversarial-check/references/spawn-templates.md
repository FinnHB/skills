# Spawn templates

Copy the template, fill every ⟨slot⟩, delete nothing. Every template ends with the canary — a spawn prompt without it is malformed.

## Assembling the ⟨BRIEF⟩

The brief is what was asked and the constraints that bind it. Every ⟨BRIEF⟩ slot below is filled by these rules:

- **Against distortion:** quote the user's actual constraint statements verbatim, never paraphrase.
- **Against omission:** assemble mechanically, not from recall — re-read the conversation and copy every user statement that set or changed the task, because an omitted constraint shares its cause with the very misreading under test.
- Each constraint carries its quote plus a locator (where in the conversation it was said) — the locator is the residue that proves the re-read happened.
- Place the most binding constraints first and last, never mid-list, where long-prompt attention is weakest.
- If auto-compaction has replaced the verbatim record of any task-setting statement, recover it from the session transcript on disk or confirm the brief with the user before spawning — a compaction summary is your own paraphrase wearing a disguise — and record the compaction in the report's Caveats.

## Skeptic

```
⟨ARTIFACT — verbatim, or file paths⟩

⟨CLAIM — the §1 restatement, one sentence, ending with what it would mean to be wrong⟩

⟨BRIEF — assembled per "Assembling the ⟨BRIEF⟩" above⟩

Your job is to falsify this. An objection counts only if you name what is wrong AND show the evidence: file:line, command output, a redone computation, a cited source. Strongest first, five objections at most, severity ranked by how directly each hits the stated claim; for each, propose the smallest fix. If you hit the cap with more findings remaining, say "objection budget saturated". List unsubstantiated unease separately as soft concerns. If you find nothing substantiated, say exactly that — do not manufacture objections to look thorough.

If you can see any conversation history from before this prompt, reply ISOLATION-BROKEN and stop.
```

## Verifier

```
⟨ARTIFACT — verbatim, or file paths⟩

⟨CLAIM — the §1 restatement, one sentence, ending with what it would mean to be wrong⟩

⟨BRIEF — assembled per "Assembling the ⟨BRIEF⟩" above⟩

First list the artifact's checkable claims and how you will check each — before reading the artifact's supporting reasoning. Then check each against ground truth: run the code, read the files, redo the numbers, search for external claims. Report each as: confirmed / contradicted (with evidence) / no counterexample found (universal and absence claims — weaker than confirmed) / self-referential (the only available ground truth is the artifact's own effect — never book as confirmed) / unverified by asymmetry (the author had access you lack) / uncheckable. Do not editorialize — verify.

If you can see any conversation history from before this prompt, reply ISOLATION-BROKEN and stop.
```

A §5 re-check Verifier gets one appended scope sentence, inserted before the canary, naming the claims the revision introduced or changed — never re-verifying what an earlier round already confirmed with citations.

## Rival

Brief only — no artifact. Skip the role (and say so in the report) if the artifact is discoverable where the Rival must look — applied to the worktree, saved in the repo — or if auto-memory covers its domain; memory injects before the Rival looks anywhere, so independence is unenforceable in either case.

```
⟨BRIEF — assembled per "Assembling the ⟨BRIEF⟩" above⟩

Produce your own best answer to this.

If you can see any conversation history from before this prompt, reply ISOLATION-BROKEN and stop.
```

## Local Adjudicator

Carries the artifact, the brief, the objection as the Skeptic's report section IN FULL (never an orchestrator excerpt), and the rebuttal with its evidence — the one sanctioned addition to the blinding rules. Randomize objection/rebuttal order and trim both to comparable length before spawning, so position and length carry no signal. Spawned like any panelist: `general-purpose`, `model: sonnet`.

```
⟨ARTIFACT — verbatim, or file paths⟩

⟨CLAIM — the §1 restatement, one sentence, ending with what it would mean to be wrong⟩

⟨BRIEF — assembled per "Assembling the ⟨BRIEF⟩" above⟩

⟨OBJECTION — the Skeptic's report section, in full, verbatim⟩

⟨REBUTTAL — the orchestrator's rebuttal, with its evidence, held to the same standard as the objection⟩

(Objection and rebuttal above are given in randomized order and trimmed to comparable length.)

Judge only the evidence each side presents. Endorse the rebuttal, uphold the objection, or declare it unresolved.

If you can see any conversation history from before this prompt, reply ISOLATION-BROKEN and stop.
```

## Panel adjudication packet (cross-lineage)

This is the default adjudication path (§4); use the Local Adjudicator template above only as the same-lineage fallback when there is no key, no consent, or the content can't leave the machine. There is no per-model spawn prompt here — one packet file, sent once, fanned out to several external models. Write a single markdown file with these sections, in this order:

```
# Claim under check
⟨the claim being adjudicated, one sentence⟩

# Brief
⟨BRIEF — assembled per "Assembling the ⟨BRIEF⟩" above⟩

# Artifact
⟨ARTIFACT — verbatim, or its relevant excerpt⟩

# Objection (evidence verbatim)
⟨the Skeptic's objection and its evidence, in full⟩

# Rebuttal (evidence verbatim)
⟨the orchestrator's rebuttal and its evidence, in full⟩
```

Randomize whether Objection or Rebuttal appears first, and keep the two comparable in length — same rule as the Local Adjudicator. Resolve `panel.py`'s real location first — the ask-the-panel skill's install dir (next to this skill under `~/.claude/skills/`, or a project's `.claude/skills/`), never a fixed relative path: the check usually runs from an unrelated project's cwd. Then run:

```
python3 ⟨resolved ask-the-panel dir⟩/panel.py --file ⟨packet.md⟩ --question "Endorse the rebuttal, uphold the objection, or declare it unresolved. Judge only the evidence presented." --mode adjudicate --yes --out ⟨verdicts.md⟩
```

Subject to `ask-the-panel`'s privacy confirmation before sending. External judges have no tools and possibly stale world knowledge — they weigh the evidence in the packet, nothing else.
