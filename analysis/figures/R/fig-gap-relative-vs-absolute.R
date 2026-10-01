# The gap has to be relative, not absolute.
#
# Reproduces ../_archive/_wip/2026-10-01/docs/figures/si-fig1-gap.svg on the current Run-Group.
#
# This is PITFALLS 7 in picture form, and it is the reason gapMeasure = "relative" is the
# default. Ranking on the ABSOLUTE gap S* - S ranks regions by how much they COULD do —
# ceiling size — rather than by how far they fall short. The two rankings are materially
# different, and picking the wrong one silently changes which regions the coupling
# constrains hardest.
#
# The figure shows both rankings side by side and connects each country, so the reordering
# is the visual.

figGapRelativeVsAbsolute <- function(group = "v5", sector = "Bulk", top = 18) {
  fr <- pfmArtifact(group, "frontier.rds")
  sc <- as.data.frame(fr$bySector[[sector]]$scores)
  sc <- sc[sc$year == max(sc$year) & is.finite(sc$efficiencyRatio), ]

  d <- data.frame(region = sc$region,
                  absolute = sc$frontierIndex - sc$observedIndex,
                  relative = 1 - sc$efficiencyRatio,
                  ceiling  = sc$frontierIndex, stringsAsFactors = FALSE)
  d$rAbs <- rank(-d$absolute, ties.method = "first")
  d$rRel <- rank(-d$relative, ties.method = "first")
  d$shift <- d$rAbs - d$rRel
  keep <- d[d$rAbs <= top | d$rRel <= top, ]

  long <- rbind(
    data.frame(region = keep$region, measure = "absolute\nS* - S", r = keep$rAbs,
               shift = keep$shift, stringsAsFactors = FALSE),
    data.frame(region = keep$region, measure = "relative\n1 - S/S*", r = keep$rRel,
               shift = keep$shift, stringsAsFactors = FALSE))
  long$measure <- factor(long$measure, levels = c("absolute\nS* - S", "relative\n1 - S/S*"))
  long$moved <- abs(long$shift) >= 5

  rho <- stats::cor(d$absolute, d$relative, method = "spearman")

  p <- ggplot2::ggplot(long, ggplot2::aes(x = measure, y = -r, group = region)) +
    ggplot2::geom_line(ggplot2::aes(colour = moved, linewidth = moved), alpha = 0.75) +
    ggplot2::geom_point(ggplot2::aes(colour = moved), size = 1.5) +
    ggplot2::geom_text(data = long[long$measure == levels(long$measure)[1], ],
                       ggplot2::aes(label = region), hjust = 1.25, size = 2.2,
                       colour = "grey25") +
    ggplot2::geom_text(data = long[long$measure == levels(long$measure)[2], ],
                       ggplot2::aes(label = region), hjust = -0.25, size = 2.2,
                       colour = "grey25") +
    ggplot2::scale_colour_manual(values = c(`FALSE` = "grey72", `TRUE` = pfmRail()),
                                 labels = c(`FALSE` = "moves < 5 places",
                                            `TRUE` = "moves 5+ places"),
                                 breaks = c(TRUE, FALSE)) +
    ggplot2::scale_linewidth_manual(values = c(`FALSE` = 0.35, `TRUE` = 0.7),
                                    guide = "none") +
    ggplot2::scale_x_discrete(expand = ggplot2::expansion(add = 0.55)) +
    ggplot2::labs(
      title = "Which countries look most constrained depends on which gap you use",
      subtitle = sprintf(paste("%s sector. Absolute gap ranks by CEILING SIZE — how much a",
                               "country could do —\nnot by how far it falls short. Spearman",
                               "between the two measures: %.2f."), sector, rho),
      x = NULL, y = NULL)
  attr(p, "pfmGrid") <- "none"
  attr(p, "pfmTheme") <- ggplot2::theme(
    axis.text.y = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank())
  pfmStamp(p, group, note = "the coupling uses the RELATIVE gap (gapMeasure = 'relative')")
}
