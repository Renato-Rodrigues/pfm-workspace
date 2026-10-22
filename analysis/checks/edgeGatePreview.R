# The edge-of-data gate on named specifications of a swept Run-Group, offline (design note 0007).
#   Rscript analysis/checks/edgeGatePreview.R <group> <data group> [spec name ...]   (repo root)
# The specs are taken from output/pfm/<group>/sweep.rds (default: the selected one). They are fitted on the
# historical panel built from <data group>'s madrat cache with the V-Dem keys on, and scored by the sanity walk's
# ceiling trajectory on the sweep's gating scenario (the group's manifest `gdx`), with the gate of the group's
# config.yml `sweep: edgeGate`. Written for v7, whose first sweep ran with the gate unable to evaluate
# (2026-10-22): it previews the verdict the gated walk will reach. Writes output/pfm/<group>/edge-gate-preview.rds.
source("analysis/_common/_loadPfm.R")
suppressMessages({ pkgload::load_all("models/mrpfm", quiet = TRUE); library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v7"; dg <- if (length(args) >= 2) args[2] else "v6"
GD <- file.path("output/pfm", g)
say <- function(...) message("[edge-preview:", g, "] ", ...)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
gate <- rc$sweep$edgeGate
sw <- readRDS(file.path(GD, "sweep.rds"))
specs <- stats::setNames(sw$specs, vapply(sw$specs, `[[`, "", "name"))
want <- if (length(args) >= 3) args[-(1:2)] else sw$sanity$PolicyStringency$chosen %||% names(specs)[1]
man <- jsonlite::read_json(file.path(GD, "manifest.json"))
gdx <- sub("^/p/projects/elevate/WP3.4/pfm-workspace/", "", man$gdx$path)

cache <- file.path(tempdir(), paste0("madrat-", dg)); dir.create(cache, showWarnings = FALSE)
invisible(file.copy(list.files(file.path("data/madrat", dg), full.names = TRUE), cache, overwrite = TRUE))
src <- Filter(dir.exists, unlist(rc$madrat$sourcefolder %||% rc$sourcefolder))[1]
setConfig(cachefolder = cache, forcecache = TRUE, sourcefolder = src, .verbose = FALSE)
options(pfm.panel = man$panel)
say("historical panel (", dg, " data, V-Dem keys on) ...")
hist <- panelDataHistorical(aggregate = TRUE, outputRegionMappingFile = "country", includePolicyStringency = TRUE)
say("scenario panel of ", gdx, " ...")
scen <- panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                          outputRegionMappingFile = "country", ssp = "SSP2", institutions = "storyline")
res <- list()
for (nm in want) for (sec in c("Bulk", "Diffuse")) {
  ct <- pfm:::.pfmCeilingTrajectory(specs[[nm]], sec, hist, scen, modelDir = NULL, indexMax = 10, edgeGate = gate)
  res[[paste(nm, sec)]] <- list(spec = nm, sector = sec, gamma = ct$gamma, ratio = ct$ratio, logLik = ct$logLik,
                                edge = ct$edge, beta = ct$beta)
  say(nm, " | ", sec, " | gamma ", round(ct$gamma, 4), " | ceiling 2100/2025 ", round(ct$ratio, 3), " | logLik ",
      round(ct$logLik, 1), " | edge gate ", if (isTRUE(ct$edge$pass)) "PASS" else "FAIL", " - ", ct$edge$detail)
}
saveRDS(list(group = g, dataGroup = dg, gdx = gdx, gate = gate, made = format(Sys.time(), "%Y-%m-%d %H:%M"), fits = res),
        file.path(GD, "edge-gate-preview.rds"))
