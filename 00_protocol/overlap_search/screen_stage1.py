"""Step 0, screening stage 1 (by code): keep records that mention a public-space / crime context.
Loose on purpose: false positives are fine (removed by reading in stage 2), false negatives are not.
Output: stage1_kept.csv (to read) and stage1_counts.txt.
"""
import csv, pathlib, re

HERE = pathlib.Path(__file__).resolve().parent
CONTEXT = re.compile(
    r"crime|criminal|victimi[sz]|street|urban|\bcit(y|ies)\b|neighbo(u)?rhood|\bpark(s)?\b|public (space|place|area|realm)"
    r"|light(ing)?\b|lit\b|pedestrian|walk|transit|public transport|bus stop|harass|cpted|green ?space|vegetation"
    r"|greenery|built environment|incivilit|disorder|campus|night|after dark|policing|surveillance|cctv", re.I)

rows = list(csv.DictReader((HERE / "overlap_records.csv").open(encoding="utf-8")))
kept = [r for r in rows if CONTEXT.search(r["title"] + " " + r["abstract"])]
with (HERE / "stage1_kept.csv").open("w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    w.writeheader(); w.writerows(kept)
msg = f"stage 1: {len(rows)} records in, {len(kept)} kept (context words), {len(rows) - len(kept)} removed\n"
(HERE / "stage1_counts.txt").write_text(msg, encoding="utf-8")
print(msg)
# safety check: the 4 benchmark reviews must survive stage 1
bench = {"10.1186/2046-4053-2-30", "10.1016/j.cities.2024.105534", "10.1177/1477153514524587", "10.1016/j.jcrimjus.2016.06.004"}
print("benchmark kept:", len(bench & {r["doi"] for r in kept}), "of 4")
