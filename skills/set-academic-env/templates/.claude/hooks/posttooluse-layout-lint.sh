#!/usr/bin/env bash
# PostToolUse on Edit|Write: advisory layout-lint for the module-based canonical map.
# Warns when code/data/figure/.tex files land outside the map. NEVER blocks.
# Exits 0 always. Emits zero warnings on a greenfield (no code/) repo.

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="$PROJECT/logs/hooks.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date -u +%FT%TZ)] layout-lint: $*" >> "$LOG"; }

# Only act on Edit or Write
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

# Extract file_path from tool input JSON
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
file_path=$(echo "$TOOL_INPUT" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null) || true

if [ -z "$file_path" ]; then
  exit 0
fi

# Normalize to a path relative to PROJECT (strip leading PROJECT prefix if present)
rel_path="$file_path"
if [[ "$file_path" == "$PROJECT/"* ]]; then
  rel_path="${file_path#$PROJECT/}"
fi

warn() {
  local msg="$1"
  echo "" >&2
  echo "── Layout lint warning (advisory) ──────────────────" >&2
  echo "  $msg" >&2
  echo "────────────────────────────────────────────────────" >&2
  log "WARN: $msg"
}

# ── Helper: get file extension (basename suffix after last dot) ──────────────
ext="${file_path##*.}"
basename_file="$(basename "$file_path")"

# ── Rule 1: code files (.py .jl .R .do .m) outside code/<module>/ ────────────
# Only warn if code/ exists at all (greenfield repos have no code/ → zero noise).
# Allow: code/<module>/... (rel_path must start with "code/" and contain at least 2 slashes)
if [[ "$ext" =~ ^(py|jl|R|do|m)$ ]]; then
  if [ -d "$PROJECT/code" ]; then
    # Must match code/<something>/<rest> — two slashes minimum inside code/
    if ! [[ "$rel_path" == code/*/* ]]; then
      warn "Code file '$rel_path' is outside code/<module>/. Canonical location: code/<module>/src/."
    fi
  fi
fi

# ── Rule 2: data files (.csv .dta .parquet .xlsx) outside module data/ or root data/ ──
if [[ "$ext" =~ ^(csv|dta|parquet|xlsx)$ ]]; then
  # Allow: code/<module>/data/... or data/...
  if ! [[ "$rel_path" == code/*/data/* ]] && ! [[ "$rel_path" == data/* ]]; then
    warn "Data file '$rel_path' is outside a module data/ or root data/. Canonical location: code/<module>/data/ or data/."
  fi
fi

# ── Rule 3: generated-looking figures (fig*/figure* .png or .pdf) at root or in paper/ ──
if [[ "$ext" =~ ^(png|pdf)$ ]]; then
  # Only flag if the basename looks like a generated figure
  if [[ "$basename_file" =~ ^(fig|figure) ]]; then
    # Warn if at repo root or anywhere in paper/ (paper/figures/ is for static only)
    if [[ "$rel_path" != */* ]] || [[ "$rel_path" == paper/* ]]; then
      # Suppress if code/ doesn't exist (theory paper — may legitimately have no module output/)
      if [ -d "$PROJECT/code" ]; then
        warn "Generated-looking figure '$rel_path' should live in code/<module>/output/ (reached via \\graphicspath). 'paper/figures/' is for static hand-made figures only."
      fi
    fi
  fi
fi

# ── Rule 4: .tex files outside paper/ (allow submissions/ and worklog/) ──────
if [[ "$ext" == "tex" ]]; then
  if ! [[ "$rel_path" == paper/* ]] && \
     ! [[ "$rel_path" == submissions/* ]] && \
     ! [[ "$rel_path" == worklog/* ]]; then
    warn ".tex file '$rel_path' is outside paper/ (also allowed: submissions/, worklog/). Canonical location: paper/."
  fi
fi

exit 0
