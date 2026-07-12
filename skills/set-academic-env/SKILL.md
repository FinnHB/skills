---
name: set-academic-env
description: Use when initializing a new academic paper repository. Scaffolds the AcademicPaperWriter harness — installs its skills, hooks, templates, and MCP wiring into the current directory. Idempotent.
allowed-tools: Bash Read Write Edit
metadata:
  version: "0.2.1"
  source-repo: AcademicPaperWriter
---

# set-academic-env

Bootstrap an AcademicPaperWriter paper repository in the current directory (or a named target directory).

## Usage

Run `install.sh` from this skill's directory:

```bash
# Scaffold current directory
~/.claude/skills/set-academic-env/install.sh

# Scaffold a named directory (creates it if needed)
~/.claude/skills/set-academic-env/install.sh ~/Documents/Papers/my-paper
```

## What it does

1. Checks required system binaries (`pandoc`, `tectonic`, `chktex`, `checkcites`, `latexdiff`, `git`). Prints `brew install` commands for any that are missing and exits non-zero.
2. Records the harness source-repo commit SHA in `paper_config.yaml` for reproducibility.
3. Copies all per-paper templates (see `templates/`) into the target directory, substituting `{{PAPER_SLUG}}`, `{{TODAY}}`, `{{HARNESS_SHA}}`, `{{KDENSE_SYMPY_SHA}}` placeholders.
4. Creates the per-paper directory tree: `paper/`, `worklog/` (with `research/`, `review/`, `transcripts/` nested under it), `source/`, `related/`, and `logs/`.
5. Installs the always-on hook scripts and the full set of workflow + library skills (real `SKILL.md` bodies — not stubs) into `.claude/`. The workflow entry points (`/start-paper`, `/scope-paper`, `/draft-paper`, `/onboard-paper`, `/refine-light`, `/refine-heavy`, `/research`, `/verify-symbolic`, `/verify-numerical`, `/find-cite`, `/sync-zotero`, `/export-coauthor`, `/signoff`) are installed as skills and are invocable as slash commands inside the paper repo.
6. Creates a Python virtual environment (`.venv/`) with required dependencies.
7. Prints next-step instructions pointing the user to `SETUP.md`.

## Idempotency

Existing files are preserved — the installer never clobbers your work. Interactive runs prompt before overwriting per-paper templates and skill bodies that already exist; non-interactive (agent-driven) runs skip them instead. Hooks, helper scripts, `.claude/settings.json`, and `.githooks/` are kept if present. Directory creation and the `.venv` refresh are always safe. Success = `install.sh` exits 0.
