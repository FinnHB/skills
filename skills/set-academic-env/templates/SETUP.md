# SETUP — Human-action checklist

Complete these steps before running any harness command.

## Environment

The root `.venv/` is the pinned harness tooling environment (sympy, pyzotero, etc.); analysis code gets its own `code/.venv/` when `code/` is first created (Phase 13b).

## System binaries
- [ ] `pandoc` installed (`brew install pandoc`)
- [ ] `tectonic` installed (`brew install tectonic`)
- [ ] `chktex` installed (`brew install chktex`)
- [ ] `checkcites` installed (`brew install checkcites` or via TeXLive)
- [ ] `latexdiff` installed (`brew install latexdiff`)

## API keys (paste into `.env`)
- [ ] DeepSeek API key — already have one? Paste as `CUSTOM_API_KEY`.
- [ ] Zotero API key — get from https://www.zotero.org/settings/keys; paste as `ZOTERO_API_KEY`. Also note your library ID and type.
- [ ] Anthropic API key — already set in Claude Code.

## Zotero app setup
- [ ] Zotero desktop app installed and running.
- [ ] Local API enabled: Edit → Preferences → Advanced → check "Allow other applications on this computer to communicate with Zotero".
- [ ] Per-paper collection created: in Zotero, right-click in the collections sidebar → New Collection → name it after this paper. Copy the collection key (right-click the collection → Copy collection key) and paste into `paper_config.yaml`'s `zotero.collection_key`.

## Theory priors
- [ ] Open `THEORY_PRIORS.md` and fill in the `<!-- BEGIN USER-SPECIFIED -->` block with hard constraints for this paper.

## Version control

The bootstrap initializes a git repository, records an initial `harness-bootstrap` commit,
and installs a secret-scanning pre-commit hook via `core.hooksPath=.githooks`.

- [ ] Confirm a git identity is set (`git config user.email`). If the bootstrap warned it was
  missing, set it and run the initial commit it printed (`git add -A && git commit -m "..."`)
- [ ] Commit after each milestone (`/scope-paper`, `/draft-paper`, each `/refine-*`) so
  latexdiff attribution and `/signoff` SHA-pinning have a baseline.
- [ ] If you add a remote, make it **private** — `.env` is gitignored, but keep keys off any
  shared host as defense in depth.

## Source files
- [ ] If onboarding an existing draft: drop `.docx` and parent `.pdf` into `source/`.
- [ ] If greenfield: leave `source/` empty.

## First run
- [ ] Existing draft: `claude` then `/onboard-paper`.
- [ ] Greenfield: `claude` then `/start-paper "your topic"`.

## Migrating an existing repo to the Phase 12 layout

**This is optional.** The harness does not auto-migrate existing repos. If you want
to move an existing paper repo to the `paper/` + `worklog/` layout, follow these steps:

```bash
# 1. Manuscript + bibliography → paper/
mkdir -p paper
git mv main.tex paper/main.tex
git mv references.bib paper/references.bib   # if it exists

# 2. Planning docs → worklog/
mkdir -p worklog
git mv IDEA.md worklog/IDEA.md               # if it exists
git mv CONTEXT.md worklog/CONTEXT.md         # if it exists (paper-level, not harness-level)
git mv RESEARCH_BRIEF.md worklog/RESEARCH_BRIEF.md   # if it exists

# 3. Report dirs → worklog/
git mv research worklog/research             # if the dir exists and has content
git mv review worklog/review                 # if the dir exists and has content
git mv transcripts worklog/transcripts       # if the dir exists and has content

# 4. Update paper_config.yaml paths: block
# Add or update the paths: block to reflect the new locations.
# The defaults (paper/main.tex, paper/references.bib, worklog) match the above.

git commit -m "Migrate repo to Phase 12 paper/ + worklog/ layout"
```

Files that stay at root (do NOT move): `CONSTITUTION.md`, `THEORY_PRIORS.md`,
`SIGNOFF.md`, `CHANGELOG.md`, `paper_config.yaml`, `CLAUDE.md`, `SETUP.md`,
`source/`, `related/`, `logs/`.

## Optional (only if you'll use /verify-numerical)
- [ ] Dynare installed (`brew install dynare` — or via Octave: `brew install octave && octave> pkg install -forge dynare`)
- [ ] Julia installed (`brew install julia`); install DSGE packages:
  ```
  julia> using Pkg; Pkg.add("HANK")   # for HANK models
  ```

## Citation extraction (only needed for /onboard-paper, not /start-paper)
- [ ] GROBID running: `docker run -d -p 8070:8070 lfoppiano/grobid:0.8.0`
- [ ] Zotero translation-server running: `docker run -d -p 1969:1969 zotero/translation-server`
- [ ] Verify both: `curl localhost:8070/api/isalive` and `curl localhost:1969`
