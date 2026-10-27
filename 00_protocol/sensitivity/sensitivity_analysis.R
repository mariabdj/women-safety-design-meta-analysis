# Sensitivity (power) analysis for the Stage 1 protocol.
# Question: with k studies of a given size and a given amount of between-study spread (tau^2),
# what is the smallest pooled effect we can detect with 80% / 90% power?
# Random-effects power after Hedges & Pigott (2001) and Valentine, Pigott & Rothstein (2010),
# using a t-test on k - 1 df to match the planned analysis (test = "t").
# Simplification: one effect per study (the three-level model can only add precision, so this is conservative).
# Run from Projet1_Meta-Analyse/:  Rscript 00_protocol/sensitivity/sensitivity_analysis.R

out_dir <- "00_protocol/sensitivity"
alpha <- 0.05
sesoi <- 0.20

# typical within-study sampling variance of g (at g = 0)
designs <- data.frame(
  design = c("within-subject, n = 60 women, r = .5", "between-subject, 40 women per condition"),
  v      = c(2 * (1 - 0.5) / 60, 2 / 40)
)
i2_levels <- c(0, 0.25, 0.50, 0.75)   # tau^2 = v * I2 / (1 - I2) (Higgins & Thompson 2002, typical-v version)
k_levels  <- c(3, 5, 8, 10, 15, 20, 30)

power_t <- function(delta, k, v, tau2) {
  se  <- sqrt((v + tau2) / k)
  df  <- k - 1
  tc  <- qt(1 - alpha / 2, df)
  ncp <- delta / se
  pt(-tc, df, ncp) + 1 - pt(tc, df, ncp)
}

mde <- function(k, v, tau2, target) {
  uniroot(function(d) power_t(d, k, v, tau2) - target, c(1e-6, 10), tol = 1e-10)$root
}

grid <- expand.grid(k = k_levels, i2 = i2_levels, design = designs$design, stringsAsFactors = FALSE)
grid$v    <- designs$v[match(grid$design, designs$design)]
grid$tau2 <- grid$v * grid$i2 / (1 - grid$i2)
grid$power_at_sesoi <- mapply(power_t, sesoi, grid$k, grid$v, grid$tau2)
grid$mde80 <- mapply(mde, grid$k, grid$v, grid$tau2, 0.80)
grid$mde90 <- mapply(mde, grid$k, grid$v, grid$tau2, 0.90)

# RQ2: women minus men in the same study, independent subgroups of equal size -> variance doubles
grid_rq2 <- grid
grid_rq2$v    <- 2 * grid$v
grid_rq2$tau2 <- grid_rq2$v * grid_rq2$i2 / (1 - grid_rq2$i2)
grid_rq2$power_at_sesoi <- mapply(power_t, sesoi, grid_rq2$k, grid_rq2$v, grid_rq2$tau2)
grid_rq2$mde80 <- mapply(mde, grid_rq2$k, grid_rq2$v, grid_rq2$tau2, 0.80)
grid_rq2$mde90 <- mapply(mde, grid_rq2$k, grid_rq2$v, grid_rq2$tau2, 0.90)

grid$question <- "RQ1 pooled effect for women"
grid_rq2$question <- "RQ2 women minus men"
res <- rbind(grid, grid_rq2)
write.csv(res, file.path(out_dir, "sensitivity_results.csv"), row.names = FALSE)

# Smallest k giving 80% power at the SESOI, per scenario (NA if above 200)
need_k <- function(v, i2, target = 0.80) {
  tau2 <- v * i2 / (1 - i2)
  for (k in 3:200) if (power_t(sesoi, k, v, tau2) >= target) return(k)
  NA_integer_
}
kk <- expand.grid(i2 = i2_levels, design = designs$design, question = c("RQ1", "RQ2"), stringsAsFactors = FALSE)
kk$v <- designs$v[match(kk$design, designs$design)] * ifelse(kk$question == "RQ2", 2, 1)
kk$k_for_80 <- mapply(need_k, kk$v, kk$i2)
kk$k_for_90 <- mapply(need_k, kk$v, kk$i2, 0.90)
write.csv(kk, file.path(out_dir, "k_needed.csv"), row.names = FALSE)

# Figure: power at g = 0.20 against k
png(file.path(out_dir, "power_curves.png"), width = 1600, height = 800, res = 160)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))
for (q in c("RQ1 pooled effect for women", "RQ2 women minus men")) {
  sub <- res[res$question == q & res$design == designs$design[1], ]
  plot(NA, xlim = c(3, 30), ylim = c(0, 1), xlab = "Number of studies (k)", ylab = "Power at g = 0.20",
       main = paste0(q, "\n(", designs$design[1], ")"), cex.main = 0.85)
  abline(h = c(0.8, 0.9), lty = 3, col = "grey50")
  for (j in seq_along(i2_levels)) {
    s <- sub[sub$i2 == i2_levels[j], ]
    lines(s$k, s$power_at_sesoi, lwd = 2, lty = j)
  }
  legend("bottomright", legend = paste0("I2 = ", i2_levels * 100, "%"), lty = seq_along(i2_levels), lwd = 2, bty = "n", cex = 0.8)
}
dev.off()

print(kk)
print(res[res$k == 10 & res$i2 == 0.5, c("question", "design", "power_at_sesoi", "mde80", "mde90")])
