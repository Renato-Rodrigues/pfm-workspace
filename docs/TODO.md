# TODO — what is open

*Open items only. Anything closed lives in `_archive/<date>/`, not here.*

**Legend:** 🔴 blocking · 🟠 required for submission · 🟢 improves the work · ⚪ optional

Last reviewed **2026-10-02**.

**`v5` is frozen.** `v5-final` is tagged in the project repo, `pfm`, `mrpfm`, `remind_pfm` and
`paper-forge`, after a reproduction check on a fresh clone of those commits. The tag covers:
- Run-Group `output/pfm/v5` (`panel_hash f8845f66fb39d316`);
- its 62-run coupled batch;
- the evidence bundle of `papers/pfm-paper-v5`, which is frozen at v18 and will not be submitted.

The `psm` → `pfm` rename is done and released as `pfm` 0.5.0; the current release is **`pfm` 0.6.0**.

**The work plan is `docs/design-notes/0005-v6-implementation-plan.md`** (Phases 0–6). This list
orders its next steps; every open item is a step of that plan, placed below, or marked as
outside it. IDs such as E13 or D17 refer to that note.

> **Item numbers are stable identifiers.** `MODEL.md`, `SCENARIOS.md`, `COUPLING.md`,
> `PITFALLS.md`, design note 0005 and `papers/pfm-paper-v5/docs/*` cite them, so a surviving item
> keeps its number and §22 maps every retired one. The file before this review is
> `../_archive/_wip/2026-10-02/TODO-pre-v6-review-2026-10-02.md`.

---

## 🧭 What to do next

Phase 0 of the v6 plan is almost done. Steps 0 (snapshot and tags), 1 (the rename) and 2 (the
small fixes E5, E10, E13) are finished. The **data side of Phase 2 is done in code** (2026-10-02):
the panel definition (2023 on the IEA 2025 edition, the annual sibling `v6-annual`, geothermal),
SSP-dependent scenario panels and the institution rule (A2 coverage, A3, A4, E9, E14, D10;
`DATA.md`), with D7 (the actor-power form) — the last releases are **`mrpfm` 0.4.0** and **`pfm`
0.8.0**. Also done 2026-10-02 (0005 E/F): a run with gaps now fails (E23); the coupling call
went from 99 s to 11 s after its first call (E17/F7); convergence covers the market shares (E8);
`pfmPreflight()` and `submitPFM()` (F2/F3); the post-batch chain as one command (F4); the
`paper-forge` data check (E19); `config.yml` cleaned (E15). These are commits after 0.8.0 /
0.4.0, not released (the version moves when the author decides). Only what the `v6` run needs is
listed here, in order.

1. 🔴 **On the cluster: Phase 0, step 3, and the `v6` cache.** Nothing else needs the workstation.
   - Pull the project repo, `pfm`, `mrpfm` and `remind_pfm` (branch `pfm`) in
     `models/remind_pfm-EU21/` and `-H12/`; delete each REMIND checkout's stale
     `modules/45_carbonprice/functionalForm/input/p45_regiDiff_feasibility.inc` by hand (git-ignored,
     so the pull leaves it; E10).
   - Install `mrpfm` and `pfm` from the pushed `main`: once into your R library (`R CMD INSTALL`)
     and into each REMIND checkout's renv (dependencies hydrated from your library, `pfm`/`mrpfm` installed directly). `./tools/setup.sh --cluster --install
     --no-cache` does both (`RUNNING.md` steps 3-4; `devtools::install` fails on the cluster).
     Then `pfm::pfmPreflight(checks = c("repos", "installed", "mappings", "replay"))`: the
     version number alone no longer proves the code (commits land under 0.8.0 / 0.4.0), so it
     compares a fingerprint of every function, and runs the replay gate (`PITFALLS.md` §2, §23).
   - Prepare the `v6` cache: `Rscript tools/prepareMadratCache.R --group v6`, then the same for
     `--group v6-annual`. The first prints `panel: 2000-2023, 5-year moving average, IEA 2025
     edition, geothermal …`. **This must run on the cluster:** the IEA 2025 edition recomputes
     mrremind's `calcIO`, whose raw sources (GCAM, FAO, IMF, PEAP) the workstation lacks
     (`DATA.md` §7). Then check the 2023 sample (countries with both outcomes in 2023, NA drivers).
2. 🔴 **Then the `v6` and `v6-annual` sweeps** (0005 Phase 2, step 4). D7 is decided (2026-10-02,
   options 1C/2C/3A) and in `config.yml` `sweep:`: all four actor-power forms, no composite specs,
   the actor-power extrapolation gate. `pfmRun(group = "v6", stage = "sweep", dryRun = TRUE)`
   prints both the `panel` and the `sweep` line; check them before submitting. The grid is
   about twice the `v5` one in split specs, so size the job accordingly. Later, the coupled
   batch goes through `submitPFM()` (`RUNNING.md` step 7) and `runCoupledStage.R` (step 10).
3. **Workstation, in parallel: Phase 1, the offline prototype on `v5`** (0005 Phase 1).
   - Write `computeAnchorGap()` and `computeStrengthPath()`.
   - The acceptance test: reproduce the methodology's $k_{Diffuse}$ = 0.70 / 0.54 / 0.56 and
     $k_{Bulk}$ = 1.08 / 1.18 / 1.21 (2035 / 2050 / 2070) on the `-PFMlevelBfix` energy system.
     These are offline numbers on Run-Group `v5`, from `../communication/methodology/PFM-Methodology.docx`
     (2026-09-30), as quoted in 0005 Phase 1, step 3.

Phases 2–6 follow 0005 §4 in order: the `v6` re-sweep, the coupling code, the run tooling, the
`v6` batch and the new paper. Small items already placed in that order:
- **E11** (the GAMS peak-budget check, was item 32) and **E12** (the mode-R bind share, was item
  21): the Phase 3 GAMS pass.
- **E23** (a failed step still lets `pfmRun()` exit 0): with the preflight, F2, in Phase 4. Until
  then, read the last lines of every run log (`DONE WITH GAPS` names the steps).
- **E19** (`paper-check` run inside a paper workspace reports every source as missing): fix it in
  `paper-forge` before the `v6` paper workspace is built, Phase 6.

**Not needed for the `v6` run: your call, and time-sensitive if you want it.**
- 🟢 **E25: keep `v5` rebuildable from scratch.** The `v5` artifacts themselves are on disk, and the
  `v6` paper's `v5` → `v6` contrasts read those. What the `v5-final` tags cannot give is a rebuild
  of `v5`'s inputs on a new machine. For that:
  - fetch the 45 shared-cache files the `v5` coupled runs read from
    `/p/projects/rd3mod/inputdata/cache` before that cache is cleaned
    (`records/v5/madrat-cache-used-runs.tsv`; its size and md5 columns are still empty);
  - deposit the 8 of 12 pinned estimation files that exist only in this workstation's
    `data/madrat/` (`records/v5/madrat-cache-used-pfm.tsv`; found by the reproduction check of
    2026-10-01; `RUNNING.md`, still to do 3 and 7).

**Deferred by the author:** version control for `../communication/` and `papers/pfm-paper-v5/`
(E4). A repository may come only with the `v6` paper.

---

## 22. Where the retired items went

Pre-review files: `../_archive/_wip/2026-09-11/TODO-pre-cleanup-2026-09-11.md`,
`../_archive/_wip/2026-09-14/TODO-pre-cleanup-2026-09-14.md`, `../_archive/_wip/2026-09-16/docs-pre-v5-sweep/TODO.md`,
`../_archive/_wip/2026-09-17/TODO-pre-review-2026-09-17.md`,
`../_archive/_wip/2026-10-02/TODO-pre-v6-review-2026-10-02.md` (the full text of every item retired
on 2026-10-02), and the bodies of the items closed on 2026-09-17/18 are in
`../_archive/_wip/2026-09-18/TODO-closed-2026-09-18.md`.

| item | status | where it went |
|---|---|---|
| **36** | ⛔ superseded 2026-10-02 | no `v5` manuscript: `papers/pfm-paper-v5` is frozen at v18 and the `v6` paper replaces it (0005 D19, Phase 6) |
| **41** | ⛔ superseded 2026-10-02 | no `v5` runs (author, 2026-10-01); rule C at θ 0.325 / 0.50 / 0.675 is `v6` wave 1 (0005 Phase 5) |
| **6** | ⛔ superseded 2026-10-02 | the USA assignment rules (donor / low) are `v6` wave 2 (0005 Phase 5, D-M2) |
| **12** | ⛔ superseded 2026-10-02 | λ is removed from the coupling in `v6` (0005 D13); the `v5` disclosure question lapsed with the `v5` paper |
| **7a** (open part) | ⛔ decided 2026-10-02 | one shared spec is held fixed in `v6` (0005 D17); the measured band (C31) is reported in the `v6` paper |
| **11a** | ⛔ superseded 2026-10-02 | the ceiling-fall gate is re-examined on `v6` (0005 C9); the guard clean-up is E14 |
| **40** | → E13 | 0005 Phase 0, step 2 |
| **20** | → E10 | 0005 Phase 0, step 2 |
| **21** | → E12 | 0005 Phase 3 (or Phase 0, step 2) |
| **32** | → E11 | analysis side done 2026-09-17; the GAMS side is 0005 Phase 3 |
| **4** | ⛔ superseded 2026-10-02 | the `v6` decomposition of $k_s(t)$ by driver group (0005 C3) |
| **8** | → C11 | optional, a separate workstream (0005 §6) |
| **9** | ⛔ obsolete 2026-10-02 | the coupling uses no `.Rprofile`: since 2026-08-11 the run folder carries its configuration (`pfm-coupling.yml` from REMIND's `preparePFM.R`, `pfm-coupling-runtime.yml` from `presolve.gms`; `COUPLING.md` §2, corrected 2026-10-02). The item's other points: the SSP check → D9, the cost of a PFM call → E17 |
| **38** | → D-M3 | the deposit, built into `v6` (0005 Phase 6) |
| **39** | ✅ done 2026-10-01/02 | project repo created and pushed; everything tagged `v5-final`; the rest is E4 (deferred) |
| **35** | ✅ done 2026-10-02 | citation slots filled 2026-09-18; the two hazards resolved 2026-10-02 with copies placed in `papers/pfm-paper-v5/literature/sources/`: the publisher's PDF of Battese & Coelli 1992 (note re-appraised, now INCLUDE) and the authors' final manuscript of Douenne & Fabre 2022 with its online appendix (70 / 14 / 22% unchanged; locators §3.1, fn. 21). Port with the literature to the `v6` paper (0005 D19); its uncited-note hygiene goes with it |
| **7** | ✅ done 2026-10-02 | `psm*` → `pfm*` renamed in `pfm`, `preparePFM.R`, `analysis/` and the governed docs, after the `v5-final` tags (`design-notes/0005` D21, F9). Legacy names are still read: `selected-models-psm.yml`, `psm-*` steps, and deprecated aliases for the old exported functions. Released as `pfm` 0.5.0 |
| **33** | ✅ done 2026-09-18 | costs and abatement relocation adopted as claims **C36** (held budget relocates: net +3/+4 Gt against 72/81 Gt moved) and **C37** (where it lands, + the GDP caveat) — `SCENARIOS.md` §4.8, **Fig 5d**, P3.7b |
| **37** | ✅ done 2026-09-18 | Fig 4b re-pointed to region rank intervals; Fig 2b carries both incumbency terms (opposite signs) — `MODEL.md` §2.3, claim C9 |
| **28** | ✅ resolved 2026-09-17 | replay gate re-scoped to the rows where the ceiling acts (+0.001 Bulk / +0.064 Diffuse) — claim C29, `MODEL.md` §8.4 |
| **14g** | ✅ decided 2026-09-17, measured 2026-09-18 | two headlines; the quantity one is `-PFMlevelBfix` vs `-PFMgateBfix` (+159.3 / +163.8 Gt) — `SCENARIOS.md` §4.2a, claim C35, `COUPLING.md` §11.7 |
| **30** | ✅ closed 2026-09-17 | H12 `-PFMratioMin` re-run: peaks 1003.0 Gt at 2090, 73 iterations; C20 quotes both resolutions |
| **31** | ✅ closed 2026-09-17 | H12 `-PFMratioTh325` re-run: markup written = seen (0.340), 94 iterations |
| **17** | ✅ closed 2026-09-17 | EU21 `-PFMlevelC` restarted from its own gdx for 57 more iterations: 1000.4 Gt, bind share 0.585, warn 0 — rule C holds in 6 of 6 (C34) |
| **7a** | ✅ closed 2026-09-17 | specification band measured on `v5-specalt` — `MODEL.md` §5.3.0, claim C31 |
| **1c** | ✅ decided 2026-09-17 | both λ estimates documented, full panel justified for projection — `MODEL.md` §4.3.1; log line fixed in `runPFMCouplingBound.R` |
| **1** | ✅ decided 2026-09-17 | θ in the main text, sources 2–8 of φ uncertainty in the SI — `MODEL.md` §5.3.2; the specification band (source 3) measured the same day, item 7a |
| **26** | ✅ done 2026-09-17 | the `v5` coupled batch; checks and floor regions in `SCENARIOS.md` §3, §6.2 |
| **27** | ✅ resolved 2026-09-17 | frontier and mean regression are different estimands; rule in `MODEL.md` §2.2 and the claims header |
| **1e-a** | ✅ closed 2026-09-17 | gap persists; switch costs measured (`SCENARIOS.md` §1.2); Methods wording fixed in `paper-design.md` M3 and abstract conditions |
| **19** | ✅ closed 2026-09-17 | gate matches to $0.71 / $0.89; wording in claim C6 and the design referee line |
| **14** | ✅ closed 2026-09-17 | gate 0.275 / γ 0.999 are code defaults; margins disclosed in claim C27 and ADR 0045; covariance screen → item 40 |
| **24a** | ✅ closed 2026-09-17 | all 35 figures rendered on `v5`, 104 outputs fresh; the build already continues past a failing figure (`analysis/figures/R/build.R`); design mismatches → item 37 |
| **25** | ✅ retired 2026-09-17 | `analysis/bindingSectorOnE.R` archived to `../_archive/_wip/2026-09-17/analysis-retired/`; superseded by `frontier.rds` (C10) and the coupled attribution (C24) |
| **29** | ✅ closed 2026-09-17 | `remind_pfm` comments updated to `v5` λ (commit with item 39) |
| **28** | ✅ resolved 2026-09-17 | re-scoped replay, body kept above until written into C29 |
| 5, 14h | ✅ closed | the claims ledger and `MODEL.md` are on `v5` |
| 13 | ✅ closed | the trend-shape grid; defence in `MODEL.md` §2.3.1 |
| 15, 16, 18, 23, 24 | ✅ closed | previous batch's coupling artifact, detectors, θ sweep, map figures, estimation figures |
| 1e | ✅ closed | the mode-R floor's λ |
| 0, 0b, 1d | ✅ closed | aggregation weight; country-resolution re-sweep; θ lower bound → 14g |
| 2, 2.1, 2.4, 3a, 7b | ⛔ superseded | → items 19, 26, 17, 14g |
| 3 | ✅ closed | reference price floor switch → claim C21 |
| 10 | ✅ closed | no seam; `PITFALLS.md` §21 |
| 11 | ✅ resolved | residue → item 11a |
| 14b–14f, 14i | ✅ closed | the specification decision (ADR 0045/0046) and its sub-items |
| 20 (registry) | ✅ closed | `config.yml`'s scenario registry |
