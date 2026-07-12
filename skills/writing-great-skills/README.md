# writing-great-skills

Matt Pocock's reference skill on how to write and edit Claude Code skills well — the vocabulary (leading words, context load, progressive disclosure, completion criteria) and principles that make a skill predictable. All reference, no steps; full definitions live in [GLOSSARY.md](GLOSSARY.md).

## Source

Vendored verbatim from [mattpocock/skills](https://github.com/mattpocock/skills/tree/main/skills/productivity/writing-great-skills) (MIT license). See CHANGELOG.md for the pinned upstream commit.

## Deployment

**Local only** — unlike the other skills in this repo, this one is *not* symlinked into `~/.claude/skills/`. It is symlinked into this repo's `.claude/skills/`, so it is available only when working inside Claude_Skills (where skill-authoring happens):

```bash
ln -s ../../skills/writing-great-skills .claude/skills/writing-great-skills
```

## Usage

It is user-invoked (`disable-model-invocation: true`), so invoke it by name:

```
/writing-great-skills
```

Useful when authoring a new skill or refining an existing one — it gives the session the shared vocabulary and failure-mode checklist (sediment, sprawl, no-ops, negation, premature completion) to review against.

## Updating

To pull upstream changes:

```bash
curl -sf -o skills/writing-great-skills/SKILL.md    https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/writing-great-skills/SKILL.md
curl -sf -o skills/writing-great-skills/GLOSSARY.md https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/writing-great-skills/GLOSSARY.md
```

Then record the new upstream commit in CHANGELOG.md.
