# SI — the same ceiling, carried forward: fitted 2001-2022, then projected under two scenarios.
#
# The companion to `frontier-vs-observed`. That figure shows where the ceiling comes from; this
# one shows what the coupling actually consumes, because phi is computed from the PROJECTED
# ceiling at the seed year, not from the fitted one. Anyone checking the chain from data to
# coupled result has to be able to see both halves in the same axes.
#
# Two scenarios, because C5 asks whether ambition raises the ceiling it runs into: the ceiling
# is a function of scenario drivers, so a high-ambition pathway and a current-policies pathway
# give different ceilings for the same country.
#
# ⚠️ THE TWO HALVES ARE THE SAME QUANTITY, AND THAT TOOK A RETRACTION TO GET RIGHT.
# An earlier version of this figure drew the FITTED CEILING (frontier.rds$scores$frontierIndex)
# for the past against the PROJECTED LEVEL (projections/*.rds$index) for the future, and reported
# the gap between them as an unexplained discontinuity. They are different objects:
#
#     frontierIndex  the SFA frontier - a CEILING              runPSMFrontier
#     index          projected policy stringency - a LEVEL     projectPSMSpecScenario
#
# projectFeasiblePath() says so in its own header: the path converges to the ECM equilibrium, NOT
# to the SFA frontier; the frontier enters only as an upper bound and as the gap exhibit. So the
# "step" was the model's SLACK TERM - its central estimated quantity - misread as a defect.
# Against the right counterpart the projection is continuous: 2025 index against 2022 observed is
# +0.95 index points, against 2022 expected +0.92, against the ceiling -1.23.
#
# This figure therefore plots the LEVEL as one continuous series (observed, then projected) and
# the fitted ceiling as the separate upper bound it is, drawn for the historical years only
# because the projection artifact carries no ceiling column. Never join them.
# See PITFALLS.md 21 and docs/TODO.md item 10.
#
# Form: small multiples again, same country ordering as `frontier-vs-observed` so the two
# figures can be read side by side. Fixed y-scale, same 0-10 index.
#
# Colour: the two SCENARIOS are a categorical pair and get the validated Bulk/Diffuse hues
# (#1B6CA8 / #C2571A - CVD dE 20.3 protan, 27.8 normal, ALL PASS) reused as a generic
# two-category pair. The historical half is not a third category: the fitted ceiling stays in
# muted ink and the observed path in near-black, exactly as in the companion figure, so the eye
# reads "past = ink, future = colour".

figFrontierProjected <- function(group = "v5",
                                 sector = "Diffuse",
                                 scenarios = c("SSP2-PkBudg1000-PFMref",
                                               "SSP2-NPi2025-PFMbase"),
                                 lastYear = 2100, ncol = 8L) {
  fr <- pfmArtifact(group, "frontier.rds")
  h <- fr$bySector[[sector]]$scores
  if (is.null(h)) stop("figFrontierProjected: no sector '", sector, "' in frontier.rds")

  # Projections are per-scenario artifacts. Read each and keep only the countries the frontier
  # was actually FITTED on - out-of-coverage countries carry a transferred relative gap rather
  # than a measured ceiling (MODEL.md 4), so plotting them beside observed data would imply
  # evidence that does not exist.
  keep <- sort(unique(h$region))
  pr <- do.call(rbind, lapply(scenarios, function(sc) {
    d <- as.data.frame(pfmArtifact(group, file.path("projections", paste0(sc, ".rds"))))
    d <- d[d$sector == sector & !d$outOfCoverage & d$region %in% keep & d$year <= lastYear, ]
    if (!nrow(d)) stop("figFrontierProjected: scenario '", sc, "' has no in-coverage rows for ",
                       sector)
    d$scenarioLab <- d$scenarioName[1]
    d
  }))

  # Continuity of the LEVEL, measured against the right counterpart. Reported on the figure
  # because the earlier version reported the wrong one and called it a defect.
  h22 <- h[h$year == max(h$year), c("region", "observedIndex")]
  p1  <- pr[pr$year == min(pr$year) & pr$scenario == scenarios[1], c("region", "index")]
  step <- stats::median(merge(h22, p1, by = "region")$index -
                        merge(h22, p1, by = "region")$observedIndex, na.rm = TRUE)

  # The scenario fan, measured at 2050 against the projection interval's own width. Quoted on
  # the figure because the visual impression overstates it - see the colour note above.
  fy <- 2050
  fa <- pr[pr$scenario == scenarios[1] & pr$year == fy, c("region", "index", "indexLo", "indexHi")]
  fb <- pr[pr$scenario == scenarios[2] & pr$year == fy, c("region", "index")]
  fm <- merge(fa, fb, by = "region", suffixes = c(".a", ".b"))
  fan <- stats::median(fm$index.a - fm$index.b, na.rm = TRUE)
  fanRel <- stats::median(abs(fm$index.a - fm$index.b), na.rm = TRUE) /
            stats::median(fm$indexHi - fm$indexLo, na.rm = TRUE)

  eff <- stats::aggregate(list(eff = h$observedIndex / pmax(h$frontierIndex, 1e-9)),
                          by = list(region = h$region), FUN = mean, na.rm = TRUE)
  eff <- eff[order(-eff$eff), ]
  h$region  <- factor(h$region,  levels = eff$region)
  pr$region <- factor(pr$region, levels = eff$region)
  pr$scenarioLab <- factor(pr$scenarioLab, levels = unique(pr$scenarioLab))

  cols <- unname(pfmSectorColours())

  p <- ggplot2::ggplot(mapping = ggplot2::aes(x = year)) +
    # --- the past: fitted ceiling and what was actually done ------------------
    # the CEILING - an upper bound, historical years only, deliberately dashed and recessive
    ggplot2::geom_line(data = h, ggplot2::aes(y = frontierIndex),
                       colour = pfmMuted(), linewidth = 0.45, linetype = "22") +
    # the LEVEL - the same quantity the projection continues, so it is drawn as one series
    ggplot2::geom_line(data = h, ggplot2::aes(y = observedIndex),
                       colour = "grey20", linewidth = 0.5) +
    # --- the future: the projected LEVEL, one line per scenario ----------------
    # This continues the grey observed line; it does NOT continue the dashed ceiling.
    # ONE ribbon, NEUTRAL, deliberately. Two translucent fills at this panel size overlapped
    # into grey mush and neither could be attributed to its line. But dropping the interval
    # would be worse: the eye reads RUS, COL and PER as strong divergence when the measured
    # gap is a median of +0.11 index points at 2050, about 7% of this band's own width. The
    # band is what prevents that misreading, and it is neutral because it is a magnitude
    # reference rather than a third identity.
    ggplot2::geom_ribbon(data = pr[pr$scenario == scenarios[1], ],
                         ggplot2::aes(ymin = indexLo, ymax = indexHi),
                         fill = "grey60", alpha = 0.18) +
    ggplot2::geom_line(data = pr, ggplot2::aes(y = index, colour = scenarioLab),
                       linewidth = 0.55) +
    ggplot2::facet_wrap(~ region, ncol = ncol) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::scale_x_continuous(breaks = c(2010, 2060), expand = ggplot2::expansion(mult = 0.05)) +
    ggplot2::scale_y_continuous(limits = c(0, 10), breaks = c(0, 5, 10),
                                expand = ggplot2::expansion(mult = 0.02)) +
    ggplot2::labs(
      title = sprintf("Policy stringency, observed and then projected (%s)", sector),
      subtitle = sprintf(paste0(
        "Grey solid then coloured: policy stringency, observed to 2022 and projected to %d — ",
        "ONE series, continuous\nacross the join (%+.2f index points). Grey dashed: the fitted ",
        "CEILING, a different quantity and an upper bound,\nshown for historical years only. The ",
        "gap between them is the model's slack. Band: the ambitious pathway's\nprojection ",
        "interval; the two scenarios differ by a median of %+.2f points at 2050, about %.0f%% of ",
        "it."),
        lastYear, step, fan, 100 * fanRel),
      x = NULL, y = "policy stringency index (0–10)")
  attr(p, "pfmGrid") <- "y"
  attr(p, "pfmTheme") <- ggplot2::theme(
    panel.spacing = grid::unit(0.35, "lines"),
    strip.text = ggplot2::element_text(size = 6.5, margin = ggplot2::margin(1, 0, 1, 0)),
    axis.text = ggplot2::element_text(size = 5.5))

  pfmStamp(p, group, note = paste0(
    "the dashed ceiling and the solid level are DIFFERENT quantities - never join them ",
    "(PITFALLS.md 21)"))
}
