# SI — the ceiling at the resolution the coupling actually uses.
#
# `frontier-vs-observed` and `frontier-projected` show 48 countries, which is where the frontier
# is FITTED. This shows the same thing over the 21 REMIND regions, which is where phi is
# ASSIGNED. Both are needed and neither substitutes for the other.
#
# 🔴 THIS IS NOT A RESCALED VIEW OF THE COUNTRY FIGURES. Two reasons, and both matter:
#   1. u is min-max normalised over whatever units are in the frame, so aggregating CHANGES THE
#      OBJECT rather than the units - the same effect that moves the anchor from 0.744 over 48
#      countries to 0.396 over 21 regions (MODEL.md 5.3, PITFALLS.md 15).
#   2. The frontier is non-linear (index = 10 * plogis(eta)), so a weighted mean of country
#      ceilings is NOT the ceiling of the weighted mean. No regional frontier was ever fitted.
#      Every line here is a SUMMARY of country ceilings and the title says so.
#
# Coverage is carried in the strip label, not in a footnote, because it is the binding caveat
# on every regional number: a region at 41% is a claim about two-fifths of its energy. The USA
# is drawn as an EMPTY PANEL - it has no in-coverage country at all, and showing the hole is
# more honest than dropping the region and letting the reader assume 20 is all there are.
#
# Colour: the two scenarios reuse the validated Bulk/Diffuse pair (#1B6CA8 / #C2571A, CVD dE
# 20.3 protan / 27.8 normal, ALL PASS). The historical half stays in ink, as in the companion
# figures, so "past = ink, future = colour" reads the same way across all three.

figFrontierByRegion <- function(group = "v5", sector = "Diffuse", lastYear = 2100,
                                ncol = 5L) {
  d <- pfmArtifact(group, "regional-frontier.rds")
  d <- d[d$sector == sector & d$year <= lastYear, ]
  if (!nrow(d)) stop("figFrontierByRegion: no rows for sector '", sector, "'")

  h   <- d[d$kind %in% c("observed", "fitted"), ]
  prj <- d[d$kind == "projected", ]
  # Label from scenarioName, and FIX THE ORDER explicitly. Taking labels from the id would sort
  # alphabetically, which put NPi first here and PkBudg first in `frontier-projected` - the same
  # two scenarios wearing swapped colours across two figures the reader is meant to compare.
  # Colour follows the entity, so the ambitious pathway is pinned first in both.
  prj$scenarioLab <- factor(prj$scenarioName,
                            levels = c(grep("Ambition", unique(prj$scenarioName), value = TRUE),
                                       grep("Ambition", unique(prj$scenarioName), value = TRUE,
                                            invert = TRUE)))

  # Order by mean use of the ceiling, matching the country figures so the three can be read
  # together. Computed from the regional aggregates, not carried over from country level.
  o <- merge(h[h$kind == "observed", c("region", "year", "index")],
             h[h$kind == "fitted",   c("region", "year", "index")],
             by = c("region", "year"), suffixes = c(".o", ".f"))
  eff <- stats::aggregate(list(eff = o$index.o / pmax(o$index.f, 1e-9)),
                          by = list(region = o$region), FUN = mean, na.rm = TRUE)
  eff <- eff[order(-eff$eff), ]

  cov <- unique(d[, c("region", "coveredShare")])
  cov <- cov[!duplicated(cov$region), ]

  # The USA has no in-coverage country, so it is absent from the artifact by construction.
  # Add it back as an empty panel: the hole is claim C18 and must be visible.
  allReg <- union(eff$region, "USA")
  lab <- function(r) {
    s <- cov$coveredShare[match(r, cov$region)]
    ifelse(is.na(s), paste0(r, "  0%"), sprintf("%s  %.0f%%", r, 100 * s))
  }
  lev <- c(eff$region, setdiff(allReg, eff$region))
  labs <- stats::setNames(lab(lev), lev)
  h$region   <- factor(labs[h$region],   levels = unname(labs))
  prj$region <- factor(labs[prj$region], levels = unname(labs))
  empty <- data.frame(region = factor(labs[["USA"]], levels = unname(labs)),
                      year = 2050, index = NA_real_)

  cols <- unname(pfmSectorColours())
  p <- ggplot2::ggplot(mapping = ggplot2::aes(x = year)) +
    ggplot2::geom_blank(data = empty, ggplot2::aes(y = index)) +
    ggplot2::geom_line(data = h[h$kind == "fitted", ], ggplot2::aes(y = index),
                       colour = pfmMuted(), linewidth = 0.45, linetype = "22") +
    ggplot2::geom_line(data = h[h$kind == "observed", ], ggplot2::aes(y = index),
                       colour = "grey20", linewidth = 0.5) +
    ggplot2::geom_line(data = prj, ggplot2::aes(y = index, colour = scenarioLab),
                       linewidth = 0.6) +
    ggplot2::geom_vline(xintercept = 2023.5, colour = "grey75", linewidth = 0.3,
                        linetype = "12") +
    ggplot2::facet_wrap(~ region, ncol = ncol) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::scale_x_continuous(breaks = c(2010, 2060), expand = ggplot2::expansion(mult = 0.05)) +
    ggplot2::scale_y_continuous(limits = c(0, 10), breaks = c(0, 5, 10),
                                expand = ggplot2::expansion(mult = 0.02)) +
    ggplot2::labs(
      title = sprintf("The ceiling summarised over REMIND regions (%s)", sector),
      subtitle = paste0(
        "Final-energy-weighted mean of the country ceilings — NOT a regional frontier, which ",
        "was never fitted.\nGrey solid: observed. Grey dashed: fitted. Coloured: projected. ",
        "The percentage beside each region is the\nshare of its energy that has a measured ",
        "ceiling at all; the United States has none, so its panel is empty."),
      x = NULL, y = "policy stringency index (0–10)")
  attr(p, "pfmGrid") <- "y"
  attr(p, "pfmTheme") <- ggplot2::theme(
    panel.spacing = grid::unit(0.4, "lines"),
    strip.text = ggplot2::element_text(size = 7, margin = ggplot2::margin(1, 0, 1, 0)))

  pfmStamp(p, group, note = paste0(
    "phi is assigned at THIS resolution, but aggregation changes the object - not a rescaled ",
    "view of the country figures (PITFALLS.md 15)"))
}
