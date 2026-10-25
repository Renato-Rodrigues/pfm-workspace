# The quantity headline, coupled: extra cumulative CO2 by 2100 under hold the price (price held at the
# theta = 0 path, cap binding) against the no-politics reference (price held), over the declared severity theta, at both
# resolutions, with the previous version beside it (v5 for v6, v6 for v7; design note 0005 Phase 5 / Phase 6 step 1).
#
# Each version against its OWN null, so REMIND's drift between versions cancels to first order. theta = 0 is zero by
# construction (the null itself). v5's facts carry the headline as headlineQuantity, v6 on as ruleB.

# old = NULL draws the group alone (figure v6-coupled-theta-only, for documents that report v6 only).
figV6CoupledTheta <- function(group = "v6", old = pfmPrevGroup(group)) {
  jn <- pfmArtifact(group, "coupling/coupled-facts.json")
  jo <- if (!is.null(old)) pfmArtifact(old, "coupling/coupled-facts.json")
  d <- do.call(rbind, lapply(c("EU21", "H12"), function(res) {
    b <- jn$ruleB[[res]]
    rbind(data.frame(version = group, resolution = res, theta = c(0, 0.325, 0.5, 0.675),
                     delta = c(0, b$delta[["0.325"]], b$delta[["0.50"]], b$delta[["0.675"]])),
          if (!is.null(old)) {
            dl <- if (!is.null(jo$ruleB)) { q <- jo$ruleB[[res]]$delta; c(q[["0.325"]], q[["0.50"]], q[["0.675"]]) }
                  else { q <- jo$headlineQuantity[[res]]; c(q$deltaTh325, q$delta, q$deltaTh675) }
            data.frame(version = old, resolution = res, theta = c(0, 0.325, 0.5, 0.675), delta = c(0, dl)) })
  }))
  d$version <- factor(d$version, levels = c(group, old))
  lab <- d[d$theta == 0.5, ]; lab$txt <- sprintf("%+.0f", lab$delta)
  # the higher of the two resolutions labelled above its point, the lower below: no collision
  lab$vj <- stats::ave(lab$delta, lab$version, FUN = function(x) ifelse(x == max(x), -0.6, 1.6))
  # the group's labels left of its points, the previous version's right of them: no collision between versions
  lab$hj <- ifelse(lab$version == group, 1.3, -0.3)
  vs <- c(group, old)

  p <- ggplot2::ggplot(d, ggplot2::aes(theta, delta, colour = resolution, linetype = version, shape = version)) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::geom_point(size = 1.8) +
    ggplot2::geom_text(data = lab, ggplot2::aes(label = txt, vjust = vj, hjust = hj), size = 2.6, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = c(EU21 = pfmAccent(), H12 = "#C2571A")) +
    ggplot2::scale_linetype_manual(values = stats::setNames(c("solid", "22")[seq_along(vs)], vs),
                                   guide = if (is.null(old)) "none" else "legend") +
    ggplot2::scale_shape_manual(values = stats::setNames(c(16, 1)[seq_along(vs)], vs),
                                guide = if (is.null(old)) "none" else "legend") +
    ggplot2::scale_x_continuous(breaks = c(0, 0.325, 0.5, 0.675), labels = c("0", "0.325", "0.50", "0.675")) +
    ggplot2::labs(title = "Holding the price: extra CO₂ grows with the declared severity",
                  subtitle = paste0("Hold the price: cumulative CO₂ by 2100 above the no-politics reference (θ = 0), Gt.",
                                    if (!is.null(old)) paste0("\n", group, " against ", old, ", each against its own null.")),
                  x = "severity θ (declared)", y = "extra cumulative CO₂ by 2100 (Gt)")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = if (is.null(old)) "coupling/coupled-facts.json" else paste0("coupling/coupled-facts.json (", old, " and ", group, ")"))
}
figV6CoupledThetaOnly <- function(group = "v6") figV6CoupledTheta(group, old = NULL)
