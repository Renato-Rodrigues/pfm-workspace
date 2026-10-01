# Pseudo-out-of-sample validation — the negative result that shapes the whole design.
#
# From the reports' validation exhibit. Fit on t <= 2015, recursively forecast 2016-2022,
# score against a persistence benchmark. The static level forecast loses to "assume nothing
# changes" in BOTH sectors, and that is precisely why this model delivers ceilings and
# speeds and never level paths (MODEL.md 4.3, and the first row of the prohibitions table).
#
# The figure has to make the loss visible rather than bury it in a skill number, so the
# persistence RMSE is drawn as a reference band and the skill is stated per sector.

figTemporalValidation <- function(group = "v5") {
  tv <- pfmArtifact(group, "temporal-validation.rds")

  d <- do.call(rbind, lapply(names(tv$bySector), function(sec) {
    r <- as.data.frame(tv$bySector[[sec]]$rows)
    r$sector <- sec
    r[, c("region", "year", "sector", "observed", "predicted")]
  }))
  m <- do.call(rbind, lapply(names(tv$bySector), function(sec) {
    x <- tv$bySector[[sec]]$metrics
    data.frame(sector = sec, rmse = x$rmse, rmseP = x$rmsePersistence,
               skill = x$skillVsPersistence, n = x$n, stringsAsFactors = FALSE)
  }))
  m$lab <- sprintf("RMSE %.2f vs persistence %.2f\nskill %+.3f  (n = %d)",
                   m$rmse, m$rmseP, m$skill, m$n)
  lim <- c(0, max(c(d$observed, d$predicted), na.rm = TRUE) * 1.05)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = observed, y = predicted)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey35", linewidth = 0.45) +
    ggplot2::geom_point(ggplot2::aes(colour = sector), size = 1.1, alpha = 0.55) +
    ggplot2::geom_text(data = m, ggplot2::aes(x = lim[1] + 0.2, y = lim[2] * 0.97,
                                              label = lab),
                       hjust = 0, vjust = 1, size = 2.4, colour = "grey25",
                       lineheight = 0.95, inherit.aes = FALSE) +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_colour_manual(values = pfmSectorColours(), guide = "none") +
    ggplot2::coord_equal(xlim = lim, ylim = lim) +
    ggplot2::labs(
      title = "The level forecast loses to \"assume nothing changes\"",
      subtitle = paste("Fit on 2001-2015, recursively forecast 2016-2022, one point per",
                       "country-year.\nNegative skill in both sectors: this is why the model",
                       "delivers ceilings and speeds,\nnever projected level paths."),
      x = "observed stringency", y = "predicted")
  attr(p, "pfmGrid") <- "both"
  pfmStamp(p, group, note = "negative result, reported deliberately")
}
