# The persistence ladder (design note 0006): every result of both closures against how long the political
# drag lasts, EU21, theta = 0.50. Read from coupling/persistence-ladder.rds (analysis/v6/persistenceLadder.R).
#
#   v6-persistence-ladder  three panels sharing the rungs: extra CO2 by 2100 when the price is held; the
#                          global price in 2050 and the abatement moved between regions when the budget is held
#   v6-cumulative-co2      cumulative CO2 to 2150 when the price is held, one line per rung against the
#                          theta = 0 run: whether and when it peaks (net-zero CO2)
#
# The rungs are ordered from the most persistent drag to the fastest erosion, in one hue from dark to light.

.pfmRungs <- function() {
  c(backslide = "drag growing (backsliding)", Ehold = "today's drag held", deployed = "fading with the transition",
    kappa02 = "plus erosion κ 0.02", kappa = "plus erosion κ 0.027", kappa05 = "plus erosion κ 0.05")
}

figV6PersistenceLadder <- function(group = "v6", resolution = "EU21") {
  L <- pfmArtifact(group, "coupling/persistence-ladder.rds")
  R <- .pfmRungs()
  B <- L$ruleB[L$ruleB$res == resolution, ]; C <- L$ruleC[L$ruleC$res == resolution, ]
  rungs <- R[names(R) %in% union(B$rung, C$rung)]
  pan <- c(B = "Hold the price:\nextra CO₂ by 2100, Gt",
           P = "Hold the budget:\nprice in 2050, × θ = 0 run",
           C = "Hold the budget:\nabatement moved, Gt")
  lv <- rev(unname(rungs))
  d1 <- data.frame(panel = pan[["B"]], rung = R[B$rung], part = "by 2100", value = B$extra2100)
  d2 <- data.frame(panel = pan[["P"]], rung = R[C$rung], part = "price", value = C$anchorOverGate)
  d3 <- rbind(data.frame(panel = pan[["C"]], rung = R[C$rung], part = "2020–2050", value = C$relocated2050),
              data.frame(panel = pan[["C"]], rung = R[C$rung], part = "2051–2100", value = C$relocatedAfter2050))
  d <- rbind(d1, d2, d3)
  d$rung <- factor(d$rung, levels = lv); d$panel <- factor(d$panel, levels = unname(pan))
  d$part <- factor(d$part, levels = c("by 2100", "price", "2051–2100", "2020–2050"))
  lab <- rbind(data.frame(panel = pan[["B"]], rung = R[B$rung], value = B$extra2100, txt = sprintf("%+.0f", B$extra2100)),
               data.frame(panel = pan[["P"]], rung = R[C$rung], value = C$anchorOverGate, txt = sprintf("×%.2f", C$anchorOverGate)),
               data.frame(panel = pan[["C"]], rung = R[C$rung], value = C$relocated, txt = sprintf("%.1f", C$relocated)))
  lab$rung <- factor(lab$rung, levels = lv); lab$panel <- factor(lab$panel, levels = unname(pan))
  # the price panel starts at 1 (the theta = 0 price), drawn as a point and a stem from 1
  dp <- d[d$part == "price", ]; db <- d[d$part != "price", ]
  p <- ggplot2::ggplot() +
    ggplot2::geom_col(data = db, ggplot2::aes(value, rung, fill = part), width = 0.62) +
    ggplot2::geom_segment(data = dp, ggplot2::aes(x = 1, xend = value, y = rung, yend = rung), colour = "grey70", linewidth = 0.5) +
    ggplot2::geom_point(data = dp, ggplot2::aes(value, rung), colour = pfmAccent(), size = 2.2) +
    ggplot2::geom_text(data = lab, ggplot2::aes(value, rung, label = txt), hjust = -0.25, size = 2.5, colour = "grey20") +
    ggplot2::facet_wrap(~panel, nrow = 1, scales = "free_x") +
    ggplot2::scale_fill_manual(values = c(`by 2100` = pfmAccent(), `2020–2050` = "grey65", `2051–2100` = "#5B9BD5"),
                               breaks = c("2020–2050", "2051–2100"), name = "abatement moved:") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.22))) +
    ggplot2::labs(title = "How long the political drag lasts orders every result, under both closures",
                  subtitle = paste0("Coupled REMIND runs, ", resolution, ", θ = 0.50, 1000 Gt budget, each against its θ = 0 run.\n",
                                    "Top row: the drag persists longest. Abatement moved: half the sum of regional changes, 2020–2100."),
                  x = NULL, y = NULL)
  attr(p, "pfmGrid") <- "x"
  attr(p, "pfmTheme") <- ggplot2::theme(legend.position = "bottom", strip.text = ggplot2::element_text(hjust = 0, face = "bold"))
  pfmStamp(p, group, note = "coupling/persistence-ladder.rds")
}

figV6CumulativeCo2 <- function(group = "v6", resolution = "EU21") {
  L <- pfmArtifact(group, "coupling/persistence-ladder.rds")
  R <- .pfmRungs()
  P <- L$paths[L$paths$res == resolution & L$paths$rule == "B" & L$paths$year >= 2025, ]
  rungs <- R[names(R) %in% P$rung]
  P$line <- ifelse(P$rung == "null", "no political limit (θ = 0)", R[P$rung])
  lv <- c(unname(rungs), "no political limit (θ = 0)")
  P$line <- factor(P$line, levels = lv)
  # one hue, dark (persistent drag) to light (fast erosion); the theta = 0 run in grey
  shades <- grDevices::colorRampPalette(c("#0B3C61", "#9CC3E4"))(length(rungs))
  cols <- c(stats::setNames(shades, unname(rungs)), `no political limit (θ = 0)` = "grey45")
  pk <- do.call(rbind, lapply(split(P, P$line), function(x) { i <- which.max(x$cum); x[i, ] }))
  pk$label <- ifelse(pk$year >= max(P$year), "still rising in 2150", paste("peaks", pk$year))
  end <- do.call(rbind, lapply(split(P, P$line), function(x) x[which.max(x$year), ]))
  end <- end[end$line %in% pk$line[pk$year >= max(P$year)], ]   # label only the lines still rising in 2150
  p <- ggplot2::ggplot(P, ggplot2::aes(year, cum, colour = line)) +
    ggplot2::geom_hline(yintercept = 1000, colour = "grey55", linewidth = 0.4, linetype = "22") +
    ggplot2::annotate("text", x = 2027, y = 1000, label = "1000 Gt budget", vjust = -0.5, hjust = 0, size = 2.5, colour = "grey35") +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(data = pk[pk$year < max(P$year), ], size = 2.2) +
    ggplot2::geom_text(data = end, ggplot2::aes(label = sprintf("%.0f Gt", cum)), hjust = -0.15, size = 2.5, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::scale_x_continuous(breaks = c(2025, 2050, 2075, 2100, 2125, 2150), expand = ggplot2::expansion(mult = c(0.01, 0.1))) +
    ggplot2::labs(title = "If the political drag does not erode, cumulative CO₂ is still rising in 2150",
                  subtitle = paste0("Hold the price (rule B), ", resolution, ", θ = 0.50: cumulative CO₂ from 2020, Gt.\n",
                                    "A dot marks the year it peaks (net-zero CO₂); no dot: still rising in 2150."),
                  x = NULL, y = "cumulative CO₂ (Gt)")
  attr(p, "pfmGrid") <- "y"
  attr(p, "pfmTheme") <- ggplot2::theme(legend.position = "right")
  pfmStamp(p, group, note = "coupling/persistence-ladder.rds (pm_actualbudgetco2)")
}
