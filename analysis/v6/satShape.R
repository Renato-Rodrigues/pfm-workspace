# How much does the deployed spec's result depend on the shape of its saturating actor-power curve?
# (design note 0005 §7a decision 6: family A in the main text, with this as its robustness check.)
# The curve is x / (x + xBar); xBar is fixed at the training median. Here xBar = s * median for
# s in 0.5, 1, 2 (pfm's apSatScale): below 1 the curve flattens earlier - incumbents lose weight faster
# as they shrink - above 1 it is closer to linear over the observed range.
#   Rscript analysis/v6/satShape.R [group] [scales]       (repo root; after analysis/v6/phase1.R)
#   Rscript analysis/v6/satShape.R v6 0.5,1,2
# Per scale: the sanity walk with the sweep's gates (gating PkBudg1000, reference NPi), the fit's BIC,
# the frontier, the donor assignment, k_s(t) on NPi and PkBudg1000, gamma and the ranking u.
# Scratch Run-Groups in output/pfm/satshape-<group>/x<s>/; s = 1 must reproduce <group>/frontier.rds.
# Output: output/pfm/<group>/phase1/sat-shape.rds and a printed summary.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v6"
scales <- if (length(args) > 1) as.numeric(strsplit(args[2], ",")[[1]]) else c(0.5, 1, 2)
GD <- file.path("output/pfm", g); P1 <- file.path(GD, "phase1"); SD <- file.path("output/pfm", paste0("satshape-", g))
dir.create(SD, showWarnings = FALSE, recursive = TRUE)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
source("analysis/v6/bases.R"); BASES <- v6Bases(rc)   # the registry's SSP2 pair (PITFALLS.md 34)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
modelDir <- rc$modelDir %||% "output/pfm/fit-cache"
say <- function(...) message("[satshape:", g, "] ", ...)

manifest <- jsonlite::read_json(file.path(GD, "manifest.json"))
panel <- loadTrainingPanel(manifest$panel_hash, modelDir)
selDeployed <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
deployed <- selDeployed[[1]]$name
rec <- pfm:::.pfmSweepOptionsForGroup(GD)
w <- pfmAssertSizeWeights(pfmCouplingWeights(year = 2025, scenario = "SSP2"), "sat shape")
scen <- lapply(c(NPi = "NPi", PkBudg1000 = "PkBudg1000"), function(k) v6ScenPanel(P1, k, BASES[[k]]))
sectors <- c("Bulk", "Diffuse")
estKeys <- c("model_type", "estimator", "indexMax", "trendMidpoint", "trendSteepness")
specOf <- function(s) { x <- pfm:::.pfmNormSpec(selDeployed[[1]]); x <- x[setdiff(names(x), c(estKeys, "description"))]
  if (s != 1) x$apSatScale <- s; x$name <- paste0(deployed, if (s != 1) paste0(" x", s) else ""); x }

res <- list(); regs <- list(); fit <- list(); frCheck <- NULL
for (s in scales) {
  tag <- paste0("x", s); gd <- file.path(SD, tag); dir.create(gd, showWarnings = FALSE)
  sp <- specOf(s)
  # 1. the sanity walk, gates as recorded for the group
  walk <- pfm:::.pfmSanitySelect(
    passModels = sp$name, specByName = stats::setNames(list(sp), sp$name), sectors = sectors,
    panelData = panel, scenarioData = scen$PkBudg1000, modelDir = modelDir, batchSize = 1, maxModels = 1,
    thresholds = list(), regionBlocks = pfm:::.h12RegionBlocks(), histIndexBySector = pfm:::.histIndexBySector(panel, sectors),
    indexMax = 10, referenceScenarioData = scen$NPi, minScenarioDelta = 0.05, deltaWindow = c(2040, 2060),
    supportShareGate = 0.275, ceilingFallGate = 0.90, gammaGate = 0.999, vcovGate = c("likelihood-mismatch", "flat"),
    apExtrapolationGate = rec$apExtrapolationGate %||% 0.275, apExtrapolationSd = rec$apExtrapolationSd %||% 1,
    apExtrapolationWindow = unlist(rec$apExtrapolationWindow %||% c(2025, 2100)), stopAtFirstPass = FALSE)
  tr <- walk$trace; fl <- walk$flags[[sp$name]]
  sev <- if (is.data.frame(fl) && nrow(fl)) paste(sort(unique(fl$rule[fl$severity == "severe"])), collapse = ",") else ""
  # 2. in-sample fit (BIC) per sector
  bic <- vapply(sectors, function(sec) {
    f <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "satP", modelDir = modelDir,
                                                       updateIndex = FALSE, verbose = FALSE), pfm:::.pfmSpecArgs(sp)))
    stats::BIC(f$model)
  }, numeric(1))
  # 3. frontier, donor assignment, anchor, k
  writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE, null = "null"), file.path(gd, "manifest.json"))
  yaml::write_yaml(lapply(selDeployed, function(e) c(sp[setdiff(names(sp), "name")], name = sp$name,
                                                      e[estKeys])),
                   file.path(gd, "selected-models-pfm.yml"))
  if (!file.exists(file.path(gd, "frontier.rds")))
    suppressMessages(runPFMFrontier(tag, resultsDir = SD, modelDir = modelDir, panelData = panel, verbose = FALSE))
  if (!file.exists(file.path(gd, "donor-assignment-band-Bulk.rds")))
    suppressMessages(runPFMDonorAssumptions(tag, resultsDir = SD, modelDir = modelDir, panelData = panel, verbose = FALSE))
  fr <- readRDS(file.path(gd, "frontier.rds"))
  if (s == 1) { ref <- readRDS(file.path(GD, "frontier.rds"))
    frCheck <- vapply(sectors, function(x) isTRUE(all.equal(fr$bySector[[x]]$coefTable, ref$bySector[[x]]$coefTable)), logical(1)) }
  gam <- vapply(sectors, function(x) { ct <- fr$bySector[[x]]$coefTable; ct$estimate[ct$term == "gamma"] }, numeric(1))
  an <- computeAnchorGap(tag, resultsDir = SD, modelDir = modelDir, weights = w, verbose = FALSE)
  for (run in names(scen)) {
    st <- computeStrengthPath(an, scen[[run]])$strength
    res[[paste(tag, run)]] <- cbind(scale = s, run = run, st[st$year %in% c(2035, 2050, 2070, 2100), c("sector", "year", "k")])
  }
  regs[[tag]] <- cbind(scale = s, an$region[, c("sector", "region", "u")])
  fit[[tag]] <- data.frame(scale = s, sanityPass = isTRUE(tr$pass[1]), nSevere = tr$nSevere[1], nWarning = tr$nWarning[1],
                           severeRules = sev, bicBulk = bic[["Bulk"]], bicDiffuse = bic[["Diffuse"]],
                           gammaBulk = gam[["Bulk"]], gammaDiffuse = gam[["Diffuse"]])
  say(tag, ": sanity ", if (isTRUE(tr$pass[1])) "PASS" else paste("FAIL", sev), " | gamma ", paste(round(gam, 4), collapse = "/"))
}
k <- do.call(rbind, res); rownames(k) <- NULL
rg <- do.call(rbind, regs); rownames(rg) <- NULL
fs <- do.call(rbind, fit); rownames(fs) <- NULL
saveRDS(list(fit = fs, k = k, regions = rg, frontierReproduced = frCheck), file.path(P1, "sat-shape.rds"))

options(width = 200)
cat("\n== control: scale 1 reproduces the deployed frontier:", paste(names(frCheck), frCheck, collapse = ", "), "\n")
fs$dBicBulk <- fs$bicBulk - fs$bicBulk[fs$scale == 1]; fs$dBicDiffuse <- fs$bicDiffuse - fs$bicDiffuse[fs$scale == 1]
cat("\n== sanity walk and fit\n"); print(fs, row.names = FALSE, digits = 4)
kw <- reshape(k, idvar = c("scale", "run", "sector"), timevar = "year", direction = "wide"); names(kw) <- sub("k.", "", names(kw), fixed = TRUE)
cat("\n== k_s(t), EU21\n"); print(kw[order(kw$sector, kw$run, kw$scale), ], row.names = FALSE, digits = 3)
d1 <- rg[rg$scale == 1, ]
cat("\n== ranking u: Spearman with scale 1\n")
print(do.call(rbind, lapply(split(rg, list(rg$scale, rg$sector), drop = TRUE), function(d) {
  m <- merge(d[, c("region", "u")], d1[d1$sector == d$sector[1], c("region", "u")], by = "region")
  data.frame(scale = d$scale[1], sector = d$sector[1], spearman = round(stats::cor(m$u.x, m$u.y, method = "spearman"), 3))
})), row.names = FALSE)
