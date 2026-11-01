# GATE 7: checks the pooled analyses three independent ways, then checks results.json for logic.
#  (a) metafor rma (REML + Knapp-Hartung)  vs  meta::metagen (REML + Hartung-Knapp)   tol 1e-4
#  (b) hand-coded inverse-variance fixed effect, Q and I^2  vs  metafor / meta        tol 1e-6
#  (c) hand-coded DerSimonian-Laird random effects          vs  metafor method="DL"   tol 1e-6
#  (d) 3-level model per feature: converged; a flat variance profile is reported as INFO (protocol 2.8)
#  (f) every RQ1/RQ2 model and OC1 re-estimated independently (V matrix, REML by optim, GLS), fallbacks with
#      their own structure; RQ4 checked against meta::metagen (REML + Hartung-Knapp)
#  (g) decision layer by hand: p, TOST p, Holm, decision order, robust label, RQ2 OC1 labels, and every
#      leave-one-out decision refitted with the hand CHE code
#  RQ4 is re-estimated with a hand REML and Knapp-Hartung. Not re-estimated: RQ3 (exploratory, its CR2 CI comes
#  from clubSandwich) and the sensitivity sets other than leave-one-out (their decisions feed the robust label).
#  (e) results.json sanity: CI contains estimate, PI >= CI, 0<=I2<=100, tau2>=0, k<=studies...
# Usage: Rscript verification/verify_model.R [extraction.csv] [results.json]
# (a)-(d) are software cross-checks on every feature x gender group with >= 3 studies in the sheet (all rows,
# including adolescents and gender 'all'); the protocol's own models are checked in (f).

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
      infos <- c(infos, sprintf("INFO %s (d) sigma2[%d] profile is flat: not identifiable with these studies; reported, not interpreted (protocol 2.8)", f, j))
    if (m3$sigma2[j] < 1e-8) infos <- c(infos, sprintf("INFO %s (d) sigma2[%d] estimated at 0", f, j))
  }
}

if (!file.exists(res_path)) { cat(sprintf("FAIL %s not found: run analysis.R first\nRESULT: FAILED\n", res_path)); quit(status = 1) }

# (f) hand re-estimation of the CHE models actually reported (protocol 2.8), written without metafor's rma.mv:
#     V_ij = rho * sqrt(v_i v_j) within a study, M = V + s2_study * ZZ' + s2_es * I,
#     REML log-likelihood maximised with optim, beta = (X'M^-1 X)^-1 X'M^-1 y, SE from the same matrix.
if (file.exists(res_path)) {
  rj <- fromJSON(res_path, simplifyVector = FALSE)
  rho <- rj$settings$rho
  hand_fit <- function(y, v, study) {
    n <- length(y); X <- matrix(1, n, 1)
    V <- diag(v, n); same <- outer(study, study, "==")
    V[same & !diag(n)] <- (rho * sqrt(outer(v, v)))[same & !diag(n)]
    Z <- outer(study, unique(study), "==") * 1
    build <- function(s2) V + s2[1] * Z %*% t(Z) + s2[2] * diag(n)
    nll <- function(ls2) {
      M <- build(exp(ls2)); Mi <- solve(M); XtMiX <- t(X) %*% Mi %*% X
      b <- solve(XtMiX, t(X) %*% Mi %*% y); r <- y - X %*% b
      0.5 * (as.numeric(determinant(M)$modulus) + as.numeric(determinant(XtMiX)$modulus) + as.numeric(t(r) %*% Mi %*% r))
    }
    o <- optim(log(c(0.01, 0.01)), nll, method = "Nelder-Mead", control = list(reltol = 1e-14, maxit = 20000))
    s2 <- exp(o$par); Mi <- solve(build(s2)); XtMiX <- t(X) %*% Mi %*% X
    list(beta = as.numeric(solve(XtMiX, t(X) %*% Mi %*% y)), se = sqrt(as.numeric(solve(XtMiX))), s2 = s2, nll = o$value)
  }
  gls_at <- function(y, v, study, s2) {   # GLS with the reported variance components
    n <- length(y); X <- matrix(1, n, 1); V <- diag(v, n); same <- outer(study, study, "==")
    V[same & !diag(n)] <- (rho * sqrt(outer(v, v)))[same & !diag(n)]
    Z <- outer(study, unique(study), "==") * 1
    Mi <- solve(V + s2[1] * Z %*% t(Z) + s2[2] * diag(n)); XtMiX <- t(X) %*% Mi %*% X
    list(beta = as.numeric(solve(XtMiX, t(X) %*% Mi %*% y)), se = sqrt(as.numeric(solve(XtMiX))))
  }
  # RQ2 differences rebuilt here independently: same study and pair_id, women minus men
  diffs_by_hand <- function(s) {
    w <- s[s$gender == "women" & !is.na(s$pair_id), ]; m <- s[s$gender == "men" & !is.na(s$pair_id), ]
    kw <- paste(w$study_id, w$pair_id); km <- paste(m$study_id, m$pair_id); both <- intersect(kw, km)
    data.frame(study_id = w$study_id[match(both, kw)], yi = w$yi[match(both, kw)] - m$yi[match(both, km)],
               vi = w$vi[match(both, kw)] + m$vi[match(both, km)])
  }
  main_d <- if ("adult_sample" %in% names(d)) d[is.na(d$adult_sample) | d$adult_sample == "yes", ] else d
  main_d <- main_d[is.na(main_d$outcome_type) | main_d$outcome_type == "perceived", ]
  # the fallback (protocol 2.8) keeps the same V but has a study-level random effect only (s2_es fixed at 0)
  hand_fit_fb <- function(y, v, study) {
    n <- length(y); X <- matrix(1, n, 1); V <- diag(v, n); same <- outer(study, study, "==")
    V[same & !diag(n)] <- (rho * sqrt(outer(v, v)))[same & !diag(n)]; Z <- outer(study, unique(study), "==") * 1
    nll <- function(ls2) { M <- V + exp(ls2) * Z %*% t(Z); Mi <- solve(M); XtMiX <- t(X) %*% Mi %*% X
      b <- solve(XtMiX, t(X) %*% Mi %*% y); r <- y - X %*% b
      0.5 * (as.numeric(determinant(M)$modulus) + as.numeric(determinant(XtMiX)$modulus) + as.numeric(t(r) %*% Mi %*% r)) }
    o <- optimize(nll, c(-30, 5), tol = 1e-12)
    Mi <- solve(V + exp(o$minimum) * Z %*% t(Z)); XtMiX <- t(X) %*% Mi %*% X
    list(beta = as.numeric(solve(XtMiX, t(X) %*% Mi %*% y)), se = sqrt(as.numeric(solve(XtMiX))), nll = o$objective)
  }
  nll_at <- function(y, v, study, s2) {
    n <- length(y); X <- matrix(1, n, 1); V <- diag(v, n); same <- outer(study, study, "==")
    V[same & !diag(n)] <- (rho * sqrt(outer(v, v)))[same & !diag(n)]; Z <- outer(study, unique(study), "==") * 1
    M <- V + s2[1] * Z %*% t(Z) + s2[2] * diag(n); Mi <- solve(M); XtMiX <- t(X) %*% Mi %*% X
    b <- solve(XtMiX, t(X) %*% Mi %*% y); r <- y - X %*% b
    0.5 * (as.numeric(determinant(M)$modulus) + as.numeric(determinant(XtMiX)$modulus) + as.numeric(t(r) %*% Mi %*% r))
  }
  # one reported model against its data: GLS at the reported variances, then an independent REML fit
  check_fit <- function(m, s) {
    fb <- startsWith(m$fit, "fallback")
    if (fb) chk(is.null(m$tau2_es) || is.na(m$tau2_es), sprintf("%s (f) labelled fallback but has a within-study variance", m$name))
    else chk(grepl("^CHE", m$fit), sprintf("%s (f) unexpected fit label '%s'", m$name, m$fit))
    s2 <- c(m$tau2_study, if (fb) 0 else m$tau2_es)
    g <- gls_at(s$yi, s$vi, s$study_id, s2)
    chk(abs(g$beta - m$estimate) < 1e-6, sprintf("%s (f) GLS estimate at reported tau2: hand=%.8f vs results=%.8f", m$name, g$beta, m$estimate))
    chk(abs(g$se - m$se) < 1e-6, sprintf("%s (f) GLS SE at reported tau2: hand=%.8f vs results=%.8f", m$name, g$se, m$se))
    h <- if (fb) hand_fit_fb(s$yi, s$vi, s$study_id) else hand_fit(s$yi, s$vi, s$study_id)
    # the reported variance components must sit at the REML maximum (they may not be unique, so compare -logLik)
    nll_rep <- nll_at(s$yi, s$vi, s$study_id, s2)
    chk(nll_rep - h$nll < 1e-6, sprintf("%s (f) reported tau2 not at the REML maximum: -logLik %.8f vs hand optimum %.8f", m$name, nll_rep, h$nll))
    chk(abs(h$beta - m$estimate) < 1e-3, sprintf("%s (f) hand REML estimate=%.6f vs results=%.6f", m$name, h$beta, m$estimate))
    fb
  }
  n_hand <- 0; n_fb <- 0
  rq_all <- Filter(function(m) grepl("^RQ[12]_", m$name), rj$models)
  for (m in rq_all) {
    f <- sub("^RQ[12]_", "", m$name)
    s <- if (startsWith(m$name, "RQ1_")) main_d[main_d$feature == f & main_d$gender == "women", c("study_id", "yi", "vi")]
         else diffs_by_hand(main_d[main_d$feature == f, ])
    fb <- check_fit(m, s); n_hand <- n_hand + 1; n_fb <- n_fb + fb
    if (fb) infos <- c(infos, sprintf("INFO (f) %s fitted with the fallback (%s); re-estimated with the same structure", m$name, m$fit))
  }
  # feature_status rebuilt from the data: tested when at least 3 studies (women's rows, or matched pairs)
  for (st in rj$feature_status) {
    f <- st$feature
    k1 <- length(unique(main_d$study_id[main_d$feature == f & main_d$gender == "women"]))
    k2 <- length(unique(diffs_by_hand(main_d[main_d$feature == f, ])$study_id))
    chk((st$rq1 == "tested") == (k1 >= 3), sprintf("(f) feature_status %s RQ1 '%s' but %d studies in the data", f, st$rq1, k1))
    chk((st$rq2 == "tested") == (k2 >= 3), sprintf("(f) feature_status %s RQ2 '%s' but %d studies with pairs", f, st$rq2, k2))
  }
  perc_all <- d[is.na(d$outcome_type) | d$outcome_type == "perceived", ]   # adolescent-only features are listed too
  chk(setequal(sapply(rj$feature_status, `[[`, "feature"), unique(perc_all$feature)), "(f) feature_status does not list every feature in the data")
  # every feature marked "tested" in feature_status must have its model in results.json
  n_tested <- sum(sapply(rj$feature_status, function(s) (s$rq1 == "tested") + (s$rq2 == "tested")))
  chk(length(rq_all) == n_tested, sprintf("(f) %d RQ1/RQ2 models in results.json but %d marked tested in feature_status", length(rq_all), n_tested))
  infos <- c(infos, sprintf("INFO (f) %d of %d RQ1/RQ2 models re-estimated by hand; %d of them fitted with the fallback", n_hand, length(rq_all), n_fb))

  # OC1 (positive control, a decision gate for RQ2 and RQ3): baseline gaps rebuilt from the gap sheet
  gpath <- file.path(dirname(path), "extraction_gap.csv")
  oc1 <- Filter(function(m) m$name == "OC1_baseline_gap", rj$models)
  if (file.exists(gpath)) {   # OC1 must be reported whenever at least 3 studies give a baseline gap
    gp0 <- read.csv(gpath, stringsAsFactors = FALSE, na.strings = c("", "NA"))
    kb <- length(unique(gp0$study_id[which(gp0$baseline == "yes")]))
    chk((length(oc1) == 1) == (kb >= 3), sprintf("(f) OC1 %s but %d studies give a baseline gap", if (length(oc1)) "reported" else "missing", kb))
  }
  if (length(oc1)) {
    chk(file.exists(gpath), "(f) OC1 reported but extraction_gap.csv not found next to the extraction sheet")
    if (file.exists(gpath)) {
      gp <- read.csv(gpath, stringsAsFactors = FALSE, na.strings = c("", "NA"))
      e <- compute_gap_es(gp)   # gap effect sizes are checked by hand in verify_effect_sizes.R (GATE 6)
      b <- data.frame(study_id = e$study_id, yi = e$yi, vi = e$vi)[which(gp$baseline == "yes"), ]
      check_fit(oc1[[1]], b)
      chk(isTRUE(rj$oc1_status == if (oc1[[1]]$ci_lb > 0) "passed" else "failed"), sprintf("(f) oc1_status '%s' does not follow the OC1 CI", rj$oc1_status))
      infos <- c(infos, "INFO (f) OC1 re-estimated by hand")
    }
  }
  # RQ4: one comparison per study and feature (most events), ln RES, REML + Knapp-Hartung, checked with meta
  apath <- file.path(dirname(path), "extraction_actual.csv")
  rq4 <- Filter(function(m) startsWith(m$name, "RQ4_"), rj$models)
  if (file.exists(apath)) {   # RQ4 must be pooled for every feature with at least 3 studies of counts
    a0 <- read.csv(apath, stringsAsFactors = FALSE, na.strings = c("", "NA")); a0 <- a0[which(a0$metric == "counts"), ]
    for (f in unique(a0$feature)) {
      ka <- length(unique(a0$study_id[a0$feature == f])); has4 <- paste0("RQ4_", f) %in% sapply(rq4, `[[`, "name")
      chk(has4 == (ka >= 3), sprintf("(f) RQ4_%s %s but %d studies of counts", f, if (has4) "reported" else "missing", ka))
    }
  }
  if (length(rq4)) {
    chk(file.exists(apath), "(f) RQ4 reported but extraction_actual.csv not found next to the extraction sheet")
    if (file.exists(apath)) {
      ac <- read.csv(apath, stringsAsFactors = FALSE, na.strings = c("", "NA"))
      ac <- ac[which(ac$metric == "counts"), ]
      ac$events <- ac$ctrl_before + ac$ctrl_after + ac$trt_before + ac$trt_after
      ac <- ac[order(-ac$events), ]; ac <- ac[!duplicated(ac[, c("study_id", "feature")]), ]
      ac <- compute_res(ac)   # ln RES is checked by hand in verify_effect_sizes.R (GATE 6)
      for (m in rq4) {
        s <- ac[ac$feature == sub("^RQ4_", "", m$name), ]
        mg <- metagen(TE = s$yi, seTE = sqrt(s$vi), method.tau = "REML", method.random.ci = "HK", common = FALSE, random = TRUE)
        chk(m$k == length(unique(s$study_id)), sprintf("%s (f) k=%s vs %d studies rebuilt", m$name, m$k, length(unique(s$study_id))))
        chk(abs(mg$TE.random - m$estimate) < 1e-4, sprintf("%s (f) ln RES meta=%.6f vs results=%.6f", m$name, mg$TE.random, m$estimate))
        chk(abs(mg$lower.random - m$ci_lb) < 1e-4 && abs(mg$upper.random - m$ci_ub) < 1e-4,
            sprintf("%s (f) CI meta=[%.4f, %.4f] vs results=[%.4f, %.4f]", m$name, mg$lower.random, mg$upper.random, m$ci_lb, m$ci_ub))
        chk(abs(mg$tau2 - m$tau2) < 1e-4, sprintf("%s (f) tau2 meta=%.6f vs results=%.6f", m$name, mg$tau2, m$tau2))
        # hand REML (meta uses metafor for tau2, so this is the independent check) and Knapp-Hartung CI
        y <- s$yi; v <- s$vi; k <- length(y)
        rl <- function(t2) { w <- 1 / (v + t2); mu <- sum(w * y) / sum(w)
          0.5 * (sum(log(v + t2)) + log(sum(w)) + sum(w * (y - mu)^2)) }
        t2 <- optimize(rl, c(0, 10), tol = 1e-12)$minimum
        if (rl(0) <= rl(t2)) t2 <- 0
        w <- 1 / (v + t2); mu <- sum(w * y) / sum(w)
        se_kh <- sqrt(sum(w * (y - mu)^2) / ((k - 1) * sum(w)))
        ci_h <- mu + c(-1, 1) * qt(0.975, k - 1) * se_kh
        chk(abs(t2 - m$tau2) < 1e-4, sprintf("%s (f) tau2 hand REML=%.6f vs results=%.6f", m$name, t2, m$tau2))
        chk(abs(mu - m$estimate) < 1e-4, sprintf("%s (f) ln RES hand=%.6f vs results=%.6f", m$name, mu, m$estimate))
        chk(abs(ci_h[1] - m$ci_lb) < 1e-4 && abs(ci_h[2] - m$ci_ub) < 1e-4,
            sprintf("%s (f) Knapp-Hartung CI hand=[%.4f, %.4f] vs results=[%.4f, %.4f]", m$name, ci_h[1], ci_h[2], m$ci_lb, m$ci_ub))
      }
      infos <- c(infos, sprintf("INFO (f) %d RQ4 models checked against meta::metagen and a hand REML", length(rq4)))
    }
  }
}

# (g) decision layer (protocol 2.8 to 2.10), written again without analysis.R:
#     model p and TOST p from estimate, SE and df; Holm by hand over the family; decision order of 2.9;
#     robust label from the stored sensitivity decisions; RQ2 labels from the OC1 status
if (file.exists(res_path)) {
  rj <- fromJSON(res_path, simplifyVector = FALSE)
  A <- rj$settings$alpha; B <- rj$settings$sesoi; KMOD <- rj$settings$min_k_moderators
  holm_hand <- function(p) {   # step-down: sort, multiply by (m - rank + 1), running maximum, cap at 1
    m <- length(p); o <- order(p); adj <- numeric(m); run <- 0
    for (j in seq_len(m)) { run <- max(run, (m - j + 1) * p[o[j]]); adj[o[j]] <- min(1, run) }
    adj
  }
  decide_hand <- function(ph, pth, est) {
    if (ph < A && pth < A) return(sprintf("present but smaller than the SESOI (%s)", if (est > 0) "positive" else "negative"))
    if (ph < A) return(if (est > 0) "supported" else "opposite direction")
    if (pth < A) return("equivalent (no meaningful effect)")
    "inconclusive"
  }
  sets_expected <- c("rho_0", "rho_0.3", "rho_0.8", "r_0.3", "r_0.7", "without_high_rob", "without_author_data",
                     "experiments_only", "without_seen_studies", "without_ceiling_floor")
  r3 <- Filter(function(m) startsWith(m$name, "RQ3_"), rj$models)
  if (length(r3)) {
    st <- unlist(rj$oc1_status)
    ih <- if (st == "passed") "as planned" else if (st == "failed") "uninformative (positive control not met)" else "interpret with caution (positive control not possible)"
    chk(identical(ih, r3[[1]]$interpretation), sprintf("(g) RQ3 interpretation by hand '%s' vs results '%s'", ih, r3[[1]]$interpretation))
  }
  for (fam in c("RQ1_", "RQ2_")) {
    ms <- Filter(function(m) startsWith(m$name, fam), rj$models)
    if (!length(ms)) next
    p <- t_ <- numeric(length(ms))
    for (i in seq_along(ms)) {
      m <- ms[[i]]; tt <- m$estimate / m$se
      p[i] <- 2 * pt(-abs(tt), m$df)
      t_[i] <- max(1 - pt((m$estimate + B) / m$se, m$df), pt((m$estimate - B) / m$se, m$df))
      chk(abs(p[i] - m$pval) < 1e-8, sprintf("%s (g) p hand=%.10f vs results=%.10f", m$name, p[i], m$pval))
      chk(abs(t_[i] - m$p_tost) < 1e-8, sprintf("%s (g) TOST p hand=%.10f vs results=%.10f", m$name, t_[i], m$p_tost))
      chk(isTRUE(m$family_size == length(ms)), sprintf("%s (g) family_size %s vs %d tested features", m$name, m$family_size, length(ms)))
    }
    ph <- holm_hand(p); pth <- holm_hand(t_)
    for (i in seq_along(ms)) {
      m <- ms[[i]]
      chk(abs(ph[i] - m$p_holm) < 1e-8, sprintf("%s (g) Holm p hand=%.10f vs results=%.10f", m$name, ph[i], m$p_holm))
      chk(abs(pth[i] - m$p_tost_holm) < 1e-8, sprintf("%s (g) Holm TOST p hand=%.10f vs results=%.10f", m$name, pth[i], m$p_tost_holm))
      dh <- decide_hand(ph[i], pth[i], m$estimate)
      chk(identical(dh, m$decision), sprintf("%s (g) decision by hand '%s' vs results '%s'", m$name, dh, m$decision))
      # robust: every sensitivity set present, CR2 only with k >= 10, leave-one-out entries; any missing = not assessable
      alt <- m$decisions_in_sensitivity
      nm <- names(alt)
      chk(all(sets_expected %in% nm), sprintf("%s (g) sensitivity sets missing: %s", m$name, paste(setdiff(sets_expected, nm), collapse = ", ")))
      chk(("cr2" %in% nm) == (m$k >= KMOD), sprintf("%s (g) CR2 in the robust label must match k >= %d (k = %s)", m$name, KMOD, m$k))
      # leave-one-out: one entry per study when k >= 4, a single empty entry when k = 3
      loo_nm <- nm[startsWith(nm, "loo")]
      if (m$k >= 4) chk(length(loo_nm) == m$k, sprintf("%s (g) %d leave-one-out entries for k = %s", m$name, length(loo_nm), m$k))
      else chk(identical(loo_nm, "loo") && is.null(alt$loo), sprintf("%s (g) k = 3 needs a single empty leave-one-out entry", m$name))
      vals <- sapply(alt, function(x) if (is.null(x)) NA_character_ else as.character(x))
      rh <- if (any(is.na(vals))) "robustness not assessable" else if (all(vals == m$decision)) "robust" else "not robust"
      chk(identical(rh, m$robust), sprintf("%s (g) robust label by hand '%s' vs results '%s'", m$name, rh, m$robust))
      if (fam == "RQ2_") {
        st <- unlist(rj$oc1_status)
        lab_h <- if (st == "failed") "positive control not met" else if (startsWith(st, "not possible")) "positive control not possible: interpret with caution" else NULL
        chk(identical(lab_h, m$label), sprintf("%s (g) OC1 label by hand '%s' vs results '%s'", m$name, if (is.null(lab_h)) "none" else lab_h, if (is.null(m$label)) "none" else m$label))
      }
    }
    # leave-one-out decisions refitted with the hand CHE code; the other features keep their main p (protocol 2.10)
    n_loo <- 0
    for (i in seq_along(ms)) {
      m <- ms[[i]]; if (m$k < 4) next
      f <- sub(fam, "", m$name)
      s_all <- if (fam == "RQ1_") main_d[main_d$feature == f & main_d$gender == "women", c("study_id", "yi", "vi")]
               else diffs_by_hand(main_d[main_d$feature == f, ])
      for (id in as.character(unique(s_all$study_id))) {
        s <- s_all[as.character(s_all$study_id) != id, ]; dfl <- length(unique(s$study_id)) - 1
        fn <- m$loo_fit[[id]]
        chk(!is.null(fn), sprintf("%s (g) leave out %s: model used not recorded", m$name, id))
        h <- if (!is.null(fn) && startsWith(fn, "fallback")) hand_fit_fb(s$yi, s$vi, s$study_id) else hand_fit(s$yi, s$vi, s$study_id)
        pl <- p; tl <- t_
        pl[i] <- 2 * pt(-abs(h$beta / h$se), dfl)
        tl[i] <- max(1 - pt((h$beta + B) / h$se, dfl), pt((h$beta - B) / h$se, dfl))
        dl <- decide_hand(holm_hand(pl)[i], holm_hand(tl)[i], h$beta)
        got <- m$decisions_in_sensitivity[[paste0("loo.", id)]]
        chk(identical(dl, got), sprintf("%s (g) leave out %s: decision by hand '%s' vs results '%s'", m$name, id, dl, if (is.null(got)) "none" else got))
        n_loo <- n_loo + 1
      }
    }
    infos <- c(infos, sprintf("INFO (g) %s family: %d leave-one-out decisions refitted by hand", sub("_", "", fam), n_loo))
    # CR2 decisions: Holm over CR2 p where k >= 10, model p otherwise (protocol 2.10)
    pc <- sapply(ms, function(m) if (m$k >= KMOD) m$cr2_pval else m$pval)
    tc <- sapply(ms, function(m) if (m$k >= KMOD) m$cr2_p_tost else m$p_tost)
    phc <- holm_hand(pc); pthc <- holm_hand(tc)
    for (i in seq_along(ms)) if (ms[[i]]$k >= KMOD) {
      dc <- decide_hand(phc[i], pthc[i], ms[[i]]$estimate)
      chk(identical(dc, ms[[i]]$decisions_in_sensitivity$cr2), sprintf("%s (g) CR2 decision by hand '%s' vs results '%s'", ms[[i]]$name, dc, ms[[i]]$decisions_in_sensitivity$cr2))
    }
    infos <- c(infos, sprintf("INFO (g) %s family: %d decisions recomputed by hand (Holm over %d features)", sub("_", "", fam), length(ms), length(ms)))
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
    if (!is.null(m$k) && grepl("^RQ[12]_", nm)) chk(m$k <= n_studies, sprintf("results %s: k=%s > %d included studies", nm, m$k, n_studies))
    if (!is.null(m$k) && !is.null(m$n_es)) chk(m$n_es >= m$k, sprintf("results %s: fewer effect sizes than studies", nm))
    if (!is.null(m$pval)) chk(m$pval >= 0 && m$pval <= 1, sprintf("results %s: p outside [0,1]", nm))
    if (!is.null(m$k) && m$k < 3) chk(FALSE, sprintf("results %s: pooled with k=%s < 3 (protocol forbids)", nm, m$k))
  }
} else infos <- c(infos, sprintf("INFO %s not found: (e) skipped", res_path))

if (length(infos)) cat(infos, sep = "\n")
if (length(errors)) { cat(errors, sep = "\n"); cat(sprintf("\nRESULT: FAILED (%d problems)\n", length(errors))); quit(status = 1) }
cat(sprintf("RESULT: PASSED (%d pooled groups checked 3 independent ways; 3-level models OK)\n", n_groups))
