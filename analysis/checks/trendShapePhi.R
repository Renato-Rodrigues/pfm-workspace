# Does the TREND SHAPE move the delivered feasibility share phi? (TODO item 13)
#
#   Rscript analysis/checks/trendShapePhi.R [group]
#
# WHY.  Item 13 asks whether the hard-coded trend shape should become a swept dimension.
# `analysis/checks/trendShapeGrid.R` showed the deployed shape is not the best fit -- `logi
# 2005/0.20` beats it in both sectors. But fit is not the criterion the project judges on
# (CLAUDE.md: "estimation improvements that do not change what the coupling delivers are
# not the priority"), so the question that actually decides item 13 is whether phi moves.
#
# THE BENCHMARK.  The numbers below are deliberately computed the same way as
# `analysis/checks/propagateFrontierRungsToPhi.R`, so they sit on the same scale as the two
# uncertainties already published in MODEL.md 3.4.1:
#
#     specification band (C31)      median |dphi| = 0.110
#     gamma robustness rungs (v4)   median |dphi| = 0.026 / 0.060 / 0.061
#
# If the trend shape moves phi by much less than 0.110 it is a robustness footnote and
# the fixed choice can be defended in MODEL.md 2. If it is comparable, the trend is a
# first-order uncertainty and belongs in the sweep.
#
# WHAT IS HELD FIXED.  The deployed specification, theta = 0.50, seed year 2022, and the
# weighting step -- pfmCouplingWeights() needs IEA energy balances that are not on the
# workstation, so every statistic is reported under equal AND GDP weights. If the two
# agree the conclusion does not depend on the weights that could not be rebuilt. This is
# the same bracket propagateFrontierRungsToPhi.R uses, for the same reason.
#
# WHAT CHANGES PER SETTING.  The trend column itself, so each setting gets its own fit and
# its own design -- E is computed from that fit's own ceiling, not by re-weighting one
# design. That is simpler than the gamma-rung case, where the design is shared.
#
# Author: Renato Rodrigues

suppressWarnings(suppressMessages({library(yaml); library(magclass); library(frontier)}))
source("analysis/_common/_loadPfm.R")
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")

args      <- commandArgs(trailingOnly = TRUE)
GROUP     <- if (length(args) >= 1) args[[1]] else "v5"
SEED_YEAR <- 2022
THETA     <- 0.50
MAPPINGS  <- c(EU21 = "models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv",
               H12  = "models/mrpfm/inst/extdata/regional/regionmappingH12.csv")

SETTINGS <- list(
  deployed  = list(logisticTimeTrend = TRUE, timeTrend = FALSE,
                   trendMidpoint = 2010, trendSteepness = 0.20),
  # Best-fitting estimable shapes on v5 (trend-shape-grid.rds): Bulk 2005/0.10 (+4.1 logLik),
  # Diffuse 2010/0.30 (+21.2). 2005/0.20 is NOT estimable in Bulk on v5 and hangs inside
  # FRONTIER's Fortran with no timeout, so it is not run here.
  `2005/0.10` = list(logisticTimeTrend = TRUE, timeTrend = FALSE,
                     trendMidpoint = 2005, trendSteepness = 0.10),
  `2010/0.30` = list(logisticTimeTrend = TRUE, timeTrend = FALSE,
                     trendMidpoint = 2010, trendSteepness = 0.30),
  linear    = list(logisticTimeTrend = FALSE, timeTrend = TRUE))

panel <- .panelForGroup(GROUP)
sel   <- yaml::read_yaml(pfm:::.pfmSelectedModels(file.path("output/pfm", GROUP)))
.norm <- function(s) {
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
    if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]])
  s
}

fitFor <- function(sector, over) {
  cfg <- .norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sector)),
                      sel)[[1]])
  a <- .pfmSpecArgs(cfg)
  for (n in names(over)) a[[n]] <- over[[n]]
  suppressWarnings(do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sector, estimator = "frontier", indexMax = 10,
         modelDir = NULL, verbose = FALSE), a)))
}

# E = observed / ceiling, from the fit's OWN design. No Jondrow term -- the coupling
# consumes the ceiling alone (computeFeasibilityFrontier()).
ceilingE <- function(fit, indexMax = 10) {
  df  <- fit$data
  fml <- stats::as.formula(fit$formula)
  mm  <- stats::model.matrix(fml, data = df)
  b   <- stats::coef(fit$model)
  keep <- intersect(colnames(mm), names(b))
  eta <- as.numeric(mm[, keep, drop = FALSE] %*% b[keep])
  obs <- as.numeric(fit$outcomeNatural[rownames(mm)])
  ceil <- indexMax * stats::plogis(eta)
  data.frame(region = as.character(df[rownames(mm), "region"]),
             year = df[rownames(mm), "year"],
             E = pmin(pmax(obs / pmax(ceil, 1e-9), 0), 1),
             stringsAsFactors = FALSE, row.names = NULL)
}

# --- kept IDENTICAL to propagateFrontierRungsToPhi.R so the numbers are comparable ----
readMap <- function(path) {
  m <- utils::read.csv(path, sep = ";", stringsAsFactors = FALSE)
  stats::setNames(as.character(m[["RegionCode"]]), as.character(m[["CountryCode"]]))
}
MAPS <- lapply(MAPPINGS, readMap)
gdpW <- {
  g <- panel[, paste0("y", SEED_YEAR), "GDP"]
  stats::setNames(as.numeric(g), magclass::getRegions(panel))
}
phiFromE <- function(Edf, weights = c("equal", "gdp"), theta = THETA, res = "EU21") {
  weights <- match.arg(weights)
  d <- Edf[Edf$year == SEED_YEAR, ]
  d$reg <- MAPS[[res]][d$region]
  d <- d[!is.na(d$reg), ]
  d$w <- if (weights == "equal") 1 else pmax(gdpW[d$region], 0)
  agg <- stats::aggregate(cbind(num = d$E * d$w, den = d$w), by = list(reg = d$reg), sum)
  Er <- stats::setNames(agg$num / agg$den, agg$reg)
  g <- 1 - Er
  u <- (g - min(g)) / (max(g) - min(g))
  1 - theta * u
}
compare <- function(a, b) {
  common <- intersect(names(a), names(b)); a <- a[common]; b <- b[common]
  list(n = length(common),
       spearman = suppressWarnings(stats::cor(a, b, method = "spearman")),
       medAbsD = stats::median(abs(a - b)), maxAbsD = max(abs(a - b)),
       maxAt = common[which.max(abs(a - b))],
       medRankShift = stats::median(abs(rank(-a) - rank(-b))))
}
# --------------------------------------------------------------------------------------

E <- list()
for (nm in names(SETTINGS)) {
  for (sec in c("Bulk", "Diffuse")) {
    message("[fit] ", nm, " / ", sec)
    E[[nm]][[sec]] <- ceilingE(fitFor(sec, SETTINGS[[nm]]))
  }
}

fmt <- function(x) sprintf("n=%2d  rho=%6.3f  med|d|=%.4f  max|d|=%.4f (%s)  medRankShift=%.1f",
                           x$n, x$spearman, x$medAbsD, x$maxAbsD, x$maxAt, x$medRankShift)

cat("\n=========== TREND SHAPE -> phi, Run-Group ", GROUP,
    " (seed ", SEED_YEAR, ", theta ", THETA, ") ===========\n", sep = "")
cat("benchmarks: specification band 0.110 | gamma rungs 0.026 / 0.060 / 0.061\n")

out <- list(group = GROUP, seedYear = SEED_YEAR, theta = THETA, generated = Sys.time())
for (res in names(MAPS)) for (wt in c("equal", "gdp")) {
  base <- NULL
  cat("\n--- delivered phi = min(Bulk, Diffuse) [", res, " / ", wt, "] ---\n", sep = "")
  for (nm in names(SETTINGS)) {
    pb <- phiFromE(E[[nm]]$Bulk, wt, res = res)
    pd <- phiFromE(E[[nm]]$Diffuse, wt, res = res)
    common <- sort(intersect(names(pb), names(pd)))
    mn <- pmin(pb[common], pd[common])
    nBulk <- sum(pb[common] < pd[common])
    if (is.null(base)) {
      base <- mn
      cat(sprintf("  %-11s (reference)  nBulk=%d/%d  median phi=%.4f\n",
                  nm, nBulk, length(common), stats::median(mn)))
    } else {
      cat(sprintf("  %-11s %s  nBulk=%d/%d\n", nm, fmt(compare(base, mn)), nBulk, length(common)))
      out$vsDeployed[[res]][[wt]][[nm]] <- compare(base, mn)
    }
    out$phi[[res]][[wt]][[nm]] <- mn
  }
}

o <- file.path("output/pfm", GROUP, "trend-shape-phi.rds")
saveRDS(out, o)
cat("\nwritten: ", o, "\n", sep = "")
