# Replication README

<!-- Materialized into replication/README.md when a project goes empirical (Phase 13b).
     Based on the Social Science Data Editors template README:
     https://github.com/social-science-data-editors/template_README -->

## Title / Overview

**Paper title:** [TITLE]

**Authors:** [AUTHOR LIST]

**Journal / submission target:** [JOURNAL]

**Abstract (one sentence):** [ONE-SENTENCE SUMMARY]

This replication package reproduces all figures, tables, and numerical results in the paper.
All analysis code is in `code/`; all raw data is in `data/raw/` (immutable). Running
`code/run_all.sh` from the project root reproduces every output.

---

## Data Availability and Provenance Statement

### Rights to share

[State whether the authors have permission to share all data used. If not, describe
what is available and what must be obtained separately.]

### Data sources

| Source name | URL / Access method | Coverage | License / Terms |
|---|---|---|---|
| [SOURCE 1] | [URL or "Request from [institution]"] | [dates/geography] | [license] |
| [SOURCE 2] | | | |

### What is included in this package

- Raw data included: [YES/PARTIAL/NO — explain what is and is not included]
- If restricted: [instructions for obtaining the restricted files]
- If public: all data needed to reproduce results is in `data/raw/`.

---

## Dataset list

| Dataset name | Source | Provided in package? | Location in package |
|---|---|---|---|
| [Dataset 1] | [Source] | [Yes/No/Partial] | `data/raw/[filename]` |
| [Dataset 2] | | | |

---

## Computational Requirements

### Software and versions

- **Python** [VERSION] — [package manager: pip/conda/uv]
  - All packages pinned in `code/requirements.txt` (or `code/environment.yml`)
  - Install: `cd code && uv venv .venv && uv pip install -r requirements.txt`
- **[Other software, e.g. Stata, R, Julia]** [VERSION] (if applicable)

### Hardware

- **OS:** [e.g. macOS 14.x / Ubuntu 22.04]
- **RAM:** approximately [X] GB required
- **Storage:** approximately [X] GB for raw data + outputs
- **CPU:** [single-core / multi-core note if relevant]

### Expected runtime

- Full pipeline (`code/run_all.sh`): approximately [X minutes / X hours]
- Individual steps: see table in "Description of programs/code" below.

---

## Description of Programs/Code

### `code/` directory layout

```
code/
├── run_all.sh          — runs all numbered scripts in order
├── 01_fetch.py         — downloads / assembles raw data
├── 02_build.py         — cleans and constructs analysis dataset
├── 03_analysis.py      — main estimation / model solution
├── 04_figures.py       — produces all figures → paper/figures/
├── [05_tables.py]      — produces all tables  → paper/tables/  (if applicable)
├── requirements.txt    — pinned Python dependencies
└── .venv/              — local venv (git-ignored; created by install step above)
```

### Script descriptions

| Script | Purpose | Inputs | Outputs | Approx. runtime |
|---|---|---|---|---|
| `01_fetch.py` | [Download / assemble raw data] | [sources] | `data/raw/` | [X min] |
| `02_build.py` | [Clean + construct dataset] | `data/raw/` | `data/derived/` | [X min] |
| `03_analysis.py` | [Main estimation / IRFs] | `data/derived/` | `data/derived/results/` | [X min] |
| `04_figures.py` | [Generate all paper figures] | `data/derived/results/` | `paper/figures/` | [X min] |

---

## Instructions to Replicators

### Prerequisites

1. Install Python [VERSION] and `uv` (or `pip`).
2. Clone this repository: `git clone [REPO URL]`
3. From the project root, install the harness tooling env:
   ```bash
   uv venv .venv && uv pip install -r conf/harness-requirements.txt
   ```
4. Install the analysis env:
   ```bash
   cd code && uv venv .venv && uv pip install -r requirements.txt
   ```
5. [Any additional prerequisites, e.g. API keys for data download]

### Running the full pipeline

```bash
bash code/run_all.sh
```

This runs all numbered scripts in sequence. On success, `logs/pipeline_state.json`
records the SHA256 of each output.

### Running a single step

```bash
python code/03_analysis.py   # runs only the analysis step
```

### Verifying outputs

After `run_all.sh` completes, compare SHA256s in `logs/pipeline_state.json` with the
values archived at submission. Any mismatch indicates a changed environment or data version.

---

## List of Figures/Tables and the Program That Produces Each

| Figure/Table | Number in paper | Program | Output path |
|---|---|---|---|
| [Figure 1 description] | Figure 1 | `code/04_figures.py` | `paper/figures/fig1.pdf` |
| [Table 1 description] | Table 1 | `code/05_tables.py` | `paper/tables/tab1.tex` |
| [Figure 2 description] | Figure 2 | `code/04_figures.py` | `paper/figures/fig2.pdf` |

---

## References

[List data sources, software packages, or methodology references the replicator
needs to understand the data or code.]
