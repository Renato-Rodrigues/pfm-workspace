# How well do simple institution rules reproduce PoliClim's SSP2 projections? (repo root)
#   Rscript analysis/checks/policlimRuleFit.R [path to the PoliClim folder]   -> output/checks/policlim-rule-fit.rds
#
# Candidate replacements for the declared convergence rule (DATA.md §5.4), each fitted to PoliClim's SSP2 country paths
# (2030-2100, five-year steps) by least squares, per indicator, and scored on the levels and on the change 2025-2100:
#   current  logistic convergence to the 2025 75th percentile, half the gap by 2080, no decline (DATA.md §5.4; not fitted)
#   global   x(t) = x0 + (1 - exp(-lambda (t - 2025))) (T - x0): every country moves toward one common level T
#   regional x(t) = x0 + (1 - exp(-lambda (t - 2025))) (r_c + delta - x0): toward its region's 2025 mean, shifted by delta
#   trend    x(t) = x0 + g (t - 2025), clipped to [0, 1]: a common drift, no convergence
# Regions are PoliClim's own (V-Dem regions, column forward2). Indicators: rule of law (v2xcl_rol), overall
# accountability, government effectiveness (0.5 + 0.2 WGI), electoral democracy (v2x_polyarchy).
pcDir <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "../PoliClim projections" })
OUT <- "output/checks"; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
pc <- read.csv2(file.path(pcDir, "pol_institutions_forecast.csv"), stringsAsFactors = FALSE, dec = ".")
IND <- c(rol = "f_Rule_of_law", acc = "f_acc", ge = "f_gov_eff", ed = "f_ele_dem")
for (k in IND) pc[[k]] <- suppressWarnings(as.numeric(pc[[k]]))
T0 <- 2025; YRS <- seq(2030, 2100, 5)
s2 <- pc[pc$scenario == "SSP2", ]

fitOne <- function(k) {
  x0 <- s2[s2$year == T0, c("countrycode", "forward2", IND[[k]])]; names(x0) <- c("c", "region", "x0")
  x0 <- x0[is.finite(x0$x0), ]
  p <- s2[s2$year %in% YRS, c("countrycode", "year", IND[[k]])]; names(p) <- c("c", "year", "x")
  d <- merge(p, x0, by = "c"); d <- d[is.finite(d$x), ]
  rmean <- tapply(x0$x0, x0$region, mean); d$r <- rmean[d$region]
  tau <- d$year - T0
  q75 <- stats::quantile(x0$x0, 0.75)
  # the current rule (SSP2 = rule (a)): logistic in time, half by 2080, complete by 2150 (pfmInstitutionStorylines)
  sh <- function(t) { s <- 1 / (1 + exp(-0.08 * (t - 2080))); s0 <- 1 / (1 + exp(-0.08 * (T0 - 2080)))
                      s1 <- 1 / (1 + exp(-0.08 * (2150 - 2080))); (s - s0) / (s1 - s0) }
  pred <- list(current = ifelse(d$x0 >= q75, d$x0, d$x0 + sh(d$year) * (q75 - d$x0)))
  sse <- function(f) function(par) sum((f(par) - d$x)^2)
  fg <- function(par) d$x0 + (1 - exp(-exp(par[1]) * tau)) * (par[2] - d$x0)
  og <- stats::optim(c(log(0.01), mean(d$x0)), sse(fg)); pred$global <- fg(og$par)
  fr <- function(par) d$x0 + (1 - exp(-exp(par[1]) * tau)) * (d$r + par[2] - d$x0)
  or <- stats::optim(c(log(0.01), 0), sse(fr)); pred$regional <- fr(or$par)
  # top: the common level fixed at the top of the scale - the best value observed 1996-2025, as in the model's
  # rule (pfm::pfmInstitutionGapClosureRates) - only the rate fitted
  TOP <- max(s2[s2$year <= T0, IND[[k]]], na.rm = TRUE)
  fT <- function(par) TOP - (TOP - d$x0) * exp(-exp(par) * tau)
  oT <- stats::optim(log(0.01), sse(fT), method = "Brent", lower = log(1e-4), upper = log(0.2)); pred$top <- fT(oT$par)
  # top, shared: T = 1 and one rate for the three V-Dem-based indicators (rule of law, accountability, democracy)
  fS <- function(lam) d$x0 + (1 - exp(-lam * tau)) * (1 - d$x0)
  pred$topShared <- fS(SHARED)
  ft <- function(par) pmin(pmax(d$x0 + par[1] * tau, 0), 1)
  ot <- stats::optim(0.001, sse(ft), method = "Brent", lower = -0.01, upper = 0.01); pred$trend <- ft(ot$par)
  e <- d$year == 2100
  score <- do.call(rbind, lapply(names(pred), function(m) {
    y <- pred[[m]]
    data.frame(indicator = k, rule = m, rmseAll = sqrt(mean((y - d$x)^2)),
               r2Change2100 = 1 - sum(((y - d$x0) - (d$x - d$x0))[e]^2) / sum(((d$x - d$x0) - mean(d$x - d$x0))[e]^2),
               meanChange2100 = mean((y - d$x0)[e]), declining2100 = mean((y - d$x0)[e] < -0.005))
  }))
  pars <- data.frame(indicator = k, top = TOP, lambdaTop = exp(oT$par), halfLifeTop = log(2) / exp(oT$par), lambdaGlobal = exp(og$par[1]), halfLifeGlobal = log(2) / exp(og$par[1]),
                     targetGlobal = og$par[2], lambdaRegional = exp(or$par[1]), halfLifeRegional = log(2) / exp(or$par[1]),
                     deltaRegional = or$par[2], trend = ot$par, mean2025 = mean(x0$x0), q75 = unname(q75),
                     policlimMeanChange2100 = mean((d$x - d$x0)[e]), policlimDeclining2100 = mean((d$x - d$x0)[e] < -0.005),
                     policlimCorLevelChange = stats::cor(d$x0[e], (d$x - d$x0)[e]), n = sum(e))
  list(score = score, pars = pars)
}
# the shared rate of 'topShared': T = 1, one lambda fitted jointly on rule of law, accountability and democracy
SHARED <- local({
  dd <- do.call(rbind, lapply(c("rol", "acc", "ed"), function(k) {
    x0 <- s2[s2$year == T0, c("countrycode", IND[[k]])]; names(x0) <- c("c", "x0")
    p <- s2[s2$year %in% YRS, c("countrycode", "year", IND[[k]])]; names(p) <- c("c", "year", "x")
    d <- merge(p, x0, by = "c"); d[is.finite(d$x) & is.finite(d$x0), ] }))
  f <- function(l) sum((dd$x0 + (1 - exp(-exp(l) * (dd$year - T0))) * (1 - dd$x0) - dd$x)^2)
  exp(stats::optimize(f, c(log(1e-4), log(0.2)))$minimum) })
cat(sprintf("shared rate (T = 1): lambda %.4f a year, half-life %.0f years
", SHARED, log(2) / SHARED))
res <- lapply(names(IND), fitOne)
score <- do.call(rbind, lapply(res, `[[`, "score")); pars <- do.call(rbind, lapply(res, `[[`, "pars"))
# the near-term dip: cross-country mean by year under SSP2
dip <- do.call(rbind, lapply(names(IND), function(k) {
  m <- tapply(s2[[IND[[k]]]], s2$year, mean, na.rm = TRUE); m <- m[names(m) %in% as.character(2020:2050)]
  data.frame(indicator = k, year = as.integer(names(m)), mean = as.numeric(m))
}))
saveRDS(list(made = format(Sys.time(), "%Y-%m-%d %H:%M"), score = score, pars = pars, dip = dip, sharedLambda = SHARED),
        file.path(OUT, "policlim-rule-fit.rds"))
options(width = 180)
cat("== fitted parameters (SSP2)\n"); print(pars, digits = 3, row.names = FALSE)
cat("\n== fit to PoliClim SSP2 (RMSE over 2030-2100; R2 of the country change 2025-2100)\n"); print(score, digits = 3, row.names = FALSE)
cat("\n== SSP2 cross-country mean, 2020-2050\n")
print(reshape(dip[dip$year %in% c(2020, 2024, 2025, 2027, 2030, 2035, 2040, 2050), ], idvar = "indicator", timevar = "year",
              direction = "wide"), digits = 3, row.names = FALSE)
