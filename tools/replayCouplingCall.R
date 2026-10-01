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

args <- commandArgs(TRUE)
i <- match("--cachefolder", args); cacheDir <- NA
if (!is.na(i)) { cacheDir <- args[i + 1]; args <- args[-c(i, i + 1)] }
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
file.copy(file.path(refRun, "fulldata.gdx"), file.path(tmp, "input_ref.gdx"))

# --- 1. preparePFM, from inside the REMIND checkout, with the fork's default source -------
cfg <- local({ cfg <- NULL; owd <- setwd(remind); on.exit(setwd(owd)); source("config/default.cfg", local = TRUE); cfg })
cfg$results_folder <- tmp
cfg$regionmapping <- file.path("config", rmap)
cfg$gms$cm_GDPpopScen <- "gdp_SSP2"
cfg$gms$cm_taxCO2_regiDiff <- 11
cfg$pfmGroup <- group
local({ owd <- setwd(remind); on.exit(setwd(owd)); source("scripts/start/preparePFM.R", local = TRUE); preparePFM(cfg) })

# --- 2. the runtime settings presolve.gms would write -------------------------------------
writeLines(c(paste0("bindMode: ", bindMode), paste0("theta: ", theta), paste0("convTol: ", convTol),
             "iteration: 1", paste0("gapClosure: ", gapClosure), paste0("startYear: ", startYear)),
           file.path(tmp, "pfm-coupling-runtime.yml"))

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
names(res) <- c("symbol", "region", "phi_run", "phi_replay", "diff")
write.csv(res, file.path(tmp, "replay-check.csv"), row.names = FALSE)
tol <- if (is.finite(convTol)) convTol else 0.002
worst <- max(abs(res$diff))
cat(sprintf("\n[replay] %d shares compared; max |replay - run| = %.5f (tolerance %.4f)\n", nrow(res), worst, tol))
print(utils::head(res[order(-abs(res$diff)), ], 6), row.names = FALSE)
cat("[replay] details:", file.path(tmp, "replay-check.csv"), "\n")
if (!(worst <= tol)) { cat("[replay] FAIL\n"); quit(status = 1) }
cat("[replay] PASS\n")
