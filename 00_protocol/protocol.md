# Urban design features and women's perceived and actual safety in public space: protocol for a gender-disaggregated systematic review and meta-analysis

**Stage 1 Registered Report (PCI Registered Reports, standard track)**

**Author:** Maria Boudjelal, independent researcher, Algiers, Algeria. ORCID [0009-0002-6434-784X](https://orcid.org/0009-0002-6434-784X)
**Version:** draft 1, 27 October 2026
**Bias-control level (PCI RR):** Level 2 (section 2.13)
**Materials:** code, search tests and logs at https://github.com/mariabdj/women-safety-design-meta-analysis; OSF project link added at deposit.

> Draft note (removed before submission): every claim about a cited study is checked against its full text during the author's read (17 to 21 November 2026). Decisions D1 to D11 are documented in `decisions_step1.md`.

---

## Abstract

Women feel less safe than men in public space, and this changes how, when and where they use cities. Planners often respond with design: more lighting, more open sightlines, trimmed vegetation, active ground floors, good maintenance and the presence of other people. A recent meta-analysis found that physical environment interventions reduce fear of crime on average, but gender was only tested at the study level, and no review has compared the responses of women and men to the same design features within the same studies. This Registered Report describes a systematic review and three-level meta-analysis of experimental and quasi-experimental studies that report results for women. For each of six design features, I will estimate (RQ1) the effect on women's perceived safety, (RQ2) whether this effect is larger for women than for men in the same studies, and (RQ3) whether the women-men gap in perceived safety is smaller in scenes with better overall design. A secondary question (RQ4) asks whether the same features reduce harm actually experienced by women (victimisation, harassment and crime against women) and whether this agrees with perceived safety. The smallest effect of interest is Hedges' g = 0.20. Hypotheses are tested with t-tests in three-level random-effects models and with equivalence tests, so that both positive and null results can be informative. The search covers English and French records from 1990 onwards in OpenAlex, Semantic Scholar, PubMed and CORE, plus theses, reports, open datasets and citation chasing.

---

## 1. Introduction

### 1.1 Why women's perceived safety in public space matters

Feeling unsafe in public space is not evenly shared. Across surveys and decades, women report more fear of crime than men, even though men are more often victims of most street crimes (Hale, 1996). One influential explanation is the "shadow of sexual assault" hypothesis: women's fear of any crime is raised by the fear of sexual violence that may come with it (Ferraro, 1996). This fear has costs of its own. It shapes which routes women take, whether they go out after dark, which jobs and services they can reach, and how freely they use parks and streets. Perceived safety is therefore an outcome that matters for equality in the city, not only a side effect of crime.

### 1.2 What design is thought to do

Several theories link the physical environment to feelings of safety. Prospect-refuge theory (Appleton, 1975) and its application to fear of crime (Fisher & Nasar, 1992) predict that people feel safer where they can see far (prospect), where potential offenders have few places to hide (low refuge for others) and where escape is easy (low entrapment). Natural surveillance ideas, from "eyes on the street" (Jacobs, 1961) to Crime Prevention Through Environmental Design (CPTED), predict that visibility, active frontages and the presence of other people reassure users because someone could see and help. Incivilities or "broken windows" accounts predict that litter, graffiti and disrepair signal a lack of social control and raise fear (Wilson & Kelling, 1982). Lighting is expected to act through several of these routes at night (Fotios et al., 2014).

If women's fear is partly a fear of sexual violence in places where help is out of reach, these same mechanisms might matter **more** for women than for men. Features that improve prospect, reduce hiding places and bring other people nearby would then reduce the women-men gap. But this is an assumption, not an established result.

### 1.3 What existing syntheses show and what they leave open

Several reviews summarise design and fear of crime. Lorenc et al. (2013) reviewed environmental interventions and fear of crime narratively, without pooling. Fotios et al. (2014) reviewed road lighting and pedestrian reassurance. Dubey et al. (2025) and te Braak and van Tienoven (2025) reviewed women's perceived safety in public places; the latter synthesised 50 studies narratively and focused on variation among women rather than on comparisons with men. Most recently, Knabe et al. (2026, preprint) meta-analysed 47 studies of physical environment interventions and fear of crime. In that analysis, gender entered only as study-level variables (whether a study controlled for gender, and the share of women in the sample), neither of which was a significant moderator.

A study-level share of women cannot answer whether design works differently for women. A sample with 60% women and one with 40% women can show the same average effect even if women and men respond very differently inside each study. Inferring individual-level differences from group-level averages is the ecological fallacy. The question needs **within-study** comparisons: women's and men's responses to the same stimuli, measured in the same way.

### 1.4 Feeling safe and being safe

Perceived safety and actual safety do not always move together. A well-lit, open park may feel safe and still be where harassment happens, and the reverse can also be true. Randomised field studies show that some design changes reduce crime, for example street lighting in New York City public housing (Chalfin et al., 2021) and the greening of vacant lots in Philadelphia (Branas et al., 2018), and lighting improvements have been meta-analysed for crime outcomes (Welsh & Farrington, 2008). However, these studies report crime overall, not crime against women. A recent scoping review found no green or blue space intervention designed specifically to prevent violence against women and girls (Cleland et al., 2025). I therefore include actual safety as a secondary, mostly descriptive question (RQ4). Showing whether this evidence exists, and whether it agrees with perceived safety, is useful in itself.

### 1.5 Aims, research questions and hypotheses

The review asks which public-space design features increase women's perceived safety, and whether they reduce the women-men safety gap. It examines six features, defined in section 2.1: (1) lighting, (2) vegetation, (3) sightlines and openness, (4) active frontages and mixed use, (5) maintenance and incivilities, and (6) presence of other people.

- **RQ1.** For each feature, what is the effect on women's perceived safety?
  - **H1** (one per feature, H1a to H1f): the feature increases women's perceived safety (pooled Hedges' g > 0).
- **RQ2.** For each feature, is the effect larger for women than for men in the same studies?
  - **H2** (one per feature, H2a to H2f): the effect for women exceeds the effect for men (difference in g > 0).
- **RQ3** (estimation, no hypothesis). Across features, is the women-men gap in perceived safety smaller in scenes with better overall design?
- **RQ4** (secondary, mostly descriptive). What is the effect of each feature on women's actual safety (victimisation, harassment, crime against women), and does it agree with the effect on perceived safety?

RQ2 and RQ3 are related but not the same. RQ2 asks, feature by feature, whether adding a feature raises women's safety more than men's. RQ3 takes each scene or place as a whole, scores how many of the six features are favourable in it, and asks whether the women-men gap is smaller where the score is higher. RQ3 can use studies that compare women and men across several scenes even when no single feature was manipulated.

---

## 2. Methods

Reporting follows PRISMA 2020 (Page et al., 2021) and PRISMA-S (Rethlefsen et al., 2021). The protocol follows PRISMA-P (Moher et al., 2015) and NIRO-SR Part A (Topor et al., 2023), mapped item by item in Appendix A. Synthesis without pooling follows SWiM (Campbell et al., 2020).

### 2.1 Eligibility criteria

| | Inclusion | Exclusion |
|---|---|---|
| **Population** | Adults (18 or older). Samples with adolescents are included if at least 80% are adults or if adult results are reported separately | Adolescent-only or child samples (kept for a sensitivity analysis only, section 2.10) |
| **Exposure** | At least one of the six design features, defined below, varied between conditions or places | Features that are not physical design (policing, CCTV, apps, campaigns, self-defence training) |
| **Comparator** | The same scene, route or place without, or with less of, the feature; or a matched place that differs in the feature | No comparison condition |
| **Outcome (primary)** | Self-reported perceived safety, fear of crime or reassurance, on any rating scale or as a proportion feeling safe | Behaviour or behavioural intention only (avoidance, route choice), physiological measures only |
| **Outcome (secondary, RQ4)** | Harm experienced by women: victimisation, sexual harassment, sexual assault, crime against women; from surveys, police records or systematic observation | Crime counts not broken down by victim sex, unless women's counts can be obtained (section 2.5) |
| **Study design** | Experiments (photos, video, virtual reality, field manipulations), quasi-experiments (before-after with or without control, matched places), and place-comparison surveys where defined places differ in a feature | Purely correlational ratings of one's "neighbourhood" as a whole; qualitative-only studies; reviews (used for citation chasing only) |
| **Must report** | Results for women separately (perceived safety: ideally women and men), or data allowing them to be computed (section 2.5) | Pooled results only, after the author contact procedure fails |
| **Language and dates** | English or French; 1 January 1990 to the date of the search | Other languages (counted and listed as "excluded: language") |

A study needs at least one eligible outcome: perceived safety, actual safety, or both.

**Feature definitions** (used at screening and coding):
1. **Lighting:** presence, amount (illuminance), uniformity, colour or type of artificial light.
2. **Vegetation:** amount, density, height or placement of trees, shrubs and planting, including their trimming.
3. **Sightlines and openness:** how far and how widely one can see; hiding places (concealment), entrapment and escape routes.
4. **Active frontages and mixed use:** shop fronts, windows, entrances and ground-floor activity facing the space; mixed land use.
5. **Maintenance and incivilities:** litter, graffiti, vandalism, disrepair, abandoned buildings.
6. **Presence of other people:** number, type (for example women, families) or activity of other people present.

**Gender.** I use the participants' reported gender or sex as given in each study and record which was measured. Most studies report two categories; results for other genders are extracted where reported and described narratively. This is a limitation of the evidence, not a choice of this review.

### 2.2 Information sources and search strategy

**Databases** (no date or language filter at the interface; both applied at screening):
- OpenAlex (title and abstract search through the API), Semantic Scholar (bulk search API), PubMed, and CORE (open repositories, includes theses and reports; title search through its website).
- I do not have institutional access to Scopus or Web of Science. OpenAlex indexes a broad and multidisciplinary set of records, and citation chasing (below) is used to catch what keyword searches miss.

**Search blocks.** The final strategy is the union of three combinations (full syntax in Appendix B):
- **S1** = design feature terms AND perceived safety terms
- **S2** = design feature terms AND actual safety terms AND women/gender terms
- **S4** = perceived safety terms AND women/gender terms AND place terms (catches gender-focused studies whose abstract names no specific feature)
- plus French outcome terms (S3) run in the same sources.

**Development and test.** Version 1 of the strings (27 October 2026) used single generic words (street, park, trees, disorder, refuge, crime) and returned about 24,000 and 32,000 records for S1 and S2, mostly irrelevant ("disorder" retrieved mental disorders and "refuge" retrieved shelters). Version 2 uses precise phrases. In OpenAlex on 27 October 2026, version 2 returned 5,340 (S1), 3,080 (S2) and 5,481 (S4) records; the union returned 12,577 records for 1990 to 2026, and S3 returned 1,253 records. Before running the test I fixed a set of seven benchmark primary studies likely to be eligible, chosen from titles only (Adamczak et al., 2025; Baran et al., 2018; Başaran et al., 2026; Basu et al., 2021; Boomsma & Steg, 2012; Brands et al., 2024; Navarrete-Hernández et al., 2025). The union retrieved 7 of 7. The same blocks, translated to each database's syntax (Appendix B), returned 7,817 records in Semantic Scholar (1990 to 2026), whose union retrieved all 6 benchmarks indexed there (Navarrete-Hernández et al., 2025, is not indexed in Semantic Scholar), and 1,005 records in PubMed. None of the benchmarks is indexed in PubMed, so recall there was checked with a positive control instead: Lorenc et al. (2013), which is indexed, is retrieved. I re-ran every string myself in my own browser on 27 October 2026, through the public search pages: all 14 counts for OpenAlex, Semantic Scholar and PubMed were identical to the scripted runs (record in `search_development/author_check_2026-10-27.csv`). CORE is searched through its public website, because API access is not available to me. Tests on 27 October 2026 showed that the website mis-reads queries that mix title and abstract fields, and queries that join whole strategies with OR (the union of S1, S2 and S4 returned 3 records). Searches limited to the title field work: S1 returned 811 records, S2 76, S3 366 and S4 646. In CORE, S1, S2, S3 and S4 are therefore run separately on titles, exported, and merged with the other sources at deduplication. Only 2 of the 7 benchmark studies are indexed in CORE, so CORE is a supplementary source, mainly for theses and reports. No known primary study of actual safety for women was available as a benchmark, which is itself consistent with Cleland et al. (2025); S2 did retrieve that review and a 2025 study on sexual violence and the built environment. Logs: `search_development/`.

**Other sources:**
- **Google Scholar:** the first 200 results of one simplified query, screened by hand.
- **Theses:** HAL and theses.fr, DART-Europe, OATD, CORE.
- **Grey literature and reports:** UN Women Safe Cities and Safe Public Spaces publications, the CIE (International Commission on Illumination) proceedings, and the reports cited by included studies.
- **Preprints:** OSF Preprints, PsyArXiv and SocArXiv (through the OSF search).
- **Citation chasing:** backward and forward citations of every included study and of the main earlier reviews (Cleland et al., 2025; Dubey et al., 2025; Fotios et al., 2014; Knabe et al., 2026; Lorenc et al., 2013; te Braak & van Tienoven, 2025), using the Lens.org database through the `citationchaser` R package.

For each search I log the date, source, interface, exact string, filters and number of records, at the time of the search. Raw exports are kept unchanged.

**Timing and update.** The full search runs only after in-principle acceptance. If more than six months pass between that search and the start of the analysis, the database searches are re-run and new records are screened with the same rules.

### 2.3 Study selection

**Records management.** Records are imported into Zotero, then deduplicated by DOI, then by normalised title and year (`synthesisr` R package), and the result is checked by hand for near-duplicates.

**Title and abstract screening.** I use ASReview (van de Schoot et al., 2021), an open-source tool that ranks records by likely relevance as screening goes on.
- **Stopping rule:** I stop when at least 30% of records have been screened **and** the last 100 consecutive records were irrelevant.
- In addition, every record with a women or gender term in its title or abstract is screened, whatever its rank.

**Full-text screening.** Each excluded full text receives one reason from a fixed list, applied in this order: not English or French; not a primary study; no eligible design; no eligible feature; no eligible outcome; no results for women (after author contact); duplicate sample; no usable data.

**Independent second screening (single author).** I am the only author of this review. To protect against my own errors and biases, screening is checked in two independent ways:
1. An AI model screens 100% of titles and abstracts and 100% of full texts, blind to my decisions, using only the written criteria and the screening manual (Appendix C). The tool, model version and full prompt are archived.
2. I re-screen a random 20% of records myself at least one week later, without seeing my first decisions.

Agreement is reported as Cohen's κ for both comparisons (McHugh, 2012). If κ is below 0.60, I re-read the disagreements, clarify the manual and re-screen the affected set. I resolve every disagreement against the full text, and each decision and its reason is kept in a decision log.

### 2.4 Data extraction

**Unit.** One row per effect size, with study, sample, condition and outcome identifiers (variables in Appendix C). The extraction sheet is piloted on three studies and then frozen; later changes are reported as deviations.

**Extracted information:**
- Study: authors, year, country, setting, design, stimulus type (photo, video, VR, field), time of day.
- Sample: N per group and condition, by gender; age.
- Features: each manipulated feature, coded with the definitions in 2.1. For RQ3, the number of the six features judged favourable in each scene or place (0 to 6), coded from the stimulus descriptions and images.
- Outcomes: measure, scale range, direction (higher = safer or higher = more fear).
- Results: means, SDs or SEs (type recorded), test statistics, proportions, counts, and the page, table or figure each number comes from.

**Double extraction (single author).** I extract all data. The AI model independently re-extracts 100% of the numbers from the full texts without seeing my sheet. A script compares the two, and every difference is resolved by me against the source.

**Figures.** When numbers appear only in a figure, I read them with WebPlotDigitizer (Drevon et al., 2016), twice and independently, and check that the digitised values reproduce any number printed in the text.

### 2.5 Missing data and evidence beyond journal articles

Many studies measured women and men but reported only the total. To recover these results, I use, in this order:
1. **The study's own open data** (OSF, Zenodo, Figshare, Dryad, journal supplements). I compute women's and men's results myself from participant-level data.
2. **Theses, conference papers and reports** of the same study, which often keep the full tables.
3. **Author contact:** one email and one reminder after 14 days; requests close 28 days after the first email. Every contact is logged with dates and outcome.

A non-article source is used only if it meets five rules:
1. It is traceable (DOI or stable official URL, access date recorded).
2. It is published by a journal, an official statistics body, a recognised data archive or the study's own authors.
3. It is documented (codebook or methods).
4. Its licence allows reuse, or the authors give written permission.
5. It passes a **sanity check**: from the data I reproduce at least one number that the source itself published (a mean, a percentage or a sample size). If the numbers do not match, the source is not used and the reason is logged.

All such sources are listed in a source register (Appendix E). Large official surveys, such as the European Social Survey item on feeling safe walking alone after dark, are used only for context in the discussion and are never pooled with experimental effects.

If the data needed for an effect size cannot be obtained, the study is described narratively and counted in the PRISMA flow.

### 2.6 Risk of bias

I adapt the revised JBI critical appraisal tool for quasi-experimental studies (Barker et al., 2024) to six items, each rated yes, no or unclear with a supporting quote or page:
1. The sample is described and its recruitment is reported.
2. Conditions are comparable except for the feature (same scene, time and viewpoint, or matched places).
3. Order of conditions is randomised or counterbalanced (within-subject designs), or allocation is random (between-subject designs).
4. The safety measure is valid: an established scale or a clearly worded item about safety or fear.
5. Outcome data are complete, or missing data are explained.
6. The analysis is appropriate and the reported statistics are internally consistent.

**Overall rating rule:** **high** risk if item 2 or item 4 is "no"; **low** if all six items are "yes"; **some concerns** otherwise. The same double-rating procedure as for extraction applies. For RQ4, item 2 becomes "comparable control area or pre-period" and item 4 becomes "harm recorded in the same way before and after".

### 2.7 Effect sizes

All effect sizes are computed by script, never by hand. They are checked by an independent re-implementation of the formulas (agreement required within 10⁻⁸). Where a study reports its own d or g, our value is also compared with it.

**Direction.** g > 0 always means "safer". Scales that measure fear are reversed.

**Perceived safety (RQ1, RQ2):**
- **Between-subject designs:** standardised mean difference with the small-sample correction J = 1 - 3/(4df - 1) (Hedges' g), using `escalc(measure = "SMD")` in metafor.
- **Within-subject designs:** standardised mean change using the control-condition SD (Morris, 2007), `escalc(measure = "SMCR")`. When the correlation between conditions is not reported, I use r = 0.5, with 0.3 and 0.7 as sensitivity analyses.
- **Odds ratios** (proportion feeling safe): d = ln(OR) × √3/π.
- **Only t, F or p reported:** standard conversions, with the method recorded.

**Gap (RQ3):** the standardised mean difference between women's and men's ratings of the same scene or place (positive = women feel less safe than men).

**Actual safety (RQ4):**
- **Counts before and after, with a control area:** log relative effect, ln[(a·d)/(b·c)], where a and b are the control area counts before and after, and c and d are the treated area counts before and after. Its variance is 1/a + 1/b + 1/c + 1/d (Welsh & Farrington, 2008). A value above 0 means less harm in the treated area.
- **Prevalence from surveys:** log odds ratio.
- The two metrics are pooled only separately. They are never pooled with perceived-safety g values.

### 2.8 Synthesis

**When to pool.** A feature's effect is pooled only when at least 3 independent studies contribute. Otherwise the results are summarised following SWiM: grouping by feature, direction of each effect, and a vote count of direction with its sign-test p-value, never presented as an effect size.

**Model.** Studies often report several effects (several scenes, outcomes or samples), which are not independent. I use a three-level random-effects model with effect sizes nested in studies (Assink & Wibbelink, 2016), estimated by restricted maximum likelihood with t-tests and k − 1 degrees of freedom:

`rma.mv(yi, vi, random = ~ 1 | study_id / es_id, test = "t")` in metafor (Viechtbauer, 2010).

When at least 10 studies contribute, inference is repeated with cluster-robust (CR2) standard errors (Pustejovsky & Tipton, 2017).

**Convergence fallback.** If a three-level model does not converge with the default optimiser, it is refitted with a second optimiser (BFGS). If it still fails, a two-level model with study-level random effects is used. The model actually used is reported for every estimate. This rule was written after the pipeline test on simulated data (Appendix F) showed that, with only 3 studies, the default optimiser can fail.

**Analyses for each question:**
- **RQ1 (H1a to H1f):** one model per feature, women's effects only.
- **RQ2 (H2a to H2f):** one model per feature, using only studies that report both women's and men's effects, with gender as moderator (`mods = ~ gender`). The coefficient is the women-minus-men difference in g.
- **RQ3:** gap effects (2.7) regressed on the scene's favourable-feature score (0 to 6), in a three-level model, if at least 10 studies report gaps for at least two scenes. A negative slope means a smaller gap in better-designed scenes. Estimation only: I report the slope with its 95% CI.
- **RQ4:** for each feature and metric, a random-effects model of log relative effects when at least 3 comparable studies exist, otherwise SWiM. I also cross-tabulate, feature by feature, the direction of the perceived-safety effect against the direction of the actual-safety effect.

**Reported for every model:** number of studies and effect sizes, N, pooled estimate, 95% CI, 95% prediction interval (IntHout et al., 2016), τ² at each level, I² at each level (Higgins & Thompson, 2002) and p.

**Multiple testing.** H1a to H1f form one family of six tests, and H2a to H2f another. Within each family, p-values are adjusted with the Holm method.

### 2.9 Decision rules and sensitivity of the tests (sampling plan)

**Smallest effect size of interest (SESOI).** g = 0.20 for RQ1 and a difference in g of 0.20 for RQ2. This is the conventional "small" standardised effect (Lakens, 2013). It is also roughly the size below which a design change would hardly justify its cost for users. Smaller effects would need many more studies than are likely to exist.

**Decision rule for each H1 and H2:**
- **Supported:** the Holm-adjusted two-sided test is significant at α = .05 and the estimate is positive.
- **Disconfirmed (no meaningful effect):** both one-sided equivalence tests against ±0.20 are significant at α = .05, so the 90% CI lies entirely inside (−0.20, 0.20) (Lakens et al., 2018).
- **Opposite direction:** significant and negative.
- **Inconclusive:** anything else. This is reported as such, with the minimal detectable effect for the observed number of studies.

**Sensitivity analysis.** I cannot choose how many studies exist, so the sampling plan is a sensitivity analysis: for a given number of studies k, what is the smallest pooled effect I can detect? I computed this for a random-effects t-test (Hedges & Pigott, 2001; Valentine et al., 2010), counting one effect per study, which is conservative (results in `sensitivity/`, checked by an independent Python implementation).

Two typical study sizes:
- **Within-subject:** 60 women rating both conditions, r = 0.5, giving a sampling variance of about 0.017.
- **Between-subject:** 40 women per condition, giving about 0.05.

Heterogeneity was set at I² = 0, 25, 50 and 75%.

| Scenario (I² = 50%) | k for 80% power at g = 0.20 | Minimal detectable g with k = 10 (80% power) |
|---|---|---|
| RQ1, within-subject studies | 9 | 0.18 |
| RQ1, between-subject studies | 22 | 0.31 |
| RQ2, within-subject studies | 16 | 0.26 |
| RQ2, between-subject studies | 42 | 0.45 |

Most experiments in this field use within-subject ratings of images or virtual scenes. On that basis, I expect adequate sensitivity at the SESOI for RQ1 for the best-studied features: lighting is by far the most frequent intervention in the most recent meta-analysis (Knabe et al., 2026). I expect limited sensitivity for RQ2 and for the less-studied features. This is why the decision rule has an explicit "inconclusive" outcome and why the minimal detectable effect is reported for each test. A well-documented inconclusive result is still informative: it shows how much evidence is missing for women.

### 2.10 Heterogeneity, publication bias and sensitivity analyses

**Moderators** (exploratory, only for features with at least 10 studies):
- stimulus type (photo, video, VR, field);
- time of day (day, night);
- outcome type (perceived safety, fear of crime, reassurance);
- region (Global North, Global South);
- design (within, between);
- risk of bias.

**Small-study effects and publication bias** (only for features with at least 10 studies):
- Funnel plot.
- Egger-type regression test inside the three-level model, using the modified precision √((n₁ + n₂)/(n₁n₂)) as moderator (Egger et al., 1997; Pustejovsky & Rodgers, 2019; Rodgers & Pustejovsky, 2021). A significant result is read as "small-study effects", which can have causes other than publication bias.
- As a sensitivity analysis, a three-parameter selection model on study-level averaged effects.

**Sensitivity analyses** (all features with pooled results):
- leave-one-study-out;
- excluding high risk-of-bias studies;
- r = 0.3 and r = 0.7 for within-subject effects;
- excluding data obtained from authors or open datasets;
- two-level instead of three-level models;
- adding adolescent samples.

Conclusions are labelled "robust" if the decision for H1 or H2 does not change across these analyses.

### 2.11 Outcome-neutral checks

These checks do not depend on the answers to RQ1 to RQ4. They show whether the data can answer the questions at all.
1. **Positive control (gender gap):** in the control or baseline conditions of the included studies, women should report lower perceived safety than men. This is one of the most consistent findings in the field (Hale, 1996). I estimate the pooled baseline gap (women minus men) in a three-level model. If the gap is not negative (95% CI includes 0 or is above 0), the included measures or samples may not capture gendered fear, and RQ2 and RQ3 results will be interpreted as uninformative rather than as evidence of no difference.
2. **Ceiling and floor:** conditions whose mean lies within 10% of either end of the scale are flagged, and the analyses are repeated without them.
3. **Search sensitivity:** the final search must retrieve all seven benchmark studies and every eligible study among the seeds listed in 2.13. Any miss leads to a revised string, a re-run and a logged deviation.
4. **Data quality:** screening κ ≥ 0.60 for both comparisons (2.3); 100% agreement between the two extractions after resolution; effect sizes reproduced by two independent implementations.

### 2.12 Software and reproducibility

- **R:** metafor, clubSandwich, meta (independent cross-check of pooled estimates), esc, robvis, PRISMA2020, synthesisr and citationchaser.
- **Python:** API searches and verification scripts.
- **Other:** ASReview for screening; Zotero for references.

All code, logs and verification scripts are public on GitHub and will be archived on OSF and Zenodo with a DOI. Every number in the Stage 2 manuscript will be generated by code from a results file.

### 2.13 Bias control and data-access statement

This review uses existing studies, so it cannot reach Level 6. I declare **Level 2**: some evidence that will be used has been accessed and partly observed, but key variables have not been extracted or analysed. Specifically, before this submission:
- **Seed and benchmark studies:** I read the titles and abstracts of seed studies listed in my project plan (Boomsma & Steg, 2012; Cui et al., 2023; Jiang et al., 2017; Mao et al., 2023; Navarrete-Hernández et al., 2021; Portnov et al., 2020), whose abstracts state some of their conclusions. I also saw the title of Navarrete-Hernández et al. (2026), which states a conclusion. Full texts of Navarrete-Hernández et al. (2021) and Portnov et al. (2020) are stored in the project folder as background reading.
- **Knabe et al. (2026):** I read the pooled results and gender moderator tests of this preprint.
- **No extraction or computation:** I have not extracted or computed any effect size, opened any participant-level dataset, or run any analysis of the planned outcomes.

The date on which each dataset or full text is first opened for extraction will be logged. I am not an author of any study likely to be included.

### 2.14 Deviations

Any change after in-principle acceptance will be:
1. dated and justified in a deviations log;
2. reported in the Stage 2 manuscript;
3. approved by the recommender in advance if it is substantial.

Analyses not listed here will be labelled exploratory.

### 2.15 Timeline

| Date | Milestone |
|---|---|
| 25 November 2026 | Stage 1 submission |
| After in-principle acceptance (expected early 2027, given the platform's December to mid-January closure) | Searches and screening, about 6 weeks |
| Following 6 weeks | Extraction, risk of bias and author contact |
| Following 4 weeks | Analysis and Stage 2 manuscript |

---

## 3. Study design table

| Question | Hypothesis | Sampling plan | Analysis plan | Rationale for deciding the sensitivity of the test | Interpretation given different outcomes | Theory that could be shown wrong |
|---|---|---|---|---|---|---|
| Outcome-neutral check: do women report less safety than men at baseline? | H0: pooled baseline gap (women minus men) < 0 | All included studies with women's and men's baseline data | Three-level model of baseline gap effects; 95% CI | Established finding (Hale, 1996); no SESOI needed, only direction | Negative CI: measures capture gendered fear, RQ2 and RQ3 interpretable. Otherwise: RQ2 and RQ3 reported as uninformative | None (quality check) |
| RQ1: For each feature, what is its effect on women's perceived safety? | H1a to H1f: g > 0 for women | All eligible studies per feature; pooled only if k ≥ 3; sensitivity: k = 9 (within) to 22 (between) studies give 80% power at g = 0.20 with I² = 50% | Per feature, three-level REML model, t-test (k − 1 df), Holm correction across six features; equivalence test (TOST) against ±0.20; CR2 check if k ≥ 10 | SESOI g = 0.20: conventional small effect, practical relevance for design budgets; minimal detectable effect reported for observed k | Significant and positive: feature supported for women. Equivalent: no meaningful effect. Significant and negative: feature lowers women's safety. Otherwise inconclusive | Prospect-refuge, natural surveillance and incivilities accounts, as applied to women |
| RQ2: Is the effect larger for women than for men? | H2a to H2f: g(women) − g(men) > 0 | Studies reporting both genders per feature, k ≥ 3; sensitivity: k = 16 (within) to 42 (between) for 80% power at 0.20 | Three-level model with gender moderator; Holm correction; TOST against ±0.20 | Same SESOI as RQ1 applied to the difference | Positive: feature reduces the gap. Equivalent: works similarly for both. Negative: helps men more. Otherwise inconclusive | "Shadow of sexual assault" prediction that surveillance and prospect features matter more for women |
| RQ3: Is the gap smaller in better-designed scenes? | None (estimation) | Studies with gap data for ≥ 2 scenes; analysis only if k ≥ 10 | Three-level meta-regression of gap on favourable-feature score (0 to 6); slope and 95% CI | Precision reported (CI width) | Negative slope with CI below 0: gap smaller in better scenes. CI including 0: no clear evidence; the width tells how much is ruled out | Same as RQ2, at the level of whole scenes |
| RQ4: Does each feature reduce harm actually experienced by women, and does this agree with perceived safety? | None (estimation, secondary) | All eligible studies; pooled per feature and metric only if k ≥ 3, otherwise SWiM | Random-effects model of log relative effects or log odds ratios; direction cross-table with RQ1 | Precision reported; expected k small (Cleland et al., 2025) | Agreement: design that reassures women also protects them. Disagreement: feeling and being safe diverge, a warning for design guidance. No studies: evidence gap documented | CPTED claim that the same features reduce both fear and crime, for women |

---

## 4. Statements

- **Data, code and materials:** all search logs, code and verification scripts are public at https://github.com/mariabdj/women-safety-design-meta-analysis, and will be archived on OSF with a DOI. Extracted data will be public at Stage 2 under CC BY 4.0; code is under the MIT licence.
- **Ethics:** not required. This is a secondary analysis of published, anonymised results. Open datasets are used under their licences.
- **Statement on tools used:** inserted in the deposited manuscript, as required by the PCI RR Guide for Authors (section 2.28).
- **Funding:** none.
- **Competing interests:** none.
- **Author contributions (CRediT):** Maria Boudjelal: conceptualisation, methodology, software, investigation, data curation, formal analysis, writing (original draft, review and editing), visualisation, project administration.

---

## References

Adamczak, R., Vieira, L., Joie la Marle, C., & Blaison, C. (2025). The spatio-affective determinants of gender discrepancy in mobility experience. *Journal of Environmental Psychology, 107*, 102752. https://doi.org/10.1016/j.jenvp.2025.102752
Appleton, J. (1975). *The experience of landscape*. Wiley.
Assink, M., & Wibbelink, C. J. M. (2016). Fitting three-level meta-analytic models in R: A step-by-step tutorial. *The Quantitative Methods for Psychology, 12*(3), 154-174. https://doi.org/10.20982/tqmp.12.3.p154
Baran, P. K., Tabrizian, P., Zhai, Y., Smith, J. W., & Floyd, M. F. (2018). An exploratory study of perceived safety in a neighborhood park using immersive virtual environments. *Urban Forestry & Urban Greening, 35*, 72-81. https://doi.org/10.1016/j.ufug.2018.08.009
Barker, T. H., et al. (2024). The revised JBI critical appraisal tool for the assessment of risk of bias for quasi-experimental studies. *JBI Evidence Synthesis*. https://doi.org/10.11124/JBIES-23-00268
Başaran, et al. (2026). Where the station ends and surroundings begin: A holistic gender perspective on perceived safety. *Cities*, 106873. https://doi.org/10.1016/j.cities.2026.106873
Basu, et al. (2021). The unequal gender effects of the suburban built environment on perceptions of security. *Journal of Transport & Health*, 101243. https://doi.org/10.1016/j.jth.2021.101243
Boomsma, C., & Steg, L. (2012). Feeling safe in the dark: Examining the effect of entrapment, lighting levels, and gender on feelings of safety and lighting policy acceptability. *Environment and Behavior*. https://doi.org/10.1177/0013916512453838
Branas, C. C., et al. (2018). Citywide cluster randomized trial to restore blighted vacant land and its effects on violence, crime, and fear. *PNAS*. https://doi.org/10.1073/pnas.1718503115
Brands, J., Jansen, J. M., van Doorn, J., & Spithoven, R. (2024). Measuring and explaining situational fear of crime. *The British Journal of Criminology*. https://doi.org/10.1093/bjc/azae072
Campbell, M., et al. (2020). Synthesis without meta-analysis (SWiM) in systematic reviews: Reporting guideline. *BMJ, 368*, l6890. https://doi.org/10.1136/bmj.l6890
Chalfin, A., Hansen, B., Lerner, J., & Parker, L. (2021). Reducing crime through environmental design: Evidence from a randomized experiment of street lighting in New York City. *Journal of Quantitative Criminology*. https://doi.org/10.1007/s10940-020-09490-6
Cleland, C., Coney, et al. (2025). Urban green and blue space interventions to prevent violence against women and girls: A systematic scoping review. *Cities & Health*. https://doi.org/10.1080/23748834.2025.2508053
Cui, et al. (2023). Analysing gender differences in the perceived safety from street view imagery. *International Journal of Applied Earth Observation and Geoinformation*, 103537. https://doi.org/10.1016/j.jag.2023.103537
Drevon, D., Fursa, S. R., & Malcolm, A. L. (2016). Intercoder reliability and validity of WebPlotDigitizer in extracting graphed data. *Behavior Modification*. https://doi.org/10.1177/0145445516673998
Dubey, S., Bailey, A., & Lee, J. (2025). Women's perceived safety in public places and public transport: A narrative review of contributing factors and measurement methods. *Cities*, 105534. https://doi.org/10.1016/j.cities.2024.105534
Egger, M., Davey Smith, G., Schneider, M., & Minder, C. (1997). Bias in meta-analysis detected by a simple, graphical test. *BMJ, 315*, 629-634. https://doi.org/10.1136/bmj.315.7109.629
Ferraro, K. F. (1996). Women's fear of victimization: Shadow of sexual assault? *Social Forces, 75*(2), 667-690. https://doi.org/10.1093/sf/75.2.667
Fisher, B. S., & Nasar, J. L. (1992). Fear of crime in relation to three exterior site features: Prospect, refuge, and escape. *Environment and Behavior, 24*(1), 35-65. https://doi.org/10.1177/0013916592241002
Fotios, S., Unwin, J., & Farrall, S. (2014). Road lighting and pedestrian reassurance after dark: A review. *Lighting Research & Technology*. https://doi.org/10.1177/1477153514524587
Hale, C. (1996). Fear of crime: A review of the literature. *International Review of Victimology, 4*(2), 79-150. https://doi.org/10.1177/026975809600400201
Hedges, L. V., & Pigott, T. D. (2001). The power of statistical tests in meta-analysis. *Psychological Methods, 6*(3), 203-217. https://doi.org/10.1037/1082-989X.6.3.203
Higgins, J. P. T., & Thompson, S. G. (2002). Quantifying heterogeneity in a meta-analysis. *Statistics in Medicine, 21*, 1539-1558. https://doi.org/10.1002/sim.1186
IntHout, J., Ioannidis, J. P. A., Rovers, M. M., & Goeman, J. J. (2016). Plea for routinely presenting prediction intervals in meta-analysis. *BMJ Open, 6*, e010247. https://doi.org/10.1136/bmjopen-2015-010247
Jacobs, J. (1961). *The death and life of great American cities*. Random House.
Jiang, B., Mak, C. N. S., Larsen, L., & Zhong, H. (2017). Minimizing the gender difference in perceived safety: Comparing the effects of urban back alley interventions. *Journal of Environmental Psychology*. https://doi.org/10.1016/j.jenvp.2017.03.012
Knabe, et al. (2026). Fear of crime in urban environments: A meta-analysis of physical environment interventions [Preprint]. OSF. https://osf.io/6wtv4
Lakens, D. (2013). Calculating and reporting effect sizes to facilitate cumulative science. *Frontiers in Psychology, 4*, 863. https://doi.org/10.3389/fpsyg.2013.00863
Lakens, D., Scheel, A. M., & Isager, P. M. (2018). Equivalence testing for psychological research: A tutorial. *Advances in Methods and Practices in Psychological Science, 1*(2), 259-269. https://doi.org/10.1177/2515245918770963
Lorenc, T., et al. (2013). Environmental interventions to reduce fear of crime: Systematic review of effectiveness. *Systematic Reviews, 2*, 30. https://doi.org/10.1186/2046-4053-2-30
Mao, Fotios, et al. (2023). Do female pedestrians express a lower degree of reassurance than male pedestrians? And does road lighting affect this? CIE proceedings. https://doi.org/10.25039/x50.2023.OP007
McHugh, M. L. (2012). Interrater reliability: The kappa statistic. *Biochemia Medica, 22*(3), 276-282. https://doi.org/10.11613/BM.2012.031
Moher, D., et al. (2015). Preferred reporting items for systematic review and meta-analysis protocols (PRISMA-P) 2015 statement. *Systematic Reviews, 4*, 1. https://doi.org/10.1186/2046-4053-4-1
Morris, S. B. (2007). Estimating effect sizes from pretest-posttest-control group designs. *Organizational Research Methods*. https://doi.org/10.1177/1094428106291059
Navarrete-Hernández, P., Vetro, A., & Concha, P. (2021). Building safer public spaces: Exploring gender difference in the perception of safety in public space through urban design interventions. *Landscape and Urban Planning*, 104180. https://doi.org/10.1016/j.landurbplan.2021.104180
Navarrete-Hernández, et al. (2025). When daylight fades: How nighttime, sociodemographics, and urban zones shape safety perceptions. *Landscape and Urban Planning, 264*, 105460. https://doi.org/10.1016/j.landurbplan.2025.105460
Navarrete-Hernández, P., Schlesser, & Luca (2026). Urban design interventions reduce fear of crime in public spaces in gender-sensitive ways. *Nature Cities*. https://doi.org/10.1038/s44284-026-00494-0
Page, M. J., et al. (2021). The PRISMA 2020 statement: An updated guideline for reporting systematic reviews. *BMJ, 372*, n71. https://doi.org/10.1136/bmj.n71
Portnov, B. A., et al. (2020). Linking nighttime outdoor lighting attributes to pedestrians' feeling of safety: An interactive survey approach. *PLOS ONE*. https://doi.org/10.1371/journal.pone.0242172
Pustejovsky, J. E., & Rodgers, M. A. (2019). Testing for funnel plot asymmetry of standardized mean differences. *Research Synthesis Methods, 10*(1), 57-71. https://doi.org/10.1002/jrsm.1332
Pustejovsky, J. E., & Tipton, E. (2017). Small-sample methods for cluster-robust variance estimation and hypothesis testing in fixed effects models. *Journal of Business & Economic Statistics*. https://doi.org/10.1080/07350015.2016.1247004
Rethlefsen, M. L., et al. (2021). PRISMA-S: An extension to the PRISMA statement for reporting literature searches in systematic reviews. *Systematic Reviews, 10*, 39. https://doi.org/10.1186/s13643-020-01542-z
Rodgers, M. A., & Pustejovsky, J. E. (2021). Evaluating meta-analytic methods to detect selective reporting in the presence of dependent effect sizes. *Psychological Methods*. https://doi.org/10.1037/met0000300
te Braak, P., & van Tienoven, T. P. (2025). Navigating the city: A systematic literature review on women's perceived safety in urban public space. *Cities*, 105907. https://doi.org/10.1016/j.cities.2025.105907
Topor, M., et al. (2023). An integrative framework for planning and conducting Non-Intervention, Reproducible, and Open Systematic Reviews (NIRO-SR). *Meta-Psychology, 7*. https://doi.org/10.15626/MP.2021.2840
Valentine, J. C., Pigott, T. D., & Rothstein, H. R. (2010). How many studies do you need? *Journal of Educational and Behavioral Statistics, 35*(2), 215-247. https://doi.org/10.3102/1076998609346961
van de Schoot, R., et al. (2021). An open source machine learning framework for efficient and transparent systematic reviews. *Nature Machine Intelligence, 3*, 125-133. https://doi.org/10.1038/s42256-020-00287-7
Viechtbauer, W. (2010). Conducting meta-analyses in R with the metafor package. *Journal of Statistical Software, 36*(3), 1-48. https://doi.org/10.18637/jss.v036.i03
Welsh, B. C., & Farrington, D. P. (2008). Effects of improved street lighting on crime. *Campbell Systematic Reviews*. https://doi.org/10.4073/csr.2008.13
Wilson, J. Q., & Kelling, G. L. (1982). Broken windows. *The Atlantic Monthly, 249*(3), 29-38.

> Draft note: incomplete author lists ("et al." where the full list is not yet copied) and missing volume/page details are completed from Crossref by `verify_references.py` before submission.

---

## Appendices

**A. Checklist mapping** (NIRO-SR Part A items A1 to A30 and PRISMA-P items): `appendix_A_checklists.md`
**B. Full search strings** for every source, with the development log: `search_development/` (OpenAlex syntax in `search_dev.py`; versions, counts and benchmark recall in `search_dev_log*.csv` and `benchmark_recall*.csv`)
**C. Screening manual and extraction variables:** `appendix_C_screening_extraction.md` and `verification/templates/extraction_template.csv`
**D. Risk-of-bias items and rule:** section 2.6; template `verification/templates/rob_template.csv`
**E. Source register for evidence beyond articles:** `verification/templates/source_registry_template.csv`
**F. Analysis code tested on simulated data:** `05_analysis/analysis.R` is the complete analysis of this protocol (RQ1 to RQ4, baseline check, decision rules, sensitivity analyses). `05_analysis/simulate_data.R` creates fake datasets with known true effects. `05_analysis/test_pipeline.R` checks three things:
1. With 60 simulated studies per feature, every estimate is within 3 standard errors of its true value, and the decisions are the expected ones.
2. Over 60 repeated small datasets (8 studies per feature), the 95% CIs contain the true value about 95% of the time, without bias.
3. The SWiM branch and RQ4 work with very few studies.

The pooled results are also checked by `verification/verify_model.R` against two independent implementations. No real data were used.
**G. Sensitivity analysis:** `sensitivity/sensitivity_analysis.R`, results and power curves
