# ask-the-panel — evals

Scenario-based checks per Anthropic's skill-authoring guidance (scenario / exact invocation /
expected observable behavior). Scenarios marked **[LIVE]** need `OPENROUTER_API_KEY` and real
network access — they are documented here, not automated. Scenarios marked **[OFFLINE]** are
covered by `tests/test_panel.py` and run in CI with no key.

## 1. [OFFLINE] Bad usage never reaches the network

**Invocation:** `python3 panel.py --models bogus --question hi` (no `OPENROUTER_API_KEY` needed
for this one to fail fast — but even with a fake key set, it must not attempt an HTTP call).

**Expected:** exits 2, stderr names the bad alias and lists known ones, no network call is
attempted, no traceback. Covered by `TestCLIValidation.test_unknown_alias_exits_two`.

## 2. [OFFLINE] Cost gate blocks silent spend in non-interactive (agent) runs

**Invocation:** `python3 panel.py --file <a big artifact, >~50KB> --models all --question hi`
run with stdin redirected from `/dev/null` (as an orchestrating agent does), no `--yes`.

**Expected:** prints the pre-flight estimate, then exits 2 with "stdin is not a TTY; re-run
with --yes" — no model is called, no cost is incurred. This is the load-bearing safety
property for letting an agent invoke this skill unattended; it is why the estimate now
includes the system prompt (WS1 item 8) and why `provider.max_price` caps each call
independently even if the estimate is wrong (WS1 item 7). **[LIVE-adjacent]**: the gate itself
is offline-verifiable (no key needed, it fails before the key check's network path — actually
before it even reaches the key check if `--models` etc. are valid, the key check runs first,
so set a fake key: `OPENROUTER_API_KEY=x`). Fully reproducible offline; not in the automated
suite only because it needs a large fixture file — verify manually per the invocation above.

## 3. [LIVE] Partial panel failure doesn't abort the run

**Invocation:** `python3 panel.py --file plan.md --models deepseek,gemini,gpt --question
"Is this sound?"` where one alias's `id` has been temporarily broken (e.g. point `gpt` at a
dead model id).

**Expected:** exit 0 (at least one model replied), the dead model's line shows `FAILED:` with
the HTTP error, the other two print normally, the `--out` file has an `**ERROR:**` section for
the dead one and full text for the rest. Exit code contract: 0 = ≥1 replied, 1 = all failed,
2 = usage/validation error — verified live in the 0.1.1/0.2.0 changelog entries; re-verify
after any `call_model` change.

## 4. [LIVE] Reasoning-heavy model gets an honest truncation message

**Invocation:** `python3 panel.py --file <a large, structurally complex artifact> --models
deepseek --max-tokens 2000 --mode critique` (deepseek-v4-flash is a reasoning model; this
reproduces the 2026-07-02 live finding of 13.5x invisible reasoning overhead on a 22KB
artifact).

**Expected:** if `usage.completion_tokens_details.reasoning_tokens` is more than half of
`completion_tokens` and the reply is truncated, the message reads "budget consumed by
reasoning, raising --max-tokens alone may not help" (not the generic "raise --max-tokens").
The visible/reasoning token split is printed per model (e.g. `220 tok (2780 reasoning)`).

## 5. [LIVE] `--council` produces two rounds and de-anonymizable output

**Invocation:** `python3 panel.py --file plan.md --question "Weakest point?" --models default
--council`

**Expected:** stdout shows `R1 <alias> ok ...` for round 1, then a "Round 2 (peer review): N
judges ..." cost re-estimate line, then `R2 <alias> ok ...` for each round-1 survivor acting as
judge. The `--out` file has three top-level sections — `# Round 1`, `# Round 2`, `# Anonymization
maps` — and every per-judge Round 2 block states its own letter→alias mapping. Exit code is
governed by round 1 only (per `build_council_prompt`'s pure, offline-tested letter/permutation
guarantees — see `tests/test_panel.py::TestBuildCouncilPrompt`).

## 6. [OFFLINE] `--council` + `--mode adjudicate` is rejected before any call

**Invocation:** `OPENROUTER_API_KEY=x python3 panel.py --question hi --council --mode
adjudicate`

**Expected:** exits 2 immediately with "incompatible with --mode adjudicate", no network call.
Covered by `TestCLIValidation.test_council_with_adjudicate_exits_two`.

## 7. [OFFLINE] Non-UTF8 artifact file fails cleanly, not with a traceback

**Invocation:** write a file containing invalid UTF-8 bytes, then `python3 panel.py --file
<that file> --question hi`.

**Expected:** exits 2, stderr names the file and the decode error, no `Traceback` in stderr.
Covered by `TestCLIValidation.test_non_utf8_file_exits_two_no_traceback`.

## 8. [LIVE] Cost label only says "billed" when every result is exact

**Invocation:** any run where at least one model's response omits `usage.cost` (rare — would
need OpenRouter to actually omit it, or mock `call_model`'s fallback path) alongside one that
includes it.

**Expected:** the final summary line says `est (mixed)`, never `billed`, when results are a mix
of exact/estimated cost. All-exact → `billed`. All-estimated → `est`. Pure-function logic
(`cost_label`) is offline-tested in `TestCostLabel`; this scenario documents the live trigger
condition since OpenRouter normally always returns `usage.cost`.
