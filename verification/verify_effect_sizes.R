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
#   OR   : g = ln(OR)*sqrt(3)/pi ; v = ((ln(UB)-ln(LB))/(2*z.975))^2 * 3/pi^2  (Chinn 2000)

args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[1] else "03_extraction/extraction.csv"
r_impute <- if (length(args) >= 2) as.numeric(args[2]) else 0.5
TOL <- 1e-8

script_dir <- dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE))))
source(file.path(script_dir, "..", "05_analysis", "effect_sizes.R"))

d <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

J <- function(m) exp(lgamma(m / 2) - log(sqrt(m / 2)) - lgamma((m - 1) / 2))

hand <- function(r) {
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
  if (!is.na(d$reported_g[i]) && abs(abs(d$reported_g[i]) - abs(h["g"])) > 0.05)
    warns <- c(warns, sprintf("WARN es_id=%s: reported d/g=%.3f vs ours=%.3f (diff > 0.05): check the PDF, explain in log", d$es_id[i], d$reported_g[i], h["g"]))
  if (abs(h["g"]) > 3)
    warns <- c(warns, sprintf("WARN es_id=%s: |g|=%.2f > 3: re-check numbers in PDF (SD vs SE?) and log", d$es_id[i], h["g"]))
  if (d$design[i] == "within" && is.na(d$r_within[i]))
    warns <- c(warns, sprintf("INFO es_id=%s: r_within imputed = %.2f (sensitivity 0.3/0.7 required)", d$es_id[i], r_impute))
}
if (length(warns)) cat(warns, sep = "\n")
if (length(errors)) { cat(errors, sep = "\n"); cat(sprintf("\nRESULT: FAILED (%d mismatches)\n", length(errors))); quit(status = 1) }
cat(sprintf("RESULT: PASSED (%d/%d rows identical, max |diff| = %.2e, tolerance %.0e; %d warnings to check by hand)\n",
            nrow(d), nrow(d), maxdiff, TOL, sum(startsWith(warns, "WARN"))))
