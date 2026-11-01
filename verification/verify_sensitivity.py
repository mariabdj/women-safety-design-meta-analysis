"""Independent re-computation of 00_protocol/sensitivity/sensitivity_results.csv (written by R).

Same formulas, different software: numerical integration in scipy instead of R's noncentral pt(); MDE found by bisection instead of uniroot;
equivalence (TOST) power under a true effect of 0 from the central t. Each row carries its own alpha (Holm bounds).
PASS if every power and MDE value agrees within 1e-6.
Usage (from Projet1_Meta-Analyse/): python verification/verify_sensitivity.py [csv]
"""
import csv, sys
import numpy as np
from scipy.integrate import quad
from scipy.stats import chi2, norm, t as tdist

SESOI, TOL = 0.20, 1e-6
path = sys.argv[1] if len(sys.argv) > 1 else "00_protocol/sensitivity/sensitivity_results.csv"


def power(delta, k, v, tau2, alpha):
    # P(|T| > tc) for a noncentral t, by direct integration over the chi-square part of T = (Z + ncp) / sqrt(W / df).
    # (scipy's nct is inaccurate in the far tails used at alpha = .05/6 with 2 to 4 df, so it is not used here.)
    se = ((v + tau2) / k) ** 0.5
    df = k - 1
    tc = tdist.ppf(1 - alpha / 2, df)
    ncp = delta / se
    f = lambda w: (norm.sf(tc * (w / df) ** 0.5 - ncp) + norm.cdf(-tc * (w / df) ** 0.5 - ncp)) * chi2.pdf(w, df)
    return quad(f, 0, np.inf, limit=100, epsabs=1e-11, epsrel=1e-10)[0]


def mde(k, v, tau2, target, alpha):
    lo, hi = 1e-6, 10.0
    for _ in range(45):   # 10 / 2^45 is far below the 1e-6 tolerance
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if power(mid, k, v, tau2, alpha) < target else (lo, mid)
    return (lo + hi) / 2


def tost0(k, v, tau2, alpha):
    # true effect 0: the estimate/se follows a central t; equivalence needs |estimate| < SESOI - tc * se
    se = ((v + tau2) / k) ** 0.5
    h = SESOI / se - tdist.ppf(1 - alpha, k - 1)
    return 0.0 if h <= 0 else tdist.cdf(h, k - 1) - tdist.cdf(-h, k - 1)


bad = 0
rows = list(csv.DictReader(open(path, encoding="utf-8")))
for r in rows:
    k, v, i2, a = int(r["k"]), float(r["v"]), float(r["i2"]), float(r["alpha"])
    tau2 = v * i2 / (1 - i2)
    if abs(tau2 - float(r["tau2"])) > TOL:
        bad += 1; print("tau2 mismatch", r); continue
    checks = {"power_at_sesoi": power(SESOI, k, v, tau2, a), "mde80": mde(k, v, tau2, 0.80, a),
              "mde90": mde(k, v, tau2, 0.90, a), "power_tost_true0": tost0(k, v, tau2, a)}
    for col, val in checks.items():
        if abs(val - float(r[col])) > TOL:
            bad += 1; print(f"MISMATCH {col}: R={r[col]} py={val:.10f} ({r['question']}, k={k}, I2={i2}, {r['design']})")
print(f"{len(rows)} rows x 5 values checked, {bad} mismatches")
print("RESULT:", "PASSED" if bad == 0 and rows else "FAILED")
sys.exit(0 if bad == 0 and rows else 1)
