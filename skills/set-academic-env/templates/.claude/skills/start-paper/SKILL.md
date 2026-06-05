---
name: start-paper
description: Use to begin a greenfield paper. Opens a grill-with-docs session on worklog/IDEA.md and worklog/CONTEXT.md. Refuses to write to paper/main.tex. Exit by invoking /scope-paper.
allowed-tools: Read Write Edit Bash
metadata:
  version: "0.1.0"
---

# /start-paper — Greenfield entry point

You are opening the greenfield drafting pipeline for a new academic economics paper per ADR 0006.

## Precondition checks

Run all three checks before doing anything else. Refuse with the exact message shown if any fails.

**Check 1 — THEORY_PRIORS.md exists:**
Read `THEORY_PRIORS.md` in the paper repo. If the file does not exist, refuse:
> "THEORY_PRIORS.md not found. Run /set-academic-env first to scaffold the paper repo, then fill in your hard constraints before running /start-paper."

**Check 2 — USER-SPECIFIED fence is non-empty:**
Read the contents between `<!-- BEGIN USER-SPECIFIED -->` and `<!-- END USER-SPECIFIED -->` in THEORY_PRIORS.md. If the fence contains only the TODO placeholder ("TODO: fill these in before running /start-paper") or is otherwise empty of real content, refuse:
> "THEORY_PRIORS.md USER-SPECIFIED fence is empty or still contains the TODO placeholder. Fill in your hard constraints (open-economy frame, welfare discipline, target journal, any paper-specific invariants) between the BEGIN USER-SPECIFIED and END USER-SPECIFIED markers before running /start-paper. The harness will not begin grilling until you have committed these upfront."

**Check 3 — paper_config.yaml exists and zotero.collection_key is populated:**
Read `paper_config.yaml`. If the file does not exist, refuse:
> "paper_config.yaml not found. Run /set-academic-env first to scaffold the paper repo."
If `zotero.collection_key` is still "TODO", refuse:
> "paper_config.yaml has zotero.collection_key: TODO. Create the Zotero collection for this paper, paste the collection key into paper_config.yaml, and re-run /start-paper. See SETUP.md for the step-by-step."

All three checks must pass before proceeding. Do not proceed past a failed check.

## Setup

1. If `worklog/IDEA.md` does not exist in the paper repo, create it as an empty file with a single comment: `<!-- Grill output — populated by /start-paper session -->`
2. If `worklog/CONTEXT.md` does not exist in the paper repo (note: this is the *paper-level* CONTEXT.md, not the harness-level one), create it as an empty file with a single comment: `<!-- Paper-specific glossary — populated incrementally during /start-paper session -->`

## Grill session

Invoke the `~/.claude/skills/grill-with-docs` skill on `worklog/IDEA.md` and the paper-level `worklog/CONTEXT.md`. Reference that skill by name — do not replicate or paraphrase its instructions here.

The skill will interview the user relentlessly, one question at a time, update worklog/CONTEXT.md inline as terminology crystallises, and challenge the plan against the documented domain model. The output of the session is a populated `worklog/IDEA.md` and a growing paper-level `worklog/CONTEXT.md`.

**Invocation instruction:** Load and run `~/.claude/skills/grill-with-docs` now, targeting `worklog/IDEA.md` and the paper-level `worklog/CONTEXT.md` as the primary documents. Do not proceed with any other action until the skill is loaded.

## Hard refusal — paper/main.tex writes are forbidden in this command

Any Write or Edit request targeting `paper/main.tex` (or any `.tex` file) during a /start-paper session must be refused immediately:
> "Writing to paper/main.tex is not permitted during /start-paper. This command's only job is to grill the idea and populate worklog/IDEA.md and worklog/CONTEXT.md. When the idea is fully grilled, invoke /scope-paper to synthesize and commit the model class. /draft-paper is where paper/main.tex gets written."

Note: Phase 7's PreToolUse hook will enforce this mechanically. This prompt-level instruction is the current enforcement until that hook is built.

Do not write, create, or edit any `.tex` file for any reason during this command, even if the user requests it.

## Exit condition

This command does not auto-transition. Continue the grill session until the user explicitly types `/scope-paper`. When the user invokes `/scope-paper`, this session ends — do not synthesize, do not write worklog/RESEARCH_BRIEF.md, do not transition the state machine. Those are /scope-paper's job.

Do not suggest or offer to "move on to the next step." Let the user decide when the idea is fully grilled.
