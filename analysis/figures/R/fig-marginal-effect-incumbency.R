# Fig 2b — does actor power act THROUGH institutions, or around them?
#
# The claim (C9) is that the effect of incumbent power on the ceiling is conditional on state
# capability rather than additive. That is a statement about a marginal effect, not about a
# coefficient, and it cannot be read off the coefficient table:
#
#     d(eta)/d(Incumbent) = beta_Inc + beta_(Inc x GovEff) * GovEff
#
# so its variance is
#
#     Var(beta_Inc) + GovEff^2 Var(beta_Inc:GovEff) + 2 GovEff Cov(beta_Inc, beta_Inc:GovEff)
#
# The covariance term is the one a coefficient table cannot give you, and it is not small:
# at v1 Cov = -0.00119 in Bulk, so ignoring it would overstate the interval where the two
# terms pull together and understate it elsewhere. This figure was BLOCKED until
# runPSMFrontier() started persisting $vcov and $support (2026-08-18).
#
# BOTH INCUMBENCY TERMS, ONE ROW EACH (added 2026-09-18, TODO item 37). The deployed spec is
# `bothIncAP`: incumbency enters twice, as a SHARE of the energy system and PER CAPITA, and the
# two are different claims about how fossil interests bind. Drawing only the share term showed
# half the mechanism, and the half that was drawn was the one whose sign is easier to read.
# Each row carries its own interaction with the moderator; a spec with only one of the two
# (e.g. `splitAPpc`) simply draws one row.
#
# The x-range is the OBSERVED GovEff support, read from the artifact - never an assumed
# +/-3 SD window. MODEL.md 2.7: an interaction evaluated outside the observed joint support is
# extrapolation, not a finding. The interquartile range is marked so a reader can see where
# the data actually are rather than only where they stop.
#
# Note the model carries a SECOND interaction, Incumbent x Horizontal Accountability. It is
# held at its sample mean, which is stated on the figure - the curve is a conditional slice,
# not a total derivative.

figMarginalEffectIncumbency <- function(group = "v5",
                                        focal = NULL,
                                        moderator = "Government.Effectiveness..WGI.",
                                        nGrid = 120L) {
  fr <- pfmArtifact(group, "frontier.rds")

  # RESOLVE the actor-power terms against the spec, do not assume their spelling. `v1`'s X-0370
  # carried `Incumbent.Power`; a `splitAPpc` spec carries `Incumbent.Power.pc` only; the
  # deployed `bothIncAP` spec carries both (ADR 0044). Hardcoding one name made this figure
  # fail on `v4` with "the interaction is not in this spec", which read as a missing term when
  # it was a renamed one. Take whatever variants the spec has that also carry the interaction.
  allTerms <- unique(unlist(lapply(fr$bySector, function(b) b$coefTable$term)))
  stem <- "Incumbent.Power"
  focals <- if (!is.null(focal)) focal else {
    cand <- grep(paste0("^", gsub(".", "\\.", stem, fixed = TRUE), "(\\.[a-z]+)?$"),
                 allTerms, value = TRUE)
    cand[paste0(cand, "_x_", moderator) %in% allTerms]
  }
  if (!length(focals)) {
    stop("figMarginalEffectIncumbency: no incumbency term with an interaction on '", moderator,
         "' in this spec (", fr$spec, ").", call. = FALSE)
  }
  # name the term: a bothIncAP spec carries incumbency twice (share and per capita)
  # SHORT strip labels: the long names are clipped at panel height, and the subtitle already
  # says what "share" and "per capita" mean.
  termLabel <- function(x) if (grepl("[.]pc$", x)) "per capita" else "share"

  d <- do.call(rbind, lapply(focals, function(f) {
    ix <- paste0(f, "_x_", moderator)
    do.call(rbind, lapply(names(fr$bySector), function(sec) {
      b <- fr$bySector[[sec]]
      if (is.null(b$vcov) || is.null(b$support)) {
        stop("figMarginalEffectIncumbency: frontier.rds carries no $vcov/$support for ", sec,
             ". Re-run the frontier step - pfm has persisted these since 2026-08-18.",
             call. = FALSE)
      }
      ct <- b$coefTable
      need <- c(f, ix)
      if (!all(need %in% ct$term)) return(NULL)

      bF <- ct$estimate[ct$term == f]
      bI <- ct$estimate[ct$term == ix]
      V <- b$vcov[need, need, drop = FALSE]

      sup <- b$support[b$support$term == moderator, ]
      z <- seq(sup$min, sup$max, length.out = nGrid)

      me <- bF + bI * z
      va <- V[1, 1] + z^2 * V[2, 2] + 2 * z * V[1, 2]
      se <- sqrt(pmax(va, 0))

      data.frame(sector = sec, term = f, termLabel = termLabel(f), z = z, me = me,
                 lo = me - 1.96 * se, hi = me + 1.96 * se,
                 p25 = sup$p25, p75 = sup$p75, stringsAsFactors = FALSE)
    }))
  }))
  if (is.null(d) || !nrow(d)) {
    stop("figMarginalEffectIncumbency: the incumbency interactions are not in this spec.",
         call. = FALSE)
  }
  # share on top, per capita below - the share term is the one the text leads with
  d$termLabel <- factor(d$termLabel, levels = c("share", "per capita"))
  d$panel <- interaction(d$sector, d$termLabel, drop = TRUE)

  # where the effect is distinguishable from zero, per sector x term
  sig <- do.call(rbind, lapply(split(d, d$panel), function(x) {
    s <- x[x$lo > 0 | x$hi < 0, ]
    data.frame(sector = x$sector[1], termLabel = as.character(x$termLabel[1]),
               any = nrow(s) > 0,
               from = if (nrow(s)) min(s$z) else NA_real_,
               to   = if (nrow(s)) max(s$z) else NA_real_, stringsAsFactors = FALSE)
  }))

  # ONE rect per panel. Mapping the rect over the 120-row grid draws it 120 times and the
  # alpha compounds into a near-opaque block that dominates the panel.
  iqr <- do.call(rbind, lapply(split(d, d$panel), function(x)
    data.frame(sector = x$sector[1], termLabel = x$termLabel[1],
               p25 = x$p25[1], p75 = x$p75[1])))

  p <- ggplot2::ggplot(d, ggplot2::aes(x = z)) +
    ggplot2::geom_rect(data = iqr, inherit.aes = FALSE,
                       ggplot2::aes(xmin = p25, xmax = p75, ymin = -Inf, ymax = Inf),
                       fill = "grey60", alpha = 0.13) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lo, ymax = hi, fill = sector), alpha = 0.18) +
    ggplot2::geom_line(ggplot2::aes(y = me, colour = sector), linewidth = 0.8) +
    # rows = the two incumbency terms, columns = the two sectors. Free y because the two terms
    # are on different scales: a share and a per-capita quantity are not comparable in level,
    # and forcing one axis would flatten whichever row is smaller into a line.
    ggplot2::facet_grid(termLabel ~ sector, scales = "free_y", switch = "y") +
    ggplot2::scale_colour_manual(values = pfmSectorColours(), guide = "none") +
    ggplot2::scale_fill_manual(values = pfmSectorColours(), guide = "none") +
    ggplot2::labs(
      title = "Fossil incumbency bites differently depending on state capability",
      subtitle = paste0(
        "Marginal effect of incumbent power on the ceiling as government effectiveness varies, ",
        "with 95% ML intervals\nfrom the frontier covariance matrix. The deployed spec carries ",
        "incumbency TWICE - as a share of the energy system\nand per capita - and each row is one ",
        "of them. Shaded band is the observed interquartile range of the moderator;\nthe axis ",
        "spans its observed range and stops there. The second interaction is held at its sample mean."),
      x = "government effectiveness (standard deviations from the sample mean)",
      y = "marginal effect on the ceiling (logit scale)")
  attr(p, "pfmGrid") <- "y"
  attr(p, "pfmTheme") <- ggplot2::theme(
    strip.placement = "outside",
    strip.text.y.left = ggplot2::element_text(angle = 90))

  note <- {
    ok <- sig[sig$any, ]
    if (!nrow(ok)) "not distinguishable from zero anywhere in the observed range"
    else if (nrow(ok) == nrow(sig))
      sprintf("distinguishable from zero over part of the range in all %d panels", nrow(sig))
    else paste0("distinguishable from zero over part of the range in: ",
                paste(paste0(ok$sector, "/", ok$termLabel), collapse = ", "))
  }
  pfmStamp(p, group, note = note)
}
