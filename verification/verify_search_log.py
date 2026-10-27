"""GATE 2: search log is complete and each export file holds exactly the logged number of records.
Usage: python verification/verify_search_log.py [01_search/search_log.csv]
search_log.csv columns: database,date,search_string,filters,n_hits,export_file  (export_file relative to 01_search/raw/)
"""
import csv, datetime, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
log_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "01_search" / "search_log.csv"
RAW = ROOT / "01_search" / "raw"
REQ = ["database", "date", "search_string", "filters", "n_hits", "export_file"]


def count_records(p: pathlib.Path) -> int:
    text = p.read_text(encoding="utf-8", errors="replace")
    suf = p.suffix.lower()
    if suf in (".ris", ".txt"):
        return len(re.findall(r"^TY  - ", text, flags=re.M))
    if suf == ".bib":
        return len(re.findall(r"^@\w+\s*\{", text, flags=re.M))
    if suf == ".nbib":
        return len(re.findall(r"^PMID- ", text, flags=re.M))
    if suf == ".csv":
        with p.open(encoding="utf-8", errors="replace", newline="") as f:
            return max(0, sum(1 for _ in csv.reader(f)) - 1)
    if suf == ".json":
        import json
        data = json.loads(text)
        return len(data if isinstance(data, list) else data.get("results", data.get("papers", [])))
    raise ValueError(f"unknown export format {suf}")


errors = []
with log_path.open(encoding="utf-8", newline="") as f:
    rows = list(csv.DictReader(f))
if not rows:
    errors.append("search log is empty")
for i, r in enumerate(rows, 2):
    for c in REQ:
        if not (r.get(c) or "").strip():
            errors.append(f"line {i}: column '{c}' empty")
    try:
        datetime.date.fromisoformat(r["date"].strip())
    except Exception:
        errors.append(f"line {i}: date '{r.get('date')}' is not YYYY-MM-DD")
    if not (r.get("n_hits") or "").strip().isdigit():
        errors.append(f"line {i}: n_hits '{r.get('n_hits')}' is not an integer")
        continue
    exp = RAW / (r.get("export_file") or "").strip()
    if not exp.is_file():
        errors.append(f"line {i}: export file {exp.name} not found in 01_search/raw/")
        continue
    n = count_records(exp)
    if n != int(r["n_hits"]):
        errors.append(f"line {i} ({r['database']}): logged n_hits={r['n_hits']} but export has {n} records "
                      "(explain in log, e.g. export cap, or re-export)")

for e in errors:
    print("FAIL", e)
total = sum(int(r["n_hits"]) for r in rows if (r.get("n_hits") or "").strip().isdigit())
print("RESULT: FAILED" if errors else f"RESULT: PASSED ({len(rows)} searches, {total} records identified)")
sys.exit(1 if errors else 0)
