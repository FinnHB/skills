#!/usr/bin/env bash
# Stop hook: if this session ran /refine-*, confirm the lean JSON sidecar exists and log it.
# Reads worklog/review/<command>-<ts>.json (written by the integrity-gate skill).
# Per Phase 14: no prose-scraping; sidecar is the machine source of truth.

set -euo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="$PROJECT/logs/hooks.log"
ws=$(grep -E '^[[:space:]]*workspace:' "$PROJECT/paper_config.yaml" 2>/dev/null | head -1 \
     | sed -E 's/.*workspace:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d '[:space:]') || true
WORKSPACE="${ws:-worklog}"
REVIEW_DIR="$PROJECT/$WORKSPACE/review"
mkdir -p "$(dirname "$LOG")" "$REVIEW_DIR"

log() { echo "[$(date -u +%FT%TZ)] stop-integrity-gate-report: $*" >> "$LOG"; }

# Find the most recent sidecar from this session (any command)
latest_sidecar=$(ls -t "$REVIEW_DIR"/*.json 2>/dev/null | head -1) || true

if [ -z "$latest_sidecar" ]; then
  log "no sidecar found this session — skip"
  exit 0
fi

# Only act on a sidecar written in the last 30 minutes (this session's)
if ! find "$latest_sidecar" -mmin -30 2>/dev/null | grep -q .; then
  log "latest sidecar is from a prior session — skip"
  exit 0
fi

# Read command and overall verdict from sidecar (python3 already used elsewhere)
result=$(python3 -c "
import json, sys
try:
    with open('$latest_sidecar') as f:
        d = json.load(f)
    cmd = d.get('command', '(unknown command)')
    gate = d.get('integrity_gate', {})
    overall = gate.get('overall', '(no gate)')
    report = d.get('report', '$latest_sidecar')
    print(cmd + '|' + overall + '|' + report)
except Exception as e:
    print('error|error|' + str(e))
" 2>/dev/null) || result="error|error|parse failed"

cmd=$(echo "$result" | cut -d'|' -f1)
overall=$(echo "$result" | cut -d'|' -f2)
report=$(echo "$result" | cut -d'|' -f3)

log "sidecar confirmed: $latest_sidecar | command: $cmd | integrity gate overall: $overall | report: $report"
exit 0
