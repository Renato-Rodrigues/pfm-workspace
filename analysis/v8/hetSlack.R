# v8 test (design note 0009 section 8.2): does the SPREAD of the slack depend on producer interests or institutions?
# A heteroscedastic half-normal frontier (Caudill, Ford & Gropper 1995): y = X b + v - u, v ~ N(0, sv^2),
# u ~ |N(0, su_it^2)|, log su_it = c + z_it' w. The mean slack is proportional to su, so w > 0 means more slack where z
# is high - the reading of section 8.1 (Battese & Coelli 1995), whose mean-shift form was not identified.
#   Rscript analysis/v8/hetSlack.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-het-slack.rds
# Maximum likelihood written here (the frontier package has no heteroscedastic slack), started at the v7 frontier; the
# homoscedastic fit (w = 0) is the v7 frontier and is checked against it. z: fossil rents (log(1 + % of GDP),
# standardised; analysis/v8/_rents.R), the exporter dummy, the three institutions, rents and institutions.
# Reported: logLik, LR against v7, w with its z (numerical Hessian), sigma_v, E in 2023 and a covered regional u.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
source("analysis/v8/_rents.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g)
FOCUS <- c("SAU", "RUS", "NOR", "CAN", "AUS", "COL", "MEX", "IDN", "ISL", "PER", "ARG", "CHN")
INST <- c("Government.Effectiveness..WGI.", "Rule.of.Law..VDem.", "Vertical.Accountability..VDem.")
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
Rh <- v8RentsHistory(getItems(panel, dim = 1), getYears(panel, as.integer = TRUE), file.path(GD, "v8-wdi-rents.rds"))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"); rmap <- stats::setNames(map$RegionCode, map$CountryCode)
uOf <- function(E, cty) { r <- rmap[cty]; ww <- w[cty]; gg <- tapply((1 - E) * ww, r, sum) / tapply(ww, r, sum); (gg - min(gg)) / (max(gg) - min(gg)) }

# negative log-likelihood of the normal / heteroscedastic half-normal frontier; p = (b, log sv, c, w)
nllHet <- function(p, y, X, Z) {
  kb <- ncol(X); b <- p[seq_len(kb)]; sv <- exp(p[kb + 1]); su <- exp(as.numeric(Z %*% p[-seq_len(kb + 1)]))
  e <- y - as.numeric(X %*% b); s <- sqrt(sv^2 + su^2); lam <- su / sv
  -sum(log(2) - log(s) + stats::dnorm(e / s, log = TRUE) + stats::pnorm(-e * lam / s, log.p = TRUE))
}

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfg)))))
  d <- ff$data; mf <- stats::model.frame(ff$formula, d); X <- stats::model.matrix(ff$formula, d)
  y <- stats::model.response(mf); obs <- as.numeric(ff$outcomeNatural[rownames(X)])
  rr <- Rh[cbind(match(as.character(d[rownames(X), "region"]), rownames(Rh)), match(as.character(d[rownames(X), "year"] - 1), colnames(Rh)))]
  zR <- (rr - mean(rr, na.rm = TRUE)) / stats::sd(rr, na.rm = TRUE); zR[!is.finite(zR)] <- 0
  b0 <- stats::coef(ff$model); s2 <- b0[["sigmaSq"]]; ga <- b0[["gamma"]]
  st0 <- c(b0[colnames(X)], log(sqrt((1 - ga) * s2)), log(sqrt(ga * s2)))
  Zs <- list(none = NULL, rents = cbind(zRents = zR), exporter = cbind(zExporter = as.numeric(expm1(rr) > 5)),
             inst = as.matrix(d[rownames(X), INST]), both = cbind(zRents = zR, as.matrix(d[rownames(X), INST])))
  out <- lapply(names(Zs), function(zn) {
    Z <- cbind(`(c)` = 1, Zs[[zn]]); st <- c(st0, rep(0, ncol(Z) - 1))
    o <- stats::optim(st, nllHet, y = y, X = X, Z = Z, method = "BFGS", control = list(maxit = 5000, reltol = 1e-12))
    H <- tryCatch(stats::optimHess(o$par, nllHet, y = y, X = X, Z = Z), error = function(e) NULL)
    se <- if (is.null(H)) rep(NA_real_, length(o$par)) else tryCatch(sqrt(pmax(diag(solve(H)), 0)), error = function(e) rep(NA_real_, length(o$par)))
    kb <- ncol(X); iw <- seq(kb + 2, length(o$par))
    E <- obs / (10 * stats::plogis(as.numeric(X %*% o$par[seq_len(kb)])))
    i23 <- d[rownames(X), "year"] == 2023; cty <- as.character(d[rownames(X), "region"])[i23]
    message(sprintf("[het] %s %s: logLik %.1f, convergence %d", sec, zn, -o$value, o$convergence))
    list(fit = data.frame(sector = sec, z = zn, logLik = -o$value, k = length(o$par), converged = o$convergence == 0,
                          sigmaV = exp(o$par[kb + 1]), fossil = o$par[match("Incumbent.Power", colnames(X))]),
         w = data.frame(sector = sec, z = zn, term = colnames(Z), w = o$par[iw], zStat = o$par[iw] / se[iw], row.names = NULL),
         E = stats::setNames(E[i23], cty))
  })
  names(out) <- names(Zs)
  fit <- do.call(rbind, lapply(out, `[[`, "fit"))
  fit$llV7 <- as.numeric(stats::logLik(ff$model)); fit$LR <- 2 * (fit$logLik - fit$logLik[fit$z == "none"]); fit$df <- fit$k - fit$k[fit$z == "none"]
  fit$p <- ifelse(fit$df > 0, stats::pchisq(pmax(fit$LR, 0), fit$df, lower.tail = FALSE), NA_real_)
  Em <- do.call(cbind, lapply(out, `[[`, "E")); U <- apply(Em, 2, uOf, cty = rownames(Em))
  fit$spearmanU <- apply(U, 2, function(x) stats::cor(x, U[, "none"], method = "spearman"))[fit$z]
  list(fit = fit, w = do.call(rbind, lapply(out, `[[`, "w")), E = Em, U = U)
})
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), bySector = res), file.path(GD, "v8-het-slack.rds"))
options(width = 220)
for (sec in names(res)) { r <- res[[sec]]; cat("\n==========", sec, "==========\n")
  print(r$fit, digits = 5, row.names = FALSE); print(r$w[r$w$term != "(c)", ], digits = 3, row.names = FALSE)
  cat("E 2023:\n"); print(round(r$E[intersect(FOCUS, rownames(r$E)), ], 2))
  cat("regional u:\n"); print(round(r$U[order(-r$U[, "none"]), ], 2)) }
