"""GATE 0: the project folder structure exists. Usage: python verification/verify_structure.py"""
import pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FOLDERS = ["00_protocol", "01_search/raw", "02_screening", "03_extraction", "04_risk_of_bias",
           "05_analysis/results", "06_manuscript", "verification"]
FILES = ["VERIFICATION_LOG.md", "README.md"]

missing = [f for f in FOLDERS if not (ROOT / f).is_dir()] + [f for f in FILES if not (ROOT / f).is_file()]
for m in missing:
    print(f"FAIL missing: {m}")
print("RESULT: FAILED" if missing else f"RESULT: PASSED ({len(FOLDERS)} folders, {len(FILES)} files present)")
sys.exit(1 if missing else 0)
