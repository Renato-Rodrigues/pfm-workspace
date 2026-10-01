# The selection landscape — where the deployed specification actually sits.
#
# `selection-stability` (Fig 2c) answers "would a RESAMPLE have chosen this model?" and says
# no: the deployed spec is reselected in 4.5% of resamples and its channel set in 29.4%. This
# figure answers the prior question - "given THIS sample, how much better than the
# alternatives was it?" - and the answer is: it was not better on any single quantity a reader
# would naturally check.
#
# On v1, of 2232 candidate specifications, 242 pass the admissibility gate. Against those 242
# the deployed spec X-0370 is:
#     4 specs have a HIGHER minimum ΔR²(theory)      - the theory-content criterion
#    43 specs have a higher MEAN ΔR²(theory)
#   159 specs have a LOWER (better) sum BIC          - i.e. two thirds fit the data better
#     9 specs sit within 0.002 of it on minΔR²       - a statistical tie
#
# It nevertheless ranks 1, because the maximin rule is MULTI-CRITERIA: worse-sector tier first,
# then theory content, then parsimony and fragility tie-breaks. So the honest sentence is not
# "the best model" and not even "tied first on the criterion", but: **selected by a declared
# multi-criteria rule from a set of near-equivalent candidates, most of which fit better.**
#
# The figure must therefore NOT imply the rule is "maximise minΔR²" - the four points to the
# right of the deployed one would look like an error if it were. Their ranks (10, 26, 39, 44)
# come from losing on the later tie-breaks, and the caption says so.
#
# Axes: theory content against fit, which is exactly the trade-off the rule navigates. BIC is
# kept on its natural scale because lower-is-better is the universal convention for it;
# reversing the axis to make "up = better" reads as a trick.

figSelectionLandscape <- function(group = "v5", stage = "PolicyStringency", tieTol = 0.002) {
  s <- pfmArtifact(group, "sweep.rds")
  m <- s$maximin[[stage]]
  if (is.null(m)) stop("figSelectionLandscape: no maximin table for '", stage, "'", call. = FALSE)
  dep <- s$selected[[stage]]

  m$group <- ifelse(m$model == dep, "deployed",
                    ifelse(m$gatePass, "passes the gate", "fails the gate"))
  m$group <- factor(m$group, levels = c("fails the gate", "passes the gate", "deployed"))
  d <- m[m$model == dep, ]
  g <- m[m$gatePass & m$model != dep, ]

  nBetterBIC  <- sum(g$sumBIC < d$sumBIC - 1e-9)
  nHigherMin  <- sum(g$minDeltaR2 > d$minDeltaR2 + 1e-9)
  nTied       <- sum(abs(g$minDeltaR2 - d$minDeltaR2) <= tieTol)
  nPass       <- sum(m$gatePass)

  p <- ggplot2::ggplot(m, ggplot2::aes(x = minDeltaR2, y = sumBIC)) +
    # the near-tie band on the theory criterion
    ggplot2::annotate("rect", xmin = d$minDeltaR2 - tieTol, xmax = d$minDeltaR2 + tieTol,
                      ymin = -Inf, ymax = Inf, fill = pfmRail(), alpha = 0.07) +
    ggplot2::geom_point(ggplot2::aes(colour = group, size = group, alpha = group)) +
    ggplot2::geom_point(data = d, colour = pfmRail(), size = 3.2, shape = 21,
                        stroke = 1.1, fill = NA) +
    ggplot2::geom_text(data = d, ggplot2::aes(label = "deployed"), hjust = -0.35,
                       size = 2.6, colour = pfmRail(), fontface = "bold") +
    ggplot2::scale_colour_manual(values = c(`fails the gate` = "grey78",
                                            `passes the gate` = pfmAccent(),
                                            deployed = pfmRail())) +
    ggplot2::scale_size_manual(values = c(`fails the gate` = 0.5,
                                          `passes the gate` = 1.1, deployed = 2.2),
                               guide = "none") +
    ggplot2::scale_alpha_manual(values = c(`fails the gate` = 0.35,
                                           `passes the gate` = 0.75, deployed = 1),
                                guide = "none") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.03, 0.12))) +
    ggplot2::labs(
      title = "The deployed specification is one of many, and most of them fit better",
      # No markdown here - ggplot subtitles are plain text and asterisks render literally.
      subtitle = sprintf(paste0(
        "%s candidate specifications; %d pass the admissibility gate. Of those, %d fit the ",
        "data better (lower BIC),\n%d have higher theory content, and %d more sit within ",
        "%.3f of the deployed spec on the theory criterion — a tie.\nIt ranks first on a ",
        "declared multi-criteria maximin rule, not on either axis alone."),
        format(nrow(m), big.mark = ","), nPass, nBetterBIC, nHigherMin, nTied, tieTol),
      x = "minimum ΔR²(theory) across sectors  →  more theory content",
      y = "sum BIC across sectors  (lower = better fit)")
  attr(p, "pfmGrid") <- "both"
  pfmStamp(p, group,
           note = "selection is a declared rule over near-equivalents, not a discovery of the best model")
}
