# Changelog — flow-chart

## 2026-06-06 (v0.4.0)
- Redesigned `template.html` with an "engineering paper" design system: dot-grid backdrop, Fraunces display + IBM Plex Sans/Mono typography, muted committed palette, legend chips, refined cards/shadows, always-visible detail panel with placeholder, staggered load animation (with reduced-motion fallback). Principles adapted from the official frontend-design plugin's guidance, filtered for document-grade restraint; plugin itself not installed (prose-only, tuned for bold app UIs, would trigger on all frontend work).
- Design lives entirely in `template.html` (progressive disclosure) — SKILL.md gained only one sentence: don't restyle per chart unless asked.

## 2026-06-06 (v0.3.1)
- Added "Scope first" rule after testing on a named component (refine-heavy within AcademicPaperWriter): chart exactly what the user named; for a whole repo chart its primary user-facing process; if ambiguous, present concrete options instead of guessing (user-confirmed behavior).

## 2026-06-06 (v0.3.0)
- Condensed SKILL.md from ~200 to ~45 lines after user feedback that it was much too long: extracted the embedded HTML boilerplate into `template.html` (the skill now copies and fills it), merged the seven rule sections into four, kept all hard constraints (node budget, banned label content, diamond test, self-check, output contract).
- Added explicit drill-down convention: `<slug>-<stage>-flowchart.html`, same budget applied inside the stage.

## 2026-06-06 (v0.2.0)
- Major rewrite after first real test (flowchart of set-academic-env) was rejected: output was a procedural code transcription with jargon labels (`SKIP_VENV=1?`) and clipped text in decision diamonds.
- Reviewed from three angles (information design, rendering technology, skill-prompt structure) by parallel review agents; findings synthesized into v0.2.0:
  - **Altitude**: added audience-first purpose statement, two-pass workflow (merge steps into outcome-named stages, then attach detail), hard node budget (5–9 stages, ≤12 nodes, ≤3 diamonds), good/bad label examples.
  - **Labels**: banned identifiers, env vars, flags, paths, placeholders, and code from node labels; added the "diamond test" so config toggles never become decision diamonds.
  - **Detail**: introduced detail hierarchy — label → hover tooltip → click-to-expand side panel → page subtitle.
  - **Rendering**: replaced hand-coded absolute-coordinate SVG (which made text clipping geometrically inevitable in diamonds) with Mermaid.js pinned at 11.4.1 via CDN; embedded a full HTML template with tooltip + detail-panel wiring and a Mermaid pitfalls list (quoting, reserved words, securityLevel).
  - **Structure**: fixed frontmatter name mismatch (`flowchart-creator` → `flow-chart`), added `allowed-tools`, moved content rules before rendering reference, added self-review gate and explicit output contract (location, open in browser, report + drill-down offer).

## 2026-06-05
- Initial draft (hand-coded SVG approach), committed as pre-review baseline.
