# SI — the fitted ceiling against what each country actually did, 2001-2022.
#
# This is the frontier itself, one country at a time. Everything else in the paper is a summary
# of this panel: the efficiency ratio is the ratio of the two lines, the slack is the gap, and
# phi is a min-max normalisation of the gap across regions. A reader who does not believe the
# aggregate numbers should be able to come here and look at their own country.
#
# Form: small multiples, one panel per country, because the READER'S JOB is "find a country,
# then read the gap". A single panel with 48 series would be unreadable and an aggregate
# distribution would answer a different question. Fixed y-scale on purpose - the index is a
# common 0-10 scale and the LEVEL is the point, so free scales would make a country that never
# legislated anything look identical to one at the ceiling.
#
# Order: by mean efficiency ratio, descending. Alphabetical would be easier to look up in but
# would hide the gradient that is the actual finding - countries at the top use nearly all the
# space their institutions allow, countries at the bottom leave most of it unused.
#
# Colour: this is estimate-vs-data, not a categorical pair, so it follows the repo's
# reference-vs-actual idiom (fig-anchor-bound-gap): the ceiling wears muted ink, the observed
# path wears the accent, and the gap between them is the only filled area because the gap IS
# the estimated quantity.
#
# HONESTY: the observed path exceeds the fitted ceiling in a few country-years. That is not a
# defect - a stochastic frontier has a two-sided noise component, so points above the frontier
# are expected and their frequency is diagnostic. They are drawn, not clipped, and counted in
# the subtitle.

figFrontierVsObserved <- function(group = "v5", sector = "Diffuse", ncol = 8L) {
  fr <- pfmArtifact(group, "frontier.rds")
  if (is.null(fr$bySector[[sector]])) {
    stop("figFrontierVsObserved: no sector '", sector, "' in frontier.rds (have: ",
         paste(names(fr$bySector), collapse = ", "), ")")
  }
  d <- fr$bySector[[sector]]$scores
  need <- c("region", "year", "observedIndex", "frontierIndex")
  miss <- setdiff(need, names(d))
  if (length(miss)) {
    stop("figFrontierVsObserved: frontier.rds$scores is missing ", paste(miss, collapse = ", "),
         " - this artifact predates the columns the figure needs.")
  }

  eff <- stats::aggregate(list(eff = d$observedIndex / pmax(d$frontierIndex, 1e-9)),
                          by = list(region = d$region), FUN = mean, na.rm = TRUE)
  eff <- eff[order(-eff$eff), ]
  d$region <- factor(d$region, levels = eff$region)

  above <- sum(d$observedIndex > d$frontierIndex)
  medEff <- stats::median(eff$eff)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = year)) +
    # the gap is the estimated quantity, so it is the only fill on the figure
    ggplot2::geom_ribbon(ggplot2::aes(ymin = pmin(observedIndex, frontierIndex),
                                      ymax = frontierIndex),
                         fill = pfmAccent(), alpha = 0.12) +
    ggplot2::geom_line(ggplot2::aes(y = frontierIndex), colour = pfmMuted(),
                       linewidth = 0.45, linetype = "22") +
    ggplot2::geom_line(ggplot2::aes(y = observedIndex), colour = pfmAccent(),
                       linewidth = 0.55) +
    ggplot2::facet_wrap(~ region, ncol = ncol) +
    ggplot2::scale_x_continuous(breaks = c(2005, 2020),
                                expand = ggplot2::expansion(mult = 0.05)) +
    ggplot2::scale_y_continuous(limits = c(0, 10), breaks = c(0, 5, 10),
                                expand = ggplot2::expansion(mult = 0.02)) +
    ggplot2::labs(
      title = sprintf("What each country's institutions allowed, and what it did (%s)", sector),
      subtitle = sprintf(paste0(
        "Dashed: the fitted ceiling. Solid: observed policy stringency. Shaded: the unused ",
        "space.\nOrdered by mean use of that space, most first — the median country uses %.0f%% ",
        "of its own ceiling.\nObserved exceeds the ceiling in %d of %d country-years, which a ",
        "two-sided noise term permits."),
        100 * medEff, above, nrow(d)),
      x = NULL, y = "policy stringency index (0–10)")
  attr(p, "pfmGrid") <- "y"
  attr(p, "pfmTheme") <- ggplot2::theme(
    panel.spacing = grid::unit(0.35, "lines"),
    strip.text = ggplot2::element_text(size = 6.5, margin = ggplot2::margin(1, 0, 1, 0)),
    axis.text = ggplot2::element_text(size = 5.5))

  pfmStamp(p, group, note = paste0(
    "the frontier itself - every aggregate in the paper is a summary of this panel; ",
    "fitted 2001-2022, ", length(levels(d$region)), " in-coverage countries"))
}
