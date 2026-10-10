# `analysis/` — evidence: scripts that turn Run-Group artifacts and REMIND runs into results

Project tooling, not package code. Every script runs **from the repository root** and takes the
Run-Group as an argument (default `v5`). Scripts that read REMIND runs also take the runs folder,
`output/remind-runs/<group>` (default `output/remind-runs/v5`):

```bash
Rscript analysis/coupled/extractCoupledResults.R output/remind-runs/v5 v5
Rscript analysis/coupled/coupledBatchFacts.R v5 output/remind-runs/v5
```

Results go to `output/pfm/<group>/…`, never into this folder. Retired scripts are in
`../_archive/_wip/<date>/analysis/`. The chain scripts (sections 1–2) are due to move into package
code with v6 (`docs/design-notes/0005`, item F5).

| folder | purpose | runs where |
|---|---|---|
| `run-groups/` | build Run-Groups and the REMIND scenario config | cluster (and workstation for the config) |
| `coupled/` | the post-batch chain | workstation, after the sync |
| `checks/` | evidence checks behind claims | workstation |
| `v6/` | v6 preparation tests | workstation |
| `figures/` | the shared figure layer (its own README) | workstation |
| `_common/` | `_loadPfm.R`: load `models/pfm` from source, and announce the build used | — |

Setting up and operating a workspace (the madrat cache, the cluster sync, the reproduction checks)
is not evidence and lives in `tools/` at the project root.

## `coupled/` — after a batch lands (any Run-Group), in this order

All of it in one command, which stops on the `PITFALLS.md` §25/§25a admission rules (design note
0005 F4):

```
Rscript analysis/coupled/runCoupledStage.R <group> [runsDir] [--allow-skipped]
```

The scripts it runs, one by one:

| script | writes (under `output/pfm/<group>/`) | what |
|---|---|---|
| `extractCoupledResults.R` | `coupling/coupled-runs.rds` | reads every run under `output/remind-runs/<group>/<res>/`; flags unfinished runs and admits them only by the `PITFALLS.md` §25a rule |
| `coupledBatchFacts.R` | `coupling/coupled-facts.json` | the numbers the docs and the paper quote |
| `coupledCostsAndAbatement.R` | `coupling/coupled-costs.json` | relocation, GDP and consumption per contrast |
| `heldBudgetPrices.R` | `coupling/held-budget-prices*.rds` | realised prices under a held budget |
| `ruleCBoundFreeze.R` | `coupling/rulec-bound-freeze.rds` | the rule-C cap rebuild check, per iteration |
| `coupledRunConvergence.R` | `coupling/convergence-audit.rds` | every run against REMIND's own tolerances |
| `runProvenance.R` | `coupling/run-provenance.rds` | the REMIND commit and modified files of each run |

## `run-groups/`

The donor step (band-rule assignment of uncovered countries, which `iterativePFM()` requires) and
the offline feasibility bound are `pfmRun()` steps, not scripts: `pfmRun(group, steps = "pfm-donor")`
and `steps = "pfm-coupling-bound"`.

| script | what |
|---|---|
| `makeGroupVariants.R` | twin Run-Groups with one assumption changed (assignment rule, USA branch, φ override), exported to `output/remind-inputs/` |
| `makeSpecVariantGroup.R`, `pinSpecInGroup.R` | a Run-Group with one sector's specification pinned |
| `scenario-matrix-v6.yml` | **the v6 coupled batch** (waves 1-2, 54 runs) as a matrix: parents, rules, arms, start tags (ADR 0055). Edit this, never the CSV |
| `buildPFMScenarioConfig.R` | builds `models/remind_pfm/config/scenario_config_PFM_v6.csv` from the matrix (`pfm::buildPFMScenarioConfig`), then runs the validator and REMIND's reader. `scenario_config_PFM.csv` stays the hand-maintained `v5` record |
| `validatePFMScenarioConfig.R` | checks the scenario config before a submission (since 2026-10-07 also the v6 option columns and `cm_pfmPhiPath` against the group) |

## `checks/` — each backs a claim or a governed-doc statement

| script | what |
|---|---|
| `docFacts.R` | every estimation-side number the governed docs quote → `doc-facts/` |
| `baseloadControl.R` | what the hydro/nuclear/geothermal control and the soft selection keys do (ADR 0048) |
| `policlimInstitutions.R` | PFM's institution drivers (history, storyline rule, SSP-extension GE) against the PoliClim institution forecasts |
| `compareSpecVariantPhi.R` | the specification band (φ across spec variants) |
| `computeThetaBounds.R`, `efficiencyRatioBand.R` | θ bounds; the efficiency-ratio band |
| `frontierSECheck.R` | audit of the frontier standard errors |
| `incomeScreen.R` | is the ordering an income gradient? |
| `inputVintages.R` | which WGI / V-Dem / CAPMF releases built the panel |
| `orderingChecks.R`, `residualOrderingPhi.R` | the ordering vs the model's own prediction error |
| `phiReadingYear.R` | how the reading year moves the ordering |
| `propagateFrontierRungsToPhi.R` | φ under the alternative frontier error structures |
| `replayRescoped.R` | the historical-replay gate on the rows where the ceiling acts |
| `trendShapeGrid.R`, `trendShapePhi.R` | the declared trend shape and its effect on φ |
| `usaBranchPhi.R` | the USA share under each assignment branch |

## The `v5` λ audit — archived

λ is removed from the coupling in v6 (`docs/design-notes/0005`, D13). The scripts that reproduce
the `v5` audit (`output/pfm/v5/lambda-explained/LAMBDA-EXPLAINED.html`, and the table the
`pfm-paper-v5` Table 1 reads), with `checks/ceilingDecomposition.R` that draws two of its figures,
are in `../_archive/_wip/2026-10-01/analysis/lambda-v5/` and `../_archive/_wip/2026-10-01/analysis/checks/`. To run them
again, copy them back to `analysis/lambda-v5/` and `analysis/checks/`: they source each other by
those paths.

## `v6/`

`v6FormulationTests.R` runs the offline tests behind `docs/design-notes/0004` on `v5` artifacts.

The Phase 1 scripts of design note 0005 run on a Run-Group's artifacts and write to
`output/pfm/<group>/phase1/` (run `phase1.R` first: it builds the scenario panels the others read).
Their REMIND energy systems are the `config.yml` registry's SSP2 pair, read through `bases.R`; each
cached panel carries the gdx it was built from, and the scripts refuse a panel from another gdx.
Move them to new REMIND bases only with `refreshBases.R` (`PITFALLS.md` §34):

| script | what it answers |
|---|---|
| `phase1.R` | anchors, $k_s(t)$ on every energy system, the formulation variants, the driver-group decomposition (C3), the anchor-year seam (C8) |
| `donorAlternatives.R` | how many uncovered countries each donor-matching rule can match, how well, and what it does to $u$ and $k$ |
| `specBand.R` | every sanity-passing spec through the same formulation: is the result the deployed spec's or the band's? Scratch Run-Groups in `output/pfm/specband-<group>/` |
| `satShape.R` | family A's robustness: the deployed spec with the saturating curve's half-saturation point at 0.5x / 1x / 2x the median (sanity walk, fit, k, ranking). Scratch Run-Groups in `output/pfm/satshape-<group>/` |
| `offlineHeadline.R` | step 9: the first-round bound with the v6 φ(t) from the anchor artifact against the v5 formulation, OFFLINE |
| `sspGovernanceSwap.R` | step 6, governance part: SSP1 / SSP3 institutions on the SSP2 energy system; the SSP spread of $k$ against θ's range |
| `ceilingGate.R` | C9: the ceiling-fall gate on the v6 spec, and what it removes from the band (`specBand.R v6 ceilingRejected`) |
| `v5v6Comparison.R` | Phase 2 step 6: the `v5` → `v6` comparison (panel, spec, selection, coefficients, efficiency ordering, $u$, floor regions); design note 0005 §8 |
| `coupledV5V6Contrast.R` | Phase 6 step 1: the `v5` → `v6` contrast of every coupled headline per resolution (rule B Δ and θ slope, the markup, rule C anchor and median 2050 price, costs and relocation), each against its group's own null → `output/pfm/v6/coupling/v5-v6-coupled-contrast.{rds,json}` |
| `ruleCRelocationDecomp.R` | Phase 6: why rule C moves less abatement in `v6` than `v5` — gross relocation by region, market (`vm_co2eqMkt`) and period, the emissions-weighted price wedge, and each region's share of the change → `output/pfm/v6/coupling/rulec-relocation-decomp.rds` |
| `couplingOffline.R` | Phase 3: the v6 coupling call offline on a REMIND gdx, against the Phase 1 numbers |
| `phase3Gate.R` | Phase 3 gate: verdicts on the `EU21V371` runs (the 3.7.1 bases, the null vs the same-version `-PFMgateRef`, rule B path and history, rule C rebuild) |
| `variantGroups.R` | the wave-2 variant Run-Groups (spec, shape, assignment twins, annual rung) through the v6 formulation on the same scenario panels: k(t), the ranking u against v6, the floor region, Δφ at 2050 (offline) |
| `bases.R` | the registry's NPi / PkBudg1000 gdx (`v6Bases`), the REMIND version of a gdx, the stamped-panel reader (`v6ScenPanel`) |
| `refreshBases.R` | moves every offline analysis to new REMIND bases in one call: snapshot `phase1/` as `phase1-remind-<version>/`, re-point the registry, re-run, print old vs new (dry run unless `--apply`) |
