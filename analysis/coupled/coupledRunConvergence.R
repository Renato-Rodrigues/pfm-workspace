# Is a coupled run usable when REMIND did not declare it converged? One table that answers it.
#
#   Rscript analysis/coupled/coupledRunConvergence.R [group] [gdxDir] [pattern]   # from the project root
#
# WHY. REMIND's Nash loop stops at cm_iteration_max = 100 whenever cm_nash_autoconverge > 0
# (modules/80_optimization/nash/datainput.gms overwrites any configured value, so the 150 set in
# scenario_config_PFM.csv for the RULECFIX rows had no effect). A run that stops there has "failed"
# one or more criteria, but which ones, where, and by how much decides whether its numbers can be
# quoted. The same measures are applied to runs still in flight (fulldata.gdx is rewritten every
# iteration) and to runs that crashed after writing a successful iteration.
#
# WHAT, at the last completed iteration, against REMIND's OWN tolerances:
#   surplus   p80_surplusMax_iter / p80_surplusMaxTolerance, split at 2060 (early = what the paper
#             quotes: peak-budget and 2050 quantities; MODEL.md 7 bars differences past ~2060)
#   taxconv   |p80_convNashTaxrev_iter| / cm_TaxConv_tolerance (net tax revenue share of GDP), same split
#   budget    o45_diff_to_Budg against cm_budgetCO2_absDevTol (Gt CO2)
#   settled   relative range of the anchor and the realised maximum price, and the largest budget
#             miss, over the last TAIL iterations: a run still moving is not usable whatever it passes
#   cycle     the 2050 anchor (p45_pfmAnchorPath_iter, US$/tCO2) over the last BAND iterations and the
#             number of peak-year switches (o45_peakBudgYr_Itr) there: a run stopped in a limit cycle is
#             quoted over this band, not at its last iteration (PITFALLS 25b)
#
# Output: output/pfm/<group>/coupling/convergence-audit.rds (one row per run directory).

args   <- commandArgs(trailingOnly = TRUE)
group  <- if (length(args) >= 1) args[1] else "v5"
gdxDir <- if (length(args) >= 2) args[2] else "output/remind-runs/v5"
pat    <- if (length(args) >= 3) args[3] else "PkBudg1000-PFM"
EARLY  <- 2060; TAIL <- 10; BAND <- 20

bin <- local({
  cand <- unlist(strsplit(Sys.getenv("GAMSDIR", ""), "[;:]"))
  cand <- c(Sys.getenv("GDXDUMP", ""), file.path(cand[nzchar(cand)], "gdxdump.exe"), Sys.which("gdxdump"),
            "C:/Program Files/GAMS/51/gdxdump.exe")
  cand <- cand[nzchar(cand) & file.exists(cand)]
  if (!length(cand)) stop("gdxdump not found; set GDXDUMP or GAMSDIR")
  cand[1]
})
sym <- function(gdx, s) {
  out <- suppressWarnings(system2(bin, c(shQuote(gdx), paste0("symb=", s), "format=csv"), stdout = TRUE, stderr = FALSE))
  if (length(out) < 2) return(NULL)
  utils::read.csv(text = paste(out, collapse = "\n"), stringsAsFactors = FALSE)
}
scalar <- function(gdx, s) { d <- sym(gdx, s); if (is.null(d)) NA_real_ else as.numeric(d[[ncol(d)]][1]) }
series <- function(gdx, s) { d <- sym(gdx, s); if (is.null(d)) return(numeric(0))
  setNames(as.numeric(d[[ncol(d)]]), as.character(d[[1]])) }
relRange <- function(v) if (length(v) < 2 || !all(is.finite(v))) NA_real_ else (max(v) - min(v)) / mean(abs(v))

dirs <- unlist(lapply(file.path(gdxDir, c("EU21", "H12")), list.dirs, recursive = FALSE, full.names = TRUE))
dirs <- dirs[grepl(pat, basename(dirs)) & file.exists(file.path(dirs, "fulldata.gdx"))]

rows <- list()
for (d in dirs) {
  g <- file.path(d, "fulldata.gdx")
  lg <- if (file.exists(file.path(d, "log.txt"))) readLines(file.path(d, "log.txt"), warn = FALSE) else character(0)
  state <- if (!length(lg)) "nolog" else if (any(grepl("REMIND run finished", lg, fixed = TRUE))) "finished" else "running"
  # the LAST run summary in the log (a restarted run appends a second one)
  crashed <- any(grepl("abort.gdx exists", lg, fixed = TRUE)) &&
             tail(grep("abort.gdx (exists|does not exist)", lg), 1) %in% grep("abort.gdx exists", lg)

  sm <- sym(g, "p80_surplusMax_iter"); tol <- sym(g, "p80_surplusMaxTolerance")
  last <- max(as.integer(sm[[2]]))
  s <- sm[as.integer(sm[[2]]) == last, ]
  r <- as.numeric(s[[4]]) / as.numeric(tol[[2]])[match(s[[1]], tol[[1]])]
  yr <- as.integer(s[[3]])
  tx <- sym(g, "p80_convNashTaxrev_iter"); txTol <- scalar(g, "cm_TaxConv_tolerance")
  tx <- tx[as.integer(tx[[1]]) == last, ]
  tr <- abs(as.numeric(tx[[4]])) / txTol; ty <- as.integer(tx[[2]])
  overTx <- tx[tr > 1, ]
  budg <- series(g, "o45_diff_to_Budg"); anc <- series(g, "p45_pfmAnchor_iter"); mxp <- series(g, "p45_pfmMaxPrice_iter")
  tailIt <- as.character(seq(max(1, last - TAIL + 1), last))
  bTol <- scalar(g, "cm_budgetCO2_absDevTol")
  bandIt <- seq(max(1, last - BAND + 1), last)
  ap <- sym(g, "p45_pfmAnchorPath_iter")
  a50 <- if (is.null(ap)) numeric(0) else {
    x <- ap[as.integer(ap[[2]]) == 2050 & as.integer(ap[[1]]) %in% bandIt, ]; as.numeric(x[[3]]) * 272 }
  pk <- series(g, "o45_peakBudgYr_Itr"); pk <- pk[names(pk) %in% as.character(bandIt)]

  rows[[length(rows) + 1]] <- data.frame(
    resolution = basename(dirname(d)), dir = basename(d),
    scenario = sub("_\\d{4}-\\d{2}-\\d{2}_.*$", "", basename(d)),
    state = state, crashed = crashed, lastIteration = last, iterationCap = scalar(g, "cm_iteration_max"),
    boundRebuild = scalar(g, "cm_pfmBoundRebuild"), pfmConverged = scalar(g, "pm_pfmConverged"),
    surplusEarlyMax = max(r[yr <= EARLY]), surplusEarlyOver = sum(r[yr <= EARLY] > 1),
    surplusLateMax = max(r[yr > EARLY]), surplusLateOver = sum(r[yr > EARLY] > 1),
    surplusOverCells = paste(unique(paste0(s[[1]][r > 1], ":", yr[r > 1])), collapse = " "),
    taxEarlyMax = max(tr[ty <= EARLY]), taxEarlyOver = sum(tr[ty <= EARLY] > 1),
    taxLateMax = max(tr[ty > EARLY]), taxLateOver = sum(tr[ty > EARLY] > 1),
    taxOverCells = paste(paste0(overTx[[3]], ":", overTx[[2]]), collapse = " "),
    budgetMissEnd = if (length(budg)) unname(budg[as.character(last)]) else NA_real_,
    budgetMissTailMax = if (length(budg)) max(abs(budg[intersect(tailIt, names(budg))])) else NA_real_,
    budgetTol = bTol,
    anchorTailRange = relRange(anc[intersect(tailIt, names(anc))]),
    maxPriceTailRange = relRange(mxp[intersect(tailIt, names(mxp))]),
    anchor2050BandMin = if (length(a50)) min(a50) else NA_real_,
    anchor2050BandMax = if (length(a50)) max(a50) else NA_real_,
    budgetMissBandMin = if (length(budg)) min(budg[names(budg) %in% as.character(bandIt)]) else NA_real_,
    budgetMissBandMax = if (length(budg)) max(budg[names(budg) %in% as.character(bandIt)]) else NA_real_,
    peakYearSwitches = if (length(pk) > 1) sum(diff(pk) != 0) else NA_integer_,
    peakYearsInBand = if (length(pk)) paste(sort(unique(pk)), collapse = "/") else NA_character_,
    stringsAsFactors = FALSE)
}
out <- do.call(rbind, rows)
f <- file.path("output/pfm", group, "coupling", "convergence-audit.rds")
saveRDS(list(runs = out, earlyThrough = EARLY, tail = TAIL, band = BAND, generated = format(Sys.time(), "%Y-%m-%dT%H:%M")), f)
show <- out; show$scenario <- sub("SSP2-(EU21-)?PkBudg1000-", "", show$scenario)
print(show[, c("resolution", "scenario", "state", "crashed", "lastIteration", "surplusEarlyMax", "surplusEarlyOver",
               "surplusLateOver", "taxEarlyOver", "taxLateOver", "budgetMissEnd", "budgetMissTailMax",
               "anchorTailRange", "maxPriceTailRange")], row.names = FALSE, digits = 3)
cat("wrote", f, "\n")
