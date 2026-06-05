---
name: research
description: Use to conduct focused sub-research on a topic. Searches Semantic Scholar + arXiv + NBER, adds confirmed papers to Zotero (or standalone cache collection), produces a structured markdown summary. Callable standalone or from inside /start-paper, /scope-paper, /draft-paper, /refine-*.
allowed-tools: Read Write Edit Bash mcp__zotero__* mcp__pal__*
metadata:
  version: "0.1.0"
---

# /research [topic] — Sub-research primitive

Conduct focused research on `$ARGUMENTS` (the topic from the command arg). Produce a structured research report and add confirmed papers to Zotero. This command is callable standalone and from inside any of the three greenfield commands.

If no topic is provided, refuse:
> "/research requires a topic argument. Example: /research 'exchange rate disconnect puzzle'"

## Step 1 — Determine context

Check whether this invocation is inside a paper repo (i.e., whether `paper_config.yaml` exists in the current directory):
- **Inside a paper repo:** write the report to `worklog/research/{topic-slug}.md` and add papers to the collection specified by `paper_config.yaml` `zotero.collection_key`. Read `THEORY_PRIORS.md` if it exists to scope the search to the paper's model class.
- **Standalone (no paper_config.yaml):** write the report to `~/Documents/AcademicPaperWriter/research-cache/{topic-slug}.md`. Add papers to the Zotero personal cache collection (document this as a standalone run in the report frontmatter; `paper_ref` is omitted).

The `topic-slug` is the topic converted to kebab-case, lowercased, with stop words removed where helpful (e.g., "exchange rate disconnect puzzle" → `exchange-rate-disconnect-puzzle`).

## Step 2 — Search

Search the following three sources. Use `Bash` with `curl` for all API calls.

### Semantic Scholar

```bash
curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query={URL-encoded-topic}&limit=20&fields=paperId,title,authors,year,externalIds,abstract,citationCount,influentialCitationCount" \
  -H "Accept: application/json"
```

No API key is required for basic search (rate limit: 100 req/5 min). If a `SEMANTIC_SCHOLAR_API_KEY` environment variable exists, include it as `-H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY"` for higher limits.

Rank results by `influentialCitationCount` descending. Take the top 10 candidates.

### arXiv

```bash
curl -s "https://export.arxiv.org/api/query?search_query=all:{URL-encoded-topic}&sortBy=relevance&sortOrder=descending&max_results=10"
```

Parse the Atom XML response to extract: title, authors, published date, arxiv ID, abstract. Take the top 10 candidates.

### NBER

```bash
curl -s "https://www.nber.org/api/v1/working_page_listing/contentType/working_paper?page=1&perPage=10&sortBy=score&filterByYear=&q={URL-encoded-topic}" \
  -H "Accept: application/json"
```

Documented limitation: NBER has no official public search API as of 2026-05-30. This curl call uses NBER's internal listing API (subject to change without notice). An NBER MCP is on the MVP+1 backlog. If the call fails (non-200, malformed response), skip NBER silently and note the gap in the report's Methodology section: "NBER search unavailable — manual NBER.org search recommended."

Take the top 5 NBER candidates.

Deduplicate across sources by DOI where available, then by title similarity.

## Step 3 — User confirmation (mandatory)

Present every candidate paper to the user BEFORE any Zotero operation. Format as a numbered list:

```
Candidate papers for: "{topic}"

  1. {Authors} ({year}). {Title}. {Journal/Source}
     DOI: {DOI or arXiv ID}
     Abstract: {first 2 sentences}
     Citations: {N influential}

  2. ...

Actions: type the numbers to accept (e.g., "1 3 5"), "all" to accept all,
"skip N" to skip item N, or "edit N" to provide an alternative DOI for item N.
Do not proceed until you receive explicit user input.
```

**Never bulk-add to Zotero without user confirmation.** This is a hard rule per ADR 0006 and the documented session-02 discipline. Each paper must be explicitly accepted by the user. Do not add papers in the background, do not pre-stage, do not assume "accept all" unless the user types exactly that.

Wait for the user's response before proceeding to Step 4.

## Step 4 — Add accepted papers to Zotero

For each accepted paper:

1. Load the `references-management` skill (at `.claude/skills/references-management/`). Do not perform Zotero operations without it.
2. Use `zotero_find_duplicates` (via the skill) with the paper's DOI to check whether the paper already exists in the Zotero library. If a match is found, reuse the existing item — do not create a duplicate. Report the existing item's key to the user.
3. If no duplicate: use `zotero_add_by_doi` (via the skill's `ALLOWED_KEYS` wrapper) to add the paper to the paper's Zotero collection (or the standalone cache collection).
4. Record the assigned Zotero key for use in the report.

If a DOI is not available for an accepted paper, ask the user for the DOI before adding. Do not add papers without a DOI.

## Step 5 — Produce the research report

After all accepted papers are added to Zotero, produce the research report. The report must contain all of the following sections exactly as specified.

**YAML Frontmatter:**
```yaml
---
title: "{topic}"
version: "1.0.0"
status: Draft
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
topic_slug: {kebab-case slug}
paper_ref: {paper-repo-path or omitted for standalone}
zotero_collection_key: {key from paper_config.yaml, or "standalone-cache" if standalone}
papers_added: {N — count of papers successfully added to Zotero this run}
confidence: {high|medium|low — your assessment of the literature coverage}
contested: {true|false — whether sources meaningfully disagree on core claims}
sources_count: {total sources consulted across all three databases}
tool_calls: {count of Bash/MCP tool calls made during this research run}
stale_after: 90d
---
```

**Sections (required, in this order):**

```markdown
# Research Report: {topic}

## TL;DR
- {bullet 1} [VERIFIED|UNVERIFIED|SPECULATIVE]
- {bullet 2} [VERIFIED|UNVERIFIED|SPECULATIVE]
- (3–5 bullets total)

## Key Findings (user-facing summary; NOT authoritative — AI cites from Zotero, not from here)
### Finding 1: {short title}
{1–2 paragraphs of synthesis}
- Based on: [{Author Year} zoteroKey:{key}], [{Author Year} zoteroKey:{key}]
- Evidence type: empirical|theoretical|survey|meta-analysis
- Confidence: high|medium|low
- Status: [VERIFIED|UNVERIFIED|SPECULATIVE]

(repeat for each major finding)

## Methodology
- Sources consulted: {N}
- Date range: {YYYY-MM to YYYY-MM}
- Databases/tools: Semantic Scholar, arXiv, NBER (or note if NBER unavailable)
- Search queries: {exact queries used}
- Exclusion criteria: {what was excluded and why}
- Known gaps: {what this search does not cover}

## Papers added to Zotero (source of truth)
- zoteroKey:{key} — {Author}, {initials}. ({year}). {Title}. DOI: {DOI}
- zoteroKey:{key} — ...
(one line per paper added; this section is the AI's citation source of truth per ADR 0007)

## Open Questions
- {single sentence question} % TKTK
- (repeat for each open question)

## Contradictions / Disagreements
- {where sources disagree on a specific claim}
- (or "None identified" if sources are in agreement)

## Provenance
- Generated by: claude-sonnet-4-6
- Generated at: {ISO-8601 timestamp}
- Verification: self-checked
- Inputs: {paths to any docs read during this session, e.g., THEORY_PRIORS.md, worklog/RESEARCH_BRIEF.md}
```

**Key Findings citation discipline:** Every `zoteroKey:{key}` inline citation in Key Findings must resolve to an entry in the `## Papers added to Zotero` section. No citation in Key Findings may reference a paper not in that section.

## Step 6 — Deterministic lint before writing

Before writing the file, lint the report deterministically. This lint must not use an LLM judgment call. Check:

1. All required sections are present: TL;DR, Key Findings, Methodology, Papers added to Zotero, Open Questions, Contradictions / Disagreements, Provenance.
2. All required YAML frontmatter fields are populated and non-placeholder: `title`, `version`, `status`, `created`, `last_updated`, `topic_slug`, `zotero_collection_key`, `papers_added`, `confidence`, `contested`, `sources_count`, `tool_calls`, `stale_after`.
3. Status enum valid: `Draft | Verified | Stale`.
4. Confidence enum valid: `high | medium | low`.
5. Every `zoteroKey:{key}` citation in Key Findings resolves to an entry in the `## Papers added to Zotero` section (regex match: `zoteroKey:` followed by the same key appears in the Papers added section).
6. TL;DR bullets each end with `[VERIFIED]`, `[UNVERIFIED]`, or `[SPECULATIVE]`.
7. Open Questions entries each end with `% TKTK`.

If any check fails: refuse to write the file. Tell the user exactly which check failed and what is missing or malformed. Do not write a partial report.

If all checks pass: write the file to the storage path determined in Step 1.

## Step 7 — Report to user

After writing the report, tell the user:
- The path where the report was written.
- How many papers were added to Zotero.
- The list of Zotero keys assigned.
- How many % TKTK open questions were identified.
- If any candidate papers were skipped (by user choice or duplicate detection): list them.
- Reminder: "The Key Findings section is human-facing. When /draft-paper cites these papers, it will query Zotero directly — not this markdown."
