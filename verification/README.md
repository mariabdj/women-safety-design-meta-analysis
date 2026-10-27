# Verification toolkit

Run a whole gate (recommended, it also writes to `VERIFICATION_LOG.md`):

```bash
python verification/run_gate.py 6
```

Every script exits with code 0 only when everything passes, and prints each failure as `FAIL <where>: <expected> vs <found>`.

## Data formats the scripts expect

### `03_extraction/extraction.csv` (copy `templates/extraction_template.csv`)
One row per effect size.

| Column | Values |
|---|---|
| es_id | unique id (e.g. 1, 2, 3) |
| study_id | same id for all rows of one study / one sample |
| gender | `women`, `men` or `all` |
| design | `between` (different people per condition) or `within` (same people rate both scenes) |
| higher_is_safer | `yes` if a higher score = feels safer; `no` for fear scales (the sign is flipped) |
| es_method | `means` (n, mean, SD per condition), `or_ci` (odds ratio + 95% CI in stat_value / stat_ci_low / stat_ci_high, OR > 1 = more "safe" answers with the feature) or `t_between` (independent t in stat_value, with n_t and n_c) |
| n_t, m_t, sd_t | feature condition (with the design feature) |
| n_c, m_c, sd_c | control condition (without the feature). For `within`, n_t = n_c = number of people |
| dispersion_type | `SD` only. If the paper gives SE, convert (SD = SE × √n), write the conversion in notes and keep `SD` |
| r_within | correlation between the two conditions (within designs); empty if not reported (0.5 is imputed) |
| scale_min, scale_max | lowest and highest possible score of the safety scale |
| reported_g | the d or g printed in the paper, if any (to cross-check) |
| source_location | page + table/figure/paragraph for the numbers. **Mandatory** |
| data_from_author | `yes` / `no` |

### `02_screening/prisma_counts.json`
See `templates/prisma_counts_template.json`.

### `04_risk_of_bias/rob.csv`
See `templates/rob_template.csv`. Items `i1` to `i6` = yes / no / unclear, each with `i1_support` (quote or page).
Overall rule (must match the protocol): **high** if i2 or i4 = no; **low** if all six = yes; otherwise **some concerns**.

### `05_analysis/results/results.json`
```json
{"models": [{"name": "lighting_women", "k": 7, "n_es": 9, "N": 812,
  "estimate": 0.41, "ci_lb": 0.22, "ci_ub": 0.60, "pi_lb": -0.10, "pi_ub": 0.92,
  "tau2": 0.05, "i2": 63.2, "pval": 0.0004}]}
```
Full precision (not rounded). The manuscript check uses these values.
