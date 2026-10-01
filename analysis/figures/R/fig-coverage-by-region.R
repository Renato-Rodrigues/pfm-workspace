# Fig 4c — how much of each REMIND region the frontier can actually speak about.
#
# The honesty panel for Fig 4. Every regional feasibility share is a weighted aggregate of its
# member countries, and only 48 countries are inside the estimation sample - but those 48 carry
# most of the world's final energy, so the limitation is about the SAMPLE rather than about the
# share of the world the frontier can speak to. For one region it rests on nothing at all.
#
# DO NOT re-quote the CHA number from an artifact written before 2026-08-18. The shares on this
# figure are WEIGHTED, and the weight was broken (PITFALLS.md 20): near-equal country weights
# gave CHA 31.8%, which was read as "China is two-thirds unobserved". China IS in coverage and
# carries 96.2% of CHA's final energy, so the corrected share is close to that and the reading
# is dead. The figure reads whatever the artifact holds; the caption below states its provenance.
#
# Two annotations carry the figure and both are load-bearing elsewhere in the paper:
#   * CHA - a large share of global abatement, and the region the weight defect hit hardest;
#   * USA at 0% - the United States has NO in-coverage share, which is why its feasibility
#     share is pinned by basisOverride = c(USA = "median") and must be reported as a RANGE,
#     not a point (TODO item 6, claims C18). It is also one of the two regions sitting on the
#     theta floor in every coupled run, so two independent fragilities land on the same region.
#
# Distinct from `coverage-three-ways`, which cuts the same limitation by country count and by
# share of world GDP. This one is per REMIND region, which is the resolution phi is assigned at.

figCoverageByRegion <- function(group = "v5", annotate = c("CHA", "USA")) {
  cs <- pfmArtifact(group, "coupling/coupling-summary.rds")
  t <- as.data.frame(cs$tiers)
  t <- t[order(t$inCoverageShare), ]
  t$region <- factor(t$region, levels = t$region)
  t$flag <- t$region %in% annotate

  t$lab <- ifelse(t$flag, sprintf("%.1f%%", 100 * t$inCoverageShare), "")

  p <- ggplot2::ggplot(t, ggplot2::aes(y = region, x = inCoverageShare)) +
    ggplot2::geom_segment(ggplot2::aes(x = 0, xend = inCoverageShare, yend = region,
                                       colour = flag), linewidth = 1.1) +
    ggplot2::geom_point(ggplot2::aes(colour = flag), size = 2) +
    ggplot2::geom_text(ggplot2::aes(label = lab), hjust = -0.25, size = 2.4,
                       colour = pfmRail()) +
    ggplot2::scale_colour_manual(values = c(`FALSE` = pfmMuted(), `TRUE` = pfmRail()),
                                 guide = "none") +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                                limits = c(0, 1),
                                expand = ggplot2::expansion(mult = c(0.01, 0.10))) +
    ggplot2::labs(
      title = "Most of the world's energy is covered; one region is not covered at all",
      subtitle = sprintf(paste0(
        "Share of each REMIND region inside the 48-country estimation sample. ",
        "%d of %d regions are fully covered\nand only %d sit below 20%%. ",
        "The uncovered part inherits a transferred relative gap, never a measured\nceiling. ",
        "China is %.0f%% covered; the United States contributes nothing at all."),
        sum(t$inCoverageShare > 0.999), nrow(t), sum(t$inCoverageShare < 0.2),
        100 * t$inCoverageShare[match("CHA", as.character(t$region))]),
      x = "share of the region inside the estimation sample", y = NULL)
  attr(p, "pfmGrid") <- "x"

  # These shares are WEIGHTED, so they are only as good as the weight (PITFALLS.md 20).
  pfmStamp(p, group, note = pfmWeightNote(cs, ok = paste0(
    "coverage is by construction, not a result - it bounds every regional claim")))
}
