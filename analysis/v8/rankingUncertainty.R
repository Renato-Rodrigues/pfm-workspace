# v8 quick test (design note 0009 section 7): how firmly is the regional ranking u pinned down, and by whom?
#   Rscript analysis/v8/rankingUncertainty.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-ranking-uncertainty.rds
# On the selected frontier, covered countries, EU21 regions, final-energy weights, anchor year 2023:
#   A. coefficient uncertainty: 1000 draws of the frontier coefficients from their estimated covariance; for each draw
#      every covered country's E (observed / ceiling) and the regions' u. Reported: each region's u median and 90% band,
#      and each extreme country's E band.
#   B. single-country leverage: each region's u with its largest country (final energy) left out.
#   C. the normalisation: u as min-max (the coupling's), as g / max g (no floor at the least constrained region), and
#      as a rank (equal steps), to show how much of a region's u is the scale.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g); ND <- 1000L; set.seed(20261027)
FOCUS <- c("ISL", "IDN", "PER", "ARG", "RUS", "SAU", "NOR", "CHN", "IND", "MEX")
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights
map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"); rmap <- stats::setNames(map$RegionCode, map$CountryCode)
gapOf <- function(E, cty) { r <- rmap[cty]; ww <- w[cty]; tapply((1 - E) * ww, r, sum) / tapply(ww, r, sum) }
mm01 <- function(x) (x - min(x)) / (max(x) - min(x))

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfg)))))
  d <- ff$data; mm <- stats::model.matrix(ff$formula, d); i23 <- which(d[rownames(mm), "year"] == 2023)
  X <- mm[i23, , drop = FALSE]; cty <- as.character(d[rownames(mm), "region"][i23]); obs <- as.numeric(ff$outcomeNatural[rownames(mm)][i23])
  b <- stats::coef(ff$model); V <- stats::vcov(ff$model); keep <- colnames(X)
  draws <- MASS::mvrnorm(ND, b[keep], V[keep, keep])
  Edraw <- sapply(seq_len(ND), function(j) pmin(obs / (10 * stats::plogis(as.numeric(X %*% draws[j, ]))), 1))
  E0 <- obs / (10 * stats::plogis(as.numeric(X %*% b[keep]))); names(E0) <- cty; rownames(Edraw) <- cty
  U <- sapply(seq_len(ND), function(j) mm01(gapOf(Edraw[, j], cty)))
  g0 <- gapOf(E0, cty); u0 <- mm01(g0)
  band <- data.frame(sector = sec, region = names(u0), u = u0, uMed = apply(U, 1, stats::median),
                     u05 = apply(U, 1, stats::quantile, 0.05), u95 = apply(U, 1, stats::quantile, 0.95),
                     topShare = apply(U, 1, function(x) mean(x == 1)), row.names = NULL)
  Eband <- data.frame(sector = sec, region = cty, E = E0, E05 = apply(Edraw, 1, stats::quantile, 0.05),
                      E95 = apply(Edraw, 1, stats::quantile, 0.95), row.names = NULL)
  lowRank <- apply(Edraw, 2, function(x) rank(x)[match(cty, cty)]); Eband$shareLowest5 <- rowMeans(lowRank <= 5)
  # B. the largest country of each region left out
  loo <- sapply(names(u0), function(r) { cc <- cty[rmap[cty] == r]; if (length(cc) < 2) return(NA_real_)
    big <- cc[which.max(w[cc])]; k <- cty != big; mm01(gapOf(E0[k], cty[k]))[[r]] })
  big <- sapply(names(u0), function(r) { cc <- cty[rmap[cty] == r]; cc[which.max(w[cc])] })
  bigShare <- sapply(names(u0), function(r) { cc <- cty[rmap[cty] == r]; max(w[cc]) / sum(w[cc]) })
  # C. the normalisation
  normal <- data.frame(sector = sec, region = names(u0), minmax = u0, ratio = g0 / max(g0), rank = (rank(g0) - 1) / (length(g0) - 1),
                       largest = big, largestShare = bigShare, uWithoutLargest = loo, row.names = NULL)
  list(band = band, Eband = Eband, normal = normal, gap = g0)
})
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), draws = ND, bySector = res), file.path(GD, "v8-ranking-uncertainty.rds"))
options(width = 220)
for (sec in names(res)) { r <- res[[sec]]; cat("\n==========", sec, "==========\n")
  m <- merge(r$band, r$normal[, -1], by = "region"); print(m[order(-m$u), -2], digits = 2, row.names = FALSE)
  cat("extreme countries, E in 2023 with its 90% band and the share of draws among the 5 lowest:\n")
  e <- r$Eband[r$Eband$region %in% FOCUS, c("region", "E", "E05", "E95", "shareLowest5")]; print(e[order(e$E), ], digits = 2, row.names = FALSE) }
