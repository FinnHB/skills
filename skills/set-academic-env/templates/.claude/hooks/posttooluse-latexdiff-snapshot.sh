#!/usr/bin/env bash
# PostToolUse on Edit|Write to *.tex: run latexdiff and save snapshot.
# Per ADR 0001 AI-edit attribution recipe.

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="$PROJECT/logs/hooks.log"
ws=$(grep -E '^[[:space:]]*workspace:' "$PROJECT/paper_config.yaml" 2>/dev/null | head -1 \
     | sed -E 's/.*workspace:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d '[:space:]') || true
WORKSPACE="${ws:-worklog}"
TRANSCRIPTS="$PROJECT/$WORKSPACE/transcripts"
mkdir -p "$(dirname "$LOG")" "$TRANSCRIPTS"

log() { echo "[$(date -u +%FT%TZ)] latexdiff-snapshot: $*" >> "$LOG"; }

# Only for Edit and Write
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

# Only for .tex files
if ! echo "$TOOL_INPUT" | grep -qE '\.tex'; then
  exit 0
fi

# Extract file path from tool input
file_path=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null) || true

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  log "skip: could not determine tex file path"
  exit 0
fi

# Check latexdiff is available
if ! command -v latexdiff &>/dev/null; then
  log "WARNING: latexdiff not installed — snapshot skipped (install: brew install latexdiff)"
  exit 0
fi

# Find the most recent prior snapshot of this file to diff against
basename_tex=$(basename "$file_path" .tex)
# Use git to get the previous committed version as the "before"
if git -C "$PROJECT" rev-parse HEAD &>/dev/null 2>&1; then
  prev_file=$(mktemp /tmp/prev-XXXXXX.tex)
  git -C "$PROJECT" show "HEAD:$(git -C "$PROJECT" ls-files --full-name "$file_path" 2>/dev/null)" > "$prev_file" 2>/dev/null || cp "$file_path" "$prev_file"

  ts=$(date -u +%Y%m%d-%H%M%S)
  diff_path="$TRANSCRIPTS/refine-${ts}.diff"

  # Flatten both old and new to make latexdiff section-aware (modular papers).
  # Falls back to the raw files if flatten_tex.py is missing (monolithic papers unaffected).
  FLATTEN_PY="$PROJECT/.claude/scripts/flatten_tex.py"
  if [[ -f "$FLATTEN_PY" ]]; then
    flat_prev=$(mktemp /tmp/flat-prev-XXXXXX.tex)
    flat_curr=$(mktemp /tmp/flat-curr-XXXXXX.tex)
    python3 "$FLATTEN_PY" "$prev_file" > "$flat_prev" 2>/dev/null || true
    python3 "$FLATTEN_PY" "$file_path" > "$flat_curr" 2>/dev/null || true
    # Use flattened files if they are non-empty; otherwise fall back to raw
    if [[ -s "$flat_prev" && -s "$flat_curr" ]]; then
      latexdiff "$flat_prev" "$flat_curr" > "$diff_path" 2>/dev/null || true
    else
      latexdiff "$prev_file" "$file_path" > "$diff_path" 2>/dev/null || true
    fi
    rm -f "$flat_prev" "$flat_curr"
  else
    latexdiff "$prev_file" "$file_path" > "$diff_path" 2>/dev/null || true
  fi
  rm -f "$prev_file"

  log "snapshot saved: $diff_path"
else
  log "skip: not a git repo"
fi

exit 0
