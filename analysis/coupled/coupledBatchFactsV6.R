# Every coupled-batch quantity of a v6 batch (design note 0005 Phase 5), for one Run-Group.
#   Rscript analysis/coupled/coupledBatchFactsV6.R v6 [runsDir]        (runsDir default output/remind-runs/<group>)
# The v6 counterpart of coupledBatchFacts.R, which stays as the v5 record: the v6 batch has other rows
# (no mode M, no GapC, no NPi twins; the -v6 suffix; institutions-held twins; option arms) and its φ is a
# PATH, read from each run's pfm-phi-history.rds (last call: φ(t), k_s(t), the options it ran with).
# Reads output/pfm/<group>/coupling/coupled-runs.rds (extractCoupledResults.R) plus the anchor path from
# each gdx; writes output/pfm/<group>/coupling/coupled-facts.json.
#
# Built for a batch that lands in parts: a run that is not there yet gives NA (null in the JSON), never an
# error, so wave 1 can be read before wave 2 exists. `missing` lists what each section looked for and did
# not find.
#
# Comparators (SCENARIOS.md 4.2a, 0005 Phase 5):
#   rule B (held price):   every -PFMlevelBfix* row against the held-price null -PFMgateBfix (cumulative CO2 2100);
#   rule C (held budget):  every -PFMlevelC* row against the theta = 0 null -PFMgate (2050 prices; the budget holds);
#   option and group arms: against the deployed row of their rule at theta 0.50 ("deltaVsDeployed").
suppressMessages(library(jsonlite))
a <- commandArgs(trailingOnly = TRUE)
GROUP  <- if (length(a) >= 1) a[1] else "v6"
RUNS   <- if (length(a) >= 2) a[2] else file.path("output/remind-runs", GROUP)
ex <- new.env(); sys.source("analysis/coupled/extractCoupledResults.R", envir = ex)
bin <- ex$gdxdumpBin()
art <- readRDS(file.path("output/pfm", GROUP, "coupling", "coupled-runs.rds"))
R <- art$runs[!art$runs$superseded, ]; P <- art$prices; CV <- art$convergence
R$key <- sub("-v6$", "", sub("^SSP2-(EU21-)?", "", R$scenario))
RES <- intersect(c("EU21", "H12"), unique(R$resolution))
rd <- function(x, d = 3) if (is.numeric(x)) round(x, d) else x
missing <- character(0)
run <- function(res, key) {
  x <- R[R$resolution == res & R$key == key, , drop = FALSE]
  if (nrow(x) > 1) stop("more than one live run for ", res, " ", key)
  if (!nrow(x)) missing <<- unique(c(missing, paste(res, key)))
  x
}
has <- function(res, key) nrow(R[R$resolution == res & R$key == key, , drop = FALSE]) == 1
val <- function(res, key, col) { x <- run(res, key); if (nrow(x)) x[[col]] else NA }
cum <- function(res, key) val(res, key, "cum2100")
runDir <- function(res, key) file.path(RUNS, res, run(res, key)$dir)
anchor2050 <- function(res, key) {
  if (!has(res, key)) return(NA_real_)
  d <- ex$readSymbol(file.path(runDir(res, key), "fulldata.gdx"), "p45_taxCO2eq_anchor", bin)
  if (is.null(d)) return(NA_real_)
  v <- as.numeric(d[[ncol(d)]]); y <- suppressWarnings(as.integer(d[[1]]))
  v[match(2050, y)] * art$tCO2Factor %||% 272
}
`%||%` <- function(a, b) if (is.null(a)) b else a
# the last PFM call of a run: phi path, k_s(t), options (NULL for an uncoupled run or theta = 0 without calls)
lastCall <- function(res, key) {
  if (!has(res, key)) return(NULL)
  f <- file.path(runDir(res, key), c("pfm-phi-history.rds", "pfm/pfm-phi-history.rds")); f <- f[file.exists(f)]
  if (!length(f)) return(NULL)
  h <- tryCatch(readRDS(f[1]), error = function(e) NULL)
  if (!length(h)) NULL else h[[length(h)]]
}
kAt <- function(e, sec, y) { if (is.null(e$strength)) return(NA_real_)
  s <- e$strength; v <- s$k[s$sector == sec & s$year == y]; if (length(v)) rd(v, 3) else NA_real_ }
floorPath <- function(e, y) {   # the floor share (min over sectors) per region in year y
  if (is.null(e$phiPath)) return(NULL)
  p <- e$phiPath[e$phiPath$year == y, ]; tapply(p$phi, p$region, min)
}
price2050 <- function(res, key) {   # the higher of the two market prices per region, 2050
  if (!has(res, key)) return(NULL)
  x <- P[P$resolution == res & P$scenario == run(res, key)$scenario & P$year == 2050, ]
  stats::setNames(pmax(x$es, x$ets), x$region)
}
lastDelta <- if (nrow(CV)) tapply(seq_len(nrow(CV)), CV$dir, function(i) { x <- CV[i, ]; x$delta[which.max(x$step)] }) else numeric(0)
R$finalDelta <- as.numeric(lastDelta[R$dir])
R$infesCode <- NA_real_
for (i in which(R$regiDiff == 11)) R$infesCode[i] <- ex$readScalar(file.path(RUNS, R$resolution[i], R$dir[i], "fulldata.gdx"), "pm_pfmInfesCode", bin)

F <- list(group = GROUP, generated = format(Sys.time()), source = art$source, formulation = "v6 (share path)")

## ---- QC: what the admission stage reads ----------------------------------------------------------
F$qc <- list(
  nRuns = nrow(R), byResolution = as.list(table(R$resolution)), allFinished = all(R$finished),
  admittedUnfinished = art$admittedUnfinished, modelstat = as.list(table(R$modelstat)),
  earlySurplusMaxWorst = rd(max(R$earlySurplusMax, na.rm = TRUE)),
  earlySurplusWorstRun = R$scenario[which.max(R$earlySurplusMax)],
  earlyCellsOver = sum(R$earlySurplusOver, na.rm = TRUE),
  iterationCap = R[R$iterations >= 100, c("resolution", "key")],
  pfmCallsRange = rd(range(R$pfmCalls[R$regiDiff == 11 & R$theta > 0], na.rm = TRUE)),
  finalDeltaRange = signif(range(R$finalDelta, na.rm = TRUE), 3),
  infesCodes = R[is.finite(R$infesCode) & R$infesCode != 0, c("resolution", "key", "infesCode")],
  budgetWarn = R[is.finite(R$budgetWarn) & R$budgetWarn != 0, c("resolution", "key", "budgetWarnDev")],
  # E11: a BUDGET-FORCED run (adj 9) that never peaks is to be disclosed; held-price runs never peak by design
  neverPeakBudgetForced = R[R$adj == 9 & is.finite(R$peakYear) & R$peakYear >= 2150, c("resolution", "key", "peak", "peakYear")],
  markupMismatch = R[is.finite(R$markupWritten) & abs(R$markupWritten - R$markupSeen) > 1e-3,
                     c("resolution", "key", "markupWritten", "markupSeen")])

## ---- every run: one line each, with k and the 2050 floor path from its last call -------------------
F$runs <- lapply(stats::setNames(RES, RES), function(res) {
  x <- R[R$resolution == res, ]; x <- x[order(x$key), ]
  lapply(seq_len(nrow(x)), function(i) {
    e <- lastCall(res, x$key[i]); fp <- floorPath(e, 2050)
    list(scenario = x$key[i], finished = x$finished[i], theta = x$theta[i], bindMode = x$bindMode[i],
         adj = x$adj[i], iterations = x$iterations[i], pfmCalls = x$pfmCalls[i],
         finalDelta = signif(x$finalDelta[i], 3), cum2100 = rd(x$cum2100[i], 1), peak = rd(x$peak[i], 1),
         peakYear = x$peakYear[i], earlySurplusMax = rd(x$earlySurplusMax[i], 2), bindShare = rd(x$bindShare[i], 3),
         infesCode = x$infesCode[i], budgetWarnDev = rd(x$budgetWarnDev[i], 2),
         formulation = e$formulation %||% NA, options = e$options %||% NULL,
         kBulk2050 = kAt(e, "Bulk", 2050), kBulk2100 = kAt(e, "Bulk", 2100),
         kDiffuse2050 = kAt(e, "Diffuse", 2050), kDiffuse2100 = kAt(e, "Diffuse", 2100),
         floor2050Median = if (length(fp)) rd(stats::median(fp), 3) else NA,
         floor2050Min = if (length(fp)) rd(min(fp), 3) else NA)
  }) })

## ---- the theta = 0 null and the pinning (Phase 3 gate criteria, per resolution) -------------------
F$gate <- lapply(stats::setNames(RES, RES), function(res) {
  out <- list(cumGate = rd(cum(res, "PkBudg1000-PFMgate"), 2), cumGateRef = rd(cum(res, "PkBudg1000-PFMgateRef"), 2))
  if (has(res, "PkBudg1000-PFMgate") && has(res, "PkBudg1000-PFMgateRef")) {
    g <- P[P$resolution == res & P$scenario == run(res, "PkBudg1000-PFMgate")$scenario & P$year >= 2030 & P$year <= 2100, ]
    r <- P[P$resolution == res & P$scenario == run(res, "PkBudg1000-PFMgateRef")$scenario & P$year >= 2030 & P$year <= 2100, ]
    m <- merge(g, r, by = c("year", "region")); d <- abs(m$taxCO2eq.x - m$taxCO2eq.y)
    out <- c(out, list(cells = nrow(m), differing = sum(d > 1e-6), maxDiff = rd(max(d), 4),
                       passes = max(d) < 1 && abs(cum(res, "PkBudg1000-PFMgate") - cum(res, "PkBudg1000-PFMgateRef")) < 0.2))
  }
  gb <- cum(res, "PkBudg1000-PFMgateBfix"); gt <- cum(res, "PkBudg1000-PFMgate")
  c(out, list(pinning = list(gate = rd(gt, 1), gateBfix = rd(gb, 1), residual = rd(gb - gt, 1),
                             residualPct = rd(100 * (gb - gt) / gt, 2), passes = isTRUE(abs(gb - gt) < 5),
                             anchor2050gate = rd(anchor2050(res, "PkBudg1000-PFMgate"), 2),
                             anchor2050gateBfix = rd(anchor2050(res, "PkBudg1000-PFMgateBfix"), 2))))
})

## ---- rule B, the quantity headline: theta sweep and the institutions-held twin --------------------
F$ruleB <- lapply(stats::setNames(RES, RES), function(res) {
  g <- cum(res, "PkBudg1000-PFMgateBfix"); dep <- cum(res, "PkBudg1000-PFMlevelBfix")
  th <- c(`0.325` = "PkBudg1000-PFMlevelBfixTh325", `0.50` = "PkBudg1000-PFMlevelBfix", `0.675` = "PkBudg1000-PFMlevelBfixTh675")
  dv <- vapply(th, function(k) cum(res, k) - g, 1)
  ok <- is.finite(dv)
  slope <- if (sum(ok) >= 2 && is.finite(g)) unname(stats::coef(stats::lm(c(0, dv[ok]) ~ c(0, as.numeric(names(dv)[ok]))))[2]) else NA
  held <- cum(res, "PkBudg1000-PFMlevelBfix-held")
  e <- lastCall(res, "PkBudg1000-PFMlevelBfix"); eh <- lastCall(res, "PkBudg1000-PFMlevelBfix-held")
  list(gateBfix = rd(g, 1), levelBfix = rd(dep, 1),
       delta = as.list(rd(dv, 1)), slopePerUnitTheta = rd(slope, 0),
       bindShare = rd(val(res, "PkBudg1000-PFMlevelBfix", "bindShare"), 3),
       k = list(Bulk2050 = kAt(e, "Bulk", 2050), Bulk2100 = kAt(e, "Bulk", 2100),
                Diffuse2050 = kAt(e, "Diffuse", 2050), Diffuse2100 = kAt(e, "Diffuse", 2100)),
       # decision 1A of 0005 section 7a: the headline always travels with its institutions-held twin
       held = list(cum2100 = rd(held, 1), delta = rd(held - g, 1), heldMinusDeployed = rd(held - dep, 1),
                   institutionsShareOfDelta = rd((dep - held) / (dep - g), 3),
                   kBulk2100 = kAt(eh, "Bulk", 2100), kDiffuse2100 = kAt(eh, "Diffuse", 2100)),
       markupOff = { m <- cum(res, "PkBudg1000-PFMlevelBfixMin")
         list(cum2100 = rd(m, 1), delta = rd(m - g, 1), markupBuysBack = rd(m - dep, 1),
              markupBuysBackShare = rd((m - dep) / (m - g), 3)) })
})

## ---- rule C, the held budget: where the price moves -----------------------------------------------
F$ruleC <- lapply(stats::setNames(RES, RES), function(res) {
  pg <- price2050(res, "PkBudg1000-PFMgate"); ag <- anchor2050(res, "PkBudg1000-PFMgate")
  keys <- c(`0.50` = "PkBudg1000-PFMlevelC", `0.325` = "PkBudg1000-PFMlevelCTh325", `0.675` = "PkBudg1000-PFMlevelCTh675",
            held = "PkBudg1000-PFMlevelC-held", markupOff = "PkBudg1000-PFMlevelCMin", ratio = "PkBudg1000-PFMratio")
  lapply(keys, function(k) {
    if (!has(res, k)) { run(res, k); return(NULL) }
    x <- run(res, k); p <- price2050(res, k); e <- lastCall(res, k)
    rel <- if (length(pg) && length(p)) p[names(pg)] / pg else NULL
    list(finished = isTRUE(x$finished), iterations = x$iterations, theta = x$theta, cum2100 = rd(x$cum2100, 1),
         overBudget = rd(x$cum2100 - 1000, 1), peak = rd(x$peak, 1), peakYear = x$peakYear,
         bindShare = rd(x$bindShare, 3), infesCode = x$infesCode, finalDelta = signif(x$finalDelta, 3),
         anchorOverGate = rd(anchor2050(res, k) / ag, 3),
         price2050OverGate = if (length(rel)) list(median = rd(stats::median(rel), 3), min = rd(min(rel), 3),
                                                    max = rd(max(rel), 3), minRegion = names(rel)[which.min(rel)],
                                                    maxRegion = names(rel)[which.max(rel)]) else NULL,
         kBulk2050 = kAt(e, "Bulk", 2050), kBulk2100 = kAt(e, "Bulk", 2100),
         kDiffuse2050 = kAt(e, "Diffuse", 2050), kDiffuse2100 = kAt(e, "Diffuse", 2100))
  })
})

## ---- the arms: every -PFMlevel(Bfix|C)-<suffix> row (ordering, assignment, shape, family B, formulation) --
## Picked up from the titles, so a new arm needs no code. Each carries the options and group its last call
## ran with, so an option that silently did not reach the coupling shows up here (0005 F8).
F$arms <- lapply(stats::setNames(RES, RES), function(res) {
  ks <- R$key[R$resolution == res & grepl("^PkBudg1000-PFMlevel(Bfix|C)-[A-Za-z0-9]+$", R$key)]
  ks <- setdiff(ks, c("PkBudg1000-PFMlevelBfix-held", "PkBudg1000-PFMlevelC-held"))
  g <- cum(res, "PkBudg1000-PFMgateBfix"); pg <- price2050(res, "PkBudg1000-PFMgate")
  lapply(stats::setNames(ks, sub("^PkBudg1000-PFMlevel", "", ks)), function(k) {
    x <- run(res, k); ruleB <- grepl("^PkBudg1000-PFMlevelBfix-", k)
    dep <- if (ruleB) "PkBudg1000-PFMlevelBfix" else "PkBudg1000-PFMlevelC"
    e <- lastCall(res, k); p <- price2050(res, k)
    grp <- tryCatch(yaml::read_yaml(file.path(runDir(res, k), "pfm-coupling.yml"))$group, error = function(e) NA)
    c(list(rule = if (ruleB) "B" else "C", group = grp %||% NA, options = e$options %||% NULL,
           finished = isTRUE(x$finished), iterations = x$iterations, cum2100 = rd(x$cum2100, 1),
           deltaVsDeployed = rd(x$cum2100 - cum(res, dep), 1),
           kBulk2050 = kAt(e, "Bulk", 2050), kBulk2100 = kAt(e, "Bulk", 2100),
           kDiffuse2050 = kAt(e, "Diffuse", 2050), kDiffuse2100 = kAt(e, "Diffuse", 2100)),
      if (ruleB) list(delta = rd(x$cum2100 - g, 1))
      else if (length(pg) && length(p)) list(price2050OverGateMedian = rd(stats::median(p[names(pg)] / pg), 3)))
  })
})

F$missing <- sort(missing)
o <- file.path("output/pfm", GROUP, "coupling", "coupled-facts.json")
write(toJSON(F, auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null", null = "null", dataframe = "rows"), o)
message("[coupledBatchFactsV6] wrote ", o, " (", nrow(R), " runs; ", length(missing), " looked-for runs not present)")
