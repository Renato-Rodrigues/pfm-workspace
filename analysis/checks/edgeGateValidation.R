# End-to-end check of the interaction weight and the edge-of-data gate (design note 0007) on a Run-Group's data,
# through the package code paths a v7 sweep will use.
#   Rscript analysis/checks/edgeGateValidation.R [group]        (repo root; default v6)
# 1. The V-Dem democracy indices through mrpfm (readVDem/calcVDem subtype "democracy": electoral, liberal, freedom of
#    expression).
# 2. The historical panel with the panel definition's `democracy` key on (panelDataHistorical): every column the
#    group's training panel already has must be unchanged; one column is added.
# 3. The scenario panel of the coupled hold-the-price run with the key on (panelDataScenario): the index is held.
# 4. The selected specification and its democracy-weighted twins (one per index), fitted as frontiers (estimatePolicyStringencyModel,
#    estimator "frontier"), and scored by the sanity walk's ceiling trajectory with the edge gate at its defaults.
# The group's madrat cache is COPIED to a temporary folder first, so its pinned files are never touched.
# Writes output/pfm/<group>/edge-gate-validation.rds.
source("analysis/_common/_loadPfm.R")
suppressMessages({ pkgload::load_all("models/mrpfm", quiet = TRUE); library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v6"
GD <- file.path("output/pfm", g)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
cache <- file.path(tempdir(), paste0("madrat-", g)); dir.create(cache, showWarnings = FALSE)
invisible(file.copy(list.files(file.path("data/madrat", g), full.names = TRUE), cache, overwrite = TRUE))
src <- Filter(dir.exists, unlist(rc$madrat$sourcefolder %||% rc$sourcefolder))[1]
setConfig(cachefolder = cache, forcecache = TRUE, sourcefolder = src, .verbose = FALSE)
say <- function(...) message("[edge-validation:", g, "] ", ...)

# 1. the index
dem <- calcOutput("VDem", subtype = "democracy", aggregate = FALSE)
v <- as.array(dem[c("CHN", "SAU", "RUS", "IND", "HUN", "DEU", "USA"), 2023, ])[, 1, ]
WEIGHTS <- c(poly = "Electoral Democracy (VDem)", libdem = "Liberal Democracy (VDem)", fexp = "Freedom of Expression (VDem)")
for (wv in WEIGHTS) say(wv, " 2023: ", paste(rownames(v), round(v[, wv], 3), collapse = ", "))

# 2. historical panel, key on, against the group's training panel
options(pfm.panel = c(pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")], democracy = TRUE))
modelDir <- rc$modelDir %||% "output/pfm/fit-cache"
old <- loadTrainingPanel(jsonlite::read_json(file.path(GD, "manifest.json"))$panel_hash, modelDir)
say("building the historical panel with the democracy key ...")
hist <- panelDataHistorical(aggregate = TRUE, outputRegionMappingFile = "country", includePolicyStringency = TRUE)   # as runPFMSweep builds it
added <- setdiff(getNames(hist), getNames(old)); common <- intersect(getNames(old), getNames(hist))
say("training panel ", paste(dim(old), collapse = " x "), " | rebuilt ", paste(dim(hist), collapse = " x "),
    " | only in the training panel: ", paste(setdiff(getNames(old), getNames(hist)), collapse = ", "))
cc <- intersect(getItems(old, 1), getItems(hist, 1)); yy <- intersect(getYears(old), getYears(hist))
dmax <- max(abs(as.array(old[cc, yy, common]) - as.array(hist[cc, yy, common])), na.rm = TRUE)
say("columns added: ", paste(added, collapse = ", "), " | max |difference| on the ", length(common), " existing columns: ", signif(dmax, 3))

# 3. scenario panel of the coupled hold-the-price run, key on
runs <- readRDS(file.path(GD, "coupling/coupled-runs.rds"))$runs
r <- runs[!runs$superseded & runs$resolution == "EU21" & grepl("PkBudg1000-PFMlevelBfix-v6$", runs$scenario), ][1, ]
gdx <- file.path("output/remind-runs", g, "EU21", r$dir, "fulldata.gdx")
say("building the scenario panel of ", r$scenario, " ...")
scen <- panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                          outputRegionMappingFile = "country", ssp = "SSP2", institutions = "storyline")
saveRDS(scen, file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, "-democracy.rds")))   # for the v7 checks (RUNNING 6a)
for (wv in WEIGHTS) {
  ds <- scen[c("CHN", "IND", "DEU"), c(2030, 2050, 2100), wv]
  say(wv, " in the scenario (held): ", paste(apply(as.array(ds)[, , 1], 1, function(x) paste(round(x, 3), collapse = "/")), collapse = "; "))
}

# 4. the selected spec and its weighted twin, as the sanity walk scores them
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
res <- list()
for (sec in c("Bulk", "Diffuse")) {
  cfg <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  for (nm in c("selected", names(WEIGHTS))) {
    cf <- cfg; if (nm != "selected") cf$interactionWeight <- WEIGHTS[[nm]]
    ct <- pfm:::.pfmCeilingTrajectory(cf, sec, hist, scen, modelDir = NULL, indexMax = 10,
                                      edgeGate = pfm:::.pfmEdgeGateDefaults())
    fit <- do.call(estimatePolicyStringencyModel, c(list(data = hist, sector = sec, estimator = "frontier", indexMax = 10,
                                                        modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cf)))
    b <- stats::coef(fit$model)
    res[[paste(sec, nm)]] <- list(sector = sec, spec = nm, gamma = ct$gamma, ceilingRatio = ct$ratio, edge = ct$edge,
                                  logLik = as.numeric(stats::logLik(fit$model)), beta = b)
    say(sec, " ", nm, ": n ", nrow(fit$data), " | gamma ", round(ct$gamma, 4), " | ceiling 2100/2025 ", round(ct$ratio, 3),
        " | logLik ", round(as.numeric(stats::logLik(fit$model)), 1), " | edge gate ",
        if (isTRUE(ct$edge$pass)) "PASS" else "FAIL", " - ", ct$edge$detail)
  }
  k <- "Incumbent.Power_x_Vertical.Accountability..VDem."
  say(sec, ": fossil x accountability ", round(res[[paste(sec, "selected")]]$beta[[k]], 3), " -> weighted ",
      paste(names(WEIGHTS), vapply(names(WEIGHTS), function(n) round(res[[paste(sec, n)]]$beta[[k]], 3), numeric(1)),
            collapse = ", "))
}
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), index2023 = v, columnsAdded = added,
             existingColumnsMaxDiff = dmax, scenarioRun = r$scenario, fits = res),
        file.path(GD, "edge-gate-validation.rds"))
