# The net effect of each actor-power term and each institution on the ceiling, at the countries' own values: the main
# effect plus its interactions (analysis/checks/netEffects.R -> output/pfm/<group>/net-effects.rds). Nothing is fitted here.

.netWhere <- function() c(`estimation sample, 2023` = "2023, estimation sample", `scenario, 2050` = "2050, scenario",
                          `scenario, 2100` = "2100, scenario")
.netCol <- function() stats::setNames(c("grey35", "#7fb3d5", pfmAccent()), .netWhere())

figNetEffects <- function(group = "v8") {
  x <- pfmArtifact(group, "net-effects.rds")
  d <- do.call(rbind, lapply(x$bySector, function(s) s$table))
  d <- d[d$where %in% names(.netWhere()), ]
  d$where <- factor(.netWhere()[d$where], levels = rev(.netWhere()))
  lev <- c("fossil dependence", "fossil interests per person", "clean-energy build-out", "government effectiveness",
           "rule of law", "vertical accountability", "horizontal accountability", "overall accountability", "institutions together")
  d$label <- factor(d$label, levels = rev(intersect(lev, unique(d$label))))
  d$sector <- factor(pfmSectorLabels()[d$sector], levels = pfmSectorLabels())
  m <- unique(d[, c("sector", "label", "main")])
  s <- d[d$where == .netWhere()[["scenario, 2100"]], ]
  s$txt <- sprintf("%.0f%% / %.0f%%", 100 * d$shareSameSign[d$where == .netWhere()[[1]]][match(paste(s$sector, s$label),
                   paste(d$sector, d$label)[d$where == .netWhere()[[1]]])], 100 * s$shareSameSign)
  xr <- tapply(c(d$p10, d$p90), rep(d$sector, 2), function(v) max(v) + 0.06 * diff(range(v)))
  s$xt <- xr[as.character(s$sector)]
  p <- ggplot2::ggplot(d, ggplot2::aes(y = label)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60", linewidth = 0.3) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = p10, xmax = p90, colour = where), linewidth = 0.9,
                            position = ggplot2::position_dodge(width = 0.6)) +
    ggplot2::geom_point(ggplot2::aes(x = median, colour = where), size = 1.9, position = ggplot2::position_dodge(width = 0.6)) +
    ggplot2::geom_point(data = m, ggplot2::aes(x = main), shape = 124, size = 5, colour = "black") +
    ggplot2::geom_text(data = s, ggplot2::aes(x = xt, label = txt), hjust = 0, size = 2.6, colour = "grey25") +
    ggplot2::facet_wrap(~sector, scales = "free_x") +
    ggplot2::scale_colour_manual(values = .netCol(), breaks = .netWhere(), name = NULL) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.04, 0.30))) +
    ggplot2::labs(title = "The net effect of each term, at each country's own values",
                  subtitle = paste0("Coefficient plus its interactions, logit of the ceiling per SD of the term.",
                                    "\nBar: 10th-90th percentile across countries; dot: median; black tick: the coefficient (the effect at average values).",
                                    "\nRight: share of countries whose net effect keeps the coefficient's sign, 2023 / 2100."),
                  x = "net effect on the ceiling (logit per SD)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group, note = paste0("net-effects.rds; scenario panel ", basename(x$scenarioPanel %||% "none")))
}
