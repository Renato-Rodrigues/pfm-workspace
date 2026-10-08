# The checklist after a coupled batch lands, as one command (design note 0005 F4).
#
#   Rscript analysis/coupled/runCoupledStage.R <group> [runsDir] [--allow-skipped] [--skip-extract]   # from the project root
#
#   <group>          the Run-Group the batch belongs to (output/pfm/<group>/coupling/ receives the artifacts)
#   [runsDir]        default output/remind-runs/<group>
#   --allow-skipped  go on when some runs are still in flight (they are listed, and left out)
#   --skip-extract   reuse the existing coupled-runs.rds (after fixing a later script)
#
# In order:
#   1. extractCoupledResults   -> coupled-runs.rds, and its flags
#   2. the admission rules, which STOP the chain instead of being left to the reader:
#        - PITFALLS 25:  a run that has not finished and fails the 25a test is skipped; any
#                        skipped run stops the chain (unless --allow-skipped)
#        - PITFALLS 25a: a FINISHED run with an early-period (<= 2060) market cell over REMIND's
#                        tolerance stops the chain - it finished, and still cannot be quoted
#   3. coupledBatchFacts (coupled-facts.json, stamped with the Run-Group), coupledCostsAndAbatement,
#      heldBudgetPrices, ruleCBoundFreeze, coupledRunConvergence, runProvenance - each as its own
#      Rscript, so one that fails stops the chain with its exit status.
# A budget-forced run that never peaks (PITFALLS 26) is reported by step 1 but does not stop the chain:
# it is a property of the run to disclose, decided per run (E11).
#
# Exit status 0 only when every step ran and nothing was refused. Project tooling, not package code:
# it orchestrates analysis/ scripts until F5 moves them into pfm, when this becomes
# pfmRun(stage = "coupled").

`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
allowSkipped <- "--allow-skipped" %in% args
skipExtract <- "--skip-extract" %in% args
args <- setdiff(args, c("--allow-skipped", "--skip-extract"))
if (!length(args)) stop("usage: runCoupledStage.R <group> [runsDir] [--allow-skipped] [--skip-extract]")
if (!file.exists("config.yml")) stop("run from the project root (no config.yml here)")
group <- args[1]
runsDir <- if (length(args) >= 2) args[2] else file.path("output", "remind-runs", group)
say <- function(...) cat("[coupled-stage] ", ..., "\n", sep = "")

artFile <- file.path("output", "pfm", group, "coupling", "coupled-runs.rds")
if (skipExtract && file.exists(artFile)) {
  say("1/3 extract: skipped (--skip-extract), reading ", artFile)
  art <- readRDS(artFile)
} else {
  say("1/3 extract: ", runsDir, " -> output/pfm/", group, "/coupling/")
  ex <- new.env()
  sys.source("analysis/coupled/extractCoupledResults.R", envir = ex)
  art <- ex$extractCoupledResults(gdxDir = runsDir, group = group)
}

say("2/3 admission rules")
refuse <- character(0)
if (length(art$inFlight)) {
  msg <- paste0(length(art$inFlight), " run(s) not finished and not admitted (PITFALLS 25): ",
                paste(art$inFlight, collapse = "; "))
  if (allowSkipped) say("  allowed by --allow-skipped: ", msg) else refuse <- c(refuse, msg)
}
live <- art$runs
if (!is.null(live) && "superseded" %in% names(live)) live <- live[!live$superseded, , drop = FALSE]
if (!is.null(live) && all(c("finished", "earlySurplusOver") %in% names(live))) {
  bad <- live[live$finished & is.finite(live$earlySurplusOver) & live$earlySurplusOver > 0, , drop = FALSE]
  if (nrow(bad)) {
    refuse <- c(refuse, paste0(nrow(bad), " finished run(s) with early-period market surplus over ",
                               "tolerance (PITFALLS 25a): ",
                               paste(bad$resolution, bad$scenario, collapse = "; ")))
  }
}
if (length(refuse)) {
  for (r in refuse) say("  REFUSED - ", r)
  say("stopped before the facts: fix or re-run these, or decide them explicitly (SCENARIOS.md section 3)")
  quit(status = 1)
}
say("  admitted: ", nrow(art$runs %||% data.frame()), " run(s)",
    if (length(art$admittedUnfinished)) paste0(", of which ", length(art$admittedUnfinished),
                                              " unfinished on the 25a test") else "")

say("3/3 facts")
rs <- file.path(R.home("bin"), "Rscript")
# v5 keeps its own facts script (the frozen record); later groups use the v6 one, which reads the phi path
# and k from each run's history and tolerates a batch that lands in waves
v5 <- grepl("^v5", group)
steps <- c(list(
  c(if (v5) "analysis/coupled/coupledBatchFacts.R" else "analysis/coupled/coupledBatchFactsV6.R", group, runsDir),
  c("analysis/coupled/coupledCostsAndAbatement.R", group, runsDir),
  c("analysis/coupled/heldBudgetPrices.R", group, runsDir)),
  # v6: the held-budget horn is rule C (level cap, rebuilt); ratio mode is a wave-2 continuity arm
  if (!v5) list(c("analysis/coupled/heldBudgetPrices.R", group, runsDir, "PkBudg1000-PFMlevelC")),
  list(
  c("analysis/coupled/ruleCBoundFreeze.R", group, runsDir),
  c("analysis/coupled/coupledRunConvergence.R", group, runsDir),
  c("analysis/coupled/runProvenance.R", group, runsDir)
))
for (s in steps) {
  say("  ", basename(s[1]))
  st <- system2(rs, shQuote(s))
  if (!identical(as.integer(st), 0L)) {
    say("  FAILED: ", basename(s[1]), " exited ", st, " - the chain stops here")
    quit(status = 1)
  }
}
say("done: output/pfm/", group, "/coupling/coupled-facts.json and the other coupling artifacts")
