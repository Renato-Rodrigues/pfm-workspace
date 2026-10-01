# A real confidence band on E = S/S*, and what it does to the theta lower bound.
#
#   Rscript analysis/checks/efficiencyRatioBand.R
#
# WHY.  MODEL.md 5.3.1 sets the theta LOWER bound at "the width at which E itself is
# resolved" and quotes 0.214 / 0.153 / 0.186. Those came from
# computeThetaBounds.R:56 as implementabilityHi - implementabilityLo, i.e. the band
# on index/10 -- the S/10 measure MODEL.md 7 prohibits (PITFALLS 22). This computes
# the band on E instead.
#
# HOW.  E = S / (M * plogis(eta_F)) is a strictly DECREASING, monotone function of
# eta_F, so a confidence interval on eta_F maps to one on E by transforming the
# endpoints -- no delta method, no symmetry assumption:
#
#     se(eta_F) = sqrt(x' Sigma_beta x)          Sigma from frontier.rds$vcov
#     E_hi = S / (M * plogis(eta_F - z*se))      (lower ceiling  -> higher ratio)
#     E_lo = S / (M * plogis(eta_F + z*se))
#
# S is observed data, so it carries no sampling error here; the whole band comes
# from the frontier coefficients.
#
# SCOPE.  Estimation sample, last observed year. That is the right frame for the
# question "how well does the DATA resolve E" -- which is what the lower bound asks.
# Projecting adds driver uncertainty on top, so the projected band is WIDER: this is
# a lower bound on the lower bound.
#
# Author: Renato Rodrigues

source("analysis/_common/_loadPfm.R")
suppressWarnings(suppressMessages({library(yaml); library(sandwich)}))
source("models/pfm/R/psmSpecArgs.R")

#   Rscript analysis/checks/efficiencyRatioBand.R [group]
#
# GROUP is an ARGUMENT, not a constant (parameterised 2026-08-26, TODO 14i). It was
# hardwired to "v1" alongside a hardcoded panel path, so this script could not be run
# for a new Run-Group at all -- which is why the theta lower bound in item 14g is still
# computed from the S/10 column this script exists to replace.
args  <- commandArgs(trailingOnly = TRUE)
GROUP <- if (length(args) >= 1) args[[1]] else "v1"
Z     <- stats::qnorm(0.975)
OUT   <- file.path("output/pfm", GROUP, "efficiency-ratio-band.rds")

# Resolved from the group's OWN manifest panel_hash; never a hardcoded path.
panel <- .panelForGroup(GROUP)
fr    <- readRDS(file.path("output/pfm", GROUP, "frontier.rds"))
sel   <- yaml::read_yaml(file.path("output/pfm", GROUP, "selected-models-psm.yml"))
norm  <- function(s) {
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
    if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]])
  s
}

out <- list(group = GROUP, z = Z, generated = Sys.time())
for (sec in c("Bulk", "Diffuse")) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)),
                     sel)[[1]])
  fit <- do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sec, estimator = "frontier", indexMax = 10,
         modelDir = NULL, verbose = FALSE), .psmSpecArgs(cfg)))

  mm   <- stats::model.matrix(stats::as.formula(fit$formula), data = fit$data)
  beta <- stats::coef(fit$model)[colnames(mm)]
  eta  <- as.numeric(mm %*% beta)

  V <- fr$bySector[[sec]]$vcov
  keep <- intersect(colnames(mm), rownames(V))
  stopifnot(length(keep) == ncol(mm))              # design and vcov must align exactly
  Vb <- V[keep, keep, drop = FALSE]
  se <- sqrt(pmax(rowSums((mm[, keep, drop = FALSE] %*% Vb) * mm[, keep, drop = FALSE]), 0))

  # NOTE (2026-08-26, TODO 14f): before that date `fr$bySector[[sec]]$vcov` could not be
  # trusted -- FRONTIER 4.1 returned a matrix 14.8x too large for v4 Bulk, which would
  # have made the band below ~15x too wide and the theta lower bound meaningless. It is
  # now recomputed from the likelihood's own Hessian and the artifact records the check
  # on `fr$bySector[[sec]]$vcovCheck`. An artifact with NO vcovCheck field predates the
  # fix and is UNCHECKED -- run analysis/checks/frontierSECheck.R on it before trusting this.
  #
  # The SFA vcov is the ML one -- there is no clustered sandwich for the SFA
  # likelihood (estimatePolicyStringencyModel.R:457). With 48 country clusters over
  # 22 years that understates the band. Measure the panel's own design effect on the
  # SAME design via the satP mean regression, where a clustered sandwich does exist.
  mfit <- do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sec, estimator = "satP", indexMax = 10,
         modelDir = NULL, verbose = FALSE), .psmSpecArgs(cfg)))
  nse <- sqrt(diag(stats::vcov(mfit$model)))
  cse <- sqrt(diag(sandwich::vcovCL(mfit$model, cluster = mfit$data$region)))
  cmn <- intersect(names(nse), names(cse))
  designEffect <- stats::median(cse[cmn] / nse[cmn])

  obs <- as.numeric(fit$outcomeNatural[rownames(mm)])
  ceilAt <- function(e) 10 * stats::plogis(e)
  Emid <- pmin(obs / pmax(ceilAt(eta), 1e-9), 1)
  Ehi  <- pmin(obs / pmax(ceilAt(eta - Z * se), 1e-9), 1)
  Elo  <- pmin(obs / pmax(ceilAt(eta + Z * se), 1e-9), 1)
  EhiC <- pmin(obs / pmax(ceilAt(eta - Z * se * designEffect), 1e-9), 1)
  EloC <- pmin(obs / pmax(ceilAt(eta + Z * se * designEffect), 1e-9), 1)

  d <- data.frame(region = fit$data[rownames(mm), "region"],
                  year = fit$data[rownames(mm), "year"],
                  E = Emid, Elo = Elo, Ehi = Ehi, EloC = EloC, EhiC = EhiC, seEta = se,
                  stringsAsFactors = FALSE)
  last <- d[d$year == max(d$year), ]
  out$bySector[[sec]] <- list(
    all = d, year = max(d$year),
    designEffect = designEffect,
    medianWidth = stats::median(last$Ehi - last$Elo),
    medianWidthClustered = stats::median(last$EhiC - last$EloC),
    meanWidth = mean(last$Ehi - last$Elo),
    medianSeEta = stats::median(last$seEta),
    saturatedHi = sum(last$Ehi >= 1 - 1e-9))
}

widths <- vapply(out$bySector, function(x) x$medianWidth, numeric(1))
pooled <- stats::median(unlist(lapply(out$bySector, function(x) {
  l <- x$all[x$all$year == x$year, ]; l$Ehi - l$Elo })))
pooledC <- stats::median(unlist(lapply(out$bySector, function(x) {
  l <- x$all[x$all$year == x$year, ]; l$EhiC - l$EloC })))
out$pooledMedianWidth <- pooled
out$pooledMedianWidthClustered <- pooledC
saveRDS(out, OUT)

cat("\n===== 95% CI WIDTH ON E = S/S*  (estimation sample, last year) =====\n")
for (sec in names(out$bySector)) {
  x <- out$bySector[[sec]]
  cat(sprintf("%-8s year %d   ML width = %.3f   design effect = %.2f   CLUSTER-SCALED = %.3f\n",
              sec, x$year, x$medianWidth, x$designEffect, x$medianWidthClustered))
}
cat(sprintf("\npooled median width on E : ML %.3f   cluster-scaled %.3f\n", pooled, pooledC))
cat(  "quoted in MODEL.md 5.3.1 (on S/10) : 0.214 Bulk / 0.153 Diffuse / 0.186 pooled\n")
# The upper bound is READ FROM THE GROUP, not hard-coded. It was pinned at 0.135 -- a
# `v1` number -- which silently mis-stated the verdict for any other Run-Group: on `v4`
# the bound is 0.1717, and the empty/non-empty answer turns on exactly that difference.
source("analysis/checks/computeThetaBounds.R")
tb <- computeThetaBounds(group = GROUP, verbose = FALSE)
thetaMax <- tb$thetaMax
cat(sprintf("\ntheta upper bound (revealed preference, read from %s) : %.4f\n", GROUP, thetaMax))
cat(sprintf("=> [%.3f, %.3f] %s   (ML band -- understates)\n", pooled, thetaMax,
            if (pooled > thetaMax) "EMPTY" else "NON-EMPTY"))
cat(sprintf("=> [%.3f, %.3f] %s   (cluster-scaled -- the one to quote)\n", pooledC, thetaMax,
            if (pooledC > thetaMax) "EMPTY" else "NON-EMPTY"))
# tb$thetaMin IS this band once TODO 1d-i repointed computeThetaBounds at it, so printing
# it here would just echo `pooledC` under an S/10 label. The prohibited figure is kept
# separately as tb$thetaMinS10 -- that is the one worth contrasting against.
if (is.finite(tb$thetaMinS10)) {
  cat(sprintf("   the prohibited S/10 bound, for contrast only: %.4f -> would report %s\n",
              tb$thetaMinS10, if (tb$thetaMinS10 > thetaMax) "EMPTY" else "non-empty"))
}
cat("\nwritten: ", OUT, "\n", sep = "")
