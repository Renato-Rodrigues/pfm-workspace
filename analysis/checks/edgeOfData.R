# Edge-of-data evaluation (design note 0007): where a driver of the selected frontier acts against the logic
# the frontier is read with, in which countries and regions, and whether that comes from evaluating the
# interest x institution terms far from the estimation sample.
#   Rscript analysis/checks/edgeOfData.R [group] [scenario panel .rds]      (repo root; default v6 and
#   output/pfm/<group>/coupling/scen-PFMlevelBfix-<group>.rds, which analysis/v6/couplingMechanism.R builds from
#   the coupled hold-the-price headline run; any country-level scenario panel of panelDataScenario() works)
#
# Generic over the specification: drivers, interaction pairs and institutions are read from the selected
# frontier's term names, so the same script runs on v7 and later. Per sector:
#   A. Position. Every country's institutions and interests (standardised, at the first scenario year) against
#      the estimation sample: Mahalanobis distance (flag above the chi-square 0.99 quantile) and the number of
#      sample countries within RADIUS standard deviations (flag below MIN_NEIGHBOURS).
#   B. Direction. Each driver's effective slope at the country's own values, beta_d + sum beta_{d x m} x_m, against
#      (i) its sign at the sample centre (beta_d: the sample's own logic) and (ii) the theory sign (EXPECT).
#   C. Weight along the pathway. The ceiling change (logit units) caused by each driver moving alone from the
#      first scenario year to 2050 and 2100, and the swing of the interaction terms against the main effects.
#   D. Regions. For each resolution, the final-energy share of each region in countries flagged in A, B or C.
#   E. Cap test. Moderators inside the interaction terms capped at the sample's 5th-95th percentiles (main effects
#      untouched): the change in the 2023 regional ranking u and in the strength k(t), against the model as run.
# Writes output/pfm/<group>/edge-of-data.rds and prints the attention list.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
a <- commandArgs(trailingOnly = TRUE)
g <- if (length(a) >= 1) a[1] else "v6"
SCEN <- if (length(a) >= 2) a[2] else file.path("output/pfm", g, "coupling", paste0("scen-PFMlevelBfix-", g, ".rds"))
RES <- c("EU21", "H12")
YEARS <- c(2050, 2100)
RADIUS <- 1.5; MIN_NEIGHBOURS <- 3; CAP <- c(0.05, 0.95)
MIN_EFFECT <- 0.25      # logit units: a contradiction smaller than this is not reported
# the theory sign of each driver (ADR 0056, design note 0007 section 2); NA = no prior (only the pair, or a control)
EXPECT <- c(Innovator.Power = 1, Incumbent.Power = -1, Incumbent.Power.pc = NA,
            Government.Effectiveness..WGI. = 1, Rule.of.Law..VDem. = 1, Vertical.Accountability..VDem. = 1,
            Overall.Accountability..VDem. = 1)
# a spec that measures an interest per person only (splitAPpc) carries the interest's sign on that form, as the
# sweep's gate reads it (.pfmEdgeGate)
expectFor <- function(beta) {
  e <- EXPECT
  for (d in c("Innovator.Power", "Incumbent.Power")) {
    if (!d %in% names(beta) && paste0(d, ".pc") %in% names(beta)) e[[paste0(d, ".pc")]] <- e[[d]]
  }
  e
}
say <- function(...) message("[edge] ", ...)

suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"),
                                   forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup(file.path("output/pfm", g), rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
anc <- setNames(lapply(RES, function(r) pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), r)), RES)
if (!file.exists(SCEN)) stop("no scenario panel at ", SCEN, " - run analysis/v6/couplingMechanism.R ", g, " first")
scen <- readRDS(SCEN)
fr <- readRDS(file.path("output/pfm", g, "frontier.rds"))$bySector

# the frontier's design matrix for every country-year: .pfmFrontierEta with its last line returning the parts
designMatrix <- function(design, data) {
  f <- pfm:::.pfmFrontierEta; b <- body(f)
  b[[length(b)]] <- quote(list(df = df, mm = mm[, names(design$beta), drop = FALSE]))
  body(f) <- b; f(design, data)
}
mapOf <- function(res) pfm:::.pfmResolveCountryMap(anc[[res]]$mapping)
regionShare <- function(res, countries) {           # final-energy share of each region held by `countries`
  w <- anc[[res]]$weights; m <- mapOf(res); cc <- intersect(names(m), names(w))
  tot <- tapply(w[cc], m[cc], sum); hit <- tapply(w[cc] * (cc %in% countries), m[cc], sum)
  hit / tot
}
aggGap <- function(res, S, Sstar, year) {            # country index and ceiling -> regional relative gap
  p <- data.frame(region = names(S), year = year, feasibleIndex = S, ceilingIndex = Sstar, outOfCoverage = FALSE)
  r <- suppressWarnings(suppressMessages(aggregateFeasibilityToRegions(p, anc[[res]]$mapping, weights = anc[[res]]$weights)))
  setNames(r$relativeGap, r$region)
}
minmax <- function(x) (x - min(x)) / (max(x) - min(x))

out <- list(group = g, scenario = basename(SCEN), made = format(Sys.time(), "%Y-%m-%d %H:%M"),
            settings = list(radius = RADIUS, minNeighbours = MIN_NEIGHBOURS, cap = CAP, minEffect = MIN_EFFECT,
                            expect = EXPECT), bySector = list())
for (sec in names(anc$EU21$designs)) {
  design <- anc$EU21$designs[[sec]]; beta <- design$beta; EXPECT <- expectFor(beta)
  dm <- designMatrix(design, scen); df <- dm$df; mm <- dm$mm
  # a democracy-weighted spec (interactionWeight, design note 0007): its interactions carry the weight
  w__ <- if ("interactionWeight__" %in% names(df)) df$interactionWeight__ else rep(1, nrow(df))
  w__[!is.finite(w__)] <- 1
  mm <- cbind(mm, w__ = w__)
  yrs <- sort(unique(df$year)); Y0 <- min(yrs[yrs >= 2025]); YR <- intersect(YEARS, yrs)
  ints <- grep("_x_", names(beta), value = TRUE)
  pairs <- do.call(rbind, strsplit(ints, "_x_", fixed = TRUE)); colnames(pairs) <- c("A", "M"); rownames(pairs) <- ints
  # interaction columns are products of the standardised factors (preparePanelData); check before relying on it
  chk <- max(abs(mm[, ints] - mm[, pairs[, "A"]] * mm[, pairs[, "M"]] * mm[, "w__"]), na.rm = TRUE)
  if (chk > 1e-8) stop(sec, ": interaction columns are not products of their factors (max dev ", chk, ")")
  drivers <- setdiff(names(beta), c(ints, "(Intercept)", grep("regionFE|[Tt]rend", names(beta), value = TRUE)))
  moder <- unique(pairs[, "M"]); inter <- unique(pairs[, "A"])
  sample <- unique(fr[[sec]]$scores$region)
  at <- function(y) { i <- which(df$year == y); x <- mm[i, , drop = FALSE]; rownames(x) <- df$region[i]; x }
  X0 <- at(Y0); cty <- rownames(X0); S0 <- X0[intersect(sample, cty), , drop = FALSE]

  # A. position against the sample (institutions = the moderators; interests separately)
  pos <- function(cols) {
    Z <- X0[, cols, drop = FALSE]; Zs <- S0[, cols, drop = FALSE]
    D <- sqrt(stats::mahalanobis(Z, colMeans(Zs), stats::cov(Zs)))
    nb <- sapply(cty, function(c) sum(sqrt(colSums((t(Zs) - Z[c, ])^2)) <= RADIUS) - (c %in% sample))
    data.frame(D = D, neighbours = nb, edge = D > sqrt(stats::qchisq(0.99, length(cols))) | nb < MIN_NEIGHBOURS)
  }
  pI <- pos(moder); pA <- pos(inter)

  # B. effective slope of every driver at each country's own values, first scenario year
  slope <- function(X) sapply(drivers, function(d) {
    s <- rep(beta[[d]], nrow(X))
    for (k in ints[pairs[, "A"] == d]) s <- s + beta[[k]] * X[, pairs[k, "M"]] * X[, "w__"]
    for (k in ints[pairs[, "M"] == d]) s <- s + beta[[k]] * X[, pairs[k, "A"]] * X[, "w__"]
    s })
  sl0 <- slope(X0); rownames(sl0) <- cty
  centre <- sign(beta[drivers])

  # C. each driver moving alone from Y0 (the others at Y0): the change in the logit ceiling, exact for this design
  dEta <- lapply(YR, function(y) {
    X1 <- at(y)[cty, , drop = FALSE]; (X1[, drivers] - X0[, drivers]) * sl0 })
  names(dEta) <- YR
  contribInt <- function(X) as.vector(X[, ints, drop = FALSE] %*% beta[ints])
  contribMain <- function(X) as.vector(X[, inter, drop = FALSE] %*% beta[inter])
  pathInt <- sapply(yrs[yrs >= Y0 & yrs <= 2100], function(y) contribInt(at(y)[cty, , drop = FALSE]))
  pathMain <- sapply(yrs[yrs >= Y0 & yrs <= 2100], function(y) contribMain(at(y)[cty, , drop = FALSE]))
  swingInt <- apply(pathInt, 1, function(v) max(v) - min(v)); swingMain <- apply(pathMain, 1, function(v) max(v) - min(v))

  # long table: country x driver
  long <- do.call(rbind, lapply(drivers, function(d) data.frame(
    country = cty, sector = sec, driver = d, inSample = cty %in% sample,
    slope = sl0[, d], centre = centre[[d]], theory = if (d %in% names(EXPECT)) EXPECT[[d]] else NA_real_,
    flipCentre = sign(sl0[, d]) != centre[[d]] & abs(sl0[, d]) > abs(beta[[d]]) / 2,
    dEta2050 = if ("2050" %in% names(dEta)) dEta[["2050"]][, d] else NA,
    dEta2100 = if ("2100" %in% names(dEta)) dEta[["2100"]][, d] else NA,
    edgeInst = pI$edge, edgeInterest = pA$edge, stringsAsFactors = FALSE)))
  long$flipTheory <- !is.na(long$theory) & sign(long$slope) != long$theory
  # a contradiction that matters: the driver moves the ceiling against its sample-centre sign by MIN_EFFECT or more
  big <- pmax(abs(long$dEta2050), abs(long$dEta2100), na.rm = TRUE)
  long$contradicts <- long$flipCentre & big >= MIN_EFFECT
  long$effect <- big

  ctab <- data.frame(country = cty, sector = sec, inSample = cty %in% sample,
                     DInst = pI$D, neighboursInst = pI$neighbours, edgeInst = pI$edge,
                     DInterest = pA$D, neighboursInterest = pA$neighbours, edgeInterest = pA$edge,
                     interaction0 = contribInt(X0), swingInteraction = swingInt, swingMain = swingMain,
                     swingFlag = swingInt > 2 & swingInt > swingMain, stringsAsFactors = FALSE)

  # E. cap test: moderators capped inside the interaction terms only
  lo <- apply(S0[, moder, drop = FALSE], 2, stats::quantile, CAP[1]); hi <- apply(S0[, moder, drop = FALSE], 2, stats::quantile, CAP[2])
  capDelta <- function(X) {                         # eta change from capping, any year
    dl <- rep(0, nrow(X))
    for (k in ints) { m <- pairs[k, "M"]; mc <- pmin(pmax(X[, m], lo[[m]]), hi[[m]]); dl <- dl + beta[[k]] * X[, pairs[k, "A"]] * (mc - X[, m]) * X[, "w__"] }
    dl }
  capped <- names(which(apply(X0[, moder, drop = FALSE], 1, function(v) any(v < lo | v > hi))))
  ac <- anc$EU21$country[anc$EU21$country$sector == sec & is.finite(anc$EU21$country$q), ]
  ac <- ac[ac$region %in% cty, ]; rownames(ac) <- ac$region
  d0 <- setNames(capDelta(X0[ac$region, , drop = FALSE]), ac$region)
  ceilCap <- 10 * stats::plogis(ac$etaAnchor + d0)
  E <- pmin(ac$indexAnchor / ac$ceilingAnchor, 1)
  Scap <- ifelse(ac$basis == "observed", ac$indexAnchor, E * ceilCap)       # observed policy fixed; borrowed E fixed
  qCap <- (ac$etaAnchor + d0) - stats::qlogis(pmin(pmax(Scap / 10, 1e-6), 1 - 1e-6))
  rank <- list(); strength <- list()
  for (res in RES) {
    gA <- aggGap(res, setNames(ac$indexAnchor, ac$region), setNames(ac$ceilingAnchor, ac$region), 2023)
    gC <- aggGap(res, setNames(Scap, ac$region), setNames(ceilCap, ac$region), 2023)
    ar <- anc[[res]]$region; ar <- ar[ar$sector == sec, ]; uRun <- setNames(ar$u, ar$region)
    rr <- names(uRun)
    rank[[res]] <- data.frame(resolution = res, sector = sec, region = rr, uRun = uRun[rr], uCheck = minmax(gA)[rr],
                              uCapped = minmax(gC)[rr], stringsAsFactors = FALSE)
    wR <- anc[[res]]$regionWeights
    kpath <- function(cap) sapply(yrs[yrs >= Y0 & yrs <= 2100], function(y) {
      X <- at(y)[ac$region, , drop = FALSE]
      eta <- as.vector(X[, names(beta), drop = FALSE] %*% beta) + if (cap) capDelta(X) else 0
      q <- if (cap) qCap else ac$q
      gr <- aggGap(res, setNames(10 * stats::plogis(eta - q), ac$region), setNames(10 * stats::plogis(eta), ac$region), y)
      sum(wR[names(gr)] * gr, na.rm = TRUE) / sum(wR[names(gr)][is.finite(gr)]) })
    kr <- kpath(FALSE); kc <- kpath(TRUE)
    strength[[res]] <- data.frame(resolution = res, sector = sec, year = yrs[yrs >= Y0 & yrs <= 2100],
                                  kRun = kr / kr[1], kCapped = kc / kc[1])
  }
  out$bySector[[sec]] <- list(drivers = drivers, moderators = moder, capBounds = rbind(lo = lo, hi = hi), capped = capped,
                              countries = ctab, long = long, ranking = do.call(rbind, rank), strength = do.call(rbind, strength))
  say(sec, ": ", length(cty), " countries, ", length(sample), " in the sample; edge (institutions) ",
      paste(intersect(sample, cty[pI$edge]), collapse = " "), " in the sample, ", sum(pI$edge), " in all; capped ", length(capped))
}

# D. the attention list: region x sector x driver where flagged countries hold a material share of final energy
att <- list()
for (sec in names(out$bySector)) {
  L <- out$bySector[[sec]]$long; C <- out$bySector[[sec]]$countries
  for (res in RES) {
    edgeShare <- regionShare(res, C$country[C$edgeInst])
    swingShare <- regionShare(res, C$country[C$swingFlag])
    for (d in unique(L$driver[L$contradicts])) {
      who <- L$country[L$driver == d & L$contradicts]
      sh <- regionShare(res, who); sh <- sh[sh >= 0.10]
      if (!length(sh)) next
      m <- mapOf(res)
      att[[length(att) + 1]] <- data.frame(resolution = res, sector = sec, driver = d, region = names(sh),
        shareContradicting = as.numeric(sh), shareEdgeInst = as.numeric(edgeShare[names(sh)]),
        shareSwing = as.numeric(swingShare[names(sh)]),
        shareEdgeInterest = as.numeric(regionShare(res, C$country[C$edgeInterest])[names(sh)]),
        countries = sapply(names(sh), function(r) {
          cc <- intersect(who, names(m)[m == r]); w <- anc[[res]]$weights[cc]
          paste(head(cc[order(-w)], 5), collapse = " ") }), stringsAsFactors = FALSE)
    }
  }
}
out$attention <- if (length(att)) do.call(rbind, att) else NULL
# one row per resolution x sector x region: what flags it, and what the cap test does to its rank
short <- function(d) c(Innovator.Power = "clean", Incumbent.Power = "fossil", Incumbent.Power.pc = "fossil pc",
                       Government.Effectiveness..WGI. = "state cap.", Rule.of.Law..VDem. = "rule of law",
                       Vertical.Accountability..VDem. = "accountab.")[d]
out$regions <- do.call(rbind, lapply(names(out$bySector), function(sec) {
  B <- out$bySector[[sec]]; C <- B$countries
  do.call(rbind, lapply(RES, function(res) {
    R <- B$ranking[B$ranking$resolution == res, ]
    A <- if (is.null(out$attention)) NULL else out$attention[out$attention$resolution == res & out$attention$sector == sec, ]
    data.frame(resolution = res, sector = sec, region = R$region,
               edgeInst = as.numeric(regionShare(res, C$country[C$edgeInst])[R$region]),
               edgeInterest = as.numeric(regionShare(res, C$country[C$edgeInterest])[R$region]),
               swing = as.numeric(regionShare(res, C$country[C$swingFlag])[R$region]),
               drivers = sapply(R$region, function(r) {
                 x <- A[A$region == r & A$shareContradicting >= 0.25, ]
                 if (is.null(x) || !nrow(x)) return("")
                 paste0(short(x$driver), " ", round(100 * x$shareContradicting), "%", collapse = ", ") }),
               uRun = R$uRun, uCapped = R$uCapped, stringsAsFactors = FALSE)
  }))
}))
saveRDS(out, file.path("output/pfm", g, "edge-of-data.rds"))
saveRDS(out, file.path("output/pfm", g, "edge-of-data.rds"))

# ---- print ------------------------------------------------------------------------------------------------
for (sec in names(out$bySector)) {
  B <- out$bySector[[sec]]; L <- B$long
  cat("\n================", sec, "================\n")
  cat("Sample countries at the edge of the institution space (Mahalanobis D, neighbours within", RADIUS, "SD):\n")
  e <- B$countries[B$countries$inSample & B$countries$edgeInst, c("country", "DInst", "neighboursInst", "interaction0", "swingInteraction", "swingMain")]
  print(e[order(-e$DInst), ], row.names = FALSE, digits = 3)
  cat("\nDrivers whose effect contradicts the sample-centre sign, by number of countries (all / in sample / at the edge):\n")
  s <- aggregate(cbind(all = contradicts, sample = contradicts & inSample, edge = contradicts & edgeInst) ~ driver, L, sum)
  print(s[order(-s$all), ], row.names = FALSE)
  cat("\nLargest contradicting effects (logit units, driver moving alone to 2050 / 2100):\n")
  x <- L[L$contradicts, c("country", "driver", "inSample", "edgeInst", "slope", "centre", "dEta2050", "dEta2100")]
  print(head(x[order(-pmax(abs(x$dEta2050), abs(x$dEta2100))), ], 15), row.names = FALSE, digits = 2)
  cat("\nCap test - the regional ranking u (run, reproduced, capped) where it moves by 0.15 or more:\n")
  R <- B$ranking; R$dU <- R$uCapped - R$uRun; print(R[abs(R$dU) >= 0.15, ], row.names = FALSE, digits = 2)
  cat("max |u reproduced - u run|:", signif(max(abs(R$uCheck - R$uRun), na.rm = TRUE), 2), "\n")
  cat("\nCap test - strength k(t), run vs capped:\n")
  K <- B$strength[B$strength$year %in% c(2030, 2040, 2050, 2060, 2080, 2100), ]
  print(reshape(K, idvar = c("resolution", "sector", "year"), direction = "long", varying = c("kRun", "kCapped"),
                v.names = "k", timevar = "case", times = c("run", "capped"))[, c("resolution", "case", "year", "k")] |>
          reshape(idvar = c("resolution", "case"), timevar = "year", direction = "wide"), row.names = FALSE, digits = 2)
}
cat("\n================ Regions: share of final energy at the edge (institutions / interests) or swinging; drivers contradicting in >= 25%; rank as run vs capped ================\n")
print(out$regions, row.names = FALSE, digits = 2)
cat("\n================ Attention list (regions where contradicting countries hold >= 10% of final energy) ================\n")
if (!is.null(out$attention)) print(out$attention[order(out$attention$resolution, out$attention$sector, -out$attention$shareContradicting), ],
                                   row.names = FALSE, digits = 2)
