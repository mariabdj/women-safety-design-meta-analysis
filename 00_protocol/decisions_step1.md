# Step 1 decisions (protocol)

**Status:** D1–D10 accepted by Maria on 2026-10-27 ("D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 I agree with your recom").

Each decision is fixed **before** any data are analysed. Once the protocol is registered, changing one becomes a reported deviation. Recommendations are justified by the documentation in `Documentation/` and the PCI RR guide. Maria decides.

| # | Decision | Options | Recommendation | Why |
|---|---|---|---|---|
| D1 | Test hypotheses, or only estimate effects? | (a) hypotheses for RQ1–RQ3 · (b) estimation only · (c) hypotheses for RQ1–RQ2, estimation for RQ3 | **(c)** | RQ1 and RQ2 have clear expected directions from theory and seed studies (features help; possibly more for women). RQ3 depends on design-quality ratings and will have few studies, so an estimate with its uncertainty is more honest than a yes/no test. PCI RR accepts both; the design table is mandatory once hypotheses are tested. |
| D2 | Smallest effect size of interest (SESOI) | g = 0.10 / 0.20 / 0.30 | **g = 0.20** for RQ1; **difference in g of 0.20** for RQ2 | 0.20 is the conventional "small" effect (Lakens 2013). Knabe et al.'s preregistration called d = 0.2 "medium" for CPTED effects on fear. Smaller effects would need far more studies than are likely to exist. We also report the minimal detectable effect given the actual number of studies. |
| D3 | Population | adults only · adults + adolescents (≥ 12) | **Adults (≥ 18) as main analysis; adolescents only in a sensitivity analysis** | Adolescents' fear differs (parental rules, school routes). Keeping them separate avoids mixing two populations. |
| D4 | Design features | the 6 from the project PDF | **Keep the 6, with written definitions:** lighting (illuminance, presence, quality); vegetation (density, height, maintenance); sightlines / openness / prospect (visibility, entrapment, escape routes); active frontages and mixed use (shops, windows, ground-floor activity); maintenance and incivilities (litter, graffiti, disrepair); presence of other people (people present, women present, activity) | These map onto the main theories (prospect–refuge, natural surveillance, broken windows) and onto the seed studies. Written definitions stop "feature drift" during screening. |
| D5 | Outcomes | perceived safety only · + fear of crime · + reassurance · + behavioural intention | **Perceived safety, fear of crime and reassurance (self-reported), analysed together, with outcome type as a moderator; behavioural intention excluded** | They measure the same feeling from different angles. Knabe et al. found little difference across fear dimensions. Behaviour (avoidance) is a different construct. |
| D6 | Study designs | experiments only · + quasi-experiments · + observational comparisons of places | **Experiments (photos, video, VR, field manipulations) and quasi-experiments (before/after, matched places). Cross-sectional surveys only if they compare defined places that differ in a feature; purely correlational ratings of "the neighbourhood" excluded** | Keeps the causal link "feature → feeling" credible while not losing field studies. |
| D7 | Languages and years | EN only · EN + FR · EN + FR + ES | **English and French, 1990–2026; other languages logged as "excluded: language" and counted** | You read both. Logging the others keeps the PRISMA flow honest about what was missed. |
| D8 | ASReview stopping rule | fixed % · consecutive irrelevant · combination | **Stop when ≥ 30% of records are screened AND the last 100 consecutive records were irrelevant; plus all records with "women/gender" in title or abstract are screened by hand regardless** | A combined rule is the standard safe practice (van de Schoot et al. 2021); the extra rule protects the key variable of this review. |
| D9 | PCI RR bias-control level | Level 3 · 2 · 1 | **Level 2, declared honestly** | We have already seen the *conclusions* of a few studies in their abstracts (e.g. Cui 2023, Jiang 2017, Mao 2023, Navarrete-Hernández 2026, Boomsma & Steg 2012) and Knabe et al.'s overall results. We have not extracted or computed any effect size. Level 2 = some key results observed, analyses not done. They will be listed in the protocol. Overstating the level would be a serious integrity problem. |
| D10 | Submission track and visibility | standard / scheduled; public / embargoed | **Standard track, public Stage 1, submitted by 25 November 2026** | The scheduled track would put the review date after the December–January closure. A public Stage 1 gives a dated record of the idea (priority) and something visible for the RePIC application. |

## Timeline to submission (backward from 1 December 2026)
| Dates | What | Who |
|---|---|---|
| 28 Oct – 10 Nov | Draft Introduction, Methods, design table, appendices | Drafting; Maria reads each section |
| 11 – 16 Nov | Search strings tested in each database; feasibility count of eligible studies (titles/abstracts only, no data extraction) | Run and logged; Maria checks |
| 17 – 21 Nov | Maria's full read; revisions; references verified | Both |
| 22 – 23 Nov | OSF project + deposit of the Stage 1 manuscript (P5) | Maria, guided |
| 24 – 25 Nov | PCI RR submission (P6) | Maria, guided |

## D11. Actual safety (crime against women), added 2026-10-27 at Maria's request
**Question raised:** besides *feeling* safer, which park and street features make women *actually* safer from crime?

**Feasibility check (logged in `feasibility/`):** OpenAlex, design × crime against women × evaluation = 277 records; titles read. Very few quantitative evaluations with women-specific crime outcomes, spread over very different settings (refugee camps, public transport, informal settlements). A 2025 systematic scoping review on exactly this question for green and blue spaces (Cleland, Coney, O'Kane & Hunter, *Cities & Health*, doi:10.1080/23748834.2025.2508053) screened 2,303 papers, found 8 interventions, and reports "the absence of urban green and blue space interventions to specifically prevent violence against women and girls".

| Option | Verdict |
|---|---|
| Separate meta-analysis of crime against women | **Not feasible**: almost no poolable studies; large extra work for an empty result |
| **Secondary question RQ4, inside the same review** | **Adopted** |

**RQ4 (secondary, inside this meta-analysis):** What is the effect of the six design features on women's *actual* safety (victimisation, sexual harassment, assaults, police-recorded or self-reported crime against women), and does it agree with their effect on women's perceived safety?
- Clarified with Maria on 2026-10-27: actual safety is part of **this** review, not a separate one. A study is eligible if it reports perceived safety **or** actual safety (or both) for women, for at least one of the six features.
- Same search and screening; outcome block widened with crime and harassment terms.
- Extraction adds: outcome type (perceived / actual), data source (survey, police records, observation), unit (person / place), measure and effect (rate ratio, counts before/after).
- Synthesis: SWiM (structured narrative) by default; random-effects meta-analysis of log rate ratios per feature when ≥ 3 comparable studies (same rule as RQ1). Actual-safety and perceived-safety effects are never pooled together (different units).
- Discussion: the "feeling safe vs being safe" gap and the evidence gap (Cleland et al. 2025; Welsh, Farrington & Douglas 2022 on lighting and crime without gender breakdown) are reported as findings.
- No hypothesis, no SESOI (estimation only).

**Status:** accepted in principle by Maria on 2026-10-27, with the clarification that actual safety is included in this meta-analysis (studies with actual-safety outcomes only are eligible). Final wording to be confirmed when she reads the protocol.


## Update to D7, 2026-10-27
Maria's decision: **no date limit** (all years; still English and French). Reason: in OpenAlex the 1990 limit removed only 233 of 12,810 records (1.8%), so it saved almost no work while needing a justification reviewers often question.
