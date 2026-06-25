
## Backlog maintenance (Definition of Done)

`BACKLOG.md` (open work) and `BACKLOG_DONE.md` (shipped + dropped) are the source of
truth for tracked work. Keeping them in sync with reality is **part of finishing a
task**, not an afterthought:

- **Before starting** non-trivial work, check whether it maps to a `BL-NN` item in
  `BACKLOG.md`. Reference that ID in the commit message (e.g. `feat: thing (BL-003)`)
  so completion is traceable via `git log --grep=BL-003`.
- **When work ships**, graduate the item: add a 1–3 line entry to `BACKLOG_DONE.md`
  (`- [x] BL-NN — <what shipped>. (was: <title>)`, plus a `Deviation:` line only if
  it diverged from what `BACKLOG.md` proposed) and **remove it from `BACKLOG.md`**.
  Do not restate diffs, file lists, or test counts — that is git's job.
- **When work is dropped**, log it: `- [dropped] BL-NN — <one-clause why>.` in
  `BACKLOG_DONE.md`. The drop rationale is high-value memory; keep it.
- **When new work is discovered**, first grep `BACKLOG_DONE.md` for a prior drop of
  the same idea; then add it to `BACKLOG.md` with the next unused `BL-NN` (IDs are
  never reused) and a score `‹V· F· C· E· → (V×F×C)÷E›` (each 1–5; see the
  `BACKLOG.md` header), placed in the right theme section, highest-score first.
- **Partials** stay in `BACKLOG.md` tagged `(partial — <done> vs <remains>)`; the
  shipped slice is found via `git log --grep=BL-NN`.

Tiering: `BACKLOG.md` is the index; deep design rationale stays in the relevant
`docs/*` plan doc, which a backlog item points to rather than duplicates. Work fully
covered by a live plan doc does not also get a `BL-NN`.
