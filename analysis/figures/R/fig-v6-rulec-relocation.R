# Hold the budget: how much abatement moves between regions, before and after 2050, in v5 and v6
# and under the v6 erosion runs (design note 0005 Phase 6 step 1; analysis/v6/ruleCRelocationDecomp.R).
#
# Gross relocation = 1/2 sum over regions of |change in cumulative GHG| against the no-politics reference (theta = 0), per
# period. The drop from v5 to v6 sits almost entirely after 2050, and the kappa sensitivity runs shrink it further,
# dose by dose: the post-2050 relocation is what a fading strength removes.

# withOld = FALSE drops the v5 bar and names the cases by how long the political limit lasts
# (figure v6-rulec-relocation-only, for documents that report v6 only).
figV6RulecRelocation <- function(group = "v6", withOld = TRUE) {
  dc <- pfmArtifact(group, "coupling/rulec-relocation-decomp.rds")
  s <- dc$summary
  g <- dc$groups[2]; o <- dc$groups[1]   # the decomposition's own pair (ruleCRelocationDecomp.R <old> <new>)
  arm <- function(x) paste0(g, " C-", x)
  lab <- if (withOld) stats::setNames(c(o, paste0(g, ", fading limit"), paste0(g, ", constant limit (k ≈ 1)"),
                                        paste0(g, ", + erosion 2%"), paste0(g, ", + erosion 2.7%"), paste0(g, ", + erosion 5%")),
                                      c(o, g, arm("Ehold"), arm("kappa02"), arm("kappa"), arm("kappa05")))
         else stats::setNames(c("growing limit", "constant limit", "fading limit", "fading + erosion 2% a year",
                                "fading + erosion 2.7% a year", "fading + erosion 5% a year"),
                              c(arm("backslide"), arm("Ehold"), g, arm("kappa02"), arm("kappa"), arm("kappa05")))
  s <- s[s$group %in% names(lab), ]
  lab <- lab[names(lab) %in% s$group]
  d <- rbind(data.frame(case = s$group, resolution = s$res, period = "2020–2050", gross = s$gross2050),
             data.frame(case = s$group, resolution = s$res, period = "2051–2100", gross = s$gross2100))
  d$case <- factor(lab[d$case], levels = rev(unname(lab)))
  d$period <- factor(d$period, levels = c("2051–2100", "2020–2050"))
  # the label is the 2020-2100 figure quoted everywhere else (coupled-costs.json); it is below the sum of
  # the two segments wherever a region's change flips sign between the periods
  tot <- stats::aggregate(gross ~ case + resolution, d, sum)
  tot$century <- s$grossRegion[match(paste(tot$resolution, tot$case), paste(s$res, lab[s$group]))]

  p <- ggplot2::ggplot(d, ggplot2::aes(gross, case, fill = period)) +
    ggplot2::geom_col(width = 0.65) +
    ggplot2::geom_text(data = tot, ggplot2::aes(gross, case, label = sprintf("%.1f", century)), inherit.aes = FALSE,
                       hjust = 0, nudge_x = 1, size = 2.6, colour = "grey20") +
    ggplot2::facet_grid(resolution ~ ., scales = "free_y", space = "free_y") +
    ggplot2::scale_fill_manual(values = c(`2020–2050` = "grey65", `2051–2100` = pfmAccent()),
                               breaks = c("2020–2050", "2051–2100")) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.08))) +
    ggplot2::labs(title = if (withOld && g == "v6") "Holding the budget: v6 moves far less abatement after 2050"
                          else if (withOld) paste0("Holding the budget: abatement moved between regions, ", g, " against ", o)
                          else "Holding the budget: how much abatement moves depends on how long the limit lasts",
                  subtitle = paste0("Hold the budget, θ = 0.50: abatement moved between regions against the θ = 0 run,\n",
                                    "Gt CO₂eq: half the sum of absolute regional changes, per period (bars) and for the century (labels)."),
                  x = "abatement moved between regions (Gt CO₂eq)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group, note = "coupling/rulec-relocation-decomp.rds")
}
figV6RulecRelocationOnly <- function(group = "v6") figV6RulecRelocation(group, withOld = FALSE)
