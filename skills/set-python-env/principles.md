# Python coding principles

Loaded for the session by [set-python-env](SKILL.md) (Phase 2). Follow these when writing any Python code for the rest of the session.

### Virtual environment
- Run all `python`, `pip`, and `pytest` commands through the project venv: `.venv/bin/python`, `.venv/bin/pip`, `.venv/bin/pytest`

### MVP first
- Build the simplest working version before adding features or optimising
- Before marking any task complete, run the code and confirm it produces the expected output

### Code architecture
- One function = one responsibility; no function should do multiple unrelated things
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
- Raise meaningful exceptions with context; catch specific exception types rather than a bare `except`

### Testing
- Test files live in `tests/`, one per script: `tests/test_<module>.py`
- Use pytest markers to allow selective test runs:
  ```python
  @pytest.mark.core
  def test_something(): ...
  ```
  Run subsets with `pytest -m core` without running the entire suite
- Confirm all relevant tests pass before marking a task complete

### Dependencies
- Pin all versions in `requirements.txt` (e.g. `numpy==1.26.4`)

### README maintenance
- Update the `README.md` Scripts table whenever a new script or test file is created or removed
- Keep the Overview section accurate as the project evolves
