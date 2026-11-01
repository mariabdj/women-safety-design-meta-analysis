"""GATE 5: risk-of-bias table is complete, justified, and the overall rating follows the protocol rule.
Usage: python verification/verify_rob.py [04_risk_of_bias/rob.csv] [03_extraction/extraction.csv]
One row per study and domain: domain = perceived (studies in extraction.csv or extraction_gap.csv) or harm
(studies in extraction_actual.csv, items 2 and 4 as adapted for RQ4 in protocol 2.6); studies only in
extraction_narrative.csv are rated in the domain given there. A study with both outcomes
has two rows. The rob_overall column of extraction.csv must equal the overall rating of its perceived row.
Model ratings (protocol 2.6): rob_check.csv (the model) and rob_pre_resolution.csv (my ratings frozen before I open
the model's; SHA-256 printed for the log) next to rob.csv. Per item: percent agreement and unweighted Cohen's kappa
before resolution; every change from my frozen ratings, and every model disagreement, needs one row in
rob_resolutions.csv (study_id, domain, item, final_value, source_location).
Items (protocol 2.6): i1 sample and recruitment described; i2 conditions comparable except the feature (RQ4:
comparable control area or pre-period); i3 order randomised or counterbalanced, or allocation random; i4 established
scale or clear item about safety or fear (RQ4: harm recorded in the same way before and after, or in the places compared); i5 outcome data
complete or missing data explained; i6 analysis appropriate and statistics consistent.
RULE (must be identical to the protocol): high if i2 or i4 = no; low if all = yes; otherwise some concerns.
"""
import csv, hashlib, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
rob = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "04_risk_of_bias" / "rob.csv"
ext = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "03_extraction" / "extraction.csv"
ITEMS = [f"i{i}" for i in range(1, 7)]
DOMAINS = ("perceived", "harm")
errors = []


def rule(r):
    if r["i2"] == "no" or r["i4"] == "no":
        return "high"
    if all(r[i] == "yes" for i in ITEMS):
        return "low"
    return "some concerns"


def low(x):
    return (x or "").strip().lower()


def read(p, need):
    if not p.is_file():
        errors.append(f"{p.name} not found")
        return None
    try:   # utf-8-sig also reads Excel's "CSV UTF-8" (with a byte-order mark)
        with p.open(encoding="utf-8-sig", newline="") as f:
            rd = csv.DictReader(f)
            rows = list(rd)
            fields = rd.fieldnames or []
    except UnicodeDecodeError:
        errors.append(f"{p.name}: not UTF-8; save it as CSV UTF-8")
        return None
    if not fields:
        errors.append(f"{p.name}: empty file (no header)")
        return None
    miss = [c for c in need if c not in fields]
    if miss:
        errors.append(f"{p.name}: missing columns {', '.join(miss)}")
        return None
    return rows


RATER_COLS = ["study_id", "domain"] + [x for i in ITEMS for x in (i, i + "_support")]


def keyed(path, label, with_overall):
    """Rows of one rating file keyed by (study_id, domain), with values, quotes and duplicates checked."""
    rows = read(path, RATER_COLS + (["overall"] if with_overall else []))
    out = {}
    for r in rows or []:
        k = (r["study_id"].strip(), low(r["domain"]))
        if k[1] not in DOMAINS:
            errors.append(f"{label}: study {k[0]} domain='{r['domain']}' (must be perceived/harm)")
        if k in out:
            errors.append(f"{label}: study {k[0]} ({k[1]}) rated twice")
        for i in ITEMS:
            r[i] = low(r.get(i))
            if r[i] not in ("yes", "no", "unclear"):
                errors.append(f"{label}: study {k[0]} ({k[1]}) {i}='{r[i]}' (must be yes/no/unclear)")
            if len((r.get(f"{i}_support") or "").strip()) < 5:
                errors.append(f"{label}: study {k[0]} ({k[1]}) {i}: no supporting quote/page")
        if with_overall and all(r[i] in ("yes", "no", "unclear") for i in ITEMS):
            expected, given = rule(r), low(r.get("overall"))
            if given != expected:
                errors.append(f"{label}: study {k[0]} ({k[1]}): overall='{given}' but protocol rule gives '{expected}'")
        out[k] = r
    return out


now = keyed(rob, rob.name, True) if rob.is_file() else (errors.append(f"{rob} not found") or {})

# which ratings are needed: perceived for the main and gap sheets, harm for the harm sheet
if not ext.is_file():
    errors.append(f"{ext} not found: the included studies cannot be determined")
else:
    needed = set()
    for name, dom in (("extraction.csv", "perceived"), ("extraction_gap.csv", "perceived"), ("extraction_actual.csv", "harm")):
        p = ext if name == "extraction.csv" else ext.parent / name
        if p.is_file():
            needed |= {(r["study_id"].strip(), dom) for r in read(p, ["study_id"]) or [] if (r.get("study_id") or "").strip()}
    # studies kept only in the narrative table are rated too, in the domain of the outcome they report
    narr = ext.parent / "extraction_narrative.csv"
    if narr.is_file():
        for r in read(narr, ["study_id", "domain"]) or []:
            s, dom = (r.get("study_id") or "").strip(), low(r.get("domain"))
            if s and dom not in DOMAINS:
                errors.append(f"extraction_narrative.csv: study {s} domain='{r.get('domain')}' (must be perceived/harm)")
            elif s:
                needed.add((s, dom))
    for s, dom in sorted(needed - set(now)):
        errors.append(f"included study {s} has no {dom} risk-of-bias rating")
    for s, dom in sorted(set(now) - needed):
        errors.append(f"study {s} rated for {dom} but not in the matching extraction sheet")
    # the sensitivity analysis without high risk of bias reads rob_overall from extraction.csv
    for r in read(ext, ["study_id", "rob_overall"]) or []:
        sid, v = (r.get("study_id") or "").strip(), low(r.get("rob_overall"))
        rated = now.get((sid, "perceived"))
        if rated and not v:
            errors.append(f"extraction.csv {r.get('es_id')}: rob_overall empty; copy the perceived rating of study {sid} ('{low(rated.get('overall'))}')")
        elif v and rated and v != low(rated.get("overall")):
            errors.append(f"extraction.csv {r.get('es_id')}: rob_overall='{v}' but the perceived rating of study {sid} is '{low(rated.get('overall'))}'")


def kappa(a, b):
    n = len(a); cats = sorted(set(a) | set(b))
    po = sum(x == y for x, y in zip(a, b)) / n
    pe = sum((a.count(c) / n) * (b.count(c) / n) for c in cats)
    return po, (None if pe == 1 else (po - pe) / (1 - pe))


chk, pre, res_p = rob.parent / "rob_check.csv", rob.parent / "rob_pre_resolution.csv", rob.parent / "rob_resolutions.csv"
if not (chk.is_file() and pre.is_file()):
    errors.append(f"{chk.name} (model ratings) and {pre.name} (my frozen ratings) are needed: protocol 2.6 reports agreement before resolution")
else:
    for p in (pre, chk):
        print(f"{p.name} SHA-256 {hashlib.sha256(p.read_bytes()).hexdigest()}")
    C, P = keyed(chk, chk.name, False), keyed(pre, pre.name, False)
    # every rating exists in all three files (protocol 2.6: the model rates all studies)
    for k in sorted(set(now) | set(P) | set(C)):
        missing = [n for n, d in ((rob.name, now), (pre.name, P), (chk.name, C)) if k not in d]
        if missing:
            errors.append(f"study {k[0]} ({k[1]}) missing from {', '.join(missing)}")
    common = sorted(set(C) & set(P))
    for i in ITEMS:
        if common:
            po, kp = kappa([P[k][i] for k in common], [C[k][i] for k in common])
            print(f"{i}: agreement {100 * po:.1f}% ({len(common)} ratings), kappa "
                  + ("not defined (one single rating used by both)" if kp is None else f"{kp:.2f}"))
    res = {}
    if res_p.is_file():
        for r in read(res_p, ["study_id", "domain", "item", "final_value", "source_location"]) or []:
            key = (r["study_id"].strip(), low(r["domain"]), low(r["item"]))
            if key in res:
                errors.append(f"{res_p.name}: {key} listed twice")
            if not (r.get("source_location") or "").strip():
                errors.append(f"{res_p.name}: {key} has no source_location")
            res[key] = low(r.get("final_value"))
    used = set()
    for k in sorted(set(P) & set(now)):
        for i in ITEMS:
            a, b, c = P[k][i], now[k][i], (C[k][i] if k in C else "")
            if a != b or (k in C and a != c):
                used.add(k + (i,))
                if res.get(k + (i,)) != b:
                    errors.append(f"study {k[0]} ({k[1]}) {i}: frozen '{a}', model '{c}', now '{b}': needs a resolution with final_value '{b}'")
    for key in sorted(set(res) - used):
        errors.append(f"{res_p.name}: {key} does not match any disagreement or change")

for e in errors:
    print("FAIL", e)
print("RESULT: FAILED" if errors else f"RESULT: PASSED ({len(now)} ratings, all justified, rule respected)")
sys.exit(1 if errors else 0)
