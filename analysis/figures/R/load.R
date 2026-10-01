# Load the figure layer. This is a directory, not a package, so this is the entry point.
#
#   source("analysis/figures/R/load.R")          # from the project root
#   figuresLoad()                       # or call it explicitly from anywhere
#
# Kept deliberately small: if this grows past sourcing files and checking packages, the
# right move is to make analysis/figures/ a package rather than to make this cleverer.

figuresLoad <- function(dir = NULL) {
  if (is.null(dir)) {
    dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)), error = function(e) NULL)
    if (is.null(dir) || !dir.exists(dir)) {
      cand <- c("analysis/figures/R", "R", "figures/R")
      dir <- cand[dir.exists(cand)][1]
    }
  }
  if (is.na(dir) || !dir.exists(dir)) {
    stop("cannot locate analysis/figures/R — source() this file by path, or pass dir=.", call. = FALSE)
  }
  need <- c("ggplot2")
  missing <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("missing required packages: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  # order matters only in that helpers must precede builders; everything else is flat
  first <- file.path(dir, c("artifacts.R", "theme.R", "registry.R", "build.R"))
  rest <- setdiff(list.files(dir, pattern = "\\.R$", full.names = TRUE),
                  c(first, file.path(dir, "load.R")))
  for (f in c(first, sort(rest))) source(f, local = globalenv())
  invisible(TRUE)
}

if (identical(environment(), globalenv()) ||
    sys.nframe() == 0L || !is.null(sys.frame(1)$ofile)) {
  try(figuresLoad(), silent = TRUE)
}
