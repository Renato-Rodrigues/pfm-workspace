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
| `buildPFMScenarioConfig.R` | scaffold for `models/remind_pfm/config/scenario_config_PFM.csv` (the deployed file is hand-maintained until `docs/design-notes/0005` F1) |
| `validatePFMScenarioConfig.R` | checks the scenario config before a submission |

## `checks/` — each backs a claim or a governed-doc statement

| script | what |
|---|---|
| `docFacts.R` | every estimation-side number the governed docs quote → `doc-facts/` |
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
