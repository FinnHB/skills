# Claude_Skills

Personal collection of Claude Code skills — authored, documented, and refined here, then made live via symlinks into `~/.claude/skills/`.

## Skills

| Skill | Description |
|-------|-------------|
| [adversarial-check](skills/adversarial-check/) | Fresh-context adversarial agents (skeptic, verifier, rival) attack a Claude output; bounded revision rounds, dissent reported |
| [ask-the-panel](skills/ask-the-panel/) | Sends a question/plan/draft to a panel of non-Anthropic models via OpenRouter and reports synthesised cross-model feedback |
| [flowchart](skills/flowchart/) | Purpose-level HTML flowcharts with hover tooltips and click-to-expand detail panels |
| [grill-me](skills/grill-me/) | Relentless interview about a plan or design until shared understanding is reached |
| [grill-with-docs](skills/grill-with-docs/) | Grilling session that also sharpens terminology and updates CONTEXT.md / ADRs inline |
| [orchestrate](skills/orchestrate/) | Makes the session model a pure orchestrator — decomposes a task into independent legs, delegates each to the right-tier subagent, choreographs the waves, verifies, and synthesises; never executes the work itself |
| [set-academic-env](skills/set-academic-env/) | Scaffolds the AcademicPaperWriter harness into a new paper repository |
| [init-backlog](skills/init-backlog/) | Scaffolds a commit-traceable backlog (BACKLOG.md + BACKLOG_DONE.md) and a Definition-of-Done maintenance rule in CLAUDE.md |
| [set-python-env](skills/set-python-env/) | Bootstraps a Python project and loads session coding principles |
| [snap-site](skills/snap-site/) | Screenshots local dev-server pages at multiple viewport widths (headless Chromium) so Claude can visually verify web UI changes |
| [writing-great-skills](skills/writing-great-skills/) | Matt Pocock's reference on writing predictable skills (vendored, MIT) — project-local only, active just inside this repo |

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

Skills that should only be active inside this repo (e.g. [writing-great-skills](skills/writing-great-skills/)) are instead symlinked into the project-local `.claude/skills/`:

```bash
ln -s ../../skills/<name> .claude/skills/<name>
```

## Refining a skill

1. Edit `SKILL.md` (and supporting files) in this repo.
2. Add a dated entry to the skill's `CHANGELOG.md` describing what changed and why.
3. Update the skill's `README.md` if usage changed.
4. Commit.
