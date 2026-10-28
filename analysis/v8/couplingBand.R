# v8 item (design note 0009 section 13): how much does the frontier's coefficient uncertainty move what the coupling
# delivers, next to the declared theta and kappa?
#   Rscript analysis/v8/couplingBand.R [group] [draws]   (repo root; default v7, 200) -> output/pfm/<group>/v8-coupling-band.rds
# Draws of the frontier's ceiling coefficients from their covariance (frontier.rds, per sector). For each draw: the 2023
# anchor is recomputed as computeAnchorGap does it - each country's ceiling moves, the observed countries keep their
# observed index, the uncovered keep their assigned share E of the (new) ceiling - so the distance q and the regional
# ranking u change; then the strength path and the shares (pfmV6Shares, theta 0.5) on the coupled hold-the-price
# headline's energy system (EU21). The design matrices are built once (.pfmFrontierEta(returnDesign = TRUE)) and reused.
# Reported: the 5-95% band of the strength k and of each region's share phi (2050, 2100) and of u, against the spread
# that theta 0.325-0.675 gives at the central coefficients.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v7"; ND <- if (length(args) >= 2) as.integer(args[2]) else 200L
GD <- file.path("output/pfm", g); modelDir <- "output/pfm/fit-cache"; set.seed(20261028)
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path(modelDir, "panels", paste0("panel_", hash, ".rds")))
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, ".rds")))
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
fr <- readRDS(file.path(GD, "frontier.rds"))
anc0 <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w, histData = panel, verbose = FALSE)

# eta with cached design matrices: one build per (sector, panel), then eta = mm %*% beta for whatever beta the design holds
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
    sNew <- 10 * stats::plogis(etaA[cc$region])
    n <- a$designs[[sec]]$nSqueeze
    sq <- function(p) pfm:::.pfmSqueeze(pmin(pmax(p, 0), 1), n)
    # the uncovered country's assigned share E, recovered from its squeezed anchor y (Smithson-Verkuilen inverted)
    e0 <- pmin((stats::plogis(cc$yAnchor) * n - 0.5) / (n - 1) * 10 / cc$ceilingAnchor, 1)
    y <- ifelse(cc$basis == "observed", cc$yAnchor, stats::qlogis(sq(e0 * sNew / 10)))
    a$country$etaAnchor[i] <- etaA[cc$region]; a$country$yAnchor[i] <- y; a$country$q[i] <- etaA[cc$region] - y
    a$country$ceilingAnchor[i] <- sNew; a$country$indexAnchor[i] <- 10 * stats::plogis(etaA[cc$region] - (etaA[cc$region] - y))
    ok <- is.finite(a$country$q[i])
    path <- data.frame(region = cc$region[ok], year = ta, feasibleIndex = a$country$indexAnchor[i][ok],
                       ceilingIndex = sNew[ok], outOfCoverage = FALSE, stringsAsFactors = FALSE)
    agg <- suppressWarnings(aggregateFeasibilityToRegions(path, a$mapping, weights = a$weights, theta = 0.5))
    agg <- agg[is.finite(agg$relativeGap), ]
    u <- stats::setNames((agg$relativeGap - min(agg$relativeGap)) / diff(range(agg$relativeGap)), agg$region)
    j <- which(a$region$sector == sec); a$region$u[j] <- u[a$region$region[j]]
  }
  a
}
summ <- function(sh) list(k = sh$strength[sh$strength$year %in% c(2050, 2100), c("sector", "year", "k")],
                          phi = sh$shares[sh$shares$year %in% c(2050, 2100), c("sector", "region", "year", "phi")])
base <- summ(pfmV6Shares(anc0, scen, theta = 0.5))
# check: the central coefficients through anchorFor reproduce the package's anchor
chk <- anchorFor(lapply(anc0$designs, `[[`, "beta"))
stopifnot(max(abs(chk$region$u - anc0$region$u), na.rm = TRUE) < 1e-8)
thetaSpread <- lapply(c(lo = 0.325, hi = 0.675), function(th) summ(pfmV6Shares(anc0, scen, theta = th)))

draws <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  b <- anc0$designs[[sec]]$beta; V <- fr$bySector[[sec]]$vcov
  k <- intersect(names(b), rownames(V)); if (length(k) < length(b)) stop(sec, ": vcov lacks ", paste(setdiff(names(b), k), collapse = ", "))
  MASS::mvrnorm(ND, b[k], V[k, k])
})
t0 <- Sys.time()
out <- lapply(seq_len(ND), function(i) {
  a <- anchorFor(list(Bulk = draws$Bulk[i, ], Diffuse = draws$Diffuse[i, ]))
  s <- summ(pfmV6Shares(a, scen, theta = 0.5))
  s$u <- a$region[, c("sector", "region", "u")]; s
})
message("[band] ", ND, " draws in ", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " min")
q <- function(x) stats::quantile(x, c(0.05, 0.5, 0.95), na.rm = TRUE)
kAll <- do.call(rbind, lapply(seq_along(out), function(i) cbind(draw = i, out[[i]]$k)))
kBand <- do.call(rbind, lapply(split(kAll, paste(kAll$sector, kAll$year)), function(d) {
  b0 <- base$k$k[base$k$sector == d$sector[1] & base$k$year == d$year[1]]
  data.frame(sector = d$sector[1], year = d$year[1], central = b0, p05 = q(d$k)[1], p50 = q(d$k)[2], p95 = q(d$k)[3], row.names = NULL) }))
pAll <- do.call(rbind, lapply(seq_along(out), function(i) cbind(draw = i, out[[i]]$phi)))
pBand <- do.call(rbind, lapply(split(pAll, paste(pAll$sector, pAll$region, pAll$year)), function(d) {
  key <- base$phi$sector == d$sector[1] & base$phi$region == d$region[1] & base$phi$year == d$year[1]
  lo <- thetaSpread$hi$phi$phi[key]; hi <- thetaSpread$lo$phi$phi[key]
  data.frame(sector = d$sector[1], region = d$region[1], year = d$year[1], central = base$phi$phi[key],
             p05 = q(d$phi)[1], p95 = q(d$phi)[3], coefWidth = q(d$phi)[3] - q(d$phi)[1], thetaWidth = hi - lo, row.names = NULL) }))
uAll <- do.call(rbind, lapply(seq_along(out), function(i) cbind(draw = i, out[[i]]$u)))
uBand <- do.call(rbind, lapply(split(uAll, paste(uAll$sector, uAll$region)), function(d) {
  data.frame(sector = d$sector[1], region = d$region[1], central = anc0$region$u[anc0$region$sector == d$sector[1] & anc0$region$region == d$region[1]],
             p05 = q(d$u)[1], p95 = q(d$u)[3], row.names = NULL) }))
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), draws = ND, strength = kBand, phi = pBand, u = uBand),
        file.path(GD, "v8-coupling-band.rds"))
options(width = 200)
cat("strength k (common), EU21 hold the price, theta 0.5: central and the 5-95% band over", ND, "coefficient draws\n"); print(kBand, digits = 3, row.names = FALSE)
for (sec in c("Bulk", "Diffuse")) {
  cat("\n", sec, ": share phi in 2050, coefficient band against the theta 0.325-0.675 spread\n")
  x <- pBand[pBand$sector == sec & pBand$year == 2050, ]; print(x[order(x$central), ], digits = 2, row.names = FALSE)
  cat("median width: coefficients", round(stats::median(x$coefWidth), 3), "| theta", round(stats::median(x$thetaWidth), 3), "\n")
  y <- uBand[uBand$sector == sec, ]; cat("ranking u, widest 5-95% bands:\n"); print(utils::head(y[order(-(y$p95 - y$p05)), ], 6), digits = 2, row.names = FALSE)
}
