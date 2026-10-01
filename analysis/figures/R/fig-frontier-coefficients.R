# Fig 2a — what sets the ceiling.
#
# The COMPLETE view: every term, fixed effects included, on the one footing where their
# magnitudes are comparable — beta * SD(x), the contribution to the linear predictor in
# logits. The focused variant drops the fixed effects to give the political terms more room;
# neither is a substitute for the other, and both use the same scaling.
#
# WHY NOT RAW COEFFICIENTS. Until 2026-08-18 this figure plotted raw beta on an axis labelled
# "per SD". That was wrong twice over. Drivers and interaction factors ARE standardized to
# unit SD (MODEL.md 2.3), but the logistic time trend is a raw logistic in [0, 1] whose sample
# range is only ~0.26 — so its beta is not a per-SD quantity and does not belong on that axis.
# The visible consequence was that the trend at 10.3 compressed every political term into an
# unreadable sliver at zero, and a reader comparing 10.3 against Government Effectiveness's
# 0.26 would conclude the trend is ~39x the largest institutional channel. On a common footing
# it is ~3x in Bulk and ~1x in Diffuse. Do not revert.
#
# REFERENCE VALUES, for anyone reading this file rather than the plot. Deliberately NOT drawn
# on the figure - the plot carries positions, the documents carry numbers (MODEL.md 8.5,
# claims C25). Run-Group v1:
#
#            raw beta   SD(x)    contribution   GovEff contribution   ratio
#   Bulk      10.279    0.0796      0.818              0.264          3.10x
#   Diffuse    5.124    0.0796      0.408              0.389          1.05x
#
#   trend share of linear-predictor variance: 0.658 Bulk / 0.405 Diffuse (MODEL.md 2.4)
#   shift across the estimation window:       2.63 logits Bulk / 1.31 Diffuse
#
# Two design obligations beyond the usual:
#   1. interactions must be visually separable from main effects, because on the Bulk side the
#      whole story is in the interactions and neither actor-power MAIN effect is significant;
#   2. the intercept is dropped — not interpretable here and it dominates the scale.
#
# Term naming, the interaction test and the SD rescaling live in terms.R, shared with the
# focused variant.

figFrontierCoefficients <- function(group = "v5") {
  d <- pfmFrontierCoefsScaled(group)
  yrs <- attr(d, "trendYears")

  ord <- stats::aggregate(estSD ~ term, d, function(x) mean(abs(x)))
  d$term <- factor(d$term, levels = ord$term[order(ord$estSD)])

  p <- ggplot2::ggplot(d, ggplot2::aes(x = estSD, y = term)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = loSD, xmax = hiSD, colour = sector),
                            linewidth = 0.5, alpha = 0.8) +
    ggplot2::geom_point(ggplot2::aes(colour = sector, alpha = sig, shape = kind),
                        size = 2) +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_colour_manual(values = pfmSectorColours(), guide = "none") +
    ggplot2::scale_alpha_manual(values = c(`TRUE` = 1, `FALSE` = 0.3),
                                labels = c(`TRUE` = "p < 0.05", `FALSE` = "not significant"),
                                breaks = c(TRUE, FALSE)) +
    ggplot2::scale_shape_manual(values = c(`main effect` = 16, interaction = 17),
                                breaks = c("main effect", "interaction")) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.08, 0.08))) +
    ggplot2::labs(
      title = "State capability sets the ceiling; the politics is in the interactions",
      subtitle = sprintf(paste0(
        "Contribution to the ceiling in logits — β × SD(x), 95%% intervals.\n",
        "Triangles are interactions; fixed effects included.\n",
        "The time trend is a raw logistic in [0,1] over %d–%d, not a standardized\n",
        "driver, so it is scaled by its own SD to make the comparison meaningful."),
        yrs[1], yrs[2]),
      x = "contribution to the linear predictor (logits, per SD of the term)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group, note = "beta x SD(x), NOT raw coefficients - see MODEL.md 8.5")
}
