# GATE 4: checks that the extraction sheet is complete, plausible and traceable.
# Usage: Rscript verification/verify_extraction.R [03_extraction/extraction.csv] [--complete]
# --complete (gate 6): the codes used by the sensitivity analyses must be filled in every row
# Exit code 0 = PASS, 1 = FAIL.

args <- commandArgs(trailingOnly = TRUE)
complete <- "--complete" %in% args; args <- setdiff(args, "--complete")
path <- if (length(args) >= 1) args[1] else "03_extraction/extraction.csv"
errors <- character(0)
sheet <- "main"   # which sheet the current rows come from (sets the message prefix)
fail <- function(row, col, msg) errors <<- c(errors, sprintf("FAIL %s, column '%s': %s",
  switch(sheet, main = paste0("row es_id=", row), gap = paste("gap", row), harm = paste("harm", row), row), col, msg))
# cells holding only spaces, and text in number columns, are reported (the analysis reads the sheet as it is,
# so it must be cleaned); then they are set to NA here so the other checks can run
reported <- character(0)   # cells already reported here, so later checks do not report them twice
fail_once <- fail
clean <- function(x, idcol, numcols) {
  for (j in names(x)) if (is.character(x[[j]])) {
    v <- tolower(trimws(x[[j]], whitespace = "[\\h\\v]"))   # every kind of space, as Python strip() does
    sp <- which(!is.na(x[[j]]) & (v == "" | v %in% c("na", "n/a", "nan", "none", "null")))
    for (i in sp) { fail_once(x[[idcol]][i], j, paste0("'", x[[j]][i], "': write nothing in an empty cell")); reported <<- c(reported, paste(sheet, x[[idcol]][i], j)) }
    x[[j]][sp] <- NA
  }
  for (j in intersect(numcols, names(x))) if (!is.numeric(x[[j]])) {
    s <- trimws(x[[j]], whitespace = "[ \t]")   # only what read.csv itself strips, so the analysis reads the same number
    ok <- grepl("^[+-]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][+-]?[0-9]+)?$", s)   # plain decimal numbers only
    v <- ifelse(ok, suppressWarnings(as.numeric(s)), NA_real_)
    ok <- ok & is.finite(v)
    v[!ok] <- NA
    for (i in which(!is.na(x[[j]]) & !ok)) { fail_once(x[[idcol]][i], j, paste0("'", x[[j]][i], "' is not a number")); reported <<- c(reported, paste(sheet, x[[idcol]][i], j)) }
    x[[j]] <- v
  }
  x
}
# a later message about a cell already reported above is dropped
fail <- function(row, col, msg) if (!(paste(sheet, row, col) %in% reported)) fail_once(row, col, msg)
d <- clean(read.csv(path, colClasses = "character", na.strings = "", check.names = FALSE), "es_id",
           c("year", "n_t", "m_t", "sd_t", "n_c", "m_c", "sd_c", "r_within", "stat_value", "stat_df", "stat_ci_low",
             "stat_ci_high", "scale_min", "scale_max", "events_t", "events_c", "reported_g"))

required <- c("es_id", "study_id", "sample_id", "contrast", "author", "year", "feature", "gender", "design",
              "higher_is_safer", "es_method", "n_t", "n_c", "outcome_measure",
              "source_location", "data_from_author")
missing_cols <- setdiff(required, names(d))
if (length(missing_cols)) {
  cat("FAIL missing columns:", paste(missing_cols, collapse = ", "), "\n"); quit(status = 1)
}
if (nrow(d) == 0) { cat("FAIL extraction sheet has no rows\n"); quit(status = 1) }

dup <- d$es_id[duplicated(d$es_id)]
for (x in dup) fail(x, "es_id", "duplicated es_id")
is_count <- function(x) !is.na(x) && x == round(x) && x > 0
# allowed values of the categorical columns added for the protocol (a typo would silently move a row)
allowed <- list(feature = c("lighting", "vegetation", "sightlines", "active_frontages", "maintenance", "presence_of_others"), adult_sample = c("yes", "no"), outcome_type = c("perceived"), outcome_source = c("self-report"), unit_of_analysis = c("person", "place"),
                rob_overall = c("low", "some concerns", "high"), seen_before_stage1 = c("yes", "no"),
                stimulus = c("photo", "video", "VR", "field"), time_of_day = c("day", "night"),
                study_design = c("experiment", "quasi-experiment", "place comparison"))
for (col in intersect(names(allowed), names(d))) {
  bad <- which(!is.na(d[[col]]) & !(d[[col]] %in% allowed[[col]]))
  for (i in bad) fail(d$es_id[i], col, paste0("'", d[[col]][i], "' not in ", paste(allowed[[col]], collapse = " / "),
                                             if (col == "outcome_type") " (harm outcomes go to the harm sheet)" else ""))
}
# gap and harm sheets, when they sit next to the extraction sheet (protocol C4)
gpath <- file.path(dirname(path), "extraction_gap.csv")
if (file.exists(gpath)) {
  sheet <- "gap"
  g <- clean(read.csv(gpath, colClasses = "character", na.strings = ""), "gap_id",
             c("scene_score", "scale_min", "scale_max", "n_w", "m_w", "sd_w", "n_m", "m_m", "sd_m"))
  need <- c("gap_id", "study_id", "scene_id", "scene_name", "scene_score", "baseline", "higher_is_safer", "scale_min", "scale_max",
            "n_w", "m_w", "sd_w", "n_m", "m_m", "sd_m", "dispersion_type", "source_location")
  miss <- setdiff(need, names(g))
  if (length(miss)) { cat("FAIL extraction_gap.csv missing columns:", paste(miss, collapse = ", "), "\n"); quit(status = 1) }
  for (x in g$gap_id[duplicated(g$gap_id)]) fail(x, "gap_id", "duplicated gap_id")
  for (i in seq_len(nrow(g))) {
    id <- g$gap_id[i]
    for (col in c("study_id", "scene_id", "scene_name", "source_location")) if (is.na(g[[col]][i])) fail(id, col, "empty (mandatory)")
    for (col in c("m_w", "m_m")) if (is.na(g[[col]][i])) fail(id, col, "missing mean")
    if (all(c("scale_min", "scale_max") %in% names(g)) && !is.na(g$scale_min[i]) && !is.na(g$scale_max[i])) {
      for (col in c("m_w", "m_m")) if (!is.na(g[[col]][i]) && (g[[col]][i] < g$scale_min[i] || g[[col]][i] > g$scale_max[i]))
        fail(id, col, "mean outside the scale range")
      # the plausibility test applies to the SD, so a reported SE is converted first (SD = SE x sqrt(n))
      se_row <- "dispersion_type" %in% names(g) && isTRUE(g$dispersion_type[i] == "SE")
      for (col in c("sd_w", "sd_m")) {
        sdv <- g[[col]][i] * if (se_row) sqrt(g[[if (col == "sd_w") "n_w" else "n_m"]][i]) else 1
        if (!is.na(sdv) && sdv > (g$scale_max[i] - g$scale_min[i]) / 2)
          fail(id, col, sprintf("SD %.3g > half the scale range: impossible, probably a variance, an SE labelled SD or the wrong column", sdv))
      }
    } else for (col in c("scale_min", "scale_max")) if (is.na(g[[col]][i])) fail(id, col, "missing")
    if (!(g$baseline[i] %in% c("yes", "no"))) fail(id, "baseline", "must be yes/no")
    for (col in c("n_w", "n_m")) if (!is_count(g[[col]][i])) fail(id, col, "is not a positive integer")
    for (col in c("sd_w", "sd_m")) if (is.na(g[[col]][i]) || g[[col]][i] <= 0) fail(id, col, "must be > 0")
    if (is.na(g$scene_score[i])) fail(id, "scene_score", "missing")
    else if (g$scene_score[i] < 0 || g$scene_score[i] > 6 || (2 * g$scene_score[i]) %% 1 != 0)
      fail(id, "scene_score", "must be a sum of six codes 0, 0.5 or 1 (0 to 6 in steps of 0.5)")
    if (!(g$higher_is_safer[i] %in% c("yes", "no"))) fail(id, "higher_is_safer", "must be yes/no")
    if ("dispersion_type" %in% names(g) && !(g$dispersion_type[i] %in% c("SD", "SE"))) fail(id, "dispersion_type", "must be SD or SE")
  }
}
hpath <- file.path(dirname(path), "extraction_actual.csv")
if (file.exists(hpath)) {
  sheet <- "harm"
  h <- clean(read.csv(hpath, colClasses = "character", na.strings = ""), "act_id",
             c("ctrl_before", "ctrl_after", "trt_before", "trt_after"))
  need <- c("act_id", "study_id", "contrast", "feature", "metric", "outcome_measure", "outcome_source", "ctrl_before", "ctrl_after", "trt_before",
            "trt_after", "source_location")
  miss <- setdiff(need, names(h))
  if (length(miss)) { cat("FAIL extraction_actual.csv missing columns:", paste(miss, collapse = ", "), "\n"); quit(status = 1) }
  for (x in h$act_id[duplicated(h$act_id)]) fail(x, "act_id", "duplicated act_id")
  for (i in seq_len(nrow(h))) {
    id <- h$act_id[i]
    for (col in c("study_id", "contrast", "source_location", "outcome_measure", "outcome_source")) if (is.na(h[[col]][i])) fail(id, col, "empty (mandatory)")
    if (!(h$metric[i] %in% c("counts", "survey"))) fail(id, "metric", "must be counts/survey")
    if (!(h$feature[i] %in% c("lighting", "vegetation", "sightlines", "active_frontages", "maintenance", "presence_of_others"))) fail(id, "feature", "not one of the six protocol features")
    if (h$metric[i] %in% "counts") for (col in c("ctrl_before", "ctrl_after", "trt_before", "trt_after")) {
      v <- h[[col]][i]; if (is.na(v) || v < 0 || v != round(v)) fail(id, col, "count must be a non-negative integer")
    }
    # a survey row holds no counts: its results go to the narrative table (appendix C4)
    if (h$metric[i] %in% "survey") for (col in c("ctrl_before", "ctrl_after", "trt_before", "trt_after"))
      if (!is.na(h[[col]][i])) fail(id, col, "survey row: leave counts empty, results go to the narrative table")
  }
}
sheet <- "main"
# pair_id must link exactly one women's and one men's effect within a study and feature (protocol 2.4)
if ("pair_id" %in% names(d)) {
  pk <- paste(d$study_id, d$feature, d$gender, d$pair_id)[!is.na(d$pair_id) & d$gender %in% c("women", "men")]
  ids <- d$es_id[!is.na(d$pair_id) & d$gender %in% c("women", "men")]
  for (x in ids[duplicated(pk) | duplicated(pk, fromLast = TRUE)]) fail(x, "pair_id", "same pair_id used twice for one gender in this study and feature")
  # and a pair_id must have both genders, otherwise it should be empty (protocol 2.4)
  pr <- d[!is.na(d$pair_id) & d$gender %in% c("women", "men"), ]
  ng <- tapply(pr$gender, paste(pr$study_id, pr$feature, pr$pair_id), function(g) length(unique(g)))
  for (x in pr$es_id[paste(pr$study_id, pr$feature, pr$pair_id) %in% names(ng)[ng < 2]])
    fail(x, "pair_id", "pair_id has no partner of the other gender: leave it empty")
  # the women's and men's rows of one pair_id must share contrast, outcome and design (protocol 2.4); the
  # statistic may differ (e.g. means for one gender, t for the other), both give g on the same scale
  for (k in unique(paste(pr$study_id, pr$feature, pr$pair_id))) {
    rr <- pr[paste(pr$study_id, pr$feature, pr$pair_id) == k, ]
    if (nrow(rr) != 2) next
    for (col in intersect(c("contrast", "outcome_measure", "design", "higher_is_safer", "scale_min", "scale_max"), names(rr)))
      if (!anyNA(rr[[col]]) && !identical(rr[[col]][1], rr[[col]][2])) fail(rr$es_id[2], "pair_id", sprintf("paired rows differ in %s ('%s' vs '%s')", col, rr[[col]][1], rr[[col]][2]))
  }
}


# at gate 6 the sensitivity codes must be filled: an empty cell would silently keep the row in every set
if (complete) for (col in c("adult_sample", "study_design", "rob_overall", "seen_before_stage1", "data_from_author", "outcome_type")) {
  if (!(col %in% names(d))) { sheet <- "cols"; fail("extraction.csv", col, "column missing (needed at gate 6)"); sheet <- "main"; next }
  for (x in d$es_id[is.na(d[[col]])]) fail(x, col, "empty at gate 6 (sensitivity analyses need it)")
}
# study-level codes are the same in every row of a study, sample-level codes in every row of a sample
if (complete) for (lv in list(c("study_id", "rob_overall"), c("study_id", "seen_before_stage1"), c("sample_id", "adult_sample"))) {
  if (!all(lv %in% names(d))) next
  k <- tapply(d[[lv[2]]], d[[lv[1]]], function(v) length(unique(v[!is.na(v)])))
  for (u in names(k)[k > 1]) fail(d$es_id[which(d[[lv[1]]] == u)[1]], lv[2], sprintf("differs between rows of %s %s", lv[1], u))
}

for (i in seq_len(nrow(d))) {
  r <- d[i, ]; id <- r$es_id
  for (col in required) if (is.na(r[[col]])) fail(id, col, "empty (mandatory)")
  if (!is.na(r$gender) && !r$gender %in% c("women", "men", "all")) fail(id, "gender", paste0("'", r$gender, "' not in women/men/all"))
  if (!is.na(r$design) && !r$design %in% c("between", "within")) fail(id, "design", paste0("'", r$design, "' not in between/within"))
  if (!is.na(r$higher_is_safer) && !r$higher_is_safer %in% c("yes", "no")) fail(id, "higher_is_safer", "must be yes/no")
  if (!is.na(r$data_from_author) && !r$data_from_author %in% c("yes", "no")) fail(id, "data_from_author", "must be yes/no")
  if (!is.na(r$year) && (r$year != round(r$year) || r$year < 1900 || r$year > as.integer(format(Sys.Date(), "%Y")))) fail(id, "year", paste(r$year, "not a plausible publication year (no date limit in the protocol)"))
  if (!is.na(r$n_t) && !is_count(r$n_t)) fail(id, "n_t", paste(r$n_t, "is not a positive integer"))
  if (!is.na(r$n_c) && !is_count(r$n_c)) fail(id, "n_c", paste(r$n_c, "is not a positive integer"))
  if (!is.na(r$design) && r$design == "within" && !is.na(r$n_t) && !is.na(r$n_c) && r$n_t != r$n_c)
    fail(id, "n_t/n_c", "within design: n_t must equal n_c (same people)")
  if (!is.na(r$scale_min) && !is.na(r$scale_max) && r$scale_min >= r$scale_max) fail(id, "scale_min/max", "min >= max")
  if (!is.na(r$source_location) && nchar(trimws(r$source_location)) < 4) fail(id, "source_location", "too vague, give page + table/figure")

  if ("stat_df" %in% names(d) && !is.na(r$stat_df) && !(r$stat_df > 0)) fail(id, "stat_df", "degrees of freedom must be > 0")
  m <- r$es_method
  if (is.na(m)) next
  if (m %in% c("means", "t_between")) for (col in c("scale_min", "scale_max")) if (is.na(r[[col]])) fail(id, col, "empty (mandatory for means and t statistics)")
  if (m == "means") {
    for (col in c("m_t", "sd_t", "m_c", "sd_c")) if (is.na(r[[col]])) fail(id, col, "empty but es_method = means")
    # the type is recorded as printed in the paper; SEs are converted by the code (protocol 2.7)
    if ("dispersion_type" %in% names(d) && !(r$dispersion_type %in% c("SD", "SE"))) fail(id, "dispersion_type", "must be 'SD' or 'SE', as labelled in the paper")
    for (col in c("sd_t", "sd_c")) if (!is.na(r[[col]]) && r[[col]] <= 0) fail(id, col, "SD must be > 0")
    for (col in c("m_t", "m_c")) if (!is.na(r[[col]]) && !is.na(r$scale_min) && !is.na(r$scale_max) &&
                                    (r[[col]] < r$scale_min || r[[col]] > r$scale_max))
      fail(id, col, sprintf("mean %s outside scale [%s, %s]", r[[col]], r$scale_min, r$scale_max))
    # An SD larger than half the scale range is impossible for a bounded scale; a reported SE is converted first
    se_row <- "dispersion_type" %in% names(d) && isTRUE(r$dispersion_type == "SE")
    for (col in c("sd_t", "sd_c")) {
      nn <- if (col == "sd_t" || is.na(r$n_c)) r$n_t else r$n_c
      sdv <- r[[col]] * if (se_row) sqrt(nn) else 1
      if (!is.na(sdv) && !is.na(r$scale_min) && !is.na(r$scale_max) && sdv > (r$scale_max - r$scale_min) / 2)
        fail(id, col, sprintf("SD %.3g > half the scale range: impossible, probably a variance, an SE labelled SD or the wrong column", sdv))
    }
    if (isTRUE(r$design == "within") && "r_within" %in% names(d) && !is.na(r$r_within) && (r$r_within <= -1 || r$r_within >= 1))
      fail(id, "r_within", "correlation must be between -1 and 1")
  } else if (m == "or_ci") {
    for (col in c("stat_value", "stat_ci_low", "stat_ci_high")) if (is.na(r[[col]])) fail(id, col, "empty but es_method = or_ci")
    if (!any(is.na(c(r$stat_value, r$stat_ci_low, r$stat_ci_high))) &&
        !(r$stat_ci_low > 0 && r$stat_ci_low < r$stat_value && r$stat_value < r$stat_ci_high))
      fail(id, "stat_value/CI", "need 0 < CI low < OR < CI high")
  } else if (m == "t_between") {
    if (is.na(r$stat_value)) fail(id, "stat_value", "empty but es_method = t_between")
    if (!isTRUE(r$design == "between")) fail(id, "design", "t_between requires design = between")
  } else {
    fail(id, "es_method", paste0("'", m, "' unsupported (means / or_ci / t_between). Add it to the protocol and both implementations first"))
  }
}

if (length(errors)) {
  cat(errors, sep = "\n"); cat(sprintf("\nRESULT: FAILED (%d problems in %d rows)\n", length(errors), nrow(d))); quit(status = 1)
}
cat(sprintf("RESULT: PASSED (%d rows, %d studies, 0 problems)\n", nrow(d), length(unique(d$study_id))))
