# Why rule C relocates less in v6: the constrained regions' carbon price, relative to the theta = 0 run,
# over time, v5 against v6 (design note 0005 Phase 6 step 1).
#
# In v5 the share was held fixed after 2035, so the constrained regions kept a cheaper price to 2100 and
# emitted more there, which China's power sector absorbed. In v6 the strength k(t) fades, and their
# price returns to the null's by about 2070. CHA's two markets are shown separately: its power market
# is unconstrained in both versions, its diffuse market became the most constrained in v6.

figV6PriceCatchup <- function(group = "v6", old = "v5", resolution = "EU21") {
  sel <- data.frame(region = c("REF", "MEA", "SSA", "IND", "CHA", "CHA"),
                    market = c("ETS", "ETS", "ETS", "ETS", "ETS", "ES"))
  one <- function(g, suffix) {
    P <- pfmArtifact(g, "coupling/coupled-runs.rds")$prices
    pre <- if (resolution == "EU21") "SSP2-EU21-" else "SSP2-"
    a <- P[P$resolution == resolution & P$scenario == paste0(pre, "PkBudg1000-PFMlevelC", suffix) & P$year >= 2025 & P$year <= 2100, ]
    b <- P[P$resolution == resolution & P$scenario == paste0(pre, "PkBudg1000-PFMgate", suffix), ]
    m <- merge(a, b, by = c("region", "year"), suffixes = c("", ".0"))
    do.call(rbind, lapply(seq_len(nrow(sel)), function(i) {
      x <- m[m$region == sel$region[i], ]; col <- if (sel$market[i] == "ETS") "ets" else "es"
      data.frame(version = g, panel = paste(sel$region[i], if (sel$market[i] == "ETS") "power & industry (ETS)" else "buildings & transport (ES)"),
                 year = x$year, ratio = x[[col]] / x[[paste0(col, ".0")]])
    }))
  }
  d <- rbind(one(group, "-v6"), one(old, ""))
  d <- d[is.finite(d$ratio), ]
  d$version <- factor(d$version, levels = c(group, old))
  d$panel <- factor(d$panel, levels = unique(d$panel))

  p <- ggplot2::ggplot(d, ggplot2::aes(year, ratio, linetype = version, colour = version)) +
    ggplot2::geom_hline(yintercept = 1, colour = "grey55", linewidth = 0.4) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::facet_wrap(~panel, ncol = 3) +
    ggplot2::scale_colour_manual(values = stats::setNames(c(pfmAccent(), "grey45"), c(group, old))) +
    ggplot2::scale_linetype_manual(values = stats::setNames(c("solid", "22"), c(group, old))) +
    ggplot2::scale_x_continuous(breaks = c(2030, 2050, 2070, 2100)) +
    ggplot2::labs(title = "In v6 the constrained regions' price catches up by about 2070",
                  subtitle = paste0("Rule C, θ = 0.50, ", resolution, ": carbon price over the θ = 0 run's, by market.\n",
                                    "Below 1, the region pays less than in the unconstrained run and emits more."),
                  x = NULL, y = "price relative to the θ = 0 run")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "coupling/coupled-runs.rds (v5 and v6)")
}
