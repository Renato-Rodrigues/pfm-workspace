# Is the v7 result the code, the data, or the weight? (design note 0007 section 14)
#   Rscript analysis/checks/v6v7Reproduction.R      (repo root) -> output/pfm/v7/v6v7-reproduction.rds
# 1. code: v6's selected spec refitted with today's code on v6's own training panel must reproduce v6's frontier.rds.
# 2. data: v6's and v7's training panels compared column by column (shared columns, shared countries and years).
# 3. the same v6 spec on v7's panel, unweighted and with each v7 weight (frontier coefficients and log-likelihood).
source("analysis/_common/_loadPfm.R")
suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
say <- function(...) message("[v6v7] ", ...)
rc <- pfmResolveConfig("config.yml", group = "v7", verbose = FALSE)
modelDir <- rc$modelDir %||% "output/pfm/fit-cache"
man <- function(g) jsonlite::read_json(file.path("output/pfm", g, "manifest.json"))
p6 <- loadTrainingPanel(man("v6")$panel_hash, modelDir); p7 <- loadTrainingPanel(man("v7")$panel_hash, modelDir)
sel6 <- yaml::read_yaml(pfm:::.pfmSelectedModels("output/pfm/v6"))
fr6 <- readRDS("output/pfm/v6/frontier.rds")

fitOn <- function(panel, cfg, sec) {
  options(pfm.panel = NULL)
  fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = 10,
                                                       modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
  list(beta = stats::coef(fit$model), logLik = as.numeric(stats::logLik(fit$model)), n = nrow(fit$data))
}
res <- list(code = list(), fits = list())
# 1. code
for (sec in c("Bulk", "Diffuse")) {
  cfg <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel6)[[1]]
  f <- fitOn(p6, cfg, sec)
  ct <- fr6$bySector[[sec]]$coefTable; b6 <- stats::setNames(ct$estimate, ct$term)
  k <- intersect(names(b6), names(f$beta))
  res$code[[sec]] <- list(maxAbsDiff = max(abs(f$beta[k] - b6[k])), logLik = f$logLik, n = f$n)
  say("1. code, ", sec, ": v6 spec on v6 panel with today's code: max |coef - v6 frontier.rds| ", signif(res$code[[sec]]$maxAbsDiff, 3),
      " | logLik ", round(f$logLik, 2), " | n ", f$n)
}
# 2. data
vars <- intersect(getNames(p6), getNames(p7)); cc <- intersect(getItems(p6, 1), getItems(p7, 1)); yy <- intersect(getYears(p6), getYears(p7))
d <- do.call(rbind, lapply(vars, function(v) {
  a <- as.vector(p6[cc, yy, v]); b <- as.vector(p7[cc, yy, v]); ok <- is.finite(a) & is.finite(b)
  data.frame(variable = v, maxAbsDiff = if (any(ok)) max(abs(a[ok] - b[ok])) else NA_real_,
             nDiffer = sum(ok & abs(a - b) > 1e-9), nMissingChange = sum(is.finite(a) != is.finite(b)))
}))
d <- d[order(-d$maxAbsDiff), ]
res$data <- list(onlyV6 = setdiff(getNames(p6), getNames(p7)), onlyV7 = setdiff(getNames(p7), getNames(p6)),
                 countries = c(v6 = length(getItems(p6, 1)), v7 = length(getItems(p7, 1))), byVariable = d)
say("2. data: ", sum(d$nDiffer > 0 | d$nMissingChange > 0), " of ", nrow(d), " shared columns differ; only in v7: ",
    paste(res$data$onlyV7, collapse = ", "))
print(head(d[d$nDiffer > 0 | d$nMissingChange > 0, ], 25), row.names = FALSE, digits = 3)
# 3. the v6 spec on v7's panel, unweighted and weighted
for (sec in c("Bulk", "Diffuse")) {
  cfg <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel6)[[1]]
  for (w in c("none", "Freedom of Expression (VDem)", "Electoral Democracy (VDem)")) {
    cf <- cfg; if (w != "none") cf$interactionWeight <- w
    f <- fitOn(p7, cf, sec)
    res$fits[[paste(sec, w)]] <- c(list(sector = sec, weight = w), f)
    say("3. ", sec, " | v6 spec on v7 panel | weight ", w, " | logLik ", round(f$logLik, 1), " | fossil ",
        round(f$beta[["Incumbent.Power"]], 3), " | fossil x VerAcc ", round(f$beta[["Incumbent.Power_x_Vertical.Accountability..VDem."]], 3))
  }
}
saveRDS(res, "output/pfm/v7/v6v7-reproduction.rds")
