# Changelog — snap-site

## 2026-06-12

Initial version. Built during fhbarton.com refinement work, where layout bugs (PaperMod's 768px `.main` width cap, a broken `[hidden]` filter rule) were invisible to Claude without rendered output and had to be discovered through human review rounds.

- `snap.mjs`: full-page screenshots of arbitrary paths × viewport widths against a local dev server; captures console errors and page errors; per-page failure tolerance with non-zero exit on any failure.
- Playwright vendored in the skill folder (resolved via `createRequire` so the script runs from any cwd) — target projects need no dependencies.
