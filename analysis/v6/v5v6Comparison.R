# Design note 0005 Phase 2, step 6: the v5 -> v6 comparison - panel, spec, selection, coefficients,
# the efficiency ordering at the anchor year, the regional ranking u and the most constrained regions.
# Methods / SI material for the v6 paper. Every number is read from the two Run-Groups' artifacts.
#   Rscript analysis/v6/v5v6Comparison.R [old] [new]     (repo root; default v5 v6; after the pfm-anchor
#                                                          step on <new>)
# u is computed for BOTH groups by the v6 rule (computeAnchorGap at each group's own anchor year, the
# same 2025 final-energy weights, the REMIND-consistent EU21 mapping), so it compares the models, not
# the formulations. v5's own operational shares (v5 formulation, coupling-summary.rds) are shown beside
# it; they were aggregated with the future mapping (0005 E26).
# Output: output/pfm/<new>/phase1/v5-v6-comparison.rds and a printed summary.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
a <- commandArgs(trailingOnly = TRUE)
OLD <- if (length(a) > 0) a[1] else "v5"; NEW <- if (length(a) > 1) a[2] else "v6"
gd <- function(g) file.path("output/pfm", g)
rc <- pfmResolveConfig("config.yml", group = NEW, verbose = FALSE)
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
modelDir <- rc$modelDir %||% "output/pfm/fit-cache"
short <- function(x) sub(" bothIncAP lev ", " ", x, fixed = TRUE)
sectors <- c("Bulk", "Diffuse")

# ── 1. panel and spec ─────────────────────────────────────────────────────────────────────────
info <- lapply(c(OLD, NEW), function(g) {
  pd <- pfm:::.pfmPanelDefForGroup(gd(g), rc$panel)
  sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(gd(g)))[[1]]
  fr <- readRDS(file.path(gd(g), "frontier.rds"))
  ncov <- length(unique(as.character(fr$bySector$Bulk$scores$region)))
  list(group = g, panelHash = jsonlite::read_json(file.path(gd(g), "manifest.json"))$panel_hash,
       years = paste(pd$firstYear, pd$lastYear, sep = "-"), movingAverage = pd$movingAverage,
       iea = pd$ieaVersion %||% NA, geothermal = isTRUE(pd$geothermal), coveredCountries = ncov,
       spec = sel$name, apTransform = sel$apTransform %||% "linear",
       actorPower = paste(unlist(sel$actorPowerDrivers), collapse = ", "),
       institutions = paste(unlist(sel$instQualityDrivers), collapse = ", "),
       controls = paste(unlist(sel$controlDrivers), collapse = ", "),
       fixedEffects = sel$regionMappingFixedEffects %||% "none")
})
names(info) <- c(OLD, NEW)

# ── 2. selection statistics of the deployed spec ──────────────────────────────────────────────
selStats <- do.call(rbind, lapply(c(OLD, NEW), function(g) {
  sw <- readRDS(file.path(gd(g), "sweep.rds")); r <- sw$results
  st <- if ("stage" %in% names(r)) r$stage else rep("PolicyStringency", nrow(r))
  r <- r[st %in% c("PolicyStringency", "PSM") & r$model == info[[g]]$spec, ]
  fr <- readRDS(file.path(gd(g), "frontier.rds"))
  gam <- vapply(sectors, function(s) { ct <- fr$bySector[[s]]$coefTable; ct$estimate[ct$term == "gamma"] }, numeric(1))
  bs <- tryCatch(readRDS(file.path(gd(g), "selection-bootstrap.rds")), error = function(e) NULL)
  do.call(rbind, lapply(sectors, function(s) { x <- r[r$sector == s, ][1, ]
    data.frame(group = g, sector = s, tier = x$tier, dR2theory = x$deltaR2Theory, pseudoR2 = x$pseudoR2,
               bic = x$bic, maxVIF = x$maxVIF, nObs = x$nObs, gamma = gam[[s]],
               bootWin = bs$deployedWinShare %||% NA_real_, bootWinGivenSanity = bs$deployedWinShareConditional %||% NA_real_,
               stringsAsFactors = FALSE) }))
}))

# ── 3. coefficients: frontier (drives the coupling) and satP with wild-cluster p (quotable) ───
coefs <- do.call(rbind, lapply(c(OLD, NEW), function(g) {
  fr <- readRDS(file.path(gd(g), "frontier.rds")); ag <- tryCatch(readRDS(file.path(gd(g), "estimator-agreement.rds")), error = function(e) NULL)
  do.call(rbind, lapply(sectors, function(s) {
    ct <- fr$bySector[[s]]$coefTable; ct <- ct[!ct$term %in% c("sigmaSq", "gamma") & !grepl("regionFE|Intercept", ct$term), ]
    d <- data.frame(group = g, sector = s, term = ct$term, frontier = ct$estimate, stringsAsFactors = FALSE)
    if (!is.null(ag)) {
      t <- ag$bySector[[s]]$table; t <- t[t$estimator == "satP", c("term", "estimate")]; names(t)[2] <- "satP"
      w <- ag$bySector[[s]]$wildBootstrap[, c("term", "pWild")]
      sg <- ag$bySector[[s]]$agreement[, c("term", "signs")]
      d <- merge(merge(merge(d, t, by = "term", all.x = TRUE), w, by = "term", all.x = TRUE), sg, by = "term", all.x = TRUE)
    }
    d }))
}))

# ── 4. the efficiency ordering at each group's anchor year (covered countries) ────────────────
eAt <- lapply(c(OLD, NEW), function(g) { fr <- readRDS(file.path(gd(g), "frontier.rds"))
  lapply(sectors, function(s) { sc <- fr$bySector[[s]]$scores; ya <- max(sc$year[is.finite(sc$efficiencyRatio)])
    x <- sc[sc$year == ya & is.finite(sc$efficiencyRatio), ]; stats::setNames(x$efficiencyRatio, as.character(x$region)) }) |> stats::setNames(sectors) })
names(eAt) <- c(OLD, NEW)
eCmp <- do.call(rbind, lapply(sectors, function(s) { o <- eAt[[OLD]][[s]]; n <- eAt[[NEW]][[s]]; cc <- intersect(names(o), names(n))
  data.frame(sector = s, nCommon = length(cc), spearman = stats::cor(o[cc], n[cc], method = "spearman"),
             medianOld = stats::median(o), medianNew = stats::median(n),
             lowest5Old = paste(names(sort(o))[1:5], collapse = ","), lowest5New = paste(names(sort(n))[1:5], collapse = ","),
             onlyOld = paste(setdiff(names(o), names(n)), collapse = ","), onlyNew = paste(setdiff(names(n), names(o)), collapse = ","),
             stringsAsFactors = FALSE) }))

# ── 5. the regional ranking u (v6 rule for both) and the most constrained regions ─────────────
pdNew <- pfm:::.pfmPanelDefForGroup(gd(NEW), rc$panel)
options(pfm.panel = pdNew[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
w <- pfmAssertSizeWeights(pfmCouplingWeights(year = 2025, scenario = "SSP2"), "v5-v6 comparison")
uNew <- pfmAnchorFor(gd(NEW), "EU21")$region
pdOld <- pfm:::.pfmPanelDefForGroup(gd(OLD), rc$panel)
options(pfm.panel = pdOld[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
uOld <- computeAnchorGap(OLD, resultsDir = "output/pfm", modelDir = modelDir, weights = w, verbose = FALSE)$region
uCmp <- merge(uOld[, c("sector", "region", "u", "g")], uNew[, c("sector", "region", "u", "g")], by = c("sector", "region"), suffixes = c(".old", ".new"))
uSum <- do.call(rbind, lapply(sectors, function(s) { d <- uCmp[uCmp$sector == s, ]
  data.frame(sector = s, spearman = stats::cor(d$u.old, d$u.new, method = "spearman"),
             mostConstrainedOld = paste(d$region[order(-d$u.old)][1:3], collapse = ","),
             mostConstrainedNew = paste(d$region[order(-d$u.new)][1:3], collapse = ","),
             leastConstrainedOld = paste(d$region[order(d$u.old)][1:3], collapse = ","),
             leastConstrainedNew = paste(d$region[order(d$u.new)][1:3], collapse = ","),
             maxAbsDu = max(abs(d$u.new - d$u.old)), regionMostMoved = d$region[which.max(abs(d$u.new - d$u.old))],
             stringsAsFactors = FALSE) }))
# floor (min over sectors) of phi at theta 0.5: v6 at t0 = 1 - 0.5 u; v5's operational shares
phiNew <- stats::aggregate(phi ~ region, data = transform(uNew, phi = 1 - 0.5 * u), FUN = min)
cs5 <- tryCatch(readRDS(file.path(gd(OLD), "coupling/coupling-summary.rds")), error = function(e) NULL)
phiOld <- if (!is.null(cs5)) { b <- cs5$boundAnchor; b <- b[b$year == min(b$year), c("region", "phi")]; b } else NULL
floors <- merge(phiNew, phiOld, by = "region", suffixes = c(".v6t0", ".v5operational"), all = TRUE)

res <- list(info = info, selection = selStats, coefficients = coefs, efficiency = eCmp, u = uCmp, uSummary = uSum,
            floors = floors, label = paste(OLD, "->", NEW, "comparison; u by the v6 rule for both groups"))
saveRDS(res, file.path(gd(NEW), "phase1", "v5-v6-comparison.rds"))

options(width = 220)
cat("\n== 1. panel and spec\n"); print(do.call(rbind, lapply(info, as.data.frame)), row.names = FALSE)
cat("\n== 2. selection statistics of the deployed spec\n"); print(selStats, row.names = FALSE, digits = 3)
cat("\n== 3. institution and actor-power coefficients (frontier | satP, wild-cluster p, sign agreement over 7 estimators)\n")
ck <- coefs[!grepl("_x_", coefs$term) & !grepl("Trend|Population|GDP|Hydro", coefs$term), ]
print(ck[order(ck$sector, ck$term, ck$group), ], row.names = FALSE, digits = 3)
cat("\n== 4. efficiency ordering at the anchor year (covered countries)\n"); print(eCmp, row.names = FALSE, digits = 3)
cat("\n== 5. regional ranking u, EU21 (v6 rule for both)\n"); print(uSum, row.names = FALSE, digits = 3)
cat("\n== floor share at theta 0.5: v6 at t0 vs v5 operational (v5 formulation)\n"); print(floors[order(floors$phi.v6t0), ], row.names = FALSE, digits = 3)
