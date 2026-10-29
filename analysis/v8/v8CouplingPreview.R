# v8 coupling preview (design note 0009 section 18): what the v8 anchor delivers on a coupled energy system, before the batch.
#   Rscript analysis/v8/v8CouplingPreview.R   (repo root) -> output/pfm/v8/v8-coupling-preview.rds
# The energy system of v7's coupled hold-the-price headline (EU21, 1000 Gt). Its scenario panel is rebuilt with v8's panel
# definition (World Bank rents linked to REMIND's) and v8's central institution rule (gap closure, design note 0008), cached
# in output/pfm/v8/coupling/. Shares at theta 0.50 (pfmV6Shares) for:
#   v7 as published   v7's anchor, its own scenario panel (storyline institutions), common strength;
#   v7 gap closure    v7's anchor on the gap-closure panel, common strength;
#   v8 common         v8's anchor, common strength;
#   v8 regional       v8's anchor, regional strength (v8's central form).
# Reported: the strength k by sector, each region's share phi in 2030 / 2050 / 2100, and the final-energy-weighted world mean
# of 1 - phi (the share of the extra effort held back).
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
suppressMessages(madrat::setConfig(cachefolder = normalizePath("data/madrat/v8", winslash = "/"), forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = "v8", verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup("output/pfm/v8", rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability", "fossilRents")])
scen7 <- readRDS("output/pfm/v7/coupling/scen-PFMlevelBfix-v7.rds"); gdx <- attr(scen7, "gdx")
dir.create("output/pfm/v8/coupling", showWarnings = FALSE)
cache <- "output/pfm/v8/coupling/scen-v7Bfix-gapclosure-v8panel.rds"
scen8 <- if (file.exists(cache) && identical(attr(readRDS(cache), "gdx"), gdx)) readRDS(cache) else {
  message("[preview] building the scenario panel (gap closure, rents linked to REMIND) ...")
  s <- panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                         outputRegionMappingFile = "country", ssp = "SSP2", institutions = "gapclosure")
  attr(s, "gdx") <- gdx; saveRDS(s, cache); s }
stopifnot("Fossil Rents" %in% getNames(scen8))
a7 <- pfmAnchorFor("output/remind-inputs/v7", "EU21"); a8 <- pfmAnchorFor("output/remind-inputs/v8", "EU21")
runs <- list(`v7 as published` = pfmV6Shares(a7, scen7, theta = 0.5),
             `v7 gap closure` = pfmV6Shares(a7, scen8, theta = 0.5),
             `v8 common` = pfmV6Shares(a8, scen8, theta = 0.5),
             `v8 regional` = pfmV6Shares(a8, scen8, theta = 0.5, options = list(strength = "regional")))
YY <- c(2030, 2050, 2100)
k <- do.call(rbind, lapply(names(runs), function(n) { s <- runs[[n]]$strength; s <- s[s$year %in% YY & s$sector %in% c("Bulk", "Diffuse"), ]
  data.frame(run = n, sector = s$sector, year = s$year, k = s$k) }))
phi <- do.call(rbind, lapply(names(runs), function(n) { s <- runs[[n]]$shares; s <- s[s$year %in% YY, ]
  data.frame(run = n, sector = s$sector, region = s$region, year = s$year, phi = s$phi) }))
wR <- a8$regionWeights
held <- do.call(rbind, lapply(split(phi, paste(phi$run, phi$sector, phi$year)), function(d)
  data.frame(run = d$run[1], sector = d$sector[1], year = d$year[1], heldBack = sum((1 - d$phi) * wR[d$region], na.rm = TRUE) / sum(wR[d$region], na.rm = TRUE))))
saveRDS(list(made = format(Sys.time(), "%Y-%m-%d %H:%M"), gdx = gdx, strength = k, phi = phi, heldBack = held), "output/pfm/v8/v8-coupling-preview.rds")
options(width = 200)
cat("strength k (common):\n"); print(reshape(k[k$run != "v8 regional", ], idvar = c("run", "sector"), timevar = "year", direction = "wide"), digits = 3, row.names = FALSE)
cat("\nworld (final-energy weighted) share of the extra effort held back, 1 - phi:\n")
print(reshape(held, idvar = c("run", "sector"), timevar = "year", direction = "wide")[order(held$sector[!duplicated(paste(held$run, held$sector))]), ], digits = 3, row.names = FALSE)
for (sec in c("Bulk", "Diffuse")) for (y in c(2050, 2100)) {
  x <- reshape(phi[phi$sector == sec & phi$year == y, c("run", "region", "phi")], idvar = "region", timevar = "run", direction = "wide")
  names(x) <- sub("phi.", "", names(x), fixed = TRUE); cat("\n", sec, y, ": share phi by region\n"); print(x[order(x[["v8 regional"]]), ], digits = 2, row.names = FALSE) }
