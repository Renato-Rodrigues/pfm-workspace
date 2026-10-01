# Fig 1b — observed stringency against the estimated ceiling.
#
# The figure that makes "frontier, not regression" visual. Everything about it is chosen to
# serve that one point: the ceiling is a boundary the points sit UNDER, and the vertical
# distance to it is the quantity the rest of the model is built on.

figFrontierFit <- function(group = "v5", year = 2022) {
  fr <- pfmArtifact(group, "frontier.rds")

  d <- do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) {
    s <- as.data.frame(fr$bySector[[sec]]$scores)
    s <- s[s$year == year & is.finite(s$frontierIndex) & is.finite(s$observedIndex), ]
    data.frame(region = s$region, sector = sec,
               observed = s$observedIndex, ceiling = s$frontierIndex,
               efficiency = s$efficiencyRatio, stringsAsFactors = FALSE)
  }))
  d$slack <- d$ceiling - d$observed

  # Label only Diffuse: Bulk slack ranks are not robust, so naming Bulk countries here
  # would invite exactly the country-level reading MODEL.md 3.4 forbids.
  lab <- d[d$sector == "Diffuse", ]
  lab <- lab[order(-lab$slack), ][1:5, ]

  med <- do.call(rbind, lapply(split(d, d$sector), function(x)
    data.frame(sector = x$sector[1], medE = stats::median(x$efficiency, na.rm = TRUE))))
  med$lab <- sprintf("median E = %.3f", med$medE)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = ceiling, y = observed)) +
    # the ceiling itself: points cannot lie materially above this
    ggplot2::geom_abline(slope = 1, intercept = 0, linewidth = 0.5, colour = "grey20") +
    ggplot2::geom_segment(ggplot2::aes(xend = ceiling, yend = ceiling),
                          colour = "grey75", linewidth = 0.25) +
    ggplot2::geom_point(ggplot2::aes(colour = sector), size = 1.3, alpha = 0.85) +
    ggrepelOrText(lab) +
    ggplot2::geom_text(data = med, ggplot2::aes(x = 0.4, y = 9.6, label = lab),
                       hjust = 0, size = 2.6, colour = "grey25", inherit.aes = FALSE) +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_colour_manual(values = pfmSectorColours(), guide = "none") +
    ggplot2::scale_x_continuous(breaks = seq(0, 10, 2.5),
                                labels = c("0", "2.5", "5", "7.5", "")) +
    ggplot2::scale_y_continuous(breaks = seq(0, 10, 2.5)) +
    ggplot2::coord_equal(xlim = c(0, 10), ylim = c(0, 10)) +
    ggplot2::labs(
      title = "Countries sit below their own political ceiling",
      subtitle = paste0("Observed CAPMF stringency against the estimated frontier, ",
                        year, ".  Grey segments are political slack."),
      x = "Estimated ceiling  S*  (index, 0-10)",
      y = "Observed stringency  S")
  attr(p, "pfmGrid") <- "both"
  pfmStamp(p, group)
}

# geom_text_repel if ggrepel is available, plain text otherwise — the figure must build on
# a machine that does not have every convenience package.
ggrepelOrText <- function(lab) {
  if (requireNamespace("ggrepel", quietly = TRUE)) {
    ggrepel::geom_text_repel(data = lab, ggplot2::aes(label = region), size = 2.2,
                             colour = "grey20", min.segment.length = 0, seed = 1,
                             max.overlaps = 20)
  } else {
    ggplot2::geom_text(data = lab, ggplot2::aes(label = region), size = 2.2,
                       colour = "grey20", hjust = -0.15, vjust = 0.5)
  }
}
