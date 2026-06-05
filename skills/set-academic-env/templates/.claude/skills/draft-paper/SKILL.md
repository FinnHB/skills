---
name: draft-paper
description: Use after /scope-paper to produce paper/main.tex section-by-section. Reads worklog/RESEARCH_BRIEF.md, worklog/CONTEXT.md, THEORY_PRIORS.md, worklog/research/, related/, and primary sources via Zotero. Writes % TKTK: for unknowns; never re-elicits mid-section.
allowed-tools: Read Write Edit Bash mcp__zotero__* mcp__pal__*
metadata:
  version: "0.1.0"
---

# /draft-paper — Section-by-section paper/main.tex production

You are running the third phase of the greenfield pipeline per ADR 0006. Your job is to write `paper/main.tex` section by section using the scoped artifacts as your blueprint and Zotero as your citation source. You do not ask the user questions during drafting. You write `% TKTK:` markers for unknowns and proceed.

Resolve the manuscript and bibliography paths from `paper_config.yaml` `paths:` (defaults `paper/main.tex`, `paper/references.bib`); do not assume the repo root.

You may consult `logs/operations.jsonl` for prior runs on this paper before starting.

## Precondition checks

Run all three checks before doing anything else. Refuse with the exact message shown if any fails.

**Check 1 — worklog/RESEARCH_BRIEF.md exists and passes checklist gate:**
Read `worklog/RESEARCH_BRIEF.md`. If it does not exist, refuse:
> "worklog/RESEARCH_BRIEF.md not found. Run /scope-paper first."

Apply the same deterministic lint as /scope-paper: verify all six required fields are present, non-empty, and free of placeholder text (`TODO`, `TBD`, `N/A`, `{`, `}`). If any field fails:
> "worklog/RESEARCH_BRIEF.md is missing or has incomplete field: <field name>. Run /scope-paper again to fix."

**Check 2 — THEORY_PRIORS.md has model_class_status declared or locked:**
Read `THEORY_PRIORS.md`. Check the YAML frontmatter field `model_class_status`. If the value is `candidate` (not `declared` or `locked`), refuse:
> "THEORY_PRIORS.md has model_class_status: candidate. /draft-paper requires a declared or locked model class. Run /scope-paper to commit the model class before drafting."

**Check 3 — paper/references.bib is in sync:**
Check whether `paper/references.bib` exists (resolved from `paper_config.yaml` `paths.references`).
- If it does not exist: invoke `/sync-zotero` to create it. Report to the user: "paper/references.bib not found — invoking /sync-zotero to export the Zotero collection before drafting begins."
- If it exists but its modification time is more than 48 hours older than `paper_config.yaml`'s `harness.installed_at`, or if the user has run /research since the last sync: invoke `/sync-zotero` to refresh. Report: "paper/references.bib may be stale — invoking /sync-zotero to refresh before drafting begins."

All three checks must pass before proceeding.

## Load context (read in this order before drafting any section)

Read the following documents fully before writing a single line of LaTeX:

1. `worklog/RESEARCH_BRIEF.md` — your blueprint. The section structure to produce is declared here.
2. Paper-level `worklog/CONTEXT.md` — the paper's glossary and terminology.
3. `THEORY_PRIORS.md` — model class, hard constraints, forbidden moves. Honor all of them.
4. All `worklog/research/*.md` files — read **TL;DR** and **Papers added to Zotero** sections ONLY. Do not read Key Findings. Do not paraphrase Key Findings. Per ADR 0007: the AI's source of truth for research material is Zotero, not the markdown summaries. The research markdowns tell you which Zotero items are available and what topics have been covered — nothing more.
5. All files in `related/` if that directory is non-empty — read as prior-paper context.

## Section structure

Derive the section structure from `worklog/RESEARCH_BRIEF.md`. The typical structure for an AER/JPE macro paper is:

1. Introduction
2. Related Literature
3. Model
4. Equilibrium (or Model Solution / Analytical Results)
5. Calibration / Estimation (if applicable — omit if purely theoretical)
6. Results
7. Conclusion

If `worklog/RESEARCH_BRIEF.md` specifies a different structure, follow it exactly.

## Drafting protocol — one section at a time

For each section, follow this protocol in order:

### Step A — Load Zotero sources for this section

Before drafting any section that cites literature:
1. Load the `references-management` skill (located at `.claude/skills/references-management/`). Do not perform Zotero operations without it.
2. Use the skill to query the Zotero collection for papers relevant to this section. The collection key is in `paper_config.yaml` at `zotero.collection_key`.
3. Read the primary source content for each paper you intend to cite. Do not cite from the research markdowns — always go to the Zotero item.

### Step B — Draft the section

Write the section as LaTeX, appending to `paper/main.tex` (or creating it for the Introduction).

**Attribution markers:** Begin every paragraph you draft with an attribution comment:
```latex
% AI:claude-sonnet-4-6 YYYY-MM-DD prompt:<short-description-of-what-was-requested>
```
This satisfies the audit trail requirement per ADR 0001.

**Citation format:** Use `\cite{citekey}` with Better BibTeX `author-year-shorttitle` format (e.g., `\cite{gali2008monetary}`). Every citekey must resolve to an entry in the paper's Zotero collection and in `paper/references.bib`.

**Unknowns — the % TKTK rule:** When you encounter anything you do not know, cannot derive from the loaded context, or that requires a judgment the user must make:
- Write `% TKTK: <single-sentence question>` at the point in the LaTeX where the answer would go.
- Write a reasonable placeholder or structural blank (e.g., `\cite{TKTK}`, `[TKTK: calibration value]`, `equation omitted — see TKTK above`) and continue.
- **Never stop to ask the user the question.** Never say "I need to know X before I can continue." Never re-elicit mid-section for any reason. The % TKTK marker is the only valid handling of unknowns.

This rule is explicit and load-bearing per ADR 0006. The documented failure mode of re-eliciting mid-draft is continuation drift: the session loses coherence and the drafter reconstructs context from unreliable summaries. Write the marker and proceed.

**Forbidden — citing from worklog/research/*.md:** You may read the TL;DR and Papers added to Zotero sections of research markdowns to orient yourself. You must not cite from the Key Findings section of any research markdown. Citations in `paper/main.tex` must trace to primary sources in Zotero. Per ADR 0007, this is a hard rule.

### Step C — Integrity gate invocation point

After completing each section, note the following invocation point for the integrity-gate skill:

> After drafting section {section name}, invoke the `integrity-gate` skill on this section before proceeding to section {next section name}.

Phase 4 builds the integrity-gate skill. For now, document this invocation point in a comment at the end of each section in `paper/main.tex`:
```latex
% INTEGRITY-GATE: invoke integrity-gate skill on this section before proceeding.
```

When Phase 4 is complete, the integrity-gate skill will be invoked here and the comment replaced with its output summary. Until then, the comment marks the invocation point for Phase 7's hook infrastructure.

Proceed to the next section only after the integrity-gate invocation point is documented.

## paper/main.tex write refusal

Note: `/start-paper` and `/scope-paper` both prohibit writing to `paper/main.tex`. /draft-paper is the one command that IS authorized to write `paper/main.tex`. Phase 7's PostToolUse hook will snapshot every `.tex` edit via `latexdiff`. This is expected and correct behavior during /draft-paper.

## Session length guidance

Drafting a full paper may exceed a single Claude Code session's context window. Recommendation: run /draft-paper in a fresh session per major section (Introduction, Model, Results) if the paper is long. Before starting a new section session, re-load /draft-paper to re-run preconditions and re-read context. This reduces continuation drift.

## End-of-command summary

After completing all sections (or when the user ends the session), provide a summary in the conversation:

1. **Sections drafted:** list each section name and its approximate line count in `paper/main.tex`.
2. **% TKTK markers:** count and list each marker with its question. These are the open items the user must resolve before /refine-heavy can run cleanly.
3. **Integrity-gate flags:** list any INTEGRITY-GATE comment blocks left in `paper/main.tex`. These mark where Phase 4's integrity-gate needs to be invoked.
4. **Citation count:** how many `\cite{}` calls were written.
5. **Next step:** "Review the % TKTK markers. Resolve the ones you can by editing `paper/main.tex` directly, or by running /research [topic] to add more Zotero sources. When ready for review, run /refine-light or /refine-heavy."
