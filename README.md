# Urban design and women's perceived safety: a gender-disaggregated meta-analysis

Which features of public space (lighting, vegetation, sightlines, active ground floors, maintenance, the presence of other people) make women feel safer, and do any of them narrow the gap between women's and men's perceived safety?

This repository holds the code, logs and data tables for a systematic review and meta-analysis on that question. The review follows PRISMA 2020 and will be run as a Registered Report. Everything needed to repeat each step is here or linked from here.

**Status (October 2026):** scoping finished, protocol in preparation.

## Why this review
Earlier work either pooled the effect of physical environment changes on fear of crime for everyone (Knabe et al., 2026, preliminary), or reviewed women's safety narratively without pooling (Te Braak & van Tienoven, 2025). As far as I could find, no study has pooled design effects separately for women and compared them with men's within the same studies. The scoping search behind that statement is in `00_protocol/overlap_search/`.

## Repository layout
```
00_protocol/          protocol, deviations, and the scoping search (overlap_search/)
01_search/            search logs (raw exports are archived on OSF)
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
- R 4.6 with `metafor`, `meta`, `esc`, `clubSandwich`, `robvis`, `jsonlite`

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
