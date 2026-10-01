# Fig 3a — the cost-optimal anchor, the politically feasible bound, and the gap between them.
#
# The panel that makes the mechanism concrete in price space: for a given region, what does
# cost-optimality ask for, what can politics sustain, and how far apart are they over the
# century. Figs 3b and 3c summarise that gap across regions and across theta; this one shows
# where it comes from.
#
# Regions are chosen from the DATA, not by hand: four evenly spaced positions in the phi
# ordering, so the panel spans the feasibility distribution and cannot be accused of
# cherry-picking. The most and least constrained regions are always included as the endpoints.
#
# Colour: this is reference-vs-constrained, not a categorical identity pair. The anchor wears
# muted ink and a dashed line, the bound wears the accent. The gap between them is the claim,
# so it is the only filled area.

figAnchorBoundGap <- function(group = "v5", nRegions = 4L) {
  cs <- pfmArtifact(group, "coupling/coupling-summary.rds")
  b <- as.data.frame(cs$boundAnchor)
  b <- b[b$year <= 2100, ]

  phi <- unique(b[, c("region", "phi")])
  phi <- phi[order(phi$phi), ]
  pick <- phi$region[round(seq(1, nrow(phi), length.out = nRegions))]

  d <- b[b$region %in% pick, ]
  lab <- sprintf("%s   φ = %.2f", phi$region, phi$phi)
  names(lab) <- phi$region
  d$panel <- factor(lab[d$region], levels = lab[pick])

  gapPct <- 100 * (1 - d$priceBound / d$priceOptimal)
  d$gapPct <- gapPct

  p <- ggplot2::ggplot(d, ggplot2::aes(x = year)) +
    # the gap IS the finding, so it is the only filled area on the figure
    ggplot2::geom_ribbon(ggplot2::aes(ymin = priceBound, ymax = priceOptimal),
                         fill = pfmAccent(), alpha = 0.13) +
    ggplot2::geom_line(ggplot2::aes(y = priceOptimal), colour = pfmMuted(),
                       linewidth = 0.6, linetype = "22") +
    ggplot2::geom_line(ggplot2::aes(y = priceBound), colour = pfmAccent(),
                       linewidth = 0.8) +
    ggplot2::facet_wrap(~ panel, nrow = 1) +
    ggplot2::scale_y_continuous(labels = function(x) paste0("$", round(x))) +
    # breaks kept off the panel edges: at 2025/2100 adjacent facets collide into "21002025"
    ggplot2::scale_x_continuous(breaks = c(2040, 2080),
                                expand = ggplot2::expansion(mult = 0.10)) +
    ggplot2::labs(
      title = "What cost-optimality asks for, and what politics can sustain",
      subtitle = paste0(
        "Dashed: the cost-optimal anchor. Solid: the politically feasible bound. ",
        "Shaded: the gap.\nFour regions spanning the feasibility distribution, ",
        "least constrained on the right."),
      x = NULL, y = "carbon price, US$2005/tCO₂")
  attr(p, "pfmGrid") <- "y"

  # Direct labels in the FIRST panel, where the gap is widest and there is room; the last
  # panel is nearly closed, so labels there overlap each other and the panel edge.
  first <- d[d$panel == levels(d$panel)[1] & d$year == 2100, ]
  p <- p +
    ggplot2::geom_text(data = first, ggplot2::aes(y = priceOptimal, label = "anchor"),
                       hjust = 1.05, vjust = 1.7, size = 2.3, colour = pfmMuted()) +
    ggplot2::geom_text(data = first, ggplot2::aes(y = priceBound, label = "feasible"),
                       hjust = 1.05, vjust = -1.0, size = 2.3, colour = pfmAccent())
  attr(p, "pfmTheme") <- ggplot2::theme(panel.spacing.x = grid::unit(1.0, "lines"))

  # State the theta the artifact was written at, and flag it only when it is NOT the declared
  # anchor. Hardcoding "SUPERSEDED" was wrong the moment the artifact was re-run - it printed
  # "SUPERSEDED theta = 0.50, not the 0.50 anchor".
  anchorDeclared <- 0.50
  th <- cs$anchorTheta
  pfmStamp(p, group, note = pfmWeightNote(cs, ok = sprintf(
    "PFM-side bound, NOT a coupled result - theta = %.2f%s", th,
    if (abs(th - anchorDeclared) > 1e-9) {
      sprintf(" (NOT the declared %.2f anchor - levels are not quotable)", anchorDeclared)
    } else "")))
}
