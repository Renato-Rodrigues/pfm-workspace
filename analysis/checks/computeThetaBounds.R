# The admissible interval for theta, from Run-Group artifacts alone.
#
# theta is not identified (MODEL.md 5.3). It does not follow that it is unrestricted:
# partial identification gives an interval without claiming a point (MODEL.md 5.3.1 route 5).
#
# UPPER BOUND — revealed preference. Under mode L the cap is phi_r * P_opt. A region cannot
# credibly be modelled below the carbon price it has ALREADY legislated:
#
#     (1 - theta * u_r) * P_opt(r,t) >= P_ref(r,t)
#        =>  theta <= (1 - P_ref/P_opt) / u_r          for u_r > 0, P_opt > P_ref
#
# Two things this bound is NOT:
#   * It is not a restriction on mode R. The relative coupling
#     P* = P_ref + phi (P_opt - P_ref) satisfies P* >= P_ref by construction at any theta
#     (verified numerically below). The bound bites on the ABSOLUTE-level formulation only.
#   * It is not tight. The delivered bound also carries the speed limit lambda and sits ~5%
#     BELOW phi * P_opt, so the truly admissible theta is smaller than what this reports.
#
# u is recovered as (1 - phi)/theta_written. u is theta-INVARIANT - it is the min-max
# position of the region's gap - so this is exact regardless of which theta the artifact was
# written at, which matters because coupling-summary.rds is still written at 0.74 (TODO 1).
#
# LOWER BOUND — resolution, and it is a HEURISTIC not a theorem. u is min-max normalised to
# [0,1], so the spread theta induces in phi is exactly theta. If theta is smaller than the
# uncertainty in the efficiency ratios phi is built from, the differentiation is inside its
# own noise. Reported at country resolution; aggregation to 21 regions averages some of that
# noise away by an amount this does not attempt to quantify, so treat it as indicative.
#
# Usage, from the project root:
#   Rscript analysis/checks/computeThetaBounds.R [group]

computeThetaBounds <- function(group = "v5", outRoot = "output/pfm", minYear = 2030,
                              verbose = TRUE) {
  say <- function(...) if (isTRUE(verbose)) cat(..., "\n", sep = "")
  root <- file.path(outRoot, group)
  cs <- readRDS(file.path(root, "coupling", "coupling-summary.rds"))

  b <- cs$boundAnchor
  b$u <- (1 - b$phi) / cs$anchorTheta
  stopifnot(all(b$u >= -1e-9), all(b$u <= 1 + 1e-9))

  # Region-years where the ambitious path has not yet diverged from current policy carry
  # P_opt == P_ref exactly. There the multiplicative cap is below the reference for ANY
  # positive theta, so they cannot inform a bound - they are a statement about the
  # FORMULATION, not about theta. Reported separately.
  parity <- b[abs(b$priceOptimal - b$priceReference) <= 1e-9, ]
  d <- b[b$priceOptimal > b$priceReference + 1e-9 & b$u > 1e-8 & b$year >= minYear, ]
  d$thetaCap <- (1 - d$priceReference / d$priceOptimal) / d$u

  thetaMax <- min(d$thetaCap)
  binding  <- d[which.min(d$thetaCap), ]

  # Lower bound: how well is E resolved at all?
  #
  # READ FROM efficiency-ratio-band.rds, NOT from projection.rds$implementability
  # (TODO 1d-i, repointed 2026-08-26). The old line was
  #     median(implementabilityHi - implementabilityLo)
  # a band on `index/indexMax` -- the S/10 measure MODEL.md 7 prohibits (PITFALLS 22).
  # This is not a tidy-up: on `v4` the S/10 bound is 0.1763 against an upper bound of
  # 0.1717 and reports the admissible interval EMPTY, while the band on E is 0.154 and
  # reports it NON-EMPTY. The prohibited quantity was flipping the verdict.
  #
  # The clustered width is the one to use: there is no clustered sandwich for the SFA
  # likelihood, so the raw ML band understates it (see efficiencyRatioBand.R).
  #
  # NO FALLBACK. If the band is absent this returns NA rather than quietly reverting to
  # the S/10 column -- a wrong bound that looks like a bound is what this item is about.
  # NB it must not *stop*: efficiencyRatioBand.R calls this function for thetaMax, so a
  # hard requirement here would be circular on the first run for a new Run-Group.
  bandPath <- file.path(root, "efficiency-ratio-band.rds")
  band <- if (file.exists(bandPath)) readRDS(bandPath) else NULL
  if (is.null(band)) {
    thetaMin <- NA_real_
    ciBySector <- NULL
    thetaMinSource <- "unavailable"
  } else {
    thetaMin <- band$pooledMedianWidthClustered
    ciBySector <- vapply(band$bySector, function(x) x$medianWidthClustered, numeric(1))
    thetaMinSource <- "E-band (cluster-scaled)"
  }

  # Kept only so the two can be compared in one place, and labelled as what it is.
  # Never quote it: MODEL.md 7 prohibits the measure.
  thetaMinS10 <- tryCatch({
    pj <- readRDS(file.path(root, "projection.rds"))
    pS <- pj[pj$year == min(pj$year) & !pj$outOfCoverage, ]
    wS <- pS$implementabilityHi - pS$implementabilityLo
    stats::median(wS[is.finite(wS)])
  }, error = function(e) NA_real_)

  violated <- function(th) sort(unique(d$region[d$thetaCap < th]))

  res <- list(
    group = group, thetaWritten = cs$anchorTheta,
    thetaMax = thetaMax, thetaMin = thetaMin, thetaMinSource = thetaMinSource,
    thetaMinS10 = thetaMinS10, ciBySector = ciBySector,
    binding = binding[, c("region", "year", "u", "priceReference", "priceOptimal")],
    perRegion = d[order(d$thetaCap), c("region", "year", "u", "priceReference",
                                       "priceOptimal", "thetaCap")],
    parityRegionYears = nrow(parity), parityYears = sort(unique(parity$year)),
    # Mirrors runPSMCouplingBound()'s swept grid; 0.95/0.99 added 2026-08-25 with it
    # (TODO 14b(b)) so the violation count is reported at every severity that is
    # actually swept. Read from the artifact rather than hard-coded where possible.
    violatedAt = stats::setNames(lapply(cs$thetas[cs$thetas > 0], violated),
                                 as.character(cs$thetas[cs$thetas > 0])),
    refGdx = cs$refGdx, optGdx = cs$optGdx)

  if (isTRUE(verbose)) {
    say("theta bounds, Run-Group ", group)
    say("  upper (revealed preference, mode L, t >= ", minYear, "): ",
        sprintf("%.4f", thetaMax), "  binding: ", binding$region, " at ", binding$year)
    if (is.na(thetaMin)) {
      say("  lower (resolution heuristic): UNAVAILABLE - no efficiency-ratio-band.rds ",
          "for this group. Run:  Rscript analysis/checks/efficiencyRatioBand.R ", group)
      say("  -> interval cannot be decided without it")
    } else {
      say("  lower (resolution heuristic, median CI width on E, ", thetaMinSource, "): ",
          sprintf("%.4f", thetaMin))
      say("  -> interval is ", if (thetaMin > thetaMax) "EMPTY" else "non-empty")
    }
    if (is.finite(thetaMinS10)) {
      say("  (for reference only, NOT quotable - the prohibited S/10 band: ",
          sprintf("%.4f", thetaMinS10), " -> would report ",
          if (thetaMinS10 > thetaMax) "EMPTY" else "non-empty", ")")
    }
    for (th in names(res$violatedAt)) {
      v <- res$violatedAt[[th]]
      say("  at theta = ", th, ": ", length(v), " regions violate",
          if (length(v)) paste0(" (", paste(v, collapse = ", "), ")") else "")
    }
    say("  ", res$parityRegionYears, " region-years are at parity (P_opt == P_ref), ",
        "years ", paste(res$parityYears, collapse = ", "),
        " - no positive theta is admissible there under the multiplicative cap")
  }
  invisible(res)
}

if (!interactive() && identical(environment(), globalenv())) {
  a <- commandArgs(trailingOnly = TRUE)
  g <- if (length(a) > 0) a[1] else "v5"
  res <- computeThetaBounds(group = g)
  # Persisted so the paper's evidence bundle reads C26 from an artifact, not from a console.
  o <- file.path("output/pfm", g, "coupling", "theta-bounds.rds")
  saveRDS(res, o); cat("written:", o, "
")
}
