# Offline tests for a possible v6 formulation (docs/design-notes/0004-v6-formulation-tests.md).
#
#   Rscript analysis/v6/v6FormulationTests.R [guard] [annual] [tiers] [ssp]      (from the repo root)
#
# Everything is Run-Group v5 and OFFLINE: coefficients are the deployed v5 fits (E1, E3) or refits
# on a rebuilt panel (E2); the energy system is the final state of ONE coupled run
# (SSP2-EU21-PkBudg1000-PFMlevelBfix); nothing is re-optimised by REMIND.
#   E1 guard  - which driver clamps bind, when, and what removing them does to ceilings and phi
#   E2 annual - the deployed spec refitted on an annual (unsmoothed) panel vs the 5-yr moving average
#   E3 tiers  - phi read at 2035 / 2050 / 2070, speed-limited vs frozen-gap projection
#   E4 ssp    - GovEff under SSP1 / SSP3 instead of SSP2 (only if the madrat cache has them)
# Output: output/pfm/v5/v6-tests/<part>.rds and a printed summary. Not a Run-Group artifact.
suppressMessages({ library(pfm); library(madrat) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(TRUE); if (!length(args)) args <- c("guard", "annual", "tiers", "ssp")
ROOT <- normalizePath(".", winslash = "/")
GD <- file.path(ROOT, "output/pfm/v5"); OUT <- file.path(GD, "v6-tests"); dir.create(OUT, showWarnings = FALSE)
# the v5 Run-Group's prepared madrat cache (pfm::pfmPrepareCache, config.yml `madrat:`)
setConfig(cachefolder = pfmResolveConfig(file.path(ROOT, "config.yml"), group = "v5", verbose = FALSE)$cachefolder,
          forcecache = TRUE, .verbose = FALSE)
GDX <- file.path(list.files(file.path(ROOT, "output/remind-runs/v5/EU21"), "^SSP2-EU21-PkBudg1000-PFMlevelBfix_", full.names = TRUE), "fulldata.gdx")
MAP <- "regionmapping_21_EU11.csv"; SECT <- c("Bulk", "Diffuse"); THETA <- 0.5
say <- function(...) message("[v6] ", ...)

sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
cfgOf <- function(sec) {
  cfg <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
    if (!is.null(cfg[[f]])) cfg[[f]] <- unlist(cfg[[f]])
  cfg$panelTransform <- cfg$panelTransform %||% "levels"; cfg
}
mf <- jsonlite::read_json(file.path(GD, "manifest.json"))
panel <- readRDS(file.path(ROOT, "output/pfm/fit-cache/panels", paste0("panel_", mf$panel_hash, ".rds")))
fr <- readRDS(file.path(GD, "frontier.rds"))
fbOf <- function(sec) { ct <- fr$bySector[[sec]]$coefTable; b <- stats::setNames(ct$estimate, ct$term); b[!names(b) %in% c("sigmaSq", "gamma")] }
asg <- stats::setNames(lapply(SECT, function(s) readRDS(file.path(GD, paste0("donor-assignment-band-", s, ".rds")))), SECT)
fitECM <- function(pan, sec) {
  cfg <- cfgOf(sec)
  do.call(estimatePolicyStringencyModel, c(list(data = pan, sector = sec, estimator = "satP", form = "ecm",
    modelDir = NULL, updateIndex = FALSE, verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
}

# ------------------------------------------------------------------ shared: scenario panel + weights
needScen <- any(c("guard", "tiers", "gaprules", "levels", "isotonic", "sspstrength") %in% args)
if (needScen) {
  scf <- file.path(OUT, "scen-EU21-levelBfix.rds")
  scen <- if (file.exists(scf)) readRDS(scf) else {
    s <- panelDataScenario(gdxFile = GDX, aggregate = TRUE, gdxRegionMappingFile = MAP, outputRegionMappingFile = "country")
    saveRDS(s, scf); s }
  wts <- pfm:::pfmAssertSizeWeights(pfmCouplingWeights(year = 2025, scenario = "SSP2"), "v6")
  ecm <- stats::setNames(lapply(SECT, function(s) fitECM(panel, s)), SECT)
}

# The guard, instrumented: records the UNGUARDED design and the ranges on every call, and optionally
# exempts columns matching `exempt` from the clamp (they are still audited).
ORIG_GUARD <- pfm:::.pfmDriverGuard
AUDIT <- new.env()
setGuard <- function(exempt = NULL) {
  g <- function(df, ranges) {
    AUDIT$df <- df; AUDIT$ranges <- ranges
    if (!is.null(exempt)) {
      keep <- ranges[!grepl(exempt, names(ranges))]
      attr(keep, "empirical") <- attr(ranges, "empirical")[names(keep)]
      res <- ORIG_GUARD(df, keep)
      # interactions of exempt drivers must use the unclamped factor too: ORIG_GUARD recomputed them
      # from its own (partially clamped) df, which is what we want
      return(res)
    }
    ORIG_GUARD(df, ranges)
  }
  utils::assignInNamespace(".pfmDriverGuard", g, "pfm")
}
project <- function(sec, rule = "speed-limited", exempt = NULL) {
  setGuard(exempt)
  p <- projectFeasiblePath(cfgOf(sec), sec, histData = panel, scenarioData = scen, rule = rule,
                           frontierBeta = fbOf(sec), fit = ecm[[sec]], modelDir = NULL, verbose = FALSE)
  list(path = p, df = AUDIT$df, ranges = AUDIT$ranges)
}
phiAt <- function(paths, ty) {
  a <- do.call(rbind, lapply(SECT, function(s) {
    r <- aggregateFeasibilityToRegions(paths[[s]], MAP, weights = wts, assignment = asg[[s]], theta = THETA, tierYear = ty)
    r <- r[r$year == ty, c("region", "phi", "relativeGap", "ceilingIndex", "feasibleIndex")]; r$sector <- s; r }))
  w <- reshape(a[, c("region", "sector", "phi")], idvar = "region", timevar = "sector", direction = "wide")
  names(w) <- sub("^phi\\.", "phi", names(w)); w$phi <- pmin(w$phiBulk, w$phiDiffuse); w$tierYear <- ty
  list(wide = w, long = a)
}
cmp <- function(a, b) {   # b against a, joined on region
  m <- merge(a, b, by = "region", suffixes = c(".a", ".b"))
  data.frame(spearman = suppressWarnings(stats::cor(m$phi.a, m$phi.b, method = "spearman")),
             medAbs = stats::median(abs(m$phi.b - m$phi.a)), maxAbs = max(abs(m$phi.b - m$phi.a)),
             maxRegion = m$region[which.max(abs(m$phi.b - m$phi.a))],
             floorA = paste(sort(m$region[m$phi.a <= min(m$phi.a) + 1e-9]), collapse = ","),
             floorB = paste(sort(m$region[m$phi.b <= min(m$phi.b) + 1e-9]), collapse = ","))
}
supportAudit <- function(df, ranges, years = c(2025, 2035, 2050, 2070, 2100)) {
  emp <- attr(ranges, "empirical") %||% ranges
  do.call(rbind, lapply(names(emp), function(cl) do.call(rbind, lapply(years, function(y) {
    v <- df[[cl]][df$year == y]; v <- v[is.finite(v)]; lo <- emp[[cl]][["min"]]; hi <- emp[[cl]][["max"]]
    over <- pmax(v - hi, lo - v, 0)
    data.frame(driver = cl, year = y, shareOut = mean(v < lo | v > hi), shareAbove = mean(v > hi),
               shareBelow = mean(v < lo), p95ExcessSD = unname(stats::quantile(over, 0.95)), maxExcessSD = max(over))
  }))))
}

# ------------------------------------------------------------------ E1: clamps
if ("guard" %in% args) {
  say("E1 guard variants")
  base <- stats::setNames(lapply(SECT, function(s) project(s)), SECT)
  audit <- do.call(rbind, lapply(SECT, function(s) cbind(sector = s, supportAudit(base[[s]]$df, base[[s]]$ranges))))
  cols <- names(base$Bulk$ranges)
  say("guarded columns: ", paste(cols, collapse = " | "))
  AP_IN <- "[Ii]nnovator"; AP_ALL <- "[Ii]nnovator|[Ii]ncumbent"
  variants <- list(deployed = NULL, noInnov = AP_IN, noActorPower = AP_ALL, noGuard = ".")
  res <- lapply(names(variants), function(v) {
    ps <- stats::setNames(lapply(SECT, function(s) project(s, exempt = variants[[v]])$path), SECT)
    ph <- lapply(c(2035, 2050, 2070), function(ty) phiAt(ps, ty))
    ceil <- do.call(rbind, lapply(SECT, function(s) {
      p <- ps[[s]]; do.call(rbind, lapply(c(2035, 2050, 2070, 2100), function(y) {
        q <- p[p$year == y & !p$outOfCoverage, ]
        data.frame(variant = v, sector = s, year = y, medCeil = stats::median(q$ceilingIndex),
                   p05Ceil = unname(stats::quantile(q$ceilingIndex, .05)), p95Ceil = unname(stats::quantile(q$ceilingIndex, .95)),
                   shareCeilAbove9 = mean(q$ceilingIndex > 9), shareCeilBelow1 = mean(q$ceilingIndex < 1),
                   medE = stats::median(q$efficiencyRatio)) }))
    }))
    list(paths = ps, phi = ph, ceiling = ceil)
  })
  names(res) <- names(variants)
  phiCmp <- do.call(rbind, lapply(names(variants)[-1], function(v) do.call(rbind, lapply(1:3, function(i)
    cbind(variant = v, tierYear = c(2035, 2050, 2070)[i], cmp(res$deployed$phi[[i]]$wide, res[[v]]$phi[[i]]$wide))))))
  ceil <- do.call(rbind, lapply(res, `[[`, "ceiling"))
  saveRDS(list(audit = audit, phiCompare = phiCmp, ceiling = ceil, guardedColumns = cols,
               phi = lapply(res, function(r) lapply(r$phi, `[[`, "wide"))), file.path(OUT, "guard.rds"))
  print(audit[audit$year %in% c(2035, 2070, 2100) & audit$shareOut > 0, ], row.names = FALSE, digits = 3)
  print(phiCmp, row.names = FALSE, digits = 3); print(ceil, row.names = FALSE, digits = 3)
}

# ------------------------------------------------------------------ E3: tier years
if ("tiers" %in% args) {
  say("E3 tier years")
  out <- list()
  # projectFeasiblePath(rule = "frozen-gap") returns NA for every row on this scenario frame (its seed
  # ceiling is taken from the earliest frame year, where the design is incomplete) - a latent defect,
  # unused by the coupling. The frozen gap is therefore built here directly: each covered country keeps
  # its 2022 efficiency ratio from frontier.rds and only the ceiling moves (S = E2022 * S*(t)).
  frozen <- function(p, sec) {
    sc <- fr$bySector[[sec]]$scores; e22 <- stats::setNames(sc$efficiencyRatio[sc$year == 2022], sc$region[sc$year == 2022])
    cov <- !p$outOfCoverage & p$region %in% names(e22)
    p$feasibleIndex[cov] <- pmin(e22[p$region[cov]], 1) * p$ceilingIndex[cov]
    p$efficiencyRatio <- p$feasibleIndex / p$ceilingIndex; p
  }
  for (rule in c("speed-limited", "frozen-gap")) {
    ps <- stats::setNames(lapply(SECT, function(s) {
      p <- project(s, rule = "speed-limited")$path
      if (rule == "frozen-gap") frozen(p, s) else p }), SECT)
    out[[rule]] <- lapply(c(2035, 2050, 2070), function(ty) phiAt(ps, ty))
  }
  tab <- do.call(rbind, lapply(names(out), function(rule) {
    ph <- out[[rule]]
    rbind(cbind(rule = rule, from = 2035, to = 2050, cmp(ph[[1]]$wide, ph[[2]]$wide)),
          cbind(rule = rule, from = 2035, to = 2070, cmp(ph[[1]]$wide, ph[[3]]$wide)),
          cbind(rule = rule, from = 2050, to = 2070, cmp(ph[[2]]$wide, ph[[3]]$wide)))
  }))
  gaps <- do.call(rbind, lapply(names(out), function(rule) do.call(rbind, lapply(out[[rule]], function(x)
    cbind(rule = rule, aggregate(relativeGap ~ sector, data = x$long, FUN = stats::median), tierYear = x$wide$tierYear[1])))))
  saveRDS(list(compare = tab, gaps = gaps, phi = lapply(out, function(o) lapply(o, `[[`, "wide"))), file.path(OUT, "tiers.rds"))
  print(tab, row.names = FALSE, digits = 3); print(gaps, row.names = FALSE, digits = 3)
}

# ------------------------------------------------------------------ E3b: what exactly is held fixed
# Three ways to hold a gap while the ceiling S*(t) moves, all anchored at the first projection period
# (2025) so covered and uncovered countries share one base: E0 = fitted 2022 E (covered) or the band-rule
# E (uncovered), S*0 = the country's own 2025 ceiling.
#   ratio    S(t) = E0 * S*(t)                         relative gap constant; ceiling changes never reach phi
#   absolute S(t) = max(S*(t) - (1 - E0) S*0, 0)       index-point gap D constant; g(t) = D / S*(t)
#   logit-u  S(t) = 10 logistic(logit(S*(t)/10) - u)   the frontier's own shortfall u constant (logit scale)
# plus the deployed speed-limited path for reference.
if ("gaprules" %in% args) {
  say("E3b gap rules")
  sq <- function(p, n = 1056) (p * (n - 1) + 0.5) / n
  rules <- c("speed-limited", "ratio", "absolute", "logit-u")
  hold <- function(p, sec, rule) {
    if (rule == "speed-limited") return(p)
    sc <- fr$bySector[[sec]]$scores
    e22 <- stats::setNames(sc$efficiencyRatio[sc$year == 2022], sc$region[sc$year == 2022])
    a <- asg[[sec]]; eb <- stats::setNames(a$efficiencyRatio, as.character(a$region))
    e0 <- ifelse(p$region %in% names(e22), e22[p$region], eb[p$region]); e0 <- pmin(e0, 1)
    s0 <- stats::setNames(p$ceilingIndex[p$year == 2025], p$region[p$year == 2025])[p$region]
    S <- switch(rule,
      ratio = e0 * p$ceilingIndex,
      absolute = pmax(p$ceilingIndex - (1 - e0) * s0, 0),
      "logit-u" = { u <- stats::qlogis(sq(s0 / 10)) - stats::qlogis(sq(e0 * s0 / 10))
                    10 * stats::plogis(stats::qlogis(sq(p$ceilingIndex / 10)) - u) })
    ok <- is.finite(S)
    p$feasibleIndex[ok] <- pmin(S[ok], p$ceilingIndex[ok])
    p$outOfCoverage[ok] <- FALSE   # every country now carries its own level; stop the band rule re-filling it
    p$efficiencyRatio <- p$feasibleIndex / p$ceilingIndex; p
  }
  base <- stats::setNames(lapply(SECT, function(s) project(s)$path), SECT)
  res <- lapply(rules, function(rl) {
    ps <- stats::setNames(lapply(SECT, function(s) hold(base[[s]], s, rl)), SECT)
    ph <- lapply(c(2035, 2050, 2070, 2025), function(ty) phiAt(ps, ty))   # 2025 last: the 2022-anchored base
    ceil <- do.call(rbind, lapply(SECT, function(s) { p <- ps[[s]]
      do.call(rbind, lapply(c(2025, 2035, 2050, 2070), function(y) { q <- p[p$year == y & is.finite(p$feasibleIndex), ]
        data.frame(rule = rl, sector = s, year = y, medCeil = stats::median(q$ceilingIndex), medS = stats::median(q$feasibleIndex),
                   medG = stats::median(1 - q$efficiencyRatio)) })) }))
    list(phi = ph, ceil = ceil)
  })
  names(res) <- rules
  tab <- do.call(rbind, lapply(rules, function(rl) {
    ph <- res[[rl]]$phi
    rbind(cbind(rule = rl, what = "2035 vs deployed 2035", cmp(res[["speed-limited"]]$phi[[1]]$wide, ph[[1]]$wide)),
          cbind(rule = rl, what = "2050 vs own 2035", cmp(ph[[1]]$wide, ph[[2]]$wide)),
          cbind(rule = rl, what = "2070 vs own 2035", cmp(ph[[1]]$wide, ph[[3]]$wide)))
  }))
  ceil <- do.call(rbind, lapply(res, `[[`, "ceil"))
  # Order-preserving severity path: phi_r(t) = 1 - theta(t) * u_r(2035), theta(t) = theta * G(t) / G(2035).
  # G(t) from the regional relative gaps of a ceiling-responsive rule: the final-energy-weighted MEAN gap,
  # or its SPREAD (weighted interquartile range, robust to the two extreme regions that min-max uses).
  regW <- tapply(wts[names(wts)], pfm:::.pfmResolveCountryMap(MAP)[names(wts)], sum, na.rm = TRUE)
  wq <- function(x, w, p) { o <- order(x); cw <- cumsum(w[o]) / sum(w[o]); x[o][which(cw >= p)[1]] }
  thetaPath <- do.call(rbind, lapply(c("absolute", "logit-u"), function(rl) do.call(rbind, lapply(c(4, 1, 2, 3), function(i) {
    L <- res[[rl]]$phi[[i]]$long
    do.call(rbind, lapply(SECT, function(s) { d <- L[L$sector == s & is.finite(L$relativeGap), ]
      w <- as.numeric(regW[d$region]); w[!is.finite(w)] <- 0
      data.frame(rule = rl, sector = s, year = c(2035, 2050, 2070, 2025)[i],
                 meanGap = stats::weighted.mean(d$relativeGap, w), iqrGap = wq(d$relativeGap, w, .75) - wq(d$relativeGap, w, .25),
                 rangeGap = diff(range(d$relativeGap))) }))
  }))))
  for (k in c("meanGap", "iqrGap", "rangeGap")) {
    key <- paste(thetaPath$rule, thetaPath$sector)
    b25 <- thetaPath[[k]][thetaPath$year == 2025][match(key, key[thetaPath$year == 2025])]
    b35 <- thetaPath[[k]][thetaPath$year == 2035][match(key, key[thetaPath$year == 2035])]
    thetaPath[[paste0("ratio2035_", k)]] <- thetaPath[[k]] / b35
    thetaPath[[paste0("ratio2025_", k)]] <- thetaPath[[k]] / b25
  }
  saveRDS(list(compare = tab, levels = ceil, thetaPath = thetaPath, phi = lapply(res, function(r) lapply(r$phi, `[[`, "wide"))), file.path(OUT, "gaprules.rds"))
  print(thetaPath, row.names = FALSE, digits = 3)
  print(tab, row.names = FALSE, digits = 3); print(ceil, row.names = FALSE, digits = 3)
}

# ------------------------------------------------------------------ E5: shares from levels (S*, S) instead of the gap
# (a) robustness of each ORDERING to the frontier error structure: country ceilings S* 2022 under the four
#     rungs of analysis/checks/propagateFrontierRungsToPhi.R, against E (the gap) under the same rungs; observed S is
#     data and identical on every rung.
# (b) stability over tier years of regional shares built by min-max on S*, on S, and on the gap.
if ("levels" %in% args) {
  say("E5 levels")
  rungCeil <- function(fit, beta, fml) {
    df <- fit$data; mm <- stats::model.matrix(stats::as.formula(fml), data = df)
    keep <- intersect(colnames(mm), names(beta)); mm <- mm[, keep, drop = FALSE]
    eta <- as.numeric(mm %*% beta[colnames(mm)]); obs <- as.numeric(fit$outcomeNatural[rownames(mm)])
    d <- data.frame(region = as.character(df[rownames(mm), "region"]), year = df[rownames(mm), "year"],
                    S = obs, Sstar = 10 * stats::plogis(eta))
    d$E <- pmin(pmax(d$S / pmax(d$Sstar, 1e-9), 0), 1); d[d$year == 2022, ]
  }
  rob <- do.call(rbind, lapply(SECT, function(sec) {
    cfg <- cfgOf(sec)
    fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = 10,
                   modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
    df <- fit$data; fml <- stats::as.formula(fit$formula)
    fmlNoFE <- if ("regionFE" %in% all.vars(fml)) stats::update(fml, . ~ . - regionFE) else fml
    pd <- { d <- df; d$region <- as.character(d$region); plm::pdata.frame(d, index = c("region", "year")) }
    rungs <- list(headline = rungCeil(fit, stats::coef(fit$model), fml))
    for (nm in c("truncnorm", "panel", "decay")) {
      f <- tryCatch(switch(nm, truncnorm = frontier::sfa(fml, data = df, truncNorm = TRUE),
                           panel = frontier::sfa(fmlNoFE, data = pd), decay = frontier::sfa(fmlNoFE, data = pd, timeEffect = TRUE)),
                    error = function(e) NULL)
      if (!is.null(f)) rungs[[nm]] <- rungCeil(fit, stats::coef(f), if (nm == "truncnorm") fml else fmlNoFE)
    }
    h <- rungs$headline
    do.call(rbind, lapply(setdiff(names(rungs), "headline"), function(nm) {
      m <- merge(h, rungs[[nm]], by = "region", suffixes = c(".h", ".r"))
      data.frame(sector = sec, rung = nm,
                 spearmanSstar = stats::cor(m$Sstar.h, m$Sstar.r, method = "spearman"),
                 spearmanE = stats::cor(m$E.h, m$E.r, method = "spearman"),
                 spearmanS = 1, medAbsSstar = stats::median(abs(m$Sstar.r - m$Sstar.h)))
    }))
  }))
  # (b) regional shares from levels, read at three tier years on the deployed projection
  ps <- stats::setNames(lapply(SECT, function(s) project(s)$path), SECT)
  mm <- function(x) { u <- (max(x) - x) / (max(x) - min(x)); 1 - THETA * u }   # highest level -> phi = 1
  shares <- lapply(c(2035, 2050, 2070), function(ty) {
    a <- phiAt(ps, ty)$long
    per <- lapply(SECT, function(s) { d <- a[a$sector == s, ]
      data.frame(region = d$region, sector = s, gap = d$phi, Sstar = mm(d$ceilingIndex), S = mm(d$feasibleIndex)) })
    d <- do.call(rbind, per)
    w <- aggregate(cbind(gap, Sstar, S) ~ region, data = d, FUN = min); w$tierYear <- ty; w
  })
  stab <- do.call(rbind, lapply(c("gap", "Sstar", "S"), function(v) do.call(rbind, lapply(2:3, function(i) {
    m <- merge(shares[[1]], shares[[i]], by = "region", suffixes = c(".a", ".b"))
    data.frame(basis = v, from = 2035, to = c(2050, 2070)[i - 1],
               spearman = stats::cor(m[[paste0(v, ".a")]], m[[paste0(v, ".b")]], method = "spearman"),
               medAbs = stats::median(abs(m[[paste0(v, ".b")]] - m[[paste0(v, ".a")]])))
  }))))
  s35 <- shares[[1]]
  cross <- data.frame(pair = c("gap vs S*", "gap vs S", "S* vs S"),
                      spearman2035 = c(stats::cor(s35$gap, s35$Sstar, method = "spearman"),
                                       stats::cor(s35$gap, s35$S, method = "spearman"),
                                       stats::cor(s35$Sstar, s35$S, method = "spearman")))
  saveRDS(list(rungs = rob, stability = stab, cross = cross, shares = shares), file.path(OUT, "levels.rds"))
  print(rob, row.names = FALSE, digits = 3); print(stab, row.names = FALSE, digits = 3); print(cross, row.names = FALSE, digits = 3)
  print(s35[order(s35$gap), ], row.names = FALSE, digits = 3)
}

# ------------------------------------------------------------------ E6: region-specific catch-up that never overtakes
# Ranking from the 2022-anchored gaps (E held from 2022, read at 2025 = first model period). Each region's
# gap then moves with its OWN ceiling (absolute gap held: g(t) = g(2025) * S*(2025) / S*(t)), and is projected
# back onto the fixed ranking by weighted isotonic regression (pool-adjacent-violators): a region that would
# overtake its neighbour is pooled with it instead (a tie), never passes it.
if ("isotonic" %in% args) {
  say("E6 isotonic")
  pava <- function(y, w) {          # weighted isotonic (non-decreasing) fit, pool-adjacent-violators
    v <- y; ww <- w; n <- rep(1, length(y)); i <- 1
    while (i < length(v)) {
      if (v[i] > v[i + 1] + 1e-12) {
        v[i] <- (ww[i] * v[i] + ww[i + 1] * v[i + 1]) / (ww[i] + ww[i + 1]); ww[i] <- ww[i] + ww[i + 1]; n[i] <- n[i] + n[i + 1]
        v <- v[-(i + 1)]; ww <- ww[-(i + 1)]; n <- n[-(i + 1)]; if (i > 1) i <- i - 1
      } else i <- i + 1
    }
    rep(v, n)
  }
  regW <- tapply(wts[names(wts)], pfm:::.pfmResolveCountryMap(MAP)[names(wts)], sum, na.rm = TRUE)
  # E held from 2022 for every country (ratio rule): the 2022-anchored gap, with each year's ceiling
  e22 <- function(sec) { sc <- fr$bySector[[sec]]$scores; stats::setNames(sc$efficiencyRatio[sc$year == 2022], sc$region[sc$year == 2022]) }
  ps <- stats::setNames(lapply(SECT, function(s) {
    p <- project(s)$path; e <- e22(s); a <- asg[[s]]; eb <- stats::setNames(a$efficiencyRatio, as.character(a$region))
    e0 <- pmin(ifelse(p$region %in% names(e), e[p$region], eb[p$region]), 1)
    ok <- is.finite(e0) & is.finite(p$ceilingIndex)
    p$feasibleIndex[ok] <- e0[ok] * p$ceilingIndex[ok]; p$outOfCoverage[ok] <- FALSE; p }), SECT)
  YR <- c(2025, 2035, 2050, 2070)
  L <- lapply(YR, function(ty) phiAt(ps, ty)$long)
  out <- do.call(rbind, lapply(SECT, function(s) {
    base <- L[[1]][L[[1]]$sector == s & is.finite(L[[1]]$relativeGap), c("region", "relativeGap", "ceilingIndex")]
    names(base) <- c("region", "g0", "C0")
    ord <- base$region[order(base$g0)]            # least constrained first
    do.call(rbind, lapply(seq_along(YR), function(i) {
      d <- merge(base, L[[i]][L[[i]]$sector == s, c("region", "ceilingIndex")], by = "region")
      d$graw <- d$g0 * d$C0 / d$ceilingIndex
      d <- d[match(ord, d$region), ]; w <- as.numeric(regW[d$region]); w[!is.finite(w) | w <= 0] <- 1
      d$giso <- pava(d$graw, w)
      mm <- function(g) (g - min(g)) / (max(g) - min(g))
      d$u0 <- mm(d$g0); d$uiso <- mm(d$giso)
      data.frame(sector = s, year = YR[i], region = d$region, g0 = d$g0, graw = d$graw, giso = d$giso, u0 = d$u0, uiso = d$uiso)
    }))
  }))
  summ <- do.call(rbind, lapply(split(out, list(out$sector, out$year)), function(d) {
    blocks <- rle(round(d$giso, 12))$lengths
    data.frame(sector = d$sector[1], year = d$year[1],
               spearmanRawVsRanking = suppressWarnings(stats::cor(d$graw, d$g0, method = "spearman")),
               regionsPooled = sum(blocks[blocks > 1]), largestTie = max(blocks),
               maxAdjust = max(abs(d$giso - d$graw)), medAbsDu = stats::median(abs(d$uiso - d$u0)), maxAbsDu = max(abs(d$uiso - d$u0)),
               maxDuRegion = d$region[which.max(abs(d$uiso - d$u0))],
               floor = paste(d$region[d$uiso >= 1 - 1e-9], collapse = ","))
  }))
  summ <- summ[order(summ$sector, summ$year), ]
  saveRDS(list(summary = summ, regions = out), file.path(OUT, "isotonic.rds"))
  print(summ, row.names = FALSE, digits = 3)
}

# ------------------------------------------------------------------ E7: SSP differentiation of the strength (level + spread)
# phi_rs(t) = 1 - theta [ k_s(t) ubar_s + d_s(t) (u_rs - ubar_s) ],  k = G(t)/G(2025) (weighted mean gap),
# d = D(t)/D(2025) (weighted SD of the regional gaps). Ranking u_rs from the 2022-anchored gaps (E held from 2022,
# read at 2025). Government effectiveness swapped to SSP1 / SSP3 by adding (SSPx - SSP2) of the normalised SSP
# index to the deployed SSP2 driver, so the deployed normalisation and 2022 harmonisation stay intact. GDP and
# population stay SSP2 (not cached for other SSPs); the energy system is the SSP2 held-price run's.
if ("sspstrength" %in% args) {
  say("E7 SSP level + spread")
  raw <- readRDS(file.path(ROOT, "data/madrat/convertSSPextensions.rds")); if (is.list(raw) && !is.null(raw$x)) raw <- raw$x
  gv <- function(ssp) grep(paste0("^", ssp, "\\.Governance Index\\|Government Effectiveness"), magclass::getNames(raw), value = TRUE)
  hy <- intersect(2000:2022, magclass::getYears(raw, as.integer = TRUE))
  lo <- apply(raw[, hy, gv("SSP2")], 3, min, na.rm = TRUE); hi <- apply(raw[, hy, gv("SSP2")], 3, max, na.rm = TRUE)
  yS <- magclass::getYears(scen, as.integer = TRUE)
  normSSP <- function(ssp) {
    x <- raw[, , gv(ssp)]; x <- x[, !apply(is.na(as.array(x)), 2, all), ]
    x <- magclass::time_interpolate(x, yS, integrate_interpolated_years = FALSE, extrapolation_type = "constant")
    magclass::setNames(pmin(pmax((x - lo) / (hi - lo), 0), 1), "GE")
  }
  base2 <- normSSP("SSP2"); GE <- "Government Effectiveness (WGI)"
  scenFor <- function(ssp) {
    if (ssp == "SSP2") return(scen)
    s2 <- scen; reg <- intersect(magclass::getItems(s2, 1), magclass::getItems(base2, 1))
    dlt <- normSSP(ssp)[reg, yS, ] - base2[reg, yS, ]; dlt[is.na(dlt)] <- 0
    s2[reg, yS, GE] <- pmin(pmax(s2[reg, yS, GE] + as.numeric(dlt), 0), 1); s2
  }
  regW <- tapply(wts[names(wts)], pfm:::.pfmResolveCountryMap(MAP)[names(wts)], sum, na.rm = TRUE)
  wsd <- function(x, w) { m <- sum(w * x) / sum(w); sqrt(sum(w * (x - m)^2) / sum(w)) }
  sq <- function(p, n = 1056) (p * (n - 1) + 0.5) / n
  holdRule <- function(p, sec, rule) {       # ceiling-responsive rules anchored at 2025 with the 2022 E
    sc <- fr$bySector[[sec]]$scores; e22 <- stats::setNames(sc$efficiencyRatio[sc$year == 2022], sc$region[sc$year == 2022])
    a <- asg[[sec]]; eb <- stats::setNames(a$efficiencyRatio, as.character(a$region))
    e0 <- pmin(ifelse(p$region %in% names(e22), e22[p$region], eb[p$region]), 1)
    s0 <- stats::setNames(p$ceilingIndex[p$year == 2025], p$region[p$year == 2025])[p$region]
    S <- switch(rule, ratio = e0 * p$ceilingIndex, absolute = pmax(p$ceilingIndex - (1 - e0) * s0, 0),
      "logit-u" = { u <- stats::qlogis(sq(s0 / 10)) - stats::qlogis(sq(e0 * s0 / 10)); 10 * stats::plogis(stats::qlogis(sq(p$ceilingIndex / 10)) - u) })
    ok <- is.finite(S); p$feasibleIndex[ok] <- pmin(S[ok], p$ceilingIndex[ok]); p$outOfCoverage[ok] <- FALSE; p
  }
  YR <- c(2025, 2035, 2050, 2070)
  res <- list(); phis <- list()
  for (ssp in c("SSP2", "SSP1", "SSP3")) {
    scen0 <- scen; scen <- scenFor(ssp)
    base <- stats::setNames(lapply(SECT, function(s) project(s)$path), SECT)
    scen <- scen0
    rank <- lapply(SECT, function(s) { p <- holdRule(base[[s]], s, "ratio"); p })   # 2022-anchored ranking
    names(rank) <- SECT
    L0 <- phiAt(rank, 2025)$long
    for (rule in c("logit-u", "absolute")) {
      ps <- stats::setNames(lapply(SECT, function(s) holdRule(base[[s]], s, rule)), SECT)
      for (s in SECT) {
        u0 <- L0[L0$sector == s & is.finite(L0$relativeGap), ]; u0$u <- (u0$relativeGap - min(u0$relativeGap)) / diff(range(u0$relativeGap))
        w0 <- as.numeric(regW[u0$region]); ubar <- sum(w0 * u0$u) / sum(w0)
        st <- do.call(rbind, lapply(YR, function(ty) { L <- phiAt(ps, ty)$long; d <- L[L$sector == s & is.finite(L$relativeGap), ]
          w <- as.numeric(regW[d$region]); data.frame(year = ty, G = sum(w * d$relativeGap) / sum(w), D = wsd(d$relativeGap, w),
            range = diff(range(d$relativeGap))) }))
        st$k <- st$G / st$G[1]; st$d <- st$D / st$D[1]; st$dRange <- st$range / st$range[1]
        res[[length(res) + 1]] <- cbind(ssp = ssp, rule = rule, sector = s, st)
        if (rule == "logit-u") for (i in seq_along(YR)) {
          ph <- 1 - THETA * (st$k[i] * ubar + st$d[i] * (u0$u - ubar)); ph <- pmin(pmax(ph, 0), 1)
          phis[[length(phis) + 1]] <- data.frame(ssp = ssp, sector = s, year = YR[i], region = u0$region, u = u0$u, phi = ph,
                                                  phiLevelOnly = pmin(pmax(1 - THETA * st$k[i] * u0$u, 0), 1))
        }
      }
    }
  }
  tab <- do.call(rbind, res); ph <- do.call(rbind, phis)
  shares <- do.call(rbind, lapply(split(ph, list(ph$ssp, ph$sector, ph$year)), function(d)
    data.frame(ssp = d$ssp[1], sector = d$sector[1], year = d$year[1], floor = min(d$phi), median = stats::median(d$phi), top = max(d$phi),
               floorLevelOnly = min(d$phiLevelOnly))))
  saveRDS(list(strength = tab, shares = shares, regions = ph), file.path(OUT, "ssp-strength.rds"))
  print(tab[, c("ssp", "rule", "sector", "year", "G", "k", "D", "d", "dRange")], row.names = FALSE, digits = 3)
  print(shares[order(shares$sector, shares$year, shares$ssp), ], row.names = FALSE, digits = 3)
}

# ------------------------------------------------------------------ E2: annual vs 5-yr moving average
if ("annual" %in% args) {
  say("E2 annual vs smoothed panel")
  build <- function(k) panelDataHistorical(aggregate = TRUE, y = 2000:2022, outputRegionMappingFile = "country",
                                           includePolicyStringency = TRUE, movingAverage = k)
  pan5 <- build(5); pan1 <- build(1)
  # control: the smoothed rebuild must reproduce the v5 panel, or nothing below is comparable
  com <- intersect(magclass::getNames(pan5), magclass::getNames(panel))
  reg <- intersect(magclass::getItems(pan5, 1), magclass::getItems(panel, 1))
  yrs <- intersect(magclass::getYears(pan5), magclass::getYears(panel))
  ctrl <- max(abs(as.numeric(pan5[reg, yrs, com]) - as.numeric(panel[reg, yrs, com])), na.rm = TRUE)
  say("control |rebuilt MA5 - v5 panel| max = ", signif(ctrl, 3))
  fitBoth <- function(pan, sec) {
    cfg <- cfgOf(sec)
    fF <- do.call(estimatePolicyStringencyModel, c(list(data = pan, sector = sec, estimator = "frontier",
      indexMax = 10, modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
    fE <- fitECM(pan, sec)
    sc <- computeFeasibilityFrontier(fF)$scores %||% computeFeasibilityFrontier(fF)
    list(frontier = fF, ecm = fE, scores = sc,
         gamma = unname(stats::coef(fF$model)[["gamma"]]), lambda = -unname(stats::coef(fE$model)[["lagged_ecp"]]),
         beta = stats::coef(fF$model), ll = tryCatch(as.numeric(stats::logLik(fF$model)), error = function(e) NA))
  }
  E2 <- lapply(SECT, function(s) list(ma5 = fitBoth(pan5, s), annual = fitBoth(pan1, s)))
  names(E2) <- SECT
  summ <- do.call(rbind, lapply(SECT, function(s) {
    a <- E2[[s]]$ma5; b <- E2[[s]]$annual
    terms <- setdiff(intersect(names(a$beta), names(b$beta)), c("sigmaSq", "gamma", "(Intercept)"))
    sa <- a$scores; sb <- b$scores
    k <- merge(sa[sa$year == 2022, c("region", "efficiencyRatio")], sb[sb$year == 2022, c("region", "efficiencyRatio")], by = "region")
    data.frame(sector = s, gammaMA5 = a$gamma, gammaAnnual = b$gamma, lambdaMA5 = a$lambda, lambdaAnnual = b$lambda,
               signAgree = sum(sign(a$beta[terms]) == sign(b$beta[terms])), nTerms = length(terms),
               spearmanE2022 = stats::cor(k$efficiencyRatio.x, k$efficiencyRatio.y, method = "spearman"),
               medE2022MA5 = stats::median(k$efficiencyRatio.x), medE2022Annual = stats::median(k$efficiencyRatio.y))
  }))
  coefTab <- do.call(rbind, lapply(SECT, function(s) {
    a <- E2[[s]]$ma5$beta; b <- E2[[s]]$annual$beta; t <- intersect(names(a), names(b))
    data.frame(sector = s, term = t, ma5 = unname(a[t]), annual = unname(b[t])) }))
  # year-to-year noise in the outcome: share of zero changes and lag-1 autocorrelation of changes
  noise <- do.call(rbind, lapply(list(ma5 = pan5, annual = pan1), function(pn) do.call(rbind, lapply(SECT, function(s) {
    v <- pn[, , paste0("Policy Stringency|", s)]; m <- matrix(as.numeric(v), nrow = dim(v)[1])
    d <- t(apply(m, 1, diff)); d1 <- d[, -1]; d0 <- d[, -ncol(d)]
    data.frame(sector = s, shareZeroChange = mean(abs(d) < 1e-9, na.rm = TRUE),
               acfChange = stats::cor(as.numeric(d0), as.numeric(d1), use = "complete.obs")) }))))
  noise$panel <- rep(c("ma5", "annual"), each = length(SECT))
  saveRDS(list(control = ctrl, summary = summ, coef = coefTab, noise = noise), file.path(OUT, "annual.rds"))
  print(summ, row.names = FALSE, digits = 3); print(noise, row.names = FALSE, digits = 3)
  print(coefTab, row.names = FALSE, digits = 3)
}

# ------------------------------------------------------------------ E4: SSP governance
if ("ssp" %in% args) {
  say("E4 SSP governance availability")
  # calcOutput(subtype = "all") forces a full mrdrivers rebuild of GDP/population for five SSPs (> 10 min,
  # stopped); the converted SOURCE is already in the madrat cache and holds all five governance paths.
  cf <- file.path(ROOT, "data/madrat/convertSSPextensions.rds")
  x <- if (file.exists(cf)) readRDS(cf) else "no convertSSPextensions.rds in the madrat cache"
  if (is.list(x) && !is.null(x$x)) x <- x$x   # madrat cache entry: list(x = <magpie>, ...)
  if (!is.character(x) && !magclass::is.magpie(x)) x <- tryCatch(magclass::as.magpie(x), error = function(e) conditionMessage(e))
  if (is.character(x)) {
    say("SSPextensions (all SSPs) not available offline: ", substr(x, 1, 200))
    saveRDS(list(available = FALSE, reason = x), file.path(OUT, "ssp.rds"))
  } else {
    ge <- grep("Governance Index\\|Government Effectiveness", magclass::getNames(x), value = TRUE)
    yrs <- intersect(c(2020, 2035, 2050, 2070, 2100), magclass::getYears(x, as.integer = TRUE))
    tab <- do.call(rbind, lapply(ge, function(n) data.frame(var = n, year = yrs,
      median = sapply(yrs, function(y) stats::median(as.numeric(x[, y, n]), na.rm = TRUE)),
      p10 = sapply(yrs, function(y) unname(stats::quantile(as.numeric(x[, y, n]), .1, na.rm = TRUE))),
      p90 = sapply(yrs, function(y) unname(stats::quantile(as.numeric(x[, y, n]), .9, na.rm = TRUE))))))
    hist <- as.numeric(x[, intersect(2000:2022, magclass::getYears(x, as.integer = TRUE)), ge[grepl("SSP2", ge)]])
    tab$aboveHistMax <- sapply(seq_len(nrow(tab)), function(i) mean(as.numeric(x[, tab$year[i], tab$var[i]]) > max(hist, na.rm = TRUE), na.rm = TRUE))
    saveRDS(list(available = TRUE, goveff = tab), file.path(OUT, "ssp.rds"))
    print(tab, row.names = FALSE, digits = 3)
  }
}
utils::assignInNamespace(".pfmDriverGuard", ORIG_GUARD, "pfm")
say("done -> ", OUT)
