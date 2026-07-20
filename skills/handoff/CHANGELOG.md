# Changelog — handoff

## 2026-07-20
Initial version. Model-invoked skill that writes a handoff briefing for a clean context window.
- **Skill, not a hook.** A `UserPromptSubmit` hook could only regex "handoff" and blind-inject — brittle on phrasing, false-positive on incidental uses, and unable to distinguish a plan handoff from a debugging one. Description-based selection handles the fuzziness natively and yields `/handoff` for free.
- **Output is a chat code block.** Rejected: a scratchpad file (still needs opening to copy), `HANDOFF.md` in the repo (litters every project), and both (noise). Nothing touches disk.
- **Recommends the launch mode, rather than invoking it.** The delivery step names `/orchestrate` when the remaining work has independent legs. It can only ever be a recommendation to the user: `orchestrate` is `disable-model-invocation: true`, so no skill and no receiving context can reach it — the handoff surfaces the call, the user makes it.
- **Rubric pass against `writing-great-skills` before first commit.** Dropped a four-row payload/emphasis table (**no-op** — leading a bug handoff with the repro is default behaviour; only the qualifier-picks-the-weighting clause survived) and folded three of five prose rules into the template that already encoded them (**duplication**). Cut ~45%.
