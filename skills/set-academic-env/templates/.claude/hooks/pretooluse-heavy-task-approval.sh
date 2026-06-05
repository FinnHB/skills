#!/usr/bin/env bash
# PreToolUse: prompt for approval before heavy tasks.
# Exits 0 (allow) or 1 (block) with message to stderr.

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
LOG="${CLAUDE_PROJECT_DIR:-$PWD}/logs/hooks.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] heavy-task-approval: $*" >> "$LOG"; }

is_heavy=0
reason=""

case "$TOOL_NAME" in
  Bash)
    if echo "$TOOL_INPUT" | grep -qE 'dynare|julia.*dsge|python.*dsge'; then
      is_heavy=1; reason="Bash invocation matches heavy-compute pattern (dynare/julia dsge/python dsge)"
    fi
    ;;
  Agent)
    is_heavy=1; reason="Subagent dispatch — potentially long-running"
    ;;
  Read)
    # Approximate size check: if pages parameter suggests > 50 pages
    if echo "$TOOL_INPUT" | grep -qE '"pages".*[5-9][0-9]|"pages".*[1-9][0-9]{2}'; then
      is_heavy=1; reason="Reading > 50 pages from a document"
    fi
    ;;
esac

# Check slash-command patterns embedded in Bash calls
if [ "$TOOL_NAME" = "Bash" ]; then
  if echo "$TOOL_INPUT" | grep -qE '/verify-numerical'; then
    is_heavy=1; reason="/verify-numerical invocation"
  fi
  if echo "$TOOL_INPUT" | grep -qE '/verify-symbolic'; then
    # Heavy if range or section scope (> 10 equations implied)
    if echo "$TOOL_INPUT" | grep -qE '\.\.|section:'; then
      is_heavy=1; reason="/verify-symbolic with multi-equation scope"
    fi
  fi
fi

if [ "$is_heavy" -eq 0 ]; then
  log "allowed: $TOOL_NAME"
  exit 0
fi

log "intercepted: $TOOL_NAME — $reason"

echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "  HEAVY TASK APPROVAL REQUIRED" >&2
echo "  Tool: $TOOL_NAME" >&2
echo "  Reason: $reason" >&2
echo "  Type 'approve' to continue or anything else to cancel." >&2
echo "  (Auto-cancel in 60 seconds)" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

response=""
if read -r -t 60 response 2>/dev/null; then
  :
else
  log "approval timed out after 60s — blocking"
  echo "Heavy task approval timed out. Re-run to try again." >&2
  exit 1
fi

if [ "$response" = "approve" ]; then
  log "approved by user: $TOOL_NAME — $reason"
  exit 0
else
  log "cancelled by user: $TOOL_NAME — $reason"
  echo "Cancelled. Re-run the command and type 'approve' when prompted." >&2
  exit 1
fi
