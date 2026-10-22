# The v7 options of design note 0007, tried on a Run-Group's selected model (offline, no REMIND re-run).
#   Rscript analysis/checks/edgeOptions.R [group] [autocracy threshold, default 0.5] [noband]   (repo root; default v6;
#   after analysis/checks/edgeOfData.R; a non-default threshold or "noband" writes edge-options-aut<t>[-noband].rds)
#
# Every variant is scored by one evaluator that rebuilds what the coupling reads: the 2023 regional ranking u
# (EU21 and H12) and the strength k(t) on the coupled hold-the-price energy system
# (output/pfm/<group>/coupling/scen-PFMlevelBfix-<group>.rds). The evaluator reproduces the run: u to 0, k to
# the run's values (checked below, variant "base"). Variants:
#   refits of the frontier on the same standardised estimation data (frontier::sfa, the selected formula):
#     O3a  without China and Saudi Arabia          O3b  without China, Saudi Arabia, Turkey and Russia
#     O5a  no interest x institution terms         O5b  no vertical-accountability terms
#     E1   + net fossil exporter, and exporter x fossil dependence and x fossil per person (exporter as a moderator)
#     E2   + net fossil exporter as a control only (a level shift of the ceiling; like an extra group effect)
#     E3   + the net energy export ratio as a control (continuous, standardised on the sample, capped at its range)
#     E4   + fossil production per person (log) as a control - the static form of O9
#     A1   + autocracy as a control (V-Dem electoral democracy index v2x_polyarchy below 0.5, mean 2019-2023: the
#          main threshold of the Regimes of the World classification)
#     A2   regime split: the interest x institution terms act in democracies only; autocracies get the main effects
#          and their own level (+ autocracy). Autocracy status is held at 2019-2023 in every projection year.
#     A3   smooth democracy weight: the interaction terms multiplied by the electoral democracy index itself (0-1)
#     A4   soft step: the interaction terms multiplied by a logistic of the index (midpoint = the threshold, scale 0.1)
#          (A3/A4 need no threshold for A3 and no hard cut for A4; countries without V-Dem data take the median index)
#     A5   smooth democracy weight on the ACCOUNTABILITY interactions only (interest x vertical accountability); the state
#          capability and rule-of-law interactions act in every regime
#     A6   hard split on the accountability interactions only (+ autocracy level)
#     A7   smooth weight on the accountability and rule-of-law interactions; state capability acts in every regime
#     A8   smooth weight on the accountability and state-capability interactions; rule of law acts in every regime
#          (exporter: net energy exports above half of total energy supply, mean 2019-2023, IEA 2025 edition;
#           every exporter covariate is held at its 2019-2023 value in every projection year - a declared
#           simplification: the projection has no exporter dynamics)
#   on the selected coefficients: O1 cap the institutions inside the interactions at the sample's 5th-95th
#     percentiles; O2 cap institutions and interests there; O6 interaction coefficients halved (a crude stand-in
#     for shrinkage, not an estimator); O7 the countries at the edge of the institution space keep their 2025
#     ceiling (no extrapolated dynamics)
#   O4   the other specifications of the passing band (output/pfm/specband-<group>/s*, analysis/v6/specBand.R)
# In a refit, countries without CAPMF data keep their borrowed efficiency ratio and every covered country keeps
# its observed 2023 policy (the dropped countries included): only the coefficients change.
# Acceptance (0007 section 5): (a) no region with >= 25% of its final energy in countries where fossil dependence or
# clean-energy build-out acts against theory by >= 0.25 logit units, in a sector whose sample-centre sign agrees
# with theory; (b) the O1 cap applied on top moves no rank u by more than 0.25 and k by less than 0.10 in 2050 and
# 2100; (c) both resolutions.
# Writes output/pfm/<group>/edge-options.rds and prints the comparison.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v6"
AUT_THRESHOLD <- if (length(args) >= 2) as.numeric(args[2]) else 0.5   # v2x_polyarchy below this = autocracy
WITH_BAND <- !(length(args) >= 3 && args[3] == "noband")             # "noband": skip O4 (a quick run)
SUFFIX <- if (AUT_THRESHOLD != 0.5 || !WITH_BAND) paste0("-aut", AUT_THRESHOLD, if (!WITH_BAND) "-noband" else "") else ""
GD <- file.path("output/pfm", g); BAND <- file.path("output/pfm", paste0("specband-", g))
RES <- c("EU21", "H12"); YRS <- c(2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060, 2070, 2080, 2090, 2100)
CAP <- c(0.05, 0.95); EXPORT_RATIO <- 0.5; MIN_EFFECT <- 0.25; SHARE <- 0.25
EXPECT <- c(Innovator.Power = 1, Incumbent.Power = -1)          # the acceptance drivers (criterion a)
say <- function(...) message("[options:", g, "] ", ...)

rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE)
modelDir <- rc$modelDir %||% "output/pfm/fit-cache"
panel <- loadTrainingPanel(jsonlite::read_json(file.path(GD, "manifest.json"))$panel_hash, modelDir)
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, ".rds")))
anc0 <- stats::setNames(lapply(RES, function(r) pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), r)), RES)
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
edgeRun <- readRDS(file.path(GD, "edge-of-data.rds"))
SECS <- names(anc0$EU21$designs)

# ---- exporters (IEA World Energy Balances, the edition of the Run-Group's energy drivers) --------------------
iea <- readRDS(Sys.glob(file.path("C:/_data/work/remind_input_data/cache/default", "calcIeaEnergyBalances-*-3474774a.rds"))[1])
iea <- if (is.list(iea) && !is.magpie(iea)) iea$x else iea
yy <- paste0("y", 2019:2023)
exportRatio <- as.vector(dimSums(-dimSums(iea[, yy, c("TOTAL.IMPORTS", "TOTAL.EXPORTS")], dim = 3), dim = 2) /
                           dimSums(iea[, yy, "TOTAL.TES"], dim = c(2, 3)))
names(exportRatio) <- getItems(iea, 1)
exporters <- names(exportRatio)[is.finite(exportRatio) & exportRatio > EXPORT_RATIO]

# ---- helpers ------------------------------------------------------------------------------------------------
designMatrix <- function(design, data) {
  f <- pfm:::.pfmFrontierEta; b <- body(f)
  b[[length(b)]] <- quote(list(df = df, mm = mm[, names(design$beta), drop = FALSE]))
  body(f) <- b; out <- f(design, data)
  rownames(out$mm) <- paste(out$df$region, out$df$year); out
}
mapOf <- function(res) pfm:::.pfmResolveCountryMap(anc0[[res]]$mapping)
aggGap <- function(res, S, Sstar, year) {
  p <- data.frame(region = names(S), year = year, feasibleIndex = S, ceilingIndex = Sstar, outOfCoverage = FALSE)
  r <- suppressWarnings(suppressMessages(aggregateFeasibilityToRegions(p, anc0[[res]]$mapping, weights = anc0[[res]]$weights)))
  stats::setNames(r$relativeGap, r$region)
}
minmax <- function(x) (x - min(x)) / (max(x) - min(x))
regionShare <- function(res, countries) {
  w <- anc0[[res]]$weights; m <- mapOf(res); cc <- intersect(names(m), names(w))
  tapply(w[cc] * (cc %in% countries), m[cc], sum) / tapply(w[cc], m[cc], sum)
}
# fossil production per person (primary coal, oil and gas, mean 2019-2023) - the static form of O9
fossilProducts <- paste0(c("ANTCOAL", "COKCOAL", "BITCOAL", "SUBCOAL", "LIGNITE", "HARDCOAL", "BROWN", "PEAT", "OILSHALE",
                           "CRUDEOIL", "NGL", "NONCRUDE", "NATGAS"), ".INDPROD")
fossilProd <- as.vector(dimSums(iea[, yy, intersect(fossilProducts, getNames(iea))], dim = c(2, 3))) / length(yy)
names(fossilProd) <- getItems(iea, 1)
popScen <- stats::setNames(as.vector(scen[, 2025, "Population"]), getItems(scen, 1))
sampleCty <- unique(as.character(readRDS(file.path(GD, "frontier.rds"))$bySector[[1]]$scores$region))
stdCap <- function(v) {                  # standardise on the sample countries, cap at their range
  m <- mean(v[sampleCty], na.rm = TRUE); sdv <- stats::sd(v[sampleCty], na.rm = TRUE)
  z <- (v - m) / sdv; lo <- min(z[sampleCty], na.rm = TRUE); hi <- max(z[sampleCty], na.rm = TRUE)
  z[!is.finite(z)] <- 0; pmin(pmax(z, lo), hi)
}
vd <- data.table::fread(Sys.glob("C:/_data/work/remind_input_data/sources/VDem/V-Dem-CY-Core-v*.csv")[1],
                        select = c("country_text_id", "year", "v2x_polyarchy"))
vd <- vd[vd$year >= 2019 & vd$year <= 2023, ]
polyarchy <- tapply(vd$v2x_polyarchy, vd$country_text_id, mean, na.rm = TRUE)
autocracies <- names(polyarchy)[is.finite(polyarchy) & polyarchy < AUT_THRESHOLD]
polyW <- pmin(pmax(polyarchy, 0), 1); polyW[!is.finite(polyW)] <- stats::median(polyW, na.rm = TRUE)
covar <- list(autocracy = stats::setNames(as.numeric(names(polyarchy) %in% autocracies), names(polyarchy)),
              polyW = polyW, polyL = stats::plogis((polyW - AUT_THRESHOLD) / 0.1),
              exporter = stats::setNames(as.numeric(names(exportRatio) %in% exporters), names(exportRatio)),
              exportRatioStd = stdCap(pmin(pmax(exportRatio, -1), 10)),
              fossilProdPcStd = stdCap(log1p(1e3 * fossilProd[names(popScen)] / popScen)))
INTS0 <- grep("_x_", names(anc0$EU21$designs[[1]]$beta), value = TRUE)
# a spec that measures an interest per person only (splitAPpc) is tested on that form, as the sweep's gate does
for (d in names(EXPECT)) if (!d %in% names(anc0$EU21$designs[[1]]$beta) && paste0(d, ".pc") %in% names(anc0$EU21$designs[[1]]$beta)) {
  names(EXPECT)[names(EXPECT) == d] <- paste0(d, ".pc")
}
MODES <- list(E1 = c("exporter", "exporter_x_Incumbent.Power", "exporter_x_Incumbent.Power.pc"),
              E2 = "exporter", E3 = "exportRatioStd", E4 = "fossilProdPcStd",
              A1 = "autocracy", A2 = c("autocracy", paste0("dem__", INTS0)),
              A3 = paste0("demw__", INTS0), A4 = paste0("deml__", INTS0),
              A5 = paste0("demw__", grep("Accountability", INTS0, value = TRUE)),
              A6 = c("autocracy", paste0("dem__", grep("Accountability", INTS0, value = TRUE))),
              A7 = paste0("demw__", grep("Accountability|Rule", INTS0, value = TRUE)),
              A8 = paste0("demw__", grep("Accountability|Effectiveness", INTS0, value = TRUE)))
# the democracy weight on the interaction terms, by prefix: hard split, the index itself, its logistic
weightOf <- function(prefix, cty) {
  look <- function(v, fill) { x <- covar[[v]][cty]; x[!is.finite(x)] <- fill; x }
  switch(prefix, dem__ = 1 - look("autocracy", 0),
         demw__ = look("polyW", stats::median(covar$polyW)), deml__ = look("polyL", stats::median(covar$polyL)), 1)
}
prefixOf <- function(k) { m <- regmatches(k, regexpr("^dem[wl]?__", k)); if (length(m)) m else "" }
covCols <- function(cty, mode, base) {   # base: a frame or matrix holding Incumbent.Power(.pc)
  look <- function(v) { x <- covar[[v]][cty]; x[!is.finite(x)] <- 0; x }
  out <- list()
  for (cl in MODES[[mode]]) out[[cl]] <-
    if (grepl("^dem[wl]?__", cl)) weightOf(prefixOf(cl), cty) * base[, sub("^dem[wl]?__", "", cl)]
    else if (startsWith(cl, "exporter_x_")) look("exporter") * base[, sub("^exporter_x_", "", cl)] else look(cl)
  as.data.frame(out, optional = TRUE)
}
addExporter <- function(X, mode = "E1") cbind(X, as.matrix(covCols(sub(" .*$", "", rownames(X)), mode, X)))

# the design matrices of a design, on history (2023) and on the coupled scenario
matsFor <- function(design, extra = NULL) {
  h <- designMatrix(design, panel); s <- designMatrix(design, scen)
  # the spec's own interaction weight (interactionWeight, design note 0007) as column w__ (1 when unweighted)
  wOf <- function(d) { w <- if ("interactionWeight__" %in% names(d)) d$interactionWeight__ else rep(1, nrow(d)); w[!is.finite(w)] <- 1; w }
  h$mm <- cbind(h$mm, w__ = wOf(h$df)); s$mm <- cbind(s$mm, w__ = wOf(s$df))
  hm <- h$mm[h$df$year == design$lastHist, , drop = FALSE]; sm <- s$mm
  if (!is.null(extra)) { hm <- addExporter(hm, extra); sm <- addExporter(sm, extra) }
  list(hist = hm, scen = sm, scenYear = s$df$year, scenRegion = s$df$region)
}

# The evaluator. beta: named coefficients (names must be columns of the matrices; absent ones count as 0).
# tf: optional transform of the interaction factors, function(X) -> X with capped factors (for O1/O2).
evaluate <- function(label, sec, mats, beta, ctab, tf = NULL, freeze = NULL) {
  cols <- names(beta); ints <- grep("_x_", cols, value = TRUE)
  pairs <- if (length(ints)) do.call(rbind, strsplit(sub("^dem[wl]?__", "", ints), "_x_", fixed = TRUE)) else matrix(character(0), 0, 2)
  if (length(ints)) rownames(pairs) <- ints
  demW <- function(X, k) { p <- prefixOf(k); if (nzchar(p)) weightOf(p, sub(" .*$", "", rownames(X))) else 1 }   # democracy weight
  specW <- function(X) if ("w__" %in% colnames(X)) X[, "w__"] else 1   # the spec's own weight, if it has one
  buildX <- function(X) {
    Xm <- if (is.null(tf)) X else tf(X)                     # factor values used inside the interactions
    if (length(ints)) for (k in ints) X[, k] <- Xm[, pairs[k, 1]] * Xm[, pairs[k, 2]] * demW(X, k) * specW(X)
    X[, cols, drop = FALSE]
  }
  etaOf <- function(X) as.vector(buildX(X) %*% beta)
  # 2023: ceilings, the anchored distance, the ranking
  H <- mats$hist[sub(" .*$", "", rownames(mats$hist)) %in% ctab$region[is.finite(ctab$q)], , drop = FALSE]
  cty <- sub(" .*$", "", rownames(H)); ct <- ctab[match(cty, ctab$region), ]
  eta0 <- etaOf(H); ceil <- 10 * stats::plogis(eta0)
  E <- pmin(ct$indexAnchor / ct$ceilingAnchor, 1)
  S <- ifelse(ct$basis == "observed", ct$indexAnchor, E * ceil)
  y <- ifelse(ct$basis == "observed", ct$yAnchor, stats::qlogis(pmin(pmax(S / 10, 1e-6), 1 - 1e-6)))
  q <- stats::setNames(eta0 - y, cty)
  rank <- do.call(rbind, lapply(RES, function(res) {
    gg <- aggGap(res, stats::setNames(S, cty), stats::setNames(ceil, cty), 2023)
    data.frame(variant = label, resolution = res, sector = sec, region = names(gg), u = minmax(gg))
  }))
  # the strength on the coupled energy system
  sel <- mats$scenRegion %in% cty & mats$scenYear %in% YRS
  X <- mats$scen[sel, , drop = FALSE]; rr <- mats$scenRegion[sel]; ty <- mats$scenYear[sel]
  et <- etaOf(X)
  if (length(freeze)) {                                      # O7: frozen countries keep their 2025 ceiling
    e25 <- stats::setNames(et[ty == 2025], rr[ty == 2025]); fz <- rr %in% freeze & ty > 2025
    et[fz] <- e25[rr[fz]]
  }
  strength <- do.call(rbind, lapply(RES, function(res) {
    wR <- anc0[[res]]$regionWeights
    G <- sapply(YRS, function(t) {
      i <- ty == t; c <- rr[i]
      gg <- aggGap(res, stats::setNames(10 * stats::plogis(et[i] - q[c]), c), stats::setNames(10 * stats::plogis(et[i]), c), t)
      sum(wR[names(gg)] * gg, na.rm = TRUE) / sum(wR[names(gg)][is.finite(gg)]) })
    data.frame(variant = label, resolution = res, sector = sec, year = YRS, k = G / G[1])
  }))
  # direction: effective slope of the acceptance drivers at each country's 2025 values, and its effect by 2050 / 2100
  at <- function(t) { i <- mats$scenYear == t & mats$scenRegion %in% cty; Z <- mats$scen[i, , drop = FALSE]; rownames(Z) <- mats$scenRegion[i]; Z }
  Z0 <- at(2025); Zm <- if (is.null(tf)) Z0 else tf(Z0)
  dir <- do.call(rbind, lapply(intersect(names(EXPECT), cols), function(d) {
    s <- rep(beta[[d]], nrow(Z0))
    for (k in ints[pairs[, 1] == d]) s <- s + beta[[k]] * Zm[, pairs[k, 2]] * demW(Z0, k) * specW(Z0)
    for (k in ints[pairs[, 2] == d]) s <- s + beta[[k]] * Zm[, pairs[k, 1]] * demW(Z0, k) * specW(Z0)
    eff <- pmax(abs((at(2050)[rownames(Z0), d] - Z0[, d]) * s), abs((at(2100)[rownames(Z0), d] - Z0[, d]) * s))
    data.frame(country = rownames(Z0), driver = d, centreAgrees = sign(beta[[d]]) == EXPECT[[d]],
               against = sign(s) != EXPECT[[d]] & eff >= MIN_EFFECT)
  }))
  countries <- data.frame(variant = label, sector = sec, country = cty, basis = ct$basis, ceiling2023 = ceil,
                          index2023 = S, efficiency2023 = pmin(S / ceil, 1), stringsAsFactors = FALSE)
  grpOf <- function(nm) ifelse(grepl("_x_", nm), "interest x institution terms",
                        ifelse(grepl("Power", nm), "fossil and clean-energy terms",
                        ifelse(grepl("WGI|VDem", nm), "institutions", "everything else")))
  fx <- sel & mats$scenRegion %in% FOCUS
  Xf <- buildX(mats$scen[fx, , drop = FALSE]); Cf <- sweep(Xf, 2, beta[colnames(Xf)], `*`)
  terms <- do.call(rbind, lapply(unique(grpOf(cols)), function(gname) data.frame(
    variant = label, sector = sec, country = mats$scenRegion[fx], year = mats$scenYear[fx], group = gname,
    value = rowSums(Cf[, grpOf(colnames(Cf)) == gname, drop = FALSE]))))
  list(rank = rank, strength = strength, dir = cbind(variant = label, sector = sec, dir), countries = countries, terms = terms)
}
FOCUS <- c("CHN", "SAU", "IND", "RUS", "DEU", "USA")
capTf <- function(sampleX, which) {      # cap the given factor columns at the sample's percentiles
  lo <- apply(sampleX[, which, drop = FALSE], 2, stats::quantile, CAP[1]); hi <- apply(sampleX[, which, drop = FALSE], 2, stats::quantile, CAP[2])
  function(X) { for (m in which) X[, m] <- pmin(pmax(X[, m], lo[[m]]), hi[[m]]); X }
}

# ---- the estimation data of the selected frontier, for the refits ------------------------------------------
fitFrontier <- function(sec) {
  cfg <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = 10,
                                               modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
}
refit <- function(fit, drop = NULL, removeTerms = NULL, exporter = NULL) {
  df <- fit$data; df <- df[!as.character(df$region) %in% drop, , drop = FALSE]
  fml <- stats::as.formula(fit$formula)
  if (!is.null(exporter)) {
    df <- cbind(df, covCols(as.character(df$region), exporter, df))
    fml <- stats::update(fml, stats::as.formula(paste(". ~ . +", paste(MODES[[exporter]], collapse = " + "))))
  }
  if (length(removeTerms)) fml <- stats::update(fml, stats::as.formula(paste(". ~ . -", paste0("`", removeTerms, "`", collapse = " - "))))
  if ("regionFE" %in% names(df)) df$regionFE <- droplevels(df$regionFE)
  m <- frontier::sfa(fml, data = df, maxit = 2000)
  b <- stats::coef(m); b <- b[!names(b) %in% c("sigmaSq", "gamma")]
  names(b) <- gsub("`", "", names(b))
  se <- tryCatch(sqrt(pmax(diag(stats::vcov(m)), 0)), error = function(e) rep(NA_real_, length(stats::coef(m))))
  names(se) <- gsub("`", "", names(stats::coef(m)))
  list(beta = b, gamma = stats::coef(m)[["gamma"]], converged = isTRUE((m$mleIter %||% 0) < 2000), n = nrow(df), se = se,
       logLik = as.numeric(stats::logLik(m)), nPar = length(stats::coef(m)))
}

out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), exporters = exporters, exportRatio = exportRatio,
            autocracies = autocracies, polyarchy = polyarchy,
            coefficients = list(), rank = list(), strength = list(), dir = list(), checks = list())
for (sec in SECS) {
  design <- anc0$EU21$designs[[sec]]
  ctab <- anc0$EU21$country[anc0$EU21$country$sector == sec, ]
  mats <- matsFor(design); matsX <- lapply(names(MODES), function(md) matsFor(design, extra = md)); names(matsX) <- names(MODES)
  fit <- fitFrontier(sec)
  b0 <- design$beta; names(b0)[names(b0) == "(Intercept)"] <- "(Intercept)"
  ref <- refit(fit)
  out$checks[[sec]] <- list(frontierReproduced = max(abs(ref$beta[names(b0)] - b0)))
  ints <- grep("_x_", names(b0), value = TRUE)
  inst <- unique(sub("^.*_x_", "", ints)); intr <- unique(sub("_x_.*$", "", ints))
  sampleX <- mats$hist[sub(" .*$", "", rownames(mats$hist)) %in% unique(fit$data$region), , drop = FALSE]
  tfI <- capTf(sampleX, inst); tfIA <- capTf(sampleX, c(inst, intr))
  edgeCty <- with(edgeRun$bySector[[sec]]$countries, country[edgeInst])

  V <- list(base = list(beta = b0))
  V$O3a <- refit(fit, drop = c("CHN", "SAU"))
  V$O3b <- refit(fit, drop = c("CHN", "SAU", "TUR", "RUS"))
  V$O5a <- refit(fit, removeTerms = ints)
  V$O5b <- refit(fit, removeTerms = grep("Accountability", names(b0), value = TRUE))
  for (md in names(MODES)) V[[md]] <- refit(fit, exporter = md, removeTerms = if (startsWith(md, "A")) intersect(ints, sub("^dem[wl]?__", "", MODES[[md]])) else NULL)
  V$base <- c(ref, V$base[setdiff(names(V$base), names(ref))]); V$base$beta <- b0
  out$coefficients[[sec]] <- lapply(V, function(v) v[intersect(c("beta", "gamma", "converged", "n", "se", "logLik", "nPar"), names(v))])
  runs <- list(
    base = evaluate("base", sec, mats, b0, ctab),
    O1 = evaluate("O1 cap institutions", sec, mats, b0, ctab, tf = tfI),
    O2 = evaluate("O2 cap institutions+interests", sec, mats, b0, ctab, tf = tfIA),
    O6 = evaluate("O6 interactions x0.5", sec, mats, replace(b0, ints, b0[ints] / 2), ctab),
    O7 = evaluate("O7 freeze edge countries", sec, mats, b0, ctab, freeze = edgeCty),
    O3a = evaluate("O3a refit -CHN,SAU", sec, mats, V$O3a$beta, ctab),
    O3b = evaluate("O3b refit -CHN,SAU,TUR,RUS", sec, mats, V$O3b$beta, ctab),
    O5a = evaluate("O5a no interactions", sec, mats, V$O5a$beta, ctab),
    O5b = evaluate("O5b no accountability", sec, mats, V$O5b$beta, ctab),
    E1 = evaluate("E1 exporter as moderator", sec, matsX$E1, V$E1$beta, ctab),
    E2 = evaluate("E2 exporter dummy control", sec, matsX$E2, V$E2$beta, ctab),
    E3 = evaluate("E3 export ratio control", sec, matsX$E3, V$E3$beta, ctab),
    E4 = evaluate("E4 fossil production pc control", sec, matsX$E4, V$E4$beta, ctab),
    A1 = evaluate("A1 autocracy control", sec, matsX$A1, V$A1$beta, ctab),
    A2 = evaluate("A2 regime split", sec, matsX$A2, V$A2$beta, ctab),
    A3 = evaluate("A3 smooth democracy weight", sec, matsX$A3, V$A3$beta, ctab),
    A4 = evaluate("A4 soft-step democracy weight", sec, matsX$A4, V$A4$beta, ctab),
    A5 = evaluate("A5 smooth weight, accountability terms", sec, matsX$A5, V$A5$beta, ctab),
    A6 = evaluate("A6 regime split, accountability terms", sec, matsX$A6, V$A6$beta, ctab),
    A7 = evaluate("A7 smooth weight, accountability and rule-of-law terms", sec, matsX$A7, V$A7$beta, ctab),
    A8 = evaluate("A8 smooth weight, accountability and state-capability terms", sec, matsX$A8, V$A8$beta, ctab))
  # criterion (b) for each coefficient variant: the O1 cap applied on top of it
  for (nm in c("O3a", "O3b", "O5b", names(MODES))) {
    mm <- if (nm %in% names(MODES)) matsX[[nm]] else mats
    runs[[paste0(nm, "+cap")]] <- evaluate(paste0(runs[[nm]]$rank$variant[1], " +cap"), sec, mm, V[[nm]]$beta, ctab, tf = tfI)
  }
  runs[["O6+cap"]] <- evaluate("O6 interactions x0.5 +cap", sec, mats, replace(b0, ints, b0[ints] / 2), ctab, tf = tfI)
  # O4: the passing band's other specifications, each with its own design, standardisation and assignment
  if (WITH_BAND && dir.exists(BAND)) for (sid in sort(list.dirs(BAND, full.names = FALSE, recursive = FALSE))) {
    an <- tryCatch(suppressMessages(computeAnchorGap(sid, resultsDir = BAND, modelDir = modelDir, weights = anc0$EU21$weights,
                                                     mapping = anc0$EU21$mapping, verbose = FALSE)), error = function(e) NULL)
    if (is.null(an)) next
    d <- an$designs[[sec]]; m2 <- matsFor(d); c2 <- an$country[an$country$sector == sec, ]
    lab <- paste("O4", sid, an$spec[[sec]])
    sX <- m2$hist[sub(" .*$", "", rownames(m2$hist)) %in% unique(c2$region[c2$basis == "observed"]), , drop = FALSE]
    i2 <- grep("_x_", names(d$beta), value = TRUE); in2 <- unique(sub("^.*_x_", "", i2))
    runs[[lab]] <- evaluate(lab, sec, m2, d$beta, c2)
    if (length(in2)) runs[[paste(lab, "+cap")]] <- evaluate(paste(lab, "+cap"), sec, m2, d$beta, c2, tf = capTf(sX, in2))
  }
  out$rank[[sec]] <- do.call(rbind, lapply(runs, `[[`, "rank"))
  out$strength[[sec]] <- do.call(rbind, lapply(runs, `[[`, "strength"))
  out$dir[[sec]] <- do.call(rbind, lapply(runs, `[[`, "dir"))
  out$countries[[sec]] <- do.call(rbind, lapply(runs[c("base", "O1", "A2", "A3", "A4")], `[[`, "countries"))
  out$terms[[sec]] <- do.call(rbind, lapply(runs[c("base", "O1", "A2", "A3", "A4")], `[[`, "terms"))
  # the evaluator reproduces the run
  ar <- anc0$EU21$region[anc0$EU21$region$sector == sec, ]
  bu <- out$rank[[sec]][out$rank[[sec]]$variant == "base" & out$rank[[sec]]$resolution == "EU21", ]
  out$checks[[sec]]$uReproduced <- max(abs(bu$u[match(ar$region, bu$region)] - ar$u))
  say(sec, ": frontier refit reproduces frontier.rds to ", signif(out$checks[[sec]]$frontierReproduced, 2),
      "; u reproduced to ", signif(out$checks[[sec]]$uReproduced, 2))
}
rank <- do.call(rbind, out$rank); strength <- do.call(rbind, out$strength); dirs <- do.call(rbind, out$dir)

# ---- the comparison ---------------------------------------------------------------------------------------
variants <- unique(rank$variant[!grepl("[+]cap$", rank$variant)])
summ <- do.call(rbind, lapply(variants, function(v) do.call(rbind, lapply(SECS, function(sec) do.call(rbind, lapply(RES, function(res) {
  r <- rank[rank$variant == v & rank$sector == sec & rank$resolution == res, ]
  r0 <- rank[rank$variant == "base" & rank$sector == sec & rank$resolution == res, ]
  k <- strength[strength$variant == v & strength$sector == sec & strength$resolution == res, ]
  capV <- if (v == "base") "O1 cap institutions" else paste0(v, " +cap")
  if (!capV %in% rank$variant) capV <- NA
  rc <- if (!is.na(capV)) rank[rank$variant == capV & rank$sector == sec & rank$resolution == res, ] else NULL
  kc <- if (!is.na(capV)) strength[strength$variant == capV & strength$sector == sec & strength$resolution == res, ] else NULL
  dd <- dirs[dirs$variant == v & dirs$sector == sec & dirs$centreAgrees, ]
  bad <- if (nrow(dd)) { sh <- lapply(split(dd, dd$driver), function(x) regionShare(res, x$country[x$against]))
    unique(unlist(lapply(sh, function(s) names(s)[s >= SHARE]))) } else character(0)
  du <- if (!is.null(rc) && nrow(rc)) max(abs(rc$u[match(r$region, rc$region)] - r$u)) else NA
  dk <- if (!is.null(kc) && nrow(kc)) max(abs(kc$k[kc$year %in% c(2050, 2100)] - k$k[k$year %in% c(2050, 2100)])) else NA
  uAt <- function(reg) { x <- r$u[r$region == reg]; if (length(x)) round(x, 2) else NA_real_ }
  data.frame(variant = v, sector = sec, resolution = res,
             spearman = round(stats::cor(r$u, r0$u[match(r$region, r0$region)], method = "spearman"), 2),
             uCHA = uAt("CHA"), uMEA = uAt("MEA"), uIND = uAt("IND"), uREF = uAt("REF"),
             k2040 = round(k$k[k$year == 2040], 2), k2050 = round(k$k[k$year == 2050], 2), k2060 = round(k$k[k$year == 2060], 2),
             k2100 = round(k$k[k$year == 2100], 2), rise = round(max(0, max(k$k[k$year >= 2040]) - k$k[k$year == 2040]), 2),
             against = paste(bad, collapse = " "), capDu = round(du, 2), capDk = round(dk, 2),
             pass = length(bad) == 0 & (is.na(du) | du <= 0.25) & (is.na(dk) | dk < 0.10), stringsAsFactors = FALSE)
}))))))
out$summary <- summ
saveRDS(out, file.path(GD, paste0("edge-options", SUFFIX, ".rds")))

options(width = 250)
cat("\nExporters (net energy exports > ", EXPORT_RATIO, " x supply, 2019-2023), in the sample: ",
    paste(intersect(exporters, with(edgeRun$bySector[[1]]$countries, country[inSample])), collapse = " "), "\n", sep = "")
for (sec in SECS) {
  cat("\n================", sec, "================\n")
  cat("checks: frontier refit vs frontier.rds", signif(out$checks[[sec]]$frontierReproduced, 2), "| u vs run", signif(out$checks[[sec]]$uReproduced, 2), "\n")
  print(summ[summ$sector == sec & summ$resolution == "EU21", -c(2, 3)], row.names = FALSE)
  cat("H12 pass:", paste(summ$variant[summ$sector == sec & summ$resolution == "H12" & summ$pass], collapse = "; "), "\n")
  cb <- out$coefficients[[sec]]
  terms <- c("Incumbent.Power", "Incumbent.Power.pc", "Incumbent.Power_x_Vertical.Accountability..VDem.",
             "Innovator.Power_x_Vertical.Accountability..VDem.", "Incumbent.Power.pc_x_Vertical.Accountability..VDem.",
             "exporter", "exporter_x_Incumbent.Power", "exporter_x_Incumbent.Power.pc", "exportRatioStd", "fossilProdPcStd",
             "autocracy", "dem__Incumbent.Power_x_Vertical.Accountability..VDem.",
             "demw__Incumbent.Power_x_Vertical.Accountability..VDem.", "deml__Incumbent.Power_x_Vertical.Accountability..VDem.")
  cat("\nkey coefficients (refits):\n")
  ct <- sapply(cb, function(v) v$beta[terms]); rownames(ct) <- terms; print(round(ct, 3))
  for (md in names(MODES)) { e1 <- cb[[md]]; tt <- intersect(c(MODES[[md]][!grepl("^dem[wl]?__", MODES[[md]])],
                                                               paste0(c("dem__", "demw__", "deml__"), "Incumbent.Power_x_Vertical.Accountability..VDem.")), names(e1$beta))
    cat(md, "z-values (ML, understated by about 2.2-2.4x):", paste(tt, round(e1$beta[tt] / e1$se[tt], 1), collapse = "; "),
        "| gamma", round(e1$gamma, 3), "\n") }
}
