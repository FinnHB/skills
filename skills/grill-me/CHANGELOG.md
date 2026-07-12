# Changelog — grill-me

## 2026-07-12
Rubric pass against `writing-great-skills`, part of a repo-wide review.
- **Interview loop extracted to `interview-loop.md`.** The loop was duplicated verbatim in `grill-with-docs`; it now lives here as the single source of truth (grill-with-docs reaches it via `../grill-me/interview-loop.md`), and grill-me's body is just a pointer to it.
- **Completion criterion sharpened.** "until we reach a shared understanding" (the rubric's own example of a fuzzy bound) is replaced with a checkable stop: every surfaced decision has a recorded answer and none still depends on an unresolved one. The "wait for my answer before continuing" clause — present in grill-with-docs but dropped here — is restored in the shared loop.
- **Description de-overlapped with grill-with-docs.** Sharpened to the no-project-docs case plus a reach clause pointing at the sibling, so the two descriptions no longer compete on "stress-test a plan".

## 2026-06-05
- Imported into the Claude_Skills repo from `~/.claude/skills/grill-me` (now the source of truth, symlinked into `~/.claude/skills/`).
