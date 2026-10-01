# Fig 5b — what political feasibility costs the carbon budget.
#
# THE QUANTITY HEADLINE (TODO 14g, decided 2026-09-17): -PFMlevelBfix against -PFMgateBfix,
# both on the anchor -PFMgate converged to (cm_pfmAnchorFromGdx = on) with budget forcing off.
# The null therefore MEETS the 1000 Gt budget, and the gap is the extra CO2 politics adds to
# that pathway. The earlier pair (-PFMlevelB / -PFMgateB) sat on an unforced $75 path whose
# null already emitted 1710 Gt; it is an SI sensitivity now, drawn by passing run/null.
#
# One number per resolution, and the POINT is that the two agree: EU21 and H12
# are independent aggregations of the world into regions, so their agreeing closely is
# evidence the result is about politics rather than about how the map was drawn. Both
# resolutions therefore belong on ONE panel - splitting them into facets would hide the
# comparison that makes the figure worth printing.
#
# Form: horizontal dumbbell, one row per resolution, null on the left and the constrained
# run on the right, with the gap labelled. The gap is the claim, so it gets the only bold
# text on the figure.
#
# Colour: this is not a categorical identity pair - it is "reference vs treatment". The null
# wears muted ink and the constrained run wears the accent, and BOTH ends are direct-labelled
# so nothing depends on hue.

figCoupledBudgetCost <- function(group = "v5",
                                 run  = "PkBudg1000-PFMlevelBfix",
                                 null = "PkBudg1000-PFMgateBfix") {
  a <- pfmArtifact(group, "coupling/coupled-runs.rds")
  r <- a$runs

  pick <- function(sfx, res) {
    pre <- if (identical(res, "EU21")) "SSP2-EU21-" else "SSP2-"
    v <- r$cum2100[r$scenario == paste0(pre, sfx) & r$resolution == res]
    if (!length(v)) NA_real_ else v[1]
  }

  res <- c("EU21", "H12")
  d <- data.frame(
    resolution = res,
    nullVal = vapply(res, function(x) pick(null, x), numeric(1)),
    runVal  = vapply(res, function(x) pick(run,  x), numeric(1)),
    stringsAsFactors = FALSE)
  d$gap <- d$runVal - d$nullVal
  d$nRegions <- ifelse(d$resolution == "EU21", 21, 12)
  d$lab <- sprintf("%s  (%d regions)", d$resolution, d$nRegions)
  d$lab <- factor(d$lab, levels = rev(d$lab))

  agree <- 100 * abs(diff(d$gap)) / mean(d$gap)

  p <- ggplot2::ggplot(d, ggplot2::aes(y = lab)) +
    ggplot2::geom_segment(ggplot2::aes(x = nullVal, xend = runVal, yend = lab),
                          colour = "grey72", linewidth = 1.4) +
    ggplot2::geom_point(ggplot2::aes(x = nullVal), colour = pfmMuted(), size = 2.6) +
    ggplot2::geom_point(ggplot2::aes(x = runVal),  colour = pfmAccent(), size = 2.6) +
    # the gap is the claim
    ggplot2::geom_text(ggplot2::aes(x = (nullVal + runVal) / 2,
                                    label = sprintf("+%.0f Gt", gap)),
                       vjust = -1.1, size = 3.1, fontface = "bold", colour = "grey15") +
    ggplot2::geom_text(ggplot2::aes(x = nullVal, label = sprintf("%.0f", nullVal)),
                       hjust = 1.25, size = 2.5, colour = "grey35") +
    ggplot2::geom_text(ggplot2::aes(x = runVal, label = sprintf("%.0f", runVal)),
                       hjust = -0.25, size = 2.5, colour = "grey20") +
    ggplot2::annotate("text", x = d$nullVal[1], y = 2.72, hjust = 1.25,
                      label = "no political\nconstraint", size = 2.4, colour = pfmMuted(),
                      lineheight = 0.95) +
    ggplot2::annotate("text", x = d$runVal[1], y = 2.72, hjust = -0.18,
                      label = "political\nceiling applied", size = 2.4,
                      colour = pfmAccent(), lineheight = 0.95) +
    ggplot2::scale_x_continuous(labels = function(x) paste0(round(x)),
                                expand = ggplot2::expansion(mult = c(0.16, 0.16))) +
    # Only two rows, and renderSpec fixes the canvas height per medium, so padding OUTSIDE
    # the rows is what pulls them together - without it the pair floats half a panel apart.
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = c(1.2, 1.2))) +
    ggplot2::labs(
      # computed, never asserted: this title once carried a previous batch's number
      title = sprintf("Political feasibility costs about %.0f-%.0f Gt CO₂", min(d$gap), max(d$gap)),
      subtitle = sprintf(paste0(
        "Cumulative CO₂ 2020-2100 under the level cap, against its matched θ = 0 null on ",
        "the same pinned price path, θ = 0.50.\nThe two region aggregations are independent and ",
        "differ by %.0f%% - agreement in size, not a replication."),
        agree),
      x = "cumulative CO₂ to 2100, Gt", y = NULL)
  attr(p, "pfmGrid") <- "x"

  pfmStamp(p, group,
           note = paste("both runs read the -PFMgate anchor and switch budget forcing off;",
                        "the EU price floor is not applied in this family"))
}
