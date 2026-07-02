# ask-the-panel

Send a question, plan, draft, or analysis to a panel of **non-Anthropic** models via
[OpenRouter](https://openrouter.ai) and get their feedback back, synthesised.

## Contents

- [Why](#why)
- [What it is / isn't](#what-it-is--isnt)
- [Setup](#setup)
- [Usage](#usage)
- [Exit codes](#exit-codes)
- [`--council` — peer-review round](#--council--peer-review-round)
- [Model panel](#model-panel)
- [Cost](#cost)
- [Tests & evals](#tests--evals)
- [Notes](#notes)

## Why

When Claude reviews its own work it carries Anthropic-lineage priors and an RLHF tilt toward
agreeableness. A *fresh* Claude agent (as in `adversarial-check`) is a weak check against
that — it shares the same training family. Routing the same artifact to **different lineages**
(OpenAI, Google, DeepSeek, Qwen, Mistral) is a genuine cross-family check: their
disagreements expose blind spots and confirmation bias that same-family review misses.

This is also the evidence base for `DEFAULT_PANEL`: PoLL (arXiv:2404.18796) found that a
**P**anel **o**f **L**LM evaluators built from several small, cheap, *disjoint-family* models
out-judges one large single-family judge (e.g. GPT-4 alone) on both accuracy and
intra-family bias, at over 7x lower cost. Three cheap, lineage-diverse models beat one
expensive same-family one — which is why the default trio is deepseek + gemini + gpt rather
than, say, three OpenAI tiers.

OpenRouter gives access to all of them behind one OpenAI-compatible endpoint and one API key.

## What it is / isn't

- **Is:** a reasoning-level outside opinion on plans, drafts, arguments, brainstorms.
- **Isn't:** evidence verification. The external models get one tool-less API call — they
  can't open files or run code, so they can't check `file:line` claims. For evidence-based
  attack with fresh agents that *can* run tools, use `adversarial-check`.
- **Isn't for confidential content.** See Notes below — everything sent leaves Anthropic.

## Setup

1. Get an OpenRouter key and export it (add to `~/.zshrc` to persist):

   ```bash
   export OPENROUTER_API_KEY=sk-or-...
   ```

   Never commit the key.

2. Symlink the skill into your live skills dir (matches this repo's deployment model):

   ```bash
   ln -s "$(pwd)/skills/ask-the-panel" ~/.claude/skills/ask-the-panel
   ```

3. (Optional) Allow the script in `.claude/settings.json` so it doesn't prompt every call:

   ```json
   { "permissions": { "allow": ["Bash(python3 *ask-the-panel/panel.py*)"] } }
   ```

   No `pip install` or venv needed — `panel.py` is Python 3 stdlib only.

## Usage

```bash
python3 panel.py --file plan.md \
  --question "Is the core argument sound? Weakest point?" \
  --mode critique --models default
```

| Flag | Meaning |
|---|---|
| `--file` / `--prompt` | artifact to send (`--file` preferred for large text) |
| `--question` | what to ask the panel |
| `--models` | `default` (deepseek,gemini,gpt), `all`/`broad` (+qwen,mistral), or `a,b,c` |
| `--mode` | `critique` (default, adversarial), `review`, `brainstorm`, `adjudicate` (two-sided evidence packets, for adversarial-check) |
| `--max-tokens` (default 2000, must be >= 1) / `--temperature` (0-2, default 0.7) | generation controls |
| `--out FILE` | where the full replies are written (else a private 0600 temp path, printed) |
| `--full` | also echo full replies to stdout (default: metadata only) |
| `--timeout` / `--retries` (must be >= 1) | per-attempt timeout (60s) and attempts on transient errors |
| `--yes` | skip the cost-confirmation prompt on runs estimated over ~$0.10 |
| `--council` | second anonymized peer-review round after round 1 ([details](#--council--peer-review-round)) |
| `--list` | print known models (cost / style / lineage) and exit |

stdout is metadata-only by default (live progress, tokens, billed cost, truncation flags,
and — for reasoning models — the visible/reasoning token split); **read the `--out` file for
the actual replies.** A `[TRUNCATED]` tag means a model hit `--max-tokens`; if it instead says
the budget was consumed by reasoning, raising `--max-tokens` alone may not fix it.

## Exit codes

- **0** — at least one model replied (round 1). A partial panel (some models failed) still
  exits 0; check stdout for which ones.
- **1** — every model failed (network, all-dead IDs, etc.). Nothing to synthesise.
- **2** — usage/validation error: bad flag value, unknown model alias, missing content,
  missing `OPENROUTER_API_KEY`, unreadable/non-UTF8 `--file`, or `--council` combined with
  `--mode adjudicate`. Nothing was sent to any model.

## `--council` — peer-review round

`--council` (off by default) adds a second round modeled on karpathy/llm-council Stage 2:
after round 1, every panelist that succeeded gets the full original task again (question +
artifact, same as round 1) plus **all** round-1 replies (its own included, unlabeled, at a
letter position randomized independently per judge) anonymized as "Response A / B / C…",
names each one's strongest point and worst flaw, and ranks them.
Claude (or you) stays the Stage-3 chairman — there is no synthesis API call; you read the
`--out` file's `# Round 2` and `# Anonymization maps` sections to see who ranked what and
de-anonymize the letters.

Use it for high-stakes decisions, or when a round-1 run's replies materially conflict and
you want to see whether that's noise or a real fault line. It roughly **doubles the cost**
of a plain run — each round-2 judge re-reads the artifact *plus* everything round 1 wrote,
so round 2's input grows with both artifact size and reply lengths — and a re-estimated cost
gate (computed from the built round-2 prompts' actual lengths) runs again before round 2 is
sent (same TTY/non-TTY rules as round 1; declining or a blocked non-TTY estimate skips round
2 only, round 1's results are kept). It's incompatible with `--mode adjudicate` (exit 2) —
adjudication wants one independent neutral verdict, not peer convergence. If fewer than 2
models succeed in round 1, round 2 is skipped automatically (nothing to peer-review) with the
reason printed.

**Anonymization caveat:** letter-stripping hides *names*, not *style* — word choice, verbosity,
and hedging patterns often survive well enough that a judge can guess "that's probably GPT's
answer." Trust a judge's stated reasons about a response's *content*; trust its guesses about
*whose* answer something is much less.

`--council-from <existing-out.md>` (re-run just the peer-review round against a saved round-1
transcript, skipping round 1 entirely) was considered and deferred — not built. See
CHANGELOG.

## Model panel

Cheap-but-capable, deliberately diverse lineages. The authoritative per-model notes
(cost tier / reasoning style / lineage) live in the `MODELS` dict in `panel.py` and are
printed by `python3 panel.py --list` — run that to pick a panel, rather than maintaining a
second copy here. IDs/prices drift; confirm against <https://openrouter.ai/models> and edit
the config block when a model errors.

**Default run** = `deepseek + gemini + gpt` (three distinct lineages, all cheap–mid) to
control cost. Extra aliases (`deepseek-pro`, `gemini-lite`, `qwen`, `mistral`, `grok`, `kimi`)
are off by default; `--models all`/`broad` adds qwen + mistral. `kimi` (Moonshot AI's
Kimi-K2.6 — mid cost, strong critique and writing) is reachable only via an explicit
`--models` list, same as the others.

Flagship-tier models are intentionally excluded from `DEFAULT_PANEL`/`BROAD_PANEL` to control
cost. There is no way to reach a flagship via `--models` unless it already has an alias in
`MODELS` — that flag only accepts aliases already present in the config dict. To use a
flagship, add an alias for it to the `MODELS` block in `panel.py` (that block is exactly what
it's for); a flagship-tier alias was considered for this release and declined.

Remember the panel are **diverse critics, not independent judges**: shared training data and
similar RLHF mean they can converge on the same wrong answer, and their model knowledge is
stale enough that they'll confidently call current, valid model IDs "non-existent." Weight
disagreement over agreement, and verify their factual claims.

## Cost

Each run hits several models in parallel; a default critique on a short artifact is typically
a fraction of a cent. stdout prints per-model token counts and cost, then a total labeled
**billed** only when every successful model returned OpenRouter's exact `usage.cost` — if any
result had to fall back to the local price table (rare; happens when a response omits
`usage.cost`) the total is labeled `est` (or `est (mixed)` when some are exact and some
aren't), since the local table drifts. Runs estimated over ~$0.10 prompt for confirmation
(`--yes` to skip; non-TTY/agent runs abort unless `--yes` is passed, so nothing is sent
silently). Use `--models <one>` for a quick single-model sanity check. Each call also carries
a provider-enforced `max_price` ceiling (3x the local table's price) as a backstop against
runaway per-call cost if a provider's price drifts up.

## Tests & evals

- `tests/test_panel.py` — offline `unittest` suite, no key/network needed. Run:
  `python3 -m unittest discover -s tests` (from this directory) or
  `python3 -m unittest discover -s skills/ask-the-panel/tests` (from the repo root).
- `evals/EVALS.md` — scenario checklist (invocation + expected behavior) per Anthropic's
  skill-authoring guidance; scenarios needing a live key are marked and documented rather
  than automated.

## Notes

- The **anti-sycophancy** framing lives in the `SYSTEM_PROMPTS` block in `panel.py`. These
  models are agreeableness-tuned too, so the prompts explicitly demand disagreement — without
  that you get five "looks good"s. `--mode critique` is the sharpest.
- Content leaves Anthropic to third-party providers. Self-censor; don't send proprietary or
  confidential material. OpenRouter has account-level privacy/no-log settings if your
  tolerance changes later.
