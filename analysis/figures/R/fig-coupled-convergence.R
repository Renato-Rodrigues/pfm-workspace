# Did phi actually converge in the coupled runs?
#
# Not in the paper's display set, but it settles a question the documents currently answer in
# prose: convergence is DEMONSTRATED in 7 of 14 coupled runs and merely ASSERTED in the other
# 7 (SCENARIOS.md 3.2, TODO item 2). That distinction is hard to believe from a sentence and
# obvious from a picture.
#
# What the distinction is. The coupling stops when max|phi_new - phi_old| falls below
# cm_pfmConvTol = 0.01. A run that needs three PFM calls produces a CONTRACTING SEQUENCE -
# 0.0146 then 0.0001 - which is evidence of convergence. A run that needs only two crosses the
# tolerance on its very first comparison and produces a single number below the line, which is
# consistent with convergence but does not demonstrate it. Neither is a failure; the second is
# simply uninformative, and lowering the tolerance would make it informative.
#
# p45_pfmDelta_iter repeats each value across the Nash iterations between PFM calls, so the
# raw series is a staircase. Consecutive duplicates are collapsed here: what matters is the
# sequence of DISTINCT deltas, one per coupling call.

figCoupledConvergence <- function(group = "v5", tol = 0.002) {  # cm_pfmConvTol since 2026-08-18
  a <- pfmArtifact(group, "coupling/coupled-runs.rds")
  cv <- a$convergence
  if (is.null(cv) || !nrow(cv)) {
    stop("figCoupledConvergence: coupled-runs.rds carries no $convergence.", call. = FALSE)
  }

  # one point per PFM call, not per Nash iteration
  d <- do.call(rbind, lapply(split(cv, list(cv$scenario, cv$resolution), drop = TRUE),
                             function(x) {
    x <- x[order(x$step), ]
    keep <- c(TRUE, abs(diff(x$delta)) > .Machine$double.eps^0.5)
    y <- x[keep, ]
    y$call <- seq_len(nrow(y))
    y
  }))
  rownames(d) <- NULL

  d$run <- sub("^SSP2-(EU21-)?", "", d$scenario)
  nCalls <- stats::aggregate(call ~ run + resolution, d, max)
  names(nCalls)[3] <- "calls"
  d <- merge(d, nCalls, by = c("run", "resolution"))
  d$evidence <- ifelse(d$calls > 1, "contraction shown", "single value below tolerance")

  nShown <- sum(nCalls$calls > 1)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = call, y = delta, group = paste(run, resolution))) +
    ggplot2::geom_hline(yintercept = tol, colour = pfmRail(), linetype = "22",
                        linewidth = 0.4) +
    ggplot2::annotate("text", x = Inf, y = tol, hjust = 1.05, vjust = -0.6, size = 2.2,
                      colour = pfmRail(), label = sprintf("tolerance %g", tol)) +
    ggplot2::geom_line(ggplot2::aes(colour = evidence), linewidth = 0.6, alpha = 0.85) +
    ggplot2::geom_point(ggplot2::aes(colour = evidence, shape = evidence), size = 1.9) +
    ggplot2::facet_wrap(~ resolution) +
    ggplot2::scale_y_log10(labels = function(x) format(x, scientific = FALSE, drop0trailing = TRUE)) +
    ggplot2::scale_x_continuous(breaks = seq_len(max(d$call))) +
    ggplot2::scale_colour_manual(values = c(`contraction shown` = pfmAccent(),
                                            `single value below tolerance` = pfmMuted())) +
    ggplot2::scale_shape_manual(values = c(`contraction shown` = 16,
                                           `single value below tolerance` = 1)) +
    ggplot2::labs(
      title = "Every coupled run converged; only some of them show it converging",
      subtitle = sprintf(paste0(
        "Change in the feasibility share between successive PFM calls, log scale, one line ",
        "per coupled run.\n%d of %d runs make more than one comparison and so exhibit a ",
        "contracting sequence; the rest cross\nthe tolerance on their first comparison. ",
        "That is uninformative, not a failure — lower the tolerance to fix it."),
        nShown, nrow(nCalls)),
      x = "PFM coupling call", y = "max change in φ between calls")
  attr(p, "pfmGrid") <- "y"
  pfmStamp(p, group, note = "a single point below the line is consistent with convergence, not evidence of it")
}
