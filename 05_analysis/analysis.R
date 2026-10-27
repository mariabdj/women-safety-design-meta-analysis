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
read <- function(f) read.csv(file.path(data_dir, f), stringsAsFactors = FALSE, na.strings = c("", "NA"))
n_studies <- function(s) length(unique(s$study_id))

raw <- read("extraction.csv")
raw_perc <- raw[is.na(raw$outcome_type) | raw$outcome_type == "perceived", ]
# main analysis: adults only (protocol 2.1); adolescent samples come back in a sensitivity analysis
main_rows <- function(d) if ("adult_sample" %in% names(d)) d[is.na(d$adult_sample) | d$adult_sample == "yes", ] else d

# ---- helpers -------------------------------------------------------------------------------------------

# multilevel I2 per level (Cheung 2014): share of total variance at each level, using the "typical" sampling variance
i2_levels <- function(m) {
  W <- diag(1 / m$vi); X <- model.matrix(m)
  P <- W - W %*% X %*% solve(t(X) %*% W %*% X) %*% t(X) %*% W
  v_typ <- (m$k - m$p) / sum(diag(P))
  100 * m$sigma2 / (sum(m$sigma2) + v_typ)
}

fit3 <- function(s, mods = NULL) {
  # rma.mv evaluates 'mods' inside the data, so an empty moderator must be left out, not passed as NULL.
  # Pre-specified fallback (protocol 2.8): if the default optimiser fails, try a second one; if that also
  # fails, use a two-level model on effect sizes (study level only), and record it in the model notes.
  one <- function(ctrl) {
    if (is.null(mods)) rma.mv(yi, vi, random = ~ 1 | study_id / es_id, data = s, test = "t", method = "REML", control = ctrl)
    else rma.mv(yi, vi, mods = mods, random = ~ 1 | study_id / es_id, data = s, test = "t", method = "REML", control = ctrl)
  }
  m <- tryCatch(one(list()), error = function(e) NULL)
  if (is.null(m)) m <- tryCatch(one(list(optimizer = "optim", optmethod = "BFGS")), error = function(e) NULL)
  if (!is.null(m)) { m$fit_note <- "three-level"; return(m) }
  m <- if (is.null(mods)) rma.mv(yi, vi, random = ~ 1 | study_id, data = s, test = "t", method = "REML")
       else rma.mv(yi, vi, mods = mods, random = ~ 1 | study_id, data = s, test = "t", method = "REML")
  m$fit_note <- "two-level fallback (three-level model did not converge)"
  m
}

# smallest effect detectable with 80% power for this k, typical variance and estimated tau2 (protocol 2.9)
mde80 <- function(k, v, tau2) {
  pw <- function(d) { se <- sqrt((v + tau2) / k); tc <- qt(1 - ALPHA / 2, k - 1)
                      pt(-tc, k - 1, d / se) + 1 - pt(tc, k - 1, d / se) }
  uniroot(function(d) pw(d) - 0.80, c(1e-6, 10))$root
}

# one coefficient of a 3-level model, in the format verify_model.R reads
summarise_coef <- function(m, s, name, coef = 1, with_pi = TRUE) {
  b <- as.numeric(m$beta[coef]); se <- m$se[coef]; df <- m$ddf[coef]
  ci90 <- b + c(-1, 1) * qt(0.95, df) * se
  out <- list(name = name, k = n_studies(s), n_es = nrow(s), n_participants = sum(s$n_t, na.rm = TRUE),
              estimate = b, se = se, df = df, ci_lb = m$ci.lb[coef], ci_ub = m$ci.ub[coef], pval = m$pval[coef],
              ci90_lb = ci90[1], ci90_ub = ci90[2],
              tau2_study = m$sigma2[1], tau2_es = if (length(m$sigma2) > 1) m$sigma2[2] else NA,
              tau2 = sum(m$sigma2), i2_study = i2_levels(m)[1],
              i2_es = if (length(m$sigma2) > 1) i2_levels(m)[2] else NA, i2 = sum(i2_levels(m)),
              fit = m$fit_note)
  if (with_pi) { p <- predict(m); out$pi_lb <- p$pi.lb[1]; out$pi_ub <- p$pi.ub[1] }
  if (out$k >= MIN_K_MOD) {   # CR2 robust check (protocol 2.8)
    rob <- coef_test(m, vcov = "CR2", cluster = s$study_id)
    out$cr2_se <- rob$SE[coef]; out$cr2_df <- rob$df_Satt[coef]; out$cr2_pval <- rob$p_Satt[coef]
  }
  out$mde80 <- mde80(out$k, median(s$vi), out$tau2)
  # equivalence test (TOST) against +/- SESOI: p is the larger of the two one-sided p-values
  out$p_tost <- max(pt((b + SESOI) / se, df, lower.tail = FALSE), pt((b - SESOI) / se, df))
  out
}

# decision rule of protocol 2.9, applied after Holm adjustment
decide <- function(x) {
  if (x$p_holm < ALPHA && x$estimate > 0) return("supported")
  if (x$p_holm < ALPHA && x$estimate < 0) return("opposite direction")
  if (x$p_tost_holm < ALPHA) return("equivalent (no meaningful effect)")
  "inconclusive"
}

holm <- function(models) {
  if (!length(models)) return(models)
  p <- p.adjust(sapply(models, `[[`, "pval"), method = "holm")
  pe <- p.adjust(sapply(models, `[[`, "p_tost"), method = "holm")
  for (i in seq_along(models)) {
    models[[i]]$p_holm <- p[i]; models[[i]]$p_tost_holm <- pe[i]; models[[i]]$decision <- decide(models[[i]])
  }
  models
}

# SWiM summary when fewer than 3 studies (protocol 2.8): direction counts and sign test, no effect size
swim <- function(s, name) {
  per_study <- tapply(s$yi, s$study_id, mean)
  pos <- sum(per_study > 0); neg <- sum(per_study < 0)
  list(name = name, k = length(per_study), n_es = nrow(s), method = "SWiM vote count",
       n_positive = pos, n_negative = neg,
       sign_test_p = if (pos + neg > 0) binom.test(pos, pos + neg)$p.value else NA)
}

# ---- effect sizes --------------------------------------------------------------------------------------
d_all <- compute_es(raw_perc)
d <- main_rows(d_all)
features <- sort(unique(d$feature))
models <- list(); swims <- list(); sens <- list()

# ---- RQ1: women's effect per feature ------------------------------------------------------------------
rq1 <- list()
for (f in features) {
  s <- d[d$feature == f & d$gender == "women", ]
  if (n_studies(s) < MIN_K) { swims[[length(swims) + 1]] <- swim(s, paste0("RQ1_", f)); next }
  rq1[[f]] <- summarise_coef(fit3(s), s, paste0("RQ1_", f))
}
rq1 <- holm(rq1)

# ---- RQ2: women minus men, same studies ------------------------------------------------------------------
rq2 <- list()
for (f in features) {
  s <- d[d$feature == f & d$gender %in% c("women", "men"), ]
  both <- intersect(s$study_id[s$gender == "women"], s$study_id[s$gender == "men"])
  s <- s[s$study_id %in% both, ]
  if (length(both) < MIN_K) { swims[[length(swims) + 1]] <- list(name = paste0("RQ2_", f), k = length(both), method = "not tested (k < 3)"); next }
  s$women <- as.integer(s$gender == "women")
  m <- fit3(s, mods = ~ women)
  rq2[[f]] <- summarise_coef(m, s, paste0("RQ2_", f), coef = 2, with_pi = FALSE)
}
rq2 <- holm(rq2)

# ---- outcome-neutral check H0 and RQ3: women-men gap --------------------------------------------------
h0 <- NULL; rq3 <- NULL
if (file.exists(file.path(data_dir, "extraction_gap.csv"))) {
  gp <- read("extraction_gap.csv")
  # positive = women feel less safe than men (protocol 2.7): men's mean minus women's mean, standardised
  e <- escalc(measure = "SMD", m1i = m_m, sd1i = sd_m, n1i = n_m, m2i = m_w, sd2i = sd_w, n2i = n_w, data = gp)
  e$yi <- ifelse(gp$higher_is_safer == "no", -e$yi, e$yi)
  e$es_id <- gp$gap_id
  base <- e[gp$baseline == "yes", ]
  if (n_studies(base) >= MIN_K) {
    h0 <- summarise_coef(fit3(base), base, "H0_baseline_gap")
    h0$check_passed <- h0$ci_lb > 0   # women less safe at baseline: RQ2 and RQ3 interpretable
  }
  multi <- names(which(tapply(e$es_id, e$study_id, length) >= 2))
  s3 <- e[e$study_id %in% multi, ]
  if (length(multi) >= MIN_K_MOD) {
    m3 <- fit3(s3, mods = ~ scene_score)
    rq3 <- summarise_coef(m3, s3, "RQ3_gap_slope_per_feature_point", coef = 2, with_pi = FALSE)
  }
}

# ---- RQ4: actual safety ----------------------------------------------------------------------------------
rq4 <- list()
if (file.exists(file.path(data_dir, "extraction_actual.csv"))) {
  ac <- read("extraction_actual.csv")
  ac <- ac[ac$metric == "counts", ]
  # log relative effect: > 0 = less harm in the treated area (Welsh & Farrington 2008)
  ac$yi <- log((ac$ctrl_after * ac$trt_before) / (ac$ctrl_before * ac$trt_after))
  ac$vi <- 1 / ac$ctrl_before + 1 / ac$ctrl_after + 1 / ac$trt_before + 1 / ac$trt_after
  for (f in sort(unique(ac$feature))) {
    s <- ac[ac$feature == f, ]
    if (n_studies(s) < MIN_K) { swims[[length(swims) + 1]] <- swim(s, paste0("RQ4_", f)); next }
    m <- rma(yi, vi, data = s, method = "REML", test = "knha")
    p <- predict(m)
    rq4[[f]] <- list(name = paste0("RQ4_", f), k = n_studies(s), n_es = nrow(s), estimate = as.numeric(m$beta),
                     se = m$se, ci_lb = m$ci.lb, ci_ub = m$ci.ub, pi_lb = p$pi.lb, pi_ub = p$pi.ub,
                     pval = m$pval, tau2 = m$tau2, i2 = m$I2, ratio = exp(as.numeric(m$beta)))
  }
  # sensitivity: crime counts are often overdispersed, so every variance is doubled (protocol 2.7)
  rq4_overdispersion <- lapply(names(rq4), function(f) {
    s <- ac[ac$feature == f, ]
    m <- rma(yi, 2 * vi, data = s, method = "REML", test = "knha")
    list(feature = f, estimate = as.numeric(m$beta), ci_lb = m$ci.lb, ci_ub = m$ci.ub, pval = m$pval)
  })
  # agreement with perceived safety, feature by feature (direction only)
  agree <- lapply(names(rq4), function(f) list(feature = f,
    perceived = if (!is.null(rq1[[f]])) sign(rq1[[f]]$estimate) else NA, actual = sign(rq4[[f]]$estimate)))
}

# ---- small-study effects (k >= 10, protocol 2.10) --------------------------------------------------------
egger <- list()
for (f in names(rq1)) {
  s <- d[d$feature == f & d$gender == "women", ]
  if (n_studies(s) < MIN_K_MOD) next
  s$mod_prec <- ifelse(s$design == "between", sqrt((s$n_t + s$n_c) / (s$n_t * s$n_c)),
                       sqrt(2 * (1 - s$r_used) / s$n_t))   # sampling SE without the g^2 term
  m <- fit3(s, mods = ~ mod_prec)
  egger[[f]] <- list(feature = f, slope = as.numeric(m$beta[2]), pval = m$pval[2])
}

# ---- sensitivity analyses on RQ1 (protocol 2.10) ---------------------------------------------------------
refit_rq1 <- function(dd, label) {
  out <- list()
  for (f in names(rq1)) {
    s <- dd[dd$feature == f & dd$gender == "women", ]
    if (n_studies(s) < MIN_K) { out[[f]] <- list(feature = f, k = n_studies(s), estimate = NA, note = "k < 3"); next }
    m <- fit3(s)
    out[[f]] <- list(feature = f, k = n_studies(s), estimate = as.numeric(m$beta), ci_lb = m$ci.lb, ci_ub = m$ci.ub, pval = m$pval)
  }
  out
}
sens$r_0.3 <- refit_rq1(main_rows(compute_es(raw_perc, r_impute = 0.3)), "r = 0.3")
sens$r_0.7 <- refit_rq1(main_rows(compute_es(raw_perc, r_impute = 0.7)), "r = 0.7")
if ("rob_overall" %in% names(d)) sens$without_high_rob <- refit_rq1(d[is.na(d$rob_overall) | d$rob_overall != "high", ], "no high RoB")
sens$without_author_data <- refit_rq1(d[is.na(d$data_from_author) | d$data_from_author != "yes", ], "no author data")
sens$with_adolescents <- refit_rq1(d_all, "with adolescents")
sens$two_level <- lapply(names(rq1), function(f) {
  s <- d[d$feature == f & d$gender == "women", ]
  m <- tryCatch(rma(yi, vi, data = s, method = "REML", test = "knha"), error = function(e) NULL)
  if (is.null(m)) return(list(feature = f, note = "two-level model did not converge"))
  list(feature = f, estimate = as.numeric(m$beta), ci_lb = m$ci.lb, ci_ub = m$ci.ub)
})
# correlated-and-hierarchical-effects working model with CR2 (Pustejovsky & Tipton 2021), rho 0.6 (0.3, 0.8)
for (rho in c(0.3, 0.6, 0.8)) sens[[paste0("che_rho_", rho)]] <- lapply(names(rq1), function(f) {
  s <- d[d$feature == f & d$gender == "women", ]
  V <- vcalc(vi, cluster = study_id, obs = es_id, rho = rho, data = s)
  fit <- function(ctrl) rma.mv(yi, V, random = ~ 1 | study_id / es_id, data = s, test = "t", control = ctrl)
  m <- tryCatch(fit(list()), error = function(e) tryCatch(fit(list(optimizer = "optim", optmethod = "BFGS")), error = function(e) NULL))
  if (is.null(m)) return(list(feature = f, note = "CHE model did not converge"))
  r <- coef_test(m, vcov = "CR2", cluster = s$study_id)
  list(feature = f, estimate = as.numeric(m$beta), se_cr2 = r$SE[1], df = r$df_Satt[1], p_cr2 = r$p_Satt[1])
})
sens$leave_one_study_out <- lapply(names(rq1), function(f) {
  s <- d[d$feature == f & d$gender == "women", ]
  if (n_studies(s) <= MIN_K) return(list(feature = f, note = "k = 3: leave-one-out would go below the minimum"))
  est <- sapply(unique(s$study_id), function(id) as.numeric(fit3(s[s$study_id != id, ])$beta))
  list(feature = f, min = min(est), max = max(est), all_positive = all(est > 0))
})

# robustness label (protocol 2.10): decision unchanged when each sensitivity estimate is re-judged by sign and CI
for (f in names(rq1)) {
  same <- sapply(sens[c("r_0.3", "r_0.7", "without_high_rob", "without_author_data")], function(x) {
    y <- x[[f]]; if (is.null(y) || is.na(y$estimate)) return(NA)
    if (rq1[[f]]$decision == "supported") y$ci_lb > 0 else TRUE
  })
  rq1[[f]]$robust <- all(same, na.rm = TRUE)
}

# ---- write --------------------------------------------------------------------------------------------
models <- c(unname(rq1), unname(rq2), if (!is.null(h0)) list(h0), if (!is.null(rq3)) list(rq3), unname(rq4))
res <- list(created_by = "05_analysis/analysis.R", data_dir = data_dir,
            settings = list(alpha = ALPHA, sesoi = SESOI, min_k = MIN_K, min_k_moderators = MIN_K_MOD,
                            r_impute = 0.5, metafor = as.character(packageVersion("metafor"))),
            models = models, swim = swims, small_study_effects = egger,
            rq4_direction_agreement = if (exists("agree")) agree else list(),
            rq4_overdispersion = if (exists("rq4_overdispersion")) rq4_overdispersion else list(), sensitivity = sens)
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write_json(res, out_path, auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null")
cat(sprintf("Wrote %s: %d pooled models, %d SWiM summaries\n", out_path, length(models), length(swims)))
