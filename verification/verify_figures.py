"""GATE 8: every figure is regenerated after the latest results, and every figure the manuscript uses exists.
Usage: python verification/verify_figures.py [06_manuscript/manuscript.qmd]
"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ms = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "06_manuscript" / "manuscript.qmd"
results = ROOT / "05_analysis" / "results" / "results.json"
FIG_EXT = {".png", ".pdf", ".svg", ".jpg", ".jpeg", ".tiff"}
errors = []

if not results.is_file():
    errors.append("05_analysis/results/results.json missing: run the analysis first")
figs = [p for p in (ROOT / "05_analysis" / "results").rglob("*") if p.suffix.lower() in FIG_EXT]
figs += [p for p in (ROOT / "04_risk_of_bias").glob("*") if p.suffix.lower() in FIG_EXT]
if results.is_file():
    t = results.stat().st_mtime
    for p in figs:
        if p.stat().st_mtime < t and "risk_of_bias" not in str(p):
            errors.append(f"{p.relative_to(ROOT)} is older than results.json: regenerate it")
if ms.is_file():
    text = ms.read_text(encoding="utf-8")
    refs = re.findall(r"!\[[^\]]*\]\(([^)\s]+)", text) + re.findall(r"include_graphics\(['\"]([^'\"]+)", text)
    for ref in refs:
        if not (ms.parent / ref).resolve().is_file():
            errors.append(f"manuscript uses missing figure: {ref}")
else:
    errors.append(f"manuscript {ms.name} not found")
for e in errors:
    print("FAIL", e)
print("RESULT: FAILED" if errors else f"RESULT: PASSED ({len(figs)} figures up to date, all manuscript figures exist)")
sys.exit(1 if errors else 0)
