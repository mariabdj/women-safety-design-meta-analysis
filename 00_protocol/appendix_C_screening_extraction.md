# Appendix C. Screening manual, extraction variables and frozen prompts

## C1. Title and abstract screening

Decide **include for full text** or **exclude**. When in doubt, include. Ask, in order:

1. Is it a primary study, a thesis, a report or a dataset (not a review, editorial or theory paper)? Reviews are excluded here but kept in a separate list for citation chasing.
2. Does it involve a physical feature of a public space from the six features below (or a place comparison that may involve one)?
3. Does it measure perceived safety, fear of crime or reassurance, **or** harm experienced by women (victimisation, harassment, assault, crime against women)?
4. Is there a comparison (two or more conditions, before and after, or places that differ)?

If 1 to 4 are "yes" or "unclear", include for full text. Women's results are **not** required at this stage: many studies report them only in the full text or the data.

**Six features:** lighting; vegetation; sightlines, openness, concealment and entrapment; active frontages and mixed use; maintenance and incivilities; presence of other people. Exclude interventions that are not physical design (policing, CCTV, phone apps, campaigns, training).

## C2. Full-text screening

Apply all criteria of protocol section 2.1. Record **one** reason for exclusion, the first that applies in this order:

1. Not English or French
2. Not a primary study
3. No eligible design (no comparison, qualitative only, correlational neighbourhood ratings only)
4. No eligible feature
5. No eligible outcome
6. No results for women, and none obtained after the procedure of section 2.5
7. Duplicate sample (same participants as another included report: keep the most complete report and link the others)
8. No usable data (no means, SDs, statistics or counts, even after section 2.5)

Samples that do not meet the adult rule of section 2.1 (adolescent-only, child, or fewer than 80% adults without separate adult results) are not a reason for exclusion: keep them and record adult_sample = no (they enter only the separate analysis of section 2.10).

## C3. Decision log

Each decision is logged with: record ID, stage, decision, reason (from the list), screener (author or AI check), date, and a short note for any "unclear" case. Disagreements between the author and the AI check are listed with the final decision and why.

## C4. Extraction variables

One row per effect size. Columns of `verification/templates/extraction_template.csv`:

| Group | Variables |
|----|--------------------------|
| IDs | es_id, study_id, sample_id (one per independent group of participants), contrast (the two conditions compared, as the paper names them; no numbers), pair_id (links exactly one women's and one men's effect that share the same scene, item and contrast; unique within study, feature and gender; empty when there is no match), author, year, country, setting (city or site, and place type as described) |
| Design | feature (lighting / vegetation / sightlines / active_frontages / maintenance / presence_of_others), gender (women / men / all; "all" = a whole-sample row kept only for context and for the study's total sample size in the study characteristics; never pooled), design (between / within), study_design (experiment / quasi-experiment / place comparison), stimulus (photo / video / VR / field), time_of_day (day / night), light_type (lighting only: light colour and lamp type, as reported), adult_sample (yes / no), age (mean and range, as reported) |
| Outcome | outcome_measure, scale_min, scale_max (for continuous outcomes: means, t, F or p; empty for odds-ratio and proportion rows), higher_is_safer, outcome_type (perceived; harm outcomes go to the harm sheet), outcome_source (self-report; sources of harm data belong to the harm sheet), unit_of_analysis (person or place) |
| Statistics | n_t, m_t, sd_t, n_c, m_c, sd_c, events_t, events_c (counts feeling safe in each condition, for proportions), stat_df (degrees of freedom of stat_value when reported), dispersion_type (SD / SE), r_within, stat_value (for or_ci: the odds ratio on the ratio scale), stat_ci_low, stat_ci_high (its 95% CI), reported_g (the paper's own d or g, entered in the review's direction: positive = safer with the feature), es_method (means / t_between / or_ci; further codes are added with each conversion before extraction, Appendix F) |
| Quality and traceability | rob_overall (low / some concerns / high), seen_before_stage1 (yes / no, section 2.13; "stage1" means before registration, a name kept from version 1), source_location (page and table or paragraph; for numbers read from a figure, the figure and the columns read from it, parts separated by ";", e.g. "Table 1: n_t, n_c; Fig. 3: m_t, m_c, sd_t, sd_c"), data_from_author (yes if any number came from the authors, an open dataset, a thesis or a report rather than the article itself), notes |

A value that is not reported is left empty (no NA, n/a, dash or spaces); numbers are plain decimals with a point.

Three further sheets (templates in the folder `verification/templates/`):

- **Gap sheet** (template `extraction_gap_template.csv`; OC1 and RQ3; only samples eligible for the main analysis, section 2.1, so no samples with adult_sample = no): gap_id, study_id, scene_id (links to the C7 coding), scene_name (the scene as the paper names it; no numbers), scene_score (sum of the six resolved scene codes, 0 to 6, section 2.4), baseline (yes for the control condition), higher_is_safer, scale_min, scale_max, n_w, m_w, sd_w, n_m, m_m, sd_m, dispersion_type, source_location.
- **Harm sheet** (template `extraction_actual_template.csv`; RQ4): act_id, study_id, contrast (the areas and periods compared, as the paper names them; no numbers), feature, metric (counts / survey), outcome_measure (type of harm, e.g. harassment, assault), outcome_source (police records, victimisation survey, observation), ctrl_before, ctrl_after, trt_before, trt_after (counts of harm against women only, used as reported; the victims' age range, if given, goes in notes), source_location, notes. A survey row (metric = survey) holds only its identifiers, metric, outcome_measure, outcome_source, source_location and notes; its results go to the narrative table (section 2.7).
- **Narrative table** (template `extraction_narrative_template.csv`; not pooled): study_id, contrast, domain (perceived / harm; a study reporting both gets one row per domain), reason (combined manipulation, contrast that cannot be mapped onto a favourable state, results for other genders, survey prevalence for RQ4, harm counts without a control area, data from which no effect size can be computed, or another reason given in sections 2.1, 2.5 or 2.7), results_as_reported, source_location.

## C5. Frozen prompt for the AI screening check (safety net)

The same text is used for every record; only the record changes. Model identifier, dates, settings and every output are archived with the data.

```
You are screening records for a systematic review. Decide INCLUDE or EXCLUDE using only
the rules below.
Do not use outside knowledge about the study's results.

Title-and-abstract stage. INCLUDE if all four are "yes" or "unclear":
1. It is a primary study, thesis, report or dataset (not a review, editorial or theory
   paper).
2. It involves a physical feature of a public space: lighting; vegetation; sightlines,
   openness, concealment or entrapment; active frontages or mixed use; maintenance or
   incivilities (litter, graffiti, disrepair); presence of other people. Policing, CCTV,
   apps, campaigns and training do not count.
3. It measures perceived safety, fear of crime or reassurance, OR harm experienced by women
   (victimisation, harassment, assault, crime against women).
4. There is a comparison: two or more conditions, before and after, or places that differ.
When in doubt, INCLUDE.

Full-text stage. Apply the eligibility table and feature definitions given below
[section 2.1 of the protocol is pasted here verbatim]. If excluded, give ONE reason, the
first that applies, from this list: not English or French; not a primary study; no
eligible design; no eligible feature; no eligible outcome; no results for women; duplicate
sample; no usable data. A sample that does not meet the adult rule (adolescent-only,
child, or fewer than 80% adults without separate adult results) is not a reason to
exclude: INCLUDE it and say so in EVIDENCE.

Answer in this format:
DECISION: INCLUDE or EXCLUDE
REASON: (one reason from the list, or "meets criteria")
EVIDENCE: (one short quote from the record that supports the decision)

RECORD:
[title, abstract or full text]
```

## C6. Frozen prompt for the AI extraction and risk-of-bias check

```
You are extracting data for a systematic review, as an independent check of another person's extraction.
Use only the attached full text and any other attached source for this study (author
reply, thesis or report). Never estimate or guess a number: if a value that this row
needs is not reported, leave the cell empty and say in notes (for the gap sheet and the
narrative table, in source_location) where you looked; cells that do not apply to the row
are left empty without a note.

1. Fill the attached row list: it gives, for each row, only es_id, study_id, sample_id,
   contrast, feature, gender, pair_id and outcome_measure (definitions pasted below from
   section 2.1). Fill the other columns of the extraction template (pasted below) for each
   listed row, and do not change the listed values; if a listed feature or favourable
   state does not match its contrast, say so in notes. Leave seen_before_stage1,
   rob_overall and data_from_author empty (they are filled from other records).
   If you find a comparison of a favourable and a less favourable state of one feature
   that is not on the list, add a row with the ID <study_id>_NEW1, <study_id>_NEW2, and so
   on (a row that is kept keeps this ID), following the rules of section 2.7 for choosing
   effects within a study (pasted below).
2. For every number, give source_location: page and table or paragraph. A number shown only
   in a figure is left empty; name the figure in notes (for the gap sheet, in
   source_location).
3. Record whether dispersion is an SD or an SE, exactly as the paper labels it.
4. Rate the six risk-of-bias items of section 2.6 (pasted below) as yes, no or unclear,
   each with a short quote and page, in the risk-of-bias template, and fill overall by the
   rule of section 2.6; rate a study that reports both perceived safety and harm once for
   each (domain perceived or harm).
5. In the same way, fill the attached row lists of the gap sheet (women's and men's
   ratings of each scene; leave scene_score empty, it is coded separately) and the harm
   sheet (counts before and after in treated and control areas); these lists give only
   gap_id, study_id, scene_id and scene_name, and act_id, study_id, contrast, feature and
   outcome_measure: do not change the listed values. Add any missing scene or harm row with
   the same <study_id>_NEW1 pattern; for a survey row (metric = survey) give only its
   identifiers, metric, outcome_measure, outcome_source, source_location and notes, and put
   its results in the narrative table. Fill the narrative table (contrasts and results
   that are not pooled, including results for other genders, survey prevalence for RQ4 and
   data from which no effect size can be computed; sections 2.1, 2.5 and 2.7), with the
   columns pasted below.

Return one CSV per sheet (extraction, gap, harm, narrative) with the template headers,
then the risk-of-bias table.

[section 2.1 eligibility table and feature definitions, pasted verbatim]
[section 2.5, pasted verbatim]
[section 2.6 risk-of-bias items and overall rule, pasted verbatim]
[section 2.7, pasted verbatim]
[Appendix C4 variable definitions and allowed values, pasted verbatim]
[extraction, gap, harm, narrative and risk-of-bias template headers, pasted verbatim]
[row lists for this study: extraction, gap and harm sheets]

FULL TEXT AND ANY OTHER SOURCE FOR THIS STUDY:
[attached]
```

## C7. Frozen prompt for the AI coder of RQ3 scene scores

```
You are coding scenes for a systematic review. Use only the attached file, which contains
the stimulus images and method descriptions of one study, with all results removed.
Code exactly the scenes in the attached list (scene_id and scene_name, the paper's name for
each scene).
For each scene, code each of the six features (definitions pasted below from section 2.1):
1 if the scene shows the feature's more favourable state, 0 if it shows the less favourable
state or if the feature does not vary within this study, and 0.5 if the feature has more
than two levels and the scene shows an intermediate level.
Return a CSV with the columns scene_id, lighting, vegetation, sightlines,
active_frontages, maintenance, presence_of_others and notes (one short note per scene
saying what you saw).

[section 2.1 feature definitions, pasted verbatim]

SCENE LIST AND FILE:
[attached]
```
