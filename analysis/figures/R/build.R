# The render spec and the build engine.
#
# One builder returns one ggplot. This file decides how big it is, in what format, and for
# whom. That split is the point: a figure is defined once, and the differences between the
# journal column, the slide and the poster stay DECLARATIVE, in the table below, instead of
# spreading as branches through every builder.

#' Render spec — size, device and text size per medium
#'
#' Widths are the real constraints, not preferences:
#'   all              the REVIEW render — one PNG per figure, every figure, always built
#'   paper1 / paper2  Nature-family single (89 mm) and double (183 mm) column
#'   slide            16:9 content area at a comfortable reading size
#'   poster           a panel of the A1 one-pager (docs/PRESENTATION.md 6.2)
#'
#' `all` replaced the old `report` medium on 2026-09-18. Every figure renders there whatever
#' its consumers, so `analysis/figures/output/all/` is the one place to look at everything at once —
#' and `slide` / `poster` are no longer built by default, because four renders of the same
#' plot is three chances for a stale one to be read as current.
#'
#' `base_size` rises with viewing distance, not with figure width — a poster panel is read
#' from ~1.5 m and needs proportionally larger type than a 183 mm journal figure read at
#' arm's length.
renderSpec <- function(medium = NULL) {
  spec <- rbind(
    # cairo_pdf, NOT pdf: the default PDF device cannot encode the UTF-8 this project
    # uses everywhere (theta, en/em dashes, the middot in the provenance stamp). It fails
    # with a *warning*, not an error, and ships a figure with dots where the characters
    # should be - straight into the paper.
    data.frame(medium = "paper1", width_mm =  89, height_mm =  75, base_size =  7,
               device = "cairo_pdf", dpi = 600, stringsAsFactors = FALSE),
    data.frame(medium = "paper2", width_mm = 183, height_mm = 110, base_size =  8,
               device = "cairo_pdf", dpi = 600, stringsAsFactors = FALSE),
    data.frame(medium = "slide",  width_mm = 254, height_mm = 143, base_size = 14,
               device = "png", dpi = 300, stringsAsFactors = FALSE),
    data.frame(medium = "poster", width_mm = 260, height_mm = 180, base_size = 18,
               device = "svg", dpi = 300, stringsAsFactors = FALSE),
    data.frame(medium = "all",    width_mm = 200, height_mm = 120, base_size = 11,
               device = "png", dpi = 150, stringsAsFactors = FALSE)
  )
  if (is.null(medium)) return(spec)
  hit <- spec[spec$medium %in% medium, , drop = FALSE]
  if (!nrow(hit)) stop("unknown medium: ", paste(medium, collapse = ", "),
                       ". Known: ", paste(spec$medium, collapse = ", "), call. = FALSE)
  hit
}

#' Where rendered figures land
figuresOutputDir <- function(medium) {
  file.path(figuresProjectRoot(), "analysis", "figures", "output", medium)
}

#' Build one figure, for one or more media
#'
#' @param id Registry id.
#' @param group Run-Group.
#' @param media Which media to render; default every medium the registry says consumes it.
#' @param write Write files (default) or just return the plot object.
#' @return Invisibly, the ggplot object — so a report or an Rmd can use it directly without
#'   going through a file.
buildFigure <- function(id, group = "v5", media = NULL, write = TRUE, quiet = FALSE) {
  e <- figureEntry(id)
  if (is.na(e$builder)) {
    stop("figure '", id, "' is registered but has no builder yet (status: ", e$status, ").",
         call. = FALSE)
  }
  fn <- get(e$builder, mode = "function")

  if (is.null(media)) {
    # EVERY figure renders to `all` (the review PNG); the paper's figures also render to
    # paper2. slide and poster are deliberately opt-in: they are needed when a deck or the
    # poster is actually built, and rendering them on every run just multiplies the number of
    # files that can go stale. Ask for them with media = "slide" / --media=slide,poster.
    consumers <- strsplit(e$consumers, ",", fixed = TRUE)[[1]]
    media <- unique(c("all", if ("paper" %in% consumers) "paper2"))
  }

  p <- fn(group = group)
  if (!inherits(p, "ggplot")) {
    stop("builder ", e$builder, "() must return a ggplot, got ", class(p)[1], call. = FALSE)
  }
  if (!write) return(invisible(p))

  for (m in media) {
    s <- renderSpec(m)
    # base_size is applied HERE, not in the builder, so one definition serves every size.
    pm <- p + theme_pfm(base_size = s$base_size, grid = attr(p, "pfmGrid") %||% "y")
    # ... which means a theme set INSIDE a builder would be silently overridden. Builders
    # that need theme control attach it as attr(p, "pfmTheme") and it is applied last.
    # The schematic needs this: it carries no data, so showing axes would imply a scale.
    if (!is.null(attr(p, "pfmTheme"))) pm <- pm + attr(p, "pfmTheme")
    dir.create(figuresOutputDir(m), showWarnings = FALSE, recursive = TRUE)
    ext <- sub("^cairo_", "", s$device)
    out <- file.path(figuresOutputDir(m), paste0(id, ".", ext))
    dev <- if (identical(s$device, "cairo_pdf")) grDevices::cairo_pdf else s$device
    ggplot2::ggsave(out, pm, width = s$width_mm, height = s$height_mm, units = "mm",
                    dpi = s$dpi, device = dev, bg = "white")
    if (!quiet) message("  [", m, "] ", out)
  }
  invisible(p)
}

#' Build every figure that has a builder
#'
#' @return A data.frame of id / status / error, so a failure is reported rather than
#'   stopping the run — one broken figure must not block the other nine.
buildAllFigures <- function(group = "v5", media = NULL, consumers = NULL) {
  reg <- figureRegistry(consumers = consumers, status = "built")
  out <- do.call(rbind, lapply(reg$id, function(id) {
    message("[", id, "]")
    err <- tryCatch({ buildFigure(id, group = group, media = media); NA_character_ },
                    error = function(e) conditionMessage(e))
    data.frame(id = id, ok = is.na(err), error = err, stringsAsFactors = FALSE)
  }))
  planned <- figureRegistry(status = "planned")
  if (nrow(planned)) {
    message("\nnot built (no builder yet): ", paste(planned$id, collapse = ", "))
  }
  bad <- out[!out$ok, , drop = FALSE]
  if (nrow(bad)) {
    message("\nFAILED: ", nrow(bad), " of ", nrow(out))
    for (i in seq_len(nrow(bad))) message("  ", bad$id[i], ": ", bad$error[i])
  } else {
    message("\nall ", nrow(out), " figures built")
  }
  invisible(out)
}

#' The detailed explainer for one figure, as markdown
#'
#' This is what makes the registry worth having: the same text feeds the paper caption, the
#' slide notes and the report, so they cannot disagree.
figureExplainer <- function(id, group = "v5") {
  e <- figureEntry(id)
  wrap <- function(x) if (is.na(x)) "_not written yet_" else x
  paste0(
    "### ", e$title, if (!is.na(e$paperId)) paste0(" (", e$paperId, ")") else "", "\n\n",
    "**id** `", e$id, "` · **status** ", e$status,
    " · **sources** `", e$sources, "` · **Run-Group** `", group, "`\n\n",
    "**What it shows.** ", wrap(e$shows), "\n\n",
    "**What to read off it.** ", wrap(e$reads), "\n\n",
    if (!is.na(e$rails)) paste0("> ⚠️ **Rails.** ", e$rails, "\n\n") else "",
    "**Caption (publication format).**\n\n> ", wrap(e$caption), "\n")
}

#' Every explainer, as one markdown document
figureExplainerDocument <- function(group = "v5", consumers = NULL) {
  reg <- figureRegistry(consumers = consumers)
  paste0(
    "# Figure guide — Run-Group `", group, "`\n\n",
    "*Generated by `analysis/figures/R/build.R`. Do not edit: change the registry instead.*\n\n",
    "Built ", format(Sys.Date()), ". ", sum(reg$status == "built"), " of ", nrow(reg),
    " figures have builders.\n\n---\n\n",
    paste(vapply(reg$id, figureExplainer, character(1), group = group), collapse = "\n---\n\n"))
}

#' The contact sheet — every rendered figure on one page
#'
#' `analysis/figures/output/all/` holds one PNG per figure; this writes the page that shows them all in
#' registry order with the title, what it shows and the rails underneath. It exists so "look at
#' every figure at once" is one file to open rather than a directory to scroll, and so a figure
#' is never reviewed without the caveat that travels with it.
#'
#' Written as HTML (opens in any browser, images inline) plus INDEX.md for anything that reads
#' markdown. Both are generated — edit the registry, not these.
figuresContactSheet <- function(group = "v5") {
  dir <- figuresOutputDir("all")
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  reg <- figureRegistry(status = "built")
  reg <- reg[file.exists(file.path(dir, paste0(reg$id, ".png"))), , drop = FALSE]
  esc <- function(x) {
    if (is.na(x)) return("")
    x <- gsub("&", "&amp;", x, fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE); gsub(">", "&gt;", x, fixed = TRUE)
  }
  card <- function(i) paste0(
    "<figure>\n<h2>", esc(reg$title[i]),
    if (!is.na(reg$paperId[i])) paste0(" <span class=\"pid\">", esc(reg$paperId[i]), "</span>") else "",
    "</h2>\n<p class=\"id\"><code>", reg$id[i], "</code> &middot; sources <code>",
    esc(reg$sources[i]), "</code> &middot; used by ", esc(reg$consumers[i]), "</p>\n",
    "<img src=\"", reg$id[i], ".png\" alt=\"", esc(reg$title[i]), "\">\n",
    "<p><b>Shows.</b> ", esc(reg$shows[i]), "</p>\n",
    if (!is.na(reg$rails[i])) paste0("<p class=\"rail\"><b>Rails.</b> ", esc(reg$rails[i]), "</p>\n") else "",
    "</figure>\n")
  html <- c(
    "<!doctype html><html><head><meta charset=\"utf-8\">",
    paste0("<title>PFM figures - ", group, "</title>"),
    "<style>",
    "body{font:14px/1.5 -apple-system,Segoe UI,Roboto,sans-serif;max-width:1000px;margin:2rem auto;padding:0 1rem;color:#222}",
    "h1{font-size:1.6rem} h2{font-size:1.1rem;margin:0 0 .2rem}",
    "figure{margin:0 0 3rem;padding-bottom:2rem;border-bottom:1px solid #e5e5e5}",
    "img{width:100%;height:auto;border:1px solid #eee;background:#fff}",
    ".id{color:#666;font-size:.85rem;margin:.1rem 0 .6rem}",
    ".pid{color:#888;font-weight:400}",
    ".rail{background:#fff6f6;border-left:3px solid #d9534f;padding:.5rem .7rem}",
    "</style></head><body>",
    paste0("<h1>PFM figures &mdash; Run-Group <code>", group, "</code></h1>"),
    paste0("<p>", nrow(reg), " figures, built ", format(Sys.Date()),
           ". Generated by <code>analysis/figures/R/build.R</code> &mdash; edit the registry, not this file.",
           " Full captions: <a href=\"../FIGURE-GUIDE.md\">FIGURE-GUIDE.md</a>.</p>"),
    vapply(seq_len(nrow(reg)), card, character(1)),
    "</body></html>")
  writeLines(html, file.path(dir, "index.html"))

  md <- c(paste0("# PFM figures - Run-Group `", group, "`"), "",
          paste0(nrow(reg), " figures, built ", format(Sys.Date()),
                 ". Generated - edit `analysis/figures/R/registry.R`, not this file."), "",
          unlist(lapply(seq_len(nrow(reg)), function(i) c(
            paste0("## ", reg$title[i],
                   if (!is.na(reg$paperId[i])) paste0(" (", reg$paperId[i], ")") else ""),
            paste0("`", reg$id[i], "` - sources `", reg$sources[i], "`"), "",
            paste0("![", reg$id[i], "](", reg$id[i], ".png)"), "",
            paste0("**Shows.** ", reg$shows[i]),
            if (!is.na(reg$rails[i])) paste0("\n> **Rails.** ", reg$rails[i]) else "", ""))))
  writeLines(md, file.path(dir, "INDEX.md"))
  invisible(file.path(dir, "index.html"))
}
