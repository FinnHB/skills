---
name: find-cite
description: Use for on-demand citation search when drafting or refining a paper. Searches Semantic Scholar + arXiv + NBER, presents candidates, adds confirmed selections to the paper's Zotero collection. Returns citekeys for immediate use.
allowed-tools: Read Write Bash mcp__zotero__*
metadata:
  version: "0.1.0"
---

# /find-cite [claim]

Quick citation search. Thinner than `/research` — no full markdown summary, just "find me a citation for X" with a fast add. Useful when drafting hits a `% TKTK: needs citation` marker.

**Argument:** free-text description of the claim needing a citation (e.g., "monetary policy transmission through the credit channel", "Calvo pricing in New Keynesian models").

If no argument provided, ask: "What claim do you need a citation for?"

## Step 1 — Search

Search three sources in parallel:

**Semantic Scholar:**
```bash
curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query=<encoded_claim>&fields=title,authors,year,abstract,externalIds&limit=5"
```

**arXiv:**
```bash
curl -s "https://export.arxiv.org/api/query?search_query=<encoded_claim>&max_results=5&sortBy=relevance"
```

**NBER:** NBER programmatic search is MVP+1 (documented limitation). For now, suggest the user check https://nber.org/papers manually if results from above are insufficient.

Merge and deduplicate results by DOI or arXiv ID. Take the top 5 unique candidates, ranked by relevance and recency.

## Step 2 — Present candidates

Show the user the top 5 candidates, numbered:

```
Citation search results for: "<claim>"
──────────────────────────────────────────────────────────
1. <Authors> (<Year>). <Title>
   DOI/URL: <doi or arxiv url>
   Abstract: <first 200 chars>...

2. <...>
...

Options: add 1,3  |  add all  |  skip  |  edit search
```

Wait for user response. Do NOT add automatically.

## Step 3 — Add to Zotero

For each accepted candidate, add to the paper's Zotero collection via the `references-management` skill:

- Prefer `zotero_add_by_doi` if a DOI is available.
- Fall back to `zotero_add_by_url` for arXiv links.
- If neither works, skip and tell the user to add manually.

After each successful add, print the Better BibTeX citekey:
> "Added: `\cite{<citekey>}`"

## Step 4 — Update ALLOWED_KEYS

After all adds, refresh `ALLOWED_KEYS` by re-running the `references-management` boot step (read collection items from Zotero to update the in-memory set). This ensures the new citekeys are immediately available for Lane 1 checks.

## Output summary

```
/find-cite complete
──────────────────────────────────────────────────────────
Added <N> citation(s) to Zotero:
  \cite{<key1>}
  \cite{<key2>}

NBER note: if you need NBER working papers, check https://nber.org/papers manually (NBER search integration is MVP+1).
```
