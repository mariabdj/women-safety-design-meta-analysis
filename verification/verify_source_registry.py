"""Checks the register of sources that are not journal articles (open data, theses, reports, surveys, figures).
A source can only be used if it is traceable, documented, reusable, and if we reproduced one of its own
published numbers from it (the sanity check).
Usage: python verification/verify_source_registry.py [01_search/source_registry.csv]
"""
import csv, datetime, math, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "01_search" / "source_registry.csv"
TYPES = {"open_data", "thesis", "proceedings", "report", "survey", "figure", "author_reply"}
REQUIRED = ["source_id", "type", "tier", "citation", "doi_or_url", "access_date", "licence", "documentation",
            "sanity_check_value_published", "sanity_check_value_reproduced", "sanity_check_pass"]

if not path.is_file():
    print(f"RESULT: PASSED (no register yet at {path.name}: nothing to check)")
    sys.exit(0)

errors, ids = [], set()
with path.open(encoding="utf-8", newline="") as f:
    rows = list(csv.DictReader(f))
for n, r in enumerate(rows, 2):
    sid = (r.get("source_id") or f"line {n}").strip()
    for col in REQUIRED:
        if not (r.get(col) or "").strip():
            errors.append(f"{sid}: '{col}' is empty")
    if sid in ids:
        errors.append(f"{sid}: duplicated source_id")
    ids.add(sid)
    if r.get("type", "").strip() and r["type"].strip() not in TYPES:
        errors.append(f"{sid}: type '{r['type']}' not in {sorted(TYPES)}")
    if r.get("tier", "").strip() not in ("1", "2"):
        errors.append(f"{sid}: tier must be 1 or 2")
    url = (r.get("doi_or_url") or "").strip()
    if url and not (url.startswith("10.") or url.startswith("http")):
        errors.append(f"{sid}: doi_or_url must be a DOI (10.xxx) or a URL")
    try:
        datetime.date.fromisoformat((r.get("access_date") or "").strip())
    except ValueError:
        errors.append(f"{sid}: access_date must be YYYY-MM-DD")
    passed = (r.get("sanity_check_pass") or "").strip().lower()
    if passed not in ("yes", "no"):
        errors.append(f"{sid}: sanity_check_pass must be yes/no")
    pub, rep = (r.get("sanity_check_value_published") or "").strip(), (r.get("sanity_check_value_reproduced") or "").strip()
    try:
        same = math.isclose(float(pub), float(rep), rel_tol=0, abs_tol=0.5 * 10 ** -max(0, len(pub.split(".")[1]) if "." in pub else 0))
    except ValueError:
        same = pub == rep and pub != ""
    if passed == "yes" and not same:
        errors.append(f"{sid}: marked as passing but reproduced {rep} != published {pub}")
    if passed == "no" and "excluded" not in (r.get("notes") or "").lower():
        errors.append(f"{sid}: failed sanity check must be marked 'excluded' in notes")

for e in errors:
    print("FAIL", e)
used = sum(1 for r in rows if (r.get("sanity_check_pass") or "").strip().lower() == "yes")
print("RESULT: FAILED" if errors else f"RESULT: PASSED ({len(rows)} sources registered, {used} usable)")
sys.exit(1 if errors else 0)
