# The selected v7 form (clean-energy build-out saturates, the fossil terms linear: satInn) against its twin with every
# actor-power term saturating (satAP, as v6), same specification otherwise: does saturating the fossil terms fix the
# extreme efficiency ratios at the edge of the data (Iceland), and what does it change elsewhere?
#   Rscript analysis/checks/saturationAlternative.R [group]   (repo root; default v7) -> output/pfm/<group>/saturation-alternative.rds
# Both forms refitted here on the group's estimation panel (frontier and mean regression, the selected specification's
# arguments, apTransform switched). Reported per sector: fit (logLik, gamma, LR), the fossil and clean-energy frontier
# coefficients, H1 on the mean regression (asymptotic clustered p: the wild bootstrap is not rerun), every covered
# country's E in 2023 under both forms, and a covered-countries-only regional ranking u (EU21, final-energy weights) as a
# first reading of what the coupling would see (the coupling's anchor also places the uncovered countries).
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
FOCUS <- c("ISL", "ARG", "SAU", "IDN", "RUS", "PER", "NOR", "CHN", "IND", "USA")
hash <- jsonlite::fromJSON(file.path("output/pfm", g, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(file.path("output/pfm", g)))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
FORMS <- c(`only clean energy saturates (selected, satInn)` = "saturating-innovator", `every actor-power term saturates (satAP)` = "saturating")
fitOne <- function(sec, form, estimator) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  a <- .pfmSpecArgs(cfg); a$apTransform <- form
  suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = estimator,
                                                                                  indexMax = 10, modelDir = NULL, verbose = FALSE), a))))
}
anc <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21"); w <- anc$weights
map <- utils::read.csv2(file.path("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"))
rmap <- stats::setNames(map$RegionCode, map$CountryCode)
res <- lapply(c("Bulk", "Diffuse"), function(sec) {
  fits <- lapply(FORMS, function(f) list(frontier = fitOne(sec, f, "frontier"), mean = fitOne(sec, f, "satP")))
  fit <- do.call(rbind, lapply(names(fits), function(n) { ff <- fits[[n]]$frontier
    data.frame(sector = sec, form = n, logLik = as.numeric(stats::logLik(ff$model)), gamma = ff$frontierGamma, lr = ff$frontierLR,
               maxVIF = ff$maxVIF, vcov = ff$vcovCheck$status) }))
  coefs <- do.call(rbind, lapply(names(fits), function(n) {
    ct <- fits[[n]]$frontier$coeftest; k <- grep("Power", rownames(ct), value = TRUE)
    m <- fits[[n]]$mean$coeftest
    data.frame(sector = sec, form = n, term = k, frontier = ct[k, 1], frontierP = ct[k, 4],
               mean = m[k, 1], meanP = m[k, 4], row.names = NULL) }))
  E <- do.call(rbind, lapply(names(fits), function(n) { s <- fits[[n]]$frontier$frontier
    s <- s[s$year == 2023, c("region", "observedIndex", "frontierIndex", "efficiencyRatio")]; cbind(sector = sec, form = n, s) }))
  # covered-countries regional reading: g = 1 - E, final-energy weighted, min-max over the regions
  U <- do.call(rbind, lapply(names(fits), function(n) { e <- E[E$form == n, ]; e$r <- rmap[e$region]; e$w <- w[e$region]
    rg <- stats::aggregate(cbind(gw = (1 - efficiencyRatio) * w, w) ~ r, e, sum); rg$g <- rg$gw / rg$w
    data.frame(sector = sec, form = n, region = rg$r, g = rg$g, u = (rg$g - min(rg$g)) / (max(rg$g) - min(rg$g))) }))
  list(fit = fit, coefs = coefs, E = E, U = U)
})
names(res) <- c("Bulk", "Diffuse")
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), forms = FORMS, bySector = res),
        file.path("output/pfm", g, "saturation-alternative.rds"))
options(width = 220)
for (sec in names(res)) {
  r <- res[[sec]]; cat("\n==========", sec, "==========\n"); print(r$fit, digits = 4, row.names = FALSE)
  print(r$coefs, digits = 3, row.names = FALSE)
  e <- reshape(r$E[, c("form", "region", "efficiencyRatio")], idvar = "region", timevar = "form", direction = "wide")
  names(e) <- c("region", "E_satInn", "E_satAP"); e$rankInn <- rank(e$E_satInn); e$rankAP <- rank(e$E_satAP)
  cat("Spearman of country E between the forms:", round(stats::cor(e$E_satInn, e$E_satAP, method = "spearman"), 3), "\n")
  print(e[e$region %in% FOCUS, ], digits = 3, row.names = FALSE)
  cat("lowest E under satAP:\n"); print(utils::head(e[order(e$E_satAP), ], 6), digits = 3, row.names = FALSE)
  u <- reshape(r$U[, c("form", "region", "u")], idvar = "region", timevar = "form", direction = "wide"); names(u) <- c("region", "u_satInn", "u_satAP")
  cat("covered-countries regional u (EU21), Spearman", round(stats::cor(u$u_satInn, u$u_satAP, method = "spearman"), 3), "\n")
  print(u[order(-u$u_satInn), ], digits = 2, row.names = FALSE)
}
