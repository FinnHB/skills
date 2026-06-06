---
name: flow-chart
description: Create audience-appropriate HTML flowcharts and process diagrams with hover tooltips and click-to-expand details. Use when users ask for a flowchart, process diagram, workflow visualization, decision tree, or a visual of how a script/system/process works. Produces purpose-level diagrams a newcomer can read in 30 seconds — not code transcriptions.
allowed-tools: Read Write Bash
metadata:
  version: "0.2.0"
---

# Flow Chart

Turn a process into a diagram a newcomer can read in ~30 seconds. Abstraction first, rendering second: the chart is the *story* of the process; implementation specifics live in tooltips and a detail panel, never in node labels.

## Guiding principle: purpose over procedure

The reader has NOT read the source and never will. If understanding a node requires having seen the code, the node is wrong. The chart answers "what happens when this runs, as I'd explain it to a colleague" — not "what lines execute in what order".

## Step 1 — Audience and purpose

Before drawing anything, write one sentence (it becomes the page subtitle): "This chart shows [audience] [what happens / how X decides Y] when [process runs]." Default audience: a person who has never seen the source. Source code never dictates altitude.

## Step 2 — Plan the skeleton (before any code)

Never draw in one pass from the source:

1. List the atomic steps as rough notes (not nodes).
2. **Merge** consecutive steps that serve a single purpose into one stage, named by its *outcome*. "Copy templates", "copy hooks", "create directories", "install skills" is ONE stage: "Set up project structure and contents". Merge until you cannot merge further without hiding a fork the reader cares about.
3. Apply the hard budget:
   - 5–9 process stages
   - ≤12 nodes total (including start/end/error exits)
   - ≤3 decision diamonds
   If the process seems to need more, the altitude is wrong — merge harder, or make an overview chart and offer per-stage drill-down charts.
4. Show the planned stage list in your response before rendering.

**Decomposition example.** Source: a 200-line install script with 14 distinct operations.
- Wrong: 14 process boxes mirroring the script.
- Right: `Check prerequisites → Scaffold project files → Configure version control → Set up Python environment → Show next steps`, with only the 1–2 decisions a *user* experiences.

## Label rules (hard constraints)

- Process node = imperative verb phrase, ≤6 words, describing outcome, not mechanism.
- Decision node = plain-English question (≤ ~25 chars) a non-programmer could answer.
- **Banned in labels:** variable names, env vars, CLI flags, file paths, function names, exit codes, version strings, template placeholders, shell syntax, code of any kind. All of it goes in the tooltip or detail panel.
- One short line per node. Needing a second line or smaller font means detail is leaking — move it out.

| Bad | Good |
|---|---|
| `Record HARNESS_SHA & KDENSE_SYMPY_SHA` | `Pin tool versions for reproducibility` |
| `SKIP_VENV=1?` | (no diamond — config toggle; note in detail panel) |
| `Copy templates, substitute {{PAPER_SLUG}}` | `Generate project files from templates` |
| `ERROR: templates missing / exit 1` | `Stop: setup cannot continue` |

## When a decision gets a diamond

Diamonds are expensive reader attention. Use one only if BOTH hold: (a) the reader could realistically be on either branch, and (b) the branches lead to visibly different stages on the chart.

Fold into the affected stage (mention in its detail entry): config toggles and skip flags, internal fallbacks ("uv, else python3"), check-warn-continue conditions, idempotency checks ("keep if exists").

The happy path runs in ONE straight visual line. Error exits are compact terminal nodes off to the side; failures with the same outcome share one "Stop" node, causes listed in the detail panel.

## Step 3 — Detail hierarchy (never in labels)

- **Node label**: one plain-language phrase.
- **Hover tooltip**: 1–2 sentence explanation.
- **Click → detail panel**: file names, commands, env vars, flags, edge cases, keyed by stage.
- **Page subtitle**: scope, version, source file described.

Detail is optional; the skeleton is not. When in doubt, leave detail out.

## Step 4 — Render with Mermaid

Use Mermaid.js (auto-layout, auto-sizing — text can never clip) in a self-contained HTML file. Template:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>[Process] Flowchart</title>
<style>
  :root { --bg:#f6f8fb; --card:#fff; --border:#e3e8f0; --text:#1a2233; --muted:#5b6577; }
  body { font-family: system-ui, sans-serif; background: var(--bg); color: var(--text);
         margin: 0; padding: 32px; }
  header h1 { font-size: 22px; margin: 0 0 4px; }
  header p  { color: var(--muted); margin: 0 0 20px; font-size: 14px; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 12px;
          padding: 20px; box-shadow: 0 1px 3px rgb(16 24 40 / .06); }
  .layout { display: flex; gap: 20px; align-items: flex-start; flex-wrap: wrap; }
  .chart { flex: 1 1 560px; }
  #detail { flex: 0 1 320px; position: sticky; top: 24px; }
  #detail h2 { font-size: 15px; margin: 0 0 8px; }
  #detail p, #detail li { font-size: 13px; color: var(--muted); line-height: 1.5; }
  #detail[hidden] { display: none; }
  .mermaid .node { cursor: pointer; }
  .mermaidTooltip { background: #1a2233 !important; color: #fff !important;
                    border-radius: 6px !important; font-size: 12px !important;
                    padding: 6px 10px !important; max-width: 280px; }
</style>
</head>
<body>
<header>
  <h1>[Process Name]</h1>
  <p>[One-sentence purpose statement] — click a node for details, hover for a summary.</p>
</header>
<div class="layout">
  <div class="card chart">
<pre class="mermaid">
flowchart TD
  S(["Start"]):::startEnd --> D1{"Prerequisites met?"}:::decision
  D1 -- "No" --> E1(["Stop: setup cannot continue"]):::stop
  D1 -- "Yes" --> P1["First stage"]:::process
  P1 --> P2["Second stage"]:::process
  P2 --> Z(["Done"]):::startEnd

  classDef startEnd fill:#2f855a,stroke:#276749,color:#fff
  classDef stop     fill:#c53030,stroke:#9b2c2c,color:#fff
  classDef process  fill:#3182ce,stroke:#2b6cb0,color:#fff
  classDef decision fill:#dd8a12,stroke:#b7791f,color:#fff

  click P1 call nodeDetail() "1-2 sentence tooltip"
  click P2 call nodeDetail() "1-2 sentence tooltip"
</pre>
  </div>
  <aside id="detail" class="card" hidden>
    <h2 id="detail-title"></h2>
    <div id="detail-body"></div>
  </aside>
</div>

<script type="module">
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs";

const DETAILS = {
  P1: { title: "First stage", body: "<ul><li>implementation specifics live here</li></ul>" },
  P2: { title: "Second stage", body: "<p>…</p>" },
};

window.nodeDetail = (id) => {
  const d = DETAILS[id];
  if (!d) return;
  document.getElementById("detail").hidden = false;
  document.getElementById("detail-title").textContent = d.title;
  document.getElementById("detail-body").innerHTML = d.body;
};

mermaid.initialize({
  startOnLoad: false,
  securityLevel: "loose",          // required for click callbacks
  theme: "base",
  themeVariables: { fontFamily: "system-ui, sans-serif", fontSize: "14px",
                    lineColor: "#94a3b8", edgeLabelBackground: "#f6f8fb" },
  flowchart: { curve: "basis", padding: 12, nodeSpacing: 40, rankSpacing: 50 },
});
await mermaid.run();
</script>
</body>
</html>
```

Color semantics: green = start / successful end, red = error stop, blue = process stage, orange = decision.

**Mermaid pitfalls:**
- Pin the CDN version (`mermaid@11.4.1`) — never `@latest`.
- ALWAYS quote labels: `id["..."]` / `id{"..."}`. Unquoted `( ) { } ; : # < >` are parse errors. Use `<br/>` for forced breaks; write "and" instead of `&`.
- `end` is a reserved word; keep node ids short alphanumerics (`P1`, `D2`); avoid ids starting `o`/`x` before a dash.
- `securityLevel: "loose"` is mandatory or click callbacks silently do nothing.
- CDN means online-only rendering; if the user needs offline, vendor the `.mjs` file next to the HTML.
- Never hand-place coordinates. `TD` for tall flows, `LR` for wide processes; tune only `nodeSpacing`/`rankSpacing`.

## Step 5 — Self-review gate (before writing the file)

- Read every label as someone who has never seen the source — rewrite any that fails.
- No identifier, env var, flag, path, placeholder, or code in any label?
- Within budget (≤9 stages, ≤12 nodes, ≤3 diamonds)? Every diamond passes the diamond test? Branches labeled?
- Happy path one straight line? Same-outcome errors share one stop node?
- Every merged stage has a detail-panel entry carrying what it hides?
- All mermaid labels quoted, ids safe?
- Could a reader summarize the process from labels alone in ~15 seconds?

## Output

1. Write to `<kebab-slug>-flowchart.html` in the cwd (or where the user asked).
2. Open it in the browser (`open` on macOS) unless running non-interactively.
3. Report: file path, chosen audience/altitude, node count — and offer a drill-down chart of any stage (this is the safety valve that makes the aggressive node budget acceptable: detail is deferred, not lost).
