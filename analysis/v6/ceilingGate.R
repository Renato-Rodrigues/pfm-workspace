# Design note 0005 C9: the ceiling-fall gate re-examined on the v6 spec. Under v6 the ceiling path IS
# what moves k: a ceiling that rises shrinks the gap (k down), one that falls widens it (k up). The gate
# (ceilingCollapse, sanity walk) rejects a spec whose median covered-country ceiling on the gating
# scenario (PkBudg1000) ends below 90% of its 2025 value.
#   Rscript analysis/v6/ceilingGate.R [group]       (repo root; after phase1.R and the pfm-anchor step)
# Reports: the gate value and margin for the deployed spec; the country distribution of the ceiling
# ratio 2025 -> 2050 / 2100 on NPi and PkBudg1000, covered and all, final-energy weighted too; how the
# gate acts across the bootstrap pool. Output: output/pfm/<group>/phase1/ceiling-gate.rds.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v6" })
GD <- file.path("output/pfm", g); P1 <- file.path(GD, "phase1")
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)   # the registry's SSP2 pair (PITFALLS.md 34)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
anc <- pfmAnchorFor(GD, "EU21")
pool <- readRDS(file.path(GD, "sanity-pool.rds"))
dep <- pool$ceiling[[match(pool$deployed, pool$pool)]]

rows <- list()
for (run in c("NPi", "PkBudg1000")) {
  cp <- computeStrengthPath(anc, v6ScenPanel(P1, run, BASES[[run]]), returnCountries = TRUE)$countries
  for (sec in c("Bulk", "Diffuse")) {
    d <- cp[cp$sector == sec, ]
    base <- stats::setNames(d$ceilingIndex[d$year == 2025], d$region[d$year == 2025])
    obs <- anc$country$region[anc$country$sector == sec & anc$country$basis == "observed"]
    for (yy in c(2050, 2100)) {
      e <- d[d$year == yy, ]; r <- e$ceilingIndex / base[e$region]; names(r) <- e$region; r <- r[is.finite(r)]
      w <- anc$weights[names(r)]; w[!is.finite(w)] <- 0
      for (set in c("covered", "all")) {
        rr <- if (set == "covered") r[names(r) %in% obs] else r; ww <- w[names(rr)]
        rows[[paste(run, sec, yy, set)]] <- data.frame(run = run, sector = sec, year = yy, countries = set, n = length(rr),
          medianRatio = stats::median(rr), weightedRatio = sum(rr * ww) / sum(ww), shareFalling = mean(rr < 1),
          shareBelow0.9 = mean(rr < 0.9), p10 = unname(stats::quantile(rr, .1)), p90 = unname(stats::quantile(rr, .9)))
      }
    }
  }
}
dist <- do.call(rbind, rows); rownames(dist) <- NULL
cr <- do.call(rbind, lapply(seq_along(pool$pool), function(i) { x <- pool$ceiling[[i]]
  if (is.null(x)) return(NULL); data.frame(model = pool$pool[i], Bulk = x[1], Diffuse = x[2]) }))
cr <- merge(cr, pool$verdicts[, c("model", "pass", "severeRules")], by = "model")
cr$onlyCeiling <- cr$severeRules == "ceilingCollapse"
saveRDS(list(deployed = dep, distribution = dist, pool = cr), file.path(P1, "ceiling-gate.rds"))
options(width = 200)
cat("== deployed", pool$deployed, ": gate value (median covered S* 2100/2025, PkBudg1000) Bulk", round(dep[1], 3), "Diffuse", round(dep[2], 3), "| gate 0.90\n")
cat("\n== country distribution of the ceiling ratio vs 2025\n"); print(dist, row.names = FALSE, digits = 3)
cat("\n== the gate across the pool (", nrow(cr), "specs with a ceiling value)\n")
cat("  ratio range Bulk", paste(round(range(cr$Bulk, na.rm = TRUE), 3), collapse = "-"), "| Diffuse", paste(round(range(cr$Diffuse, na.rm = TRUE), 3), collapse = "-"), "\n")
cat("  specs below 0.90 in a sector:", sum(pmin(cr$Bulk, cr$Diffuse) < 0.9, na.rm = TRUE), "| rejected by ceilingCollapse alone:", sum(cr$onlyCeiling), "\n")
cat("  passing specs' lowest ratio:", round(min(pmin(cr$Bulk, cr$Diffuse)[cr$pass], na.rm = TRUE), 3), "\n")
