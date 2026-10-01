# Fig 3b — where the ceiling binds.
#
# The distributional figure: the constraint is not a uniform haircut. Ranked, because rank
# order is what survives; the levels move with theta and with the Run-Group.
#
# The USA is flagged rather than silently plotted: its feasibility share moves across the
# entire scale under defensible donor rules (TODO item 6), so a point estimate for it is not
# a result. Flagging on the figure is better than a caption nobody reads.

figShortfallRegions <- function(group = "v5", year = 2050) {
  cs <- pfmArtifact(group, "coupling/coupling-summary.rds")
  b <- as.data.frame(cs$boundAnchor)
  d <- b[b$year == year & is.finite(b$bindGap), ]
  if (!nrow(d)) stop("no boundAnchor rows at ", year, call. = FALSE)

  d$shortfallPct <- 100 * d$bindGap / d$priceOptimal
  d <- d[order(d$bindGap), ]
  d$region <- factor(d$region, levels = d$region)
  d$uncertain <- d$region %in% c("USA")

  th <- cs$anchorTheta

  p <- ggplot2::ggplot(d, ggplot2::aes(x = bindGap, y = region)) +
    ggplot2::geom_segment(ggplot2::aes(xend = 0, yend = region), colour = "grey80",
                          linewidth = 0.9) +
    ggplot2::geom_point(ggplot2::aes(colour = uncertain, shape = uncertain), size = 2.4) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("$%.0f  (%.0f%%)", bindGap,
                                                    shortfallPct)),
                       hjust = -0.12, size = 2.3, colour = "grey30") +
    ggplot2::scale_colour_manual(
      values = c(`FALSE` = pfmAccent(), `TRUE` = pfmRail()),
      labels = c(`FALSE` = "in coverage",
                 `TRUE` = "share not identified across rules — treat as a range"),
      breaks = c(FALSE, TRUE)) +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 17), guide = "none") +
    ggplot2::scale_x_continuous(limits = c(0, max(d$bindGap) * 1.32),
                                labels = function(x) paste0("$", round(x))) +
    ggplot2::labs(
      title = "The political constraint is deeply uneven across regions",
      subtitle = sprintf(paste("Shortfall of the politically feasible %d carbon price",
                               "against cost-optimal, at θ = %.2f."), year, th),
      x = sprintf("%d shortfall below cost-optimal", year), y = NULL)
  attr(p, "pfmGrid") <- "x"
  # Region-level quantities here are weighted aggregates; stamp says so (PITFALLS.md 20).
  pfmStamp(p, group, note = pfmWeightNote(cs, ok = paste0(
    "PFM-side bound, NOT a coupled result - the two are different objects")))
}
