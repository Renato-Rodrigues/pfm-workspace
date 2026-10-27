# v8 test 3 (design note 0009 section 4.3): how well does the rule for the countries without CAPMF data place them,
# and would a prediction from their own drivers do better?
#   Rscript analysis/v8/uncoveredRule.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-uncovered-rule.rds
# Out of sample: each covered country in turn is treated as uncovered (dropped from the frontier scores) and its 2023
# efficiency ratio E is assigned by
# (In the leave-one-out the median's rank correlation is negative by construction: dropping a low country raises the
# median of the rest. Read the errors.)
#   rule     the group's rule (computeDonorAssignment defaults: 3 donors in the |beta|-weighted driver metric up to the
#            covered 90th-percentile distance, else the low band (25th percentile) or the median by the linear index;
#            the USA override kept);
#   median   the covered median for everyone;
#   donors   the 3 nearest donors always (no distance cut-off);
#   ridge    a ridge regression of logit E on the same base drivers (glmnet, lambda by 10-fold CV), fitted on the
#            other covered countries;
#   ge       a one-driver regression of logit E on government effectiveness (the computeDonorAssignment note:
#            cor(E, GovEff) +0.52 / +0.65).
# Scored: mean absolute error, the error by the rule's basis, and the rank correlation with the observed E. The best
# alternative is then applied to the real uncovered countries and its regional ranking u (EU21, computeAnchorGap)
# compared with the group's.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
# the edge gate and the coupling weights read final energy through madrat: without the group's cache the edge gate
# finds no weights and passes without testing anything
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
local({ pd <- pfm:::.pfmPanelDefForGroup(file.path("output/pfm", g), pfmResolveConfig("config.yml", group = g, verbose = FALSE)$panel)   # the IEA edition: the cache key
  options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability"), names(pd))]) })
GD <- file.path("output/pfm", g); modelDir <- "output/pfm/fit-cache"
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD)); fr <- readRDS(file.path(GD, "frontier.rds"))
panel <- loadTrainingPanel(jsonlite::read_json(file.path(GD, "manifest.json"))$panel_hash, modelDir)
pAll <- panel[, , setdiff(getNames(panel), grep("Policy Stringency", getNames(panel), value = TRUE))]
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights   # the coupling anchor's final-energy weights (no madrat cache needed)
OVR <- c(USA = "median"); YEAR <- 2023
lg <- function(p) stats::qlogis(pmin(pmax(p, 0.01), 0.99))

setup <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cf <- pfm:::.pfmNormSpec(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  fit <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "satP",
           modelDir = modelDir, updateIndex = FALSE, verbose = FALSE), pfm:::.pfmSpecArgs(cf)))))
  sDf <- preparePanelData(data = pAll, sector = sec, actorPowerDrivers = cf$actorPowerDrivers, actorPowerIndex = cf$actorPowerIndex,
                          instQualityDrivers = cf$instQualityDrivers, controlDrivers = cf$controlDrivers,
                          regionMappingFixedEffects = NULL, driverScaling = fit$driverScaling, outcomeVar = "Policy Stringency")
  list(fit = fit, sDf = sDf, scores = fr$bySector[[sec]]$scores)
})

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  s <- setup[[sec]]
  base <- computeDonorAssignment(s$fit, s$scores, s$sDf, k = 3, basisOverride = OVR, sector = sec)
  stored <- readRDS(file.path(GD, paste0("donor-assignment-band-", sec, ".rds")))
  reproduces <- isTRUE(all.equal(base$efficiencyRatio[order(base$region)], stored$efficiencyRatio[order(stored$region)]))
  drv <- names(attr(base, "weights"))
  X <- s$sDf[s$sDf$year == YEAR, ]; rownames(X) <- as.character(X$region)
  obs <- s$scores[s$scores$year == YEAR, c("region", "efficiencyRatio")]; cov <- obs$region
  ge <- grep("Government.Effectiveness", drv, value = TRUE)[1]
  loo <- do.call(rbind, lapply(cov, function(c) {
    sc <- s$scores[s$scores$region != c, ]; tr <- obs[obs$region != c, ]
    one <- s$sDf[as.character(s$sDf$region) %in% cov, ]
    r <- computeDonorAssignment(s$fit, sc, one, k = 3, basisOverride = OVR[names(OVR) == c], sector = sec)
    r2 <- computeDonorAssignment(s$fit, sc, one, k = 3, sector = sec, qualityQuantiles = c(0.5, Inf))
    Xt <- as.matrix(X[tr$region, drv]); yt <- lg(tr$efficiencyRatio)
    cvr <- glmnet::cv.glmnet(Xt, yt, alpha = 0, nfolds = 10)
    rid <- stats::plogis(as.numeric(stats::predict(cvr, as.matrix(X[c, drv, drop = FALSE]), s = "lambda.min")))
    gl <- stats::lm(yt ~ x, data.frame(yt = yt, x = X[tr$region, ge]))
    data.frame(sector = sec, region = c, observed = obs$efficiencyRatio[obs$region == c],
               rule = r$efficiencyRatio[r$region == c], basis = r$basis[r$region == c],
               median = stats::median(tr$efficiencyRatio), donors = r2$efficiencyRatio[r2$region == c], ridge = rid,
               ge = stats::plogis(stats::predict(gl, data.frame(x = X[c, ge]))))
  }))
  M <- c("rule", "median", "donors", "ridge", "ge")
  score <- data.frame(sector = sec, method = M,
                      MAE = vapply(M, function(m) mean(abs(loo[[m]] - loo$observed)), 0),
                      RMSE = vapply(M, function(m) sqrt(mean((loo[[m]] - loo$observed)^2)), 0),
                      spearman = vapply(M, function(m) stats::cor(loo[[m]], loo$observed, method = "spearman"), 0), row.names = NULL)
  byBasis <- do.call(rbind, lapply(split(loo, loo$basis), function(d) data.frame(sector = sec, basis = d$basis[1], n = nrow(d),
    MAE_rule = mean(abs(d$rule - d$observed)), MAE_median = mean(abs(d$median - d$observed)), MAE_ridge = mean(abs(d$ridge - d$observed)))))
  # the ridge on all covered, applied to the real uncovered
  cvr <- glmnet::cv.glmnet(as.matrix(X[cov, drv]), lg(obs$efficiencyRatio), alpha = 0, nfolds = 10)
  alt <- base; alt$efficiencyRatio <- stats::plogis(as.numeric(stats::predict(cvr, as.matrix(X[base$region, drv]), s = "lambda.min")))
  if ("USA" %in% alt$region) alt$efficiencyRatio[alt$region == "USA"] <- base$efficiencyRatio[base$region == "USA"]
  med <- base; med$efficiencyRatio <- stats::median(obs$efficiencyRatio); med$basis <- "median"
  list(reproduces = reproduces, loo = loo, score = score, byBasis = byBasis, base = base, ridgeAssignment = alt, medianAssignment = med,
       ridgeCoef = as.matrix(stats::coef(cvr, s = "lambda.min")))
})
an0 <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w, verbose = FALSE)
anB <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w,
                        assignment = lapply(res, `[[`, "base"), verbose = FALSE)
anR <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w,
                        assignment = lapply(res, `[[`, "ridgeAssignment"), verbose = FALSE)
anM <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w,
                        assignment = lapply(res, `[[`, "medianAssignment"), verbose = FALSE)
cols <- intersect(c("sector", "region", "u", "shareObserved", "shareDonor", "shareLowBand", "shareMedian"), names(an0$region))
U <- merge(an0$region[, cols], anR$region[, c("sector", "region", "u")], by = c("sector", "region"), suffixes = c("", "_ridge"))
U$u_median <- anM$region$u[match(paste(U$sector, U$region), paste(anM$region$sector, anM$region$region))]
U$u_rebuilt <- anB$region$u[match(paste(U$sector, U$region), paste(anB$region$sector, anB$region$region))]
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), year = YEAR, bySector = res, regionU = U),
        file.path(GD, "v8-uncovered-rule.rds"))

options(width = 220)
for (sec in names(res)) { r <- res[[sec]]; cat("\n==========", sec, "| rule reproduces the stored assignment:", r$reproduces, "==========\n")
  print(r$score, digits = 3, row.names = FALSE); print(r$byBasis, digits = 3, row.names = FALSE)
  cat("uncovered E: rule median", round(stats::median(r$base$efficiencyRatio), 3), "| ridge median", round(stats::median(r$ridgeAssignment$efficiencyRatio), 3),
      "| Spearman rule vs ridge", round(stats::cor(r$base$efficiencyRatio, r$ridgeAssignment$efficiencyRatio, method = "spearman"), 2), "\n") }
cat("\nregional u (EU21): group anchor, rebuilt with the rule, with the ridge\n")
for (sec in unique(U$sector)) { x <- U[U$sector == sec, ]; cat(sec, "Spearman(u, u_ridge) =", round(stats::cor(x$u, x$u_ridge, method = "spearman"), 2),
  "; max |du| =", round(max(abs(x$u - x$u_ridge)), 2), "\n"); print(x[order(-x$u), ], digits = 2, row.names = FALSE) }
