#!/usr/bin/env Rscript
# Build the PFM figures — one chunk per figure, runnable top to bottom or a chunk at a time.
#
#   Rscript analysis/figures/build-figures.R                  # everything, every consumer's medium
#   Rscript analysis/figures/build-figures.R --group=v5
#   Rscript analysis/figures/build-figures.R --media=paper2   # just the journal size
#   Rscript analysis/figures/build-figures.R --only=theta-sweep
#   Rscript analysis/figures/build-figures.R --guide          # regenerate the figure guide only
#
# Interactively, source R/load.R and run any single chunk. Each is independent: a chunk
# reads its own artifact and writes its own files, so you can iterate on one figure without
# rebuilding the other nine.
#
# WHAT GOES WHERE
#   the figure itself      R/fig-<id>.R          one builder, returns a ggplot
#   what it means          R/registry.R          caption, what it shows, what to read, rails
#   how big / what format  R/build.R             renderSpec(), per medium
#   the rendered files     output/all/  (every figure, PNG) and output/paper2/ (the paper)
#                          slide / poster are opt-in: --media=slide,poster
#   everything at once     output/all/index.html  (generated contact sheet)
#   the human-readable     output/FIGURE-GUIDE.md   (generated — do not edit)
#
# Adding a figure: write R/fig-<id>.R, add a registry row, add a chunk below. Nothing else.

args  <- commandArgs(trailingOnly = TRUE)
getA  <- function(f, d = NULL) { h <- grep(paste0("^", f, "="), args, value = TRUE)
                                 if (length(h)) sub(paste0("^", f, "="), "", h[1]) else d }
GROUP <- getA("--group", "v5")
MEDIA <- if (!is.null(getA("--media"))) strsplit(getA("--media"), ",")[[1]] else NULL
ONLY  <- getA("--only")

root <- tryCatch(dirname(normalizePath(sub("^--file=", "", grep("^--file=",
          commandArgs(FALSE), value = TRUE)[1]))), error = function(e) getwd())
if (!dir.exists(file.path(root, "R"))) root <- getwd()
source(file.path(root, "R", "load.R"), local = TRUE)
figuresLoad(file.path(root, "R"))

run <- function(id) is.null(ONLY) || identical(ONLY, id)
message("Run-Group: ", GROUP, "  ·  media: ",
        if (is.null(MEDIA)) "per registry" else paste(MEDIA, collapse = ", "), "\n")

if (!"--guide" %in% args) {

  # ── Fig 1b · frontier fit ───────────────────────────────────────────────────
  # Countries against their own estimated ceiling. The figure that makes "frontier,
  # not regression" visual — the vertical distance IS political slack.
  # Rail: label Diffuse only; Bulk slack ranks are not robust.
  if (run("frontier-fit")) {
    message("[frontier-fit]"); buildFigure("frontier-fit", GROUP, MEDIA)
  }

  # ── Fig 2a · frontier coefficients ──────────────────────────────────────────
  # What moves the ceiling, and that the two sectors are moved by different things.
  # Rail: neither Bulk actor-power MAIN effect is significant — the story is the
  # interactions (triangles).
  if (run("frontier-coefficients")) {
    message("[frontier-coefficients]"); buildFigure("frontier-coefficients", GROUP, MEDIA)
  }

  # ── Fig 2c · selection stability ────────────────────────────────────────────
  # The honesty exhibit: state capability is identified, the accountability channel
  # is not. Do not soften it.
  if (run("selection-stability")) {
    message("[selection-stability]"); buildFigure("selection-stability", GROUP, MEDIA)
  }

  # ── Fig 3c · theta sweep ────────────────────────────────────────────────────
  # The headline magnitude. Two non-obvious points carried ON the figure: the binding
  # share is flat across theta, and theta = 0 is NOT the cost-optimal path.
  # Rail: PFM-side bound, not a coupled REMIND result — stamped automatically.
  if (run("theta-sweep")) {
    message("[theta-sweep]"); buildFigure("theta-sweep", GROUP, MEDIA)
  }

  # ── Fig 3b · regional shortfall ─────────────────────────────────────────────
  # The constraint is distributional, not a uniform haircut. Read rank order, not levels.
  # Rail: the USA is flagged on-figure — its share is not identified across donor rules.
  if (run("shortfall-regions")) {
    message("[shortfall-regions]"); buildFigure("shortfall-regions", GROUP, MEDIA)
  }

  # ── deck · sector speeds ────────────────────────────────────────────────────
  # Speed and forecastability are different things. Only electricity beats persistence;
  # skill is encoded in colour AND text so the point cannot be lost in reproduction.
  if (run("sector-speeds")) {
    message("[sector-speeds]"); buildFigure("sector-speeds", GROUP, MEDIA)
  }

  # ── Fig 1a · chain schematic ─────────────────────────────────────
  # Conceptual, no data. The dashed return arrow is the contribution; it is labelled
  # "conditional scenario accounting" because the IV identifies no causal effect.
  # Not Run-Group stamped, deliberately - nothing in it comes from an artifact.
  if (run("chain-schematic")) {
    message("[chain-schematic]"); buildFigure("chain-schematic", GROUP, MEDIA)
  }

  # ── Fig 1c · efficiency distribution ────────────────────────────────
  # E = S/S* for all 248 projected countries, coloured by provenance. Only 48 are
  # estimated; the rest are transferred. That contrast IS the figure.
  # Rail: NOT built on projection.rds$implementability - that column is index/10, the
  # S/10 measure MODEL.md 7 prohibits.
  if (run("efficiency-distribution")) {
    message("[efficiency-distribution]"); buildFigure("efficiency-distribution", GROUP, MEDIA)
  }

  # ── Fig 4a · implementability map ─────────────────────────────────
  # Where the ceiling is ESTIMATED. Out-of-coverage countries are left uncoloured, never
  # given a value - colouring a transferred gap on the same scale would present an
  # assumption as a measurement. The grey is as much the finding as the colour.
  if (run("implementability-map")) {
    message("[implementability-map]"); buildFigure("implementability-map", GROUP, MEDIA)
  }

  # ── variant · map, all 248 countries ──────────────────────────────────────────
  # Companion to implementability-map. That one shows only what was MEASURED;
  # this shows what the coupling actually feeds REMIND, with transferred values
  # faded so measurement and assumption stay visually distinct.
  if (run("implementability-map-full")) {
    message("[implementability-map-full]"); buildFigure("implementability-map-full", GROUP, MEDIA)
  }

  # ── variant · coefficients, political terms only ──────────────────────────────
  # Same beta x SD(x) scaling as Fig 2a, fixed effects dropped so the political terms
  # get the room. The trend is scaled, never dropped - it carries 0.658 of the Bulk
  # linear-predictor variance and a reader must still see that it is the largest term.
  if (run("frontier-coefficients-focused")) {
    message("[frontier-coefficients-focused]"); buildFigure("frontier-coefficients-focused", GROUP, MEDIA)
  }

  # ── SI · relative vs absolute gap ─────────────────────────────────────────────
  # Reproduces ../_archive/_wip/2026-10-01/docs/figures/si-fig1-gap.svg on the current Run-Group.
  # PITFALLS 7 in picture form: the absolute gap ranks by CEILING SIZE, not by
  # shortfall, and reorders the ranking substantially.
  if (run("gap-relative-vs-absolute")) {
    message("[gap-relative-vs-absolute]"); buildFigure("gap-relative-vs-absolute", GROUP, MEDIA)
  }

  # ── SI · coverage, counted two ways ───────────────────────────────────────────
  # Reproduces ../_archive/_wip/2026-10-01/docs/figures/si-fig2-coverage.svg. By country count the sample looks
  # tiny; by the weight the coupling applies it is large. Both true - quoting one
  # alone misleads. Weight is emissions-proxy FINAL ENERGY, never GDP.
  if (run("coverage-three-ways")) {
    message("[coverage-three-ways]"); buildFigure("coverage-three-ways", GROUP, MEDIA)
  }

  # ── report · leave-one-country-out influence ──────────────────────────────────
  # From the reports' influence exhibit (ADR 0037). A term whose worst-case p crosses
  # alpha has a pivotal country and may not be claimed - the Bulk HorAcc main effect
  # is exactly this case.
  if (run("influence-loro")) {
    message("[influence-loro]"); buildFigure("influence-loro", GROUP, MEDIA)
  }

  # ── report · scenario fan-out ─────────────────────────────────────────────────
  # From the reports' projection exhibit. Separation between scenarios is the feedback
  # channel being alive at all - the reason split actor power is load-bearing.
  # Late horizon greyed: past ~2060 the differences are not interpretable.
  if (run("scenario-fanout")) {
    message("[scenario-fanout]"); buildFigure("scenario-fanout", GROUP, MEDIA)
  }

  # ── report · pseudo-out-of-sample validation ──────────────────────────────────
  # The negative result that shapes the design: the level forecast LOSES to persistence
  # in both sectors, which is why the model delivers ceilings and speeds and never
  # projected level paths. Reported deliberately, not buried.
  if (run("temporal-validation")) {
    message("[temporal-validation]"); buildFigure("temporal-validation", GROUP, MEDIA)
  }

  # ── deck · saturating map ───────────────────────────────────────────────────
  # Justifies ADR 0040 in one glance: estimated on one range, asked to operate on another.
  if (run("saturating-map")) {
    message("[saturating-map]"); buildFigure("saturating-map", GROUP, MEDIA)
  }

  # ── SI · estimator sign agreement ───────────────────────────────────────────
  # Harsher than a p-value: only 3 of 13 terms hold their sign across estimators.
  if (run("estimator-agreement")) {
    message("[estimator-agreement]"); buildFigure("estimator-agreement", GROUP, MEDIA)
  }

  # ── SI · the replay gate ────────────────────────────────────────────────────
  # Passes, and proves less than it looks like: the ceiling binds in 1.6-4.0% of rows.
  if (run("historical-replay")) {
    message("[historical-replay]"); buildFigure("historical-replay", GROUP, MEDIA)
  }

  # ── SI · the sharing cost ───────────────────────────────────────────────────
  # One spec for both sectors costs Bulk 4.9% and Diffuse 24.9% of theory content.
  if (run("sharing-cost")) {
    message("[sharing-cost]"); buildFigure("sharing-cost", GROUP, MEDIA)
  }

  # ── SI · the selection landscape ────────────────────────────────────────────
  # Where the deployed spec sits among 2232 candidates. 159 of the 242 admissible ones
  # fit better; it wins on a declared multi-criteria rule, not by dominating.
  if (run("selection-landscape")) {
    message("[selection-landscape]"); buildFigure("selection-landscape", GROUP, MEDIA)
  }

  # ── SI · the IV null ────────────────────────────────────────────────────────
  # Endogeneity confirmed, causal effect not identified. The reason nothing near the
  # feedback loop may say "causes".
  if (run("iv-null")) {
    message("[iv-null]"); buildFigure("iv-null", GROUP, MEDIA)
  }

  # ── report · coupled convergence ────────────────────────────────────────────
  # Settles "demonstrated in 6 of 14" visually. A single point below the tolerance is
  # consistent with convergence, not evidence of it.
  if (run("coupled-convergence")) {
    message("[coupled-convergence]"); buildFigure("coupled-convergence", GROUP, MEDIA)
  }

  # ── Fig 2b · marginal effect of incumbency ──────────────────────────────────
  # C9 in one panel. Needs the vcov: the interval is NOT the two standard errors.
  # Rail: the axis stops at the observed support, deliberately.
  if (run("marginal-effect-incumbency")) {
    message("[marginal-effect-incumbency]"); buildFigure("marginal-effect-incumbency", GROUP, MEDIA)
  }

  # ── SI · driver correlations ────────────────────────────────────────────────
  # The figure form of the old reports' correlation tables. Documents WHY selection
  # cannot separate the channels — a limitation, not a result.
  if (run("driver-correlations")) {
    message("[driver-correlations]"); buildFigure("driver-correlations", GROUP, MEDIA)
  }

  # ── Fig 3a · anchor, bound and the gap ──────────────────────────────────────
  # Where the Fig 3b/3c shortfall comes from, in price space. Regions picked from the phi
  # ordering, never by hand.
  # Rail: PFM-side bound AND written at the superseded theta = 0.74 (TODO item 1).
  if (run("anchor-bound-gap")) {
    message("[anchor-bound-gap]"); buildFigure("anchor-bound-gap", GROUP, MEDIA)
  }

  # ── Fig 4b · implementability ranked ────────────────────────────────────────
  # Read the distance between a country's two points, not its absolute position.
  # Rail: ordered by Diffuse on purpose — never read a Bulk country ranking off it.
  if (run("implementability-ranked-countries")) {
    message("[implementability-ranked-countries]")
    buildFigure("implementability-ranked-countries", GROUP, MEDIA)
  }
  if (run("implementability-ranked")) {
    message("[implementability-ranked]"); buildFigure("implementability-ranked", GROUP, MEDIA)
  }

  # ── Fig 4c · coverage per REMIND region ─────────────────────────────────────
  # The honesty panel for Fig 4: every regional share rests on a minority of the region,
  # and the USA on nothing at all.
  if (run("coverage-by-region")) {
    message("[coverage-by-region]"); buildFigure("coverage-by-region", GROUP, MEDIA)
  }

  # ── Fig 5a · coupled sector split ───────────────────────────────────────────
  # THE payoff figure. Read the two SPREADS, not the two levels: industry stays near
  # cost-optimal while households absorb the constraint.
  # Rail: never add ETS and ES; the result is conditional on the markup being on.
  if (run("coupled-sector-split")) {
    message("[coupled-sector-split]"); buildFigure("coupled-sector-split", GROUP, MEDIA)
  }

  # ── Fig 5b · the cost of political feasibility ──────────────────────────────
  # Headline B, both resolutions on one panel because their AGREEMENT is the point.
  # ── Fig 5d · where the abatement goes ───────────────────────────────────────
  # The only panel in Fig 5 that says WHO. Rail: emissions only - no GDP bar.
  if (run("coupled-relocation")) {
    message("[coupled-relocation]"); buildFigure("coupled-relocation", GROUP, MEDIA)
  }

  if (run("coupled-budget-cost")) {
    message("[coupled-budget-cost]"); buildFigure("coupled-budget-cost", GROUP, MEDIA)
  }

  # ── Fig 5c · the NPi twins ──────────────────────────────────────────────────
  # Kills "your result is an artefact of high ambition", and prints the confound that
  # decides the sign rather than leaving it to the caption.
  if (run("coupled-npi-twins")) {
    message("[coupled-npi-twins]"); buildFigure("coupled-npi-twins", GROUP, MEDIA)
  }

  # ── SI-10 / SI-11 · the frontier itself, per country ────────────────────────
  # The chain from data to coupled result, made inspectable: SI-10 is where the ceiling
  # comes from, SI-11 is what the coupling consumes. Read them as a pair - and mind the
  # seam between them, which SI-11 draws as a break on purpose.
  if (run("frontier-vs-observed")) {
    message("[frontier-vs-observed]"); buildFigure("frontier-vs-observed", GROUP, MEDIA)
  }
  if (run("frontier-projected")) {
    message("[frontier-projected]"); buildFigure("frontier-projected", GROUP, MEDIA)
  }
  # SI-12 · the same object at the resolution phi is ASSIGNED on. Complementary to the two
  # above, never a substitute - aggregation changes the object, it does not rescale it.
  if (run("frontier-by-region")) {
    message("[frontier-by-region]"); buildFigure("frontier-by-region", GROUP, MEDIA)
  }

  # ── Fig 5d · the markup-off counterfactual ──────────────────────────────────
  # The attribution panel for Fig 5a, and C20's confirmation in the same frame. Always
  # show it WITH 5a: alone, the right-hand panel reads as a scenario rather than as a
  # counterfactual that discards information.
  if (run("markup-counterfactual")) {
    message("[markup-counterfactual]"); buildFigure("markup-counterfactual", GROUP, MEDIA)
  }

  # ── v6 coupled (Phase 5 / 6) — only for a v6 group: they read the v6 coupling artifacts
  # and the v5 ones beside them. Rails: theta and kappa are declared; the v5 -> v6 drop is
  # mostly lambda's removal; rule C relocates, it does not add emissions.
  if (grepl("^v6", GROUP)) {
    for (id in c("v6-coupled-theta", "v6-coupled-arms", "v6-rulec-relocation", "v6-price-catchup")) {
      if (run(id)) { message("[", id, "]"); buildFigure(id, GROUP, MEDIA) }
    }
  }
}

# ── the figure guide ──────────────────────────────────────────────────────────
# Generated from the registry, so the caption in the paper, the notes on the slide and
# the explainer in the report are the same text by construction.
guide <- file.path(root, "output", "FIGURE-GUIDE.md")
dir.create(dirname(guide), showWarnings = FALSE, recursive = TRUE)
writeLines(figureExplainerDocument(GROUP), guide)
message("\nfigure guide: ", guide)

# the contact sheet: every figure on one page, with its rails
sheet <- figuresContactSheet(GROUP)
message("contact sheet: ", sheet)

planned <- figureRegistry(status = "planned")
if (nrow(planned)) {
  message("still to build (registered, no builder): ", paste(planned$id, collapse = ", "))
}

# ── Orphan check ──────────────────────────────────────────────────────────────
# A rendered file whose figure no longer declares that medium is never rewritten, so it sits
# in output/ at whatever it looked like when the declaration changed - and it looks exactly
# like a current figure. On 2026-08-18 five such files were being read as if fresh; one of
# them carried a stamp that had been corrected days earlier. Regenerable output must not be
# allowed to disagree with the registry.
reg <- figureRegistry()
wanted <- unlist(lapply(seq_len(nrow(reg)), function(i) {
  cons <- strsplit(reg$consumers[i], ",", fixed = TRUE)[[1]]
  # mirrors buildFigure()'s default: `all` for everything, paper2 for the paper's figures.
  # slide / poster are opt-in, so a slide render is only an orphan once it is stale AND the
  # deck is not being rebuilt - the check below therefore ignores them unless asked for.
  med <- unique(c("all", if ("paper" %in% cons) "paper2",
                  if (!is.null(MEDIA)) intersect(MEDIA, c("slide", "poster"))))
  vapply(med, function(m) {
    ext <- if (identical(m, "paper2")) "pdf" else if (identical(m, "poster")) "svg" else "png"
    file.path(root, "output", m, paste0(reg$id[i], ".", ext))
  }, character(1))
}))
onDisk <- list.files(file.path(root, "output"), pattern = "[.](png|pdf|svg)$",
                     recursive = TRUE, full.names = TRUE)
norm <- function(x) gsub("\\\\", "/", normalizePath(x, mustWork = FALSE))
orphans <- setdiff(norm(onDisk), norm(wanted))
if (length(orphans)) {
  message("
ORPHANED OUTPUTS - no registry entry declares these, so nothing rewrites them.")
  message("They are stale renders and will be read as current. Remove them:")
  for (o in sort(orphans)) message("  ", o)
  message("  Rscript analysis/figures/build-figures.R --prune")
  if ("--prune" %in% args) {
    file.remove(orphans)
    message("removed ", length(orphans), " orphan(s).")
  } else {
    warning(length(orphans), " orphaned figure output(s) in analysis/figures/output/ - ",
            "re-run with --prune to remove.", call. = FALSE)
  }
} else {
  message("no orphaned outputs")
}
