# `--council` — the peer-review round

`--council` (off by default) runs a second round after round 1: each panelist that succeeded
in round 1 gets the full original task again (question + artifact, same as round 1) plus
**all** round-1 replies (its own included, unlabeled) anonymized as "Response A / B / C…"
with a letter order randomized independently per judge, and ranks them best to worst.
Modeled on karpathy/llm-council Stage 2 — you (Claude) stay the Stage-3 chairman; there's no
synthesis API call, you read the `--out` file's `# Round 2` section and the
`# Anonymization maps` section yourself to see who ranked what.

## When to use it

- the decision is high-stakes enough to want convergence evidence, not just N independent
  opinions, or
- a plain round-1 run came back with replies that **materially conflict** and you need a
  cheap way to see whether that's noise or a real fault line (does everyone else agree with
  the outlier once they can see it stated plainly, or does the outlier hold up under peer
  scrutiny?).

Don't reach for it by default — it's roughly **2x the cost** of a plain run (each round-2
judge re-reads the full artifact *plus* everything round 1 wrote, so its input grows with
both artifact size and reply lengths) and adds real latency (two sequential rounds). It's
incompatible with `--mode adjudicate` (exit 2) — that mode already produces one independent
neutral verdict; peer convergence is a different tool for a different job. If fewer than 2
models succeeded in round 1 there's nothing to peer-review; round 2 is skipped automatically
with a printed reason.

## Synthesizing round 2

Weight ranking *consensus* — if three judges independently rank the same response worst,
that's a stronger signal than any one judge's stated reasons. Pay particular attention when
a judge downranks its own (anonymized) answer: it didn't know it was judging itself, so
that's a rare moment of a model being harder on itself than an outside reviewer would be —
treat it as a credible signal, not noise. Style and fluency survive anonymization (a judge
can sometimes guess "that's probably GPT's answer" from tone), so don't over-trust a judge's
confidence about *whose* answer something is — only trust its stated reasons about the
*content*.
