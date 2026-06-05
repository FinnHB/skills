Set up a Python project environment and load coding principles for this session.

## Phase 1 — Environment Setup

Work through these steps in order, checking what already exists before making any changes:

**1. Permissions**
Run `/init-claude-permissions` to ensure project-level auto-approval permissions are configured.

**2. Virtual environment**
Check for an existing virtual environment (`.venv/`, `venv/`, `env/`):
- If found: confirm it exists and note which Python it uses
- If not found: create one with `python3 -m venv .venv` and confirm creation

**3. Default folders**
Check for and create any missing standard directories:
- `scripts/` — main Python scripts
- `tests/` — test files
- `data/` — supplementary data and inputs

**4. `.gitignore`**
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

**5. `requirements.txt`**
Check for `requirements.txt`. If missing, create an empty one with a comment:
```
# Pin all package versions, e.g. numpy==1.26.4
```

**6. `README.md`**
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

For the remainder of this session, follow these principles when writing any Python code:

### Virtual environment
- Run all `python`, `pip`, and `pytest` commands using the project venv: `.venv/bin/python`, `.venv/bin/pip`, `.venv/bin/pytest`
- Never install packages globally

### MVP first
- Build the simplest working version before adding features or optimising
- Before marking any task complete: run the code and confirm it produces the expected output
- Never assume code works — validate it by running it

### Code architecture
- One function = one responsibility; no function should do multiple unrelated things
- Keep cross-script dependencies minimal and explicit
- Decide deliberately what goes in `if __name__ == "__main__"` (entry point logic) vs what's importable (reusable functions/classes)
- Use classes to group related state and behaviour when multiple scripts share the same data or logic

### Docstrings and type hints
- Every script: module-level docstring at the top explaining what it does, plus `Last updated: YYYY-MM-DD`
- Every function: docstring with description, parameters, return value, and a minimal usage example where it makes sense
- All function signatures must have type hints:
  ```python
  def process_raster(path: Path, resolution: float = 1.0) -> np.ndarray:
  ```

### Code quality
- Define magic numbers and strings as named constants at module level — never bury them in functions
- Use `pathlib.Path` for all file paths, not raw strings
- Use the `logging` module (with appropriate levels: `DEBUG`, `INFO`, `WARNING`, `ERROR`) instead of `print` for anything beyond throwaway debugging
- Raise meaningful exceptions with context — no silent failures, no bare `except` clauses

### Testing
- Test files live in `tests/`, one per script: `tests/test_<module>.py`
- Tests are cumulative — update them when code changes, remove them when a feature is removed
- Use pytest markers to allow selective test runs:
  ```python
  @pytest.mark.core
  def test_something(): ...
  ```
  Run subsets with `pytest -m core` without running the entire suite
- Confirm all relevant tests pass before marking a task complete

### Dependencies
- Pin all versions in `requirements.txt` (e.g. `numpy==1.26.4`)
- Prefer the standard library over third-party packages where reasonable

### README maintenance
- Update the `README.md` Scripts table whenever a new script or test file is created or removed
- Keep the Overview section accurate as the project evolves
