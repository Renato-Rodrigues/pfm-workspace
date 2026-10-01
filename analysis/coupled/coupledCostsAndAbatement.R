# Where abatement moves, and what political feasibility costs in GDP and consumption.
#   Rscript analysis/coupled/coupledCostsAndAbatement.R v5 [gdx]
# Reads regional GHG emissions (vm_co2eq, GtCeq), GDP (vm_cesIO "inco", T$) and consumption
# (vm_cons, T$) from each coupled run and compares every mechanism run with its matched theta = 0
# null. Writes output/pfm/<group>/coupling/coupled-costs.json. Mode R's claim is that politics changes
# WHERE abatement happens; until this script, no artifact measured that.
suppressMessages(library(jsonlite))
a <- commandArgs(trailingOnly = TRUE)
GROUP <- if (length(a) >= 1) a[1] else "v5"; GDXDIR <- if (length(a) >= 2) a[2] else "output/remind-runs/v5"
ex <- new.env(); sys.source("analysis/coupled/extractCoupledResults.R", envir = ex); bin <- ex$gdxdumpBin()
art <- readRDS(file.path("output/pfm", GROUP, "coupling", "coupled-runs.rds"))
# Superseded re-runs stay in `runs` (flagged) so nothing disappears without trace - drop them here, or a
# scenario with two directories hands series() two gdx paths at once (2026-09-23: EU21 -PFMlevelC exists
# twice in the RULECFIX batch; no earlier batch had a duplicate, so no published number was affected).
R <- art$runs[!art$runs$superseded, ]; R$key <- sub("^SSP2-(EU21-)?", "", R$scenario)
C2C <- 44 / 12; YEARS <- 2020:2100; DISC <- 0.05

series <- function(res, key, symb, filt = NULL) {
  r <- R[R$resolution == res & R$key == key, ]
  d <- ex$readSymbol(file.path(GDXDIR, res, r$dir, "fulldata.gdx"), symb, bin)
  if (!is.null(filt)) d <- d[d[[3]] == filt, ]
  data.frame(year = as.integer(d[[1]]), region = d[[2]], v = as.numeric(d[[ncol(d)]]))
}
# annual interpolation between model periods, then sum / discount over 2020-2100
integrate <- function(df, discount = 0) {
  do.call(rbind, lapply(split(df, df$region), function(x) {
    x <- x[order(x$year), ]; f <- stats::approx(x$year, x$v, xout = YEARS, rule = 2)$y
    data.frame(region = x$region[1], total = sum(f / (1 + discount)^(YEARS - 2020)))
  }))
}
contrasts <- list(
  ratio = c("PkBudg1000-PFMratio", "PkBudg1000-PFMgate"), ratioTh325 = c("PkBudg1000-PFMratioTh325", "PkBudg1000-PFMgate"),
  ratioTh675 = c("PkBudg1000-PFMratioTh675", "PkBudg1000-PFMgate"), ratioGapC = c("PkBudg1000-PFMratioGapC", "PkBudg1000-PFMgate"),
  ratioMin = c("PkBudg1000-PFMratioMin", "PkBudg1000-PFMgate"), levelC = c("PkBudg1000-PFMlevelC", "PkBudg1000-PFMgate"),
  levelB = c("PkBudg1000-PFMlevelB", "PkBudg1000-PFMgateB"), levelBTh325 = c("PkBudg1000-PFMlevelBTh325", "PkBudg1000-PFMgateB"),
  levelBTh675 = c("PkBudg1000-PFMlevelBTh675", "PkBudg1000-PFMgateB"), mildProg = c("PkBudg1000-PFMmildProg", "PkBudg1000-PFMgateB"),
  # The FIXPRICE family (TODO 14g): the quantity headline lives here, so the cost and relocation
  # figures the paper quotes must be measured against ITS null, not the unforced one.
  levelBfix = c("PkBudg1000-PFMlevelBfix", "PkBudg1000-PFMgateBfix"),
  levelBfixTh325 = c("PkBudg1000-PFMlevelBfixTh325", "PkBudg1000-PFMgateBfix"),
  levelBfixTh675 = c("PkBudg1000-PFMlevelBfixTh675", "PkBudg1000-PFMgateBfix"),
  levelBfixGapC = c("PkBudg1000-PFMlevelBfixGapC", "PkBudg1000-PFMgateBfix"),
  levelBfixMin = c("PkBudg1000-PFMlevelBfixMin", "PkBudg1000-PFMgateBfix"),
  ratioBfix = c("PkBudg1000-PFMratioBfix", "PkBudg1000-PFMgateBfix"),
  # rule C with the mode-2 cap rebuilt every iteration (cm_pfmBoundRebuild = 1, RULECFIX, 2026-09-22):
  # the level cap's own held-budget closure, against the budget-forced null like ratio mode (GP-22)
  levelCTh325 = c("PkBudg1000-PFMlevelCTh325", "PkBudg1000-PFMgate"),
  levelCTh675 = c("PkBudg1000-PFMlevelCTh675", "PkBudg1000-PFMgate"),
  levelCGapC = c("PkBudg1000-PFMlevelCGapC", "PkBudg1000-PFMgate"),
  levelCMin = c("PkBudg1000-PFMlevelCMin", "PkBudg1000-PFMgate"),
  # the Run-Group variants of the held-price headline (GROUPVARIANTS, 2026-09-22): same run, feasibility
  # shares from a twin group (GP-14 specification band, GP-10(b) US assignment, GP-3(b) assignment rule)
  `levelBfix-specalt` = c("PkBudg1000-PFMlevelBfix-specalt", "PkBudg1000-PFMgateBfix"),
  `levelBfix-noinc` = c("PkBudg1000-PFMlevelBfix-noinc", "PkBudg1000-PFMgateBfix"),
  `levelBfix-usadonor` = c("PkBudg1000-PFMlevelBfix-usadonor", "PkBudg1000-PFMgateBfix"),
  `levelBfix-usalow` = c("PkBudg1000-PFMlevelBfix-usalow", "PkBudg1000-PFMgateBfix"),
  `levelBfix-allmedian` = c("PkBudg1000-PFMlevelBfix-allmedian", "PkBudg1000-PFMgateBfix"),
  `levelBfix-alllow` = c("PkBudg1000-PFMlevelBfix-alllow", "PkBudg1000-PFMgateBfix"),
  # the pinning gate, as a cost contrast: -PFMgateBfix against the budget-forced -PFMgate
  gateBfix = c("PkBudg1000-PFMgateBfix", "PkBudg1000-PFMgate"))
out <- list(group = GROUP, generated = format(Sys.time()), units = list(
  emissions = "GtCO2eq, vm_co2eq summed 2020-2100 (annual interpolation)",
  gdp = "% change of GDP (vm_cesIO inco) discounted at 5%/yr, 2020-2100, vs matched theta = 0 null",
  consumption = "% change of consumption (vm_cons) discounted at 5%/yr, 2020-2100, vs matched null"))
for (res in c("EU21", "H12")) {
  phi <- art$phi[art$phi$resolution == res & art$phi$scenario == R$scenario[R$resolution == res & R$key == "PkBudg1000-PFMratio"], ]
  out[[res]] <- lapply(contrasts, function(k) {
    e1 <- integrate(series(res, k[1], "vm_co2eq")); e0 <- integrate(series(res, k[2], "vm_co2eq"))
    m <- merge(e1, e0, by = "region"); m$d <- C2C * (m$total.x - m$total.y); m$base <- C2C * m$total.y
    g1 <- integrate(series(res, k[1], "vm_cesIO", "inco"), DISC); g0 <- integrate(series(res, k[2], "vm_cesIO", "inco"), DISC)
    c1 <- integrate(series(res, k[1], "vm_cons"), DISC); c0 <- integrate(series(res, k[2], "vm_cons"), DISC)
    gm <- merge(g1, g0, by = "region"); cm <- merge(c1, c0, by = "region")
    m$phi <- phi$phi[match(m$region, phi$region)]
    rho <- suppressWarnings(stats::cor(m$phi, m$d / abs(m$base), method = "spearman"))
    list(globalDeltaEmissions = round(sum(m$d), 1),
         grossRelocated = round(sum(abs(m$d)) / 2, 1),
         regionsEmittingMore = sum(m$d > 0.5), regionsEmittingLess = sum(m$d < -0.5),
         spearmanPhiVsRelativeChange = round(rho, 3),
         gdpChangePct = round(100 * (sum(gm$total.x) / sum(gm$total.y) - 1), 3),
         consumptionChangePct = round(100 * (sum(cm$total.x) / sum(cm$total.y) - 1), 3),
         byRegion = lapply(order(m$d), function(i) list(region = m$region[i], phi = round(m$phi[i], 3),
           deltaGtCO2eq = round(m$d[i], 1), relative = round(m$d[i] / abs(m$base[i]), 3),
           gdpChangePct = round(100 * (gm$total.x[gm$region == m$region[i]] / gm$total.y[gm$region == m$region[i]] - 1), 3)))) })
}
o <- file.path("output/pfm", GROUP, "coupling", "coupled-costs.json")
write(toJSON(out, auto_unbox = TRUE, pretty = TRUE, digits = NA), o)
for (res in c("EU21", "H12")) for (k in names(contrasts)) { x <- out[[res]][[k]]
  cat(sprintf("%-4s %-11s global dCO2eq %+7.1f  relocated %6.1f  more/less %2d/%2d  rho(phi, rel) %+.2f  GDP %+.3f%%  cons %+.3f%%\n",
              res, k, x$globalDeltaEmissions, x$grossRelocated, x$regionsEmittingMore, x$regionsEmittingLess,
              x$spearmanPhiVsRelativeChange, x$gdpChangePct, x$consumptionChangePct)) }
message("wrote ", o)
