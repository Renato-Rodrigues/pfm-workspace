# Is the fossil-dependence effect an abatement-cost effect? (the model paper's review v04 M6 / v05 M4)
#   Rscript analysis/v8/abatementCost.R [group] [variants]   (repo root; default v8, base,energyIntensity,gdpEnergy)
#   -> output/pfm/<group>/coupling/abatement-cost.rds
# Fossil dependence of the energy system proxies structural power, but also the cost of decarbonising it, which REMIND
# already prices; under that reading the coupled cap double-counts. Here the selected frontier is refitted with controls
# for abatement cost added (energy intensity of GDP; and energy intensity with GDP per capita squared already in), the
# anchor rebuilt, and k(t) recomputed on current policies, the 1000 Gt reference and the coupled headline (as
# analysis/v8/fossilBound.R, whose machinery this reuses). If the fossil coefficient and the pathway contrast survive the
# control, the cost reading does not explain them. Offline; nothing in the package or the Run-Group changes.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
BOUNDS <- if (length(args) > 1) strsplit(args[2], ",")[[1]] else c("base", "energyIntensity")
GD <- file.path("output/pfm", g); CPL <- file.path(GD, "coupling")
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [abatement-cost:", g, "] ", ...)
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE); pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability", "fossilRents"), names(pd))])
panel <- .panelForGroup(g)
if ("GDP per Capita" %in% getNames(panel) && !"GDP per Capita Sq" %in% getNames(panel)) panel <- mbind(panel, setNames(panel[, , "GDP per Capita"]^2, "GDP per Capita Sq"))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD)); fr <- readRDS(file.path(GD, "frontier.rds"))
a0 <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")
ol <- readRDS(file.path(CPL, "open-loop-strength.rds"))
PANELS <- c("current policies (NPi), uncoupled" = "current policies", "1000 Gt, no-politics reference (theta 0)" = "1000 Gt reference",
            "1000 Gt, hold the price (headline)" = "1000 Gt, hold the price", "1000 Gt, hold the budget" = "1000 Gt, hold the budget")
scenFile <- function(lab) { run <- unique(ol$strength$run[ol$strength$pathway == lab])
  if (grepl("headline", lab)) file.path(CPL, paste0("scen-PFMlevelBfix-", g, ".rds")) else file.path(CPL, paste0("scen-openloop-", gsub("[^A-Za-z0-9]+", "-", run), ".rds")) }
scens <- lapply(stats::setNames(names(PANELS), PANELS), function(lab) readRDS(scenFile(lab)))
SECTORS <- c(Bulk = "P&I", Diffuse = "B&T"); YRS <- c(2025, 2030, 2040, 2050, 2070, 2100)
cfgOf <- function(sec, bound) { hit <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers")) if (!is.null(hit[[f]])) hit[[f]] <- unlist(hit[[f]])
  if (bound == "energyIntensity") hit$controlDrivers <- unique(c(hit$controlDrivers, "Energy Intensity")); hit }

BASECF <- list()   # the base fit's coefficients per sector, the restart point of the other bounds
anchorAt <- function(bound) {
  a <- a0; rows <- list(); info <- list()
  for (sec in names(SECTORS)) {
    cfg <- cfgOf(sec, bound)
    fit <- R.utils::withTimeout(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = 10,
             modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg))), timeout = 1800, onTimeout = "error")
    # Restart (2026-11-23, design note 0012 sec. 12): the energy-intensity refit in power and industry stopped at a worse
    # optimum than the base (log-likelihood -1332.5 against -1232.1 on the same 1127 rows). A model with one more regressor
    # must reach at least the base's maximum, so a refit without a slack model is restarted from the base estimates (0 for
    # the added control) and the better of the two maxima is kept; `restarted` records which.
    restarted <- FALSE
    if (bound == "base") BASECF[[sec]] <<- stats::coef(fit$model)
    if (bound != "base" && !length(pfm:::.pfmSlackDriversFor(cfg$slackDrivers, sec)) && !is.null(BASECF[[sec]])) {
      nm <- names(stats::coef(fit$model)); b0 <- BASECF[[sec]]
      st <- stats::setNames(ifelse(nm %in% names(b0), b0[nm], 0), nm)
      keep <- intersect(all.vars(fit$formula), colnames(fit$data))
      d <- fit$data[stats::complete.cases(fit$data[, keep, drop = FALSE]), , drop = FALSE]
      if ("regionFE" %in% colnames(d) && is.factor(d$regionFE)) d$regionFE <- droplevels(d$regionFE)
      m2 <- tryCatch(frontier::sfa(fit$formula, data = d, startVal = unname(st), maxit = 5000), error = function(e) { say("restart failed: ", conditionMessage(e)); NULL })
      if (!is.null(m2)) {
        l1 <- as.numeric(stats::logLik(fit$model)); l2 <- as.numeric(stats::logLik(m2))
        say(bound, " ", sec, ": log-likelihood ", round(l1, 1), " from the default start, ", round(l2, 1), " from the base estimates (", nrow(d), " rows)")
        if (l2 > l1 + 1e-6) { fit$model <- m2; restarted <- TRUE }
      }
    }
    cf <- stats::coef(fit$model)
    des <- pfm:::.pfmAnchorDesign(cfg, sec, panel, cf, modelDir = NULL, indexMax = 10, slackScaling = fit$driverScaling)
    ta <- a0$anchorYear; sq <- function(p) pfm:::.pfmSqueeze(pmin(pmax(p, 0), 1), des$nSqueeze)
    eh <- pfm:::.pfmFrontierEta(des, panel); eh <- eh[eh$year == ta & is.finite(eh$eta), , drop = FALSE]
    etaA <- stats::setNames(eh$eta, eh$region); slackA <- stats::setNames(eh$slackShift, eh$region)
    fd <- des$fit$data; cov <- fd[fd$year == ta & is.finite(fd$ecp), c("region", "ecp")]; yCov <- stats::setNames(cov$ecp, as.character(cov$region))
    old <- a0$country[a0$country$sector == sec, ]; reg <- intersect(old$region, names(etaA)); basis <- stats::setNames(old$basis, old$region)[reg]
    eCov <- pmin(stats::plogis(yCov) / stats::plogis(etaA[names(yCov)]), 1)
    asg <- readRDS(file.path(GD, paste0("donor-assignment-band-", sec, ".rds")))
    eUnc <- if (bound == "base") stats::setNames(asg$efficiencyRatio, as.character(asg$region))[reg] else rep(stats::median(eCov), length(reg))
    y <- ifelse(basis == "observed", yCov[reg], stats::qlogis(sq(pmin(eUnc, 1) * stats::plogis(etaA[reg]))))
    q <- etaA[reg] - y
    rows[[sec]] <- data.frame(sector = sec, region = reg, basis = basis, etaAnchor = as.numeric(etaA[reg]), yAnchor = as.numeric(y), q = as.numeric(q),
                              slackShiftAnchor = as.numeric(slackA[reg]), ceilingAnchor = 10 * stats::plogis(as.numeric(etaA[reg])),
                              indexAnchor = 10 * stats::plogis(as.numeric(etaA[reg] - q)), stringsAsFactors = FALSE)
    a$designs[[sec]] <- des
    cb <- pfm:::.pfmCeilingBeta(cf)
    info[[sec]] <- data.frame(bound = bound, sector = SECTORS[[sec]], logLik = as.numeric(stats::logLik(fit$model)), restarted = restarted, gamma = unname(cf["gamma"]) %||% NA_real_,
                              fossil = cb[["Incumbent.Power"]], fossilPc = cb[["Incumbent.Power.pc"]])
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
  list(anchor = a, info = do.call(rbind, info))
}

# the share of final energy whose fossil terms sit at the bound, from the frozen scaling of the frontier (0.05 refit)
atBound <- function(des, s, sec) {
  sc <- des$fit$driverScaling; out <- list()
  for (term in c("Incumbent Power", "Incumbent Power pc")) {
    v <- paste0(term, "|", sec); if (!v %in% getNames(s)) next
    p <- sc[[make.names(term)]]; lo <- p[["floor"]] %||% NA_real_; if (!is.finite(lo)) next
    x <- s[, YRS, v]; cc <- intersect(getItems(x, 1), names(a0$weights)); w <- a0$weights[cc]; w[!is.finite(w)] <- 0
    for (y in YRS) { z <- as.numeric(x[cc, y, ]); ok <- is.finite(z)
      out[[paste(term, y)]] <- data.frame(term = term, year = y, shareAtBound = sum(w[ok] * (z[ok] <= lo)) / sum(w[ok])) } }
  do.call(rbind, out)
}

K <- list(); FIT <- list(); B <- list()
for (b in BOUNDS) {
  say("bound ", b, " ...")
  r <- tryCatch(anchorAt(b), error = function(e) { say("  FAILED: ", conditionMessage(e)); NULL }); if (is.null(r)) next
  FIT[[b]] <- r$info
  for (p in names(scens)) { st <- computeStrengthPath(r$anchor, scens[[p]], theta = 0.5)$strength
    K[[paste(b, p)]] <- data.frame(bound = b, pathway = p, st[st$year %in% YRS, c("sector", "year", "k")]) }
  if (b == "base") {
    h <- K[[paste(b, "1000 Gt, hold the price")]]; o <- ol$strength[ol$strength$pathway == "1000 Gt, hold the price (headline)", ]
    dev <- max(abs(h$k - o$k[match(paste(h$sector, h$year), paste(o$sector, o$year))]), na.rm = TRUE)
    say("  check: k on the headline panel against open-loop-strength.rds, max |difference| ", signif(dev, 2)); stopifnot(dev < 1e-2)   # the cached headline panel was rebuilt from the final gdx by openLoopStrength.R; 0.007 apart
    for (p in names(scens)) for (sec in names(SECTORS)) { z <- atBound(r$anchor$designs[[sec]], scens[[p]], sec)
      if (!is.null(z)) B[[paste(p, sec)]] <- data.frame(pathway = p, sector = SECTORS[[sec]], z) }
  }
  k50 <- do.call(rbind, K[grepl(paste0("^", b, " "), names(K))]); k50 <- k50[k50$year == 2050, ]
  say("  k(2050): ", paste(sprintf("%s %s %.3f", substr(k50$pathway, 1, 12), k50$sector, k50$k), collapse = "; "))
  saveRDS(list(k = K, fit = FIT, atBound = B), file.path(CPL, "abatement-cost-partial.rds"))
}
K <- do.call(rbind, K); rownames(K) <- NULL; FIT <- do.call(rbind, FIT); rownames(FIT) <- NULL
B <- if (length(B)) do.call(rbind, B) else NULL
W <- stats::reshape(K[K$year == 2050, c("bound", "pathway", "sector", "k")], idvar = c("bound", "sector"), timevar = "pathway", direction = "wide")
names(W) <- sub("^k\\.", "", names(W))
W$contrast <- W[["current policies"]] - W[["1000 Gt reference"]]; W$feedback <- W[["1000 Gt, hold the price"]] - W[["1000 Gt reference"]]
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), bounds = BOUNDS, strength = K, contrast2050 = W, fit = FIT, atBound = B,
            note = paste("selected frontier refitted with abatement-cost controls added (energyIntensity: Energy Intensity in the controls); anchor rebuilt;",
                         "k(t) by computeStrengthPath on the group's EU21 anchor design, theta 0.50, on four cached pathway panels.",
                         "contrast = k(current policies) - k(1000 Gt reference); feedback = k(headline) - k(reference); 2050. Offline."))
saveRDS(out, file.path(CPL, "abatement-cost.rds")); unlink(file.path(CPL, "abatement-cost-partial.rds")); say("wrote ", file.path(CPL, "abatement-cost.rds"))
options(width = 200); cat("\n== refits ==\n"); print(FIT, row.names = FALSE, digits = 4)
cat("\n== k(2050) by bound and pathway ==\n"); print(W, row.names = FALSE, digits = 3)
if (!is.null(B)) { cat("\n== share of final energy at the bound (0.05 fit) ==\n"); print(stats::reshape(B, idvar = c("pathway", "sector", "term"), timevar = "year", direction = "wide"), row.names = FALSE, digits = 2) }
