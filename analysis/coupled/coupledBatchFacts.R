# Every coupled-batch quantity the governed documents quote, for one Run-Group.
#   Rscript analysis/coupled/coupledBatchFacts.R v5 [gdx]
# Reads output/pfm/<group>/coupling/coupled-runs.rds (analysis/coupled/extractCoupledResults.R) plus the few
# gdx symbols that artifact does not carry (the anchor path and the infeasibility code), and writes
# output/pfm/<group>/coupling/coupled-facts.json. SCENARIOS.md sections 3-6 and claims C6, C19-C24,
# C32-C34 re-read their numbers from here.
suppressMessages(library(jsonlite))
a <- commandArgs(trailingOnly = TRUE)
GROUP  <- if (length(a) >= 1) a[1] else "v5"
GDXDIR <- if (length(a) >= 2) a[2] else "output/remind-runs/v5"
ex <- new.env(); sys.source("analysis/coupled/extractCoupledResults.R", envir = ex)
bin <- ex$gdxdumpBin()
art <- readRDS(file.path("output/pfm", GROUP, "coupling", "coupled-runs.rds"))
# Superseded re-runs stay in art$runs, flagged; prices/phi/convergence already hold only the kept run. Without
# this filter run() returns every directory of a re-run scenario and each fact becomes a vector (2026-09-23:
# EU21 -PFMlevelC has three). No batch before RULECFIX had a duplicate, so no earlier fact was affected.
R <- art$runs[!art$runs$superseded, ]; P <- art$prices; PHI <- art$phi; CV <- art$convergence
R$key <- sub("^SSP2-(EU21-)?", "", R$scenario)
rd <- function(x, d = 3) if (is.numeric(x)) round(x, d) else x
RES <- c("EU21", "H12")
run <- function(res, key) { x <- R[R$resolution == res & R$key == key, , drop = FALSE]
  if (nrow(x) > 1) stop("more than one live run for ", res, " ", key); x }
cum <- function(res, key) run(res, key)$cum2100
gdxOf <- function(res, key) file.path(GDXDIR, res, run(res, key)$dir, "fulldata.gdx")
anchor2050 <- function(res, key) {
  d <- ex$readSymbol(gdxOf(res, key), "p45_taxCO2eq_anchor", bin)
  if (is.null(d)) return(NA_real_)
  v <- as.numeric(d[[ncol(d)]]); y <- suppressWarnings(as.integer(d[[1]]))
  v[match(2050, y)] * 272
}
scalar <- function(res, key, s) ex$readScalar(gdxOf(res, key), s, bin)
F <- list(group = GROUP, generated = format(Sys.time()), source = art$source)

## ---- QC ------------------------------------------------------------------------------------------
lastDelta <- tapply(seq_len(nrow(CV)), CV$dir, function(i) { x <- CV[i, ]; x$delta[which.max(x$step)] })
R$finalDelta <- as.numeric(lastDelta[R$dir])
R$infesCode <- NA_real_
for (i in which(R$regiDiff == 11)) R$infesCode[i] <- scalar(R$resolution[i], R$key[i], "pm_pfmInfesCode")
F$qc <- list(
  nRuns = nrow(R), allFinished = all(R$finished), admittedUnfinished = art$admittedUnfinished,
  modelstat = as.list(table(R$modelstat)),
  earlySurplusMaxWorst = rd(max(R$earlySurplusMax, na.rm = TRUE)),
  earlySurplusWorstRun = R$scenario[which.max(R$earlySurplusMax)],
  earlyCellsOver = sum(R$earlySurplusOver, na.rm = TRUE),
  iterationCap = R[R$iterations >= 100, c("resolution", "key")],
  pfmCallsRange = rd(range(R$pfmCalls[R$regiDiff == 11 & R$theta > 0], na.rm = TRUE)),
  finalDeltaRange = signif(range(R$finalDelta, na.rm = TRUE), 3),
  markupMismatch = R[is.finite(R$markupWritten) & abs(R$markupWritten - R$markupSeen) > 1e-3,
                     c("resolution", "key", "markupWritten", "markupSeen")],
  infesCodes = R[is.finite(R$infesCode) & R$infesCode != 0, c("resolution", "key", "infesCode")],
  budgetWarn = R[is.finite(R$budgetWarn) & R$budgetWarn != 0, c("resolution", "key", "budgetWarnDev")],
  neverPeak = R[R$adj == 9 & is.finite(R$peakYear) & R$peakYear >= 2150, c("resolution", "key", "peak", "peakYear")],
  floorSwitch = unique(R$floorSwitch))
F$runs <- lapply(split(R, R$resolution), function(x) {
  x <- x[order(x$key), ]
  lapply(seq_len(nrow(x)), function(i) list(scenario = x$key[i], iterations = x$iterations[i],
    pfmCalls = x$pfmCalls[i], finalDelta = signif(x$finalDelta[i], 3), cum2100 = rd(x$cum2100[i], 1),
    earlySurplusMax = rd(x$earlySurplusMax[i], 2), lateSurplusOver = x$lateSurplusOver[i],
    bindShare = rd(x$bindShare[i], 3), infesCode = x$infesCode[i], budgetWarnDev = rd(x$budgetWarnDev[i], 2),
    markupWritten = rd(x$markupWritten[i], 3), phiMktSpread = rd(x$phiMktSpread[i], 3))) })

## ---- interface gate ----------------------------------------------------------------------------------
F$gate <- lapply(stats::setNames(RES, RES), function(res) {
  g <- P[P$resolution == res & P$scenario == run(res, "PkBudg1000-PFMgate")$scenario, ]
  r <- P[P$resolution == res & P$scenario == run(res, "PkBudg1000-PFMgateRef")$scenario, ]
  m <- merge(g, r, by = c("year", "region")); d <- abs(m$taxCO2eq.x - m$taxCO2eq.y)
  list(cells = nrow(m), differing = sum(d > 1e-6), maxDiff = rd(max(d), 4), meanDiff = rd(mean(d), 4),
       cumGate = rd(cum(res, "PkBudg1000-PFMgate"), 2), cumGateRef = rd(cum(res, "PkBudg1000-PFMgateRef"), 2),
       itersGate = run(res, "PkBudg1000-PFMgate")$iterations, itersGateRef = run(res, "PkBudg1000-PFMgateRef")$iterations,
       ratioSpreadAtGate = rd(run(res, "PkBudg1000-PFMgate")$phiMktSpread, 4)) })

## ---- mode R -------------------------------------------------------------------------------------------
modeR <- c(gate = "PkBudg1000-PFMgate", Th325 = "PkBudg1000-PFMratioTh325", ratio = "PkBudg1000-PFMratio",
           Th675 = "PkBudg1000-PFMratioTh675", GapC = "PkBudg1000-PFMratioGapC", Min = "PkBudg1000-PFMratioMin")
F$modeR <- lapply(stats::setNames(RES, RES), function(res) lapply(modeR, function(k) {
  x <- P[P$resolution == res & P$scenario == run(res, k)$scenario & P$year == 2050, ]
  an <- anchor2050(res, k); rt <- x$taxCO2eq / an; es_ets <- x$es / x$ets
  list(cum2100 = rd(cum(res, k), 1), anchor2050 = rd(an, 2), regionalSpread = rd(max(rt) / min(rt), 3),
       floorOverAnchorRange = rd(range(rt), 3),
       esEtsRange = rd(range(es_ets), 3), esEtsMedian = rd(stats::median(es_ets), 3),
       esBelowEts = sum(es_ets < 1 - 1e-3), esAboveEts = sum(es_ets > 1 + 1e-3), nRegions = nrow(x),
       maxMarketOverAnchor = rd(max(pmax(x$es, x$ets)) / an, 3),
       anchorOverGate = rd(an / anchor2050(res, "PkBudg1000-PFMgate"), 3),
       maxMarketOverGateAnchor = rd(max(pmax(x$es, x$ets)) / anchor2050(res, "PkBudg1000-PFMgate"), 3),
       minMarketOverGateAnchor = rd(min(pmin(x$es, x$ets)) / anchor2050(res, "PkBudg1000-PFMgate"), 3),
       peak = rd(run(res, k)$peak, 1), peakYear = run(res, k)$peakYear, iterations = run(res, k)$iterations,
       esMin = rd(x$region[which.min(es_ets)]), esMax = rd(x$region[which.max(es_ets)])) }))
F$modeRExamples <- lapply(stats::setNames(RES, RES), function(res) {
  x <- P[P$resolution == res & P$scenario == run(res, "PkBudg1000-PFMratio")$scenario & P$year == 2050, ]
  x <- x[order(x$es / x$ets), ]
  lapply(seq_len(nrow(x)), function(i) list(region = x$region[i], es = rd(x$es[i], 1), ets = rd(x$ets[i], 1),
                                            ratio = rd(x$es[i] / x$ets[i], 3))) })

## ---- mode L rule B, theta, gap closure, markup ------------------------------------------------------------
F$headlineB <- lapply(stats::setNames(RES, RES), function(res) {
  g <- cum(res, "PkBudg1000-PFMgateB")
  d <- function(k) rd(cum(res, k) - g, 1)
  x <- P[P$resolution == res & P$scenario == run(res, "PkBudg1000-PFMlevelB")$scenario & P$year == 2050, ]
  th <- c(0, 0.325, 0.5, 0.675); dv <- c(0, cum(res, "PkBudg1000-PFMlevelBTh325") - g,
                                           cum(res, "PkBudg1000-PFMlevelB") - g, cum(res, "PkBudg1000-PFMlevelBTh675") - g)
  sl <- stats::coef(stats::lm(dv ~ th))[2]
  min_ <- cum(res, "PkBudg1000-PFMlevelBMin") - g
  list(gateB = rd(g, 1), levelB = rd(cum(res, "PkBudg1000-PFMlevelB"), 1), delta = d("PkBudg1000-PFMlevelB"),
       deltaTh325 = d("PkBudg1000-PFMlevelBTh325"), deltaTh675 = d("PkBudg1000-PFMlevelBTh675"),
       slopePerUnitTheta = rd(unname(sl), 0), deltaGapC = d("PkBudg1000-PFMlevelBGapC"),
       deltaMin = rd(min_, 1), markupBuysBack = rd(min_ - (cum(res, "PkBudg1000-PFMlevelB") - g), 1),
       markupBuysBackShare = rd((min_ - (cum(res, "PkBudg1000-PFMlevelB") - g)) / min_, 3),
       bindShare = rd(run(res, "PkBudg1000-PFMlevelB")$bindShare, 3),
       market2050Range = rd(range(c(x$es, x$ets)), 1),
       gapCDirection = if (cum(res, "PkBudg1000-PFMlevelBGapC") > cum(res, "PkBudg1000-PFMlevelB")) "lambda=0 lowers the cost" else "lambda=0 raises the cost") })
## ---- headline VARIANTS: -PFMlevelBfix-<suffix> rows run on another Run-Group (pfmGroup column) ----
## GP-14 (v5-specalt, v5-noinc), GP-3(b) (v5-usadonor, v5-usalow), GP-10(b) (v5-allmedian,
## v5-alllow). Each is the deployed headline run with ONLY the Run-Group changed, so it is measured
## against the same zero-severity null, -PFMgateBfix (phi = 1 at theta = 0, whatever the group).
## Picked up automatically from the titles, so a new variant needs no code.
F$headlineVariants <- lapply(stats::setNames(RES, RES), function(res) {
  ks <- R$key[R$resolution == res & grepl("^PkBudg1000-PFMlevelBfix-[A-Za-z0-9]+$", R$key)]
  g <- cum(res, "PkBudg1000-PFMgateBfix"); base <- cum(res, "PkBudg1000-PFMlevelBfix")
  lapply(stats::setNames(ks, sub("^PkBudg1000-PFMlevelBfix-", "", ks)), function(k) {
    x <- run(res, k)
    list(cum2100 = rd(x$cum2100, 1), delta = rd(x$cum2100 - g, 1),
         deltaVsDeployed = rd(x$cum2100 - base, 1), iterations = x$iterations,
         finished = isTRUE(x$finished))
  })
})

## ---- the QUANTITY headline: rule B on the pinned budget-consistent path (TODO 14g) ----------------
## -PFMlevelBfix against -PFMgateBfix. Both read the anchor of this resolution's -PFMgate from its
## gdx (cm_pfmAnchorFromGdx = on) with budget forcing off, so the cap is measured against the price
## path that MEETS the budget rather than the unforced $75 path headlineB uses.
F$headlineQuantity <- lapply(stats::setNames(RES, RES), function(res) {
  g <- cum(res, "PkBudg1000-PFMgateBfix")
  d <- function(k) rd(cum(res, k) - g, 1)
  th <- c(0, 0.325, 0.5, 0.675); dv <- c(0, cum(res, "PkBudg1000-PFMlevelBfixTh325") - g,
                                            cum(res, "PkBudg1000-PFMlevelBfix") - g,
                                            cum(res, "PkBudg1000-PFMlevelBfixTh675") - g)
  sl <- stats::coef(stats::lm(dv ~ th))[2]
  min_ <- cum(res, "PkBudg1000-PFMlevelBfixMin") - g
  lvl <- cum(res, "PkBudg1000-PFMlevelBfix") - g
  # The pinning gate: -PFMgateBfix must reproduce -PFMgate. The residual is what dropping budget
  # forcing costs on an anchor that is no longer rescaled, not a coupling effect.
  gate <- cum(res, "PkBudg1000-PFMgate")
  list(gateBfix = rd(g, 1), levelBfix = rd(cum(res, "PkBudg1000-PFMlevelBfix"), 1), delta = d("PkBudg1000-PFMlevelBfix"),
       deltaTh325 = d("PkBudg1000-PFMlevelBfixTh325"), deltaTh675 = d("PkBudg1000-PFMlevelBfixTh675"),
       slopePerUnitTheta = rd(unname(sl), 0), deltaGapC = d("PkBudg1000-PFMlevelBfixGapC"),
       deltaMin = rd(min_, 1), markupBuysBack = rd(min_ - lvl, 1),
       markupBuysBackShare = rd((min_ - lvl) / min_, 3),
       deltaRatioBfix = d("PkBudg1000-PFMratioBfix"),
       conversionEffect = rd((cum(res, "PkBudg1000-PFMratioBfix") - g) - lvl, 1),
       bindShare = rd(run(res, "PkBudg1000-PFMlevelBfix")$bindShare, 3),
       pinning = list(gate = rd(gate, 1), gateBfix = rd(g, 1), residual = rd(g - gate, 1),
                      residualPct = rd(100 * (g - gate) / gate, 2),
                      anchor2050gate = rd(anchor2050(res, "PkBudg1000-PFMgate"), 2),
                      anchor2050gateBfix = rd(anchor2050(res, "PkBudg1000-PFMgateBfix"), 2),
                      peakGate = rd(run(res, "PkBudg1000-PFMgate")$peak, 1),
                      peakGateBfix = rd(run(res, "PkBudg1000-PFMgateBfix")$peak, 1))) })

F$gapClosureModeR <- lapply(stats::setNames(RES, RES), function(res) list(
  spreadLambda0 = F$modeR[[res]]$ratio$regionalSpread, spreadGapC = F$modeR[[res]]$GapC$regionalSpread,
  markupLambda0 = rd(run(res, "PkBudg1000-PFMratio")$markupWritten, 3),
  markupGapC = rd(run(res, "PkBudg1000-PFMratioGapC")$markupWritten, 3)))

## ---- rule C ----------------------------------------------------------------------------------------------
F$ruleC <- lapply(stats::setNames(RES, RES), function(res) lapply(
  c(levelC = "PkBudg1000-PFMlevelC", Min = "PkBudg1000-PFMlevelCMin", GapC = "PkBudg1000-PFMlevelCGapC",
    # the severity arms: a result since the cap is rebuilt every iteration (cm_pfmBoundRebuild = 1,
    # RULECFIX 2026-09-22); before that they were the frozen-cap diagnostic of SI S18
    Th325 = "PkBudg1000-PFMlevelCTh325", Th675 = "PkBudg1000-PFMlevelCTh675"),
  function(k) { x <- run(res, k)
    # nashIter, not cm_iteration_max: the latter reads 100 for any run that did not converge (PITFALLS 25b)
    list(iterations = x$nashIter, finished = isTRUE(x$finished), theta = x$theta, cum2100 = rd(x$cum2100, 1), overBudget = rd(x$cum2100 - 1000, 1),
         peak = rd(x$peak, 1), peakYear = x$peakYear, bindShare = rd(x$bindShare, 3),
         infesCode = x$infesCode, budgetWarnDev = rd(x$budgetWarnDev, 2),
         finalDelta = signif(x$finalDelta, 3),
         # The level-cap closure's own anchor rise, reported beside the ratio mode's (referee v08,
         # M3: the two held-budget closures are different mechanisms and only one was reported).
         anchorOverGate = rd(anchor2050(res, k) / anchor2050(res, "PkBudg1000-PFMgate"), 3)) }))

## ---- mode M and the NPi twins ----------------------------------------------------------------------------
F$modeM <- lapply(stats::setNames(RES, RES), function(res) list(
  mildProg = rd(cum(res, "PkBudg1000-PFMmildProg"), 1),
  deltaVsGateB = rd(cum(res, "PkBudg1000-PFMmildProg") - cum(res, "PkBudg1000-PFMgateB"), 1),
  gapToLevelB = rd(cum(res, "PkBudg1000-PFMmildProg") - cum(res, "PkBudg1000-PFMlevelB"), 1),
  gapShareOfLevelB = rd((cum(res, "PkBudg1000-PFMmildProg") - cum(res, "PkBudg1000-PFMlevelB")) / cum(res, "PkBudg1000-PFMlevelB"), 3),
  gapCIdentical = isTRUE(all.equal(cum(res, "PkBudg1000-PFMmildProg"), cum(res, "PkBudg1000-PFMmildProgGapC")))))
F$npiTwins <- lapply(stats::setNames(RES, RES), function(res) {
  g <- cum(res, "NPi2025-PFMgate")
  list(npi = rd(cum(res, "NPi2025"), 1), npiGate = rd(g, 1), regiDiffEffect = rd(g - cum(res, "NPi2025"), 1),
       ratio = rd(cum(res, "NPi2025-PFMratio") - g, 1), level = rd(cum(res, "NPi2025-PFMlevel") - g, 1),
       mildProg = rd(cum(res, "NPi2025-PFMmildProg") - g, 1)) })
F$npiPrice2050 <- lapply(stats::setNames(RES, RES), function(res) {
  x <- P[P$resolution == res & P$scenario == run(res, "NPi2025")$scenario & P$year == 2050, ]
  x <- x[order(-x$taxCO2eq), ]; as.list(stats::setNames(rd(x$taxCO2eq, 2), x$region)) })

## ---- phi -----------------------------------------------------------------------------------------------------
F$phi <- lapply(stats::setNames(RES, RES), function(res) {
  ph <- merge(PHI[PHI$resolution == res, ], R[, c("scenario", "theta", "sectorMarkup", "key")], by = "scenario")
  ref <- ph[ph$key == "PkBudg1000-PFMlevelB", ]
  c05 <- ph[abs(ph$theta - 0.5) < 1e-9, ]
  mov <- tapply(c05$phi, c05$region, function(v) max(v) - min(v))
  mov2 <- { x <- c05[!grepl("GapC", c05$key), ]; tapply(x$phi, x$region, function(v) max(v) - min(v)) }
  mk <- ph[abs(ph$theta - 0.5) < 1e-9 & ph$sectorMarkup == 1, ]
  bind <- ifelse(mk$phiES < mk$phiETS - 1e-9, "Diffuse", ifelse(mk$phiETS < mk$phiES - 1e-9, "Bulk", "tie"))
  stab <- tapply(bind, mk$region, function(v) length(unique(v)) == 1)
  rb <- ifelse(ref$phiES < ref$phiETS - 1e-9, "Diffuse", ifelse(ref$phiETS < ref$phiES - 1e-9, "Bulk", "tie"))
  floorBy <- lapply(split(ph[ph$theta > 0, ], ph$key[ph$theta > 0]), function(x)
    sort(x$region[abs(x$phi - (1 - x$theta)) < 1e-4]))
  list(levelB = lapply(order(ref$phi), function(i) list(region = ref$region[i], phi = rd(ref$phi[i], 4),
         phiES = rd(ref$phiES[i], 4), phiETS = rd(ref$phiETS[i], 4), binds = rb[i])),
       medianPhi = rd(stats::median(ref$phi), 3),
       floorRegions = sort(ref$region[abs(ref$phi - 0.5) < 1e-4]),
       floorByRun = floorBy, top = ref$region[which.max(ref$phi)], topPhi = rd(max(ref$phi), 4),
       nDiffuse = sum(rb == "Diffuse"), nBulk = sum(rb == "Bulk"), nTie = sum(rb == "tie"),
       bulkRegions = sort(ref$region[rb == "Bulk"]),
       bindStableAcrossRuns = sum(stab), nRegions = length(stab), nMarkupRuns = length(unique(mk$scenario)),
       maxMovementTheta05 = rd(max(mov), 4), maxMovementRegion = names(mov)[which.max(mov)],
       maxMovementNoGapC = rd(max(mov2), 4), maxMovementNoGapCRegion = names(mov2)[which.max(mov2)],
       nRunsTheta05 = length(unique(c05$scenario)),
       budgetFamily = { x <- c05[grepl("^PkBudg", c05$key), ]; m <- tapply(x$phi, x$region, function(v) max(v) - min(v))
         list(runs = length(unique(x$key)), maxMove = rd(max(m), 4), maxRegion = names(m)[which.max(m)], medianMove = rd(stats::median(m), 4)) },
       levelBvsNPiLevel = { u <- merge(ph[ph$key == "PkBudg1000-PFMlevelB", c("region", "phi")], ph[ph$key == "NPi2025-PFMlevel", c("region", "phi")], by = "region")
         dd <- abs(u$phi.x - u$phi.y); list(maxAbs = rd(max(dd), 4), region = u$region[which.max(dd)], medianAbs = rd(stats::median(dd), 4)) }) })

## ---- policy world ------------------------------------------------------------------------------------------
F$belowReference <- lapply(stats::setNames(RES, RES), function(res) {
  ref <- P[P$resolution == res & P$scenario == run(res, "NPi2025")$scenario, c("year", "region", "taxCO2eq")]
  out <- lapply(c(adj0 = 0, adj9 = 9), function(ad) {
    ks <- R$scenario[R$resolution == res & R$adj == ad & R$theta > 0 & grepl("PkBudg1000-PFM", R$key)]
    x <- merge(P[P$resolution == res & P$scenario %in% ks & P$year >= 2030 & P$year <= 2100, ], ref, by = c("year", "region"))
    below <- pmax(x$es, x$ets) < x$taxCO2eq.y - 0.01
    list(runs = length(ks), regionYears = nrow(x), belowReference = sum(below)) })
  out })

o <- file.path("output/pfm", GROUP, "coupling", "coupled-facts.json")
write(toJSON(F, auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null", dataframe = "rows"), o)
message("[coupledBatchFacts] wrote ", o)
