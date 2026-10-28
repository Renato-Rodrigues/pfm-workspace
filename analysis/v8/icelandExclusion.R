# v8 test (design note 0009 section 9.1): should Iceland leave the estimation sample?
#   Rscript analysis/v8/icelandExclusion.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-iceland-exclusion.rds
# Iceland's power system is almost entirely renewable (fossil dependence the lowest of the sample), so a carbon-pricing
# index that scores instruments may measure little need rather than little will (section 1). The package's exclusion
# switch (options(pfm.excludeCountries), which already drops Estonia) refits the selected specification without it:
#   v7 / v7-ISL           the selected specification, with and without Iceland;
#   fos5 / fos5-ISL       the same with the v8 fossil lower bound (fossilFloor = 0.05).
# Reported per sector: frontier logLik per row (the samples differ), gamma, the coefficients that move most, H1-H2 on the
# mean regression (.pfmTheoryScreen), H3 coherence, every other covered country's E in 2023 (rank correlation, largest
# changes) and the covered-countries regional u (EU21).
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
tg <- utils::modifyList(pfm:::.pfmTheoryGateDefaults(), rc$sweep$theoryGate %||% list())
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"); rmap <- stats::setNames(map$RegionCode, map$CountryCode)
uOf <- function(E) { r <- rmap[names(E)]; ww <- w[names(E)]; gg <- tapply((1 - E) * ww, r, sum) / tapply(ww, r, sum); (gg - min(gg)) / (max(gg) - min(gg)) }
base0 <- getOption("pfm.excludeCountries", "EST")
V <- list(`v7` = list(ex = base0, floor = NULL), `v7-ISL` = list(ex = c(base0, "ISL"), floor = NULL),
          `fos5` = list(ex = base0, floor = 0.05), `fos5-ISL` = list(ex = c(base0, "ISL"), floor = 0.05))

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg0 <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  out <- lapply(names(V), function(vn) {
    options(pfm.excludeCountries = V[[vn]]$ex); on.exit(options(pfm.excludeCountries = base0))
    cfg <- cfg0; cfg$fossilFloor <- V[[vn]]$floor; cfg$name <- vn
    fit <- function(est) suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = est,
                           indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfg)))))
    ff <- fit("frontier"); mf <- fit("satP")
    b <- stats::coef(ff$model); bb <- b[!names(b) %in% c("sigmaSq", "gamma")]
    ct <- as.data.frame(unclass(mf$coeftest)); names(ct) <- c("estimate", "stdError", "zValue", "pValue")
    ct$term <- rownames(mf$coeftest); ct$model <- vn; ct$sector <- sec
    s <- ff$frontier; e <- s[s$year == 2023, ]
    list(fit = data.frame(sector = sec, variant = vn, n = nrow(ff$frontier), logLik = as.numeric(stats::logLik(ff$model)),
                          llPerRow = as.numeric(stats::logLik(ff$model)) / nrow(ff$frontier), gamma = ff$frontierGamma,
                          H3 = pfm:::.pfmTheoryCoherence(bb, ff$data)$share, ISLinSample = "ISL" %in% s$region),
         beta = bb, coefs = ct, E = stats::setNames(e$efficiencyRatio, e$region))
  })
  names(out) <- names(V)
  fit <- do.call(rbind, lapply(out, `[[`, "fit"))
  th <- pfm:::.pfmTheoryScreen(do.call(rbind, lapply(out, `[[`, "coefs")), names(V), sec, tg)
  fit$H1H2 <- th$pass[match(fit$variant, th$model)]; fit$theoryReason <- th$reason[match(fit$variant, th$model)]
  cmp <- function(a, b) { k <- intersect(names(out[[a]]$E), names(out[[b]]$E)); k <- setdiff(k, "ISL")
    d <- out[[b]]$E[k] - out[[a]]$E[k]
    list(spearmanE = stats::cor(out[[a]]$E[k], out[[b]]$E[k], method = "spearman"), maxAbsDE = max(abs(d)),
         largest = utils::head(sort(abs(d), decreasing = TRUE), 5) * sign(d[names(utils::head(sort(abs(d), decreasing = TRUE), 5))]),
         spearmanU = { ua <- uOf(out[[a]]$E[k]); ub <- uOf(out[[b]]$E[k]); stats::cor(ua, ub[names(ua)], method = "spearman") },
         uA = uOf(out[[a]]$E[k]), uB = uOf(out[[b]]$E[k]),
         dBeta = { kk <- intersect(names(out[[a]]$beta), names(out[[b]]$beta)); utils::head(sort((out[[b]]$beta - out[[a]]$beta)[kk], decreasing = TRUE), 0)
                   x <- (out[[b]]$beta - out[[a]]$beta)[kk]; x[order(-abs(x))][1:6] }) }
  list(fit = fit, v7 = cmp("v7", "v7-ISL"), fos5 = cmp("fos5", "fos5-ISL"), ISL = sapply(out, function(o) o$E["ISL"]))
})
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), bySector = res), file.path(GD, "v8-iceland-exclusion.rds"))
options(width = 220)
for (sec in names(res)) { r <- res[[sec]]; cat("\n==========", sec, "==========\n")
  print(r$fit, digits = 4, row.names = FALSE)
  cat("Iceland's E 2023 in-sample:", paste(names(r$ISL), round(r$ISL, 2), collapse = " | "), "\n")
  for (k in c("v7", "fos5")) { x <- r[[k]]
    cat(sprintf("%s: without Iceland, other countries' E rank correlation %.3f, max |dE| %.3f; regional u rank correlation %.3f\n",
                k, x$spearmanE, x$maxAbsDE, x$spearmanU))
    cat("  largest dE:", paste(names(x$largest), sprintf("%+.3f", x$largest), collapse = ", "), "\n")
    cat("  coefficients moving most:", paste(names(x$dBeta), sprintf("%+.3f", x$dBeta), collapse = ", "), "\n")
    cat("  u NEN with/without:", round(x$uA[["NEN"]], 3), round(x$uB[["NEN"]], 3), "\n") } }
