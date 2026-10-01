# The IV result — endogeneity confirmed, causal effect NOT identified.
#
# Not in the paper's display set, and it should be. This is the single most load-bearing
# honesty claim the project makes (MODEL.md 8.1, and the reason every mention of the feedback
# loop must say "conditional scenario accounting" rather than "causes"), and until now it
# existed only as a table in a document. A reader who has just seen the co-evolution schematic
# in Fig 1a needs to see this.
#
# The shift-share instrument is base-year incumbency x leave-one-out global VRE diffusion. It
# is STRONG on the trend rungs (first-stage F ~47 and ~37, far above the conventional 10) and
# the Wu-Hausman test rejects exogeneity overwhelmingly (p ~1e-53). And with all that, the
# 2SLS estimate of the incumbency effect is indistinguishable from zero in every rung.
#
# That combination is the finding: the endogeneity is real, so OLS cannot be read causally -
# and the instrument that establishes this is not powerful enough to replace it. Both halves
# must be on the figure, which is why the first-stage F is printed beside each estimate.
#
# The no-trend rungs are drawn but flagged: their first-stage F falls to 4.6 and 4.9, below
# any usable threshold, so their wider intervals are weak instrumentation and not evidence of
# a larger effect.

figIVNull <- function(group = "v5", focal = "Incumbent.Power") {
  iv <- pfmArtifact(group, "iv.rds")

  d <- do.call(rbind, lapply(names(iv$bySector), function(rung) {
    b <- iv$bySector[[rung]]
    ct <- as.data.frame(b$coefTable)
    hit <- ct[ct$term == focal, ]
    if (!nrow(hit)) return(NULL)
    dg <- unlist(b$ivDiagnostics)
    parts <- strsplit(rung, ".", fixed = TRUE)[[1]]
    data.frame(
      sector = parts[1],
      rung = if (length(parts) > 1 && parts[2] == "noTrend") "no trend" else "with trend",
      est = hit$estimate[1], se = hit$stdError[1], p = hit$pValue[1],
      F1 = unname(dg["statistic1"]), whP = unname(dg["p-value4"]),
      n = b$n, stringsAsFactors = FALSE)
  }))
  if (is.null(d) || !nrow(d)) stop("figIVNull: '", focal, "' not in iv.rds", call. = FALSE)

  d$lo <- d$est - 1.96 * d$se
  d$hi <- d$est + 1.96 * d$se
  d$weak <- d$F1 < 10
  d$lab <- sprintf("first-stage F = %.1f%s", d$F1, ifelse(d$weak, "  ⚠ weak", ""))
  d$row <- factor(paste(d$sector, d$rung, sep = ", "),
                  levels = rev(paste(rep(c("Bulk", "Diffuse"), each = 2),
                                     c("with trend", "no trend"), sep = ", ")))

  p <- ggplot2::ggplot(d, ggplot2::aes(y = row)) +
    ggplot2::geom_vline(xintercept = 0, colour = pfmRail(), linewidth = 0.5) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = lo, xmax = hi, colour = sector),
                            linewidth = 0.7, alpha = 0.85) +
    ggplot2::geom_point(ggplot2::aes(x = est, colour = sector, alpha = weak), size = 2.2) +
    ggplot2::geom_text(ggplot2::aes(x = hi, label = lab), hjust = -0.08, size = 2.2,
                       colour = "grey35") +
    ggplot2::scale_colour_manual(values = pfmSectorColours(), guide = "none") +
    ggplot2::scale_alpha_manual(values = c(`FALSE` = 1, `TRUE` = 0.35), guide = "none") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.08, 0.34))) +
    ggplot2::labs(
      title = "Endogeneity is confirmed; the causal effect is not identified",
      subtitle = sprintf(paste0(
        "2SLS estimate of the incumbent-power effect with 95%% intervals, shift-share ",
        "instrument, n = %d.\nEvery interval crosses zero — while Wu-Hausman rejects ",
        "exogeneity at p ≈ %.0e. The endogeneity is real,\nand the instrument that ",
        "establishes it cannot replace OLS. Faded points are weakly instrumented (F < 10)."),
        d$n[1], min(d$whP, na.rm = TRUE)),
      x = "2SLS estimate of the incumbency effect (logit scale)", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group,
           note = "never write 'causes' near the feedback loop - this is why (MODEL.md 8.1)")
}
