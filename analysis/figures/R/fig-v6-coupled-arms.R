# Every v6 sensitivity arm of the rule-B quantity headline, EU21, theta = 0.50: extra cumulative CO2 by
# 2100 against the held-price null, grouped by what the arm tests, against the deployed run (design note
# 0005 Phase 5). The arms are picked up from coupled-facts.json `arms` (each recorded the options its last
# PFM call ran with), so the figure cannot show an arm the batch did not run.

figV6CoupledArms <- function(group = "v6", resolution = "EU21") {
  j <- pfmArtifact(group, "coupling/coupled-facts.json")
  A <- j$arms[[resolution]]; dep <- j$ruleB[[resolution]]$delta[["0.50"]]
  fam <- list(
    "declared closure κ" = c(`κ 0.02` = "Bfix-kappa02", `κ 0.027` = "Bfix-kappa", `κ 0.05` = "Bfix-kappa05"),
    "ranking u" = c(uniform = "Bfix-uniform", `permuted 1` = "Bfix-permuted1", `permuted 2` = "Bfix-permuted2",
                    `permuted 3` = "Bfix-permuted3", reversed = "Bfix-reversed"),
    "uncovered countries" = c(`all median` = "Bfix-allmedian", `all low` = "Bfix-alllow", `nearest donors` = "Bfix-nearest",
                              `USA donor` = "Bfix-usadonor", `USA low` = "Bfix-usalow"),
    "specification" = c(`saturation 0.5×` = "Bfix-sat05", `saturation 2×` = "Bfix-sat2",
                        `family B` = "Bfix-specalt", `annual data` = "Bfix-annual"),
    "formulation" = c(`static share (E-hold)` = "Bfix-Ehold", `hold 2060` = "Bfix-hold2060", `regional k` = "Bfix-regk"))
  d <- do.call(rbind, lapply(names(fam), function(f) {
    k <- fam[[f]]; k <- k[k %in% names(A)]
    if (!length(k)) return(NULL)
    data.frame(family = f, arm = names(k), delta = vapply(k, function(x) A[[x]]$delta, 0))
  }))
  held <- j$ruleB[[resolution]]$held$delta
  d <- rbind(d, data.frame(family = "formulation", arm = "institutions held", delta = held))
  d$family <- factor(d$family, levels = names(fam))
  d <- d[order(d$family, d$delta), ]
  d$arm <- factor(paste(d$family, d$arm, sep = "|"), levels = paste(d$family, d$arm, sep = "|"))

  p <- ggplot2::ggplot(d, ggplot2::aes(delta, arm)) +
    ggplot2::geom_vline(xintercept = dep, colour = pfmAccent(), linewidth = 0.6) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60", linewidth = 0.3) +
    ggplot2::geom_segment(ggplot2::aes(x = dep, xend = delta, yend = arm), colour = "grey70", linewidth = 0.4) +
    ggplot2::geom_point(size = 1.9, colour = "grey15") +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%+.0f", delta), hjust = ifelse(delta >= dep, -0.35, 1.35)),
                       size = 2.4, colour = "grey25") +
    ggplot2::facet_grid(family ~ ., scales = "free_y", space = "free_y") +
    ggplot2::scale_y_discrete(labels = function(x) sub("^.*\\|", "", x)) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.1))) +
    ggplot2::geom_text(data = data.frame(family = factor(levels(d$family)[1], levels = levels(d$family)), x = dep,
                                         arm = d$arm[d$family == levels(d$family)[1]][1]),
                       ggplot2::aes(x, arm, label = sprintf("deployed %+.0f", dep)), vjust = -1.4, hjust = -0.05,
                       size = 2.5, colour = pfmAccent(), inherit.aes = FALSE) +
    ggplot2::labs(title = "What moves the quantity headline",
                  subtitle = paste0("Rule B, θ = 0.50, ", resolution, ": extra cumulative CO₂ by 2100 above the held-price null (Gt).\n",
                                    "Each arm changes one choice; the blue line is the deployed run."),
                  x = "extra cumulative CO₂ by 2100 (Gt)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  attr(p, "pfmHeightScale") <- 1.5
  attr(p, "pfmTheme") <- ggplot2::theme(strip.text.y = ggplot2::element_text(angle = 0, hjust = 0, face = "bold"))
  pfmStamp(p, group, note = "coupling/coupled-facts.json (arms)")
}
