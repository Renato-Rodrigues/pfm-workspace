# v8 candidate (design note 0009): fossil rents as a producer-interest term of the frontier, tested offline on the v7
# estimation panel before any new Run-Group or cluster sweep.
#   Rscript analysis/v8/rentsTest.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-rents-test.rds
# Fossil rents: World Bank WDI oil + gas + coal rents, % of GDP (NY.GDP.PETR.RT.ZS, NY.GDP.NGAS.RT.ZS,
# NY.GDP.COAL.RT.ZS), downloaded here (WDI package), log(1 + rents) to tame the skew (Saudi Arabia ~25%), held at its
# last value after 2021 (the series ends there), centred five-year mean as every panel column, added to the panel as
# "Fossil Rents" (no sector suffix: one series for both sectors). Variants of the selected v7 specification, both
# sectors, frontier and mean regression:
#   v7       the selected specification;
#   A_add    fossil rents added as a fourth actor-power term (main effect + three weighted interactions);
#   B_swap   fossil rents replacing fossil energy per person (the scale channel), same number of terms as v7.
# Reported: fit (frontier logLik, BIC; mean-regression R2), the rents terms (asymptotic clustered p of the mean
# regression; the wild bootstrap is not rerun), H1 for the fossil share, max VIF, the correlation of rents with the
# existing fossil terms, every covered country's E in 2023, and a covered-countries regional u (EU21).
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
FOCUS <- c("SAU", "RUS", "IDN", "NOR", "CAN", "AUS", "MEX", "COL", "ARG", "PER", "ISL", "CHN", "USA")
hash <- jsonlite::fromJSON(file.path("output/pfm", g, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
cty <- getItems(panel, dim = 1); yrs <- getYears(panel, as.integer = TRUE)

# ---- the rents series ------------------------------------------------------------------------------------------------
cache <- file.path("output/pfm", g, "v8-wdi-rents.rds")
wdi <- if (file.exists(cache)) readRDS(cache) else {
  options(timeout = 900)   # the World Bank API is slow; one indicator per request
  ind <- c(oil = "NY.GDP.PETR.RT.ZS", gas = "NY.GDP.NGAS.RT.ZS", coal = "NY.GDP.COAL.RT.ZS")
  parts <- lapply(names(ind), function(n) { x <- WDI::WDI(country = "all", indicator = stats::setNames(ind[[n]], n), start = 1995, end = 2023, extra = FALSE)
    if (!nrow(x)) stop("WDI download of ", ind[[n]], " returned nothing"); x[, c("iso3c", "year", n)] })
  x <- Reduce(function(a, b) merge(a, b, by = c("iso3c", "year"), all = TRUE), parts)
  if (sum(is.finite(x$oil)) < 3000) stop("WDI download incomplete")
  saveRDS(x, cache); x }
wdi$rents <- rowSums(wdi[, c("oil", "gas", "coal")], na.rm = TRUE)
wdi$rents[rowSums(is.finite(as.matrix(wdi[, c("oil", "gas", "coal")]))) == 0] <- NA
R <- matrix(NA_real_, length(cty), length(1995:2023), dimnames = list(cty, as.character(1995:2023)))
for (i in seq_len(nrow(wdi))) if (wdi$iso3c[i] %in% cty) R[wdi$iso3c[i], as.character(wdi$year[i])] <- wdi$rents[i]
dn <- dimnames(R)
R <- t(apply(R, 1, function(r) { ok <- which(is.finite(r)); if (!length(ok)) return(r)   # hold the last value, fill gaps
  r[seq_len(length(r)) > max(ok)] <- r[max(ok)]; stats::approx(ok, r[ok], xout = seq_along(r), rule = 2)$y }))
R <- log1p(R); dimnames(R) <- dn
ma <- t(apply(R, 1, function(r) vapply(seq_along(r), function(i) mean(r[max(1, i - 2):min(length(r), i + 2)], na.rm = TRUE), 0)))
dimnames(ma) <- dn
RN <- c("Fossil Rents", "Fossil Rents|Bulk", "Fossil Rents|Diffuse")   # the index list reads the sector-qualified name
rm <- new.magpie(cty, yrs, RN, fill = NA)
for (y in yrs) for (n in RN) rm[, y, n] <- ma[cty, as.character(y)]
panelR <- mbind(panel, rm)

# ---- the variants ----------------------------------------------------------------------------------------------------
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(file.path("output/pfm", g)))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
VARIANTS <- list(
  v7 = function(c) c,
  A_add = function(c) { c$actorPowerDrivers <- c(c$actorPowerDrivers, "Fossil Rents"); c$actorPowerIndex <- c(c$actorPowerIndex, "Fossil Rents"); c },
  B_swap = function(c) { s <- function(v) replace(v, v == "Incumbent Power pc", "Fossil Rents")
    c$actorPowerDrivers <- s(c$actorPowerDrivers); c$actorPowerIndex <- s(c$actorPowerIndex); c })
fitOne <- function(sec, vn, estimator) {
  cfg <- VARIANTS[[vn]](norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]))
  a <- .pfmSpecArgs(cfg)
  suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panelR, sector = sec, estimator = estimator,
                                                                                  indexMax = 10, modelDir = NULL, verbose = FALSE), a))))
}
anc <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21"); w <- anc$weights
map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv")
rmap <- stats::setNames(map$RegionCode, map$CountryCode)
res <- lapply(c("Bulk", "Diffuse"), function(sec) {
  fits <- lapply(stats::setNames(names(VARIANTS), names(VARIANTS)), function(vn) list(frontier = fitOne(sec, vn, "frontier"), mean = fitOne(sec, vn, "satP")))
  fit <- do.call(rbind, lapply(names(fits), function(n) { ff <- fits[[n]]$frontier; mf <- fits[[n]]$mean
    k <- nrow(ff$coeftest); ll <- as.numeric(stats::logLik(ff$model)); nn <- nrow(ff$frontier)
    r2 <- tryCatch(1 - stats::deviance(mf$model) / mf$model$null.deviance, error = function(e) NA_real_)
    data.frame(sector = sec, variant = n, logLik = ll, BIC = -2 * ll + k * log(nn), gamma = ff$frontierGamma, maxVIF = ff$maxVIF,
               meanR2 = r2, vcov = ff$vcovCheck$status) }))
  terms <- do.call(rbind, lapply(names(fits), function(n) { ct <- fits[[n]]$frontier$coeftest; m <- fits[[n]]$mean$coeftest
    k <- grep("Fossil.Rents|^Incumbent.Power$", rownames(ct), value = TRUE)
    data.frame(sector = sec, variant = n, term = k, frontier = ct[k, 1], frontierP = ct[k, 4], mean = m[k, 1], meanP = m[k, 4], row.names = NULL) }))
  E <- do.call(rbind, lapply(names(fits), function(n) { s <- fits[[n]]$frontier$frontier
    cbind(sector = sec, variant = n, s[s$year == 2023, c("region", "observedIndex", "frontierIndex", "efficiencyRatio")]) }))
  U <- do.call(rbind, lapply(names(fits), function(n) { e <- E[E$variant == n, ]; e$r <- rmap[e$region]; e$w <- w[e$region]
    rg <- stats::aggregate(cbind(gw = (1 - efficiencyRatio) * w, w) ~ r, e, sum); rg$g <- rg$gw / rg$w
    data.frame(sector = sec, variant = n, region = rg$r, u = (rg$g - min(rg$g)) / (max(rg$g) - min(rg$g))) }))
  d <- fits$A_add$mean$data
  cors <- stats::cor(d[, intersect(c("Fossil.Rents", "Incumbent.Power", "Incumbent.Power.pc", "Innovator.Power"), names(d))], use = "complete.obs")
  list(fit = fit, terms = terms, E = E, U = U, cor = cors)
})
names(res) <- c("Bulk", "Diffuse")
rents23 <- data.frame(region = cty, rentsPctGDP = expm1(ma[cty, "2023"]))
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), rents2023 = rents23, bySector = res),
        file.path("output/pfm", g, "v8-rents-test.rds"))
options(width = 220)
cat("fossil rents 2023 (held from 2021), % of GDP, sample countries with > 2%:\n")
cov <- unique(res$Bulk$E$region); r <- rents23[rents23$region %in% cov & rents23$rentsPctGDP > 2, ]; print(r[order(-r$rentsPctGDP), ], digits = 3, row.names = FALSE)
for (sec in names(res)) {
  x <- res[[sec]]; cat("\n==========", sec, "==========\n"); print(x$fit, digits = 4, row.names = FALSE); print(x$terms, digits = 3, row.names = FALSE)
  cat("correlations (standardised, estimation rows):\n"); print(round(x$cor, 2))
  e <- reshape(x$E[, c("variant", "region", "efficiencyRatio")], idvar = "region", timevar = "variant", direction = "wide")
  names(e) <- sub("efficiencyRatio.", "E_", names(e), fixed = TRUE); print(e[e$region %in% FOCUS, ], digits = 3, row.names = FALSE)
  u <- reshape(x$U[, c("variant", "region", "u")], idvar = "region", timevar = "variant", direction = "wide"); names(u) <- sub("u.", "u_", names(u), fixed = TRUE)
  print(u[order(-u$u_v7), ][1:8, ], digits = 2, row.names = FALSE)
}
