# Fig 1a — polity to politics to policy, resolving into the feasibility share.
#
# Conceptual: it carries NO data and must not be drawn as if it does. No axes, no scale, no
# numbers. The one design obligation is that the reader can see where the loop closes —
# the arrow back from the IAM to actor power is the whole contribution, and it is the thing
# most often missed when this is explained verbally.

figChainSchematic <- function(group = "v5") {
  box <- function(id, x, y, w, h, label, detail = NA, kind = "step") {
    data.frame(id = id, x = x, y = y, w = w, h = h, label = label,
               detail = detail, kind = kind, stringsAsFactors = FALSE)
  }
  b <- rbind(
    box("polity",   1.0, 3.0, 1.7, 1.0, "POLITY",
        "state capability\naccountability", "input"),
    box("actors",   1.0, 1.4, 1.7, 1.0, "ACTORS",
        "innovator vs\nincumbent power", "input"),
    box("ceiling",  3.4, 2.2, 1.8, 1.2, "CEILING  S*",
        "the most stringency\nthese politics support", "core"),
    box("gap",      5.7, 2.2, 1.7, 1.2, "SLACK  E = S/S*",
        "distance below\nits OWN ceiling", "core"),
    box("phi",      7.9, 2.2, 1.7, 1.2, "SHARE  φ",
        "of the INCREMENT\na region can realize", "core"),
    box("iam",     10.1, 2.2, 1.8, 1.2, "IAM PRICE",
        "cost-optimal path,\npolitically bounded", "output"))

  arr <- data.frame(
    x    = c(1.85, 1.85, 4.30, 6.55, 8.75),
    y    = c(3.00, 1.40, 2.20, 2.20, 2.20),
    xend = c(2.50, 2.50, 4.85, 7.05, 9.20),
    yend = c(2.55, 1.90, 2.20, 2.20, 2.20))

  # the feedback: IAM energy system -> actor power. Drawn low and long so it reads as a
  # loop rather than another forward step.
  fb <- data.frame(x = 10.1, y = 1.60, xend = 1.0, yend = 0.90)

  cols <- c(input = "#E8EEF4", core = "#D8E6F0", output = "#F2E4D8")

  p <- ggplot2::ggplot() +
    ggplot2::geom_tile(data = b, ggplot2::aes(x = x, y = y, width = w, height = h,
                                              fill = kind),
                       colour = "grey35", linewidth = 0.35) +
    ggplot2::geom_text(data = b, ggplot2::aes(x = x, y = y + 0.22, label = label),
                       size = 2.9, fontface = "bold", colour = "grey15") +
    ggplot2::geom_text(data = b[!is.na(b$detail), ],
                       ggplot2::aes(x = x, y = y - 0.20, label = detail),
                       size = 2.2, colour = "grey30", lineheight = 0.95) +
    ggplot2::geom_segment(data = arr, ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
                          arrow = ggplot2::arrow(length = grid::unit(1.6, "mm"),
                                                 type = "closed"),
                          linewidth = 0.4, colour = "grey35") +
    ggplot2::geom_curve(data = fb, ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
                        curvature = 0.16, linewidth = 0.45, colour = pfmRail(),
                        linetype = "31",
                        arrow = ggplot2::arrow(length = grid::unit(1.8, "mm"),
                                               type = "closed")) +
    ggplot2::annotate("text", x = 5.6, y = 0.72, colour = pfmRail(), size = 2.4,
                      label = "deployment shifts who holds power — the loop closes here") +
    ggplot2::annotate("text", x = 5.6, y = 0.36, colour = pfmRail(), size = 2.1,
                      fontface = "italic",
                      label = "conditional scenario accounting, NOT an identified causal effect") +
    ggplot2::scale_fill_manual(values = cols, guide = "none") +
    ggplot2::coord_cartesian(xlim = c(0, 11.2), ylim = c(0.1, 3.8)) +
    ggplot2::labs(title = "From institutions to a bounded carbon price",
                  x = NULL, y = NULL)
  attr(p, "pfmGrid") <- "none"
  # Applied AFTER theme_pfm by buildFigure(). A conceptual figure must show no axes and no
  # grid: numeric ticks on a schematic imply a scale that does not exist.
  attr(p, "pfmTheme") <- ggplot2::theme(
    axis.text = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(), panel.grid = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank())
  p   # deliberately NOT stamped: it carries no data, so no Run-Group applies
}
