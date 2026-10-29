# The interface gate in detail (SCENARIOS.md 3.1): is the no-politics run's difference from the uncoupled reference one
# global path (the budget loop stopping at another iteration), or a regional pattern (the coupling acting at theta = 0)?
#   Rscript analysis/checks/gateRefCompare.R <group> [resolution]   (repo root; default H12) -> output/pfm/<group>/coupling/gate-ref-compare.rds
# Reads pm_taxCO2eq and vm_emiAll/emissions from fulldata.gdx of -PFMgate-<group> and -PFMgateRef in
# output/remind-runs/<group>/<res>/, with the gdxdump reader of analysis/coupled/extractCoupledResults.R.
a <- commandArgs(trailingOnly = TRUE); g <- a[1]; res <- if (length(a) >= 2) a[2] else "H12"
ex <- new.env(); sys.source("analysis/coupled/extractCoupledResults.R", envir = ex); bin <- ex$gdxdumpBin()
dir <- file.path("output/remind-runs", g, res)
# matched on the run key (analysis/coupled/_runKey.R), so v8's titles (-PFM-noPolitics-holdBudget) are found too
pick <- function(pat) { d <- list.files(dir); d <- d[grepl(pat, pfmRunKey(d))]
  if (length(d) != 1) stop(res, ": expected one run for ", pat, ", found ", length(d)); file.path(dir, d) }
gate <- pick(paste0("-PFMgate-", g, "_")); ref <- pick("-PFMgateRef_")
rd <- function(run, s) { d <- ex$readSymbol(file.path(run, "fulldata.gdx"), s, bin); names(d)[1:2] <- c("year", "region")
  data.frame(year = as.integer(d$year), region = d$region, v = as.numeric(d[[ncol(d)]])) }
p <- merge(rd(gate, "pm_taxCO2eq"), rd(ref, "pm_taxCO2eq"), by = c("year", "region"), suffixes = c(".gate", ".ref"))
p <- p[p$year >= 2030 & p$year <= 2100 & p$v.ref > 0, ]
p$ratio <- p$v.gate / p$v.ref
byYear <- stats::aggregate(ratio ~ year, p, function(x) c(min = min(x), max = max(x), spread = diff(range(x))))
byYear <- do.call(data.frame, byYear)
log <- function(run) { l <- readLines(file.path(run, "log.txt"), warn = FALSE); it <- grep("^ *Iteration *[0-9]+", l, value = TRUE)
  list(iterations = length(it)) }
out <- list(group = g, resolution = res, gate = basename(gate), ref = basename(ref), made = format(Sys.time(), "%Y-%m-%d %H:%M"),
            cells = nrow(p), maxAbsDiff = max(abs(p$v.gate - p$v.ref)) * 1000 * 12 / 44,
            ratioByYear = byYear, maxSpreadAcrossRegions = max(byYear$ratio.spread))
saveRDS(out, file.path("output/pfm", g, "coupling", "gate-ref-compare.rds"))
options(width = 160)
cat(res, ":", out$gate, "vs", out$ref, "|", out$cells, "cells\n")
cat("price ratio gate / ref by year (min, max over regions, spread):\n"); print(round(byYear, 5), row.names = FALSE)
cat("largest spread of the ratio across regions in any year:", signif(out$maxSpreadAcrossRegions, 3),
    if (out$maxSpreadAcrossRegions < 1e-4) "-> one global path (a uniform scaling of the price)" else "-> a regional pattern", "\n")
