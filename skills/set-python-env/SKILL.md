---
name: set-python-env
description: Set up a Python project environment (venv, folders, .gitignore, requirements.txt, README) and load Python coding principles for the session. Use when starting a new Python project or when the user wants the session to follow their Python conventions.
metadata:
  version: "1.1.0"
---

## Phase 1 — Environment Setup

Work through these steps in order, checking what already exists before making any changes:

**1. Virtual environment**
Check for an existing virtual environment (`.venv/`, `venv/`, `env/`):
- If found: confirm it exists and note which Python it uses
- If not found: create one with `python3 -m venv .venv` and confirm creation

**2. Default folders**
Check for and create any missing standard directories:
- `scripts/` — main Python scripts
- `tests/` — test files
- `data/` — supplementary data and inputs

**3. `.gitignore`**
Check for `.gitignore`. Ensure it includes at minimum:
```
.venv/
venv/
env/
__pycache__/
*.pyc
*.pyo
.DS_Store
```
Create the file if it doesn't exist; append missing entries if it does.

**4. `requirements.txt`**
Check for `requirements.txt`. If missing, create an empty one with a comment:
```
# Pin all package versions, e.g. numpy==1.26.4
```

**5. `README.md`**
Check for `README.md`. If missing, create one using this structure:
```markdown
# <Project Name>

## Overview
<What this project does and why — 2-4 sentences>

## Scripts

### scripts/
| File | Description |
|------|-------------|
| *(add entries as scripts are created)* | |

### tests/
| File | Description |
|------|-------------|
| *(add entries as tests are created)* | |

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Usage
*(Add only if non-obvious; otherwise covered in Overview)*
```

If `README.md` already exists, leave it unchanged.

After completing setup, print a brief summary of what was found, what was created, and the path to the active virtual environment.

---

## Phase 2 — Session Coding Principles

Read [principles.md](principles.md) now and follow those Python conventions for the rest of the session — venv-only execution, MVP-first, type hints and docstrings, `pathlib`/`logging`, pinned dependencies, a per-script pytest layout, and README upkeep. Load them before writing any code.
