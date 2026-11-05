# Urban design and women's perceived safety: a gender-disaggregated meta-analysis

Which features of public space (lighting, vegetation, sightlines, active ground floors, maintenance, the presence of other people) make women feel safer, and do any of them narrow the gap between women's and men's perceived safety?

This repository holds the code, logs and data tables for a systematic review and meta-analysis on that question. The review follows PRISMA 2020 and is preregistered on OSF. Everything needed to repeat each step is here or linked from here.

**Status (November 2026):** protocol version 2 deposited on OSF (https://doi.org/10.17605/OSF.IO/AJQ93), next to version 1. Version 1 was deposited on OSF on 1 November 2026 as a Stage 1 Registered Report; PCI Registered Reports declined to review it because screening and extraction are not done by two people. Version 2 keeps every analysis rule and describes the single human reviewer and the AI safety net openly; all changes are listed in protocol section 2.14.

## For reviewers

The registered protocol (version 2, PDF in the OSF component below and in the registration) is the version of record. To check it, these files are enough:

| What | File |
|---|---|
| Protocol (version of record, including all statements) | Version 2 PDF on OSF: https://osf.io/ajq93/ (component DOI: https://doi.org/10.17605/OSF.IO/AJQ93), frozen in the OSF registration; version 1: https://osf.io/v85qc |
| Search strings, counts and benchmark recall | `00_protocol/appendix_B_search_strings.md`, `00_protocol/search_development/benchmark_recall.csv`, `00_protocol/search_development/benchmark_recall_other_dbs.csv` |
| Screening manual, extraction variables, frozen prompts | `00_protocol/appendix_C_screening_extraction.md` |
| Sampling plan (sensitivity analysis) | `00_protocol/sensitivity/sensitivity_analysis.R`, `00_protocol/sensitivity/k_needed.csv` |
| Analysis code and its test on simulated data | `05_analysis/analysis.R`, `05_analysis/effect_sizes.R`, `05_analysis/simulate_data.R`, `05_analysis/test_pipeline.R`, `05_analysis/simulated/test_pipeline_output.txt`, `verification/verify_effect_sizes.R`, `verification/verify_model.R`, `verification/verify_coverage.R`, `05_analysis/simulated/coverage_runs.csv`, `05_analysis/simulated/or_ci_check/` |
| Citation checks | `00_protocol/citation_check.md`, `verification/verify_references.py` |

Everything else (earlier search versions, scoping files, verification scripts for later steps) is background and does not need to be read.

## Why this review
Earlier work either pooled the effect of physical environment changes on fear of crime for everyone (Knabe et al., 2026, preliminary), or reviewed women's safety narratively without pooling (te Braak & van Tienoven, 2025). As far as I could find, no study has pooled design effects separately for women and compared them with men's within the same studies. The scoping search behind that statement is in `00_protocol/overlap_search/`.

## Repository layout
```
00_protocol/          protocol, deviations, and the scoping search (overlap_search/)
01_search/            search logs (raw exports will be archived on OSF)
02_screening/         screening decisions and PRISMA counts
03_extraction/        extraction sheet
04_risk_of_bias/      study quality ratings
05_analysis/          effect sizes and models (R)
06_manuscript/        manuscript source
verification/         checks run after every step (R and Python)
VERIFICATION_LOG.md   output of every check, in order
```

## Reproducing the work
- Python 3.12 (standard library only for the search scripts)
- R 4.6 with `metafor`, `meta`, `esc`, `clubSandwich`, `robvis`, `jsonlite`, `PRISMA2020`, `synthesisr`, `citationchaser`

Scoping search (needs a free OpenAlex key in the `OPENALEX_API_KEY` environment variable):
```bash
python 00_protocol/overlap_search/overlap_search.py
python 00_protocol/overlap_search/screen_stage1.py
```

Checks for a given step (0 to 9):
```bash
python verification/run_gate.py 0
```

Each step of the review has a gate: a set of checks that must pass before the next step starts. Effect sizes and pooled estimates are computed twice, with metafor and with an independent implementation of the formulas, and must agree. The results of every run are appended to `VERIFICATION_LOG.md`.

## Licence
Code: MIT (see `LICENSE`). Data tables, logs and text: CC BY 4.0.

## Author
Maria Boudjelal, independent researcher, Algiers, Algeria
ORCID: [0009-0002-6434-784X](https://orcid.org/0009-0002-6434-784X) · GitHub: [mariabdj](https://github.com/mariabdj)
