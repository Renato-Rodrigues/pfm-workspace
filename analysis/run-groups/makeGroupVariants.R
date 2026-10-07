# Build and export the Run-Group variants the -PFMlevelBfix-<suffix> / -PFMlevelC-<suffix> scenario rows
# point at (pfmGroup column): GP-14 (v5-specalt, v5-noinc), GP-3(b) (v5-usadonor, v5-usalow),
# GP-10(b) (v5-allmedian, v5-alllow), and - added 2026-09-23 for the paper's GP-23 / GP-24 - the
# phi-OVERRIDE groups (v5-uniform, v5-permuted1..3, v5-chinaseed-EU21, v5-chinaseed-H12).
#
#   cd /p/projects/elevate/WP3.4          # the project root: output/, models/pfm/, output/remind-inputs/ side by side
#   Rscript analysis/run-groups/makeGroupVariants.R  # all six
#   Rscript analysis/run-groups/makeGroupVariants.R v5-usadonor v5-usalow   # only some
#   PFM_VARIANT_BASE=v6 Rscript analysis/run-groups/makeGroupVariants.R v6-nearest   # twins of another base
# On a v6 base (one with phi-anchor.rds) only the assignment twins are built: each twin's anchor is
# REBUILT from its own assignment (pfm-anchor) and checked to differ from the base's - a copied anchor
# would make the twin couple exactly like the base. The phi-override groups do not exist for v6 (the
# ordering tests are the pfmPhiOrdering columns, D15); spec variants come from makeSpecVariantGroup.R.
#
# What it does, per group:
#   * twins of v5 (usadonor, usalow, allmedian, alllow, nearest): copies output/pfm/v5 -> output/pfm/<group> if absent,
#     re-runs ONLY the donor step with the group's basisOverride (or, for -nearest, its matching rule:
#     every uncovered country on its nearest donors, design note 0005 §7a decision 3), and VERIFIES the result - the donor
#     step returns without an error when it cannot find the panel, so a silent no-op is checked for;
#   * all six: exports the REMIND inputs to output/remind-inputs/<group>/ (pfmRun stage "remind"), which is what
#     preparePFM() copies into a run whose pfmGroup names that group;
#   * override groups: a copy of the EXPORTED v5 (output/remind-inputs/v5, exported first if absent) plus a
#     phi-override.yml that pfm::iterativePFM() applies to the regional shares on every coupling call
#     (pfm >= 0.4.1; R/pfmPhiOverride.R). Nothing is re-estimated - the estimation is v5's, and only the
#     shares REMIND receives are replaced: uniform at the sector mean (no ordering), permuted across
#     regions (ordering scrambled, distribution kept), or China held at its 2022-seed reading.
# The coupled run needs nothing else from the group - no projection, no offline bound.

args <- commandArgs(trailingOnly = TRUE)
base <- Sys.getenv("PFM_VARIANT_BASE", "v5")   # the group names below follow the base: v5-allmedian, v6-allmedian ...
remindDir <- "output/remind-inputs"          # beside models/remind_pfm/, i.e. cfg$pfm$source = "../../output/remind-inputs" seen from there
if (!dir.exists(remindDir)) stop("no '", remindDir, "' here - run from the project root (", getwd(), ")")
if (!dir.exists(file.path("output/pfm", base))) stop("no output/pfm/", base, " here - run from the project root")

source("analysis/_common/_loadPfm.R")      # the source tree, not a possibly stale install (PITFALLS 23)
# Where the Run-Groups and the Fit Cache are: config.yml (output/pfm, output/pfm/fit-cache). The donor
# step's own defaults are the pre-2026-10-01 layout (output/), so without this every twin failed with
# "Run-Group 'output/<group>' does not exist" after copying the base (2026-10-07).
local({
  `%||%` <- function(a, b) if (is.null(a)) b else a   # not in base R 4.3
  rc <- pfmResolveConfig("config.yml", group = base, verbose = FALSE)
  options(pfm.resultsDir = rc$resultsDir %||% "output/pfm", pfm.modelDir = rc$modelDir %||% "output/pfm/fit-cache")
})
if (!identical(normalizePath(getOption("pfm.resultsDir"), winslash = "/"), normalizePath("output/pfm", winslash = "/"))) {
  stop("config.yml resultsDir is ", getOption("pfm.resultsDir"), ", but this script copies Run-Groups in output/pfm")
}

unc <- readRDS(file.path("output/pfm", base, "donor-assignment-band-Bulk.rds"))$region
twins <- list(
  usadonor  = c(USA = "donor"),
  usalow    = c(USA = "lowBand"),
  allmedian = stats::setNames(rep("median",  length(unc)), unc),
  alllow    = stats::setNames(rep("lowBand", length(unc)), unc))
names(twins) <- paste0(base, "-", names(twins))
# Twins that change the matching rule rather than the bases: donor-step arguments, the USA override kept.
ruleTwins <- list(nearest = list(qualityQuantiles = c(0.5, Inf)))
names(ruleTwins) <- paste0(base, "-", names(ruleTwins))
exportOnly <- paste0(base, c("-specalt", "-noinc"))

# China's 2022-seed shares (headline frontier rung, equal country weights) from
# output/pfm/v5/frontier-rung-phi.rds, recorded 2026-09-23; checked against the artifact when it is here.
chinaSeed <- list(EU21 = c(Bulk = 0.8618, Diffuse = 0.5558), H12 = c(Bulk = 0.9339, Diffuse = 0.5558))
frp <- file.path("output/pfm", base, "frontier-rung-phi.rds")
if (base == "v5" && file.exists(frp)) {
  a <- readRDS(frp)
  for (r in names(chinaSeed)) for (s in c("Bulk", "Diffuse")) {
    v <- round(unname(a$bySector[[s]]$phi[[r]]$equal$headline["CHA"]), 4)
    if (!isTRUE(all.equal(v, unname(chinaSeed[[r]][s])))) {
      stop("China seed share ", r, "/", s, " is ", v, " in ", frp, ", not ", chinaSeed[[r]][s])
    }
  }
}
yamlSet <- function(v) c("mode: set", "regions:", "  CHA:", sprintf("    Bulk: %.4f", v[["Bulk"]]),
                         sprintf("    Diffuse: %.4f", v[["Diffuse"]]))
overrides <- list(
  uniform        = c("mode: uniform", "value: mean"),
  permuted1      = c("mode: permute", "seed: 1"),
  permuted2      = c("mode: permute", "seed: 2"),
  permuted3      = c("mode: permute", "seed: 3"),
  # China's seed shares are v5's (checked against the artifact above); another base has no recorded value
  "chinaseed-EU21" = if (base == "v5") yamlSet(chinaSeed$EU21),
  "chinaseed-H12"  = if (base == "v5") yamlSet(chinaSeed$H12))
overrides <- Filter(Negate(is.null), overrides)
# A v6 base couples through phi-anchor.rds, and the v6 coupling REFUSES phi-override.yml: its ordering
# tests are the scenario columns pfmPhiOrdering / pfmPhiOrderingSeed (design note 0005 D15), not groups.
# The spec variants (v6-specalt, v6-sat05, v6-sat2) come from makeSpecVariantGroup.R, not from here.
if (file.exists(file.path("output/pfm", base, "phi-anchor.rds"))) { overrides <- list(); exportOnly <- character(0) }
if (length(overrides)) names(overrides) <- paste0(base, "-", names(overrides))

todo <- if (length(args)) args else c(exportOnly, names(twins), names(ruleTwins), names(overrides))
bad <- setdiff(todo, c(exportOnly, names(twins), names(ruleTwins), names(overrides)))
if (length(bad)) stop("unknown group(s): ", paste(bad, collapse = ", "))

expectBasis <- function(ov, sec) {
  a <- readRDS(file.path("output/pfm", g, sprintf("donor-assignment-band-%s.rds", sec)))
  # "donor" keeps the matched blend, so the expected basis is "donor" only where the country was matched
  got <- a$basis[match(names(ov), a$region)]
  want <- ifelse(ov == "donor", "donor", ov)
  data.frame(sector = sec, n = length(ov), mismatches = sum(got != want, na.rm = TRUE),
             missing = sum(is.na(got)), usa = a$basis[a$region == "USA"],
             usaE = round(a$efficiencyRatio[a$region == "USA"], 4))
}

for (g in intersect(todo, names(overrides))) {
  cat("\n==================", g, "(phi override) ==================\n")
  srcDir <- file.path(remindDir, base)
  if (!file.exists(pfm:::.pfmSelectedModels(srcDir))) {
    cat("no exported ", base, " in ", remindDir, " - exporting it first\n", sep = "")
    pfmRun(group = base, stage = "remind", remindDir = remindDir)
  }
  if (file.exists(file.path(srcDir, "phi-override.yml"))) stop(srcDir, " itself carries a phi-override.yml - refusing")
  dst <- file.path(remindDir, g)
  if (dir.exists(dst)) unlink(dst, recursive = TRUE)
  dir.create(dst)
  ok <- file.copy(list.files(srcDir, full.names = TRUE), dst, recursive = TRUE)
  if (!all(ok)) stop("copy of ", srcDir, " to ", dst, " incomplete")
  writeLines(c(paste0("# ", g, ": written by analysis/run-groups/makeGroupVariants.R, ", format(Sys.Date())),
               "# applied by pfm::iterativePFM() (pfm >= 0.4.1) to the regional shares on every coupling call",
               overrides[[g]]), file.path(dst, "phi-override.yml"))
  cat("exported: ", normalizePath(dst), "  [", paste(overrides[[g]], collapse = " | "), "]\n", sep = "")
}
todo <- setdiff(todo, names(overrides))

for (g in todo) {
  cat("\n==================", g, "==================\n")
  if (g %in% c(names(twins), names(ruleTwins))) {
    if (!dir.exists(file.path("output/pfm", g))) {
      cat("copying output/", base, " -> output/", g, "\n", sep = "")
      dir.create(file.path("output/pfm", g))
      ok <- file.copy(list.files(file.path("output/pfm", base), full.names = TRUE, all.files = FALSE),
                      file.path("output/pfm", g), recursive = TRUE)
      if (!all(ok)) stop("copy to output/", g, " incomplete")
    }
    # A v6 base carries phi-anchor.rds, which holds the ranking u built from the BASE's donor
    # assignment. Copied as it is, the twin would export the base's anchor and couple exactly like the
    # base, silently. Remove it here; it is rebuilt from the twin's own assignment below.
    anchorBase <- file.path("output/pfm", base, "phi-anchor.rds")
    v6base <- file.exists(anchorBase)
    if (v6base) unlink(file.path("output/pfm", g, "phi-anchor.rds"))
    f <- file.path("output/pfm", g, c("donor-assignment-band-Bulk.rds", "donor-assignment-band-Diffuse.rds"))
    t0 <- max(file.mtime(f))
    if (g %in% names(twins)) runPFMDonorAssumptions(g, basisOverride = twins[[g]]) else
      do.call(runPFMDonorAssumptions, c(list(g), ruleTwins[[g]]))
    if (max(file.mtime(f)) <= t0) {
      stop("runPFMDonorAssumptions('", g, "') did not rewrite the band assignment - most likely it could ",
           "not find the historical panel (it returns quietly in that case). Nothing was exported.")
    }
    if (g %in% names(twins)) {
      chk <- rbind(expectBasis(twins[[g]], "Bulk"), expectBasis(twins[[g]], "Diffuse"))
      print(chk, row.names = FALSE)
      if (any(chk$mismatches > 0) || any(chk$missing > 0)) stop("the override did not take effect in ", g)
    } else {
      # nearest donors: no recipient left without a donor; only the USA keeps its median override
      chk <- do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) {
        a <- readRDS(file.path("output/pfm", g, sprintf("donor-assignment-band-%s.rds", sec)))
        data.frame(sector = sec, recipients = nrow(a), none = sum(a$donorQuality == "none"),
                   notDonor = paste(a$region[a$basis != "donor"], collapse = ","))
      }))
      print(chk, row.names = FALSE)
      if (any(chk$none > 0) || any(chk$notDonor != "USA")) stop("the nearest-donors rule did not take effect in ", g)
    }
  }
  if (g %in% c(names(twins), names(ruleTwins)) && v6base) {
    pfmRun(group = g, steps = "pfm-anchor")
    af <- file.path("output/pfm", g, "phi-anchor.rds")
    if (!file.exists(af)) stop("pfm-anchor did not write ", af, " - nothing exported")
    a1 <- readRDS(af); a0 <- readRDS(anchorBase)
    if (identical(a1$country, a0$country)) {
      stop(g, ": the rebuilt anchor equals ", base, "'s - the twin's assignment did not reach it. Nothing exported.")
    }
    cat("anchor rebuilt from ", g, "'s own assignment (differs from ", base, "'s)
", sep = "")
  }
  pfmRun(group = g, stage = "remind", remindDir = remindDir)
  marker <- pfm:::.pfmSelectedModels(file.path(remindDir, g))
  if (!file.exists(marker)) stop("export of ", g, " did not produce ", marker)
  cat("exported: ", normalizePath(file.path(remindDir, g)), "\n", sep = "")
}
cat("\nready in ", normalizePath(remindDir), ": ", paste(list.dirs(remindDir, full.names = FALSE, recursive = FALSE), collapse = ", "), "\n", sep = "")
