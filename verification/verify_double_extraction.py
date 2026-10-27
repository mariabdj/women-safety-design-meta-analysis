"""GATE 4: compares two independent extractions of the same rows (matched on es_id).
Usage: python verification/verify_double_extraction.py [03_extraction/extraction.csv] [03_extraction/extraction_check.csv]
Any disagreement must be resolved against the PDF and the decision written in VERIFICATION_LOG.md.
"""
import csv, math, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
a = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "03_extraction" / "extraction.csv"
b = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "03_extraction" / "extraction_check.csv"
NUMERIC = ["n_t", "m_t", "sd_t", "n_c", "m_c", "sd_c", "r_within", "stat_value", "stat_ci_low", "stat_ci_high",
           "scale_min", "scale_max", "year"]
CATEG = ["study_id", "feature", "gender", "design", "higher_is_safer", "es_method"]


def load(p):
    with p.open(encoding="utf-8", newline="") as f:
        return {r["es_id"].strip(): r for r in csv.DictReader(f)}


A, B = load(a), load(b)
errors, compared = [], 0
for es_id, rb in B.items():
    ra = A.get(es_id)
    if ra is None:
        errors.append(f"es_id={es_id} in check file but not in main extraction")
        continue
    for col in NUMERIC:
        va, vb = (ra.get(col) or "").strip(), (rb.get(col) or "").strip()
        if va == vb == "":
            continue
        compared += 1
        try:
            same = math.isclose(float(va), float(vb), rel_tol=0, abs_tol=1e-9)
        except ValueError:
            same = False
        if not same:
            errors.append(f"es_id={es_id} {col}: main='{va}' vs check='{vb}'")
    for col in CATEG:
        compared += 1
        if (ra.get(col) or "").strip().lower() != (rb.get(col) or "").strip().lower():
            errors.append(f"es_id={es_id} {col}: main='{ra.get(col)}' vs check='{rb.get(col)}'")

share = 100 * len(B) / max(1, len(A))
if share < 20:
    errors.append(f"only {share:.0f}% of rows double-extracted (protocol requires >= 20%)")
for e in errors:
    print("FAIL", e)
print("RESULT: FAILED" if errors else
      f"RESULT: PASSED ({len(B)} rows = {share:.0f}% double-extracted, {compared} values identical)")
sys.exit(1 if errors else 0)
