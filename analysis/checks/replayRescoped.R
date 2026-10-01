# The historical-replay gate re-scoped to the rows where it can discriminate (TODO item 28).
#   Rscript analysis/checks/replayRescoped.R [group]
# The full-sample gate compares coupled vs uncoupled replay over all country-years, but the two
# paths are identical wherever the ceiling never touches the path, so the full-sample skill is
# mostly a tie by construction. This scores only the rows where the coupled path differs.
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v5" })
h <- readRDS(file.path("output/pfm", g, "historical-replay.rds"))
rmse <- function(x) sqrt(mean(x^2))
out <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(s) {
  r <- h$bySector[[s]]$rows; d <- abs(r$feasibleIndex.coupled - r$feasibleIndex.ecm) > 1e-9; x <- r[d, ]
  m <- list(nRows = nrow(r), nAffected = sum(d), shareAffected = mean(d), nCountries = length(unique(x$region)),
            countries = sort(unique(x$region)),
            rmseCoupled = rmse(x$feasibleIndex.coupled - x$observed), rmseEcm = rmse(x$feasibleIndex.ecm - x$observed))
  m$skillVsEcm <- 1 - m$rmseCoupled / m$rmseEcm
  m$meanCeilingPull <- mean(x$feasibleIndex.ecm - x$feasibleIndex.coupled)
  cat(sprintf("%-8s affected %d of %d rows (%.1f%%, %d countries)  RMSE coupled %.3f  ECM %.3f  skill %+.3f\n",
              s, m$nAffected, m$nRows, 100 * m$shareAffected, m$nCountries, m$rmseCoupled, m$rmseEcm, m$skillVsEcm))
  m })
saveRDS(list(group = g, spec = h$spec, seedYear = h$seedYear, bySector = out, generated = Sys.time()),
        file.path("output/pfm", g, "historical-replay-rescoped.rds"))
