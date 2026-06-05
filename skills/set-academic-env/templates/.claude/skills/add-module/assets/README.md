# {{MODULE}}

## Purpose

_Describe what this module does and what research question it addresses._

## Layout

```
{{MODULE}}/
├── src/          numbered analysis scripts (01_*, 02_* ...)
├── output/       generated figures/tables/numbers (git-ignored)
├── data/
│   ├── raw/      read-only inputs (large files git-ignored)
│   └── README.md data manifest (source, url, sha256, size)
├── tests/        optional tests
├── pipeline.py   provenance recorder/checker
├── run.sh        run all src/ scripts in order, then check provenance
└── README.md     this file
```

## How to run

```bash
bash run.sh
```

This runs all numbered scripts in `src/` in order, then verifies provenance
with `pipeline.py check`. Outputs appear in `output/`.

## Checking provenance

```bash
# Check presence, tamper, staleness of all recorded outputs
python pipeline.py check

# Check with non-zero exit on issues (for CI)
python pipeline.py check --strict
```

## Data

See `data/README.md` for the data manifest (sources, checksums, sizes).
Large raw data files are git-ignored; re-fetch with `data/fetch.sh` if present.

## Environment

```bash
# Python (default) — activate the module venv
source .venv/bin/activate
pip install -r requirements.txt

# Or with uv
uv venv && uv pip sync requirements.txt
```
