---
name: snap-site
description: Screenshot pages of a locally running dev server at multiple viewport widths using headless Chromium, so Claude can visually verify CSS/layout changes and catch console errors. Use when iterating on web UI (any framework — Hugo, Vite, Next, plain HTML) and Claude needs to see the rendered result before asking the user to review.
---

# snap-site

Capture full-page screenshots of a local dev server at several viewport widths, plus any browser console errors, so visual changes can be verified by reading the PNGs.

## One-time setup check

This skill vendors its own Playwright so target projects need no dependencies.
If `node_modules/playwright` is missing in this skill's directory, run (from the skill directory):

```bash
npm install && npx playwright install chromium
```

## Usage

1. Make sure the project's dev server is running (e.g. `hugo server -D`, `npm run dev`). Start it in the background if needed.
2. Run the snap script from anywhere (adjust the skill path if this skill lives in a project's `.claude/skills/` rather than `~/.claude/skills/`):

```bash
node <skill-dir>/snap.mjs \
  --url http://localhost:1313 \
  --paths /,/blog/,/about/ \
  --widths 1920,1440,768,375 \
  --out ./.screenshots
```

All flags are optional. Defaults: `--url http://localhost:1313`, `--paths /`, `--widths 1920,768,375`, `--out ./.screenshots`.

3. The script prints one line per screenshot written, then a `CONSOLE ERRORS` section (empty means clean).
4. **Read the PNGs** (they are images — use the Read tool) and judge the result against what the change was supposed to do. Don't skip this; the screenshots are the point.
5. If the output dir is inside a git repo, make sure it's gitignored before committing anything.

## Notes

- Screenshots are full-page, named `<page>-<width>w.png` (e.g. `home-1920w.png`, `blog-768w.png`).
- For interaction checks (click a button, then screenshot), write a one-off script importing `chromium` from this skill's `node_modules` — see `snap.mjs` for the pattern.
- If a page fails to load, the script reports it and continues with the rest; exit code is non-zero if anything failed.
