"""Search development for PubMed, Semantic Scholar and CORE (protocol Appendix B).

Same word blocks as OpenAlex (search_blocks.py); only the syntax changes per database.
Counts and benchmark recall only: no record is saved or screened (the real search runs after acceptance).
Writes the exact strings to strings_<database>.txt and appends counts to search_dev_log.csv / benchmark_recall.csv.
Usage (from Projet1_Meta-Analyse/): python 00_protocol/search_development/search_other_dbs.py
Optional: SEMANTIC_SCHOLAR_API_KEY, CORE_API_KEY in the environment.
"""
import csv, datetime, json, os, pathlib, re, time, urllib.error, urllib.parse, urllib.request

from search_blocks import *  # VERSION, blocks, STRATEGIES, UNION, BENCHMARKS

HERE = pathlib.Path(__file__).resolve().parent
TODAY = datetime.date.today().isoformat()
UA = {"User-Agent": "search-dev/1.0 (mailto:129296788+mariabdj@users.noreply.github.com)"}


def get_json(url, headers=None, tries=6):
    for i in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={**UA, **(headers or {})}), timeout=90) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503, 504) and i < tries - 1:
                time.sleep(6 * (i + 1)); continue
            raise
        except (urllib.error.URLError, TimeoutError, OSError):
            time.sleep(6 * (i + 1))
    raise RuntimeError(url)


# ---- syntax per database ---------------------------------------------------------------------------------
def pubmed_term(t):
    return f"{t}[tiab]" if t.startswith('"') else f"{t}[tiab]"


def pubmed(blocks):
    return " AND ".join("(" + " OR ".join(pubmed_term(t) for t in b) + ")" for b in blocks)


def s2(blocks):
    # Semantic Scholar bulk search: + = AND, | = OR, "..." = phrase; searches title and abstract
    return " + ".join("(" + " | ".join(b) + ")" for b in blocks)


def core(blocks):
    # CORE v3: field search on title and abstract only (a plain query would also search full texts)
    def blk(b):
        inner = " OR ".join(b)
        return f"(title:({inner}) OR abstract:({inner}))"
    return " AND ".join(blk(b) for b in blocks)


def union(fn):
    return " OR ".join("(" + fn(STRATEGIES[s]) + ")" for s in UNION) if fn is not s2 else \
        " | ".join("(" + s2(STRATEGIES[s]) + ")" for s in UNION)


# ---- PubMed (NCBI E-utilities) -----------------------------------------------------------------------------
def pubmed_count(term, years=False):
    if years:
        term = f"({term}) AND 1990:2026[dp]"
    # POST: the union string is too long for a URL (HTTP 414)
    body = urllib.parse.urlencode({"db": "pubmed", "term": term, "retmode": "json", "retmax": 0}).encode()
    time.sleep(0.4)  # 3 requests per second without a key
    with urllib.request.urlopen(urllib.request.Request(
            "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi", data=body, headers=UA), timeout=90) as resp:
        r = json.load(resp)["esearchresult"]
    if r.get("errorlist") or r.get("warninglist", {}).get("phrasesignored"):
        print("  PubMed warning:", r.get("errorlist"), r.get("warninglist"))
    return int(r["count"])


# ---- Semantic Scholar (bulk search) ------------------------------------------------------------------------
S2_KEY = os.environ.get("SEMANTIC_SCHOLAR_API_KEY", "")


def s2_count(query, years=False):
    p = {"query": query, "fields": "title"}
    if years:
        p["year"] = "1990-2026"
    url = "https://api.semanticscholar.org/graph/v1/paper/search/bulk?" + urllib.parse.urlencode(p)
    time.sleep(1.5)
    return int(get_json(url, {"x-api-key": S2_KEY} if S2_KEY else None).get("total", 0))


def title_phrase(title, n=6):
    words = re.findall(r"[A-Za-z]+", title)
    return '"' + " ".join(words[:n]) + '"'


# ---- run --------------------------------------------------------------------------------------------------
log, recall = [], []
strings = {"pubmed": {}, "semantic_scholar": {}, "core": {}}
for name, blocks in STRATEGIES.items():
    strings["pubmed"][name] = pubmed(blocks)
    strings["semantic_scholar"][name] = s2(blocks)
    strings["core"][name] = core(blocks)
strings["pubmed"]["UNION_S1_S2_S4"] = union(pubmed)
strings["semantic_scholar"]["UNION_S1_S2_S4"] = union(s2)
strings["core"]["UNION_S1_S2_S4"] = union(core)
for db, d in strings.items():
    (HERE / f"strings_{db}.txt").write_text(
        "\n\n".join(f"## {k}\n{v}" for k, v in d.items()) + "\n", encoding="utf-8")

for db, counter in (("PubMed (E-utilities, [tiab])", pubmed_count), ("Semantic Scholar (bulk search)", s2_count)):
    key = "pubmed" if db.startswith("PubMed") else "semantic_scholar"
    for name, q in strings[key].items():
        try:
            n, n_lim = counter(q), counter(q, years=True)
        except Exception as e:
            n = n_lim = f"error: {e}"
        log.append({"date": TODAY, "version": VERSION, "database": db, "strategy": name, "query": q,
                    "n_hits_all_years": n, "n_hits_1990_2026": n_lim})
        print(f"{db} | {name}: {n} ({n_lim} in 1990-2026)")

# benchmark recall
for label, doi in BENCHMARKS.items():
    row = {"date": TODAY, "version": VERSION, "benchmark": label, "doi": doi}
    pm = pubmed_count(f'"{doi}"[aid]')
    row["pubmed_indexed"] = "yes" if pm else "no"
    row["pubmed_union"] = ("found" if pubmed_count(f'({strings["pubmed"]["UNION_S1_S2_S4"]}) AND "{doi}"[aid]') else "missed") if pm else "NA"
    try:
        try:
            paper = get_json(f"https://api.semanticscholar.org/graph/v1/paper/DOI:{doi}?fields=title,abstract",
                             {"x-api-key": S2_KEY} if S2_KEY else None)
            row["s2_lookup"] = "doi"
        except urllib.error.HTTPError:
            # some records carry no DOI in Semantic Scholar: look the paper up by its OpenAlex title instead
            oa = get_json(f"https://api.openalex.org/works/doi:{doi}?select=title")
            m = get_json("https://api.semanticscholar.org/graph/v1/paper/search/match?" + urllib.parse.urlencode(
                {"query": oa["title"], "fields": "title,abstract"}), {"x-api-key": S2_KEY} if S2_KEY else None)
            paper = m["data"][0]
            row["s2_lookup"] = "title match"
        row["s2_has_abstract"] = "yes" if paper.get("abstract") else "no"
        hit = s2_count(f'({strings["semantic_scholar"]["UNION_S1_S2_S4"]}) + {title_phrase(paper["title"])}')
        row["s2_union"] = "found" if hit else "missed"
    except Exception as e:
        row["s2_has_abstract"] = row["s2_union"] = f"error: {e}"
    recall.append(row)
    print(label, row)

with (HERE / "search_dev_log.csv").open("a", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["date", "version", "database", "strategy", "query", "n_hits_all_years", "n_hits_1990_2026"])
    w.writerows(log)
with (HERE / "benchmark_recall_other_dbs.csv").open("a", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(recall[0]))
    if f.tell() == 0:
        w.writeheader()
    w.writerows(recall)
