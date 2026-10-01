# Fig 2a-focused — frontier terms on a footing that is actually common.
#
# THE PROBLEM. The raw coefficients are not comparable. Every driver and interaction factor is
# standardized to unit SD (MODEL.md 2.3), but the logistic time trend is a RAW logistic in
# [0, 1] whose sample range is only ~0.26. So the trend's 10.279 and Government
# Effectiveness's 0.264 are quoted in different units, and putting both on one axis labelled
# "per SD" invites the reader to conclude the trend is ~39x the largest institutional channel.
#
# It is not. Rescaled to beta * SD(x) - each term's contribution to the linear predictor, in
# logits - the trend is 0.818 against GovEff's 0.264 in Bulk, about 3x; in Diffuse it is 0.408
# against 0.389, about 1x. That is the honest comparison, it is still the largest single term,
# and it FITS ON THE AXIS, so the axis break the previous version needed is gone.
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
# Companion to fig-frontier-coefficients, which uses the SAME scaling but keeps the fixed
# effects. Use that one for the complete term list; use this one when the political terms need
# the room. Neither shows raw coefficients - for those, read
# frontier.rds$bySector$<s>$coefTable directly, or MODEL.md 2.5 for the mean-regression table.

figFrontierCoefficientsFocused <- function(group = "v5", showFE = FALSE) {
  d <- pfmFrontierCoefsScaled(group)
  if (!showFE) d <- d[!d$fe, ]

  yrs <- attr(d, "trendYears")

  # order by mean absolute CONTRIBUTION, pooled across sectors - the whole point is that this
  # ordering differs from the raw-coefficient one
  ord <- stats::aggregate(estSD ~ term, d, function(x) mean(abs(x)))
  d$term <- factor(d$term, levels = ord$term[order(ord$estSD)])

  p <- ggplot2::ggplot(d, ggplot2::aes(y = term)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = loSD, xmax = hiSD, colour = sector),
                            linewidth = 0.5, alpha = 0.8) +
    ggplot2::geom_point(ggplot2::aes(x = estSD, colour = sector, alpha = sig, shape = kind),
                        size = 2) +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_colour_manual(values = pfmSectorColours(), guide = "none") +
    ggplot2::scale_alpha_manual(values = c(`TRUE` = 1, `FALSE` = 0.3),
                                labels = c(`TRUE` = "p < 0.05", `FALSE` = "not significant"),
                                breaks = c(TRUE, FALSE)) +
    ggplot2::scale_shape_manual(values = c(`main effect` = 16, interaction = 17),
                                breaks = c("main effect", "interaction")) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.06, 0.08))) +
    ggplot2::labs(
      title = "What each term contributes, on a footing that is actually common",
      subtitle = sprintf(paste0(
        "Contribution in logits — β × SD(x), 95%% intervals. Triangles are interactions.\n",
        "The time trend is a raw logistic in [0,1] over %d–%d, not a standardized\n",
        "driver, so it is scaled by its own SD to make the comparison meaningful."),
        yrs[1], yrs[2]),
      x = "contribution to the linear predictor (logits, per SD of the term)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group,
           note = "political terms only; fig-frontier-coefficients adds the fixed effects")
}
