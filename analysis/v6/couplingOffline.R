# Design note 0005 Phase 3: the v6 coupling call, offline, against the Phase 1 numbers.
# Runs pfm::iterativePFM() on a Run-Group's REMIND export (it must carry phi-anchor.rds) and an existing
# REMIND gdx, as a coupled run's first call would, then checks:
#   - the share path equals pfmV6Shares() on the Phase 1 scenario panel (same energy system);
#   - the gdx carries the v6 symbols with their declared domains, over every ttot, lambda = 0.
#   Rscript analysis/v6/couplingOffline.R [group] [run]     (repo root; default v6 PkBudg1000)
# Writes into tempdir(); nothing in output/ changes.
suppressMessages({ library(magclass) })
source("analysis/_common/_loadPfm.R")
a <- commandArgs(trailingOnly = TRUE)
g <- if (length(a) > 0) a[1] else "v6"; run <- if (length(a) > 1) a[2] else "PkBudg1000"
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)   # the registry's SSP2 pair (PITFALLS.md 34)
gdxs <- BASES
madrat::setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
out <- file.path(tempdir(), "pfm-coupling-offline"); unlink(out, recursive = TRUE); dir.create(out)
ok <- iterativePFM(gdx = gdxs[[run]], outputFile = file.path(out, "p45_regiDiff_phi.gdx"), group = g,
                   resultsDir = "output/remind-inputs", modelDir = rc$modelDir %||% "output/pfm/fit-cache",
                   couplingConfig = "none.yml", runtimeConfig = "none.yml", theta = 0.5,
                   gdxRegionMapping = "regionmapping_21_EU11.csv", mapping = "regionmapping_21_EU11.csv",
                   refGdx = gdxs[["NPi"]], bindMode = 2L, weightScenario = "SSP2")
stopifnot(isTRUE(ok))
h <- readRDS(file.path(out, "pfm-phi-history.rds"))[[1]]
ref <- pfmV6Shares(pfmAnchorFor(file.path("output/remind-inputs", g), "EU21"),
                   v6ScenPanel(file.path("output/pfm", g, "phase1"), run, BASES[[run]]), theta = 0.5)
m <- merge(h$phiPath, ref$shares[, c("sector", "region", "year", "phi")], by = c("sector", "region", "year"))
cat("share path vs Phase 1:", nrow(m), "values, max |diff|", signif(max(abs(m$phi.x - m$phi.y)), 3), "\n")
k <- h$strength; print(k[k$year %in% c(2050, 2100), c("sector", "year", "k")], row.names = FALSE)
gd <- gamstransfer::Container$new(file.path(out, "p45_regiDiff_phi.gdx"))
for (nm in c("p45_regiDiff_phi", "p45_pfmPhiPath", "p45_pfmPhiMktPath", "p45_pfmPriceBound", "p45_regiDiff_lambda")) {
  x <- gd$getSymbols(nm)[[1]]
  cat(sprintf("%-20s (%s) %d records, range %s\n", nm, paste(x$domainNames, collapse = ","), nrow(x$records),
              paste(signif(range(x$records$value), 3), collapse = " .. ")))
}
stopifnot(max(abs(m$phi.x - m$phi.y)) < 1e-12,
          all(gd$getSymbols("p45_regiDiff_lambda")[[1]]$records$value == 0),
          min(gd$getSymbols("p45_pfmPhiPath")[[1]]$records$value) > 0)
cat("OK\n")
