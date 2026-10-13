# The growing-limit rate (ADR 0057): the two checks the declared rate kappa = -0.005 a year rests on, neither of
# them a result of the coupled runs.
#   Rscript analysis/v6/growingLimitRate.R [group]          (repo root; default v6)
#
# 1. Bound. The share is phi = 1 - theta k u, clipped at 0; the most constrained country has u = 1 (min-max
#    normalisation), so its share reaches 0 once k = 1 / theta. The growing limit is the constant limit times
#    (1 - kappa)^(t - 2025), kappa < 0. For each candidate rate, the most constrained share in 2100 at the highest
#    declared severity (0.675), and the first year it reaches 0. k of the constant limit is read from the
#    growing-limit run itself (last coupling call, kRaw = k before the rate), so the bound is the run's own.
# 2. History. The gap below the ceiling, 1 - efficiencyRatio, 2008-2023, per country and sector (frontier.rds):
#    the yearly log trend per country, its quantiles weighted by 2025 final energy (the anchor weights), and the
#    trend of the weighted mean gap. A plausibility check on the size of the rate, not an estimate of it: an
#    estimated drift has the identification problem of lambda (ADR 0050, alternatives rejected).
#
# Writes output/pfm/<group>/coupling/growing-limit-rate.{rds,json} and prints both tables.
suppressMessages(library(jsonlite))
`%||%` <- function(a, b) if (is.null(a)) b else a
a <- commandArgs(trailingOnly = TRUE)
GROUP <- if (length(a) >= 1) a[1] else "v6"
CPL <- file.path("output/pfm", GROUP, "coupling")
THETA <- c(0.325, 0.50, 0.675)
DECLARED <- -0.005
RATES <- -seq(0.001, 0.010, by = 0.001)

# ---- 1. bound ---------------------------------------------------------------------------------------------
run <- list.files(file.path("output/remind-runs", GROUP, "EU21"), "PFMlevelBfix-backslide", full.names = TRUE)
if (length(run) != 1) stop("expected one EU21 hold-the-price growing-limit run, found ", length(run))
h <- readRDS(file.path(run, "pfm-phi-history.rds"))
last <- h[[length(h)]]
st <- last$strength
kappaRun <- last$options$kappa %||% NA
# the run's own k against the formula: k = kRaw (1 - kappa)^(t - 2025), over the horizon the rate acts on
st$kFormula <- st$kRaw * (1 - DECLARED)^(st$year - 2025)
in25 <- st$year >= 2025 & st$year <= 2100
chkK <- max(abs(st$k - st$kFormula)[in25])
# the run's most constrained regional share at theta = 0.50 against 1 - 0.5 k (a region holds several countries,
# so its minimum sits at or above the country floor)
pp <- last$phiPath
floorRun <- aggregate(phi ~ sector + year, pp, min)
floorRun <- merge(floorRun, st[, c("sector", "year", "k")])
floorRun$countryFloor <- 1 - 0.5 * floorRun$k
kE <- aggregate(kRaw ~ year, st, max)                              # the larger of the two sectors
kE <- kE[kE$year >= 2025 & kE$year <= 2100, ]
yrs <- kE$year
bound <- do.call(rbind, lapply(RATES, function(r) {
  k <- kE$kRaw * (1 - r)^(yrs - 2025)
  fl <- 1 - 0.675 * k
  data.frame(kappa = r, k2050 = k[yrs == 2050], k2100 = k[yrs == 2100],
             floor2100 = fl[yrs == 2100], zeroYear = if (any(fl <= 0)) min(yrs[fl <= 0]) else NA_real_)  # NA: not by 2100
}))
kappaMax <- -((1 / 0.675 / kE$kRaw[kE$year == 2100])^(1 / 75) - 1)

# ---- 2. history -------------------------------------------------------------------------------------------
fr <- readRDS(file.path("output/pfm", GROUP, "frontier.rds"))$bySector
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", GROUP), "EU21")$weights
wq <- function(x, ww, p) { o <- order(x); cw <- cumsum(ww[o]) / sum(ww); x[o][which(cw >= p)[1]] }
hist <- do.call(rbind, lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(s) {
  sc <- fr[[s]]$scores
  sc <- sc[sc$year >= 2008 & sc$year <= 2023, ]
  sc$g <- 1 - sc$efficiencyRatio
  sl <- sapply(split(sc, sc$region), function(d) {
    if (nrow(d) >= 8 && all(d$g > 0)) unname(coef(lm(log(g) ~ year, d))[2]) else NA
  })
  sl <- sl[is.finite(sl)]
  ww <- w[names(sl)]; ww[!is.finite(ww)] <- 0
  G <- tapply(seq_len(nrow(sc)), sc$year, function(i) {
    v <- w[sc$region[i]]; ok <- is.finite(v); sum(v[ok] * sc$g[i][ok]) / sum(v[ok])
  })
  top <- names(sort(ww, decreasing = TRUE))[1]
  xt <- names(sl) != top
  data.frame(sector = s, countries = length(sl), shareWidening = sum(ww[sl > 0]) / sum(ww),
             q25 = wq(sl, ww, 0.25), q50 = wq(sl, ww, 0.50), q75 = wq(sl, ww, 0.75), q90 = wq(sl, ww, 0.90),
             meanGapTrend = unname(coef(lm(log(G) ~ as.numeric(names(G))))[2]),
             medianUnweighted = median(sl), shareWideningUnweighted = mean(sl > 0),
             q50WithoutLargest = wq(sl[xt], ww[xt], 0.50), q90WithoutLargest = wq(sl[xt], ww[xt], 0.90),
             largestWeight = top, largestWeightShare = ww[[top]] / sum(ww), largestWeightTrend = sl[[top]])
}))
rownames(hist) <- NULL

out <- list(group = GROUP, made = format(Sys.time(), "%Y-%m-%d %H:%M"), declared = DECLARED, theta = THETA,
            run = basename(run), runKappa = kappaRun, checkK = chkK,
            runK = st[st$year %in% c(2025, 2050, 2100), c("sector", "year", "k", "kRaw")],
            runFloor = floorRun[floorRun$year %in% c(2050, 2100), ],
            kappaMax = kappaMax, bound = bound, history = hist,
            note = paste("bound: most constrained country share 1 - 0.675 k; history: d ln(1 - efficiencyRatio)/yr",
                         "2008-2023, quantiles weighted by 2025 final energy; a plausibility check, not an estimate"))
saveRDS(out, file.path(CPL, "growing-limit-rate.rds"))
write_json(out, file.path(CPL, "growing-limit-rate.json"), auto_unbox = TRUE, digits = 5, pretty = TRUE)

cat("Run", basename(run), "| kappa", kappaRun, "| max |k - kRaw (1 - kappa)^(t-2025)|", signif(chkK, 3), "\n")
print(out$runK, row.names = FALSE)
cat("\nMost constrained regional share in the run (theta 0.50) against the country floor 1 - 0.5 k:\n")
print(out$runFloor, row.names = FALSE, digits = 3)
cat("\nBound at theta = 0.675 (k of the constant limit from the run, the larger sector):\n")
print(bound, row.names = FALSE, digits = 3)
cat("Largest rate keeping the most constrained share above 0 to 2100 at theta = 0.675:", signif(kappaMax, 3), "\n")
cat("\nHistory, gap below the ceiling 2008-2023 (d ln gap / yr; quantiles weighted by final energy):\n")
print(hist, row.names = FALSE, digits = 3)
