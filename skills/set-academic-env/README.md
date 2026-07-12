# set-academic-env

Bootstraps an AcademicPaperWriter paper repository in the current (or named) directory. Installs its skills, hooks, templates, and MCP wiring from the bundled `templates/` tree. Idempotent — safe to re-run to pick up harness updates.

## Files

| Path | Purpose |
|------|---------|
| `SKILL.md` | Main skill instructions |
| `install.sh` | Installer script that copies the harness into the target directory |
| `templates/` | The full AcademicPaperWriter harness (CLAUDE.md, hooks, nested skills, configs) |

## Usage examples

```
/set-academic-env
```
Scaffold the harness into the current directory.

```
/set-academic-env my-new-paper
```
Scaffold into a named target directory.

## When to use

- Initializing a new academic paper repository
- Re-running in an existing paper repo to sync harness updates

## Reinstalling / updating the skill

After updating the harness source repo, refresh this skill with:

```bash
mkdir -p ~/.claude/skills/set-academic-env
cp ~/Documents/AcademicPaperWriter/skills/set-academic-env/SKILL.md ~/.claude/skills/set-academic-env/
cp ~/Documents/AcademicPaperWriter/skills/set-academic-env/install.sh ~/.claude/skills/set-academic-env/
cp -r ~/Documents/AcademicPaperWriter/templates ~/.claude/skills/set-academic-env/
```
