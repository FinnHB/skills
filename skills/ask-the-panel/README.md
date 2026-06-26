# ask-the-panel

Send a question, plan, draft, or analysis to a panel of **non-Anthropic** models via
[OpenRouter](https://openrouter.ai) and get their feedback back, synthesised.

## Why

When Claude reviews its own work it carries Anthropic-lineage priors and an RLHF tilt toward
agreeableness. A *fresh* Claude agent (as in `adversarial-check`) is a weak check against
that — it shares the same training family. Routing the same artifact to **different lineages**
(OpenAI, Google, DeepSeek, Qwen, Mistral) is a genuine cross-family check: their
disagreements expose blind spots and confirmation bias that same-family review misses.

OpenRouter gives access to all of them behind one OpenAI-compatible endpoint and one API key.

## What it is / isn't

- **Is:** a reasoning-level outside opinion on plans, drafts, arguments, brainstorms.
- **Isn't:** evidence verification. The external models get one tool-less API call — they
  can't open files or run code, so they can't check `file:line` claims. For evidence-based
  attack with fresh agents that *can* run tools, use `adversarial-check`.

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
| `--models` | `default` (deepseek,gemini,gpt), `all` (+qwen,mistral), or `a,b,c` |
| `--mode` | `critique` (default, adversarial), `review`, `brainstorm` |
| `--max-tokens` (default 2000) / `--temperature` | generation controls |
| `--out FILE` | where the full replies are written (else a temp path, printed) |
| `--full` | also echo full replies to stdout (default: metadata only) |
| `--timeout` / `--retries` | per-attempt timeout (60s) and attempts on transient errors |
| `--yes` | skip the cost-confirmation prompt on runs estimated over ~$0.10 |
| `--list` | print known models (cost / style / lineage) and exit |

stdout is metadata-only by default (live progress, tokens, billed cost, truncation flags);
**read the `--out` file for the actual replies.** A `[TRUNCATED]` tag means a model hit
`--max-tokens` — raise it and re-run.

## Model panel

Cheap-but-capable, deliberately diverse lineages. The authoritative per-model notes
(cost tier / reasoning style / lineage) live in the `MODELS` dict in `panel.py` and are
printed by `python3 panel.py --list` — run that to pick a panel, rather than maintaining a
second copy here. IDs/prices drift; confirm against <https://openrouter.ai/models> and edit
the config block when a model errors.

**Default run** = `deepseek + gemini + gpt` (three distinct lineages, all cheap–mid) to
control cost. Extra aliases (`deepseek-pro`, `gemini-lite`, `qwen`, `mistral`, `grok`) are
off by default; `--models all` adds qwen + mistral. Flagship models are intentionally
excluded from defaults — add them by explicit `--models` override only.

Remember the panel are **diverse critics, not independent judges**: shared training data and
similar RLHF mean they can converge on the same wrong answer, and their model knowledge is
stale enough that they'll confidently call current, valid model IDs "non-existent." Weight
disagreement over agreement, and verify their factual claims.

## Cost

Each run hits several models in parallel; a default critique on a short artifact is typically
a fraction of a cent. stdout prints per-model token counts and the **billed** cost (from
OpenRouter's `usage.cost`), then a total. Runs estimated over ~$0.10 prompt for confirmation
(`--yes` to skip; non-TTY/agent runs abort unless `--yes` is passed, so nothing is sent
silently). Use `--models <one>` for a quick single-model sanity check.

## Notes

- The **anti-sycophancy** framing lives in the `SYSTEM_PROMPTS` block in `panel.py`. These
  models are agreeableness-tuned too, so the prompts explicitly demand disagreement — without
  that you get five "looks good"s. `--mode critique` is the sharpest.
- Content leaves Anthropic to third-party providers. Self-censor; don't send proprietary or
  confidential material. OpenRouter has account-level privacy/no-log settings if your
  tolerance changes later.
