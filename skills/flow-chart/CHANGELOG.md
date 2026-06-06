# Changelog — flow-chart

## 2026-06-06
- Major rewrite after first real test (flowchart of set-academic-env) was rejected: output was a procedural code transcription with jargon labels (`SKIP_VENV=1?`) and clipped text in decision diamonds.
- Reviewed from three angles (information design, rendering technology, skill-prompt structure) by parallel review agents; findings synthesized into v0.2.0:
  - **Altitude**: added audience-first purpose statement, two-pass workflow (merge steps into outcome-named stages, then attach detail), hard node budget (5–9 stages, ≤12 nodes, ≤3 diamonds), good/bad label examples.
  - **Labels**: banned identifiers, env vars, flags, paths, placeholders, and code from node labels; added the "diamond test" so config toggles never become decision diamonds.
  - **Detail**: introduced detail hierarchy — label → hover tooltip → click-to-expand side panel → page subtitle.
  - **Rendering**: replaced hand-coded absolute-coordinate SVG (which made text clipping geometrically inevitable in diamonds) with Mermaid.js pinned at 11.4.1 via CDN; embedded a full HTML template with tooltip + detail-panel wiring and a Mermaid pitfalls list (quoting, reserved words, securityLevel).
  - **Structure**: fixed frontmatter name mismatch (`flowchart-creator` → `flow-chart`), added `allowed-tools`, moved content rules before rendering reference, added self-review gate and explicit output contract (location, open in browser, report + drill-down offer).

## 2026-06-05
- Initial draft (hand-coded SVG approach), committed as pre-review baseline.
