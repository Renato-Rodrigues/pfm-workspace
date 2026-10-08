# The Phase 3 gate of design note 0005 on the EU21V6GATE runs, and the same checks on the H12 wave-1 runs (COUPLING.md 14):
#   0. the REMIND 3.7.1 bases (-NPi2025, -PkBudg1000, -PFMgateRef) finished;
#   1. the theta = 0 null on the v6 fork reproduces the uncoupled uniform-price run -PFMgateRef on the
#      SAME REMIND version within SCENARIOS.md 3.1 (max |dP| < $1 per pm_taxCO2eq cell, cumulative CO2
#      within 0.2 Gt), with phi and the share path exactly 1. Since the fork moved to REMIND 3.7.1
#      (2026-10-07) the v5 null (3.7.0.dev) is no longer a valid comparator; it is shown for information;
#   2. one EU21 rule-B run (-PFMlevelBfix-v6) converges, with the share path loaded and k in its history;
#   3. one EU21 rule-C run (-PFMlevelC-v6) converges with a rebuild error near 1e-6 on call iterations;
#   plus, for every run: no infeasibility code, the peak-budget record (E11), the mode bind share (E12).
#   Rscript analysis/v6/phase3Gate.R [REMIND output folder] [--res EU21|H12]
#   e.g. on the cluster:  Rscript analysis/v6/phase3Gate.R models/remind_pfm-EU21/output
#                         Rscript analysis/v6/phase3Gate.R models/remind_pfm-H12/output --res H12
#        on the workstation, after syncing:  Rscript analysis/v6/phase3Gate.R output/remind-runs/v6/EU21
#                                            Rscript analysis/v6/phase3Gate.R output/remind-runs/v6/H12 --res H12
# The same seven runs are looked for in this folder: at EU21 those of the start group EU21V371, at H12
# those of V6W1H12 (its 3.7.1 bases and the four rows of the same names; H12 titles carry no infix).
# The v5 null (SSP2[-EU21]-PkBudg1000-PFMgate) also in output/remind-runs/v5/<res>. The latest folder of
# each title is used. Default folder: models/remind_pfm-<res>/output.
a <- commandArgs(trailingOnly = TRUE)
iRes <- match("--res", a)
res <- if (is.na(iRes)) "EU21" else a[iRes + 1]
if (!res %in% c("EU21", "H12")) stop("--res must be EU21 or H12, got '", res, "'")
pos <- if (is.na(iRes)) a else a[-c(iRes, iRes + 1)]
outDir <- if (length(pos)) pos[1] else file.path(paste0("models/remind_pfm-", res), "output")
pre <- if (res == "EU21") "SSP2-EU21-" else "SSP2-"   # H12 titles carry no resolution infix
TCO2 <- 1000 / (44 / 12)
`%||%` <- function(a, b) if (is.null(a)) b else a
latest <- function(dirs, title) {
  hit <- unlist(lapply(dirs, function(d) Sys.glob(file.path(d, paste0(title, "_20*")))))
  hit <- hit[file.exists(file.path(hit, "fulldata.gdx"))]
  if (!length(hit)) NA_character_ else hit[order(basename(hit), decreasing = TRUE)][1]
}
rd <- function(run, sym) tryCatch(suppressWarnings(gdx::readGDX(file.path(run, "fulldata.gdx"), sym, react = "silent")),
                                  error = function(e) NULL)
num <- function(x) if (is.null(x)) NA_real_ else as.numeric(x)
verdict <- list()
say <- function(...) cat(..., "\n", sep = "")
pass <- function(name, ok, detail) { verdict[[name]] <<- ok; say(sprintf("  [%s] %s: %s", if (isTRUE(ok)) "PASS" else "FAIL", name, detail)) }

runs <- paste0(pre, c(null = "PkBudg1000-PFMgate-v6", nullB = "PkBudg1000-PFMgateBfix-v6",
                      ruleB = "PkBudg1000-PFMlevelBfix-v6", ruleC = "PkBudg1000-PFMlevelC-v6",
                      ref = "PkBudg1000-PFMgateRef", npi = "NPi2025", base = "PkBudg1000"))
names(runs) <- c("null", "nullB", "ruleB", "ruleC", "ref", "npi", "base")
path <- vapply(runs, function(t) latest(outDir, t), character(1))
v5null <- latest(c(outDir, file.path("output/remind-runs/v5", res)), paste0(pre, "PkBudg1000-PFMgate"))
say("== resolution ", res, ", runs in ", outDir)
version <- function(run) {   # the set c_model_version in fulldata.gdx, e.g. "3-7-0-dev29"
  if (is.na(run)) return(NA_character_)
  v <- tryCatch({ g <- gamstransfer::Container$new(); g$read(file.path(run, "fulldata.gdx"), "c_model_version")
                  as.character(g["c_model_version"]$records[[1]][1]) }, error = function(e) NA_character_)
  if (length(v) && !is.na(v)) v else NA_character_
}
ver <- vapply(c(path, v5null = v5null), version, character(1))
say("== runs (REMIND version)")
for (k in names(ver)) say(sprintf("  %-6s %-10s %s", k, ver[[k]], c(path, v5null = v5null)[[k]]))

compareNull <- function(a, b, label, gate) {
  pa <- rd(a, "pm_taxCO2eq") * TCO2; pb <- rd(b, "pm_taxCO2eq") * TCO2
  y <- intersect(magclass::getYears(pa), magclass::getYears(pb))
  y <- y[as.integer(sub("y", "", y)) >= 2030 & as.integer(sub("y", "", y)) <= 2100]
  dP <- abs(as.numeric(pa[, y, ]) - as.numeric(pb[, y, ]))
  ca <- num(rd(a, "pm_actualbudgetco2")[, "y2100", ]); cb <- num(rd(b, "pm_actualbudgetco2")[, "y2100", ])
  dPrice <- sprintf("%d cells 2030-2100, %d differ, max |dP| $%.2f, mean $%.2f", length(dP), sum(dP > 1e-6), max(dP), mean(dP))
  dCum <- sprintf("%.2f vs %.2f Gt", ca, cb)
  if (gate) {
    pass(paste(label, "prices"), max(dP) < 1, dPrice)
    pass(paste(label, "cumulative CO2 2100"), abs(ca - cb) < 0.2, dCum)
  } else say(sprintf("  [info] %s: prices %s; cumulative CO2 2100 %s", label, dPrice, dCum))
}

common <- function(run, label) {
  if (is.na(run)) { pass(paste(label, "present"), FALSE, "no finished run (fulldata.gdx) found"); return(invisible()) }
  infes <- num(rd(run, "pm_pfmInfesCode")); conv <- num(rd(run, "pm_pfmConverged"))
  d <- rd(run, "p45_pfmDelta_iter"); d <- if (is.null(d)) numeric(0) else as.numeric(d); d <- d[d != 0]
  d <- rle(d)$values   # GAMS repeats the last call's delta on the iterations between calls
  pass(paste(label, "no infeasibility"), isTRUE(infes == 0), paste0("pm_pfmInfesCode = ", infes))
  pass(paste(label, "converged"), isTRUE(conv == 1),
       paste0("pm_pfmConverged = ", conv, "; delta sequence ", paste(signif(utils::tail(d, 6), 3), collapse = " -> ")))
  np <- rd(run, "p45_pfmBudgetNoPeak_iter"); pk <- rd(run, "p45_pfmBudgetPeak_iter"); py <- rd(run, "p45_pfmBudgetPeakYr_iter")
  if (!is.null(pk)) {
    pk <- as.numeric(pk); py <- as.numeric(py); np <- as.numeric(np); i <- max(which(pk != 0), 0)
    if (i > 0) say(sprintf("  [info] %s cumulative CO2 peak %.1f Gt in %d%s (E11)", label, pk[i], py[i],
                           if (isTRUE(np[i] == 1)) " - NEVER PEAKED" else ""))
  }
  bs <- rd(run, "p45_pfmBindShare_iter"); if (!is.null(bs)) { bs <- as.numeric(bs); bs <- bs[bs != 0]
    if (length(bs)) say(sprintf("  [info] %s bind share (last iteration) %.3f (E12)", label, utils::tail(bs, 1))) }
}

say("\n== 0. the REMIND 3.7.1 bases")
for (k in c("npi", "base", "ref")) {
  pass(paste(k, "finished on REMIND 3.7.1"), !is.na(path[[k]]) && grepl("^3-7-1", ver[[k]]),
       if (is.na(path[[k]])) "no finished run (fulldata.gdx) found" else sprintf("REMIND %s", ver[[k]]))
}
pass("null and -PFMgateRef on the same REMIND version", !is.na(ver[["null"]]) && identical(ver[["null"]], ver[["ref"]]),
     sprintf("%s vs %s", ver[["null"]], ver[["ref"]]))

say("\n== 1. the theta = 0 null on the v6 fork")
common(path[["null"]], "null")
if (!is.na(path[["null"]]) && !is.na(path[["ref"]])) compareNull(path[["null"]], path[["ref"]], "null vs -PFMgateRef:", TRUE)
if (!is.na(path[["null"]]) && !is.na(v5null)) compareNull(path[["null"]], v5null, "null vs the v5 null (older REMIND, not gated)", FALSE)
if (!is.na(path[["null"]])) {
  phi <- num(rd(path[["null"]], "p45_regiDiff_phi")); pp <- num(rd(path[["null"]], "p45_pfmPhiPath"))
  pass("null: phi and the path are 1", isTRUE(all(abs(phi - 1) < 1e-12)) && isTRUE(all(abs(pp[pp != 0] - 1) < 1e-12)),
       sprintf("phi in [%s], path in [%s]", paste(signif(range(phi), 4), collapse = ", "), paste(signif(range(pp[pp != 0]), 4), collapse = ", ")))
}
say("\n== (the held-price null)"); common(path[["nullB"]], "nullB")
if (!is.na(path[["nullB"]]) && !is.na(path[["null"]])) {   # SCENARIOS.md 4.2a: "more than a few Gt" = the pinning failed
  cb <- num(rd(path[["nullB"]], "pm_actualbudgetco2")[, "y2100", ]); cn <- num(rd(path[["null"]], "pm_actualbudgetco2")[, "y2100", ])
  pass("nullB pinning (within 5 Gt of the null)", isTRUE(abs(cb - cn) < 5),
       sprintf("cumulative CO2 2100 %.1f vs %.1f Gt (%+.1f; v5 +2.1 EU21 / +3.5 H12)", cb, cn, cb - cn))
}

say("\n== 2. rule B with the share path")
common(path[["ruleB"]], "ruleB")
for (k in c("ruleB", "ruleC")) {
  run <- path[[k]]; if (is.na(run)) next
  pp <- rd(run, "p45_pfmPhiPath")
  hf <- c(file.path(run, "pfm-phi-history.rds"), file.path(run, "pfm", "pfm-phi-history.rds"))
  hf <- hf[file.exists(hf)]
  h <- if (length(hf)) tryCatch(readRDS(hf[1]), error = function(e) NULL) else NULL
  ok <- !is.null(pp) && any(as.numeric(pp) < 1 - 1e-9) && !is.null(h) && identical(h[[length(h)]]$formulation, "v6-anchor")
  last <- if (!is.null(h)) h[[length(h)]] else NULL
  kk <- if (!is.null(last$strength)) last$strength[last$strength$year %in% c(2050, 2100), ] else NULL
  pass(paste(k, "share path loaded, v6 history"), ok,
       paste0(length(h), " PFM call(s); ", if (!is.null(kk)) paste(sprintf("%s %d k %.3f", kk$sector, kk$year, kk$k), collapse = " | ") else "no strength record",
              if (!is.null(pp)) sprintf("; 2050 path in GAMS: min %.3f median %.3f", min(as.numeric(pp[, "y2050", ])), stats::median(as.numeric(pp[, "y2050", ]))) else ""))
  if (!is.null(h)) say(sprintf("  [info] %s path deltas: %s (all-period %s; alpha %s)", k,
                              paste(signif(vapply(h, function(e) e$delta %||% NA_real_, 1), 3), collapse = " -> "),
                              signif(last$deltaAll %||% NA, 3), paste(vapply(h, function(e) e$alpha %||% NA_real_, 1), collapse = ",")))
}

say("\n== 3. rule C: the rebuild from the share path")
common(path[["ruleC"]], "ruleC")
if (!is.na(path[["ruleC"]])) {
  bc <- rd(path[["ruleC"]], "p45_pfmBoundCheck_iter"); bc <- if (is.null(bc)) numeric(0) else as.numeric(bc); bc <- bc[bc != 0]
  pass("ruleC rebuild check", length(bc) > 0 && max(bc) < 1e-4,
       if (length(bc)) sprintf("p45_pfmBoundCheck_iter on call iterations: max %.2e (target ~1e-6; a value after a non-optimal iteration may be larger)", max(bc)) else "no call-iteration record")
}

ok <- all(unlist(verdict))
say("\n== GATE ", if (ok) "PASSED" else "NOT PASSED", " (", sum(unlist(verdict)), " of ", length(verdict), " checks)")
