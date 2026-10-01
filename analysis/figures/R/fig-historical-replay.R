# The historical-replay gate — it passes, and it proves less than it looks like it proves.
#
# The gate runs the coupled system over history from a 2000 seed and asks whether it tracks
# observed stringency at least as well as the uncoupled error-correction model. It does. But
# the honest reading is in the second bar, not the first:
#
#   * against PERSISTENCE the coupled system is far better (skill +0.71 / +0.73) - which is
#     unsurprising, because persistence is a very weak baseline over 22 years;
#   * against the ECM - the model it is actually meant to improve on - the gain is +0.003 in
#     Bulk and +0.038 in Diffuse. In Bulk that is indistinguishable from nothing.
#
# And the reason it is nearly nothing is the third number: the ceiling BINDS in only 1.6% of
# Bulk rows and 4.0% of Diffuse rows over the historical window. A constraint that almost never
# binds cannot change much, so this gate rules out a BROKEN coupling; it does not validate the
# ceiling. Out of sample the binding share is an order of magnitude larger (84.5% of
# region-years), and nothing here speaks to that regime. MODEL.md 8.4.
#
# The figure therefore has to show the bind share as prominently as the RMSE, or it will be
# read as a validation result. That is why it is printed on the panel rather than left to the
# caption.

figHistoricalReplay <- function(group = "v5") {
  hr <- pfmArtifact(group, "historical-replay.rds")

  d <- do.call(rbind, lapply(names(hr$bySector), function(sec) {
    m <- unlist(hr$bySector[[sec]]$metrics)
    data.frame(sector = sec,
               series = c("coupled (with ceiling)", "uncoupled ECM", "persistence"),
               rmse = c(m[["rmseCoupled"]], m[["rmseEcm"]], m[["rmsePersistence"]]),
               bind = m[["ceilingBindShare"]],
               skillEcm = m[["skillVsEcm"]],
               n = m[["n"]], stringsAsFactors = FALSE)
  }))
  d$series <- factor(d$series,
                     levels = c("persistence", "uncoupled ECM", "coupled (with ceiling)"))
  d$emph <- d$series == "coupled (with ceiling)"

  ann <- do.call(rbind, lapply(split(d, d$sector), function(x) {
    data.frame(sector = x$sector[1], bind = x$bind[1], skillEcm = x$skillEcm[1],
               y = 3.4, x = max(x$rmse), stringsAsFactors = FALSE)
  }))
  ann$lab <- sprintf("ceiling binds in %.1f%% of rows\nskill vs ECM %+.3f",
                     100 * ann$bind, ann$skillEcm)

  p <- ggplot2::ggplot(d, ggplot2::aes(y = series, x = rmse, fill = emph)) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.3f", rmse)), hjust = -0.18,
                       size = 2.4, colour = "grey25") +
    ggplot2::geom_text(data = ann, inherit.aes = FALSE,
                       ggplot2::aes(x = x, y = y, label = lab), hjust = 1, vjust = 1,
                       size = 2.3, colour = pfmRail(), lineheight = 0.95) +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_fill_manual(values = c(`FALSE` = pfmMuted(), `TRUE` = pfmAccent()),
                               guide = "none") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.18))) +
    ggplot2::labs(
      title = "The replay gate passes — because the ceiling almost never binds in history",
      subtitle = sprintf(paste0(
        "Root-mean-square error against observed stringency, replayed from a %d seed over ",
        "%d country-years.\nAgainst persistence the coupled system wins easily; against the ",
        "uncoupled ECM — the model it must actually\nimprove on — it gains 0.003 in Bulk. ",
        "The constraint is rarely active, so there is little for it to change."),
        hr$seedYear, d$n[1]),
      x = "RMSE against observed stringency (lower is better)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group,
           note = "rules out a broken coupling; does NOT validate the ceiling out of sample")
}
