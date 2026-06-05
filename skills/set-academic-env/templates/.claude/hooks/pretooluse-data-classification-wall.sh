#!/usr/bin/env bash
# PreToolUse: data-classification guard (MVP: log-only, no enforcement).
# Full enforcement is MVP+1 DATA_CLASSIFICATION wall.

set -euo pipefail

LOG="${CLAUDE_PROJECT_DIR:-$PWD}/logs/hooks.log"
OPS_LOG="${CLAUDE_PROJECT_DIR:-$PWD}/logs/operations.jsonl"
CONFIG="${CLAUDE_PROJECT_DIR:-$PWD}/paper_config.yaml"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] data-classification-wall: $*" >> "$LOG"; }

classification=$(grep -A1 "^data:" "$CONFIG" 2>/dev/null | grep "classification" | awk -F'"' '{print $2}' | tr -d '[:space:]') || true

if [ -z "$classification" ] || [ "$classification" = "public" ]; then
  exit 0
fi

# Non-public: log a warning and continue (MVP: log-only, enforcement is MVP+1)
log "WARNING: data.classification=$classification — full wall is MVP+1; logging only"

ts=$(date -u +%FT%TZ)
echo "{\"ts\":\"$ts\",\"event\":\"data_classification_warning\",\"classification\":\"$classification\",\"tool\":\"${CLAUDE_TOOL_NAME:-unknown}\"}" >> "$OPS_LOG" 2>/dev/null || true

exit 0
