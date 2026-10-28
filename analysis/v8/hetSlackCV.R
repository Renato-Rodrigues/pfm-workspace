# v8 test (design note 0009 section 9.2): is the heteroscedastic-slack frontier a better model out of sample?
#   Rscript analysis/v8/hetSlackCV.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-het-slack-cv.rds
# A better in-sample likelihood is guaranteed when a model gains parameters; out of sample it is not. Each covered country
# in turn is left out; every model is refitted on the others (started at its full-sample estimate) and scored by the
# log-likelihood of the left-out country's rows (its ceiling from the drivers, its slack scale from its own z). Models
# (analysis/v8/hetSlack.R): none (the v7 frontier), rents, exporter, inst, both.
# Reported per sector: the summed held-out log-likelihood, its difference to `none` with a paired standard error over
# countries, the number of countries each model predicts better, and the countries that gain or lose most.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
source("analysis/v8/_rents.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g)
INST <- c("Government.Effectiveness..WGI.", "Rule.of.Law..VDem.", "Vertical.Accountability..VDem.")
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
Rh <- v8RentsHistory(getItems(panel, dim = 1), getYears(panel, as.integer = TRUE), file.path(GD, "v8-wdi-rents.rds"))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
llRows <- function(p, y, X, Z) {   # per-row log-likelihood of the normal / heteroscedastic half-normal frontier
  kb <- ncol(X); b <- p[seq_len(kb)]; sv <- exp(p[kb + 1]); su <- exp(as.numeric(Z %*% p[-seq_len(kb + 1)]))
  e <- y - as.numeric(X %*% b); s <- sqrt(sv^2 + su^2); lam <- su / sv
  log(2) - log(s) + stats::dnorm(e / s, log = TRUE) + stats::pnorm(-e * lam / s, log.p = TRUE)
}
nll <- function(p, y, X, Z) -sum(llRows(p, y, X, Z))

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfg)))))
  d <- ff$data; X <- stats::model.matrix(ff$formula, d); y <- stats::model.response(stats::model.frame(ff$formula, d))
  cty <- as.character(d[rownames(X), "region"])
  rr <- Rh[cbind(match(cty, rownames(Rh)), match(as.character(d[rownames(X), "year"] - 1), colnames(Rh)))]
  zR <- (rr - mean(rr, na.rm = TRUE)) / stats::sd(rr, na.rm = TRUE); zR[!is.finite(zR)] <- 0
  Zs <- list(none = NULL, rents = cbind(zRents = zR), exporter = cbind(zExporter = as.numeric(expm1(rr) > 5)),
             inst = as.matrix(d[rownames(X), INST]), both = cbind(zRents = zR, as.matrix(d[rownames(X), INST])))
  b0 <- stats::coef(ff$model); s2 <- b0[["sigmaSq"]]; ga <- b0[["gamma"]]
  st0 <- c(b0[colnames(X)], log(sqrt((1 - ga) * s2)), log(sqrt(ga * s2)))
  full <- lapply(Zs, function(z) { Z <- cbind(rep(1, nrow(X)), z)
    stats::optim(c(st0, rep(0, ncol(Z) - 1)), nll, y = y, X = X, Z = Z, method = "BFGS", control = list(maxit = 5000, reltol = 1e-12))$par })
  ho <- sapply(names(Zs), function(zn) { Z <- cbind(rep(1, nrow(X)), Zs[[zn]])
    vapply(unique(cty), function(c) {
      tr <- cty != c
      # a design column that is constant (or absent) without this country cannot be fitted: drop it from the fit, and
      # give it weight 0 in the held-out prediction (its group's level is then the reference level)
      keepX <- apply(X[tr, , drop = FALSE], 2, function(v) stats::var(v) > 0) | colnames(X) == "(Intercept)"
      p0 <- full[[zn]]; kb <- ncol(X); pX <- p0[seq_len(kb)][keepX]
      o <- stats::optim(c(pX, p0[-seq_len(kb)]), nll, y = y[tr], X = X[tr, keepX, drop = FALSE], Z = Z[tr, , drop = FALSE],
                        method = "BFGS", control = list(maxit = 3000, reltol = 1e-10))
      pFull <- c(replace(numeric(kb), which(keepX), o$par[seq_len(sum(keepX))]), o$par[-seq_len(sum(keepX))])
      sum(llRows(pFull, y[!tr], X[!tr, , drop = FALSE], Z[!tr, , drop = FALSE]))
    }, numeric(1))
  })
  message("[het cv] ", sec, " done")
  dd <- ho - ho[, "none"]
  summ <- data.frame(sector = sec, model = colnames(ho), heldOutLogLik = colSums(ho), diffToNone = colSums(dd),
                     seDiff = apply(dd, 2, function(x) stats::sd(x) * sqrt(length(x))), nBetter = colSums(dd > 0), nCountries = nrow(ho),
                     row.names = NULL)
  list(summary = summ, byCountry = ho)
})
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), bySector = res), file.path(GD, "v8-het-slack-cv.rds"))
options(width = 200)
for (sec in names(res)) { r <- res[[sec]]; cat("\n==========", sec, "==========\n"); print(r$summary, digits = 4, row.names = FALSE)
  for (m in c("rents", "both")) { dd <- r$byCountry[, m] - r$byCountry[, "none"]
    cat(m, "- gains most:", paste(names(sort(dd, decreasing = TRUE))[1:5], sprintf("%+.1f", sort(dd, decreasing = TRUE)[1:5]), collapse = ", "),
        "| loses most:", paste(names(sort(dd))[1:5], sprintf("%+.1f", sort(dd)[1:5]), collapse = ", "), "\n") } }
