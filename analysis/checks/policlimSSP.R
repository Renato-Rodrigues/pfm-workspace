# PoliClim's institution forecasts across the SSPs: do they behave as the SSP narratives say, globally, by region and
# by country? (repo root; reads ../PoliClim projections/pol_institutions_forecast.csv)
#   Rscript analysis/checks/policlimSSP.R [path to the PoliClim folder]   -> output/checks/policlim-ssp.rds
#
# Reference: the SSP governance narratives (O'Neill et al. 2017; Andrijevic et al. 2020): SSP1 and SSP5 strong,
# improving and converging institutions; SSP2 slow, uneven progress; SSP3 weak, deteriorating, fragmented; SSP4
# polarised (capable states for elites, low accountability, divergence). Expected ordering of the cross-country mean by
# 2100: SSP1 >= SSP5 >= SSP2 >= SSP4 >= SSP3. PoliClim recommends SSP3c and SSP4c over SSP3 and SSP4.
# Columns: f_Rule_of_law (V-Dem v2xcl_rol), f_acc (v2x_accountability_osp), f_gov_eff (0.5 + 0.2 x WGI GE),
# f_ele_dem (v2x_polyarchy); the forecast starts in 2025 (government effectiveness: history to 2024).
`%||%` <- function(a, b) if (is.null(a)) b else a
pcDir <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "../PoliClim projections" })
OUT <- "output/checks"; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
pc <- read.csv2(file.path(pcDir, "pol_institutions_forecast.csv"), stringsAsFactors = FALSE, dec = ".")
IND <- c(rol = "f_Rule_of_law", acc = "f_acc", ge = "f_gov_eff", ed = "f_ele_dem")
OBS <- c(rol = "Rule_of_Law", acc = "acc_ind_osp", ge = "gov_eff", ed = "ele_dem_ind")
LAB <- c(rol = "rule of law (equality before the law)", acc = "overall accountability", ge = "government effectiveness",
         ed = "electoral democracy")
for (k in c(IND, OBS)) pc[[k]] <- suppressWarnings(as.numeric(pc[[k]]))
SSP <- c("SSP1", "SSP2", "SSP3", "SSP3c", "SSP4", "SSP4c", "SSP5")
T0 <- 2025; YRS <- c(2025, 2050, 2075, 2100)
wide <- function(ind, years = YRS) {   # country x scenario x year
  x <- pc[pc$year %in% years, c("countrycode", "forward2", "year", "scenario", IND[[ind]])]
  names(x)[5] <- "v"; x
}
at <- function(ind, y) { x <- wide(ind, y); stats::setNames(tapply(x$v, list(x$countrycode, x$scenario), mean), NULL) }
mat <- function(ind, y) { x <- pc[pc$year == y, c("countrycode", "scenario", IND[[ind]])]; names(x)[3] <- "v"
  m <- tapply(x$v, list(x$countrycode, x$scenario), mean); m[, SSP, drop = FALSE] }
out <- list(made = format(Sys.time(), "%Y-%m-%d %H:%M"), nCountries = length(unique(pc$countrycode)))

# ---- 0. data checks -------------------------------------------------------------------------------------------------
hist <- pc[pc$scenario == "SSP2" & pc$year <= 2024, ]
out$histVsFitted <- do.call(rbind, lapply(names(IND), function(k) {
  d <- hist[[IND[[k]]]] - hist[[OBS[[k]]]]; ok <- is.finite(d)
  data.frame(indicator = k, share = mean(abs(d[ok]) > 1e-9), maxAbs = max(abs(d[ok])), meanAbs = mean(abs(d[ok])))
}))
jump <- do.call(rbind, lapply(names(IND), function(k) {
  a <- mat(k, 2024); b <- mat(k, 2026); d <- b[, "SSP2"] - a[, "SSP2"]
  data.frame(indicator = k, meanAbs = mean(abs(d), na.rm = TRUE), p95 = stats::quantile(abs(d), .95, na.rm = TRUE),
             largest = paste(names(sort(abs(d), decreasing = TRUE))[1:5], collapse = " "))
}))
out$seam <- jump

# ---- 1. global: the cross-country mean, its ordering, and the spread ------------------------------------------------
glob <- do.call(rbind, lapply(names(IND), function(k) do.call(rbind, lapply(YRS, function(y) {
  m <- mat(k, y); data.frame(indicator = k, year = y, t(round(colMeans(m, na.rm = TRUE), 3)), check.names = FALSE)
}))))
out$globalMean <- glob
spread <- do.call(rbind, lapply(names(IND), function(k) do.call(rbind, lapply(YRS, function(y) {
  m <- mat(k, y); data.frame(indicator = k, year = y, t(round(apply(m, 2, stats::sd, na.rm = TRUE), 3)), check.names = FALSE)
}))))
out$globalSd <- spread
# polarisation: the gap between the countries above and below the 2025 median, 2100 against 2025
gap <- do.call(rbind, lapply(names(IND), function(k) {
  m0 <- mat(k, T0); m1 <- mat(k, 2100); hi <- m0[, "SSP2"] >= stats::median(m0[, "SSP2"], na.rm = TRUE)
  g <- function(m) colMeans(m[hi, , drop = FALSE], na.rm = TRUE) - colMeans(m[!hi, , drop = FALSE], na.rm = TRUE)
  data.frame(indicator = k, t(round(g(m1) / g(m0), 2)), check.names = FALSE)
}))
out$gapRatio2100 <- gap
# share of countries declining (2100 below 2025) by scenario
decl <- do.call(rbind, lapply(names(IND), function(k) {
  d <- mat(k, 2100) - mat(k, T0); data.frame(indicator = k, t(round(colMeans(d < -0.02, na.rm = TRUE), 2)), check.names = FALSE)
}))
out$shareDeclining <- decl

# ---- 2. regions -----------------------------------------------------------------------------------------------------
reg <- unique(pc[, c("countrycode", "forward2")]); reg <- stats::setNames(reg$forward2, reg$countrycode)
regional <- do.call(rbind, lapply(names(IND), function(k) {
  m0 <- mat(k, T0); m1 <- mat(k, 2100); r <- reg[rownames(m1)]
  d <- apply(m1 - m0, 2, function(v) tapply(v, r, mean, na.rm = TRUE))
  data.frame(indicator = k, region = rownames(d), n = as.integer(table(r)[rownames(d)]), round(d, 3), check.names = FALSE)
}))
out$regionalChange2100 <- regional

# ---- 3. countries: departures from the narrative ---------------------------------------------------------------------
tol <- 0.02
flags <- do.call(rbind, lapply(names(IND), function(k) {
  m0 <- mat(k, T0); m1 <- mat(k, 2100); m50 <- mat(k, 2050)
  data.frame(indicator = k, country = rownames(m1), region = reg[rownames(m1)], v2025 = m0[, "SSP2"],
             SSP1 = m1[, "SSP1"], SSP2 = m1[, "SSP2"], SSP3c = m1[, "SSP3c"], SSP4c = m1[, "SSP4c"], SSP5 = m1[, "SSP5"],
             ssp3cAboveSsp1 = m1[, "SSP3c"] > m1[, "SSP1"] + tol,
             ssp3AboveSsp2 = m1[, "SSP3"] > m1[, "SSP2"] + tol,
             ssp1Declines = m1[, "SSP1"] < m0[, "SSP1"] - tol,
             ssp5BelowSsp2 = m1[, "SSP5"] < m1[, "SSP2"] - tol,
             ssp4cAboveSsp1 = m1[, "SSP4c"] > m1[, "SSP1"] + tol,
             ssp3cBest = apply(m1, 1, function(v) names(v)[which.max(v)]) %in% c("SSP3", "SSP3c"),
             range2100 = apply(m1, 1, function(v) diff(range(v, na.rm = TRUE))),
             stringsAsFactors = FALSE)
}))
out$countryFlags <- flags
fl <- c("ssp3cAboveSsp1", "ssp3AboveSsp2", "ssp1Declines", "ssp5BelowSsp2", "ssp4cAboveSsp1", "ssp3cBest")
out$flagCounts <- do.call(rbind, lapply(names(IND), function(k) {
  x <- flags[flags$indicator == k, ]; data.frame(indicator = k, t(colSums(x[, fl], na.rm = TRUE)), check.names = FALSE)
}))
# paths that reverse: the 2025-2100 path changes direction more than once by more than tol (five-year steps)
rev <- do.call(rbind, lapply(names(IND), function(k) {
  x <- pc[pc$year %in% seq(2025, 2100, 5), c("countrycode", "scenario", "year", IND[[k]])]; names(x)[4] <- "v"
  s <- split(x, list(x$countrycode, x$scenario), drop = TRUE)
  r <- vapply(s, function(d) { d <- d[order(d$year), ]; dv <- diff(d$v); dv <- dv[abs(dv) > tol / 3]
    if (length(dv) < 2) 0L else sum(diff(sign(dv)) != 0) }, integer(1))
  data.frame(indicator = k, key = names(r), reversals = r)
}))
out$reversals <- stats::aggregate(reversals ~ indicator, rev, function(v) mean(v >= 2))

# ---- 4. coherence between indicators: electoral democracy and accountability moving apart ---------------------------
coh <- do.call(rbind, lapply(SSP, function(s) {
  dA <- mat("acc", 2100)[, s] - mat("acc", T0)[, s]; dE <- mat("ed", 2100)[, s] - mat("ed", T0)[, s]
  dR <- mat("rol", 2100)[, s] - mat("rol", T0)[, s]; dG <- mat("ge", 2100)[, s] - mat("ge", T0)[, s]
  data.frame(scenario = s, corAccEd = stats::cor(dA, dE, use = "pairwise"), corAccRol = stats::cor(dA, dR, use = "pairwise"),
             corAccGe = stats::cor(dA, dG, use = "pairwise"), corRolGe = stats::cor(dR, dG, use = "pairwise"),
             oppositeAccGe = mean(sign(dA) * sign(dG) < 0 & abs(dA) > tol & abs(dG) > tol, na.rm = TRUE))
}))
out$coherence <- coh

# ---- 5. selected countries ------------------------------------------------------------------------------------------
KEY <- c("USA", "DEU", "FRA", "GBR", "JPN", "POL", "HUN", "TUR", "RUS", "CHN", "IND", "IDN", "BRA", "MEX", "ZAF", "NGA",
         "SAU", "IRN", "EGY", "KOR")
out$keyCountries <- do.call(rbind, lapply(names(IND), function(k) {
  m0 <- mat(k, T0); m1 <- mat(k, 2100); kk <- intersect(KEY, rownames(m1))
  data.frame(indicator = k, country = kk, v2025 = m0[kk, "SSP2"], round(m1[kk, , drop = FALSE], 2), check.names = FALSE)
}))
saveRDS(out, file.path(OUT, "policlim-ssp.rds"))

# ---- print ----------------------------------------------------------------------------------------------------------
options(width = 230)
cat("PoliClim institution forecasts:", out$nCountries, "countries, scenarios", paste(SSP, collapse = " "), "\n")
cat("\n0a. history: forecast column differs from the observed one (share of 1996-2024 cells, size)\n"); print(out$histVsFitted, row.names = FALSE, digits = 2)
cat("\n0b. seam: |2026 - 2024| (SSP2)\n"); print(out$seam, row.names = FALSE, digits = 2)
cat("\n1a. cross-country mean (unweighted)\n"); print(glob, row.names = FALSE)
cat("\n1b. cross-country SD\n"); print(spread, row.names = FALSE)
cat("\n1c. gap between the upper and lower half of 2025, 2100 / 2025 (>1 diverging)\n"); print(gap, row.names = FALSE)
cat("\n1d. share of countries lower in 2100 than in 2025 (by more than", tol, ")\n"); print(decl, row.names = FALSE)
cat("\n2. regional mean change 2025-2100\n"); for (k in names(IND)) { cat("--", LAB[[k]], "\n"); print(regional[regional$indicator == k, -1], row.names = FALSE) }
cat("\n3a. countries departing from the narrative (counts of", out$nCountries, ")\n"); print(out$flagCounts, row.names = FALSE)
cat("\n3b. share of country-scenario paths reversing direction at least twice\n"); print(out$reversals, row.names = FALSE, digits = 2)
cat("\n4. coherence of the 2025-2100 changes across countries\n"); print(coh, row.names = FALSE, digits = 2)
cat("\n5. selected countries, 2100 (2025 = SSP2 value)\n"); for (k in names(IND)) { cat("--", LAB[[k]], "\n"); print(out$keyCountries[out$keyCountries$indicator == k, -1], row.names = FALSE, digits = 2) }
