# Replay one PFM coupling call outside REMIND, and check it reproduces what a finished run used.
#
#   Rscript tools/replayCouplingCall.R <run-folder> <reference-run-folder> <group> [remind-checkout] [--cachefolder <dir>]
#
#   <run-folder>            a finished coupled run with fulldata.gdx, e.g.
#                           output/remind-runs/v5/EU21/SSP2-EU21-PkBudg1000-PFMlevelBfix_2026-09-17_14.34.22
#   <reference-run-folder>  its current-policies run (the run's path_gdx_ref), e.g.
#                           output/remind-runs/v5/EU21/SSP2-EU21-NPi2025_2026-08-26_16.51.07
#   <group>                 a Run-Group exported to output/remind-inputs/<group> (pfmRun(stage = "remind"))
#   [remind-checkout]       default models/remind_pfm
#   --cachefolder <dir>     the madrat cache the replayed call reads, with forcecache. Default: the
#                           cache preparePFM() stages from the Run-Group's REMIND export (as a real
#                           run does), else the group's prepared project cache (config.yml `madrat:`).
#                           Runs from before the staging (all of v5) read madrat's shared cache instead,
#                           so reproducing their shares needs the files that run read
#                           (listMadratCacheUsed.R on its log.txt; ADR 0047).
#
# What it exercises, in the order a coupled run does:
# 1. The fork's own scripts/start/preparePFM.R, run from inside the REMIND checkout with the
#    fork's default cfg$pfm$source. It must find output/remind-inputs/<group> and stage the
#    Run-Group into <tmp-run>/pfm/.
# 2. pfm-coupling-runtime.yml, as presolve.gms writes it: bind mode, theta, gap closure and start
#    year are read from the run's own fulldata.gdx.
# 3. pfm::iterativePFM() in the run folder, exactly as GAMS calls it. Its gdx goes through the
#    same write-and-verify path as in a real run.
#
# The check: the replayed shares against the shares the run ended on (p45_regiDiff_phi,
# p45_pfmPhiMkt in fulldata.gdx). They are not expected to be bit-identical. The run's last PFM
# call saw the energy system of the iteration BEFORE the one fulldata.gdx holds. They must agree
# within the run's own convergence tolerance (cm_pfmConvTol, 0.002), which is what "converged"
# meant for that run. Writes <tmp-run>/replay-check.csv and exits non-zero on failure.

#
# 2026-11-25 (gap plan GP-52 of the GMD paper): the replay now runs at the RUN's own settings. Before, the cfg was
# default.cfg plus five fields, so every scenario-row option (pfmPhiStrength, pfmInstitutions, pfmFormulation,
# pfmPhiHold, pfmPhiKappa, pfmRentsPrice, cm_pfmRefPrice, ...) took its default: a run at regional strength was
# replayed at common strength. Now:
#   - the pfm* options and the cm_pfm* switches come from the run's config.Rdata (cfg$pfm, the staging source, stays
#     the local default, so the replay finds the local Run-Group export);
#   - the reference gdx is staged under the name the run read it from (input_ref.gdx or input_refpolicycost.gdx);
#   - the runtime file carries phiPath and ssp, as presolve.gms writes them;
#   - the run's own pfm-phi-history.rds, minus its last call, is seeded, so the replay IS the run's last call,
#     damping included (a last call that damped the path cannot be reproduced from an empty history).
#     --no-history replays a first call instead;
#   - the share path p45_pfmPhiPath is compared as well;
#   - --keep <dir> copies the replay's output gdx, the check and the settings files there (the example files).
args <- commandArgs(TRUE)
i <- match("--cachefolder", args); cacheDir <- NA
if (!is.na(i)) { cacheDir <- args[i + 1]; args <- args[-c(i, i + 1)] }
i <- match("--keep", args); keepDir <- NA
if (!is.na(i)) { keepDir <- args[i + 1]; args <- args[-c(i, i + 1)] }
useHistory <- !("--no-history" %in% args); args <- setdiff(args, "--no-history")
if (length(args) < 3) stop("usage: replayCouplingCall.R <run-folder> <reference-run-folder> <group> [remind-checkout]")
run <- normalizePath(args[1], mustWork = TRUE)
refRun <- normalizePath(args[2], mustWork = TRUE)
group <- args[3]
remind <- normalizePath(if (length(args) >= 4) args[4] else "models/remind_pfm", mustWork = TRUE)
suppressMessages({ library(gdx); library(pfm) })
`%||%` <- function(a, b) if (is.null(a)) b else a

g <- file.path(run, "fulldata.gdx")
sc <- function(sym) { v <- tryCatch(as.numeric(readGDX(g, sym, react = "silent")), error = function(e) NA); if (length(v)) v[1] else NA }
bindMode <- sc("cm_pfmBindMode"); theta <- sc("cm_pfmTheta"); gapClosure <- sc("cm_pfmGapClosure")
startYear <- sc("cm_startyear"); convTol <- sc("cm_pfmConvTol")
regi <- readGDX(g, "regi")
rmap <- if (length(regi) == 21) "regionmapping_21_EU11.csv" else if (length(regi) == 12) "regionmappingH12.csv" else
  stop("cannot tell the region mapping from ", length(regi), " regions")
cat(sprintf("[replay] %s\n  bindMode %s, theta %s, gapClosure %s, startYear %s, convTol %s, %s\n",
            basename(run), bindMode, theta, gapClosure, startYear, convTol, rmap))

# --- a fresh run folder -------------------------------------------------------------------
tmp <- file.path(tempdir(), paste0("replay-", basename(run)))
unlink(tmp, recursive = TRUE); dir.create(tmp, recursive = TRUE)
file.copy(g, file.path(tmp, "fulldata.gdx"))

# --- 1. preparePFM, from inside the REMIND checkout, with the fork's default source -------
cfg <- local({ cfg <- NULL; owd <- setwd(remind); on.exit(setwd(owd)); source("config/default.cfg", local = TRUE); cfg })
runCfg <- NULL
if (file.exists(file.path(run, "config.Rdata"))) {
  e <- new.env(); load(file.path(run, "config.Rdata"), envir = e); runCfg <- e$cfg
  for (n in setdiff(grep("^pfm", names(runCfg), value = TRUE), "pfm")) cfg[[n]] <- runCfg[[n]]
  for (n in grep("^cm_pfm|^c_pfm", names(runCfg$gms), value = TRUE)) cfg$gms[[n]] <- runCfg$gms[[n]]
  if (!is.null(runCfg$gms$cm_GDPpopScen)) cfg$gms$cm_GDPpopScen <- runCfg$gms$cm_GDPpopScen
  if (!identical(as.character(runCfg$pfmGroup %||% group), group))
    cat("[replay] NOTE: the run used Run-Group", runCfg$pfmGroup, "- replaying with", group, "as asked\n")
} else {
  cat("[replay] WARNING: no config.Rdata in the run folder - the scenario-row options take their defaults\n")
  cfg$gms$cm_GDPpopScen <- "gdp_SSP2"
}
cfg$results_folder <- tmp
cfg$regionmapping <- file.path("config", rmap)
cfg$gms$cm_taxCO2_regiDiff <- 11
cfg$pfmGroup <- group
refPrice <- as.character(cfg$gms$cm_pfmRefPrice %||% "")
if (!nzchar(refPrice)) refPrice <- as.character(cfg$pfmRefPrice %||% "")
if (!nzchar(refPrice)) refPrice <- "ref"
file.copy(file.path(refRun, "fulldata.gdx"), file.path(tmp, "input_ref.gdx"))
if (refPrice != "ref") file.copy(file.path(refRun, "fulldata.gdx"), file.path(tmp, paste0("input_", refPrice, ".gdx")))
cat(sprintf("[replay] settings from the run: strength %s, institutions %s, formulation %s, reference price %s\n",
            cfg$pfmPhiStrength %||% "(default)", cfg$pfmInstitutions %||% "(default)", cfg$pfmFormulation %||% "(default)", refPrice))
local({ owd <- setwd(remind); on.exit(setwd(owd)); source("scripts/start/preparePFM.R", local = TRUE); preparePFM(cfg) })

# --- 2. the runtime settings presolve.gms would write -------------------------------------
phiPath <- as.character(cfg$gms$cm_pfmPhiPath %||% sc("cm_pfmPhiPath"))
ssp <- sub("^gdp_", "", as.character(cfg$gms$cm_GDPpopScen %||% "SSP2"))
writeLines(c(paste0("bindMode: ", bindMode), paste0("theta: ", theta), paste0("convTol: ", convTol),
             "iteration: 1", paste0("gapClosure: ", gapClosure), paste0("startYear: ", startYear),
             paste0("ssp: ", ssp), paste0("phiPath: ", phiPath)),
           file.path(tmp, "pfm-coupling-runtime.yml"))

# --- 2b. the run's own history up to its last call, so the replay is that call (damping included) -------
hf <- file.path(run, "pfm-phi-history.rds"); seeded <- 0L
if (useHistory && file.exists(hf)) {
  h <- readRDS(hf)
  if (length(h) >= 2) {
    saveRDS(h[-length(h)], file.path(tmp, "pfm-phi-history.rds")); seeded <- length(h) - 1L
    cat(sprintf("[replay] history: the run's first %d of %d calls seeded; replaying call %d (its alpha was %s)\n",
                seeded, length(h), length(h), format(h[[length(h)]]$alpha %||% NA)))
  }
}

# --- 3. the coupling call -----------------------------------------------------------------
# The staged cache preparePFM() just copied in (pfm/madrat-cache, declared in pfm-coupling.yml)
# is applied by iterativePFM() itself. An explicit --cachefolder replaces it: the declaration is
# dropped, or iterativePFM() would switch back to the staged copy. With neither, the group's
# prepared project cache (config.yml `madrat:`).
yml <- file.path(tmp, "pfm-coupling.yml")
staged <- file.path(tmp, "pfm", "madrat-cache")
if (!is.na(cacheDir)) {
  writeLines(grep("^cachefolder:", readLines(yml), invert = TRUE, value = TRUE), yml)
} else if (!dir.exists(staged)) {
  cacheDir <- pfm::pfmResolveConfig("config.yml", group = group, verbose = FALSE)$cachefolder
}
if (!is.na(cacheDir)) {
  cacheDir <- normalizePath(cacheDir, mustWork = TRUE)
  madrat::setConfig(cachefolder = cacheDir, forcecache = TRUE, .verbose = FALSE)
}
cat("[replay] madrat cache:", if (is.na(cacheDir)) "pfm/madrat-cache, staged with the Run-Group" else cacheDir,
    "(forcecache)
")
owd <- setwd(tmp)
ok <- pfm::iterativePFM()
setwd(owd)
if (!isTRUE(ok)) stop("iterativePFM() failed - see the messages above")

# --- the check ------------------------------------------------------------------------------
out <- file.path(tmp, "p45_regiDiff_phi.gdx")
cmp1 <- function(sym) {
  a <- readGDX(g, sym); b <- readGDX(out, sym)
  da <- as.data.frame(a, rev = 3); db <- as.data.frame(b, rev = 3)
  key <- setdiff(names(da), ".value")
  m <- merge(da, db, by = key, suffixes = c(".run", ".replay"))
  m$symbol <- sym; m$diff <- m$.value.replay - m$.value.run
  m
}
res <- rbind(cmp1("p45_regiDiff_phi")[, c("symbol", "all_regi", ".value.run", ".value.replay", "diff")],
             { x <- cmp1("p45_pfmPhiMkt"); x$all_regi <- paste(x$all_regi, x$all_emiMkt); x[, c("symbol", "all_regi", ".value.run", ".value.replay", "diff")] })
pathOk <- tryCatch(!is.null(readGDX(out, "p45_pfmPhiPath", react = "silent")), error = function(e) FALSE)
if (identical(phiPath, "1") && pathOk) {
  x <- cmp1("p45_pfmPhiPath"); yc <- grep("^(ttot|year|t)$", names(x), value = TRUE)[1]
  # From the first period after cm_startyear (the tier year, the first one REMIND is free to change) to 2100: the
  # same years the run's own convergence test measures the path over (iterativePFM: delta from t0). cm_startyear
  # itself is inside the fixed window (first replay, 2026-11-25: USA 2030 differed by 0.0021, every later cell by < 0.0007).
  x <- x[as.integer(as.character(x[[yc]])) > as.integer(startYear) & as.integer(as.character(x[[yc]])) <= 2100, ]
  x$all_regi <- paste(x$all_regi, x[[yc]])
  res <- rbind(res, x[, c("symbol", "all_regi", ".value.run", ".value.replay", "diff")])
}
names(res) <- c("symbol", "region", "phi_run", "phi_replay", "diff")
write.csv(res, file.path(tmp, "replay-check.csv"), row.names = FALSE)
tol <- if (is.finite(convTol)) convTol else 0.002
worst <- max(abs(res$diff))
cat(sprintf("\n[replay] %d shares compared; max |replay - run| = %.5f (tolerance %.4f)\n", nrow(res), worst, tol))
print(utils::head(res[order(-abs(res$diff)), ], 6), row.names = FALSE)
cat("[replay] details:", file.path(tmp, "replay-check.csv"), "\n")
verdict <- if (worst <= tol) "PASS" else "FAIL"
if (!is.na(keepDir)) {
  dir.create(keepDir, recursive = TRUE, showWarnings = FALSE)
  file.copy(file.path(tmp, c("p45_regiDiff_phi.gdx", "replay-check.csv", "pfm-coupling.yml", "pfm-coupling-runtime.yml")),
            keepDir, overwrite = TRUE)
  writeLines(c(paste0("run: ", basename(run)), paste0("reference: ", basename(refRun)), paste0("group: ", group),
               paste0("historySeeded: ", seeded), paste0("sharesCompared: ", nrow(res)),
               paste0("maxAbsDiff: ", signif(worst, 6)), paste0("tolerance: ", tol), paste0("verdict: ", verdict),
               paste0("made: ", format(Sys.time(), "%Y-%m-%d %H:%M"))), file.path(keepDir, "replay-summary.yml"))
  cat("[replay] kept in", normalizePath(keepDir), "\n")
}
if (verdict == "FAIL") { cat("[replay] FAIL\n"); quit(status = 1) }
cat("[replay] PASS\n")
