# Fig 4b — how robust the ordering of regions is, drawn as RANK INTERVALS.
#
# Re-pointed 2026-09-18 (TODO item 37). This panel used to plot a country POINT ranking of the
# efficiency ratio. Claim C11 says no country may be named from a point ranking on `v5` — slack
# ranks collapse on the panel rung in both sectors — so a point ranking drawn as a figure asserts
# exactly what the claims ledger forbids. The country version still exists, as its own figure
# (`implementability-ranked-countries`, report and slides only, never the paper).
#
# What this draws instead: the delivered region-level phi (the min() of the two sectors, the
# quantity the coupling actually consumes) re-derived under FOUR fitted frontier variants —
# headline half-normal, truncated-normal, panel, and time-decay — and for each region the RANGE
# of ranks those four produce. A wide bar is a region whose position depends on which defensible
# error structure was assumed.
#
# 🔴 THE INTERVAL IS NOT A CONFIDENCE INTERVAL. It is the spread over four fitted models. Saying
# "95%" anywhere near it would invent a sampling statement nothing here estimated.
#
# Reading direction: rank 1 = the LEAST constrained region (highest phi). The most constrained
# sit at the bottom, which is where the coupling bites hardest.
#
# Source: output/pfm/<group>/frontier-rung-phi.rds$minRule$<resolution>$<weights>$rankInterval
# (analysis/checks/propagateFrontierRungsToPhi.R). `separable` marks regions whose whole interval sits
# clear of the middle of the field — the rungs agree on which half it belongs to.

figImplementabilityRanked <- function(group = "v5", resolution = "EU21", weights = "gdp") {
  rp <- pfmArtifact(group, "frontier-rung-phi.rds")
  g <- rp$minRule[[resolution]][[weights]]
  if (is.null(g)) {
    stop("figImplementabilityRanked: no minRule$", resolution, "$", weights,
         " in frontier-rung-phi.rds", call. = FALSE)
  }
  d <- g$rankInterval
  nRungs <- attr(d, "nRungs"); rungs <- attr(d, "rungs")
  maxWidth <- attr(d, "maxWidth"); shareSep <- attr(d, "shareSeparable")
  n <- nrow(d)

  d <- d[order(-d$rankMed), ]
  d$unit <- factor(d$unit, levels = d$unit)
  # The claim is about which orderings survive, so the two groups are direct-labelled by
  # colour AND by the legend text; nothing here depends on hue alone.
  d$agree <- factor(ifelse(d$separable, "rungs agree on the half", "position depends on the rung"),
                    levels = c("rungs agree on the half", "position depends on the rung"))

  mid <- (n + 1) / 2

  p <- ggplot2::ggplot(d, ggplot2::aes(y = unit)) +
    ggplot2::geom_vline(xintercept = mid, linetype = "22", linewidth = 0.4, colour = "grey70") +
    ggplot2::geom_linerange(ggplot2::aes(xmin = rankLo, xmax = rankHi, colour = agree),
                            linewidth = 1.6, alpha = 0.55) +
    ggplot2::geom_point(ggplot2::aes(x = rankMed, colour = agree), size = 1.8) +
    ggplot2::scale_colour_manual(values = stats::setNames(
      c(pfmAccent(), pfmMuted()), levels(d$agree)), drop = FALSE) +
    ggplot2::scale_x_continuous(
      breaks = function(l) unique(round(scales::breaks_pretty(6)(l))),
      expand = ggplot2::expansion(mult = c(0.03, 0.03))) +
    ggplot2::labs(
      # computed, never asserted — this panel's numbers change with the Run-Group
      title = sprintf("Which regions the ceiling constrains most - and how much of that ordering survives"),
      subtitle = sprintf(paste0(
        "Rank of delivered feasibility share across %d fitted frontier variants (%s),\n",
        "%s, %d regions. Widest interval %s ranks of %d; only %.0f%% of regions sit clear of\n",
        "the middle of the field. A RANGE OVER MODELS, not a confidence interval."),
        nRungs, paste(rungs, collapse = ", "), resolution, n,
        format(maxWidth), n, 100 * shareSep),
      x = sprintf("rank (1 = least constrained, %d = most constrained)", n), y = NULL)
  attr(p, "pfmGrid") <- "x"
  attr(p, "pfmTheme") <- ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = ggplot2::rel(0.8)),
    legend.position = "bottom", legend.title = ggplot2::element_blank())
  pfmStamp(p, group,
           note = "range over four fitted frontier variants; NOT a confidence interval (claim C11)")
}
