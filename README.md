# Claude_Skills

Personal collection of Claude Code skills — authored, documented, and refined here, then made live via symlinks into `~/.claude/skills/`.

## Skills

| Skill | Description |
|-------|-------------|
| [grill-me](skills/grill-me/) | Relentless interview about a plan or design until shared understanding is reached |
| [grill-with-docs](skills/grill-with-docs/) | Grilling session that also sharpens terminology and updates CONTEXT.md / ADRs inline |
| [set-academic-env](skills/set-academic-env/) | Scaffolds the AcademicPaperWriter harness into a new paper repository |
| [init-claude-permissions](skills/init-claude-permissions/) | Creates a project `.claude/settings.json` with Python/geospatial auto-approval permissions |
| [set-python-env](skills/set-python-env/) | Bootstraps a Python project and loads session coding principles |

## Layout & conventions

Each skill lives in `skills/<name>/` and contains:

- `SKILL.md` — the skill itself: YAML frontmatter (`name`, `description`, optional `allowed-tools` / `metadata`) followed by the instructions Claude executes. The `description` should state what the skill does **and** when to use it (this is what triggers automatic invocation).
- `README.md` — human documentation: what it does, usage examples, when to use it.
- `CHANGELOG.md` — dated entries describing each refinement, newest first.
- Supporting files as needed (templates, scripts, format docs).

## Deployment

The directories in `~/.claude/skills/` are symlinks into this repo, so edits here are live immediately:

```bash
ln -s "$(pwd)/skills/<name>" ~/.claude/skills/<name>
```

To add a new skill: create `skills/<name>/SKILL.md` (+ README + CHANGELOG), symlink it as above, then commit.

## Refining a skill

1. Edit `SKILL.md` (and supporting files) in this repo.
2. Add a dated entry to the skill's `CHANGELOG.md` describing what changed and why.
3. Update the skill's `README.md` if usage changed.
4. Commit.
