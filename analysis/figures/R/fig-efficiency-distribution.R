# Fig 1c — distribution of the efficiency ratio, by sector and by how it was obtained.
#
# ⚠️ NOT built on projection.rds$implementability. That column is exactly index/10 —
# the S/10 multiplier MODEL.md 7 prohibits, because it compares every country to a
# universal maximum instead of to its own ceiling. Verified: the column equals index/10 to
# machine precision for all 7,440 rows.
#
# The right quantity is E = S/S*, and it comes from two artifacts that partition the 248
# projected countries exactly:
#   frontier.rds$scores          48 in-coverage countries — E is ESTIMATED
#   donor-assignment-band-<s>    200 out-of-coverage      — E is TRANSFERRED (donor/band)
#
# Plotting them in one undifferentiated distribution would be the coverage failure in
# picture form, so provenance is the fill.

.pfmEfficiencyByProvenance <- function(group) {
  fr <- pfmArtifact(group, "frontier.rds")
  do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) {
    sc <- as.data.frame(fr$bySector[[sec]]$scores)
    sc <- sc[sc$year == max(sc$year) & is.finite(sc$efficiencyRatio), ]
    obs <- data.frame(region = sc$region, sector = sec, E = sc$efficiencyRatio,
                      basis = "observed", stringsAsFactors = FALSE)
    a <- as.data.frame(pfmArtifact(group, paste0("donor-assignment-band-", sec, ".rds")))
    tr <- data.frame(region = a$region, sector = sec, E = a$efficiencyRatio,
                     basis = a$basis, stringsAsFactors = FALSE)
    rbind(obs, tr)
  }))
}

figEfficiencyDistribution <- function(group = "v5") {
  d <- .pfmEfficiencyByProvenance(group)
  d <- d[is.finite(d$E), ]
  lev <- c("observed", "donor", "lowBand", "median")
  labs <- c(observed = "estimated (in coverage)", donor = "donor-transferred",
            lowBand  = "low band (below support)", median = "median (unmatched)")
  d$basis <- factor(d$basis, levels = lev)

  n <- as.data.frame(table(d$sector, d$basis))
  names(n) <- c("sector", "basis", "n")
  ann <- do.call(rbind, lapply(split(d, d$sector), function(x) {
    o <- x[x$basis == "observed", ]
    data.frame(sector = x$sector[1],
               lab = sprintf("%d of %d estimated · median E = %.3f (estimated only)",
                             nrow(o), nrow(x), stats::median(o$E)),
               stringsAsFactors = FALSE)
  }))

  p <- ggplot2::ggplot(d, ggplot2::aes(x = E, fill = basis)) +
    ggplot2::geom_histogram(binwidth = 0.025, colour = "white", linewidth = 0.12) +
    ggplot2::geom_text(data = ann, ggplot2::aes(x = 0.02, y = Inf, label = lab),
                       hjust = 0, vjust = 1.6, size = 2.4, colour = "grey25",
                       inherit.aes = FALSE) +
    ggplot2::facet_wrap(~ sector, ncol = 1, scales = "free_y") +
    ggplot2::scale_fill_manual(values = c(observed = pfmAccent(), donor = "#7FA8C9",
                                          lowBand = "#D9B48F", median = "grey78"),
                               labels = labs, drop = FALSE) +
    # coord_cartesian, not scale limits: scale limits FILTER the data (and drop empty
    # bins with a warning), coord zooms. E is bounded in (0,1] by construction anyway.
    ggplot2::coord_cartesian(xlim = c(0, 1)) +
    ggplot2::guides(fill = ggplot2::guide_legend(nrow = 2)) +
    ggplot2::labs(
      title = "Most countries' position is transferred, not estimated",
      subtitle = paste("Efficiency ratio E = S/S*, all 248 projected countries.",
                       "Only the dark bars are\nestimated; the rest inherit a relative gap",
                       "from the band rule."),
      x = "efficiency ratio  E = S / S*", y = "countries")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "E = S/S*, never S/10")
}
