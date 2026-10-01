# Driver correlations — why the selection bootstrap cannot separate the channels.
#
# The figure form of the correlation tables the old reports carried
# (pfm-reports::kableCorrelationMatrix, one table per driver group). Promoted into the figure
# layer because it is the direct evidence for a claim the paper makes in words: the deployed
# channel set is reselected in only 29.4% of resamples and leads its runner-up by 0.5
# percentage points (claims C17). Collinearity between the institutional channels is WHY, and
# a reader should be able to see it rather than take it on trust.
#
# ONE MATRIX, BOTH SECTORS. The two sectors are fitted on different estimation rows (the
# Estonia PE-coal exclusion hits Bulk), so their correlation matrices are NOT identical - they
# differ by up to 0.225. Showing them as two 12x12 facets would halve the cell size for a
# difference that is mostly small, so instead Bulk is drawn BELOW the diagonal and Diffuse
# ABOVE it, in one grid. Terms are named once on the left axis and numbered; the columns
# repeat the numbers. Naming them on the diagonal was tried and does not fit - a 30-character
# interaction name cannot live in a 1/12th-width tile.
#
# Colour: correlation is POLARITY data, so the scale is diverging - two hues with a neutral
# grey midpoint at r = 0, never a sequential ramp and never a rainbow. The poles are the
# repo's accent and rail colours, validated as a distinguishable pair (CVD dE 21.6 deutan,
# 28.4 normal). Values are printed in every cell, so the encoding is never colour-alone.
#
# Fixed effects are excluded: they are design variables, not drivers, and their correlations
# say something about the region mapping rather than about the theory.

figDriverCorrelations <- function(group = "v5", dropFE = TRUE, digits = 2) {
  fr <- pfmArtifact(group, "frontier.rds")
  secs <- names(fr$bySector)
  cors <- lapply(fr$bySector, `[[`, "correlation")
  if (any(vapply(cors, is.null, logical(1)))) {
    stop("figDriverCorrelations: frontier.rds carries no $correlation. Re-run the frontier ",
         "step - pfm has persisted it since 2026-08-18.", call. = FALSE)
  }

  terms <- rownames(cors[[1]])
  if (isTRUE(dropFE)) terms <- terms[!pfmIsFE(terms)]
  lab <- pfmPrettyTerm(terms)

  lo <- cors[[secs[1]]][terms, terms, drop = FALSE]   # below the diagonal
  hi <- cors[[secs[2]]][terms, terms, drop = FALSE]   # above the diagonal

  n <- length(terms)
  g <- expand.grid(i = seq_len(n), j = seq_len(n))
  g$r <- NA_real_
  g$sector <- NA_character_
  below <- g$i > g$j
  above <- g$i < g$j
  g$r[below] <- lo[cbind(g$i[below], g$j[below])]
  g$r[above] <- hi[cbind(g$i[above], g$j[above])]
  g$sector[below] <- secs[1]
  g$sector[above] <- secs[2]
  g$lab <- ifelse(is.na(g$r), "", sub("^0\\.", ".", sprintf(paste0("%.", digits, "f"), g$r)))
  g$lab <- sub("^-0\\.", "-.", g$lab)

  # Term names live on the Y AXIS, numbered, and the columns repeat the numbers. Putting the
  # names on the diagonal overflows their cells at any realistic figure width - a 30-character
  # interaction name cannot fit in a 1/12th-width tile.
  diag0 <- data.frame(i = seq_len(n), j = seq_len(n),
                      lab = as.character(seq_len(n)), stringsAsFactors = FALSE)
  yLab <- sprintf("%d  %s", seq_len(n), lab)

  strongest <- max(abs(g$r), na.rm = TRUE)

  p <- ggplot2::ggplot(g, ggplot2::aes(x = j, y = i)) +
    ggplot2::geom_tile(ggplot2::aes(fill = r), colour = "white", linewidth = 0.6) +
    ggplot2::geom_text(ggplot2::aes(label = lab), size = 1.9, colour = "grey15") +
    ggplot2::geom_text(data = diag0, ggplot2::aes(label = lab), size = 2.0,
                       colour = "grey45") +
    ggplot2::scale_fill_gradient2(low = pfmAccent(), mid = "grey93", high = pfmRail(),
                                  midpoint = 0, limits = c(-1, 1), na.value = "white",
                                  name = "correlation",
                                  breaks = c(-1, -0.5, 0, 0.5, 1)) +
    ggplot2::scale_y_reverse(expand = ggplot2::expansion(0),
                             breaks = seq_len(n), labels = yLab) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(0),
                                breaks = seq_len(n), position = "top") +
    ggplot2::guides(fill = ggplot2::guide_colourbar(barheight = grid::unit(0.5, "lines"),
                                                    barwidth = grid::unit(7, "lines"))) +
    ggplot2::labs(
      title = "The institutional channels are correlated, which is why selection cannot separate them",
      subtitle = sprintf(paste0(
        "Pearson correlation among model terms on the estimation rows.\n",
        "Below the diagonal: %s. Above: %s. Rows are named on the left; columns repeat ",
        "those numbers.\nStrongest off-diagonal |r| = %.2f. Fixed effects excluded."),
        secs[1], secs[2], strongest),
      x = NULL, y = NULL)
  attr(p, "pfmGrid") <- "none"
  attr(p, "pfmTheme") <- ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = ggplot2::rel(0.72), hjust = 1),
    axis.text.x = ggplot2::element_text(size = ggplot2::rel(0.72)),
    axis.ticks = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank())
  pfmStamp(p, group,
           note = "the two sectors are fitted on different rows, so the halves are not symmetric")
}
