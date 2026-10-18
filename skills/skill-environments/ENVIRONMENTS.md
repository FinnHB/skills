# Skill Environments

Named collections of skills that span multiple projects — a level above
project-level skills. Managed by the `skill-environments` extension
(`~/.pi/agent/extensions/skill-environments/index.ts`).

## Layout

```
~/.pi/skill-environments/
└── <environment-name>/    # e.g. academic, matt-pocock
    ├── description.txt    # optional: one-sentence blurb shown in the picker
    └── <skill-name>/
        └── SKILL.md       # normal pi skill
```

An environment is a plain directory of normal skills. Because
`~/.pi/skill-environments/` is not one of pi's auto-discovery paths,
everything here is **inert until activated**.

`description.txt` (optional, first non-`#` line, ~120 chars) is shown next to
the environment name in the `/skill-environment` dropdown. Without it, the
picker derives a fallback like "38 skills: a-philosophy-of-software-design, …".

## Activating an environment

- **Interactive:** `/skill-environment` in any project opens a dropdown of
  available environments. The active environment is always shown in the
  footer (`env: <name>`).
- **For one project (persistent):** `/skill-environment academic`, or
  `/skill-environment` and pick from the dropdown. This writes the name into
  `<project>/.pi-environments` (one name per line, `#` comments allowed) and
  reloads. Clear with `/skill-environment (none — deactivate all)` or by
  emptying the file. Commit `.pi-environments` to the project repo to share
  it with teammates.
- **For one invocation (ad hoc):** `PI_SKILL_ENVIRONMENTS=academic pi`
- **For all projects (global):** add to `~/.pi/agent/settings.json`:
  ```json
  { "skills": ["~/.pi/skill-environments/academic"] }
  ```

## Precedence

User skills (`~/.pi/agent/skills`) and project skills (`.pi/skills`) load
first; pi keeps the first skill found on a name collision. An environment
therefore **cannot override** your own skills — if an environment skill
shares a name with one of yours, yours wins and pi logs a collision warning.
