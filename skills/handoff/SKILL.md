---
name: handoff
description: Handoff the current work into a clean context window as a self-contained briefing prompt. Use when the user says "handoff", or wants to carry this work into a fresh context window or a new session.
---

A handoff is a **briefing**, not a **log**: standing orders the next context can act on cold, naming every file, decision and error in full, for a Claude with no memory of this conversation.

## 1. Verify before writing

Reconstructing state from conversational memory is how a handoff lies. Establish the ground first — `git status` and `git diff --stat`, plus a read of anything you believe exists but did not write yourself this session. Completion criterion: every path, and every claim of "done", is one you confirmed here rather than one you remember.

## 2. Write the briefing

The user's qualifier — "handoff a *plan* for this" — decides which sections carry the weight. Drop any that would be empty; head the rest exactly as written.

```markdown
# Handoff: <goal in one line>

## Objective
<The end state, not the activity.>

## Done — verified
<Confirmed in step 1. What, and where.>

## In flight
<Started, not finished — say how far.>

## Decisions locked
<Each: the decision — why — what was rejected and why.>

## Open questions

## Key files
<`path/to/file.md:40` — what state it's in.>

## Next action
<One instruction, small enough to start immediately.>

## Out of scope
```

A decision without its rejected alternative gets relitigated by the fresh context, which then drifts back into ground you already settled — that clause earns its length more than any other line in the briefing.

## 3. Deliver

Print the briefing as one fenced block, then a line telling the user how to open the fresh session: `/orchestrate` first when the remaining work splits into independent legs worth fanning out, otherwise a plain paste. Leave that recommendation explicitly — `/orchestrate` is user-invoked, so the receiving context can only act on it if the user launches that way. The run ends there: the briefing is for the next context to execute, not this one.
