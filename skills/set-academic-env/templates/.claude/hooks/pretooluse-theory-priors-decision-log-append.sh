#!/usr/bin/env bash
# PreToolUse on Edit|Write: refuse any edit that modifies existing Decision-log
# lines in THEORY_PRIORS.md. Only appends are allowed. Per ADR 0008.

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
LOG="${CLAUDE_PROJECT_DIR:-$PWD}/logs/hooks.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] theory-priors-decision-log: $*" >> "$LOG"; }

if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

if ! echo "$TOOL_INPUT" | grep -q "THEORY_PRIORS.md"; then
  exit 0
fi

PRIORS_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/THEORY_PRIORS.md"
if [ ! -f "$PRIORS_FILE" ]; then
  exit 0
fi

# Extract existing Decision-log entries (lines under the Decision log heading)
existing_log=$(awk '/^## Decision log/,0 {print}' "$PRIORS_FILE" 2>/dev/null | tail -n +2) || true

if [ -z "$existing_log" ]; then
  log "allowed: no existing decision log entries"
  exit 0
fi

# Extract old_string from the edit to check if it targets existing log lines
old_string=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('old_string',''))" 2>/dev/null) || true

if [ -z "$old_string" ]; then
  log "allowed: could not parse old_string"
  exit 0
fi

# If old_string contains any existing decision log line, block
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if echo "$old_string" | grep -qF "$line"; then
    log "BLOCKED: edit targets existing Decision-log entry: $line"
    echo "BLOCKED: The Decision-log in THEORY_PRIORS.md is append-only. You may add new entries but cannot modify existing ones. To correct a prior decision, append a new entry that supersedes it." >&2
    exit 1
  fi
done <<< "$existing_log"

log "allowed: $TOOL_NAME on THEORY_PRIORS.md (decision log not modified)"
exit 0
