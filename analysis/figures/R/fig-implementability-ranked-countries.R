# Every in-coverage country, ranked, both sectors on one scale.
#
# Was Fig 4b until 2026-09-18. It is NOT a paper figure any more: claim C11 forbids naming a
# country from a point ranking on `v5`, and that is exactly what a ranked country plot invites a
# reader to do. Fig 4b is now the region RANK INTERVALS (fig-implementability-ranked.R); this
# builder survives for the report and slides, where the question is "how far is each country from
# its own ceiling", not "which country ranks where".
#
# The companion to the choropleth: a map shows WHERE, this shows HOW FAR APART. Putting both
# sectors on one axis is the point - it makes visible that a country can sit near its ceiling
# in electricity and far below it in buildings, which is the split the whole coupling turns on.
#
# ⚠️ ORDERING IS BY DIFFUSE, DELIBERATELY. Bulk slack ranks do not survive the robustness
# battery (rank correlation 0.154 on the panel rung against 0.854 / 0.579 for Diffuse,
# MODEL.md 3.4), so a country ordering driven by Bulk would be an unquotable claim drawn as a
# figure. Diffuse orders the rows; Bulk points are plotted against that ordering for
# comparison and must never be read as a Bulk ranking. TODO item 1.
#
# The `region` column holds ISO3 COUNTRY codes, not REMIND regions - a madrat convention.
# This figure is therefore 48 countries, not 21 regions.
#
# 🔴 FIXED 2026-08-19. This built on projection.rds$implementability while its own subtitle
# claimed "Efficiency ratio E = S/S*". That column is exactly index/indexMax - the S/10
# multiplier MODEL.md 7 prohibits - so the figure was plotting one quantity and labelling it
# another. fig-efficiency-distribution.R and fig-implementability-map.R had already caught
# this; this builder was missed. It now reads E from frontier.rds$scores, the same canonical
# source Fig 1c uses. MODEL.md 3.4.2b, PITFALLS 22.
#
# CONSEQUENCE: the figure is now at the last ESTIMATED year (2022), not a projected year.
# Projected E is not in any Run-Group artifact - it is built at runtime by
# projectFeasiblePath() - so a projected version needs that path exported first. The ranking
# question this figure answers does not need the projection.

figImplementabilityRankedCountries <- function(group = "v5", year = NULL) {
  fr <- pfmArtifact(group, "frontier.rds")
  d <- do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) {
    sc <- as.data.frame(fr$bySector[[sec]]$scores)
    sc <- sc[is.finite(sc$efficiencyRatio), ]
    yr <- if (is.null(year)) max(sc$year) else year
    sc <- sc[sc$year == yr, ]
    data.frame(region = sc$region, sector = sec,
               implementability = sc$efficiencyRatio,
               # the per-row conditional slack band (ADR 0040), mapped onto E
               implementabilityLo = pmin(sc$observedIndex / pmax(sc$frontierIndex, 1e-9), 1),
               implementabilityHi = pmin(sc$observedIndex / pmax(sc$expectedIndexP10, 1e-9), 1),
               year = sc$year, stringsAsFactors = FALSE)
  }))
  if (!nrow(d)) stop("figImplementabilityRankedCountries: no in-coverage rows", call. = FALSE)
  year <- max(d$year)

  ord <- d[d$sector == "Diffuse", c("region", "implementability")]
  ord <- ord[order(ord$implementability), ]
  d$region <- factor(d$region, levels = ord$region)
  d <- d[!is.na(d$region), ]

  # renderSpec fixes the canvas height per medium, so 48 rows in one column collide into an
  # unreadable stack. Two columns halve the rows and double the label space; the split is at
  # the median of the Diffuse ordering, so each column is a contiguous block of the ranking.
  half <- ceiling(nlevels(d$region) / 2)
  rank <- match(as.character(d$region), levels(d$region))
  # Top of the ranking on the LEFT, so the panel reads left-to-right, top-to-bottom like
  # a single ranked list rather than doubling back.
  d$col <- factor(ifelse(rank > half, "using more of its space", "using less of its space"),
                  levels = c("using more of its space", "using less of its space"))

  medians <- stats::aggregate(implementability ~ sector, d, stats::median)

  p2 <- ggplot2::ggplot(d, ggplot2::aes(y = region, colour = sector)) +
    ggplot2::geom_vline(data = medians,
                        ggplot2::aes(xintercept = implementability, colour = sector),
                        linetype = "22", linewidth = 0.4, alpha = 0.7) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = implementabilityLo, xmax = implementabilityHi),
                            linewidth = 0.4, alpha = 0.55) +
    ggplot2::geom_point(ggplot2::aes(x = implementability), size = 1.4) +
    ggplot2::facet_wrap(~ col, scales = "free_y", nrow = 1) +
    ggplot2::scale_colour_manual(values = pfmSectorColours()) +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                                expand = ggplot2::expansion(mult = c(0.04, 0.04))) +
    ggplot2::labs(
      title = "How much of its own political space each country is using",
      subtitle = sprintf(paste0(
        "Efficiency ratio E = S/S* at %d (last estimated year), %d in-coverage\n",
        "countries. Dashed lines are sector medians. Rows are ordered by DIFFUSE —\n",
        "the Bulk points are for within-country comparison, NOT a Bulk ranking."),
        year, length(unique(d$region))),
      x = sprintf("share of own estimated ceiling used, %d", year), y = NULL)
  attr(p2, "pfmGrid") <- "x"
  attr(p2, "pfmTheme") <- ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = ggplot2::rel(0.72)),
    panel.spacing.x = grid::unit(1.0, "lines"))
  pfmStamp(p2, group, note = "ordered by Diffuse; do NOT read a Bulk country ranking off this")
}
