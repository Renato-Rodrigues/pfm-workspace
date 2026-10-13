# Why the political limit fades in the coupled runs, and how far it rests on drivers outside the data
# (0005 C3 and C10; the mechanism figure of the paper).
#   Rscript analysis/v6/couplingMechanism.R [group]          (repo root; default v6)
# Run after runCoupledStage.R <group>. Two parts:
#   1. C10, every admitted coupled run: the strength k_s(t) of its last PFM call and the share of the
#      weighted drivers outside the observed range (outOfSupportShare), read from pfm-phi-history.rds.
#   2. C3 on the coupled energy systems: the two headline runs at EU21 (hold the price and hold the
#      budget, fading limit) recomputed with only one driver group moving - the weight of fossil and
#      clean-energy interests (actor power), institutions, or income and population - the others held at
#      2025, exactly as analysis/v6/phase1.R does offline on the uncoupled bases. "all" is the run's own
#      recomputation, checked against the k its last call recorded.
# Output: output/pfm/<group>/coupling/strength-support.rds (support, decomposition, check).
suppressMessages({ library(pfm); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v6" })
if (!file.exists("config.yml")) stop("run from the project root")
say <- function(...) cat("[mechanism:", g, "] ", ..., "\n", sep = "")
CPL <- file.path("output/pfm", g, "coupling"); RUNS <- file.path("output/remind-runs", g)
CR <- readRDS(file.path(CPL, "coupled-runs.rds"))$runs
CR <- CR[grepl("-PFMlevel|-PFMratio", CR$scenario), ]
THETA <- 0.5; T0 <- 2025; YRS <- c(2025, 2030, 2035, 2040, 2050, 2060, 2070, 2080, 2100)

# ── 1. C10: k and the out-of-support share of every coupled run's last call ───────────────────────
support <- do.call(rbind, lapply(seq_len(nrow(CR)), function(i) {
  f <- file.path(RUNS, CR$resolution[i], CR$dir[i], "pfm-phi-history.rds")
  if (!file.exists(f)) return(NULL)
  h <- readRDS(f); s <- h[[length(h)]]$strength
  data.frame(resolution = CR$resolution[i], run = sub("^SSP2-(EU21-)?PkBudg1000-", "", CR$scenario[i]),
             s[, c("sector", "year", "k", "outOfSupportShare", "clipShare")])
}))
say("C10: ", length(unique(paste(support$resolution, support$run))), " coupled runs read")
hl <- support[support$run %in% c("PFMlevelBfix-v6", "PFMlevelC-v6") & support$year %in% c(2030, 2050, 2070, 2100), ]
print(reshape(hl[, c("resolution", "run", "sector", "year", "outOfSupportShare")],
              idvar = c("resolution", "run", "sector"), timevar = "year", direction = "wide"), row.names = FALSE, digits = 3)
rng <- aggregate(outOfSupportShare ~ resolution + sector + year, support[support$year %in% c(2050, 2100), ], range)
say("range of the out-of-support share over every coupled run:"); print(rng, row.names = FALSE, digits = 3)

# ── 2. C3 on the coupled energy systems (EU21 headline runs) ─────────────────────────────────────
# the Run-Group's prepared madrat cache, forced, as iterativePFM does in a run (config.yml madrat:, ADR 0047)
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"),
                                   forcecache = TRUE, .verbose = FALSE))
# the Run-Group's panel definition (the IEA edition behind the energy drivers), as phase1.R and a run set it
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup(file.path("output/pfm", g), rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
# the anchor the coupled runs read (output/remind-inputs/<group>/phi-anchor.rds, EU21), with its weights
a <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")
heads <- CR[CR$resolution == "EU21" & sub("^SSP2-EU21-PkBudg1000-", "", CR$scenario) %in% c("PFMlevelBfix-v6", "PFMlevelC-v6"), ]
dec <- list(); chk <- list()
for (i in seq_len(nrow(heads))) {
  run <- sub("^SSP2-EU21-PkBudg1000-", "", heads$scenario[i])
  gdx <- file.path(RUNS, "EU21", heads$dir[i], "fulldata.gdx")
  cache <- file.path(CPL, paste0("scen-", run, ".rds"))
  scen <- if (file.exists(cache) && identical(attr(readRDS(cache), "gdx"), normalizePath(gdx, winslash = "/"))) readRDS(cache) else {
    say("building the scenario panel of ", run)
    s <- panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                           outputRegionMappingFile = "country", ssp = "SSP2", institutions = "storyline")
    attr(s, "gdx") <- normalizePath(gdx, winslash = "/"); saveRDS(s, cache); s }
  vars <- getNames(scen)
  grp <- list(`actor power` = grep("Power", vars, value = TRUE),
              institutions = grep("\\((WGI|VDem)\\)", vars, value = TRUE),
              controls = grep("^GDP|^Population|Hydro", vars, value = TRUE))
  freezeExcept <- function(x, keep) {
    arr <- as.array(x); yrs <- getYears(x, as.integer = TRUE); i0 <- which(yrs == T0)
    for (v in setdiff(unlist(grp), keep)) for (yi in seq_along(yrs)) arr[, yi, v] <- arr[, i0, v]
    as.magpie(arr, spatial = 1)
  }
  full <- computeStrengthPath(a, scen, theta = THETA)$strength
  dec[[run]] <- rbind(cbind(run = run, onlyMoving = "all", full[full$year %in% YRS, c("sector", "year", "k", "outOfSupportShare")]),
    do.call(rbind, lapply(names(grp), function(gn) {
      s <- computeStrengthPath(a, freezeExcept(scen, grp[[gn]]), theta = THETA)$strength
      cbind(run = run, onlyMoving = gn, s[s$year %in% YRS, c("sector", "year", "k", "outOfSupportShare")])
    })))
  rec <- support[support$resolution == "EU21" & support$run == run & support$year %in% YRS, c("sector", "year", "k")]
  m <- merge(rec, full[, c("sector", "year", "k")], by = c("sector", "year"), suffixes = c(".call", ".gdx"))
  chk[[run]] <- cbind(run = run, m, diff = m$k.gdx - m$k.call)
}
dec <- do.call(rbind, dec); chk <- do.call(rbind, chk)
say("check: the final energy system against the last call's k (max |diff| ",
    formatC(max(abs(chk$diff)), format = "f", digits = 4), ")")
dw <- reshape(dec[, c("run", "onlyMoving", "sector", "year", "k")], idvar = c("run", "onlyMoving", "sector"),
              timevar = "year", direction = "wide")
names(dw) <- sub("^k\\.", "", names(dw)); print(dw[order(dw$run, dw$sector, dw$onlyMoving), ], row.names = FALSE, digits = 3)

# ── 3. beyond the observed energy system: the fossil and clean-energy terms outside their training range ─
# outOfSupportShare above counts drivers beyond their guard range; for the saturating actor-power terms that
# range is the physical domain, so they never count there. Here: the final-energy-weighted share of
# countries whose saturated, standardised actor-power term lies outside the range observed in estimation
# (frontier.rds support), per term, sector and year, on each headline run's final energy system.
FR <- readRDS(file.path("output/pfm", g, "frontier.rds"))$bySector
apNames <- c(Innovator.Power = "Innovator Power", Incumbent.Power = "Incumbent Power", Incumbent.Power.pc = "Incumbent Power pc")
beyond <- do.call(rbind, lapply(seq_len(nrow(heads)), function(i) {
  run <- sub("^SSP2-EU21-PkBudg1000-", "", heads$scenario[i])
  scen <- readRDS(file.path(CPL, paste0("scen-", run, ".rds")))
  do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) {
    sup <- FR[[sec]]$support; sc <- FR[[sec]]$driverScaling
    do.call(rbind, lapply(names(apNames), function(term) {
      x <- scen[, , paste0(apNames[[term]], "|", sec)]
      cc <- intersect(getItems(x, 1), names(a$weights)); x <- x[cc, YRS, ]
      p <- sc[[term]]; zt <- ((x / (x + p[["sat"]])) - p[["mean"]]) / p[["sd"]]
      lo <- sup$min[sup$term == term]; hi <- sup$max[sup$term == term]
      wv <- a$weights[cc]
      do.call(rbind, lapply(YRS, function(y) {
        v <- as.numeric(zt[, y, ]); ok <- is.finite(v)
        data.frame(run = run, sector = sec, term = term, year = y,
                   above = sum(wv[ok] * (v[ok] > hi)) / sum(wv[ok]), below = sum(wv[ok] * (v[ok] < lo)) / sum(wv[ok]))
      }))
    }))
  }))
}))
say("beyond the observed range (final-energy-weighted share of countries), headline runs:")
print(reshape(beyond[beyond$year %in% c(2050, 2100), c("run", "sector", "term", "year", "above", "below")],
              idvar = c("run", "sector", "term"), timevar = "year", direction = "wide"), row.names = FALSE, digits = 2)

out <- list(group = g, beyond = beyond, generated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), support = support,
            decomposition = dec, check = chk, note = paste(
              "support: every admitted coupled run, last PFM call. decomposition: EU21 headline runs, final",
              "energy system, one driver group moving (others at 2025), theta = 0.50; 'actor power' = the weight",
              "of fossil and clean-energy interests (ADR 0056)."))
saveRDS(out, file.path(CPL, "strength-support.rds"))
say("wrote ", file.path(CPL, "strength-support.rds"))
