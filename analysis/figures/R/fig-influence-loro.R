# Leave-one-country-out influence — which findings survive dropping any single country.
#
# From the reports' influence-diagnostics exhibit (ADR 0037). With 48 clusters a single
# atypical country can carry a coefficient, and a result that evaporates when Iceland is
# removed is not a result.
#
# THREE states, not two. An earlier version coloured everything with pMax > alpha as
# "fragile", which is wrong: a term that was never significant in the first place (Bulk
# Innovator, p = 0.67) trivially has pMax > alpha, and calling it fragile implies there was
# a finding to lose. The honest classification is:
#
#   not a claim   p >= alpha at full sample        - nothing to be fragile about
#   robust        p < alpha and no pivotal country - claimable
#   PIVOTAL       p < alpha but one country flips it - NOT claimable, and the countries
#                                                     are named on the figure
#
# MODEL.md 2.6: Bulk Horizontal Accountability is pivotal on ISL / PER / ZAF and is
# explicitly not a finding. Naming them is the point - "has a pivotal country" invites the
# reader to wonder which, and the answer is short enough to print.

figInfluenceLoro <- function(group = "v5") {
  inf <- pfmArtifact(group, "influence.rds")
  alpha <- inf$bySector[[1]]$alpha %||% 0.05

  # Prefer the gain/loss split (computeInfluenceDiagnostics, 2026-08-17). Artifacts built
  # before that carry only the union, so derive the split from $path instead of failing -
  # the information is there either way, it was only the summary that collapsed it.
  d <- do.call(rbind, lapply(names(inf$bySector), function(sec) {
    b <- as.data.frame(inf$bySector[[sec]]$byTerm)
    if (!"nPivotalLoss" %in% names(b)) {
      pth <- as.data.frame(inf$bySector[[sec]]$path)
      agg <- function(kind) vapply(b$term, function(tm) {
        paste(pth$cluster[pth$term == tm & pth$crossing %in% kind], collapse = ", ")
      }, character(1))
      b$pivotalLossClusters <- agg("loss")
      b$pivotalGainClusters <- agg("gain")
      b$nPivotalLoss <- lengths(strsplit(b$pivotalLossClusters, ", ")) *
        (nzchar(b$pivotalLossClusters))
      b$nPivotalGain <- lengths(strsplit(b$pivotalGainClusters, ", ")) *
        (nzchar(b$pivotalGainClusters))
    }
    data.frame(sector = sec, term = pfmPrettyTerm(b$term), p = b$p,
               pMin = b$pMin, pMax = b$pMax,
               nLoss = b$nPivotalLoss, loss = trimws(b$pivotalLossClusters),
               nGain = b$nPivotalGain, gain = trimws(b$pivotalGainClusters),
               stringsAsFactors = FALSE)
  }))

  # LOSS and GAIN are opposite findings and are now labelled as such.
  d$state <- ifelse(d$nLoss > 0, "one country destroys it",
             ifelse(d$p < alpha, "robust",
             ifelse(d$nGain > 0, "one country suppresses it", "not a claim")))
  d$state <- factor(d$state, levels = c("robust", "one country destroys it",
                                        "one country suppresses it", "not a claim"))
  d$term <- factor(d$term, levels = unique(d$term[order(-d$pMax)]))
  d$lab <- ifelse(d$nLoss > 0, paste0("− ", d$loss),
           ifelse(d$nGain > 0, paste0("+ ", d$gain), ""))

  # Label gutter: p is bounded above by 1, so anything right of 1 is free space. Labels sit
  # at a FIXED x so they form a column instead of tracking each bar's end.
  labX <- 1.6
  xhi  <- 30000
  xlo  <- min(d$pMin, na.rm = TRUE) * 0.4

  # Exponent tick labels. Plain decimals collided ("0.000001" next to "0.001") and
  # scientific notation as text is barely better; 10^-6 is one glyph-stack wide.
  expLab <- function(x) {
    e <- round(log10(x))
    parse(text = ifelse(e == 0, "1", paste0("10^", e)))
  }

  p <- ggplot2::ggplot(d, ggplot2::aes(y = term)) +
    ggplot2::geom_vline(xintercept = alpha, linetype = "22", colour = pfmRail(),
                        linewidth = 0.4) +
    ggplot2::geom_vline(xintercept = labX / 1.35, colour = "grey85", linewidth = 0.3) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = pMin, xmax = pMax, colour = state),
                            linewidth = 1.1, alpha = 0.85) +
    ggplot2::geom_point(ggplot2::aes(x = p, colour = state), size = 1.9) +
    # colour follows the STATE, not a fixed red: for a term that is not significant at
    # full sample, "pivotal" means removing that country would MAKE it significant - the
    # opposite reading - so it must not be styled like a lost finding.
    ggplot2::geom_text(ggplot2::aes(x = labX, label = lab, colour = state), hjust = 0,
                       size = 2.2, fontface = "bold", show.legend = FALSE) +
    ggplot2::facet_wrap(~ sector, scales = "free_y") +
    ggplot2::scale_colour_manual(
      values = c("robust" = pfmAccent(), "one country destroys it" = pfmRail(),
                 "one country suppresses it" = "#B8860B", "not a claim" = "grey72"),
      drop = FALSE) +
    ggplot2::scale_x_log10(limits = c(xlo, xhi), breaks = 10^seq(-8, 0, by = 2),
                           labels = expLab, expand = ggplot2::expansion(mult = 0)) +
    ggplot2::guides(colour = ggplot2::guide_legend(nrow = 2)) +
    ggplot2::labs(
      title = "What survives dropping any single country",
      subtitle = paste0("Point is the full-sample p; the bar spans all 48 ",
                        "leave-one-country-out refits.\nDashed line is alpha = ", alpha,
                        ".
− marks a country whose removal DESTROYS a finding;",
                        " + marks one whose removal would CREATE",
                        "
significance - opposite meanings, and only the first is a",
                        " fragility."),
      x = "cluster-robust p-value", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group)
}
