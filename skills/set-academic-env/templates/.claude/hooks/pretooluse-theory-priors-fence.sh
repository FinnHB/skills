#!/usr/bin/env bash
# PreToolUse on Edit|Write: refuse any edit that touches lines inside
# <!-- BEGIN USER-SPECIFIED --> ... <!-- END USER-SPECIFIED --> in THEORY_PRIORS.md.
# Per ADR 0008.

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
LOG="${CLAUDE_PROJECT_DIR:-$PWD}/logs/hooks.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] theory-priors-fence: $*" >> "$LOG"; }

# Only applies to Edit and Write tools
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

# Only applies when the target file is THEORY_PRIORS.md
if ! echo "$TOOL_INPUT" | grep -q "THEORY_PRIORS.md"; then
  exit 0
fi

# Check if the edit targets any content inside the USER-SPECIFIED fence
if echo "$TOOL_INPUT" | grep -qE 'BEGIN USER-SPECIFIED|END USER-SPECIFIED'; then
  log "BLOCKED: attempt to edit USER-SPECIFIED fence markers in THEORY_PRIORS.md"
  echo "BLOCKED: The <!-- BEGIN USER-SPECIFIED --> / <!-- END USER-SPECIFIED --> fence markers in THEORY_PRIORS.md are inviolable. Edit the content inside the fence (the hard constraints block), not the markers themselves." >&2
  exit 1
fi

# Check if old_string or content being written falls inside the fenced region
# by reading the current file and checking line positions
PRIORS_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/THEORY_PRIORS.md"
if [ ! -f "$PRIORS_FILE" ]; then
  exit 0
fi

# Extract the fence content to detect if the proposed edit targets it
fence_content=$(awk '/<!-- BEGIN USER-SPECIFIED -->/,/<!-- END USER-SPECIFIED -->/' "$PRIORS_FILE" 2>/dev/null) || true

if [ -z "$fence_content" ]; then
  exit 0
fi

# If any line of the proposed old_string matches fence content exactly, block
# (Heuristic: extract old_string from JSON input if available)
old_string=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('old_string',''))" 2>/dev/null) || true

if [ -n "$old_string" ] && echo "$fence_content" | grep -qF "$old_string"; then
  log "BLOCKED: edit targets content inside USER-SPECIFIED fence"
  echo "BLOCKED: The proposed edit targets content inside the <!-- BEGIN USER-SPECIFIED --> fence in THEORY_PRIORS.md. This section contains user-specified hard constraints and must be edited manually by the author, not by the AI." >&2
  exit 1
fi

log "allowed: $TOOL_NAME on THEORY_PRIORS.md (outside fence)"
exit 0
