# Fig 2c — what the data does and does not identify.
#
# The honesty exhibit, and the one figure here most easily misread.
#
# A raw selection frequency is NOT evidence on its own. The specification menu offers THREE
# accountability options (Horizontal / Vertical / Diagonal) against ONE "none", so a selector
# choosing at random picks "some accountability" 80% of the time purely from the shape of the
# menu. Reading 64% as support for accountability inverts the actual finding.
#
# So this figure plots selection frequency AGAINST the base rate in the candidate pool the
# bootstrap actually draws from. The gap between them is the evidence; the bar alone is not.
#
#   menu -> pool   is the full-sample tournament's verdict (does it belong?)
#   pool -> winner is stability under resampling (is that verdict robust?)

figSelectionStability <- function(group = "v5") {
  b <- pfmArtifact(group, "selection-bootstrap.rds")
  pr <- as.data.frame(b$perResample)

  chOf <- function(x) sub(" .*$", "", sub("^X-[0-9]+ ", "", x))
  poolCh <- chOf(b$pool); winCh <- chOf(pr$winner)
  slotPool <- grepl("[|]", poolCh); slotWin <- grepl("[|]", winCh)

  el <- list(
    list(lab = "Gov. Effectiveness", cond = FALSE,
         pool = grepl("WGIge", poolCh), win = grepl("WGIge", winCh)),
    list(lab = "split actor power", cond = FALSE,
         pool = grepl("splitAP", b$pool), win = grepl("splitAP", pr$winner)),
    list(lab = "ANY accountability", cond = TRUE,
         pool = grepl("HorAcc|VerAcc|DiagAcc", poolCh),
         win  = grepl("HorAcc|VerAcc|DiagAcc", winCh)),
    list(lab = "Rule of Law", cond = TRUE,
         pool = grepl("[|]RoL[|]", poolCh), win = grepl("[|]RoL[|]", winCh)))

  d <- do.call(rbind, lapply(el, function(e) {
    kp <- if (e$cond) slotPool else rep(TRUE, length(poolCh))
    kw <- if (e$cond) slotWin  else rep(TRUE, length(winCh))
    data.frame(element = e$lab, pool = mean(e$pool[kp]), sel = mean(e$win[kw]),
               stringsAsFactors = FALSE)
  }))
  d$gap <- d$sel - d$pool
  d <- d[order(d$pool), ]
  d$element <- factor(d$element, levels = d$element)

  p <- ggplot2::ggplot(d, ggplot2::aes(y = element)) +
    ggplot2::geom_segment(ggplot2::aes(x = pool, xend = sel, yend = element),
                          colour = "grey70", linewidth = 1.1) +
    ggplot2::geom_point(ggplot2::aes(x = pool, shape = "available in the candidate pool"),
                        size = 2.6, colour = "grey45") +
    ggplot2::geom_point(ggplot2::aes(x = sel, shape = "selected by the bootstrap"),
                        size = 2.6, colour = pfmAccent()) +
    ggplot2::geom_text(ggplot2::aes(x = pmax(pool, sel),
                                    label = sprintf("  %.0f%% → %.0f%%", 100*pool, 100*sel)),
                       hjust = 0, size = 2.5, colour = "grey30") +
    ggplot2::scale_shape_manual(values = c("available in the candidate pool" = 1,
                                           "selected by the bootstrap" = 16)) +
    ggplot2::scale_x_continuous(limits = c(0, 1.28),
                                labels = function(x) paste0(round(100 * x), "%")) +
    ggplot2::labs(
      title = "State capability is identified. Accountability is not.",
      subtitle = paste0(
        "Selection frequency across ", b$nResamples, " resamples against the base rate in ",
        "the candidate pool.\nA bar is only evidence if it exceeds what the menu hands out ",
        "for free."),
      x = "share of candidate pool  ·  share of bootstrap winners", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group, note = "selection frequency alone is not evidence — compare to the pool")
}
