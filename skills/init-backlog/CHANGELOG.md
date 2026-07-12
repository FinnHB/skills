# Changelog — init-backlog

## 2026-07-12 (v1.0.1)
Rubric pass against `writing-great-skills`, part of a repo-wide review.
- **Scoring rubric de-duplicated.** The `(Value × Frequency × Confidence) ÷ Effort` scale was stated verbatim in both SKILL.md and `templates/BACKLOG.md`. The SKILL.md copy is removed; Step 4 now points at the `BACKLOG.md` header (which the skill writes in Step 2, before seeding) as the single source of truth.
- **Verify step made checkable.** "Show the two files" replaced with an exhaustive gate: both root files exist, no `{{PROJECT}}` placeholder remains, and `grep -c "Backlog maintenance" CLAUDE.md` returns 1.
- **Description trimmed** to what-it-is plus triggers, cutting the file enumeration the body's "What it installs" already carries.

## 2026-06-05
- Initial version (v1.0.0): scaffolds `BACKLOG.md` + `BACKLOG_DONE.md` and a Definition-of-Done rule in `CLAUDE.md`.
