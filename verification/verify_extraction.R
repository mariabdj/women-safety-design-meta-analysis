# GATE 4: checks that the extraction sheet is complete, plausible and traceable.
# Usage: Rscript verification/verify_extraction.R [03_extraction/extraction.csv]
# Exit code 0 = PASS, 1 = FAIL.

args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[1] else "03_extraction/extraction.csv"
d <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
errors <- character(0)
fail <- function(row, col, msg) errors <<- c(errors, sprintf("FAIL row es_id=%s, column '%s': %s", row, col, msg))

required <- c("es_id", "study_id", "author", "year", "feature", "gender", "design",
              "higher_is_safer", "es_method", "n_t", "n_c", "scale_min", "scale_max",
              "source_location", "data_from_author")
missing_cols <- setdiff(required, names(d))
if (length(missing_cols)) {
  cat("FAIL missing columns:", paste(missing_cols, collapse = ", "), "\n"); quit(status = 1)
}
if (nrow(d) == 0) { cat("FAIL extraction sheet has no rows\n"); quit(status = 1) }

dup <- d$es_id[duplicated(d$es_id)]
for (x in dup) fail(x, "es_id", "duplicated es_id")

is_count <- function(x) !is.na(x) && x == round(x) && x > 0

for (i in seq_len(nrow(d))) {
  r <- d[i, ]; id <- r$es_id
  for (col in required) if (is.na(r[[col]])) fail(id, col, "empty (mandatory)")
  if (!is.na(r$gender) && !r$gender %in% c("women", "men", "all")) fail(id, "gender", paste0("'", r$gender, "' not in women/men/all"))
  if (!is.na(r$design) && !r$design %in% c("between", "within")) fail(id, "design", paste0("'", r$design, "' not in between/within"))
  if (!is.na(r$higher_is_safer) && !r$higher_is_safer %in% c("yes", "no")) fail(id, "higher_is_safer", "must be yes/no")
  if (!is.na(r$data_from_author) && !r$data_from_author %in% c("yes", "no")) fail(id, "data_from_author", "must be yes/no")
  if (!is.na(r$year) && (r$year < 1900 || r$year > as.integer(format(Sys.Date(), "%Y")))) fail(id, "year", paste(r$year, "not a plausible publication year (no date limit in the protocol)"))
  if (!is_count(r$n_t)) fail(id, "n_t", paste(r$n_t, "is not a positive integer"))
  if (!is_count(r$n_c)) fail(id, "n_c", paste(r$n_c, "is not a positive integer"))
  if (!is.na(r$design) && r$design == "within" && !is.na(r$n_t) && !is.na(r$n_c) && r$n_t != r$n_c)
    fail(id, "n_t/n_c", "within design: n_t must equal n_c (same people)")
  if (!is.na(r$scale_min) && !is.na(r$scale_max) && r$scale_min >= r$scale_max) fail(id, "scale_min/max", "min >= max")
  if (!is.na(r$source_location) && nchar(trimws(r$source_location)) < 4) fail(id, "source_location", "too vague, give page + table/figure")

  m <- r$es_method
  if (is.na(m)) next
  if (m == "means") {
    for (col in c("m_t", "sd_t", "m_c", "sd_c")) if (is.na(r[[col]])) fail(id, col, "empty but es_method = means")
    if ("dispersion_type" %in% names(d) && !identical(r$dispersion_type, "SD")) fail(id, "dispersion_type", "must be 'SD' (convert SE first and note it)")
    for (col in c("sd_t", "sd_c")) if (!is.na(r[[col]]) && r[[col]] <= 0) fail(id, col, "SD must be > 0")
    for (col in c("m_t", "m_c")) if (!is.na(r[[col]]) && !is.na(r$scale_min) && !is.na(r$scale_max) &&
                                    (r[[col]] < r$scale_min || r[[col]] > r$scale_max))
      fail(id, col, sprintf("mean %s outside scale [%s, %s]", r[[col]], r$scale_min, r$scale_max))
    # An SD larger than half the scale range is impossible for a bounded scale
    for (col in c("sd_t", "sd_c")) if (!is.na(r[[col]]) && !is.na(r$scale_min) && !is.na(r$scale_max) &&
                                       r[[col]] > (r$scale_max - r$scale_min) / 2)
      fail(id, col, sprintf("SD %s > half the scale range: impossible, probably a variance or wrong column", r[[col]]))
    if (r$design == "within" && "r_within" %in% names(d) && !is.na(r$r_within) && (r$r_within <= -1 || r$r_within >= 1))
      fail(id, "r_within", "correlation must be between -1 and 1")
  } else if (m == "or_ci") {
    for (col in c("stat_value", "stat_ci_low", "stat_ci_high")) if (is.na(r[[col]])) fail(id, col, "empty but es_method = or_ci")
    if (!any(is.na(c(r$stat_value, r$stat_ci_low, r$stat_ci_high))) &&
        !(r$stat_ci_low > 0 && r$stat_ci_low < r$stat_value && r$stat_value < r$stat_ci_high))
      fail(id, "stat_value/CI", "need 0 < CI low < OR < CI high")
  } else if (m == "t_between") {
    if (is.na(r$stat_value)) fail(id, "stat_value", "empty but es_method = t_between")
    if (r$design != "between") fail(id, "design", "t_between requires design = between")
  } else {
    fail(id, "es_method", paste0("'", m, "' unsupported (means / or_ci / t_between). Add it to the protocol and both implementations first"))
  }
}

if (length(errors)) {
  cat(errors, sep = "\n"); cat(sprintf("\nRESULT: FAILED (%d problems in %d rows)\n", length(errors), nrow(d))); quit(status = 1)
}
cat(sprintf("RESULT: PASSED (%d rows, %d studies, 0 problems)\n", nrow(d), length(unique(d$study_id))))
