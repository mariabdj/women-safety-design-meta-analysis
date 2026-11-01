# Appendix F: does analysis.R find the truth we planted in simulated data?
# Three tests, all on made-up data (no real study is read):
#  1. Large simulation (60 studies per feature): every pooled estimate must be within 3 SE of its true value,
#     and the decisions must be the expected ones (big true effect -> "supported", true 0 -> "equivalent").
#  2. Repeated small simulations (8 studies per feature, as in the real literature): over many datasets,
#     the 95% CIs for women's lighting effect and the women-men difference must not cover the truth less often than
#     95% (exact binomial CI; the full calibration check over 300 runs is verification/verify_coverage.R),
#     and the average estimate must be close to the truth (no bias).
#  3. The pipeline runs end to end on a small dataset, including the SWiM branch (k < 3) and RQ4.
# Usage (from Projet1_Meta-Analyse/): Rscript 05_analysis/test_pipeline.R [n_reps]

suppressPackageStartupMessages(library(jsonlite))
args <- commandArgs(trailingOnly = TRUE)
n_reps <- if (length(args) >= 1) as.integer(args[1]) else 100
R <- file.path(R.home("bin"), "Rscript")
tmp <- file.path(tempdir(), "sim"); dir.create(tmp, showWarnings = FALSE)
fails <- character(0)
check <- function(ok, msg) { cat(if (isTRUE(ok)) "PASS" else "FAIL", msg, "\n"); if (!isTRUE(ok)) fails <<- c(fails, msg) }

run <- function(k, seed, dir) {
  unlink(file.path(dir, c("extraction.csv", "extraction_gap.csv", "extraction_actual.csv", "truth.json", "results.json")))
  ss <- system2(R, c("05_analysis/simulate_data.R", k, seed, shQuote(dir)), stdout = FALSE)
  if (!identical(as.integer(ss), 0L) || !file.exists(file.path(dir, "truth.json"))) stop(sprintf("simulate_data.R failed (k = %s, seed = %s)", k, seed))
  st <- system2(R, c("05_analysis/analysis.R", shQuote(dir), shQuote(file.path(dir, "results.json"))), stdout = FALSE)
  if (st != 0) stop(sprintf("analysis.R failed on simulated data (k = %s, seed = %s)", k, seed))
  list(res = fromJSON(file.path(dir, "results.json"), simplifyVector = FALSE), truth = fromJSON(file.path(dir, "truth.json")))
}
get <- function(res, name) Filter(function(m) m$name == name, res$models)[[1]]

# ---- 1. large simulation ------------------------------------------------------------------------------------
cat("== Test 1: large simulation, 60 studies per feature ==\n")
big <- run(60, 1, file.path(tmp, "big"))
for (f in names(big$truth$true_women)) {
  m <- get(big$res, paste0("RQ1_", f)); tw <- big$truth$true_women[[f]]
  check(abs(m$estimate - tw) < 3 * m$se, sprintf("RQ1 %s: estimate %.3f vs truth %.2f (SE %.3f)", f, m$estimate, tw, m$se))
  m2 <- get(big$res, paste0("RQ2_", f)); td <- big$truth$true_diff[[f]]
  check(abs(m2$estimate - td) < 3 * m2$se, sprintf("RQ2 %s: difference %.3f vs truth %.2f (SE %.3f)", f, m2$estimate, td, m2$se))
}
check(get(big$res, "RQ1_lighting")$decision == "supported", "decision: lighting (true g = 0.45) supported")
check(get(big$res, "RQ1_presence_of_others")$decision == "equivalent (no meaningful effect)", "decision: presence of others (true g = 0) equivalent")
h0 <- get(big$res, "OC1_baseline_gap"); check(isTRUE(h0$check_passed), sprintf("OC1 baseline gap detected (estimate %.3f)", h0$estimate))
s3 <- get(big$res, "RQ3_exploratory_within_study_slope")
check(abs(s3$estimate - big$truth$gap_slope) < 3 * s3$se, sprintf("RQ3 slope %.3f vs truth %.2f (SE %.3f)", s3$estimate, big$truth$gap_slope, s3$se))
v <- system2(R, c("verification/verify_model.R", shQuote(file.path(tmp, "big", "extraction.csv")), shQuote(file.path(tmp, "big", "results.json"))), stdout = TRUE)
check(any(grepl("RESULT: PASSED", v)), "verify_model.R on large simulation")

# ---- 2. coverage and bias over repeated small simulations ----------------------------------------------------
cat(sprintf("== Test 2: %d small simulations, 8 studies per feature ==\n", n_reps))
cov1 <- cov2 <- est1 <- est2 <- numeric(0)
for (i in seq_len(n_reps)) {
  x <- run(8, 1000 + i, file.path(tmp, "rep"))
  m <- get(x$res, "RQ1_lighting"); m2 <- get(x$res, "RQ2_lighting")
  est1 <- c(est1, m$estimate); cov1 <- c(cov1, m$ci_lb <= x$truth$true_women$lighting && x$truth$true_women$lighting <= m$ci_ub)
  est2 <- c(est2, m2$estimate); cov2 <- c(cov2, m2$ci_lb <= x$truth$true_diff$lighting && x$truth$true_diff$lighting <= m2$ci_ub)
}
# Coverage may sit above 0.95 with 8 studies (t with k - 1 df); the precise check, with SE calibration over
# 300 runs, is verification/verify_coverage.R. Here: intervals must not be too narrow.
cov_ok <- function(x) binom.test(sum(x), length(x))$conf.int[2] >= 0.95
check(cov_ok(cov1), sprintf("RQ1 lighting: CI coverage %.2f, not below 0.95 (exact CI)", mean(cov1)))
check(abs(mean(est1) - 0.45) < 0.05, sprintf("RQ1 lighting: mean estimate %.3f vs truth 0.45", mean(est1)))
check(cov_ok(cov2), sprintf("RQ2 lighting: CI coverage %.2f, not below 0.95 (exact CI)", mean(cov2)))
check(abs(mean(est2) - 0.25) < 0.05, sprintf("RQ2 lighting: mean difference %.3f vs truth 0.25", mean(est2)))

# ---- 3. small run, all branches -------------------------------------------------------------------------------
cat("== Test 3: small dataset, SWiM and RQ4 branches ==\n")
x <- run(3, 7, file.path(tmp, "small"))
check(length(x$res$models) > 0, "pipeline runs with 3 studies per feature")
check(any(sapply(x$res$swim, function(s) s$name == "RQ4_vegetation")), "RQ4 vegetation (2 studies) goes to SWiM, not pooled")
check(!is.null(get(x$res, "RQ4_lighting")$ratio), "RQ4 lighting (4 studies) pooled as log relative effect")
rq1s <- Filter(function(m) startsWith(m$name, "RQ1_"), x$res$models)
check(all(sapply(rq1s, function(m) m$robust %in% c("robust", "not robust", "robustness not assessable"))), "every RQ1 decision carries a robustness label")
check(all(sapply(Filter(function(m) startsWith(m$name, "RQ2_"), big$res$models), function(m) m$family_size >= 1)), "RQ2 Holm family size recorded")
# a pair_id used twice for one gender must stop the analysis (protocol 2.4)
dup_dir <- file.path(tmp, "dup"); dir.create(dup_dir, showWarnings = FALSE)
for (f in c("extraction_gap.csv", "extraction_actual.csv")) file.copy(file.path(tmp, "small", f), dup_dir, overwrite = TRUE)
ex <- read.csv(file.path(tmp, "small", "extraction.csv"), stringsAsFactors = FALSE, na.strings = c("", "NA"))
w <- which(ex$gender == "women" & !is.na(ex$pair_id))[1:2]
ex$study_id[w[2]] <- ex$study_id[w[1]]; ex$feature[w[2]] <- ex$feature[w[1]]; ex$pair_id[w[2]] <- ex$pair_id[w[1]]
write.csv(ex, file.path(dup_dir, "extraction.csv"), row.names = FALSE, na = "")
msg <- suppressWarnings(system2(R, c("05_analysis/analysis.R", shQuote(dup_dir), shQuote(file.path(dup_dir, "r.json"))), stdout = FALSE, stderr = TRUE))
check(!is.null(attr(msg, "status")) && any(grepl("pair_id must link", msg)), "analysis stops when one pair_id links two effects of the same gender")
cf_diff <- sapply(names(big$res$sensitivity$without_ceiling_floor$rq1), function(f)
  big$res$sensitivity$without_ceiling_floor$rq1[[f]]$estimate - get(big$res, paste0("RQ1_", f))$estimate)
check(any(abs(unlist(cf_diff)) > 0), "ceiling/floor sensitivity removes the flagged conditions")
check(length(big$res$feature_status) == 6, "every feature has a status line")
check(is.finite(get(x$res, "RQ4_lighting")$estimate), "RQ4 pooled estimate finite with a zero count (0.5 rule)")
pw <- sapply(big$res$rq2_pomp, function(p) p$ci_ub - p$ci_lb)
check(length(pw) > 0 && all(pw < 30), sprintf("RQ2 POMP intervals plausible (widest %.1f points)", max(pw)))

write_json(list(date = as.character(Sys.Date()), n_reps = n_reps, coverage_rq1 = mean(cov1), coverage_rq2 = mean(cov2),
                mean_est_rq1 = mean(est1), mean_est_rq2 = mean(est2), failures = fails),
           "05_analysis/simulated/test_pipeline_summary.json", auto_unbox = TRUE, pretty = TRUE, digits = NA)
cat(if (length(fails)) sprintf("\nRESULT: FAILED (%d)\n", length(fails)) else "\nRESULT: PASSED\n")
quit(status = if (length(fails)) 1 else 0)
