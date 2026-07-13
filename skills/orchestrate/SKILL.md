---
name: orchestrate
description: Orchestrate a task across subagents — decompose into independent legs, delegate each to the right-tier model (Haiku/Sonnet/Opus), choreograph the waves, verify, and synthesise. You are the orchestrator and never execute the work yourself. User-invoked.
disable-model-invocation: true
metadata:
  version: 0.1.0
---

# Orchestrate

You are the **orchestrator**. You decompose the task, delegate every piece of *execution* to subagents chosen for the job, choreograph the waves, and synthesise the result.

**One hard rule: you never execute the task yourself.** Your context is for judgment — planning, deciding, merging — not for doing the work. The moment you catch yourself writing the feature, running the analysis, or doing a research leg with your own hands, stop and delegate it.

You keep in your own hands only four things: **light recon** to plan, **choreography**, **synthesis and final decisions**, and **the report**. Bulk assembly of a large artifact may be delegated too — but the final judgment on it stays yours.

The orchestrator's model is the one the session launched in — the user chose it (Fable or Opus for real work). You route the **subagents**; you don't check yourself. Work the steps in order; each ends on a checkable criterion. `references/model-routing.md` holds the tier IDs, defaults, and heuristics; `references/harness-assumptions.md` holds the spawn mechanics this skill leans on — consult them where the steps point.

## 1. Gate — is this worth orchestrating?

Multi-agent work costs 3–10× the tokens of a single agent and *loses* to one agent on tightly-coupled reasoning. So the first act is to earn the fan-out.

- Carve the task into **legs** — units of work with no tight coupling between them. Split by *object of work*, never by *phase*: a "planner" leg feeding a "writer" leg feeding a "reviewer" leg is a telephone game that loses fidelity at every handoff — that work belongs in **one** leg.
- If the task is a single coupled job, or small enough that one worker does it well, say so and stop: **"This task likely doesn't need orchestration because &lt;reason&gt;. Do you still want to orchestrate? (Y/N)"** Proceed only on Y.

**Done when:** you hold a set of legs, each an independent object of work — and the fan-out earns its cost, or the user answered Y.

## 2. Plan — tier each leg, then write it down

Stamp every leg with a **model tier** and an **effort level**, decided now by task property (not model personality). The IDs, defaults, and the counterintuitive heuristics live in `references/model-routing.md`; the short of it:

- **Sonnet** — the default worker: general coding, execution, research legs, drafting.
- **Opus** — hard reasoning: ambiguous, architectural, or multi-step-judgment legs.
- **Haiku** — only when the leg is **low-risk, low-ambiguity, and checkable** (extraction, classification, mechanical transforms).
- **Fable** — orchestrator only; never a worker.
- When a leg needs more, prefer a **tier upgrade over a bigger token budget**; raising effort is the middle lever.

**Right-size the fan-out** (justify in your thinking any spawn beyond what the task's complexity warrants — over-decomposition is the single most common orchestration failure):

| Task shape | Legs |
|---|---|
| Simple fact-finding | 1 |
| Direct comparison | 2–4 |
| Genuinely open-ended | 10+, responsibilities divided |

Then **write the pre-flight plan** before any spawn: the legs, each leg's model + effort, what runs in parallel vs series, and each leg's one-line objective. This is your oversight surface and your division-of-labour map. It is **non-binding** — deviate, drop, or add legs freely as the work reveals itself.

**Done when:** every leg carries a tier + effort stamp and the pre-flight plan is written out.

## 3. Spawn — the five-field brief

Vague briefs are the direct cause of duplicated and off-target work. Every spawn carries all five fields, no freehand:

1. **Objective** — one crisp, self-contained statement. The worker sees *only* what you give it.
2. **Output format** — the exact shape to return. Machine-strict (JSON / enumerated verdict) when you'll act on fields; structured-prose (named sections) when you'll synthesise with judgment.
3. **Tools / sources** — which to prioritise, where to look.
4. **Boundaries** — scope limits, and what the leg must **not** touch / what other legs own. This is the field that prevents overlap; no spawn goes out without it.
5. **Model + effort** — the Step 2 stamp, made real on the spawn (`model` on the Agent tool; effort per `references/harness-assumptions.md`).

Pick the **agent type** by the leg's nature: `general-purpose` for execution and verification (needs tools), `Explore` for read-only recon/search (can't accidentally write), `Plan` for an occasional planning leg.

**Announce each spawn as you make it** — what it is, its model, its effort — so the trail is legible while it runs.

**Done when:** each spawn satisfies all five fields and has been announced.

## 4. Run the waves

- Fan out independent legs as a **parallel cohort**; run legs in series only when one's output truly feeds the next. Use `isolation: worktree` for parallel legs that edit files, or they collide.
- **Barrier-join:** wait for the whole cohort, then re-plan the next wave with fresh judgment. The join is where you decide whether more legs are needed.
- **Budget every leg:** a checkable "done" and a tool-call ceiling, so a worker can't wander. Cap remediation loops at **3 rounds**. A failed or empty return is not done — re-spawn, reassign, or record it.
- **Parallel ≠ faster.** Total tokens rise; latency only falls when legs are independent and balanced. An imbalanced cohort stalls the join on its slowest leg — you've paid the premium for nothing.

**Done when:** every leg in the wave has returned or been accounted for, and you've decided the next wave (or that there is none).

## 5. Diagnose, then remediate

When a leg's return falls short, **diagnose the cause before reaching for a lever.** Most shortfalls are specification or coordination, not worker capability — so the reflex "throw a bigger model at it" usually treats the rarest cause. Match the lever to the actual cause, cheapest first:

| What's actually wrong | Lever |
|---|---|
| Thin, off-target, or missed part of the ask | **Richer spec** — sharper objective, tighter boundaries, a fuller plan handed over |
| Right approach, reasoning too shallow for the leg | **Tier up** (Sonnet→Opus) **or raise effort** |
| One leg tried to hold too much / came back incoherent | **Split into smaller independent legs + synthesise** (guard against over-decomposition) |
| Plausible, but might be wrong | **Verify** — Step 6 |

**Done when:** each short return has been diagnosed and its matching lever applied, or the round cap reached and the shortfall named.

## 6. Verify — proportional, not universal

Verify in proportion to **stakes**, and inversely to how self-checkable the output already is — tests, lint, and compile give ground truth cheaply, so lean on them first. Not every leg needs a check. When one does, pick the rung by *failure type*:

- **Rung 1 — fresh blackbox verifier spawn** (a normal `general-purpose` spawn: a checking objective, a structured verdict). The everyday check. Its fresh context is immune to the generator's rationalisations.
- **Rung 2 — `/adversarial-check`** — for an output that might be **wrong** against ground truth, whose stakes justify 100k+ tokens. **Reserved:** fire only with a strong stated argument — name the stakes and why a rung-1 verifier can't settle it — and give the user the cost envelope first.
- **Rung 3 — `/ask-the-panel --council`** — for an output that might be **blinkered** (a reasoning blind spot or Anthropic-flavoured bias), on a self-contained artifact. **Reserved;** respect that skill's privacy gate before content leaves Anthropic.

Rung 2 is *"might be wrong"*; rung 3 is *"might be blinkered."* Different failure, different tool — never swap them.

**Done when:** every output whose stakes warranted a check has one, and the heavy rungs fired only with their justification stated.

## 7. Synthesise and report

**Merge the legs into the deliverable yourself** — adjudicate conflicts, resolve overlaps, own the final call. Concatenating worker outputs unmerged is not synthesis.

Then render the report:

- **One short synthesis paragraph** on what was delivered (bullets as relevant).
- **A table of every agent spun up:**

  | Agent (role) | Model | Effort | What it did (1 sentence) | Tokens | Duration |
  |---|---|---|---|---|---|
  | … | … | … | … | … | … |
  | **Total** | | | | **N** | |

Tokens and Duration are **receipts**, not estimates: copy each spawn's returned `subagent_tokens` and `duration_ms`. A report that cannot list its spawns describes work that didn't happen.

**Done when:** the deliverable is synthesised and the report + table are rendered from real receipts.
