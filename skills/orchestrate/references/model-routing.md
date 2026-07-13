# Model routing

Which tier each leg gets, and the knobs for tuning it. Route by **task property**, not by
"which model is smartest" — the orchestrator already holds that prior; what it doesn't reliably
hold are the current IDs, the user's defaults, and the counterintuitive heuristics below.

## Tiers

The Agent tool's `model` param takes an **alias** that resolves to the current lineup:

| Alias | Model | ID | Role |
|---|---|---|---|
| `haiku` | Haiku 4.5 | `claude-haiku-4-5` | cheap / fast / checkable work |
| `sonnet` | Sonnet 5 | `claude-sonnet-5` | **default worker** |
| `opus` | Opus 4.8 | `claude-opus-4-8` | hard reasoning; orchestrator |
| `fable` | Fable 5 | `claude-fable-5` | **orchestrator only — never a worker** |

## Choosing a tier by task property

- **Sonnet (default):** general coding and execution, research/exploration legs, drafting,
  summarise-with-judgment. Reach here first; upgrade *from* here.
- **Opus:** genuinely hard multi-step reasoning, ambiguous or under-specified problems,
  architecture and design decisions, final adjudication.
- **Haiku:** only when the leg is **low-risk AND low-ambiguity AND checkable** — extraction,
  classification, format conversion, filtering, "does X contain Y", mechanical transforms. A
  cheap model is safe exactly when its mistakes are cheap to catch. Messy or under-specified
  work does not tolerate Haiku even when it *looks* small.
- **Fable:** orchestrator only. Do not spawn it as a worker.

## Heuristics the model won't apply on its own

- **Prefer a tier upgrade over a token-budget increase.** When a worker underperforms, move
  Sonnet→Opus before throwing more tokens at the same tier. (Anthropic's research system found
  a Sonnet 3.7→4 upgrade beat *doubling* Sonnet 3.7's token budget.)
- **Escalate one tier on low confidence or a failed verification** — don't re-run the same tier
  and hope.
- **Route by messiness, not size.** Clean, well-scoped legs tolerate a cheaper tier; ambiguous
  ones do not, however short they look.

## Effort and isolation

- **effort** (`low | medium | high | xhigh | max`) is a first-class opt only in **Workflow**
  `agent()` calls. The interactive Agent tool has **no `effort` param** — on an Agent spawn,
  steer effort through the prompt's thinking directive and through the tier choice; otherwise it
  inherits the session default. The report's Effort column records the *intended* level. See
  `harness-assumptions.md` §2.
- **`isolation: worktree`** (Agent param) gives a leg its own git worktree — use it for
  **parallel legs that mutate files**, or they collide. It costs setup + disk, so use it only
  when parallel writers would otherwise conflict.

## Source

Tier pattern and the token/upgrade findings are from Anthropic's multi-agent research system
write-up (Opus lead + Sonnet subagents beat single-agent Opus by 90.2%; token budget explained
~80% of quality variance). Model IDs drift — confirm the lineup and edit the table above when it
changes; this is the one-place edit for a lineup update.
