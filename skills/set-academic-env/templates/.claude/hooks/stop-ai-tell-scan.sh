#!/usr/bin/env bash
# Stop hook: invoke lane1-ai-tell-scan on any Claude-generated prose this session.
# Per session-01 Q8. Non-blocking — results are advisory.

set -euo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="$PROJECT/logs/hooks.log"
ms=$(grep -E '^[[:space:]]*manuscript:' "$PROJECT/paper_config.yaml" 2>/dev/null | head -1 \
     | sed -E 's/.*manuscript:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d '[:space:]') || true
MANUSCRIPT="${ms:-paper/main.tex}"
MAIN_TEX="$PROJECT/$MANUSCRIPT"
ws=$(grep -E '^[[:space:]]*workspace:' "$PROJECT/paper_config.yaml" 2>/dev/null | head -1 \
     | sed -E 's/.*workspace:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d '[:space:]') || true
WORKSPACE="${ws:-worklog}"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] stop-ai-tell-scan: $*" >> "$LOG"; }

# If no manuscript yet, skip
if [ ! -f "$MAIN_TEX" ]; then
  log "no manuscript found at $MANUSCRIPT — skip"
  exit 0
fi

# Produce a flattened temp file for section-aware scanning (modular papers).
# Falls back to the raw manuscript if flatten_tex.py is missing (monolithic papers unaffected).
FLATTEN_PY="$PROJECT/.claude/scripts/flatten_tex.py"
flat_tmp=""
if [[ -f "$FLATTEN_PY" ]]; then
  flat_tmp=$(mktemp /tmp/flat-aitell-XXXXXX.tex)
  python3 "$FLATTEN_PY" "$MAIN_TEX" > "$flat_tmp" 2>/dev/null || true
  [[ -s "$flat_tmp" ]] || { rm -f "$flat_tmp"; flat_tmp=""; }
fi
# Use flattened file for modification check and scan; fall back to raw
scan_target="${flat_tmp:-$MAIN_TEX}"

# Check if manuscript was modified this session (within last 30 minutes as heuristic)
if ! find "$MAIN_TEX" -mmin -30 2>/dev/null | grep -q .; then
  [ -n "$flat_tmp" ] && rm -f "$flat_tmp" || true
  log "manuscript not recently modified — skip AI-tell scan"
  exit 0
fi

log "manuscript modified this session — AI-tell scan queued for next /refine-* run (scan target: $scan_target)"
# The actual lane1-ai-tell-scan invocation happens inside /refine-* Phase 5.
# This hook logs that the scan should occur and can surface a reminder if
# the session ends without a /refine-* run.

# Clean up flattened temp file
[ -n "$flat_tmp" ] && rm -f "$flat_tmp" || true

# Check if a review report exists from this session
latest_report=$(ls -t "$PROJECT/$WORKSPACE/review"/refine-*.md 2>/dev/null | head -1) || true
if [ -z "$latest_report" ] || ! find "$latest_report" -mmin -30 2>/dev/null | grep -q .; then
  echo "Note: paper/main.tex was modified this session but no /refine-* run was completed. Consider running /refine-light to get an AI-tell scan and integrity check." >&2
  log "reminder: paper/main.tex modified without /refine-* run"
fi

exit 0
