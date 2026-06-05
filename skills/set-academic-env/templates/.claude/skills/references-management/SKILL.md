---
name: references-management
description: Use whenever the harness needs to read from, write to, or sync with the per-paper Zotero collection. Wraps Zotero MCP calls with the ALLOWED_KEYS client-side scope filter. Regenerates paper/references.bib on demand.
allowed-tools: Read Write Edit Bash mcp__zotero__*
metadata:
  version: "0.1.0"
---

# references-management skill

This skill is the sole gateway for all Zotero MCP calls in the harness. No other skill or command may call Zotero MCP tools directly — all citation operations route through this wrapper. Per ADR 0007 and ADR 0010.

---

## On-boot procedure (run once at session start)

**Step 1 — Read config.**
Read `paper_config.yaml`. Extract:
- `zotero.collection_key` (8-char alphanumeric, e.g. `"ABC123XY"`)
- `zotero.collection_name` (human-readable slug, e.g. `"monetary-spillovers-2026"`)

**Step 2 — Verify collection key.**
Call `zotero_search_collections(name=<collection_name>)`.
Compare the key returned by the MCP against `collection_key` from config.

**FAIL LOUD if mismatched.** Do not silently proceed. Print:
```
ERROR: collection_key mismatch.
  paper_config.yaml says: <config_key>
  Zotero returned for "<collection_name>": <returned_key>

Fix: update paper_config.yaml zotero.collection_key to match,
or rename your Zotero collection to match collection_name.
Aborting — no Zotero operations will run this session.
```
Then stop. Do not fall back to library-wide operations.

**Step 3 — Cache ALLOWED_KEYS.**
Call `zotero_get_collection_items(collection_key=<collection_key>)`.
Cache the returned item keys as `ALLOWED_KEYS` (in-memory set for this session only — never persisted to disk per ADR 0010).

Print: `references-management: loaded N items into ALLOWED_KEYS for collection "<collection_name>".`

---

## Per-operation routing table

All harness code routes Zotero operations through this table. Tool names are authoritative from Research/09 and the `54yyyu/zotero-mcp` README.

| Operation | Routing rule |
|---|---|
| `zotero_search_items` | Pass `collection_key` directly (native collection scoping — supported in v0.3.0+) |
| `zotero_search_by_tag` | Pass `collection_key` directly (native collection scoping — supported) |
| `zotero_get_recent` | Pass `collection_key` directly (native collection scoping — supported) |
| `zotero_get_item_metadata` | Call only if `item_key in ALLOWED_KEYS`; skip and warn if not |
| `zotero_get_item_fulltext` | Call only if `item_key in ALLOWED_KEYS`; skip and warn if not |
| `zotero_get_item_children` | Call only if `item_key in ALLOWED_KEYS`; skip and warn if not |
| `zotero_semantic_search` | Call library-wide; filter results to `item_key in ALLOWED_KEYS` before returning |
| `zotero_advanced_search` | Call library-wide; filter results to `item_key in ALLOWED_KEYS` before returning |
| `zotero_add_by_doi` | (1) Call; (2) capture returned `item_key`; (3) immediately call `zotero_manage_collections(operation="add", collection_key=<collection_key>, item_keys=[new_key])`; (4) update `ALLOWED_KEYS` with `new_key` |
| `zotero_add_by_url` | Same as `zotero_add_by_doi` |
| `zotero_add_from_file` | Same as `zotero_add_by_doi` |
| `zotero_update_item` | Allowed only if `item_key in ALLOWED_KEYS`; refuse and warn if not |

**Never call `zotero_search_notes`, `zotero_get_annotations`, or `zotero_create_note` without first confirming `item_key in ALLOWED_KEYS`.**

---

## Local vs Web API split (ADR 0010)

**Reads → Local API** (`ZOTERO_LOCAL=true`). Faster; no auth required beyond the local socket. Set `ZOTERO_LOCAL=true` in the paper's `.env` for all read operations.

**Writes → Web API.** Issues #277 and #306 in `54yyyu/zotero-mcp` make the local write path unreliable as of v0.4.1. Web API writes require `ZOTERO_API_KEY`, `ZOTERO_LIBRARY_ID`, `ZOTERO_LIBRARY_TYPE` in `.env`. Re-evaluate when both issues close.

The MCP's connection mode is set per session; the harness cannot switch mid-session. Consequence: if a session needs both reads and writes, the user must configure the Web API path (which also supports reads). Document this in SETUP.md instructions.

---

## paper/references.bib regeneration

When asked to regenerate `paper/references.bib` (by `/sync-zotero` or on demand):

Resolve the bibliography path from `paper_config.yaml` `paths.references` (default `paper/references.bib`); do not assume the repo root.

1. Confirm `ALLOWED_KEYS` is populated. If not, run the on-boot procedure first.
2. For each `item_key` in `ALLOWED_KEYS`, call `zotero_get_item_metadata(item_key=...)` to retrieve bibliographic fields.
3. Format each item as a BibTeX entry using the `betterbibtex-author-year-shorttitle` citekey style (e.g., `gali2008monetary`). Citekey construction: lowercase first-author surname + 4-digit year + first significant word of title (lowercase, no articles/prepositions).
4. Write all entries to `paper/references.bib` (resolved from `paths.references`).
5. Print: `paper/references.bib regenerated: N entries written.`

**Preferred path:** if Zotero has Better BibTeX (BBT) plugin installed, use BBT export via `zotero_export_collection` or Zotero's BBT JSON export rather than hand-constructing BibTeX. BBT produces correctly styled citekeys per the paper's BBT preferences. Check SETUP.md — BBT install is a prerequisite.

---

## Known limitation

`zotero_get_item_fulltext` returns empty for closed-access papers when no OA fallback (Unpaywall / arXiv / S2 / PMC) is available. In those cases, Lane 1 citation-claim semantic match degrades to metadata-only judgment. This is a known limitation per ADR 0010, not a bug.
