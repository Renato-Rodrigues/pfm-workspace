# T2 of design note 0010: the frontier's uncertainty with countries as the sampling unit, through to what the coupling reads.
#   Rscript analysis/v8/frontierBlockBootstrap.R [group] [resamples] [strength]   (repo root; default v8, 200, regional)
#     -> output/pfm/<group>/frontier-block-bootstrap.rds
# analysis/v8/couplingBand.R draws the ceiling coefficients from the frontier's ML covariance, which ignores that the 23
# rows of a country are not independent (design effect 1.94x / 2.46x, MODEL.md 3.3). Here the countries are resampled with
# replacement, both frontiers are refitted on each resample (the selected specification's estimation frame, its scaling
# held; buildings & transport with its rents slack, pfm:::.pfmHetFrontierFit), and each refit's ceiling coefficients go
# through the same steps as couplingBand.R: the 2023 anchor recomputed for ALL countries (observed countries keep their
# index, the uncovered their assigned share of the new ceiling), the ranking u, and the strength and shares on the coupled
# hold-the-price headline's energy system (EU21, theta 0.5).
# Reported: 5-95% bands of u, k and phi beside the ML band (v8-coupling-band-<strength>.rds), each refit's gamma, the
# resamples that failed, and the two resamples at the 5th and 95th percentile of the world's mean constraint in 2050
# (their coefficients are kept: the anchors of the emissions-band runs, R1).
# Each refit runs in a worker process (frontier::sfa's Fortran search cannot be interrupted and stalls on some
# resamples): the parent starts PFM_BOOT_WORKERS workers (default 6), each writes a marker before a resample and its
# result after; a resample that runs longer than PFM_BOOT_TIMEOUT seconds (default 240) is counted as failed, its worker
# is killed and restarted. Results are kept in output/pfm/<group>/block-bootstrap-work/, so a second call resumes.
#   (internal) Rscript analysis/v8/frontierBlockBootstrap.R <group> worker <k>
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v8"; WORKER <- length(args) >= 3 && args[2] == "worker"
NB <- if (!WORKER && length(args) >= 2) as.integer(args[2]) else 200L
STR <- if (!WORKER && length(args) >= 3) args[3] else "regional"; OPT <- list(strength = STR)
GD <- file.path("output/pfm", g); WK <- file.path(GD, "block-bootstrap-work"); dir.create(WK, showWarnings = FALSE)
if (WORKER) {   # a worker: refit its share of the resamples, one file per result
  k <- as.integer(args[3]); S <- readRDS(file.path(WK, "setup.rds"))
  refitW <- function(sec, ids) { f <- S$frames[[sec]]; rows <- unlist(lapply(ids, function(i) which(f$df$region == i)))
    d <- f$df[rows, , drop = FALSE]; if ("regionFE" %in% colnames(d) && is.factor(d$regionFE)) d$regionFE <- droplevels(d$regionFE)
    m <- frontier::sfa(f$fml, data = d); if (length(f$slack)) m <- pfm:::.pfmHetFrontierFit(f$fml, d, f$slack, m)
    cf <- stats::coef(m); b <- pfm:::.pfmCeilingBeta(cf)
    if (!all(f$names %in% names(b))) stop("a term is missing from the refit (a group left empty)")
    list(beta = b[f$names], gamma = if ("gamma" %in% names(cf)) cf[["gamma"]] else NA_real_) }
  for (i in which((seq_along(S$ids) - 1L) %% S$workers == (k - 1L))) {
    if (file.exists(file.path(WK, sprintf("res-%04d.rds", i))) || file.exists(file.path(WK, sprintf("fail-%04d.txt", i)))) next
    writeLines(c(i, Sys.getpid(), format(Sys.time(), "%Y-%m-%d %H:%M:%S")), file.path(WK, sprintf("current-%02d.txt", k)))
    r <- tryCatch(suppressWarnings(list(Bulk = refitW("Bulk", S$ids[[i]]), Diffuse = refitW("Diffuse", S$ids[[i]]))), error = function(e) conditionMessage(e))
    if (is.character(r)) writeLines(r, file.path(WK, sprintf("fail-%04d.txt", i))) else saveRDS(r, file.path(WK, sprintf("res-%04d.rds", i)))
  }
  unlink(file.path(WK, sprintf("current-%02d.txt", k))); quit(status = 0)
}
modelDir <- "output/pfm/fit-cache"; set.seed(20261110)
say <- function(...) message("[block-bootstrap:", g, "] ", ...)
options(pfm.panel = list(firstYear = 2000L, lastYear = 2023L, movingAverage = 5L, ieaVersion = "latest", geothermal = TRUE,
                         democracy = TRUE, overallAccountability = TRUE, fossilRents = TRUE))
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g)), forcecache = TRUE, .verbose = FALSE)
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path(modelDir, "panels", paste0("panel_", hash, ".rds")))
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, ".rds")))
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
anc0 <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w, histData = panel, verbose = FALSE)
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
cfgOf <- function(sec) { hit <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers")) if (!is.null(hit[[f]])) hit[[f]] <- unlist(hit[[f]]); hit }

# --- the anchor for a set of ceiling coefficients: as analysis/v8/couplingBand.R -------------------------------------------
etaOrig <- pfm:::.pfmFrontierEta; cache <- new.env()
etaCached <- function(design, data, returnDesign = FALSE) {
  key <- paste(design$sector, paste(dim(data), collapse = "x"))
  if (is.null(cache[[key]])) cache[[key]] <- etaOrig(design, data, returnDesign = TRUE)
  r <- cache[[key]]; f <- r$frame
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
summ <- function(sh) list(k = sh$strength[sh$strength$year %in% c(2050, 2100), c("sector", "year", "k")],
                          phi = sh$shares[sh$shares$year %in% c(2050, 2100), c("sector", "region", "year", "phi")])
base <- summ(pfmV6Shares(anc0, scen, theta = 0.5, options = OPT))
chk <- anchorFor(lapply(anc0$designs, `[[`, "beta"))
stopifnot(max(abs(chk$region$u - anc0$region$u), na.rm = TRUE) < 1e-8)

# --- the estimation frames, and a refit on a resample ---------------------------------------------------------------------
frames <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- cfgOf(sec)
  fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier", indexMax = 10, modelDir = NULL,
                                                       verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
  slack <- make.names(pfm:::.pfmSlackDriversFor(cfg$slackDrivers, sec) %||% character(0))
  keep <- intersect(c(all.vars(fit$formula), slack), colnames(fit$data))
  df <- fit$data[stats::complete.cases(fit$data[, keep, drop = FALSE]), , drop = FALSE]
  b0 <- pfm:::.pfmCeilingBeta(stats::coef(fit$model))
  # the check: the frame and the refit give the group's coefficients
  stopifnot(max(abs(b0[names(anc0$designs[[sec]]$beta)] - anc0$designs[[sec]]$beta)) < 1e-6)
  list(fml = fit$formula, df = df, slack = slack, names = names(anc0$designs[[sec]]$beta))
})
countries <- unique(as.character(frames$Bulk$df$region))
outFile <- file.path(GD, "frontier-block-bootstrap.rds")
NW <- as.integer(Sys.getenv("PFM_BOOT_WORKERS", "6")); TLIM <- as.numeric(Sys.getenv("PFM_BOOT_TIMEOUT", "240"))
setupFile <- file.path(WK, "setup.rds")
if (file.exists(setupFile) && length(readRDS(setupFile)$ids) == NB) S <- readRDS(setupFile) else {
  unlink(list.files(WK, full.names = TRUE))
  S <- list(frames = frames, ids = lapply(seq_len(NB), function(i) sample(countries, length(countries), replace = TRUE)), workers = NW)
  saveRDS(S, setupFile) }
NW <- S$workers
has <- function(i) file.exists(file.path(WK, sprintf("res-%04d.rds", i))) || file.exists(file.path(WK, sprintf("fail-%04d.txt", i)))
left <- function(k) { i <- which((seq_len(NB) - 1L) %% NW == (k - 1L)); i[!vapply(i, has, logical(1))] }
start <- function(k) system2(file.path(R.home("bin"), "Rscript"), c("analysis/v8/frontierBlockBootstrap.R", g, "worker", k), wait = FALSE, stdout = FALSE, stderr = FALSE)
for (k in seq_len(NW)) { unlink(file.path(WK, sprintf("current-%02d.txt", k))); if (length(left(k))) start(k) }
t0 <- Sys.time(); lastSay <- 0; restarted <- rep(Sys.time(), NW)
repeat {
  Sys.sleep(10); todo <- vapply(seq_len(NW), function(k) length(left(k)), integer(1)); if (!sum(todo)) break
  for (k in which(todo > 0)) {
    cur <- file.path(WK, sprintf("current-%02d.txt", k)); x <- if (file.exists(cur)) tryCatch(readLines(cur), error = function(e) NULL) else NULL
    if (length(x) == 3) {
      age <- as.numeric(difftime(Sys.time(), as.POSIXct(x[3]), units = "secs")); i <- as.integer(x[1])
      if (age > TLIM && !has(i)) {   # stalled: count it as failed, kill the worker, start it again
        tools::pskill(as.integer(x[2])); system2("taskkill", c("/F", "/PID", x[2]), stdout = FALSE, stderr = FALSE)
        writeLines(paste("timeout after", TLIM, "s"), file.path(WK, sprintf("fail-%04d.txt", i))); unlink(cur)
        say("resample ", i, " stalled; worker ", k, " restarted"); start(k); restarted[k] <- Sys.time() }
    } else if (as.numeric(difftime(Sys.time(), restarted[k], units = "secs")) > 120) { start(k); restarted[k] <- Sys.time() }   # the worker died or never started
  }
  done <- sum(vapply(seq_len(NB), has, logical(1)))
  if (done - lastSay >= 20) { lastSay <- done; say(done, " of ", NB, " resamples, ", length(list.files(WK, pattern = "^fail-")), " failed, ",
                                                    round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " min") }
}
fails <- list.files(WK, pattern = "^fail-", full.names = TRUE); failed <- length(fails)
failReasons <- table(vapply(fails, function(f) substr(readLines(f, warn = FALSE)[1], 1, 60), character(1)))
res <- list()
for (f in list.files(WK, pattern = "^res-", full.names = TRUE)) {
  fb <- readRDS(f); r <- tryCatch({
    a <- anchorFor(list(Bulk = fb$Bulk$beta, Diffuse = fb$Diffuse$beta)); s <- summ(pfmV6Shares(a, scen, theta = 0.5, options = OPT))
    s$u <- a$region[, c("sector", "region", "u")]; s$gamma <- c(Bulk = fb$Bulk$gamma, Diffuse = fb$Diffuse$gamma)
    s$beta <- list(Bulk = fb$Bulk$beta, Diffuse = fb$Diffuse$beta); s }, error = function(e) { failed <<- failed + 1L; NULL })
  if (!is.null(r)) res[[length(res) + 1L]] <- r
}
say(length(res), " resamples used, ", failed, " failed"); print(failReasons)
q <- function(x) stats::quantile(x, c(0.05, 0.5, 0.95), na.rm = TRUE)
ml <- tryCatch(readRDS(file.path(GD, paste0("v8-coupling-band", if (STR == "common") "" else paste0("-", STR), ".rds"))), error = function(e) NULL)
kAll <- do.call(rbind, lapply(seq_along(res), function(i) cbind(draw = i, res[[i]]$k)))
kBand <- do.call(rbind, lapply(split(kAll, paste(kAll$sector, kAll$year)), function(d) {
  m <- if (is.null(ml)) NULL else ml$strength[ml$strength$sector == d$sector[1] & ml$strength$year == d$year[1], ]
  data.frame(sector = d$sector[1], year = d$year[1], central = base$k$k[base$k$sector == d$sector[1] & base$k$year == d$year[1]],
             p05 = q(d$k)[1], p95 = q(d$k)[3], mlP05 = m$p05 %||% NA, mlP95 = m$p95 %||% NA, row.names = NULL) }))
pAll <- do.call(rbind, lapply(seq_along(res), function(i) cbind(draw = i, res[[i]]$phi)))
pBand <- do.call(rbind, lapply(split(pAll, paste(pAll$sector, pAll$region, pAll$year)), function(d) {
  key <- base$phi$sector == d$sector[1] & base$phi$region == d$region[1] & base$phi$year == d$year[1]
  m <- if (is.null(ml)) NULL else ml$phi[ml$phi$sector == d$sector[1] & ml$phi$region == d$region[1] & ml$phi$year == d$year[1], ]
  data.frame(sector = d$sector[1], region = d$region[1], year = d$year[1], central = base$phi$phi[key], p05 = q(d$phi)[1], p95 = q(d$phi)[3],
             width = q(d$phi)[3] - q(d$phi)[1], mlWidth = m$coefWidth %||% NA, thetaWidth = m$thetaWidth %||% NA, row.names = NULL) }))
uAll <- do.call(rbind, lapply(seq_along(res), function(i) cbind(draw = i, res[[i]]$u)))
uBand <- do.call(rbind, lapply(split(uAll, paste(uAll$sector, uAll$region)), function(d) {
  m <- if (is.null(ml)) NULL else ml$u[ml$u$sector == d$sector[1] & ml$u$region == d$region[1], ]
  rk <- vapply(split(uAll[uAll$sector == d$sector[1], ], uAll$draw[uAll$sector == d$sector[1]]), function(x) rank(-x$u)[x$region == d$region[1]], numeric(1))
  data.frame(sector = d$sector[1], region = d$region[1], central = anc0$region$u[anc0$region$sector == d$sector[1] & anc0$region$region == d$region[1]],
             p05 = q(d$u)[1], p95 = q(d$u)[3], mlP05 = m$p05 %||% NA, mlP95 = m$p95 %||% NA, rank05 = q(rk)[1], rank95 = q(rk)[3],
             shareMostConstrained = mean(rk == 1), row.names = NULL) }))
gam <- do.call(rbind, lapply(res, `[[`, "gamma"))
# the world's mean constraint in 2050 per resample (final-energy weights are in the shares' aggregation; here the simple mean
# of 1 - phi over regions and sectors), and the resamples at its 5th and 95th percentile: the anchors of run R1
load <- vapply(res, function(r) mean(1 - r$phi$phi[r$phi$year == 2050]), numeric(1))
edge <- c(p05 = which.min(abs(load - q(load)[1])), p95 = which.min(abs(load - q(load)[3])))
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), resamples = NB, used = length(res), failed = failed, failReasons = failReasons, timeout = TLIM, strength = kBand,
            phi = pBand, u = uBand, kDraws = kAll, shareLoosening = stats::aggregate(k ~ sector + year, data = kAll, FUN = function(x) mean(x < 1)), gamma = gam, gammaAtGate = colMeans(gam >= 0.999, na.rm = TRUE), load2050 = load,
            edges = lapply(edge, function(i) list(resample = i, load = load[i], beta = res[[i]]$beta)))
saveRDS(out, outFile); say("wrote ", outFile)
options(width = 220)
cat("resamples used", length(res), "of", NB, "| share with gamma >= 0.999:", paste(names(out$gammaAtGate), round(out$gammaAtGate, 2), collapse = ", "), "\n")
cat("\nstrength k: the country bootstrap against the ML draws\n"); print(kBand, digits = 3, row.names = FALSE)
for (sec in c("Bulk", "Diffuse")) {
  x <- pBand[pBand$sector == sec & pBand$year == 2050, ]
  cat("\n", sec, ": share in 2050, median 5-95% width: country bootstrap", round(stats::median(x$width), 3), "| ML draws",
      round(stats::median(x$mlWidth), 3), "| theta 0.325-0.675", round(stats::median(x$thetaWidth), 3), "\n")
  y <- uBand[uBand$sector == sec, ]; print(y[order(-y$central), ], digits = 2, row.names = FALSE)
}
