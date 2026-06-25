# Backlog

Open, deferred work for {{PROJECT}}. **This file holds open items only** — shipped and
dropped items live in [`BACKLOG_DONE.md`](BACKLOG_DONE.md). The maintenance rules (when
to add, graduate, or drop an item) are the **Definition of Done** in
[`CLAUDE.md`](CLAUDE.md) — keeping this file in sync is part of finishing a task.

## How this file works

Each item has a **stable ID** (`BL-NN`, never reused) and an **importance score**.
Reference the ID in commit messages when you work on an item (`feat: thing (BL-003)`) so
completion is traceable via `git log --grep=BL-003`.

**Score** = `(Value × Frequency × Confidence) ÷ Effort`, each rated **1–5**, shown
inline as `‹V· F· C· E· → score›`. It is a sort key, not an absolute — higher = do
sooner. Quick, frequently-hit, well-understood wins float up; risky, rarely-used big
jobs sink. Items within each section are listed highest-score first.

- **Value** — how much better this makes the tool / how much it's wanted
- **Frequency** — how often it's actually hit (5 = every session, 1 = rare edge case)
- **Confidence** — how sure it'll work and is scoped right (5 = trivial/well-understood, 1 = research spike)
- **Effort** — 1 = <1 hr, 2 = a few hrs, 3 = a day, 4 = a few days, 5 = a week+

**Status markers:** items are open unless tagged `(partial — <done> vs <remains>)`.
`[M]` = must-have / blocker. A `(partial …)` item's shipped slice is found via
`git log --grep=BL-NN`.

**Tiering:** this file is the *index*. Deep design rationale for an active initiative
stays in its `docs/*` plan doc; a substantial item here just carries a `see docs/…`
pointer rather than absorbing the detail. Work fully covered by a live plan doc does
**not** also get a `BL-NN` (no double-tracking).

---

## <Theme A>

<!-- - **(BL-001) Title** ‹V3 F3 C4 E2 → 18.0› — one-paragraph description; see docs/foo_plan.md -->

## <Theme B>

## <Theme C>
