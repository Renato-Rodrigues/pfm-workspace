# Build config/scenario_config_PFM.csv FROM config/scenario_config.csv.
#
# Why this is generated and not hand-maintained
# ---------------------------------------------
# The coupled runs only mean something against REMIND's own scenarios, so every switch
# that is not part of the coupling must match the canonical row exactly. Hand-copying
# does not hold: the previous PkBudg1000 PFM family was, in every row, a copy of the
# canonical *PkBudg750* with cm_budgetCO2from2020 changed to 1000. All seven of its
# non-coupling differences from SSP2-EU21-PkBudg1000 matched PkBudg750 exactly -
# cm_rcp_scen rcp20 vs rcp26, cm_taxCO2_startyear 100 vs 75, cm_peakBudgYr 2055 vs 2080,
# cm_taxCO2_regiDiff 6 vs 7, cm_wasteIncinerationCCSshare 0.9 vs 0.5, cm_CESMkup_ind
# Elec_Push vs blank, cm_EDGEtr_scen Mix4ICEban vs Mix3ICEban. So the runs carried a
# 750 Gt scenario's climate target, transport pathway and industry markup while being
# compared against a genuinely-1000 Gt baseline.
#
# Generating removes that whole failure class: a PFM row is its canonical parent plus a
# named delta, and nothing else. When REMIND updates its scenarios, re-run this.
#
# Lives in analysis/, NOT in models/remind_pfm/: it is project tooling and must not be committed to
# the REMIND fork. It therefore takes the REMIND checkout as an argument.
#
# Usage, from the project root (the folder holding config.yml and models/remind_pfm/):
#   Rscript analysis/run-groups/buildPFMScenarioConfig.R
#   Rscript analysis/run-groups/validatePFMScenarioConfig.R
# or against another checkout:
#   Rscript analysis/run-groups/buildPFMScenarioConfig.R ../some-other-remind
#
# The delta, in full
# ------------------
# Budget parents (SSP2[-EU21]-PkBudg1000) ALREADY use carbonprice = functionalForm with a
# path_gdx_ref, so the coupling delta is only:
#     cm_taxCO2_regiDiff  7 -> 11   (or 0 for the uniform-price gate reference)
#     cm_pfmBindMode / cm_pfmTheta / cm_pfmConvTol   added
#     cm_pfmSectorMarkup                            added (ADR 0042; 0 = the old min())
#     cm_iterative_target_adj  9 -> 0   for the variants that drop the budget forcing
#
# NPi parents carry no carbon price at all, so their twins additionally need the
# functionalForm scaffolding: carbonprice, an anchor, cm_startyear > 2005 (2005 aborts -
# ttot spin-up years resolve the historical anchor before 2005) and a path_gdx_ref. The
# anchor is taken from the SAME resolution's PkBudg1000 parent so the twin's price path
# stays comparable with the ambitious family and tracks it automatically.

`%||%` <- function(a, b) if (is.null(a) || !length(a) || is.na(a) || !nzchar(a)) b else a

# theta: DECLARED, not anchored - its analogy-based derivation has moved three times. 0.79 (ADR 0041) was derived on the
# pre-satAP frontier, for Bulk, over 48 COUNTRIES. Regenerating the frontier moved it to
# 0.74 and ADR 0042 moved the floor-setting sector to Diffuse - but both of those were still
# country-resolution numbers, and the coupling assigns phi over 21 REMIND REGIONS at the
# seed year. Aggregation collapses the gap range (Bulk 0.155-0.834 -> 0.219-0.450), so the
# normalised median gap rises and theta falls: the anchor at the resolution that matters is
# 0.50 (Diffuse), with Bulk at 0.70 - and Bulk is NOT out of admissible range, which the
# country-level figure wrongly suggested.
#
# Re-derive rather than trust this constant: coupling-summary.rds$anchorDerivation records
# it every run (pfm::computeEfficiencyAnchor). If that disagrees with the value here, the
# artifact wins.
#
# NOTE this changes what the coupled runs do. Batches before 2026-08-17 were run at 0.79;
# pass theta = "0.79" to reproduce them.
# 🔴 THE DEPLOYED CONFIG IS HAND-MAINTAINED (since 2026-09-18).
# `models/remind_pfm/config/scenario_config_PFM.csv` carries section separators, a warm-start chain in
# `path_gdx`, and edits made directly in the file. THIS GENERATOR DOES NOT REPRODUCE ALL OF IT.
# Regenerating straight over the deployed file therefore DESTROYS work. The safe procedure:
#
#   f <- file.path(tempdir(), "gen.csv")
#   buildPFMScenarioConfig(remindDir = "remind_pfm", out = f)     # scaffold to a temp file
#   # then merge the rows you want by hand, keeping the deployed file's start tags and path_gdx
#   Rscript analysis/run-groups/validatePFMScenarioConfig.R models/remind_pfm/config/scenario_config_PFM.csv
#
# The validator now checks what REMIND's own reader and start.R enforce: legal titles (letters,
# digits, '_' and '-' only - a separator typed with a space aborts the entire read) and start
# tags without whitespace (" H12" is not "H12").

buildPFMScenarioConfig <- function(remindDir = "remind_pfm",
                                   base  = file.path(remindDir, "config/scenario_config.csv"),
                                   out   = file.path(remindDir, "config/scenario_config_PFM.csv"),
                                   theta = "0.50",
                                   # 0.002, not the 0.01 the 2026-08-17 batch used. At 0.01 the
                                   # 2-call runs cross tolerance on their FIRST comparison, so
                                   # they report a single delta instead of a contracting
                                   # sequence and convergence can only be asserted, never shown
                                   # (SCENARIOS.md 3.2 - EU21 -PFMratio at 0.0075 and
                                   # -PFMratioMin at 0.0077 are the two that still do this).
                                   # 0.002 sits below every observed first-comparison delta, so
                                   # a sequence appears.
                                   #
                                   # COST, and it is real: runs whose final delta currently
                                   # sits between 0.002 and 0.01 will now need more PFM calls -
                                   # H12 -PFMlevelC ends at 0.0079 and -PFMratioMin at 0.0029.
                                   # Budget more iterations for those, and use the per-variant
                                   # `ct` override to hold a row at 0.01 if it will not settle.
                                   #
                                   # This does NOT address the -PFMlevelCMin cap. That run's
                                   # PFM loop already converged (0.0188 -> 0.0028); what capped
                                   # was REMIND's budget loop. Tightening this dial cannot help
                                   # it and may cost iterations it needs (SCENARIOS.md 4.5).
                                   convTol = "0.002",
                                   # The alternative theta group (ADR 0045, v5): a DECLARED,
                                   # symmetric sweep about 0.50. On v5 the efficiency analogy
                                   # is inadmissible for Bulk (1.019), so no value here is an
                                   # anchor. Emitted under startgroup=THETA only.
                                   altThetas = c("0.325", "0.675"),
                                   # FIXED BUDGET-CONSISTENT PRICE PATH for rule B (TODO 14g,
                                   # decided 2026-09-17). With cm_iterative_target_adj = 0 the
                                   # anchor is never raised, so the original -PFMgateB null runs
                                   # $75 -> $86 -> $104 and emits 1710 Gt: headline B measured the
                                   # cap against a path that already misses the budget. The FIXPRICE
                                   # rows instead READ the anchor the budget-held theta = 0 gate
                                   # converged to (cm_pfmAnchorFromGdx = on, path_gdx_carbonprice =
                                   # this resolution's -PFMgate; start.R resolves the title to its
                                   # latest finished run). No price is typed into the CSV.
                                   #
                                   # Why not cm_taxCO2_startyear / cm_peakBudgYr (the first attempt,
                                   # 2026-09-17): (1) a spreadsheet save turned 108.2663 into
                                   # 1.082.663 and 96.6655 into 966.655 and every run was
                                   # infeasible; (2) the values themselves were 0.27% low - the
                                   # gate's final anchor is $108.56 / $96.92 in 2030 (EU21 / H12).
                                   # A -PFMgateBfix run must reproduce -PFMgate (~992 Gt, peak
                                   # ~999 Gt); if it does not, stop.
                                   anchorDonor = "PFMgate",
                                   # Existing rows to re-submit, tagged RERUN in addition to their
                                   # own tags (TODO items 30, 31): both hit the 100-iteration cap on
                                   # the 2026-09-16 batch.
                                   rerun = c("SSP2-PkBudg1000-PFMratioMin", "SSP2-PkBudg1000-PFMratioTh325"),
                                   # No iteration-cap column (removed 2026-10-01). A run that does not
                                   # converge is handled by fixing the source of non-convergence, or by
                                   # starting a new run from its gdx (path_gdx) - never by raising
                                   # cm_iteration_max. EU21 -PFMlevelC (TODO item 17) is the precedent:
                                   # restarted from its own gdx it converged to 1000.4 Gt.
                                   sectorMarkup = "1",
                                   # cm_pfmGapClosure: does the political gap CLOSE over the
                                   # horizon (1, at the frontier's estimated ECM speeds) or
                                   # PERSIST (0)?
                                   #
                                   # "0" DEPLOYED 2026-09-11 (TODO.md 1e-a). The estimated
                                   # lambda cannot carry the claim: it loses a forecast-skill
                                   # test to plain persistence (-0.123 Bulk / -0.797 Diffuse at
                                   # v4) and a placebo battery on panels built with NO
                                   # adjustment by construction returns 0.281 / 0.107 - larger
                                   # than the estimates themselves. Persist is also
                                   # exportFeasibilityRegiDiff()'s documented default and the
                                   # stated reason bind mode 11 exists.
                                   #
                                   # It is NOT a small dial: it moves mode R's cross-regional
                                   # spread between ~1.98x and 1.12x and moves every mode-L
                                   # price bound with it. So the opposite setting is emitted as
                                   # a declared sensitivity group (startgroup=GAPCLOSE) rather
                                   # than left as a paragraph.
                                   gapClosure = "0",
                                   # cm_taxCO2_lowerBound_path_gdx_ref: floor pm_taxCO2eq at the
                                   # reference run's own price path. REMIND's default is 1 (on);
                                   # every scenario this builder emits now pins it explicitly.
                                   #
                                   # WHY "0" (decided 2026-08-22, TODO item 3). With the floor on,
                                   # the coupled price can never fall below current policy - which
                                   # is a statement that policy rollback is impossible, i.e. a
                                   # POLITICAL assumption smuggled in as a numerical guard, and one
                                   # that competes with the feasibility constraint the paper is
                                   # about. Worse, it was not applied uniformly: postsolve's
                                   # Step IV.3 sits inside the
                                   # `cm_iterative_target_adj in {5,7,9}` block
                                   # (functionalForm/postsolve.gms:35-480), so with the switch ON
                                   # the floor bound the budget-forcing family and was silently
                                   # absent from the rest - 126 of 280 EU21 region-years below the
                                   # floor in the adj = 0 runs, and EU21 ECS at 2030 differing
                                   # \$222 vs \$75 between families that the paper compares.
                                   # Pinning "0" makes every family agree and makes the omission
                                   # a stated modelling choice instead of an artefact of which
                                   # `if` block a line happens to sit in.
                                   #
                                   # Methods MUST now say that policy rollback is permitted.
                                   # Setting this back to "1" re-opens the asymmetry above unless
                                   # Step IV.3 is first hoisted out of the adj block.
                                   taxFloorFromRef = "0",
                                   verbose = TRUE) {

  say <- function(...) if (isTRUE(verbose)) cat(..., "\n", sep = "")

  # strsplit() drops ONE trailing empty field, so the field count is taken from the separator
  # count instead. The previous sentinel version (append ";" then drop the last element)
  # dropped the LAST column of every row whenever that column was non-empty - which silently
  # removed REMIND's `description` column from the whole PFM config (found 2026-09-17).
  splitRow <- function(x) { n <- nchar(gsub("[^;]", "", x)) + 1L
                            f <- strsplit(x, ";", fixed = TRUE)[[1]]
                            c(f, rep("", n - length(f))) }

  raw  <- readLines(base, warn = FALSE)
  raw  <- raw[nzchar(trimws(raw))]
  hdr  <- splitRow(raw[1])
  rows <- lapply(raw[-1], splitRow)
  rows <- rows[vapply(rows, length, integer(1)) == length(hdr)]
  names(rows) <- vapply(rows, `[`, character(1), 1L)

  parent <- function(title) {
    r <- rows[[title]]
    if (is.null(r)) stop("buildPFMScenarioConfig: '", title, "' not in ", base)
    stats::setNames(as.list(r), hdr)
  }

  # The coupling columns live only in the PFM config; everything else is inherited.
  pfmCols <- c("c_pfmIter", "cm_nash_autoconverge",
               "cm_pfmBindMode", "cm_pfmConvTol", "cm_pfmTheta",
               "cm_pfmSectorMarkup", "cm_pfmGapClosure",
               "cm_pfmAnchorFromGdx", "path_gdx_carbonprice")
  # Pinned on every emitted row rather than left to REMIND's default; see the
  # `taxFloorFromRef` note in the signature. Added to the header only if the base
  # config does not already carry it, so a base that sets it is still overridden
  # by value rather than duplicated into a second column.
  floorCol <- "cm_taxCO2_lowerBound_path_gdx_ref"
  outHdr  <- c(hdr, pfmCols, setdiff(floorCol, hdr))

  emit <- function(p, title, start, desc, set = list()) {
    r <- p
    for (k in names(set)) r[[k]] <- set[[k]]
    # The config is ';'-separated and unquoted, so free text may not carry a ';'.
    r$title <- title; r$start <- start; r$description <- gsub(";", ",", desc, fixed = TRUE)
    # Applied AFTER `set` so a variant may override it deliberately, but never
    # inherit it by accident: an empty field here means "REMIND default = on",
    # which is the behaviour this pin exists to prevent.
    if (is.null(r[[floorCol]]) || !nzchar(r[[floorCol]])) r[[floorCol]] <- taxFloorFromRef
    for (k in pfmCols) if (is.null(r[[k]])) r[[k]] <- ""
    v <- vapply(outHdr, function(k) as.character(r[[k]] %||% ""), character(1))
    # A ';' anywhere in a field shears the row and every check downstream reads garbage.
    if (any(grepl(";", v, fixed = TRUE))) {
      stop("buildPFMScenarioConfig: ';' in a field of '", title, "'")
    }
    paste(v, collapse = ";")
  }

  # --- the variant table -------------------------------------------------------
  # bind modes: 1 ratio, 2 absolute cap, 3 mild progression. adj = "" leaves the
  # parent's cm_iterative_target_adj alone; "0" drops the budget forcing.
  # mk = NULL inherits `sectorMarkup`; mk = "0" forces the pre-ADR-0042 min() collapse.
  budVariants <- list(
    list(sfx = "PFMgateRef",  rd = "0",  bm = "",  th = "",   adj = "",
         d = "Uniform global price (cm_taxCO2_regiDiff = 0). The run -PFMgate must reproduce EXACTLY at theta = 0; any difference is an interface bug, not a finding. Not a science control."),
    list(sfx = "PFMgate",     rd = "11", bm = "1", th = "0",  adj = "",
         d = "INTERFACE CORRECTNESS GATE and the theta = 0 null under a held budget. Every phi is 1, so it must reproduce -PFMgateRef exactly. Run it FIRST. NOTE it cannot detect a defect that erases phi, because at theta = 0 such a wipe is a no-op - also assert p45_regiDiff_ratio is not identically 1 on a theta > 0 run."),
    list(sfx = "PFMratio",    rd = "11", bm = "1", th = theta, adj = "",
         d = "Mode R. phi scales the anchor, so the budget is always met and politics only moves the price BETWEEN regions. Carries the redistribution exhibit. Read against -PFMgate."),
    list(sfx = "PFMlevelC",   rd = "11", bm = "2", th = theta, adj = "",
         d = "Mode L, conflict rule C. phi caps the ABSOLUTE price while the budget forcing stays ON, so the budget may become unreachable - that is the finding, not a bug. Read against -PFMgate."),
    list(sfx = "PFMgateB",    rd = "11", bm = "1", th = "0",  adj = "0",
         d = "MATCHED theta = 0 NULL FOR -PFMlevelB: same cm_iterative_target_adj = 0, bind mode 1, no political constraint at all. levelB differs from -PFMgate in TWO ways at once (phi AND the dropped budget forcing), so the headline is not attributable without this row. A bind mode 2 run at theta = 0 is NOT this null - the cap still binds through the speed limit lambda."),
    list(sfx = "PFMlevelB",   rd = "11", bm = "2", th = theta, adj = "0",
         d = "Mode L, conflict rule B, on the UNFORCED anchor ($75 / $86 / $104 in 2030 / 2050 / 2100). Budget forcing is OFF, so emissions land where politics allows - but the null -PFMgateB already emits ~1710 Gt, so this measures the cap against a path that misses the budget. The quantity headline is the -PFMlevelBfix family (FIXPRICE); this row is kept as its unforced-anchor sensitivity. Read against -PFMgateB."),
    list(sfx = "PFMmildProg", rd = "11", bm = "3", th = theta, adj = "0",
         d = "Mode M. The price is GENERATED by political momentum rather than constraining a cost-optimal path - no anchor, no budget, so it cannot be infeasible. Independent check on mode L by a completely different mechanism."),

    # --- markup-off counterfactuals (cm_pfmSectorMarkup = 0) -------------------
    # Added 2026-08-18. The 2026-08-17 batch ran with the markup ON in every row, so its
    # headline result - the political constraint lands on the household-facing price while
    # the industrial price stays near cost-optimal - CANNOT be attributed. It may be the
    # frontier, or it may be nothing more than a cost-optimiser arbitraging two instruments.
    # These rows are each an exact twin of the run above them with the single switch flipped,
    # so the difference isolates ADR 0042 and nothing else.
    #
    # No matching theta = 0 nulls are needed: at theta = 0 every phi is 1, so every markup is
    # identically zero and -PFMgate / -PFMgateB ALREADY serve both markup settings. That is
    # also why the interface gate cannot test the markup (COUPLING.md 11.4).
    list(sfx = "PFMratioMin",  rd = "11", bm = "1", th = theta, adj = "", mk = "0",
         d = "MARKUP-OFF COUNTERFACTUAL for -PFMratio: cm_pfmSectorMarkup = 0, the pre-ADR-0042 min(phi_Bulk, phi_Diffuse) collapse to a single economy-wide price. Identical to -PFMratio in every other switch. Read the PAIR, not this row alone: it is what attributes the sector-split headline to the frontier rather than to REMIND having two instruments. Also re-tests the older finding that mode R is self-defeating under a budget - which held when the anchor was the only instrument."),
    list(sfx = "PFMlevelBMin", rd = "11", bm = "2", th = theta, adj = "0", mk = "0",
         d = "MARKUP-OFF COUNTERFACTUAL for -PFMlevelB. Identical to -PFMlevelB but cm_pfmSectorMarkup = 0. Gives the headline 'political feasibility costs X Gt CO2' a markup-free counterpart, so the paper can state how much of the rule-B cost survives without sector-differentiated delivery. Read against -PFMgateB, the same null -PFMlevelB uses."),
    list(sfx = "PFMlevelCMin", rd = "11", bm = "2", th = theta, adj = "", mk = "0",
         d = "MARKUP-OFF COUNTERFACTUAL for -PFMlevelC. Rules B and C agreed to 0.4% before ADR 0042 and diverge substantially with the markup on; the suspected cause is that the markup gives rule C a second instrument to buy the budget back through industry. This row tests that directly. Read against -PFMgate.")
  )

  npiVariants <- list(
    list(sfx = "PFMgate",     bm = "1", th = "0",
         d = "THETA = 0 NULL FOR THE NPi FAMILY. Identical to the other NPi twins except cm_pfmTheta = 0, so every phi is 1 and the price is the bare anchor. Without it the twins have no null at cm_taxCO2_regiDiff = 11 and their effect cannot be separated from the regiDiff branch change - which flips the SIGN of the result, not just its size."),
    list(sfx = "PFMratio",    bm = "1", th = theta,
         d = "Mode R on the current-policies pathway. Read against -PFMgate."),
    list(sfx = "PFMlevel",    bm = "2", th = theta,
         d = "Mode L on the current-policies pathway. Read against -PFMgate."),
    list(sfx = "PFMmildProg", bm = "3", th = theta,
         d = "Mode M on the current-policies pathway. Read against -PFMgate.")
  )

  twinNote <- paste(
    "NPi twins exist so an effect seen only in the ambitious runs cannot be confused with",
    "what the mechanism does to ANY price path. The NPi parent carries no carbon price, so",
    "the twin adds the functionalForm scaffolding: the anchor is the same resolution's",
    "PkBudg1000 anchor, keeping the two families comparable.")

  blank <- paste(rep("", length(outHdr)), collapse = ";")
  sep <- function(label) sub("^", "", paste(c(label, rep("", length(outHdr) - 1)), collapse = ";"))

  lines <- c(paste(outHdr, collapse = ";"))
  built <- character(0)

  for (res in c("H12", "EU21")) {
    pre  <- if (identical(res, "EU21")) "SSP2-EU21-" else "SSP2-"
    npiT <- paste0(pre, "NPi2025")
    budT <- paste0(pre, "PkBudg1000")
    pN <- parent(npiT); pB <- parent(budT)
    # EU21 also carries "1", REMIND's default startgroup, so a bare
    #   Rscript start.R config/scenario_config_PFM.csv
    # runs the primary (paper) family instead of dropping into the interactive chooser.
    # "AMT" is on both families, so startgroup=AMT is an "everything" alias.
    tag <- if (identical(res, "EU21")) "1,AMT,EU21" else "AMT,H12"
    # compileInTests only on the cheaper H12 twins: it makes `start.R --gamscompile`
    # cover all three bind modes without doubling the compile set.
    tagT <- if (identical(res, "H12")) paste0(tag, ",compileInTests") else tag
    # EVERY SENSITIVITY GROUP IS RESOLUTION-SCOPED (2026-09-18). The two resolutions live in
    # SEPARATE CHECKOUTS with separate output folders, so a group tag shared between them
    # (`THETA`) asks one checkout to start runs whose path_gdx_ref resolves in the other. Scope
    # the tag and the question disappears: `startgroup=H12THETA` from the H12 checkout.
    # start.R matches tags with grepl("(^|,)TAG($|,)"), so a tag must carry NO whitespace.
    grp <- function(g) paste0(res, g)

    lines <- c(lines, sep(paste0("_____", res, "_____")))

    # Baselines: byte-identical copies of the canonical rows. They ARE the uncoupled
    # references - a separate "-PFMref"/"-PFMbase" row would be the same run twice.
    lines <- c(lines,
      emit(pN, npiT, tag, paste0(
        "Uncoupled current-policies baseline, copied VERBATIM from ", base,
        ". It is P_ref for the PFM, the path_gdx_ref of every ", res,
        " row below, and the uncoupled comparison for the NPi twins - so it MUST complete first.")),
      emit(pB, budT, tag, paste0(
        "Uncoupled 1000 Gt cost-optimal run, copied VERBATIM from ", base,
        ". The reference the coupled budget runs are measured against. There is deliberately no",
        " separate -PFMref row: after aligning the switches it would be this run twice.")))
    built <- c(built, npiT, budT)

    for (v in budVariants) {
      t <- paste0(budT, "-", v$sfx)
      # v$mk overrides the batch-wide sectorMarkup for the markup-off counterfactuals.
      mk <- v$mk %||% sectorMarkup
      ct <- v$ct %||% convTol
      st <- list(cm_taxCO2_regiDiff = v$rd, cm_pfmBindMode = v$bm,
                 cm_pfmTheta = v$th, cm_pfmConvTol = if (nzchar(v$bm)) ct else "",
                 cm_pfmSectorMarkup = if (nzchar(v$bm)) mk else "",
                 cm_pfmGapClosure = if (nzchar(v$bm)) gapClosure else "")
      if (nzchar(v$adj)) st$cm_iterative_target_adj <- v$adj
      lines <- c(lines, emit(pB, t, tag, paste0(v$d, " Inherits every non-coupling switch from ",
                                                budT, " (", res, ")."), st))
      built <- c(built, t)
    }

    # --- the theta sensitivity group ------------------------------------------
    # Exact twins of -PFMratio and -PFMlevelB at the alternative thetas. Two runs per theta
    # per resolution, because those two carry the paper's two headline objects: mode R the
    # sector split, mode L the budget cost.
    #
    # NO NEW NULLS. -PFMgate and -PFMgateB are at theta = 0 and are therefore theta-invariant,
    # so they already serve every value here - the same argument that let the markup-off rows
    # reuse them.
    #
    # -PFMlevelC was EXCLUDED here while its budget loop was unresolved. It is now emitted as its
    # OWN group (RULEC, below) rather than inside THETA: the rule-C runs are the slowest in the
    # batch and giving them a separate start group keeps a THETA submission cheap.
    #
    # TAGGED "THETA" AND NOTHING ELSE, on purpose. AMT / EU21 / H12 / 1 keep selecting exactly
    # the set they selected before this group existed, so `startgroup=AMT` does not silently
    # grow by 8 runs. Launch the sensitivity explicitly:
    #     Rscript start.R config/scenario_config_PFM.csv startgroup=H12THETA   (or EU21THETA)
    for (th in altThetas) {
      thTag <- paste0("Th", sub("^0[.]", "", format(as.numeric(th), nsmall = 3)))
      for (v in Filter(function(x) x$sfx %in% c("PFMratio", "PFMlevelB"), budVariants)) {
        t <- paste0(budT, "-", v$sfx, thTag)
        st <- list(cm_taxCO2_regiDiff = v$rd, cm_pfmBindMode = v$bm,
                   cm_pfmTheta = th, cm_pfmConvTol = convTol,
                   cm_pfmSectorMarkup = v$mk %||% sectorMarkup,
                   cm_pfmGapClosure = gapClosure)
        if (nzchar(v$adj)) st$cm_iterative_target_adj <- v$adj
        lines <- c(lines, emit(pB, t, grp("THETA"), paste0(
          "THETA SENSITIVITY, cm_pfmTheta = ", th, ". Exact twin of ", budT, "-", v$sfx,
          " with only theta changed. theta is DECLARED and swept, never estimated (ADR 0045):",
          " 0.325 / 0.50 / 0.675 is a symmetric sweep, and no value is an efficiency anchor.",
          " Read against the SAME null as its 0.50 twin (theta = 0 is theta-invariant).",
          " Inherits every non-coupling switch from ", budT, " (", res, ")."), st))
        built <- c(built, t)
      }
    }

    # --- rule C across the severity range (TODO item 41) ----------------------
    # C34 ("the budget can be held under the political cap") was measured at theta = 0.50 only,
    # while every other headline carries the declared range. Severity is exactly what should
    # break it: a harsher theta binds the cap in more region-periods, and once bindShare
    # approaches 1 raising the anchor moves no price. Whether the budget still holds at 0.675 is
    # a RESULT either way - if it stops holding, the severity at which it stops is the finding.
    #
    # Its own start group because rule-C runs are the slowest in the batch (the EU21 deployed run
    # needed ~150 iterations in total):
    #     Rscript start.R config/scenario_config_PFM.csv startgroup=H12RULEC   (or EU21RULEC)
    for (th in altThetas) {
      thTag <- paste0("Th", sub("^0[.]", "", format(as.numeric(th), nsmall = 3)))
      t <- paste0(budT, "-PFMlevelC", thTag)
      lines <- c(lines, emit(pB, t, grp("RULEC"), paste0(
        "RULE-C SEVERITY SENSITIVITY, cm_pfmTheta = ", th, ". Exact twin of ", budT,
        "-PFMlevelC with only theta changed: the cap binds the ABSOLUTE price while budget",
        " forcing stays ON, so the budget may become unreachable - that is the finding, not a",
        " bug (claim C34). Read against -PFMgate, the same null the 0.50 twin uses. Expect it to",
        " be slow: give it the iteration budget before calling it stuck.",
        " Inherits every non-coupling switch from ", budT, " (", res, ")."),
        list(cm_taxCO2_regiDiff = "11", cm_pfmBindMode = "2", cm_pfmTheta = th,
             cm_pfmConvTol = convTol, cm_pfmSectorMarkup = sectorMarkup,
             cm_pfmGapClosure = gapClosure)))
      built <- c(built, t)
    }

    # --- the gap-closure sensitivity group ------------------------------------
    # The declared counterpart to cm_pfmGapClosure = 0 (TODO.md 1e-a). Same four science
    # runs, same theta, ONLY the gap-closure rate changed - so the pair measures exactly
    # what riding on lambda costs, and nothing else.
    #
    # Why all four and not two, unlike the THETA group: this switch reaches mode 1 (the
    # ratio path) and mode 2 (the speed limit on the level bound) but NOT mode 3, whose
    # lambda is a momentum rate that zeroing would freeze (pfm: see the note beside
    # `lambdaGap` in iterativePFM.R). Emitting -PFMmildProg here anyway is deliberate: it
    # is the control that shows the switch left mode M untouched. If a -PFMmildProgGapC
    # run ever differs from -PFMmildProg, the scoping broke.
    #
    # TAGGED "GAPCLOSE" AND NOTHING ELSE, same discipline as THETA: startgroup=AMT does
    # not silently grow. Launch it explicitly:
    #     Rscript start.R config/scenario_config_PFM.csv startgroup=GAPCLOSE
    if (identical(gapClosure, "0")) {
      for (v in Filter(function(x) x$sfx %in% c("PFMratio", "PFMlevelB", "PFMlevelC",
                                                "PFMmildProg"), budVariants)) {
        t <- paste0(budT, "-", v$sfx, "GapC")
        st <- list(cm_taxCO2_regiDiff = v$rd, cm_pfmBindMode = v$bm,
                   cm_pfmTheta = v$th, cm_pfmConvTol = v$ct %||% convTol,
                   cm_pfmSectorMarkup = v$mk %||% sectorMarkup,
                   cm_pfmGapClosure = "1")
        if (nzchar(v$adj)) st$cm_iterative_target_adj <- v$adj
        lines <- c(lines, emit(pB, t, grp("GAPCLOSE"), paste0(
          "GAP-CLOSURE SENSITIVITY, cm_pfmGapClosure = 1. Exact twin of ", budT, "-", v$sfx,
          " with only the gap-closure rate changed: the political gap closes at the",
          " frontier's estimated ECM speeds (v5: Bulk 0.1094/yr, Diffuse 0.0769/yr) instead",
          " of persisting, so a region handed phi = 0.50 ends up paying close to the full",
          " anchor. The DEPLOYED setting is 0 (persist), because the estimated lambda loses a",
          " forecast-skill test to persistence and sits below or inside a placebo null built",
          " with no adjustment by construction. Read the PAIR: it is the declared",
          " sensitivity on the single largest unmeasured parameter in the coupling.",
          " Inherits every non-coupling switch from ", budT, " (", res, ")."), st))
        built <- c(built, t)
      }
    }

    # --- the fixed budget-consistent price path: the QUANTITY headline ----------
    # Rule B again, but with the anchor PINNED to the converged path of this resolution's
    # budget-held gate (see `anchorDonor`). Budget forcing stays off, so politics can move
    # emissions; the price path it caps is the one that meets 1000 Gt without politics. The
    # difference -PFMlevelBfix minus -PFMgateBfix is "what political feasibility costs relative
    # to the 1000 Gt pathway". Same six-row shape as the unforced family it replaces as the
    # headline: null, central, two thetas, gap closure, markup off - plus a mode-R twin, so
    # the price headline (-PFMratio) and the quantity headline differ in closure only.
    #
    # TAGGED "FIXPRICE" AND NOTHING ELSE, same discipline as THETA and GAPCLOSE:
    #     Rscript start.R config/scenario_config_PFM.csv startgroup=H12FIXPRICE (or EU21FIXPRICE)
    if (!is.null(anchorDonor) && nzchar(anchorDonor)) {
      donorT <- paste0(budT, "-", anchorDonor)
      # Only the anchor source differs from -PFMgateB: cm_taxCO2_startyear / cm_peakBudgYr keep
      # the parent's values (Part I still runs and its checks still apply) and are discarded.
      fixSet <- function(bm, th, mk = sectorMarkup, gc = gapClosure) list(
        cm_taxCO2_regiDiff = "11", cm_pfmBindMode = bm, cm_pfmTheta = th, cm_pfmConvTol = convTol,
        cm_pfmSectorMarkup = mk, cm_pfmGapClosure = gc, cm_iterative_target_adj = "0",
        cm_pfmAnchorFromGdx = "on", path_gdx_carbonprice = donorT)
      anchorNote <- paste0(" Anchor READ from the converged budget-held run ", donorT,
        " (cm_pfmAnchorFromGdx = on, path_gdx_carbonprice); budget forcing OFF (cm_iterative_target_adj = 0).")
      fixRows <- list(
        list(sfx = "PFMgateBfix", st = fixSet("1", "0"), d = paste0(
          "FIXED-PRICE NULL for the quantity headline: theta = 0 on the pinned budget-consistent path.",
          " MUST reproduce ", budT, "-PFMgate (cumulative CO2 ~992 Gt, peak ~999 Gt); if it does not,",
          " the pinning failed and the FIXPRICE family is not interpretable.")),
        list(sfx = "PFMlevelBfix", st = fixSet("2", theta), d = paste0(
          "QUANTITY HEADLINE. Mode L at theta = ", theta, " on the pinned budget-consistent path: the",
          " extra CO2 when each region's price is capped at what its politics permits and nobody",
          " compensates. Read against -PFMgateBfix.")),
        list(sfx = "PFMratioBfix", st = fixSet("1", theta), d = paste0(
          "MODE-R TWIN of the quantity headline: mode R (phi x anchor) at theta = ", theta, " on the same",
          " pinned path. -PFMratio is the PRICE headline (budget held, anchor raised); this row is the same",
          " conversion with the anchor NOT raised, so the gap between the two headlines is not a mix of",
          " closure and conversion. Its difference from -PFMlevelBfix is the conversion alone. Read against -PFMgateBfix.")),
        list(sfx = paste0("PFMlevelBfixTh", sub("^0[.]", "", altThetas[1])), st = fixSet("2", altThetas[1]),
          d = paste0("THETA SENSITIVITY of -PFMlevelBfix, cm_pfmTheta = ", altThetas[1], ". Read against -PFMgateBfix.")),
        list(sfx = paste0("PFMlevelBfixTh", sub("^0[.]", "", altThetas[2])), st = fixSet("2", altThetas[2]),
          d = paste0("THETA SENSITIVITY of -PFMlevelBfix, cm_pfmTheta = ", altThetas[2], ". Read against -PFMgateBfix.")),
        list(sfx = "PFMlevelBfixGapC", st = fixSet("2", theta, gc = "1"),
          d = "GAP-CLOSURE SENSITIVITY of -PFMlevelBfix (cm_pfmGapClosure = 1). Read against -PFMgateBfix."),
        list(sfx = "PFMlevelBfixMin", st = fixSet("2", theta, mk = "0"),
          d = "MARKUP-OFF COUNTERFACTUAL of -PFMlevelBfix (cm_pfmSectorMarkup = 0): how much of the quantity cost pricing two markets buys back. Read against -PFMgateBfix."))
      for (v in fixRows) {
        t <- paste0(budT, "-", v$sfx)
        lines <- c(lines, emit(pB, t, grp("FIXPRICE"), paste0(v$d, anchorNote,
          " Inherits every other non-coupling switch from ", budT, " (", res, ")."), v$st))
        built <- c(built, t)
      }
    }

    for (v in npiVariants) {
      t <- paste0(npiT, "-", v$sfx)
      st <- list(
        cm_taxCO2_regiDiff  = "11",
        carbonprice         = "functionalForm",
        cm_taxCO2_startyear = pB$cm_taxCO2_startyear,   # the ambitious family's anchor
        cm_startyear        = "2030",                   # 2005 aborts under functionalForm
        path_gdx_ref        = npiT,
        path_gdx_refpolicycost = npiT,
        cm_pfmBindMode = v$bm, cm_pfmTheta = v$th, cm_pfmConvTol = convTol,
        cm_pfmSectorMarkup = sectorMarkup, cm_pfmGapClosure = gapClosure)
      lines <- c(lines, emit(pN, t, tagT, paste0(v$d, " ", twinNote,
                             " Inherits every other switch from ", npiT, " (", res, ")."), st))
      built <- c(built, t)
    }
  }

  if (length(rerun)) {
    for (i in seq_along(lines)) {
      f <- strsplit(lines[i], ";", fixed = TRUE)[[1]]
      f <- c(f, rep("", length(outHdr) - length(f)))   # strsplit drops trailing empty fields
      if (length(f) >= 2 && f[1] %in% rerun && !grepl("RERUN", f[2], fixed = TRUE)) {
        # resolution-scoped, like every other group: the two resolutions are separate checkouts
        rr <- if (grepl("^SSP2-EU21-", f[1])) "EU21RERUN" else "H12RERUN"
        f[2] <- paste0(f[2], ",", rr); lines[i] <- paste(f, collapse = ";")
      }
    }
  }
  writeLines(lines, out)
  say("wrote ", out, ": ", length(built), " scenarios (", length(built) / 2, " per resolution)")
  invisible(built)
}

if (!interactive() && identical(environment(), globalenv())) {
  a <- commandArgs(trailingOnly = TRUE)
  rd <- if (length(a) > 0) a[1] else "remind_pfm"
  if (!dir.exists(file.path(rd, "config"))) {
    stop("buildPFMScenarioConfig: no config/ under '", rd, "'. Run this from the project ",
         "root (the folder holding config.yml and models/remind_pfm/), or pass the REMIND ",
         "checkout as the first argument.")
  }
  buildPFMScenarioConfig(remindDir = rd)
}
