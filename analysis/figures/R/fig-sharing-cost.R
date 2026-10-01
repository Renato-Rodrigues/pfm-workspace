# What it costs to make both sectors share one specification.
#
# The model deploys a SINGLE specification across Bulk and Diffuse, because a shared functional
# form is what makes the two sectors comparable and the maximin selection rule meaningful. That
# is a design choice, and it has a measurable price: each sector could have done better on its
# own.
#
# On v1 the price is wildly asymmetric:
#   Bulk    best 0.102 vs deployed 0.097  ->  4.9% of achievable theory content given up
#   Diffuse best 0.189 vs deployed 0.142  -> 24.9% given up
#
# So the shared specification is close to Bulk's own optimum and a long way from Diffuse's.
# The deployed spec is, in effect, a Bulk specification that Diffuse is made to wear - which
# matters because Diffuse is the sector that usually binds in the coupling (SCENARIOS.md 1.1)
# and therefore the one carrying the headline result.
#
# This is the third leg of the selection-honesty set, and it is the one nobody had looked at:
#   selection-stability   would a RESAMPLE choose this spec?          (no - 4.5%)
#   selection-landscape   did it dominate on THIS sample?             (no - 159 fit better)
#   sharing-cost          what does forcing one spec on both cost?    (Diffuse: a quarter)

figSharingCost <- function(group = "v5") {
  sv <- pfmArtifact(group, "selection-variants.rds")
  d <- as.data.frame(sv$perSector, stringsAsFactors = FALSE)
  d$sector <- factor(d$sector, levels = rev(d$sector))
  topRow <- d[d$sector == levels(d$sector)[nlevels(d$sector)], ]

  p <- ggplot2::ggplot(d, ggplot2::aes(y = sector)) +
    ggplot2::geom_segment(ggplot2::aes(x = deployedDeltaR2, xend = bestDeltaR2, yend = sector),
                          colour = "grey72", linewidth = 1.5) +
    ggplot2::geom_point(ggplot2::aes(x = deployedDeltaR2, colour = sector), size = 2.8) +
    ggplot2::geom_point(ggplot2::aes(x = bestDeltaR2), colour = pfmMuted(), size = 2.8,
                        shape = 21, fill = "white", stroke = 1.1) +
    ggplot2::geom_text(ggplot2::aes(x = (deployedDeltaR2 + bestDeltaR2) / 2,
                                    label = sprintf("−%.1f%%", 100 * sharingCostShare)),
                       vjust = -1.2, size = 3.0, fontface = "bold", colour = "grey15") +
    ggplot2::geom_text(ggplot2::aes(x = deployedDeltaR2, label = sprintf("%.3f", deployedDeltaR2)),
                       hjust = 1.3, size = 2.4, colour = "grey30") +
    ggplot2::geom_text(ggplot2::aes(x = bestDeltaR2, label = sprintf("%.3f", bestDeltaR2)),
                       hjust = -0.35, size = 2.4, colour = "grey30") +
    # anchored to the TOP row's own points - placing them at another row's x-values leaves
    # the labels floating over empty space and pointing at nothing
    ggplot2::annotate("text", x = topRow$deployedDeltaR2, y = nrow(d) + 0.45,
                      hjust = 0.5, vjust = 0, size = 2.4, colour = pfmAccent(),
                      label = "shared spec") +
    ggplot2::annotate("text", x = topRow$bestDeltaR2, y = nrow(d) + 0.45,
                      hjust = 0.5, vjust = 0, size = 2.4, colour = pfmMuted(),
                      label = "sector's own best") +
    ggplot2::scale_colour_manual(values = pfmSectorColours(), guide = "none") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.16, 0.16))) +
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = c(0.7, 1.5))) +
    ggplot2::labs(
      title = "The shared specification costs Diffuse a quarter of its explanatory content",
      subtitle = paste0(
        "Theory content ΔR² of the deployed shared specification against what each sector ",
        "could reach on its own.\nBulk gives up 4.9%; Diffuse gives up 24.9%. The shared ",
        "form sits close to Bulk's optimum and far from Diffuse's —\nand Diffuse is the ",
        "sector that usually binds in the coupling."),
      x = "ΔR²(theory)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group,
           note = "a design choice with a measurable price, not a defect - but it is asymmetric")
}
