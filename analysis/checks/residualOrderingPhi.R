# GP-13(b): how much of the REGIONAL ordering the coupling consumes is the model's own prediction error?
#
#   Rscript analysis/checks/residualOrderingPhi.R [group]        # from the project root
#
# WHY. At country level the frontier shortfall tracks the mean regression's residual at Spearman
# 0.73 / 0.87 (orderingChecks.R, C42), because the frontier assigns nearly all residual variance to
# the one-sided term. The coupling does not consume that country object: it consumes a REGIONAL
# ordering, several transformations away. This script asks the regional question directly.
#
# WHAT. Two country-level ratios, pushed through the SAME offline route Fig. 3b's rank spans use
# (propagateFrontierRungsToPhi.R: seed year 2022, covered countries aggregated to EU21 regions with
# equal and with GDP weights, min-max over regions, severity 0.50):
#   deployed   E     = S / S*          observed over the frontier ceiling (what the coupling uses)
#   residual   E_res = S / S_mean      observed over the MEAN regression's fitted level, i.e. a pure
#                                      prediction-error ratio: > 1 where the model under-predicts
# If the regional orderings coincide, the regional ordering IS prediction error; the further apart,
# the more the frontier adds beyond the residual. Reported per sector, for the combined share (the
# more constrained sector, as the coupling's floor), and split by coverage: regions whose final
# energy is mostly measured versus mostly assigned in the coupled runs.
#
# LIMITS, stated. Offline and covered countries only - the coupled run also places 200 uncovered
# countries by rule from the covered countries' ratios, which this does not re-run; the tier-year
# projection is not applied (seed year 2022, as Fig. 3b). So this bounds the ordering's content at
# the seed, where the prediction-error question is posed, not the coupled phi at 2035.

args  <- commandArgs(trailingOnly = TRUE)
GROUP <- if (length(args) >= 1) args[[1]] else "v5"
GDIR  <- file.path("output/pfm", GROUP)
SEED  <- 2022; THETA <- 0.50; M <- 10
MAPF  <- "models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"

options(repos = c(CRAN = "@CRAN@", pik = "https://rse.pik-potsdam.de/r/packages"))
suppressMessages(devtools::load_all("pfm", quiet = TRUE))
`%||%` <- function(a, b) if (is.null(a)) b else a

fr <- readRDS(file.path(GDIR, "frontier.rds"))
s  <- readRDS(file.path(GDIR, "sweep.rds"))
nm <- vapply(s$specs, function(z) as.character(z$name %||% NA), character(1))
cfg <- s$specs[[which(nm == s$selected$PolicyStringency)]]
for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(cfg[[f]])) cfg[[f]] <- unlist(cfg[[f]])
panel <- pfm:::.psmHistPanel(GDIR, verbose = FALSE)
SECT <- c("Bulk", "Diffuse")

map <- utils::read.csv(MAPF, sep = ";", stringsAsFactors = FALSE)
MAP <- stats::setNames(as.character(map$RegionCode), as.character(map$CountryCode))
gdpW <- { g <- panel[, paste0("y", SEED), "GDP"]; stats::setNames(as.numeric(g), magclass::getRegions(panel)) }
cs <- readRDS(file.path(GDIR, "coupling", "coupling-summary.rds"))
cov <- stats::setNames(as.numeric(cs$tiers$inCoverageShare), as.character(cs$tiers$region))

# ---- country ratios at the seed year -----------------------------------------------------------
country <- do.call(rbind, lapply(SECT, function(sec) {
  fit <- do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sec, estimator = "satP", indexMax = M, modelDir = NULL, verbose = FALSE),
    pfm:::.psmSpecArgs(cfg)))
  fv <- stats::fitted(fit$model)                       # fitted y* (logit scale), named by row
  nd <- fit$data
  pos <- match(names(fv), rownames(nd))                # by NAME, never by position (orderingChecks.R)
  stopifnot(!anyNA(pos))
  mr <- data.frame(region = as.character(nd$region[pos]), year = nd$year[pos],
                   meanIndex = M * stats::plogis(as.numeric(fv)), stringsAsFactors = FALSE)
  sc <- fr$bySector[[sec]]$scores
  sc <- sc[sc$year == SEED, c("region", "year", "observedIndex", "frontierIndex", "efficiencyRatio")]
  d <- merge(sc, mr, by = c("region", "year"))
  d$Eres <- d$observedIndex / pmax(d$meanIndex, 1e-9)
  d$sector <- sec
  d
}))

phiFrom <- function(d, col, weights) {
  d$reg <- MAP[as.character(d$region)]
  d <- d[!is.na(d$reg) & is.finite(d[[col]]), ]
  d$w <- if (weights == "equal") 1 else pmax(gdpW[as.character(d$region)], 0)
  a <- stats::aggregate(cbind(num = d[[col]] * d$w, den = d$w), by = list(reg = d$reg), sum)
  Er <- stats::setNames(a$num / a$den, a$reg)
  g <- 1 - Er
  1 - THETA * (g - min(g)) / (max(g) - min(g))
}
cmp <- function(a, b, keep = NULL) {
  k <- intersect(names(a), names(b)); if (!is.null(keep)) k <- intersect(k, keep)
  a <- a[k]; b <- b[k]
  list(n = length(k), spearman = suppressWarnings(stats::cor(a, b, method = "spearman")),
       medAbsD = stats::median(abs(a - b)), maxAbsD = max(abs(a - b)), maxAt = k[which.max(abs(a - b))],
       medRankShift = stats::median(abs(rank(-a) - rank(-b))),
       floorA = paste(names(a)[a == min(a)], collapse = ","), floorB = paste(names(b)[b == min(b)], collapse = ","))
}

rows <- list(); phis <- list()
for (w in c("equal", "gdp")) {
  per <- lapply(stats::setNames(SECT, SECT), function(sec) {
    d <- country[country$sector == sec, ]
    list(dep = phiFrom(d, "efficiencyRatio", w), res = phiFrom(d, "Eres", w))
  })
  regs <- Reduce(intersect, lapply(per, function(p) names(p$dep)))
  comb <- list(dep = pmin(per$Bulk$dep[regs], per$Diffuse$dep[regs]),
               res = pmin(per$Bulk$res[regs], per$Diffuse$res[regs]))
  measured <- names(cov)[cov >= 0.5]; assigned <- names(cov)[cov < 0.5]
  for (what in c("Bulk", "Diffuse", "combined")) {
    p <- if (what == "combined") comb else per[[what]]
    for (sub in c("all", "measured", "assigned")) {
      keep <- switch(sub, all = NULL, measured = measured, assigned = assigned)
      v <- cmp(p$dep, p$res, keep)
      rows[[length(rows) + 1]] <- data.frame(weights = w, share = what, regions = sub, n = v$n,
        spearman = v$spearman, medAbsD = v$medAbsD, maxAbsD = v$maxAbsD, maxAt = v$maxAt,
        medRankShift = v$medRankShift, floorDeployed = v$floorA, floorResidual = v$floorB,
        stringsAsFactors = FALSE)
    }
  }
  phis[[w]] <- data.frame(region = regs, phiDeployed = comb$dep, phiResidual = comb$res,
                          coverage = cov[regs], stringsAsFactors = FALSE)
}
res <- do.call(rbind, rows)

# country-level anchor for the same comparison, so the regional numbers can be read against it
cty <- do.call(rbind, lapply(SECT, function(sec) {
  d <- country[country$sector == sec, ]
  data.frame(sector = sec, n = nrow(d),
             spearmanE_Eres = stats::cor(d$efficiencyRatio, d$Eres, method = "spearman"))
}))

cat("\nCountry level, ", SEED, " (the object C42 is about):\n", sep = ""); print(cty, row.names = FALSE, digits = 3)
cat("\nRegional ordering, EU21, severity ", THETA, ", deployed E versus prediction-error ratio:\n", sep = "")
print(res, row.names = FALSE, digits = 3)
out <- list(comparisons = res, countryLevel = cty, phi = phis, country = country,
            seedYear = SEED, theta = THETA, group = GROUP,
            note = paste("Offline, covered countries only, seed year 2022, as Fig. 3b. E_res = observed / mean-regression",
                         "fitted level. Regions split by coupled coverage (>= 0.5 of final energy measured)."))
saveRDS(out, file.path(GDIR, "residual-ordering-phi.rds"))
cat("\nwrote", file.path(GDIR, "residual-ordering-phi.rds"), "\n")
