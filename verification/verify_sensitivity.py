"""Independent re-computation of 00_protocol/sensitivity/sensitivity_results.csv (written by R).

Same formula, different software: scipy's noncentral t instead of R's pt(); MDE found by bisection instead of uniroot.
PASS if every power and MDE value agrees within 1e-6.
Usage (from Projet1_Meta-Analyse/): python verification/verify_sensitivity.py [csv]
"""
import csv, sys
from scipy.stats import nct, t as tdist

ALPHA, SESOI, TOL = 0.05, 0.20, 1e-6
path = sys.argv[1] if len(sys.argv) > 1 else "00_protocol/sensitivity/sensitivity_results.csv"


def power(delta, k, v, tau2):
    se = ((v + tau2) / k) ** 0.5
    df = k - 1
    tc = tdist.ppf(1 - ALPHA / 2, df)
    ncp = delta / se
    return nct.cdf(-tc, df, ncp) + nct.sf(tc, df, ncp)


def mde(k, v, tau2, target):
    lo, hi = 1e-6, 10.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if power(mid, k, v, tau2) < target else (lo, mid)
    return (lo + hi) / 2


bad = 0
rows = list(csv.DictReader(open(path, encoding="utf-8")))
for r in rows:
    k, v, i2 = int(r["k"]), float(r["v"]), float(r["i2"])
    tau2 = v * i2 / (1 - i2)
    if abs(tau2 - float(r["tau2"])) > TOL:
        bad += 1; print("tau2 mismatch", r); continue
    checks = {"power_at_sesoi": power(SESOI, k, v, tau2), "mde80": mde(k, v, tau2, 0.80), "mde90": mde(k, v, tau2, 0.90)}
    for col, val in checks.items():
        if abs(val - float(r[col])) > TOL:
            bad += 1; print(f"MISMATCH {col}: R={r[col]} py={val:.10f} ({r['question']}, k={k}, I2={i2}, {r['design']})")
print(f"{len(rows)} rows x 4 values checked, {bad} mismatches")
print("RESULT:", "PASSED" if bad == 0 and rows else "FAILED")
sys.exit(0 if bad == 0 and rows else 1)
