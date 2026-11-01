# Main analysis (protocol sections 2.7 to 2.11). Every pooled number in the paper comes from results.json.
#
# Usage (from Projet1_Meta-Analyse/):
#   Rscript 05_analysis/analysis.R [data_dir] [results.json]
# data_dir must contain extraction.csv; extraction_gap.csv and extraction_actual.csv are used if present.
# Default: 03_extraction/ -> 05_analysis/results/results.json
# Tested on simulated data before any real data were extracted (Appendix F, test_pipeline.R).

suppressPackageStartupMessages({ library(metafor); library(clubSandwich); library(jsonlite) })

args <- commandArgs(trailingOnly = TRUE)
data_dir <- if (length(args) >= 1) args[1] else "03_extraction"
out_path <- if (length(args) >= 2) args[2] else "05_analysis/results/results.json"
here <- dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE))))
source(file.path(here, "effect_sizes.R"))

ALPHA <- 0.05; SESOI <- 0.20; MIN_K <- 3; MIN_K_MOD <- 10
RHO <- 0.6        # assumed correlation between sampling errors of effects from the same study (protocol 2.8)
read <- function(f) read.csv(file.path(data_dir, f), stringsAsFactors = FALSE, na.strings = c("", "NA"))
n_studies <- function(s) length(unique(s$study_id))
has <- function(d, col) col %in% names(d)

raw <- read("extraction.csv")
raw_perc <- raw[is.na(raw$outcome_type) | raw$outcome_type == "perceived", ]
# main analysis: adults only (protocol 2.1); adolescent samples come back in a sensitivity analysis
main_rows <- function(d) if (has(d, "adult_sample")) d[is.na(d$adult_sample) | d$adult_sample == "yes", ] else d

# ---- model -----------------------------------------------------------------------------------------------

# Correlated-and-hierarchical-effects model (Pustejovsky & Tipton 2022): random effects for studies and for
# effects within studies, plus correlated sampling errors (rho) within a study. rho = 0 is the plain
# three-level model. df from the containment method, i.e. based on the number of studies (dfs = "contain").
# Fallback written in the protocol: second optimiser, then a model with study-level random effects only.
fit_che <- function(s, mods = NULL, rho = RHO) {
  V <- if (rho > 0 && nrow(s) > 1) vcalc(vi, cluster = study_id, obs = es_id, rho = rho, data = s) else s$vi
  one <- function(random, ctrl) {
    if (is.null(mods)) rma.mv(yi, V, random = random, data = s, test = "t", dfs = "contain", method = "REML", control = ctrl)
    else rma.mv(yi, V, mods = mods, random = random, data = s, test = "t", dfs = "contain", method = "REML", control = ctrl)
  }
  m <- tryCatch(one(~ 1 | study_id / es_id, list()), error = function(e) NULL)
  bfgs <- is.null(m)
  # reltol: the default BFGS tolerance can stop short of the REML maximum when a variance is near 0
  if (is.null(m)) m <- tryCatch(one(~ 1 | study_id / es_id, list(optimizer = "optim", optmethod = "BFGS", reltol = 1e-14)), error = function(e) NULL)
  if (!is.null(m)) { m$fit_note <- paste0(if (rho > 0) paste0("CHE, rho = ", rho) else "three-level (rho = 0)", if (bfgs) " (BFGS optimiser)" else ""); return(m) }
  m <- one(~ 1 | study_id, list())
  m$fit_note <- "fallback: study-level random effects only (full model did not converge)"
  m
}

# multilevel I2 per level (Cheung 2014): share of total variance at each level, using the "typical" sampling variance
i2_levels <- function(m) {
  W <- diag(1 / m$vi); X <- model.matrix(m)
  P <- W - W %*% X %*% solve(t(X) %*% W %*% X) %*% t(X) %*% W
  v_typ <- (m$k - m$p) / sum(diag(P))
  100 * m$sigma2 / (sum(m$sigma2) + v_typ)
}

# smallest effect detectable with 80% power for this k, typical variance and tau2, at a given alpha (protocol 2.9)
mde80 <- function(k, v, tau2, alpha) {
  if (k < 2) return(NA)
  pw <- function(d) { se <- sqrt((v + tau2) / k); tc <- qt(1 - alpha / 2, k - 1)
                      pt(-tc, k - 1, d / se) + 1 - pt(tc, k - 1, d / se) }
  uniroot(function(d) pw(d) - 0.80, c(1e-6, 10), extendInt = "upX")$root
}

# number of participants: one count per study (largest sample reported), not one per effect size
n_people <- function(s) {
  n <- if (has(s, "n_c")) ifelse(!is.na(s$design) & s$design == "between", s$n_t + s$n_c, s$n_t) else s$n_t
  if (is.null(n)) return(NA)
  sum(tapply(n, s$study_id, max, na.rm = TRUE))
}

# one coefficient of a fitted model, in the format verify_model.R reads
summarise_coef <- function(m, s, name, coef = 1, with_pi = TRUE) {
  b <- as.numeric(m$beta[coef]); se <- m$se[coef]; df <- m$ddf[coef]
  ci90 <- b + c(-1, 1) * qt(0.95, df) * se
  i2 <- i2_levels(m)
  out <- list(name = name, k = n_studies(s), n_es = nrow(s), n_participants = n_people(s),
              estimate = b, se = se, df = df, ci_lb = m$ci.lb[coef], ci_ub = m$ci.ub[coef], pval = m$pval[coef],
              ci90_lb = ci90[1], ci90_ub = ci90[2],
              tau2_study = m$sigma2[1], tau2_es = if (length(m$sigma2) > 1) m$sigma2[2] else NA,
              tau2 = sum(m$sigma2), i2_study = i2[1], i2_es = if (length(i2) > 1) i2[2] else NA, i2 = sum(i2),
              fit = m$fit_note)
  if (with_pi) { p <- predict(m); out$pi_lb <- p$pi.lb[1]; out$pi_ub <- p$pi.ub[1] }
  if (out$k >= MIN_K_MOD) {   # CR2 robustness check (protocol 2.8): never decides, only enters the robust label
    rob <- coef_test(m, vcov = "CR2", cluster = s$study_id)
    out$cr2_se <- rob$SE[coef]; out$cr2_df <- rob$df_Satt[coef]; out$cr2_pval <- rob$p_Satt[coef]
    out$cr2_ci_lb <- b - qt(0.975, out$cr2_df) * out$cr2_se; out$cr2_ci_ub <- b + qt(0.975, out$cr2_df) * out$cr2_se
    out$cr2_p_tost <- max(pt((b + SESOI) / out$cr2_se, out$cr2_df, lower.tail = FALSE), pt((b - SESOI) / out$cr2_se, out$cr2_df))
  }
  out$v_typ <- median(s$vi)
  out$mde80 <- mde80(out$k, out$v_typ, out$tau2, ALPHA)
  # equivalence test (TOST) against +/- SESOI: p is the larger of the two one-sided p-values
  out$p_tost <- max(pt((b + SESOI) / se, df, lower.tail = FALSE), pt((b - SESOI) / se, df))
  out
}

# decision rule of protocol 2.9, applied after Holm adjustment, in this order
decide <- function(p_holm, p_tost_holm, estimate) {
  sig <- p_holm < ALPHA; eq <- p_tost_holm < ALPHA
  if (sig && eq) return(paste0("present but smaller than the SESOI (", if (estimate > 0) "positive" else "negative", ")"))
  if (sig) return(if (estimate > 0) "supported" else "opposite direction")
  if (eq) return("equivalent (no meaningful effect)")
  "inconclusive"
}

# Holm family = the features that reach k >= 3 and are tested (protocol 2.8)
# In sensitivity analyses the family size stays that of the main analysis (m_fixed), as protocol 2.10 says;
# only if a set makes more features testable (adolescents added) does it grow to that number (protocol 2.10).
holm <- function(models, pfield = "pval", tfield = "p_tost", m_fixed = NULL) {
  if (!length(models)) return(models)
  m_fam <- if (is.null(m_fixed)) length(models) else max(m_fixed, length(models))
  p <- p.adjust(sapply(models, function(x) x[[pfield]]), method = "holm", n = m_fam)
  pe <- p.adjust(sapply(models, function(x) x[[tfield]]), method = "holm", n = m_fam)
  for (i in seq_along(models)) {
    models[[i]]$family_size <- m_fam
    models[[i]]$p_holm <- p[i]; models[[i]]$p_tost_holm <- pe[i]
    models[[i]]$decision <- decide(p[i], pe[i], models[[i]]$estimate)
    models[[i]]$mde80_strictest_holm <- mde80(models[[i]]$k, models[[i]]$v_typ, models[[i]]$tau2, ALPHA / m_fam)
  }
  models
}

# SWiM summary when fewer than 3 studies (protocol 2.8): direction of each study's effect, no formal test
swim <- function(s, name) {
  per_study <- tapply(s$yi, s$study_id, mean)
  pos <- sum(per_study > 0); neg <- sum(per_study < 0)
  list(name = name, k = length(per_study), n_es = nrow(s), method = "SWiM direction count (no formal test)",
       n_positive = pos, n_negative = neg)
}

# ---- the two hypothesis families, as one function so every sensitivity analysis reruns them the same way ----

# RQ2 data: within each study and scene (pair_id), women's g minus men's g; independent groups, so v_w + v_m
# pair_id links exactly one women's and one men's effect (same scene, item and contrast); empty = no match
pair_diffs <- function(s) {
  if (!has(s, "pair_id")) return(s[0, c("study_id", "yi", "vi")])
  w <- s[s$gender == "women" & !is.na(s$pair_id), ]; mn <- s[s$gender == "men" & !is.na(s$pair_id), ]
  if (!nrow(w) || !nrow(mn)) return(s[0, c("study_id", "yi", "vi")])
  key <- c("study_id", "pair_id")
  if (any(duplicated(w[, key])) || any(duplicated(mn[, key])))
    stop("pair_id must link exactly one women's and one men's effect within a study and feature")
  p <- merge(w, mn, by = key, suffixes = c("_w", "_m"))
  if (!nrow(p)) return(s[0, c("study_id", "yi", "vi")])   # pair labels present but no women-men match
  n_of <- function(des, nt, nc) ifelse(!is.na(des) & des == "between", nt + nc, nt)
  data.frame(study_id = p$study_id, es_id = paste(p$study_id, p$pair_id, sep = "_"),
             yi = p$yi_w - p$yi_m, vi = p$vi_w + p$vi_m,
             n_t = n_of(p$design_w, p$n_t_w, p$n_c_w) + n_of(p$design_m, p$n_t_m, p$n_c_m),
             design = "pair", stringsAsFactors = FALSE)
}

run_families <- function(dd, rho = RHO, m_fixed = NULL) {
  out <- list(rq1 = list(), rq2 = list(), swim = list())
  for (f in sort(unique(dd$feature))) {
    s <- dd[dd$feature == f & dd$gender == "women", ]
    if (n_studies(s) >= MIN_K) out$rq1[[f]] <- summarise_coef(fit_che(s, rho = rho), s, paste0("RQ1_", f))
    else out$swim[[length(out$swim) + 1]] <- swim(s, paste0("RQ1_", f))
    pd <- pair_diffs(dd[dd$feature == f, ])
    if (n_studies(pd) >= MIN_K) out$rq2[[f]] <- summarise_coef(fit_che(pd, rho = rho), pd, paste0("RQ2_", f))
    else if (nrow(pd)) out$swim[[length(out$swim) + 1]] <- swim(pd, paste0("RQ2_", f))
  }
  out$rq1 <- holm(out$rq1, m_fixed = m_fixed$rq1); out$rq2 <- holm(out$rq2, m_fixed = m_fixed$rq2)
  out
}


# ---- effect sizes and main analysis ---------------------------------------------------------------------
d_all <- compute_es(raw_perc)
d <- main_rows(d_all)
main <- run_families(d)
rq1 <- main$rq1; rq2 <- main$rq2; swims <- main$swim
# protocol 2.8: every feature is reported, with "not tested" when fewer than 3 studies (or no matched pairs)
all_features <- sort(unique(raw_perc$feature))
status <- lapply(all_features, function(f) list(feature = f,
  rq1 = if (!is.null(rq1[[f]])) "tested" else paste0("not tested (k = ", n_studies(d[d$feature == f & d$gender == "women", ]), ")"),
  rq2 = if (!is.null(rq2[[f]])) "tested" else paste0("not tested (k = ", n_studies(pair_diffs(d[d$feature == f, ])), ")")))

# ---- outcome-neutral check OC1 (baseline gap) and exploratory RQ3 -----------------------------------------
oc1 <- NULL; rq3 <- NULL; oc1_status <- "not possible (no gap data)"
if (file.exists(file.path(data_dir, "extraction_gap.csv"))) {
  gp <- read("extraction_gap.csv")
  # positive = women feel less safe than men (protocol 2.7); checked in verify_effect_sizes.R
  e <- compute_gap_es(gp)
  e$es_id <- gp$gap_id
  e$n_t <- gp$n_w + gp$n_m
  base <- e[which(gp$baseline == "yes"), ]
  if (n_studies(base) >= MIN_K) {
    oc1 <- summarise_coef(fit_che(base), base, "OC1_baseline_gap")
    oc1$check_passed <- oc1$ci_lb > 0
    oc1_status <- if (oc1$check_passed) "passed" else "failed"
  } else oc1_status <- "not possible (fewer than 3 studies)"
  # RQ3 (exploratory): within-study slope of the gap on the scene score, study mean as a separate term
  scenes <- tapply(e$scene_score, e$study_id, function(x) length(unique(x)))
  multi <- names(scenes[scenes >= 2])
  if (length(multi) >= MIN_K_MOD) {
    s3 <- e[e$study_id %in% multi, ]
    s3$sc_mean <- ave(s3$scene_score, s3$study_id)
    s3$sc_within <- s3$scene_score - s3$sc_mean
    rq3 <- summarise_coef(fit_che(s3, mods = ~ sc_within + sc_mean), s3, "RQ3_exploratory_within_study_slope",
                          coef = 2, with_pi = FALSE)
  }
}
# OC1 qualifies RQ2 and RQ3 (protocol 2.11)
for (f in names(rq2)) {
  rq2[[f]]$oc1_status <- oc1_status
  if (oc1_status == "failed") rq2[[f]]$label <- "positive control not met"
  if (startsWith(oc1_status, "not possible")) rq2[[f]]$label <- "positive control not possible: interpret with caution"
}
if (!is.null(rq3)) {
  rq3$oc1_status <- oc1_status
  rq3$interpretation <- if (oc1_status == "passed") "as planned" else if (oc1_status == "failed")
    "uninformative (positive control not met)" else "interpret with caution (positive control not possible)"
  rq3$ci_reported <- "CR2 (cr2_ci_lb, cr2_ci_ub)"
}

# ---- RQ4: actual safety (counts before and after, treated and control areas) -----------------------------
rq4 <- list(); rq4_overdispersion <- list(); agree <- list()
if (file.exists(file.path(data_dir, "extraction_actual.csv"))) {
  ac <- read("extraction_actual.csv")
  ac <- ac[which(ac$metric == "counts"), ]
  # one effect per study and feature: the one with the most events (protocol 2.8)
  ac$events <- ac$ctrl_before + ac$ctrl_after + ac$trt_before + ac$trt_after
  ac <- ac[order(-ac$events), ]
  ac <- ac[!duplicated(ac[, c("study_id", "feature")]), ]
  # ln RES of Welsh & Farrington (2008), 0.5 rule for zero counts; checked in verify_effect_sizes.R
  ac <- compute_res(ac)
  for (f in sort(unique(ac$feature))) {
    s <- ac[ac$feature == f, ]
    if (n_studies(s) < MIN_K) { swims[[length(swims) + 1]] <- swim(s, paste0("RQ4_", f)); next }
    m <- rma(yi, vi, data = s, method = "REML", test = "knha")
    p <- predict(m)
    rq4[[f]] <- list(name = paste0("RQ4_", f), k = n_studies(s), n_es = nrow(s), estimate = as.numeric(m$beta),
                     se = m$se, ci_lb = m$ci.lb, ci_ub = m$ci.ub, pi_lb = p$pi.lb, pi_ub = p$pi.ub,
                     pval = m$pval, tau2 = m$tau2, i2 = m$I2, ratio = exp(as.numeric(m$beta)))
    # sensitivity: crime counts are often overdispersed, so every variance is doubled (protocol 2.7)
    m2 <- rma(yi, 2 * vi, data = s, method = "REML", test = "knha")
    rq4_overdispersion[[f]] <- list(feature = f, estimate = as.numeric(m2$beta), ci_lb = m2$ci.lb, ci_ub = m2$ci.ub)
  }
  agree <- lapply(names(rq4), function(f) list(feature = f,
    perceived = if (!is.null(rq1[[f]])) sign(rq1[[f]]$estimate) else NA, actual = sign(rq4[[f]]$estimate)))
}

# ---- small-study effects (k >= 10, protocol 2.10) --------------------------------------------------------
egger <- list()
for (f in names(rq1)) {
  s <- d[d$feature == f & d$gender == "women", ]
  if (n_studies(s) < MIN_K_MOD) next
  # modified precision: the sampling SE without the g^2 term (Pustejovsky & Rodgers 2019)
  s$mod_prec <- ifelse(s$design == "between", sqrt((s$n_t + s$n_c) / (s$n_t * s$n_c)), sqrt(2 * (1 - s$r_used) / s$n_t))
  m <- fit_che(s, mods = ~ mod_prec)
  egger[[f]] <- list(feature = f, slope = as.numeric(m$beta[2]), pval = m$pval[2])
}

# ---- sensitivity analyses (protocol 2.10): each reruns both families with the same decision rule ----------
ceiling_floor <- function(dd) {   # control mean within 10% of either end of the scale
  pos <- round((dd$m_c - dd$scale_min) / (dd$scale_max - dd$scale_min), 10)   # so exactly 10% is not flagged by rounding
  !is.na(pos) & (pos < 0.10 | pos > 0.90)
}
MF <- list(rq1 = length(rq1), rq2 = length(rq2))   # Holm family sizes of the main analysis
rf <- function(dd, rho = RHO) run_families(dd, rho = rho, m_fixed = MF)
sets <- list(
  rho_0 = function() rf(d, rho = 0),
  rho_0.3 = function() rf(d, rho = 0.3),
  rho_0.8 = function() rf(d, rho = 0.8),
  r_0.3 = function() rf(main_rows(compute_es(raw_perc, r_impute = 0.3))),
  r_0.7 = function() rf(main_rows(compute_es(raw_perc, r_impute = 0.7))),
  without_high_rob = function() if (has(d, "rob_overall")) rf(d[is.na(d$rob_overall) | d$rob_overall != "high", ]) else NULL,
  without_author_data = function() rf(d[is.na(d$data_from_author) | d$data_from_author != "yes", ]),
  experiments_only = function() if (has(d, "study_design")) rf(d[is.na(d$study_design) | d$study_design != "place comparison", ]) else NULL,
  without_seen_studies = function() if (has(d, "seen_before_stage1")) rf(d[is.na(d$seen_before_stage1) | d$seen_before_stage1 != "yes", ]) else NULL,
  without_ceiling_floor = function() rf(d[!ceiling_floor(d), ])
)
sens <- list()
for (nm in names(sets)) { r <- sets[[nm]](); if (!is.null(r)) sens[[nm]] <- r }
# reported, but not part of the robust label (different population)
with_adolescents <- run_families(d_all, m_fixed = MF)

# leave one study out: refit that feature, keep the other features' p-values for the Holm step
loo_fits <- list()   # model used in each leave-one-out refit (checked by verify_model.R)
loo_decisions <- function(fam_name, fam, make_data) {
  out <- list()
  for (f in names(fam)) {
    s_all <- make_data(f); ids <- as.character(unique(s_all$study_id))   # text keys, also for numeric IDs
    if (length(ids) < MIN_K + 1) { out[[f]] <- NA; next }   # leave-one-out only with at least 4 studies
    out[[f]] <- sapply(setNames(ids, ids), function(id) {
      s <- s_all[as.character(s_all$study_id) != id, ]
      x <- summarise_coef(fit_che(s), s, f)
      loo_fits[[fam_name]][[f]][[id]] <<- x$fit
      ps <- sapply(fam, `[[`, "pval"); pt_ <- sapply(fam, `[[`, "p_tost"); ps[f] <- x$pval; pt_[f] <- x$p_tost
      decide(p.adjust(ps, "holm", n = length(ps))[f], p.adjust(pt_, "holm", n = length(pt_))[f], x$estimate)
    })
  }
  out
}
loo1 <- loo_decisions("rq1", rq1, function(f) d[d$feature == f & d$gender == "women", ])
loo2 <- loo_decisions("rq2", rq2, function(f) pair_diffs(d[d$feature == f, ]))

# CR2 decisions: Holm on CR2 p-values where k >= 10, model-based p otherwise
cr2_decisions <- function(fam) {
  if (!length(fam)) return(character(0))
  for (i in seq_along(fam)) {
    cr <- !is.null(fam[[i]]$cr2_pval)
    fam[[i]]$p_for_cr2 <- if (cr) fam[[i]]$cr2_pval else fam[[i]]$pval
    fam[[i]]$p_for_cr2_tost <- if (cr) fam[[i]]$cr2_p_tost else fam[[i]]$p_tost
  }
  sapply(holm(fam, "p_for_cr2", "p_for_cr2_tost"), `[[`, "decision")
}

# robust label (protocol 2.10): the same decision in every sensitivity set, under CR2, and leaving out each study
label_robust <- function(fam, which, loo) {
  cr2 <- cr2_decisions(fam)
  for (f in names(fam)) {
    alt <- sapply(names(sets), function(nm) { x <- sens[[nm]]; if (is.null(x)) return(NA)
      y <- x[[which]][[f]]; if (is.null(y)) NA else y$decision })
    use_cr2 <- fam[[f]]$k >= MIN_K_MOD
    fam[[f]]$cr2_in_label <- if (use_cr2) "yes" else "no (fewer than 10 studies)"
    alt <- c(alt, if (use_cr2) c(cr2 = unname(cr2[f])), loo = loo[[f]])
    fam[[f]]$decisions_in_sensitivity <- as.list(alt)
    fam[[f]]$loo_fit <- loo_fits[[which]][[f]]
    # a set where the feature cannot be tested (k < 3), or leave-one-out skipped (k < 4): not assessable
    fam[[f]]$robust <- if (any(is.na(alt))) "robustness not assessable" else if (all(alt == fam[[f]]$decision)) "robust" else "not robust"
  }
  fam
}
# RQ2 in POMP units (Cohen et al. 1999): raw mean change of women minus men, as % of the scale range.
# Reported beside the decision only (no equivalence bound), protocol 2.10.
pomp_rq2 <- list()
raw_change <- function(s) {
  rng <- s$scale_max - s$scale_min
  sd_t <- s$sd_t; sd_c <- s$sd_c   # already SDs: compute_es() converted every reported SE
  chg <- (s$m_t - s$m_c) * ifelse(s$higher_is_safer == "no", -1, 1)
  r <- ifelse(is.na(s$r_used), 0.5, s$r_used)
  v <- ifelse(s$design == "within", (sd_t^2 + sd_c^2 - 2 * r * sd_t * sd_c) / s$n_t, sd_t^2 / s$n_t + sd_c^2 / s$n_c)
  data.frame(yi = 100 * chg / rng, vi = (100 / rng)^2 * v)
}
for (f in names(rq2)) {
  s <- d[d$feature == f & d$es_method == "means", ]
  if (!nrow(s)) next
  s[, c("yi", "vi")] <- raw_change(s)
  pd <- pair_diffs(s)
  if (n_studies(pd) < MIN_K) next
  m <- fit_che(pd)
  pomp_rq2[[f]] <- list(feature = f, estimate_pomp = as.numeric(m$beta), ci_lb = m$ci.lb, ci_ub = m$ci.ub, pval = m$pval)
}

rq1 <- label_robust(rq1, "rq1", loo1)
rq2 <- label_robust(rq2, "rq2", loo2)

slim <- function(fam) lapply(fam, function(x) list(rq1 = lapply(x$rq1, function(y) y[c("estimate", "ci_lb", "ci_ub", "p_holm", "decision")]),
                                                    rq2 = lapply(x$rq2, function(y) y[c("estimate", "ci_lb", "ci_ub", "p_holm", "decision")])))

# ---- write --------------------------------------------------------------------------------------------
models <- c(unname(rq1), unname(rq2), if (!is.null(oc1)) list(oc1), if (!is.null(rq3)) list(rq3), unname(rq4))
res <- list(created_by = "05_analysis/analysis.R", data_dir = data_dir,
            settings = list(alpha = ALPHA, sesoi = SESOI, min_k = MIN_K, min_k_moderators = MIN_K_MOD, rho = RHO,
                            r_impute = 0.5, dfs = "contain", metafor = as.character(packageVersion("metafor"))),
            models = models, swim = swims, feature_status = status, oc1_status = oc1_status, small_study_effects = egger,
            rq4_direction_agreement = agree, rq4_overdispersion = rq4_overdispersion, rq2_pomp = pomp_rq2,
            sensitivity = slim(sens), with_adolescents = slim(list(x = with_adolescents))$x)
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write_json(res, out_path, auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null")
cat(sprintf("Wrote %s: %d pooled models, %d SWiM summaries\n", out_path, length(models), length(swims)))
