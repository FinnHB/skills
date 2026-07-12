# Changelog — init-claude-permissions

## 2026-07-12 (v1.0.1)
Rubric pass against `writing-great-skills`, part of a repo-wide review.
- **"geospatial" removed** from the description and body — nothing in the shipped config is geospatial; it was a phantom claim carried as context load, matching no real trigger.
- **Description register aligned to the payload:** "sensible defaults for a new project" narrowed to "a Python project", since the allowlist is Python-specific (an agent could otherwise match it on a Node/Rust project and write a Python allowlist).
- **Verify step made checkable:** step 4 now re-reads the file and confirms valid JSON with both `allow` and `deny` blocks, instead of "confirm it was created successfully" (a no-op).

Deferred (not in this pass): the ~70-line inlined `settings.json` could be disclosed to a template file to keep the steps legible.

## 2026-06-05
- Converted from a legacy slash command (`~/.claude/commands/init-claude-permissions.md`) to skill format. Body unchanged; added frontmatter. The repo is now the source of truth, symlinked into `~/.claude/skills/`.
