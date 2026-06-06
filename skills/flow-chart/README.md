# flow-chart

Creates purpose-level HTML flowcharts a newcomer can read in ~30 seconds. Renders with Mermaid.js (auto-layout — no clipped text), with hover tooltips and a click-to-expand detail panel where implementation specifics live. Node labels are plain language only; identifiers, env vars, and file paths are banned from labels by design.

## Usage examples

```
/flow-chart make a flowchart of the deployment pipeline
```

```
/flow-chart visualize what install.sh does
```

```
Create a decision tree for how we triage incoming bug reports.
```

## What you get

- `<process>-flowchart.html` — self-contained page (Mermaid via pinned CDN), opened in your browser
- 5–9 purpose-named stages, max 3 decision diamonds; happy path in one straight line
- Hover a node for a 1–2 sentence summary; click for full implementation details in a side panel
- An offer to drill down into any stage with a separate sub-chart

## Design rules baked in

- Audience first: the chart answers one question for a reader who has never seen the source
- Two-pass workflow: merge procedural steps into outcome-named stages, then attach detail to tooltips/panel
- Diamond test: config toggles and internal fallbacks never get decision diamonds
- Self-review gate before the file is written
