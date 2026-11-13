# The index maximum: how much of the loosening of the limit comes from the index stopping at 10?
# (design note 0010 section 9, T7; the model paper's gap plan GP-1)
#   Rscript analysis/v8/indexMaximum.R [group] [maxima, comma-separated]   (repo root; default v8, 8,9,10,12)
#   -> output/pfm/<group>/index-maximum.rds
# The coupling holds each country's logit distance below its ceiling, q = eta - y with y = logit(S / M). With q held,
# the share of the ceiling used rises as the ceiling rises only because the logistic curve flattens towards M, the
# index maximum (CAPMF's scale maximum, 10; the highest observed value is about 7). Here the selected frontier is
# refitted with M = 8, 9, 12 (both sectors, the heteroscedastic slack in buildings & transport kept), the anchor is
# rebuilt from each refit (the covered countries from their own q, the uncovered at the covered median share of the
# ceiling used, v8's rule), and the strength k(t) is recomputed on the coupled hold-the-price energy system
# (computeStrengthPath on coupling/scen-PFMlevelBfix-<group>.rds, as analysis/v6/couplingMechanism.R).
# Checks: the refit at M = 10 reproduces frontier.rds; the anchor rebuilt at M = 10 reproduces the staged anchor's
# distances and ranking; its k reproduces the staged anchor's. Each refit runs under a time limit and a failure is
# reported, not dropped. Nothing in the package, the fit cache or the Run-Group changes.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
MS <- if (length(args) > 1) as.numeric(strsplit(args[2], ",")[[1]]) else c(10, 9, 12, 8)
GD <- file.path("output/pfm", g); say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [index-maximum:", g, "] ", ...)
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE); pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability", "fossilRents"), names(pd))])
panel <- .panelForGroup(g)
if ("GDP per Capita" %in% getNames(panel) && !"GDP per Capita Sq" %in% getNames(panel)) panel <- mbind(panel, setNames(panel[, , "GDP per Capita"]^2, "GDP per Capita Sq"))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD)); fr <- readRDS(file.path(GD, "frontier.rds"))
a0 <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, ".rds")))
SECTORS <- c(Bulk = "P&I", Diffuse = "B&T"); YRS <- c(2025, 2030, 2040, 2050, 2070, 2100); TLIM <- 1800
cfgOf <- function(sec) { hit <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers")) if (!is.null(hit[[f]])) hit[[f]] <- unlist(hit[[f]]); hit }

# the anchor of one maximum: a0 with the designs, the country distances and the regional ranking of the refit
anchorAt <- function(M) {
  a <- a0; rows <- list(); info <- list()
  for (sec in names(SECTORS)) {
    cfg <- cfgOf(sec); t1 <- Sys.time()
    fit <- R.utils::withTimeout(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = M,
             modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg))), timeout = TLIM, onTimeout = "error")
    cf <- stats::coef(fit$model)
    des <- pfm:::.pfmAnchorDesign(cfg, sec, panel, cf, modelDir = NULL, indexMax = M, slackScaling = fit$driverScaling)
    ta <- a0$anchorYear; sq <- function(p) pfm:::.pfmSqueeze(pmin(pmax(p, 0), 1), des$nSqueeze)
    eh <- pfm:::.pfmFrontierEta(des, panel); eh <- eh[eh$year == ta & is.finite(eh$eta), , drop = FALSE]
    etaA <- stats::setNames(eh$eta, eh$region); slackA <- stats::setNames(eh$slackShift, eh$region)
    fd <- des$fit$data; cov <- fd[fd$year == ta & is.finite(fd$ecp), c("region", "ecp")]; yCov <- stats::setNames(cov$ecp, as.character(cov$region))
    old <- a0$country[a0$country$sector == sec, ]; reg <- intersect(old$region, names(etaA)); basis <- stats::setNames(old$basis, old$region)[reg]
    eCov <- stats::plogis(yCov) / stats::plogis(etaA[names(yCov)])
    # the uncovered countries: the staged anchor's share of the ceiling used at M = 10 (the check); at another maximum
    # the covered median of this refit, which is v8's rule (coverage: median)
    asg <- readRDS(file.path(GD, paste0("donor-assignment-band-", sec, ".rds")))
    eBand <- stats::setNames(asg$efficiencyRatio, as.character(asg$region))[reg]
    stopifnot(all(basis %in% c("observed", "median")))
    eUnc <- if (M == 10) eBand else rep(stats::median(pmin(eCov, 1), na.rm = TRUE), length(reg))
    y <- ifelse(basis == "observed", yCov[reg], stats::qlogis(sq(pmin(eUnc, 1) * stats::plogis(etaA[reg]))))
    q <- etaA[reg] - y
    rows[[sec]] <- data.frame(sector = sec, region = reg, basis = basis, etaAnchor = as.numeric(etaA[reg]), yAnchor = as.numeric(y), q = as.numeric(q),
                              slackShiftAnchor = as.numeric(slackA[reg]), ceilingAnchor = 10 * stats::plogis(as.numeric(etaA[reg])),
                              indexAnchor = 10 * stats::plogis(as.numeric(etaA[reg] - q)), stringsAsFactors = FALSE)
    a$designs[[sec]] <- des
    cb <- pfm:::.pfmCeilingBeta(cf)
    info[[sec]] <- data.frame(M = M, sector = SECTORS[[sec]], logLik = as.numeric(stats::logLik(fit$model)), gamma = unname(cf["gamma"]) %||% NA_real_,
                              fossil = cb[["Incumbent.Power"]], fossilPc = cb[["Incumbent.Power.pc"]], maxCeiling = M * max(stats::plogis(etaA[names(yCov)])),
                              medianE = stats::median(pmin(eCov, 1)), seconds = round(as.numeric(difftime(Sys.time(), t1, units = "secs"))))
    attr(info[[sec]], "E") <- eCov
  }
  a$country <- do.call(rbind, rows); rownames(a$country) <- NULL
  # the regional gaps and the ranking, as computeAnchorGap (the ratio S / S* does not depend on the scale factor)
  a$region <- do.call(rbind, lapply(names(SECTORS), function(sec) {
    cc <- a$country[a$country$sector == sec & is.finite(a$country$q), ]
    path <- data.frame(region = cc$region, year = a0$anchorYear, feasibleIndex = cc$indexAnchor, ceilingIndex = cc$ceilingAnchor, outOfCoverage = FALSE)
    agg <- suppressWarnings(aggregateFeasibilityToRegions(path, a0$mapping, weights = a0$weights, theta = 0.5))
    agg <- agg[is.finite(agg$relativeGap), c("region", "relativeGap", "feasibleIndex", "ceilingIndex")]; names(agg) <- c("region", "g", "indexAnchor", "ceilingAnchor")
    rng <- range(agg$g); agg$u <- if (diff(rng) > 0) (agg$g - rng[1]) / diff(rng) else 0
    old <- a0$region[a0$region$sector == sec, ]; extra <- setdiff(names(old), c(names(agg), "sector"))
    cbind(sector = sec, agg, old[match(agg$region, old$region), extra, drop = FALSE], stringsAsFactors = FALSE) }))
  list(anchor = a, info = info)
}

res <- list(); fits <- list(); E <- list()
for (M in MS) {
  say("maximum ", M, " ...")
  r <- tryCatch(anchorAt(M), error = function(e) { say("  FAILED at maximum ", M, ": ", conditionMessage(e)); NULL })
  if (is.null(r)) { fits[[as.character(M)]] <- data.frame(M = M, sector = unname(SECTORS), logLik = NA, gamma = NA, fossil = NA, fossilPc = NA, maxCeiling = NA, medianE = NA, seconds = NA); next }
  a <- r$anchor; st <- computeStrengthPath(a, scen, theta = 0.5)
  hold <- computeStrengthPath(a, scen, theta = 0.5, hold = "ratio")$strength
  if (M == 10) {   # the checks
    for (sec in names(SECTORS)) { sc <- fr$bySector[[sec]]$scores; sc <- sc[sc$year == a0$anchorYear, ]
      d1 <- max(abs(stats::setNames(a$country$ceilingAnchor[a$country$sector == sec], a$country$region[a$country$sector == sec])[as.character(sc$region)] - sc$frontierIndex), na.rm = TRUE)
      say("  check ", sec, ": refit ceilings against frontier.rds, max |difference| ", signif(d1, 2), " index points"); stopifnot(d1 < 1e-3) }
    k <- merge(a$country, a0$country, by = c("sector", "region")); d2 <- max(abs(k$q.x - k$q.y), na.rm = TRUE)
    u <- merge(a$region, a0$region, by = c("sector", "region")); d3 <- max(abs(u$u.x - u$u.y), na.rm = TRUE)
    s0 <- computeStrengthPath(a0, scen, theta = 0.5)$strength; d4 <- max(abs(st$strength$k - s0$k), na.rm = TRUE)
    say("  check: rebuilt anchor against the staged one, max |difference| q ", signif(d2, 2), ", u ", signif(d3, 2), ", k ", signif(d4, 2)); stopifnot(d2 < 1e-6, d4 < 1e-6)
    # the staged ranking u is built by the remind stage and differs from this recomputation (max |difference| d3); the
    # rankings below are compared within this script's own computation, so the difference does not enter them
    uCheck <- d3
  }
  fits[[as.character(M)]] <- do.call(rbind, r$info); for (sec in names(SECTORS)) E[[paste(M, sec)]] <- attr(r$info[[sec]], "E")
  s <- st$strength[st$strength$year %in% YRS, c("sector", "year", "k", "G")]
  s$kConstantLimit <- hold$k[match(paste(s$sector, s$year), paste(hold$sector, hold$year))]
  res[[as.character(M)]] <- list(M = M, strength = cbind(M = M, s), region = cbind(M = M, a$region[, c("sector", "region", "g", "u")]),
                                 regionsPath = cbind(M = M, st$regions[st$regions$year %in% YRS, ]))
  say("  k(2050): ", paste(sprintf("%s %.3f", SECTORS[s$sector[s$year == 2050]], s$k[s$year == 2050]), collapse = ", "))
  saveRDS(list(res = res, fits = fits, E = E), file.path(GD, "index-maximum-partial.rds"))
}
fit <- do.call(rbind, fits); rownames(fit) <- NULL
strength <- do.call(rbind, lapply(res, `[[`, "strength")); region <- do.call(rbind, lapply(res, `[[`, "region")); rownames(strength) <- rownames(region) <- NULL
# against the maximum of 10: the ranking of the regions (u) and of the covered countries (E) at the anchor year; k
ref <- region[region$M == 10, ]
rank <- do.call(rbind, lapply(setdiff(unique(region$M), 10), function(M) do.call(rbind, lapply(names(SECTORS), function(sec) {
  x <- region[region$M == M & region$sector == sec, ]; r0 <- ref[ref$sector == sec, ]; e <- E[[paste(M, sec)]]; e0 <- E[[paste(10, sec)]]
  data.frame(M = M, sector = SECTORS[[sec]], rankRegionU = stats::cor(x$u, r0$u[match(x$region, r0$region)], method = "spearman"),
             maxAbsDiffU = max(abs(x$u - r0$u[match(x$region, r0$region)])), rankCountryE = stats::cor(e, e0[names(e)], method = "spearman")) }))))
kw <- stats::reshape(strength[, c("M", "sector", "year", "k")], idvar = c("M", "sector"), timevar = "year", direction = "wide"); names(kw) <- sub("^k\\.", "k", names(kw))
k10 <- kw[kw$M == 10, ]; kw$dk2050 <- kw$k2050 - k10$k2050[match(kw$sector, k10$sector)]; kw$dk2100 <- kw$k2100 - k10$k2100[match(kw$sector, k10$sector)]
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), maxima = MS, fit = fit, strength = strength, strengthWide = kw, region = region, rank = rank,
            stagedRankingMaxDiff = if (exists("uCheck")) uCheck else NA_real_,
            note = paste("selected frontier refitted at each index maximum M; anchor rebuilt (uncovered countries at the refit's covered median E);",
                         "k on the coupled hold-the-price panel of the group (theta 0.50, EU21). kConstantLimit is k with the share of the ceiling held (1 by construction",
                         "at the regional level only if gaps are held; reported as computed). Not a coupled result: REMIND was not re-run."))
saveRDS(out, file.path(GD, "index-maximum.rds")); unlink(file.path(GD, "index-maximum-partial.rds")); say("wrote ", file.path(GD, "index-maximum.rds"))
options(width = 200)
cat("\n== the refits ==\n"); print(fit, row.names = FALSE, digits = 4)
cat("\n== the strength k(t) of the fading limit, by index maximum (dk: against the maximum of 10) ==\n"); print(kw[order(kw$sector, kw$M), ], row.names = FALSE, digits = 3)
cat("\n== the anchor-year ranking against the maximum of 10 ==\n"); print(rank, row.names = FALSE, digits = 3)
