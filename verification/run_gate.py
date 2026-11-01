"""Runs every automatic check of one gate and appends the full outputs to VERIFICATION_LOG.md.
Usage (from Projet1_Meta-Analyse/):  python verification/run_gate.py <0-9>
Manual checks of the gate ([MARIA] approvals, reading figures, logic reads) must still be logged by hand.
"""
import datetime, pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
V = ROOT / "verification"
RS = r"C:\Program Files\R\R-4.6.1\bin\Rscript.exe"
PY = sys.executable
NAMES = {0: "Set-up", 1: "Protocol", 2: "Search", 3: "Screening", 4: "Extraction", 5: "Risk of bias",
         6: "Effect sizes", 7: "Analysis", 8: "Figures", 9: "Manuscript"}
GATES = {
    0: [[PY, V / "verify_structure.py"]],
    1: [[PY, V / "verify_sensitivity.py"],
        [PY, V / "verify_references.py", ROOT / "00_protocol" / "references.bib", ROOT / "none.qmd"]],
    2: [[PY, V / "verify_search_log.py"], [PY, V / "verify_source_registry.py"]],
    3: [[PY, V / "verify_prisma_counts.py"]],
    4: [[RS, V / "verify_extraction.R"], [PY, V / "verify_double_extraction.py"]],
    5: [[PY, V / "verify_rob.py"]],
    6: [[RS, V / "verify_extraction.R", "03_extraction/extraction.csv", "--complete"], [RS, V / "verify_effect_sizes.R"]],
    7: [[RS, V / "verify_effect_sizes.R"], [RS, V / "verify_model.R"]],
    8: [[PY, V / "verify_figures.py"]],
    9: [[PY, V / "verify_manuscript_numbers.py", "--style"], [PY, V / "verify_references.py"],
        [PY, V / "verify_public_release.py"]],
}

n = int(sys.argv[1])
log = ROOT / "VERIFICATION_LOG.md"
prev = log.read_text(encoding="utf-8") if log.is_file() else ""
run_no = len(re.findall(rf"^## GATE {n}:", prev, flags=re.M)) + 1
def last_run_passed(text, g):
    # the manual verdict is the last non-empty line of the last "## GATE g:" section, outside code fences
    text = re.sub(r"```.*?```", "", text, flags=re.S)   # script output first, so a heading inside it cannot fake a run
    runs = re.split(r"^(?=## )", text, flags=re.M)
    runs = [r for r in runs if r.startswith(f"## GATE {g}:")]
    if not runs:
        return False
    body = runs[-1].split("```")[0]   # an unclosed fence: ignore everything after it
    lines = [l.rstrip() for l in body.splitlines() if l.strip()]
    return bool(lines) and lines[-1] == "RESULT: PASSED"


if n > 0 and not last_run_passed(prev, n - 1):
    print(f"STOP: GATE {n-1} has no PASSED run in VERIFICATION_LOG.md (last line of its last run). "
          f"Per the protocol, step {n} must not start.")
    sys.exit(1)

out = [f"\n## GATE {n}: {NAMES[n]} | run {run_no} | {datetime.datetime.now():%Y-%m-%d %H:%M}\n"]
all_ok = True
for cmd in GATES[n]:
    if not pathlib.Path(cmd[1]).is_file():
        out.append(f"### {pathlib.Path(cmd[1]).name}: FAIL (script not found)\n")
        all_ok = False
        continue
    p = subprocess.run([str(c) for c in cmd], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    ok = p.returncode == 0
    all_ok &= ok
    out.append(f"### {pathlib.Path(cmd[1]).name}: {'PASS' if ok else 'FAIL'}\n```\n{(p.stdout + p.stderr).strip()}\n```\n")
if not GATES[n]:
    out.append("(no automatic script for this gate: manual checks only)\n")
out.append("Manual checks: (fill in: each manual item of the gate, with evidence)\n")
out.append(f"AUTOMATIC CHECKS: {'ALL PASSED' if all_ok else 'FAILED'}\n")
out.append("RESULT: (write PASSED only when automatic AND manual checks all pass)\n")
with log.open("a", encoding="utf-8") as f:
    f.write("".join(out))
print("".join(out))
sys.exit(0 if all_ok else 1)
