# Load `pfm` for an analysis script — source this INSTEAD of library(pfm).
#
#   source("analysis/_common/_loadPfm.R")
#
# WHY THIS EXISTS (PITFALLS 23). `library(pfm)` resolves to whatever is INSTALLED,
# which on a workstation can be months behind the working tree. On 2026-08-25 the
# installed build was 0.3.0 while the tree was 0.4.0; the two differ in
# preparePanelData()'s `known_indices`, so every per-capita actor-power driver failed
# to resolve its "|<sector>" suffix and propagateFrontierRungsToPhi.R died with
# "missing from the data: Incumbent Power pc" — a bug already fixed in source.
#
# Dying was the LUCKY outcome. A stale install that merely lacks a later refinement
# runs to completion and writes a plausible artifact from a specification nobody is
# looking at. This is the local twin of PITFALLS 2 (the cluster installs from the git
# remote, so unpushed fixes are invisible there).
#
# So: prefer the source tree, and always ANNOUNCE which build was used, because the
# only defence against a silent version mismatch is seeing the version.
#
# Paths resolve against the REPO ROOT, matching the rest of analysis/ (which already
# does readRDS("output/...") and source("models/pfm/R/...")). Run these scripts from there.

local({
  src <- "pfm"
  hasTree <- dir.exists(src) && file.exists(file.path(src, "DESCRIPTION"))

  if (!hasTree) {
    if (!requireNamespace("pfm", quietly = TRUE)) {
      stop("_loadPfm.R: no pfm source tree at './", src, "' and no installed pfm.\n",
           "  Run from the repository root, or install pfm first.", call. = FALSE)
    }
    suppressWarnings(suppressMessages(library(pfm, character.only = FALSE)))
    message("[pfm] INSTALLED build ", as.character(utils::packageVersion("pfm")),
            " — no source tree at './", src, "'. Verify this is the build you mean.")
    return(invisible(NULL))
  }

  if (!requireNamespace("pkgload", quietly = TRUE)) {
    stop("_loadPfm.R: pkgload is required to load pfm from source.\n",
         "  install.packages('pkgload'), or devtools::install('", src, "') and re-run.",
         call. = FALSE)
  }
  suppressWarnings(suppressMessages(pkgload::load_all(src, quiet = TRUE)))

  # unname(): read.dcf()[1, "Version"] keeps a names attribute ("Version"), and
  # identical() is strict about names -- without this the mismatch note fired on
  # every run, including when the two versions were the same string.
  srcVer <- unname(read.dcf(file.path(src, "DESCRIPTION"))[1, "Version"])
  instVer <- tryCatch(as.character(utils::packageVersion("pfm")), error = function(e) NA_character_)
  message("[pfm] SOURCE ", src, " (", srcVer, ")",
          if (!is.na(instVer) && !identical(instVer, srcVer)) {
            paste0("  — note: the INSTALLED build is ", instVer,
                   ", so `library(pfm)` elsewhere would differ")
          } else "")
  invisible(NULL)
})

# ---------------------------------------------------------------------------
# .panelForGroup() — resolve a Run-Group's OWN panel, or stop
# ---------------------------------------------------------------------------
# Lifted here from propagateFrontierRungsToPhi.R on 2026-08-26 (TODO 14i) so that
# scripts taking a Run-Group argument stop pairing one group's specification with
# another group's panel. That failure is SILENT: both artifacts exist, the fit
# completes, the numbers look fine and are wrong. It cost the 2026-08-25 gamma-gate
# comparison a full run.
#
# Never fall back to output/pfm/fit-cache/panels/<any>.rds. If the panel is not on this machine,
# that is the answer: run it where the Fit Cache lives.
.panelForGroup <- function(group, root = "output/pfm", fitCache = file.path(root, "fit-cache")) {
  mf <- file.path(root, group, "manifest.json")
  if (!file.exists(mf)) {
    stop("no manifest.json for Run-Group '", group, "' - cannot identify its panel. ",
         "Never substitute another group's panel: it produces numbers that look fine ",
         "and are wrong.", call. = FALSE)
  }
  h <- jsonlite::fromJSON(mf)$panel_hash
  if (is.null(h) || !nzchar(h)) {
    stop("manifest.json for '", group, "' records no panel_hash.", call. = FALSE)
  }
  p <- file.path(fitCache, "panels", paste0("panel_", h, ".rds"))
  if (!file.exists(p)) {
    stop("Run-Group '", group, "' was fitted on panel ", h, ", which is NOT on this ",
         "machine (looked for ", p, "). Run this on the cluster, where the Fit Cache ",
         "lives. Do NOT substitute another panel.", call. = FALSE)
  }
  message("[panel] group ", group, " -> ", h)
  readRDS(p)
}

# .scenarioPanelForGroup() — the companion trap, closed the same way (TODO 14i)
# ---------------------------------------------------------------------------
# runPFMCouplingBound() writes the projection panel as
# <resultsDir>/panel-cache/<group>-scen-ca.rds, so it is already group-keyed. Every
# analysis script nonetheless read "v1-scen-ca.rds" by name, which pairs one group's
# SPECIFICATION with another group's SCENARIO panel — the same silent mismatch as
# .panelForGroup(), on the input that decides the ceiling TRAJECTORY rather than the fit.
#
# Stopping is the correct behaviour when the cache is absent: it is written by the
# coupling-bound step, so a missing file means "that step has not run for this group
# here", and the honest response is to say so rather than to project the wrong world.
.scenarioPanelForGroup <- function(group, root = "output/pfm") {
  p <- file.path(root, "panel-cache", paste0(group, "-scen-ca.rds"))
  if (!file.exists(p)) {
    stop("no scenario panel for Run-Group '", group, "' (looked for ", p, "). It is written ",
         "by the pfm-coupling-bound step; run that for this group, or copy the cache from ",
         "the cluster. Do NOT substitute another group's scenario panel.", call. = FALSE)
  }
  message("[scen] group ", group, " -> ", basename(p))
  readRDS(p)
}
