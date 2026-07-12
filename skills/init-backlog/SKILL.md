---
name: init-backlog
description: Backlog system for a repo — BACKLOG.md + BACKLOG_DONE.md plus a Definition-of-Done maintenance rule in CLAUDE.md. Use when a project has no real backlog (no issue tracker, scattered TODOs/planning docs) and the user wants durable, commit-traceable tracking that Claude keeps in sync. Idempotent.
allowed-tools: Bash, Read, Write, Edit
metadata:
  version: "1.0.1"
---

# init-backlog

Scaffold a two-file, commit-traceable backlog into the current repository and wire
its maintenance into `CLAUDE.md` as a Definition of Done. Designed for solo, often
remote-less repos where GitHub Issues are overkill but scattered TODOs and one-off
planning docs rot.

## What it installs

1. **`BACKLOG.md`** (repo root) — open work only. Stable IDs (`BL-NN`, never reused),
   a `(Value × Frequency × Confidence) ÷ Effort` score per item, theme sections sorted
   highest-score first.
2. **`BACKLOG_DONE.md`** (repo root) — terminal states: shipped + dropped. A decision
   ledger keyed by `BL-NN`, mapped to commits via `git log --grep=BL-NN`. 3-line ceiling
   per entry; no diffs/file-lists/test-counts (that's git's job).
3. **A "Backlog maintenance (Definition of Done)" section** appended to `CLAUDE.md`
   (created if absent) — the rules that make Claude keep the two files in sync.

The model: **git** = what changed & when; **`BACKLOG.md`** = the open, scored index
(deep design rationale stays in `docs/*` plan docs it points to, never duplicated);
**`BACKLOG_DONE.md`** = the BL-NN→outcome ledger with drop rationale. No item lives in
two places except `(partial …)` items by design.

## Steps

Run from the target repo root.

### 1. Idempotency check

```bash
ls BACKLOG.md BACKLOG_DONE.md 2>/dev/null
```

- If **both** exist, do not clobber. Report they're present and stop (or, if the user
  asked to re-seed, only update content — never overwrite their entries).
- If neither exists, continue. The skill's templates are in `templates/` next to this
  file (resolve via the skill base directory).

### 2. Drop the two root files

Copy `templates/BACKLOG.md` and `templates/BACKLOG_DONE.md` to the repo root.
Replace the `{{PROJECT}}` placeholder with the repo's name. Keep the header sections
verbatim — they document the scoring and entry rules. Leave the theme sections as
the provided starter set; the user will rename them to fit the project.

### 3. Inject the Definition of Done into CLAUDE.md

- If `CLAUDE.md` exists, append the contents of `templates/claude_md_section.md` to it
  (check it isn't already present first — grep for "Backlog maintenance").
- If `CLAUDE.md` does not exist, create it with a one-line project header followed by
  that section.

### 4. Seed real items (optional but recommended)

Offer to populate `BACKLOG.md` from what the repo already defers, so it starts useful
rather than empty. Harvest from, in order:

- inline `TODO`/`FIXME`/`HACK`/`FOLLOW-UP` markers (`grep -rIn`),
- "deferred / parked / follow-up / fast-follow / out of scope / future work" mentions
  in `docs/*.md` and any planning docs,
- open issues if a tracker exists.

For each genuine deferred item, mint the next `BL-NN`, write a one-paragraph entry, and
score it `‹V· F· C· E· → (V×F×C)÷E›` using the scale documented in the header of the
`BACKLOG.md` you just wrote (Step 2). Put a `see docs/…` pointer on anything that has a
deeper design doc rather than copying the detail in. Sort each theme highest-score first.
Confirm the harvested set with the user before writing — do not invent work.

### 5. Verify

Confirm both files landed and the CLAUDE.md rule is present exactly once: `BACKLOG.md` and
`BACKLOG_DONE.md` exist at the repo root, neither still contains the literal `{{PROJECT}}`
placeholder, and `grep -c "Backlog maintenance" CLAUDE.md` returns 1. Then show the two
files and the appended CLAUDE.md section. Do **not** commit unless the user asks; if they
do, use a message like `chore: add BACKLOG.md tracking system`.
