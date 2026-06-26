---
name: ask-the-panel
description: Send a question, plan, draft, or analysis to a panel of NON-Anthropic models (OpenAI, Google, DeepSeek, Qwen, Mistral…) via OpenRouter and report their feedback, synthesised. Use when the user wants an outside view, a second opinion from other AIs, cross-model critique, or to pressure-test something against models from different lineages to counter Anthropic-flavoured sycophancy and confirmation bias.
allowed-tools: Bash, Read
metadata:
  version: 0.2.0
---

# ask-the-panel

Fan a prompt + artifact out to several different model families in parallel and bring back
their feedback. The point is *lineage diversity*: GPT / Gemini / DeepSeek / Qwen / Mistral
diverge enough from Claude in architecture and fine-tuning to surface blind spots that
same-family review misses. They are **diverse critics, not independent judges** — they share
large overlapping training data and similar RLHF, so they can converge on the same wrong
answer. Treat panel *agreement* as a weak signal and *disagreement* as the useful one.

The external models get a single API call with **no tools** — they reason over the text you
send, they cannot open files or run code. So this is a *reasoning-level* second opinion
(great for plans, drafts, arguments, brainstorming), not evidence verification of `file:line`
claims. For evidence-based attack, use `adversarial-check` instead.

## One-time setup check

Requires an OpenRouter key in the environment:

```bash
echo "${OPENROUTER_API_KEY:+set}"   # prints "set" if present
```

If empty, tell the user to `export OPENROUTER_API_KEY=sk-or-...` (add to `~/.zshrc` to
persist) and stop — don't proceed without it.

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

Flags: `--models default|all|<a,b,c>` (default = deepseek,gemini,gpt), `--mode
critique|review|brainstorm`, `--max-tokens` (default 2000), `--temperature`,
`--out <file.md>` for the full replies, `--full` to also echo replies to stdout,
`--timeout`/`--retries` for flaky networks, `--yes` to skip the cost prompt on runs
estimated over ~$0.10. Run `python3 <skill-dir>/panel.py --list` to see each model's
cost / style / lineage before choosing a non-default panel.

By default stdout shows only per-model metadata (tokens, billed cost, timing, truncation)
plus a live progress line; the **full replies are written to the `--out` file** (or a temp
path it prints at the end). Read that file to synthesise — don't reach for `--full` just to
scrape stdout. A `[TRUNCATED]` tag means the model hit `--max-tokens`; raise it and re-run.
One model failing does not abort the run.

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
