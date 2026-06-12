# snap-site

Gives Claude eyes during web UI work: screenshots pages of a locally running dev server at multiple viewport widths using headless Chromium, and reports browser console errors. Claude then reads the PNGs to verify CSS/layout changes visually before asking for a human review.

## Why

Visual bugs are often invisible in source code — a theme's width cap, a `[hidden]` rule that doesn't apply, a section that doesn't separate visually. Without rendered output, the human becomes the renderer and every iteration costs a review round-trip. This skill closes the loop: edit → snap → look → fix, before anyone else needs to look.

## Usage

Works with any framework that serves locally (Hugo, Vite, Next, plain HTML). With the dev server running:

```bash
node ~/.claude/skills/snap-site/snap.mjs \
  --url http://localhost:1313 \
  --paths /,/blog/,/about/ \
  --widths 1920,1440,768,375 \
  --out ./.screenshots
```

All flags optional — defaults: `--url http://localhost:1313`, `--paths /`, `--widths 1920,768,375`, `--out ./.screenshots`.

Output: full-page PNGs named `<page>-<width>w.png`, plus a `CONSOLE ERRORS` section (page errors and console.error calls). Non-zero exit if any page failed to load.

## Setup

Playwright is vendored in this skill's folder so target projects gain no dependencies:

```bash
cd skills/snap-site && npm install && npx playwright install chromium
```

(`node_modules/` is gitignored; rerun this after a fresh clone. The Chromium download is cached machine-wide by Playwright.)

## Notes

- Gitignore the output dir (`.screenshots/`) in target projects.
- For interaction checks (click, then screenshot), write a one-off script importing `chromium` from this skill's `node_modules` — `snap.mjs` shows the pattern.
