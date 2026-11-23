# Does the pathway contrast of the strength survive a frontier without the noise/shortfall split? (the model paper's
# review v04 point M1, carrying v02:M6)
#   Rscript analysis/v8/quantileStrength.R [group] [taus]   (repo root; default v8, 0.80,0.90,0.95)
#   -> output/pfm/<group>/coupling/quantile-strength.rds
# In power and industry the stochastic frontier sits at gamma 0.9989 and its own check rejects the homoscedastic
# shortfall; the strength k(t) is read from that frontier's LEVEL. Here the ceiling coefficients are replaced by those of
# the conditional tau-quantile of the response on the selected design (quantreg, as analysis/v8/paperChecks.R T3: no
# split between noise and shortfall), the 2023 anchor is rebuilt from them as analysis/v8/frontierBlockBootstrap.R does
# for its resamples (observed countries keep their index, uncovered keep their assigned share of the new ceiling), and
# k(t) is recomputed on the current-policies, the no-politics 1000 Gt reference and the coupled headline pathways (the
# cached panels of analysis/v8/openLoopStrength.R). Country bootstrap of the quantile fit (199 resamples) for the
# contrast at tau 0.90. The buildings & transport rents slack is kept as estimated (it scales the held distance).
# Check: with the stochastic frontier's own coefficients the rebuilt anchor reproduces the staged ranking u to 1e-8.
# Offline: no REMIND run, nothing in the package or the Run-Group changes.
source("analysis/_common/_loadPfm.R"); suppressMessages({ library(magclass); library(quantreg) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
TAUS <- if (length(args) > 1) as.numeric(strsplit(args[2], ",")[[1]]) else c(0.80, 0.90, 0.95)
GD <- file.path("output/pfm", g); CPL <- file.path(GD, "coupling"); modelDir <- "output/pfm/fit-cache"
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [quantile-strength:", g, "] ", ...)
options(pfm.panel = list(firstYear = 2000L, lastYear = 2023L, movingAverage = 5L, ieaVersion = "latest", geothermal = TRUE,
                         democracy = TRUE, overallAccountability = TRUE, fossilRents = TRUE))
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path(modelDir, "panels", paste0("panel_", hash, ".rds")))
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
anc0 <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w, histData = panel, verbose = FALSE)
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
cfgOf <- function(sec) { hit <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers")) if (!is.null(hit[[f]])) hit[[f]] <- unlist(hit[[f]]); hit }
ol <- readRDS(file.path(CPL, "open-loop-strength.rds"))
PANELS <- c("current policies (NPi), uncoupled" = "current policies", "1000 Gt, no-politics reference (theta 0)" = "1000 Gt reference",
            "1000 Gt, hold the price (headline)" = "1000 Gt, hold the price")
scenFile <- function(lab) { run <- unique(ol$strength$run[ol$strength$pathway == lab])
  if (grepl("headline", lab)) file.path(CPL, paste0("scen-PFMlevelBfix-", g, ".rds")) else file.path(CPL, paste0("scen-openloop-", gsub("[^A-Za-z0-9]+", "-", run), ".rds")) }
scens <- lapply(stats::setNames(names(PANELS), PANELS), function(lab) readRDS(scenFile(lab)))

# the anchor for a set of ceiling coefficients (analysis/v8/frontierBlockBootstrap.R anchorFor, unchanged)
etaOrig <- pfm:::.pfmFrontierEta; ecache <- new.env()
etaCached <- function(design, data, returnDesign = FALSE) {
  key <- paste(design$sector, paste(dim(data), collapse = "x"), digest::digest(data, algo = "xxhash64"))
  if (is.null(ecache[[key]])) ecache[[key]] <- etaOrig(design, data, returnDesign = TRUE)
  r <- ecache[[key]]; f <- r$frame
  f$eta <- as.numeric(r$mm[, names(design$beta), drop = FALSE] %*% design$beta)
  if (isTRUE(returnDesign)) list(frame = f, mm = r$mm) else f
}
assignInNamespace(".pfmFrontierEta", etaCached, ns = "pfm")
ta <- anc0$anchorYear
anchorFor <- function(betas) {
  a <- anc0
  for (sec in names(betas)) {
    a$designs[[sec]]$beta <- betas[[sec]]
    eh <- etaCached(a$designs[[sec]], panel); eh <- eh[eh$year == ta, ]
    etaA <- stats::setNames(eh$eta, eh$region)
    i <- which(a$country$sector == sec); cc <- a$country[i, ]
    sNew <- 10 * stats::plogis(etaA[cc$region]); n <- a$designs[[sec]]$nSqueeze
    sq <- function(p) pfm:::.pfmSqueeze(pmin(pmax(p, 0), 1), n)
    e0 <- pmin((stats::plogis(cc$yAnchor) * n - 0.5) / (n - 1) * 10 / cc$ceilingAnchor, 1)
    y <- ifelse(cc$basis == "observed", cc$yAnchor, stats::qlogis(sq(e0 * sNew / 10)))
    a$country$etaAnchor[i] <- etaA[cc$region]; a$country$yAnchor[i] <- y; a$country$q[i] <- etaA[cc$region] - y
    a$country$ceilingAnchor[i] <- sNew; a$country$indexAnchor[i] <- 10 * stats::plogis(y)
    ok <- is.finite(a$country$q[i])
    path <- data.frame(region = cc$region[ok], year = ta, feasibleIndex = a$country$indexAnchor[i][ok], ceilingIndex = sNew[ok],
                       outOfCoverage = FALSE, stringsAsFactors = FALSE)
    agg <- suppressWarnings(aggregateFeasibilityToRegions(path, a$mapping, weights = a$weights, theta = 0.5))
    agg <- agg[is.finite(agg$relativeGap), ]
    u <- stats::setNames((agg$relativeGap - min(agg$relativeGap)) / diff(range(agg$relativeGap)), agg$region)
    j <- which(a$region$sector == sec); a$region$u[j] <- u[a$region$region[j]]
  }
  a
}
chk <- anchorFor(lapply(anc0$designs, `[[`, "beta"))
d0 <- max(abs(chk$region$u - anc0$region$u), na.rm = TRUE); say("check: the stochastic frontier's coefficients reproduce u, max |difference| ", signif(d0, 2)); stopifnot(d0 < 1e-8)

# the selected design and response, per sector (the satP design the frontier is fitted on)
frames <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = 10, modelDir = NULL,
                                                       verbose = FALSE), pfm:::.pfmSpecArgs(cfgOf(sec))))
  mf <- stats::model.frame(fit$formula, fit$data); X <- stats::model.matrix(fit$formula, mf); y <- stats::model.response(mf)
  list(X = X, y = y, cl = as.character(fit$data$region)[match(rownames(mf), rownames(fit$data))], names = names(anc0$designs[[sec]]$beta)) })
qBeta <- function(sec, tau, rows = NULL) { f <- frames[[sec]]; X <- f$X; y <- f$y; if (!is.null(rows)) { X <- X[rows, , drop = FALSE]; y <- y[rows] }
  b <- quantreg::rq.fit(X, y, tau = tau)$coefficients; names(b) <- colnames(f$X)
  miss <- setdiff(f$names, names(b)); if (length(miss)) stop("quantile fit lacks ", paste(miss, collapse = ", ")); b[f$names] }
kOn <- function(a) do.call(rbind, lapply(names(scens), function(p) { st <- computeStrengthPath(a, scens[[p]], theta = 0.5)$strength
  data.frame(pathway = p, st[st$year %in% c(2030, 2050, 2070, 2100), c("sector", "year", "k")]) }))

res <- list(stochastic = cbind(estimator = "stochastic frontier (selected)", kOn(anc0)))
for (tau in TAUS) { a <- anchorFor(list(Bulk = qBeta("Bulk", tau), Diffuse = qBeta("Diffuse", tau)))
  res[[paste0("q", tau)]] <- cbind(estimator = paste0("quantile ", tau), kOn(a))
  rk <- vapply(c("Bulk", "Diffuse"), function(s) stats::cor(a$region$u[a$region$sector == s], anc0$region$u[anc0$region$sector == s], method = "spearman"), numeric(1))
  say("tau ", tau, ": rank correlation of u with the stochastic frontier's ", paste(sprintf("%s %.2f", names(rk), rk), collapse = ", ")) }
K <- do.call(rbind, res); rownames(K) <- NULL
W <- stats::reshape(K[K$year == 2050, c("estimator", "pathway", "sector", "k")], idvar = c("estimator", "sector"), timevar = "pathway", direction = "wide")
names(W) <- sub("^k\\.", "", names(W)); W$contrast <- W[["current policies"]] - W[["1000 Gt reference"]]; W$feedback <- W[["1000 Gt, hold the price"]] - W[["1000 Gt reference"]]

# country bootstrap of the 0.90-quantile contrast in 2050 (and 2100)
set.seed(20261121); NB <- 199L; cc <- unique(frames$Bulk$cl); bs <- list()
for (b in seq_len(NB)) {
  ids <- sample(cc, length(cc), replace = TRUE)
  r <- tryCatch({ rowsOf <- function(sec) unlist(lapply(ids, function(i) which(frames[[sec]]$cl == i)))
    a <- anchorFor(list(Bulk = qBeta("Bulk", 0.90, rowsOf("Bulk")), Diffuse = qBeta("Diffuse", 0.90, rowsOf("Diffuse"))))
    k <- kOn(a); k <- k[k$year %in% c(2050, 2100) & k$pathway %in% c("current policies", "1000 Gt reference"), ]
    wk <- stats::reshape(k, idvar = c("sector", "year"), timevar = "pathway", direction = "wide")
    data.frame(draw = b, sector = wk$sector, year = wk$year, d = wk[["k.current policies"]] - wk[["k.1000 Gt reference"]]) }, error = function(e) NULL)
  if (!is.null(r)) bs[[length(bs) + 1]] <- r
  if (b %% 50 == 0) say(b, " resamples")
}
BS <- do.call(rbind, bs)
band <- do.call(rbind, lapply(split(BS, paste(BS$sector, BS$year)), function(z) data.frame(sector = z$sector[1], year = z$year[1], n = nrow(z),
  median = stats::median(z$d), p05 = stats::quantile(z$d, 0.05), p95 = stats::quantile(z$d, 0.95), sharePositive = mean(z$d > 0), row.names = NULL)))
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), taus = TAUS, strength = K, contrast2050 = W, bootstrapQ90 = band, draws = BS,
            note = paste("ceiling coefficients from the conditional tau-quantile of the response on the selected design; anchor rebuilt as for the",
                         "country bootstrap; k(t) on the cached pathway panels, theta 0.50, EU21. contrast = k(current policies) - k(1000 Gt reference).",
                         "bootstrapQ90: 199 country resamples of the 0.90-quantile fit."))
saveRDS(out, file.path(CPL, "quantile-strength.rds")); say("wrote ", file.path(CPL, "quantile-strength.rds"))
options(width = 200); print(W, row.names = FALSE, digits = 3); cat("\n== 0.90 quantile, country bootstrap of the contrast ==\n"); print(band, row.names = FALSE, digits = 3)
