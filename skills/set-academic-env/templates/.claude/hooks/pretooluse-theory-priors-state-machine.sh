#!/usr/bin/env bash
# PreToolUse on Edit|Write: refuse model_class_status transitions that violate
# the candidate → declared → locked state machine. Per ADR 0008.

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
LOG="${CLAUDE_PROJECT_DIR:-$PWD}/logs/hooks.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] theory-priors-state-machine: $*" >> "$LOG"; }

if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

if ! echo "$TOOL_INPUT" | grep -q "THEORY_PRIORS.md"; then
  exit 0
fi

# Only care if the edit mentions model_class_status
if ! echo "$TOOL_INPUT" | grep -q "model_class_status"; then
  exit 0
fi

PRIORS_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/THEORY_PRIORS.md"
if [ ! -f "$PRIORS_FILE" ]; then
  exit 0
fi

# Read current status
current=$(grep "model_class_status:" "$PRIORS_FILE" 2>/dev/null | head -1 | awk '{print $2}') || true
current=$(echo "$current" | tr -d '"' | tr -d "'")

# Read proposed new status from the edit
proposed=$(echo "$TOOL_INPUT" | grep -o 'model_class_status:[^"]*"[^"]*"' | tail -1 | awk -F'"' '{print $2}') || true

if [ -z "$proposed" ]; then
  # Try alternate extraction
  proposed=$(echo "$TOOL_INPUT" | python3 -c "
import sys, re
data = sys.stdin.read()
m = re.search(r'model_class_status:\s*(\w+)', data)
if m: print(m.group(1))
" 2>/dev/null) || true
fi

if [ -z "$proposed" ] || [ "$proposed" = "$current" ]; then
  log "allowed: model_class_status unchanged or not determinable"
  exit 0
fi

# Validate transition
valid=0
case "$current" in
  candidate) [ "$proposed" = "declared" ] && valid=1 ;;
  declared)  [ "$proposed" = "locked" ] && valid=1 ;;
  locked)    valid=0 ;;  # locked is terminal
  *)         valid=1 ;;  # unknown current state: allow (bootstrap edge case)
esac

if [ "$valid" -eq 1 ]; then
  log "allowed: model_class_status transition $current → $proposed"
  exit 0
fi

log "BLOCKED: invalid model_class_status transition $current → $proposed"
echo "BLOCKED: Invalid model_class_status transition: $current → $proposed. Allowed transitions: candidate → declared → locked (terminal). Reverse transitions are not permitted." >&2
exit 1
