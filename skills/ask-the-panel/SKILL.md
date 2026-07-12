---
name: ask-the-panel
description: Send a question, plan, draft, or analysis to a panel of NON-Anthropic models (OpenAI, Google, DeepSeek, Qwen, Mistral…) via OpenRouter and report their feedback, synthesised. Use when the user wants a second opinion or outside view from other AIs, a model council / cross-model peer review, or to pressure-test something against different lineages to counter Anthropic-flavoured sycophancy and confirmation bias.
allowed-tools: Bash, Read
metadata:
  version: 0.4.1
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

## Privacy — confirm before sending

Everything in `--file`/`--prompt` leaves Anthropic and reaches OpenRouter and the downstream
provider (OpenAI, Google, DeepSeek, Qwen, Mistral, xAI…), some of which log or train on
inputs. Before the first send in a session, **state in one line what you're about to send
and which providers it will reach, and get the user's go-ahead** — unless the content is
plainly public/non-sensitive (a skill, public analysis, a general question), which you may
send while noting that you're doing so. If it looks proprietary, confidential, or personal,
stop and ask rather than shipping it silently.

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

`--council` (off by default) adds a second round in which each round-1 panelist ranks all
the round-1 replies, anonymized — convergence evidence rather than N independent opinions,
at roughly **2x the cost** of a plain run. Before adding the flag — or when a plain run
comes back with materially conflicting replies and you're weighing whether a council round
would settle it — read `references/council.md`: when it pays, its limits, and how to
synthesise the rankings.

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
