# Pin one sector's specification inside a Run-Group that ALREADY EXISTS.
#
# Why this exists. `analysis/run-groups/makeSpecVariantGroup.R` copies a Run-Group and pins one sector in
# the copy, and it refuses to write into a destination that exists - correctly, because
# overwriting a Run-Group silently is how a result ends up describing a specification nobody
# recorded. But that makes it impossible to chain: pinning BOTH sectors to the same alternative
# needs a second pin inside the group the first call just created, not a second copy.
#
# This script does exactly the pinning half of that script, in place, and nothing else:
# it reads the candidate config out of the group's own sweep.rds (never hand-written), replaces
# the named sector's entry in selected-models-psm.yml, and prints both entries afterwards so the
# result is visible rather than assumed.
#
# Usage, from the project root:
#   Rscript analysis/run-groups/pinSpecInGroup.R v5-noinc Diffuse "X-2076 WGIge|noRoL|VerAcc bothIncAP lev ctl:Pop.Hyd fe:OECDp"
#
# Typical sequence for a BOTH-SECTOR variant:
#   Rscript analysis/run-groups/makeSpecVariantGroup.R v5 v5-noinc Bulk    "<spec>"   # creates the group
#   Rscript analysis/run-groups/pinSpecInGroup.R          v5-noinc Diffuse "<spec>"   # pins the second sector
#   Rscript -e 'library(pfm); pfmRun(group = "v5-noinc", steps = c("psm-frontier","psm-temporal",
#               "psm-donor","psm-projection","psm-coupling-bound"), cluster = "slurm")'
#   Rscript analysis/checks/compareSpecVariantPhi.R v5 v5-noinc
#
# It REFUSES to pin a group whose fitted artifacts already exist, because a pin applied after
# the fit leaves frontier.rds and temporal-validation.rds describing the previous specification
# while the yml claims the new one - two specifications inside one phi, which is the exact
# failure makeSpecVariantGroup.R exists to prevent. Delete those artifacts deliberately, or
# rebuild the group, and run again.

pinSpecInGroup <- function(group, sector, specName, resultsDir = "output/pfm", force = FALSE,
                           verbose = TRUE) {
  say <- function(...) if (isTRUE(verbose)) cat(..., "\n", sep = "")
  dir <- file.path(resultsDir, group)
  if (!dir.exists(dir)) stop("pinSpecInGroup: no such Run-Group: ", dir)
  if (!requireNamespace("yaml", quietly = TRUE)) stop("the 'yaml' package is required.")

  fitted <- c("frontier.rds", "temporal-validation.rds", "projection.rds")
  present <- fitted[file.exists(file.path(dir, fitted))]
  if (length(present) && !isTRUE(force)) {
    stop("pinSpecInGroup: ", group, " already holds fitted artifacts (",
         paste(present, collapse = ", "), "). Pinning now would leave them describing the ",
         "previous specification while the yml names the new one. Delete them deliberately ",
         "and re-run the chain from psm-frontier, or pass force = TRUE if you are about to.")
  }

  selFile <- file.path(dir, "selected-models-psm.yml")
  swFile  <- file.path(dir, "sweep.rds")
  if (!file.exists(selFile)) stop("pinSpecInGroup: no selected-models-psm.yml in ", dir)
  if (!file.exists(swFile))  stop("pinSpecInGroup: no sweep.rds in ", dir,
                                  " - the pin must come from the sweep, not from hand-written yaml.")

  sweep <- readRDS(swFile)
  nms <- vapply(sweep$specs, function(z) {
    n <- z[["name"]]; if (is.null(n)) NA_character_ else as.character(n)
  }, character(1))
  hit <- which(nms == specName)
  if (!length(hit)) {
    stop("pinSpecInGroup: '", specName, "' is not in ", group,
         "/sweep.rds$specs. Names are matched EXACTLY, including any satAP suffix.")
  }
  cfg <- sweep$specs[[hit[1]]]

  sel <- yaml::read_yaml(selFile)
  tag <- paste0("PolicyStringency: ", sector)
  idx <- which(vapply(sel, function(x) identical(x$model_type, tag), logical(1)))
  if (!length(idx)) stop("pinSpecInGroup: no '", tag, "' entry in ", selFile)

  old <- sel[[idx[1]]]$name
  cfg$model_type <- tag
  sel[[idx[1]]] <- cfg
  yaml::write_yaml(sel, selFile)

  say("pinned ", sector, " in ", group, ":")
  say("  was: ", old)
  say("  now: ", specName)

  # Print every sector entry, so "did both pins land?" is answered by the file rather than by
  # remembering which commands were run.
  after <- yaml::read_yaml(selFile)
  say("\nselected-models-psm.yml now reads:")
  for (e in after) {
    mt <- e$model_type %||% "(no model_type)"
    say("  ", mt, "  ->  ", e$name %||% "(unnamed)")
  }
  invisible(list(group = group, sector = sector, was = old, now = specName))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

if (!interactive() && identical(environment(), globalenv())) {
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a) < 3) {
    stop("usage: Rscript analysis/run-groups/pinSpecInGroup.R <group> <sector> <specName>")
  }
  pinSpecInGroup(group = a[1], sector = a[2], specName = a[3])
}
