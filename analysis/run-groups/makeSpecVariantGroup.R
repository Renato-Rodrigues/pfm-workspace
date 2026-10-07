# Build a Run-Group that PINS an alternative specification, so phi can be re-derived through
# the full pipeline and compared like-for-like.
#
# Why this exists. `analysis/testSectorSpecificSpec.R` answers the question on a laptop, but it
# has to approximate three things the real pipeline does properly:
#   * region aggregation is UNWEIGHTED there (the pipeline weights by final energy, which needs
#     IEA EnergyBalances - absent from data/madrat, present on the cluster);
#   * it uses the last HISTORICAL year (2022) rather than the projected tier year (2025);
#   * it does not model the out-of-coverage transfer, so the USA - 0% covered and one of the
#     two floor regions - is missing entirely.
# Running the real chain removes all three. This script only does the setup.
#
# WHAT IT DOES. Copies a finished Run-Group, then rewrites `selected-models-pfm.yml` in the copy
# so a chosen sector names a different spec. Everything else is inherited, so the only thing
# that differs downstream is the specification - which is the whole point.
#
# It deliberately does NOT run pfm-sweep in the copy: the sweep would re-SELECT and overwrite
# the pin. Start the chain at pfm-frontier.
#
# Usage, from the project root:
#   Rscript analysis/run-groups/makeSpecVariantGroup.R v1 v1-specalt Diffuse "X-0102 WGIge|RoL|HorAcc splitAP lev ctl:GDPq fe:OECDp satAP"
#   sector "both" pins the spec in both sectors (v6 deploys one shared spec); key=value arguments after
#   the spec name override fields of the pinned spec, e.g. the shape of the saturating curve:
#   Rscript analysis/run-groups/makeSpecVariantGroup.R v6 v6-specalt both "X-2079 WGIge|noRoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satInn"
#   Rscript analysis/run-groups/makeSpecVariantGroup.R v6 v6-sat05 both "X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP" apSatScale=0.5
#
# then on the cluster:
#   Rscript -e 'library(pfm); pfmRun(group = "v1-specalt",
#                           steps = c("pfm-frontier","pfm-temporal","pfm-donor",
#                                     "pfm-projection","pfm-coupling-bound","pfm-remind-inputs"),
#                           cluster = "slurm")'
# (pfm-remind-inputs exports output/remind-inputs/<to> for coupled runs whose pfmGroup names the variant.)
#
# pfm-temporal is NOT optional. pfm-coupling-bound reads the political closure rate lambda from
# temporal-validation.rds$bySector$<s>$ecm$metrics$adjustmentSpeed, and that ECM is fitted on
# the SPEC. Copying v1's temporal-validation.rds into the variant instead would pair the
# deployed spec's lambda with the alternative spec's frontier - two specifications inside one
# phi, which is precisely the silent mixing this comparison exists to avoid. Without it the run
# completes and only the last step reports
#     [PFM-BOUND] skipped - missing: temporal-validation.rds
# which is easy to lose in a long log.
#
# CHECK THE LOG LINE "steps to run:". It must read
#     pfm-frontier, pfm-temporal, pfm-donor, pfm-projection, pfm-coupling-bound
# If pfm-projection comes FIRST, the installed pfm predates the 2026-08-18 step-ordering fix:
# startRun()/runPostProcessing() filtered steps with intersect(validSteps, steps), which
# re-sorted any caller's list into DECLARATION order - and pfm-projection was declared second.
# The job then runs the projection before the frontier exists and dies. Reinstall pfm, or
# submit pfm-frontier as its own job first.
#
# and finally diff the two:
#   Rscript analysis/checks/compareSpecVariantPhi.R v1 v1-specalt

makeSpecVariantGroup <- function(from = "v1", to = "v1-specalt", sector = "Diffuse",
                                 specName = NULL, overrides = list(), resultsDir = "output/pfm",
                                 verbose = TRUE) {
  if (is.null(specName)) stop("makeSpecVariantGroup: specName is required.")
  say <- function(...) if (isTRUE(verbose)) cat(..., "\n", sep = "")

  src <- file.path(resultsDir, from)
  dst <- file.path(resultsDir, to)
  if (!dir.exists(src)) stop("makeSpecVariantGroup: no such Run-Group: ", src)
  if (dir.exists(dst)) {
    stop("makeSpecVariantGroup: '", dst, "' already exists. Remove it deliberately rather ",
         "than having this script overwrite a Run-Group.")
  }
  if (!requireNamespace("yaml", quietly = TRUE)) stop("the 'yaml' package is required.")

  # The sweep artifact is what carries every candidate spec config, so the pin has to come
  # from there - not hand-written, or the variant would differ in ways nobody recorded.
  sweep <- readRDS(file.path(src, "sweep.rds"))
  nms <- vapply(sweep$specs, function(z) {
    n <- z[["name"]]; if (is.null(n)) NA_character_ else as.character(n)
  }, character(1))
  hit <- which(nms == specName)
  if (!length(hit)) {
    stop("makeSpecVariantGroup: '", specName, "' is not in ", from,
         "/sweep.rds$specs. Names are matched EXACTLY, including the satAP suffix.")
  }
  cfg <- sweep$specs[[hit[1]]]
  # Field overrides (e.g. apSatScale): recorded in the spec and its name, so the variant is never
  # mistaken for the swept spec.
  if (length(overrides)) {
    for (k in names(overrides)) cfg[[k]] <- overrides[[k]]
    cfg$name <- paste0(cfg$name, " [", paste(names(overrides), unlist(overrides), sep = "=", collapse = ","), "]")
  }

  dir.create(dst, recursive = TRUE)
  # Copy the inputs the downstream steps read; do NOT copy the artifacts they will rewrite,
  # so a stale file cannot masquerade as a fresh one. frontier.rds and temporal-validation.rds
  # are deliberately NOT copied: both are fitted on the spec, and a copied one would put the
  # deployed spec's frontier or lambda underneath the alternative spec's phi.
  keep <- c(basename(pfm:::.pfmSelectedModels(src)), "sweep.rds", "channels-exhaustive.yml", "manifest.json")
  for (f in keep) {
    p <- file.path(src, f)
    if (file.exists(p)) file.copy(p, file.path(dst, f))
  }
  if (dir.exists(file.path(src, "data"))) {
    file.copy(file.path(src, "data"), dst, recursive = TRUE)
  }
  say("copied inputs from ", src, " to ", dst)

  selFile <- pfm:::.pfmSelectedModels(dst)   # the copy keeps the source group's file name
  sel <- yaml::read_yaml(selFile)
  secs <- if (identical(sector, "both")) c("Bulk", "Diffuse") else sector
  old <- character(0)
  for (sec in secs) {
    tag <- paste0("PolicyStringency: ", sec)
    idx <- which(vapply(sel, function(x) identical(x$model_type, tag), logical(1)))
    if (!length(idx)) stop("makeSpecVariantGroup: no '", tag, "' entry in selected-models-pfm.yml")
    old <- c(old, sel[[idx[1]]]$name)
    # keep the deployed entry's estimation settings (estimator, index bound, trend shape)
    keep <- sel[[idx[1]]][intersect(c("estimator", "indexMax", "trendMidpoint", "trendSteepness"), names(sel[[idx[1]]]))]
    cfg$model_type <- tag
    sel[[idx[1]]] <- c(cfg[setdiff(names(cfg), names(keep))], keep)
  }
  old <- unique(old)
  yaml::write_yaml(sel, selFile)

  say("pinned ", sector, ":")
  say("  was: ", old)
  say("  now: ", cfg$name)
  say("\nNext, on the cluster (pfm-sweep is EXCLUDED on purpose - it would re-select and ",
      "overwrite the pin):")
  say("  Rscript -e 'library(pfm); pfmRun(group = \"", to, "\", steps = c(\"pfm-frontier\",",
      "\"pfm-temporal\",\"pfm-donor\",\"pfm-projection\",\"pfm-coupling-bound\",\"pfm-remind-inputs\"), ",
      "cluster = \"slurm\")'")
  say("  pfm-temporal is REQUIRED: pfm-coupling-bound reads lambda from ",
      "temporal-validation.rds, and that ECM is fitted on the spec.")
  say("\nThen: Rscript analysis/checks/compareSpecVariantPhi.R ", from, " ", to)
  invisible(list(from = from, to = to, sector = sector, was = old, now = cfg$name))
}

if (!interactive() && identical(environment(), globalenv())) {
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a) < 4) {
    stop("usage: Rscript analysis/run-groups/makeSpecVariantGroup.R <from> <to> <sector|both> <specName> [key=value ...]")
  }
  kv <- a[-(1:4)]
  ov <- lapply(sub("^[^=]+=", "", kv), function(v) { n <- suppressWarnings(as.numeric(v)); if (is.na(n)) v else n })
  names(ov) <- sub("=.*$", "", kv)
  makeSpecVariantGroup(from = a[1], to = a[2], sector = a[3], specName = a[4], overrides = ov)
}
