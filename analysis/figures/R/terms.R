# Term naming and classification — shared, because it was duplicated and drifted.
#
# Both coefficient figures carried their own copy of a `pretty()` helper and their own
# interaction test. The interaction test was wrong in both: terms are named `A_x_B`, and
# since "_" is a word character the pattern "\\bx\\b" never matches inside `Incumbent_x_GovEff`.
# Every interaction was therefore drawn as a main effect. One definition, used everywhere.

#' Human-readable term label
pfmPrettyTerm <- function(x) {
  # NORMALISE FIRST, relabel second. The raw names carry doubled dots
  # ("GDP.per.Capita..Q.centred."), so a label replacement applied before the squeeze
  # silently fails to match - which is how two labels stayed raw in the first version.
  x <- gsub("[.][.]WGI[.]|[.][.]VDem[.]", "", x)
  x <- gsub("_x_", " @X@ ", x)        # protect the interaction marker from the dot pass
  x <- gsub("[.]", " ", x)
  x <- trimws(gsub("  +", " ", x))
  x <- gsub(" @X@ ", " × ", x)
  repl <- c(
    "logisticTimeTrend"        = "Logistic time trend",
    "regionFEOECD"             = "FE: OECD non-EU",
    "regionFEother"            = "FE: other",
    "Government Effectiveness" = "Gov. Effectiveness",
    "Horizontal Accountability"= "Horizontal Acc.",
    "Vertical Accountability"  = "Vertical Acc.",
    "Diagonal Accountability"  = "Diagonal Acc.",
    "Rule of Law"              = "Rule of Law",
    "Innovator Power"          = "Innovator",
    "Incumbent Power"          = "Incumbent",
    "GDP per Capita Q centred" = "GDP p.c. (Q-centred)",
    "Population log"           = "Population (log)",
    "Hydro Nuclear Share"      = "Hydro/nuclear share")
  for (k in names(repl)) x <- gsub(k, repl[[k]], x, fixed = TRUE)
  x
}

#' Is this term an interaction?
#'
#' `_x_` is the separator the estimator uses; ":" covers formula-style names should they
#' ever appear. Do NOT use "\\bx\\b" — "_" is a word character, so it matches nothing.
pfmIsInteraction <- function(x) grepl("_x_|:", x)

#' Is this the time trend? It is an order of magnitude larger than everything else and
#' several figures need to treat it separately.
pfmIsTrend <- function(x) grepl("TimeTrend|logistic|trend", x, ignore.case = TRUE)

#' Is this a fixed effect rather than a driver?
pfmIsFE <- function(x) grepl("^regionFE|^FE:", x)

#' Frontier coefficients for both sectors, tidied — the shared input to the two
#' coefficient figures.
pfmFrontierCoefs <- function(group, drop = c("(Intercept)", "sigmaSq", "gamma")) {
  fr <- pfmArtifact(group, "frontier.rds")
  d <- do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) {
    ct <- as.data.frame(fr$bySector[[sec]]$coefTable)
    ct <- ct[!ct$term %in% drop, ]
    data.frame(sector = sec, raw = ct$term, term = pfmPrettyTerm(ct$term),
               est = ct$estimate, se = ct$stdError, p = ct$pValue,
               kind = ifelse(pfmIsInteraction(ct$term), "interaction", "main effect"),
               trend = pfmIsTrend(ct$term), fe = pfmIsFE(ct$term),
               stringsAsFactors = FALSE)
  }))
  d$lo <- d$est - 1.96 * d$se
  d$hi <- d$est + 1.96 * d$se
  d$sig <- d$p < 0.05
  d
}

#' Put every frontier coefficient on a common footing
#'
#' The trap this closes: **the coefficients are not comparable as they stand.** Every driver
#' and interaction factor is standardized to unit SD (`MODEL.md` §2.3), but the logistic time
#' trend is a *raw* logistic in [0, 1] whose sample range is only ~0.26. A large coefficient on
#' a narrow-range regressor and a small one on a unit-SD regressor can describe identical
#' effects, so plotting them on one "per SD" axis invites exactly the wrong comparison — the
#' trend's 10.279 looks ~39x Government Effectiveness when its actual contribution is ~3x.
#'
#' This rescales to \eqn{\beta \times \mathrm{SD}(x)} — the term's contribution to the linear
#' predictor, in logits. Standardized terms are unchanged (SD = 1); the trend is multiplied by
#' its own SD and lands on scale.
#'
#' @section Where the SDs come from: since 2026-08-18 `runPSMFrontier()` persists
#'   `$bySector$<s>$support`, which carries the SD and observed range of every model-matrix
#'   column **as actually fitted**. That is authoritative and is used when present. Artifacts
#'   written before that date lack it, so the trend SD falls back to reconstruction from the
#'   estimation years and the documented curve shape — which is close but not identical
#'   (0.0796 reconstructed against 0.0778 fitted, because excluding Estonia unbalances the
#'   panel). The fallback warns; if you see that warning, re-run the frontier step.
#'
#' @param group Run-Group.
#' @param trendMidpoint,trendSteepness Fallback shape of the logistic trend, used only when the
#'   artifact carries no `support` table.
#' @return `pfmFrontierCoefs()` plus `sdX` (the regressor's SD), `estSD`, `loSD`, `hiSD`
#'   (contribution in logits) and `rangeShift` (the shift across the observed range).
pfmFrontierCoefsScaled <- function(group, trendMidpoint = 2030, trendSteepness = 0.08) {
  d <- pfmFrontierCoefs(group)
  fr <- pfmArtifact(group, "frontier.rds")
  yrs <- sort(unique(fr$bySector[[1]]$scores$year))

  # Per-sector SD and observed range, from the artifact where available.
  d$sdX <- NA_real_; d$rangeX <- NA_real_
  usedFallback <- FALSE
  for (sec in unique(d$sector)) {
    sup <- fr$bySector[[sec]]$support
    if (is.null(sup)) {
      usedFallback <- TRUE
      tr <- 1 / (1 + exp(-trendSteepness * (yrs - trendMidpoint)))
      i <- d$sector == sec
      d$sdX[i]    <- ifelse(d$trend[i], stats::sd(tr), 1)
      d$rangeX[i] <- ifelse(d$trend[i], diff(range(tr)), 2)
      next
    }
    i <- d$sector == sec
    m <- match(d$raw[i], sup$term)
    d$sdX[i]    <- sup$sd[m]
    d$rangeX[i] <- sup$max[m] - sup$min[m]
  }
  # Terms absent from the support table (sigmaSq, gamma if they survive the drop) keep SD 1
  # rather than silently becoming NA and dropping out of the figure.
  d$sdX[!is.finite(d$sdX)] <- 1
  d$rangeX[!is.finite(d$rangeX)] <- 2

  if (usedFallback) {
    warning("pfmFrontierCoefsScaled: frontier.rds carries no $support table, so the trend SD ",
            "was reconstructed rather than read. Re-run the frontier step to persist it.",
            call. = FALSE)
  }

  d$estSD <- d$est * d$sdX
  d$loSD  <- d$lo  * d$sdX
  d$hiSD  <- d$hi  * d$sdX
  d$rangeShift <- d$est * d$rangeX
  attr(d, "trendYears") <- range(yrs)
  attr(d, "sdTrend") <- d$sdX[d$trend][1]
  attr(d, "fromArtifact") <- !usedFallback
  d
}
