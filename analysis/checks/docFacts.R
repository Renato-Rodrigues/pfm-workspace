# Extract every estimation-side quantity the governed documents quote, for one Run-Group, into
# output/pfm/<group>/doc-facts/facts.json and a readable facts.md.
#   Rscript analysis/checks/docFacts.R v5
# Documents re-read their numbers from here rather than from each other (CLAUDE.md: "Do not copy
# numbers between documents - re-read them from the artifact"). Coupled-run quantities are NOT here:
# they come from the REMIND batch (analysis/coupled/extractCoupledResults.R).
source("analysis/_common/_loadPfm.R")
suppressMessages({library(yaml); library(jsonlite)})
`%||%` <- function(a, b) if (is.null(a)) b else a
GROUP <- local({ a <- commandArgs(trailingOnly = TRUE); a <- a[!grepl("^-", a)]
  if (length(a)) a[1] else yaml::read_yaml("config.yml")$group })
G <- file.path("output/pfm", GROUP); OUT <- file.path(G, "doc-facts")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
rd <- function(x, d = 4) if (is.numeric(x)) round(x, d) else x
SECT <- c("Bulk", "Diffuse")
F <- list(group = GROUP, generated = format(Sys.time()))

## ---- selection --------------------------------------------------------------
sw <- readRDS(file.path(G, "sweep.rds"))
mm <- sw$maximin$PolicyStringency
dep <- sw$selected$PolicyStringency
res <- sw$results[sw$results$stage == "PolicyStringency" & sw$results$model == dep, ]
r <- mm[mm$model == dep, ]
F$spec <- dep
F$selection <- list(
  nSpecsRanked = nrow(mm), nGatePass = sum(mm$gatePass), rank = r$rank, tier = r$minTier,
  meanDeltaR2 = rd(r$meanDeltaR2), minDeltaR2 = rd(r$minDeltaR2), sumBIC = rd(r$sumBIC, 1),
  fragility = r$fragility,
  bySector = lapply(stats::setNames(SECT, SECT), function(s) { x <- res[res$sector == s, ]
    list(deltaR2Theory = rd(x$deltaR2Theory), theoryFrac = rd(x$theoryFrac), pseudoR2 = rd(x$pseudoR2),
         maxVIF = rd(x$maxVIF, 2), trendShare = rd(x$trendShare, 3), tier = x$tier,
         sigActorPower = x$sigActorPower, sigInstQual = x$sigInstQual, sigInteractions = x$sigInteractions,
         nObs = x$nObs, minSigTheoryT = rd(x$minSigTheoryT, 2)) }),
  gates = list(supportShareGate = 0.275, ceilingFallGate = 0.90, gammaGate = 0.999,
               vifHard = 10, vifSoft = 6))
san <- sw$sanity$PolicyStringency
F$sanity <- list(chosen = san$chosen, forced = san$forced,
  deployedFlags = { f <- san$flags[[dep]]; if (is.null(f)) NULL else as.list(table(f$severity)) },
  ceiling = if (!is.null(san$ceiling[[dep]])) as.list(rd(san$ceiling[[dep]])) else NULL,
  gamma = if (!is.null(san$gamma[[dep]])) as.list(rd(san$gamma[[dep]])) else NULL,
  trace = lapply(seq_len(nrow(san$trace)), function(i) list(model = san$trace$model[i],
    pass = san$trace$pass[i], nSevere = san$trace$nSevere[i], reason = san$trace$reason[i] %||% "")))
sv <- readRDS(file.path(G, "selection-variants.rds"))
F$sharing <- lapply(split(sv$perSector, sv$perSector$sector), function(x)
  list(bestModel = x$bestModel, bestDeltaR2 = rd(x$bestDeltaR2), deployedDeltaR2 = rd(x$deployedDeltaR2),
       sharingCost = rd(x$sharingCost), sharingCostShare = rd(x$sharingCostShare)))
F$tierWinners <- as.list(unlist(sv$winners))
bt <- readRDS(file.path(G, "selection-bootstrap.rds"))
top <- function(v, n = 6) { v <- utils::head(v, n); as.list(stats::setNames(rd(as.numeric(v)), names(v))) }
chan <- sub(" .*$", "", sub("^X-[0-9]+ ", "", dep)); form <- regmatches(dep, regexpr("bothIncAP|splitAPpc|mixedAP|compAP|splitAP", dep))
F$bootstrap <- list(nResamples = bt$nResamples, poolSize = bt$poolSize, sanityRejected = length(bt$sanityRejected),
  deployedWinShare = rd(bt$deployedWinShare), deployedWinShareConditional = rd(bt$deployedWinShareConditional),
  deployedChannelSet = chan, deployedForm = form,
  channelSet = top(bt$channelSetFreq), channelSetConditional = top(bt$channelSetFreqConditional),
  apForm = top(bt$apFormFreq), apFormConditional = top(bt$apFormFreqConditional),
  tokens = top(bt$channelTokenFreq, 10), specConditional = top(bt$specFreqConditional))

## ---- mean regression (satP) with wild-cluster inference ---------------------
inf <- readRDS(file.path(G, "inference.rds"))
ea <- readRDS(file.path(G, "estimator-agreement.rds"))
F$meanRegression <- lapply(stats::setNames(SECT, SECT), function(s) {
  t <- inf$bySector[[s]]$table
  list(estimator = "satP (conditional mean, logit of squeezed index)", nClusters = inf$bySector[[s]]$nClusters,
       B = inf$B, terms = lapply(seq_len(nrow(t)), function(i) list(term = t$term[i],
         estimate = rd(t$estimate[i]), pWild = rd(t$pWild[i]), pAsymptotic = rd(t$pAsymptotic[i]),
         ame = rd(t$ame[i]), ameSE = rd(t$ameSE[i])))) })
F$signAgreement <- lapply(stats::setNames(SECT, SECT), function(s) {
  a <- ea$bySector[[s]]$agreement
  list(nTerms = nrow(a) - 1, nAgree = sum(a$signsAgree[a$term != "(phi)"]),
       estimators = ea$bySector[[s]]$fitStats$estimator,
       terms = lapply(seq_len(nrow(a)), function(i) list(term = a$term[i], signs = a$signs[i],
         agree = a$signsAgree[i], nSig05 = a$nSignificant05[i]))) })

## ---- frontier -----------------------------------------------------------------
fr <- readRDS(file.path(G, "frontier.rds"))
F$frontier <- lapply(stats::setNames(SECT, SECT), function(s) { b <- fr$bySector[[s]]; ct <- b$coefTable
  list(gamma = rd(b$gamma, 4), lr = rd(b$lr, 1), n = b$n, converged = b$converged,
       vcov = list(status = b$vcovCheck$status, ratio = rd(b$vcovCheck$ratio, 3)),
       logLik = rd(b$vcovCheck$logLikReported, 1),
       rungs = lapply(b$robustness, function(x) lapply(x, rd)),
       terms = lapply(seq_len(nrow(ct)), function(i) list(term = ct$term[i], estimate = rd(ct$estimate[i]),
         se = rd(ct$stdError[i]), p = signif(ct$pValue[i], 3)))) })

## ---- IV -----------------------------------------------------------------------
iv <- readRDS(file.path(G, "iv.rds"))
F$iv <- lapply(iv$bySector, function(x) {
  ct <- x$coefTable; d <- x$ivDiagnostics; i <- match("Incumbent.Power", ct$term)
  list(n = x$n, incumbent = list(estimate = rd(ct$estimate[i], 2), se = rd(ct$stdError[i], 2), p = rd(ct$pValue[i], 3)),
       firstStageF = rd(d[grepl("^Weak instruments \\(Incumbent.Power\\)", rownames(d)), "statistic"], 2),
       wuHausman = list(statistic = rd(d["Wu-Hausman", "statistic"], 2), p = signif(d["Wu-Hausman", "p-value"], 3))) })

## ---- influence ---------------------------------------------------------------
infl <- readRDS(file.path(G, "influence.rds"))
F$influence <- lapply(stats::setNames(SECT, SECT), function(s) { t <- infl$bySector[[s]]$byTerm
  list(nClusters = infl$bySector[[s]]$nClusters, terms = lapply(seq_len(nrow(t)), function(i)
    list(term = t$term[i], p = rd(t$p[i]), pMin = signif(t$pMin[i], 3), pMax = signif(t$pMax[i], 3),
         nPivotal = t$nPivotal[i], pivotal = t$pivotalClusters[i], topInfluencer = t$topInfluencer[i]))) })

## ---- validation and speeds --------------------------------------------------
tv <- readRDS(file.path(G, "temporal-validation.rds"))
F$temporal <- list(trainEnd = tv$trainEnd, bySector = lapply(tv$bySector, function(x)
  list(static = lapply(x$metrics, rd), ecm = lapply(x$ecm$metrics, rd), events = lapply(x$events$metrics, rd))))
ss <- readRDS(file.path(G, "sector-speeds.rds"))
F$sectorSpeeds <- lapply(ss$bySector, function(x) lapply(x$metrics, rd))
hr <- readRDS(file.path(G, "historical-replay.rds"))
F$replay <- list(pass = hr$pass, seedYear = hr$seedYear, bySector = lapply(hr$bySector, function(x) lapply(x$metrics, rd)))

## ---- PFM-side coupling bound ---------------------------------------------------
cs <- readRDS(file.path(G, "coupling", "coupling-summary.rds"))
ba <- cs$boundAnchor
yr0 <- min(ba$year)
phi0 <- ba[ba$year == yr0, ]
F$bound <- list(anchorTheta = cs$anchorTheta, thetas = cs$thetas, lambda = as.list(rd(cs$lambda)),
  inCoverageCountries = cs$inCoverageCountries, weights = cs$weights$source,
  anchorDerivation = lapply(split(cs$anchorDerivation, cs$anchorDerivation$sector), function(x) lapply(x, rd)),
  thetaSweep = lapply(seq_len(nrow(cs$thetaSweep)), function(i) lapply(cs$thetaSweep[i, ], rd)),
  phiAtAnchor = list(year = yr0, byRegion = as.list(stats::setNames(rd(phi0$phi, 3), phi0$region)),
    floorRegions = sort(phi0$region[abs(phi0$phi - (1 - cs$anchorTheta)) < 1e-6]),
    unconstrained = sort(phi0$region[abs(phi0$phi - 1) < 1e-6]),
    median = rd(stats::median(phi0$phi), 3)),
  bindShare = rd(mean(ba$binds, na.rm = TRUE), 4),
  tiers = as.list(table(cs$tiers$tier)))

## ---- projection fan-out (scenario responsiveness) -----------------------------
pj <- lapply(list.files(file.path(G, "projections"), full.names = TRUE), readRDS)
names(pj) <- sub("\\.rds$", "", list.files(file.path(G, "projections")))
if (length(pj) == 2) {
  a <- pj[[1]]; b <- pj[[2]]
  m <- merge(a[, c("region", "year", "sector", "index", "outOfCoverage")],
             b[, c("region", "year", "sector", "index")], by = c("region", "year", "sector"))
  m <- m[!m$outOfCoverage & m$year >= 2040 & m$year <= 2060, ]
  F$fanOut <- lapply(stats::setNames(SECT, SECT), function(s) { x <- m[m$sector == s, ]
    list(scenarios = names(pj), window = "2040-2060", medianAbsDelta = rd(stats::median(abs(x$index.x - x$index.y)), 4),
         meanDelta = rd(mean(x$index.y - x$index.x), 4)) })
}

## ---- seams ---------------------------------------------------------------------
sd_ <- readRDS(file.path(G, "seam-diagnostics.rds"))
F$seams <- list(n = nrow(sd_), flagged = sum(sd_$flagged), flaggedShare = rd(mean(sd_$flagged), 3),
  worstVariables = as.list(utils::head(sort(tapply(sd_$flagged, sd_$variable, mean), decreasing = TRUE), 5)))

## ---- lambda audit -----------------------------------------------------------------
lf <- file.path(G, "lambda-explained", "facts.json")
if (file.exists(lf)) F$lambdaAudit <- jsonlite::fromJSON(lf, simplifyVector = FALSE)

write(jsonlite::toJSON(F, auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null"), file.path(OUT, "facts.json"))
message("[docFacts] wrote ", file.path(OUT, "facts.json"))
