# Rule C (budget held): how much abatement moves between regions, before and after 2050, in v5 and v6
# and under the v6 closure arms (design note 0005 Phase 6 step 1; analysis/v6/ruleCRelocationDecomp.R).
#
# Gross relocation = 1/2 sum over regions of |change in cumulative GHG| against the theta = 0 null, per
# period. The drop from v5 to v6 sits almost entirely after 2050, and the kappa arms shrink it further,
# dose by dose: the post-2050 relocation is what a fading strength removes.

figV6RulecRelocation <- function(group = "v6") {
  dc <- pfmArtifact(group, "coupling/rulec-relocation-decomp.rds")
  s <- dc$summary
  lab <- c(v5 = "v5", v6 = "v6 (deployed)", `v6 C-Ehold` = "v6, static share (k ≈ 1)",
           `v6 C-kappa02` = "v6, κ 0.02", `v6 C-kappa` = "v6, κ 0.027", `v6 C-kappa05` = "v6, κ 0.05")
  s <- s[s$group %in% names(lab), ]
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
    ggplot2::labs(title = "Holding the budget: v6 moves far less abatement after 2050",
                  subtitle = paste0("Rule C, θ = 0.50: abatement moved between regions against the θ = 0 run,\n",
                                    "Gt CO₂eq: half the sum of absolute regional changes, per period (bars) and for the century (labels)."),
                  x = "abatement moved between regions (Gt CO₂eq)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group, note = "coupling/rulec-relocation-decomp.rds")
}
