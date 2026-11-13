# Fewer interaction terms: does the selected specification need all nine, and does the answer depend on the weight's scope?
#   Rscript analysis/v8/interactionBlockTest.R [group] [walk]   (repo root; default v8) -> output/pfm/<group>/interaction-block-test.rds
# The package interacts every sectoral-interest term with every institution (buildModelFormula: actorPowerIndex x
# instQualityDrivers), so the search never tests a subset. Here, on the selected specification, with everything else fixed:
#   A. every subset of the nine interactions (512), in both sectors, under three scopes of the freedom-of-expression weight:
#        all    every interaction weighted (the selected specification)
#        geRoL  state capacity and rule of law weighted, accountability unweighted (author's decision 2026-11-09, 0009 section 23.1)
#        none   no weight
#      on the mean regression the theory gate reads (least squares on the logit response, country-clustered CR1, z-test, as the
#      sweep's satP fits; the full set under "all" must reproduce sweep.rds). Per subset: BIC and theory gain per sector, H1,
#      H2 with the Bonferroni level over the fossil x institution terms KEPT. The subset is shared by the two sectors
#      (the Shared Specification rule); "best" is the lowest summed BIC.
#   B. with "walk": named candidate blocks under "all" and "geRoL" through the sanity walk (frontier gamma, H3, edge-of-data,
#      support share, ceiling fall), the wild bootstrap and leave-one-country-out of the fossil terms. The walk's raw
#      results are kept in interaction-block-walk.rds, so a second call walks only the candidates still missing.
# Nothing in the package or the fit cache changes: the geRoL scope and a formula filter (option pfm.test.dropTerms, read by a
# wrapper around buildModelFormula) are set for this session only; the walk caches in temporary folders, one per candidate.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args) && args[1] != "walk") args[1] else "v8"; WALK <- "walk" %in% args
GD <- file.path("output/pfm", g)
say <- function(...) message("[interaction-block:", g, "] ", ...)
options(pfm.panel = list(firstYear = 2000L, lastYear = 2023L, movingAverage = 5L, ieaVersion = "latest", geothermal = TRUE,
                         democracy = TRUE, overallAccountability = TRUE, fossilRents = TRUE))
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g)), forcecache = TRUE, .verbose = FALSE)

utils::assignInNamespace(".pfmIwScopes", c(accRoL = "Accountability|Rule\\.of\\.Law",
                                           geRoL = "Government\\.Effectiveness|Rule\\.of\\.Law"), ns = "pfm")
origBuild <- pfm:::buildModelFormula
utils::assignInNamespace("buildModelFormula", function(...) {
  f <- origBuild(...); drop <- getOption("pfm.test.dropTerms")
  if (!length(drop)) return(f)
  tl <- attr(stats::terms(f), "term.labels")
  stats::as.formula(paste(as.character(f[[2]]), "~", paste(setdiff(tl, drop), collapse = " + ")))
}, ns = "pfm")

sw <- readRDS(file.path(GD, "sweep.rds"))
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
specByName <- stats::setNames(sw$specs, vapply(sw$specs, `[[`, character(1), "name"))
SEL <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))[[1]]$name
base <- specByName[[SEL]]
SECTORS <- c(Bulk = "P&I", Diffuse = "B&T")
W <- "Freedom of Expression (VDem)"
SCOPES <- list(all = W, geRoL = paste0(W, "@geRoL"), none = NULL)
AP <- c(clean = "Innovator.Power", fossil = "Incumbent.Power", fossilPc = "Incumbent.Power.pc")
INST <- c(GE = "Government.Effectiveness..WGI.", RoL = "Rule.of.Law..VDem.", Acc = "Vertical.Accountability..VDem.")
INT <- as.vector(t(outer(AP, INST, paste, sep = "_x_")))            # 9 terms, clean x (GE, RoL, Acc), fossil x ..., fossilPc x ...
SHORT <- as.vector(t(outer(names(AP), names(INST), paste, sep = ":")))
isFossil <- grepl("^Incumbent", INT)
cfgOf <- function(scope) { cfg <- base; cfg$interactionWeight <- SCOPES[[scope]]; cfg }
satP <- function(scope, sec) do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "satP", indexMax = 10,
                                                                           modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfgOf(scope))))

# --- A. every subset, mean regression ---------------------------------------------------------------------------------
# least squares with the CR1 cluster covariance sandwich::vcovCL(type = "HC1") gives, p from the normal (coeftest on a glm)
ols <- function(X, y, cl) {
  XtXi <- solve(crossprod(X)); b <- drop(XtXi %*% crossprod(X, y)); e <- drop(y - X %*% b)
  n <- nrow(X); k <- ncol(X); G <- length(unique(cl))
  sc <- rowsum(X * e, cl); V <- XtXi %*% crossprod(sc) %*% XtXi * (G / (G - 1)) * ((n - 1) / (n - k))
  se <- sqrt(diag(V)); rss <- sum(e^2)
  list(b = b, p = 2 * stats::pnorm(-abs(b / se)), rss = rss, bic = n * log(rss / n) + (k + 1) * log(n), k = k)
}
subsets <- as.matrix(expand.grid(rep(list(c(FALSE, TRUE)), 9))); colnames(subsets) <- SHORT
rowsA <- list(); frames <- list()
for (scope in names(SCOPES)) for (sec in names(SECTORS)) {
  fit <- satP(scope, sec); df <- fit$data
  tl <- attr(stats::terms(fit$formula), "term.labels"); stopifnot(all(INT %in% tl))
  mf <- stats::model.frame(fit$formula, df); yy <- stats::model.response(mf); Xfull <- stats::model.matrix(fit$formula, mf)
  cl <- as.character(df$region)[match(rownames(mf), rownames(df))]
  theory <- colnames(Xfull) %in% c(AP, INST, INT)
  rssBase <- ols(Xfull[, !theory, drop = FALSE], yy, cl)$rss; tss <- sum((yy - mean(yy))^2)
  if (scope == "all") {   # the check: the full set reproduces the sweep's coefficient table
    o <- ols(Xfull, yy, cl); ref <- sw$coefficients[sw$coefficients$model == SEL & sw$coefficients$sector == sec, ]
    d <- max(abs(o$b - ref$estimate[match(names(o$b), ref$term)]), abs(o$p - ref$pValue[match(names(o$b), ref$term)]))
    say("check ", sec, ": full block against the sweep, max |difference| ", signif(d, 2)); stopifnot(d < 1e-6)
  }
  frames[[paste(scope, sec)]] <- fit
  res <- t(apply(subsets, 1, function(keep) {
    X <- Xfull[, !(colnames(Xfull) %in% INT[!keep]), drop = FALSE]; o <- ols(X, yy, cl)
    kf <- INT[keep & isFossil]; pk <- o$p[kf]
    c(bic = o$bic, dR2 = (rssBase - o$rss) / tss, fossil = o$b[["Incumbent.Power"]], pFossil = o$p[["Incumbent.Power"]],
      H1 = o$b[["Incumbent.Power"]] < 0 && o$p[["Incumbent.Power"]] < 0.05,
      H2 = length(kf) > 0 && any(pk < 0.05 / length(kf)), pH2min = if (length(kf)) min(pk) else NA, nFossilInt = length(kf))
  }))
  rowsA[[paste(scope, sec)]] <- cbind(data.frame(scope = scope, sector = sec, id = seq_len(nrow(subsets)), n = rowSums(subsets)), res)
  say("A: ", scope, " ", sec, " done")
}
A <- do.call(rbind, rowsA); rownames(A) <- NULL
# one row per scope x subset, the two sectors side by side
wideA <- merge(A[A$sector == "Bulk", ], A[A$sector == "Diffuse", ], by = c("scope", "id", "n"), suffixes = c(".PI", ".BT"))
wideA$sumBIC <- wideA$bic.PI + wideA$bic.BT; wideA$minDR2 <- pmin(wideA$dR2.PI, wideA$dR2.BT)
wideA$gate <- wideA$H1.PI & wideA$H2.PI & wideA$H1.BT & wideA$H2.BT
wideA$label <- apply(subsets[wideA$id, , drop = FALSE], 1, function(k) if (any(k)) paste(SHORT[k], collapse = " ") else "(none)")
ref <- wideA[wideA$scope == "all" & wideA$n == 9, ]
wideA$dBIC <- wideA$sumBIC - ref$sumBIC; wideA$dBIC.PI <- wideA$bic.PI - ref$bic.PI; wideA$dBIC.BT <- wideA$bic.BT - ref$bic.BT
idOf <- function(keep) which(apply(subsets, 1, function(k) all(k == keep)))
NAMED <- list(full = rep(TRUE, 9), fossilOnly = isFossil, fossilShareOnly = grepl("^Incumbent\\.Power_x_", INT),
              fossilPcOnly = grepl("^Incumbent\\.Power\\.pc_x_", INT), noInteractions = rep(FALSE, 9),
              fossilNoAcc = isFossil & !grepl("Accountability", INT), fossilGEonly = isFossil & grepl("Government", INT))
cols <- c("scope", "n", "label", "dBIC", "dBIC.PI", "dBIC.BT", "dR2.PI", "dR2.BT", "fossil.PI", "fossil.BT", "H1.PI", "H2.PI", "H1.BT", "H2.BT", "gate")
named <- do.call(rbind, lapply(names(SCOPES), function(sc) do.call(rbind, lapply(names(NAMED), function(nm)
  cbind(block = nm, wideA[wideA$scope == sc & wideA$id == idOf(NAMED[[nm]]), cols])))))
# by size: the best shared subset (lowest summed BIC), and how many subsets pass H1-H2 in both sectors
bySize <- do.call(rbind, lapply(names(SCOPES), function(sc) do.call(rbind, lapply(0:9, function(n) {
  x <- wideA[wideA$scope == sc & wideA$n == n, ]; b <- x[which.min(x$sumBIC), ]
  xg <- x[x$gate %in% TRUE, ]; bg <- if (nrow(xg)) xg[which.min(xg$sumBIC), ] else NULL
  data.frame(scope = sc, n = n, subsets = nrow(x), passGate = sum(x$gate), bestDBIC = b$dBIC, best = b$label, bestPasses = b$gate %in% TRUE,
             bestPassingDBIC = if (is.null(bg)) NA else bg$dBIC, bestPassing = if (is.null(bg)) NA else bg$label)
}))))
# each term: what dropping it alone costs, and how often the 20 best subsets (per scope) keep it
terms <- do.call(rbind, lapply(names(SCOPES), function(sc) {
  x <- wideA[wideA$scope == sc, ]; full <- x[x$n == 9, ]; top <- x[order(x$sumBIC)[1:20], ]
  topG <- x[x$gate %in% TRUE, ]; topG <- topG[order(topG$sumBIC)[seq_len(min(20, nrow(topG)))], ]
  do.call(rbind, lapply(seq_along(INT), function(j) {
    d <- x[x$id == idOf(replace(rep(TRUE, 9), j, FALSE)), ]
    data.frame(scope = sc, term = SHORT[j], dropCostPI = d$bic.PI - full$bic.PI, dropCostBT = d$bic.BT - full$bic.BT,
               inTop20 = mean(subsets[top$id, j]), inTop20Passing = if (nrow(topG)) mean(subsets[topG$id, j]) else NA)
  }))
}))
best <- do.call(rbind, lapply(names(SCOPES), function(sc) { x <- wideA[wideA$scope == sc, ]
  rbind(cbind(pick = "lowest BIC", x[which.min(x$sumBIC), cols]), cbind(pick = "lowest BIC passing H1-H2", { xg <- x[x$gate %in% TRUE, ]; xg[which.min(xg$sumBIC), cols] })) }))

out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), selected = SEL, terms9 = stats::setNames(INT, SHORT), subsets = subsets,
            all = wideA, named = named, bySize = bySize, terms = terms, best = best, walk = NULL)
saveRDS(out, file.path(GD, "interaction-block-test.rds"))
options(width = 250)
cat("\n== named blocks (dBIC against the selected: all nine, every pair weighted; negative = better) ==\n"); print(named, row.names = FALSE, digits = 3)
cat("\n== by number of interactions kept ==\n"); print(bySize, row.names = FALSE, digits = 3)
cat("\n== each interaction: BIC cost of dropping it alone (positive = the data want it), share of the 20 best subsets keeping it ==\n")
print(terms, row.names = FALSE, digits = 3)
cat("\n== best subsets ==\n"); print(best, row.names = FALSE, digits = 3)

# --- B. candidates through the wild bootstrap, leave-one-out and the sanity walk -----------------------------------------
if (WALK) {
  # the candidate blocks, fixed after stage A (2026-11-10): the three per-person fossil interactions are the ones the data
  # want in both sectors; "four" adds fossil dependence x state capacity; "six" adds clean energy x state capacity and
  # x accountability (the lowest summed BIC under the selected weight)
  pc3 <- NAMED$fossilPcOnly; four <- pc3 | SHORT == "fossil:GE"; six <- four | SHORT %in% c("clean:GE", "clean:Acc")
  CAND <- list("all|full" = list("all", NAMED$full), "all|six" = list("all", six), "all|four" = list("all", four), "all|pc3" = list("all", pc3),
               "geRoL|full" = list("geRoL", NAMED$full), "geRoL|six" = list("geRoL", six), "geRoL|four" = list("geRoL", four),
               "geRoL|pc3" = list("geRoL", pc3), "none|six" = list("none", six), "none|pc3" = list("none", pc3))
  only <- Sys.getenv("PFM_BLOCK_CANDIDATES", ""); if (nzchar(only)) CAND <- CAND[strsplit(only, ",")[[1]]]
  mk <- function(gdx) panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                                        outputRegionMappingFile = "country", histYears = pfm:::.pfmPanelYears(), movingAverage = pfm:::.pfmPanelMA())
  gating <- mk("output/remind-runs/v6/EU21/SSP2-EU21-PkBudg1000_2026-10-07_19.04.46/fulldata.gdx")
  reference <- mk("output/remind-runs/v6/EU21/SSP2-EU21-NPi2025_2026-10-07_12.36.43/fulldata.gdx")
  FOS <- c("Incumbent.Power", "Incumbent.Power.pc")
  # candidates walked by an earlier call are kept and skipped (PFM_BLOCK_REDO=1 walks them again)
  prev <- tryCatch(readRDS(file.path(GD, "interaction-block-walk.rds")), error = function(e) NULL)
  wk <- prev$raw %||% list(); wsum <- prev$wsum %||% list(); wterms <- prev$wterms %||% list()
  for (nm in names(CAND)) {
    if (!is.null(wsum[[nm]]) && Sys.getenv("PFM_BLOCK_REDO", "") == "") { say("B: ", nm, " kept from an earlier call"); next }
    scope <- CAND[[nm]][[1]]; keep <- CAND[[nm]][[2]]; drop <- INT[!keep]
    cfg <- cfgOf(scope); cfg$name <- paste0("TEST ", nm)
    options(pfm.test.dropTerms = drop)
    say("B: ", nm, " (", sum(keep), " interactions: ", if (any(keep)) paste(SHORT[keep], collapse = " ") else "none", ") ...")
    for (sec in names(SECTORS)) {
      fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "satP", indexMax = 10, modelDir = NULL,
                                                           verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
      ct <- as.data.frame(unclass(fit$coeftest)); tt <- intersect(c(FOS, INT[keep & isFossil]), rownames(ct))
      wb <- computeWildClusterBootstrap(fit, B = 999, seed = 42)
      inf <- computeInfluenceDiagnostics(fit, terms = tt, alpha = 0.05, wcb = FALSE, verbose = FALSE)
      wterms[[paste(nm, sec)]] <- data.frame(candidate = nm, sector = SECTORS[[sec]], term = tt, estimate = ct[tt, 1], pAsym = ct[tt, 4],
                                             pWild = wb$pWild[match(tt, wb$term)], pLooMax = inf$byTerm$pMax[match(tt, inf$byTerm$term)],
                                             looPivotal = inf$byTerm$pivotalLossClusters[match(tt, inf$byTerm$term)],
                                             bonferroni = 0.05 / max(1, sum(keep & isFossil)))
    }
    cacheDir <- file.path(tempdir(), paste0("fit-cache-", gsub("[^A-Za-z]", "", nm))); dir.create(cacheDir, showWarnings = FALSE)
    w <- tryCatch(pfm:::.pfmSanitySelect(passModels = cfg$name, specByName = stats::setNames(list(cfg), cfg$name), sectors = names(SECTORS),
                                         panelData = panel, scenarioData = gating, modelDir = cacheDir, batchSize = 5, maxModels = 1, thresholds = list(),
                                         regionBlocks = pfm:::.h12RegionBlocks(), histIndexBySector = pfm:::.histIndexBySector(panel, names(SECTORS)),
                                         indexMax = 10, referenceScenarioData = reference, minScenarioDelta = 0.05, deltaWindow = c(2040, 2060),
                                         supportShareGate = 0.275, ceilingFallGate = 0.90, gammaGate = 0.999, vcovGate = c("likelihood-mismatch", "flat"),
                                         apExtrapolationGate = 0.275, apExtrapolationSd = 1, apExtrapolationWindow = c(2025, 2100),
                                         edgeGate = list(share = 0.25, effect = 0.25, capShift = 0.5, cap = c(0.05, 0.95), mapping = "regionmapping_21_EU11.csv"),
                                         theoryGate = list(p = 0.05, structural = TRUE, contingency = TRUE, coherence = 0.75)),
                  error = function(e) list(error = conditionMessage(e)))
    wk[[nm]] <- w
    wsum[[nm]] <- if (!is.null(w$error)) data.frame(candidate = nm, n = sum(keep), nSevere = NA, nWarning = NA, pass = NA, severe = w$error, gammaPI = NA, gammaBT = NA) else {
      f <- w$flags[[cfg$name]]; sv <- f[f$severity == "severe", ]
      data.frame(candidate = nm, n = sum(keep), nSevere = w$trace$nSevere[1], nWarning = w$trace$nWarning[1], pass = isTRUE(w$trace$pass[1]),
                 severe = paste(unique(paste0(sv$sector, ":", sv$rule, " [", substr(sv$detail, 1, 110), "]")), collapse = "; "),
                 gammaPI = w$gamma[[cfg$name]][["Bulk"]] %||% NA_real_, gammaBT = w$gamma[[cfg$name]][["Diffuse"]] %||% NA_real_)
    }
    say("   ", if (is.null(w$error)) paste0(wsum[[nm]]$nSevere, " severe: ", wsum[[nm]]$severe) else w$error)
    saveRDS(list(raw = wk, wsum = wsum, wterms = wterms), file.path(GD, "interaction-block-walk.rds"))
  }
  options(pfm.test.dropTerms = NULL)
  out$walk <- list(candidates = lapply(CAND, function(x) list(scope = x[[1]], keep = SHORT[x[[2]]])), summary = do.call(rbind, wsum),
                   terms = do.call(rbind, wterms))
  saveRDS(out, file.path(GD, "interaction-block-test.rds"))
  cat("\n== B. the candidates through the walk ==\n"); print(out$walk$summary, row.names = FALSE)
  cat("\n== B. fossil terms: wild bootstrap and leave-one-country-out ==\n"); print(out$walk$terms, row.names = FALSE, digits = 3)
}
say("wrote ", file.path(GD, "interaction-block-test.rds"))
