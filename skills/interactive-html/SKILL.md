---
name: interactive-html
description: Put the questions inside the HTML you are producing — options and free-text boxes the user submits back to Claude in one click. Use when there are more than four questions at once, when answers need free text rather than a pick from a short list, or when the questions belong beside a document the user is reading.
---

`AskUserQuestion` is the default for up to four questions with a few options each. This skill takes over past that ceiling — and only past it.

## 1. Choose the layout

The shape of the material decides this, not the question count:

- **Panel** — one document, several questions about it *as a whole*. Set `document` to the HTML file; it renders in a left pane with the questions beside it.
- **Inline** — questions each attached to a *different part* of the material. Omit `document` and interleave `prose` blocks with questions in one column, so each question sits directly under the thing it asks about.

A review that walks section by section is inline; a chart with five decisions hanging off it is panel. Name the layout you picked in the sentence that hands over the URL, so a wrong call is cheap to correct.

## 2. Write the spec

Write `spec.json` to the scratchpad. Its schema is the docstring at the top of [form.py](form.py) — read that before writing your first spec.

What makes the page worth opening:

- **One decision per question.** A question carrying two decisions comes back with one muddled answer.
- **The evidence travels with the question.** The trade-off, the benchmark number, the excerpt being decided on — in `context` for panel, in the preceding `prose` block for inline. The answer should never depend on what the user still remembers.
- **`required` only for genuine blockers.** Everything else stays optional so a fast pass can still submit.

## 3. Serve, then hand over

```bash
python3 <skill-dir>/form.py <spec.json> <answers.json>
```

Run it with `run_in_background: true`. It prints `FORM READY <url>`; `open` that URL, then end the turn with one line naming what you asked about.

Handing over *is* the completion criterion. The server waits indefinitely, exits when the user submits, and that exit re-invokes you with the answers waiting — so polling for the file, or holding the turn open, spends context to learn what arrives for free.

## 4. Act on the answers

Read `answers.json`; its keys are the question ids.

- An absent key is an unanswered optional question. Read it as "no preference", pick the sensible default, and say which default you took — a second round of asking is the thing this skill exists to avoid.
- Free text in `Other` beats a selected option when the two disagree.
