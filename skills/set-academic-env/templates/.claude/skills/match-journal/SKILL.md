---
name: match-journal
description: Use after a paper is drafted to rank top economics journals by how well the paper's field, method, and contribution align with each journal's stated aims & scope. Produces a sourced fit report in worklog/review/. Scope-fit only — never predicts acceptance.
allowed-tools: Read Write Bash WebSearch WebFetch
metadata:
  version: "0.1.0"
---

# /match-journal — Journal fit and targeting

Given a drafted paper, rank the journals in the curated profile set by how well the paper's field, method, model class, and contribution align with each journal's **stated aims & scope**, and write a sourced report to `worklog/review/`.

**This is a scope/contribution fit assessment, not an acceptance prediction.** It tells you where the paper *belongs by topic and method*, with the reasoning and the source link for each match. It does not — and must not — estimate acceptance probability, accept rates, or review times. Editorial taste, novelty bar, and timing are not modeled.

**Arguments:** optional.
- `refresh` — re-check each journal's live scope page and flag drift (Step 3). With no argument, the curated profiles are used as-is.
- `--variant <name>` — target a named variant instead of the active default manuscript.

## Precondition checks

Run these in order. On failure, refuse with the exact message shown and stop.

1. **Inside a paper repo.** If `paper_config.yaml` does not exist in the current directory, refuse:
   > "/match-journal must run inside a paper repository (no paper_config.yaml found). cd into the paper directory and try again."

2. **Resolve the target manuscript** using the **Variant-resolution rule**:
   - If `--variant <name>` was given: look up `manuscripts.variants[name].file` in `paper_config.yaml`. If the `manuscripts:` block is absent or `<name>` is not found, refuse with: "Unknown variant '<name>'. Known variants: <list keys from manuscripts.variants, or 'none registered'>." Stop.
   - Else: use `paths.manuscript` (default `paper/main.tex`).
   - Always report which manuscript you are acting on: "Acting on variant: <name> (<file>)" or "Acting on default manuscript: <file>".

3. **A drafted paper exists.** If the resolved manuscript does not exist, or it exists but contains neither a non-empty `\begin{abstract}`…`\end{abstract}` nor a recognizable introduction section, refuse:
   > "/match-journal requires a drafted paper. No manuscript (or no abstract/intro) found — run /draft-paper first."

## Step 1 — Extract paper traits

Use the manuscript path resolved in Precondition check 2; do not assume the repo root.

Read, in this order:

1. The resolved manuscript file — extract the title, the abstract, the introduction, any `\jelclass`/JEL codes, and any keywords. The abstract and introduction are the primary evidence of field and contribution.
2. `worklog/RESEARCH_BRIEF.md` if it exists — read all six fields, especially **Research question**, **Contribution claim**, **Identification strategy**, **Model class candidate**, **Data plan**, and **Target journal**.
3. `THEORY_PRIORS.md` if it exists — read the **Declared model class** and the `<!-- BEGIN USER-SPECIFIED -->` … `<!-- END USER-SPECIFIED -->` fence. Any "Target journal" line inside that fence is a **user-declared target** and is a hard constraint: you may assess its fit and note alternatives, but never silently drop or contradict it.

From these, derive the paper's traits:
- **Field tags** (e.g. macro, international, monetary, finance, growth, capital-flows).
- **Method**: one of `theoretical | empirical | structural | mixed`.
- **Contribution type**: one of `new model | new mechanism | new empirical fact | methodological | policy`.
- **Model class** (from THEORY_PRIORS.md if declared, else "n/a").
- **User-declared target journal**, recorded verbatim with its source file, or "none".

Base traits only on what the paper actually says. Do not infer a field the paper does not claim.

## Step 2 — Load journal profiles

Read `journals.yaml` from **this skill's own directory** at runtime: `.claude/skills/match-journal/journals.yaml`. This is the grounded source of truth for every journal claim you make — name, type, scope, and source URL. Do not assert any journal scope, ranking, accept rate, or review time that is not in this file.

Note each profile's `verification` field, which records provenance (highest trust first): `fetched:<date>` (from the publisher's own page), `web-research:<date>` (corroborated via web search of the publisher page and reliable secondary sources, because a direct fetch was bot-blocked), or `from-model-knowledge` (uncorroborated). Treat `web-research` and `from-model-knowledge` scope as not pulled from the live publisher page, and surface that in the report's Caveats.

## Step 3 — Optional live refresh (hybrid)

Perform this step **only if** the user passed the `refresh` argument. Otherwise skip it and record in the report that profiles are as of `journals.yaml`'s `built` date.

For each journal, obtain its current aims & scope using this **escalation ladder**, stopping at the first rung that yields the scope text. Record which rung succeeded as the refresh provenance for that journal (it mirrors the `verification` tiers):

1. **`curl` the publisher page** (`Bash`, mirror `research/SKILL.md` Step 2 — `curl -sL` with a browser User-Agent on `aims_scope_url`). Strip HTML to text. If it returns the real aims-&-scope text → provenance `fetched`.
2. **`WebFetch` the publisher page** if `curl` returned a CAPTCHA/JS wall, non-200, or empty body. Prompt it to extract the aims-&-scope text from `aims_scope_url`. If it returns the real text → provenance `fetched` (still the publisher's own page).
3. **`WebSearch`** if both direct fetches are blocked. Query the journal's aims & scope; corroborate from the publisher's description and reliable secondary sources (e.g. the society page, Wikipedia, Scimago). If it yields the scope → provenance `web-research`.
4. **All blocked** → record the journal as "scope unavailable this run" and keep the curated value.

Then compare what you obtained against the stored `scope_summary`:
- Material agreement → note the journal as **confirmed** (with the rung/provenance).
- Material divergence → record a **drift flag** capturing the stored text, the freshly obtained text, and the provenance rung.

**Never rewrite `journals.yaml` from this step.** The curated file is human-verified; refresh only *flags* drift (and proposes the fresh text + provenance) for a human to apply. Do not use WebSearch/WebFetch outside this `refresh` step — the no-refresh path stays offline (Read + the curated file only).

## Step 4 — Grounded fit assessment (Claude-only)

For each journal in `journals.yaml`, assign a categorical fit and a rationale. Reason only from the paper traits (Step 1) and the journal profile (Step 2). No external model, no Zotero, no web call (beyond the optional Step 3 refresh).

**Fit categories** (use exactly one; do not invent numeric scores):
- **Strong** — the paper's field and method sit squarely inside the journal's stated scope; a natural primary target.
- **Moderate** — clear topical overlap but a mismatch in emphasis, method, breadth, or format.
- **Weak** — only tangential overlap; a stretch submission.
- **Poor** — outside the journal's stated scope.

Each rationale must (a) name the specific paper trait it matched, (b) quote or closely paraphrase the specific `scope_summary` text it matched against, and (c) cite the journal's `aims_scope_url`.

**Forbidden in any rationale or anywhere in the output:** acceptance probabilities, accept rates, "X% chance", "competitive but feasible" framed as odds, review-time estimates, or any scope claim not present in `journals.yaml`. If you catch yourself writing a number about acceptance, delete it.

Rank journals by fit (Strong → Moderate → Weak → Poor); within a tier, order general-interest by prestige tier then field journals by topical closeness.

## Step 5 — Produce the report

Write to `worklog/review/journal-targets-{ISO-8601-timestamp}.md` (timestamp from `Bash`: `date -u +%Y-%m-%dT%H:%M:%SZ`, with colons replaced by hyphens in the filename). Use exactly this structure:

```markdown
---
title: "Journal targeting: {paper title}"
version: "1.0.0"
generated_by: /match-journal
generated_at: {ISO-8601}
paper_slug: {from paper_config.yaml}
profiles_as_of: {journals.yaml built date}
refresh_run: {true|false}
journals_assessed: {N}
disclaimer: "Scope/contribution fit only — not an acceptance prediction."
---

# Journal Targeting Report: {paper title}

> Advisory and non-authoritative. Ranks journals by alignment with each journal's
> stated aims & scope. It does NOT predict acceptance. Verify current scope at the
> linked pages before submitting.

## TL;DR — Top recommendations
1. {Journal} — {Strong} — {one-line why}
2. {Journal} — {Strong/Moderate} — {one-line why}
3. {Journal} — {Moderate} — {one-line why}

## Paper profile (extracted)
- Field(s): {tags}
- Method: {theoretical|empirical|structural|mixed}
- Contribution type: {new model|new mechanism|new empirical fact|methodological|policy}
- Model class: {from THEORY_PRIORS.md, or "n/a"}
- JEL / keywords: {if present in paper/main.tex, else "none found"}
- User-declared target (if any): {journal — source: worklog/RESEARCH_BRIEF.md / THEORY_PRIORS.md, or "none"}

## Ranked recommendations
| Rank | Journal | Fit | Why (scope match) | Source |
|------|---------|-----|-------------------|--------|
| 1 | {name} | Strong | {trait ↔ scope text} | {aims_scope_url} |
| 2 | ... | ... | ... | ... |

### Per-journal rationale
#### {Journal} — {Fit}
{2–4 sentences: which paper trait matches which scope text; the notable mismatch or risk; a practical note (length, short-paper sibling, methodological framing). Cite {aims_scope_url}.}

(repeat for every journal assessed)

## User-declared target assessment
{If a target was declared: name it, give its fit category, and state whether the ranking
agrees with it or suggests reconsidering — with reasons. If none: "No target journal
declared in worklog/RESEARCH_BRIEF.md or THEORY_PRIORS.md."}

## Drift flags
{If refresh_run: a one-line summary of how many journals were confirmed vs. drifted vs.
unavailable, with the rung each was obtained by (curl/WebFetch = `fetched`, search =
`web-research`). For each drifted journal, show the stored text, the freshly obtained text,
and the provenance rung, so a human can update journals.yaml. List any "scope unavailable
this run" journals. Else: "Live refresh not run; profiles as of {built date}."}

## Caveats
- Fit ≠ acceptance. Editorial taste, novelty bar, and timing are not modeled here.
- Journal scope changes; confirm at the linked pages before submitting.
- Coverage is limited to the {N} journals in journals.yaml (top general-interest plus
  macro / international / monetary field journals) — it is not exhaustive.
- Profile provenance (journals.yaml `verification`): {count} fetched from the publisher's
  own page; {count} `web-research` (corroborated via search, not the live publisher page);
  {count} `from-model-knowledge` (uncorroborated). Run `/match-journal refresh` to re-check
  any non-`fetched` entries. {List `web-research`/`from-model-knowledge` journal keys, or "none".}

## Provenance
- Generated by: {model id}
- Generated at: {ISO-8601}
- Profiles source: .claude/skills/match-journal/journals.yaml (built {built date})
- Inputs read: {paper/main.tex, worklog/RESEARCH_BRIEF.md?, THEORY_PRIORS.md?}
```

## Step 6 — Deterministic lint before writing

Before writing the file, lint the report mechanically. **This lint must not use an LLM judgment call.** Check:

1. All sections present: TL;DR, Paper profile, Ranked recommendations, Per-journal rationale, User-declared target assessment, Drift flags, Caveats, Provenance.
2. All frontmatter fields populated and non-placeholder: `title`, `version`, `generated_by`, `generated_at`, `paper_slug`, `profiles_as_of`, `refresh_run`, `journals_assessed`, `disclaimer`.
3. `disclaimer` is present and contains the string "not an acceptance prediction".
4. Every fit value used (in the table and the per-journal headers) is one of: `Strong`, `Moderate`, `Weak`, `Poor`. No numeric scores.
5. Every journal named in the Ranked recommendations table exists as a `key` (or `name`) in `journals.yaml`.
6. Every per-journal rationale block contains an `http` URL (the `aims_scope_url` citation).
7. `journals_assessed` equals the number of per-journal rationale blocks, and equals the number of journals in `journals.yaml`.
8. If a user-declared target was found in Step 1, the User-declared target assessment section names that journal.
9. The report contains no acceptance-probability or accept-rate language (no `%` adjacent to "accept", no "odds", no "chance of acceptance", no review-time estimate).

If any check fails: do not write the file. Tell the user exactly which check failed and what is missing or malformed. Do not write a partial report.

If all checks pass: write the file to `worklog/review/`.

## Exit

After writing the report, tell the user:
- The path written.
- The top 3 ranked journals with their fit category and one-line why.
- Whether a user-declared target was found, and its fit.
- Whether `refresh` was run and whether any drift was flagged.
- The closing reminder: "This is a scope-fit assessment, not an acceptance prediction. Verify current scope at the linked pages before submitting."

Do not auto-invoke any other skill. Choosing and formatting for a target journal is the user's call.
