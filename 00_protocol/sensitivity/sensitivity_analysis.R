# Sensitivity (power) analysis for the Stage 1 protocol.
# Question: with k studies of a given size and a given amount of between-study spread (tau^2),
# (1) what is the power to detect the SESOI, and the smallest effect detectable with 80% power, and
# (2) what is the power of the equivalence test (TOST) when the true effect is 0?
# Both at alpha = .05 (Holm's largest p-value) and at alpha = .05 / 6 (Holm's smallest p-value, six features).
# Random-effects power after Hedges & Pigott (2001) and Valentine, Pigott & Rothstein (2010),
# t-test on k - 1 df to match the planned analysis. One effect per study (conservative).
# Run from Projet1_Meta-Analyse/:  Rscript 00_protocol/sensitivity/sensitivity_analysis.R

out_dir <- "00_protocol/sensitivity"
sesoi <- 0.20
alphas <- c(holm_largest = 0.05, holm_smallest = 0.05 / 6)

# typical within-study sampling variance of g (at g = 0)
designs <- data.frame(
  design = c("within-subject, n = 60 women, r = .5", "between-subject, 40 women per condition"),
  v      = c(2 * (1 - 0.5) / 60, 2 / 40)
)
i2_levels <- c(0, 0.25, 0.50, 0.75)   # tau^2 = v * I2 / (1 - I2) (Higgins & Thompson 2002, typical-v version)
k_levels  <- c(3, 5, 8, 10, 15, 20, 30)

power_t <- function(delta, k, v, tau2, alpha) {
  se <- sqrt((v + tau2) / k); df <- k - 1; tc <- qt(1 - alpha / 2, df); ncp <- delta / se
  pt(-tc, df, ncp) + 1 - pt(tc, df, ncp)
}
mde <- function(k, v, tau2, target, alpha) uniroot(function(d) power_t(d, k, v, tau2, alpha) - target, c(1e-6, 10), tol = 1e-10)$root
# TOST power when the true effect is 0: the estimate must fall inside (-sesoi + tc*se, sesoi - tc*se)
power_tost0 <- function(k, v, tau2, alpha) {
  se <- sqrt((v + tau2) / k); df <- k - 1; tc <- qt(1 - alpha, df); h <- sesoi / se - tc
  if (h <= 0) 0 else pt(h, df) - pt(-h, df)
}

grid <- expand.grid(k = k_levels, i2 = i2_levels, design = designs$design, question = c("RQ1", "RQ2"),
                    alpha_name = names(alphas), stringsAsFactors = FALSE)
grid$alpha <- alphas[grid$alpha_name]
# RQ2: women minus men in the same study, independent subgroups of equal size -> variance doubles
grid$v    <- designs$v[match(grid$design, designs$design)] * ifelse(grid$question == "RQ2", 2, 1)
grid$tau2 <- grid$v * grid$i2 / (1 - grid$i2)
grid$power_at_sesoi <- mapply(power_t, sesoi, grid$k, grid$v, grid$tau2, grid$alpha)
grid$mde80 <- mapply(mde, grid$k, grid$v, grid$tau2, 0.80, grid$alpha)
grid$mde90 <- mapply(mde, grid$k, grid$v, grid$tau2, 0.90, grid$alpha)
grid$power_tost_true0 <- mapply(power_tost0, grid$k, grid$v, grid$tau2, grid$alpha)
write.csv(grid, file.path(out_dir, "sensitivity_results.csv"), row.names = FALSE)

need_k <- function(v, i2, alpha, target = 0.80) {
  tau2 <- v * i2 / (1 - i2)
  for (k in 3:300) if (power_t(sesoi, k, v, tau2, alpha) >= target) return(k)
  NA_integer_
}
kk <- unique(grid[, c("i2", "design", "question", "alpha_name", "alpha", "v")])
kk$k_for_80 <- mapply(need_k, kk$v, kk$i2, kk$alpha)
kk$k_for_90 <- mapply(need_k, kk$v, kk$i2, kk$alpha, 0.90)
write.csv(kk, file.path(out_dir, "k_needed.csv"), row.names = FALSE)

# Figure: power at g = 0.20 against k, within-subject designs, both Holm bounds
png(file.path(out_dir, "power_curves.png"), width = 1600, height = 800, res = 160)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))
for (q in c("RQ1", "RQ2")) {
  plot(NA, xlim = c(3, 30), ylim = c(0, 1), xlab = "Number of studies (k)", ylab = "Power at g = 0.20",
       main = paste0(q, ", within-subject, I2 = 50%"), cex.main = 0.9)
  abline(h = 0.8, lty = 3, col = "grey50")
  for (j in seq_along(alphas)) {
    s <- grid[grid$question == q & grid$design == designs$design[1] & grid$i2 == 0.5 & grid$alpha_name == names(alphas)[j], ]
    lines(s$k, s$power_at_sesoi, lwd = 2, lty = j)
  }
  legend("bottomright", legend = c("alpha = .05", "alpha = .05/6"), lty = 1:2, lwd = 2, bty = "n", cex = 0.8)
}
dev.off()

print(kk[kk$i2 == 0.5, c("question", "design", "alpha_name", "k_for_80")])
print(grid[grid$k == 10 & grid$i2 == 0.5, c("question", "design", "alpha_name", "power_at_sesoi", "mde80", "power_tost_true0")])
