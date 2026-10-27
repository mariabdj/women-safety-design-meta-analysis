# Step 0: Overlap search report

**Date of searches:** 27 October 2026 · **Question checked:** has anyone already done a meta-analysis (or systematic review) of how public-space design features affect women's perceived safety, and whether they change the women/men gap?

## 1. Where and how we searched (final version = v3)

| Source | How | Hits | Kept for screening |
|---|---|---|---|
| OpenAlex | Boolean, title + abstract, 4 strategies (below) | 68 / 346 / 1,606 / 3,858 | all |
| Semantic Scholar | Same Boolean strategies (bulk search) | 35 / 230 / 953 / 2,396 | all |
| OSF Registries | 8 plain-word queries (no Boolean support), registrations only | 1,601 registrations | 578 that are reviews |
| PubMed (connector) | Boolean with field tags | 15 | nothing new |
| SciSpace (connector) | Natural-language question | 10 shown | 1 new review + 3 primary studies |
| Scite (connector, trial) | Citation and retraction check of 13 seed papers | 13 | no retractions |
| Elicit (connector) | Not possible: free plan has no API access | n/a | n/a |
| PROSPERO (in Maria's Chrome) | "fear of crime" (all fields); "perceived safety" (title); "street lighting" OR lighting (title) | 14 / 3 / 21 | 2 registrations read in full |
| Google Scholar (in Maria's Chrome) | Query 1 (see `manual_checks_log.csv`) | about 3,570 (top 20 read) | 1 missed review found → search v3 |
| Google Scholar | Query 2 (full text) / Query 3 (title only) / extra title query | about 1,930 (top 20 read) / 0 / 11 | 2 more reviews noted; 1 meta-analysis not verifiable (site down) |

Strategies (blocks combined with AND, words inside a block with OR):
- **with_gender** = Review type AND Outcome AND Design AND Gender
- **without_gender** = Review type AND Outcome AND Design
- **ma_on_outcome** = (meta-analysis OR meta-analytic OR meta-regression) AND Outcome
- **women_outcome_no_design** = Review type AND Outcome AND Gender (added in v3)

Files: `overlap_search_log.csv` (v3), `overlap_search_log_v2.csv`, `overlap_search_log_v1.csv`; manual checks in `manual_checks_log.csv` and `connectors_log.csv`; raw answers in `raw/` (v3), `raw/v2/`, `raw/v1/`; code `overlap_search.py`.

## 2. Search validation (sensitivity test)

| Benchmark review | v1 | v2 | v3 |
|---|---|---|---|
| Lorenc et al. 2013 | found | found | found |
| Dubey, Bailey & Lee 2025 | missed ("narrative review") | found | found |
| Fotios, Unwin & Farrall 2015 | missed ("A review") | found | found |
| Collins 2016 | missed (no abstract in OpenAlex) | found | found |
| Te Braak & van Tienoven 2025 (added after Google Scholar) | missed | **missed** (no abstract in OpenAlex, no design word in title) | found |

v1 → v2: added the word `review`; added `ma_on_outcome`; OSF with plain words. v2 → v3: added `women_outcome_no_design`. All 5 benchmarks also survive screening stage 1.

## 3. Screening

- v3 unique records: **6,507** (v2: 2,711)
- Stage 1 (code rule, `screen_stage1.py`): **2,584 kept**, 3,923 removed (5 of 5 benchmarks kept)
- Stage 2: titles read: 1,176 (v2 set) + 1,408 (new in v3) → 52 + 32 = **84 candidates** (`stage2_candidates.csv`, `stage2_candidates_v3_new.csv`), abstracts read
- Full records read: OSF fba2v, 6wtv4, m7w5s; PROSPERO CRD42022378465, CRD42024565151; Te Braak 2025 abstract + introduction

## 4. The closest existing work

| # | Work | Type | Overlap | Why ours is different |
|---|---|---|---|---|
| 1 | **Knabe, Arui, Mertens, Nagin & van Gelder (2026)**, "Fear of Crime in Urban Environments. A Meta-Analysis of Physical Environment Interventions". OSF fba2v (registered 25 June 2025), OSF 6wtv4 (2026, not yet peer reviewed) | **Meta-analysis**, 47 studies, 9,955 respondents, 429 effect sizes | **High** on "design → fear of crime" | Gender only at study level: (a) study controlled for gender, n.s. (b = −0.25, p = .19); (b) % women in sample, n.s. (p = .20). **No pooled effect for women, no within-study women vs men comparison, no gap analysis.** Study-level % women is open to aggregation bias (ecological fallacy). |
| 2 | **Te Braak & van Tienoven 2025** (doi:10.1016/j.cities.2025.105907) | Narrative systematic review, 50 studies, conceptual framework | High on topic (women, perceived safety) | **No meta-analysis**; explicitly **excludes** studies comparing women and men (studies variation *within* women) |
| 3 | Lorenc et al. 2013 (doi:10.1186/2046-4053-2-30) | Systematic review, 47 studies, **no meta-analysis** | Medium | Narrative; interventions; not gender-split |
| 4 | Dubey, Bailey & Lee 2025 (doi:10.1016/j.cities.2024.105534) | Narrative review, 32 articles | Medium | No calculation |
| 5 | Xu 2024 (doi:10.62476/ndi83674) | Systematic review, 45 publications, female users of urban alleys | Medium | No meta-analysis |
| 6 | Steed & Jagarnath 2022, PROSPERO CRD42022378465 | Registered review (MPH), greenspace design and perceived safety | Medium | Green spaces only; meta-analysis only "if possible"; no planned gender analysis |
| 7 | Lizarraga, Castillo-Pérez & Grindlay 2024/2026 (PROSPERO CRD42024565151; doi:10.1016/j.wsif.2026.103353) | Systematic review, gender + insecurity + active transport | Low to medium | Bibliometric synthesis; outcome is walking/cycling |
| 8 | "Practices of Fear" (OSF m7w5s, 2025); "The gendered nature of fear" (2026, 42 studies) | Systematic reviews | Low | Fear-related behaviours / individual factors, not design effects |
| 9 | Jeong & Lee 2017, CPTED & fear of crime (doi:10.26470/jcssed.2017.8.2.155) | Meta-analysis of Korean studies | Medium (design → fear) | Korean literature only; no gender |
| 10 | Collins 2016 (doi:10.1016/j.jcrimjus.2016.06.004) | Meta-analysis of fear-of-crime factors | Low | Individual factors (gender as a main effect), not design |
| 11 | Fotios, Unwin & Farrall 2015; Jansson, Fors, Lindgren & Wiström 2013 (doi:10.1016/j.ufug.2013.01.005); Trop, Shoshany Tavory & Portnov 2023 (doi:10.1177/00139165231163550); Sreetheran & van den Bosch 2014 (doi:10.1016/j.ufug.2013.11.006) | Narrative / systematic reviews | Medium (one feature or setting each) | No pooling, no gender analysis |
| 12 | Zhai et al. 2026 (doi:10.1016/j.ufug.2026.129359); Samadi-Todar & Hami 2026 (GeoJournal 91:105); STEP UP thematic review 2023 (doi:10.3390/su152115636) | Scoping / systematic / thematic reviews | Medium | No meta-analysis |
| 13 | Qin, Van de Weghe & Huang 2025 (doi:10.1016/j.eiar.2025.107915) | Systematic review | Medium | No abstract in databases: full text to check in Step 2 |
| 14 | Eye-tracking & perceived security SR protocol (OSF dbv7g, 2025) | Registration | Low | Visual attention, not gender |
| 15 | O'Brien, Farrell & Welsh 2019, *Annual Review of Criminology* | Meta-analysis (neighbourhood disorder → fear of crime) | Medium (one feature: disorder) | No gender analysis reported in the snippet; full text to check in Step 2 |
| 16 | Noor & Iamtrakul 2024, *Public Transport* | Semi-systematic review, transit environments and women's fear | Medium | No meta-analysis; transport only |
| 17 | Niazi, Bayat, Abbaszadeh & Ashayeri 2018, "Meta-analysis of the factors affecting on women's fear of crime", *Societal Security Studies* 9(55):99–125 (sid.ir/paper/203294) | Meta-analysis, 16 Iranian correlational surveys, women only | Low | Abstract read (supplied by Maria, saved in `raw/close_matches/Niazi2018_abstract_from_sid.txt`): individual and social factors (education, income, age, trust, victimisation, media…); **no design features, no women vs men comparison**. Full text not retrievable (server down). |

**Bonus for Step 2 (primary studies to include):** Navarrete-Hernández, Schlesser & Luca 2026 (*Nature Cities*, "Urban design interventions reduce fear of crime in public spaces in gender-sensitive ways"); Navarrete-Hernández et al. 2025 (*Landscape and Urban Planning* 264:105460); Basu et al. 2021 (doi:10.1016/J.JTH.2021.101243); Başaran et al. 2026 (doi:10.1016/j.cities.2026.106873); Knabe et al.'s 134 references (`raw/close_matches/Knabe2026_References.md`).

## 5. Conclusion (to be confirmed by Maria)

1. A meta-analysis of **physical environment interventions and fear of crime now exists** (Knabe et al. 2026): the general question is no longer new.
2. The newest review on **women's** perceived safety (Te Braak 2025) is narrative and deliberately leaves out women vs men comparisons.
3. **No study found pools design effects separately for women, compares women and men within the same studies, or tests whether good design shrinks the gender gap.**
4. **Recommended angle:** a *gender-disaggregated* meta-analysis. Keep the 3 sub-questions; position the work between Knabe et al. (design effects, all people) and Te Braak & van Tienoven (women only, no numbers).
5. Risk for the protocol: Knabe et al. may publish soon; check their final paper before writing.

## 6. Remaining checks

- All planned manual checks done (Google Scholar 3 queries + 1 extra; PROSPERO 3 searches): see `manual_checks_log.csv`.
- Niazi et al. 2018: abstract obtained by Maria from sid.ir and assessed (row 17). Resolved; the full text could not be downloaded (server not responding), which is noted as a minor limitation.
