# The coupled scenario set — what each run is for, and what the batch says

*A plain-language guide to the coupled REMIND runs: why each one exists, what it may and may
not be used to conclude, and where it belongs in the paper.*

**Status.** The `v5` batch is in and complete: **48 scenarios, 24 per resolution**, run
2026-09-16 on Run-Group **`v5`** (deployed spec `X-2079 WGIge|noRoL|VerAcc bothIncAP lev
ctl:GDPq.Pop.Hyd fe:OECDp`, panel `f8845f66fb39d316`), from the committed code — every run log
reads `group v5`, `tier year 2035`, `gapClosure 0` (or 1 in `GAPCLOSE`). Results are in
`output/remind-runs/v5/{EU21,H12}/`; the previous batch is in `../_archive/_wip/2026-10-01/gdx/v4/` and is not quoted. Central setting θ = 0.50,
`cm_pfmGapClosure = 0`; the `THETA` (0.325 / 0.675) and `GAPCLOSE` sensitivities are complete at
both resolutions.

**62 runs, over two submissions.** 2026-09-16 carried the original 48. 2026-09-17 added the 14
`FIXPRICE` runs (§4.2a), re-ran the two flagged H12 mode-R runs, and re-ran EU21 `-PFMlevelC` from
its own gdx for another 57 iterations. **Every run in the batch now finishes, converges and clears
its early markets** (§3).

**Every number below** is from `output/pfm/v5/coupling/coupled-runs.rds`
(`Rscript analysis/coupled/extractCoupledResults.R output/remind-runs/v5 v5`) and `output/pfm/v5/coupling/coupled-facts.json`
(`Rscript analysis/coupled/coupledBatchFacts.R v5 output/remind-runs/v5`). Re-read them from there.

> ⚠️ **The uncoupled baselines and the θ = 0 nulls are not spec-dependent**, and they reproduce
> across batches to the decimal (`-PFMgateB` 1710.3 Gt EU21). Everything with θ > 0 is new.

> ⚠️ **Every price in this document names its market.** With the markup on
> (`cm_pfmSectorMarkup = 1`) *both* markets carry one: ES (buildings and transport) faces
> `pm_taxCO2eq + pm_taxemiMkt("ES")`, ETS (electricity and industry) faces
> `pm_taxCO2eq + pm_taxemiMkt("ETS")`, and `pm_taxCO2eq` alone is the **floor** that neither
> market actually pays. In the `-Min` twins ETS ≡ ES by construction. `COUPLING.md` §11.6.

**The batch in five sentences.**

1. **Political feasibility adds 159 Gt CO₂ at EU21 and 164 Gt at H12** to the price path that holds
   the 1000 Gt budget (the quantity headline, §4.2a), **100–236 Gt** across the declared θ range, and
   **254–266 Gt** if the political gap is assumed to close. On the unforced anchor the same cap costs
   +128 / +149 Gt against a null that misses the budget — the SI sensitivity (§4.2).
2. **With the budget held, the carbon price splits within regions**: ES/ETS runs 0.66–1.37 (EU21)
   and 0.70–1.31 (H12), households paying *less* than industry in 15 of 21 and 9 of 12 regions — not
   one direction everywhere (§4.1).
3. **The budget holds** in every budget-forced run — all of mode R and all six rule-C runs (§3, §4.1,
   §4.3). The three runs that missed on 2026-09-16 were re-run and now converge.
4. **The feedback is visible**: φ moves by up to 0.08 across runs as the energy system changes, and
   the PFM loop contracts over 3–8 calls rather than settling in one (§3.2, limitation 5).
5. **On the price path that holds the budget, the ceiling adds about 160 Gt CO₂** (+159.3 EU21 /
   +163.8 H12, θ = 0.50; 100–236 Gt across the declared θ range) — the quantity headline (§4.2a).

Companion documents: `COUPLING.md` (how the interface works and how to run one), `MODEL.md`
(the mathematics), `PITFALLS.md` (what silently breaks).

---

## 1. The idea in one page, no equations

REMIND normally answers: *what is the cheapest way to hit a carbon budget?* Its answer is a
carbon price path. Left alone it will happily propose that Russia or Sub-Saharan Africa charge
several hundred dollars a tonne, because that is cost-efficient.

The PFM asks a different question: **could that country's politics actually deliver that
price?** It estimates, from institutions and who holds power, a ceiling on how stringent a
country can plausibly get. The coupling feeds that ceiling back into REMIND so the model has to
respect it while it optimises.

Three moving parts:

**The anchor.** A single global carbon price path REMIND builds. Everything regional is derived
from it.

**φ ("phi"), the feasibility share.** One number per region between 0 and 1. φ = 1 means
"politics is no obstacle here". φ = 0.6 means "this region can realistically deliver about 60% of
the *extra* effort the cost-optimal answer asks beyond current policy". φ comes out of the PFM,
is read at the tier year **2035** (`cm_startyear` 2030 + 5), and is recomputed *during* the REMIND
run, so it responds to the energy system REMIND is building.

**θ ("theta"), the severity dial.** How hard the political constraint is allowed to bite. θ = 0
switches the mechanism off entirely (every φ becomes 1). **θ = 0.50 is the central setting**, and
the `THETA` group runs **0.325** and **0.675**. These are declared, not anchored (`MODEL.md` §5.3).
**φ can never fall below 1 − θ**; the batch confirms the floor regions land on 1 − θ to four
decimals at every θ (§6.2).

**Three ways φ can bind** ("bind modes"), which make genuinely different claims:

| mode | what it does | the claim it supports | can the budget still be met? |
|---|---|---|---|
| **R** — ratio | each region pays a φ-scaled share of the anchor | politics changes **where** abatement happens | yes, always |
| **L** — level | each region's price is capped at current policy plus φ × the extra effort | politics caps **how much** a region can do | maybe not — *that is the finding* |
| **M** — mild progression | the price is *generated* by political momentum; no anchor, no budget | where does observed political momentum actually take us? | no budget involved |

---

### 1.1 Two political regimes, one carbon price

The PFM is **estimated separately for two sectors**, on one shared specification
(`CONTEXT.md`, `MODEL.md` §2.2):

| sector | what is in it | the politics |
|---|---|---|
| **Bulk** | electricity + industry | few, large, organised actors — utilities, heavy industry |
| **Diffuse** | buildings + transport | costs land on households, visibly and immediately |

Each gets its own frontier, its own donor-assignment bands, and its own estimated speed λ —
**Bulk 0.1094/yr, Diffuse 0.0769/yr** (`output/pfm/v5/temporal-validation.rds`). At the deployed
`cm_pfmGapClosure = 0` every run exports λ = 0 to modes R and L (verified in every log).

REMIND needs the two sector answers reconciled. Two delivery paths:

| `cm_pfmSectorMarkup` | delivery | rows |
|---|---|---|
| 0 | collapse to `min(φ_Bulk, φ_Diffuse)` — one price, the worse sector wins | the three `-Min` twins per resolution (§4.5) |
| 1 | floor + **symmetric** markup: `pm_taxCO2eq` = the worse sector, `pm_taxemiMkt(m)` = market *m*'s own increment over it | every other coupled row |

**Which sector binds** (§6.2a has the table):

| where | Diffuse binds | Bulk binds |
|---|---:|---:|
| estimation sample, country $E$, 2022 (`MODEL.md` §3.4.2) | 16 of 48 | **32 of 48** |
| coupled, **EU21 regions**, `-PFMlevelB` | **14 of 21** | 7 — CAZ, DEU, ENC, IND, REF, SSA, UKI |
| coupled, **H12 regions**, `-PFMlevelB` | **9 of 12** | 3 — CAZ, IND, REF |

Bulk is the more constrained sector in most *countries*; Diffuse binds in most *regions*. The
reversal happens after estimation — in the projection to 2035, the per-sector min–max
normalisation (φ ranks regions within a sector, so which sector binds depends on each sector's
cross-regional **spread**) and aggregation.

> ⚠️ **"The political limit on household-facing energy costs constrains the economy-wide carbon
> price" is right for two-thirds of EU21 regions and three-quarters of H12 regions, and wrong for
> the rest** — including Russia (REF), one of the two floor regions, which binds on Bulk. It is
> also a statement about the headline frontier: the offline rung propagation moves the attribution
> for about half the regions (`MODEL.md` §3.4.1). Write it per region, with that caveat.

### 1.2 The gap persists, and λ is a declared switch

**Decision (2026-09-11): the gap PERSISTS.** `cm_pfmGapClosure = 0` is the deployed setting, with
the frontier's estimated rates run as a **declared sensitivity** (`startgroup=GAPCLOSE`, four runs
per resolution). The reason is `claim ≤ evidence` (`MODEL.md` §4.3, `output/pfm/v5/lambda-explained/LAMBDA-EXPLAINED.html`):

- **neither two-sector rate beats persistence** as a forecast (skill −0.180 Bulk, −0.698 Diffuse);
- a **placebo battery** on panels built with *no adjustment by construction* returns λ̂ of
  **0.291 [0.181, 0.419]** (Bulk) and **0.104 [0.062, 0.209]** (Diffuse) — the published Bulk rate is
  below its null and the Diffuse rate inside it;
- λ = 0 is `exportFeasibilityRegiDiff()`'s documented default.

**One symbol called λ does three jobs, and the switch touches only two** (`test-exportFeasibilityBound.R`):

| mode | λ is… | at λ = 0 | switched? |
|---|---|---|---|
| **1** ratio | the gap-closure rate | ratio = φ for the whole horizon | **yes** |
| **2** level | the speed limit on approaching the φ-scaled target | the bound *is* the target from the first period; early bounds go **up** | **yes** |
| **3** mild progression | the **momentum rate** — the mechanism itself | the price would freeze at its seed | **no** |

**Measured on the batch — the switch points opposite ways in the two modes:**

| result | λ = 0 (deployed) | λ = estimated (`GAPCLOSE`) | what λ = 0 does |
|---|---:|---:|---|
| quantity headline, EU21 (§4.2a) | **+159.3 Gt** | +254.4 Gt | **−37%** — conservative |
| quantity headline, H12 | **+163.8 Gt** | +266.0 Gt | **−38%** — conservative |
| headline B, EU21 / H12 (§4.2, SI) | +128.4 / +148.8 Gt | +192.2 / +239.6 Gt | −33% / −38% — conservative |
| mode R regional spread, EU21 / H12 (§4.1) | **1.88× / 1.76×** | 1.10× / 1.09× | **+71% / +62%** — generous |
| mode R markup written, EU21 / H12 | **0.722 / 0.617** | 0.108 / 0.089 | **~7×** — generous |
| mode R within-region ES/ETS, EU21 | **0.66–1.37** | 0.92–1.03 | a split vs almost none |

Methods must say: *we do not assume the gap closes; on the level-cap headline that is the cautious
choice and lowers the cost by about a third; on the price-distribution result it is the generous one
and it is what makes the split visible at all.*

✅ **Scoping control passes exactly.** `-PFMmildProgGapC` is identical to `-PFMmildProg` at both
resolutions (2583.3 / 2589.2 Gt): the switch does not reach mode 3.

**Two estimates, two jobs** (decided 2026-09-17, `MODEL.md` §4.3.1): the 2001–2015 validation estimate
above is what the `GAPCLOSE` rows apply; φ in every run is built on the same ECM re-estimated over
2001–2022 (0.1027 / 0.0621).

---

## 2. The scenario map

**The file is generated, not hand-written.** `scripts/start/buildPFMScenarioConfig.R` reads
REMIND's own `config/scenario_config.csv` and emits every row as *its canonical parent plus a
named delta*:

```bash
Rscript scripts/start/buildPFMScenarioConfig.R
Rscript scripts/start/validatePFMScenarioConfig.R config/scenario_config_PFM.csv
```

**24 scenarios per resolution, 48 in total**, identical in structure at H12 and EU21: two
uncoupled baselines, four nulls, four science runs, three markup-off twins, four NPi twins, a
four-run θ sweep and a four-run λ sensitivity. All rows carry `cm_startyear = 2030` and
`cm_taxCO2_lowerBound_path_gdx_ref = 0` (§6.3).

### 2.1 Uncoupled baselines

| run | why it exists |
|---|---|
| `SSP2[-EU21]-NPi2025` | current policies. The PFM's reference price path P_ref, the `path_gdx_ref` of every other row, and the uncoupled comparison for the NPi twins. **Must complete first.** |
| `SSP2[-EU21]-PkBudg1000` | REMIND's own 1000 Gt cost-optimal answer. |

### 2.2 Nulls — the mechanism installed but switched off

**A null is not one thing.** Using the wrong one silently changes the answer (§4.7).

| run | switched off how | answers "what happens if we add…" |
|---|---|---|
| `-PkBudg1000-PFMgateRef` | mechanism absent (`regiDiff = 0`, uniform price) | — the **interface** check, not a science control |
| `-PkBudg1000-PFMgate` | present, θ = 0, budget enforced | …φ, under a held budget |
| `-PkBudg1000-PFMgateB` | present, θ = 0, budget forcing off, mode R | …the cap, on the **unforced** anchor (SI sensitivity) |
| `-PkBudg1000-PFMgateBfix` | present, θ = 0, budget forcing off, **anchor pinned to the `-PFMgate` path** | …the political **cap** — the control for the quantity headline; must reproduce `-PFMgate` |
| `-NPi2025-PFMgate` | present, θ = 0, current policies | …φ, to a **non-ambitious** price path |

> ⚠️ **A bind mode 2 run at θ = 0 is not an uncoupled null** when gap closure is on, because the
> speed limit can still bind — which is why `-PFMgateB` is bind mode 1.

### 2.3 The science runs — 1000 Gt budget, θ = 0.50

| run | mode | budget forcing | the sentence it produces |
|---|---|---|---|
| `-PkBudg1000-PFMratio` | R | on | "politics moves carbon price between regions and markets, and the budget holds" |
| `-PkBudg1000-PFMlevelBfix` | L, rule B | **off, anchor pinned** | **quantity headline:** "political feasibility adds X Gt CO₂ to the 1000 Gt pathway" |
| `-PkBudg1000-PFMratioBfix` | R | **off, anchor pinned** | bridge: the price headline's conversion with the anchor not raised |
| `-PkBudg1000-PFMlevelB` | L, rule B | **off** | SI: the cap against the unforced \$75 → \$104 path |
| `-PkBudg1000-PFMlevelC` | L, rule C | on | "the budget can / cannot be held under the cap" |
| `-PkBudg1000-PFMmildProg` | M | n/a | "observed political momentum alone gets us to X Gt" |

### 2.4 The sensitivities and twins

| group | rows | varies |
|---|---|---|
| **`-Min` twins** | `-PFMratioMin`, `-PFMlevelBMin`, `-PFMlevelCMin` | `cm_pfmSectorMarkup = 0` — one price per region |
| **`<res>THETA`** | `-PFMratioTh325/Th675`, `-PFMlevelBTh325/Th675` | θ = 0.325 / 0.675 |
| **`<res>GAPCLOSE`** | `-PFMratioGapC`, `-PFMlevelBGapC`, `-PFMlevelCGapC`, `-PFMmildProgGapC` | `cm_pfmGapClosure = 1` |
| **NPi twins** | `-NPi2025-PFM{ratio,level,mildProg}`, null `-NPi2025-PFMgate` | the current-policies parent |
| **`FIXPRICE`** | `-PFM{gateBfix, levelBfix, ratioBfix, levelBfixTh325, levelBfixTh675, levelBfixGapC, levelBfixMin}` | anchor **read** from the budget-held `-PFMgate` gdx (`cm_pfmAnchorFromGdx = on`, `path_gdx_carbonprice`; `COUPLING.md` §11.7), `cm_iterative_target_adj = 0` |
| **`<res>RULEC`** | `-PFMlevelCTh325`, `-PFMlevelCTh675` | θ = 0.325 / 0.675 on rule C — the one claim still measured at a single severity (`TODO.md` item 41, claim C34). **Not yet run** |


**Retired groups (2026-10-01).**
- `<res>RERUN`: the re-runs of 2026-09-17 are done, so the tags were removed from the config.
- `ITERTEST`: the row is gone, and so is the `cm_iteration_max` column. A run that does not
  converge is not given a higher iteration cap. Either remove the source of non-convergence, or
  start a new run from its gdx (`path_gdx`). The precedent is EU21 `-PFMlevelC`, which was
  restarted from its own gdx (`TODO.md` 17). See `PITFALLS.md` §25b.

### 2.5 Running them

```bash
Rscript start.R config/scenario_config_PFM.csv startgroup=EU21     # EU21 (no row carries the default tag "1": a bare start.R runs nothing)
Rscript start.R config/scenario_config_PFM.csv startgroup=H12      # H12
Rscript start.R config/scenario_config_PFM.csv startgroup=AMT      # both resolutions, plain rows
# EVERY sensitivity group is resolution-scoped: run it from that resolution's checkout
Rscript start.R config/scenario_config_PFM.csv startgroup=H12THETA     # θ sensitivity, 4 runs
Rscript start.R config/scenario_config_PFM.csv startgroup=H12GAPCLOSE  # λ sensitivity, 4 runs
Rscript start.R config/scenario_config_PFM.csv startgroup=H12FIXPRICE  # quantity headline, 7 runs
Rscript start.R config/scenario_config_PFM.csv startgroup=H12RULEC     # rule C at θ 0.325/0.675, 2 runs
Rscript start.R config/scenario_config_PFM.csv startgroup=H12RULECFIX  # the 5 rule-C rows with the cap rebuilt every iteration
Rscript start.R config/scenario_config_PFM.csv startgroup=H12GROUPVARIANTS  # held price on 6 variant Run-Groups (spec, income, USA, assignment)
Rscript start.R config/scenario_config_PFM.csv startgroup=H12GP24      # ordering tests: Bfix uniform/permuted1-3, C uniform/permuted1 (6)
Rscript start.R config/scenario_config_PFM.csv startgroup=H12GP23      # rule C under all-median / all-low / China seed (3)
#   ... and the same groups with the EU21 prefix from the EU21 checkout. Every group has the same
#   number of rows at both resolutions. Rows are ordered in the file by mode and rule, with
#   sub-sections (unforcedAnchor, heldPrice, heldPrice_groupVariants, heldPrice_orderingTests,
#   heldBudget, heldBudget_orderingTests, heldBudget_assignmentTests).
```

> 🔴 **Group tags are resolution-scoped and carry NO whitespace.** `start.R` matches a tag with
> `grepl("(^|,)TAG($|,)")`, so `RULECH12, H12` makes `" H12"` a tag that `startgroup=H12` will never
> select — silently, with a short run list. `analysis/run-groups/validatePFMScenarioConfig.R` now checks this,
> and that titles use only letters, digits, `_` and `-` (REMIND's reader aborts the whole file on a
> section separator typed with a space).

> ⚠️ **Submit one `startgroup` at a time.** `start.R` turns a refused `sbatch` into a `stop()` that
> kills the whole loop rather than skipping a row. `PITFALLS.md` §24.

### 2.5a How an unfinished run earns its place

🔴 **An unfinished run's `fulldata.gdx` is complete and reports success** (`PITFALLS.md` §25).
`analysis/coupled/extractCoupledResults.R` admits an unfinished run only if **zero market-year cells
through 2060 exceed REMIND's own `p80_surplusMaxTolerance`**, and records the reason in
`$admittedUnfinished` (including `nolog` for a run copied without its `log.txt`). **In the `v5`
batch every run finished and none needed admitting.**

---

## 3. Did the runs work?

| check | `v5` batch (62 runs) |
|---|---|
| solve status | `o_modelstat = 2` in **62 of 62** |
| finished | **62 of 62** (`REMIND run finished` in every log); none admitted unfinished |
| early-period markets (≤ 2060) | **zero cells over tolerance anywhere**; worst 1.00× in H12 `-PFMratioBfix` |
| PFM converged | final δ **3.1×10⁻⁵ to 1.96×10⁻³**, all below 0.002, against `cm_pfmConvTol = 0.002` |
| PFM calls | **3 to 8** per coupled run |
| iteration cap | **no run ends at `cm_iteration_max`** |
| budget converged (adj = 9) | **held in every budget-forced run**; no `pm_pfmBudgetWarn`, and no run whose cumulative CO₂ is still rising at 2150 |
| infeasibility code | `pm_pfmInfesCode = 0` in every coupled run |
| markup written = seen | **equal everywhere** |
| legislated floor | `cm_taxCO2_lowerBound_path_gdx_ref = 0` in all 62 |

> ✅ **The three defects the 2026-09-16 batch carried are gone**, each fixed by a re-run rather than
> by a change of method (`TODO.md` items 30, 31, 17):
>
> - **H12 `-PFMratioMin`** now peaks at **1003.0 Gt in 2090** in 73 iterations (it previously never
>   peaked, reaching 1068 Gt at 2150). The H12 markup-off column in §4.5 is usable.
> - **H12 `-PFMratioTh325`** now has markup written = seen (**0.340**) in 94 iterations; the only
>   mismatch in the batch is resolved.
> - **EU21 `-PFMlevelC`**, restarted from its own gdx for 57 more iterations, now **holds the
>   budget** (peak 1000.4 Gt in 2090, `pm_pfmBudgetWarn = 0`, δ = 0.0014) with a bind share of
>   0.585 rather than 1.000 (§4.3). Its early markets are the cleanest in the batch (0.14×
>   tolerance); three `pebiolc` cells sit at 1.06× tolerance **after 2100**, outside the reporting
>   horizon.

### 3.1 The interface gate — a tolerance, not bit-identity

`-PFMgate` (θ = 0, mechanism present) against `-PFMgateRef` (mechanism absent):

| resolution | `pm_taxCO2eq` cells | differing | max difference | mean difference | cum. CO₂ 2100 | Nash iterations |
|---|---:|---:|---:|---:|---|---|
| EU21 | 358 | **294** | **\$0.71** | \$0.36 | 991.61 vs 991.77 Gt | 31 vs 27 |
| H12 | 196 | **168** | **\$0.89** | \$0.47 | 989.11 vs 989.21 Gt | 50 vs 37 |

φ is exactly 1 and `p45_pfmPhiMktSpread` exactly 0 in both gates, so it is not the political layer;
the two runs' budget loops stop at different iterations. The same cell counts have differed in
every batch; the size stays below \$1 and cumulative CO₂ agrees to 0.2 Gt. **Do not write
"bit-identical".** `TODO.md` item 19.

**`v6` (REMIND 3.7.1):** EU21 reproduces exactly (0 of 231 cells). H12 does not stay inside the
tolerance: all 132 cells differ, by at most \$1.57 (0.13% in 2030 rising to 0.32% in 2090), and
cumulative CO₂ is 1000.07 vs 1000.81 Gt. The difference is identical across all 12 regions in every
year, so it is a uniformly lower global path from the budget loop stopping elsewhere, not the
coupling. Both runs are inside REMIND's 2 Gt budget tolerance. Waived and disclosed, 0005 Phase 3,
"H12 gate check".

> ⚠️ The gate is **structurally blind** to defects that only exist at θ > 0. It proves the
> plumbing, nothing else; §3.3 is the real test.

### 3.2 Convergence — the loop contracts over several calls

At θ > 0 the PFM is called **3 to 8 times** per run. Of 36 runs with a δ sequence, **30 contract
strictly** (e.g. EU21 `-PFMratio`: 0.0094 → 0.0027 → 0.00036); the six rule-C runs oscillate before
settling below 0.002. Every final δ is below 0.002. This is a real fixed-point iteration, not a
single-comparison assertion — the energy system moves φ and φ moves back (limitation 5).

### 3.3 φ and the markup both reach the solver

- `p45_pfmPhiMktSpread` is **1.3–2.9** (EU21) and **0.9–2.0** (H12) in markup-on θ > 0 runs, and
  exactly **0** in every `-Min` twin and every gate.
- `p45_pfmMarkupWritten` equals `p45_pfmMarkupSeen` in **every** run of the batch.
- Every log reports `lambda per sector exported: Bulk 0.0000 | Diffuse 0.0000` at
  `cm_pfmGapClosure = 0`.

---

## 4. What the results say

Cumulative figures are `pm_actualbudgetco2("2100")` in Gt CO₂ unless marked **peak** (the
PkBudg budget is a peak budget); prices are 2050, \$2005/tCO₂, and name their market.

### 4.1 Mode R — politics redistributes, the budget survives, and the split runs both ways

| run | peak CO₂ EU21 / H12 | anchor 2050 EU21 / H12 | anchor vs θ = 0 | regional spread EU21 / H12 | within-region ES/ETS EU21 / H12 |
|---|---|---|---:|---|---|
| `-PFMgate` (θ = 0) | 999.1 / 998.4 | 253.7 / 248.3 | 1.00 | 1.00 | 1.000 |
| `-PFMratioTh325` | 999.6 / 997.7 ⚠️ | 299.0 / 295.2 | 1.18 / 1.19 | 1.43 / 1.37 | 0.81–1.19 / 0.83–1.17 |
| **`-PFMratio`** (θ = 0.50) | **1001.5 / 998.9** | 336.2 / 334.6 | **1.33 / 1.35** | **1.88 / 1.76** | **0.66–1.37 / 0.70–1.31** |
| `-PFMratioTh675` | 999.8 / 1000.3 | 393.0 / 393.6 | 1.55 / 1.59 | 2.82 / 2.59 | 0.48–1.73 / 0.52–1.55 |
| `-PFMratioGapC` | 1001.8 / 1000.9 | 265.0 / 260.5 | 1.05 / 1.05 | 1.10 / 1.09 | 0.92–1.03 / 0.93–1.02 |
| `-PFMratioMin` | 1003.7 / 1003.0 | 364.8 / 369.2 | 1.44 / 1.49 | 1.88 / 1.76 | 1.000 — one price |

**The budget holds** at every θ and both λ settings, at both resolutions (peak 998.4–1003.7).
Politics redistributes the burden; it does not break the budget.

**The anchor rises to pay for it** — by a third at θ = 0.50. The constrained regions' discount has
to be made up somewhere, and REMIND raises the anchor that every region's share multiplies. The
most constrained regions pay about **two-thirds** of the θ = 0 price (0.66 EU21 / 0.67 H12), the
least constrained pay **1.33–1.35×** it.

**The regional spread is φ_max / φ_min**, which at λ = 0 is at most 1/(1 − θ): 1.88 at EU21 because
the least constrained region sits at φ ≈ 0.94, not 1.

**The sector split within a region is wide and runs both ways.** At θ = 0.50:

| | ES below ETS | ES above ETS | median ES/ETS | largest splits |
|---|---:|---:|---:|---|
| EU21 `-PFMratio` | **15 of 21** | 6 | 0.965 | ECS 0.66 (ES \$168 vs ETS \$255); REF 1.37 (ES \$230 vs ETS \$168) |
| H12 `-PFMratio` | **9 of 12** | 3 | 0.923 | LAM 0.70; REF 1.31 |

Households pay less than industry in most regions, and **more in Russia, India, Canada/Australia/NZ**
and, at EU21, Germany, the UK and North-Central Europe. The finding is the **width and
region-specificity**, not a direction.

### 4.2 Mode L rule B on the unforced anchor — an SI sensitivity, not the headline

> ✅ **Decided 2026-09-17, measured 2026-09-18 (`TODO.md` 14g):** the quantity headline is
> `-PFMlevelBfix` against `-PFMgateBfix` on the pinned budget path (**§4.2a**). Everything in this
> section is the unforced-anchor family and belongs in the SI (claim C19).

`-PFMlevelB` against its matched null `-PFMgateB` (both budget forcing **off**):

| resolution | `-PFMgateB` | `-PFMlevelB` | **Δ cumulative CO₂ 2100** | market price 2050, low → high | bind share |
|---|---:|---:|---:|---|---:|
| EU21 | 1710.3 | 1838.7 | **+128.4 Gt** | \$45.2 → \$86.4 | 0.571 |
| H12 | 1384.8 | 1533.6 | **+148.8 Gt** | \$71.5 → \$139.0 | 0.958 |

**Political feasibility costs roughly 130–150 Gt CO₂ over the century — relative to an unforced
price path.** The two resolutions differ by 15% of their mean — agreement in size, not a replication.

> 🔴 **Read this before quoting headline B.** With budget forcing off, REMIND never raises the anchor.
> The null `-PFMgateB` therefore runs a **uniform \$75 (2030) → \$86 (2050) → \$104 (2100)** and emits
> **1710 Gt** by 2100 (peak 2319 Gt) — it is not the 1000 Gt pathway, which needs \$254 by 2050
> (`-PFMgate`). Headline B is the extra CO₂ when the political cap binds *below that low path*. The
> EU/UK regions already sit below their \$199 current-policy price in the null. `TODO.md` item 14g.

| | EU21 | H12 | what it says |
|---|---:|---:|---|
| θ = 0.325 | +73.9 | +76.9 | the mild end |
| **θ = 0.50 (deployed)** | **+128.4** | **+148.8** | the headline |
| θ = 0.675 | +204.1 | +217.5 | the harsh end |
| slope | **296 Gt / unit θ** | **322 Gt / unit θ** | close to linear through θ = 0 |
| gap closes (`GAPCLOSE`) | +192.2 | +239.6 | λ = 0 is the conservative choice (§1.2) |
| markup off (`-Min`) | +156.0 | +189.9 | §4.5 |

**This is the SI sensitivity, not the headline.** If it is quoted at all: 128 Gt (EU21) / 149 Gt
(H12) at θ = 0.50, with the 74–218 Gt θ range and 192–240 Gt under gap closure — always with the fact
that its null emits 1710 / 1385 Gt. The headline is §4.2a.

> ⚠️ **This is a world without the legislated EU price floor** (§6.3): EU/UK regions pay \$86.4 in
> 2050 against a current-policy reference of \$199.47 — **in the null as well as under the cap**.

### 4.2a The quantity headline — the cap on the price path that holds the budget

The `FIXPRICE` family (§2.4). Both runs read the anchor `-PFMgate` converged to
(`cm_pfmAnchorFromGdx = on`) and switch budget forcing off, so the **null meets the budget** and the
gap is the extra CO₂ the ceiling adds to the 1000 Gt pathway.

**The pinning gate first.** `-PFMgateBfix` must reproduce `-PFMgate`, and it does:

| | EU21 | H12 |
|---|---:|---:|
| anchor 2050, `-PFMgate` / `-PFMgateBfix` | \$254.42 / \$254.42 | \$248.98 / \$248.98 |
| cumulative CO₂ 2100 | 991.6 → **993.7** | 989.1 → **992.6** |
| peak cumulative CO₂ | 999.1 → **1001.4** | 998.4 → **1001.1** |

The residual (**+2.1 Gt, 0.21%** EU21; **+3.5 Gt, 0.35%** H12) is what dropping budget forcing costs
on an anchor that is no longer rescaled — not a coupling effect. **If a future re-run moves this by
more than a few Gt, the pinning failed and nothing below is interpretable.**

| | EU21 | H12 | |
|---|---:|---:|---|
| `-PFMgateBfix` (θ = 0 null) | 993.7 | 992.6 | meets the budget |
| **`-PFMlevelBfix`** (θ = 0.50) | **1153.0** | **1156.4** | **+159.3 / +163.8 Gt** |
| θ = 0.325 | 1093.7 | 1092.9 | +100.0 / +100.3 |
| θ = 0.675 | 1217.8 | 1228.2 | +224.1 / +235.6 |
| slope | | | **330 / 346 Gt per unit θ** |
| gap closes (`GapC`) | 1248.1 | 1258.6 | +254.4 / +266.0 |
| markup off (`Min`) | 1199.2 | 1215.0 | +205.5 / +222.4 |
| mode-R twin (`-PFMratioBfix`) | 1163.3 | 1168.3 | +169.6 / +175.7 |

**Political feasibility adds about 160 Gt CO₂ to the 1000 Gt pathway** at the central severity,
100–236 Gt across the declared θ range. The two resolutions differ by **2.8% of their mean** — far
closer than the unforced family's 15%, because both are now measured against a null that meets the
same budget.

- **The conversion is not the story.** The mode-R twin, which scales each region's price by φ
  instead of capping its increment, costs **+10.3 / +11.9 Gt more** — 6–7% of the headline. The two
  headlines therefore differ because of the closure (hold the budget or hold the price), not because
  of the mechanism (§8).
- **Sectoral differentiation buys back 46.2 Gt (22.5%) at EU21 and 58.6 Gt (26.4%) at H12** — more
  than in the unforced family (§4.5).
- **λ = 0 is the conservative setting here**: assuming the gap closes raises the cost to +254 / +266.
- **The cap binds almost everywhere**: bind share 0.912 (EU21) and 0.982 (H12), against 0.571 / 0.958
  in the unforced family.
- **Emissions do not peak inside the horizon** in any capped run (cumulative still rising at 2150),
  which is what "the budget is not enforced" means. Quote the 2100 cumulative, never a peak, for
  this family.

### 4.3 Mode L rule C — the budget can be held under the cap

| run | EU21: iterations, peak CO₂, bind share | H12: iterations, peak CO₂, bind share |
|---|---|---|
| `-PFMlevelC` (deployed) | **57 (restarted), 1000.4, 0.585** — `pm_pfmBudgetWarn = 0` | 57, 998.8, 0.738 |
| `-PFMlevelCMin` (markup off) | 88, 1003.0, 0.211 | 71, 998.3, 0.399 |
| `-PFMlevelCGapC` (gap closes) | 42, 998.6, 1.000 | 43, 1001.8, 1.000 |

**All six rule-C runs hold the budget.** The EU21 deployed run previously ended 15 Gt over at the
100-iteration cap with the cap binding in every region-period; restarted from its own gdx for 57
more iterations it converges to **1000.4 Gt with a bind share of 0.585** (`TODO.md` item 17). The
earlier reading — that a fully binding cap leaves the anchor no instrument — described a run that had
not finished converging, not a property of rule C. **Do not quote the 1015.4 Gt figure.**

**Reading.** Rule C is **not** "the budget cannot be held". It is "the budget can be held under the
political cap in most configurations, and at EU21 the deployed setting sits at the edge". The PFM loop
converged in all six (final δ ≤ 0.002); the budget loop is what capped in the one miss. Do not tune
`cm_pfmConvTol` for it. `TODO.md` item 17.

> ⚠️ Cumulative CO₂ **at 2100** is below 1000 in the gap-closure runs (954 / 963) because emissions
> overshoot the peak and then go net-negative; the peak is the budget quantity.

### 4.4 Mode M does not corroborate mode L

| | EU21 | H12 |
|---|---:|---:|
| `-PFMmildProg` cumulative 2100 | 2583.3 | 2589.2 |
| vs `-PFMgateB` | **+873.0 Gt** | **+1204.4 Gt** |
| vs `-PFMlevelB` | +744.7 (41% of the level-B pathway) | +1055.6 (69%) |

Observed political momentum alone takes the world far past a 1000 Gt budget — six to eight times the
level-cap cost. Modes L and M answer different questions and must not be presented as agreeing.

### 4.5 The markup-off counterfactual

| | EU21 | H12 |
|---|---:|---:|
| headline B with markup (`-PFMlevelB`) | +128.4 | +148.8 |
| headline B without (`-PFMlevelBMin`) | +156.0 | +189.9 |
| **bought back by pricing two markets separately** | **27.6 Gt = 17.7%** | **41.1 Gt = 21.6%** |
| **quantity headline with markup (`-PFMlevelBfix`)** | **+159.3** | **+163.8** |
| **quantity headline without (`-PFMlevelBfixMin`)** | **+205.5** | **+222.4** |
| **bought back, pinned path** | **46.2 Gt = 22.5%** | **58.6 Gt = 26.4%** |
| mode R anchor 2050, markup on / off (vs θ = 0) | 1.33× / 1.44× | 1.35× / 1.49× |
| most expensive market 2050, markup on / off (vs θ = 0 anchor) | 1.33× / 1.35× | 1.35× / 1.32× |

**Sectoral differentiation buys back about a fifth of the carbon cost of political feasibility**
(18–22%). The markup also lowers the anchor rise the constraint needs (1.33× against 1.44× at
EU21) — but **does not remove it**: with or without two prices, REMIND pays for the constrained
regions' discount by raising what the unconstrained ones pay to about a third above cost-optimal.
`p45_pfmPhiMktSpread` and `p45_pfmMarkupWritten` are exactly 0 in every `-Min` twin. On the pinned
path the buy-back is larger (22–26%) because the cap binds in almost every region-period there.

### 4.6 The θ sweep

**The quantity headline (mode L, pinned path, §4.2a):** +100.0 / +159.3 / +224.1 Gt at EU21 and
+100.3 / +163.8 / +235.6 at H12 for θ = 0.325 / 0.50 / 0.675 — **330 and 346 Gt per unit θ**, close
to linear.

**Headline B (mode L, unforced anchor, SI):** +73.9 / +128.4 / +204.1 Gt at EU21 and +76.9 / +148.8 /
+217.5 at H12 — **296 and 322 Gt per unit θ**.

**Mode R:** the regional spread goes 1.43 → 1.88 → 2.82 (EU21) and the within-region ES/ETS range
widens from 0.81–1.19 to 0.48–1.73. The budget holds at every θ. Floor regions land on exactly
1 − θ in every run (§6.2).

The sweep is symmetric about 0.50 and declared; none of its points is an estimate or an anchor.

### 4.7 The NPi twins — direction on a non-ambitious pathway

Each mechanism on the current-policies pathway, against the correct θ = 0 null `-NPi2025-PFMgate`:

| | EU21 | H12 |
|---|---:|---:|
| mode R (`-NPi2025-PFMratio`) | **+156.2 Gt** | **+185.6 Gt** |
| mode L (`-NPi2025-PFMlevel`) | **+131.0 Gt** | **+157.8 Gt** |
| mode M (`-NPi2025-PFMmildProg`) | +852.6 Gt | +1101.4 Gt |
| **the confound**: `cm_taxCO2_regiDiff` 6 → 11 alone (`-NPi2025-PFMgate` vs `SSP2[-EU21]-NPi2025`) | **−904.7 Gt** | **−1163.8 Gt** |

**All three mechanisms raise emissions at both resolutions** against the correct null. Against the
uncoupled baseline they would appear to *lower* them, because switching the mechanism on also
switches a REMIND regional-differentiation setting whose effect alone is **six to seven times** the
political one, of the opposite sign.

**The mode-L twin corroborates headline B on a completely different parent pathway**: +131.0 against
+128.4 at EU21 (2%), +157.8 against +148.8 at H12 (6%). Nothing in the NPi family may be quoted
against the uncoupled `SSP2[-EU21]-NPi2025`.

---

### 4.8 Where abatement goes, and what it costs in GDP

`analysis/coupled/coupledCostsAndAbatement.R v5 output/remind-runs/v5` → `coupled-costs.json`. Regional `vm_co2eq`, `vm_cesIO`
("inco") and `vm_cons` integrated over 2020–2100, each run against its matched θ = 0 null; the
monetary series are discounted at 5%/yr. **Relocated** is half the sum of the absolute regional
changes — the volume that moved, not the net.

| | net Δ CO₂eq | relocated | ρ(φ, relative change) | GDP |
|---|---:|---:|---:|---:|
| **mode R** (budget held) EU21 / H12 | **+3.2 / +4.3** | **72.2 / 81.4** | **−0.76 / −0.61** | +0.041% / +0.033% |
| mode R, gap closes | +6.6 / +9.9 | 6.0 / 7.1 | −0.68 / −0.86 | +0.032% / +0.029% |
| **quantity headline** (`-PFMlevelBfix`) | +167.9 / +173.6 | 114.3 / 115.1 | −0.45 / −0.67 | +0.211% / +0.218% |
| its null against `-PFMgate` (the pin) | **+2.1 / +3.5** | 1.1 / 1.7 | — | **+0.002% / +0.005%** |
| mode M | +955.2 / +1312.7 | 478.4 / 656.4 | +0.10 / −0.26 | +0.473% / +0.714% |

**Under a held budget the ceiling moves abatement rather than reducing it**: the net change is a few
Gt while 72–81 Gt of abatement changes region. That is mode R's central claim, and until this artifact
nothing tested it. The negative rank correlation says the direction is the one the mechanism asserts —
**the more constrained a region, the more it emits relative to its own baseline**. With gap closure on,
the relocation nearly vanishes (6–7 Gt): it exists because the gap persists, exactly as the price split
does (§1.2).

**Where the extra emissions land under the cap** (EU21, `-PFMlevelBfix`): MEA **+60.8**, SSA **+56.7**,
REF **+27.7**, USA **+19.2 Gt**; the one large decrease is CHA **−28.9 Gt**, a general-equilibrium
response rather than a political one.

> 🔴 **GDP rises, and that is not a benefit.** REMIND carries no climate damages, so any run that
> abates less looks richer (+0.21% GDP, +0.26% consumption under the cap). Quote it only in the same
> sentence as the extra CO₂, or not at all. Regional GDP is not reported: the aggregation is not
> reliable at region level.

> ✅ **An independent check on the pinning.** `-PFMgateBfix` against `-PFMgate` moves 2.1 / 3.5 GtCO₂eq
> and 0.002 / 0.005% of GDP — the pinned null is the budget-forced run in every respect that matters
> (§4.2a).

---

## 5. Limitations — read this before quoting anything

1. **λ is a declared choice, and its direction differs by result** (§1.2): λ = 0 lowers headline B by
   a third and is what makes the mode-R price split visible. State the direction per result.
2. **Two results rest on runs that needed a second submission to converge** (§3): H12
   `-PFMratioMin` and `-PFMratioTh325`, and EU21 `-PFMlevelC`, which converged only when restarted
   for another 57 iterations. Nothing in the batch is at the iteration cap now, but a result whose
   run needed 150+ iterations is a result to re-check when anything upstream changes.
3. **Two regions per resolution are pinned by the parameter, not by data.** φ = 1 − θ exactly for
   **ECS (Central Europe) and REF (Russia & Central Asia)** at EU21 and **LAM and REF** at H12, in
   every run at every θ. φ is a *ranking*; both endpoints of the scale are guaranteed by construction
   (§6.2). Note these are not the offline bound's pair (CHA, REF at 2025): the coupled φ is read at
   2035 on the live energy system.
4. **Legislated prices may be rolled back in every run** (§6.3). In the budget-unforced θ > 0 runs,
   **689 of 1540** EU21 region-years from 2030–2100 have both market prices below the current-policy
   reference; in budget-forced runs 174 of 1760.
5. **The co-evolution feedback is visible, and moderate.** Across the eleven θ = 0.50 PkBudg runs φ
   moves by up to **0.077** per region (India, EU21) — median 0.009 at EU21, 0.046 at H12 — and
   between the 1000 Gt and current-policy families by up to 0.03. The loop contracts over 3–8 PFM
   calls (§3.2). This is a real response of feasibility to the energy system, not a rounding error.
   It is **not causal** (`MODEL.md` §8.1): call it conditional scenario accounting.
6. **The United States has no covered country.** Its coupled φ (0.649 EU21 / 0.567 H12 in
   `-PFMlevelB`) is set by the median-basis override and must be reported as a range
   (`TODO.md` item 6).
7. **θ has no admissible interval under the raw level cap** (`MODEL.md` §5.3.1). Mode L is usable
   because it caps the increment over current policy, and because the legislated floor is off.
8. **The interface gate is verified to a tolerance** (§3.1).
9. **Every φ is conditional on modelling choices the data do not settle** — nine sources, listed with
   their size in `MODEL.md` §5.3.2. θ carries the band in the main text; the frontier error structure
   (median |Δφ| up to 0.171 offline), the specification (median |Δφ| ~0 but max 0.271 and the floor
   region moves, claim C31, `v5` vs `v5-specalt`) and the rest are reported in the SI. No φ here is a measured property of a region.
10. **Which sector binds depends on the frontier rung** offline, and the coupled attribution has not
    been re-run across rungs (§6.2a).

---

## 6. Diagnosis: mechanisms that shape every result

### 6.1 The reference path is the hidden driver

Everything the coupling does is measured against `SSP2[-EU21]-NPi2025`, and modes R and L act on the
*increment* over its price. Its 2050 carbon price:

| region | NPi 2050 price |
|---|---:|
| the 9 EU/UK regions (EU21) / EUR (H12) | **\$199.47** |
| Canada/Australia/NZ | \$29.74 |
| Latin America | \$22.36 |
| Japan | \$18.91 |
| Non-EU Nordic (EU21 NEN) / Non-EU Europe (H12 NEU) | \$16.43 / \$14.10 |
| Non-EU S. Europe (EU21 NES) | \$13.73 |
| China | \$11.17 |
| Other Asia | \$11.15 |
| India | \$4.35 |
| Russia & Central Asia | \$4.04 |
| Middle East & N. Africa | \$3.84 |
| Sub-Saharan Africa | \$1.34 |
| **United States** | **absent** |

Two orders of magnitude, and the US is not in the reference file at all. Regions with near-zero
reference prices have almost all of their cost-optimal price exposed to φ.

### 6.2 Why φ = 1 − θ for some regions — it is a *ranking*, not a capability

`models/pfm/R/aggregateFeasibilityToRegions.R` computes

```
phi = 1 - theta * u        u = (gap - gap_min) / (gap_max - gap_min)
```

`u` is the region's **position between the best and worst region in the sample**. The largest gap
is handed `u = 1` → φ = 1 − θ; the smallest `u = 0`. **Both endpoints are guaranteed by
construction.** φ = 0.50 at θ = 0.50 means "ranked last" and carries no information about how far
last place is from the rest.

In the batch (`-PFMlevelB`, θ = 0.50): **EU21** floor **ECS, REF**, top **NEN 0.938**, median 0.738;
**H12** floor **LAM, REF**, top **CAZ 0.877**, median 0.738. The floor pair is identical in every run
at every θ at each resolution. With the markup on, overall φ reaches 1 only if a region is best in
**both** sectors, and none is.

**For the paper.** Do not write "Russia can only sustain 50% of the cost-optimal price". Write "these
regions rank at the bottom of the feasibility distribution; how far below the rest is set by θ, a
parameter we declare."

### 6.2a Which sector binds, at region level

Measured on `-PFMlevelB` from `p45_pfmPhiMkt`, checked across all 11 markup-on θ = 0.50 runs:

| | Diffuse binds | Bulk binds | assignment stable across runs |
|---|---:|---:|---:|
| **EU21 regions** | **14 of 21 (67%)** | **7** — CAZ, DEU, ENC, IND, REF, SSA, UKI | 19 of 21 |
| **H12 regions** | **9 of 12 (75%)** | **3** — CAZ, IND, REF | 12 of 12 |

The clearest cases at EU21:

| region | ES (Diffuse) φ | ETS (Bulk) φ | binds |
|---|---:|---:|---|
| Russia & Central Asia (REF) | 0.670 | **0.500** | **Bulk**, by 0.170 |
| Central Europe (ECS) | **0.500** | 0.764 | **Diffuse**, by 0.264 |
| North-Central Europe (ENC) | 1.000 | **0.746** | **Bulk** (ES on the ceiling clamp) |
| China (CHA) | **0.785** | 1.000 | **Diffuse** (ETS on the ceiling clamp) |
| Non-EU S. Europe (NES) | **0.711** | 0.915 | **Diffuse** |

**The two floor regions bind in opposite sectors** at EU21: REF on Bulk, ECS on Diffuse. So "the
coupled result is a buildings-and-transport limit applied to the whole economy" is false for Russia.
A sector φ of exactly 1.000 is a ceiling clamp, not a measurement — do not report "China's electricity
and industry face no political constraint".

**Stability is not robustness.** The assignment is stable against the bind mode, not against the
specification or the frontier rung (limitation 10). Never quote a country-level figure for a coupled
regional result.

### 6.3 The legislated price floor is off in every run

`cm_taxCO2_lowerBound_path_gdx_ref` defaults to **on**, and
`45_carbonprice/functionalForm/postsolve.gms` applies

```gams
pm_taxCO2eq(t,regi) = max(pm_taxCO2eq(t,regi), p45_taxCO2eq_path_gdx_ref(t,regi));
```

inside the `cm_iterative_target_adj eq 5/7/9` block. **It is 0 in all 62 runs**, so budget-forced and
unforced families are in the same policy world, and prices below the reference path are permitted
and occur (limitation 4). `extractCoupledResults()` reports zero floor violations because the check is
gated on the switch.

**It still has to be declared.** Of the two coherent options it is the *less* conservative: a
feasibility ceiling that cannot bind below currently legislated policy is legislation plus a ceiling,
but a model that lets the EU abolish its ETS is also a choice. **Methods must say which**, in one
sentence.

### 6.4 The mode L ratchet — fixed, confirmed absent

A past defect: mode L read `priceOptimal` from the run's own already-capped `pm_taxCO2eq`, making the
bound collapse onto the NPi reference within 3–4 calls. `models/pfm/R/iterativePFM.R` now takes it from
`p45_taxCO2eq_anchor`. **Confirmed absent on `v5`**: the lowest 2050 mode-L market price is \$45.2
(EU21) / \$71.5 (H12), well above the near-zero reference prices of the regions that pay it.

---

## 7. Needed improvements, in priority order

1. ✅ **H12 `-PFMratioMin` re-run** (2026-09-17): peaks at 1003.0 Gt in 2090, 73 iterations. C20 and
   §4.5 quote both resolutions again.
2. ✅ **H12 `-PFMratioTh325` re-run**: markup written = seen (0.340), 94 iterations.
3. 🟠 **Extend the budget warning to peak budgets** — `pm_pfmBudgetWarn` did not fire on the run
   whose peak cumulative CO₂ was 68 Gt over (that run has since been re-run, but the blind spot in
   the check is still there: `TODO.md` item 32, `PITFALLS.md` §26).
4. 🟠 **State λ's direction per result** in Methods (§1.2).
5. 🟠 **Restate the interface gate as a tolerance** (§3.1, `TODO.md` item 19).
6. 🟡 **Re-run the binding-sector attribution across frontier rungs** inside REMIND (limitation 10).
7. 🟡 **Regenerate or delete the seed `.inc`** (`TODO.md` item 20).
8. 🟡 **Give modes R and M a bind-share diagnostic** (`TODO.md` item 21).
9. ✅ **The specification band is measured** (2026-09-17, `v5-specalt`; `MODEL.md` §5.3.0). Quote its
   max and rank shift, not its median.

---

## 8. How to use these in the paper

| display | runs | numbers | must travel with it |
|---|---|---|---|
| **the cost of political feasibility** (Fig 5b, quantity headline) | `-PFMlevelBfix` vs `-PFMgateBfix`, both resolutions, with `Th325/Th675`, `GapC`, `Min`; `-PFMratioBfix` | **+159 / +164 Gt**; θ range 100–236; gap closes 254–266; conversion +10–12 | θ declared; λ direction; floor-off world; the null reproduces `-PFMgate` to 0.2–0.4% |
| SI: the cap on the unforced anchor | `-PFMgateB` vs `-PFMlevelB`; `THETA`, `GAPCLOSE` | +128 / +149 Gt; θ range 74–218; gap closes 192–240 | the null emits 1710 Gt, not 1000 |
| **where the abatement goes** (Fig 5d) | `-PFMratio` vs `-PFMgate` and `-PFMlevelBfix` vs `-PFMgateBfix`, per region (§4.8) | budget held: net +3 / +4 Gt against 72 / 81 Gt relocated, ρ(φ) −0.76 / −0.61; price held: 114 / 115 Gt relocated | emissions only — the GDP effect never travels without the CO₂ number (C37) |
| **politics splits the carbon price** (Fig 5a) | `-PFMratio`, EU21, 2050; `-PFMratioMin` | ES/ETS 0.66–1.37, 15 of 21 below | both directions; conditional on λ = 0; rung caveat |
| **the NPi twins** (Fig 5c) | NPi mechanism rows vs `-NPi2025-PFMgate` | +131 to +186 Gt (R, L); confound −905 / −1164 | the correct null; the confound drawn to scale |
| **the bound** (Fig 3) | none — `coupling-summary.rds` | PFM-side | not re-optimised |
| **Methods: which policy world** | config + every gdx | floor off in 48 of 48 | one sentence |
| **Discussion: the feedback** | all θ = 0.50 PkBudg rows | φ moves ≤ 0.08; 3–8 PFM calls | not causal |

**Do not use for:** any mode-R spread or sector split without stating it is conditional on λ = 0;
"rule C cannot hold the budget" (it holds in six of six); the retired figures from the pre-re-run
batch (H12 `-PFMratioMin` at 1068 Gt, EU21 `-PFMlevelC` at 1015.4 Gt); the unforced-anchor cost
(+128 / +149 Gt) as the headline — it is the SI sensitivity (§4.2, claim C19); any floor-region claim
without flagging that φ is ordinal; any country-level binding-sector figure as a statement about
regions; any price without naming its market; mode M as corroboration of mode L; "the constraint
lands on households" as a uniform statement.

---

## 9. How to re-derive every number here

```bash
Rscript analysis/coupled/extractCoupledResults.R output/remind-runs/v5 v5   # -> output/pfm/v5/coupling/coupled-runs.rds (≈5 min)
Rscript analysis/coupled/coupledBatchFacts.R v5 output/remind-runs/v5       # -> output/pfm/v5/coupling/coupled-facts.json
```

The extractor keeps the newest run per (resolution, scenario), checks `log.txt` for `REMIND run
finished`, and applies the early-market admission rule (§2.5a). Keep older batches out of the
`output/remind-runs/v5/EU21` and `output/remind-runs/v5/H12` folders (the previous batch is in `../_archive/_wip/2026-10-01/gdx/v4/`, which the extractor ignores
because it holds no `fulldata.gdx` of its own).

By hand, `gdxdump fulldata.gdx symb=<name> format=csv`:

| what | symbol |
|---|---|
| cumulative CO₂ | `pm_actualbudgetco2` — element `"2100"`. **It runs to 2150**; the peak is the budget quantity |
| the **floor** every market pays | `pm_taxCO2eq` — **multiply by 272 to get \$2005/tCO₂**. ⚠️ **This is not the ES price** |
| **ES** market price | `pm_taxCO2eq + pm_taxemiMkt(t,regi,"ES")` — dims are **(year, region, market)** |
| **ETS** market price | `pm_taxCO2eq + pm_taxemiMkt(t,regi,"ETS")` — same dims |
| the cost-optimal anchor | `p45_taxCO2eq_anchor(ttot)` — ×272 |
| φ per region / per market | `p45_regiDiff_phi` / `p45_pfmPhiMkt(regi, market)` |
| λ per market | `p45_pfmLambdaMkt(regi, market)` — and `cm_pfmGapClosure` |
| did φ reach the solver? | `p45_regiDiff_ratio`; `p45_pfmRatioSpread` |
| did the markup reach the solver? | `p45_pfmMarkupWritten` vs `p45_pfmMarkupSeen` |
| is the markup doing anything? | `p45_pfmMarkupShare_iter`, `p45_pfmPhiMktSpread` (0 = cannot differentiate) |
| φ convergence path | `p45_pfmDelta_iter` — **entries before the first PFM call are a 1e6 sentinel**; `p45_pfmCallCount` |
| how hard the cap bit | `p45_pfmBindShare_iter` — ⚠️ **written only under bind mode 2** |
| did Nash converge? | `cm_iteration_max` — the count actually used; 100 means it hit the cap |
| did the **budget** converge? | `p80_globalBudget_absDev_iter` at the last iteration, against `cm_budgetCO2_absDevTol`; `pm_pfmBudgetWarn`; `pm_pfmInfesCode = 4` only past 10× the tolerance |
| solve status | `o_modelstat` (2 = locally optimal) — **reads 2 on an unfinished run too** |
| did the markets clear? | `p80_surplusMax_iter` at the last iteration over `p80_surplusMaxTolerance`; split at 2060 |
| the legislated floor | `p45_taxCO2eq_path_gdx_ref`, `cm_taxCO2_lowerBound_path_gdx_ref` |
| the dial | `cm_pfmTheta`, `cm_pfmBindMode`, `cm_pfmSectorMarkup`, `cm_pfmGapClosure`, `cm_iterative_target_adj` |

`cm_iterative_target_adj` tells you which family a run belongs to: 9 = budget enforced by iteration,
0 = not. It must match before two runs are differenced.

> 🔴 **Before reading any symbol by hand, check the run finished.** `grep -q "REMIND run finished"
> <rundir>/log.txt`. `PITFALLS.md` §25.
