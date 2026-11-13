# Four offline checks of design note 0010 (section 9) on a Run-Group's fitted frontier: T5, T4, T3, T11.
#   Rscript analysis/v8/paperChecks.R [group]     (repo root; default v8) -> output/pfm/<group>/paper-checks.rds
# All four read the selected specification's frontier refitted here (the package's fit; its ceilings are checked against
# frontier.rds) and its estimation frame; none changes the Run-Group. Country bootstrap: 999 resamples of the countries.
#   T5  persistence   how long the distance below the ceiling (q, logit scale) and the ordering (the share of the ceiling used, E)
#                     lasted in the sample: cross-section regressions and rank correlations at 5, 10, 15 years, from 2008;
#                     the narrowing of the spread of the gaps; an erosion rate per year to set against the declared kappa.
#   T4  slack and the ceiling   is the logit distance independent of the ceiling (the fading limit holds q), or does it
#                     grow with it so that E stays (the constant limit holds E)? (a) within country, the change of E and of q
#                     over 5 and 10 years on the change of the ceiling eta, against what each rule predicts; (b) the
#                     heteroscedastic frontier with the slack's spread on the fitted ceiling (pfm:::.pfmHetFrontierFit).
#   T3  quantile frontier   the 0.80 / 0.90 / 0.95 conditional quantile of the response on the selected design (quantreg):
#                     a ceiling without the noise/slack split; rank correlation of country and EU21-region E with the
#                     stochastic frontier's; the fossil coefficients with a country bootstrap.
#   T11 lead and lag  long differences over the countries: the change in fossil dependence 2003-2013 on the change in
#                     stringency 2013-2023 and the reverse, controlling for initial levels (raw panel values).
source("analysis/_common/_loadPfm.R"); suppressMessages({ library(magclass); library(quantreg) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g); say <- function(...) message("[paper-checks:", g, "] ", ...)
options(pfm.panel = list(firstYear = 2000L, lastYear = 2023L, movingAverage = 5L, ieaVersion = "latest", geothermal = TRUE,
                         democracy = TRUE, overallAccountability = TRUE, fossilRents = TRUE))
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g)), forcecache = TRUE, .verbose = FALSE)
set.seed(20261110); NB <- 999L
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD)); fr <- readRDS(file.path(GD, "frontier.rds"))
SECTORS <- c(Bulk = "P&I", Diffuse = "B&T")
cfgOf <- function(sec) { hit <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers")) if (!is.null(hit[[f]])) hit[[f]] <- unlist(hit[[f]]); hit }
map <- tryCatch(pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21"), error = function(e) NULL)
mp <- tryCatch(pfm:::pfmGetMapping("regionmapping_21_EU11.csv"), error = function(e) NULL)
regionOf <- if (is.null(mp)) NULL else stats::setNames(as.character(mp$RegionCode), as.character(mp$CountryCode))
if (is.null(regionOf)) map <- NULL
boot <- function(ids, stat) { u <- unique(ids); n0 <- length(stat(u))   # a resample that cannot be fitted (a group left empty) counts as missing
  r <- replicate(NB, tryCatch(stat(sample(u, length(u), replace = TRUE)), error = function(e) rep(NA_real_, n0)))
  if (is.matrix(r)) t(apply(r, 1, stats::quantile, c(0.05, 0.95), na.rm = TRUE)) else stats::quantile(r, c(0.05, 0.95), na.rm = TRUE) }
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"))

for (sec in names(SECTORS)) {
  cfg <- cfgOf(sec)
  fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = 10, modelDir = NULL,
                                                       verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
  df <- fit$data; fml <- fit$formula; yv <- as.character(fml[[2]])
  b <- pfm:::.pfmCeilingBeta(stats::coef(fit$model))
  mf <- stats::model.frame(fml, df); X <- stats::model.matrix(fml, mf); rn <- rownames(mf)
  eta <- drop(X[, names(b), drop = FALSE] %*% b); y <- stats::model.response(mf)
  d <- data.frame(c = as.character(df[rn, "region"]), t = as.integer(df[rn, "year"]), eta = eta, y = y, q = eta - y,
                  E = stats::plogis(y) / stats::plogis(eta), stringsAsFactors = FALSE)
  # the check: these ceilings are the group's (frontier.rds scores)
  sc <- fr$bySector[[sec]]$scores; k <- match(paste(d$c, d$t), paste(sc$region, sc$year))
  dev <- max(abs(10 * stats::plogis(d$eta) - sc$frontierIndex[k]), na.rm = TRUE)
  say(sec, ": ceilings against frontier.rds, max |difference| ", signif(dev, 2), " index points"); stopifnot(dev < 1e-3)
  at <- function(v, yr) { x <- d[d$t == yr, ]; stats::setNames(x[[v]], x$c) }
  last <- max(d$t); res <- list()

  # ---- T5 persistence ----
  pers <- do.call(rbind, lapply(c(5, 10, 15), function(h) {
    y0 <- last - h; a <- at("q", y0); bq <- at("q", last); cc <- intersect(names(a), names(bq))
    e0 <- at("E", y0); e1 <- at("E", last)
    st <- function(ids) { ids <- ids[ids %in% cc]
      c(rho = unname(stats::coef(stats::lm(bq[ids] ~ a[ids]))[2]), rankE = stats::cor(e0[ids], e1[ids], method = "spearman"),
        rankQ = stats::cor(a[ids], bq[ids], method = "spearman")) }
    s0 <- st(cc); ci <- boot(cc, st)
    data.frame(sector = SECTORS[[sec]], horizon = h, from = y0, slopeQ = s0[["rho"]], slopeQ05 = ci["rho", 1], slopeQ95 = ci["rho", 2],
               erosionPerYear = 1 - max(s0[["rho"]], 0)^(1 / h), erosion05 = 1 - max(ci["rho", 2], 0)^(1 / h), erosion95 = 1 - max(ci["rho", 1], 0)^(1 / h),
               rankE = s0[["rankE"]], rankE05 = ci["rankE", 1], rankE95 = ci["rankE", 2], rankQ = s0[["rankQ"]])
  }))
  sdg <- function(yr, ids = NULL) { x <- 1 - at("E", yr); if (!is.null(ids)) x <- x[ids]; stats::sd(x) }
  cc <- intersect(names(at("E", 2008)), names(at("E", last)))
  nar <- function(ids) 1 - (sdg(last, ids) / sdg(2008, ids))^(1 / (last - 2008))
  spread <- data.frame(sector = SECTORS[[sec]], sd2008 = sdg(2008), sdLast = sdg(last), narrowingPerYear = nar(cc), t(boot(cc, nar)))
  names(spread)[5:6] <- c("p05", "p95")
  # the mean reversion of q about the cross-section mean each year (annual AR(1) of the demeaned distance, 5-year steps)
  res$persistence <- pers; res$spread <- spread

  # ---- T4 slack and the ceiling ----
  sg <- stats::plogis
  chg <- do.call(rbind, lapply(list(c(5, 2008), c(10, 2008), c(5, 2001), c(10, 2001)), function(hf) {
    h <- hf[1]; from <- max(hf[2], min(d$t)); yrs <- seq(from, last - h); x <- do.call(rbind, lapply(yrs, function(y0) { a <- d[d$t == y0, ]; z <- d[d$t == y0 + h, ]; k <- match(a$c, z$c)
      data.frame(c = a$c, dEta = z$eta[k] - a$eta, dE = z$E[k] - a$E, dq = z$q[k] - a$q,
                 dEholdQ = sg(z$eta[k] - a$q) / sg(z$eta[k]) - a$E) }))
    x <- x[stats::complete.cases(x), ]
    st <- function(ids) { w <- unlist(lapply(ids, function(i) which(x$c == i)))
      c(dE = unname(stats::coef(stats::lm(dE ~ dEta, x[w, ]))[2]), holdQ = unname(stats::coef(stats::lm(dEholdQ ~ dEta, x[w, ]))[2]),
        dq = unname(stats::coef(stats::lm(dq ~ dEta, x[w, ]))[2])) }
    s0 <- st(unique(x$c)); ci <- boot(x$c, st)
    data.frame(sector = SECTORS[[sec]], horizon = h, from = from, n = nrow(x), slopeE = s0[["dE"]], slopeE05 = ci["dE", 1], slopeE95 = ci["dE", 2],
               predictedHoldQ = s0[["holdQ"]], predictedHoldE = 0, slopeQ = s0[["dq"]], slopeQ05 = ci["dq", 1], slopeQ95 = ci["dq", 2])
  }))
  # (b) the slack's spread on the fitted ceiling: log sigma_u = c + omega * eta_std; omega = 0 under hold-q
  # on the whole sample and from 2008 (before 2008 policy is near zero and the logit distance very large)
  hetFit <- function(from) { keep <- d$t >= from
    dfh <- droplevels(df[rn[keep], , drop = FALSE]); dfh$ceilingStd__ <- as.numeric(scale(eta[keep]))
    start <- tryCatch(frontier::sfa(fml, data = dfh), error = function(e) NULL)
    het <- tryCatch(pfm:::.pfmHetFrontierFit(fml, dfh, "ceilingStd__", start), error = function(e) { say("  het fit failed: ", conditionMessage(e)); NULL })
    if (is.null(het)) return(NULL)
    cf <- stats::coef(het); V <- tryCatch(stats::vcov(het), error = function(e) NULL)
    nm <- grep("^slack_", names(cf), value = TRUE); nm <- nm[grepl("ceilingStd", nm)]
    # the omega that would keep E constant: the slope of log(the q that keeps E at its median) on the standardised ceiling
    e <- eta[keep]; qKeep <- e - stats::qlogis(pmin(pmax(stats::median(d$E[keep]) * sg(e), 1e-6), 1 - 1e-6))
    data.frame(sector = SECTORS[[sec]], from = from, n = sum(keep), omega = cf[[nm]], se = if (is.null(V)) NA else sqrt(diag(V))[[nm]],
               omegaHoldE = unname(stats::coef(stats::lm(log(qKeep) ~ dfh$ceilingStd__))[2]), omegaHoldQ = 0,
               logLikGain = as.numeric(stats::logLik(het)) - as.numeric(stats::logLik(start)),
               shareAtZero = mean(df[rn[keep], yv] <= min(df[rn, yv]) + 1e-9),
               # what the ceiling of this frontier would change: the anchor-year ordering and the fossil terms
               rankE = { bh <- pfm:::.pfmCeilingBeta(cf); bh <- bh[names(bh) %in% colnames(X)]; eh <- drop(X[, names(bh), drop = FALSE] %*% bh)
                         i <- d$t == last; stats::cor(sg(y[i]) / sg(eh[i]), d$E[i], method = "spearman") },
               fossil = cf[["Incumbent.Power"]], fossilPc = cf[["Incumbent.Power.pc"]]) }
  hetRow <- rbind(hetFit(min(d$t)), hetFit(2008))
  res$slackChange <- chg; res$slackHet <- hetRow

  # ---- T3 quantile frontier ----
  Xq <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  qf <- do.call(rbind, lapply(c(0.80, 0.90, 0.95), function(tau) {
    m <- quantreg::rq.fit(X, y, tau = tau); etaQ <- drop(X %*% m$coefficients); Eq <- pmin(sg(y) / sg(etaQ), 1)
    i <- d$t == last; cE <- stats::cor(Eq[i], d$E[i], method = "spearman")
    reg <- NA_real_
    if (!is.null(map)) { w <- map$weights; rc <- regionOf[d$c[i]]; ww <- as.numeric(w[d$c[i]])
      if (all(is.finite(ww)) && !anyNA(rc)) { agg <- function(e) tapply(e * ww, rc, sum) / tapply(ww, rc, sum)
        reg <- stats::cor(agg(Eq[i]), agg(d$E[i]), method = "spearman") } }
    st <- function(ids) { w <- unlist(lapply(ids, function(j) which(d$c == j))); quantreg::rq.fit(X[w, ], y[w], tau = tau)$coefficients[c("Incumbent.Power", "Incumbent.Power.pc")] }
    ci <- if (tau == 0.90) boot(d$c, st) else matrix(NA, 2, 2)
    data.frame(sector = SECTORS[[sec]], tau = tau, shareAbove = mean(y > etaQ), rankCountryE = cE, rankRegionE = reg,
               fossil = m$coefficients[["Incumbent.Power"]], fossil05 = ci[1, 1], fossil95 = ci[1, 2], fossilSFA = b[["Incumbent.Power"]],
               fossilPc = m$coefficients[["Incumbent.Power.pc"]], fossilPc05 = ci[2, 1], fossilPc95 = ci[2, 2], fossilPcSFA = b[["Incumbent.Power.pc"]])
  }))
  res$quantile <- qf
  out[[sec]] <- res; say(sec, " done")
}

# ---- T11 lead and lag, on the raw panel ----
ll <- NULL
tryCatch({
  for (sec in names(SECTORS)) {
    get <- function(v, yr) { x <- panel[, yr, v]; stats::setNames(as.numeric(x), magclass::getItems(x, 1)) }
    vS <- paste0("Policy Stringency|", sec); vF <- paste0("Incumbent Power|", sec)
    s0 <- get(vS, 2003); s1 <- get(vS, 2013); s2 <- get(vS, 2023); f0 <- get(vF, 2003); f1 <- get(vF, 2013); f2 <- get(vF, 2023)
    cc <- Reduce(intersect, lapply(list(s0, s1, s2, f0, f1, f2), function(x) names(x)[is.finite(x)]))
    cc <- intersect(cc, unique(as.character(fr$bySector[[sec]]$scores$region)))
    z <- function(x) as.numeric(scale(x))
    D <- data.frame(dS1 = z(s1[cc] - s0[cc]), dS2 = z(s2[cc] - s1[cc]), dF1 = z(f1[cc] - f0[cc]), dF2 = z(f2[cc] - f1[cc]), S1 = z(s1[cc]), F1 = z(f1[cc]))
    a <- summary(stats::lm(dS2 ~ dF1 + S1 + F1, D))$coefficients["dF1", ]; r <- summary(stats::lm(dF2 ~ dS1 + S1 + F1, D))$coefficients["dS1", ]
    ll <- rbind(ll, data.frame(sector = SECTORS[[sec]], n = length(cc), fossilLeadsStringency = a[1], p1 = a[4],
                               stringencyLeadsFossil = r[1], p2 = r[4], row.names = NULL))
  }
}, error = function(e) say("T11 failed: ", conditionMessage(e)))
out$leadLag <- ll
saveRDS(out, file.path(GD, "paper-checks.rds")); say("wrote ", file.path(GD, "paper-checks.rds"))
options(width = 230)
for (nm in c("persistence", "spread", "slackChange", "slackHet", "quantile")) { cat("\n==", nm, "==\n"); print(do.call(rbind, lapply(names(SECTORS), function(s) out[[s]][[nm]])), row.names = FALSE, digits = 3) }
cat("\n== lead and lag (standardised long differences, 2003-2013 on 2013-2023) ==\n"); print(ll, row.names = FALSE, digits = 3)
