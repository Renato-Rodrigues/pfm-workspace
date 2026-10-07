# The spec band (design note 0005 Phase 2 step 4): every spec that passes the sanity walk of a Run-Group,
# taken through the v6 coupling formulation offline - its frontier, its donor assignment, its anchor and
# k_s(t) on the same energy systems. Answers: is the headline mechanism (k falling on PkBudg1000) a
# property of the deployed spec, or of the band? Separates spec from panel when compared with v6-annual.
#   Rscript analysis/v6/specBand.R [group] [set]    (from the repo root; default v6; after analysis/v6/phase1.R)
#   set: "passing" (default) - the sanity-passing specs; "ceilingRejected" - the pool specs rejected by
#   the ceilingCollapse gate ALONE (design note 0005 C9: what the gate keeps out of the band).
# Each spec gets a scratch Run-Group output/pfm/specband-<group>/s<i>/ (manifest, selected spec, frontier,
# donor assignment); the deployed spec is run through the same path as a control and must reproduce
# <group>/frontier.rds. Output: output/pfm/<group>/phase1/spec-band.rds and a printed summary.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v6"
set <- if (length(args) > 1) args[2] else "passing"
stopifnot(set %in% c("passing", "ceilingRejected"))
sfx <- if (set == "passing") "" else "-ceilingRejected"
GD <- file.path("output/pfm", g); P1 <- file.path(GD, "phase1"); BAND <- file.path("output/pfm", paste0("specband-", g, sfx))
dir.create(BAND, showWarnings = FALSE, recursive = TRUE)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)   # the registry's SSP2 pair (PITFALLS.md 34)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
modelDir <- rc$modelDir %||% "output/pfm/fit-cache"
say <- function(...) message("[specband:", g, "] ", ...)

sweep <- readRDS(file.path(GD, "sweep.rds"))
specByName <- stats::setNames(sweep$specs, vapply(sweep$specs, `[[`, character(1), "name"))
pool <- readRDS(file.path(GD, "sanity-pool.rds"))
passing <- if (set == "passing") pool$verdicts$model[pool$verdicts$pass] else
  pool$verdicts$model[!pool$verdicts$pass & pool$verdicts$severeRules == "ceilingCollapse"]
deployed <- pool$deployed
boot <- readRDS(file.path(GD, "selection-bootstrap.rds"))$specFreqConditional
manifest <- jsonlite::read_json(file.path(GD, "manifest.json"))
panel <- loadTrainingPanel(manifest$panel_hash, modelDir)
selDeployed <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
w <- pfmAssertSizeWeights(pfmCouplingWeights(year = 2025, scenario = "SSP2"), "spec band")
scen <- lapply(c(NPi = "NPi", PkBudg1000 = "PkBudg1000"), function(k) v6ScenPanel(P1, k, BASES[[k]]))
say(length(passing), " sanity-passing spec(s); deployed ", deployed)

ymlFor <- function(spec) lapply(selDeployed, function(e) {
  keep <- e[c("model_type", "estimator", "indexMax", "trendMidpoint", "trendSteepness")]
  s <- spec[setdiff(names(spec), "description")]
  s$controlDrivers <- s$controlDrivers %||% list()
  c(s, keep)
})

res <- list(); regs <- list(); frCheck <- NULL
for (i in seq_along(passing)) {
  nm <- passing[i]; sid <- sprintf("s%02d", i); sd <- file.path(BAND, sid)
  dir.create(sd, showWarnings = FALSE)
  writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE, null = "null"), file.path(sd, "manifest.json"))
  yaml::write_yaml(ymlFor(specByName[[nm]]), file.path(sd, "selected-models-pfm.yml"))
  if (!file.exists(file.path(sd, "frontier.rds")))
    suppressMessages(runPFMFrontier(sid, resultsDir = BAND, modelDir = modelDir, panelData = panel, verbose = FALSE))
  if (!file.exists(file.path(sd, "donor-assignment-band-Bulk.rds")))
    suppressMessages(runPFMDonorAssumptions(sid, resultsDir = BAND, modelDir = modelDir, panelData = panel, verbose = FALSE))
  fr <- readRDS(file.path(sd, "frontier.rds"))
  if (identical(nm, deployed)) {
    ref <- readRDS(file.path(GD, "frontier.rds"))
    frCheck <- vapply(c("Bulk", "Diffuse"), function(s) isTRUE(all.equal(fr$bySector[[s]]$coefTable, ref$bySector[[s]]$coefTable)), logical(1))
  }
  an <- computeAnchorGap(sid, resultsDir = BAND, modelDir = modelDir, weights = w, verbose = FALSE)
  for (run in names(scen)) {
    st <- computeStrengthPath(an, scen[[run]])$strength
    st <- st[st$year %in% c(2035, 2050, 2070, 2100), c("sector", "year", "k")]
    res[[paste(sid, run)]] <- cbind(id = sid, spec = nm, deployed = identical(nm, deployed),
                                    bootWin = { bw <- unname(boot[nm]); if (length(bw) == 0 || is.na(bw)) 0 else bw }, run = run, st)
  }
  gam <- vapply(c("Bulk", "Diffuse"), function(s) { ct <- fr$bySector[[s]]$coefTable; ct$estimate[ct$term == "gamma"] }, numeric(1))
  regs[[sid]] <- cbind(id = sid, spec = nm, gammaBulk = gam[["Bulk"]], gammaDiffuse = gam[["Diffuse"]],
                       an$region[, c("sector", "region", "u")])
  say(sid, " ", nm, " | gamma ", paste(round(gam, 4), collapse = "/"))
}
out <- do.call(rbind, res); rownames(out) <- NULL
rg <- do.call(rbind, regs); rownames(rg) <- NULL
saveRDS(list(k = out, regions = rg, frontierReproduced = frCheck, set = set), file.path(P1, paste0("spec-band", sfx, ".rds")))

options(width = 220)
cat("\n== control: deployed spec's frontier reproduced:", paste(names(frCheck), frCheck, collapse = ", "), "\n")
kw <- reshape(out, idvar = c("id", "spec", "deployed", "bootWin", "run", "sector"), timevar = "year", direction = "wide")
names(kw) <- sub("k.", "", names(kw), fixed = TRUE)
kw$spec <- sub(" bothIncAP lev ", " ", sub("WGIge|", "", kw$spec, fixed = TRUE), fixed = TRUE)
for (s in c("Bulk", "Diffuse")) for (r in names(scen)) {
  cat("\n==", s, r, "\n"); x <- kw[kw$sector == s & kw$run == r, ]
  print(x[order(-x$bootWin), c("id", "spec", "deployed", "bootWin", "2035", "2050", "2070", "2100")], row.names = FALSE, digits = 3)
}
dep <- if (deployed %in% rg$spec) rg[rg$spec == deployed, c("sector", "region", "u")] else
  data.frame(sector = readRDS(file.path(P1, "anchors.rds"))$EU21$region$sector, region = readRDS(file.path(P1, "anchors.rds"))$EU21$region$region,
             u = readRDS(file.path(P1, "anchors.rds"))$EU21$region$u)
cat("\n== ranking u: Spearman with the deployed spec (EU21)\n")
print(do.call(rbind, lapply(split(rg, list(rg$id, rg$sector), drop = TRUE), function(d) {
  m <- merge(d[, c("region", "u")], dep[dep$sector == d$sector[1], c("region", "u")], by = "region")
  data.frame(id = d$id[1], sector = d$sector[1], gammaBulk = round(d$gammaBulk[1], 4), spearman = round(stats::cor(m$u.x, m$u.y, method = "spearman"), 3))
})), row.names = FALSE)
