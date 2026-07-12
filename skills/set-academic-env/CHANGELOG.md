# Changelog — set-academic-env

## 2026-07-12 (v0.2.1)
Rubric pass against `writing-great-skills`, part of a repo-wide review.
- **Fixed a stale, factually-wrong directory tree.** SKILL.md listed `source/ related/ transcripts/ review/ research/ logs/`, but `install.sh` creates `paper/`, `worklog/` (with `research/`, `review/`, `transcripts/` nested under it), `source/`, `related/`, and `logs/`. Corrected to match the installer.
- **Idempotency claim corrected.** "prompts before overwriting each file" was false for ~half the copy paths and for all non-interactive (agent-driven) runs; the section now describes the real keep-if-exists / prompt-interactively / skip-non-interactively behaviour, with `install.sh` exit 0 as the success check.
- **Human-maintenance section moved to README.** The "Reinstalling / updating the skill" cp block never bore on a runtime invocation; relocated out of the always-loaded SKILL.md.
- **Description:** dropped "commands" — the workflow entry points are installed as skills that are invocable as slash commands, so "skills … commands" named one thing twice.

## 2026-06-05
- Imported into the Claude_Skills repo from `~/.claude/skills/set-academic-env` at version 0.2.0 (now the source of truth, symlinked into `~/.claude/skills/`).
