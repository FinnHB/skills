---
name: init-claude-permissions
description: Create or update a project-level .claude/settings.json with auto-approval permissions for Python development. Use when starting a Python project and the user wants sensible default permissions configured.
metadata:
  version: "1.0.1"
---

Create a `.claude/settings.json` file in the current project root with auto-approval permissions configured for Python development.

The file should contain:
```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read",
      "Edit",
      "Write",
      "Glob",
      "Grep",
      "MultiEdit",
      "NotebookEdit",
      "WebSearch",
      "WebFetch",
      "Bash(python *)",
      "Bash(python3 *)",
      "Bash(pip *)",
      "Bash(pip3 *)",
      "Bash(pytest *)",
      "Bash(python -m pytest *)",
      "Bash(python -m *)",
      "Bash(.venv/bin/python *)",
      "Bash(.venv/bin/python3 *)",
      "Bash(.venv/bin/pip *)",
      "Bash(.venv/bin/pytest *)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(find *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(echo *)",
      "Bash(which *)",
      "Bash(wc *)",
      "Bash(diff *)",
      "Bash(file *)",
      "Bash(stat *)",
      "Bash(mkdir *)",
      "Bash(touch *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(rm *)",
      "Bash(git status *)",
      "Bash(git log *)",
      "Bash(git diff *)",
      "Bash(git branch *)",
      "Bash(git show *)",
      "Bash(git stash list *)",
      "Bash(env *)",
      "Bash(printenv *)",
      "Bash(conda *)"
    ],
    "deny": [
      "Bash(sudo *)",
      "Bash(rm -rf *)",
      "Bash(git push *)",
      "Bash(git reset *)",
      "Bash(git rebase *)",
      "Bash(git merge *)",
      "Bash(git checkout *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(chmod *)",
      "Bash(chown *)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(kill *)",
      "Bash(pkill *)",
      "Bash(brew *)"
    ]
  }
}
```

Note: deny rules take precedence over allow rules. For example, `Bash(rm *)` is allowed but `Bash(rm -rf *)` is denied — targeted deletion works, mass deletion is blocked.

Steps:
1. Check if `.claude/settings.json` already exists in the current project root
2. If it does:
   - Inform the user that a permissions file already exists
   - Show a clear before/after diff of what would change
   - Ask the user whether they want to:
     a. **Overwrite** — replace the file entirely with the default config above
     b. **Update** — merge the new entries into the existing config, preserving any custom settings
     c. **Cancel** — leave the file unchanged
   - Only proceed once the user selects an option and confirms
3. If it doesn't exist, create `.claude/` directory if needed, then create the file with the content above
4. Re-read the written file and confirm it is valid JSON containing both the `allow` and `deny` blocks
