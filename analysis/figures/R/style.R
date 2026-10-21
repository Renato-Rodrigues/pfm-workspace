# The report style — shared with the PowerPoint schematics through style/figure-style.json, so a
# chart and a diagram placed side by side in a document have the same palette, font and sizes.
#
# Used by the `doc` render medium (build.R) and the doc figure builders (fig-doc.R). The
# journal and slide media keep theme_pfm(); this is the look of figures in written reports.

figureStyle <- function() {
  f <- file.path(figuresProjectRoot(), "analysis", "figures", "style", "figure-style.json")
  jsonlite::read_json(f)
}

#' A colour from the shared style, as "#RRGGBB"
docColour <- function(key) paste0("#", figureStyle()$colour[[key]])

#' Sector colours of the report style
docSectorColours <- function() {
  s <- figureStyle()$sector
  c(Bulk = paste0("#", s$Bulk), Diffuse = paste0("#", s$Diffuse))
}

#' The report theme: font and sizes from the shared style, applied last (attr "pfmTheme")
theme_doc <- function(grid = c("y", "x", "both", "none")) {
  grid <- match.arg(grid)
  st <- figureStyle(); z <- st$size; fam <- st$font$body
  ink <- paste0("#", st$colour$ink); muted <- paste0("#", st$colour$muted); gl <- paste0("#", st$colour$grid)
  g <- ggplot2::element_line(colour = gl, linewidth = 0.3)
  th <- ggplot2::theme(
    text = ggplot2::element_text(family = fam, colour = ink, size = z$body),
    axis.text = ggplot2::element_text(family = fam, colour = muted, size = z$small),
    axis.title = ggplot2::element_text(family = fam, colour = ink, size = z$body),
    strip.text = ggplot2::element_text(family = fam, colour = paste0("#", st$colour$deep), size = z$title,
                                       face = "bold", hjust = 0.5),
    legend.text = ggplot2::element_text(family = fam, colour = ink, size = z$small),
    legend.title = ggplot2::element_blank(),
    legend.position = "top", legend.justification = "left",
    plot.title = ggplot2::element_text(family = fam, colour = muted, size = z$small, face = "italic", hjust = 0),
    plot.title.position = "plot",
    plot.subtitle = ggplot2::element_blank(), plot.caption = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.x = if (grid %in% c("x", "both")) g else ggplot2::element_blank(),
    panel.grid.major.y = if (grid %in% c("y", "both")) g else ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(4, 14, 4, 4))
  th
}

#' Results figures are marked "Preliminary results" by the document that places them (author, 2026-10-16: an
#' emphasised overlay above the chart in the .docx and PDF, not part of the image). Kept as the one place to change that.
docPreliminary <- function(p) p
