---
name: flowchart
description: Create HTML flowcharts and process diagrams with hover tooltips and click-to-expand details. Use when users ask for a flowchart, process diagram, workflow visualization, decision tree, or a visual of how a script/system/process works. Output is at purpose-level, not a code transcription. An explicit "deep" request adds linked per-stage drill-down charts.
allowed-tools: Bash, Read, Write, Edit
metadata:
  version: "0.10.3"
---

# Flow Chart

Turn a process into a diagram someone who has never seen the source can read in ~30 seconds. Implementation specifics live in tooltips and the detail panel, never in node labels.

## 1. Scope

Chart exactly what the user named: a component → that component's process; a whole repo/system → its primary user-facing process. Ambiguous target (multiple matches, or system-vs-part unclear)? Don't guess — reply with the concrete options and let the user pick before charting. Always emit `flowchart` (never stateDiagram/sequenceDiagram etc.); model states as nodes and transitions as labeled edges.

## 2. Plan

1. One-sentence purpose statement (becomes the page subtitle): who reads this, what question it answers.
2. List atomic steps, then merge consecutive steps serving one purpose into a stage named by its outcome ("copy templates / copy hooks / create dirs" → "Set up project structure"). State the stage list in your response, then proceed — don't wait for approval. (An explicit "deep" request → state the full chart tree per §7 instead.)
3. **Hard budget: ≤9 stages (never pad a short process), ≤12 nodes total (start/end/stops/diamonds included), ≤3 diamonds.** Over budget = wrong altitude: merge harder, or apply the **drill-down convention** (chart the stage separately under the same budget). Chart count is known when the plan is stated, so flat file vs set directory is decided before anything is written:
   - **Sets & filenames.** More than one chart makes a **set**, living in its own directory `<kebab-slug>-flowchart/`: the root chart is `index.html`, children are `<stage-slug>.html`, and deeper children extend their parent's filename (`validate-sentence.html` → `validate-sentence-coverage-check.html`) — so child filenames are fixed before writing.
   - **Drill-down visible without clicking (parent side):** suffix the parent node label with ⤵, add its legend chip, and make the link the FIRST line of the stage's detail entry ("→ Open this stage's own chart") — buried-last links fail the 30-second test.
   - **Up-link (child side):** the child's start node is the way back up — prefix its label ↰, link it to the parent, and give it the FIRST `DETAILS` entry naming the parent.
   - Exact click binding, chip markup, and child-chart slot patterns live in the template header.

## 3. Labels

- Process: imperative verb phrase, ≤6 words, outcome not mechanism.
- Decision: plain question, ideally 1–2 words ("Approved?", "Checks pass?") — edge labels carry the answers.
- **Banned:** variable/function names, env vars, flags, file paths, exit codes, placeholders, code — all of it goes to the tooltip or detail panel. `Record HARNESS_SHA` → `Pin tool versions for reproducibility`; `SKIP_VENV=1?` → no node at all (config toggle → detail panel).

## 4. Diamonds, error paths, and loops

- Diamond only if the reader could realistically be on either branch AND the branches visibly diverge on the chart. Config toggles, internal fallbacks ("uv, else python3"), and keep-if-exists checks fold into the stage's detail entry. Label every branch edge.
- Happy path: one straight line. Same-outcome failures share one "Stop: …" node. Failure causes live in the detail entry of the decision that routes there; stop nodes get no click binding.
- Loops: draw a labeled back-edge when the reader steers the iteration or the cycle is the process's normal operation (refine → check → refine). Automatic bounded retries are not loops — fold them into the stage's detail entry, suffix the stage label ↻, add its legend chip, and put the retry mechanism first in that entry. "Stop" is legal only when resolution happens outside the charted process; a stop whose remedy is "re-run" is a disguised loop — draw the back-edge, named for its trigger ("Issues found").
- Exception — the user asked for a *decision tree*: the chart IS the decisions. Drop the diamond cap, keep ≤12 nodes total, nest ≤3 levels deep.

## 5. Render

`cp` `template.html` from this skill's directory to the target file, then Edit only the slots listed in its header comment, following the syntax rules there — never retype or regenerate the file from memory; everything outside the slots stays byte-identical.

- Node classes: `start`, `process` (rounded: `P1("...")`), `decision`, `success`, `stop`. Bind a 1–2 sentence tooltip + a `DETAILS` entry to every process, decision, and success node — not start/stop (sole exception: the §2.3 up-link start node). Detail entries carry whatever their stage merged away.
- Edge vocabulary: solid gray = forward, dashed red = error exit, dashed amber = loop back. Index, mark, and style edges per the header's edge-map rules (slots 5–6); add the matching legend chip for every glyph or edge style used.
- If the user supplies brand colors, keep the pattern: tinted fill + saturated stroke + dark same-hue text (≥7:1 contrast), and Stop keeps its dashed border — never encode state by hue alone. Otherwise don't restyle.
- Keep the pinned mermaid version and `securityLevel: "loose"` exactly as in the template — clicks fail silently without it, and the keyboard handler depends on 11.x DOM-id internals. Offline rendering: the header's CDN note.
- Always `flowchart TD` (vertical scrolls; horizontal shrinks — the SVG scales to fit the card width, so LR charts render with tiny text). Use `LR` only if the user explicitly asks for horizontal. Never hand-place coordinates.

## 6. Check, then ship

1. Every label readable without the source; nothing banned in labels; within budget; diamonds pass the branch test; branches labeled.
2. Click lines and `DETAILS` keys are the same case-sensitive set, every key is a declared node id, and every process/decision/success node appears in it.
3. `grep -n '\[Process Name\]\|\[project-name\]\|\[One-sentence\|1-2 sentence tooltip' <file>` — any hit is an unfilled slot (tab title and screen-reader text don't show in the browser).
4. `linkStyle` indices re-derived from the edge index map (format rules: slot 6 of the file's own header), or the red line deleted.

A single chart ships flat as `<kebab-slug>-flowchart.html` in the cwd (or the path the user gave); a multi-chart set ships as its §2.3 directory in the same place. Open the root — the flat file, or the set's `index.html` (`open` on macOS, `xdg-open` on Linux — if that fails, skip it and just report). Report: absolute path, chosen altitude, node count, and an offer to drill into any stage.

## 7. Deep mode (explicit "deep" request only)

Root chart per §1–6, plus a drill-down (§2.3 convention) for every stage passing the chartability test, recursing into sub-charts. Hard caps: **2 levels below root, ≤12 chart files per run** — deeper or wider, the user re-runs deep on a sub-chart (it becomes the new root). §2.3 over-budget drill-downs join the tree and count toward both caps — state the one-line tree amendment, with filename, before writing it. At a cap, §2.3's fix is merge-only (fold the excess into detail entries) and the stage is named a re-root candidate.

- **Chartability test:** ≥4 post-fold steps (after §3 bans and §4 folds) where swapping two adjacent steps breaks the process. Inventories and menus ("available at any time") never qualify; decisions never qualify a stage — a genuine §4 diamond earns its place inside a chart that qualified on steps, otherwise it stays in the detail entry.
- Before writing anything, state the **binding tree**: every stage verdicted (✓ sub-chart: N ordered steps / ✗ detail panel: unordered / ✗ capped — re-run deep here) with every output filename. Hrefs and `cp` targets are copied from this list, never re-derived; if two names anywhere in the tree collide (compare all levels), rename a stage label — never numeric suffixes. A deep set is atomic in its §2.3 set directory; never split it.
- Generate root-first. Sub-charts use the template header's child-chart slot patterns (kicker breadcrumb, linked subtitle, child title). Re-rooting an existing sub-chart: read its kicker href BEFORE `cp` clobbers it, write it back unchanged; the new children join the existing set directory, extending the re-rooted chart's filename.
- Every chart passes §6's checks 1–4 individually; then cross-file: grep all hrefs across every `*.html` in the set's directory — match single AND double quotes (`href=["'']…`); DETAILS bodies force single-quoted hrefs, which a double-quote-only grep silently misses — and `test -f` each target. Report `*.html` files in the set's directory absent from the tree as possible orphans; never delete, and say so before overwriting an existing chart.
- Interrupted run? Regenerate only files missing from the binding tree — a file that exists but fails §6.3's grep counts as missing; never re-plan on resume.
- Open the root only. Report (replaces §6's): the tree with absolute paths and re-root candidates. Zero qualifying stages → ship the root alone and say so.
