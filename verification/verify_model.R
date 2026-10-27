# GATE 7: checks the pooled analyses three independent ways, then checks results.json for logic.
#  (a) metafor rma (REML + Knapp-Hartung)  vs  meta::metagen (REML + Hartung-Knapp)   tol 1e-4
#  (b) hand-coded inverse-variance fixed effect, Q and I^2  vs  metafor / meta        tol 1e-6
#  (c) hand-coded DerSimonian-Laird random effects          vs  metafor method="DL"   tol 1e-6
#  (d) 3-level model per feature: converged, variance components identifiable (profile not flat)
#  (e) results.json sanity: CI contains estimate, PI >= CI, 0<=I2<=100, tau2>=0, k<=studies...
# Usage: Rscript verification/verify_model.R [extraction.csv] [results.json]
# Groups pooled: each feature x gender with >= 3 studies (protocol minimum).

args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[1] else "03_extraction/extraction.csv"
res_path <- if (length(args) >= 2) args[2] else "05_analysis/results/results.json"

script_dir <- dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE))))
source(file.path(script_dir, "..", "05_analysis", "effect_sizes.R"))
suppressPackageStartupMessages({ library(meta); library(jsonlite) })

d <- compute_es(read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE))
errors <- character(0); infos <- character(0)
chk <- function(ok, msg) if (!isTRUE(ok)) errors <<- c(errors, paste("FAIL", msg))
n_groups <- 0

for (f in unique(d$feature)) for (gnd in unique(d$gender)) {
  s <- d[d$feature == f & d$gender == gnd, ]
  if (length(unique(s$study_id)) < 3) { infos <- c(infos, sprintf("INFO %s/%s: %d studies < 3, not pooled (SWiM)", f, gnd, length(unique(s$study_id)))); next }
  n_groups <- n_groups + 1; lab <- sprintf("%s/%s", f, gnd)
  y <- s$yi; v <- s$vi; k <- length(y)

  # (a) metafor vs meta
  m1 <- rma(y, v, method = "REML", test = "knha")
  m2 <- metagen(TE = y, seTE = sqrt(v), method.tau = "REML", method.random.ci = "HK", common = TRUE, random = TRUE)
  chk(abs(as.numeric(m1$beta) - m2$TE.random) < 1e-4, sprintf("%s (a) pooled g metafor=%.6f vs meta=%.6f", lab, m1$beta, m2$TE.random))
  chk(abs(m1$tau2 - m2$tau2) < 1e-4, sprintf("%s (a) tau2 metafor=%.6f vs meta=%.6f", lab, m1$tau2, m2$tau2))
  chk(abs(m1$ci.lb - m2$lower.random) < 1e-4 && abs(m1$ci.ub - m2$upper.random) < 1e-4,
      sprintf("%s (a) CI metafor=[%.4f, %.4f] vs meta=[%.4f, %.4f]", lab, m1$ci.lb, m1$ci.ub, m2$lower.random, m2$upper.random))

  # (b) hand fixed effect, Q, I2
  w <- 1 / v; fe <- sum(w * y) / sum(w); Q <- sum(w * (y - fe)^2); I2 <- max(0, (Q - (k - 1)) / Q) * 100
  mfe <- rma(y, v, method = "FE")
  chk(abs(fe - as.numeric(mfe$beta)) < 1e-6, sprintf("%s (b) FE hand=%.8f vs metafor=%.8f", lab, fe, mfe$beta))
  chk(abs(Q - mfe$QE) < 1e-6, sprintf("%s (b) Q hand=%.8f vs metafor=%.8f", lab, Q, mfe$QE))
  chk(abs(I2 - 100 * m2$I2) < 1e-6, sprintf("%s (b) I2 hand=%.6f vs meta=%.6f", lab, I2, 100 * m2$I2))

  # (c) hand DerSimonian-Laird
  t2 <- max(0, (Q - (k - 1)) / (sum(w) - sum(w^2) / sum(w)))
  ws <- 1 / (v + t2); re <- sum(ws * y) / sum(ws); se <- sqrt(1 / sum(ws))
  mdl <- rma(y, v, method = "DL")
  chk(abs(t2 - mdl$tau2) < 1e-6, sprintf("%s (c) DL tau2 hand=%.8f vs metafor=%.8f", lab, t2, mdl$tau2))
  chk(abs(re - as.numeric(mdl$beta)) < 1e-6, sprintf("%s (c) DL g hand=%.8f vs metafor=%.8f", lab, re, mdl$beta))
  chk(abs(se - mdl$se) < 1e-6, sprintf("%s (c) DL SE hand=%.8f vs metafor=%.8f", lab, se, mdl$se))

  # direction check (rule 7 of GATE 7)
  maj <- sign(sum(sign(y))); if (maj != 0 && sign(as.numeric(m1$beta)) != maj)
    infos <- c(infos, sprintf("WARN %s: pooled sign differs from majority of study signs: explain in log", lab))
}

# (d) 3-level models per feature (all genders, gender as moderator when both present)
for (f in unique(d$feature)) {
  s <- d[d$feature == f, ]
  if (length(unique(s$study_id)) < 3) next
  form <- if (length(unique(s$gender)) > 1) ~ factor(gender) else ~ 1
  m3 <- tryCatch(rma.mv(yi, vi, mods = form, random = ~ 1 | study_id / es_id, data = s, test = "t"),
                 error = function(e) e)
  if (inherits(m3, "error")) { chk(FALSE, sprintf("%s (d) 3-level model did not converge: %s", f, conditionMessage(m3))); next }
  for (j in seq_along(m3$sigma2)) {
    p <- tryCatch(profile(m3, sigma2 = j, plot = FALSE, progbar = FALSE, steps = 10), error = function(e) NULL)
    if (is.null(p)) { infos <- c(infos, sprintf("WARN %s (d) could not profile sigma2[%d]", f, j)); next }
    if (diff(range(p$ll, na.rm = TRUE)) < 0.01)
      chk(FALSE, sprintf("%s (d) sigma2[%d] profile is flat: variance component not identifiable, simplify model", f, j))
    if (m3$sigma2[j] < 1e-8) infos <- c(infos, sprintf("INFO %s (d) sigma2[%d] estimated at 0", f, j))
  }
}

# (e) results.json logic
if (file.exists(res_path)) {
  r <- fromJSON(res_path, simplifyVector = FALSE)$models
  n_studies <- length(unique(d$study_id))
  for (m in r) {
    nm <- m$name
    for (fld in c("name", "k", "n_es", "estimate", "ci_lb", "ci_ub")) chk(!is.null(m[[fld]]), sprintf("results %s: field '%s' missing", nm, fld))
    if (!is.null(m$ci_lb)) chk(m$ci_lb <= m$estimate && m$estimate <= m$ci_ub, sprintf("results %s: CI does not contain estimate", nm))
    if (!is.null(m$pi_lb)) chk(m$pi_lb <= m$ci_lb + 1e-12 && m$pi_ub >= m$ci_ub - 1e-12, sprintf("results %s: PI narrower than CI", nm))
    if (!is.null(m$i2)) chk(m$i2 >= 0 && m$i2 <= 100, sprintf("results %s: I2=%s outside 0-100", nm, m$i2))
    if (!is.null(m$tau2)) chk(m$tau2 >= 0, sprintf("results %s: tau2 < 0", nm))
    if (!is.null(m$k)) chk(m$k <= n_studies, sprintf("results %s: k=%s > %d included studies", nm, m$k, n_studies))
    if (!is.null(m$k) && !is.null(m$n_es)) chk(m$n_es >= m$k, sprintf("results %s: fewer effect sizes than studies", nm))
    if (!is.null(m$pval)) chk(m$pval >= 0 && m$pval <= 1, sprintf("results %s: p outside [0,1]", nm))
    if (!is.null(m$k) && m$k < 3) chk(FALSE, sprintf("results %s: pooled with k=%s < 3 (protocol forbids)", nm, m$k))
  }
} else infos <- c(infos, sprintf("INFO %s not found: (e) skipped", res_path))

if (length(infos)) cat(infos, sep = "\n")
if (length(errors)) { cat(errors, sep = "\n"); cat(sprintf("\nRESULT: FAILED (%d problems)\n", length(errors))); quit(status = 1) }
cat(sprintf("RESULT: PASSED (%d pooled groups checked 3 independent ways; 3-level models OK)\n", n_groups))
