# set-python-env

Two-phase Python project bootstrap:

1. **Environment setup** — creates `.venv/`, standard folders (`scripts/`, `tests/`, `data/`), `.gitignore`, `requirements.txt`, and a structured `README.md` (each only if missing).
2. **Session coding principles** — loads the Python conventions in [`principles.md`](principles.md) for the rest of the session: venv-only execution, MVP-first, type hints + docstrings everywhere, `pathlib`/`logging`, pinned dependencies, per-script pytest layout with markers, README maintenance.

## Usage examples

```
/set-python-env
```
Run from a (possibly empty) project root at the start of a Python session.

## When to use

- Starting a brand-new Python project
- Beginning a session in an existing Python project where the coding principles should apply
