# The two walk rivals of the selected specification (the GMD paper's review v03, points M5 and M3; gap plan GP-46)
#   Rscript analysis/v8/walkRivals.R [group]          (repo root; default v8)
#   -> output/pfm/<group>/coupling/walk-rivals.rds
# The specification walk (sanity-pool.rds) rejected the two candidates nearest the selected one (candidate 7,
# `... fe:OECDp satAP iw:fexp fos5`, apTransform "saturating"): candidate 1 has NO saturation of the sectoral-interest
# terms (apTransform "linear"; rejected for the extrapolation flag) and candidate 5 saturates clean energy only
# (apTransform "saturating-innovator", the v7 form; rejected for gamma alone, P&I 0.999004 against the gate 0.999).
# Each is refitted on the group's panel, its EU21 anchor is rebuilt as in analysis/v8/fossilBound.R, and k(t) is
# recomputed on the four cached pathway panels (analysis/v8/openLoopStrength.R).
#
# Countries without data: the selected anchor places buildings-and-transport countries by the fossil-rents donor
# assignment (efficiencyRatio, ADR 0061), which belongs to the selected fit. A rival has no donor assignment of its
# own, so every variant here is ALSO built with the covered-median rule, and the rivals are compared with the selected
# specification under that same rule ("selected, median rule"): the comparison isolates the saturation form. The
# selected specification with its own donor rule is the reproduction check against the deployed anchor.
#
# Reported per variant: the fit (log-likelihood, gamma per sector), the 2023 rank value u by region and sector, its rank
# correlation with the selected one, the most and least limited region, the final-energy-weighted mean of u (the
# average constraint per unit theta at k = 1), k(2050) and k(2100) on each pathway, and the 2050 mean constraint per
# unit theta on the headline pathway (weighted mean u x k(2050)). Offline: no REMIND run; nothing in the package, the fit
# cache (modelDir = NULL) or the Run-Group changes.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g); CPL <- file.path(GD, "coupling")
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [walk-rivals:", g, "] ", ...)
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE); pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability", "fossilRents"), names(pd))])
panel <- .panelForGroup(g)
if ("GDP per Capita" %in% getNames(panel) && !"GDP per Capita Sq" %in% getNames(panel)) panel <- mbind(panel, setNames(panel[, , "GDP per Capita"]^2, "GDP per Capita Sq"))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
a0 <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")
ol <- readRDS(file.path(CPL, "open-loop-strength.rds"))
PANELS <- c("current policies (NPi), uncoupled" = "current policies", "1000 Gt, no-politics reference (theta 0)" = "1000 Gt reference",
            "1000 Gt, hold the price (headline)" = "1000 Gt, hold the price", "1000 Gt, hold the budget" = "1000 Gt, hold the budget")
scenFile <- function(lab) { run <- unique(ol$strength$run[ol$strength$pathway == lab])
  if (grepl("headline", lab)) file.path(CPL, paste0("scen-PFMlevelBfix-", g, ".rds")) else file.path(CPL, paste0("scen-openloop-", gsub("[^A-Za-z0-9]+", "-", run), ".rds")) }
scens <- lapply(stats::setNames(names(PANELS), PANELS), function(lab) readRDS(scenFile(lab)))
SECTORS <- c(Bulk = "P&I", Diffuse = "B&T"); YRS <- c(2025, 2030, 2040, 2050, 2070, 2100)
FORMS <- c("selected (satAP)" = "saturating", "candidate 1 (no saturation)" = "linear", "candidate 5 (clean energy saturated only, satInn)" = "saturating-innovator")
cfgOf <- function(sec, apT) { hit <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers")) if (!is.null(hit[[f]])) hit[[f]] <- unlist(hit[[f]])
  stopifnot(identical(hit$apTransform, "saturating")); hit$apTransform <- apT; hit }

fitForm <- function(apT) lapply(stats::setNames(names(SECTORS), names(SECTORS)), function(sec) {
  cfg <- cfgOf(sec, apT)
  fit <- R.utils::withTimeout(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = 10,
           modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg))), timeout = 3600, onTimeout = "error")
  list(cfg = cfg, fit = fit, cf = stats::coef(fit$model))
})

anchorFrom <- function(fits, rule) {
  a <- a0; rows <- list()
  for (sec in names(SECTORS)) {
    cfg <- fits[[sec]]$cfg; fit <- fits[[sec]]$fit; cf <- fits[[sec]]$cf
    des <- pfm:::.pfmAnchorDesign(cfg, sec, panel, cf, modelDir = NULL, indexMax = 10, slackScaling = fit$driverScaling)
    ta <- a0$anchorYear; sq <- function(p) pfm:::.pfmSqueeze(pmin(pmax(p, 0), 1), des$nSqueeze)
    eh <- pfm:::.pfmFrontierEta(des, panel); eh <- eh[eh$year == ta & is.finite(eh$eta), , drop = FALSE]
    etaA <- stats::setNames(eh$eta, eh$region); slackA <- stats::setNames(eh$slackShift, eh$region)
    fd <- des$fit$data; cov <- fd[fd$year == ta & is.finite(fd$ecp), c("region", "ecp")]; yCov <- stats::setNames(cov$ecp, as.character(cov$region))
    old <- a0$country[a0$country$sector == sec, ]; reg <- intersect(old$region, names(etaA)); basis <- stats::setNames(old$basis, old$region)[reg]
    eCov <- pmin(stats::plogis(yCov) / stats::plogis(etaA[names(yCov)]), 1)
    asg <- readRDS(file.path(GD, paste0("donor-assignment-band-", sec, ".rds")))
    eUnc <- if (rule == "donor") stats::setNames(asg$efficiencyRatio, as.character(asg$region))[reg] else rep(stats::median(eCov), length(reg))
    y <- ifelse(basis == "observed", yCov[reg], stats::qlogis(sq(pmin(eUnc, 1) * stats::plogis(etaA[reg]))))
    q <- etaA[reg] - y
    rows[[sec]] <- data.frame(sector = sec, region = reg, basis = basis, etaAnchor = as.numeric(etaA[reg]), yAnchor = as.numeric(y), q = as.numeric(q),
                              slackShiftAnchor = as.numeric(slackA[reg]), ceilingAnchor = 10 * stats::plogis(as.numeric(etaA[reg])),
                              indexAnchor = 10 * stats::plogis(as.numeric(etaA[reg] - q)), stringsAsFactors = FALSE)
    a$designs[[sec]] <- des
  }
  a$country <- do.call(rbind, rows); rownames(a$country) <- NULL
  a$region <- do.call(rbind, lapply(names(SECTORS), function(sec) {
    cc <- a$country[a$country$sector == sec & is.finite(a$country$q), ]
    path <- data.frame(region = cc$region, year = a0$anchorYear, feasibleIndex = cc$indexAnchor, ceilingIndex = cc$ceilingAnchor, outOfCoverage = FALSE)
    agg <- suppressWarnings(aggregateFeasibilityToRegions(path, a0$mapping, weights = a0$weights, theta = 0.5))
    agg <- agg[is.finite(agg$relativeGap), c("region", "relativeGap", "feasibleIndex", "ceilingIndex")]; names(agg) <- c("region", "g", "indexAnchor", "ceilingAnchor")
    rng <- range(agg$g); agg$u <- if (diff(rng) > 0) (agg$g - rng[1]) / diff(rng) else 0
    old <- a0$region[a0$region$sector == sec, ]; extra <- setdiff(names(old), c(names(agg), "sector"))
    cbind(sector = sec, agg, old[match(agg$region, old$region), extra, drop = FALSE], stringsAsFactors = FALSE) }))
  a
}

V <- list(); FIT <- list()
for (lab in names(FORMS)) {
  say(lab, ": fitting both sectors ...")
  fits <- tryCatch(fitForm(FORMS[[lab]]), error = function(e) { say("  FAILED: ", conditionMessage(e)); NULL }); if (is.null(fits)) next
  FIT[[lab]] <- do.call(rbind, lapply(names(SECTORS), function(sec) { cf <- fits[[sec]]$cf
    data.frame(variant = lab, apTransform = FORMS[[lab]], sector = SECTORS[[sec]], logLik = as.numeric(stats::logLik(fits[[sec]]$fit$model)),
               gamma = unname(cf["gamma"]) %||% NA_real_, stringsAsFactors = FALSE) }))
  say("  gamma: ", paste(sprintf("%s %.6f", FIT[[lab]]$sector, FIT[[lab]]$gamma), collapse = ", "))
  for (rule in if (FORMS[[lab]] == "saturating") c("donor", "median") else "median") {
    a <- anchorFrom(fits, rule); key <- paste0(lab, ", ", rule, " rule")
    k <- do.call(rbind, lapply(names(scens), function(p) { st <- computeStrengthPath(a, scens[[p]], theta = 0.5)$strength
      data.frame(pathway = p, st[st$year %in% YRS, c("sector", "year", "k")]) }))
    V[[key]] <- list(variant = lab, rule = rule, region = a$region[, c("sector", "region", "g", "u", "weight")], k = k)
    say("  ", rule, " rule: k(2050) headline ", paste(sprintf("%s %.3f", k$sector[k$year == 2050 & k$pathway == "1000 Gt, hold the price"],
                                                                 k$k[k$year == 2050 & k$pathway == "1000 Gt, hold the price"]), collapse = ", "))
  }
  saveRDS(list(variants = V, fit = FIT), file.path(CPL, "walk-rivals-partial.rds"))
}

# --- the check: the selected specification with its own donor rule reproduces the deployed anchor and k ------------
chk <- V[["selected (satAP), donor rule"]]
if (!is.null(chk)) {
  du <- merge(chk$region, a0$region[, c("sector", "region", "u")], by = c("sector", "region"))
  devU <- max(abs(du$u.x - du$u.y))
  h <- chk$k[chk$pathway == "1000 Gt, hold the price", ]; o <- ol$strength[ol$strength$pathway == "1000 Gt, hold the price (headline)", ]
  devK <- max(abs(h$k - o$k[match(paste(h$sector, h$year), paste(o$sector, o$year))]), na.rm = TRUE)
  say("check: u against the deployed anchor, max |difference| ", signif(devU, 2), "; k on the headline panel against open-loop-strength.rds ", signif(devK, 2))
  stopifnot(devU < 1e-3, devK < 1e-2)
}

# --- the summary ----------------------------------------------------------------------------------------------------
ref <- V[["selected (satAP), median rule"]]
S <- do.call(rbind, lapply(names(V), function(key) { v <- V[[key]]
  do.call(rbind, lapply(names(SECTORS), function(sec) {
    r <- v$region[v$region$sector == sec, ]; r0 <- ref$region[ref$region$sector == sec, ]; r0 <- r0[match(r$region, r0$region), ]
    r1 <- chk$region[chk$region$sector == sec, ]; r1 <- r1[match(r$region, r1$region), ]
    kk <- function(p, y) v$k$k[v$k$pathway == p & v$k$sector == sec & v$k$year == y]
    wmu <- sum(r$weight * r$u) / sum(r$weight)
    data.frame(variant = v$variant, rule = v$rule, sector = SECTORS[[sec]],
               rankCorrWithSelectedSameRule = stats::cor(r$u, r0$u, method = "spearman"),
               rankCorrWithDeployed = stats::cor(r$u, r1$u, method = "spearman"),
               mostLimited = r$region[which.max(r$u)], leastLimited = r$region[which.min(r$u)],
               weightedMeanU = wmu,
               k2050Headline = kk("1000 Gt, hold the price", 2050), k2100Headline = kk("1000 Gt, hold the price", 2100),
               k2050Reference = kk("1000 Gt reference", 2050), k2100Reference = kk("1000 Gt reference", 2100),
               k2050CurrentPolicies = kk("current policies", 2050),
               meanConstraintPerTheta2050Headline = wmu * kk("1000 Gt, hold the price", 2050), stringsAsFactors = FALSE) })) }))
rownames(S) <- NULL
FIT <- do.call(rbind, FIT); rownames(FIT) <- NULL
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), forms = FORMS, summary = S, fit = FIT,
            variants = V, check = if (!is.null(chk)) c(maxDiffU = devU, maxDiffKHeadline = devK) else NULL,
            note = paste("the selected specification refitted with apTransform linear (walk candidate 1, no saturation) and saturating-innovator",
                         "(candidate 5, clean energy saturated only); EU21 anchor rebuilt; countries without data at the covered median for every",
                         "variant (the selected one also with its fossil-rents donor rule, the reproduction check); k(t) by computeStrengthPath,",
                         "theta 0.50, on four cached pathway panels. Offline."))
saveRDS(out, file.path(CPL, "walk-rivals.rds")); unlink(file.path(CPL, "walk-rivals-partial.rds")); say("wrote ", file.path(CPL, "walk-rivals.rds"))
options(width = 220); cat("\n== fits ==\n"); print(FIT, row.names = FALSE, digits = 6)
cat("\n== summary ==\n"); print(S, row.names = FALSE, digits = 3)
