# Backlog — Done

Terminal states for backlog items: **shipped and dropped**. Open items live in
[`BACKLOG.md`](BACKLOG.md). Each entry maps to its implementing commits via
`git log --grep=BL-NN` — consult git for file-level detail; **do not restate diffs,
file lists, or test counts here**.

Entry format (3-line hard ceiling):

- `- [x] BL-NN — <one-clause what shipped>. (was: <backlog title>)`
- optional second line `Deviation: <how it differs from what BACKLOG.md proposed>.` — only if it deviated
- dropped items: `- [dropped] BL-NN — <one-clause why>.`

Cross-references fold inline, e.g. `(unblocks BL-019)`. Before minting a new `BL-NN`
in `BACKLOG.md`, grep this file for a prior drop of the same idea.

---

<!-- No graduated items yet. The first item to ship or get dropped lands here. -->
