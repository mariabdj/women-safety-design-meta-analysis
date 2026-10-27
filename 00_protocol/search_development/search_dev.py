"""Search development for the Stage 1 protocol (primary studies, not reviews).

Builds the Boolean blocks, runs them in OpenAlex (title + abstract), logs date, query and hit count,
and checks recall on a fixed set of benchmark studies chosen before the test (titles/DOIs only, no results read).
Counts only: records are not saved or screened here. The final search runs in Step 2, after registration.
Usage (from Projet1_Meta-Analyse/): python 00_protocol/search_development/search_dev.py
"""
import csv, datetime, json, os, pathlib, time, urllib.parse, urllib.request

HERE = pathlib.Path(__file__).resolve().parent
KEY = os.environ.get("OPENALEX_API_KEY", "")
TODAY = datetime.date.today().isoformat()

from search_blocks import *  # VERSION, blocks, STRATEGIES, UNION, BENCHMARKS


def q(blocks):
    return " AND ".join("(" + " OR ".join(b) + ")" for b in blocks)


def get(params):
    if KEY:
        params["api_key"] = KEY
    url = "https://api.openalex.org/works?" + urllib.parse.urlencode(params)
    for i in range(5):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "search-dev/1.0"}), timeout=90) as r:
                return json.load(r)
        except (urllib.error.URLError, TimeoutError, OSError):
            time.sleep(5 * (i + 1))
    raise RuntimeError(url)


def count(query, extra=""):
    f = f"title_and_abstract.search:{query}" + extra
    return get({"filter": f, "per-page": "1"})["meta"]["count"]


log, recall = [], []
for name, blocks in STRATEGIES.items():
    query = q(blocks)
    n = count(query)
    n_lim = count(query, ",publication_year:1990-2026")
    log.append({"date": TODAY, "version": VERSION, "database": "OpenAlex (title_and_abstract.search)", "strategy": name,
                "query": query, "n_hits_all_years": n, "n_hits_1990_2026": n_lim})
    print(f"{name}: {n} hits ({n_lim} in 1990-2026)")

uq = " OR ".join("(" + q(STRATEGIES[s]) + ")" for s in UNION)
STRATEGIES["UNION_S1_S2_S4"] = None
log.append({"date": TODAY, "version": VERSION, "database": "OpenAlex (title_and_abstract.search)", "strategy": "UNION_S1_S2_S4",
            "query": uq, "n_hits_all_years": count(uq), "n_hits_1990_2026": count(uq, ",publication_year:1990-2026")})
print("UNION:", log[-1]["n_hits_all_years"], "/", log[-1]["n_hits_1990_2026"])

for label, doi in BENCHMARKS.items():
    w = get({"filter": f"doi:https://doi.org/{doi}", "per-page": "1"})["results"]
    if not w:
        recall.append({"date": TODAY, "version": VERSION, "benchmark": label, "doi": doi, "in_openalex": "no"}); continue
    wid = w[0]["id"].split("/")[-1]
    row = {"date": TODAY, "version": VERSION, "benchmark": label, "doi": doi, "in_openalex": "yes",
           "has_abstract": "yes" if w[0].get("abstract_inverted_index") else "no"}
    for name, blocks in STRATEGIES.items():
        query = uq if blocks is None else q(blocks)
        hit = get({"filter": f"openalex:{wid},title_and_abstract.search:{query}", "per-page": "1"})["meta"]["count"]
        row[name] = "found" if hit else "missed"
    recall.append(row)
    print(label, {k: v for k, v in row.items() if k.startswith("S") or k == "has_abstract"})

with (HERE / "search_dev_log.csv").open("a", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(log[0])); w.writeheader() if f.tell() == 0 else None; w.writerows(log)
with (HERE / "benchmark_recall.csv").open("a", encoding="utf-8", newline="") as f:
    keys = ["date", "version", "benchmark", "doi", "in_openalex", "has_abstract"] + list(STRATEGIES)
    w = csv.DictWriter(f, fieldnames=keys, restval="NA"); w.writeheader() if f.tell() == 0 else None; w.writerows(recall)
