---
name: citation-extract
description: Use during /onboard-paper to extract citations from an existing draft (.docx prose + .pdf full draft), resolve them via Crossref/Semantic Scholar, and add them to the paper's Zotero collection.
allowed-tools: Bash Read Write Edit mcp__zotero__*
metadata:
  version: "0.1.0"
---

# citation-extract skill

Extracts in-text citation markers from an existing draft, resolves them to primary sources via Crossref and Semantic Scholar, and adds confirmed items to the paper's Zotero collection. Called by `/onboard-paper` (Phase 6). Per Research/10 §A and ADR 0007.

---

## Pipeline overview

```
[.docx]                              [.pdf]
   |                                    |
   v                                    v
python-docx                          GROBID full-text
  walk paragraph.text                  (Docker; reference-list parsing)
  + word/footnotes.xml                 |
   |                                   v
   v                               TEI/XML with bibStruct + in-text refs
text + footnote map                    |
   |                                   |
   +------- merge: dedupe across both -+
                    |
                    v
           Regex pre-pass (~80% recall on author-date)
                    |
                    v
           LLM cleanup (Claude tool-call; structured JSON output)
                    |
                    v
           Crossref + Semantic Scholar lookup
           (require DOI or S2 paperId match before accepting)
                    |
                    v
           USER CONFIRMATION STEP (mandatory — see below)
                    |
                    v
           pyzotero → translation-server → Zotero collection
```

---

## Prerequisites

### GROBID (reference-list parsing from PDF)

GROBID must be running before this skill executes. Do NOT auto-start it. Check first:

```bash
curl -s localhost:8070/api/isalive
```

If GROBID is not running, print:
```
GROBID not running. Start it with:
  docker run -d -p 8070:8070 lfoppiano/grobid:0.8.0
Then re-run /onboard-paper.
```
and stop.

Start command (for SETUP.md reference):
```bash
docker run -d -p 8070:8070 lfoppiano/grobid:0.8.0
```

Use `grobid-client-python` for calls. Set `timeout=600` — long bibliographies need it. Call with `consolidateCitations=1` for CrossRef DOI resolution at >0.95 F1.

### Zotero translation-server (add-by-identifier)

The translation-server is a separate Docker container from GROBID. Check first:

```bash
curl -s localhost:1969
```

If not running:
```
Zotero translation-server not running. Start it with:
  docker run -d -p 1969:1969 zotero/translation-server
Then re-run /onboard-paper.
```
and stop.

Start command:
```bash
docker run -d -p 1969:1969 zotero/translation-server
```

URL is read from `paper_config.yaml` at `zotero.translation_server_url` (default: `http://localhost:1969`).

---

## Step 1 — python-docx extraction

Walk the `.docx` file (path from `paper_config.yaml.paper.full_draft_context` or `source/` directory):

1. Open with `python-docx`.
2. Walk every `paragraph.text` in the document body.
3. Open `word/footnotes.xml` directly (python-docx does not expose footnotes via the standard API; read the XML as text). Extract text content from `<w:t>` elements.
4. Produce a combined text corpus: body paragraphs + footnote text, tagged with paragraph index and footnote number for provenance.

---

## Step 2 — GROBID extraction

Submit the full-draft PDF to GROBID's `processFulltextDocument` endpoint:

```bash
curl -X POST localhost:8070/api/processFulltextDocument \
  -F input=@source/FullDraftPaper.pdf \
  -F consolidateCitations=1
```

Parse the TEI/XML response:
- `//biblStruct` elements → reference list entries with DOIs where CrossRef resolved them.
- `//ref[@type="bibr"]` elements → in-text citation markers linked to their `biblStruct` IDs.

---

## Step 3 — Merge and deduplicate

Merge in-text markers from python-docx extraction and GROBID extraction. Deduplicate by (author_tokens, year) pairs — the same citation may appear in both sources.

Produce a unified list of candidate citations with provenance tags (`docx`, `grobid`, or `both`).

---

## Step 4 — Regex pre-pass

Apply two regex patterns to the merged text corpus to identify author-date citation markers. These patterns cover Chicago author-date format used in economics writing:

**Pattern 1 — parenthetical citations** (e.g., `(Gali and Monacelli 2005)`, `(Obstfeld 1994, p. 4)`, `(Bernanke et al. 2005, pp. 10–12)`):
```
\(([A-Z][a-zA-Zé\-]+(?:\s+(?:and|&)\s+[A-Z][a-zA-Zé\-]+|\s+et\s+al\.)?),?\s+(1[89]\d{2}|20[0-2]\d)(?:,\s+pp?\.?\s+[\d\-–]+)?\)
```

**Pattern 2 — narrative citations** (e.g., `Gali and Monacelli (2005)`, `Obstfeld (1994, p. 4)`):
```
([A-Z][a-zA-Zé\-]+(?:\s+(?:and|&)\s+[A-Z][a-zA-Zé\-]+|\s+et\s+al\.)?)[ \t]+\((1[89]\d{2}|20[0-2]\d)(?:,\s+pp?\.?\s+[\d\-–]+)?\)
```

The regex pre-pass achieves ~80% recall on author-date economics prose (Tkaczyk et al. baseline). The LLM cleanup pass (Step 5) closes the remaining ~20%.

---

## Step 5 — LLM cleanup

Call Claude as a tool to clean up the regex output. Use this prompt structure:

```
You are extracting academic citation markers from economics prose.
I will give you text that has already been pre-processed by regex
to identify likely citation markers. Your job is to:
1. Find any citations the regex missed.
2. Normalize all citations to structured JSON.
3. Flag ambiguous or uncertain markers.

The text is from an economics paper using Chicago author-date format.
Common patterns: (Author Year), Author (Year), (Author et al. Year, p. N).
Include page numbers, narrative vs parenthetical distinction, and et-al expansion where possible.

Output a JSON array. Each element must be exactly:
{
  "authors": ["<surname1>", "<surname2>"],
  "year": <int>,
  "page": "<page string or null>",
  "narrative": <true if "Author (Year)" form, false if "(Author Year)" form>,
  "confidence": "high" | "medium" | "low"
}

Use "low" confidence for: ambiguous author names, years that may be dates not citations,
unclear narrative vs parenthetical context.

Do not add any entries not found in the text. Do not omit entries the regex found.
Return only the JSON array, no prose.
```

The LLM must return a JSON array. Parse and validate; reject responses that are not valid JSON. Retry once if invalid.

---

## Step 6 — Crossref + Semantic Scholar lookup

For each citation in the merged list (regex hits + LLM additions):

1. **Crossref query:** `GET https://api.crossref.org/works?query.author=<surname>&query.bibliographic=<year>&rows=3`
2. **Semantic Scholar query:** `GET https://api.semanticscholar.org/graph/v1/paper/search?query=<surname>+<year>&fields=paperId,title,authors,year,externalIds`

**Acceptance rule:** a citation is accepted only if at least one of these resolves to a match with:
- A DOI (from Crossref), OR
- An S2 `paperId` (from Semantic Scholar)

AND the returned year matches within ±1 year AND at least one author surname token appears in the result.

**Unresolved citations** — if neither Crossref nor S2 produce a match:
- Mark as `"unresolved"`.
- Include in the user confirmation step with a `[UNRESOLVED — needs manual lookup]` label.
- Never silently drop or silently add unresolved citations.

---

## Step 7 — USER CONFIRMATION STEP (MANDATORY)

**This step is not optional.** Silent bulk-add to Zotero violates ADR 0007 and the harness's trust contract with the user.

Present all resolved citations as a numbered list for review before adding anything to Zotero:

```
Found N citations. Review and confirm before adding to Zotero:

  1. Gali, J. and Monacelli, T. (2005)
     "Monetary Policy and Exchange Rate Volatility in a Small Open Economy"
     DOI: 10.1111/j.1467-937X.2005.00349.x
     → Crossref match: Review of Economic Studies, 72(3), 707–734
     [confidence: high]

  2. Obstfeld, M. (1994)
     "Risk-Taking, Global Diversification, and Growth"
     DOI: 10.1257/aer.84.5.1310
     → Crossref match: American Economic Review, 84(5), 1310–1329
     [confidence: high]

  3. Unknown Author (2003) — [UNRESOLVED — needs manual lookup]
     Matched text: "(Unknown 2003, p. 42)"
     → No Crossref or S2 match found

Commands:
  accept         — add all resolved citations to Zotero
  accept all     — add all including unresolved (add unresolved as stubs)
  skip N         — skip citation N (do not add)
  edit N         — manually correct citation N before adding
```

Wait for user input. Do not proceed until the user types a response.

Process responses:
- `accept` — add all `[confidence: high | medium]` resolved citations; leave unresolved pending.
- `accept all` — add all, including unresolved as minimal stubs for manual completion.
- `skip N` — remove citation N from the add queue.
- `edit N` — prompt user for corrected author, year, DOI; re-run Crossref lookup on corrected data.

---

## Step 8 — Add to Zotero via pyzotero + translation-server

For each accepted citation:

1. Use the translation-server to convert DOI → Zotero item JSON:
   ```bash
   curl -d '{"DOI": "<doi>"}' \
        -H 'Content-Type: application/json' \
        http://localhost:1969/search
   ```
   The translation-server returns Zotero-format JSON.

2. POST the item JSON to Zotero via pyzotero (Web API path per ADR 0010):
   ```python
   zot = zotero.Zotero(library_id, library_type, api_key)
   zot.create_items([item_json])
   ```

3. After each successful add, immediately add to the paper's collection:
   Call `zotero_manage_collections(operation="add", collection_key=<collection_key>, item_keys=[new_key])` via the `references-management` skill (which also updates `ALLOWED_KEYS`).

4. Log each added item: author, year, title, DOI, Zotero item key.

After all adds complete, call `/sync-zotero` to regenerate `paper/references.bib` with the newly added items.

---

## What this skill does NOT do

- Does NOT implement `/onboard-paper` (Phase 6 owns that command).
- Does NOT run Lane 1 citation-claim semantic match (Phase 3).
- Does NOT implement RefChecker (MVP+1 backlog).
- Does NOT auto-start Docker containers — check and report, let the user start them.
