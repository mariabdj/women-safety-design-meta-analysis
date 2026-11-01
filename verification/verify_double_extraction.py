"""GATE 4: compares my extraction with the blind second extraction (protocol 2.4, Appendix C6).

Usage: python verification/verify_double_extraction.py [03_extraction]

Files in the folder, for each sheet (extraction, extraction_gap, extraction_actual):
  <sheet>.csv                  my sheet now (after resolution)
  <sheet>_pre_resolution.csv   my sheet frozen before the comparison (its SHA-256 goes in the log)
  <sheet>_check.csv            the second extraction. It was given only the row list (the ID and SKELETON
                               columns below, no numbers, ratings or other codes); rows it added have IDs
                               <study_id>_NEW1, <study_id>_NEW2, ...; a kept row keeps that ID in my sheet
and double_extraction_resolutions.csv with columns sheet, key, column, final_value, source_location:
  - one row per disagreement: key = row ID as written, column = the column, final_value = the value kept
  - a row present in only one extraction: column = _row, final_value = kept (row is in my sheet now)
    or removed (row is not in my sheet now)
  - a study re-extracted in full after agreement < 90%: sheet = all, key = study_id, column = _study_reextracted
  - a row removed with _row = removed still needs a resolution for each of its number disagreements

Checks:
  1. every row of my frozen sheet is in the check, with the same skeleton values
  2. agreement per study, before resolution: share of numbers filled by at least one extractor that agree
     exactly (all sheets of the study together); categorical codes are reported separately
  3. a study below 90% must be re-extracted in full (_study_reextracted)
  4. every disagreement and every unmatched row has one resolution with a source_location (a number I read
     from a figure, left empty by the model, is not compared: my two digitisations check it, protocol 2.4),
     and my sheet now holds the resolved value
  5. every cell changed between my frozen sheet and my sheet now has a resolution (no silent edits), in every
     column except those filled at a later step (LATER below); a row added after freezing must come from the check
"""
import csv, hashlib, math, pathlib, re, sys
from collections import defaultdict

ROOT = pathlib.Path(__file__).resolve().parent.parent
folder = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "03_extraction"

SHEETS = {
    "extraction": dict(id="es_id", skeleton=["study_id", "sample_id", "contrast", "feature", "gender", "pair_id",
                                                     "outcome_measure"],
                       num=["n_t", "m_t", "sd_t", "n_c", "m_c", "sd_c", "r_within", "stat_value", "stat_df", "stat_ci_low",
                            "stat_ci_high", "scale_min", "scale_max", "events_t", "events_c", "reported_g"],
                       # year is a bibliographic value, compared as a code so it does not inflate the share of
                       # agreeing numbers; light_type is free text "as reported", so it is not compared
                       cat=["year", "design", "higher_is_safer", "es_method", "dispersion_type", "study_design",
                            "adult_sample", "outcome_type", "outcome_source", "unit_of_analysis", "stimulus",
                            "time_of_day"]),
    # scene_score comes from the separate C7 coding (results removed), so it is not double-extracted here
    "extraction_gap": dict(id="gap_id", skeleton=["study_id", "scene_id", "scene_name"],
                           num=["scale_min", "scale_max", "n_w", "m_w", "sd_w", "n_m", "m_m", "sd_m"],
                           cat=["baseline", "higher_is_safer", "dispersion_type"]),
    "extraction_actual": dict(id="act_id", skeleton=["study_id", "contrast", "feature", "outcome_measure"],
                              num=["ctrl_before", "ctrl_after", "trt_before", "trt_after"],
                              cat=["metric", "outcome_source"]),
}
NA_STRINGS = {"na", "n/a", "nan", "none", "null"}
LATER = {"rob_overall", "seen_before_stage1", "scene_score", "notes"}   # filled after extraction (2.6, 2.13, C7)


def norm(x):
    x = (x or "").strip()
    return "" if x.lower() in NA_STRINGS else x


def load(p):
    try:   # utf-8-sig also reads Excel's "CSV UTF-8" (byte-order mark)
        with p.open(encoding="utf-8-sig", newline="") as f:
            return list(csv.DictReader(f))
    except UnicodeDecodeError:
        print(f"FAIL {p.name}: not UTF-8; save it as CSV UTF-8")
        print("RESULT: FAILED")
        sys.exit(1)


def fig_cols(loc):
    """Columns named after a figure label in source_location, e.g. 'Table 1: n_t; Fig. 3: m_t, m_c' gives {m_t, m_c}."""
    out = set()
    for part in norm(loc).split(";"):
        m = re.match(r"\s*fig(?:ure)?\.?\s*\w+\s*:\s*(.+)$", part, re.I)
        if m:
            out |= {c.strip().lower() for c in m.group(1).split(",")}
    return out


def by_id(rows, idc, label, errors):
    out = {}
    for r in rows:
        k = norm(r.get(idc))
        if not k:
            errors.append(f"{label}: a row has an empty {idc}")
        elif k in out:
            errors.append(f"{label}: {idc} {k} appears twice")
        else:
            out[k] = r
    return out


def same(a, b, numeric):
    if numeric and a and b:
        try:
            return math.isclose(float(a), float(b), rel_tol=0, abs_tol=1e-9)
        except ValueError:
            pass
    return a.lower() == b.lower()


errors, report = [], []

# resolutions
resolutions = {}
res_path = folder / "double_extraction_resolutions.csv"
if res_path.exists():
    for r in load(res_path):
        key = (norm(r.get("sheet")), norm(r.get("key")), norm(r.get("column")))
        if key in resolutions:
            errors.append(f"resolutions: {key} listed twice")
        if not norm(r.get("source_location")):
            errors.append(f"resolutions: {key} has no source_location")
        resolutions[key] = norm(r.get("final_value"))
used = set()

num_agree, num_total = defaultdict(int), defaultdict(int)
cat_agree, cat_total = defaultdict(int), defaultdict(int)

for sheet, s in SHEETS.items():
    p_now, p_pre, p_chk = (folder / f"{sheet}.csv", folder / f"{sheet}_pre_resolution.csv", folder / f"{sheet}_check.csv")
    if sheet != "extraction" and not any(p.exists() for p in (p_now, p_pre, p_chk)):
        continue
    missing = [p.name for p in (p_now, p_pre, p_chk) if not p.exists()]
    if missing:
        errors.append(f"{sheet}: missing {', '.join(missing)} (double extraction covers 100% of every sheet)")
        continue
    print(f"{p_pre.name} SHA-256 {hashlib.sha256(p_pre.read_bytes()).hexdigest()}")
    idc = s["id"]
    NOW = by_id(load(p_now), idc, f"{sheet} (mine)", errors)
    PRE = by_id(load(p_pre), idc, f"{sheet} (frozen)", errors)
    CHK = by_id(load(p_chk), idc, f"{sheet} (check)", errors)
    cols = [(c, True) for c in s["num"]] + [(c, False) for c in s["cat"]]

    # unmatched rows
    for k in sorted(set(PRE) ^ set(CHK)):
        fv = resolutions.get((sheet, k, "_row"))
        used.add((sheet, k, "_row"))
        where = "my sheet only" if k in PRE else "check only"
        if fv is None:
            errors.append(f"{sheet} {idc}={k} ({where}): not resolved")
        elif fv not in ("kept", "removed"):
            errors.append(f"{sheet} {idc}={k}: _row must be kept or removed, not '{fv}'")
        elif (fv == "kept") != (k in NOW):
            errors.append(f"{sheet} {idc}={k}: resolved as {fv} but my sheet {'lacks' if fv == 'kept' else 'still has'} it")
        st = norm((PRE.get(k) or CHK.get(k)).get("study_id"))
        num_total[st] += 1  # a missed or extra row counts as one disagreement
    for k in sorted(set(PRE) - set(NOW)):
        used.add((sheet, k, "_row"))
        if resolutions.get((sheet, k, "_row")) != "removed":
            errors.append(f"{sheet} {idc}={k}: removed from my sheet without a resolution")

    for k in sorted(set(PRE) & set(CHK)):
        rp, rc = PRE[k], CHK[k]
        st = norm(rp.get("study_id"))
        for col in s["skeleton"]:
            if norm(rp.get(col)).lower() != norm(rc.get(col)).lower():
                errors.append(f"{sheet} {idc}={k}: skeleton column {col} differs (mine '{norm(rp.get(col))}', check '{norm(rc.get(col))}'); the row list must be given unchanged")
        for col, numeric in cols:
            va, vb = norm(rp.get(col)), norm(rc.get(col))
            if va == "" and vb == "":
                continue  # empty in both: not counted
            # numbers read from a figure are checked by my digitisations, not by the model (protocol 2.4):
            # skipped only for a column that my source_location names after a figure ("Fig. 3: m_t, m_c")
            if numeric and vb == "" and col in fig_cols(rp.get("source_location")):
                continue
            agree = same(va, vb, numeric)
            (num_agree if numeric else cat_agree)[st] += agree
            (num_total if numeric else cat_total)[st] += 1
            if agree:
                continue
            fv = resolutions.get((sheet, k, col))
            used.add((sheet, k, col))
            if fv is None:
                errors.append(f"{sheet} {idc}={k} {col}: mine '{va}' vs check '{vb}', not resolved")
            elif k in NOW and not same(fv, norm(NOW[k].get(col)), numeric):
                errors.append(f"{sheet} {idc}={k} {col}: resolved to '{fv}' but my sheet says '{norm(NOW[k].get(col))}'")

    # no silent edits between the frozen sheet and my sheet now
    numeric_cols = set(s["num"])
    all_cols = [c for c in dict.fromkeys(list(next(iter(PRE.values()), {}).keys()) + list(next(iter(NOW.values()), {}).keys()))
                if c not in LATER and c != idc]
    for k in sorted(set(PRE) & set(NOW)):
        for col in all_cols:
            numeric = col in numeric_cols
            a, b = norm(PRE[k].get(col)), norm(NOW[k].get(col))
            if same(a, b, numeric):
                continue
            used.add((sheet, k, col))
            if (sheet, k, col) not in resolutions:
                errors.append(f"{sheet} {idc}={k} {col}: changed from '{a}' to '{b}' after freezing, with no resolution")
            elif not same(resolutions[(sheet, k, col)], b, numeric):
                errors.append(f"{sheet} {idc}={k} {col}: resolved to '{resolutions[(sheet, k, col)]}' but my sheet says '{b}'")
    for k in sorted(set(NOW) - set(PRE)):
        used.add((sheet, k, "_row"))
        if k not in CHK:
            errors.append(f"{sheet} {idc}={k}: added after freezing but not in the second extraction (extract it twice first)")
        elif resolutions.get((sheet, k, "_row")) != "kept":
            errors.append(f"{sheet} {idc}={k}: added to my sheet after freezing, with no resolution")
        else:   # my values for a row first found by the model are compared with the model's, like any other row
            for col, numeric in [(c, False) for c in s["skeleton"]] + cols:
                va, vb = norm(NOW[k].get(col)), norm(CHK[k].get(col))
                if same(va, vb, numeric):
                    continue
                used.add((sheet, k, col))
                fv = resolutions.get((sheet, k, col))
                if fv is None:
                    errors.append(f"{sheet} {idc}={k} {col}: mine '{va}' vs check '{vb}' on a kept new row, not resolved")
                elif not same(fv, va, numeric):
                    errors.append(f"{sheet} {idc}={k} {col}: resolved to '{fv}' but my sheet says '{va}'")

for st in sorted(set(num_total) | set(cat_total)):
    share = 100 * num_agree[st] / num_total[st] if num_total[st] else float("nan")
    cat = f"{cat_agree[st]}/{cat_total[st]} codes" if cat_total[st] else "no codes"
    report.append(f"study {st}: {num_agree[st]}/{num_total[st]} numbers agree before resolution ({share:.1f}%); {cat}")
    if num_total[st] and share < 90:
        used.add(("all", st, "_study_reextracted"))
        if ("all", st, "_study_reextracted") not in resolutions:
            errors.append(f"study {st}: agreement {share:.1f}% < 90%, re-extract the study in full and log it")
for key in sorted(set(resolutions) - used):
    errors.append(f"resolutions: {key} does not match any disagreement")

print("\n".join(report))
for e in errors:
    print("FAIL", e)
print("RESULT: FAILED" if errors else f"RESULT: PASSED ({len(report)} studies compared, every disagreement resolved)")
sys.exit(1 if errors else 0)
