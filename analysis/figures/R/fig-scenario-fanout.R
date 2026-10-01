# Scenario fan-out — does the projected ceiling actually respond to the pathway?
#
# From the reports' scenario-projection exhibit. This is the figure that answers "is the
# feedback channel alive at all", and it is the reason the composite actor-power form was
# rejected: under the composite the two pathways winsorized to the same boundary and the
# fan-out collapsed to a single line (MODEL.md 2.3, "scenario-blind").
#
# Rails printed on the figure, not just spoken:
#   - beyond the guard year the scenario difference is not interpretable, so the late horizon
#     is greyed;
#   - the divergence is conditional scenario accounting, not an identified causal effect.
#
# THE GUARD YEAR IS DERIVED FROM THE DATA, not chosen. It is the first projection year in which
# more than half the in-coverage countries have at least one driver outside the observed joint
# support and are therefore being winsorized by the guard (MODEL.md 7). Measured on v1 that is
# 2060, which is where the previous hardcoded value happened to sit - but it is now computed,
# so it moves if the projection does.
#
# The shading is CONSERVATIVE, and the underlying numbers are worse than it implies:
#
#   year   share out-of-SUPPORT (winsorized)   share out-of-SAMPLE
#   2050              31%                             94-98%
#   2055              46%                            100%
#   2060              54%                            100%
#   2100              85%                            100%
#
# By 2055 EVERY in-coverage country is being extrapolated beyond the estimation range. Anyone
# proposing to remove this band should read that column first: the honest objection is that
# the band starts too late, not that it should not be there.

figScenarioFanout <- function(group = "v5", guardShare = 0.5) {
  dir <- file.path(figuresResultsRoot(), group, "projections")
  fs <- list.files(dir, pattern = "[.]rds$", full.names = TRUE)
  if (!length(fs)) stop("no scenario projections in ", dir, call. = FALSE)

  raw <- lapply(fs, function(f) {
    x <- as.data.frame(readRDS(f))
    x[!x$outOfCoverage %in% TRUE, ]
  })

  d <- do.call(rbind, lapply(raw, function(x) {
    nm <- if ("scenarioName" %in% names(x)) x$scenarioName else "scenario"
    data.frame(scenario = nm, sector = x$sector, year = x$year, index = x$index,
               stringsAsFactors = FALSE)
  }))

  # Guard year, computed: the first year where more than `guardShare` of in-coverage rows are
  # being winsorized because a driver has left the observed joint support.
  sup <- do.call(rbind, lapply(raw, function(x)
    data.frame(year = x$year, oos = x$driverOutOfSupport > 0)))
  byYr <- stats::aggregate(oos ~ year, sup, mean)
  byYr <- byYr[order(byYr$year), ]
  hit <- byYr$year[byYr$oos > guardShare]
  guard <- if (length(hit)) min(hit) else Inf
  guardPct <- if (is.finite(guard)) 100 * byYr$oos[byYr$year == guard][1] else NA_real_

  q <- do.call(rbind, lapply(split(d, list(d$scenario, d$sector, d$year), drop = TRUE),
                             function(x) data.frame(
    scenario = x$scenario[1], sector = x$sector[1], year = x$year[1],
    med = stats::median(x$index, na.rm = TRUE),
    lo  = stats::quantile(x$index, 0.25, na.rm = TRUE),
    hi  = stats::quantile(x$index, 0.75, na.rm = TRUE), stringsAsFactors = FALSE)))
  q <- q[q$year <= 2100, ]

  p <- ggplot2::ggplot(q, ggplot2::aes(x = year, colour = scenario, fill = scenario)) +
    ggplot2::annotate("rect", xmin = guard, xmax = Inf, ymin = -Inf, ymax = Inf,
                      fill = "grey85", alpha = 0.30) +
    ggplot2::annotate("segment", x = guard, xend = guard, y = -Inf, yend = Inf,
                      colour = "grey55", linetype = "22", linewidth = 0.4) +
    ggplot2::annotate("text", x = guard + 2, y = 0.4, hjust = 0, size = 2.1,
                      colour = "grey35", lineheight = 0.95,
                      label = sprintf("from %d, >%.0f%% of countries\nhave a driver outside the\nobserved range", guard, guardPct)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lo, ymax = hi), alpha = 0.16,
                         colour = NA) +
    ggplot2::geom_line(ggplot2::aes(y = med), linewidth = 0.7) +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_colour_manual(values = c(pfmAccent(), pfmSectorColours()[["Diffuse"]],
                                            "grey40")) +
    ggplot2::scale_fill_manual(values = c(pfmAccent(), pfmSectorColours()[["Diffuse"]],
                                          "grey40")) +
    ggplot2::guides(colour = ggplot2::guide_legend(nrow = 2)) +
    ggplot2::labs(
      title = "The projected ceiling responds to the pathway",
      subtitle = paste("Median projected stringency across in-coverage countries; ribbon is",
                       "the interquartile range.\nSeparation between the lines is the",
                       "feedback channel being alive at all."),
      x = NULL, y = "projected stringency index (0-10)")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "conditional scenario accounting - not an identified causal effect")
}
