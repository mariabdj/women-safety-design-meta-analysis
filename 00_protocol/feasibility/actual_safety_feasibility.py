"""Feasibility check for a possible secondary question: do design changes reduce crime or harassment
against women (actual safety), not only fear?

Counts candidate records in OpenAlex (title + abstract) and lists their titles for a rough look.
Titles only: no results are extracted here. Run date and counts go to feasibility_log.csv.
Usage: python 00_protocol/feasibility/actual_safety_feasibility.py
"""
import csv, datetime, json, os, pathlib, urllib.parse, urllib.request

HERE = pathlib.Path(__file__).resolve().parent
KEY = os.environ.get("OPENALEX_API_KEY", "")

DESIGN = ['lighting', '"street light"', '"street lighting"', 'CCTV', 'vegetation', '"built environment"', 'CPTED',
          '"environmental design"', '"urban design"', 'park', 'parks', '"public toilet"', '"bus stop"']
CRIME = ['"sexual harassment"', '"sexual assault"', '"sexual violence"', '"violence against women"',
         '"gender-based violence"', 'victimization', 'victimisation', '"crime against women"', 'rape']
WOMEN = ['women', 'female', 'gender', 'girls']
EVAL = ['intervention', 'experiment', '"quasi-experimental"', '"before and after"', '"difference-in-differences"',
        'evaluation', 'randomized', 'randomised', '"natural experiment"']

QUERIES = {
    "design_x_crime_against_women": [DESIGN, CRIME, WOMEN],
    "design_x_crime_against_women_x_evaluation": [DESIGN, CRIME, WOMEN, EVAL],
}


def q(blocks):
    return " AND ".join("(" + " OR ".join(b) + ")" for b in blocks)


def fetch(query, n=200):
    params = {"filter": f"title_and_abstract.search:{query}", "per-page": str(n),
              "select": "doi,title,publication_year,type", "sort": "relevance_score:desc"}
    if KEY:
        params["api_key"] = KEY
    url = "https://api.openalex.org/works?" + urllib.parse.urlencode(params)
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "feasibility/1.0"}), timeout=60) as r:
        return json.load(r)


log = []
for name, blocks in QUERIES.items():
    query = q(blocks)
    data = fetch(query)
    n = data["meta"]["count"]
    log.append({"date": datetime.date.today().isoformat(), "database": "OpenAlex", "name": name,
                "query": query, "n_hits": n})
    rows = [{"year": w.get("publication_year"), "type": w.get("type"), "doi": (w.get("doi") or "").replace("https://doi.org/", ""),
             "title": w.get("title") or ""} for w in data["results"]]
    with (HERE / f"{name}_top200.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["year", "type", "doi", "title"]); w.writeheader(); w.writerows(rows)
    print(f"{name}: {n} hits")

with (HERE / "feasibility_log.csv").open("a", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["date", "database", "name", "query", "n_hits"])
    if f.tell() == 0:
        w.writeheader()
    w.writerows(log)
