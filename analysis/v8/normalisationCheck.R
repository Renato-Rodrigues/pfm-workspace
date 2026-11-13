# T8 of design note 0010: how much of the regional ranking u, and of the average constraint, is set by the min-max normalisation.
#   Rscript analysis/v8/normalisationCheck.R [group]   (repo root; default v8) -> output/pfm/<group>/normalisation-check.rds
# u is the min-max of the regional gaps g at the anchor year, so the most constrained region sets the scale for all the
# others. From the staged anchor (output/remind-inputs/<group>/phi-anchor.rds), per resolution and sector, u under:
#   minmax        the model's
#   noExtreme     min-max over the regions without the most constrained one, which is set to 1
#   p05p95        min-max on the 5th-95th percentile range of g, clipped to [0, 1]
#   rank          (rank - 1) / (n - 1)
# and the final-energy-weighted mean of u, the average constraint per unit of theta at the reference year (k = 1). The
# coupled headline is close to linear in theta (161 Gt per unit theta at EU21, MODEL.md 5.3), so the ratio of the weighted
# means is a first-order proxy of what a normalisation would do to it. A proxy: it ignores each region's price exposure
# and the strength path, and it is not a coupled result.
source("analysis/_common/_loadPfm.R")
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g)
norm <- list(
  minmax = function(x) (x - min(x)) / diff(range(x)),
  noExtreme = function(x) { i <- which.max(x); r <- range(x[-i]); pmin((x - r[1]) / diff(r), 1) },
  p05p95 = function(x) { r <- stats::quantile(x, c(0.05, 0.95)); pmin(pmax((x - r[1]) / diff(r), 0), 1) },
  rank = function(x) (rank(x) - 1) / (length(x) - 1))
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"))
for (res in c("EU21", "H12")) {
  a <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), res); r <- a$region
  tab <- do.call(rbind, lapply(split(r, r$sector), function(x) {
    stopifnot(max(abs(norm$minmax(x$g) - x$u)) < 1e-8)       # the check: the staged u is the min-max of the staged gaps
    w <- x$weight / sum(x$weight)
    do.call(rbind, lapply(names(norm), function(nm) { u <- norm[[nm]](x$g)
      data.frame(resolution = res, sector = x$sector[1], normalisation = nm, weightedMeanU = sum(w * u), medianU = stats::median(u),
                 rankCorWithModel = stats::cor(u, x$u, method = "spearman"), maxChange = max(abs(u - x$u)),
                 mostChanged = x$region[which.max(abs(u - x$u))], extreme = x$region[which.max(x$g)],
                 secondGapOverExtreme = sort(x$g, decreasing = TRUE)[2] / max(x$g)) })) }))
  tab$relativeToModel <- tab$weightedMeanU / tab$weightedMeanU[match(paste(tab$sector, "minmax"), paste(tab$sector, tab$normalisation))]
  out[[res]] <- tab
}
saveRDS(out, file.path(GD, "normalisation-check.rds"))
options(width = 200); for (res in c("EU21", "H12")) print(out[[res]], row.names = FALSE, digits = 3)
