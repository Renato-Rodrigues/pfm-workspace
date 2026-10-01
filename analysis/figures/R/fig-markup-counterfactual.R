# Fig 5d — the markup-off counterfactual: what the second instrument is actually doing.
#
# The attribution panel. Fig 5a shows the sector split; the obvious referee question is whether
# that split is the frontier speaking or just REMIND having two markets to price. This figure
# answers it with the exact twin: cm_pfmSectorMarkup = 0, nothing else changed.
#
# The answer is NOT "the split is an artefact". Turning the markup off does not remove a
# spurious spread - it DISCARDS the Bulk/Diffuse distinction, so REMIND receives only
# min(phi_Bulk, phi_Diffuse) and prices one number. So the figure has two jobs, and they are
# both comparisons within a row:
#
#   1. left panel  - the dumbbell fans out: two markets, two prices, industry near the anchor;
#   2. right panel - the dumbbell COLLAPSES to a single dot, and the dots sit AT OR ABOVE the
#      cost-optimal anchor line. That second part is claim C20's confirmation: with one
#      instrument the budget loop can only restore the budget by rescaling the anchor upward,
#      so the constraint becomes self-defeating.
#
# Form: the same horizontal dumbbell as fig-coupled-sector-split, faceted on the two runs, and
# deliberately so - the reader already knows how to read that mark from Fig 5a, and the visual
# collapse of a familiar mark is the whole message. Regions keep ONE ordering (by phi) across
# both facets, otherwise the eye cannot track a region between them.
#
# Colour: pfmSectorColours() unchanged from Fig 5a - ETS is Bulk, ES is Diffuse. Re-validated
# as a categorical pair here (scripts/validate_palette.js): CVD dE 20.3 protan, 27.8 normal,
# ALL CHECKS PASS. The anchor is a reference rule, not a third series.
#
# The collapsed mark is deliberately NEUTRAL, not a third hue, and that is a considered
# deviation from the categorical rule. pfmRail() was tried first and the validator FAILED it -
# dE 10.3 against the ES orange on normal vision, below the floor of 15 - which is exactly the
# kind of thing that survives eyeballing and should not. But the fix is not "pick a third hue":
# a third hue would assert a third CATEGORY, and the whole point is that the two categories
# MERGED. Neutral ink says "both series, same value" the way the anchor line says "reference".
# Identity still never rests on colour: the facet strip names the condition, the legend keys it,
# and the collapse is visible as geometry.

figMarkupCounterfactual <- function(group = "v5",
                                    on  = "SSP2-EU21-PkBudg1000-PFMratio",
                                    off = "SSP2-EU21-PkBudg1000-PFMratioMin",
                                    year = 2050) {
  a <- pfmArtifact(group, "coupling/coupled-runs.rds")
  res <- a$runs$resolution[a$runs$scenario == on][1]

  # Assert the twin really is markup-off. The whole figure is a claim about one switch, and a
  # mislabelled run would draw a perfectly convincing wrong picture (PITFALLS.md 16 - the
  # markup has already once read as identically zero for an unrelated reason).
  mk <- function(sc) {
    v <- a$runs$sectorMarkup[a$runs$scenario == sc & !a$runs$superseded]
    if (!length(v)) stop("figMarkupCounterfactual: no run '", sc, "' in group ", group)
    v[1]
  }
  if (!identical(mk(on) == 1, TRUE) || !identical(mk(off) == 0, TRUE)) {
    stop("figMarkupCounterfactual: expected cm_pfmSectorMarkup 1 for '", on, "' and 0 for '",
         off, "', got ", mk(on), " and ", mk(off), ".")
  }

  get <- function(sc, lab) {
    px <- a$prices[a$prices$scenario == sc & a$prices$year == year, ]
    ph <- a$phi[a$phi$scenario == sc, ]
    d <- merge(px[, c("region", "taxCO2eq", "es", "ets", "floor")], ph[, c("region", "phi")], by = "region")
    d$panel <- lab
    d
  }
  d <- rbind(get(on, "markup on   (two markets)"), get(off, "markup off   (one price)"))
  if (!nrow(d)) stop("figMarkupCounterfactual: no prices at ", year)

  # ONE region ordering across both facets, taken from the markup-on run, so a region sits on
  # the same row in each panel and the collapse is readable row by row.
  ord <- d[d$panel == "markup on   (two markets)", ]
  ord <- ord$region[order(ord$phi)]
  d$region <- factor(d$region, levels = ord)
  d$panel <- factor(d$panel, levels = c("markup on   (two markets)", "markup off   (one price)"))
  # The legislated floor is applied to pm_taxCO2eq, not to a market price - compare
  # against `taxCO2eq`, which since 2026-09-11 is a column of its own (`es` is now the
  # ES MARKET price, floor + its own markup).
  d$pinned <- is.finite(d$floor) & d$floor > 0.01 & abs(d$taxCO2eq - d$floor) < 0.01

  # the anchor is the theta = 0 gate of the same family and resolution, never assumed
  gate <- if (grepl("^SSP2-EU21", on)) "SSP2-EU21-PkBudg1000-PFMgate" else "SSP2-PkBudg1000-PFMgate"
  g <- a$prices[a$prices$scenario == gate & a$prices$year == year, ]
  anchorPrice <- stats::median(g$es, na.rm = TRUE)

  medOn  <- stats::median(d$es[d$panel == levels(d$panel)[1]])
  medOff <- stats::median(d$es[d$panel == levels(d$panel)[2]])

  # Where the markup is off the two series are EQUAL, so drawing both would stack one on the
  # other and the visible dot would be whichever was plotted last - the panel would read as
  # "only ETS" when the truth is "one price for both". Collapsed rows therefore get a single
  # point in neutral ink with its own legend key, which is what actually happened.
  cols <- pfmSectorColours()
  d$collapsed <- abs(d$ets - d$es) < 0.01
  split2 <- d[!d$collapsed, ]
  merged <- d[d$collapsed, ]

  p <- ggplot2::ggplot(d, ggplot2::aes(y = region)) +
    ggplot2::geom_vline(xintercept = anchorPrice, linetype = "22", colour = "grey35",
                        linewidth = 0.4) +
    ggplot2::geom_segment(data = split2,
                          ggplot2::aes(x = es, xend = ets, yend = region),
                          colour = "grey72", linewidth = 0.7) +
    ggplot2::geom_point(data = split2, ggplot2::aes(x = es,  colour = "ES",  shape = pinned),
                        size = 2.1, stroke = 0.8, fill = "white") +
    ggplot2::geom_point(data = split2, ggplot2::aes(x = ets, colour = "ETS", shape = pinned),
                        size = 2.1, stroke = 0.8, fill = "white") +
    ggplot2::geom_point(data = merged, ggplot2::aes(x = es, colour = "one", shape = pinned),
                        size = 2.1, stroke = 0.8, fill = "white") +
    ggplot2::facet_wrap(~ panel, nrow = 1) +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 21), guide = "none") +
    ggplot2::scale_colour_manual(
      values = c(ES = unname(cols["Diffuse"]), ETS = unname(cols["Bulk"]),
                 one = "grey30"),
      labels = c(ETS = "ETS  (electricity + industry)", ES = "ES  (buildings + transport)",
                 one = "one price, both markets"),
      breaks = c("ETS", "ES", "one")) +
    ggplot2::scale_x_continuous(labels = function(x) paste0("$", round(x)),
                                expand = ggplot2::expansion(mult = c(0.08, 0.12))) +
    ggplot2::labs(
      title = "Without the second instrument the constraint stops binding",
      subtitle = sprintf(paste0(
        "Regional carbon price in %d, %s, θ = 0.50, budget held, ordered by φ. The twins ",
        "differ in one switch.\nDashed: the cost-optimal anchor ($%.0f). With the markup off ",
        "the two markets collapse to one price and the\nmedian region returns to the anchor ",
        "($%.0f against $%.0f with it) — the constraint is absorbed, not expressed."),
        year, res, anchorPrice, medOff, medOn),
      x = sprintf("carbon price, US$2005/tCO₂ (%d)", year), y = NULL)
  attr(p, "pfmGrid") <- "x"
  attr(p, "pfmTheme") <- ggplot2::theme(panel.spacing.x = grid::unit(1.1, "lines"))

  # Direct labels once, in the left facet only - in the right facet the two series coincide,
  # so labelling both would print two names on one dot.
  ex <- d[d$panel == levels(d$panel)[1], ]
  ex <- ex[c(1, nrow(ex)), ]
  p <- p +
    ggplot2::geom_text(data = ex, ggplot2::aes(x = ets, label = "ETS"), hjust = -0.35,
                       size = 2.3, colour = unname(cols["Bulk"])) +
    ggplot2::geom_text(data = ex, ggplot2::aes(x = es, label = "ES"), hjust = 1.35,
                       size = 2.3, colour = unname(cols["Diffuse"]))

  pfmStamp(p, group, note = paste0(
    "exact twins, cm_pfmSectorMarkup 1 vs 0 - the split's direction is a frontier ",
    "result, its magnitude is rule-dependent"))
}
