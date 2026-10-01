# Artifact access — the ONLY way a figure reads data.
#
# Two rules this enforces, both from CLAUDE.md:
#   1. Figures are PURE CONSUMERS of Run-Group artifacts. Nothing here fits, selects or
#      recomputes anything. If a figure needs a number that is not in an artifact, the
#      number does not exist yet and the fix belongs in `pfm`, not here.
#   2. Numbers carry their Run-Group. Every read goes through pfmArtifact(group, ...), so
#      a figure can always say which group it came from, and a stamped figure cannot
#      silently mix groups.

#' Resolve the Results Root
#'
#' Honours `PFM_RESULTS_DIR`, then the `pfm.resultsDir` option, then `output/pfm/` beside this
#' repository. Paths resolve against the project root, not the working directory, so the
#' scripts run from anywhere.
figuresResultsRoot <- function() {
  env <- Sys.getenv("PFM_RESULTS_DIR", "")
  if (nzchar(env)) return(normalizePath(env, mustWork = TRUE))
  opt <- getOption("pfm.resultsDir", NULL)
  if (!is.null(opt) && dir.exists(opt)) return(normalizePath(opt, mustWork = TRUE))
  here <- figuresProjectRoot()
  cand <- file.path(here, "output", "pfm")
  if (dir.exists(cand)) return(normalizePath(cand, mustWork = TRUE))
  stop("cannot find the Results Root. Set PFM_RESULTS_DIR or options(pfm.resultsDir=).",
       call. = FALSE)
}

#' The project root — the folder holding analysis/figures/, output/ and docs/
figuresProjectRoot <- function() {
  d <- getOption("pfm.figuresRoot", NULL)
  if (!is.null(d)) return(normalizePath(d, mustWork = TRUE))
  # walk up from this file's directory until output/ and docs/ are both visible
  start <- tryCatch(dirname(dirname(normalizePath(sys.frame(1)$ofile %||% "."))),
                    error = function(e) getwd())
  d <- normalizePath(start, mustWork = FALSE)
  for (i in 1:6) {
    if (dir.exists(file.path(d, "output")) && dir.exists(file.path(d, "docs"))) return(d)
    d <- dirname(d)
  }
  normalizePath(getwd(), mustWork = FALSE)
}

#' Read one artifact from a Run-Group
#'
#' @param group Run-Group name, e.g. "v5".
#' @param path Path within the group, e.g. "frontier.rds" or "coupling/coupling-summary.rds".
#' @return The deserialized artifact, with attribute "pfmGroup" set.
pfmArtifact <- function(group, path) {
  f <- file.path(figuresResultsRoot(), group, path)
  if (!file.exists(f)) {
    stop("artifact not found: ", f,
         "\n  Run-Group '", group, "' may not carry it yet — check docs/TODO.md.",
         call. = FALSE)
  }
  # .json artifacts (coupled-facts, coupled-costs) are read the same way as .rds so a builder
  # never has to know which serialisation an artifact happens to use.
  x <- if (grepl("[.]json$", path)) {
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("reading ", path, " needs the 'jsonlite' package", call. = FALSE)
    }
    jsonlite::fromJSON(f)
  } else readRDS(f)
  attr(x, "pfmGroup") <- group
  attr(x, "pfmPath") <- path
  x
}

#' Which artifacts a Run-Group actually has, for the status report
pfmArtifactExists <- function(group, path) {
  file.exists(file.path(figuresResultsRoot(), group, path))
}

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

#' Is a coupling summary's aggregation weight actually a size variable?
#'
#' Everything region-level in `coupling-summary.rds` — phi, the tier table, inCoverageShare,
#' every price derived from them — is a WEIGHTED aggregate of member countries. Until
#' 2026-08-18 that weight was the normalised-index proxy (max/median 1.4, i.e. near-equal
#' country weights) rather than final energy (417). Artifacts written before the fix carry no
#' `weights` block at all; those written after carry its dispersion.
#'
#' Figures must not silently render a superseded artifact as though it were current, so every
#' figure reading this artifact stamps the answer. Returns a note string for `pfmStamp()`.
#' See PITFALLS.md 20.
#' @param cs A parsed coupling summary.
#' @param ok Note to use when the weight passes.
pfmWeightNote <- function(cs, ok = NULL) {
  disp <- cs$weights$maxOverMedian %||% NA_real_
  if (!is.finite(disp) || disp < 20) {
    return(sprintf(paste0("NOT QUOTABLE - aggregation weight is not size-like (max/median = %s);",
                          " re-run psm-coupling-bound"),
                   if (is.finite(disp)) signif(disp, 3) else "absent"))
  }
  ok %||% sprintf("%s weights", cs$weights$source %||% "size")
}
