# Propagate the SFA robustness rungs through to the feasibility share phi.
#
#   Rscript analysis/checks/propagateFrontierRungsToPhi.R
#
# WHY.  frontier.rds stores each rung's gamma and its `slackRankCor` -- the
# Spearman correlation of each rung's mean ABSOLUTE slack against the headline.
# That is not the quantity the coupling consumes.  The coupling consumes
# E = observed / ceiling, then g = 1 - E, then a min-max position across regions.
# E depends on the fitted CEILING only; the Jondrow slack decomposition -- the
# part the gamma-boundary caveat is about -- never enters it.  So the published
# 0.154 does not answer "does the gamma rung choice move phi".  This script does.
#
# WHAT IT DOES.  For each rung: refit, rebuild the ceiling from that rung's own
# coefficients on its own design, form E per covered country at the seed year,
# aggregate to EU21 regions, min-max, phi = 1 - theta*u.  Then compare against
# the headline rung.
#
# THE ONE THING HELD FIXED, AND WHY.  pfmCouplingWeights() needs IEA energy
# balances, which are not on the workstation, so the exact final-energy weights
# cannot be rebuilt offline.  The weighting step is IDENTICAL across rungs, so it
# cannot by itself create rank instability -- but it does decide which countries
# dominate a region.  The script therefore BRACKETS it: every statistic is
# reported under equal weights and under GDP weights (in the panel).  If the two
# agree, the conclusion does not depend on the weights we could not rebuild.
#
# Author: Renato Rodrigues

suppressWarnings(suppressMessages({
  library(yaml); library(magclass); library(frontier); library(plm)
}))

# Prefer the SOURCE TREE over the installed library — see analysis/_common/_loadPfm.R and
# PITFALLS 23. This script is where that trap was found: `library(pfm)` resolved to
# an installed 0.3.0 while the tree was 0.4.0, and the run died on a bug already
# fixed in source.
source("analysis/_common/_loadPfm.R")

#   Rscript analysis/checks/propagateFrontierRungsToPhi.R [group] [seedYear]
#
# GROUP is an ARGUMENT, not a constant (parameterised 2026-08-25). It was hard-wired
# to "v1" together with a hard-wired panel path, so re-running it for a new Run-Group
# silently mixed one group's selected spec with another group's panel. The panel is
# now resolved from the group's OWN manifest.json panel_hash, and the script stops if
# that file is absent rather than falling back to whatever is on disk.
args      <- commandArgs(trailingOnly = TRUE)
GROUP     <- if (length(args) >= 1) args[[1]] else "v1"
SEED_YEAR <- if (length(args) >= 2) as.integer(args[[2]]) else 2022
THETA     <- 0.50          # the deployed severity dial
MAPPINGS  <- c(EU21 = "models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv",
               H12  = "models/mrpfm/inst/extdata/regional/regionmappingH12.csv")
OUT       <- file.path("output/pfm", GROUP, "frontier-rung-phi.rds")

.panelForGroup <- function(group) {
  mf <- file.path("output/pfm", group, "manifest.json")
  if (!file.exists(mf)) {
    stop("no manifest.json for Run-Group '", group, "' - cannot identify its panel. ",
         "Never fall back to output/pfm/fit-cache/panels/<any>.rds: pairing one group's spec with ",
         "another group's panel produces numbers that look fine and are wrong.")
  }
  h <- jsonlite::fromJSON(mf)$panel_hash
  if (is.null(h) || !nzchar(h)) stop("manifest.json for '", group, "' records no panel_hash.")
  p <- file.path("output/pfm/fit-cache", "panels", paste0("panel_", h, ".rds"))
  if (!file.exists(p)) {
    stop("Run-Group '", group, "' was fitted on panel ", h, ", which is NOT on this machine ",
         "(looked for ", p, "). Run this on the cluster, where the Fit Cache lives. ",
         "Do NOT substitute another panel.")
  }
  message("[rung-phi] group ", group, " -> panel ", h)
  readRDS(p)
}

# .pfmSpecArgs comes from the source tree loaded above; source() it only if we
# fell back to an installed build old enough to lack it.
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---------------------------------------------------------------------------
# 1. the deployed fit, per sector
# ---------------------------------------------------------------------------
panel <- .panelForGroup(GROUP)
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(file.path("output/pfm", GROUP)))
norm <- function(s) {
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
    if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]])
  s
}
fitSector <- function(sec) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sec, estimator = "frontier", indexMax = 10,
         modelDir = NULL, verbose = FALSE), .pfmSpecArgs(cfg)))
}

# ---------------------------------------------------------------------------
# 2. the ceiling, and hence E, under an arbitrary rung
# ---------------------------------------------------------------------------
# Same construction as computeFeasibilityFrontier(), but driven by a supplied
# coefficient vector and formula so it can be pointed at any rung. Note E uses
# ONLY the ceiling: no Jondrow term, so nothing here depends on gamma.
ceilingE <- function(fit, beta, fml, indexMax = 10) {
  df <- fit$data
  mm <- stats::model.matrix(stats::as.formula(fml), data = df)
  keep <- intersect(colnames(mm), names(beta))
  if (length(keep) < ncol(mm)) {
    warning("rung is missing ", ncol(mm) - length(keep), " design column(s); dropped")
    mm <- mm[, keep, drop = FALSE]
  }
  etaF <- as.numeric(mm %*% beta[colnames(mm)])
  obs <- fit$outcomeNatural
  obsRows <- as.numeric(obs[rownames(mm)])
  ceil <- indexMax * stats::plogis(etaF)
  data.frame(region = as.character(df[rownames(mm), "region"]),
             year = df[rownames(mm), "year"],
             observedIndex = obsRows,
             ceilingIndex = ceil,
             E = pmin(pmax(obsRows / pmax(ceil, 1e-9), 0), 1),
             stringsAsFactors = FALSE, row.names = NULL)
}

rungScores <- function(fit) {
  df  <- fit$data
  fml <- stats::as.formula(fit$formula)
  fmlNoFE <- if ("regionFE" %in% all.vars(fml)) stats::update(fml, . ~ . - regionFE) else fml
  pd <- { d <- df; d$region <- as.character(d$region); plm::pdata.frame(d, index = c("region", "year")) }

  res <- list()
  res$headline <- list(E = ceilingE(fit, stats::coef(fit$model), fml),
                       gamma = fit$frontierGamma, fml = fml)
  tryRung <- function(nm, f, fmlUse) {
    ok <- tryCatch({
      b <- stats::coef(f)
      list(E = ceilingE(fit, b, fmlUse), gamma = as.numeric(b[["gamma"]]), fml = fmlUse)
    }, error = function(e) list(error = conditionMessage(e)))
    res[[nm]] <<- ok
  }
  tryRung("truncnorm", frontier::sfa(fml, data = df, truncNorm = TRUE), fml)
  tryRung("panel",     frontier::sfa(fmlNoFE, data = pd), fmlNoFE)
  tryRung("decay",     frontier::sfa(fmlNoFE, data = pd, timeEffect = TRUE), fmlNoFE)
  res
}

# ---------------------------------------------------------------------------
# 3. country E -> region phi
# ---------------------------------------------------------------------------
readMap <- function(path) {
  m <- utils::read.csv(path, sep = ";", stringsAsFactors = FALSE)
  stats::setNames(as.character(m[["RegionCode"]]), as.character(m[["CountryCode"]]))
}
MAPS <- lapply(MAPPINGS, readMap)

gdpW <- {
  g <- panel[, paste0("y", SEED_YEAR), "GDP"]
  stats::setNames(as.numeric(g), magclass::getRegions(panel))
}

phiFromE <- function(Edf, weights = c("equal", "gdp"), theta = THETA, res = "EU21") {
  weights <- match.arg(weights)
  d <- Edf[Edf$year == SEED_YEAR, ]
  d$reg <- MAPS[[res]][d$region]
  d <- d[!is.na(d$reg), ]
  d$w <- if (weights == "equal") 1 else pmax(gdpW[d$region], 0)
  agg <- stats::aggregate(cbind(num = d$E * d$w, den = d$w), by = list(reg = d$reg), sum)
  Er <- stats::setNames(agg$num / agg$den, agg$reg)
  g <- 1 - Er
  u <- (g - min(g)) / (max(g) - min(g))
  1 - theta * u
}

compare <- function(a, b) {
  common <- intersect(names(a), names(b))
  a <- a[common]; b <- b[common]
  list(n = length(common),
       spearman = suppressWarnings(stats::cor(a, b, method = "spearman")),
       medAbsD = stats::median(abs(a - b)),
       maxAbsD = max(abs(a - b)),
       maxAt = common[which.max(abs(a - b))],
       medRankShift = stats::median(abs(rank(-a) - rank(-b))))
}

# ---------------------------------------------------------------------------
# 3b. RANK INTERVALS, not point ranks  (added 2026-08-25)
# ---------------------------------------------------------------------------
# MODEL.md 3.4 forbids publishing a country-level slack ORDER because the rungs
# reorder it. The reason a point rank is indefensible is that it hides how much
# of the ordering is rung choice; the fix is to stop reporting a point.
#
# Each rung is a defensible estimate, so the set of ranks a unit takes ACROSS the
# rungs is a legitimate interval for its position. This is a range over four
# fitted models, NOT a sampling confidence interval -- do not call it one, and do
# not attach a coverage probability to it.
#
# `stable` is the honest headline: units whose interval does not overlap the
# median unit's interval are separated by more than the rung choice explains.
rankIntervals <- function(byRung, decreasing = TRUE) {
  byRung <- Filter(function(v) is.numeric(v) && length(v), byRung)
  if (length(byRung) < 2) return(NULL)
  common <- Reduce(intersect, lapply(byRung, names))
  if (!length(common)) return(NULL)
  R <- vapply(byRung, function(v) rank(if (decreasing) -v[common] else v[common]),
              numeric(length(common)))
  R <- matrix(R, nrow = length(common), dimnames = list(common, names(byRung)))
  out <- data.frame(
    unit      = common,
    rankLo    = apply(R, 1, min),
    rankMed   = apply(R, 1, stats::median),
    rankHi    = apply(R, 1, max),
    valueLo   = vapply(common, function(k) min(vapply(byRung, function(v) v[[k]], 0)), 0),
    valueHi   = vapply(common, function(k) max(vapply(byRung, function(v) v[[k]], 0)), 0),
    stringsAsFactors = FALSE, row.names = NULL)
  out$rankWidth <- out$rankHi - out$rankLo
  out$valueWidth <- out$valueHi - out$valueLo
  # A unit is "separable" if its whole rank interval sits clear of the middle of
  # the field -- i.e. the rungs agree it is in the top or bottom half.
  mid <- (length(common) + 1) / 2
  out$separable <- out$rankHi < mid | out$rankLo > mid
  out <- out[order(out$rankMed), ]
  attr(out, "nRungs") <- ncol(R)
  attr(out, "rungs") <- colnames(R)
  attr(out, "maxWidth") <- max(out$rankWidth)
  attr(out, "shareSeparable") <- mean(out$separable)
  out
}

# ---------------------------------------------------------------------------
# 4. run it
# ---------------------------------------------------------------------------
out <- list(group = GROUP, seedYear = SEED_YEAR, theta = THETA, generated = Sys.time())
for (sec in c("Bulk", "Diffuse")) {
  message("=== ", sec, " ===")
  fit <- fitSector(sec)
  sc <- rungScores(fit)
  out$bySector[[sec]]$gamma <- vapply(sc, function(x) x$gamma %||% NA_real_, numeric(1))

  # country-level E rank stability (the direct analogue of slackRankCor, but on
  # the quantity the coupling actually consumes)
  base <- sc$headline$E
  base <- stats::setNames(base$E[base$year == SEED_YEAR], base$region[base$year == SEED_YEAR])
  out$countryE_raw[[sec]] <- lapply(sc, function(x) {
    if (!is.null(x$error)) return(NULL)
    e <- x$E; stats::setNames(e$E[e$year == SEED_YEAR], e$region[e$year == SEED_YEAR])
  })
  out$bySector[[sec]]$countryE <- lapply(sc[-1], function(x) {
    if (!is.null(x$error)) return(list(error = x$error))
    e <- x$E; e <- stats::setNames(e$E[e$year == SEED_YEAR], e$region[e$year == SEED_YEAR])
    compare(base, e)
  })

  # Country-level E rank INTERVAL across rungs (see rankIntervals()).
  out$bySector[[sec]]$countryErankInterval <-
    rankIntervals(Filter(Negate(is.null), out$countryE_raw[[sec]]))

  for (res in names(MAPS)) for (wt in c("equal", "gdp")) {
    ph0 <- phiFromE(sc$headline$E, wt, res = res)
    byRung <- lapply(sc[-1], function(x) {
      if (!is.null(x$error)) return(NULL)
      phiFromE(x$E, wt, res = res)
    })
    out$bySector[[sec]]$phi[[res]][[wt]] <- list(
      headline = ph0,
      byRung = byRung,
      vsHeadline = lapply(sc[-1], function(x) {
        if (!is.null(x$error)) return(list(error = x$error))
        compare(ph0, phiFromE(x$E, wt, res = res))
      }),
      # phi rank interval over headline + rungs. This is what SCENARIOS.md and
      # any regional ordering should quote instead of a point rank.
      rankInterval = rankIntervals(c(list(headline = ph0), Filter(Negate(is.null), byRung))))
  }
}

# --- the min() rule, and WHICH SECTOR BINDS -------------------------------
# phi delivered = min(phi_Bulk, phi_Diffuse) per region. The binding sector is
# whichever side attains that min -- the quantity SCENARIOS.md 6.2a reports, and
# the claim "politics lands on households" rests on.
for (res in names(MAPS)) for (wt in c("equal", "gdp")) {
  getPhi <- function(sec, rung) {
    p <- out$bySector[[sec]]$phi[[res]][[wt]]
    if (rung == "headline") p$headline else p$byRung[[rung]]
  }
  rungs <- c("headline", "truncnorm", "panel", "decay")
  mins <- list(); binds <- list()
  for (r in rungs) {
    pb <- getPhi("Bulk", r); pd <- getPhi("Diffuse", r)
    if (is.null(pb) || is.null(pd)) next
    common <- sort(intersect(names(pb), names(pd)))
    mins[[r]]  <- pmin(pb[common], pd[common])
    binds[[r]] <- stats::setNames(ifelse(pb[common] < pd[common], "Bulk", "Diffuse"), common)
  }
  bt <- do.call(cbind, binds)                       # region x rung
  flips <- apply(bt, 1, function(v) length(unique(v)) > 1)
  out$minRule[[res]][[wt]] <- list(
    phi = mins,
    # The delivered min(phi_Bulk, phi_Diffuse) as a rank INTERVAL over the rungs.
    # This is the only phi the coupling sees, so this is the table to publish a
    # regional ordering from -- or to decline to, if the widths are large.
    rankInterval = rankIntervals(mins),
    vsHeadline = lapply(mins[setdiff(names(mins), "headline")],
                        function(m) compare(mins$headline, m)),
    bindTable = bt,
    nBulk = vapply(binds, function(v) sum(v == "Bulk"), numeric(1)),
    nRegions = nrow(bt),
    alwaysDiffuse = rownames(bt)[!flips & bt[, "headline"] == "Diffuse"],
    alwaysBulk    = rownames(bt)[!flips & bt[, "headline"] == "Bulk"],
    flips         = rownames(bt)[flips])
}

# the same question at country level, where SCENARIOS.md 6.2a starts (94% / 3)
{
  cb <- list()
  for (r in c("headline", "truncnorm", "panel", "decay")) {
    eb <- out$countryE_raw$Bulk[[r]]; ed <- out$countryE_raw$Diffuse[[r]]
    if (is.null(eb) || is.null(ed)) next
    common <- sort(intersect(names(eb), names(ed)))
    # at country level the binding sector is the one with the LARGER relative gap
    cb[[r]] <- stats::setNames(ifelse((1 - eb[common]) > (1 - ed[common]), "Bulk", "Diffuse"),
                               common)
  }
  ct <- do.call(cbind, cb)
  out$countryBind <- list(table = ct, n = nrow(ct),
                          nBulk = vapply(cb, function(v) sum(v == "Bulk"), numeric(1)),
                          flips = rownames(ct)[apply(ct, 1, function(v) length(unique(v)) > 1)])
}

saveRDS(out, OUT)

# ---------------------------------------------------------------------------
# 5. report
# ---------------------------------------------------------------------------
fmt <- function(x) if (is.null(x$spearman)) "  (failed)" else
  sprintf("  n=%2d  Spearman=%6.3f   median|d|=%.4f   max|d|=%.4f (%s)   med rank shift=%.1f",
          x$n, x$spearman, x$medAbsD, x$maxAbsD, x$maxAt, x$medRankShift)

cat("\n\n================ FRONTIER RUNGS -> phi ================\n")
cat("Run-Group ", GROUP, " | seed year ", SEED_YEAR, " | theta ", THETA, "\n", sep = "")
for (sec in c("Bulk", "Diffuse")) {
  s <- out$bySector[[sec]]
  cat("\n--- ", sec, " ---\n", sep = "")
  cat("gamma by rung: ",
      paste(sprintf("%s=%.4f", names(s$gamma), s$gamma), collapse = "  "), "\n", sep = "")
  cat("\n country-level E (48 covered countries), vs headline:\n")
  for (r in names(s$countryE)) cat(sprintf("  %-10s%s\n", r, fmt(s$countryE[[r]])))
  # s$phi is keyed [[resolution]][[weights]]. Reading it as s$phi[[wt]] returns
  # NULL, so this whole block printed NOTHING while the run still exited 0 -- the
  # artifact was correct, only the report was blind (found 2026-08-26).
  for (res in names(s$phi)) for (wt in c("equal", "gdp")) {
    cat("\n region-level phi [", res, " / ", wt, " weights], vs headline:\n", sep = "")
    for (r in names(s$phi[[res]][[wt]]$vsHeadline))
      cat(sprintf("  %-10s%s\n", r, fmt(s$phi[[res]][[wt]]$vsHeadline[[r]])))
  }
}
cat("\nwritten: ", OUT, "\n", sep = "")
