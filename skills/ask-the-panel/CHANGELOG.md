# Changelog

## 0.2.0 — 2026-06-15

Reliability, output-discipline, and framing pass, derived from a cross-model panel review of
the skill plus a full adversarial-check (Skeptic/Verifier/Rival) of the resulting plan.

**panel.py**
- Retry + backoff in `call_model` (3 attempts on 429/5xx/network; permanent 4xx fail fast).
- `--timeout` (per-attempt, default 60s) and `--retries` flags replace the fixed 180s timeout.
- Up-front `--models` alias validation and a clean `--file` error (exit 2) instead of a
  mid-run per-model error / a raw traceback.
- stdout is now **metadata-only** by default (live progress line + token/cost/timing); full
  replies are always written to `--out` (or a printed temp path) for the orchestrator to
  read. `--full` restores inline replies.
- Cost is taken from OpenRouter's billed `usage.cost`; the price table is now only for
  `--list` / fallback. `[TRUNCATED]` warning when a reply hits `finish_reason == "length"`.
- Pre-flight cost estimate with a ~$0.10 confirmation gate (`--yes` to skip; errors out in
  non-TTY runs so an agent must opt in rather than spend silently).
- Default `--max-tokens` raised 1200 → 2000.
- Model `note` fields standardised to three axes (cost / reasoning style / lineage), dropping
  the unfalsifiable regional "house style" quips.

**SKILL.md**
- Calibrated the "lineage diversity" claim ("diverse critics, not independent judges; can
  converge on the same wrong answer").
- Prescriptive synthesis template (added a "What to ignore" heading).
- Privacy step is now a mandatory pre-send confirmation naming the providers.
- Points Claude to `--list` before choosing a non-default panel; documents the metadata-only
  stdout / read-the-`--out`-file workflow.
- Added a note that the panel's model knowledge is stale (it will call live IDs "fake").

## 0.1.1 — 2026-06-15

Fix stale OpenRouter model IDs found while verifying the skill end-to-end (all three were
returning HTTP 400). Verified live: default trio replied 3/3; error isolation holds for both
unknown aliases and dead IDs.

- `gpt`: `openai/gpt-mini-latest` → `~openai/gpt-mini-latest`.
- `gemini`: `google/gemini-flash-latest` → `~google/gemini-flash-latest`. OpenRouter's
  floating `…-latest` aliases now carry a literal leading `~` in the slug; without it the
  call 400s. Added a config comment so the `~` isn't mistaken for a typo and stripped.
- `mistral`: `mistralai/mistral-medium-3.5` → `mistralai/mistral-medium-3-5` (dot → dash).

## 0.1.0 — 2026-06-15

Initial release. Standalone skill that fans a question + artifact out to a panel of
non-Anthropic models via OpenRouter and reports their feedback, synthesised.

- `panel.py`: stdlib-only (no pip/venv). Parallel calls via `ThreadPoolExecutor`, per-model
  error isolation (one failure doesn't abort the run), token counts + estimated cost per
  model, `--out` to save raw replies.
- Editable config block: model panel (`MODELS`, `DEFAULT_PANEL` = deepseek/gemini/gpt,
  `BROAD_PANEL` adds qwen/mistral) and anti-sycophancy `SYSTEM_PROMPTS` for
  critique/review/brainstorm modes.
- `SKILL.md`: mandatory synthesis step (consensus / disagreements / where the panel
  contradicts Claude), privacy check-before-send, key setup check.
- Scope: standalone only. Wiring a foreign-model panelist into `adversarial-check` is a
  deliberate follow-up.
