# handoff

Turns whatever the session is currently doing into a briefing prompt you can paste into a clean context window. Saves re-explaining "I want a handoff prompt so I can continue this in a new session" every time.

Fires on the word itself — "let's handoff a plan for this", "handoff the debugging state" — and on the paraphrases ("continue this in a fresh context window"). The qualifier you use decides which sections of the briefing carry the weight.

Output is a single fenced block in the chat, printed and not acted on. Nothing is written to disk.

## Usage examples

```
Let's handoff a plan for this.
```

```
/handoff
```

```
I'm running low on context — hand this off to a new session.
```

## Why it's a skill and not a hook

A hook would have to pattern-match your prompt text and blind-inject instructions: brittle across phrasings, false-positive on incidental uses of the word, and blind to which *kind* of handoff you asked for. Skill selection is fuzzy matching on a description, which is the actual problem.

## What it protects against

The two failure modes of a hand-written handoff:

- **Stating from memory.** Step 1 forces `git status` / `git diff --stat` before anything is claimed done, so the briefing can't assert a file state that isn't real.
- **Dropping the rejected alternatives.** A decision recorded without what it beat gets relitigated in the fresh context, which then drifts back into settled ground.
