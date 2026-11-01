# Appendix F: coverage and calibration of the RQ1 and RQ2 intervals over many simulated reviews.
# Each run simulates 8 studies per feature (simulate_data.R, seeds 5001...), fits the lighting models
# with the functions of analysis.R (no sensitivity runs) and records whether the 95% CI holds the truth.
# Usage (from Projet1_Meta-Analyse/): Rscript verification/verify_coverage.R [n_runs = 300] [out.csv]
# Pass criteria, for RQ1 and RQ2 lighting:
#   1. not anti-conservative: the exact 95% CI of the coverage reaches 0.95 or above
#   2. SE calibrated: mean model SE / SD of the estimates between 0.85 and 1.15
#   3. unbiased: |mean estimate - truth| < 0.03
# Coverage above 0.95 is reported, not failed: with few studies the t distribution with k - 1 df
# makes intervals wider than a normal one even when the SE is right (protocol, Appendix F).
# Exit code 0 = PASS, 1 = FAIL.

suppressPackageStartupMessages({ library(metafor); library(clubSandwich); library(jsonlite) })
args <- commandArgs(trailingOnly = TRUE)
n <- if (length(args) >= 1) as.integer(args[1]) else 300
out <- if (length(args) >= 2) args[2] else "05_analysis/simulated/coverage_runs.csv"
an <- if (length(args) >= 3) args[3] else "05_analysis/analysis.R"   # the analysis file whose functions are tested

source("05_analysis/effect_sizes.R")
# take only the constants and function definitions of analysis.R (the rest of that file reads real data);
# this evaluates our own source file, nothing downloaded
keep <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("<-")) &&
  (is.call(e[[3]]) && identical(e[[3]][[1]], as.name("function")) ||
   deparse(e[[2]]) %in% c("ALPHA", "SESOI", "MIN_K", "MIN_K_MOD", "RHO")), as.list(parse(an)))
for (e in keep) eval(e, globalenv())

R <- file.path(R.home("bin"), "Rscript"); tmp <- tempfile(); res <- NULL
for (i in seq_len(n)) {
  seed <- 5000 + i
  unlink(file.path(tmp, c("extraction.csv", "truth.json")))   # never reuse the previous run's files
  st <- system2(R, c("05_analysis/simulate_data.R", 8, seed, shQuote(tmp)), stdout = FALSE, stderr = FALSE)
  if (!identical(as.integer(st), 0L) || !file.exists(file.path(tmp, "truth.json"))) stop("simulation failed for seed ", seed)
  tr <- fromJSON(file.path(tmp, "truth.json"))
  d <- compute_es(read.csv(file.path(tmp, "extraction.csv"), stringsAsFactors = FALSE, na.strings = c("", "NA")))
  d <- d[is.na(d$adult_sample) | d$adult_sample == "yes", ]
  s1 <- d[d$feature == "lighting" & d$gender == "women", ]; m1 <- fit_che(s1)
  pd <- pair_diffs(d[d$feature == "lighting", ]); m2 <- fit_che(pd)
  res <- rbind(res, data.frame(seed = seed,
    est1 = as.numeric(m1$beta), se1 = m1$se, cov1 = m1$ci.lb <= tr$true_women$lighting && tr$true_women$lighting <= m1$ci.ub,
    est2 = as.numeric(m2$beta), se2 = m2$se, cov2 = m2$ci.lb <= tr$true_diff$lighting && tr$true_diff$lighting <= m2$ci.ub,
    k2 = length(unique(pd$study_id)), fit2 = m2$fit_note))
}
write.csv(res, out, row.names = FALSE)

fails <- character(0)
for (q in c(1, 2)) {
  cv <- res[[paste0("cov", q)]]; est <- res[[paste0("est", q)]]; se <- res[[paste0("se", q)]]
  truth <- if (q == 1) tr$true_women$lighting else tr$true_diff$lighting
  ci <- binom.test(sum(cv), n)$conf.int; ratio <- mean(se) / sd(est)
  lab <- if (q == 1) "RQ1 lighting" else "RQ2 lighting"
  cat(sprintf("%s: coverage %d/%d = %.3f (exact 95%% CI %.3f to %.3f); mean SE / SD of estimates = %.2f; mean estimate %.3f vs truth %.2f\n",
              lab, sum(cv), n, mean(cv), ci[1], ci[2], ratio, mean(est), truth))
  if (ci[2] < 0.95) fails <- c(fails, sprintf("%s: intervals too narrow (coverage CI below 0.95)", lab))
  if (ratio < 0.85 || ratio > 1.15) fails <- c(fails, sprintf("%s: SE not calibrated (ratio %.2f)", lab, ratio))
  if (abs(mean(est) - truth) >= 0.03) fails <- c(fails, sprintf("%s: biased (%.3f vs %.2f)", lab, mean(est), truth))
}
if (length(fails)) { cat(paste("FAIL", fails), sep = "\n"); cat("RESULT: FAILED\n"); quit(status = 1) }
cat(sprintf("RESULT: PASSED (%d simulated reviews)\n", n))
