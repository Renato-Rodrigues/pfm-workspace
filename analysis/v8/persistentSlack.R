# v8 test 2 (design note 0009 section 4.1): does the data say how long a country's distance below its ceiling lasts?
#   Rscript analysis/v8/persistentSlack.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-persistent-slack.rds
# The coupling's largest sensitivity is the persistence of the political limit, declared (erosion kappa 2-5% a year,
# the constant limit, the growing limit). Three readings of the estimation panel, on the selected specification:
#   A. Four-component frontier (Kumbhakar, Lien & Hardaker 2014, multi-step): logit stringency = X b + a_i + e_it with
#      a_i = c + w_i - eta_i (country heterogeneity w, persistent slack eta >= 0) and e_it = c' + v_it - u_it (noise v,
#      transient slack u >= 0). Step 1 a random-intercept regression (lme4) on the frontier's own design; steps 2-3 a
#      half-normal frontier on the country effects and on the residuals; eta and u by Jondrow et al. (1982).
#      Reported: the persistent share of mean slack, and the yearly persistence of u (its within-country AR(1)).
#   B. The gaps themselves: g = 1 - E (the v7 frontier's efficiency ratios, frontier.rds). The yearly rate at which a
#      country's gap relative to the year's cross-country mean shrinks (AR(1) of the demeaned gap at a 5-year lag,
#      as a rate), and the drift of the median gap.
#   C. The time-decay frontier (Battese & Coelli 1992) of the robustness battery: eta, gamma, and the agreement of its
#      slack ranking with the headline's.
#   D. The counterpart of kappa, which erodes the strength k (MODEL.md section 5.2a): how fast the spread of the gaps
#      across countries, and across the EU21 regions (final-energy weights, covered countries), shrank: the slope of
#      log sd(gap) on the year, 2008-2023 and 2013-2023; and the rank persistence of the gaps.
# Read against the coupling: the declared ladder's share of the 2023 limit left in 2050 and 2100.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g)
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
fr <- readRDS(file.path(GD, "frontier.rds"))$bySector

# half-normal frontier y = mu + v - u on one series (no regressors), by maximum likelihood; JLMS E[u | e]
sfaHN <- function(y) {
  nll <- function(p) { mu <- p[1]; sv <- exp(p[2]); su <- exp(p[3]); s <- sqrt(sv^2 + su^2); lam <- su / sv; e <- y - mu
    -sum(log(2) - log(s) + stats::dnorm(e / s, log = TRUE) + stats::pnorm(-e * lam / s, log.p = TRUE)) }
  st <- c(mean(y) + stats::sd(y) * 0.8, log(stats::sd(y) * 0.6), log(stats::sd(y) * 0.8))
  o <- stats::optim(st, nll, method = "BFGS", control = list(maxit = 2000))
  mu <- o$par[1]; sv <- exp(o$par[2]); su <- exp(o$par[3]); s2 <- sv^2 + su^2; e <- y - mu
  ss <- sqrt(su^2 * sv^2 / s2); m <- -e * su^2 / s2
  u <- m + ss * stats::dnorm(m / ss) / stats::pnorm(m / ss)
  list(mu = mu, sigmaV = sv, sigmaU = su, gamma = su^2 / s2, u = u, logLik = -o$value,
       skew = mean((y - mean(y))^3) / stats::sd(y)^3, converged = o$convergence == 0)
}
ar1 <- function(df, lag) {   # pooled within-country AR coefficient of x at `lag` years, as a yearly rate
  d <- merge(df, transform(df, year = year + lag), by = c("region", "year"), suffixes = c("", ".lag"))
  d <- d[is.finite(d$x) & is.finite(d$x.lag), ]
  rho <- unname(stats::coef(stats::lm(x ~ x.lag - 1, d))[1])
  c(rho = rho, rate = -log(max(rho, 1e-6)) / lag, n = nrow(d))
}

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfg)))))
  d <- ff$data; X <- stats::model.matrix(ff$formula, d); y <- stats::model.response(stats::model.frame(ff$formula, d))
  X <- X[, colnames(X) != "(Intercept)", drop = FALSE]; X <- X[, apply(X, 2, stats::var) > 0, drop = FALSE]
  # A. four components
  re <- lme4::lmer(y ~ X + (1 | region), data = data.frame(y = y, region = d$region), REML = FALSE)
  a <- lme4::ranef(re)$region[, 1]; names(a) <- rownames(lme4::ranef(re)$region)
  e <- stats::residuals(re)
  pA <- sfaHN(a); pE <- sfaHN(e)
  tr <- data.frame(region = as.character(d$region), year = d$year, x = pE$u)
  uAR <- rbind(lag1 = ar1(tr, 1), lag5 = ar1(tr, 5))
  four <- data.frame(sector = sec, varCountry = stats::var(a), varResid = stats::var(e), skewCountry = pA$skew, skewResid = pE$skew,
                     gammaPersistent = pA$gamma, gammaTransient = pE$gamma, meanPersistent = mean(pA$u), meanTransient = mean(pE$u),
                     persistentShare = mean(pA$u) / (mean(pA$u) + mean(pE$u)), uAR1 = uAR["lag1", "rho"], uRate1 = uAR["lag1", "rate"],
                     uAR5 = uAR["lag5", "rho"], uRate5 = uAR["lag5", "rate"])
  # B. the gaps
  sc <- fr[[sec]]$scores; sc <- sc[is.finite(sc$efficiencyRatio), ]
  sc$gap <- 1 - sc$efficiencyRatio
  sc$rel <- sc$gap - stats::ave(sc$gap, sc$year)
  rel <- ar1(data.frame(region = sc$region, year = sc$year, x = sc$rel), 5)
  rel10 <- ar1(data.frame(region = sc$region, year = sc$year, x = sc$rel), 10)
  late <- sc[sc$year >= 2010, ]
  med <- tapply(late$gap, late$year, stats::median)
  drift <- unname(stats::coef(stats::lm(log(med) ~ as.numeric(names(med))))[2])
  gaps <- data.frame(sector = sec, relAR5 = rel[["rho"]], relRate5 = rel[["rate"]], relAR10 = rel10[["rho"]], relRate10 = rel10[["rate"]],
                     medianGap2010 = med[["2010"]], medianGap2023 = med[["2023"]], medianGapDrift = -drift)
  # D. the spread of the gaps, countries and regions
  map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"); rmap <- stats::setNames(map$RegionCode, map$CountryCode)
  wt <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
  s8 <- sc[sc$year >= 2008, ]; s8$r <- rmap[s8$region]; s8$w <- wt[s8$region]
  rg <- stats::aggregate(cbind(gw = gap * w, w) ~ r + year, s8, sum); rg$gap <- rg$gw / rg$w
  rate <- function(x, from) { v <- tapply(x$gap[x$year >= from], x$year[x$year >= from], stats::sd)
    -unname(stats::coef(stats::lm(log(v) ~ as.numeric(names(v))))[2]) }
  rk <- function(x, idv, a, b) { W <- stats::reshape(x[, c(idv, "year", "gap")], idvar = idv, timevar = "year", direction = "wide")
    stats::cor(W[[paste0("gap.", a)]], W[[paste0("gap.", b)]], method = "spearman", use = "complete.obs") }
  spread <- data.frame(sector = sec, sdCountry2008 = stats::sd(s8$gap[s8$year == 2008]), sdCountry2023 = stats::sd(s8$gap[s8$year == 2023]),
                       rateCountry0823 = rate(s8, 2008), rateCountry1323 = rate(s8, 2013),
                       sdRegion2008 = stats::sd(rg$gap[rg$year == 2008]), sdRegion2023 = stats::sd(rg$gap[rg$year == 2023]),
                       rateRegion0823 = rate(rg, 2008), rateRegion1323 = rate(rg, 2013),
                       rankCountry1323 = rk(s8, "region", 2013, 2023), rankRegion1323 = rk(rg, "r", 2013, 2023), rankRegion1823 = rk(rg, "r", 2018, 2023))
  # persistent slack against the headline's 2023 gap
  pc <- data.frame(region = names(a), eta = pA$u)
  g23 <- sc[sc$year == 2023, c("region", "gap")]; m <- merge(pc, g23)
  # C. the decay frontier (robustness battery)
  bc <- fr[[sec]]$robustness
  list(four = four, gaps = gaps, spread = spread, persistentByCountry = m[order(-m$eta), ],
       spearmanEtaGap = stats::cor(m$eta, m$gap, method = "spearman"), robustness = bc)
})
four <- do.call(rbind, lapply(res, `[[`, "four")); gaps <- do.call(rbind, lapply(res, `[[`, "gaps")); spread <- do.call(rbind, lapply(res, `[[`, "spread"))
# what each reading implies for the share of today's limit left, against the declared ladder
yrs <- c(2050, 2100)
ladder <- rbind(`erosion 5%` = exp(-0.05 * (yrs - 2023)), `erosion 2.7%` = exp(-0.027 * (yrs - 2023)),
                `erosion 2%` = exp(-0.02 * (yrs - 2023)), `constant limit` = c(1, 1))
emp <- do.call(rbind, lapply(names(res), function(sec) { f <- four[four$sector == sec, ]; gp <- gaps[gaps$sector == sec, ]
  rbind(stats::setNames(f$persistentShare + (1 - f$persistentShare) * exp(-f$uRate5 * (yrs - 2023)), yrs),
        stats::setNames(exp(-gp$relRate5 * (yrs - 2023)), yrs),
        stats::setNames(exp(-gp$relRate10 * (yrs - 2023)), yrs),
        stats::setNames(exp(-spread$rateCountry1323[spread$sector == sec] * (yrs - 2023)), yrs),
        stats::setNames(exp(-spread$rateRegion1323[spread$sector == sec] * (yrs - 2023)), yrs)) |>
    `rownames<-`(paste(sec, c("four-component (persistent + decaying transient)", "relative gap, 5-year AR", "relative gap, 10-year AR",
                              "spread of country gaps, 2013-2023 rate", "spread of regional gaps, 2013-2023 rate"))) }))
colnames(ladder) <- yrs
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), four = four, gaps = gaps, spread = spread, ladder = ladder, implied = emp,
             bySector = res), file.path(GD, "v8-persistent-slack.rds"))
options(width = 220)
cat("=== A. four components ===\n"); print(four, digits = 3, row.names = FALSE)
cat("\n=== B. gaps ===\n"); print(gaps, digits = 3, row.names = FALSE)
for (s in names(res)) { cat("\n", s, ": Spearman(persistent eta, 2023 gap) =", round(res[[s]]$spearmanEtaGap, 2), "; top persistent:\n")
  print(utils::head(res[[s]]$persistentByCountry, 8), digits = 2, row.names = FALSE) }
cat("\n=== C. decay frontier (robustness) ===\n"); str(lapply(res, function(r) r$robustness), max.level = 3)
cat("\n=== share of the 2023 limit left ===\n"); print(round(rbind(ladder, emp), 2))
