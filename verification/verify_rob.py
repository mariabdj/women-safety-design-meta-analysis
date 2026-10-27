"""GATE 5: risk-of-bias table is complete, justified, and the overall rating follows the protocol rule.
Usage: python verification/verify_rob.py [04_risk_of_bias/rob.csv] [03_extraction/extraction.csv]
Items (adapted JBI quasi-experimental): i1 sample adequate; i2 stimuli comparable except the feature;
i3 randomised/counterbalanced order; i4 validated safety measure; i5 complete outcome data; i6 appropriate analysis.
RULE (must be identical to the protocol): high if i2 or i4 = no; low if all = yes; otherwise some concerns.
"""
import csv, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
rob = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "04_risk_of_bias" / "rob.csv"
ext = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "03_extraction" / "extraction.csv"
ITEMS = [f"i{i}" for i in range(1, 7)]


def rule(r):
    if r["i2"] == "no" or r["i4"] == "no":
        return "high"
    if all(r[i] == "yes" for i in ITEMS):
        return "low"
    return "some concerns"


errors = []
with rob.open(encoding="utf-8", newline="") as f:
    rows = list(csv.DictReader(f))
seen = set()
for r in rows:
    sid = r["study_id"].strip()
    if sid in seen:
        errors.append(f"study {sid} rated twice")
    seen.add(sid)
    for i in ITEMS:
        v = (r.get(i) or "").strip().lower()
        r[i] = v
        if v not in ("yes", "no", "unclear"):
            errors.append(f"study {sid} {i}='{v}' (must be yes/no/unclear)")
        if len((r.get(f"{i}_support") or "").strip()) < 5:
            errors.append(f"study {sid} {i}: no supporting quote/page")
    expected, given = rule(r), (r.get("overall") or "").strip().lower()
    if given != expected:
        errors.append(f"study {sid}: overall='{given}' but protocol rule gives '{expected}'")
if ext.is_file():
    with ext.open(encoding="utf-8", newline="") as f:
        included = {r["study_id"].strip() for r in csv.DictReader(f)}
    for s in sorted(included - seen):
        errors.append(f"included study {s} has no risk-of-bias rating")
    for s in sorted(seen - included):
        errors.append(f"study {s} rated but not in extraction.csv")
for e in errors:
    print("FAIL", e)
print("RESULT: FAILED" if errors else f"RESULT: PASSED ({len(rows)} studies rated, all justified, rule respected)")
sys.exit(1 if errors else 0)
