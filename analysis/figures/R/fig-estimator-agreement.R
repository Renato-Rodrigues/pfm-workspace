# Do the coefficient SIGNS survive a change of estimator?
#
# The frontier is one estimator among several defensible ones (satP, fractional, beta, levels,
# satP-re, satP-yearFE, levels-twfe). If a term's sign flips when the estimator changes, no
# claim about its direction is safe - and that is a different and harsher test than a p-value,
# which is computed within one estimator.
#
# On v1 only THREE of thirteen terms hold their sign across every estimator that fits them.
# That is the honest headline of this figure, and it constrains what may be said about
# everything else.
#
# WHY BARS AND NOT A GRID. `agreement$signs` is a character string like "++++++-", one mark per
# estimator that produced the term - but terms fitted by fewer estimators (the trend, 5 of 7)
# give shorter strings, and the artifact does not record WHICH estimator each position belongs
# to. Drawing a 7-column grid would silently assert a mapping that is not in the data. Counting
# the signs asserts only what is actually recorded.
#
# The significance count is carried alongside because the two are independent: a term can be
# significant in most estimators and still flip sign (Government Effectiveness is significant
# in 7 of 7 and still flips once), and a sign-stable term can be significant in almost none.

figEstimatorAgreement <- function(group = "v5") {
  ea <- pfmArtifact(group, "estimator-agreement.rds")

  d <- do.call(rbind, lapply(names(ea$bySector), function(sec) {
    a <- as.data.frame(ea$bySector[[sec]]$agreement, stringsAsFactors = FALSE)
    s <- gsub("[^+-]", "", a$signs)
    data.frame(sector = sec, raw = a$term, term = pfmPrettyTerm(a$term),
               nPos = nchar(gsub("-", "", s)), nNeg = nchar(gsub("\\+", "", s)),
               n = a$nEstimators, agree = a$signsAgree,
               nSig = a$nSignificant05, stringsAsFactors = FALSE)
  }))

  # long form: one row per (term, sign) so the bar diverges from zero
  long <- rbind(
    transform(d[d$nNeg > 0, ], count = -d$nNeg[d$nNeg > 0], sign = "negative"),
    transform(d[d$nPos > 0, ], count =  d$nPos[d$nPos > 0], sign = "positive"))

  ord <- stats::aggregate(cbind(agree, nSig) ~ term, d, function(x) mean(as.numeric(x)))
  ord <- ord[order(ord$agree, ord$nSig), ]
  long$term <- factor(long$term, levels = ord$term)
  d$term <- factor(d$term, levels = ord$term)

  nAgree <- sum(d$agree[d$sector == d$sector[1]])
  nTerm <- sum(d$sector == d$sector[1])

  p <- ggplot2::ggplot(long, ggplot2::aes(y = term, x = count, fill = sign)) +
    ggplot2::geom_col(width = 0.62) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey30", linewidth = 0.5) +
    # fixed x so the counts form a clean right-hand column; anchoring them to the end of
    # each bar scatters them across the panel and reads as noise
    ggplot2::geom_text(data = d, inherit.aes = FALSE,
                       ggplot2::aes(y = term, x = max(d$n) + 1.2,
                                    label = sprintf("%d/%d sig", nSig, n)),
                       hjust = 0, size = 2.0, colour = "grey45") +
    ggplot2::facet_wrap(~ sector) +
    ggplot2::scale_fill_manual(values = c(negative = pfmAccent(), positive = pfmRail()),
                               breaks = c("positive", "negative")) +
    ggplot2::scale_x_continuous(breaks = seq(-8, 8, 2), labels = abs(seq(-8, 8, 2)),
                                expand = ggplot2::expansion(mult = c(0.05, 0.30))) +
    ggplot2::labs(
      title = "Most coefficient signs do not survive a change of estimator",
      subtitle = sprintf(paste0(
        "Number of estimators returning a positive or negative coefficient for each term, ",
        "out of up to %d.\nA bar on one side only means the sign is stable — that holds for ",
        "just %d of %d terms in %s.\nThe count beside each bar is how many estimators find ",
        "the term significant at 5%%, which is independent."),
        max(d$n), nAgree, nTerm, d$sector[1]),
      x = "estimators returning that sign", y = NULL)
  attr(p, "pfmGrid") <- "x"
  pfmStamp(p, group,
           note = "sign stability across estimators is a harsher test than a p-value within one")
}
