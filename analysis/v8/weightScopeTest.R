# Which institutions the freedom-of-expression weight should condition: a targeted test on the selected specification.
#   Rscript analysis/v8/weightScopeTest.R [group] [walk]    (repo root; default v8; "walk" adds the sanity walk)
#     -> output/pfm/<group>/weight-scope-test.rds
# The question (author, 2026-11-09). The selected specification weights every fossil and clean-energy x institution
# interaction by V-Dem freedom of expression (iw:fexp). For vertical accountability the weight is close to part of the
# institution itself, so fossil x accountability x weight may act as a non-linear accountability term (a double count)
# rather than a conditioning. The test: weight only the state-capacity and rule-of-law interactions, or either alone,
# and leave accountability unweighted.
# Variants of the selected specification, everything else fixed (the weight scope is the only change):
#   all      every interaction weighted (the selected specification, iw:fexp)        - control: reproduces the sweep
#   none     no weight                                                                - the sweep has it
#   accRoL   accountability and rule of law weighted (in the sweep, design note 0007 A7) - the sweep has it
#   geRoL    state capacity and rule of law weighted, accountability not             - the proposal
#   ge       state capacity only;  rol  rule of law only;  acc  accountability only  - its parts, and the reverse
# The scopes beyond accRoL are not in the package: this script adds them to pfm's .pfmIwScopes for this session only
# (assignInNamespace), so nothing in the package or the fit cache changes; the fits are not cached (modelDir NULL; the
# walk caches in a temporary folder).
# Reported per variant and sector:
#   0. on the estimation sample: the correlation of the weight with each institution, and how much of each weighted
#      institution (institution x weight) a quadratic in that institution explains (R^2) - the double-count diagnostic;
#   1. the sweep's metrics (runFitGrid: ΔR²(theory), BIC, max VIF, tier) and the admissibility gates and rank had the
#      variant been in the search (computeMaximinScore on the sweep's rows plus the variant's, the cluster job's settings);
#   2. the theory gate H1-H2 at p 0.05 and 0.10 (.pfmTheoryScreen), with the smallest fossil x institution p and its
#      Bonferroni level; the fossil and fossil x institution coefficients;
#   3. wild-cluster bootstrap p of those terms (B 999, computeWildClusterBootstrap), as MODEL.md quotes them;
#   4. leave-one-country-out stability of those terms (computeInfluenceDiagnostics, largest p, the pivotal country);
#   5. with "walk": the sanity walk (.pfmSanitySelect: γ gate, H3, edge-of-data, support share, ceiling fall,
#      responsiveness) on the coupled 1000 Gt and NPi drivers (EU21), as the cluster walk runs it.
#      PFM_WALK_VARIANTS=all,geRoL,ge walks only those variants (default: all seven).
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v8"; WALK <- "walk" %in% args
GD <- file.path("output/pfm", g)
say <- function(...) message("[weight-scope:", g, "] ", ...)
options(pfm.panel = list(firstYear = 2000L, lastYear = 2023L, movingAverage = 5L, ieaVersion = "latest", geothermal = TRUE,
                         democracy = TRUE, overallAccountability = TRUE, fossilRents = TRUE))
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g)), forcecache = TRUE, .verbose = FALSE)

# the scopes, for this session: accRoL keeps position 1 (the code the package's own accRoL twins carry)
SCOPES <- c(accRoL = "Accountability|Rule\\.of\\.Law", geRoL = "Government\\.Effectiveness|Rule\\.of\\.Law",
            ge = "Government\\.Effectiveness", rol = "Rule\\.of\\.Law", acc = "Accountability")
stopifnot(identical(pfm:::.pfmIwScopes[["accRoL"]], SCOPES[["accRoL"]]))
utils::assignInNamespace(".pfmIwScopes", SCOPES, ns = "pfm")

sw <- readRDS(file.path(GD, "sweep.rds"))
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
specByName <- stats::setNames(sw$specs, vapply(sw$specs, `[[`, character(1), "name"))
SEL <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))[[1]]$name
base <- specByName[[SEL]]; stopifnot(identical(base$interactionWeight, "Freedom of Expression (VDem)"))
SECTORS <- c(Bulk = "power & industry", Diffuse = "buildings & transport")
W <- "Freedom of Expression (VDem)"
stem <- sub(" iw:fexp fos5$", "", SEL)
VARIANTS <- list(all = W, none = NULL, accRoL = paste0(W, "@accRoL"), geRoL = paste0(W, "@geRoL"),
                 ge = paste0(W, "@ge"), rol = paste0(W, "@rol"), acc = paste0(W, "@acc"))
specs <- lapply(names(VARIANTS), function(v) {
  cfg <- base; cfg$interactionWeight <- VARIANTS[[v]]
  cfg$name <- switch(v, all = SEL, none = paste0(stem, " fos5"), paste0(stem, " iw:fexp@", v, " fos5"))
  cfg
})
names(specs) <- names(VARIANTS)
inSweep <- vapply(specs, function(cfg) cfg$name %in% names(specByName), logical(1))
say("variants: ", paste(sprintf("%s%s", names(specs), ifelse(inSweep, " (in the sweep)", "")), collapse = ", "))

# 1. the sweep's fits for every variant -------------------------------------------------------------------------------
fg <- runFitGrid(unname(specs), sectors = names(SECTORS), stages = "PolicyStringency", panelData = panel,
                 modelDir = NULL, verbose = FALSE)
res <- fg$results; co <- fg$coefficients
# the check: the variants the sweep fitted are reproduced (coefficients and p to 1e-6)
for (v in names(specs)[inSweep]) {
  a <- co[co$model == specs[[v]]$name, ]; b <- sw$coefficients[sw$coefficients$model == specs[[v]]$name, ]
  k <- match(paste(a$sector, a$term), paste(b$sector, b$term))
  d <- max(abs(a$estimate - b$estimate[k]), abs(a$pValue - b$pValue[k]))
  say("check ", v, ": max |difference| to the sweep ", signif(d, 2)); stopifnot(d < 1e-6)
}
# the ranking had the variants been in the search (the cluster job's settings, as analysis/v8/perSectorSelection.R)
sub <- sw$results[sw$results$stage == "PolicyStringency" & !sw$results$model %in% res$model, , drop = FALSE]
add <- res; for (k in setdiff(colnames(sub), colnames(add))) add[[k]] <- NA
sub <- rbind(sub, add[add$stage == "PolicyStringency", colnames(sub)])
sub <- sub[grepl("fe:(H12|OECDp|Mundlak)", sub$model), , drop = FALSE]
mmCols <- intersect(c("model", "sector", "sigActorPower", "sigInstQual", "sigInteractions", "deltaR2Theory", "pseudoR2", "bic",
                      "maxVIF", "converged", "usesLagged", "nFE", "nObs", "sigControl", "nControl", "trendShare", "minSigTheoryT"),
                    colnames(sub))
mm <- computeMaximinScore(sub[, mmCols, drop = FALSE], nearTieEps = 0.025, feParsimonyWeight = 0, dropIdleControls = TRUE,
                          softVifGate = Inf, trendDominanceGate = 0.9, deltaR2Max = 1, inferenceTGate = 0,
                          rankBy = "worseDeltaR2", tierGate = "Green")
allCoef <- rbind(sw$coefficients[!sw$coefficients$model %in% co$model, colnames(co)], co)
th05 <- pfm:::.pfmTheoryScreen(allCoef, unique(mm$model[mm$gatePass]), names(SECTORS), list(p = 0.05))
mm$theoryPass <- mm$model %in% th05$model[th05$pass]
mm$pool <- mm$gatePass & mm$theoryPass
ord <- order(mm$rank); mm$poolRank <- NA_integer_; mm$poolRank[ord[mm$pool[ord]]] <- seq_len(sum(mm$pool))
selPool <- mm$poolRank[mm$model == SEL]
say("pool with the variants: ", sum(mm$pool), " (the sweep: 80); the selected specification at pool position ", selPool)

# 0, 2-4 per variant and sector: the satP refit (the engine the gate reads), its terms, the wild bootstrap, the LOO
FOSSIL <- c("Incumbent.Power", "Incumbent.Power.pc")
INST <- c(GE = "Government.Effectiveness..WGI.", RoL = "Rule.of.Law..VDem.", Acc = "Vertical.Accountability..VDem.")
theoryTerms <- c(FOSSIL, as.vector(outer(FOSSIL, INST, paste, sep = "_x_")))
rows <- list(); corr <- list(); loo <- list()
for (v in names(specs)) for (sec in names(SECTORS)) {
  cfg <- specs[[v]]
  fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "satP", indexMax = 10,
                                                       modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
  df <- fit$data
  if (v == "all") {   # the double-count diagnostic, once per sector (the weight and the institutions do not depend on the scope)
    w <- df$interactionWeight__
    corr[[sec]] <- do.call(rbind, lapply(names(INST), function(i) {
      x <- df[[INST[[i]]]]; ok <- is.finite(x) & is.finite(w)
      q <- summary(stats::lm(I(x * w) ~ x + I(x^2), subset = ok))$r.squared
      data.frame(sector = SECTORS[[sec]], institution = i, n = sum(ok), pearson = stats::cor(x[ok], w[ok]),
                 spearman = stats::cor(x[ok], w[ok], method = "spearman"), r2WeightedOnQuadratic = q)
    }))
  }
  ct <- as.data.frame(unclass(fit$coeftest)); ct$term <- rownames(ct)
  wb <- computeWildClusterBootstrap(fit, B = 999, seed = 42)
  inf <- computeInfluenceDiagnostics(fit, terms = intersect(theoryTerms, ct$term), alpha = 0.05, wcb = FALSE, verbose = FALSE)
  tt <- intersect(theoryTerms, ct$term)
  rows[[paste(v, sec)]] <- data.frame(variant = v, sector = SECTORS[[sec]], term = tt, estimate = ct[tt, 1], pAsym = ct[tt, 4],
                                      pWild = wb$pWild[match(tt, wb$term)],
                                      pLooMax = inf$byTerm$pMax[match(tt, inf$byTerm$term)],
                                      looPivotal = inf$byTerm$pivotalLossClusters[match(tt, inf$byTerm$term)],
                                      logLik = as.numeric(stats::logLik(fit$model)))
  say(v, " ", sec, " done")
}
terms <- do.call(rbind, rows); rownames(terms) <- NULL
corr <- do.call(rbind, corr); rownames(corr) <- NULL

saveRDS(list(terms = terms, corr = corr, res = res, co = co, mm = mm[mm$model %in% vapply(specs, `[[`, "", "name"), ]),
        file.path(tempdir(), "weight-scope-raw.rds"))
one <- function(x) if (length(x)) x[1] else NA
# the summary table, one row per variant and sector
gate <- function(p) pfm:::.pfmTheoryScreen(co, vapply(specs, `[[`, "", "name"), names(SECTORS), list(p = p))
g05 <- gate(0.05); g10 <- gate(0.10)
summ <- do.call(rbind, lapply(names(specs), function(v) do.call(rbind, lapply(names(SECTORS), function(sec) {
  nm <- specs[[v]]$name; r <- res[res$model == nm & res$sector == sec, ]
  x <- terms[terms$variant == v & terms$sector == SECTORS[[sec]], ]
  fos <- if ("Incumbent.Power" %in% x$term) "Incumbent.Power" else "Incumbent.Power.pc"
  k <- grepl("_x_", x$term); j <- which(k)[which.min(x$pAsym[k])]
  data.frame(variant = v, sector = SECTORS[[sec]], deltaR2Theory = one(r$deltaR2Theory), bic = one(r$bic), maxVIF = one(r$maxVIF),
             tier = one(r$tier), fossil = one(x$estimate[x$term == fos]), pFossilWild = one(x$pWild[x$term == fos]),
             pFossilLooMax = one(x$pLooMax[x$term == fos]), H2term = one(x$term[j]), H2estimate = one(x$estimate[j]), H2pAsym = one(x$pAsym[j]),
             H2pWild = one(x$pWild[j]), H2bonferroni = 0.05 / sum(k), H2pLooMax = one(x$pLooMax[j]), H2looPivotal = one(x$looPivotal[j]),
             nSigInteractionsWild = sum(x$pWild[k] < 0.05 / sum(k)),
             gatesBeforeTheory = one(mm$gatePass[mm$model == nm][1]), gateFail = one(mm$gateFailReason[mm$model == nm][1]),
             rank = one(mm$rank[mm$model == nm][1]), H1H2at05 = one(g05$pass[g05$model == nm]), H1H2at10 = one(g10$pass[g10$model == nm]),
             poolRank = one(mm$poolRank[mm$model == nm][1]), theoryFail05 = one(g05$reason[g05$model == nm]))
}))))

# 5. the sanity walk (optional) --------------------------------------------------------------------------------------
walk <- NULL
if (WALK) {
  mk <- function(gdx) panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                                        outputRegionMappingFile = "country", histYears = pfm:::.pfmPanelYears(),
                                        movingAverage = pfm:::.pfmPanelMA())
  gating <- mk("output/remind-runs/v6/EU21/SSP2-EU21-PkBudg1000_2026-10-07_19.04.46/fulldata.gdx")
  reference <- mk("output/remind-runs/v6/EU21/SSP2-EU21-NPi2025_2026-10-07_12.36.43/fulldata.gdx")
  cacheDir <- file.path(tempdir(), "fit-cache-weight-scope"); dir.create(cacheDir, showWarnings = FALSE)
  sb <- c(specByName[setdiff(names(specByName), vapply(specs, `[[`, "", "name"))], stats::setNames(specs, vapply(specs, `[[`, "", "name")))
  walkV <- strsplit(Sys.getenv("PFM_WALK_VARIANTS", paste(names(specs), collapse = ",")), ",")[[1]]   # e.g. all,geRoL,ge
  walk <- lapply(stats::setNames(walkV, walkV), function(v) {
    say("walk: ", v, " ...")
    tryCatch(pfm:::.pfmSanitySelect(passModels = specs[[v]]$name, specByName = sb, sectors = names(SECTORS), panelData = panel,
                                    scenarioData = gating, modelDir = cacheDir, batchSize = 5, maxModels = 1, thresholds = list(),
                                    regionBlocks = pfm:::.h12RegionBlocks(),
                                    histIndexBySector = pfm:::.histIndexBySector(panel, names(SECTORS)), indexMax = 10,
                                    referenceScenarioData = reference, minScenarioDelta = 0.05, deltaWindow = c(2040, 2060),
                                    supportShareGate = 0.275, ceilingFallGate = 0.90, gammaGate = 0.999,
                                    vcovGate = c("likelihood-mismatch", "flat"), apExtrapolationGate = 0.275, apExtrapolationSd = 1,
                                    apExtrapolationWindow = c(2025, 2100),
                                    edgeGate = list(share = 0.25, effect = 0.25, capShift = 0.5, cap = c(0.05, 0.95),
                                                    mapping = "regionmapping_21_EU11.csv"),
                                    theoryGate = list(p = 0.05, structural = TRUE, contingency = TRUE, coherence = 0.75)),
             error = function(e) { say("  walk failed: ", conditionMessage(e)); list(error = conditionMessage(e)) })
  })
  # the check: the selected specification's verdict and severe flags as on the cluster
  cl <- sw$sanity$PolicyStringency$flags[[SEL]]; here <- walk$all$flags[[SEL]]
  if (!is.null(cl) && !is.null(here)) {
    same <- identical(sort(cl$rule[cl$severity == "severe"]), sort(here$rule[here$severity == "severe"]))
    say("check: the selected specification's severe flags as on the cluster: ", same)
  }
  walkSumm <- do.call(rbind, lapply(names(walk), function(v) {
    w <- walk[[v]]; if (!is.null(w$error)) return(data.frame(variant = v, nSevere = NA, nWarning = NA, pass = NA, severe = w$error))
    f <- w$flags[[specs[[v]]$name]]; sv <- f[f$severity == "severe", ]
    data.frame(variant = v, nSevere = w$trace$nSevere[1], nWarning = w$trace$nWarning[1], pass = isTRUE(w$trace$pass[1]),
               severe = paste(unique(paste0(sv$sector, ":", sv$rule)), collapse = "; "),
               gammaBulk = w$gamma[[specs[[v]]$name]][["Bulk"]] %||% NA_real_,
               gammaDiffuse = w$gamma[[specs[[v]]$name]][["Diffuse"]] %||% NA_real_)
  }))
  walk <- list(raw = walk, summary = walkSumm)
}

out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), selected = SEL, scopes = SCOPES,
            specs = lapply(specs, `[[`, "name"), correlation = corr, summary = summ, terms = terms, fits = res,
            ranking = mm[mm$model %in% vapply(specs, `[[`, "", "name"), ], poolSize = sum(mm$pool), walk = walk)
saveRDS(out, file.path(GD, "weight-scope-test.rds")); say("wrote ", file.path(GD, "weight-scope-test.rds"))

options(width = 250)
cat("\n== 0. the weight against each institution, estimation sample ==\n"); print(corr, row.names = FALSE, digits = 3)
cat("\n== 1-4. per variant and sector ==\n")
print(summ[, c("variant", "sector", "deltaR2Theory", "bic", "maxVIF", "fossil", "pFossilWild", "pFossilLooMax", "H2term",
               "H2estimate", "H2pAsym", "H2pWild", "H2bonferroni", "H2pLooMax", "H2looPivotal", "nSigInteractionsWild")],
      row.names = FALSE, digits = 3)
cat("\n== gates and position ==\n")
print(unique(summ[, c("variant", "gatesBeforeTheory", "gateFail", "rank", "H1H2at05", "H1H2at10", "poolRank", "theoryFail05")]),
      row.names = FALSE)
cat("\n== fossil x institution terms ==\n")
print(terms[grepl("_x_", terms$term), c("variant", "sector", "term", "estimate", "pAsym", "pWild", "pLooMax", "looPivotal")],
      row.names = FALSE, digits = 3)
if (!is.null(walk)) { cat("\n== 5. the sanity walk ==\n"); print(walk$summary, row.names = FALSE) }
