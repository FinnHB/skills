---
name: flow-chart
description: Create audience-appropriate HTML flowcharts and process diagrams with hover tooltips and click-to-expand details. Use when users ask for a flowchart, process diagram, workflow visualization, decision tree, or a visual of how a script/system/process works. Produces purpose-level diagrams a newcomer can read in 30 seconds — not code transcriptions. An explicit "deep" request additionally produces linked per-stage drill-down charts.
allowed-tools: Bash, Read, Write, Edit
metadata:
  version: "0.8.1"
---

# Flow Chart

Turn a process into a diagram someone who has never seen the source can read in ~30 seconds. Implementation specifics live in tooltips and the detail panel, never in node labels.

## 1. Scope

Chart exactly what the user named: a component → that component's process; a whole repo/system → its primary user-facing process. Ambiguous target (multiple matches, or system-vs-part unclear)? Don't guess — reply with the concrete options and let the user pick before charting. Always emit `flowchart` (never stateDiagram/sequenceDiagram etc.); model states as nodes and transitions as labeled edges.

## 2. Plan

1. One-sentence purpose statement (becomes the page subtitle): who reads this, what question it answers.
2. List atomic steps, then merge consecutive steps serving one purpose into a stage named by its outcome ("copy templates / copy hooks / create dirs" → "Set up project structure"). State the stage list in your response, then proceed — don't wait for approval. (An explicit "deep" request → state the full chart tree per §7 instead.)
3. Hard budget: **≤9 stages (typically 5–9; never pad a short process), ≤12 nodes total (start/end/stops/diamonds included), ≤3 diamonds.** Over budget = wrong altitude: merge harder, or apply the **drill-down convention** — chart the stage separately as `<parent file minus -flowchart.html>-<stage-slug>-flowchart.html` (same budget; nesting prepends the same way, so child filenames are fixed before writing). The drill-down must be visible without clicking: suffix the parent node label with ⤵, add a legend chip ("⤵ stage has its own chart"), and make the link the FIRST line of the stage's detail entry ("→ Open this stage's own chart") — buried-last links fail the 30-second test. The child's start node is the way back up: prefix its label ↰ and bind `click S href "<parent-file>" "Go up one level: <parent name>" _self` — the explicit `_self` matters (mermaid's default target is _blank) — plus a DETAILS entry for S naming the parent, placed FIRST in the map (href-linked nodes get the clickable class, so the integrity check demands the entry; first position means direct landers see the orientation on load).

## 3. Labels

- Process: imperative verb phrase, ≤6 words, outcome not mechanism.
- Decision: plain question, ideally 1–2 words ("Approved?", "Checks pass?") — edge labels carry the answers, and short diamonds render smaller.
- **Banned:** variable/function names, env vars, flags, file paths, exit codes, placeholders, code — all of it goes to the tooltip or detail panel. `Record HARNESS_SHA` → `Pin tool versions for reproducibility`; `SKIP_VENV=1?` → no node at all (config toggle → detail panel).

## 4. Diamonds, error paths, and loops

- Diamond only if the reader could realistically be on either branch AND the branches visibly diverge on the chart. Config toggles, internal fallbacks ("uv, else python3"), and keep-if-exists checks fold into the stage's detail entry. Label every branch edge.
- Happy path: one straight line. Same-outcome failures share one "Stop: …" node. Failure causes live in the detail entry of the decision that routes there; stop nodes get no click binding.
- Loops: draw a labeled back-edge when the reader steers the iteration or the cycle is the process's normal operation (refine → check → refine). Automatic bounded retries are not loops — fold them into the stage's detail entry, suffix the stage label ↻, add the legend chip ("↻ improves its output internally"), and put the retry mechanism first in its detail entry. "Stop" is legal only when resolution happens outside the charted process; a stop whose remedy is "re-run" is a disguised loop — draw the back-edge, named for its trigger ("Issues found").
- Exception — the user asked for a *decision tree*: the chart IS the decisions. Drop the diamond cap, keep ≤12 nodes total, nest ≤3 levels deep.

## 5. Render

`cp` `template.html` from this skill's directory to the target file, then Edit only the slots listed in its header comment — never retype or regenerate the file from memory; everything outside the slots stays byte-identical.

- Node classes: `start` (outlined), `process` (indigo, rounded: `P1("...")`), `decision` (amber), `success` (green), `stop` (red, dashed). Bind a 1–2 sentence tooltip + a `DETAILS` entry to every process, decision, and success node — not start/stop (one exception: a drill-down chart's start node carries the §2.3 up-link and its DETAILS entry). Detail entries carry whatever their stage merged away.
- After the edges, write the `%% edge index map:` comment (own line — trailing comments are a parse error) enumerating every edge 0-based in declaration order, marking error edges `(error)` and loop back-edges `(loop)`; subgraph-internal edges count. Derive `linkStyle` indices from that map — they index ALL edges, not just error ones. No error edges → delete the red `linkStyle` line entirely (an out-of-range index aborts the whole render). Loop edges get their own line, dashed amber: `linkStyle <i> stroke:#e8930c,stroke-width:1.5px,stroke-dasharray:4 3` — the edge vocabulary is solid gray = forward, dashed red = error exit, dashed amber = loop back (add its legend chip when used).
- If the user supplies brand colors, keep the pattern: tinted fill + saturated stroke + dark same-hue text (≥7:1 contrast), and Stop keeps its dashed border — never encode state by hue alone. Otherwise don't restyle.

Mermaid pitfalls:
- Keep the pinned mermaid version and `securityLevel: "loose"` exactly as in the template — clicks fail silently without it, and the keyboard handler depends on 11.x DOM-id internals. CDN = online-only rendering; for offline, vendor `dist/mermaid.min.js` (UMD, single file) and swap to a classic script — the ESM build lazy-loads chunks and cannot be vendored as one file.
- Quote every node AND edge label: `P1("...")`, `-- "Yes" -->`. No double quotes inside any quoted string (labels, edge labels, click tooltips) — rephrase or use `#quot;`. Write "and" not `&`, `&lt;` for a literal `<`. Edge operators are ASCII (`-->`), never unicode arrows.
- Ids match `[A-Z][A-Za-z0-9]*` (`P1`, `D2`) — no hyphens or underscores (the keyboard handler parses DOM ids); `end` is reserved.
- `DETAILS` bodies are JS template literals: never put backticks or `${` inside them — use `<code>` tags and HTML entities.
- Swimlanes: `subgraph SG1["Lane name"] ... end` (quoted title); node ids stay global; lane-internal edges still count toward linkStyle indices.
- Always `flowchart TD` (vertical scrolls; horizontal shrinks — the SVG scales to fit the card width, so LR charts render with tiny text). Use `LR` only if the user explicitly asks for horizontal. Never hand-place coordinates.

## 6. Check, then ship

1. Every label readable without the source; nothing banned in labels; within budget; diamonds pass the branch test; branches labeled.
2. Click lines, `DETAILS` keys, and node ids are the same case-sensitive set (the template logs console errors on mismatch).
3. `grep -n '\[Process Name\]\|\[project-name\]\|\[One-sentence' <file>` — any hit is an unfilled slot (tab title and screen-reader text don't show in the browser).
4. `linkStyle` indices re-derived from the edge index map, or the red line deleted.

Write `<kebab-slug>-flowchart.html` to the cwd (or the path the user gave); open it (`open` on macOS, `xdg-open` on Linux — if that fails, skip it and just report). Report: absolute path, chosen altitude, node count, and an offer to drill into any stage — detail is deferred, not lost.

## 7. Deep mode (explicit "deep" request only)

Root chart per §1–6, plus a drill-down (§2.3 convention) for every stage passing the chartability test, recursing into sub-charts. Hard caps: **2 levels below root, ≤12 chart files per run** — deeper or wider, the user re-runs deep on a sub-chart (it becomes the new root). §2.3 over-budget drill-downs join the tree and count toward both caps; at a cap, §2.3's fix is merge-only and the stage is named a re-root candidate.

- **Chartability test:** ≥4 post-fold steps (after §3 bans and §4 folds) where swapping two adjacent steps breaks the process. Inventories and menus ("available at any time") never qualify; decisions never qualify a stage — a genuine §4 diamond earns its place inside a chart that qualified on steps, otherwise it stays in the detail entry.
- Before writing anything, state the **binding tree**: every stage verdicted (✓ sub-chart: 6 ordered steps / ✗ detail panel: unordered / ✗ capped — re-run deep here) with every output filename. Hrefs and `cp` targets are copied from this list, never re-derived; if two names collide, rename a stage label — never numeric suffixes. A deep set is atomic in one directory; never split it.
- Generate root-first. Sub-chart kicker slot: `<span class="name"><a href="<parent-file>" style="color:var(--accent)">parent process</a> › stage</span>`; subtitle opens "Drill-down into one stage of <parent>: …" with the parent name linked; title slot = `Stage · Parent · Process map` (h1 stays the stage name alone). Re-rooting an existing sub-chart: read its kicker href first, write it back unchanged.
- Every chart passes §6 individually; then cross-file: grep all hrefs across `<slug>*-flowchart.html` — match single AND double quotes (`href=["'']…`); DETAILS bodies force single-quoted hrefs, which a double-quote-only grep silently misses — and `test -f` each target — also the recovery command after an interrupted run (regenerate only missing files from the tree statement; never re-plan on resume). Report on-pattern files absent from the tree as orphans; never delete, and say so before overwriting an existing chart.
- Open the root only. Report (replaces §6's): the tree with absolute paths and re-root candidates. Zero qualifying stages → ship the root alone and say so.
