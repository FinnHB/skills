# init-claude-permissions

Creates (or carefully updates) a project-level `.claude/settings.json` with auto-approval permissions tuned for Python/geospatial development: file tools and common read-only/dev commands allowed, destructive or outward-facing commands (`sudo`, `rm -rf`, `git push`, `curl`, …) denied.

If a settings file already exists, it shows a before/after diff and asks whether to overwrite, merge, or cancel.

## Usage examples

```
/init-claude-permissions
```
Run from a project root to set up permissions for that project.

## When to use

- First Claude Code session in a new Python project
- Reducing permission prompts to a known-safe baseline
- Typically invoked automatically as step 1 of [set-python-env](../set-python-env/)
