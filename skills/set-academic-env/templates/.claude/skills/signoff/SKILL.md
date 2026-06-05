---
name: signoff
description: Use to attest that you have reviewed the latest integrity-gate report, open TKTK markers, and Lane 1 flags. Appends a timestamped entry to SIGNOFF.md with paper/main.tex SHA pinning. Required before "final" coauthor exports or future render gates.
allowed-tools: Bash Read Write Edit
metadata:
  version: "0.1.0"
---

# /signoff [--variant <name>]

Human-attested gating per the Goldsmith-Pinkham "RA-not-coauthor" pattern (session 01). Signoffs are append-only — mistakes get a new entry, never a deletion.

**Arguments:**
- `[--variant <name>]` — optional. Sign off on a named variant instead of the active default.

## Step 1 — Precondition: integrity gate must not be failing

Read `paper_config.yaml`. Resolve the target manuscript using the **Variant-resolution rule**:

**Variant-resolution rule:**
1. If `--variant <name>` was given: look up `manuscripts.variants[name].file` in `paper_config.yaml`. If the `manuscripts:` block is absent or `<name>` is not found, refuse with: "Unknown variant '<name>'. Known variants: <list keys from manuscripts.variants, or 'none registered'>." Stop.
2. Else: use `paths.manuscript` (default `paper/main.tex`).
3. Always report which manuscript you are acting on: "Acting on variant: <name> (<file>)" or "Acting on default manuscript: <file>".

Find the most recent integrity-gate report in `worklog/review/`:
```bash
latest=$(ls -t worklog/review/refine-*.md 2>/dev/null | head -1)
```

If no report exists: warn "No integrity-gate report found in worklog/review/. Run /refine-light or /refine-heavy before signing off." And stop.

Read the `overall_status` from the report:
- `overall_status: fail` → **Refuse hard.** Print:
  > "Cannot sign off. The latest integrity-gate report shows overall_status: fail. Resolve all failing integrity-gate issues and re-run /refine-* before signing off."
  And stop.
- `overall_status: warn` → Warn but allow with confirmation:
  > "The latest integrity-gate report shows overall_status: warn. You can still sign off, but unresolved flags will be noted. Proceed?"
  Wait for user confirmation (any affirmative response proceeds).
- `overall_status: pass` → proceed.

## Step 2 — Show review summary

Display to the user:

```
─────────────────────────────────────────────────────────
SIGNOFF REVIEW — <paper slug>
─────────────────────────────────────────────────────────

Latest integrity-gate report: <filename> (overall: <status>)
<paste the Summary section of the report>

Open % TKTK: markers in <resolved manuscript file>:
<grep -c '% TKTK:' <resolved manuscript file>> total
<list first 10, with line numbers>

Unresolved Lane 1 flags from latest report:
<extract citation mismatches and AI-tell flags from report>
─────────────────────────────────────────────────────────
```

## Step 2b — Advisory replication-readiness check (non-blocking)

This check is **advisory only — it never blocks signoff**. Theory-only papers (no `code/` or
`data/`) must sign off cleanly; the warning only fires when the project is empirical.

Read `paper_config.yaml` to get the empirical dir paths (defaults if absent):
```bash
code_dir=$(grep -E '^\s+code_dir:' paper_config.yaml | awk '{print $2}' | tr -d '"' || echo "code")
data_dir=$(grep -E '^\s+data_dir:' paper_config.yaml | awk '{print $2}' | tr -d '"' || echo "data")
```

Check whether either dir exists and is non-empty, and whether `replication/README.md` is absent:
```bash
empirical=false
if { [[ -d "$code_dir" ]] && [[ -n "$(ls -A "$code_dir" 2>/dev/null)" ]]; } \
   || { [[ -d "$data_dir" ]] && [[ -n "$(ls -A "$data_dir" 2>/dev/null)" ]]; }; then
    empirical=true
fi

if [[ "$empirical" == "true" ]] && [[ ! -f "replication/README.md" ]]; then
    echo ""
    echo "WARNING: No replication/README.md found, but this project has code/ or data/."
    echo "  AER/JPE submission requires a replication package — create replication/README.md"
    echo "  from templates/replication-README.md."
    echo ""
fi
```

Include the warning (if triggered) in the Step 2 review summary block under a
"Replication readiness" line. If `empirical=false` or `replication/README.md` exists, omit
the line entirely (no noise for theory papers).

## Step 3 — Attestation

Ask the user:
> "Have you reviewed the above? Type `yes I have reviewed` exactly to sign off, or anything else to cancel."

Wait for exact match. Do NOT accept paraphrases. If the user types anything other than `yes I have reviewed`, cancel:
> "Signoff cancelled. No entry written."

## Step 4 — Write SIGNOFF.md entry

On confirmation, get the SHA of the resolved manuscript (the file determined by the Variant-resolution rule in Step 1):
```bash
# Use the resolved manuscript path (e.g. paper/main.tex or paper/main_empirical.tex)
main_sha=$(git -C "$CLAUDE_PROJECT_DIR" rev-parse HEAD:<resolved-manuscript-path> 2>/dev/null || sha256sum <resolved-manuscript-path> | awk '{print $1}')
```

Create `SIGNOFF.md` if it doesn't exist, with header:
```markdown
# SIGNOFF LOG

Append-only attestation log. Each entry is immutable — corrections go in a new entry.

```

Append entry:
```markdown
## Signoff <YYYY-MM-DD HH:MM>
- Signed by: <git config user.name>
- Manuscript at signoff: <resolved manuscript path> (SHA: <sha>)
- Variant: <name if --variant was given, else "default (paths.manuscript)">
- Open % TKTK: markers: <count>
- Latest integrity-gate report: <filename> (overall: <status>)
- Lane 1 unresolved flags acknowledged:
  <bullet list, or "none">
```

Print:
> "Signed off. Entry appended to SIGNOFF.md."

## Note on render-blocking

For MVP, `/signoff` records the attestation but does not block render or export operations. The render-blocking hook is MVP+1. The SIGNOFF.md entry is the audit trail for journal AI-disclosure requirements.
