#!/usr/bin/env bash
# Stop hook: append one CHANGELOG.md entry per /refine-* run this session.
# Idempotent via run timestamp: checks if the entry already exists before appending.
# Per Phase 14: reads lean JSON sidecar (worklog/review/<command>-<ts>.json), not prose.

set -euo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="$PROJECT/logs/hooks.log"
CHANGELOG="$PROJECT/CHANGELOG.md"
ws=$(grep -E '^[[:space:]]*workspace:' "$PROJECT/paper_config.yaml" 2>/dev/null | head -1 \
     | sed -E 's/.*workspace:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d '[:space:]') || true
WORKSPACE="${ws:-worklog}"
REVIEW_DIR="$PROJECT/$WORKSPACE/review"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] stop-changelog-append: $*" >> "$LOG"; }

# Find the most recent sidecar from this session (any command)
latest_sidecar=$(ls -t "$REVIEW_DIR"/*.json 2>/dev/null | head -1) || true

if [ -z "$latest_sidecar" ]; then
  log "no sidecar found — no CHANGELOG entry needed"
  exit 0
fi

# Only write if sidecar is recent (this session's)
if ! find "$latest_sidecar" -mmin -30 2>/dev/null | grep -q .; then
  log "latest sidecar is from a prior session — skip"
  exit 0
fi

# Extract timestamp from sidecar filename: worklog/review/refine-20260531-142300.json
ts=$(basename "$latest_sidecar" .json | sed 's/^[^-]*-//')

# Check idempotency: if this timestamp already appears in CHANGELOG.md, skip
if [ -f "$CHANGELOG" ] && grep -q "$ts" "$CHANGELOG"; then
  log "CHANGELOG entry for $ts already exists — skip (idempotent)"
  exit 0
fi

# Read all relevant fields from the sidecar via python3
fields=$(python3 -c "
import json, sys
try:
    with open('$latest_sidecar') as f:
        d = json.load(f)
    cmd = d.get('command', '/refine')
    gate = d.get('integrity_gate', {})
    overall = gate.get('overall', '')
    layer2 = gate.get('layer_2', '')
    lane = d.get('lane_1', {})
    citation = lane.get('citation_existence', '')
    claim = lane.get('claim_match', '')
    report = d.get('report', '')
    diff = d.get('diff', '')
    # Build pipe-separated output; empty string means field absent
    print('|'.join([cmd, overall, layer2, citation, claim, report, diff]))
except Exception as e:
    sys.exit(1)
" 2>/dev/null) || { log "sidecar parse failed — skip"; exit 0; }

cmd=$(echo "$fields"    | cut -d'|' -f1)
overall=$(echo "$fields"  | cut -d'|' -f2)
layer2=$(echo "$fields"   | cut -d'|' -f3)
citation=$(echo "$fields" | cut -d'|' -f4)
claim=$(echo "$fields"    | cut -d'|' -f5)
report=$(echo "$fields"   | cut -d'|' -f6)
diff_path=$(echo "$fields"| cut -d'|' -f7)

# Format date for header from ts (YYYYMMDD-HHMMSS)
date_fmt=$(date -j -f "%Y%m%d-%H%M%S" "$ts" "+%Y-%m-%d %H:%M" 2>/dev/null || \
           date -d "${ts:0:8} ${ts:9:2}:${ts:11:2}:${ts:13:2}" "+%Y-%m-%d %H:%M" 2>/dev/null || \
           echo "$ts")

# Create CHANGELOG.md if it doesn't exist
if [ ! -f "$CHANGELOG" ]; then
  printf "# CHANGELOG\n\nAI-assisted edits to this paper, newest first.\n\n" > "$CHANGELOG"
fi

# Build lane-1 summary line (only include fields present in sidecar)
lane_summary=""
if [ -n "$citation" ]; then
  lane_summary="citation: $citation"
fi
if [ -n "$claim" ]; then
  lane_summary="${lane_summary:+$lane_summary | }claim-match: $claim"
fi
if [ -z "$lane_summary" ]; then
  lane_summary="(not run)"
fi

# Build diff line
if [ -n "$diff_path" ]; then
  diff_display="$diff_path"
else
  diff_display="(none)"
fi

# Build report display
if [ -n "$report" ]; then
  report_display=$(basename "$report")
else
  report_display="(none)"
fi

# Prepend entry (newest first) using a temp file
tmpfile=$(mktemp)
{
  head -4 "$CHANGELOG"
  printf "## %s — %s\n" "$date_fmt" "$cmd"
  if [ -n "$layer2" ] || [ -n "$overall" ]; then
    printf -- "- Integrity gate: layer-2: %s | overall: %s\n" "${layer2:-(n/a)}" "${overall:-(n/a)}"
  fi
  printf -- "- Lane 1: %s\n" "$lane_summary"
  printf -- "- Diff: %s\n" "$diff_display"
  printf -- "- Report: %s\n\n" "$report_display"
  tail -n +5 "$CHANGELOG" 2>/dev/null || true
} > "$tmpfile"
mv "$tmpfile" "$CHANGELOG"

log "CHANGELOG entry appended for $ts ($cmd)"
exit 0
