# 43. The ceiling-collapse selection gate

Date: 2026-08-23

## Status

Accepted. Implemented in `pfm` (2026-08-23, `ceilingFallGate = 0.90` by default); pending the
Run-Group re-sweep of TODO item 0b.

Extends ADR 0036 (PSM), ADR 0039 (Tournament v2) and ADR 0040 (saturating actor power and the
support-share gate). Supersedes nothing.

## Context

Selection admits a specification on how well it *fits* — the maximin worse-sector
ΔR²(theory) tier, plus the gates of 0033, 0037, 0039 and 0040. Nothing in that ladder looks at
what the fitted frontier then *does* over the projection horizon.

Measured on Run-Group `v1` (`analysis/ceilingTrajectoryBySpec.R`), the deployed spec X-0370
produces a Bulk frontier ceiling that runs **6.95 → 4.34 over 2025–2100 — a 38% fall, with 96%
of covered countries losing ceiling.** The decomposition (`analysis/ceilingDecomposition.R`)
attributes it almost entirely to **Incumbent Power × Government Effectiveness**, which carries a
*positive* coefficient: the model has learned that powerful fossil incumbents plus a capable
state raise the ceiling. A decarbonisation scenario removes incumbents by construction, so the
model contains a feedback that lowers the political ceiling as the transition succeeds.

Two things had to be established before making this a gate.

**1. Does it actually reach $\varphi$?** Partly, and less than first claimed.
`aggregateFeasibilityToRegions.R:240` assigns $\varphi$ **once**, at `tierYear` — not per period.
So the ceiling's later trajectory does not compound into the coupled price. But `tierYear` is
derived as `cm_startyear + 5` (`iterativePFM.R:161`), and 38 of the 40 configured runs set
`cm_startyear = 2030`, so $\varphi$ is fixed at **2035** — ten years into the drift, not at the
seed. Holding S\* flat at its first projected value and re-deriving $\varphi$
(`analysis/frozenCeilingPhiTest.R`, H12, θ = 0.5) gives:

| tierYear | Bulk max \|Δφ\| | Bulk median | Diffuse max \|Δφ\| | Diffuse median |
|---|---:|---:|---:|---:|
| 2025 (seed) | 0.000 | 0.000 | 0.000 | 0.000 |
| **2035 (operational)** | **0.152** | 0.020 | **0.250** | 0.044 |
| 2050 | 0.246 | 0.110 | 0.389 | 0.096 |
| 2100 | 0.188 | 0.055 | 0.500 | 0.249 |

$\varphi \in [1-\theta, 1] = [0.5, 1]$ at θ = 0.5, so the worst region's 0.15–0.25 at the
operational tier year is **30–50% of the entire available range**. The median region moves
0.02–0.04. The exposure is real, bounded, and strongly increasing in `tierYear`.

**2. Is a non-collapsing specification available, and at what cost?** Yes. Of the top 60
gate-passing specs of `v1`, **6 hold the median ceiling at ≥ 0.90 and 3 at ≥ 1.00**. The best
admissible one, X-0418 `satAP`, is Green in both sectors at maximin rank 11 against the
incumbent's rank 1, costing **≈ 8% of the mean ΔR²(theory)** (0.110 against 0.1195) — a
within-tier trade, not a tier concession.

## Decision

Add a **severe** `ceilingCollapse` rule to the projection-sanity walk and enable it by default at
`ceilingFallGate = 0.90`: reject a candidate whose **median frontier ceiling over covered
countries** falls below 90% of its first projected value by the end of the horizon.

- Scored on the **median**, because the median is what survives region aggregation into $\varphi$.
- Run inside the sanity walk only, so it costs one frontier fit per candidate per sector rather
  than one per spec in the grid.
- Reported, never silent: the flag text carries both the ratio and the share of covered countries
  still falling, and every evaluated model's ratio is returned on `$ceiling` whether it trips or
  not.

## Consequences

**It does not eliminate the behaviour, and must not be described as doing so.** The best
`shareCountriesFalling` anywhere in the scanned pool is 44%; **no spec gets below 25%**. A passing
specification holds the *median* ceiling flat while roughly half its countries still lose theirs
(X-0418: median 1.005, 46% falling — against the incumbent's 0.62 and 96%). The gate buys a large
improvement, not a fix. TODO item 11's other three options remain open.

**It is unsafe alone and must never be run without ADR 0040's `supportShareGate` and ADR 0039's
`minScenarioDelta`.** The cheapest way to hold a ceiling flat is to stop responding to the
scenario. Measured across the 60: corr(median ceiling ratio, cross-country ceiling SD) =
**−0.42**. Flatter ceilings really do come with less cross-country signal. X-0418 is not one of
these — its spread is 0.88 against the incumbent's 0.79, with *lower* out-of-support — but the
correlation is why the three gates are a set.

**Screen γ on any winner.** X-0170 has the second-best ceiling (1.002) and frontier γ =
**1.0000** exactly — the boundary degeneracy of `MODEL.md` §3.4, the same failure that
disqualified the (2005, 0.25) time-trend setting in TODO item 0b. A ceiling gate alone would
admit it.

**`apTransform` is doing much of the work, but is not sufficient.** The same X-0418 *without*
`satAP` gives 0.633 rather than 1.005, so ADR 0040's saturating form is load-bearing here. It is
not enough on its own: the deployed spec is also `satAP` and still falls to 0.62.

**Selection is now conditional on a scenario.** The gate needs `scenarioData`; without it the
sanity walk does not run and selection is unchanged. A sweep run without a scenario panel and one
run with it can now select different specifications for a further reason.

**Only ~10% of specs clear it, so watch `sanityMaxModels`.** 6 of the 60 scanned pass at ≥ 0.90.
The walk evaluates at most `sanityMaxModels` (default 20) candidates before forcing the
least-flagged one and then walking the tier-relaxed Blue pool. On `v1` two passing specs sit
inside the top 20 by rank (ranks 6 and 11), so the walk terminates cleanly — but that is a
property of this grid, not a guarantee. If a re-sweep reports `forced = TRUE` with
`ceilingCollapse` flags dominating, raise `sanityMaxModels` before weakening the gate.

**Test fixtures opt out deliberately.** `helper-psm.R::psmTestSweep()` defaults
`ceilingFallGate = NA`: the synthetic sweep panels exercise one gate at a time, and a second
severe gate firing on them would make those tests assert the wrong thing. `test-ceilingFallGate.R`
pins the production default at 0.90 so the opt-out cannot silently become the real default.

**`tierYear` is exposed as a live modelling choice.** The table above shows $\varphi$ is
materially sensitive to it, and it is currently *derived* from `cm_startyear` rather than argued.
That is not resolved here; it is recorded in TODO item 11 as owed.

**The re-sweep will pick a different specification, and the numbers move.** The scan behind this
ADR ran on `v1`'s pre-trend-change fits (TODO item 0b), so its ranking is indicative, not final.
Re-read `ceiling-by-spec.rds` from the new Run-Group before quoting any figure here.

**To restore the previous behaviour** set `ceilingFallGate = NA`.
