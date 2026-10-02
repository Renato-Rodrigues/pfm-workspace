# Audit a Run-Group's frontier standard errors.
#
#   Rscript analysis/checks/frontierSECheck.R [group] [sector ...]
#   Rscript analysis/checks/frontierSECheck.R v4
#
# WHY.  `frontier::sfa()` wraps Coelli's FRONTIER 4.1 Fortran and reports standard
# errors from the Fortran's own covariance matrix. On 2026-08-26 that matrix was
# found to be CORRUPT for `v4` Bulk: it reported a median SE of 0.924 and 0 of 15
# significant coefficients, when the true median SE at the very same MLE is 0.062
# and 12 of 15 are significant. The point estimates were never affected. Nothing in
# the fit object flagged it — `converged` was TRUE, the log-likelihood correct, and
# the Hessian at the reported optimum negative definite and well conditioned.
# See docs/TODO.md item 14f.
#
# ✅ FIXED IN `pfm` 2026-08-26. `estimatePolicyStringencyModel()` now recomputes the
# covariance matrix through `.pfmFrontierVcov()` and records the outcome on
# `fit$vcovCheck`, so a NEW frontier fit carries trustworthy standard errors and
# says so. This script exists for the other direction:
#
#   * to AUDIT artifacts fitted before that change — every `frontier.rds` written
#     up to and including Run-Group `v4` — without re-running the pipeline;
#   * to produce `output/pfm/<group>/frontier-se-check.rds`, the record of what a given
#     group's reported standard errors were worth.
#
# It calls the same `.pfmFrontierVcov()` the estimator now uses, so there is one
# implementation of the likelihood and one of the Hessian, not two.
#
# READING IT.  `ratio` is reported / recomputed.
#   ok        -> the reported SEs were fine; quoting the old artifact is safe.
#   corrupt   -> the reported SEs are inflated garbage; use the recomputed ones,
#                and re-fit before quoting anything else from that group.
#   boundary  -> gamma is AT 1.0000. The likelihood is degenerate and NEITHER set
#                of SEs means anything — MODEL.md 3.4's "standard errors on gamma
#                are meaningless at the boundary". This is the state `v3` is in.
#                Not this bug; a different problem, and not fixable by recomputing.
#   flat      -> the likelihood really is flat; the large reported SEs are honest.
#
# Author: Renato Rodrigues

suppressWarnings(suppressMessages({
  library(yaml); library(magclass); library(frontier)
}))
source("analysis/_common/_loadPfm.R")           # also provides .panelForGroup()
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")

args    <- commandArgs(trailingOnly = TRUE)
GROUP   <- if (length(args) >= 1) args[[1]] else "v4"
SECTORS <- if (length(args) >= 2) args[-1] else c("Bulk", "Diffuse")

panel <- .panelForGroup(GROUP)
sel   <- yaml::read_yaml(pfm:::.pfmSelectedModels(file.path("output/pfm", GROUP)))

.norm <- function(s) {
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
    if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]])
  s
}

frontierSECheck <- function(sector) {
  cfg <- .norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sector)),
                      sel)[[1]])
  fit <- suppressWarnings(do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sector, estimator = "frontier", indexMax = 10,
         modelDir = NULL, verbose = FALSE), .pfmSpecArgs(cfg))))

  chk <- fit$vcovCheck
  cf  <- stats::coef(fit$model)
  X   <- stats::model.matrix(stats::as.formula(fit$formula), data = fit$data)
  b   <- cf[colnames(X)]
  # What the OLD code would have shipped, i.e. what the artifact on disk carries.
  seOld <- sqrt(pmax(diag(as.matrix(stats::vcov(fit$model)))[colnames(X)], 0))
  # What this build ships.
  seNew <- fit$coeftest[colnames(X), "Std. Error"]

  cat("\n=== ", GROUP, " / ", sector, " ===\n", sep = "")
  cat(sprintf("  gamma = %.8f   sigmaSq = %.4f   n = %d\n",
              cf[["gamma"]], cf[["sigmaSq"]], nrow(fit$data)))
  cat(sprintf("  status = %-20s source = %s\n", chk$status, chk$source))

  if (identical(chk$status, "boundary")) {
    cat("  gamma is AT the boundary -- the likelihood is degenerate and NEITHER set of\n",
        "  standard errors is interpretable (MODEL.md 3.4). Reported medSE = ",
        sprintf("%.4f", stats::median(seOld)), "; do not quote it.\n", sep = "")
    return(invisible(list(sector = sector, status = chk$status, gamma = cf[["gamma"]],
                          seReported = seOld)))
  }

  cat(sprintf("  logLik agrees (%.4f vs %.4f)\n", chk$logLikCheck, chk$logLikReported))
  cat(sprintf("  median SE  as-shipped-before %.4f   recomputed %.4f   RATIO %.2f  %s\n",
              stats::median(seOld), stats::median(seNew), chk$ratio,
              if (identical(chk$status, "corrupt")) "<-- THE OLD ARTIFACT IS WRONG" else "(ok)"))
  cat(sprintf("  significant at 5%%:  before %d/%d   now %d/%d\n",
              sum(abs(b / seOld) > 1.96), length(b),
              sum(abs(b / seNew) > 1.96), length(b)))

  out <- data.frame(term = colnames(X), estimate = as.numeric(b),
                    seReported = as.numeric(seOld), seRecomputed = as.numeric(seNew),
                    zReported = as.numeric(b / seOld), zRecomputed = as.numeric(b / seNew),
                    stringsAsFactors = FALSE, row.names = NULL)
  if (identical(chk$status, "corrupt")) { cat("\n"); print(out, row.names = FALSE, digits = 4) }
  invisible(list(sector = sector, status = chk$status, ratio = chk$ratio,
                 gamma = cf[["gamma"]], table = out))
}

res <- lapply(SECTORS, frontierSECheck)
names(res) <- SECTORS
out <- file.path("output/pfm", GROUP, "frontier-se-check.rds")
saveRDS(res, out)
cat("\nwritten: ", out, "\n", sep = "")
