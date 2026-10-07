# Decision 3 of 2026-10-06: how many uncovered countries the band rule can match to donors, and how
# good those matches are, under alternative matching rules - and what each does to the coupling.
#   Rscript analysis/v6/donorAlternatives.R [group]          (from the repo root; default v6)
# The deployed rule (computeDonorAssignment defaults): distance over the spec's base drivers weighted
# by |beta|; "close" up to the median, "far" up to the 90th percentile of the covered countries'
# nearest-neighbour distances; beyond that no donor (median or low band). Alternatives:
#   fewer drivers (the top 3-6 by |beta|), equal weights, a looser "far" bound (95th percentile, the
#   maximum, no bound).
# Quality is judged in the FULL space (the deployed metric), so a rule that finds more donors only
# by ignoring drivers shows it. Effect on the coupling: the anchor ranking u (EU21) and k(t) on
# PkBudg1000. Output: output/pfm/<group>/phase1/donor-alternatives.rds and a printed summary.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v6" })
GD <- file.path("output/pfm", g); OUT <- file.path(GD, "phase1"); dir.create(OUT, showWarnings = FALSE)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)   # the registry's SSP2 pair (PITFALLS.md 34)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
modelDir <- rc$modelDir %||% "output/pfm/fit-cache"
`%||%` <- function(a, b) if (is.null(a)) b else a

sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD)); fr <- readRDS(file.path(GD, "frontier.rds"))
panel <- loadTrainingPanel(jsonlite::read_json(file.path(GD, "manifest.json"))$panel_hash, modelDir)
pAll <- panel[, , setdiff(getNames(panel), grep("Policy Stringency", getNames(panel), value = TRUE))]
w <- pfmAssertSizeWeights(pfmCouplingWeights(year = 2025, scenario = "SSP2"), "donor alternatives")
map <- pfm:::.pfmResolveCountryMap("regionmapping_21_EU11.csv")
scen <- v6ScenPanel(OUT, "PkBudg1000", BASES[["PkBudg1000"]])   # built by analysis/v6/phase1.R

setup <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cf <- pfm:::.pfmNormSpec(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "satP", modelDir = modelDir,
                                                       updateIndex = FALSE, verbose = FALSE), pfm:::.pfmSpecArgs(cf)))
  sDf <- preparePanelData(data = pAll, sector = sec, actorPowerDrivers = cf$actorPowerDrivers, actorPowerIndex = cf$actorPowerIndex,
                          instQualityDrivers = cf$instQualityDrivers, controlDrivers = cf$controlDrivers,
                          regionMappingFixedEffects = NULL, driverScaling = fit$driverScaling, outcomeVar = "Policy Stringency")
  list(fit = fit, sDf = sDf, scores = fr$bySector[[sec]]$scores)
})
run <- function(sec, ...) computeDonorAssignment(setup[[sec]]$fit, setup[[sec]]$scores, setup[[sec]]$sDf,
                                                 k = 3, basisOverride = c(USA = "median"), sector = sec, ...)
base <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), run)
topDrivers <- lapply(base, function(b) names(sort(attr(b, "weights"), decreasing = TRUE)))
for (s in names(base)) {
  stored <- readRDS(file.path(GD, paste0("donor-assignment-band-", s, ".rds")))
  ok <- identical(table(base[[s]]$donorQuality), table(stored$donorQuality))
  cat(s, "default reproduces the stored assignment:", ok, "| drivers by |beta|:", paste(topDrivers[[s]], collapse = ", "), "\n")
}

alts <- list(
  "current: 9 drivers, |beta|, far <= q90" = list(),
  "top 3 drivers by |beta|" = list(top = 3), "top 4 drivers" = list(top = 4),
  "top 5 drivers" = list(top = 5), "top 6 drivers" = list(top = 6),
  "equal weights, 9 drivers" = list(weighting = "equal"),
  "far <= q95" = list(qualityQuantiles = c(0.5, 0.95)),
  "far <= max covered distance" = list(qualityQuantiles = c(0.5, 1)),
  "no 'none' class (nearest donors always)" = list(qualityQuantiles = c(0.5, Inf)))

# full-space distance of each recipient to its nearest chosen donor, in the deployed metric
fullDist <- function(sec, a) {
  b <- base[[sec]]; wv <- attr(b, "weights"); yr <- attr(b, "year")
  X <- setup[[sec]]$sDf; X <- X[X$year == yr, ]; rownames(X) <- as.character(X$region); X <- as.matrix(X[, names(wv)])
  vapply(seq_len(nrow(a)), function(i) {
    if (is.na(a$donors[i])) return(NA_real_)
    d <- strsplit(a$donors[i], ",")[[1]]
    min(sqrt(colSums(wv * (t(X[d, , drop = FALSE]) - X[a$region[i], ])^2)))
  }, numeric(1))
}
uncovW <- function(rr) sum(w[intersect(rr, names(w))], na.rm = TRUE)

uBase <- NULL; kBase <- NULL; res <- list(); regs <- list()
for (nm in names(alts)) {
  o <- alts[[nm]]
  asg <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
    args <- o; if (!is.null(args$top)) { args$drivers <- topDrivers[[sec]][seq_len(args$top)]; args$top <- NULL }
    do.call(run, c(list(sec), args))
  })
  an <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w, assignment = asg, verbose = FALSE)
  st <- computeStrengthPath(an, scen)$strength
  u <- an$region[, c("sector", "region", "u", "shareObserved", "shareDonor", "shareLowBand", "shareMedian")]
  k <- st[st$year %in% c(2050, 2100), c("sector", "year", "k")]
  if (is.null(uBase)) { uBase <- u; kBase <- k }
  for (sec in names(asg)) {
    a <- asg[[sec]]; q90full <- attr(base[[sec]], "coveredDistanceQuantiles")[[2]]
    fd <- fullDist(sec, a); don <- a$basis %in% "donor"
    m <- merge(u[u$sector == sec, c("region", "u")], uBase[uBase$sector == sec, c("region", "u")], by = "region")
    kk <- merge(k[k$sector == sec, ], kBase[kBase$sector == sec, ], by = c("sector", "year"))
    res[[paste(nm, sec)]] <- data.frame(
      alternative = nm, sector = sec, close = sum(a$donorQuality == "close"), far = sum(a$donorQuality == "far"),
      none = sum(a$donorQuality == "none"),
      donorWeightShare = uncovW(a$region[don]) / uncovW(a$region),
      fullDistOverQ90 = median(fd[don] / q90full, na.rm = TRUE),
      shareDonorsBeyondFullQ90 = mean(fd[don] > q90full, na.rm = TRUE),
      spearmanU = stats::cor(m$u.x, m$u.y, method = "spearman"), maxAbsDU = max(abs(m$u.x - m$u.y)),
      regionMostMoved = m$region[which.max(abs(m$u.x - m$u.y))],
      k2050 = kk$k.x[kk$year == 2050], k2100 = kk$k.x[kk$year == 2100], stringsAsFactors = FALSE)
    regs[[paste(nm, sec)]] <- cbind(alternative = nm, u[u$sector == sec & u$region %in% c("LAM", "MEA", "OAS", "REF", "SSA", "NES"), ])
  }
  message("[donor-alt] ", nm, " done")
}
out <- do.call(rbind, res); rownames(out) <- NULL
rg <- do.call(rbind, regs); rownames(rg) <- NULL
saveRDS(list(summary = out, regions = rg), file.path(OUT, "donor-alternatives.rds"))
options(width = 220)
num <- vapply(out, is.numeric, logical(1)); out[num] <- lapply(out[num], function(x) round(x, 3))
print(out[order(out$sector), ], row.names = FALSE)
cat("\nDonor share of each region's weight (Bulk), and u:\n")
r2 <- rg[rg$sector == "Bulk", c("alternative", "region", "shareDonor", "shareMedian", "shareLowBand", "u")]
r2[, 3:6] <- round(r2[, 3:6], 2); print(r2, row.names = FALSE)
