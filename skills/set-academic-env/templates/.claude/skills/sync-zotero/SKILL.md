---
name: sync-zotero
description: Refresh ALLOWED_KEYS, pull current Zotero collection state, regenerate paper/references.bib, and print a sync summary. Run after adding papers to Zotero manually or before any citation-heavy command.
allowed-tools: Read Write Edit Bash mcp__zotero__*
metadata:
  version: "0.1.0"
---

# /sync-zotero

Refresh the paper's Zotero collection cache and regenerate `paper/references.bib` (resolved from `paper_config.yaml` `paths.references`; do not assume the repo root).

---

## Behavior

### Step 1 — Refresh ALLOWED_KEYS

Load the `references-management` skill (`.claude/skills/references-management/SKILL.md`). Run its on-boot procedure:
- Read `paper_config.yaml` for `zotero.collection_key` and `zotero.collection_name`.
- Verify the collection key via `zotero_search_collections`.
- Eagerly call `zotero_get_collection_items(collection_key=...)` and rebuild `ALLOWED_KEYS` in memory.

If the collection key verification fails, print the mismatch error from `references-management` and stop. Do not proceed to subsequent steps.

### Step 2 — Pull current collection state

Record the count of items now in `ALLOWED_KEYS`. Compare against the previous session's count if `paper/references.bib` already exists (count BibTeX entries in the existing file as a proxy for "last known count").

### Step 3 — Regenerate paper/references.bib

Using the `references-management` skill's regeneration procedure:
- For each `item_key` in `ALLOWED_KEYS`, retrieve metadata via `zotero_get_item_metadata`.
- Write a BibTeX entry for each item to `paper/references.bib` (resolved from `paths.references`).
- Use `betterbibtex-author-year-shorttitle` citekey style throughout.

**Preferred path:** if the Zotero Better BibTeX plugin is installed, use BBT export for correct citekey formatting. See SETUP.md for BBT install instructions.

### Step 4 — Print summary

Print a sync summary in this format:
```
/sync-zotero complete
  Collection : <collection_name> (<collection_key>)
  Items now  : <N>
  New since last run : <M>  (0 if paper/references.bib did not exist or count unchanged)
  Dropped    : <K>  (items in old paper/references.bib not in current ALLOWED_KEYS)
  paper/references.bib : written (<N> entries)
```

If any items were dropped (K > 0), list their citekeys so the user can decide whether any `\cite{}` calls in `paper/main.tex` now dangle.

---

## Notes

- `/sync-zotero` is also called automatically by `/onboard-paper` (Phase 6) after citation extraction completes.
- Run manually after adding papers to Zotero via the desktop app, since the in-session `ALLOWED_KEYS` cache is not automatically updated by external changes.
- Full verification requires a live Zotero collection with `paper_config.yaml.zotero.collection_key` correctly set. See `SETUP.md` for collection setup steps.
