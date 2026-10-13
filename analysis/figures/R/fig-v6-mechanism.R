# Why the political limit fades in the coupled headline run, and how far that rests on energy systems
# nobody has observed (0005 C3 and C10). Read from coupling/strength-support.rds (analysis/v6/couplingMechanism.R).
#
# Top row: the strength k_s(t) of the hold-the-price headline run (EU21, theta = 0.50, final energy system)
# with every driver moving, and with only one group moving, the others held at 2025 - the economic weight
# of fossil and clean-energy interests, institutions, income and population.
# Bottom row: the final-energy-weighted share of countries whose fossil dependence lies below, or whose
# clean-energy build-out lies above, anything observed in estimation. Two rows, one measure each: no
# second axis. Lines are labelled at their end; no legend.

figV6Mechanism <- function(group = "v6") {
  S <- pfmArtifact(group, "coupling/strength-support.rds")
  run <- "PFMlevelBfix-v6"
  rowK <- "strength k (2025 = 1)"
  rowB <- "% beyond observed"
  grpLab <- c(all = "all drivers", `actor power` = "weight of interests only", institutions = "institutions only",
              controls = "income and population only")
  d1 <- S$decomposition[S$decomposition$run == run, ]
  d1 <- data.frame(row = rowK, sector = d1$sector, year = d1$year, value = d1$k, series = grpLab[d1$onlyMoving])
  b <- S$beyond[S$beyond$run == run, ]
  up <- b[b$term == "Innovator.Power", ]; dn <- b[b$term == "Incumbent.Power", ]
  lUp <- "clean-energy build-out\nabove"; lDn <- "fossil dependence\nbelow"
  d2 <- rbind(data.frame(row = rowB, sector = up$sector, year = up$year, value = 100 * up$above, series = lUp),
              data.frame(row = rowB, sector = dn$sector, year = dn$year, value = 100 * dn$below, series = lDn))
  d <- rbind(d1, d2)
  d$row <- factor(d$row, levels = c(rowK, rowB))
  cols <- c("#1F2A33", "#1B6CA8", "#C2571A", "grey60", "#1F8A7E", "#8C510A")
  names(cols) <- c(grpLab[["all"]], grpLab[["actor power"]], grpLab[["institutions"]], grpLab[["controls"]], lUp, lDn)
  ends <- d[d$year == max(d$year), ]
  ends$txt <- ifelse(ends$row == rowB, sprintf("%s (%.0f%%)", ends$series, ends$value), ends$series)
  # keep end labels apart: within a panel, at least 26% of the panel's range between neighbours
  ends$ly <- ends$value
  for (k in split(seq_len(nrow(ends)), list(as.character(ends$row), ends$sector), drop = TRUE)) {
    v <- d$value[d$row == ends$row[k[1]] & d$sector == ends$sector[k[1]]]
    gap <- 0.26 * diff(range(v)); o <- k[order(ends$value[k])]
    for (j in seq_along(o)[-1]) ends$ly[o[j]] <- max(ends$ly[o[j]], ends$ly[o[j - 1]] + gap)
  }
  ref <- data.frame(row = factor(rowK, levels = levels(d$row)), y = 1)
  p <- ggplot2::ggplot(d, ggplot2::aes(year, value, colour = series)) +
    ggplot2::geom_hline(data = ref, ggplot2::aes(yintercept = y), colour = "grey80", linewidth = 0.4) +
    ggplot2::geom_line(ggplot2::aes(linewidth = series == "all drivers")) +
    ggplot2::geom_point(data = ends, size = 1.6) +
    ggplot2::geom_text(data = ends, ggplot2::aes(y = ly, label = txt), hjust = -0.08, size = 2.5,
                       lineheight = 0.85, show.legend = FALSE) +
    ggplot2::facet_grid(row ~ sector, scales = "free_y", switch = "y") +
    ggplot2::scale_colour_manual(values = cols, guide = "none") +
    ggplot2::scale_linewidth_manual(values = c(`TRUE` = 1.1, `FALSE` = 0.6), guide = "none") +
    ggplot2::scale_x_continuous(limits = c(2025, 2185), breaks = c(2025, 2050, 2075, 2100)) +
    ggplot2::labs(title = "The limit fades as fossil dependence falls, on energy systems never observed",
                  subtitle = paste0("Hold the price, fading limit, EU21, θ = 0.50. Top: k with all drivers moving, and with one\n",
                                    "group moving (others held at 2025). Bottom: % of countries (by final energy) beyond estimation data."),
                  x = NULL, y = NULL)
  p <- pfmStamp(p, group, note = "coupling/strength-support.rds")
  attr(p, "pfmTheme") <- ggplot2::theme(strip.placement = "outside", strip.text.y.left = ggplot2::element_text(angle = 90),
                                        panel.spacing.y = grid::unit(1.2, "lines"))
  p
}
