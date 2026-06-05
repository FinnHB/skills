#!/usr/bin/env bash
# Bootstrap an AcademicPaperWriter paper repository.
# Usage: install.sh [TARGET_DIR]   (default: current directory)
# Idempotent: prompts before overwriting existing files.
set -euo pipefail

# ── Resolve paths ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_SOURCE="${HARNESS_SOURCE:-$HOME/Documents/AcademicPaperWriter}"

# Templates: prefer skill's own copy, fall back to harness source repo.
if [[ -d "$SCRIPT_DIR/templates" ]]; then
    TEMPLATES_DIR="$SCRIPT_DIR/templates"
elif [[ -d "$HARNESS_SOURCE/templates" ]]; then
    TEMPLATES_DIR="$HARNESS_SOURCE/templates"
else
    echo "ERROR: Cannot find templates directory."
    echo "  Expected: $SCRIPT_DIR/templates"
    echo "  or: $HARNESS_SOURCE/templates"
    echo "  Re-run the skill install command from SKILL.md."
    exit 1
fi

TARGET_DIR="${1:-$PWD}"
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

TODAY="$(date +%Y-%m-%d)"
PAPER_SLUG="$(basename "$TARGET_DIR")"

echo "AcademicPaperWriter bootstrap"
echo "  Target:      $TARGET_DIR"
echo "  Paper slug:  $PAPER_SLUG"
echo "  Templates:   $TEMPLATES_DIR"
echo ""

# ── 1. Required system binaries ───────────────────────────────────────────────
# Set SKIP_BINARY_CHECK=1 to bypass (useful during CI / test runs without TeX).
if [[ "${SKIP_BINARY_CHECK:-0}" != "1" ]]; then
    MISSING_BINS=()
    for bin in pandoc tectonic chktex checkcites latexdiff git; do
        command -v "$bin" &>/dev/null || MISSING_BINS+=("$bin")
    done

    if [[ ${#MISSING_BINS[@]} -gt 0 ]]; then
        echo "ERROR: Missing required system binaries. Install them first:"
        for bin in "${MISSING_BINS[@]}"; do
            echo "  brew install $bin"
        done
        echo ""
        echo "Then re-run: $0 $TARGET_DIR"
        exit 1
    fi
fi

# ── 2. Version SHAs ───────────────────────────────────────────────────────────
HARNESS_SHA="$(git -C "$HARNESS_SOURCE" rev-parse HEAD 2>/dev/null || echo "unknown")"
KDENSE_SYMPY_SHA="$(git ls-remote https://github.com/K-Dense-AI/scientific-agent-skills.git HEAD 2>/dev/null \
    | awk '{print $1}' \
    || echo "unknown")"

echo "  Harness SHA: $HARNESS_SHA"
echo "  SymPy SHA:   $KDENSE_SYMPY_SHA"
echo ""

# ── 3. Idempotent copy helper ─────────────────────────────────────────────────
# Copies $TEMPLATES_DIR/<rel_path> → $TARGET_DIR/<rel_path> with placeholder
# substitution.  If destination already exists, prompts before overwriting.
copy_template() {
    local rel_path="$1"
    local src="$TEMPLATES_DIR/$rel_path"
    local dst="$TARGET_DIR/$rel_path"

    if [[ ! -f "$src" ]]; then
        echo "  WARN: template not found: $rel_path (skipping)"
        return 0
    fi

    if [[ -f "$dst" ]]; then
        local response
        if [[ -t 0 ]]; then
            printf "  File exists: %-40s overwrite? [y/N] " "$rel_path"
            read -r response
        else
            response="n"
            echo "  Exists (non-interactive, skipping): $rel_path"
        fi
        [[ "$response" =~ ^[Yy]$ ]] || return 0
    fi

    mkdir -p "$(dirname "$dst")"
    sed \
        -e "s|{{PAPER_SLUG}}|$PAPER_SLUG|g" \
        -e "s|{{TODAY}}|$TODAY|g" \
        -e "s|{{HARNESS_SHA}}|$HARNESS_SHA|g" \
        -e "s|{{KDENSE_SYMPY_SHA}}|$KDENSE_SYMPY_SHA|g" \
        "$src" > "$dst"
    echo "  Wrote: $rel_path"
}

# ── 4. Copy per-paper templates ───────────────────────────────────────────────
for rel in \
    CLAUDE.md \
    CONSTITUTION.md \
    THEORY_PRIORS.md \
    paper_config.yaml \
    SETUP.md \
    WORKFLOW.md \
    .env.template \
    .gitignore \
    .mcp.json \
    conf/custom_models.json \
    conf/harness-requirements.txt; do
    copy_template "$rel"
done

# ── 5. Copy .claude/ hook scripts ─────────────────────────────────────────────
mkdir -p "$TARGET_DIR/.claude/hooks"

for hook_src in "$TEMPLATES_DIR/.claude/hooks/"*.sh; do
    [[ -f "$hook_src" ]] || continue
    hook_name="$(basename "$hook_src")"
    hook_dst="$TARGET_DIR/.claude/hooks/$hook_name"
    if [[ -f "$hook_dst" ]]; then
        echo "  Exists (keeping): .claude/hooks/$hook_name"
    else
        cp "$hook_src" "$hook_dst"
        chmod +x "$hook_dst"
        echo "  Wrote: .claude/hooks/$hook_name"
    fi
done

# ── 5b. Copy .claude/scripts/ helper scripts ──────────────────────────────────
mkdir -p "$TARGET_DIR/.claude/scripts"

for script_src in "$TEMPLATES_DIR/.claude/scripts/"*; do
    [[ -f "$script_src" ]] || continue
    script_name="$(basename "$script_src")"
    script_dst="$TARGET_DIR/.claude/scripts/$script_name"
    if [[ -f "$script_dst" ]]; then
        echo "  Exists (keeping): .claude/scripts/$script_name"
    else
        cp "$script_src" "$script_dst"
        chmod +x "$script_dst"
        echo "  Wrote: .claude/scripts/$script_name"
    fi
done

# ── 6. Create per-paper directory tree ────────────────────────────────────────
for dir in paper worklog worklog/research worklog/review worklog/transcripts source related logs; do
    if [[ ! -d "$TARGET_DIR/$dir" ]]; then
        mkdir -p "$TARGET_DIR/$dir"
        echo "  Created: $dir/"
    fi
done

# ── 7. Install workflow + library skills ──────────────────────────────────────
# Copies each skill directory (SKILL.md + any supporting files) from the harness
# templates into the paper's .claude/skills/. These are the real bodies, not
# stubs: the user-facing workflow entry points (start-paper, scope-paper,
# draft-paper, onboard-paper, refine-*, research, verify-*, find-cite,
# sync-zotero, export-coauthor, signoff — each invocable as /<skill-name>) plus
# the library skills they call (references-management, citation-extract,
# pandoc-import, integrity-gate, theory-verify, sympy, lane1-*, lane2-orchestrate).
# Skills contain no {{...}} placeholders, so this is a verbatim copy.
SKILLS_SRC="$TEMPLATES_DIR/.claude/skills"
if [[ ! -d "$SKILLS_SRC" ]]; then
    echo "ERROR: skills source not found: $SKILLS_SRC"
    exit 1
fi
skill_count=0
for skill_dir in "$SKILLS_SRC"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    dst="$TARGET_DIR/.claude/skills/$skill_name"
    if [[ -f "$dst/SKILL.md" ]]; then
        if [[ -t 0 ]]; then
            printf "  Skill exists: %-26s overwrite? [y/N] " "$skill_name"
            read -r response
        else
            response="n"
            echo "  Skill exists (non-interactive, skipping): $skill_name"
        fi
        [[ "$response" =~ ^[Yy]$ ]] || continue
        rm -rf "$dst"
    fi
    mkdir -p "$dst"
    cp -R "$skill_dir." "$dst/"
    skill_count=$((skill_count + 1))
done
echo "  Installed: .claude/skills/ ($skill_count skill bodies)"

# ── 8. Copy .claude/settings.json with hooks (skip if already exists) ─────────
SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
SETTINGS_SRC="$HARNESS_SOURCE/templates/.claude/settings.json"
if [[ ! -f "$SETTINGS_FILE" ]]; then
    mkdir -p "$TARGET_DIR/.claude"
    if [[ -f "$SETTINGS_SRC" ]]; then
        cp "$SETTINGS_SRC" "$SETTINGS_FILE"
        echo "  Wrote: .claude/settings.json (with hook registration)"
    else
        # Fallback: minimal settings if template missing
        printf '{\n  "permissions": {\n    "defaultMode": "autoEdit"\n  }\n}\n' > "$SETTINGS_FILE"
        echo "  Wrote: .claude/settings.json (minimal — Phase 7 template not found)"
    fi
else
    echo "  Exists (keeping): .claude/settings.json"
fi

# ── 8b. Copy .githooks/ into target (keep-if-exists; chmod +x) ───────────────
mkdir -p "$TARGET_DIR/.githooks"
for githook_src in "$TEMPLATES_DIR/.githooks/"*; do
    [[ -f "$githook_src" ]] || continue
    githook_name="$(basename "$githook_src")"
    githook_dst="$TARGET_DIR/.githooks/$githook_name"
    if [[ -f "$githook_dst" ]]; then
        echo "  Exists (keeping): .githooks/$githook_name"
    else
        cp "$githook_src" "$githook_dst"
        chmod +x "$githook_dst"
        echo "  Wrote: .githooks/$githook_name"
    fi
done

# ── 8c. Initialize git repository ─────────────────────────────────────────────
if command -v git &>/dev/null; then
    if git -C "$TARGET_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
        # Repo already exists — ensure hooksPath is set, leave history untouched.
        git -C "$TARGET_DIR" config core.hooksPath .githooks
        echo "  Existing git repo — left history untouched"
    else
        # Fresh init.
        git -C "$TARGET_DIR" init -q
        git -C "$TARGET_DIR" config core.hooksPath .githooks
        echo "  Initialized git repository"

        # Initial commit only if there are no commits yet.
        if ! git -C "$TARGET_DIR" rev-parse HEAD &>/dev/null 2>&1; then
            GIT_EMAIL="$(git -C "$TARGET_DIR" config user.email 2>/dev/null || true)"
            if [[ -z "$GIT_EMAIL" ]]; then
                echo "  WARN: No git identity set; skipping initial commit."
                echo "        Set user.name/user.email and run:"
                echo "          git add -A && git commit -m 'Bootstrap AcademicPaperWriter paper repo'"
            else
                git -C "$TARGET_DIR" add -A
                git -C "$TARGET_DIR" commit -q \
                    -m "Bootstrap AcademicPaperWriter paper repo (harness $HARNESS_SHA)"
                git -C "$TARGET_DIR" tag harness-bootstrap 2>/dev/null || true
                echo "  Created initial commit + harness-bootstrap tag"
            fi
        fi
    fi
else
    echo "  WARN: git not found; skipping git init (install git to enable version control)"
fi

# ── 9. Python virtual environment ─────────────────────────────────────────────
echo ""
if [[ "${SKIP_VENV:-0}" == "1" ]]; then
    echo "  venv skipped (SKIP_VENV)"
else
    echo "Setting up Python virtual environment..."
    if command -v uv &>/dev/null; then
        uv venv "$TARGET_DIR/.venv" --quiet 2>/dev/null || true
        uv pip install --python "$TARGET_DIR/.venv/bin/python" --quiet \
            -r "$TARGET_DIR/conf/harness-requirements.txt"
    else
        python3 -m venv "$TARGET_DIR/.venv"
        "$TARGET_DIR/.venv/bin/pip" install --quiet \
            -r "$TARGET_DIR/conf/harness-requirements.txt"
    fi
    echo "  .venv ready"
fi

# ── 10. Next-step instructions ────────────────────────────────────────────────
echo ""
echo "Bootstrap complete. Workflow skills are installed and invocable as"
echo "slash commands in this repo (e.g. /start-paper, /scope-paper, /draft-paper)."
echo ""
echo "Next steps:"
echo "  1. Edit SETUP.md and complete the human-action checklist."
echo "  2. Edit THEORY_PRIORS.md USER-SPECIFIED block with hard constraints."
echo "  3. Drop source files in source/."
echo "  4. Run /onboard-paper (for existing draft) or /start-paper (for greenfield)."
