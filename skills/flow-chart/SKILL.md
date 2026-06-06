---
name: flow-chart
description: Create audience-appropriate HTML flowcharts and process diagrams with hover tooltips and click-to-expand details. Use when users ask for a flowchart, process diagram, workflow visualization, decision tree, or a visual of how a script/system/process works. Produces purpose-level diagrams a newcomer can read in 30 seconds — not code transcriptions.
allowed-tools: Read Write Bash
metadata:
  version: "0.5.1"
---

# Flow Chart

Turn a process into a diagram a newcomer can read in ~30 seconds. The chart is the *story* of the process; implementation specifics live in tooltips and a click-to-expand detail panel, never in node labels. If understanding a node requires having seen the source, the node is wrong.

## Scope first

Chart exactly what the user named. A specific component ("refine-heavy in repo X") → chart that component's process only. A whole repo/system → chart its primary user-facing process. If the target is ambiguous (multiple matches, or unclear whether they want the system or one part), do NOT guess — come back with the concrete options and let the user pick.

## Plan before rendering

1. Write a one-sentence purpose statement (becomes the page subtitle): who reads this, what question it answers. Default audience: someone who has never seen the source.
2. List the atomic steps, then **merge** consecutive steps serving one purpose into a stage named by its *outcome* ("copy templates / copy hooks / create dirs" → "Set up project structure"). Show the planned stage list in your response.
3. Hard budget: **5–9 stages, ≤12 nodes total, ≤3 diamonds.** Need more? The altitude is wrong — merge harder, or make an overview chart plus drill-down sub-charts per stage (`<slug>-<stage>-flowchart.html`, same budget inside the stage).

## Labels

- Process = imperative verb phrase, ≤6 words, outcome not mechanism. Decision = plain question, 1–2 words where possible ("Approved?", "Checks pass?") — the edge labels carry the answers, and short diamonds render ~40% smaller.
- **Banned in labels:** variable/function names, env vars, flags, file paths, exit codes, placeholders, code. All of it goes in tooltip or detail panel.
- Bad → good: `Record HARNESS_SHA` → `Pin tool versions for reproducibility`; `SKIP_VENV=1?` → no node at all (config toggle → detail panel).

## Diamonds and error paths

- A decision gets a diamond only if the reader could realistically be on either branch AND the branches visibly diverge on the chart. Config toggles, internal fallbacks ("uv, else python3"), and keep-if-exists checks fold into their stage's detail entry.
- Happy path runs in one straight line. Same-outcome failures share one "Stop: …" node; causes go in the detail panel.

## Render

Copy `template.html` from this skill's directory; replace the title, kicker (project name in the `.name` span), subtitle, `accTitle`/`accDescr`, mermaid graph, `linkStyle` error-edge indices, click bindings, and `DETAILS` map. The template carries the design system (typography, dot-grid backdrop, tinted node palette, legend, interactions, print appendix) — do not restyle per chart unless the user asks. Node classes: `start` (outlined), `process` (indigo), `decision` (amber), `success` (green), `stop` (red, dashed). Use rounded process rects `P1("...")`, not `P1["..."]`. Each stage gets a 1–2 sentence tooltip and a detail-panel entry carrying whatever it merged away.

Mermaid pitfalls: pin `mermaid@11.4.1` (never `@latest`); always quote labels (`id["..."]`) — unquoted `( ) { } # ;` are parse errors; write "and" not `&`; `end` is reserved; keep ids short (`P1`, `D2`); `securityLevel: "loose"` is required or clicks silently fail; CDN means online-only rendering (vendor the `.mjs` for offline). Never hand-place coordinates — `TD` for tall flows, `LR` for wide.

## Self-check, then output

Before writing the file: every label readable by someone who never saw the source; nothing banned in labels; within budget; diamonds pass the test; branches labeled; all labels quoted; `linkStyle` error-edge indices match the 0-based declaration order of the error edges (count them — they are positional).

Write `<kebab-slug>-flowchart.html` to the cwd (or where asked), open it in the browser, and report: path, chosen altitude, node count — plus an offer to drill down into any stage (detail is deferred, not lost).
