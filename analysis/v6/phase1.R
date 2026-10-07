# Phase 1 of design note 0005: the v6 coupling formulation, offline, on Run-Group v6.
#   Rscript analysis/v6/phase1.R [group]                       (from the repo root; default v6)
# Uses pfm::computeAnchorGap / computeStrengthPath / computeSharePath. Nothing is re-optimised by
# REMIND: every energy system is the final state of an existing run - the config.yml registry's NPi and
# PkBudg1000 bases (analysis/v6/bases.R), plus the v5 coupled runs where present.
#   1. anchors at EU21 and H12 (the ranking u, the provenance of each region's gap)
#   2. k_s(t) on every energy system: NPi, PkBudg1000, and the coupled -PFMgate / -PFMlevelBfix /
#      -PFMlevelC runs (how much REMIND's energy system moves k between pathways)
#   3. the variants: E-hold (D2/C5), hold 2060 (D6), model spread (D11), regional k (D16),
#      ordering tests (D15/C1)
#   4. C3: k_s(t) with only one driver group moving (actor power / institutions / controls)
#   5. C8: the seam at the anchor year, eta of the scenario panel against history
# Output: output/pfm/<group>/phase1/*.rds and a printed summary. Not a Run-Group artifact.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v6" })
ROOT <- normalizePath(".", winslash = "/")
GD <- file.path("output/pfm", g); OUT <- file.path(GD, "phase1"); dir.create(OUT, showWarnings = FALSE)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)   # the registry's SSP2 pair (PITFALLS.md 34)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
say <- function(...) message("[phase1:", g, "] ", ...)
THETA <- 0.5; T0 <- 2025; YRS <- c(2025, 2030, 2035, 2040, 2050, 2060, 2070, 2080, 2100)
RES <- c(EU21 = "regionmapping_21_EU11.csv", H12 = "regionmappingH12.csv")

# ── scenario panels (fixed code, the group's panel definition), cached ───────────────────────
runs <- c(BASES, v5CoupledRuns())
say("bases: ", paste(sprintf("%s = %s (REMIND %s)", names(BASES), basename(dirname(BASES)),
                             vapply(BASES, remindVersion, "")), collapse = "; "))
scen <- lapply(names(runs), function(k) {
  f <- file.path(OUT, paste0("scen-", k, ".rds"))
  if (file.exists(f)) {
    s <- readRDS(f)
    if (identical(normalizePath(attr(s, "gdx") %||% "", winslash = "/", mustWork = FALSE),
                  normalizePath(runs[[k]], winslash = "/", mustWork = FALSE))) return(s)
    say("the cached panel of ", k, " was built from another gdx - rebuilding")
  }
  say("building the scenario panel of ", k)
  s <- panelDataScenario(gdxFile = runs[[k]],
                         aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                         outputRegionMappingFile = "country", ssp = "SSP2", institutions = "storyline")
  attr(s, "gdx") <- normalizePath(runs[[k]], winslash = "/")
  saveRDS(s, f); s
})
names(scen) <- names(runs)

# ── 1. anchors ───────────────────────────────────────────────────────────────────────────────
w <- pfmAssertSizeWeights(pfmCouplingWeights(year = T0, scenario = "SSP2"), "phase1")
anchors <- lapply(RES, function(m) computeAnchorGap(g, resultsDir = "output/pfm", modelDir = rc$modelDir %||% "output/pfm/fit-cache",
                                                   mapping = m, weights = w, verbose = FALSE))
for (r in names(anchors)) {
  a <- anchors[[r]]
  say(r, ": anchor ", a$anchorYear, "; bases ", paste(names(table(a$country$basis)), table(a$country$basis), collapse = " "))
}
saveRDS(lapply(anchors, function(a) a[setdiff(names(a), "designs")]), file.path(OUT, "anchors.rds"))

# ── 2. k_s(t) on every energy system, both resolutions ───────────────────────────────────────
strength <- do.call(rbind, lapply(names(RES), function(r) do.call(rbind, lapply(names(scen), function(k) {
  s <- computeStrengthPath(anchors[[r]], scen[[k]], theta = THETA)$strength
  cbind(resolution = r, run = k, s[s$year %in% YRS, ])
}))))
saveRDS(strength, file.path(OUT, "strength.rds"))
cat("\n== k_s(t) by energy system (EU21 regions; H12 alongside)\n")
kw <- reshape(strength[, c("resolution", "run", "sector", "year", "k")], idvar = c("resolution", "run", "sector"),
              timevar = "year", direction = "wide")
names(kw) <- sub("^k\\.", "", names(kw)); print(kw, row.names = FALSE, digits = 3)
cat("\n== out-of-support share of the drivers (C10), EU21\n")
print(reshape(strength[strength$resolution == "EU21" & strength$sector == "Bulk", c("run", "year", "outOfSupportShare")],
              idvar = "run", timevar = "year", direction = "wide"), row.names = FALSE, digits = 2)

# ── 3. variants on the two horns' energy systems (EU21) ──────────────────────────────────────
a <- anchors$EU21
phiOf <- function(st, ...) { p <- computeSharePath(a, st, theta = THETA, ...); p[p$sector != "min", ] }
cmpPhi <- function(base, alt, label) do.call(rbind, lapply(c(2035, 2050, 2070), function(y) {
  m <- merge(base[base$year == y, c("sector", "region", "phi")], alt[alt$year == y, c("sector", "region", "phi")],
             by = c("sector", "region"))
  do.call(rbind, lapply(split(m, m$sector), function(d) data.frame(
    variant = label, sector = d$sector[1], year = y,
    spearman = suppressWarnings(stats::cor(d$phi.x, d$phi.y, method = "spearman")),
    medAbsDiff = stats::median(abs(d$phi.y - d$phi.x)), maxAbsDiff = max(abs(d$phi.y - d$phi.x)))))
}))
variants <- do.call(rbind, lapply(c("PkBudg1000", "PFMlevelBfix"), function(k) {
  st <- computeStrengthPath(a, scen[[k]], theta = THETA)
  base <- phiOf(st)
  stE <- computeStrengthPath(a, scen[[k]], theta = THETA, hold = "ratio")
  st60 <- computeStrengthPath(a, scen[[k]], theta = THETA, holdYear = 2060)
  # regional strength k_r(t) = g_r(t) / g_r(t0) instead of the common k (D16)
  rg <- st$regions; g0 <- rg[rg$year == T0, c("sector", "region", "g")]
  rg <- merge(rg, g0, by = c("sector", "region"), suffixes = c("", "0")); rg$kr <- rg$g / rg$g0
  regPhi <- merge(rg[, c("sector", "region", "year", "kr")], a$region[, c("sector", "region", "u")], by = c("sector", "region"))
  regPhi$phi <- pmin(pmax(1 - THETA * regPhi$kr * regPhi$u, 0), 1)
  kpath <- function(s, lab) cbind(variant = lab, s$strength[s$strength$year %in% YRS, c("sector", "year", "k")])
  out <- rbind(
    cmpPhi(base, phiOf(stE), "E-hold (static share, C5)"),
    cmpPhi(base, phiOf(st60), "hold 2060 (D6)"),
    cmpPhi(base, phiOf(st, spread = "model"), "model spread d = D/D(t0) (D11)"),
    cmpPhi(base, regPhi, "regional k_r (D16)"),
    cmpPhi(base, phiOf(st, ordering = "uniform"), "uniform u (D15)"),
    cmpPhi(base, phiOf(st, ordering = "reversed"), "reversed u (D15)"),
    do.call(rbind, lapply(1:3, function(sd) cmpPhi(base, phiOf(st, ordering = "permuted", seed = sd), paste0("permuted u, seed ", sd)))))
  attr(out, "k") <- rbind(kpath(st, "logit hold (central)"), kpath(stE, "E-hold"), kpath(st60, "hold 2060"))
  cbind(run = k, out)
}))
saveRDS(variants, file.path(OUT, "variants.rds"))
cat("\n== variants: phi against the central formulation, theta = 0.5 (EU21)\n")
print(variants, row.names = FALSE, digits = 3)

# ── 4. C3: only one driver group moves ───────────────────────────────────────────────────────
vars <- getNames(scen$PkBudg1000)
grp <- list(`actor power` = grep("Power", vars, value = TRUE),
            institutions = grep("\\((WGI|VDem)\\)", vars, value = TRUE),
            controls = grep("^GDP|^Population|Hydro", vars, value = TRUE))
freezeExcept <- function(x, keep) {
  arr <- as.array(x); yrs <- getYears(x, as.integer = TRUE); i0 <- which(yrs == T0)
  fr <- setdiff(unlist(grp), keep)
  for (v in fr) for (yi in seq_along(yrs)) arr[, yi, v] <- arr[, i0, v]
  as.magpie(arr, spatial = 1)
}
decomp <- do.call(rbind, lapply(c("PkBudg1000", "NPi"), function(k) do.call(rbind, lapply(names(grp), function(gn) {
  s <- computeStrengthPath(a, freezeExcept(scen[[k]], grp[[gn]]), theta = THETA)$strength
  cbind(run = k, onlyMoving = gn, s[s$year %in% YRS, c("sector", "year", "k")])
}))))
full <- strength[strength$resolution == "EU21" & strength$run %in% c("PkBudg1000", "NPi"), c("run", "sector", "year", "k")]
decomp <- rbind(decomp, cbind(onlyMoving = "all (central)", full[, c("run", "sector", "year", "k")])[, names(decomp)])
saveRDS(decomp, file.path(OUT, "decomposition.rds"))
cat("\n== C3: k_s(t) with only one driver group moving (EU21)\n")
dw <- reshape(decomp, idvar = c("run", "onlyMoving", "sector"), timevar = "year", direction = "wide")
names(dw) <- sub("^k\\.", "", names(dw)); print(dw[order(dw$run, dw$sector, dw$onlyMoving), ], row.names = FALSE, digits = 3)

# ── 5. C8: the seam at the anchor ────────────────────────────────────────────────────────────
# The scenario panel has no 2023 row, so it is interpolated to annual steps and eta read at the anchor
# year: both sides then read the 2022 drivers (the lag counts years since 2026-10-06, PITFALLS 31).
# (Interpolating eta itself would invent a gap: eta is not linear in the drivers - interactions, saturation.)
sp <- scen$PkBudg1000
ta <- a$anchorYear
spy <- getYears(sp, as.integer = TRUE)
sp <- time_interpolate(sp, seq(min(spy), max(spy)), integrate_interpolated_years = TRUE, extrapolation_type = "constant")
seam <- do.call(rbind, lapply(names(a$designs), function(sec) {
  des <- a$designs[[sec]]
  es <- pfm:::.pfmFrontierEta(des, sp); es <- es[es$year == ta, , drop = FALSE]
  m <- data.frame(region = es$region, etaScen = es$eta, stringsAsFactors = FALSE)
  cc <- a$country[a$country$sector == sec, c("region", "basis", "etaAnchor", "q")]
  m <- merge(m, cc, by = "region")
  m$dEta <- m$etaScen - m$etaAnchor
  m$dIndex <- 10 * stats::plogis(m$etaScen - m$q) - 10 * stats::plogis(m$etaAnchor - m$q)
  cbind(sector = sec, m)
}))
saveRDS(seam, file.path(OUT, "seam.rds"))
cat("\n== C8: eta(scenario, interpolated to the anchor year) - eta(history), per country\n")
print(do.call(rbind, lapply(split(seam, list(seam$sector, seam$basis == "observed"), drop = TRUE), function(d) {
  nNA <- sum(!is.finite(d$dEta)); d <- d[is.finite(d$dEta), , drop = FALSE]; data.frame(
  sector = d$sector[1], countries = if (d$basis[1] == "observed") "covered" else "band rule", n = nrow(d), nMissingEta = nNA,
  medAbsDEta = stats::median(abs(d$dEta)), p95AbsDEta = unname(stats::quantile(abs(d$dEta), .95)),
  medAbsDIndex = stats::median(abs(d$dIndex)), maxAbsDIndex = max(abs(d$dIndex)),
  worst = d$region[which.max(abs(d$dIndex))]) })), row.names = FALSE, digits = 3)
say("done -> ", OUT)
