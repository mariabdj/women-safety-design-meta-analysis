# MAIN effect-size computation (metafor). Used by analysis.R.
# Its results are checked against an independent hand-coded version in
# verification/verify_effect_sizes.R (GATE 6). Do not change one without the other.
#
# Convention (protocol): g > 0 = the design feature increases perceived safety.
#   means, between : SMD (Hedges' g, exact small-sample correction), pooled SD
#   means, within  : SMCR, standardised by the control-condition SD, r imputed if missing
#   t_between      : SMD from the independent-samples t statistic
#   or_ci          : log odds ratio from its 95% CI, converted to d (x sqrt(3)/pi)

suppressPackageStartupMessages(library(metafor))

compute_es <- function(d, r_impute = 0.5) {
  d$yi <- NA_real_; d$vi <- NA_real_
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
