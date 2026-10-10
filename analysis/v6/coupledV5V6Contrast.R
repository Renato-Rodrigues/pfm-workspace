# Design note 0005 Phase 6, step 1: the v5 -> v6 contrast of every coupled headline, per resolution.
# Read from the two Run-Groups' coupling artifacts; nothing is re-extracted from a gdx.
#   Rscript analysis/v6/coupledV5V6Contrast.R [old] [new]     (repo root; default v5 v6; after
#                                                              runCoupledStage.R on both groups)
# Each headline is a difference against the group's OWN theta = 0 null, so REMIND's drift between
# the two groups' versions (v5 3.7.0.dev29, v6 3.7.1; PITFALLS.md §34) cancels to first order. The
# nulls themselves are shown so that drift stays visible.
# Rule C's 2050 price ratio is recomputed for BOTH groups by the v6 facts rule (the higher of the two
# market prices per region, over the theta = 0 run), since v5's facts did not record it.
# Output: output/pfm/<new>/coupling/v5-v6-coupled-contrast.rds and .json, and a printed table.
`%||%` <- function(a, b) if (is.null(a)) b else a
a <- commandArgs(trailingOnly = TRUE)
OLD <- if (length(a) > 0) a[1] else "v5"; NEW <- if (length(a) > 1) a[2] else "v6"
cd <- function(g) file.path("output/pfm", g, "coupling")
fx <- lapply(c(old = OLD, new = NEW), function(g) jsonlite::fromJSON(file.path(cd(g), "coupled-facts.json")))
cs <- lapply(c(old = OLD, new = NEW), function(g) jsonlite::fromJSON(file.path(cd(g), "coupled-costs.json")))
pr <- lapply(c(old = OLD, new = NEW), function(g) readRDS(file.path(cd(g), "coupled-runs.rds"))$prices)
RES <- c("EU21", "H12")
pre <- function(res) if (res == "EU21") "SSP2-EU21-" else "SSP2-"
suf <- c(old = "", new = "-v6")   # v6 coupled titles carry -v6; the uncoupled ones do not
title <- function(w, res, key) paste0(pre(res), key, suf[[w]])

med2050 <- function(w, res, key) {   # median over regions of the 2050 price over the theta = 0 run's
  P <- pr[[w]]; p <- function(t) { x <- P[P$resolution == res & P$scenario == t & P$year == 2050, ]
                                    stats::setNames(pmax(x$es, x$ets), x$region) }
  g <- p(title(w, res, "PkBudg1000-PFMgate")); k <- p(title(w, res, key))
  if (!length(g) || !length(k)) return(NA_real_)
  round(stats::median(k[names(g)] / g), 3)
}
cost <- function(w, res, key, f) { x <- cs[[w]][[res]][[key]]; if (is.null(x)) NA_real_ else x[[f]] }

rows <- list()
add <- function(res, what, old, new, unit = "") {
  rows[[length(rows) + 1]] <<- data.frame(resolution = res, quantity = what, old = old, new = new,
                                          change = if (is.numeric(old) && is.numeric(new)) round(new - old, 3) else NA,
                                          unit = unit)
}
for (res in RES) {
  qo <- fx$old$headlineQuantity[[res]]; bn <- fx$new$ruleB[[res]]
  co <- fx$old$ruleC[[res]]; cn <- fx$new$ruleC[[res]]
  add(res, "theta = 0 null, cumulative CO2 2100 (gate)", fx$old$gate[[res]]$cumGate %||% NA, fx$new$gate[[res]]$cumGate, "Gt")
  add(res, "held-price null -PFMgateBfix, cumulative CO2 2100", qo$gateBfix, bn$gateBfix, "Gt")
  add(res, "rule B: delta, theta 0.50 (the quantity headline)", qo$delta, bn$delta[["0.50"]], "Gt")
  add(res, "rule B: delta, theta 0.325", qo$deltaTh325, bn$delta[["0.325"]], "Gt")
  add(res, "rule B: delta, theta 0.675", qo$deltaTh675, bn$delta[["0.675"]], "Gt")
  add(res, "rule B: slope per unit theta", qo$slopePerUnitTheta, bn$slopePerUnitTheta, "Gt")
  add(res, "rule B: markup off, delta", qo$deltaMin, bn$markupOff$delta, "Gt")
  add(res, "rule B: what the markup buys back", qo$markupBuysBack, bn$markupOff$markupBuysBack, "Gt")
  add(res, "rule B: bind share", qo$bindShare, bn$bindShare, "")
  for (th in c(`0.325` = "Th325", `0.50` = "", `0.675` = "Th675")) {
    k <- paste0("PkBudg1000-PFMlevelC", th); nm <- names(th)
    on <- if (th == "") "levelC" else th
    add(res, sprintf("rule C, theta %s: anchor 2050 x null", if (th == "") "0.50" else sub("Th", "0.", th)),
        co[[on]]$anchorOverGate %||% NA, cn[[if (th == "") "0.50" else sub("Th", "0.", th)]]$anchorOverGate, "x")
    add(res, sprintf("rule C, theta %s: median regional 2050 price x null", if (th == "") "0.50" else sub("Th", "0.", th)),
        med2050("old", res, k), med2050("new", res, k), "x")
  }
  add(res, "rule C: cumulative CO2 2100", co$levelC$cum2100, cn[["0.50"]]$cum2100, "Gt")
  add(res, "costs, rule B: global CO2eq 2020-2100", cost("old", res, "levelBfix", "globalDeltaEmissions"),
      cost("new", res, "levelBfix", "globalDeltaEmissions"), "Gt CO2eq")
  add(res, "costs, rule B: gross relocated", cost("old", res, "levelBfix", "grossRelocated"),
      cost("new", res, "levelBfix", "grossRelocated"), "Gt CO2eq")
  add(res, "costs, rule B: GDP", cost("old", res, "levelBfix", "gdpChangePct"), cost("new", res, "levelBfix", "gdpChangePct"), "%")
  add(res, "costs, rule C: global CO2eq 2020-2100", cost("old", res, "levelC", "globalDeltaEmissions"),
      cost("new", res, "levelC", "globalDeltaEmissions"), "Gt CO2eq")
  add(res, "costs, rule C: gross relocated", cost("old", res, "levelC", "grossRelocated"),
      cost("new", res, "levelC", "grossRelocated"), "Gt CO2eq")
  add(res, "costs, rule C: GDP", cost("old", res, "levelC", "gdpChangePct"), cost("new", res, "levelC", "gdpChangePct"), "%")
}
out <- do.call(rbind, rows)
names(out)[3:4] <- c(OLD, NEW)
res <- list(groups = c(OLD, NEW), generated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), table = out,
            note = paste("Differences against each group's own theta = 0 null; the groups run on different REMIND",
                         "versions (PITFALLS.md 34). Rule C's median 2050 ratio recomputed for both by the v6 facts rule."))
saveRDS(res, file.path(cd(NEW), "v5-v6-coupled-contrast.rds"))
jsonlite::write_json(res, file.path(cd(NEW), "v5-v6-coupled-contrast.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)
op <- options(width = 200); print(out, row.names = FALSE); options(op)
cat("wrote", file.path(cd(NEW), "v5-v6-coupled-contrast.rds"), "and .json\n")
