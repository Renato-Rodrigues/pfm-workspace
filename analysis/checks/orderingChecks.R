# Two checks on what the feasibility ORDERING actually contains.
#
# A. IS THE ORDERING THE PREDICTION ERROR, RELABELLED?  (gap-plan GP-13, referee v04 M2)
#    With the slack share of the composed error at 0.99 / 0.98, nearly all residual variance is
#    assigned to the one-sided term, so the frontier's shortfall is close to a monotone transform
#    of whatever the model fails to predict. The paper draws that consequence for the LEVEL of a
#    country's ceiling; the objection is that it never draws it for the ORDERING the coupling
#    consumes. The test: how closely does the frontier's shortfall track the mean regression's
#    residual on the same rows? If they are the same object, the paper has to say so.
#
# B. DOES THE TREND CANCEL OUT OF THE RANKING?  (gap-plan GP-15, referee v04 M4)
#    Reported from `trend-shape-phi.rds`, which already varies the one part of the trend that is a
#    modelling choice - its SHAPE - and re-derives the delivered share under each. Note what this
#    does and does not answer: it bounds the effect of choosing the shape, not the effect of the
#    trend existing. Removing the trend altogether is not an admissible comparison here, because
#    the no-trend specifications are more weakly identified and, on the demand side, not estimable.
#
# Run from the project root:  Rscript analysis/checks/orderingChecks.R
# Writes: output/pfm/v5/ordering-checks.rds

options(repos = c(CRAN = "@CRAN@", pik = "https://rse.pik-potsdam.de/r/packages"))
suppressMessages(devtools::load_all("pfm", quiet = TRUE))
`%||%` <- function(a, b) if (is.null(a)) b else a

GROUP <- "v5"; GDIR <- file.path("output/pfm", GROUP)
M <- 10

fr <- readRDS(file.path(GDIR, "frontier.rds"))
s  <- readRDS(file.path(GDIR, "sweep.rds"))
nm <- vapply(s$specs, function(z) as.character(z$name %||% NA), character(1))
cfg <- s$specs[[which(nm == s$selected$PolicyStringency)]]
for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(cfg[[f]])) cfg[[f]] <- unlist(cfg[[f]])

panel <- pfm:::.pfmHistPanel(GDIR, verbose = FALSE)
SECT <- c("Bulk", "Diffuse")
sp <- function(x, y) stats::cor(as.numeric(x), as.numeric(y), method = "spearman", use = "complete.obs")
out <- list()

# ---- A ---------------------------------------------------------------------------------------
for (sec in SECT) {
  fit <- do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sec, estimator = "satP", indexMax = M,
         modelDir = NULL, verbose = FALSE),
    pfm:::.pfmSpecArgs(cfg)))

  # The glm drops incomplete rows, so residuals are matched back to the design frame by the row
  # names the model kept, never by position - matching by position misaligns silently.
  rr  <- stats::residuals(fit$model, type = "response")
  nd  <- fit$data
  # fit$data carries its own row names (they survive from the pre-filter frame), so residuals are
  # matched by NAME. Matching by position looks right and is wrong by 48 rows.
  pos <- match(names(rr), rownames(nd))
  stopifnot(!anyNA(pos))
  resid <- data.frame(region = nd$region[pos], year = nd$year[pos],
                      resid = as.numeric(rr), stringsAsFactors = FALSE)

  sc <- fr$bySector[[sec]]$scores
  yr <- max(sc$year)
  m <- merge(sc[, c("region", "year", "slackIndex", "efficiencyRatio")], resid,
             by = c("region", "year"))
  mLast <- m[m$year == yr, ]

  cat("=== ", sec, " - A. shortfall versus prediction error =====================\n", sep = "")
  cat(sprintf("  rows compared                          : %d\n", nrow(m)))
  cat(sprintf("  Spearman(shortfall, -residual), all yrs: %+.3f\n", sp(m$slackIndex, -m$resid)))
  cat(sprintf("  Spearman(E, residual), all years       : %+.3f\n", sp(m$efficiencyRatio, m$resid)))
  cat(sprintf("  Spearman(E, residual) at %s          : %+.3f  (n = %d)\n\n",
              yr, sp(mLast$efficiencyRatio, mLast$resid), nrow(mLast)))
  out[[paste0(sec, ".A")]] <- m
}

# ---- B ---------------------------------------------------------------------------------------
tsp <- readRDS(file.path(GDIR, "trend-shape-phi.rds"))
cat("=== B. the trend's SHAPE and the delivered ordering (EU21, GDP weights) ====\n")
rows <- list()
for (w in names(tsp$vsDeployed$EU21)) {
  for (shape in names(tsp$vsDeployed$EU21[[w]])) {
    v <- tsp$vsDeployed$EU21[[w]][[shape]]
    cat(sprintf("  %-10s %-10s Spearman %+.3f  median |dphi| %.4f  max %.4f (%s)  rank shift %.1f of %d\n",
                w, shape, v$spearman, v$medAbsD, v$maxAbsD, v$maxAt, v$medRankShift, v$n))
    rows[[length(rows) + 1L]] <- data.frame(weights = w, shape = shape, spearman = v$spearman,
                                            medAbsD = v$medAbsD, maxAbsD = v$maxAbsD,
                                            maxAt = v$maxAt, medRankShift = v$medRankShift,
                                            n = v$n, stringsAsFactors = FALSE)
  }
}
out$B.trendShapes <- do.call(rbind, rows)

saveRDS(list(byPart = out, group = GROUP,
             note = paste("A: frontier shortfall vs mean-regression residual, country level.",
                          "B: delivered phi under alternative trend SHAPES, from trend-shape-phi.rds;",
                          "this bounds the effect of choosing the shape, not of the trend existing.")),
        file.path(GDIR, "ordering-checks.rds"))
cat("\nwritten:", file.path(GDIR, "ordering-checks.rds"), "\n")
