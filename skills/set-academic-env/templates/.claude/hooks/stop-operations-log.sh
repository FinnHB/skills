#!/usr/bin/env bash
# Stop hook: append one JSONL entry to logs/operations.jsonl per command run.
# One truthful summary entry per session, not per tool call.
# Per Phase 14: reads lean JSON sidecar; no fabricated models_used/tokens/"unknown" fields.
# Idempotent via run_id.

set -euo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="$PROJECT/logs/hooks.log"
OPS_LOG="$PROJECT/logs/operations.jsonl"
ws=$(grep -E '^[[:space:]]*workspace:' "$PROJECT/paper_config.yaml" 2>/dev/null | head -1 \
     | sed -E 's/.*workspace:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d '[:space:]') || true
WORKSPACE="${ws:-worklog}"
REVIEW_DIR="$PROJECT/$WORKSPACE/review"
CONFIG="$PROJECT/paper_config.yaml"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] stop-operations-log: $*" >> "$LOG"; }

# Find the most recent sidecar from this session
latest_sidecar=$(ls -t "$REVIEW_DIR"/*.json 2>/dev/null | head -1) || true

if [ -z "$latest_sidecar" ]; then
  log "no sidecar found this session — skip operations log"
  exit 0
fi

# Only write if sidecar is recent (this session's)
if ! find "$latest_sidecar" -mmin -30 2>/dev/null | grep -q .; then
  log "latest sidecar is from a prior session — skip"
  exit 0
fi

# Generate a short stable run_id from sidecar filename
sidecar_base=$(basename "$latest_sidecar" .json)
run_id="${sidecar_base}-$(head -c4 /dev/urandom | xxd -p 2>/dev/null || echo "0000")"

# Idempotency: check if this sidecar base already logged (use sidecar filename as anchor)
if [ -f "$OPS_LOG" ] && grep -qF "$sidecar_base" "$OPS_LOG"; then
  log "operations.jsonl entry for $sidecar_base already exists — skip"
  exit 0
fi

# Read paper config fields — omit if not found (no "unknown" placeholders)
paper_slug=$(python3 -c "
import re, sys
try:
    txt = open('$CONFIG').read()
    m = re.search(r'^\s*slug:\s*[\"\'']?([^\"\''#\n]+)[\"\'']?', txt, re.M)
    v = m.group(1).strip() if m else ''
    if v and v not in ('{{PAPER_SLUG}}', 'TODO', ''):
        print(v)
except: pass
" 2>/dev/null) || paper_slug=""

harness_version=$(python3 -c "
import re, sys
try:
    txt = open('$CONFIG').read()
    m = re.search(r'^\s*version:\s*[\"\'']?([^\"\''#\n]+)[\"\'']?', txt, re.M)
    v = m.group(1).strip() if m else ''
    if v and v not in ('{{HARNESS_SHA}}', 'TODO', ''):
        print(v)
except: pass
" 2>/dev/null) || harness_version=""

# Build the operations entry from sidecar + config — only truthful fields
ts_now=$(date -u +%FT%TZ)

entry=$(python3 -c "
import json, sys

try:
    with open('$latest_sidecar') as f:
        sidecar = json.load(f)
except Exception as e:
    sys.exit(1)

entry = {
    'ts': '$ts_now',
    'run_id': '$run_id',
    'sidecar': '$latest_sidecar',
}

# Copy command and args from sidecar (only if present)
for key in ('command', 'args', 'ts'):
    if key in sidecar and key != 'ts':
        entry[key] = sidecar[key]

# Add paper_slug and harness_version only if resolved
paper_slug = '$paper_slug'.strip()
harness_version = '$harness_version'.strip()
if paper_slug:
    entry['paper_slug'] = paper_slug
if harness_version:
    entry['harness_version'] = harness_version

# Copy integrity_gate block verbatim from sidecar (already truthful)
if 'integrity_gate' in sidecar:
    entry['integrity_gate'] = sidecar['integrity_gate']

# Copy lane_1 block verbatim from sidecar (only if it ran)
if 'lane_1' in sidecar:
    entry['lane_1'] = sidecar['lane_1']

# Copy open_tktk if present
if 'open_tktk' in sidecar:
    entry['open_tktk'] = sidecar['open_tktk']

# Copy manuscript_sha if present
if 'manuscript_sha' in sidecar:
    entry['manuscript_sha'] = sidecar['manuscript_sha']

# Copy report and diff paths if present
if 'report' in sidecar:
    entry['report'] = sidecar['report']
if 'diff' in sidecar:
    entry['diff'] = sidecar['diff']

print(json.dumps(entry))
" 2>/dev/null) || { log "python3 serialization failed for $latest_sidecar — skip"; exit 0; }

mkdir -p "$(dirname "$OPS_LOG")"
echo "$entry" >> "$OPS_LOG"
log "operations.jsonl entry written: $run_id (sidecar: $sidecar_base)"
exit 0
