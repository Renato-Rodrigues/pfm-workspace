# Turn a coupled REMIND gdx batch into ONE Run-Group artifact.
#
# Why this exists
# ---------------
# `analysis/figures/` is a pure consumer of Run-Group artifacts (analysis/figures/R/artifacts.R): a figure may
# not fit, select or recompute anything, and every read goes through pfmArtifact(group, ...).
# The coupled results arrive as a folder of fulldata.gdx files, which is not that. This
# script is the seam: it reads the gdx once and writes
#
#     output/pfm/<group>/coupling/coupled-runs.rds
#
# so Figures 5a-5c can be pure consumers like every other figure.
#
# It lives in analysis/ for the same reason buildPFMScenarioConfig.R does: project tooling,
# not part of pfm and not part of the REMIND fork.
#
# Reading the gdx
# ---------------
# There is no GAMS Python API and no gamstransfer on this workstation, so this shells out to
# `gdxdump ... format=csv`. Four traps, all of which fail SILENTLY (PITFALLS.md 16):
#   * pm_taxemiMkt is (year, region, market) - transposing it makes a live markup read as
#     identically zero, which is indistinguishable from "the markup is off";
#   * pm_actualbudgetco2 runs to 2150, so the LAST element is not the 2100 figure;
#   * p45_pfmDelta_iter opens with a 1e6 sentinel;
#   * cm_iteration_max is the count actually USED, not the configured cap.
#
# Usage, from the project root:
#   Rscript analysis/coupled/extractCoupledResults.R                 # output/remind-runs/v5 -> output/pfm/v5
#   Rscript analysis/coupled/extractCoupledResults.R output/remind-runs/v5 v5
#
# Re-run it whenever a new coupled batch lands. It is cheap and idempotent.

TCO2 <- 272            # pm_taxCO2eq is T$/GtC; x272 gives US$2005/tCO2 (SCENARIOS.md 9)

# Resolution order, most specific first:
#   GDXDUMP        - explicit override, wins over everything
#   GAMSDIR        - set by the GAMS installer; on Windows it is a ';'-separated list
#                    (e.g. "C:\\Program Files\\GAMS\\51;C:\\Program Files\\GAMS\\51\\gbin")
#   PATH           - Sys.which()
#
# Do NOT add a bare "C:/Program Files/GAMS" fallback. That directory held a GAMS 54.3.1
# system the PIK licence could not run ("license file too old for this version",
# maintenance expired 2026-04) while the working 51.4.0 sits in its `51` subfolder, so a
# fallback pointing at the parent silently picks the wrong one. GAMSDIR is what the
# installer maintains and is the only path worth hard-coding a preference for.
gdxdumpBin <- function() {
  fromGamsDir <- unlist(strsplit(Sys.getenv("GAMSDIR", ""), "[;:]"))
  fromGamsDir <- file.path(fromGamsDir[nzchar(fromGamsDir)], "gdxdump.exe")
  cand <- c(Sys.getenv("GDXDUMP", ""), fromGamsDir, Sys.which("gdxdump"))
  cand <- cand[nzchar(cand)]
  hit <- cand[file.exists(cand) | nzchar(Sys.which(cand))]
  if (!length(hit)) {
    stop("gdxdump not found. Set the GDXDUMP environment variable, or start a shell that ",
         "has GAMSDIR set (a fresh one - the variable is created at install time and an ",
         "older session will not see it).")
  }
  hit[1]
}

#' Read one symbol from a gdx as a data.frame; NULL when the symbol is absent or empty.
readSymbol <- function(gdx, symb, bin = gdxdumpBin()) {
  out <- suppressWarnings(system2(bin, c(shQuote(gdx), paste0("symb=", symb), "format=csv"),
                                  stdout = TRUE, stderr = FALSE))
  if (!length(out) || length(out) < 2) return(NULL)
  txt <- paste(out, collapse = "\n")
  df <- tryCatch(utils::read.csv(text = txt, stringsAsFactors = FALSE),
                 error = function(e) NULL)
  if (is.null(df) || !nrow(df)) return(NULL)
  df
}

#' A gdx scalar as a plain numeric, NA when absent.
readScalar <- function(gdx, symb, bin = gdxdumpBin()) {
  d <- readSymbol(gdx, symb, bin)
  if (is.null(d) || !ncol(d)) return(NA_real_)
  suppressWarnings(as.numeric(d[[ncol(d)]][1]))
}

# Where the "early" period ends, for the market-clearing test below. 2060 because every
# headline in SCENARIOS.md is a peak-budget or 2050 quantity and nothing the paper claims
# rests on post-2060 trade (MODEL.md 7 prohibits scenario differences past ~2060 anyway).
EARLY_THROUGH <- 2060

extractCoupledResults <- function(gdxDir = "output/remind-runs/v5",
                                  group  = "v5",
                                  outRoot = "output/pfm",
                                  acceptUnfinished = TRUE,
                                  verbose = TRUE) {
  bin <- gdxdumpBin()
  say <- function(...) if (isTRUE(verbose)) cat(..., "\n", sep = "")

  resolutions <- list.dirs(gdxDir, recursive = FALSE, full.names = FALSE)
  resolutions <- resolutions[nzchar(resolutions)]
  if (!length(resolutions)) stop("no resolution folders under ", gdxDir)

  runs <- list(); prices <- list(); phis <- list(); conv <- list()
  inFlight <- character(0); admitted <- character(0)

  # A RUNNING run's fulldata.gdx is readable and looks finished. REMIND rewrites it every
  # Nash iteration, so a run still in its loop carries o_modelstat = 2, pm_pfmConverged = 1
  # and a plausible price surface - there is NO symbol in the gdx that distinguishes it from
  # a converged run. Observed 2026-09-14: eight runs mid-loop, every gdx flag clean, prices
  # 20-40% off where they finally landed. The only marker is in log.txt beside it.
  #
  # Three states, not two, and the third matters: a run directory copied WITHOUT its log
  # cannot be confirmed either way. Observed 2026-09-15, when a re-run arrived as a bare
  # fulldata.gdx. Treat it like an unfinished run - admit it only on the market test below -
  # but SAY which it was, because "no log" and "log says still running" are different facts
  # and only one of them is the user's to fix.
  runState <- function(d) {
    lg <- file.path(d, "log.txt")
    if (!file.exists(lg)) return("nolog")
    if (any(grepl("REMIND run finished", readLines(lg, warn = FALSE), fixed = TRUE))) {
      return("finished")
    }
    "running"
  }

  #' Residual market surplus at the last completed Nash iteration, against REMIND's OWN
  #' per-market tolerance (`p80_surplusMaxTolerance`), split at EARLY_THROUGH.
  #'
  #' Returns list(earlyMax, earlyOver, lateMax, lateOver, iter) as ratios of tolerance, so
  #' 1.0 is exactly at tolerance and > 1 is over it.
  #'
  #' This is what decides whether an UNFINISHED run may be used. A REMIND run converges the
  #' near term first and leaves its residual imbalance in the far-future periods, so a run
  #' stopped at iteration ~85 of ~100 can have cleaner early-period market clearing than a
  #' run that finished - measured 2026-09-14, where the five in-flight EU21 runs scored
  #' 0.10-0.44 of tolerance early while several finished runs scored 0.8+.
  surplusAudit <- function(gdx, bin) {
    sm  <- readSymbol(gdx, "p80_surplusMax_iter", bin)
    tol <- readSymbol(gdx, "p80_surplusMaxTolerance", bin)
    na <- list(earlyMax = NA_real_, earlyOver = NA_integer_, lateMax = NA_real_,
               lateOver = NA_integer_, iter = NA_integer_)
    if (is.null(sm) || is.null(tol) || ncol(sm) < 4 || ncol(tol) < 2) return(na)
    mk <- as.character(sm[[1]]); it <- suppressWarnings(as.integer(sm[[2]]))
    yr <- suppressWarnings(as.integer(sm[[3]])); v <- as.numeric(sm[[ncol(sm)]])
    tolV <- as.numeric(tol[[ncol(tol)]])[match(mk, as.character(tol[[1]]))]
    keep <- is.finite(it) & is.finite(yr) & is.finite(v) & is.finite(tolV) & tolV > 0
    if (!any(keep)) return(na)
    last <- max(it[keep])
    sel <- keep & it == last
    r <- v[sel] / tolV[sel]; y <- yr[sel]
    e <- r[y <= EARLY_THROUGH]; l <- r[y > EARLY_THROUGH]
    list(earlyMax  = if (length(e)) max(e) else NA_real_,
         earlyOver = if (length(e)) sum(e > 1) else NA_integer_,
         lateMax   = if (length(l)) max(l) else NA_real_,
         lateOver  = if (length(l)) sum(l > 1) else NA_integer_,
         iter      = last)
  }

  for (res in resolutions) {
    for (d in list.dirs(file.path(gdxDir, res), recursive = FALSE)) {
      gdx <- file.path(d, "fulldata.gdx")
      if (!file.exists(gdx)) next
      nm  <- basename(d)
      scen <- sub("_[0-9]{4}-[0-9]{2}-[0-9]{2}_.*$", "", nm)
      st <- runState(d)
      isFin <- identical(st, "finished")
      au <- surplusAudit(gdx, bin)
      if (!isFin) {
        # An unfinished run is admitted ONLY if its EARLY-period markets clear inside
        # REMIND's own tolerance. That is the whole of the test - it is not a judgement
        # about how far the run got, and a run that finished is not exempt from being
        # reported against the same measure (see `tradeFlags` below).
        why <- if (identical(st, "nolog")) "no log.txt - cannot confirm it finished" else "unfinished"
        okEarly <- isTRUE(is.finite(au$earlyOver) && au$earlyOver == 0)
        if (!isTRUE(acceptUnfinished) || !okEarly) {
          inFlight <- c(inFlight, paste(res, scen))
          say("  ", res, "  ", scen, "   SKIPPED - ", why,
              if (!okEarly) paste0(" AND ", au$earlyOver, " early market(s) over tolerance") else "")
          next
        }
        admitted <- c(admitted, paste0(res, " ", scen, "  [", why, "]"))
        say("  ", res, "  ", scen, "   ADMITTED (", why, ") at iteration ", au$iter,
            " - early surplus ", format(round(au$earlyMax, 2)), "x tolerance, 0 over")
      } else {
        say("  ", res, "  ", scen)
      }

      # --- scalars: what kind of run is this -------------------------------
      sc <- vapply(c("o_modelstat", "cm_pfmTheta", "cm_pfmBindMode", "cm_pfmSectorMarkup",
                     "cm_iterative_target_adj", "cm_taxCO2_regiDiff", "cm_iteration_max",
                     "cm_budgetCO2from2020", "p45_pfmCallCount",
                     "cm_taxCO2_lowerBound_path_gdx_ref",
                     "p45_pfmMarkupWritten", "p45_pfmMarkupSeen", "p45_pfmPhiMktSpread",
                     # NA on every run before 2026-09-14 - the warning did not exist yet.
                     "pm_pfmBudgetWarn", "pm_pfmBudgetWarnDev"),
                   function(s) readScalar(gdx, s, bin), numeric(1))

      # --- cumulative CO2: element "2100", NOT the last element ------------
      bud <- readSymbol(gdx, "pm_actualbudgetco2", bin)
      cum2100 <- NA_real_; peak <- NA_real_; peakYr <- NA_integer_
      if (!is.null(bud) && ncol(bud) >= 2) {
        yr <- suppressWarnings(as.integer(bud[[1]])); v <- as.numeric(bud[[ncol(bud)]])
        ok <- is.finite(yr) & is.finite(v)
        cum2100 <- if (any(yr[ok] == 2100)) v[ok][yr[ok] == 2100][1] else NA_real_
        if (any(ok)) { i <- which.max(v[ok]); peak <- v[ok][i]; peakYr <- yr[ok][i] }
      }

      # --- prices --------------------------------------------------------
      # pm_taxCO2eq is the FLOOR, and since ADR 0042 made the markup symmetric
      # (2026-08-17) it is the price NEITHER market pays. Each market's price is
      # floor + its OWN pm_taxemiMkt entry:
      #
      #   taxCO2eq = pm_taxCO2eq                      <- what MAC curves see
      #   es       = taxCO2eq + pm_taxemiMkt(t,regi,"ES")
      #   ets      = taxCO2eq + pm_taxemiMkt(t,regi,"ETS")
      #
      # `floor` is a DIFFERENT thing and keeps its name: the legislated reference path
      # p45_taxCO2eq_path_gdx_ref, which REMIND max()es pm_taxCO2eq against when
      # cm_taxCO2_lowerBound_path_gdx_ref is on (it is off in the 2026-08-26/29 batch).
      #
      # This file read `es` as the bare floor until 2026-09-11, which understated the
      # household price by up to $118.55 (EU21 -PFMratio 2050) and fed that into five
      # figures and into SCENARIOS.md 4.1. The asymmetric reading was correct only for
      # the pre-2026-08-17 markup, which added to ETS and zeroed ES.
      px <- readSymbol(gdx, "pm_taxCO2eq", bin)
      mk <- readSymbol(gdx, "pm_taxemiMkt", bin)
      pr <- NULL
      if (!is.null(px) && ncol(px) >= 3) {
        pr <- data.frame(year = suppressWarnings(as.integer(px[[1]])),
                         region = as.character(px[[2]]),
                         taxCO2eq = as.numeric(px[[ncol(px)]]) * TCO2,
                         stringsAsFactors = FALSE)
        # (year, region, market) - transposing this is PITFALLS.md 16
        mkup <- function(market) {
          out <- rep(0, nrow(pr))
          if (is.null(mk) || ncol(mk) < 4) return(out)
          m <- mk[as.character(mk[[3]]) == market, , drop = FALSE]
          if (!nrow(m)) return(out)
          key <- paste(as.integer(m[[1]]), as.character(m[[2]]))
          v <- as.numeric(m[[ncol(m)]])[match(paste(pr$year, pr$region), key)] * TCO2
          v[is.na(v)] <- 0
          v
        }
        pr$markupES  <- mkup("ES")
        pr$markupETS <- mkup("ETS")
        pr$es  <- pr$taxCO2eq + pr$markupES
        pr$ets <- pr$taxCO2eq + pr$markupETS
        # kept so downstream code written against the old column keeps working, and
        # so "the markup" in a figure caption is unambiguous about which market
        pr$markup <- pr$markupETS
        # the legislated-policy floor, to detect where it was not applied
        fl <- readSymbol(gdx, "p45_taxCO2eq_path_gdx_ref", bin)
        pr$floor <- NA_real_
        if (!is.null(fl) && ncol(fl) >= 3) {
          key <- paste(as.integer(fl[[1]]), as.character(fl[[2]]))
          pr$floor <- as.numeric(fl[[ncol(fl)]])[match(paste(pr$year, pr$region), key)] * TCO2
        }
        pr$scenario <- scen; pr$resolution <- res
        prices[[nm]] <- pr
      }

      # --- phi, economy-wide and per market --------------------------------
      ph <- readSymbol(gdx, "p45_regiDiff_phi", bin)
      pm <- readSymbol(gdx, "p45_pfmPhiMkt", bin)
      if (!is.null(ph) && ncol(ph) >= 2) {
        p <- data.frame(region = as.character(ph[[1]]),
                        phi = as.numeric(ph[[ncol(ph)]]),
                        scenario = scen, resolution = res, stringsAsFactors = FALSE)
        p$phiETS <- NA_real_; p$phiES <- NA_real_
        if (!is.null(pm) && ncol(pm) >= 3) {
          reg <- as.character(pm[[1]]); mkt <- as.character(pm[[2]])
          val <- as.numeric(pm[[ncol(pm)]])
          p$phiETS <- val[match(paste(p$region, "ETS"), paste(reg, mkt))]
          p$phiES  <- val[match(paste(p$region, "ES"),  paste(reg, mkt))]
        }
        phis[[nm]] <- p
      }

      # --- convergence: drop the 1e6 sentinel ------------------------------
      dl <- readSymbol(gdx, "p45_pfmDelta_iter", bin)
      if (!is.null(dl) && ncol(dl) >= 2) {
        v <- as.numeric(dl[[ncol(dl)]]); v <- v[is.finite(v) & v < 1e5]
        if (length(v)) conv[[nm]] <- data.frame(
          scenario = scen, resolution = res, step = seq_along(v), delta = v,
          stringsAsFactors = FALSE)
      }

      bs <- readSymbol(gdx, "p45_pfmBindShare_iter", bin)
      bindShare <- if (!is.null(bs) && ncol(bs) >= 2) {
        v <- as.numeric(bs[[ncol(bs)]]); if (length(v)) v[length(v)] else NA_real_
      } else NA_real_

      runs[[nm]] <- data.frame(
        dir = nm, scenario = scen, resolution = res,
        finished = isFin, nashIter = au$iter,
        earlySurplusMax = au$earlyMax, earlySurplusOver = au$earlyOver,
        lateSurplusMax = au$lateMax, lateSurplusOver = au$lateOver,
        modelstat = sc[1], theta = sc[2], bindMode = sc[3], sectorMarkup = sc[4],
        adj = sc[5], regiDiff = sc[6], iterations = sc[7], budget = sc[8],
        pfmCalls = sc[9], floorSwitch = sc[10],
        markupWritten = sc[11], markupSeen = sc[12], phiMktSpread = sc[13],
        budgetWarn = sc[14], budgetWarnDev = sc[15],
        cum2100 = cum2100, peak = peak, peakYear = peakYr, bindShare = bindShare,
        stringsAsFactors = FALSE)
    }
  }

  # ── one run per (resolution, scenario): keep the NEWEST ──────────────────────
  # A re-run lands beside its predecessor rather than replacing it - the folder name carries a
  # timestamp, so `SSP2-PkBudg1000-PFMlevelC` legitimately exists twice. `runs` is keyed on the
  # directory and survives that, but `prices`, `phi` and `convergence` carry only
  # (scenario, resolution), so both vintages would concatenate into one scenario and every
  # figure filtering on it would silently read a mixture of two runs.
  #
  # Newest wins, because a re-run exists to supersede. The choice is REPORTED, never silent,
  # and the superseded directory stays in `runs` (flagged) so nothing disappears without trace.
  stamp <- function(nm) {
    s <- regmatches(nm, regexpr("[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}[.][0-9]{2}[.][0-9]{2}$", nm))
    if (!length(s)) return(as.POSIXct(NA))
    as.POSIXct(s, format = "%Y-%m-%d_%H.%M.%S", tz = "UTC")
  }
  if (length(runs)) {
    key <- vapply(runs, function(r) paste(r$resolution, r$scenario), character(1))
    ts  <- as.POSIXct(vapply(names(runs), function(n) as.numeric(stamp(n)), numeric(1)),
                      origin = "1970-01-01", tz = "UTC")
    superseded <- character(0)
    for (k in unique(key[duplicated(key)])) {
      sib <- names(runs)[key == k]
      keep <- sib[which.max(ts[key == k])]
      drop <- setdiff(sib, keep)
      superseded <- c(superseded, drop)
      say("  DUPLICATE ", k, " - keeping ", keep)
      for (d in drop) say("    superseded: ", d)
    }
    if (length(superseded)) {
      prices[superseded] <- NULL; phis[superseded] <- NULL; conv[superseded] <- NULL
      for (d in superseded) runs[[d]]$superseded <- TRUE
    }
    for (n in names(runs)) if (is.null(runs[[n]]$superseded)) runs[[n]]$superseded <- FALSE
    # traceability: which directory each price/phi/convergence row actually came from
    for (n in names(prices)) prices[[n]]$dir <- n
    for (n in names(phis))   phis[[n]]$dir   <- n
    for (n in names(conv))   conv[[n]]$dir   <- n
  }

  bind <- function(x) if (length(x)) do.call(rbind, c(x, list(make.row.names = FALSE))) else NULL

  art <- list(
    runs        = bind(runs),
    prices      = bind(prices),
    phi         = bind(phis),
    convergence = bind(conv),
    tCO2Factor  = TCO2,
    inFlight    = inFlight,
    admittedUnfinished = admitted,
    earlyThrough = EARLY_THROUGH,
    source      = normalizePath(gdxDir, mustWork = FALSE),
    generated   = Sys.time())

  # A run whose floor switch is on but whose family skips the floor - PITFALLS.md 17.
  if (!is.null(art$prices)) {
    p <- art$prices
    # Compare the LEGISLATED floor against pm_taxCO2eq, which is the quantity REMIND's
    # Step IV.3 applies max() to - not against a market price, which carries a markup
    # Step IV.3 never sees.
    #
    # GATED ON THE SWITCH. The defect this detects is "cm_taxCO2_lowerBound_path_gdx_ref
    # is ON but this run's family skips Step IV.3" (PITFALLS.md 17). With the switch OFF
    # a price below the reference path is the modelling choice, not a violation - and the
    # switch is 0 on all 40 runs of the 2026-08-26/29 batch, where an ungated check
    # reported 38 phantom violations. SCENARIOS.md 6.3.
    onRuns <- if (!is.null(art$runs)) {
      art$runs$scenario[is.finite(art$runs$floorSwitch) & art$runs$floorSwitch > 0.5]
    } else character(0)
    v <- p[p$scenario %in% onRuns &
             is.finite(p$floor) & p$floor > 0.01 & p$year >= 2030 &
             p$taxCO2eq < p$floor - 0.01, ]
    art$floorViolations <- if (nrow(v)) stats::aggregate(
      list(nBelowFloor = v$taxCO2eq),
      by = list(scenario = v$scenario, resolution = v$resolution),
      FUN = length) else data.frame()
  }

  outDir <- file.path(outRoot, group, "coupling")
  dir.create(outDir, recursive = TRUE, showWarnings = FALSE)
  f <- file.path(outDir, "coupled-runs.rds")
  saveRDS(art, f)
  say("wrote ", f, ": ", nrow(art$runs), " runs, ", nrow(art$prices), " price rows")
  if (length(admitted)) {
    say("  ", length(admitted), " unfinished run(s) ADMITTED on the early-market test:")
    for (x in admitted) say("    ", x)
  }
  if (length(inFlight)) {
    say("  ", length(inFlight), " run(s) SKIPPED - re-run this script when they land:")
    for (x in inFlight) say("    ", x)
  }
  # Every run, finished or not, is reported against the same market-clearing measure - except
  # superseded ones: their warnings describe a run nothing reads (2026-09-23, the pre-fix rule-C arms
  # were being reported as live failures beside the re-runs that replaced them).
  live <- if (!is.null(art$runs)) art$runs[!art$runs$superseded, ] else NULL
  if (!is.null(live)) {
    bad <- live[is.finite(live$earlySurplusOver) & live$earlySurplusOver > 0, ]
    if (nrow(bad)) {
      say("  ", nrow(bad), " run(s) carry EARLY-period market surplus over tolerance:")
      for (i in seq_len(nrow(bad))) say("    ", bad$resolution[i], " ", bad$scenario[i],
        "  ", bad$earlySurplusOver[i], " cell(s), worst ", format(round(bad$earlySurplusMax[i], 2)), "x",
        if (!bad$finished[i]) "  (also unfinished)" else "  (FINISHED - this one is not a copy artefact)")
    }
  }
  # A PEAK budget is failed by a run whose cumulative CO2 is still rising at the horizon end,
  # whatever its 2100 value or pm_pfmBudgetWarn says (PITFALLS.md 26, TODO item 32).
  if (!is.null(live) && all(c("peakYear", "adj") %in% names(live))) {
    hz <- live[is.finite(live$adj) & live$adj == 9 & is.finite(live$peakYear) &
                 live$peakYear >= max(live$peakYear, na.rm = TRUE) & live$peakYear >= 2150, ]
    if (nrow(hz)) {
      say("  ", nrow(hz), " budget-forced run(s) NEVER PEAK - cumulative CO2 still rising at ", max(hz$peakYear), ":")
      for (i in seq_len(nrow(hz))) say("    ", hz$resolution[i], " ", hz$scenario[i], "  peak ",
                                        format(round(hz$peak[i], 1)), " Gt at ", hz$peakYear[i])
    }
  }
  invisible(art)
}

if (!interactive() && identical(environment(), globalenv())) {
  a <- commandArgs(trailingOnly = TRUE)
  extractCoupledResults(gdxDir = if (length(a) > 0) a[1] else "output/remind-runs/v5",
                        group  = if (length(a) > 1) a[2] else "v5")
}
