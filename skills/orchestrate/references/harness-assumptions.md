# Harness assumptions

Verified 2026-07-13 against this session's tool schemas and observed harness behaviour. This is a
**quarantine, not a source of truth**: before a run, if any param, field, or behaviour below is
absent or contradicted by the current tool schemas or docs, **HALT and re-derive** rather than
trust this file. Harness surfaces get renamed and re-gated silently between releases.

## Catalog

1. **Agent-tool spawn params.** The Agent tool exposes: `prompt`, `description`, `subagent_type`,
   `model` (enum: `sonnet | opus | haiku | fable`), `isolation` (`worktree | remote`),
   `run_in_background`. → These are the real spawn knobs. Set the tier via `model`, the agent
   role via `subagent_type` (`general-purpose` / `Explore` / `Plan`).

2. **No per-spawn `effort` param on the Agent tool.** Effort as a first-class knob
   (`low | medium | high | xhigh | max`) exists only in **Workflow** `agent()` opts. On an
   interactive Agent spawn, effort is steered via prompt-level thinking directives and tier
   choice, and otherwise inherits the session default. → The report's Effort column records the
   *intended/requested* level, not a returned field.

3. **Spawn receipts.** Each completed Agent spawn returns a usage block carrying `subagent_tokens`
   and `duration_ms` (observed in this session's completion notification; not publicly
   documented). → These are the report's receipts — copy them, never estimate.

4. **Background spawns, invisible finals.** Agents run in the background by default and fire a
   task-notification on completion; their final messages are **not** shown to the user. →
   Synthesise and report after joins; the Step 7 report is mandatory because otherwise the user
   sees nothing.

5. **Model alias resolution.** `model: opus|sonnet|haiku|fable` resolves to the current lineup
   (Opus 4.8 / Sonnet 5 / Haiku 4.5 / Fable 5). Resolution order:
   `CLAUDE_CODE_SUBAGENT_MODEL` env var > per-invocation `model` param > agent-definition
   frontmatter > inherit parent. → If the env var pins a tier, unset it before routing; if an
   alias fails to resolve, halt rather than silently inherit the parent model.

6. **Workflow opt-in.** The Workflow tool requires explicit opt-in, and a skill whose
   instructions tell you to call it counts as opt-in — so reaching for Workflow from within
   orchestrate is legitimate for a big, uniform, high-fan-out sub-problem. Its `agent()` supports
   `effort` and `isolation: worktree` natively.

7. **CLAUDE.md / auto-memory injection.** `general-purpose` subagents load CLAUDE.md and
   auto-memory; only `Explore` / `Plan` skip them. → A verifier or panel that must be blind to
   project context should account for this; for the full blinding discipline, cross-reference
   `adversarial-check/references/harness-assumptions.md`.

8. **Sub-skill gates are not bypassed.** `/adversarial-check` (cost pre-flight) and
   `/ask-the-panel` (privacy confirmation before content leaves Anthropic) each carry their own
   gate. Invoking them from orchestrate runs those gates — it does not skip them.
