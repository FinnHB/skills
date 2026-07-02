---
name: ask-the-panel
description: Send a question, plan, draft, or analysis to a panel of NON-Anthropic models (OpenAI, Google, DeepSeek, Qwen, Mistral…) via OpenRouter and report their feedback, synthesised; optionally run a council-style round where the panelists rank each other's anonymized answers. Use when the user wants an outside view, a second opinion from other AIs, cross-model critique, a model council or peer review across AIs, or to pressure-test something against models from different lineages to counter Anthropic-flavoured sycophancy and confirmation bias.
allowed-tools: Bash, Read
metadata:
  version: 0.4.0
---

# ask-the-panel

Fan a prompt + artifact out to several different model families in parallel and bring back
their feedback. The point is *lineage diversity*: GPT / Gemini / DeepSeek / Qwen / Mistral
diverge enough from Claude in architecture and fine-tuning to surface blind spots that
same-family review misses. They are **diverse critics, not independent judges** — they share
large overlapping training data and similar RLHF, so they can converge on the same wrong
answer. Treat panel *agreement* as a weak signal and *disagreement* as the useful one.

## When to use this / when not to

**Every panelist is a single tool-less API call.** It has no skills, no tools, no repo or
web access, and stale world knowledge — it can only reason over the text you paste into the
prompt. That drives everything below:

- **The artifact must be fully self-contained.** Inline everything the panel needs to judge
  the thing — don't pass a file path, a link, or "see the code changes above." A panelist
  cannot follow any of that; it will either invent an answer or (better) say it can't see it.
- **Not for claims that need verification against ground truth** — files, running code,
  current facts, "does this actually work." That's `adversarial-check`'s job (fresh agents
  *with* tools). Ask-the-panel is a reasoning-level second opinion, not evidence verification.
- **Not for confidential content** — see Privacy below.
- **Good for:** self-contained plans, drafts, arguments, designs, naming/strategy questions,
  brainstorming — anything where "what would a different kind of mind think of this" is the
  question, not "is this fact true."

## One-time setup check

Requires an OpenRouter key in the environment:

```bash
echo "${OPENROUTER_API_KEY:+set}"   # prints "set" if present
```

If empty, don't give up yet: sessions not launched from a terminal (e.g. the desktop app)
never source `~/.zshrc`, so the key may exist there without reaching the session. Check with
`grep -c OPENROUTER_API_KEY ~/.zshrc ~/.zshenv 2>/dev/null` — if present, pull it inline for
the run (`OPENROUTER_API_KEY=$(grep '^export OPENROUTER_API_KEY=' ~/.zshrc | tail -1 | cut
-d= -f2-) python3 …`) without ever printing the key. Only if it's nowhere, tell the user to
`export OPENROUTER_API_KEY=sk-or-...` (in `~/.zshenv` so every session sees it) and stop —
don't proceed without it.

## Usage

1. Put the artifact in a file when it's more than a couple of lines (avoids shell-escaping
   problems) and pass it with `--file`. Short content can go inline via `--prompt`.
2. Run the script (adjust the skill path if it lives under a project's `.claude/skills/`):

```bash
python3 <skill-dir>/panel.py \
  --file /path/to/artifact.md \
  --question "Is the core argument sound? What's the weakest point?" \
  --mode critique \
  --models default
```

Flags: `--models default|all|broad|<a,b,c>` (default = deepseek,gemini,gpt; `all`/`broad` add
qwen,mistral), `--mode critique|review|brainstorm|adjudicate`, `--max-tokens` (default 2000,
must be >= 1), `--temperature` (0-2, default 0.7), `--out <file.md>` for the full replies,
`--full` to also echo replies to stdout, `--timeout` and `--retries` (retries >= 1) for flaky networks,
`--yes` to skip the cost prompt on runs estimated over ~$0.10, `--council` for a second
anonymized peer-review round (below). Run `python3 <skill-dir>/panel.py --list` to see each
model's cost / style / lineage before choosing a non-default panel.

By default stdout shows only per-model metadata (tokens, billed cost, timing, truncation)
plus a live progress line; the **full replies are written to the `--out` file** (or a temp
path it prints at the end). Read that file to synthesise — don't reach for `--full` just to
scrape stdout. A `[TRUNCATED]` tag means the model hit `--max-tokens`; if the note instead
says "budget consumed by reasoning," the model spent most of its output budget on invisible
reasoning tokens — raising `--max-tokens` alone may not fix it, since the model may just
reason longer. One model failing does not abort the run.

## `--council` — a peer-review round

`--council` (off by default) runs a second round after round 1: each panelist that succeeded
in round 1 gets the full original task again (question + artifact, same as round 1) plus
**all** round-1 replies (its own included, unlabeled) anonymized as "Response A / B / C…"
with a letter order randomized independently per judge, and ranks them best to worst.
Modeled on karpathy/llm-council Stage 2 — you (Claude) stay the Stage-3
chairman; there's no synthesis API call, you read the `--out` file's `# Round 2` section and
the `# Anonymization maps` section yourself to see who ranked what.

**Use it when:**
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
neutral verdict; peer convergence is a different tool for a different job. If fewer than 2 models succeeded in round 1 there's nothing to
peer-review; round 2 is skipped automatically with a printed reason.

**Synthesizing round 2:** weight ranking *consensus* — if three judges independently rank the
same response worst, that's a stronger signal than any one judge's stated reasons. Pay
particular attention when a judge downranks its own (anonymized) answer: it didn't know it
was judging itself, so that's a rare moment of a model being harder on itself than an outside
reviewer would be — treat it as a credible signal, not noise. Style and fluency survive
anonymization (a judge can sometimes guess "that's probably GPT's answer" from tone), so don't
over-trust a judge's confidence about *whose* answer something is — only trust its stated
reasons about the *content*.

## Privacy — confirm before sending

Everything in `--file`/`--prompt` leaves Anthropic and reaches OpenRouter and the downstream
provider (OpenAI, Google, DeepSeek, Qwen, Mistral, xAI…), some of which log or train on
inputs. Before the first send in a session, **state in one line what you're about to send
and which providers it will reach, and get the user's go-ahead** — unless the content is
plainly public/non-sensitive (a skill, public analysis, a general question), which you may
send while noting that you're doing so. If it looks proprietary, confidential, or personal,
stop and ask rather than shipping it silently.

## Synthesise — do NOT just dump the output

After the panel replies, the value is in your synthesis, not the raw transcript. Read the
`--out` file, then report in this shape (skip a heading if it's empty):

1. **Consensus** — what the panel agrees on (and whether it matches your own view).
2. **Genuine disagreements** — where models contradict *each other*, with who said what.
3. **Where the panel contradicts you** — the payoff. Call out every point where an external
   model challenges the prior view in this conversation. Don't soften it; that's the whole
   reason to ask outsiders.
4. **What to ignore** — agreement with no substance, hedging, and any claim you can show is
   wrong (e.g. a panelist confidently mis-stating a verifiable fact).

Lead with the synthesis; quote raw replies sparingly.

## Notes

- The model list, prices, and the anti-sycophancy system prompts live in an editable config
  block at the top of `panel.py`. OpenRouter IDs/prices drift — confirm against
  <https://openrouter.ai/models> and edit the block if a model errors.
- `--mode critique` is the default and is deliberately adversarial (these models are also
  agreeableness-tuned; without it you get five "looks good"s).
- For a wider, more expensive sweep use `--models all` (adds Qwen + Mistral).
- **The panel's model knowledge is stale.** Asked about current models, panelists will
  confidently call valid, live model IDs "hallucinated" or "non-existent" because their
  training cutoff predates them. Verify such factual claims against ground truth before
  repeating them — a concrete instance of the "diverse critics, not independent judges"
  caveat at the top.
- `--mode adjudicate` exists for the `adversarial-check` skill's cross-lineage Adjudicator —
  it judges a two-sided evidence packet; see that skill's `references/spawn-templates.md`
  for the packet format.
