# Why actor power must saturate (ADR 0040).
#
# Deck-only, and worth building first: it justifies a design choice visually in one glance.
# The argument is entirely in the two shaded ranges — the model is estimated on one and
# asked to operate on another, and they barely overlap. Linear in the share, the slopes get
# extrapolated far past the data that identifies them.
#
# The saturation scale Abar is the frozen training median, read from the fit rather than
# assumed, so the curve is the one the model actually uses.

figSaturatingMap <- function(group = "v5", sector = "Bulk") {
  fr <- pfmArtifact(group, "frontier.rds")
  sc <- as.data.frame(fr$bySector[[sector]]$scores)

  # Abar: the frozen training median of the raw share. Recover it from driverScaling when
  # the fit carries it, otherwise fall back to the documented Bulk training median.
  ds <- tryCatch(fr$bySector[[sector]]$driverScaling, error = function(e) NULL)
  abar <- tryCatch({
    s <- ds$sat
    if (is.null(s)) NA_real_ else as.numeric(s[[grep("Innov", names(s))[1]]])
  }, error = function(e) NA_real_)
  if (!is.finite(abar)) abar <- 0.16   # documented Bulk training median order of magnitude

  x <- seq(0, 0.8, length.out = 400)
  d <- data.frame(A = x, sat = x / (x + abar), linear = x / max(x))

  trainLo <- 0.03; trainHi <- 0.43     # MODEL.md 2.3, Bulk innovator power in training
  projLo  <- 0.58; projHi  <- 0.68     # the range REMIND takes it to

  p <- ggplot2::ggplot(d, ggplot2::aes(x = A)) +
    ggplot2::annotate("rect", xmin = trainLo, xmax = trainHi, ymin = -Inf, ymax = Inf,
                      fill = pfmAccent(), alpha = 0.10) +
    ggplot2::annotate("rect", xmin = projLo, xmax = projHi, ymin = -Inf, ymax = Inf,
                      fill = pfmRail(), alpha = 0.10) +
    ggplot2::annotate("text", x = (trainLo + trainHi) / 2, y = 0.06,
                      label = "estimated here", size = 2.6, colour = pfmAccent()) +
    ggplot2::annotate("text", x = (projLo + projHi) / 2, y = 0.06,
                      label = "asked to\noperate here", size = 2.6, colour = pfmRail(),
                      lineheight = 0.95) +
    ggplot2::geom_line(ggplot2::aes(y = linear), linetype = "22", colour = "grey55",
                       linewidth = 0.5) +
    ggplot2::geom_line(ggplot2::aes(y = sat), colour = pfmAccent(), linewidth = 0.9) +
    ggplot2::annotate("text", x = 0.78, y = 0.985, label = "linear", hjust = 1,
                      size = 2.6, colour = "grey45") +
    ggplot2::annotate("text", x = 0.78, y = 0.78 / (0.78 + abar) - 0.05,
                      label = "saturating", hjust = 1, size = 2.6, colour = pfmAccent()) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(
      title = "Political power saturates in economic weight",
      subtitle = paste0("The first tenth of renewable capacity creates a constituency where ",
                        "none existed;\nthe eighth adds little that is politically new.  ",
                        sector, " innovator power, Ā = ", sprintf("%.3f", abar), "."),
      x = "raw actor-power share  A", y = "transformed  Ã")
  attr(p, "pfmGrid") <- "both"
  pfmStamp(p, group, note = "design choice, parameter-free — not an estimate")
}
