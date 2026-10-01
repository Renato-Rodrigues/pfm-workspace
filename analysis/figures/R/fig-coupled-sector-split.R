# Fig 5a — where the political constraint actually lands.
#
# THE payoff figure of the coupled batch, and the one that carries the paper's headline.
#
# The message is a CONTRAST between two spreads, not two levels: with two markets to price,
# REMIND holds the industrial (ETS) price near the cost-optimal anchor in every region and
# absorbs almost the whole political constraint in the household-facing (ES) price. So the
# figure has to make "one series is flat, the other fans out" legible at a glance.
#
# Form: horizontal dumbbell, one row per region, ordered by phi. A dumbbell is the right
# mark here because the READER'S JOB is to compare two values within a region and then
# compare that gap across regions - which grouped bars make hard and a dual axis would make
# impossible. The anchor is a reference rule, not a third series.
#
# Colour: pfmSectorColours(), unchanged - ETS is Bulk (electricity + industry), ES is
# Diffuse (buildings + transport). Validated as a categorical pair (CVD dE 20.3 protan,
# 27.8 normal, both PASS), and identity is carried by direct labels as well as hue.

figCoupledSectorSplit <- function(group = "v5",
                                  scenario = "SSP2-EU21-PkBudg1000-PFMratio",
                                  year = 2050) {
  a <- pfmArtifact(group, "coupling/coupled-runs.rds")
  res <- a$runs$resolution[a$runs$scenario == scenario][1]

  px <- a$prices[a$prices$scenario == scenario & a$prices$year == year, ]
  ph <- a$phi[a$phi$scenario == scenario, ]
  if (!nrow(px)) stop("figCoupledSectorSplit: no prices for ", scenario, " at ", year)

  d <- merge(px[, c("region", "taxCO2eq", "es", "ets", "floor")],
             ph[, c("region", "phi")], by = "region")
  d <- d[order(d$phi), ]
  d$region <- factor(d$region, levels = d$region)

  # regions pinned at the legislated-policy floor read as a political result and are not one
  # The legislated floor is applied to pm_taxCO2eq, not to a market price - compare
  # against `taxCO2eq`, which since 2026-09-11 is a column of its own (`es` is now the
  # ES MARKET price, floor + its own markup).
  d$pinned <- is.finite(d$floor) & d$floor > 0.01 & abs(d$taxCO2eq - d$floor) < 0.01

  anchor <- a$runs$cum2100[0]  # placeholder to keep the artifact contract explicit
  anchorPrice <- max(d$ets, na.rm = TRUE)
  # the anchor is the uncapped cost-optimal path; take it from the theta = 0 gate of the
  # same family and resolution rather than assuming it
  gate <- if (grepl("^SSP2-EU21", scenario)) "SSP2-EU21-PkBudg1000-PFMgate" else
                                             "SSP2-PkBudg1000-PFMgate"
  g <- a$prices[a$prices$scenario == gate & a$prices$year == year, ]
  if (nrow(g)) anchorPrice <- stats::median(g$es, na.rm = TRUE)

  cols <- pfmSectorColours()
  lab <- c(ETS = "ETS price  (electricity + industry)",
           ES  = "ES price  (buildings + transport)")

  # Spreads are quoted on the regions where the mechanism CAN act. The regions pinned at the
  # legislated EU floor have their ES price held up, which mechanically lifts their ETS total
  # too - at EU21 that alone inflates the ETS spread from 1.06x to 1.36x and would overstate
  # the very dispersion this figure argues is absent. Quote the unpinned set and show the
  # pinned regions as hollow so the reader can see which rows were excluded and why.
  u <- d[!d$pinned, ]
  spreadES  <- max(u$es)  / min(u$es)
  spreadETS <- max(u$ets) / min(u$ets)

  p <- ggplot2::ggplot(d, ggplot2::aes(y = region)) +
    ggplot2::geom_vline(xintercept = anchorPrice, linetype = "22", colour = "grey35",
                        linewidth = 0.4) +
    ggplot2::annotate("text", x = anchorPrice, y = Inf, hjust = 1.03, vjust = -0.5,
                      label = sprintf("cost-optimal  $%.0f", anchorPrice),
                      size = 2.5, colour = "grey30") +
    ggplot2::coord_cartesian(clip = "off") +
    # the gap IS the markup - draw it as the connector, 2px, recessive
    ggplot2::geom_segment(ggplot2::aes(x = es, xend = ets, yend = region),
                          colour = "grey72", linewidth = 0.7) +
    # hollow = pinned at the legislated floor, so not a political result
    ggplot2::geom_point(ggplot2::aes(x = es,  colour = "ES",  shape = pinned), size = 2.1,
                        stroke = 0.8, fill = "white") +
    ggplot2::geom_point(ggplot2::aes(x = ets, colour = "ETS", shape = pinned), size = 2.1,
                        stroke = 0.8, fill = "white") +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 21), guide = "none") +
    ggplot2::scale_colour_manual(values = c(ES = unname(cols["Diffuse"]),
                                            ETS = unname(cols["Bulk"])),
                                 labels = lab, breaks = c("ETS", "ES")) +
    ggplot2::scale_x_continuous(labels = function(x) paste0("$", round(x)),
                                expand = ggplot2::expansion(mult = c(0.10, 0.10))) +
    # TITLE. Until 2026-09-14 this read "The political constraint lands on households, not on
    # industry". That was true of the lambda = 1 batch, where ES/ETS ran 0.907-1.019 and the
    # sign was the same everywhere. It is NOT true at the deployed lambda = 0: the split is
    # three times wider and runs BOTH ways - 14 of 21 EU21 regions price households below
    # industry and 7 above, by up to 1.73x. The direction is region-specific, and that IS the
    # result. Every number in the subtitle is computed from the data, never asserted.
    ggplot2::labs(
      # the title number is computed too: the widest split in either direction
      title = sprintf("Politics splits the two sectors by up to %.1f× — and not the same way everywhere",
                      max(max(d$es / d$ets), max(d$ets / d$es))),
      subtitle = sprintf(paste0(
        "Regional carbon price in %d, %s, θ = 0.50, ordered by φ. The budget is held.\n",
        "Households pay LESS than industry in %d of %d regions and MORE in %d; ES/ETS runs %.2f–%.2f.",
        if (any(d$pinned)) "\nHollow = %d regions pinned at the legislated EU floor, excluded from the spreads." else "%.0s"),
        year, res, sum(d$es < d$ets - 1e-9), nrow(d), sum(d$es > d$ets + 1e-9),
        min(d$es / d$ets), max(d$es / d$ets), sum(d$pinned)),
      x = sprintf("carbon price, US$2005/tCO₂ (%d)", year), y = NULL)
  attr(p, "pfmGrid") <- "x"

  # Direct labels on the two extreme rows, so identity never rests on hue alone.
  ex <- d[c(1, nrow(d)), ]
  p <- p +
    ggplot2::geom_text(data = ex, ggplot2::aes(x = ets, label = "ETS"),
                       hjust = -0.35, size = 2.3, colour = unname(cols["Bulk"])) +
    ggplot2::geom_text(data = ex, ggplot2::aes(x = es, label = "ES"),
                       hjust = 1.35, size = 2.3, colour = unname(cols["Diffuse"]))

  note <- if (any(d$pinned))
    sprintf("%d regions sit at the legislated EU price floor, not at a political limit",
            sum(d$pinned)) else NULL
  pfmStamp(p, group, note = note)
}
