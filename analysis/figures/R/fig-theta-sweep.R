# Fig 3c — what the political ceiling costs the pathway.
#
# The headline magnitude figure. Two things it must communicate that a naive plot does not:
#   1. the binding SHARE is flat across theta — theta sets how far below, not how often;
#   2. theta = 0 is NOT the cost-optimal path, because the speed limit binds even when every
#      feasibility share is 1. That surprises people and it belongs on the figure.

figThetaSweep <- function(group = "v5") {
  cs <- pfmArtifact(group, "coupling/coupling-summary.rds")
  ts <- as.data.frame(cs$thetaSweep)
  anchor <- cs$anchorTheta
  opt <- ts$optPrice2050[1]

  # TWO thetas, and the figure must not conflate them (MODEL.md 5.3):
  #   * anchorTheta - DECLARED, and what cm_pfmTheta gives every coupled run. This is the rail.
  #   * anchorDerivation$theta - derived by ANALOGY from this group's own aggregation. Until
  #     2026-08-18 the two coincided at 0.50 and this figure drew the derived one, calling it
  #     "the efficiency anchor". The weight fix moved the derived value to 0.396 while the
  #     declared value stayed at 0.50, so drawing the derived one would put the rail at a theta
  #     no run has ever used, with no swept point under it.
  ad <- cs$anchorDerivation
  derived <- if (!is.null(ad)) ad$theta[ad$sector == "Diffuse"][1] else NA_real_
  anchorAt <- anchor
  anchorLab <- sprintf("declared  θ = %.2f", anchor)

  p <- ggplot2::ggplot(ts, ggplot2::aes(x = theta)) +
    ggplot2::geom_hline(yintercept = opt, linetype = "22", colour = "grey35",
                        linewidth = 0.4) +
    ggplot2::annotate("text", x = max(ts$theta), y = opt, vjust = -0.7, hjust = 1,
                      label = sprintf("cost-optimal  $%.0f", opt),
                      size = 2.6, colour = "grey30") +
    # the anchor, drawn from the artifact
    ggplot2::geom_vline(xintercept = anchorAt, colour = pfmRail(), linewidth = 0.4,
                        linetype = "31") +
    ggplot2::annotate("label", x = anchorAt, y = opt * 0.75, label = anchorLab,
                      size = 2.5, colour = pfmRail(), fill = "white",
                      label.padding = grid::unit(0.6, "mm")) +
    ggplot2::geom_line(ggplot2::aes(y = medPrice2050), colour = pfmAccent(),
                       linewidth = 0.7) +
    ggplot2::geom_point(ggplot2::aes(y = medPrice2050), colour = pfmAccent(), size = 1.8) +
    ggplot2::geom_text(ggplot2::aes(y = medPrice2050,
                                    label = sprintf("%.0f%%", shortfall2050pct)),
                       vjust = -1.4, size = 2.4, colour = "grey30") +
    ggplot2::scale_x_continuous(breaks = ts$theta,
                                labels = function(x) sub("^0", "", sprintf("%.2f", x)),
                                expand = ggplot2::expansion(mult = 0.06)) +
    ggplot2::scale_y_continuous(limits = c(0, opt * 1.08),
                                labels = function(x) paste0("$", round(x))) +
    ggplot2::labs(
      # The title must not outrun the largest number on the plot. It read "MOST of the
      # cost-optimal price is politically unreachable" when the sweep topped out at 56%; after
      # the 2026-08-18 weight fix it tops out at 47%, and "most" became false at every swept
      # theta. Stated as a fraction instead, so the claim cannot drift away from the data again.
      title = "Between a third and a half of the cost-optimal carbon price is politically unreachable",
      subtitle = sprintf(paste0("Median 2050 feasible price across 21 REMIND regions. ",
                                "Labels are the shortfall against cost-optimal.\n",
                                "The bound binds in %.1f%% of region-years at EVERY θ — ",
                                "θ sets how far below, not how often."),
                         100 * ts$bindShare[1]),
      x = "coupling severity  θ", y = "median 2050 price")
  attr(p, "pfmGrid") <- "y"

  # The analogy-derived value, shown as a muted tick BESIDE the declared rail rather than as a
  # rail of its own - it is a scale-fixing device, not a second scenario. Drawn only when it
  # actually differs, so the figure stays quiet when the two agree.
  if (is.finite(derived) && abs(derived - anchor) > 0.005) {
    p <- p +
      ggplot2::geom_vline(xintercept = derived, colour = pfmMuted(), linewidth = 0.3,
                          linetype = "12") +
      ggplot2::annotate("text", x = derived, y = opt * 0.30, hjust = 1.08,
                        label = sprintf("derived by analogy  %.2f", derived),
                        size = 2.2, colour = pfmMuted())
  }

  # A rail that must be PRINTED, not spoken (docs/PRESENTATION.md 6.4).
  # Region-level quantities here are weighted aggregates; stamp says so (PITFALLS.md 20).
  pfmStamp(p, group, note = pfmWeightNote(cs, ok = paste0(
    "PFM-side bound, NOT a coupled result - the two are different objects")))
}
