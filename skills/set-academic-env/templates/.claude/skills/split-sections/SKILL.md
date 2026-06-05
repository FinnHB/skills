---
name: split-sections
description: Decompose a monolithic paper/main.tex into paper/sections/_preamble.tex + 00_front.tex + NN_<slug>.tex + a thin wrapper. Back up to main.tex.presplit first; verify flatten_tex.py round-trips the body; abort+restore on mismatch; refuse if already modular.
allowed-tools: Read Write Bash
metadata:
  version: "0.1.0"
---

# split-sections

Migration skill: convert a monolithic `paper/main.tex` into the modular section-library layout. Safe and idempotent: backs up the original before touching anything; verifies content integrity via `flatten_tex.py` round-trip; aborts and restores on any mismatch.

## Purpose

Turn this:
```
paper/main.tex   (monolithic — preamble + body + sections all in one file)
```

Into this:
```
paper/sections/_preamble.tex    (everything before \begin{document})
paper/sections/00_front.tex     (front-matter: title, abstract, before first \section)
paper/sections/01_introduction.tex
paper/sections/02_model.tex
…
paper/main.tex                  (thin wrapper: \input each section file)
paper/main.tex.presplit         (backup of the original)
```

## Preconditions (check before starting)

1. Resolve `paths.manuscript` from `paper_config.yaml` (default `paper/main.tex`). Verify the file exists; abort with a clear message if not.
2. **Already modular** — if `paper/main.tex` contains any `\input{sections/` command, refuse:
   ```
   /split-sections: paper/main.tex already appears to be modular (\input{sections/…} found).
   Run this skill only on a monolithic paper/main.tex. Aborting.
   ```
3. **No \section{} to split on** — if the body contains no top-level `\section{` command, refuse:
   ```
   /split-sections: no \section{} found in paper/main.tex body. Nothing to split. Aborting.
   ```

## Step 1 — Back up the original

Copy `paper/main.tex` to `paper/main.tex.presplit` before making any changes. This file is the ground truth for abort/restore.

```bash
cp paper/main.tex paper/main.tex.presplit
```

Note in the conversation: "Backed up original to paper/main.tex.presplit."

## Step 2 — Parse the monolithic file

Read `paper/main.tex` in full. Split into three logical parts:

**Part A — Preamble**: everything from the start of the file up to (but not including) `\begin{document}`.

**Part B — Front-matter**: everything from `\begin{document}` (exclusive — do not include the `\begin{document}` line itself) up to (but not including) the first `\section{` or `\section*{` command. Typically contains: `\maketitle`, abstract environment, keywords, JEL codes.

**Part C — Body sections**: everything from the first `\section{` command to the line before `\end{document}`. This includes all `\section{}`, `\subsection{}`, `\subsubsection{}` and their content, as well as `\bibliography{}` / `\printbibliography` if they appear before `\end{document}`.

The `\begin{document}` line goes into the thin wrapper (not into any section file).
The `\end{document}` line goes into the thin wrapper.

**Bibliography handling**: if `\bibliography{…}` or `\printbibliography` appears in Part C (after the last section body), include it in the last section file. The thin wrapper does **not** duplicate it.

## Step 3 — Split Part C into per-section files

Split Part C at each top-level `\section{…}` (or `\section*{…}`) boundary. Each split yields one file.

**Slug generation** from section title:
1. Take the title string (text inside `\section{…}`).
2. Lowercase. Strip LaTeX commands (e.g., `\texorpdfstring{…}{…}` → use the second arg; strip other macros).
3. Replace non-alphanumeric characters with underscores. Collapse consecutive underscores. Strip leading/trailing underscores.
4. Truncate to 40 characters.
5. If the slug is empty, fall back to `sec_NN`.

**File numbering**: 00 = front-matter; 01 = first section; 02 = second; etc.

Each section file contains the `\section{…}` line and all content up to (but not including) the next `\section{` boundary.

## Step 4 — Write section files

Create `paper/sections/` if it does not exist.

Write the following files (all new; abort with restore if any already exists — do not overwrite existing section files):

| File | Content |
|------|---------|
| `paper/sections/_preamble.tex` | Part A (preamble, no `\begin{document}`) |
| `paper/sections/00_front.tex` | Part B (front-matter, no `\begin{document}`) |
| `paper/sections/01_<slug>.tex` | First section content |
| `paper/sections/02_<slug>.tex` | Second section content |
| … | … |

## Step 5 — Rewrite paper/main.tex as a thin wrapper

Overwrite `paper/main.tex` with:

```latex
% Variant: base
\input{sections/_preamble}
\begin{document}
\input{sections/00_front}
\input{sections/01_<slug>}
\input{sections/02_<slug>}
…
\end{document}
```

No `\bibliography{}` line in the wrapper if it was included in the last section file.

## Step 6 — Verify round-trip (CRITICAL — abort on mismatch)

Run:
```bash
python3 .claude/scripts/flatten_tex.py paper/main.tex
```

Capture the output. Compare the **body** of the flattened output (everything between `\begin{document}` and `\end{document}`, exclusive) against the original body (Part B + Part C extracted in Step 2).

Normalize both sides before comparing:
- Strip leading/trailing whitespace from the full body string.
- The comparison must pass with no diff.

If the flattened body does NOT match the original body:
1. Restore from backup: `cp paper/main.tex.presplit paper/main.tex`
2. Remove any newly created `paper/sections/` files.
3. Report:
   ```
   /split-sections: round-trip check FAILED — content mismatch detected.
   Original restored from paper/main.tex.presplit.
   No changes were made.
   Diff (first 20 lines): <show diff>
   ```
4. Abort.

If the round-trip passes, report success.

## Step 7 — Report success

Print a summary:
```
/split-sections: done.
  Backup:   paper/main.tex.presplit
  Preamble: paper/sections/_preamble.tex
  Front:    paper/sections/00_front.tex
  Sections: paper/sections/01_… … paper/sections/NN_…
  Wrapper:  paper/main.tex (thin wrapper)
  Round-trip: PASS — flatten_tex.py reproduces original body exactly.

Next steps:
  - Edit individual section files in paper/sections/ for focused revisions.
  - paper/main.tex is now a thin wrapper — Tectonic builds it natively.
  - Gates (integrity-gate, lane1-*) analyze the flattened content automatically.
  - Run /refine-light or /refine-heavy as usual.
```

## Error handling summary

| Situation | Action |
|-----------|--------|
| Already modular (`\input{sections/` found) | Refuse — print message, abort, no changes |
| No `\section{}` found | Refuse — print message, abort, no changes |
| `paper/main.tex` missing | Refuse — print message, abort |
| `paper/sections/*.tex` already exists | Abort, restore from backup |
| Round-trip mismatch | Restore from backup, remove new files, abort |
| `flatten_tex.py` missing | Abort — cannot verify round-trip |

## Notes

- The `\begin{document}` line is in the wrapper only — never in a section file.
- The `\end{document}` line is in the wrapper only.
- `_preamble.tex` contains NO `\begin{document}` line — it is `\input`-ed before `\begin{document}`.
- Section files contain only their `\section{…}` and body — no document environment tags.
- `paper/main.tex.presplit` is the authoritative backup. If something goes wrong later, the user can restore it manually.
- This skill does NOT create `paper/sections/sections/` — the wrapper uses `\input{sections/…}` because `paper/` is the compilation root.
- Per Non-goals: this skill does NOT create variant files, a registry, or any 16-2 artifacts.
