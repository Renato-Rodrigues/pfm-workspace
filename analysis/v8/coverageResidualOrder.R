# The regional order with instrument coverage removed (the GMD paper's review v03, point M4; gap plan GP-45)
#   Rscript analysis/v8/coverageResidualOrder.R [group]          (repo root; default v8)
#   -> output/pfm/<group>/coupling/coverage-residual-order.rds
# The rank value u that orders the regions is built from each country's 2023 distance below its ceiling on the logit
# scale (phi-anchor.rds `country`: q = etaAnchor - yAnchor). The observed stringency is an index that rewards
# instrument breadth (CAPMF coverage), so part of a country's distance may be how many instruments it uses rather than
# how reluctant it is. Here, per sector, the 48 covered countries' q is regressed on CAPMF coverage
# (shortfall-correlates.rds, the same CAPMF file as the panel) and replaced by its residual plus the mean; countries
# without data then take the model's rule (the covered median efficiency ratio E = plogis(y) / plogis(eta), capped at
# 1), and the anchor is aggregated to the regions with the anchor's weights and rescaled min-max, as the model does.
# Check: with q unchanged the same code reproduces the deployed u.
# Reported per resolution and sector: the slope and R^2 of q on coverage, the rank correlation of the residualised u
# with the model's u, the most and least limited region under each, and the ratio of the final-energy-weighted mean u
# (the mean constraint per unit theta at k = 1) to the model's. Offline: no fit, no REMIND run; nothing changes.
source("analysis/_common/_loadPfm.R")
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g); CPL <- file.path(GD, "coupling")
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [coverage-residual:", g, "] ", ...)
sc <- readRDS(file.path(GD, "shortfall-correlates.rds"))
SECTORS <- c(Bulk = "P&I", Diffuse = "B&T")

regionU <- function(a, ctry, sec) {
  cc <- ctry[ctry$sector == sec & is.finite(ctry$q), ]
  path <- data.frame(region = cc$region, year = a$anchorYear, feasibleIndex = 10 * stats::plogis(cc$etaAnchor - cc$q),
                     ceilingIndex = 10 * stats::plogis(cc$etaAnchor), outOfCoverage = FALSE)
  agg <- suppressWarnings(aggregateFeasibilityToRegions(path, a$mapping, weights = a$weights, theta = 0.5))
  agg <- agg[is.finite(agg$relativeGap), c("region", "relativeGap")]
  rng <- range(agg$relativeGap); agg$u <- if (diff(rng) > 0) (agg$relativeGap - rng[1]) / diff(rng) else 0
  agg
}
uncoveredQ <- function(ctry, sec, qCov) {     # the model's rule: the covered median E, capped at 1
  x <- ctry[ctry$sector == sec, ]
  cov <- x$basis == "observed"
  E <- pmin(stats::plogis(x$etaAnchor[cov] - qCov) / stats::plogis(x$etaAnchor[cov]), 1)
  eMed <- stats::median(E)
  x$etaAnchor[!cov] - stats::qlogis(pmin(eMed * stats::plogis(x$etaAnchor[!cov]), 1 - 1e-12))
}

OUT <- list(); REG <- list(); FITS <- list()
for (res in c("EU21", "H12")) {
  a <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), res)
  w <- a$region[, c("sector", "region", "u", "weight")]
  for (sec in names(SECTORS)) {
    x <- a$country[a$country$sector == sec, ]; cov <- x$basis == "observed"
    d <- sc$data[sc$data$sector == sec, ]
    m <- match(x$region[cov], d$region); if (anyNA(m)) stop("no coverage for ", paste(x$region[cov][is.na(m)], collapse = ", "))
    q <- x$q[cov]; cv <- d$coverage[m]
    # the check: the model's uncovered rule rebuilds the deployed uncovered q (to the squeeze), and u is reproduced
    qUnc0 <- uncoveredQ(a$country, sec, q)
    devQ <- max(abs(qUnc0 - x$q[!cov]))
    ctry0 <- x; ctry0$q[!cov] <- qUnc0
    u0 <- regionU(a, ctry0, sec); wm <- w[w$sector == sec, ]
    devU <- max(abs(u0$u - wm$u[match(u0$region, wm$region)]))
    say(res, " ", SECTORS[[sec]], ": check, uncovered q max |diff| ", signif(devQ, 2), ", u max |diff| ", signif(devU, 2))
    stopifnot(devU < 0.02)
    # the residualised distance
    f <- stats::lm(q ~ cv); qRes <- stats::residuals(f) + mean(q)
    ctry1 <- x; ctry1$q[cov] <- qRes; ctry1$q[!cov] <- uncoveredQ(a$country, sec, qRes)
    u1 <- regionU(a, ctry1, sec)
    r <- merge(data.frame(region = u0$region, uModel = u0$u), data.frame(region = u1$region, uResidual = u1$u), by = "region")
    r$weight <- wm$weight[match(r$region, wm$region)]; r$resolution <- res; r$sector <- SECTORS[[sec]]
    r$rankModel <- rank(-r$uModel, ties.method = "min"); r$rankResidual <- rank(-r$uResidual, ties.method = "min")
    REG[[paste(res, sec)]] <- r
    FITS[[paste(res, sec)]] <- data.frame(resolution = res, sector = SECTORS[[sec]], countries = length(q), slope = unname(stats::coef(f)[2]),
                                          slopeSE = unname(sqrt(diag(stats::vcov(f)))[2]), r2 = summary(f)$r.squared, checkMaxDiffU = devU)
    wmu <- function(u) sum(r$weight * u) / sum(r$weight)
    OUT[[paste(res, sec)]] <- data.frame(resolution = res, sector = SECTORS[[sec]], regions = nrow(r),
      rankCorr = stats::cor(r$uModel, r$uResidual, method = "spearman"),
      mostLimitedModel = r$region[which.max(r$uModel)], mostLimitedResidual = r$region[which.max(r$uResidual)],
      leastLimitedModel = r$region[which.min(r$uModel)], leastLimitedResidual = r$region[which.min(r$uResidual)],
      weightedMeanUModel = wmu(r$uModel), weightedMeanUResidual = wmu(r$uResidual), ratioMeanU = wmu(r$uResidual) / wmu(r$uModel),
      stringsAsFactors = FALSE)
    say("  rank correlation ", round(OUT[[paste(res, sec)]]$rankCorr, 3), "; most limited ", OUT[[paste(res, sec)]]$mostLimitedModel,
        " -> ", OUT[[paste(res, sec)]]$mostLimitedResidual, "; mean-u ratio ", round(OUT[[paste(res, sec)]]$ratioMeanU, 3))
  }
}
S <- do.call(rbind, OUT); rownames(S) <- NULL
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), capmf = sc$capmf, year = 2023, summary = S,
            fits = do.call(rbind, FITS), regions = do.call(rbind, REG),
            note = paste("per sector, the 48 covered countries' 2023 logit distance q (phi-anchor.rds) regressed on CAPMF coverage (OLS) and",
                         "replaced by residual + mean; uncovered countries at the covered median efficiency ratio (the model's rule);",
                         "aggregated with the anchor's weights and rescaled min-max. Check: unchanged q reproduces the deployed u. Offline."))
saveRDS(out, file.path(CPL, "coverage-residual-order.rds")); say("wrote ", file.path(CPL, "coverage-residual-order.rds"))
options(width = 200); print(out$fits, row.names = FALSE, digits = 3); print(S, row.names = FALSE, digits = 3)
