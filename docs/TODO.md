# TODO — what is open

*Open items only. Anything closed lives in `_archive/<date>/`, not here.*

**Legend:** 🔴 blocking · 🟠 required for submission · 🟢 improves the work · ⚪ optional

Last reviewed **2026-09-18**, against Run-Group **`output/pfm/v5`** (country resolution,
`panel_hash f8845f66fb39d316`, `pfm 0.4.0`), deployed spec
**`X-2079 WGIge|noRoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp`**. Estimation, diagnostics,
selection bootstrap, λ audit, the offline coupling bound, the specification variant `v5-specalt` and
the coupled REMIND batch (`output/remind-runs/v5/{EU21,H12}/`, **62 runs** over 2026-09-16 and 2026-09-17) are all on
`v5`. **Every run finishes, converges and holds its budget; none ends at the iteration cap.**
**All 37 figures are rendered on `v5`** — `analysis/figures/output/all/index.html` shows every one of them on a
single page — and the **paper evidence bundle is current**: `papers/pfm-paper-v5/paper-data/` (32 data files, 332
numbers, 26 source artifacts, validated clean).

> **Item numbers are stable identifiers.** `MODEL.md`, `SCENARIOS.md`, `COUPLING.md`,
> `PITFALLS.md` and `papers/pfm-paper-v5/docs/*` cite them, so a surviving item keeps its number even where
> the list is no longer contiguous. §22 maps retired numbers. The file before this review is
> `../_archive/_wip/2026-09-17/TODO-pre-review-2026-09-17.md`, and the bodies of the items closed on
> 2026-09-17/18 are in `../_archive/_wip/2026-09-18/TODO-closed-2026-09-18.md`.

---

## 🧭 What to do next

**The model work is done.** 62 coupled runs, all converged; the specification band measured; the
evidence bundle current (32 data files, 332 numbers); 37 figures rendered on `v5`. Nothing in the
queue is waiting on the cluster. **What stands between here and a submission is prose.**

**One decision only you can make:**

1. 🟠 **Whether to retarget the path on the frontier gap** (item 12a) — recommend **declining** for
   this paper and stating the limitation in the SI. Everything else that needed a decision is decided
   (λ documentation, θ in the main text, two headlines, C36/C37 adopted).

**Then, in order:**

2. 🔴 **Draft the manuscript** (item 36) — S2, S3, S4 and Methods are all unblocked: every coupled
   number is final, C35/C36/C37 are adopted, and the figures match the design. Freeze the bundle
   first, draft one section per `paper-draft` invocation, gate with `paper-check`.
3. 🟠 **Four rule-C runs at θ = 0.325 and 0.675** (new item 41) — the one claim still resting on a
   single severity. Everything else already carries the declared range.
4. 🟠 **The USA feasibility range** (item 6) — workstation only, feeds one Methods sentence.
5. 🟡 **Get the workstation-only work somewhere durable** (item 39) — `remind_pfm` is pushed;
   `analysis/`, `analysis/figures/`, `papers/pfm-paper-v5/paper-data/` and the governed docs exist on this machine only.
6. 🟡 **Four small code items** that no longer block anything but will be asked about: the stale
   coupling input (20), the mode-R bind-share diagnostic (21), the GAMS peak-budget check (32) and
   the frontier-covariance screen (40).
7. ⚪ Re-acquire two sources properly: a readable Battese & Coelli 1992, and the published Douenne &
   Fabre (item 35).

**The coupled result is the paper** (`CLAUDE.md`).

---

# Coupled batch

## 32. 🟡 `pm_pfmBudgetWarn` does not see a peak-budget overshoot — half done

✅ **Analysis side done 2026-09-17:** `extractCoupledResults.R` prints every budget-forced run whose
cumulative CO₂ is still rising at the horizon end, and `coupledBatchFacts.R` records them as
`qc$neverPeak` (`PITFALLS.md` §26).

**Still open (GAMS side):** add a peak-year check on `pm_actualbudgetco2` to `presolve.gms` next to
`pm_pfmBudgetWarn`. The run that exposed the blind spot (H12 `-PFMratioMin`) has since been re-run
and now peaks, so the test needs a deliberately short run rather than that gdx. The check itself is
still missing, and nothing in GAMS would catch the next one.

## 20. 🟡 A stale coupling input that has not bitten but would

`models/remind_pfm/modules/45_carbonprice/functionalForm/input/p45_regiDiff_feasibility.inc` is an H12-shaped
export from 2026-08-10 with φ values unrelated to the deployed spec. At EU21 its region names are not
in `regi`, so it seeds nothing; it would bite silently if the names ever lined up. Regenerate from `v5`,
or delete it and let runs start uncoupled until the first PFM call.

## 21. 🟡 Modes R and M have no bind-share diagnostic

`p45_pfmBindShare_iter` is written only under `cm_pfmBindMode = 2`. Mode R has no trace of how much
of the political gap it actually took. If mode R carries a figure, add the share of region-periods
where `p45_regiDiff_ratio < 1 − ε` and the mean shortfall against the anchor. Item 33 partly covers
the need from the emissions side.

---

# λ

## 12. 🟠 λ: what it rests on, and whether to retarget it

The audit is `output/pfm/v5/lambda-explained/LAMBDA-EXPLAINED.html` (`output/pfm/v5/lambda-explained/`).

- **a. DECISION — retarget?** The ECM attractor ranks observed stringency worse than the frontier
  (Spearman 0.40 vs 0.65 Bulk, 0.48 vs 0.90 Diffuse), and retargeting on the frontier gap would change
  the path. **Recommendation: decline for this paper** — at `cm_pfmGapClosure = 0` the closure rate is
  not used in modes R and L, so the retarget would change φ's projection only, and the Diffuse ≤ 2015
  frontier it rests on is at γ = 1.000. State the limitation in the SI.
- **b. Disclosure (writing only):** λ̂ sits below (Bulk) or inside (Diffuse) a no-adjustment placebo
  null — 0.291 [0.181, 0.419] / 0.104 [0.062, 0.209]. In the bundle; goes in Methods M3.
- **c, d. Disclosure or decline in writing:** λ is a cross-country quantity (67% of Diffuse countries
  have λ ≤ 0), and a bare ECM forecasts better but cannot drive the path.

**Done when:** (a) is decided and (b)–(d) are in Methods or explicitly declined.

**A prior question, written up 2026-09-18:** whether λ belongs in the paper *at all* —
`docs/design-notes/0003-lambda-in-or-out.md` carries two draft abstracts (with and without), the six
claims that would be dropped (C12–C16, C25, C29) and the fifteen that would survive but weaken, and
the asymmetry that decides it: **λ = 0 is the conservative choice for the cost headline and the
generous one for the price split**, so dropping λ leaves the split resting on an undisclosed
assumption. It also separates λ's two jobs — the REMIND switch (droppable, changes nothing) from the
projection rate (not droppable: no λ, no φ).

---

# Frontier, specification and θ

## 7a. 🟢 Should Bulk and Diffuse share one specification — band MEASURED 2026-09-17

**The price on `v5`** (claim C30): Bulk gives up 19.4% of achievable ΔR²(theory), Diffuse 19.8%.

✅ **The band is measured** (`output/pfm/v5-specalt`, Bulk pinned to `X-1791`; five steps re-run from the
frontier to the coupling bound; `output/pfm/v5/coupling/spec-band-v5-specalt.rds`): Spearman **0.775**,
median |Δφ| **0.0001**, max **0.271** (IND), median rank shift **1 of 21**, **5 of 21** regions move
more than 0.05, and the floor region moves **REF → IND**. Written into `MODEL.md` §5.3.0 / §5.3.2 and
claim C31 (now established). `X-1959` was not run and is not needed for C31.

**Still open, and now smaller:** whether the two sectors should share one spec at all. The band says
the sharing choice is not innocuous for the regions where Bulk binds. **Done when:** the SI states the
band with its max and rank shift (not the median alone), and P4.4 cites C31 as established.

<details>
<summary>How to run the variant group, on the cluster</summary>

```bash
# Bulk per-sector optimum; the name must match sweep.rds EXACTLY (this one has no satAP suffix)
Rscript analysis/run-groups/makeSpecVariantGroup.R v5 v5-specalt Bulk "X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp"
Rscript -e 'pfm::pfmRun(group = "v5-specalt",
                        steps = c("psm-frontier","psm-temporal","psm-donor",
                                  "psm-projection","psm-coupling-bound"),
                        cluster = "slurm")'
#    The log MUST list those five steps in that order, and the LAST line must not be
#    "[PSM-BOUND] skipped - missing: ...".
Rscript analysis/checks/compareSpecVariantPhi.R v5 v5-specalt
```

> 🔴 **The θ-dial trap.** Differencing stored φ across two groups written at different anchors measures
> the dial. `compareSpecVariantPhi.R` recovers `u = (1−φ)/θ` and re-applies one θ unconditionally.

</details>

## 6. 🟠 The USA's feasibility share is a range, not a point

No covered country; pinned by `basisOverride = c(USA = "median")`; coupled φ **0.649** (EU21) /
**0.567** (H12) in `-PFMlevelB`. **Can be done on the workstation:** re-run `psm-donor` and
`psm-coupling-bound` offline with the USA on each basis rule (donor / lowBand / median) and report the
φ range. **Done when:** the range is in Methods and every figure carrying US φ shows it as a range.

## 11a. 🟡 The ceiling-fall gate is "better, not fixed"

The deployed spec clears `ceilingFallGate` by **0.003** (Bulk 0.9025); 75% of Bulk countries' ceilings
still fall by 2100. Disclose in the SI; re-specifying is out of scope for this paper.
`.driverSupportRanges()` still excludes the time trend from the projection guard — harmless (winsorising
a frozen trend is a no-op), clean up with item 7.

## 40. 🟡 NEW — nothing screens a corrupt frontier covariance automatically

`vcovCheck` records a corrupt covariance on `frontier.rds`, but `runPSMSweep()` does not gate on it,
and one numerically dead spec sits in the ranked list (`../_archive/_wip/2026-10-01/docs/reference/spec-selection-2026-09-15/`).
The deployed spec is clean (ratio 0.97 / 1.01). Add a severe flag in the sanity walk.

## 4. 🟢 Decompose the ceiling feedback per country

The mean decomposition exists (`../_archive/_wip/2026-10-01/analysis/checks/ceilingDecomposition.R v5`, archived with the λ audit: Bulk net −0.28 logit, Diffuse
+0.64). Owed: the per-country distribution and its sign across rungs. More relevant now that the coupled
feedback is visible (φ moves up to 0.08, claim C23).

## 8. 🟢 Estimate the dimensionless price–efficiency elasticity

$\log(1+P_{r,t}) = \alpha_r + \tau_t + \beta E_{r,t} + \varepsilon$ — the only remaining route to an
empirical θ. Needs a carbon-price panel; cannot block the paper.

---

# The paper

## 35. ✅ DONE 2026-09-18 — every citation slot is filled by an appraised source

All eight `[CITATION: …]` placeholders in `paper-design.md` resolve to appraised notes. **57 notes,
41 INCLUDE**, `check-literature.R` clean. Acquired and appraised on 2026-09-17/18:

| source | verdict | fills |
|---|---|---|
| Ohlendorf et al. 2021, *Distributional impacts of carbon pricing* (CC BY) | INCLUDE | P3.6 incidence — transport pricing is **+44.7 pp** more likely progressive |
| Klenert et al. 2018, *Making carbon pricing work for citizens* | INCLUDE-WITH-CAVEATS | P3.6 acceptability — a Perspective, not a study |
| Douenne & Fabre 2022, *Yellow vests…* | INCLUDE-WITH-CAVEATS | P3.6 — **70% would gain, 14% believe it**; belief, not incidence, is the constraint |
| Aigner, Lovell & Schmidt 1977 | INCLUDE | P1.3 — the estimator the ceiling rests on |
| Jondrow et al. 1982 | INCLUDE | P1.3 — per-country shortfall, and why it is not consistent |
| Battese & Coelli 1992 | INCLUDE-WITH-CAVEATS | P1.3 — the time-decay rung |
| Bohnet et al. 2026 (CIB, EU) | INCLUDE-WITH-CAVEATS | P4.1 — the elicitation alternative |
| Zwar et al. 2023 (Ariadne) | BACKGROUND-ONLY | P4.2 — generic indices miss climate-specific institutions |

**Two hazards drafting must respect:**

- 🔴 **Battese & Coelli 1992 is a scan with no text layer** and could not be read. Its DOI and metadata
  are Crossref-verified; **no number may be quoted from it**, and it is cited only as the origin of the
  decay rung. Get an OCR'd or publisher copy and re-appraise.
- 🔴 **The Douenne & Fabre PDF is the 2020 HAL working paper**, titled differently from the 2022 AEJ
  article. Cite the published version and re-verify the 70 / 14% figures against it.

**Residual hygiene:** **20 INCLUDE notes are cited by nothing** in the design — mostly Methods/S2
sources drafting will absorb. Any still uncited when drafting ends should be downgraded. Three DOIs
were wrong or missing on file and are now corrected (Treib 2007, Mildenberger 2020, Dolphin 2016).

## 41. 🟠 NEW — rule C is the one claim tested at a single severity

Every headline already carries the declared θ range: the quantity headline **+100.0 / +159.3 / +224.1**
(EU21) and **+100.3 / +163.8 / +235.6** (H12) at θ = 0.325 / 0.50 / 0.675, mode R's anchor **1.18× /
1.33× / 1.55×** and its within-region split **0.81–1.19 / 0.66–1.37 / 0.48–1.73**, and the relocation
arms come with them (`levelBfixTh325/Th675` are in `coupled-costs.json`).

**Rule C does not.** `-PFMlevelC`, `-PFMlevelCMin` and `-PFMlevelCGapC` exist **only at θ = 0.50**, and
claim **C34** — "the budget can be held under the political cap, in 6 of 6 configurations" — is the one
general statement in the paper resting on a single severity. Severity is exactly what should break it:
at θ = 0.675 the cap binds harder, and the EU21 run already needed ~150 iterations at θ = 0.50.

**The runs:** `-PFMlevelCTh325` and `-PFMlevelCTh675` × EU21, H12 — **4 runs**, same switches as
`-PFMlevelC` with `cm_pfmTheta` changed. ✅ In the config as `H12RULEC` / `EU21RULEC`
(`startgroup=H12RULEC` from the H12 checkout).

**Done when:** C34 says whether the budget still holds at the harsh end, or names the severity at which
it stops holding — which would be a *result*, not a failure.

## 36. 🔴 No manuscript text exists yet — and it is now the critical path

`papers/pfm-paper-v5/manuscript/` does not exist. The design, the claims ledger, a validated evidence bundle and 37
figures on `v5` all do. **Nothing blocks drafting any more** — S3 was the last section waiting, and its
inputs (the `FIXPRICE` family, the H12 re-runs, C35/C36/C37, Fig 5b and 5d) are final.

**Order:** S2 (the frontier) → S3 (the coupling) → S4 (discussion) → Methods M1–M3 → S1 last, when the
result it introduces is fixed. One section per `paper-draft` invocation. **Freeze the bundle first**
(`paper-data` rule: regenerating mid-draft silently changes numbers already written), then gate with
`paper-check`.

**Two things drafting must not lose**, because both are easy to write around: the GDP effect never
appears without the CO₂ number (C37), and the two incumbency channels are always reported as a pair
(C9).

## 39. 🟡 Uncommitted work

✅ **`remind_pfm` is committed and pushed** — `cm_pfmAnchorFromGdx` (`main.gms`,
`functionalForm/datainput.gms`, `declarations.gms`) and the 63-row scenario config are in
`946bd84ae` on branch `pfm`, and the λ comments in `26c718c21`.

**Still outside version control** (the working tree, now `pfm-workspace/`, got its git repository on
2026-10-01 and has no first commit yet, so these live only on this machine): `pfm` (the 0.275 gate defaults, `R/` and `man/`); `analysis/`
(`coupledBatchFacts.R` with the fixed-price block, `coupledCostsAndAbatement.R` with the FIXPRICE
contrasts, `compareSpecVariantPhi.R` now writing `spec-band-*.rds`, `buildPFMScenarioConfig.R`,
`replayRescoped.R`, `computeThetaBounds.R`, `extractCoupledResults.R`); `analysis/figures/` (Fig 5b
re-pointed to the pinned-path pair, registry); `paper-forge` (`check-data.R`);
`papers/pfm-paper-v5/paper-data/` (32 data files, 332 numbers, incl. `extract-costs.R`); and the governed documents.

**Owed for the availability package** (item 38): whatever of this the paper's reproduction chain
needs has to be archived somewhere a referee can reach — a fix that exists only on one workstation
is the same failure as one that was never pushed (`PITFALLS.md` §2).

## 38. 🟢 NEW — data and code availability package

Nature Climate Change requires availability statements. Owed: a frozen archive of `output/pfm/v5` artifacts
the bundle reads (listed with hashes in `papers/pfm-paper-v5/paper-data/output/manifest.json`), the 62 gdx files (or
the extracted `coupled-runs.rds` plus the REMIND commit and scenario config), and the `pfm`/`mrpfm`
versions. Use `paper-submission` when drafting is done.

## 7. ⚪ Rename `psm*` → `pfm*` in code

Deferred until after submission — renaming invalidates artifact paths the bundle's manifest traces to.

## 9. ⚪ Loose ends in the coupling

- The per-run `.Rprofile` is hand-written and untracked (static paths only).
- `pfm.couplingWeightScenario` names an SSP that GAMS cannot validate; check by hand.
- ✅ Measured: each PFM call costs **128–189 s** (median 159 s) over 153 calls in the `v5` batch —
  about 6.8 h of the batch, 3–8 calls per run.

---

## 22. Where the retired items went

Pre-review files: `../_archive/_wip/2026-09-11/TODO-pre-cleanup-2026-09-11.md`,
`../_archive/_wip/2026-09-14/TODO-pre-cleanup-2026-09-14.md`, `../_archive/_wip/2026-09-16/docs-pre-v5-sweep/TODO.md`,
`../_archive/_wip/2026-09-17/TODO-pre-review-2026-09-17.md`, and the bodies of the items closed on
2026-09-17/18 are in `../_archive/_wip/2026-09-18/TODO-closed-2026-09-18.md`.

| item | status | where it went |
|---|---|---|
| **33** | ✅ done 2026-09-18 | costs and abatement relocation adopted as claims **C36** (held budget relocates: net +3/+4 Gt against 72/81 Gt moved) and **C37** (where it lands, + the GDP caveat) — `SCENARIOS.md` §4.8, **Fig 5d**, P3.7b |
| **37** | ✅ done 2026-09-18 | Fig 4b re-pointed to region rank intervals; Fig 2b carries both incumbency terms (opposite signs) — `MODEL.md` §2.3, claim C9 |
| **28** | ✅ resolved 2026-09-17 | replay gate re-scoped to the rows where the ceiling acts (+0.001 Bulk / +0.064 Diffuse) — claim C29, `MODEL.md` §8.4 |
| **14g** | ✅ decided 2026-09-17, measured 2026-09-18 | two headlines; the quantity one is `-PFMlevelBfix` vs `-PFMgateBfix` (+159.3 / +163.8 Gt) — `SCENARIOS.md` §4.2a, claim C35, `COUPLING.md` §11.7 |
| **30** | ✅ closed 2026-09-17 | H12 `-PFMratioMin` re-run: peaks 1003.0 Gt at 2090, 73 iterations; C20 quotes both resolutions |
| **31** | ✅ closed 2026-09-17 | H12 `-PFMratioTh325` re-run: markup written = seen (0.340), 94 iterations |
| **17** | ✅ closed 2026-09-17 | EU21 `-PFMlevelC` restarted from its own gdx for 57 more iterations: 1000.4 Gt, bind share 0.585, warn 0 — rule C holds in 6 of 6 (C34) |
| **7a** | ✅ closed 2026-09-17 | specification band measured on `v5-specalt` — `MODEL.md` §5.3.0, claim C31 |
| **1c** | ✅ decided 2026-09-17 | both λ estimates documented, full panel justified for projection — `MODEL.md` §4.3.1; log line fixed in `runPSMCouplingBound.R` |
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
