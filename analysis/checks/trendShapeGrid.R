# Is the deployed logistic time-trend shape defensible? (TODO item 13)
#
#   Rscript analysis/checks/trendShapeGrid.R [group]
#   Rscript analysis/checks/trendShapeGrid.R v4
#
# WHY.  `createChannelConfigs()` hard-codes `logisticTimeTrend = TRUE` at one midpoint
# and one steepness, so the sweep never sees the trend shape as a choice and the
# selected specification is conditional on an unexamined constant. Item 0b showed the
# choice is consequential -- the frontier logLik spans ~400 across settings at IDENTICAL
# parameter count. This is the table item 13's "done when" asks for: either the sweep
# carries a trend grid, or the fixed choice is defended against a likelihood table. It
# computes the table; it does not re-run the sweep.
#
# WHY IT SPAWNS SUBPROCESSES.  Several trend shapes do not converge on this panel:
# `logi 2005/0.10` and `logi 2010/0.30` each ran for over five minutes on one sector
# without returning. The time is spent inside FRONTIER 4.1's Fortran grid-search, where
# R cannot interrupt: `setTimeLimit()` never fires, and `frontier::sfa`'s own `maxit`
# does not bite either (both were tried, 2026-08-26). The only cap that works is an
# OS-level one, so each fit runs in its own Rscript under `system2(timeout = )` and a
# setting that overruns is recorded as NOT ESTIMABLE -- which is a result, since a shape
# that cannot be fitted is not an admissible choice.
#
# WHAT IT REPORTS, per sector and setting:
#   logLik      frontier log-likelihood. Comparable ACROSS settings: every setting has
#               the same parameter count, the trend contributing one coefficient
#               whatever its shape.
#   gamma       item 13's guardrail. A setting that drives gamma to the boundary buys fit
#               with the degeneracy of MODEL.md 3.4 and must not be selected.
#   trendShare  var(trend contribution) / var(linear predictor) on the satP mean
#               regression -- the definition the sweep gates on
#               (runChannelsWorkflow.R:650), so comparable to `sweep.rds$results`.
#   medSE/nSig  frontier standard errors via the RECOMPUTED covariance matrix (TODO 14f).
#               Before that fix these were not comparable across settings.
#
# WHAT IT DOES NOT DO.  It holds the deployed specification fixed and varies only the
# trend, so it answers "is the constant defensible", not "would the maximin winner
# change" -- the latter needs the sweep re-run with a trend dimension.
#
# Author: Renato Rodrigues

suppressWarnings(suppressMessages({library(yaml); library(magclass); library(frontier)}))

args   <- commandArgs(trailingOnly = TRUE)
GROUP  <- if (length(args) >= 1 && !startsWith(args[[1]], "--")) args[[1]] else "v4"
WORKER <- "--worker" %in% args
TIMEOUT <- as.numeric(Sys.getenv("PFM_TREND_TIMEOUT", "120"))

# Midpoints are held INSIDE the estimation window (2000-2022), per item 13's guardrail: a
# midpoint beyond the last data year fits the curve on its convex toe alone and the
# saturation is asserted rather than estimated (item 0b). k = 0.10 is KEPT -- it is where
# the non-convergence lives, and with a hard timeout that is reportable rather than fatal.
# `linear` and `none` are reference points, not part of the logistic grid.
GRID <- c(
  list(list(id = "none",   kind = "none"),
       list(id = "linear", kind = "linear")),
  unlist(lapply(c(2005, 2010, 2015, 2020), function(mid)
    lapply(c(0.10, 0.20, 0.30), function(k)
      list(id = sprintf("logi %d/%.2f", mid, k), kind = "logistic", mid = mid, k = k))),
    recursive = FALSE))

# Each R process gets its OWN tempdir(), so the driver would never see a worker's file.
# The driver creates one directory and hands it to every worker through the environment.
ROWDIR <- Sys.getenv("PFM_TSG_DIR", "")
if (!nzchar(ROWDIR)) {
  ROWDIR <- file.path(tempdir(), "tsg-rows")
  Sys.setenv(PFM_TSG_DIR = ROWDIR)
}
dir.create(ROWDIR, recursive = TRUE, showWarnings = FALSE)

rowFile <- function(group, sector, id)
  file.path(ROWDIR, paste0("tsg-", group, "-", sector, "-",
                           gsub("[^A-Za-z0-9]", "_", id), ".rds"))

# --------------------------------------------------------------------------
# WORKER: fit exactly one (sector, setting) and write one row.
# --------------------------------------------------------------------------
if (WORKER) {
  source("analysis/_common/_loadPfm.R")
  if (!exists(".psmSpecArgs")) source("models/pfm/R/psmSpecArgs.R")
  SECTOR <- args[[which(args == "--worker") + 1L]]
  ID     <- args[[which(args == "--worker") + 2L]]
  G <- Filter(function(g) identical(g$id, ID), GRID)[[1]]

  panel <- .panelForGroup(GROUP)
  sel   <- yaml::read_yaml(file.path("output/pfm", GROUP, "selected-models-psm.yml"))
  .norm <- function(s) {
    for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
      if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]])
    s
  }
  trendArgs <- switch(G$kind,
    none     = list(logisticTimeTrend = FALSE, timeTrend = FALSE),
    linear   = list(logisticTimeTrend = FALSE, timeTrend = TRUE),
    logistic = list(logisticTimeTrend = TRUE, timeTrend = FALSE,
                    trendMidpoint = G$mid, trendSteepness = G$k))

  fitOne <- function(estimator) {
    cfg <- .norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", SECTOR)),
                        sel)[[1]])
    a <- .psmSpecArgs(cfg)
    for (n in names(trendArgs)) a[[n]] <- trendArgs[[n]]
    suppressWarnings(do.call(estimatePolicyStringencyModel, c(
      list(data = panel, sector = SECTOR, estimator = estimator, indexMax = 10,
           modelDir = NULL, verbose = FALSE), a)))
  }
  # matches runChannelsWorkflow.R:650 exactly, so comparable to sweep.rds$results
  trendShareOf <- function(fit) tryCatch({
    co <- stats::coef(fit$model)
    tn <- intersect(c("logisticTimeTrend", "timeTrend"), names(co))
    d  <- fit$data
    if (length(tn) != 1L || !is.finite(co[[tn]]) || !tn %in% names(d)) return(NA_real_)
    contrib <- co[[tn]] * as.numeric(d[[tn]])
    mm <- stats::model.matrix(stats::as.formula(fit$formula), data = d)
    sh <- intersect(colnames(mm), names(co))
    lp <- as.numeric(mm[, sh, drop = FALSE] %*% co[sh])
    v  <- stats::var(lp, na.rm = TRUE)
    if (is.finite(v) && v > 0) stats::var(contrib, na.rm = TRUE) / v else NA_real_
  }, error = function(e) NA_real_)

  ff <- fitOne("frontier")
  mf <- tryCatch(fitOne("satP"), error = function(e) NULL)
  ct <- as.data.frame(unclass(ff$coeftest)); names(ct)[1:3] <- c("est", "se", "z")
  keep <- !rownames(ct) %in% c("sigmaSq", "gamma")
  saveRDS(list(
    id = G$id, kind = G$kind, mid = G$mid, k = G$k, sector = SECTOR,
    logLik = as.numeric(stats::logLik(ff$model)), gamma = ff$frontierGamma,
    trendShare = if (is.null(mf)) NA_real_ else trendShareOf(mf),
    medSE = stats::median(ct$se[keep]), nSig = sum(abs(ct$z[keep]) > 1.96),
    nTerms = sum(keep), vcovStatus = ff$vcovCheck$status,
    converged = isTRUE(ff$converged), iter = ff$frontierIter,
    deployed = identical(G$kind, "logistic") && identical(G$mid, 2010) &&
      identical(G$k, 0.20)),
    rowFile(GROUP, SECTOR, G$id))
  quit(save = "no", status = 0)
}

# --------------------------------------------------------------------------
# DRIVER
# --------------------------------------------------------------------------
me      <- "analysis/checks/trendShapeGrid.R"
rscript <- file.path(R.home("bin"), "Rscript")
cat("=== trend-shape grid, Run-Group ", GROUP, " ===\n", sep = "")
cat("one subprocess per fit, hard timeout ", TIMEOUT,
    "s (R cannot interrupt FRONTIER's Fortran -- see the header)\n", sep = "")

fmt <- function(r, d) sprintf("%-16s %10.1f %9s %8.4f %11.3f %8.4f %4d/%-2d %8s%s\n",
  r$id, r$logLik, d, r$gamma, r$trendShare, r$medSE, r$nSig, r$nTerms,
  substr(r$vcovStatus, 1, 7),
  if (!isTRUE(r$converged)) "  <- NOT converged" else
    if (isTRUE(r$deployed)) "  <- deployed" else
      if (is.finite(r$gamma) && r$gamma >= 0.999) "  <- gamma AT BOUNDARY" else "")

out <- list(group = GROUP, generated = Sys.time(), timeout = TIMEOUT, bySector = list())
for (sector in c("Bulk", "Diffuse")) {
  cat("\n########", sector, "\n")
  cat(sprintf("%-16s %10s %9s %8s %11s %8s %7s %8s\n",
              "setting", "logLik", "dLogLik", "gamma", "trendShare", "medSE", "nSig", "vcov"))
  rows <- list(); ref <- NA_real_
  for (G in GRID) {
    f <- rowFile(GROUP, sector, G$id)
    if (file.exists(f)) unlink(f)
    t0 <- Sys.time()
    suppressWarnings(system2(rscript, c(me, GROUP, "--worker", shQuote(sector), shQuote(G$id)),
                             stdout = FALSE, stderr = FALSE, timeout = TIMEOUT))
    el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (!file.exists(f)) {
      why <- if (el >= TIMEOUT - 2) sprintf("NOT ESTIMABLE - no result within %gs", TIMEOUT)
             else sprintf("fit failed after %.0fs", el)
      cat(sprintf("%-16s  %s\n", G$id, why)); utils::flush.console()
      rows[[G$id]] <- list(id = G$id, kind = G$kind, mid = G$mid, k = G$k,
                           logLik = NA_real_, gamma = NA_real_, failed = why)
      next
    }
    r <- readRDS(f); rows[[G$id]] <- r
    if (isTRUE(r$deployed)) ref <- r$logLik
    cat(fmt(r, "")); utils::flush.console()
  }
  cat("  -- ", sector, ": ranked by fit, dLogLik vs the deployed shape --\n", sep = "")
  ok <- Filter(function(x) is.finite(x$logLik), rows)
  for (r in ok[order(-vapply(ok, function(x) x$logLik, numeric(1)))])
    cat(fmt(r, if (is.na(ref)) "-" else sprintf("%+.1f", r$logLik - ref)))
  for (r in Filter(function(x) !is.finite(x$logLik), rows))
    cat(sprintf("%-16s %10s   %s\n", r$id, "-", r$failed))
  out$bySector[[sector]] <- rows
}

o <- file.path("output/pfm", GROUP, "trend-shape-grid.rds")
saveRDS(out, o)
cat("\nwritten: ", o, "\n", sep = "")
cat("\nGUARDRAIL (item 13): a setting with gamma >= 0.999 buys fit with the boundary\n",
    "degeneracy of MODEL.md 3.4 and must not be selected, however well it fits.\n", sep = "")
