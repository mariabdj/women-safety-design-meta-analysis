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
tau_gender <- 0.08  # spread of the women-men difference between studies
sd_rating <- 1.2    # SD of a 1-7 safety rating
r_true    <- 0.5    # correlation between the two ratings in within-subject designs

summarise <- function(x) c(m = mean(x), sd = sd(x), n = length(x))

rows <- list(); sid <- 0; eid <- 0
for (f in features) for (s in seq_len(n_per_feature)) {
  sid <- sid + 1
  study <- sprintf("S%03d", sid)
  design <- if (runif(1) < 0.6) "within" else "between"
  fear_scale <- runif(1) < 0.25               # some studies ask about fear (higher = worse)
  reports_se <- runif(1) < 0.15               # some papers give standard errors instead of SDs
  study_design <- if (runif(1) < 0.8) "experiment" else "place comparison"
  seen <- if (runif(1) < 0.1) "yes" else "no"  # conclusions seen before Stage 1 (protocol 2.13)
  u <- rnorm(1, 0, tau_study)                 # study-level deviation, shared by women and men
  J <- sample(1:3, 1)                         # 1 to 3 scenes per study
  n_items <- if (runif(1) < 0.2) 2 else 1     # some studies report two safety items and no composite
  e <- rnorm(J, 0, tau_es)                    # scene-level deviations, shared by women and men
  for (gnd in c("women", "men")) {
    # the gender difference also varies a little between studies and scenes, as it would in real data
    ug <- rnorm(1, 0, tau_gender); eg <- rnorm(J, 0, tau_gender / 2)
    delta <- (if (gnd == "women") true_w[f] else true_m[f]) + u + e + ug + eg
    base <- 4 - (gnd == "women") * 0.4        # women start lower (baseline gap)
    n <- sample(30:110, 1)
    if (design == "within") {
      # the same participants rate the control scene and every treated scene, so sampling errors are correlated
      S <- matrix(r_true, J + 1, J + 1); diag(S) <- 1
      x <- mvrnorm(n, c(base, base + delta * sd_rating), sd_rating^2 * S)
      ctl <- summarise(x[, 1]); trts <- lapply(seq_len(J), function(j) summarise(x[, j + 1]))
      r_rep <- sapply(seq_len(J), function(j) cor(x[, 1], x[, j + 1]))
    } else {
      # one control group shared by all treated scenes (a multi-arm design)
      ctl <- summarise(rnorm(sample(30:110, 1), base, sd_rating))
      trts <- lapply(seq_len(J), function(j) summarise(rnorm(sample(30:110, 1), base + delta[j] * sd_rating, sd_rating)))
      r_rep <- rep(NA, J)
    }
    report_r <- design == "within" && runif(1) > 0.33   # a third of within-subject studies do not report r
    for (j in seq_len(J)) for (it in seq_len(n_items)) {
      trt <- trts[[j]]; c0 <- ctl
      if (it == 2) { trt["m"] <- trt[["m"]] + rnorm(1, 0, 0.05); c0["m"] <- c0[["m"]] + rnorm(1, 0, 0.05) }
      if (fear_scale) { c0["m"] <- 8 - c0["m"]; trt["m"] <- 8 - trt["m"] }
      if (reports_se) { trt["sd"] <- trt[["sd"]] / sqrt(trt[["n"]]); c0["sd"] <- c0[["sd"]] / sqrt(c0[["n"]]) }
      eid <- eid + 1
      rows[[eid]] <- data.frame(
        es_id = sprintf("E%04d", eid), study_id = study, sample_id = paste0(study, "_", gnd),
        contrast = sprintf("scene %d %s: changed vs control", j, letters[it]),
        # pair_id links one women's and one men's effect; a few men's rows have no match (empty)
        pair_id = if (gnd == "men" && runif(1) < 0.05) NA else paste0(j, letters[it]), study_design = study_design,
        seen_before_stage1 = seen, author = "Simulated", year = 2020, country = "simulated", setting = "simulated street", age = "mean 30", light_type = if (f == "lighting") "LED, white" else NA,
        feature = f, gender = gnd, design = design, stimulus = "photo", time_of_day = "night",
        outcome_measure = if (fear_scale) "fear rating" else "safety rating", scale_min = 1, scale_max = 7,
        higher_is_safer = if (fear_scale) "no" else "yes", es_method = "means",
        n_t = trt[["n"]], m_t = trt[["m"]], sd_t = trt[["sd"]], n_c = c0[["n"]], m_c = c0[["m"]], sd_c = c0[["sd"]],
        dispersion_type = if (reports_se) "SE" else "SD",
        r_within = if (report_r) round(r_rep[j], 3) else NA,
        events_t = NA, events_c = NA,   # proportions: converter added before extraction (Appendix F)
        stat_value = NA, stat_df = NA, stat_ci_low = NA, stat_ci_high = NA, reported_g = NA,
        source_location = "simulated", data_from_author = if (runif(1) < 0.15) "yes" else "no", notes = "",
        outcome_type = "perceived", outcome_source = "self-report", unit_of_analysis = "person",
        rob_overall = sample(c("low", "some concerns", "high"), 1, prob = c(0.4, 0.4, 0.2)),
        adult_sample = if (runif(1) < 0.9) "yes" else "no"
      )
    }
  }
}
extraction <- do.call(rbind, rows)
# risk of bias is rated per study and adult status is a property of the sample: one value each
extraction$rob_overall <- ave(extraction$rob_overall, extraction$study_id, FUN = function(v) v[1])
extraction$adult_sample <- ave(extraction$adult_sample, extraction$sample_id, FUN = function(v) v[1])
# a pair_id without its partner of the other gender is left empty (protocol 2.4)
pk <- paste(extraction$study_id, extraction$feature, extraction$pair_id)
both <- tapply(extraction$gender, pk, function(g) all(c("women", "men") %in% g))
extraction$pair_id[!is.na(extraction$pair_id) & !both[pk]] <- NA
# some between-subject rows report only a t statistic (es_method t_between)
tb <- which(extraction$design == "between" & extraction$dispersion_type == "SD")
tb <- tb[seq_len(min(length(tb), max(1, round(0.05 * nrow(extraction)))))]
sp <- sqrt(((extraction$n_t[tb] - 1) * extraction$sd_t[tb]^2 + (extraction$n_c[tb] - 1) * extraction$sd_c[tb]^2) /
           (extraction$n_t[tb] + extraction$n_c[tb] - 2))
extraction$stat_value[tb] <- (extraction$m_t[tb] - extraction$m_c[tb]) / (sp * sqrt(1 / extraction$n_t[tb] + 1 / extraction$n_c[tb]))
extraction$es_method[tb] <- "t_between"
# a few control conditions close to the bottom of the 1-7 scale, so the ceiling/floor sensitivity has work to do
cf <- which(extraction$higher_is_safer == "yes")[1:3]
shift <- extraction$m_c[cf] - 1.3
extraction$m_c[cf] <- 1.3; extraction$m_t[cf] <- pmax(extraction$m_t[cf] - shift, 1.05)   # means stay on the 1-7 scale

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
    gse <- (s %% 5) == 0                      # every fifth study reports SEs
    gap_rows[[g]] <- data.frame(gap_id = sprintf("G%04d", g), study_id = sprintf("R%03d", s), scene_id = paste0("S", sc),
                                scene_name = paste("street scene", sc), scene_score = sc,
                                baseline = if (sc == min(scores)) "yes" else "no", higher_is_safer = "yes", scale_min = 1, scale_max = 7,
                                n_w = nw, m_w = mean(w), sd_w = if (gse) sd(w) / sqrt(nw) else sd(w),
                                n_m = nm, m_m = mean(m), sd_m = if (gse) sd(m) / sqrt(nm) else sd(m),
                                dispersion_type = if (gse) "SE" else "SD",
                                source_location = "simulated")
  }
}
gaps <- do.call(rbind, gap_rows)
fs <- gaps$study_id == gaps$study_id[1]   # one study measured fear (higher = worse): flip its means
gaps$m_w[fs] <- 8 - gaps$m_w[fs]; gaps$m_m[fs] <- 8 - gaps$m_m[fs]; gaps$higher_is_safer[fs] <- "no"

# RQ4: counts of harm against women, before and after, treated and control areas.
# Few studies on purpose (as in the real literature): lighting gets 4, vegetation 2 (SWiM branch).
true_lrr <- c(lighting = 0.20, vegetation = 0.10)
act_rows <- list(); a <- 0
for (f in names(true_lrr)) for (s in seq_len(if (f == "lighting") 4 else 2)) {
  a <- a + 1
  base <- sample(40:120, 1)
  effect <- exp(-(true_lrr[[f]] + rnorm(1, 0, 0.05)))     # fewer incidents after, in the treated area
  act_rows[[a]] <- data.frame(act_id = sprintf("A%03d", a), study_id = sprintf("C%03d", a),
                              contrast = paste0(if (f == "lighting") "relit" else "replanted", " streets vs comparison streets, year before vs year after"), feature = f,
                              metric = "counts", outcome_measure = "harassment", outcome_source = "police records",
                              ctrl_before = rpois(1, base), ctrl_after = rpois(1, base),
                              trt_before = rpois(1, base), trt_after = rpois(1, base * effect),
                              source_location = "simulated", notes = NA)
}
actual <- do.call(rbind, act_rows)
actual$trt_after[1] <- 0   # a lighting comparison (pooled branch) exercises the 0.5 rule (protocol 2.7)

write.csv(extraction, file.path(out_dir, "extraction.csv"), row.names = FALSE, na = "")
write.csv(gaps, file.path(out_dir, "extraction_gap.csv"), row.names = FALSE, na = "")
write.csv(actual, file.path(out_dir, "extraction_actual.csv"), row.names = FALSE, na = "")
write_json(list(seed = seed, n_per_feature = n_per_feature, true_women = as.list(true_w), true_men = as.list(true_m),
                true_diff = as.list(true_w - true_m), gap_intercept = gap_intercept, gap_slope = gap_slope,
                true_log_relative_effect = as.list(true_lrr)),
           file.path(out_dir, "truth.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)
cat(sprintf("Simulated %d effect sizes from %d studies, %d gap rows, %d actual-safety studies -> %s\n",
            nrow(extraction), length(unique(extraction$study_id)), nrow(gaps), nrow(actual), out_dir))
