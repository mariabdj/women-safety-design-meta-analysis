# Appendix C. Screening manual and extraction variables

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

## C3. Decision log

Each decision is logged with: record ID, stage, decision, reason (from the list), screener (author or AI screener), date, and a short note for any "unclear" case. Disagreements between the author and the AI screener are listed with the final decision and why.

## C4. Extraction variables

One row per effect size. Columns of `verification/templates/extraction_template.csv`:

| Group | Variables |
|---|---|
| IDs | es_id, study_id, author, year, country |
| Design | feature, gender (women / men / all), design (between / within), stimulus (photo, video, VR, field), time_of_day |
| Outcome | outcome_measure, scale_min, scale_max, higher_is_safer, outcome_type (perceived / actual), outcome_source (self-report, victimisation survey, police records, observation), unit_of_analysis (person, place, area) |
| Statistics | n_t, m_t, sd_t, n_c, m_c, sd_c, dispersion_type (SD / SE), r_within, stat_value, stat_ci_low, stat_ci_high, reported_g, es_method |
| Traceability | source_location (page, table or figure), data_from_author (yes / no), notes |

For RQ3, a separate sheet records each scene or place with its favourable-feature score (0 to 6) and the reason for each of the six codes.
