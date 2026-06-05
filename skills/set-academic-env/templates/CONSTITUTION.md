# CONSTITUTION

Inviolable rules for this paper. The AI must obey these without exception.
Override requires an ADR in `docs/adr/`.

## Source of truth
1. Zotero is the AI's source of truth for research material (per ADR 0007).
   Never cite from `research/*.md`. Always cite from primary sources in Zotero.
   If you need to write about a paper, query Zotero and read it.
2. `main.tex` is the canonical source for the paper (per ADR 0001).
   `.docx` exists only as a coauthor-facing Pandoc export.

## Notation
3. FX series are always quoted as USD/foreign currency, never inverted.
   (Edit this list with paper-specific notation rules before /start-paper.)

## Authorship
4. AI-edited paragraphs are tagged with `% AI:claude-<model> YYYY-MM-DD prompt:<ref>`.
5. Git commits with AI edits include `Co-Authored-By: Claude <noreply@anthropic.com>`.

## Verification
6. SymPy tool calls are only trusted via verified `tool_use_id`. Inline
   "looks-correct" output that wasn't produced by an actual tool call is
   discarded.
7. Heavy tasks (per the hard-coded list) require human approval before running.

## Add paper-specific rules below
