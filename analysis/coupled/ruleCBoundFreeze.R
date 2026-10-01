# Did the political cap follow the budget loop in the rule-C runs? One artifact that answers it.
#
# Why this exists
# ---------------
# Rule C keeps budget forcing ON under a binding political cap (COUPLING.md 4). In bind mode 2 the
# cap reaches GAMS as an ABSOLUTE price, P_ref + phi (P0 - P_ref), computed on the R side at the
# anchor P0 of that call (presolve.gms loads p45_pfmPriceBound). R is called only on the
# iterations in pfmIter up to phi convergence; after that the absolute bound is never recomputed,
# while the budget iteration keeps rescaling the anchor. So the cap stops following the formula it
# is documented by.
#
# Found 2026-09-21 on the rule-C severity arms (-PFMlevelCTh325/-Th675): at theta 0.325 the anchor
# doubles after the last call, the realised maximum price stays flat, the cap binds in every region,
# pm_pfmInfesCode = 4 fires on every check, and the budget miss is constant for ~65 iterations.
#
# Rule B is unaffected by construction (budget forcing off, the anchor does not move).
#
# Output: output/pfm/<group>/coupling/rulec-bound-freeze.rds, one row per run, plus the per-iteration
# traces. The paper reads it through paper-data; nothing here is quoted by hand.
#
#   Rscript analysis/coupled/ruleCBoundFreeze.R v5 output/remind-runs/v5

args  <- commandArgs(trailingOnly = TRUE)
group <- if (length(args) >= 1) args[1] else "v5"
gdxDir <- if (length(args) >= 2) args[2] else "output/remind-runs/v5"

bin <- local({
  cand <- unlist(strsplit(Sys.getenv("GAMSDIR", ""), "[;:]"))
  cand <- c(Sys.getenv("GDXDUMP", ""), file.path(cand[nzchar(cand)], "gdxdump.exe"), Sys.which("gdxdump"))
  cand <- cand[nzchar(cand) & file.exists(cand)]
  if (!length(cand)) stop("gdxdump not found; set GDXDUMP or GAMSDIR")
  cand[1]
})

sym <- function(gdx, s) {
  out <- suppressWarnings(system2(bin, c(shQuote(gdx), paste0("symb=", s), "format=csv"),
                                  stdout = TRUE, stderr = FALSE))
  if (length(out) < 2) return(NULL)
  utils::read.csv(text = paste(out, collapse = "\n"), stringsAsFactors = FALSE)
}
iterSeries <- function(gdx, s) {
  d <- sym(gdx, s); if (is.null(d)) return(setNames(numeric(0), character(0)))
  setNames(as.numeric(d[[ncol(d)]]), as.character(d[[1]]))
}
scalar <- function(gdx, s) { d <- sym(gdx, s); if (is.null(d)) NA_real_ else as.numeric(d[[ncol(d)]][1]) }

# The superseded-run rule of extractCoupledResults.R: the latest timestamp of a scenario wins.
# One level below each resolution folder, never recursive: gdxDir is ONE Run-Group's batch
# (output/remind-runs/<group>/<resolution>/<run>/), and reading deeper would pick up anything nested below a run.
dirs <- unlist(lapply(file.path(gdxDir, c("EU21", "H12")), list.dirs, recursive = FALSE, full.names = TRUE))
# Ratio-mode runs (-PFMratio*) are included as the control: their price is rho * anchor, rebuilt in
# GAMS every iteration, so their realised price should follow the anchor after the last call. That
# is the evidence that the held-budget price results (which are ratio-mode) are not affected
# (referee v08, M3).
dirs <- dirs[grepl("PkBudg1000-PFM(level[BC]|ratio)", basename(dirs)) & file.exists(file.path(dirs, "fulldata.gdx"))]
scen <- sub("_\\d{4}-\\d{2}-\\d{2}_.*$", "", basename(dirs))
res  <- basename(dirname(dirs))
key  <- paste(res, scen)
dirs <- dirs[order(key, basename(dirs), decreasing = TRUE)]
dirs <- dirs[!duplicated(paste(basename(dirname(dirs)), sub("_\\d{4}-.*$", "", basename(dirs))))]

rows <- list(); traces <- list()
for (d in dirs) {
  g <- file.path(d, "fulldata.gdx")
  sc <- sub("_\\d{4}-\\d{2}-\\d{2}_.*$", "", basename(d)); rs <- basename(dirname(d))
  calls <- grep("runtime config from GAMS", readLines(file.path(d, "log.txt"), warn = FALSE), value = TRUE)
  callIt <- as.integer(sub(".*iteration ", "", calls))
  lastCall <- if (length(callIt)) max(callIt) else NA_integer_
  anchor <- iterSeries(g, "p45_pfmAnchor_iter")
  maxP   <- iterSeries(g, "p45_pfmMaxPrice_iter")
  diffB  <- iterSeries(g, "o45_diff_to_Budg")
  bind   <- iterSeries(g, "p45_pfmBindShare_iter")
  infes  <- iterSeries(g, "p45_pfmInfes_iter")
  # Rule B runs have budget forcing off and carry no budget trace; fall back to the anchor's.
  if (!length(diffB)) diffB <- setNames(rep(NA_real_, length(anchor)), names(anchor))
  it <- as.integer(names(diffB)); last <- max(it)
  # Length of the terminal stall: trailing iterations whose budget miss stays within 3 Gt of the
  # final one while the final one is itself outside that band.
  fin <- unname(diffB[as.character(last)])
  stall <- if (is.finite(fin) && abs(fin) > 3) { k <- 0; for (v in rev(diffB)) { if (abs(v - fin) <= 3) k <- k + 1 else break }; k } else 0L
  rows[[length(rows) + 1]] <- data.frame(
    resolution = rs, scenario = sc, rule = if (grepl("PFMlevelC", sc)) "C" else if (grepl("PFMratio", sc)) "ratio" else "B",
    theta = scalar(g, "cm_pfmTheta"), iterations = last,
    lastPfmCall = lastCall, nPfmCalls = length(callIt),
    anchorAtLastCall = unname(anchor[as.character(lastCall)]), anchorAtEnd = unname(anchor[length(anchor)]),
    anchorDrift = unname(anchor[length(anchor)] / anchor[as.character(lastCall)]),
    maxPriceAtLastCall = unname(maxP[as.character(lastCall)]), maxPriceAtEnd = unname(maxP[length(maxP)]),
    # If the realised price follows the anchor, priceDrift / anchorDrift is ~1; a frozen bound gives ~1/anchorDrift.
    priceDrift = unname(maxP[length(maxP)] / maxP[as.character(lastCall)]),
    bindShareEnd = if (length(bind)) unname(bind[length(bind)]) else NA_real_,
    budgetMissEnd = fin, stallIterations = stall,
    infesCode4Checks = sum(infes == 4, na.rm = TRUE), infesCodeEnd = scalar(g, "pm_pfmInfesCode"),
    # Runs made with the fork fix (cm_pfmBoundRebuild = 1): the switch, the worst call-iteration
    # gap between the GAMS rebuild and R's bound (~1e-6 when it reproduces R), and how far the
    # applied cap had followed the anchor by the end. NA on runs built before the switch existed.
    boundRebuild = scalar(g, "cm_pfmBoundRebuild"),
    boundCheckMax = { v <- iterSeries(g, "p45_pfmBoundCheck_iter"); if (length(v)) max(v) else NA_real_ },
    boundDriftEnd = { v <- iterSeries(g, "p45_pfmBoundDrift_iter"); if (length(v)) unname(v[length(v)]) else NA_real_ },
    stringsAsFactors = FALSE)
  traces[[paste(rs, sc)]] <- data.frame(resolution = rs, scenario = sc, iteration = it,
    budgetMiss = unname(diffB), anchor = unname(anchor[as.character(it)]),
    maxPrice = unname(maxP[as.character(it)]), pfmCall = it %in% callIt)
  cat(sprintf("%-5s %-40s theta %.3f  iter %3d  lastCall %2d  drift %.2f  miss %6.1f  stall %2d  code4 %2d\n",
              rs, sc, rows[[length(rows)]]$theta, last, lastCall, rows[[length(rows)]]$anchorDrift, fin, stall,
              rows[[length(rows)]]$infesCode4Checks))
}

out <- list(runs = do.call(rbind, rows), traces = do.call(rbind, traces), group = group,
            generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
            mechanism = paste("bind mode 2 ships the cap as an absolute price computed at the anchor of",
                              "the last PFM call; after phi converges it is not recomputed while the",
                              "budget loop keeps moving the anchor"))
f <- file.path("output/pfm", group, "coupling", "rulec-bound-freeze.rds")
saveRDS(out, f)
cat("wrote", f, ":", nrow(out$runs), "runs\n")
