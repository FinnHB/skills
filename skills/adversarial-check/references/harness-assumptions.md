# Harness assumptions

Verified 2026-07-02 against the Claude Code sub-agents/agent-teams docs. This is a quarantine, not a source of truth: before a run, if any named env var, behavior, or field below is absent or contradicted, HALT and re-derive from current docs rather than trusting this file. Prefer behavioral tripwires (the canary) over config-name checks — env vars get renamed and re-gated silently between releases; a canary reply doesn't.

## Catalog

1. **CLAUDE.md / auto-memory injection.** `general-purpose` subagents load CLAUDE.md and auto-memory; only Explore/Plan skip them; there is no per-agent off-switch. → Uncontrollable leak: report in Caveats when memory plausibly covers the artifact's domain; also triggers the Rival skip rule.

2. **Fork mode.** `/fork` is enabled by default from v2.1.161; Claude-initiated forks are experimental/staged; `CLAUDE_CODE_FORK_SUBAGENT=1`/`0` explicitly enables/disables it. → The canary line is the tripwire, not the env var: on any ISOLATION-BROKEN reply, halt the check, set `CLAUDE_CODE_FORK_SUBAGENT=0`, and restart.

3. **Subagent model resolution order.** `CLAUDE_CODE_SUBAGENT_MODEL` env var > per-invocation `model` parameter > agent-definition frontmatter > inherit parent. → Check the env var before spawning; if it forces haiku, have the user unset it — haiku never runs critique.

4. **Panel model pinning.** Panel model is passed per-spawn as `model: sonnet`; left unset, agents inherit the parent model. → If the sonnet alias ever fails to resolve, halt — never fall back to inherit silently. If the parent session's model equals the panel model, the check has zero model diversity; record that in Caveats.

5. **Spawn result stats.** Each Agent spawn's result carries `subagent_tokens` and `duration_ms` (observed harness behavior; not documented publicly). → These are the report's Stats receipts; a report must quote them, never estimate.

6. **Background spawns, invisible final messages.** Agents run in the background by default and notify on completion; their final messages are not shown to the user. → Triage only after every panelist has reported; the §6 report is mandatory because of this.

7. **ask-the-panel dependency (cross-lineage adjudication).** Requires `OPENROUTER_API_KEY` in the environment and a resolvable path to the sibling skill's `panel.py` — its install location varies, so never assume a fixed relative path. → When adjudication is plausible, verify both at pre-flight; absent either, use the local Adjudicator fallback per §4 and record same-lineage adjudication in Caveats.

8. **SendMessage / resume gating.** SendMessage is always available for resuming a subagent by ID (changed ~2026-06: previously believed gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`; only structured team-protocol messages still need that flag). → The fresh-spawn-only rule stands anyway, on anchoring grounds: a resumed agent carries the debate history, which is exactly the contamination this skill exists to remove.
