---
name: add-variant
description: Create a thin sibling manuscript variant (paper/main_<name>.tex) sharing paper/sections/, and register it in paper_config.yaml.
allowed-tools: Read Write Bash
metadata:
  version: "0.1.0"
---

# /add-variant <name> [--from <base>] [--journal <J>]

Create a new manuscript variant as a thin sibling wrapper alongside the base manuscript. All variants share `paper/sections/`; the wrapper file is the manifest of which sections to include.

**Arguments:**
- `<name>` — required. The variant name (alphanumeric + hyphens/underscores; e.g. `empirical`, `theory-only`, `jpe`). Must be unique.
- `[--from <base>]` — optional. The variant or file to copy the `\input` assembly from. Default: `base` (resolves via `manuscripts.variants.base.file`, else `paths.manuscript`).
- `[--journal <J>]` — optional. The target journal abbreviation to record in the registry (e.g. `AER`, `JPE`). Default: `~` (null).

**Examples:**
- `/add-variant empirical` — add variant named `empirical`, based on `base`
- `/add-variant jpe --from base --journal JPE` — add a JPE-tailored variant
- `/add-variant theory-only --from empirical` — branch from another variant

---

## Step 1 — Preconditions

Read `paper_config.yaml`. Check in order:

1. **Inside a paper repo.** If `paper_config.yaml` does not exist, refuse:
   > "/add-variant must run inside a paper repository (no paper_config.yaml found)."

2. **Valid name.** If `<name>` is empty, contains spaces, or matches the reserved word `base`, refuse:
   > "Variant name '<name>' is invalid. Use alphanumeric characters, hyphens, or underscores. 'base' is reserved."

3. **No file collision.** If `paper/main_<name>.tex` already exists, refuse:
   > "paper/main_<name>.tex already exists. Choose a different variant name or remove the existing file."

4. **No registry collision.** If `manuscripts.variants.<name>` already exists in `paper_config.yaml`, refuse:
   > "Variant '<name>' is already registered in paper_config.yaml. Choose a different name."

---

## Step 2 — Resolve the base wrapper

Determine the source wrapper file to copy from:

1. If `--from <base_name>` was given:
   - If `<base_name>` is a key in `manuscripts.variants`, use `manuscripts.variants[base_name].file`.
   - Else if `<base_name>` is a file path that exists, use it directly.
   - Else refuse: "Cannot resolve --from '<base_name>': not a known variant and not a file path."
2. Else (default):
   - If `manuscripts.variants.base` exists in `paper_config.yaml`, use `manuscripts.variants.base.file`.
   - Else use `paths.manuscript` (default `paper/main.tex`).

Read the resolved base wrapper file in full.

---

## Step 3 — Modularity check

Inspect the base wrapper for `\input{sections/` lines.

**If no `\input{sections/` is found** (the base is monolithic — all content in one file):
> "WARNING: The base manuscript '<file>' is monolithic — it contains no `\input{sections/…}` lines. Creating a variant would duplicate all content into paper/main_<name>.tex, causing drift as both files diverge independently. Run `/split-sections` first to decompose the manuscript into paper/sections/ before adding variants."

Ask the user: "Do you want to proceed anyway, accepting that this variant will duplicate content and may drift? Type `yes proceed` to continue, or anything else to abort."

If the user does not type `yes proceed` exactly, abort:
> "/add-variant aborted. Run /split-sections first, then /add-variant again."

---

## Step 4 — Create the thin wrapper

Create `paper/main_<name>.tex` with the following structure:

**Header comment** (first line, always):
```
% Variant: <name> — "<name>"  Base: <resolved base file>  Target journal: <J or ~>
```

Then copy **only** the `\input{…}` lines from the base wrapper — the preamble `\input{sections/_preamble}` (if present) and all `\input{sections/…}` section lines. Do **not** copy any prose, environments, or content. Do not copy `\begin{document}` or `\end{document}` — re-emit them from the wrapper template below.

The created file must have this structure:
```latex
% Variant: <name> — "<name>"  Base: <base file>  Target journal: <J or ~>
\input{sections/_preamble}
\begin{document}
\input{sections/00_front}
\input{sections/01_…}
…
\end{document}
```

If the base is modular (has `\input{sections/`), this is exact: copy only the `\input` lines in order, wrapped in `\begin{document}` … `\end{document}`. The variant starts as an identical assembly to the base — diverge it later by editing its `\input` list.

**CRITICAL: Never copy section file content, prose, equations, or anything other than `\input{…}` lines and the document environment delimiters.**

---

## Step 5 — Register in paper_config.yaml

Append the new variant to `manuscripts.variants` in `paper_config.yaml`.

**If `manuscripts:` block is absent:** create it (with the inferred `base` entry first) before appending:
```yaml
manuscripts:
  variants:
    base: { file: "paper/main.tex", journal: ~ }
    <name>: { file: "paper/main_<name>.tex", journal: <J or ~> }
```

**If `manuscripts:` block exists:** append under `manuscripts.variants`:
```yaml
    <name>: { file: "paper/main_<name>.tex", journal: <J or ~> }
```

Use `~` for null journal (not `null`, not empty string).

---

## Step 6 — Report

Print a summary:

```
/add-variant complete
─────────────────────────────────────────────────────────
  Created:   paper/main_<name>.tex
             (thin wrapper: header + copied \input list; no content duplication)
  Registry:  paper_config.yaml → manuscripts.variants.<name>
             { file: "paper/main_<name>.tex", journal: <J or ~> }
  Based on:  <resolved base file>
  Modular:   <yes — \input{sections/…} lines copied | no — content duplicated (warned)>

Next steps:
  - Diverge this variant by editing its \input list in paper/main_<name>.tex
    (add, remove, or reorder \input{sections/…} lines; or add a new journal-tailored
    section file in paper/sections/ and \input it only in this variant).
  - --variant <name> now works on /refine-light, /refine-heavy, /signoff,
    /export-coauthor, and /match-journal.
  - See the delta between variants with:
      .claude/scripts/diff_variants.sh paper/main.tex paper/main_<name>.tex
```
