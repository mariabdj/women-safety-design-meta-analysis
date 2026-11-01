# GATE 6: recomputes every effect size with an INDEPENDENT hand-coded implementation
# of the published formulas and compares with the main metafor code (05_analysis/effect_sizes.R).
# Usage: Rscript verification/verify_effect_sizes.R [03_extraction/extraction.csv] [r_impute]
# Exit code 0 = PASS, 1 = FAIL. Warnings (reported g, outliers) must be checked by hand and logged.
#
# Formulas:
#   Exact Hedges correction J(m) = Gamma(m/2) / (sqrt(m/2) * Gamma((m-1)/2))   (Hedges 1981)
#   SMD  : g = J(n1+n2-2) * (m1-m2)/Sp ; Sp = sqrt(((n1-1)s1^2 + (n2-1)s2^2)/(n1+n2-2))
#          v = 1/n1 + 1/n2 + g^2/(2(n1+n2))
#   t    : d = t*sqrt(1/n1+1/n2), g = J(n1+n2-2)*d, v as SMD
#   SMCR : g = J(n-1) * (m1-m2)/s_control ; v = 2(1-r)/n + g^2/(2n)      (Becker 1988)
#   SE   : rows with dispersion_type SE use SD = SE*sqrt(n) before any formula
#   OR   : g = ln(OR)*sqrt(3)/pi ; v = ((ln(UB)-ln(LB))/(2*z.975))^2 * 3/pi^2  (Chinn 2000)
#   gap  : SMD with men as group 1 and women as group 2, sign flipped on fear scales (extraction_gap.csv)
#   RES  : as protocol 2.7, a = treated before, b = treated after, c = control before, d = control after;
#          ln RES = ln(a*d/(b*c)), v = 1/a+1/b+1/c+1/d; 0.5 added to all four counts if one is 0 (extraction_actual.csv)

args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[1] else "03_extraction/extraction.csv"
r_impute <- if (length(args) >= 2) as.numeric(args[2]) else 0.5
TOL <- 1e-8

script_dir <- dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE))))
source(file.path(script_dir, "..", "05_analysis", "effect_sizes.R"))

d <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

J <- function(m) exp(lgamma(m / 2) - log(sqrt(m / 2)) - lgamma((m - 1) / 2))

hand <- function(r) {
  # a reported standard error is first turned back into a standard deviation
  if (isTRUE(r$dispersion_type == "SE")) {
    n_c <- if (is.na(r$n_c)) r$n_t else r$n_c
    r$sd_t <- r$sd_t * sqrt(r$n_t); r$sd_c <- r$sd_c * sqrt(n_c)
  }
  if (r$es_method == "means" && r$design == "between") {
    m <- r$n_t + r$n_c - 2
    sp <- sqrt(((r$n_t - 1) * r$sd_t^2 + (r$n_c - 1) * r$sd_c^2) / m)
    g <- J(m) * (r$m_t - r$m_c) / sp
    v <- 1 / r$n_t + 1 / r$n_c + g^2 / (2 * (r$n_t + r$n_c))
  } else if (r$es_method == "means" && r$design == "within") {
    rr <- if (is.na(r$r_within)) r_impute else r$r_within
    n <- r$n_t
    g <- J(n - 1) * (r$m_t - r$m_c) / r$sd_c
    v <- 2 * (1 - rr) / n + g^2 / (2 * n)
  } else if (r$es_method == "t_between") {
    m <- r$n_t + r$n_c - 2
    g <- J(m) * r$stat_value * sqrt(1 / r$n_t + 1 / r$n_c)
    v <- 1 / r$n_t + 1 / r$n_c + g^2 / (2 * (r$n_t + r$n_c))
  } else if (r$es_method == "or_ci") {
    g <- log(r$stat_value) * sqrt(3) / pi
    se <- (log(r$stat_ci_high) - log(r$stat_ci_low)) / (2 * qnorm(0.975))
    v <- se^2 * 3 / pi^2
  } else stop("unsupported es_method: ", r$es_method)
  if (r$higher_is_safer == "no") g <- -g
  c(g = g, v = v)
}

main <- compute_es(d, r_impute = r_impute)
errors <- character(0); warns <- character(0); maxdiff <- 0
for (i in seq_len(nrow(d))) {
  h <- hand(d[i, ])
  dy <- abs(h["g"] - main$yi[i]); dv <- abs(h["v"] - main$vi[i])
  if (is.na(dy) || is.na(dv)) { errors <- c(errors, sprintf("FAIL es_id=%s: NA effect size (main=%s, hand=%s)", d$es_id[i], main$yi[i], h["g"])); next }
  maxdiff <- max(maxdiff, dy, dv)
  if (dy > TOL) errors <- c(errors, sprintf("FAIL es_id=%s: g metafor=%.10f vs hand=%.10f", d$es_id[i], main$yi[i], h["g"]))
  if (dv > TOL) errors <- c(errors, sprintf("FAIL es_id=%s: var metafor=%.10f vs hand=%.10f", d$es_id[i], main$vi[i], h["v"]))
  if (!is.na(d$reported_g[i]) && abs(d$reported_g[i] - h["g"]) > 0.05)   # reported_g is entered in the review's direction (C4)
    warns <- c(warns, sprintf("WARN es_id=%s: reported d/g=%.3f vs ours=%.3f (diff > 0.05): check the PDF, explain in log", d$es_id[i], d$reported_g[i], h["g"]))
  if (abs(h["g"]) > 3)
    warns <- c(warns, sprintf("WARN es_id=%s: |g|=%.2f > 3: re-check numbers in PDF (SD vs SE?) and log", d$es_id[i], h["g"]))
  if (d$design[i] == "within" && is.na(d$r_within[i]))
    warns <- c(warns, sprintf("INFO es_id=%s: r_within imputed = %.2f (sensitivity 0.3/0.7 required)", d$es_id[i], r_impute))
}
# gap and harm sheets next to the extraction sheet: same check, hand formulas against effect_sizes.R
n_extra <- 0
gpath <- file.path(dirname(path), "extraction_gap.csv")
if (file.exists(gpath)) {
  gp <- read.csv(gpath, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  main_g <- compute_gap_es(gp)
  for (i in seq_len(nrow(gp))) {
    r <- gp[i, ]
    if (isTRUE(r$dispersion_type == "SE")) { r$sd_w <- r$sd_w * sqrt(r$n_w); r$sd_m <- r$sd_m * sqrt(r$n_m) }
    m <- r$n_m + r$n_w - 2
    sp <- sqrt(((r$n_m - 1) * r$sd_m^2 + (r$n_w - 1) * r$sd_w^2) / m)
    g <- J(m) * (r$m_m - r$m_w) / sp
    v <- 1 / r$n_m + 1 / r$n_w + g^2 / (2 * (r$n_m + r$n_w))
    if (r$higher_is_safer == "no") g <- -g
    dy <- abs(g - main_g$yi[i]); dv <- abs(v - main_g$vi[i])
    if (!isTRUE(dy <= TOL && dv <= TOL)) errors <- c(errors, sprintf("FAIL gap_id=%s: g main=%.10f vs hand=%.10f, var main=%.10f vs hand=%.10f", r$gap_id, main_g$yi[i], g, main_g$vi[i], v))
    else maxdiff <- max(maxdiff, dy, dv)
    n_extra <- n_extra + 1
  }
}
hpath <- file.path(dirname(path), "extraction_actual.csv")
if (file.exists(hpath)) {
  ac <- read.csv(hpath, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  ac <- ac[which(ac$metric == "counts"), ]
  main_r <- compute_res(ac)
  for (i in seq_len(nrow(ac))) {
    a <- ac$trt_before[i]; b <- ac$trt_after[i]; c <- ac$ctrl_before[i]; dd <- ac$ctrl_after[i]
    if (a == 0 || b == 0 || c == 0 || dd == 0) { a <- a + 0.5; b <- b + 0.5; c <- c + 0.5; dd <- dd + 0.5 }
    y <- log(a * dd / (b * c)); v <- 1 / a + 1 / b + 1 / c + 1 / dd
    dy <- abs(y - main_r$yi[i]); dv <- abs(v - main_r$vi[i])
    if (!isTRUE(dy <= TOL && dv <= TOL)) errors <- c(errors, sprintf("FAIL act_id=%s: lnRES main=%.10f vs hand=%.10f, var main=%.10f vs hand=%.10f", ac$act_id[i], main_r$yi[i], y, main_r$vi[i], v))
    else maxdiff <- max(maxdiff, dy, dv)
    n_extra <- n_extra + 1
  }
}
if (length(warns)) cat(warns, sep = "\n")
if (length(errors)) { cat(errors, sep = "\n"); cat(sprintf("\nRESULT: FAILED (%d mismatches)\n", length(errors))); quit(status = 1) }
cat(sprintf("RESULT: PASSED (%d/%d rows identical, plus %d gap/harm rows, max |diff| = %.2e, tolerance %.0e; %d warnings to check by hand)\n",
            nrow(d), nrow(d), n_extra, maxdiff, TOL, sum(startsWith(warns, "WARN"))))
