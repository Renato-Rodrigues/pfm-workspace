# A specification per sector instead of one for both: what the declared search would select in each sector alone.
#   Rscript analysis/v8/perSectorSelection.R [group] [sectors]   (repo root; default v8, Bulk,Diffuse)
#     -> output/pfm/<group>/per-sector-selection.rds
#   on the cluster (the walk needs more memory than a workstation): sbatch analysis/v8/perSectorSelection.sbatch
#   PFM_WALK_TIMEOUT_MIN sets the time limit per candidate (default 15).
# The Shared Specification rule (ADR 0039, CONTEXT.md) selects one specification for both sectors: the pool is ranked
# on the WORSE sector's ΔR²(theory), H1-H2 must hold in both sectors, and the sanity walk rejects a candidate with a
# severe flag in either. Here each sector is selected alone with the same gates and settings as the cluster job
# (output/pfm/<group>/pfm-<group>-job.R): the ranking on that sector's ΔR²(theory), the theory screen in that sector,
# and the walk (γ gate, H3, edge-of-data, responsiveness, extrapolation, ceiling fall) on that sector's flags only.
# Nothing is refitted for the ranking: the sweep's fit tables (sweep.rds) are re-ranked. The walk refits each candidate's
# frontier and projects it on the two registry scenarios (EU21 gdx, local copies), as the cluster walk does.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v8"
WALK <- if (length(args) >= 2) strsplit(args[2], ",")[[1]] else c("Bulk", "Diffuse")
GD <- file.path("output/pfm", g)
options(pfm.panel = list(firstYear = 2000L, lastYear = 2023L, movingAverage = 5L, ieaVersion = "latest", geothermal = TRUE,
                         democracy = TRUE, overallAccountability = TRUE, fossilRents = TRUE))
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g)), forcecache = TRUE, .verbose = FALSE)

sw <- readRDS(file.path(GD, "sweep.rds"))
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
specByName <- stats::setNames(sw$specs, vapply(sw$specs, `[[`, character(1), "name"))
SECTORS <- c("Bulk", "Diffuse")
THEORY <- list(p = 0.05, structural = TRUE, contingency = TRUE, coherence = 0.75)
EDGE <- list(share = 0.25, effect = 0.25, capShift = 0.5, cap = c(0.05, 0.95), mapping = "regionmapping_21_EU11.csv")

# the ranking, exactly as runPFMSweep() builds it (the job's settings; the rest at their defaults)
sub <- sw$results[sw$results$stage == "PolicyStringency", , drop = FALSE]
sub <- sub[grepl("fe:(H12|OECDp|Mundlak)", sub$model), , drop = FALSE]
mmCols <- intersect(c("model", "sector", "sigActorPower", "sigInstQual", "sigInteractions", "deltaR2Theory", "pseudoR2", "bic",
                      "maxVIF", "converged", "usesLagged", "nFE", "nObs", "sigControl", "nControl", "trendShare", "minSigTheoryT"),
                    colnames(sub))
rank <- function(sectors) {
  mm <- computeMaximinScore(sub[sub$sector %in% sectors, mmCols, drop = FALSE], nearTieEps = 0.025, feParsimonyWeight = 0,
                            dropIdleControls = TRUE, softVifGate = Inf, trendDominanceGate = 0.9, deltaR2Max = 1,
                            inferenceTGate = 0, rankBy = "worseDeltaR2", tierGate = "Green")
  th <- pfm:::.pfmTheoryScreen(sw$coefficients, unique(sub$model), sectors, THEORY)
  mm$theoryPass <- mm$model %in% th$model[th$pass]
  mm$pool <- mm$gatePass & mm$theoryPass
  mm
}
# check: the joint ranking reproduces the cluster's walk order
joint <- rank(SECTORS)
walked <- sw$sanity$PolicyStringency$trace$model
stopifnot(identical(head(joint$model[joint$pool], length(walked)), walked))
cat("joint ranking reproduces the cluster walk (", length(walked), " candidates)\n")

say <- function(...) message("[perSector] ", ...)
mk <- function(gdx) panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                                      outputRegionMappingFile = "country", histYears = pfm:::.pfmPanelYears(),
                                      movingAverage = pfm:::.pfmPanelMA())
gating <- mk("output/remind-runs/v6/EU21/SSP2-EU21-PkBudg1000_2026-10-07_19.04.46/fulldata.gdx")
reference <- mk("output/remind-runs/v6/EU21/SSP2-EU21-NPi2025_2026-10-07_12.36.43/fulldata.gdx")

# The walk, one candidate at a time in its own R process (callr) with a time limit: a candidate whose fit or projection
# hangs (2026-10-29: one sat > 40 min where the others took ~2) is tried once more and then skipped, and the skip is
# recorded. Each candidate's verdict does not depend on the others, so walking them singly gives the same verdicts as
# .pfmSanitySelect() walking the list; it stops at the first that passes, as the walk does.
TIMEOUT <- as.numeric(Sys.getenv("PFM_WALK_TIMEOUT_MIN", "15")) * 60; MAXMODELS <- 60
inputs <- tempfile(fileext = ".rds")
saveRDS(list(specByName = specByName, panel = panel, gating = gating, reference = reference, EDGE = EDGE, THEORY = THEORY), inputs)
one <- function(model, sector, inputs, root, panelOpt, cache) {
  # the child process inherits nothing: the panel definition and the madrat cache are set again, or the walk reads a
  # different panel (2026-10-29: one more severe flag per candidate than the cluster walk without them)
  setwd(root); source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
  options(pfm.panel = panelOpt); madrat::setConfig(cachefolder = cache, forcecache = TRUE, .verbose = FALSE)
  x <- readRDS(inputs)
  pfm:::.pfmSanitySelect(passModels = model, specByName = x$specByName, sectors = sector, panelData = x$panel,
                         scenarioData = x$gating, modelDir = "output/pfm/fit-cache", batchSize = 5, maxModels = 1,
                         thresholds = list(), regionBlocks = pfm:::.h12RegionBlocks(),
                         histIndexBySector = pfm:::.histIndexBySector(x$panel, sector), indexMax = 10,
                         referenceScenarioData = x$reference, minScenarioDelta = 0.05, deltaWindow = c(2040, 2060),
                         supportShareGate = 0.275, ceilingFallGate = 0.90, gammaGate = 0.999,
                         vcovGate = c("likelihood-mismatch", "flat"), apExtrapolationGate = 0.275, apExtrapolationSd = 1,
                         apExtrapolationWindow = c(2025, 2100), edgeGate = x$EDGE, theoryGate = x$THEORY)
}
walk <- function(sector, pool) {
  trace <- list(); flags <- list(); gamma <- list(); chosen <- NULL
  for (i in seq_len(min(length(pool), MAXMODELS))) {
    m <- pool[i]; t0 <- Sys.time(); res <- NULL; tries <- 0
    while (is.null(res) && tries < 2) {
      tries <- tries + 1
      res <- tryCatch(callr::r(one, list(model = m, sector = sector, inputs = inputs, root = getwd(),
                                         panelOpt = getOption("pfm.panel"), cache = madrat::getConfig("cachefolder")), timeout = TIMEOUT),
                      error = function(e) { say("  #", i, " try ", tries, ": ", class(e)[1], " - ", conditionMessage(e)); NULL })
    }
    mins <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
    if (is.null(res)) {
      trace[[i]] <- data.frame(model = m, nSevere = NA_integer_, nWarning = NA_integer_, pass = NA, status = "skipped (timeout)", minutes = mins)
      say(sprintf("#%d %s - SKIPPED after %d tries (%.0f min)", i, m, tries, mins)); next
    }
    tr <- res$trace
    trace[[i]] <- data.frame(model = m, nSevere = tr$nSevere, nWarning = tr$nWarning, pass = isTRUE(tr$pass),
                             status = if (tries > 1) "ok on retry" else "ok", minutes = mins)
    flags[[m]] <- res$flags[[m]]; gamma[[m]] <- res$gamma[[m]]
    # check against the cluster walk where it evaluated the same candidate: the same severe flags in this sector
    cl <- sw$sanity$PolicyStringency$flags[[m]]
    if (!is.null(cl)) {
      a <- sort(cl$rule[cl$severity == "severe" & cl$sector == sector]); b <- sort(res$flags[[m]]$rule[res$flags[[m]]$severity == "severe"])
      if (!identical(a, b)) stop("walk differs from the cluster's on ", m, " (", sector, "): cluster ", paste(a, collapse = ","),
                                 " | here ", paste(b, collapse = ","))
      say("  matches the cluster walk on this candidate")
    }
    say(sprintf("#%d %s - %d severe / %d warnings%s (%.1f min)", i, m, tr$nSevere, tr$nWarning,
                if (isTRUE(tr$pass)) " - PASSES" else "", mins))
    if (isTRUE(tr$pass)) { chosen <- m; break }
  }
  list(chosen = chosen, trace = do.call(rbind, trace), flags = flags, gamma = gamma)
}
# a sector walked earlier is kept when only the other one is walked now (the sectors argument)
outFile <- file.path(GD, "per-sector-selection.rds")
out <- if (file.exists(outFile) && length(WALK) < length(SECTORS)) readRDS(outFile) else list()
out$group <- g; out$made <- format(Sys.time(), "%Y-%m-%d %H:%M"); out$host <- Sys.info()[["nodename"]]
out$joint <- list(ranking = joint, chosen = sw$selected$PolicyStringency)
for (s in WALK) {
  mm <- rank(s)
  say(s, ": ", sum(mm$pool), " specs in the pool (joint: ", sum(joint$pool), "); top: ", mm$model[mm$pool][1])
  sel <- walk(s, mm$model[mm$pool])
  say(s, ": chosen ", sel$chosen %||% "NONE within the walk")
  out[[s]] <- list(ranking = mm, sanity = sel, chosen = sel$chosen)
  saveRDS(out, outFile)
}
done <- intersect(SECTORS, names(out))
cat("\njoint:  ", out$joint$chosen, "\n"); for (s in done) cat(sprintf("%-8s %s\n", s, out[[s]]$chosen %||% "none"))
for (s in done) { cat("\n==", s, "walk ==\n"); print(out[[s]]$sanity$trace, row.names = FALSE) }
