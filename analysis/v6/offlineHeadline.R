# Phase 1, step 9 of design note 0005: the first-round headline change, offline.
# The offline bound machinery (exportFeasibilityBound, as runPFMCouplingBound uses it) with the v6
# shares phi_r(t) from the anchor artifact, on the v5 reference (NPi) and optimal (PkBudg1000) price
# paths. Gives the DIRECTION of the change against v5 before any REMIND run. OFFLINE: one round, no
# REMIND response, no held-budget closure (rule C needs REMIND) - label every number so (GP-2).
#   Rscript analysis/v6/offlineHeadline.R [group]       (repo root; after analysis/v6/phase1.R and
#                                                        pfmRun(steps = "pfm-anchor") or runPFMAnchor)
# Cases, EU21, sector rule "min" (the worse sector), theta 0.325 / 0.50 / 0.675:
#   v5 formulation:    <group>'s and v5's coupling-summary.rds (tiers at 2022/2025, lambda speed limit)
#   v6:                phi(t) from the anchor, k(t) on the PkBudg1000 energy system, no speed limit
#   v6, k on NPi:      the same with k(t) read on the reference energy system
#   v6, phi held at t0: k = 1 throughout - isolates what the moving strength does
#   v6 + lambda:       the v6 phi(t) with <group>'s lambda speed limit - isolates removing lambda
# Output: output/pfm/<group>/phase1/offline-headline.rds and a printed summary.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v6" })
GD <- file.path("output/pfm", g); P1 <- file.path(GD, "phase1")
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)   # the registry's SSP2 pair (PITFALLS.md 34)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
THETAS <- c(0.325, 0.5, 0.675)
RUNS <- BASES

anc <- pfmAnchorFor(GD, "EU21")
TCO2 <- 1000 / (44 / 12)   # T$/GtC -> US$/tCO2, as runPFMCouplingBound
price <- function(f) { x <- gdx::readGDX(f, "pm_taxCO2eq") * TCO2; y <- getYears(x, as.integer = TRUE); x[, y[y >= 2025 & y <= 2100], ] }
pRef <- price(RUNS[["NPi"]]); pOpt <- price(RUNS[["PkBudg1000"]])
yrs <- getYears(pOpt, as.integer = TRUE)
cs <- readRDS(file.path(GD, "coupling/coupling-summary.rds")); lambdaG <- cs$lambda

st <- lapply(c(PkBudg1000 = "PkBudg1000", NPi = "NPi"), function(k)
  computeStrengthPath(anc, v6ScenPanel(P1, k, BASES[[k]])))
feas <- function(s, theta, hold = FALSE) {
  if (hold) { s$strength$k <- 1; s$strength$d <- 1 }
  sh <- computeSharePath(anc, s, theta = theta)
  sh <- sh[sh$sector %in% c("Bulk", "Diffuse") & sh$year %in% yrs, c("region", "year", "sector", "phi")]
  sh$tier <- NA_real_
  sh
}
bound <- function(f, lambda) exportFeasibilityBound(f, pOpt, pRef, lambda = lambda, sectorRule = "min")
summ <- function(b, case, theta) {
  q <- function(y, v) stats::median(b[[v]][b$year == y])
  data.frame(case = case, theta = theta, bindShare = mean(b$binds),
             medPrice2030 = q(2030, "priceBound"), medPrice2050 = q(2050, "priceBound"), medPrice2100 = q(2100, "priceBound"),
             optPrice2050 = q(2050, "priceOptimal"),
             shortfall2050pct = 100 * (1 - q(2050, "priceBound") / q(2050, "priceOptimal")),
             shortfall2100pct = 100 * (1 - q(2100, "priceBound") / q(2100, "priceOptimal")),
             stringsAsFactors = FALSE)
}
rows <- list(); regs <- list()
for (th in THETAS) {
  cases <- list(
    "v6: phi(t), k on PkBudg1000, no speed limit" = bound(feas(st$PkBudg1000, th), 0),
    "v6: phi(t), k on NPi, no speed limit"        = bound(feas(st$NPi, th), 0),
    "v6: phi held at t0 (k = 1), no speed limit"   = bound(feas(st$PkBudg1000, th, hold = TRUE), 0),
    "v6 phi(t) + v5-style lambda speed limit"      = bound(feas(st$PkBudg1000, th), lambdaG))
  for (nm in names(cases)) {
    rows[[paste(nm, th)]] <- summ(cases[[nm]], nm, th)
    b <- cases[[nm]]; regs[[paste(nm, th)]] <- cbind(case = nm, theta = th, b[b$year %in% c(2030, 2050, 2100), c("region", "year", "phi", "priceBound", "priceOptimal", "binds")])
  }
}
v6 <- do.call(rbind, rows); rownames(v6) <- NULL
# the v5 formulation, as computed by the pipeline (theta 0.25 / 0.50 / 0.75 grid; 0.50 is common)
old <- function(path, label) { if (!file.exists(path)) return(NULL); x <- readRDS(path)$thetaSweep
  x <- x[x$theta %in% c(0.25, 0.5, 0.75), ]
  data.frame(case = label, theta = x$theta, bindShare = x$bindShare, medPrice2030 = x$medPrice2030,
             medPrice2050 = x$medPrice2050, medPrice2100 = NA_real_, optPrice2050 = x$optPrice2050,
             shortfall2050pct = x$shortfall2050pct, shortfall2100pct = NA_real_, stringsAsFactors = FALSE) }
ref <- rbind(old(file.path(GD, "coupling/coupling-summary.rds"), paste0("v5 formulation, ", g, " spec (pipeline)")),
             old("output/pfm/v5/coupling/coupling-summary.rds", "v5 formulation, v5 spec (pipeline; future mapping, E26)"))
all <- rbind(ref, v6)
saveRDS(list(summary = all, regions = do.call(rbind, regs), lambda = lambdaG, thetas = THETAS,
             label = "OFFLINE first round - no REMIND response, no held-budget closure"),
        file.path(P1, "offline-headline.rds"))

options(width = 220)
cat("\n== OFFLINE first-round bound, EU21, sector rule min (median over regions; US$/tCO2)\n")
print(all[order(all$theta, all$case), ], row.names = FALSE, digits = 3)
r <- do.call(rbind, regs); r <- r[r$case == "v6: phi(t), k on PkBudg1000, no speed limit" & r$theta == 0.5, ]
cat("\n== v6 phi(t) per region, theta 0.5 (floor over sectors), k on PkBudg1000\n")
print(reshape(r[, c("region", "year", "phi")], idvar = "region", timevar = "year", direction = "wide"), row.names = FALSE, digits = 3)
v5t <- cs$boundAnchor[cs$boundAnchor$year == 2030, c("region", "phi")]; names(v5t)[2] <- "phi_v5formulation"
cat("\n== the same regions under the v5 formulation (", g, " spec, theta 0.5, time-invariant)\n"); print(v5t[order(v5t$phi_v5formulation), ], row.names = FALSE, digits = 3)
