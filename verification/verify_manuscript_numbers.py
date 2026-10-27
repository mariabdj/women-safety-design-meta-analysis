"""GATE 9: every number written in the manuscript must come from the results, and the style rules hold.
Usage: python verification/verify_manuscript_numbers.py [manuscript.md|.qmd|.txt|.docx] [results.json] [--style]

A number in the text is accepted if it equals a value from results.json, extraction.csv or prisma_counts.json
rounded to 0, 1, 2 or 3 decimals (also as a percentage), or is whitelisted in verification/number_whitelist.txt
(one number per line), or is a year 1900-2030. The References section is skipped.
--style also fails on em dashes.
"""
import csv, json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
args = [a for a in sys.argv[1:] if not a.startswith("--")]
STYLE = "--style" in sys.argv
ms = pathlib.Path(args[0]) if args else ROOT / "06_manuscript" / "manuscript.md"
res = pathlib.Path(args[1]) if len(args) > 1 else ROOT / "05_analysis" / "results" / "results.json"


def numbers_in(obj):
    if isinstance(obj, bool):
        return
    if isinstance(obj, (int, float)):
        yield float(obj)
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from numbers_in(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from numbers_in(v)


def text_of(p: pathlib.Path) -> str:
    if p.suffix.lower() == ".docx":
        import subprocess
        exe = pathlib.Path.home() / ".local" / "bin" / "markitdown.exe"
        return subprocess.run([str(exe), str(p)], capture_output=True, text=True, encoding="utf-8").stdout
    return p.read_text(encoding="utf-8")


allowed = set()


def allow(x: float):
    for d in (0, 1, 2, 3):
        allowed.add(round(x, d))
        allowed.add(round(abs(x), d))
        allowed.add(round(100 * x, d))


sources = [res, ROOT / "02_screening" / "prisma_counts.json"]
for s in sources:
    if s.is_file():
        for x in numbers_in(json.loads(s.read_text(encoding="utf-8"))):
            allow(x)
ext = ROOT / "03_extraction" / "extraction.csv"
if ext.is_file():
    with ext.open(encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            for v in r.values():
                try:
                    allow(float(v))
                except (TypeError, ValueError):
                    pass
wl = ROOT / "verification" / "number_whitelist.txt"
if wl.is_file():
    for line in wl.read_text(encoding="utf-8").splitlines():
        line = line.split("#")[0].strip()
        if line:
            allowed.add(float(line))
for x in (0.05, 0.001, 0.95, 95, 2020, 1, 2, 3):   # alpha, p threshold, 95% CI, PRISMA 2020, generic counts
    allowed.add(x)

text = text_of(ms)
body = re.split(r"^#+\s*(References|Bibliography|Références)\s*$", text, flags=re.M | re.I)[0]
body = re.sub(r"```.*?```", "", body, flags=re.S)                 # code blocks
body = re.sub(r"\]\([^)]*\)|https?://\S+|doi:\S+|10\.\d{4,}/\S+", "", body)  # links, DOIs
errors = []
NUM = re.compile(r"(?<![\w.])[-−]?(?:\d+(?:[.,]\d+)?|\.\d+)(?![\w])")
for ln, line in enumerate(body.splitlines(), 1):
    for m in NUM.finditer(line):
        raw = m.group().replace("−", "-").replace(",", ".")
        try:
            x = float(raw)
        except ValueError:
            continue
        if 1900 <= x <= 2030 and float(x).is_integer():
            continue
        if x in allowed or abs(x) in allowed:
            continue
        errors.append(f"line {ln}: number {m.group()} not found in results/data -> \"{line.strip()[:110]}\"")
    if STYLE and "—" in line:
        errors.append(f"line {ln}: em dash found (Maria's rule) -> \"{line.strip()[:110]}\"")

for e in errors:
    print("FAIL", e)
print("RESULT: FAILED" if errors else "RESULT: PASSED (every number traced to results/data" + (", no em dashes)" if STYLE else ")"))
sys.exit(1 if errors else 0)
