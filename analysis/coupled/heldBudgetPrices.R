# What does the average tonne pay when the budget is held under the ceiling? (review-v10 M1)
#
#   Rscript analysis/coupled/heldBudgetPrices.R v5 output/remind-runs/v5                          # ratio mode (-PFMratio)
#   Rscript analysis/coupled/heldBudgetPrices.R v5 output/remind-runs/v5 PkBudg1000-PFMlevelC     # the level cap under rule C (GP-22)
#
# For ratio mode the anchor is the highest 2050 market price, which is the anchor by construction (the
# least constrained market has phi = 1). Under the level cap no market need pay the anchor, so for any
# other run it is read from the run's own p45_taxCO2eq_anchor, and "phi" below is the realised price over
# that anchor - an effective share, not the coupling's phi. Output for a non-default run goes to
# held-budget-prices-<run suffix>.rds so the ratio-mode artifact the paper quotes is never overwritten.
#
# In ratio mode each market pays its own sector's feasibility share times the common anchor, so the
# anchor - which rises by about a third - is paid in full only where phi = 1. This script measures
# the REALISED prices: the 2050 price of every region-market in the held-budget run (-PFMratio)
# against the zero-severity null (-PFMgate), unweighted and weighted by that market's CO2eq
# emissions in the null (vm_co2eqMkt; ES and "other" pay the Diffuse price, ETS the Bulk price, as
# in the coupling). It also records how close the anchor rise is to 1 / (emissions-weighted phi),
# the arithmetic of keeping abatement constant when every market pays phi x anchor.

args <- commandArgs(trailingOnly = TRUE)
group <- if (length(args) >= 1) args[1] else "v5"
gdxDir <- if (length(args) >= 2) args[2] else "output/remind-runs/v5"
runKey <- if (length(args) >= 3) args[3] else "PkBudg1000-PFMratio"
isRatio <- identical(runKey, "PkBudg1000-PFMratio")
bin <- local({
  cand <- unlist(strsplit(Sys.getenv("GAMSDIR", ""), "[;:]"))
  cand <- c(Sys.getenv("GDXDUMP", ""), file.path(cand[nzchar(cand)], "gdxdump.exe"), Sys.which("gdxdump"))
  cand <- cand[nzchar(cand) & file.exists(cand)]; if (!length(cand)) stop("gdxdump not found"); cand[1]
})
sym <- function(gdx, s) {
  out <- suppressWarnings(system2(bin, c(shQuote(gdx), paste0("symb=", s), "format=csv"), stdout = TRUE, stderr = FALSE))
  utils::read.csv(text = paste(out, collapse = "\n"), stringsAsFactors = FALSE)
}

cr <- readRDS(file.path("output/pfm", group, "coupling", "coupled-runs.rds"))
R <- cr$runs[!cr$runs$superseded, ]; R$key <- sub("^SSP2-(EU21-)?", "", R$scenario)
P <- cr$prices
YEAR <- 2050

res <- list(); tabs <- list()
for (rs in c("EU21", "H12")) {
  rr <- R[R$resolution == rs & R$key == runKey, ]
  rg <- R[R$resolution == rs & R$key == "PkBudg1000-PFMgate", ]
  stopifnot(nrow(rr) == 1, nrow(rg) == 1)
  pr <- P[P$scenario == rr$scenario & P$resolution == rs & P$year == YEAR, c("region", "es", "ets")]
  pg <- P[P$scenario == rg$scenario & P$resolution == rs & P$year == YEAR, c("region", "es", "ets")]
  names(pg)[2:3] <- c("esNull", "etsNull")
  d <- merge(pr, pg, by = "region")
  em <- sym(file.path(gdxDir, rs, rg$dir, "fulldata.gdx"), "vm_co2eqMkt")
  names(em) <- c("ttot", "region", "mkt", "val")
  em <- em[em$ttot == YEAR, ]
  w <- function(m) { x <- em[em$mkt %in% m, ]; a <- stats::aggregate(val ~ region, x, sum); stats::setNames(pmax(a$val, 0), a$region) }
  wES <- w(c("ES", "other")); wETS <- w("ETS")
  d$wES <- unname(wES[d$region]); d$wETS <- unname(wETS[d$region])
  d$wES[is.na(d$wES)] <- 0; d$wETS[is.na(d$wETS)] <- 0
  gdxAnchor <- function(dir) { a <- sym(file.path(gdxDir, rs, dir, "fulldata.gdx"), "p45_taxCO2eq_anchor")
    as.numeric(a[[ncol(a)]])[match(YEAR, suppressWarnings(as.integer(a[[1]])))] * 272 }
  anchor <- if (isRatio) max(c(d$es, d$ets)) else gdxAnchor(rr$dir)
  anchorNull <- if (isRatio) max(c(d$esNull, d$etsNull)) else gdxAnchor(rg$dir)
  phiES <- d$es / anchor; phiETS <- d$ets / anchor
  wMean <- (sum(d$es * d$wES) + sum(d$ets * d$wETS)) / (sum(d$wES) + sum(d$wETS))
  wMeanNull <- (sum(d$esNull * d$wES) + sum(d$etsNull * d$wETS)) / (sum(d$wES) + sum(d$wETS))
  wPhi <- (sum(phiES * d$wES) + sum(phiETS * d$wETS)) / (sum(d$wES) + sum(d$wETS))
  res[[rs]] <- list(
    anchor = anchor, anchorNull = anchorNull, anchorRise = anchor / anchorNull,
    meanES = mean(d$es), meanETS = mean(d$ets), meanUnweighted = mean(c(d$es, d$ets)),
    meanUnweightedRise = mean(c(d$es, d$ets)) / anchorNull,
    meanWeighted = wMean, meanWeightedNull = wMeanNull, meanWeightedRise = wMean / wMeanNull,
    weightedPhi = wPhi, inverseWeightedPhi = 1 / wPhi,
    marketsAboveNull = sum(c(d$es > d$esNull + 1e-6, d$ets > d$etsNull + 1e-6)),
    marketsBelowNull = sum(c(d$es < d$esNull - 1e-6, d$ets < d$etsNull - 1e-6)), markets = 2 * nrow(d),
    minRatio = min(c(d$es / d$esNull, d$ets / d$etsNull)), maxRatio = max(c(d$es / d$esNull, d$ets / d$etsNull)))
  tabs[[rs]] <- cbind(resolution = rs, d)
  cat(sprintf("%s: anchor %.1f vs null %.1f (x%.3f) | mean realised price unweighted %.1f (x%.3f), emissions-weighted %.1f vs null %.1f (x%.3f) | 1/weighted phi %.3f | markets above/below null %d/%d of %d | ratio to null %.2f-%.2f\n",
              rs, anchor, anchorNull, anchor / anchorNull, res[[rs]]$meanUnweighted, res[[rs]]$meanUnweightedRise,
              wMean, wMeanNull, wMean / wMeanNull, 1 / wPhi, res[[rs]]$marketsAboveNull, res[[rs]]$marketsBelowNull,
              res[[rs]]$markets, res[[rs]]$minRatio, res[[rs]]$maxRatio))
}
f <- file.path("output/pfm", group, "coupling",
               if (isRatio) "held-budget-prices.rds" else paste0("held-budget-prices-", sub("^PkBudg1000-PFM", "", runKey), ".rds"))
saveRDS(list(summary = res, byRegion = do.call(rbind, tabs), year = YEAR, group = group, run = runKey,
             anchorFrom = if (isRatio) "highest 2050 market price" else "p45_taxCO2eq_anchor, 2050",
             note = paste0("held-budget run ", runKey, " vs its zero-severity null, 2050; weights = null-run vm_co2eqMkt (ES+other -> Diffuse price, ETS -> Bulk price)")), f)
cat("wrote", f, "\n")
