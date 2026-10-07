# Phase 1, step 6 of design note 0005, governance part (0004 §5 step 5): SSP1 and SSP3 institutions on
# the SSP2 energy system, to measure the SSP spread of k_s(t) against the spread across theta.
#   Rscript analysis/v6/sspGovernanceSwap.R [group]     (repo root; after phase1.R and the pfm-anchor step)
# What moves with the SSP here: the institution drivers of the deployed spec -
#   V-Dem Rule of Law and Vertical Accountability: the declared storyline rule per SSP (DATA.md 5.4);
#   Government Effectiveness: the SSP extensions' Governance Model, per SSP.
# What does NOT (the full version needs SSP GDP and population, cluster): the energy system (SSP2
# REMIND runs), income, population. So this is the governance share of the SSP spread, a lower bound
# on the whole SSP effect only if income and population move k the same way.
# Method: the institution block is rebuilt per SSP exactly as panelDataScenario builds it (projection,
# median imputation, normalisation on the historical range, harmonisation to the panel's 2023 value),
# and the SSP2 scenario panel gets  rebuilt(SSPx) - rebuilt(SSP2)  added, which cancels any replication
# error. "hold" (institutions at their last observation) is the decision-1A twin, for reference.
# Output: output/pfm/<group>/phase1/ssp-governance.rds and a printed summary.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass); library(mrpfm) })
`%||%` <- function(a, b) if (is.null(a)) b else a
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v6" })
GD <- file.path("output/pfm", g); P1 <- file.path(GD, "phase1")
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)   # the registry's SSP2 pair (PITFALLS.md 34)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
src <- getConfig("sourcefolder"); if (!dir.exists(file.path(src, "SSPextensions"))) src <- "C:/_data/work/remind_input_data/sources"
CASES <- c("SSP1", "SSP2", "SSP3", "hold")
GE <- "Government Effectiveness (WGI)"; ROL <- "Rule of Law (VDem)"; VA <- "Vertical Accountability (VDem)"

anc <- pfmAnchorFor(GD, "EU21")
hist <- loadTrainingPanel(jsonlite::read_json(file.path(GD, "manifest.json"))$panel_hash, rc$modelDir %||% "output/pfm/fit-cache")
scen <- lapply(c(NPi = "NPi", PkBudg1000 = "PkBudg1000"), function(k) v6ScenPanel(P1, k, BASES[[k]]))
y <- getYears(scen$NPi, as.integer = TRUE)
cc <- getItems(scen$NPi, 1)

# V-Dem block, as panelDataScenario: storyline projection, median imputation, country-range min-max
vdem <- calcOutput("VDem", aggregate = FALSE)
vMin <- apply(vdem, 3, min, na.rm = TRUE); vMax <- apply(vdem, 3, max, na.rm = TRUE)
vdemFor <- function(case) {
  p <- pfm:::.pfmProjectInstitutions(vdem, y, if (case == "hold") "hold" else "storyline", if (case == "hold") "SSP2" else case)
  p <- toolImputeMedians(p)
  toolNormalize(p, minVal = vMin, maxVal = vMax, targetRange = c(0, 1))[, , c(ROL, VA)]
}
# GE: the SSP extensions' Governance Model, read from the workbook (2099 -> 2100, held after, as the
# cached conversion does), median-imputed, normalised on the pipeline's historical range with the clamp
sx <- readxl::read_excel(file.path(src, "SSPextensions", "ssp-extensions_all_data.xlsx"), col_types = "text")
sx <- sx[sx$Variable == "Governance Index|Government Effectiveness", ]
wgiYears <- getYears(calcOutput("WGIindicator", aggregate = FALSE), as.integer = TRUE)
geBounds <- local({
  x <- calcOutput("SSPextensions", subtype = "drivers_SSP2", aggregate = FALSE)
  hy <- intersect(paste0("y", wgiYears), getYears(x))
  v <- x[, hy, "SSP2.Governance Index|Government Effectiveness"]
  c(lo = min(v, na.rm = TRUE), hi = max(v, na.rm = TRUE))
})
geFor <- function(case) {
  ssp <- if (case == "hold") "SSP2" else case
  d <- sx[sx$Scenario == ssp, ]
  iso <- suppressWarnings(countrycode::countrycode(d$Region, "country.name", "iso3c"))
  d <- d[!is.na(iso), ]; iso <- iso[!is.na(iso)]
  yc <- names(d)[grepl("^[0-9]{4}$", names(d))]
  m <- sapply(yc, function(z) suppressWarnings(as.numeric(d[[z]])))
  rownames(m) <- iso; m <- m[!duplicated(iso), , drop = FALSE]
  yrsX <- as.integer(colnames(m)); m <- m[, yrsX >= 2000, drop = FALSE]; yrsX <- yrsX[yrsX >= 2000]
  # normalisation bounds: the pipeline's, i.e. the cached (converted) series over its years shared
  # with WGI - the workbook alone has GE only from 2015, which gives a different range
  lo <- geBounds[["lo"]]; hi <- geBounds[["hi"]]
  val <- sapply(y, function(t) { tt <- min(t, 2099); if (as.character(tt) %in% colnames(m)) m[, as.character(tt)] else {
    a <- max(yrsX[yrsX <= tt]); b <- min(yrsX[yrsX >= tt]); m[, as.character(a)] + (tt - a) / max(b - a, 1) * (m[, as.character(b)] - m[, as.character(a)]) } })
  if (case == "hold") val[] <- val[, which(y == 2025)]          # hold: GE frozen at 2025 too
  out <- new.magpie(cc, y, GE, fill = NA)
  have <- intersect(cc, rownames(val)); out[have, , GE] <- val[have, ]
  out <- toolImputeMedians(out)
  pmin(pmax((out - lo) / (hi - lo), 0), 1)
}
# harmonisation to the panel at the stitch year, fading by 2040 (DATA.md 5.5)
harm <- function(x) {
  at <- time_interpolate(x, 2023, extrapolation_type = "linear")
  pfm:::.pfmHarmoniseScenario(x, hist[cc, , ], at, getNames(x), 2023, 2040)
}
block <- lapply(stats::setNames(CASES, CASES), function(case) {
  b <- mbind(vdemFor(case)[cc, y, ], geFor(case))
  harm(b)
})
# check: the SSP2 rebuild against the SSP2 panel (the difference method cancels what remains)
chk <- sapply(c(ROL, VA, GE), function(v) max(abs(block$SSP2[, y[y >= 2025], v] - scen$NPi[cc, y[y >= 2025], v]), na.rm = TRUE))
cat("SSP2 rebuild vs SSP2 panel, max |diff| from 2025:", paste(names(chk), signif(chk, 3), collapse = " | "), "\n")

kOf <- function(sp) { s <- computeStrengthPath(anc, sp)$strength; s[s$year %in% c(2035, 2050, 2070, 2100), c("sector", "year", "k")] }
res <- list()
for (run in names(scen)) for (case in CASES) {
  sp <- scen[[run]]
  for (v in c(ROL, VA, GE)) sp[cc, , v] <- sp[cc, , v] + (block[[case]][cc, , v] - block$SSP2[cc, , v])
  res[[paste(run, case)]] <- cbind(run = run, case = case, kOf(sp))
}
k <- do.call(rbind, res); rownames(k) <- NULL
kw <- reshape(k, idvar = c("run", "case", "sector"), timevar = "year", direction = "wide"); names(kw) <- sub("k.", "", names(kw), fixed = TRUE)

# the gate (0005 Phase 1): SSP spread of k against theta's range, on the most constrained region's phi
# (u = 1): phi = 1 - theta k. theta spread: k(SSP2) * (0.675 - 0.325); SSP spread: 0.5 * (max - min of k over SSP1-3).
gate <- do.call(rbind, lapply(split(k[k$case %in% c("SSP1", "SSP2", "SSP3"), ], list(k$run[k$case %in% c("SSP1", "SSP2", "SSP3")],
                                     k$sector[k$case %in% c("SSP1", "SSP2", "SSP3")], k$year[k$case %in% c("SSP1", "SSP2", "SSP3")]), drop = TRUE), function(d) {
  k2 <- d$k[d$case == "SSP2"]
  data.frame(run = d$run[1], sector = d$sector[1], year = d$year[1], kSSP1 = d$k[d$case == "SSP1"], kSSP2 = k2, kSSP3 = d$k[d$case == "SSP3"],
             phiRangeSSP = 0.5 * (max(d$k) - min(d$k)), phiRangeTheta = (0.675 - 0.325) * k2)
}))
gate$ratio <- gate$phiRangeSSP / gate$phiRangeTheta
saveRDS(list(k = k, gate = gate, check = chk, label = "governance-only SSP swap on the SSP2 energy system"), file.path(P1, "ssp-governance.rds"))
options(width = 200)
cat("\n== k_s(t) with SSP institutions on the SSP2 energy system (EU21)\n"); print(kw[order(kw$sector, kw$run, kw$case), ], row.names = FALSE, digits = 3)
cat("\n== the gate: the SSP spread of the floor region's phi against theta's range (u = 1; ratio < ~0.3 = small)\n")
print(gate[order(gate$sector, gate$run, gate$year), ], row.names = FALSE, digits = 3)
