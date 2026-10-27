"""Step 0: overlap search. Does a systematic review / meta-analysis on our question already exist?

Runs the same Boolean strategy in OpenAlex and Semantic Scholar (and OSF Registries for planned reviews),
saves every raw API answer untouched in raw/, logs date + exact query + hit count in overlap_search_log.csv,
and merges all records (deduplicated by DOI, then by normalised title) into overlap_records.csv for screening.

Usage (from Projet1_Meta-Analyse/):  python 00_protocol/overlap_search/overlap_search.py
Needs: OPENALEX_API_KEY in the environment (optional SEMANTIC_SCHOLAR_API_KEY).
"""
import csv, datetime, json, os, pathlib, re, time, urllib.parse, urllib.request

HERE = pathlib.Path(__file__).resolve().parent
RAW = HERE / "raw"
RAW.mkdir(exist_ok=True)
TODAY = datetime.date.today().isoformat()

# ---- The strategy: blocks of synonyms -----------------------------------------------------------------
# VERSION 2 (2026-10-27). Changes from v1, after the sensitivity test missed 3 of 4 known reviews:
#  - block A now includes the plain word "review" (v1 missed Dubey 2025 "narrative review", Fotios 2015 "A review")
#  - new strategy "ma_on_outcome": any meta-analysis on the outcome, no design block (v1 missed Collins 2016,
#    whose record has no abstract in OpenAlex, so its design content is invisible to a title/abstract search)
#  - OSF: its engine has no Boolean operators, so simple queries are run one by one and reviews kept locally
# v1 outputs are archived in raw/v1/, overlap_search_log_v1.csv, overlap_records_v1.csv
# VERSION 3 (2026-10-27). Google Scholar (manual check) found Te Braak & van Tienoven 2025 (systematic review of women's
#  perceived safety, doi:10.1016/j.cities.2025.105907), missed by v2: no abstract in OpenAlex and no design word in its
#  title. New strategy "women_outcome_no_design" = review AND outcome AND gender. v2 archived in raw/v2/, *_v2.csv
VERSION = "v3"
A = ['"meta-analysis"', '"meta-analytic"', '"systematic review"', 'review']
A_MA = ['"meta-analysis"', '"meta-analytic"', '"meta-regression"']
B = ['"perceived safety"', '"fear of crime"', '"feeling of safety"', '"feelings of safety"',
     '"perception of safety"', '"sense of safety"', 'reassurance']
C = ['lighting', 'vegetation', 'greenery', '"built environment"', '"urban design"', '"street design"',
     '"physical environment"', '"environmental design"', 'CPTED']
D = ['women', 'gender', 'female', '"sex differences"']
STRATEGIES = {"with_gender": [A, B, C, D], "without_gender": [A, B, C], "ma_on_outcome": [A_MA, B],
              "women_outcome_no_design": [A, B, D]}
OSF_QUERIES = ["fear of crime", "perceived safety", "feeling of safety", "feelings of safety", "sense of safety",
               "perception of safety", "reassurance lighting", "women safety"]
REVIEW_WORDS = re.compile(r"meta-anal|systematic review|scoping review|\breview\b|umbrella review|evidence synthesis", re.I)


def openalex_query(blocks):
    return " AND ".join("(" + " OR ".join(b) + ")" for b in blocks)


def s2_query(blocks):
    # Semantic Scholar bulk syntax: + = AND, | = OR, quotes = phrase
    return " + ".join("(" + " | ".join(b) + ")" for b in blocks)


def get_json(url, headers=None, tries=6):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "overlap-search/1.0", **(headers or {})})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503) and i < tries - 1:
                time.sleep(5 * (i + 1)); continue
            raise
        except (urllib.error.URLError, TimeoutError, ConnectionError, OSError):
            time.sleep(5 * (i + 1))
    raise RuntimeError(f"failed: {url}")


def abstract_from_index(inv):
    if not inv:
        return ""
    pos = {}
    for word, idx in inv.items():
        for i in idx:
            pos[i] = word
    return " ".join(pos[i] for i in sorted(pos))


def run_openalex(name, blocks):
    q = openalex_query(blocks)
    params = {"filter": f"title_and_abstract.search:{q}", "per-page": "200", "cursor": "*",
              "select": "id,doi,title,publication_year,type,abstract_inverted_index,primary_location"}
    key = os.environ.get("OPENALEX_API_KEY")
    if key:
        params["api_key"] = key
    results, pages = [], []
    while True:
        data = get_json("https://api.openalex.org/works?" + urllib.parse.urlencode(params))
        pages.append(data)
        results += data["results"]
        cur = data["meta"].get("next_cursor")
        if not cur or not data["results"]:
            break
        params["cursor"] = cur
    raw = RAW / f"openalex_{name}.json"
    raw.write_text(json.dumps(pages, ensure_ascii=False), encoding="utf-8")
    recs = [{"source": "OpenAlex", "doi": (w.get("doi") or "").replace("https://doi.org/", "").lower(),
             "title": w.get("title") or "", "year": w.get("publication_year"), "type": w.get("type"),
             "venue": ((w.get("primary_location") or {}).get("source") or {}).get("display_name", ""),
             "abstract": abstract_from_index(w.get("abstract_inverted_index"))} for w in results]
    return q, pages[0]["meta"]["count"], recs, raw.name


def run_s2(name, blocks):
    q = s2_query(blocks)
    params = {"query": q, "fields": "title,year,externalIds,abstract,publicationTypes,venue"}
    headers = {"x-api-key": os.environ["SEMANTIC_SCHOLAR_API_KEY"]} if os.environ.get("SEMANTIC_SCHOLAR_API_KEY") else {}
    results, pages, total = [], [], None
    while True:
        data = get_json("https://api.semanticscholar.org/graph/v1/paper/search/bulk?" + urllib.parse.urlencode(params), headers)
        pages.append(data)
        total = data.get("total", total)
        results += data.get("data") or []
        if not data.get("token"):
            break
        params["token"] = data["token"]
        time.sleep(1.5)
    raw = RAW / f"semanticscholar_{name}.json"
    raw.write_text(json.dumps(pages, ensure_ascii=False), encoding="utf-8")
    recs = [{"source": "Semantic Scholar", "doi": ((p.get("externalIds") or {}).get("DOI") or "").lower(),
             "title": p.get("title") or "", "year": p.get("year"), "type": ",".join(p.get("publicationTypes") or []),
             "venue": p.get("venue") or "", "abstract": p.get("abstract") or ""} for p in results]
    return q, total, recs, raw.name


def run_osf(q):
    """OSF Registries (planned/ongoing reviews) via the public SHARE index. Plain-word query (no Boolean support).
    Returns every registration found, plus the subset that are reviews (REVIEW_WORDS in title or description)."""
    url = ("https://share.osf.io/api/v3/index-card-search?" + urllib.parse.urlencode(
        {"cardSearchText": q, "cardSearchFilter[resourceType]": "Registration", "page[size]": "100"}))
    pages, recs = [], []
    while url and len(pages) < 20:
        data = get_json(url, {"Accept": "application/vnd.api+json"})
        pages.append(data)
        for item in data.get("included", []):
            if item.get("type") != "index-card":
                continue
            meta = (item.get("attributes") or {}).get("resourceMetadata") or {}
            title = " ".join(t.get("@value", "") for t in meta.get("title", []) if isinstance(t, dict))
            desc = " ".join(t.get("@value", "") for t in meta.get("description", []) if isinstance(t, dict))
            date = " ".join(t.get("@value", "") for t in meta.get("dateCreated", []) if isinstance(t, dict))
            if title:
                recs.append({"source": "OSF Registries", "doi": "", "title": title, "year": date[:4],
                             "type": "registration", "venue": meta.get("@id", ""), "abstract": desc})
        url = ((data.get("data") or {}).get("relationships", {}).get("searchResultPage", {}).get("links", {}) or {}).get("next", {})
        url = url.get("href") if isinstance(url, dict) else url
        time.sleep(0.5)
    total = pages[0]["data"]["attributes"].get("totalResultCount", len(recs))
    if isinstance(total, dict):
        total = total.get("@id", len(recs))
    raw = RAW / f"osf_{re.sub(r'[^a-z]+', '_', q.lower())}.json"
    raw.write_text(json.dumps(pages, ensure_ascii=False), encoding="utf-8")
    reviews = [r for r in recs if REVIEW_WORDS.search(r["title"] + " " + r["abstract"])]
    return total, recs, reviews, raw.name


def norm_title(t):
    return re.sub(r"[^a-z0-9]", "", (t or "").lower())


def main():
    log_rows, all_recs = [], []
    for name, blocks in STRATEGIES.items():
        for db, fn in (("OpenAlex", run_openalex), ("Semantic Scholar", run_s2)):
            q, n, recs, raw = fn(name, blocks)
            print(f"{db:17s} {name:15s} hits={n}  records saved={len(recs)}")
            log_rows.append({"database": db, "date": TODAY, "strategy": name, "search_string": q,
                             "fields": "title + abstract" if db == "OpenAlex" else "title + abstract (bulk search)",
                             "filters": "none (all years, all languages, all types)", "n_hits": n,
                             "n_records_saved": len(recs), "export_file": raw})
            for r in recs:
                r["strategy"] = name
            all_recs += recs
    for q in OSF_QUERIES:
        try:
            n, recs, reviews, raw = run_osf(q)
            print(f"{'OSF Registries':17s} '{q}': registrations={n} fetched={len(recs)} of which reviews={len(reviews)}")
            log_rows.append({"database": "OSF Registries (SHARE)", "date": TODAY, "strategy": "osf_plain_words",
                             "search_string": q, "fields": "all metadata",
                             "filters": "resource type = Registration; then kept only reviews (regex on title+description)",
                             "n_hits": n, "n_records_saved": len(reviews), "export_file": raw})
            for r in reviews:
                r["strategy"] = "osf_plain_words"
            all_recs += reviews
        except Exception as e:
            print(f"OSF Registries '{q}' failed: {e}")
            log_rows.append({"database": "OSF Registries (SHARE)", "date": TODAY, "strategy": "osf_plain_words",
                             "search_string": q, "fields": "", "filters": "", "n_hits": "FAILED",
                             "n_records_saved": 0, "export_file": str(e)[:80]})

    with (HERE / "overlap_search_log.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(log_rows[0].keys()))
        w.writeheader(); w.writerows(log_rows)

    merged = {}
    for r in all_recs:
        k = r["doi"] or norm_title(r["title"])
        if not k:
            continue
        if k in merged:
            merged[k]["found_in"] = ";".join(sorted(set(merged[k]["found_in"].split(";")) | {f"{r['source']}/{r['strategy']}"}))
            if not merged[k]["abstract"] and r["abstract"]:
                merged[k]["abstract"] = r["abstract"]
        else:
            merged[k] = {**r, "found_in": f"{r['source']}/{r['strategy']}"}
    # second pass: same title, one with DOI and one without
    by_title = {}
    for k, r in list(merged.items()):
        t = norm_title(r["title"])
        if t in by_title and t:
            keep, drop = (by_title[t], k) if merged[by_title[t]]["doi"] else (k, by_title[t])
            merged[keep]["found_in"] = ";".join(sorted(set(merged[keep]["found_in"].split(";")) | set(merged[drop]["found_in"].split(";"))))
            del merged[drop]; by_title[t] = keep
        else:
            by_title[t] = k
    fields = ["doi", "title", "year", "type", "venue", "found_in", "abstract"]
    with (HERE / "overlap_records.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader(); w.writerows(sorted(merged.values(), key=lambda r: -(int(r["year"]) if str(r["year"]).isdigit() else 0)))
    print(f"\nTotal records collected: {len(all_recs)}; unique after deduplication: {len(merged)}")


if __name__ == "__main__":
    main()
