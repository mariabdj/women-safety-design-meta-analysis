# MAIN effect-size computation (metafor). Used by analysis.R.
# Its results are checked against an independent hand-coded version in
# verification/verify_effect_sizes.R (GATE 6). Do not change one without the other.
#
# Convention (protocol): g > 0 = the design feature increases perceived safety.
#   means, between : SMD (Hedges' g, exact small-sample correction), pooled SD
#   means, within  : SMCR, standardised by the control-condition SD, r imputed if missing
#   t_between      : SMD from the independent-samples t statistic
#   or_ci          : log odds ratio from its 95% CI, converted to d (x sqrt(3)/pi)
#   dispersion_type = "SE" rows are turned into SDs first (SD = SE * sqrt(n))
#   compute_gap_es : gap sheet, SMD of men minus women (> 0 = women feel less safe), protocol 2.7
#   compute_res    : harm sheet, ln RES of Welsh & Farrington (> 0 = less harm in the treated area)

suppressPackageStartupMessages(library(metafor))

compute_es <- function(d, r_impute = 0.5) {
  d$yi <- NA_real_; d$vi <- NA_real_
  # papers sometimes give standard errors: SD = SE x sqrt(n). Within-subject rows have one n (n_t).
  if ("dispersion_type" %in% names(d)) {
    se <- which(d$dispersion_type == "SE")
    d$sd_t[se] <- d$sd_t[se] * sqrt(d$n_t[se])
    d$sd_c[se] <- d$sd_c[se] * sqrt(ifelse(is.na(d$n_c[se]), d$n_t[se], d$n_c[se]))
    d$dispersion_type[se] <- "SD (converted from SE)"   # so no later step converts these rows again
  }
  d$r_used <- ifelse(d$design == "within", ifelse(is.na(d$r_within), r_impute, d$r_within), NA_real_)

  i <- which(d$es_method == "means" & d$design == "between")
  if (length(i)) {
    e <- escalc(measure = "SMD", m1i = m_t, sd1i = sd_t, n1i = n_t,
                m2i = m_c, sd2i = sd_c, n2i = n_c, data = d[i, ])
    d$yi[i] <- e$yi; d$vi[i] <- e$vi
  }
  i <- which(d$es_method == "means" & d$design == "within")
  if (length(i)) {
    e <- escalc(measure = "SMCR", m1i = m_t, m2i = m_c, sd1i = sd_c, ni = n_t,
                ri = r_used, data = d[i, ])
    d$yi[i] <- e$yi; d$vi[i] <- e$vi
  }
  i <- which(d$es_method == "t_between")
  if (length(i)) {
    e <- escalc(measure = "SMD", ti = stat_value, n1i = n_t, n2i = n_c, data = d[i, ])
    d$yi[i] <- e$yi; d$vi[i] <- e$vi
  }
  i <- which(d$es_method == "or_ci")
  if (length(i)) {
    e <- conv.wald(out = stat_value, ci.lb = stat_ci_low, ci.ub = stat_ci_high,
                   data = d[i, ], transf = log)
    d$yi[i] <- e$yi * sqrt(3) / pi
    d$vi[i] <- e$vi * 3 / pi^2
  }
  flip <- d$higher_is_safer == "no"
  d$yi[flip] <- -d$yi[flip]
  d
}

compute_gap_es <- function(gp) {
  if ("dispersion_type" %in% names(gp)) {   # same SE-to-SD rule as for the main sheet
    se <- which(gp$dispersion_type == "SE")
    gp$sd_w[se] <- gp$sd_w[se] * sqrt(gp$n_w[se]); gp$sd_m[se] <- gp$sd_m[se] * sqrt(gp$n_m[se])
  }
  e <- escalc(measure = "SMD", m1i = m_m, sd1i = sd_m, n1i = n_m, m2i = m_w, sd2i = sd_w, n2i = n_w, data = gp)
  e$yi <- ifelse(gp$higher_is_safer == "no", -e$yi, e$yi)
  e
}

compute_res <- function(ac) {
  cnt <- c("ctrl_before", "ctrl_after", "trt_before", "trt_after")
  # a zero count makes ln RES infinite: add 0.5 to all four counts of that comparison (protocol 2.7)
  z <- apply(ac[, cnt] == 0, 1, any)
  ac[z, cnt] <- ac[z, cnt] + 0.5
  ac$yi <- log((ac$ctrl_after * ac$trt_before) / (ac$ctrl_before * ac$trt_after))
  ac$vi <- 1 / ac$ctrl_before + 1 / ac$ctrl_after + 1 / ac$trt_before + 1 / ac$trt_after
  ac
}
