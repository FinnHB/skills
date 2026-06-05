#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# Resolve a Python: prefer the module's own venv, then python, then python3.
if [ -x .venv/bin/python ]; then PY=.venv/bin/python
elif command -v python >/dev/null 2>&1; then PY=python
else PY=python3; fi
export PYTHONPATH="$PWD${PYTHONPATH:+:$PYTHONPATH}"
for s in src/[0-9]*.py; do [ -e "$s" ] || continue; echo "── $s ──"; "$PY" "$s"; done
"$PY" pipeline.py check
