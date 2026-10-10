# The v6 quantity headline, coupled: extra cumulative CO2 by 2100 under rule B (price held at the
# theta = 0 path, cap binding) against the held-price null, over the declared severity theta, at both
# resolutions, with v5 beside it (design note 0005 Phase 5 / Phase 6 step 1).
#
# Each version against its OWN null, so REMIND's drift between 3.7.0.dev29 (v5) and 3.7.1 (v6) cancels
# to first order. theta = 0 is zero by construction (the null itself).

figV6CoupledTheta <- function(group = "v6", old = "v5") {
  jn <- pfmArtifact(group, "coupling/coupled-facts.json")
  jo <- pfmArtifact(old, "coupling/coupled-facts.json")
  d <- do.call(rbind, lapply(c("EU21", "H12"), function(res) {
    b <- jn$ruleB[[res]]; q <- jo$headlineQuantity[[res]]
    rbind(data.frame(version = group, resolution = res, theta = c(0, 0.325, 0.5, 0.675),
                     delta = c(0, b$delta[["0.325"]], b$delta[["0.50"]], b$delta[["0.675"]])),
          data.frame(version = old, resolution = res, theta = c(0, 0.325, 0.5, 0.675),
                     delta = c(0, q$deltaTh325, q$delta, q$deltaTh675)))
  }))
  d$version <- factor(d$version, levels = c(group, old))
  lab <- d[d$theta == 0.5, ]; lab$txt <- sprintf("%+.0f", lab$delta)
  # the higher of the two resolutions labelled above its point, the lower below: no collision
  lab$vj <- stats::ave(lab$delta, lab$version, FUN = function(x) ifelse(x == max(x), -0.6, 1.6))

  p <- ggplot2::ggplot(d, ggplot2::aes(theta, delta, colour = resolution, linetype = version, shape = version)) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::geom_point(size = 1.8) +
    ggplot2::geom_text(data = lab, ggplot2::aes(label = txt, vjust = vj), hjust = 1.3, size = 2.6, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = c(EU21 = pfmAccent(), H12 = "#C2571A")) +
    ggplot2::scale_linetype_manual(values = stats::setNames(c("solid", "22"), c(group, old))) +
    ggplot2::scale_shape_manual(values = stats::setNames(c(16, 1), c(group, old))) +
    ggplot2::scale_x_continuous(breaks = c(0, 0.325, 0.5, 0.675), labels = c("0", "0.325", "0.50", "0.675")) +
    ggplot2::labs(title = "Holding the price: extra CO₂ grows with the declared severity",
                  subtitle = paste0("Rule B: cumulative CO₂ by 2100 above the held-price null (θ = 0), Gt.\n",
                                    group, " against ", old, ", each against its own null."),
                  x = "severity θ (declared)", y = "extra cumulative CO₂ by 2100 (Gt)")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "coupling/coupled-facts.json (v5 and v6)")
}
