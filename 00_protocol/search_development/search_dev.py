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

# VERSION 2 (2026-10-27). v1 (same day, logged) gave 24k + 32k hits: generic words (street, park, trees,
# maintenance, visibility, disorder, refuge, crime) pulled in unrelated work ("disorder" = mental disorders,
# "refuge" = shelters). v1 also missed Adamczak 2025, which names no design feature. v2: precise feature phrases,
# specific harm terms, and S4 (outcome AND women AND place) to catch gender-focused studies without a feature word.
VERSION = "v2"
FEATURE = ['lighting', 'illumination', '"street lights"', '"street lighting"', '"street lamps"', 'vegetation',
           'greenery', '"green space"', '"green spaces"', 'landscaping', 'sightlines', '"sight lines"',
           '"prospect-refuge"', '"prospect and refuge"', 'entrapment', 'concealment', '"active frontage"',
           '"active frontages"', '"shop fronts"', '"mixed use"', '"mixed-use"', 'incivilities', '"physical disorder"',
           '"neighborhood disorder"', '"neighbourhood disorder"', '"social disorder"', 'graffiti', 'litter',
           '"broken windows"', '"presence of others"', '"presence of people"', '"natural surveillance"',
           '"eyes on the street"', '"built environment"', '"urban design"', '"environmental design"', 'CPTED',
           '"physical environment"']
PERCEIVED = ['"perceived safety"', '"fear of crime"', '"feeling of safety"', '"feelings of safety"',
             '"sense of safety"', '"perception of safety"', '"perceptions of safety"', '"perceived security"',
             '"feeling safe"', '"feel safe"', '"feelings of insecurity"', 'reassurance', '"perceived danger"',
             '"perceived risk of crime"', '"fear of victimization"', '"fear of victimisation"']
ACTUAL = ['"sexual harassment"', '"street harassment"', '"sexual assault"', '"sexual violence"',
          '"violence against women"', '"gender-based violence"', '"crime against women"', '"crimes against women"',
          'victimization', 'victimisation', 'rape']
WOMEN = ['women', 'woman', 'female', 'females', 'gender', 'girls', '"sex differences"']
PLACE = ['environment', 'environments', '"public space"', '"public spaces"', 'park', 'parks', 'street', 'streets',
         'neighbourhood', 'neighborhood', 'urban', 'city', 'transport', 'transit']
FR = ['"sentiment de sécurité"', "\"sentiment d'insécurité\"", '"peur du crime"', '"harcèlement de rue"']

STRATEGIES = {
    "S1_feature_x_perceived": [FEATURE, PERCEIVED],
    "S2_feature_x_actual_x_women": [FEATURE, ACTUAL, WOMEN],
    "S3_french_outcomes": [FR],
    "S4_perceived_x_women_x_place": [PERCEIVED, WOMEN, PLACE],
}
UNION = ["S1_feature_x_perceived", "S2_feature_x_actual_x_women", "S4_perceived_x_women_x_place"]

# Benchmarks: primary studies we expect to be eligible, fixed before running the test.
# Chosen from titles only (Step 0 notes and Knabe et al. reference list); their results were not read.
BENCHMARKS = {
    "Boomsma & Steg 2014": "10.1177/0013916512453838",
    "Baran et al. 2018": "10.1016/j.ufug.2018.08.009",
    "Basu et al. 2021": "10.1016/j.jth.2021.101243",
    "Navarrete-Hernandez et al. 2025": "10.1016/j.landurbplan.2025.105460",
    "Adamczak et al. 2025": "10.1016/j.jenvp.2025.102752",
    "Brands et al. 2025": "10.1093/bjc/azae072",
    "Basaran et al. 2026": "10.1016/j.cities.2026.106873",
}


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
