"""GATE 3: every PRISMA 2020 flow-diagram number adds up exactly.
Usage: python verification/verify_prisma_counts.py [02_screening/prisma_counts.json] [03_extraction/extraction.csv]
Format: verification/templates/prisma_counts_template.json
If fulltext_exclusions.csv exists (columns record_id,reason) its reason counts must equal exclusion_reasons.
"""
import collections, csv, json, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
p = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "02_screening" / "prisma_counts.json"
ext = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "03_extraction" / "extraction.csv"
c = json.loads(p.read_text(encoding="utf-8"))
errors = []


def eq(label, left, right):
    if left != right:
        errors.append(f"{label}: {left} != {right}")


db = c["databases"]
for k, v in list(db.items()) + list(c["other_methods"].items()):
    if isinstance(v, int) and v < 0:
        errors.append(f"negative count: {k}={v}")
eq("db: identified - duplicates - automation - other_removed = screened",
   db["identified"] - db["duplicates_removed"] - db["automation_removed"] - db["other_removed"], db["screened"])
eq("db: screened - excluded_title_abstract = sought_for_retrieval",
   db["screened"] - db["excluded_title_abstract"], db["sought_for_retrieval"])
eq("db: sought - not_retrieved = assessed", db["sought_for_retrieval"] - db["not_retrieved"], db["assessed_for_eligibility"])
eq("db: assessed - sum(exclusion_reasons) = included_reports",
   db["assessed_for_eligibility"] - sum(db["exclusion_reasons"].values()), db["included_reports"])
om = c["other_methods"]
eq("other: sought - not_retrieved = assessed", om["sought_for_retrieval"] - om["not_retrieved"], om["assessed_for_eligibility"])
eq("other: assessed - sum(exclusion_reasons) = included_reports",
   om["assessed_for_eligibility"] - sum(om["exclusion_reasons"].values()), om["included_reports"])
if om["sought_for_retrieval"] > om["identified"]:
    errors.append("other: sought_for_retrieval > identified")
eq("total_included_reports = db + other", db["included_reports"] + om["included_reports"], c["total_included_reports"])
if c["total_included_studies"] > c["total_included_reports"]:
    errors.append("more studies than reports is impossible (one study can have several reports, not the reverse)")

fx = ROOT / "02_screening" / "fulltext_exclusions.csv"
if fx.is_file():
    with fx.open(encoding="utf-8", newline="") as f:
        counted = collections.Counter(r["reason"].strip() for r in csv.DictReader(f))
    declared = collections.Counter({k: v for k, v in db["exclusion_reasons"].items() if v})
    for k in om["exclusion_reasons"]:
        declared[k] += om["exclusion_reasons"][k]
    declared = +declared
    if counted != declared:
        errors.append(f"fulltext_exclusions.csv reasons {dict(counted)} != JSON {dict(declared)}")

if ext.is_file():
    with ext.open(encoding="utf-8", newline="") as f:
        n_studies = len({r["study_id"] for r in csv.DictReader(f)})
    eq("studies in extraction.csv = total_included_studies", n_studies, c["total_included_studies"])

for e in errors:
    print("FAIL", e)
print("RESULT: FAILED" if errors else
      f"RESULT: PASSED (all PRISMA arithmetic closes; {c['total_included_studies']} studies / {c['total_included_reports']} reports)")
sys.exit(1 if errors else 0)
