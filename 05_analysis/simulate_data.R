# Simulated data for testing the analysis pipeline before any real data exist (protocol Appendix F).
# Nothing here is real: the "true" effects below are made up so I can check that analysis.R
# finds them again. Participants are simulated one by one, then summarised the way papers report them.
#
# Usage (from Projet1_Meta-Analyse/):
#   Rscript 05_analysis/simulate_data.R [n_studies_per_feature] [seed] [out_dir]
# Writes: extraction.csv (perceived safety), extraction_gap.csv (RQ3 and baseline check),
#         extraction_actual.csv (RQ4 counts), truth.json (the values we expect back)

suppressPackageStartupMessages({ library(MASS); library(jsonlite) })

args <- commandArgs(trailingOnly = TRUE)
n_per_feature <- if (length(args) >= 1) as.integer(args[1]) else 8
seed          <- if (length(args) >= 2) as.integer(args[2]) else 2026
out_dir       <- if (length(args) >= 3) args[3] else "05_analysis/simulated"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
set.seed(seed)

features <- c("lighting", "vegetation", "sightlines", "active_frontages", "maintenance", "presence_of_others")
# made-up true effects (Hedges' g scale): women and men
true_w <- c(0.45, 0.10, 0.35, 0.20, 0.25, 0.00)
true_m <- c(0.20, 0.10, 0.15, 0.20, 0.25, 0.00)
names(true_w) <- names(true_m) <- features
tau_study <- 0.12   # spread of true effects between studies
tau_es    <- 0.08   # spread between effect sizes inside a study
sd_rating <- 1.2    # SD of a 1-7 safety rating
r_true    <- 0.5    # correlation between the two ratings in within-subject designs

summarise <- function(x) c(m = mean(x), sd = sd(x), n = length(x))

rows <- list(); sid <- 0; eid <- 0
for (f in features) for (s in seq_len(n_per_feature)) {
  sid <- sid + 1
  study <- sprintf("S%03d", sid)
  design <- if (runif(1) < 0.6) "within" else "between"
  fear_scale <- runif(1) < 0.25               # some studies ask about fear (higher = worse)
  u <- rnorm(1, 0, tau_study)                 # study-level deviation, shared by women and men
  for (j in seq_len(sample(1:3, 1))) {        # 1 to 3 scenes per study
    e <- rnorm(1, 0, tau_es)
    for (gnd in c("women", "men")) {
      delta <- (if (gnd == "women") true_w[f] else true_m[f]) + u + e
      n <- sample(30:110, 1)
      base <- 4 - (gnd == "women") * 0.4      # women start lower (baseline gap)
      if (design == "within") {
        x <- mvrnorm(n, c(base, base + delta * sd_rating), sd_rating^2 * matrix(c(1, r_true, r_true, 1), 2))
        ctl <- summarise(x[, 1]); trt <- summarise(x[, 2]); r_rep <- cor(x[, 1], x[, 2])
        n_c <- n
      } else {
        n_c <- sample(30:110, 1)
        ctl <- summarise(rnorm(n_c, base, sd_rating)); trt <- summarise(rnorm(n, base + delta * sd_rating, sd_rating))
        r_rep <- NA
      }
      if (fear_scale) { ctl["m"] <- 8 - ctl["m"]; trt["m"] <- 8 - trt["m"] }
      eid <- eid + 1
      rows[[eid]] <- data.frame(
        es_id = sprintf("E%04d", eid), study_id = study, author = "Simulated", year = 2020, country = "NA",
        feature = f, gender = gnd, design = design, stimulus = "photo", time_of_day = "night",
        outcome_measure = if (fear_scale) "fear rating" else "safety rating", scale_min = 1, scale_max = 7,
        higher_is_safer = if (fear_scale) "no" else "yes", es_method = "means",
        n_t = trt[["n"]], m_t = trt[["m"]], sd_t = trt[["sd"]], n_c = ctl[["n"]], m_c = ctl[["m"]], sd_c = ctl[["sd"]],
        dispersion_type = "SD",
        # about a third of within-subject studies do not report r: left NA so the imputation is exercised
        r_within = if (design == "within" && runif(1) > 0.33) round(r_rep, 3) else NA,
        stat_value = NA, stat_ci_low = NA, stat_ci_high = NA, reported_g = NA,
        source_location = "simulated", data_from_author = if (runif(1) < 0.15) "yes" else "no", notes = "",
        outcome_type = "perceived", outcome_source = "self-report", unit_of_analysis = "person",
        rob_overall = sample(c("low", "some concerns", "high"), 1, prob = c(0.4, 0.4, 0.2)),
        adult_sample = if (runif(1) < 0.9) "yes" else "no"
      )
    }
  }
}
extraction <- do.call(rbind, rows)

# RQ3 and the baseline check: women's and men's ratings of whole scenes with a favourable-feature score 0-6.
# True gap (standardised, positive = women feel less safe) shrinks with the score.
gap_intercept <- 0.45; gap_slope <- -0.05
gap_rows <- list(); g <- 0
for (s in seq_len(max(12, n_per_feature * 2))) {
  u <- rnorm(1, 0, 0.08)
  scores <- sort(sample(0:6, sample(2:4, 1)))
  for (sc in scores) {
    g <- g + 1
    gap <- gap_intercept + gap_slope * sc + u + rnorm(1, 0, 0.05)
    nw <- sample(30:110, 1); nm <- sample(30:110, 1)
    w <- rnorm(nw, 4 - gap * sd_rating, sd_rating); m <- rnorm(nm, 4, sd_rating)
    gap_rows[[g]] <- data.frame(gap_id = sprintf("G%04d", g), study_id = sprintf("R%03d", s), scene_score = sc,
                                baseline = if (sc == min(scores)) "yes" else "no", higher_is_safer = "yes",
                                n_w = nw, m_w = mean(w), sd_w = sd(w), n_m = nm, m_m = mean(m), sd_m = sd(m),
                                source_location = "simulated")
  }
}
gaps <- do.call(rbind, gap_rows)

# RQ4: counts of harm against women, before and after, treated and control areas.
# Few studies on purpose (as in the real literature): lighting gets 4, vegetation 2 (SWiM branch).
true_lrr <- c(lighting = 0.20, vegetation = 0.10)
act_rows <- list(); a <- 0
for (f in names(true_lrr)) for (s in seq_len(if (f == "lighting") 4 else 2)) {
  a <- a + 1
  base <- sample(40:120, 1)
  effect <- exp(-(true_lrr[[f]] + rnorm(1, 0, 0.05)))     # fewer incidents after, in the treated area
  act_rows[[a]] <- data.frame(act_id = sprintf("A%03d", a), study_id = sprintf("C%03d", a), feature = f,
                              metric = "counts",
                              ctrl_before = rpois(1, base), ctrl_after = rpois(1, base),
                              trt_before = rpois(1, base), trt_after = rpois(1, base * effect),
                              source_location = "simulated")
}
actual <- do.call(rbind, act_rows)

write.csv(extraction, file.path(out_dir, "extraction.csv"), row.names = FALSE, na = "")
write.csv(gaps, file.path(out_dir, "extraction_gap.csv"), row.names = FALSE, na = "")
write.csv(actual, file.path(out_dir, "extraction_actual.csv"), row.names = FALSE, na = "")
write_json(list(seed = seed, n_per_feature = n_per_feature, true_women = as.list(true_w), true_men = as.list(true_m),
                true_diff = as.list(true_w - true_m), gap_intercept = gap_intercept, gap_slope = gap_slope,
                true_log_relative_effect = as.list(true_lrr)),
           file.path(out_dir, "truth.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)
cat(sprintf("Simulated %d effect sizes from %d studies, %d gap rows, %d actual-safety studies -> %s\n",
            nrow(extraction), length(unique(extraction$study_id)), nrow(gaps), nrow(actual), out_dir))
