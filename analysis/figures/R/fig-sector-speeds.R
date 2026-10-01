# Sector adjustment speeds, with forecast skill annotated.
#
# The design constraint drives everything here: speed and FORECASTABILITY are different
# things, and only electricity beats persistence. A plain speed ranking would actively
# mislead — industry and transport look fastest and are the least forecastable. So skill is
# encoded twice, in colour AND in text, and the negative-skill bars are visually demoted.

figSectorSpeeds <- function(group = "v5") {
  ss <- pfmArtifact(group, "sector-speeds.rds")
  d <- do.call(rbind, lapply(names(ss$bySector), function(s) {
    m <- ss$bySector[[s]]$metrics
    data.frame(sector = s, lambda = m$adjustmentSpeed, halfLife = m$halfLife,
               skill = m$skillVsPersistence, stringsAsFactors = FALSE)
  }))
  d$forecastable <- d$skill > 0
  d$sector <- factor(d$sector, levels = d$sector[order(d$lambda)])
  d$lab <- sprintf("λ %.3f · t½ %.1f y · skill %+.3f", d$lambda, d$halfLife, d$skill)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = lambda, y = sector)) +
    ggplot2::geom_segment(ggplot2::aes(xend = 0, yend = sector, colour = forecastable),
                          linewidth = 1.6, alpha = 0.85) +
    ggplot2::geom_point(ggplot2::aes(colour = forecastable), size = 3) +
    ggplot2::geom_text(ggplot2::aes(label = lab), hjust = -0.08, size = 2.5,
                       colour = "grey25") +
    ggplot2::scale_colour_manual(
      values = c(`TRUE` = pfmAccent(), `FALSE` = "grey70"),
      labels = c(`TRUE` = "beats persistence out of sample",
                 `FALSE` = "does NOT beat persistence — a bound, not a forecast"),
      breaks = c(TRUE, FALSE)) +
    ggplot2::scale_x_continuous(limits = c(0, max(d$lambda) * 1.85)) +
    ggplot2::labs(
      title = "Only electricity is validated as a forecast",
      subtitle = paste("Annual gap-closure rate by sector. The other three rates are",
                       "descriptive bounds —\npolicy has never moved faster than this — not",
                       "predictions that it will."),
      x = "adjustment speed  λ  (per year, logit scale)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group)
}
