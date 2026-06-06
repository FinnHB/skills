---
name: flow-chart
description: Create audience-appropriate HTML flowcharts and process diagrams with hover tooltips and click-to-expand details. Use when users ask for a flowchart, process diagram, workflow visualization, decision tree, or a visual of how a script/system/process works. Produces purpose-level diagrams a newcomer can read in 30 seconds — not code transcriptions.
allowed-tools: Bash, Read, Write, Edit
metadata:
  version: "0.6.0"
---

# Flow Chart

Turn a process into a diagram someone who has never seen the source can read in ~30 seconds. Implementation specifics live in tooltips and the detail panel, never in node labels.

## 1. Scope

Chart exactly what the user named: a component → that component's process; a whole repo/system → its primary user-facing process. Ambiguous target (multiple matches, or system-vs-part unclear)? Don't guess — reply with the concrete options and let the user pick before charting. Always emit `flowchart` (never stateDiagram/sequenceDiagram etc.); model states as nodes and transitions as labeled edges.

## 2. Plan

1. One-sentence purpose statement (becomes the page subtitle): who reads this, what question it answers.
2. List atomic steps, then merge consecutive steps serving one purpose into a stage named by its outcome ("copy templates / copy hooks / create dirs" → "Set up project structure"). State the stage list in your response, then proceed — don't wait for approval.
3. Hard budget: **≤9 stages (typically 5–9; never pad a short process), ≤12 nodes total (start/end/stops/diamonds included), ≤3 diamonds.** Over budget = wrong altitude: merge harder, or make an overview plus per-stage drill-downs (`<slug>-<stage>-flowchart.html`, same budget each; link each drill-down from its stage's detail entry).

## 3. Labels

- Process: imperative verb phrase, ≤6 words, outcome not mechanism.
- Decision: plain question, ideally 1–2 words ("Approved?", "Checks pass?") — edge labels carry the answers, and short diamonds render smaller.
- **Banned:** variable/function names, env vars, flags, file paths, exit codes, placeholders, code — all of it goes to the tooltip or detail panel. `Record HARNESS_SHA` → `Pin tool versions for reproducibility`; `SKIP_VENV=1?` → no node at all (config toggle → detail panel).

## 4. Diamonds and error paths

- Diamond only if the reader could realistically be on either branch AND the branches visibly diverge on the chart. Config toggles, internal fallbacks ("uv, else python3"), and keep-if-exists checks fold into the stage's detail entry. Label every branch edge.
- Happy path: one straight line. Same-outcome failures share one "Stop: …" node. Failure causes live in the detail entry of the decision that routes there; stop nodes get no click binding.
- Exception — the user asked for a *decision tree*: the chart IS the decisions. Drop the diamond cap, keep ≤12 nodes total, nest ≤3 levels deep.

## 5. Render

`cp` `template.html` from this skill's directory to the target file, then Edit only the slots listed in its header comment — never retype or regenerate the file from memory; everything outside the slots stays byte-identical.

- Node classes: `start` (outlined), `process` (indigo, rounded: `P1("...")`), `decision` (amber), `success` (green), `stop` (red, dashed). Bind a 1–2 sentence tooltip + a `DETAILS` entry to every process, decision, and success node — not start/stop. Detail entries carry whatever their stage merged away.
- After the edges, write the `%% edge index map:` comment (own line — trailing comments are a parse error) enumerating every edge 0-based in declaration order, marking error edges `(error)`; subgraph-internal edges count. Derive `linkStyle` indices from that map — they index ALL edges, not just error ones. No error edges → delete the red `linkStyle` line entirely (an out-of-range index aborts the whole render).
- If the user supplies brand colors, keep the pattern: tinted fill + saturated stroke + dark same-hue text (≥7:1 contrast), and Stop keeps its dashed border — never encode state by hue alone. Otherwise don't restyle.

Mermaid pitfalls:
- Keep the pinned mermaid version and `securityLevel: "loose"` exactly as in the template — clicks fail silently without it, and the keyboard handler depends on 11.x DOM-id internals. CDN = online-only rendering; for offline, vendor `dist/mermaid.min.js` (UMD, single file) and swap to a classic script — the ESM build lazy-loads chunks and cannot be vendored as one file.
- Quote every node AND edge label: `P1("...")`, `-- "Yes" -->`. No double quotes inside any quoted string (labels, edge labels, click tooltips) — rephrase or use `#quot;`. Write "and" not `&`, `&lt;` for a literal `<`. Edge operators are ASCII (`-->`), never unicode arrows.
- Ids match `[A-Z][A-Za-z0-9]*` (`P1`, `D2`) — no hyphens or underscores (the keyboard handler parses DOM ids); `end` is reserved.
- `DETAILS` bodies are JS template literals: never put backticks or `${` inside them — use `<code>` tags and HTML entities.
- Swimlanes: `subgraph SG1["Lane name"] ... end` (quoted title); node ids stay global; lane-internal edges still count toward linkStyle indices.
- Direction only — `flowchart TD` by default, `LR` only for near-linear flows (≤1 diamond); never hand-place coordinates.

## 6. Check, then ship

1. Every label readable without the source; nothing banned in labels; within budget; diamonds pass the branch test; branches labeled.
2. Click lines, `DETAILS` keys, and node ids are the same case-sensitive set (the template logs console errors on mismatch).
3. `grep -n '\[Process Name\]\|\[project-name\]\|\[One-sentence' <file>` — any hit is an unfilled slot (tab title and screen-reader text don't show in the browser).
4. `linkStyle` indices re-derived from the edge index map, or the red line deleted.

Write `<kebab-slug>-flowchart.html` to the cwd (or the path the user gave); open it (`open` on macOS, `xdg-open` on Linux — if that fails, skip it and just report). Report: absolute path, chosen altitude, node count, and an offer to drill into any stage — detail is deferred, not lost.
