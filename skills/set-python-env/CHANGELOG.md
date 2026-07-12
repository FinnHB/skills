# Changelog — set-python-env

## 2026-07-12 (v1.1.0)
Follow-up to the rubric pass, applying the two deferred structural edits.
- **Dropped the permissions hop.** Phase 1 no longer runs `/init-claude-permissions` (that skill is retired — Claude's automode now covers auto-approval natively). Remaining setup steps renumbered 1–5.
- **Phase 2 principles disclosed to `principles.md`.** The ~40-line coding-conventions block moved out of SKILL.md into a reference file; Phase 2 is now a pointer that reads it at invocation, loading the conventions for the session the same way while keeping the setup steps legible. SKILL.md dropped from 128 to 82 lines (Phase 1's inline `README.md` template is the bulk of what remains).

## 2026-07-12 (v1.0.1)
Rubric pass against `writing-great-skills`, part of a repo-wide review.
- **No-op cull in the Phase 2 coding principles.** Removed generic advice the model already follows by default ("keep cross-script dependencies minimal", "tests are cumulative", "prefer the standard library"), plus the one-line body restatement of the frontmatter description.
- **Negations rephrased positively:** "Never install packages globally" folded into the positive venv rule; "Never assume code works" merged into the run-and-confirm gate; the bare-`except` ban reworded to "catch specific exception types".
- **Duplicate MVP gate collapsed** — the run-and-confirm-before-complete rule was stated twice (once positive, once negated).

Deferred (bigger, not in this pass): disclosing the whole Phase 2 principles block to a reference file (it's what makes this the longest SKILL.md in the repo), and splitting the two phases so the "load my conventions" trigger doesn't also run venv/folder scaffolding.

## 2026-06-05
- Converted from a legacy slash command (`~/.claude/commands/set-python-env.md`) to skill format. Body unchanged; added frontmatter. The repo is now the source of truth, symlinked into `~/.claude/skills/`.
