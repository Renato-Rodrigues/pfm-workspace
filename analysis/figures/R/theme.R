# Theme and palette.
#
# These figures have to hold up at 89 mm in a journal column and at A1 on a board. Sizes
# therefore come from the render spec (see build.R) and are applied through `base_size`, so
# one definition scales instead of three definitions drifting.

#' Sector colours — the one distinction that appears on almost every figure
pfmSectorColours <- function() {
  c(Bulk = "#1B6CA8", Diffuse = "#C2571A")
}

#' Sequential accent used for single-series figures
pfmAccent <- function() "#1B6CA8"
pfmMuted  <- function() "grey55"
pfmRail   <- function() "#B02418"   # for annotations that carry a warning

#' Shared theme
#'
#' @param base_size Point size for body text; set by the render spec, not by the builder.
#' @param grid "y" (default), "x", "both" or "none" — most of these figures read along one
#'   axis only, and a full grid is noise at poster size.
theme_pfm <- function(base_size = 9, grid = c("y", "x", "both", "none")) {
  grid <- match.arg(grid)
  th <- ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title      = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.15),
                                              hjust = 0, margin = ggplot2::margin(b = 3)),
      plot.subtitle   = ggplot2::element_text(colour = "grey30", size = ggplot2::rel(0.95),
                                              hjust = 0, margin = ggplot2::margin(b = 6)),
      plot.caption    = ggplot2::element_text(colour = "grey45", size = ggplot2::rel(0.75),
                                              hjust = 0, margin = ggplot2::margin(t = 8)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      axis.title      = ggplot2::element_text(size = ggplot2::rel(0.95)),
      legend.position = "top",
      legend.justification = "left",
      legend.title    = ggplot2::element_blank(),
      legend.key.height = grid::unit(0.8, "lines"),
      strip.text      = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.0)),
      panel.grid.minor = ggplot2::element_blank(),
      plot.margin     = ggplot2::margin(4, 4, 4, 4)
    )
  if (grid == "y") th <- th + ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
  if (grid == "x") th <- th + ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
  if (grid == "none") th <- th + ggplot2::theme(panel.grid.major = ggplot2::element_blank())
  th
}

#' Stamp provenance onto a figure
#'
#' Every rendered figure carries its Run-Group and build date in the caption. The asset
#' outlives the Run-Group and someone will read it against a later one; this is the cheapest
#' possible defence (PITFALLS.md 9).
#'
#' @param p A ggplot.
#' @param group Run-Group.
#' @param note Optional extra text prepended to the stamp — used for the rails that must be
#'   PRINTED rather than spoken, e.g. "PFM-side bound, NOT a coupled result".
pfmStamp <- function(p, group, note = NULL) {
  txt <- paste0(if (!is.null(note)) paste0(note, "  ·  ") else "",
                "Run-Group ", group, "  ·  built ", format(Sys.Date()))
  p + ggplot2::labs(caption = txt)
}
