#!/usr/bin/env bash
# PostToolUse on Edit|Write to *.tex: run chktex + checkcites (advisory, non-blocking).
# Per session-01 Q8. Warnings are surfaced; never block writer flow.

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="$PROJECT/logs/hooks.log"
ms=$(grep -E '^[[:space:]]*manuscript:' "$PROJECT/paper_config.yaml" 2>/dev/null | head -1 \
     | sed -E 's/.*manuscript:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d '[:space:]') || true
MANUSCRIPT="${ms:-paper/main.tex}"
rf=$(grep -E '^[[:space:]]*references:' "$PROJECT/paper_config.yaml" 2>/dev/null | head -1 \
     | sed -E 's/.*references:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d '[:space:]') || true
REFERENCES="${rf:-paper/references.bib}"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] lint-tex: $*" >> "$LOG"; }

if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

if ! echo "$TOOL_INPUT" | grep -qE '\.tex'; then
  exit 0
fi

file_path=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null) || true

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

warnings=""

# Produce a flattened temp file for section-aware linting (modular papers).
# Falls back to the real file if flatten_tex.py is missing (monolithic papers unaffected).
FLATTEN_PY="$PROJECT/.claude/scripts/flatten_tex.py"
lint_target="$file_path"
flat_tmp=""
if [[ -f "$FLATTEN_PY" ]]; then
  flat_tmp=$(mktemp /tmp/flat-lint-XXXXXX.tex)
  python3 "$FLATTEN_PY" "$file_path" > "$flat_tmp" 2>/dev/null || true
  if [[ -s "$flat_tmp" ]]; then
    lint_target="$flat_tmp"
  fi
fi

# chktex — style/syntax warnings (run on flattened content; edit the real file)
if command -v chktex &>/dev/null; then
  chktex_out=$(chktex -q "$lint_target" 2>&1) || true
  if [ -n "$chktex_out" ]; then
    warnings="${warnings}chktex: ${chktex_out}\n"
  fi
  log "chktex ran on $file_path (via flatten)"
else
  log "WARNING: chktex not installed (brew install chktex)"
fi

# checkcites — citation warnings (only on the manuscript)
if echo "$file_path" | grep -q "main\.tex"; then
  bib="${PROJECT}/${REFERENCES}"
  if command -v checkcites &>/dev/null && [ -f "$bib" ]; then
    checkcites_out=$(checkcites --backend biber "$lint_target" 2>&1) || true
    if echo "$checkcites_out" | grep -qiE "warning|unused|undefined"; then
      warnings="${warnings}checkcites: ${checkcites_out}\n"
    fi
    log "checkcites ran on $file_path (via flatten)"
  elif ! command -v checkcites &>/dev/null; then
    log "WARNING: checkcites not installed"
  fi
fi

# Clean up flattened temp file
[ -n "$flat_tmp" ] && rm -f "$flat_tmp" || true

# Print warnings (advisory — always exit 0)
if [ -n "$warnings" ]; then
  echo "" >&2
  echo "── LaTeX lint warnings (advisory) ──────────────────" >&2
  printf "%b" "$warnings" >&2
  echo "────────────────────────────────────────────────────" >&2
fi

exit 0
