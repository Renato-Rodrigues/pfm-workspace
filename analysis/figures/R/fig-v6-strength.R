# The v6 strength factor k_s(t) = G_s(t) / G_s(2025): how strongly the anchored ranking bites over
# time, on each energy system (design note 0005 D4; COUPLING.md 14).
#
# One panel per sector, one line per REMIND energy system. The reference line k = 1 is "the 2025
# constraint, unchanged"; below it every region moves the same fraction towards phi = 1. OFFLINE:
# the energy systems are fixed REMIND runs (the Phase 1 bases), not a coupled fixed point.

figV6Strength <- function(group = "v6", resolution = "EU21") {
  s <- pfmArtifact(group, "phase1/strength.rds")
  s <- s[s$resolution == resolution & s$run %in% c("NPi", "PkBudg1000"), ]
  if (!nrow(s)) stop("no ", resolution, " NPi / PkBudg1000 rows in phase1/strength.rds", call. = FALSE)
  s$system <- factor(ifelse(s$run == "NPi", "current policies (NPi)", "1000 Gt budget (PkBudg1000)"),
                     levels = c("1000 Gt budget (PkBudg1000)", "current policies (NPi)"))
  s$sector <- factor(s$sector, levels = c("Bulk", "Diffuse"),
                     labels = c("Electricity & industry (Bulk)", "Buildings & transport (Diffuse)"))
  end <- s[s$year == max(s$year), ]
  end$lab <- sprintf("%.2f", end$k)
  # the higher of the two end values sits above its point, the lower below: no collision
  end$vj <- stats::ave(end$k, end$sector, FUN = function(k) ifelse(k == max(k), -0.7, 1.7))

  p <- ggplot2::ggplot(s, ggplot2::aes(year, k, linetype = system)) +
    ggplot2::geom_hline(yintercept = 1, colour = "grey60", linewidth = 0.4) +
    ggplot2::annotate("text", x = min(s$year), y = 1, label = "2025 strength", vjust = -0.6, hjust = 0,
                      size = 2.6, colour = "grey40") +
    ggplot2::geom_line(colour = pfmAccent(), linewidth = 0.7) +
    ggplot2::geom_point(colour = pfmAccent(), size = 1.4) +
    ggplot2::geom_text(data = end, ggplot2::aes(label = lab, vjust = vj), hjust = 0.5, size = 2.6, colour = "grey20",
                       show.legend = FALSE) +
    ggplot2::facet_wrap(~sector) +
    ggplot2::scale_linetype_manual(values = c("solid", "22"), name = NULL) +
    ggplot2::scale_x_continuous(breaks = c(2025, 2050, 2075, 2100), expand = ggplot2::expansion(mult = c(0.03, 0.06))) +
    ggplot2::labs(title = "How strongly the 2023 ranking bites over time",
                  subtitle = paste0("Strength k(t) = mean regional gap / its 2025 value, ", resolution, ".\n",
                                    "Below 1 the constraint relaxes for every region by the same fraction.\n",
                                    "Offline: fixed REMIND energy systems, not a coupled result."),
                  x = NULL, y = "strength k(t)")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "phase1/strength.rds")
}
