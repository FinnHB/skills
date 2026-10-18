# skill-environments

A [pi](https://github.com/earendil-works/pi-coding-agent) **extension**, not a
model-invoked skill — there is no `SKILL.md` because there is nothing for the
model to execute. Install it into pi's extension directory and it contributes a
`/skill-environment` command plus skill-path plumbing.

## What it does

Adds a level of abstraction above project-level skills: named **environments**
of skills that span multiple projects (e.g. `academic` for all academic writing
work, `matt-pocock` for an imported skill suite). Environments live in
`~/.pi/skill-environments/<name>/`, each containing normal skill directories
(`SKILL.md`). Because that path is outside pi's auto-discovery paths, an
environment is **inert until activated** for a given project.

Activation (all sources merge, deduped):

1. `PI_SKILL_ENVIRONMENTS` env var — comma-separated names (ad hoc, per invocation)
2. `.pi-environments` file — walked up from cwd to the git root, one name per
   line, `#` comments allowed (persistent, per-project)

Precedence is safe: user/project skills load before environment skills and pi
keeps the first skill found on name collisions, so environments never override
your own skills.

## Commands

- `/skill-environment` — dropdown picker; each option shows a one-sentence
  description (from `<env>/description.txt`, or derived from the skills it
  contains). The chosen environment is written to `.pi-environments` and the
  session reloads.
- `/skill-environment <name>` — activate `<name>` directly (comma-separated
  list accepted).
- The footer always shows the currently active environment(s).

## Install

```bash
mkdir -p ~/.pi/agent/extensions/skill-environments
cp index.ts ~/.pi/agent/extensions/skill-environments/index.ts
```

Then create environments and manage them as described in
[ENVIRONMENTS.md](ENVIRONMENTS.md) (layout, activation, precedence).
