"""GATE 9: every reference is real (DOI resolves on Crossref) and matches title, first author and year;
every in-text citation is in the bibliography and every bibliography entry is cited.
Usage: python verification/verify_references.py [06_manuscript/references.bib] [06_manuscript/manuscript.qmd]
Entries without DOI must contain  note = {verified-manually: <how>}  or they fail.
"""
import difflib, pathlib, re, sys, time, unicodedata
import json, urllib.parse, urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
bib = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "06_manuscript" / "references.bib"
ms = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "06_manuscript" / "manuscript.qmd"


def norm(s):
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9 ]", " ", re.sub(r"[{}\\]", "", s)).split()


def field(entry, name):
    """Value of a BibTeX field, with balanced braces (works for one-line and multi-line entries)."""
    m = re.search(rf"[,{{\s]{name}\s*=\s*", entry, flags=re.I)
    if not m:
        return ""
    i = m.end()
    if i >= len(entry):
        return ""
    if entry[i] == "{":
        depth, j = 0, i
        while j < len(entry):
            depth += {"{": 1, "}": -1}.get(entry[j], 0)
            if depth == 0:
                return entry[i + 1:j].strip()
            j += 1
        return entry[i + 1:].strip()
    if entry[i] == '"':
        j = entry.find('"', i + 1)
        return entry[i + 1:j].strip()
    return re.match(r"[^,}\s]*", entry[i:]).group().strip()


def crossref(doi):
    url = "https://api.crossref.org/works/" + urllib.parse.quote(doi)
    req = urllib.request.Request(url, headers={"User-Agent": "meta-analysis-verifier/1.0 (mailto:unknown@example.org)"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)["message"]
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
        except Exception:
            pass
        time.sleep(2 * (attempt + 1))
    raise RuntimeError("Crossref unreachable")


text = bib.read_text(encoding="utf-8")
entries = re.split(r"(?=^@\w+\s*\{)", text, flags=re.M)
entries = [e for e in entries if e.strip().startswith("@")]
errors, ok, keys = [], 0, set()
for e in entries:
    key = re.match(r"@\w+\s*\{\s*([^,\s]+)", e).group(1)
    keys.add(key)
    doi = field(e, "doi").removeprefix("https://doi.org/")
    title, year, author = field(e, "title"), field(e, "year") or field(e, "date")[:4], field(e, "author")
    first = norm(author.split(" and ")[0].split(",")[0] if "," in author.split(" and ")[0] else author.split(" and ")[0].split()[-1] if author else "")
    if not doi:
        if "verified-manually" not in field(e, "note"):
            errors.append(f"{key}: no DOI and not marked verified-manually")
        continue
    msg = crossref(doi)
    if msg is None:
        errors.append(f"{key}: DOI {doi} does not exist on Crossref")
        continue
    cr_title = (msg.get("title") or [""])[0]
    # Crossref keeps the subtitle in a separate field; a bib title may include it or not, so take the better match
    cr_full = cr_title + ": " + (msg.get("subtitle") or [""])[0] if msg.get("subtitle") else cr_title
    sim = max(difflib.SequenceMatcher(None, " ".join(norm(title)), " ".join(norm(c))).ratio() for c in (cr_title, cr_full))
    if sim < 0.90:
        errors.append(f"{key}: title mismatch ({sim:.2f}) bib='{title[:60]}' vs Crossref='{cr_title[:60]}'")
    parts = (msg.get("issued") or {}).get("date-parts") or [[None]]
    cr_years = {str(parts[0][0])}
    for k in ("published-print", "published-online"):
        dp = (msg.get(k) or {}).get("date-parts")
        if dp and dp[0][0]:
            cr_years.add(str(dp[0][0]))
    if year and year not in cr_years:
        errors.append(f"{key}: year {year} vs Crossref {sorted(cr_years)}")
    # group authors (e.g. "PRISMA-P Group") have no family name: compare with the first named person
    cr_auth = [a for a in (msg.get("author") or []) if a.get("family")]
    if first and cr_auth and norm(cr_auth[0].get("family", "")) != first:
        errors.append(f"{key}: first author '{' '.join(first)}' vs Crossref '{cr_auth[0].get('family')}'")
    ok += 1
    time.sleep(0.2)

if ms.is_file():
    mtext = ms.read_text(encoding="utf-8")
    cited = set(re.findall(r"@([A-Za-z0-9_:\-]+[A-Za-z0-9_])", re.sub(r"\S+@\S+\.\w+", "", mtext)))
    cited = {c for c in cited if not c.startswith(("fig-", "tbl-", "sec-", "eq-"))}
    for c in sorted(cited - keys):
        errors.append(f"cited in text but missing from bibliography: @{c}")
    for k in sorted(keys - cited):
        errors.append(f"in bibliography but never cited: {k}")

for e in errors:
    print("FAIL", e)
print("RESULT: FAILED" if errors else f"RESULT: PASSED ({ok} DOIs verified on Crossref, citations and bibliography match)")
sys.exit(1 if errors else 0)
