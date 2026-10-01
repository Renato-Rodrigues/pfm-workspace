# Validate a PFM coupling scenario config before anything is submitted.
#
# Every check here corresponds to a defect that actually shipped. Each one produced a
# run that completed and looked fine:
#   * carbonprice not functionalForm -> cm_taxCO2_regiDiff = 11 is INERT, run silently
#     uncoupled (three scenarios, found only by reading gdx symbol lists)
#   * path_gdx_ref naming a scenario absent from the file -> dangling reference
#   * a coupled row with no bind mode, or bind mode 2 with no reference run
#   * rows sheared by a hand-appended column
#
# Lives in analysis/, NOT in models/remind_pfm/: project tooling, not committed to the REMIND fork.
#
# Usage, from the project root:  Rscript analysis/run-groups/validatePFMScenarioConfig.R [path/to/csv]
# Exit code 1 on any ERROR, so it can gate a submission.

`%||%` <- function(a, b) if (is.null(a) || !length(a) || is.na(a)) b else a

validatePFMScenarioConfig <- function(file = "models/remind_pfm/config/scenario_config_PFM.csv",
                                      verbose = TRUE) {
  errs <- character(0); warns <- character(0); notes <- character(0)
  err <- function(...) errs  <<- c(errs,  paste0(...))
  wrn <- function(...) warns <<- c(warns, paste0(...))

  if (!file.exists(file)) stop("scenario config not found: ", file)
  raw  <- readLines(file, warn = FALSE)
  body <- raw[nzchar(trimws(raw)) & !grepl("^#", raw)]
  if (!length(body)) stop("no non-comment rows in ", file)

  # strsplit() DROPS trailing empty fields, so a row whose last columns are blank looks
  # short and would fall out of every check - which is exactly how an uncoupled baseline
  # becomes invisible and then shows up as a dangling reference. Sentinel, split, drop.
  # The sentinel must be NON-EMPTY: strsplit("a;b;", ";") already drops the trailing
  # empty, so appending a bare ";" and removing the last element deletes a real field.
  splitRow <- function(x) {
    f <- strsplit(paste0(x, ";"), ";", fixed = TRUE)[[1]]
    f[-length(f)]
  }
  hdr  <- splitRow(body[1])
  rows <- body[-1]
  nCol <- length(hdr)

  # --- 1. field counts --------------------------------------------------------
  nf  <- vapply(lapply(rows, splitRow), length, integer(1))
  for (i in which(nf != nCol)) {
    err("row ", i + 1, " (", substr(rows[i], 1, 30), ") has ", nf[i],
        " fields, header has ", nCol)
  }

  parse <- function(r) { f <- splitRow(r); length(f) <- nCol
                         stats::setNames(as.list(f), hdr) }
  recs   <- lapply(rows[nf == nCol], parse)
  titles <- vapply(recs, function(r) r$title %||% "", character(1))
  # SEPARATOR ROWS ARE CHECKED TOO, and then dropped. They are the rows most likely to carry an
  # illegal character, because they are typed by hand as section headings - and REMIND's own
  # reader aborts the WHOLE file on one of them.
  for (t in titles[nzchar(titles)]) {
    if (!grepl("^[A-Za-z0-9_-]+$", t)) {
      err("title '", t, "' has characters REMIND rejects - readCheckScenarioConfig() allows ",
          "only letters, digits, '_' and '-', and stops the whole read on the first offender")
    }
  }
  keep   <- nzchar(titles) & !grepl("^_+", titles)   # skip separator rows
  recs   <- recs[keep]; titles <- titles[keep]

  # --- 2. duplicate titles ----------------------------------------------------
  dup <- titles[duplicated(titles)]
  if (length(dup)) err("duplicate scenario title(s): ",
                       paste(unique(dup), collapse = ", "))

  # --- 2a. what start.R accepts -----------------------------------------------
  # selectScenarios() matches a start tag with grepl("(^|,)TAG($|,)"), so a space after a comma
  # makes " H12" a DIFFERENT tag from "H12". `startgroup=H12` then silently skips those rows -
  # no error, just a short run list nobody counted. Real, on 2026-09-18.
  for (i in seq_along(recs)) {
    t <- titles[i]
    st <- recs[[i]]$start %||% ""
    if (grepl("[[:space:]]", st)) {
      err(t, ": start = '", st, "' contains whitespace; start.R matches tags exactly, so ",
          "'", trimws(strsplit(st, ",")[[1]][2] %||% ""), "' would never be selected")
    }
  }

  # --- 2b. warm starts must not point across price paths ----------------------
  # path_gdx is the starting point. Pointing a FIXPRICE run at a run on a DIFFERENT anchor
  # (the unforced $75 path, or the budget-forced anchor) is legal and merely slow; pointing it
  # at one on the same anchor is free. Warn, do not fail.
  for (i in seq_along(recs)) {
    t <- titles[i]; g <- trimws(recs[[i]]$path_gdx %||% "")
    if (!nzchar(g) || !grepl("fix$|fix(Th[0-9]+|GapC|Min)$", t)) next
    if (!grepl("fix", g) && !grepl("PFMgate$", g)) {
      wrn(t, ": warm start '", g, "' is on a different price path than the pinned anchor; ",
          "-PFMgateBfix or -PFMlevelBfix is closer")
    }
  }

  # --- 3. dangling gdx references --------------------------------------------
  gdxCols <- intersect(c("path_gdx", "path_gdx_ref", "path_gdx_refpolicycost",
                         "path_gdx_carbonprice", "path_gdx_bau"), hdr)
  for (i in seq_along(recs)) for (cl in gdxCols) {
    v <- trimws(recs[[i]][[cl]] %||% "")
    if (!nzchar(v) || grepl("^[/~]|:", v)) next        # absolute path: not ours to check
    if (!v %in% titles) {
      err(titles[i], ": ", cl, " = '", v, "' is not a scenario in this file")
    }
  }

  # --- 4. coupling consistency -----------------------------------------------
  cpl <- function(r) identical(trimws(r$cm_taxCO2_regiDiff %||% ""), "11")
  for (i in seq_along(recs)) {
    r <- recs[[i]]; t <- titles[i]
    bm <- trimws(r$cm_pfmBindMode %||% "")
    th <- trimws(r$cm_pfmTheta %||% "")
    if (cpl(r)) {
      # THE quiet one. cm_taxCO2_regiDiff = 11 acts only inside
      # 45_carbonprice/functionalForm. Under any other realization the switch is inert:
      # the run carries every PFM setting, compiles, solves, and is fully uncoupled.
      cp <- trimws(r$carbonprice %||% "")
      if (!identical(cp, "functionalForm")) {
        err(t, ": coupled (regiDiff = 11) but carbonprice = '",
            if (nzchar(cp)) cp else "<blank, inherited>",
            "' - must be 'functionalForm' or the coupling never runs")
      }
      if (!nzchar(bm)) err(t, ": coupled but cm_pfmBindMode is empty")
      if (nzchar(bm) && !bm %in% c("1", "2", "3")) {
        err(t, ": cm_pfmBindMode '", bm, "' not in 1/2/3")
      }
      if (!nzchar(th)) {
        wrn(t, ": coupled but cm_pfmTheta empty - defaults to 0, i.e. UNCOUPLED. ",
            "Intended only for the correctness gate.")
      }
      if (identical(bm, "2") && !nzchar(trimws(r$path_gdx_ref %||% ""))) {
        err(t, ": cm_pfmBindMode = 2 needs a reference run (path_gdx_ref) for P_ref")
      }
      if (identical(bm, "3") && !nzchar(trimws(r$path_gdx_ref %||% ""))) {
        err(t, ": cm_pfmBindMode = 3 seeds from the current-policy price and needs ",
            "path_gdx_ref")
      }
    } else if (nzchar(bm) || nzchar(th)) {
      wrn(t, ": has PFM settings but cm_taxCO2_regiDiff is not 11 - they are ignored")
    }
  }

  # --- 4b. functionalForm needs a global anchor and a reference gdx -----------
  # Both of these are unconditional in 45_carbonprice/functionalForm/datainput.gms and
  # both fail as a bare GAMS execution error ~28s in, with no fulldata.gdx and no
  # abort.gdx to read - the least diagnosable failure this config can produce. All
  # three NPi twins died this way on 2026-08-12.
  #   * the anchor: cm_taxCO2_startyear and cm_taxCO2_peakBudgYr BOTH default to -1,
  #     and the linear/exponential branch aborts unless exactly one is positive.
  #   * input_ref.gdx: read by Execute_Loadpoint before any branch, so it is required
  #     even for bind mode 1, which needs no reference price of its own.
  num <- function(x) suppressWarnings(as.numeric(trimws(x %||% "")))
  for (i in seq_along(recs)) {
    r <- recs[[i]]; t <- titles[i]
    if (!identical(trimws(r$carbonprice %||% ""), "functionalForm")) next
    sy <- num(r$cm_taxCO2_startyear)
    pk <- num(r$cm_taxCO2_peakBudgYr)
    syOn <- !is.na(sy) && sy > 0
    pkOn <- !is.na(pk) && pk > 0
    if (!syOn && !pkOn) {
      err(t, ": carbonprice = functionalForm but neither cm_taxCO2_startyear nor ",
          "cm_taxCO2_peakBudgYr is set - both default to -1 and GAMS aborts in ",
          "datainput.gms before the first solve")
    } else if (syOn && pkOn) {
      err(t, ": cm_taxCO2_startyear (", sy, ") and cm_taxCO2_peakBudgYr (", pk,
          ") are both set - the anchor branch needs exactly one, the other must be -1")
    }
    if (!nzchar(trimws(r$path_gdx_ref %||% ""))) {
      err(t, ": carbonprice = functionalForm reads pm_taxCO2eq from input_ref.gdx ",
          "unconditionally, so path_gdx_ref is required (even in bind mode 1)")
    }
    # The linear anchor runs from (cm_taxCO2_historicalYr, historical price) to
    # (cm_startyear, cm_taxCO2_startyear), and the historical year defaults to the last
    # ttot BEFORE cm_startyear, which must itself be >= 2005. ttot carries the spin-up
    # years 1900-2000, so cm_startyear = 2005 resolves it to 2000 and aborts - and no
    # other value of cm_taxCO2_historicalYr can rescue it, since none lies in
    # [2005, 2005). A 2005 start is simply not available under this realization.
    sty <- num(r$cm_startyear)
    if (!is.na(sty) && sty <= 2005) {
      err(t, ": cm_startyear = ", sty, " with carbonprice = functionalForm - the ",
          "historical anchor year resolves before 2005 and GAMS aborts. Use a later ",
          "start year (the other functionalForm rows use 2030).")
    }
  }

  # --- 5. theta range ---------------------------------------------------------
  for (i in seq_along(recs)) {
    th <- suppressWarnings(as.numeric(trimws(recs[[i]]$cm_pfmTheta %||% "")))
    if (!is.na(th) && (th < 0 || th >= 1)) {
      err(titles[i], ": cm_pfmTheta = ", th, " outside [0, 1)")
    }
  }

  # --- 6. resolution consistency ---------------------------------------------
  # Mixing resolutions in ONE file is deliberate and fine - an H12 cross-check living
  # beside the EU21 set (SCENARIOS.md improvement 7). What is never fine is a run whose
  # path_gdx_ref sits at a DIFFERENT resolution: REMIND copies that gdx into the run
  # folder as input_ref.gdx and 45_carbonprice/datainput.gms reads it unconditionally,
  # so P_ref is read against the wrong region set. Every region is mis-assigned, the run
  # completes, and nothing anywhere reports it.
  #
  # The coupling itself needs no help here: preparePFM.R derives BOTH couplingMapping and
  # gdxRegionMapping from cfg$regionmapping, so it always matches the run it is inside.
  # Only this cross-run reference can shear, which is why it is the only thing checked.
  #
  # A BLANK regionmapping means "inherit default.cfg", which is H12 - so blank and an
  # explicit regionmappingH12.csv are the SAME resolution and must not be flagged. The
  # default is read from default.cfg rather than hard-coded, so this cannot drift.
  defMap <- "regionmappingH12.csv"
  dcfg <- file.path(dirname(file), "default.cfg")
  if (file.exists(dcfg)) {
    hit <- grep("^\\s*cfg\\$regionmapping\\s*<-", readLines(dcfg, warn = FALSE), value = TRUE)
    if (length(hit)) defMap <- basename(gsub('.*["\']([^"\']+)["\'].*', "\\1", hit[1]))
  }
  mapOf <- vapply(recs, function(r) {
    v <- basename(trimws(r$regionmapping %||% ""))
    if (nzchar(v)) v else defMap
  }, character(1))

  # Every cross-run gdx reference, not just path_gdx_ref: path_gdx_refpolicycost feeds
  # the policy-cost reporting and path_gdx restarts from another run, and both shear the
  # same way. gdxCols is the list already used by check 3.
  for (i in seq_along(recs)) for (cl in gdxCols) {
    ref <- trimws(recs[[i]][[cl]] %||% "")
    j <- match(ref, titles)
    if (!nzchar(ref) || is.na(j)) next
    if (!identical(mapOf[i], mapOf[j])) {
      err(titles[i], ": regionmapping is '", mapOf[i], "' but its ", cl, " '", ref,
          "' is '", mapOf[j], "' - that gdx would be read at the wrong resolution ",
          "and every region mis-assigned, silently")
    }
  }

  maps <- unique(mapOf)
  if (length(maps) > 1) {
    notes <- c(notes, paste0(length(maps), " resolutions in this file (",
      paste(maps, collapse = ", "), ") - fine, but numbers are NOT comparable across ",
      "them, and each family needs its own path_gdx_ref at its own resolution"))
  }

  # --- 6b. is the reference price floor pinned OFF on every run? --------------
  # TODO item 3, decided 2026-08-22. `cm_taxCO2_lowerBound_path_gdx_ref` floors
  # pm_taxCO2eq at the reference run's own price path. REMIND's default is 1 (ON), so
  # a BLANK field here does not mean "off" -- it means "on", inherited silently.
  #
  # Two reasons this is an error and not a preference. (1) With the floor on, the
  # coupled price can never fall below current policy, which is a political assumption
  # -- policy rollback is impossible -- competing with the very constraint the paper
  # estimates. (2) It was never applied uniformly: postsolve's Step IV.3 sits inside
  # the `cm_iterative_target_adj in {5,7,9}` block (functionalForm/postsolve.gms:432),
  # so with the switch ON the floor bound the budget-forcing family and was silently
  # absent from the rest. The 2026-08-17 batch ran floorSwitch = 1 on all 33 runs and
  # recorded 126 of 280 EU21 region-years below the floor in the adj = 0 family.
  #
  # Setting this back to "1" is only defensible once Step IV.3 is hoisted out of the
  # adj block; until then a "1" or a blank re-opens an asymmetry between families the
  # paper compares directly.
  floorCol <- "cm_taxCO2_lowerBound_path_gdx_ref"
  for (i in seq_along(recs)) {
    v <- trimws(recs[[i]][[floorCol]] %||% "")
    if (!nzchar(v)) {
      err(titles[i], ": ", floorCol, " is blank, which inherits REMIND's default of 1 ",
          "(floor ON). Pin it to 0 - blank is not off (TODO item 3)")
    } else if (!identical(v, "0")) {
      err(titles[i], ": ", floorCol, " = '", v, "'. The reference price floor must be ",
          "OFF (0) on every run: with it on it binds only the ",
          "cm_iterative_target_adj in {5,7,9} family, so the families this config ",
          "compares are not the same policy world (TODO item 3)")
    }
  }

  # --- 7. is there a correctness gate? ---------------------------------------
  cpl2 <- vapply(recs, cpl, logical(1))
  gate <- vapply(recs, function(r) cpl(r) &&
    identical(suppressWarnings(as.numeric(trimws(r$cm_pfmTheta %||% "NA"))), 0), logical(1))
  if (any(cpl2) && !any(gate)) {
    wrn("no coupled scenario at cm_pfmTheta = 0. That run is the interface ",
        "correctness gate - it must reproduce the uncoupled reference exactly.")
  }

  if (isTRUE(verbose)) {
    cat("scenarios: ", length(recs), " (", sum(cpl2), " coupled)\n", sep = "")
    for (n in notes) cat("note  ", n, "\n", sep = "")
    for (w in warns) cat("WARN  ", w, "\n", sep = "")
    for (e in errs)  cat("ERROR ", e, "\n", sep = "")
    if (!length(errs) && !length(warns)) cat("OK - no problems found\n")
  }
  invisible(list(errors = errs, warnings = warns, nScenarios = length(recs)))
}

if (!interactive() && identical(environment(), globalenv())) {
  a   <- commandArgs(trailingOnly = TRUE)
  res <- validatePFMScenarioConfig(if (length(a)) a[1] else "models/remind_pfm/config/scenario_config_PFM.csv")
  if (length(res$errors)) quit(status = 1)
}
