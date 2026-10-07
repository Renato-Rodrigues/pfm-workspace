# The v6 feasibility shares phi_r(t) = clip(1 - theta k_s(t) u_r): the ranking u is read once, at the
# anchor year, and k moves every region by the same fraction (ADR 0049).
#
# Per sector, regions ordered by u (most constrained at the bottom); each region shows its share at
# 2025 (k = 1) and in 2100 on the 1000 Gt energy system. The order never changes; only the spread
# shrinks or grows with k. Regions whose final energy is mostly assigned rather than observed are
# starred. Arithmetic on two artifacts (the anchor's u, Phase 1's k): nothing is fitted here.

figV6Shares <- function(group = "v6", resolution = "EU21", theta = 0.5, run = "PkBudg1000", years = c(2025, 2050, 2100)) {
  a <- pfmArtifact(group, "phase1/anchors.rds")[[resolution]]
  s <- pfmArtifact(group, "phase1/strength.rds")
  s <- s[s$resolution == resolution & s$run == run & s$year %in% years, c("sector", "year", "k")]
  r <- a$region
  d <- merge(r[, c("sector", "region", "u", "shareObserved")], s, by = "sector")
  d$phi <- pmin(1, pmax(0, 1 - theta * d$k * d$u))
  d$assigned <- d$shareObserved < 0.5
  d$label <- paste0(d$region, ifelse(d$assigned, "*", ""))
  d$sector <- factor(d$sector, levels = c("Bulk", "Diffuse"),
                     labels = c("Electricity & industry (Bulk)", "Buildings & transport (Diffuse)"))
  # one y-order per sector: by u, most constrained at the bottom
  d$key <- paste(d$sector, d$label)
  ord <- unique(d[order(d$sector, -d$u), c("sector", "key")])$key
  d$key <- factor(d$key, levels = ord)
  d$yr <- factor(d$year, levels = years)
  shp <- stats::setNames(c(1, 16, 17)[seq_along(years)], years)
  seg <- stats::aggregate(phi ~ key + sector, d, range)
  seg <- data.frame(key = seg$key, sector = seg$sector, lo = seg$phi[, 1], hi = seg$phi[, 2])

  p <- ggplot2::ggplot(d, ggplot2::aes(phi, key)) +
    ggplot2::geom_segment(data = seg, ggplot2::aes(x = lo, xend = hi, y = key, yend = key),
                          colour = "grey75", linewidth = 0.6, inherit.aes = FALSE) +
    ggplot2::geom_point(ggplot2::aes(shape = yr), colour = pfmAccent(), size = 2) +
    ggplot2::facet_wrap(~sector, scales = "free_y") +
    ggplot2::scale_y_discrete(labels = function(x) sub("^.*\\) ", "", x)) +
    ggplot2::scale_shape_manual(values = shp, name = NULL) +
    ggplot2::scale_x_continuous(limits = c(min(0.4, min(d$phi)), 1)) +
    ggplot2::labs(title = "The ranking is fixed; its strength moves",
                  subtitle = paste0("Feasibility share φ = 1 − θ k(t) u, θ = ", theta, ", ", resolution,
                                    ", ", run, " energy system.\n",
                                    "Regions ordered by u, most constrained at the bottom. * = less than half of the\n",
                                    "region's final energy observed (efficiency assigned by rule)."),
                  x = "feasibility share φ", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group, note = "phase1/anchors.rds, phase1/strength.rds")
}
