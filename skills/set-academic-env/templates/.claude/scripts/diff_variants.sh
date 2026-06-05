#!/usr/bin/env bash
# Show what variant B adds/changes over variant A (latexdiff on flattened wrappers).
# Usage: diff_variants.sh <A.tex> <B.tex> [out.tex]
set -euo pipefail
A="$1"; B="$2"; OUT="${3:-}"
DIR="$(cd "$(dirname "$0")" && pwd)"
FA=$(mktemp); FB=$(mktemp); trap 'rm -f "$FA" "$FB"' EXIT
python3 "$DIR/flatten_tex.py" "$A" > "$FA"
python3 "$DIR/flatten_tex.py" "$B" > "$FB"
if command -v latexdiff >/dev/null 2>&1; then
  if [ -n "$OUT" ]; then latexdiff "$FA" "$FB" > "$OUT"; echo "wrote $OUT"; else latexdiff "$FA" "$FB"; fi
else
  echo "latexdiff not found — plain diff:" >&2; diff "$FA" "$FB" || true
fi
