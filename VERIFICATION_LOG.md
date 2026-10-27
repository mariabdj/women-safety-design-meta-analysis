# Verification log: Project 1 meta-analysis

Rules: see META-ANALYSIS_WORKFLOW_GUIDE.md, Part A. Every gate run is appended below (never deleted).
A gate is PASSED only when all automatic AND manual checks pass. Run automatic checks with:
`python verification/run_gate.py <gate number>`

## GATE 0: Set-up | run 1 | 2026-10-27 11:05
### verify_structure.py: PASS
```
RESULT: PASSED (8 folders, 2 files present)
```
Manual checks: (fill in: each manual item of the gate, with evidence)
AUTOMATIC CHECKS: ALL PASSED
RESULT: (write PASSED only when automatic AND manual checks all pass)

## GATE 0: Set-up | run 2 | 2026-10-27 12:06
### verify_structure.py: PASS
```
RESULT: PASSED (8 folders, 2 files present)
```
Manual checks:
- [x] Overlap search logged (database, exact string, date, hits): `00_protocol/overlap_search/overlap_search_log.csv` (v2, 14 rows), `overlap_search_log_v1.csv` (v1, archived), `connectors_log.csv` (PubMed, SciSpace, Elicit, Scite). Raw API answers saved in `raw/` and `raw/v1/`.
- [x] Search validated: v1 found 1/4 benchmark reviews → strategy revised (reasons logged in `overlap_search.py` header) → v2 found 4/4 (Lorenc 2013, Dubey 2025, Fotios 2015, Collins 2016); 4/4 also survive screening stage 1.
- [x] Screening documented: 2,711 unique → 1,176 (stage 1, code rule in `screen_stage1.py`) → 52 candidates (stage 2, all titles read) → abstracts read → 3 full records read (OSF fba2v, 6wtv4, m7w5s).
- [x] Every close match listed with DOI/OSF id and why it differs: `00_protocol/overlap_search/OVERLAP_REPORT.md` section 4 (11 entries). Author names checked against OpenAlex: 1 error found and fixed ("Lee 2017" → "Jeong & Lee 2017").
- [x] Seed papers checked in Scite: 0 retractions/corrections/concerns among 13.
- [ ] PENDING (Maria, by hand): Google Scholar (3 queries) and PROSPERO (3 queries), see OVERLAP_REPORT.md section 6.
- [ ] PENDING [MARIA]: confirms the question is still original, with the gender-disaggregated angle (OVERLAP_REPORT.md section 5).
- [x] LEARNING_NOTEBOOK.md chapter for Step 0 written (sections 0 to 13 + 16 glossary terms). Its arithmetic re-computed by code from overlap_search_log.csv: 2022 + 1218 + 579 = 3819; 3819 − 2711 = 1108; 2711 − 1176 = 1535. All match.
AUTOMATIC CHECKS: ALL PASSED
RESULT: NOT YET PASSED (2 items pending for Maria, listed above)

## GATE 0: Set-up | run 3 | 2026-10-27 13:23
### verify_structure.py: PASS
```
RESULT: PASSED (8 folders, 2 files present)
```
Manual checks:
- [x] PROSPERO (in Maria's Chrome): "fear of crime" all fields 14; "perceived safety" title 3 (all fields 151, mostly clinical); "street lighting" OR lighting title 21. 2 registrations read in full (CRD42022378465, CRD42024565151): neither is a meta-analysis on our question. Log: `manual_checks_log.csv`.
- [x] Google Scholar (in Maria's Chrome; Maria solved 2 CAPTCHAs): query 1 ≈ 3,570 (top 20 read); query 2 ≈ 1,930 (top 20 read); query 3 = 0; extra title query = 11. Log: `manual_checks_log.csv`.
- [x] Google Scholar revealed a review missed by search v2 (Te Braak & van Tienoven 2025: no abstract in OpenAlex, no design word in title) → search revised to v3 (new strategy women_outcome_no_design; v2 archived in raw/v2/ and *_v2.csv) → v3: 6,507 unique, 5/5 benchmarks found and kept in stage 1 (2,584 kept) → 1,408 new titles read → 32 new candidates, abstracts read → no new meta-analysis.
- [x] Te Braak 2025 abstract + introduction read on ScienceDirect: narrative SR of 50 studies, no meta-analysis, explicitly excludes women vs men comparisons.
- [x] OVERLAP_REPORT.md updated (17 entries in section 4). Numbers re-checked by code from logs: OSF reviews v3 = 14+142+22+31+63+91+0+215 = 578; stage-2 candidates 52 + 32 = 84; titles read 1,176 + 1,408 = 2,584.
- [!] KNOWN LIMITATION: Niazi et al. 2018 "Meta-analysis of the factors affecting on women's fear of crime" could not be read (sid.ir error 502; absent from OpenAlex and Semantic Scholar). Content assumed, not verified. To check before the protocol is finalised (Step 1).
- [ ] PENDING [MARIA]: confirms the question is still original, with the gender-disaggregated angle (OVERLAP_REPORT.md section 5).
- [x] LEARNING_NOTEBOOK.md Step 0 chapter updated with the v3 revision and the manual checks.
AUTOMATIC CHECKS: ALL PASSED
RESULT: NOT YET PASSED (1 item pending for Maria + 1 known limitation to clear in Step 1)

### GATE 0 addendum | 2026-10-27
- [x] Known limitation resolved: Niazi et al. 2018 abstract obtained by Maria from sid.ir (saved: `00_protocol/overlap_search/raw/close_matches/Niazi2018_abstract_from_sid.txt`, kept private). 16 Iranian correlational surveys, women only, individual/social factors, no design features, no women vs men comparison → not an overlap. Full text not downloadable (server not responding).
- [x] Public repository created and pushed: https://github.com/mariabdj/women-safety-design-meta-analysis (39 files; `verify_public_release.py` PASSED before and after push; GitHub contributors: mariabdj only).
- [x] Pre-release check script fixed: it now checks only the files git will publish (it was reading ignored raw data) and every line in the git history; Windows encoding crash fixed. Re-tested with planted cases: problem in a tracked file → FAIL; problem only in history → FAIL; clean repo → PASS.
- [ ] PENDING [MARIA]: go / no-go on the gender-disaggregated angle and the PCI RR route.
RESULT: NOT YET PASSED (1 item pending for Maria)

## GATE 0: Set-up | run 4 | 2026-10-27 20:38
### verify_structure.py: PASS
```
RESULT: PASSED (8 folders, 2 files present)
```
Manual checks: (fill in: each manual item of the gate, with evidence)
AUTOMATIC CHECKS: ALL PASSED
RESULT: (write PASSED only when automatic AND manual checks all pass)
Manual checks (run 4):
- [x] All manual items of runs 2 and 3 carried over and still valid (overlap search v1→v3 logged; 5/5 benchmarks; PROSPERO and Google Scholar checks; 17 close matches assessed in OVERLAP_REPORT.md; Niazi et al. 2018 abstract assessed; known limitations listed).
- [x] [MARIA] Decision given in chat on 2026-10-27: "GO : je confirme l'angle désagrégé par genre, la voie PCI RR, le plan C et le travail en solo. On passe à l'étape 1."
- [x] Decisions recorded for Step 1: gender-disaggregated meta-analysis; Registered Report at PCI RR (Stage 1 before 2026-12-01); Plan C sources (guide Step 2b); solo author with documented safeguards.
- [x] LEARNING_NOTEBOOK chapter for Step 0 complete.
RESULT: PASSED

## STEP 1 started | 2026-10-27
- Entry gate: GATE 0 PASSED (run 4, 2026-10-27).
- PCI RR Stage 1 requirements read from the official guide and summarised: `00_protocol/PCI_RR_stage1_requirements.md`.
- Protocol skeleton created: `00_protocol/protocol.md` (all PRISMA-P / NIRO-SR areas present as sections).
- Ten protocol decisions prepared for the author: `00_protocol/decisions_step1.md` (pending).
- Data access so far (for the bias-control statement): abstracts and titles only, plus Knabe et al. (2026) posted materials; no effect size extracted or computed.
- 2026-10-27: D1–D10 accepted by the author. D11 added at the author's request (actual safety): feasibility search logged in `00_protocol/feasibility/` (OpenAlex: 1,062 records design × crime against women; 277 with an evaluation term; titles only). Cleland et al. (2025) scoping review found no intervention specifically preventing violence against women in green/blue spaces → RQ4 added as a secondary, descriptive question (SWiM; pooling only if ≥ 3 comparable studies). Extraction template: 3 columns added (outcome_type, outcome_source, unit_of_analysis).
- 2026-10-27: D11 clarified by the author: actual safety is part of this meta-analysis. Eligibility now = perceived safety and/or actual safety for women; RQ4 pooled (log rate ratios) per feature when ≥ 3 comparable studies, otherwise SWiM. Protocol, decisions file and design table (RQ4 row) updated.
- 2026-10-27: Protocol draft 1 written (`00_protocol/protocol.md`, appendices A and C). Inputs read: PCI RR Guide for Authors (sections 2.1, 2.6, 2.16, 2.17, 2.22, 2.28), one accepted Stage 1 meta-analysis with its reviews (rr.peercommunityin.org/articles/rec?id=51), "Ten simple rules for writing a Registered Report" (PMC9612468), NIRO-SR v1.1 tool (osf.io/c9wer, saved in Documentation/), PRISMA-P.
- 2026-10-27: Search development (`00_protocol/search_development/`). v1: S1 23,950 / S2 31,724 hits, too noisy. v2: S1 5,340; S2 3,080; S3 (French) 1,253; S4 5,481; union S1+S2+S4 = 12,577 (1990-2026). Benchmark recall (7 studies fixed before the test, titles only): 7/7 found by the union. S2 retrieves Cleland 2025 and doi:10.1080/17450101.2025.2598271 (no eligible actual-safety benchmark exists).
- 2026-10-27: Sensitivity analysis (`00_protocol/sensitivity/`): 112 scenarios computed in R; new script `verification/verify_sensitivity.py` recomputes them with scipy: 0 mismatches > 1e-6. Planted error (+0.001 on one MDE) caught: FAILED as expected.
- 2026-10-27: `verify_references.py` changed: (1) title compared with Crossref title with and without its subtitle (Crossref stores subtitles separately: 3 false failures); (2) first author compared with the first named person (group authors have no family name: 1 false failure). Re-tested with 5 planted errors (wrong title, wrong year, fake DOI, 2 wrong first authors): 5/5 caught. Protocol bibliography `00_protocol/references.bib`: 46 DOIs PASSED; 4 entries without DOI marked verified-manually. Collins 2016 removed (listed but not cited). `run_gate.py`: Gate 1 now runs verify_sensitivity.py and verify_references.py on the protocol bibliography.

## GATE 1: Protocol | run 1 | 2026-10-27 21:32
### verify_sensitivity.py: PASS
```
112 rows x 4 values checked, 0 mismatches
RESULT: PASSED
```
### verify_references.py: PASS
```
RESULT: PASSED (46 DOIs verified on Crossref, citations and bibliography match)
```
Manual checks: (fill in: each manual item of the gate, with evidence)
AUTOMATIC CHECKS: ALL PASSED
RESULT: (write PASSED only when automatic AND manual checks all pass)
Manual checks (Gate 1, run 1):
- [x] Every NIRO-SR Part A item (A1-A30) and PRISMA-P item mapped to a protocol section: `00_protocol/appendix_A_checklists.md`.
- [x] Search string runs without syntax error in OpenAlex, hit counts logged: `search_development/search_dev_log.csv` (v2, 2026-10-27).
- [x] Each sub-question maps to one pre-specified analysis and vice versa: protocol section 3 (design table rows H0, RQ1-RQ4) and 2.8.
- [ ] [MARIA] reads and approves the protocol, then deposits it on OSF (link and date to be logged). Open: the search strings for Semantic Scholar, PubMed and CORE are still to be adapted and tested (timeline 11-16 Nov); Appendix F (analysis code on simulated data) is still to be written.
RESULT: NOT YET PASSED (Maria's approval and OSF deposit pending; Appendix F and other-database strings pending)
- 2026-10-27: Appendix F written: `05_analysis/analysis.R` (RQ1-RQ4, H0, Holm, TOST decisions, MDE, CR2, small-study test, sensitivity analyses), `simulate_data.R`, `test_pipeline.R`. First small-k run crashed (rma.mv nlminb non-convergence with 3 studies): fallback added (second optimiser BFGS, then two-level model, reported per estimate) and written into protocol 2.8. `test_pipeline.R 60` (thresholds fixed in the script before the run): Test 1 (60 studies/feature) 17/17 PASS incl. verify_model.R PASSED; Test 2 (60 reps, 8 studies/feature) RQ1 lighting coverage 0.90, mean 0.451 (truth 0.45); RQ2 coverage 0.95, mean 0.245 (truth 0.25): PASS; Test 3 (SWiM and RQ4 branches) PASS. RESULT: PASSED. Output: `05_analysis/simulated/test_pipeline_output.txt`.
- 2026-10-27: Search strings for other databases (`search_other_dbs.py`, blocks moved to `search_blocks.py` so all databases use the same words). Semantic Scholar union 8,143 (7,817 in 1990-2026), 6/6 indexed benchmarks found (Navarrete-Hernandez 2025 not indexed). PubMed union 1,019 (1,005), no benchmark indexed in PubMed; positive control Lorenc 2013 found. First PubMed run failed on the union (HTTP 414, URL too long): switched to POST, rows of the failed run removed before rerun. CORE: string written (`strings_core.txt`, title/abstract fields only) but core.ac.uk unreachable from this machine (API timeout, browser refused): to test by hand or with the API key.
