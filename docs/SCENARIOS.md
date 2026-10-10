# The coupled scenario set — what each run is for, and what the batch says

*A plain-language guide to the coupled REMIND runs: why each one exists, what it may and may
not be used to conclude, and where it belongs in the paper.*

**Status.** The **`v6` batch** is in and complete (2026-10-10): **64 runs** on REMIND 3.7.1 — 46 at
EU21 and 18 at H12, of which 54 are coupled (39 EU21, 15 H12) — on Run-Group **`v6`** (deployed spec
`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP`). Every row is generated from
`analysis/run-groups/scenario-matrix-v6.yml` (ADR 0055). One further EU21 run, `-PFMlevelC-Ehold-v6`
(start tag `V6CEHOLD`), was added on 2026-10-10 to separate two causes in §4.10; it is not in the
numbers below until it lands. The `v5` version of this document, with the `v5` batch's numbers, is
archived at `../_archive/_wip/2026-10-10/docs/SCENARIOS-v5.md`.

**Every number below** is read from `output/pfm/v6/coupling/`: `coupled-facts.json` (results per run
and arm), `coupled-costs.json` (emissions moved, GDP), `convergence-audit.rds`,
`rulec-relocation-decomp.rds` and `v5-v6-coupled-contrast.json`. `Rscript
analysis/coupled/runCoupledStage.R v6` rebuilds all of them (§9). Re-read them from there.

> ⚠️ **Every price in this document names its market.** With the markup on
> (`cm_pfmSectorMarkup = 1`) *both* markets carry one: ES (buildings and transport) faces
> `pm_taxCO2eq + pm_taxemiMkt("ES")`, ETS (electricity and industry) faces
> `pm_taxCO2eq + pm_taxemiMkt("ETS")`, and `pm_taxCO2eq` alone is the **floor** that neither
> market actually pays. In the `-Min` twins ETS ≡ ES by construction. `COUPLING.md` §11.6.

**The batch in five sentences.**

1. **Holding the price, political feasibility adds 118 Gt CO₂ by 2100 at EU21 and 113 Gt at H12**
   (θ = 0.50; 70–182 Gt across the declared θ range) — the quantity headline (§4.2a).
2. **The headline depends most on whether politics improves by itself**: a declared erosion of the
   political drag (κ = 0.027 a year) leaves 41 Gt of it; the assignment of countries without data is
   the widest data-side band, 110–155 Gt (§4.9).
3. **Holding the budget, every run meets it**, and the ceiling moves about 20 Gt CO₂eq of abatement
   between regions (22.7 EU21 / 19.9 H12) while the global anchor rises by a quarter (§4.3, §4.8).
4. **v6 is weaker than v5 on both counts** — the quantity headline by a quarter to a third, the
   relocated abatement by three quarters — almost all of it after 2050, where v6's political drag
   fades and v5's did not (§4.10).
5. **The two resolutions agree** within about 10% on the quantity headline and in sign region by
   region on the relocation (§4.3, §4.8).

Companion documents: `COUPLING.md` (how the interface works and how to run one), `MODEL.md`
(the mathematics), `PITFALLS.md` (what silently breaks), design note 0005 (the v6 plan and its
results as they landed).

---

## 1. The idea in one page, no equations

REMIND normally answers: *what is the cheapest way to hit a carbon budget?* Its answer is a
carbon price path. Left alone it will happily propose that every region charge several hundred
dollars a tonne by mid-century, because that is cost-efficient.

The PFM asks a different question: **could that region's politics actually deliver that price?**
It estimates, from institutions and who holds economic power, a ceiling on how stringent a country's
climate policy can plausibly get, and how far below that ceiling each country sits. The coupling feeds
that into REMIND so the model has to respect it while it optimises.

The moving parts:

**The anchor.** The global, cost-optimal carbon price path REMIND builds. Everything regional is
derived from it.

**u, the ranking.** Where each region sits, from least to most constrained (0 to 1), read **once**,
from observed 2023 data, separately for each sector. It does not change over the century.

**k(t), the strength.** How large the political shortfall is overall, relative to 2025 (k = 1 in
2025). It moves every period, because the ceilings move with REMIND's energy system, income and
institutions. On the 1000 Gt pathway the Bulk strength falls to about 0.69 by 2050 and 0.52 by 2100.

**φ ("phi"), the feasibility share.** φ = 1 − θ · k(t) · u, per region, sector and period. φ = 1 means
"politics is no obstacle here". φ = 0.6 means "this region carries 60% of the *extra* price the
cost-optimal answer asks beyond current policy" (rule B and C, §1.2) — a ranking at a declared
severity, not a measured capability (§6.2).

**θ ("theta"), the severity dial.** How hard the constraint bites. θ = 0 switches the mechanism off
(every φ = 1). **θ = 0.50 is the central setting**, with **0.325** and **0.675** as the declared range.
Declared, never estimated (`MODEL.md` §5.3).

**κ ("kappa"), the declared erosion.** An optional extra fade on the strength, k(t)·(1−κ)^(t−2025):
"politics improves by itself at κ a year". **κ = 0 in every headline run**; 0.027 (central), 0.02 and
0.05 are one sensitivity arm (ADR 0050 decision 5).

### 1.1 Two political regimes, one carbon price

The PFM is **estimated separately for two sectors**, on one shared specification
(`CONTEXT.md`, `MODEL.md` §2.2):

| sector | what is in it | the politics | market in REMIND |
|---|---|---|---|
| **Bulk** | electricity + industry | few, large, organised actors — utilities, heavy industry | ETS |
| **Diffuse** | buildings + transport | costs land on households, visibly and immediately | ES and "other" |

Each sector gets its own ranking u and its own strength k(t). REMIND needs the two reconciled:

| `cm_pfmSectorMarkup` | delivery | rows |
|---|---|---|
| 0 | collapse to `min(φ_Bulk, φ_Diffuse)` — one price, the worse sector wins | the `-Min` twins (§4.5) |
| 1 | floor + markup: `pm_taxCO2eq` = the worse sector, `pm_taxemiMkt(m)` = market *m*'s own increment over it | every other coupled row |

**Which sector binds depends on the specification family** (§6.2a). Under the deployed family A the
**Bulk** sector is the more constrained one in **15 of 21 EU21 regions and 11 of 12 H12 regions**; under
family B and the annual-data rung it is the Diffuse sector in 17 and 18 of 21, close to `v5` (14). Neither "the limit on
household energy costs constrains the economy-wide price" nor its opposite is a robust statement.

### 1.2 Two closures: hold the price, or hold the budget

The level cap caps each region's price at current policy plus φ times the extra effort,
P = min(A, P_ref + φ · max(A − P_ref, 0)). What REMIND may do in response defines the closure:

| closure | rows | anchor | budget | the sentence it produces |
|---|---|---|---|---|
| **rule B — hold the price** | `-PFMlevelBfix…` | pinned to the θ = 0 run's converged anchor (`cm_pfmAnchorFromGdx`) | not enforced | "political feasibility adds X Gt CO₂ to the 1000 Gt pathway" — the **quantity headline** |
| **rule C — hold the budget** | `-PFMlevelC…` | rises until the budget holds; the cap is rebuilt every iteration (`cm_pfmBoundRebuild = 1`) | enforced | "the budget holds, and abatement moves between regions" |
| ratio mode (continuity) | `-PFMratio` | rises | enforced | each region pays φ times the anchor |

**No adjustment speed λ.** `v5` carried observed stringency forward to 2035 at an estimated speed λ.
λ is not identified (it does not beat persistence, and a placebo returns rates of the same size), so
`v6` removes it from the coupling (ADR 0050). The gap is read at the anchor year and held; the only
gap-closure assumption left is the declared κ arm.

---

## 2. The scenario map

**The file is generated, not hand-written** (ADR 0055): edit the matrix, rebuild, commit both.

```bash
Rscript analysis/run-groups/buildPFMScenarioConfig.R   # -> models/remind_pfm/config/scenario_config_PFM_v6.csv,
                                                       #    then the validator and REMIND's own reader
```

Every row is REMIND's canonical scenario plus named deltas; every coupled row carries
`cm_taxCO2_regiDiff = 11`, `cm_pfmPhiPath = 1` (the share path), `cm_pfmGapClosure = 0` (no λ),
`cm_pfmSectorMarkup = 1` unless a `-Min` twin, and `cm_taxCO2_lowerBound_path_gdx_ref = 0` (§6.3).
H12 titles carry no resolution infix; EU21 titles carry `-EU21-`; coupled titles end in `-v6`.

### 2.1 Uncoupled baselines (re-run on REMIND 3.7.1)

| run | why it exists |
|---|---|
| `SSP2[-EU21]-NPi2025` | current policies: the reference price P_ref, and the `path_gdx_ref` of every other row. **Must complete first.** |
| `SSP2[-EU21]-PkBudg1000` | REMIND's own 1000 Gt cost-optimal answer |
| `SSP2[-EU21]-PkBudg1000-PFMgateRef` | the uniform-price reference: the interface check (§3.1) |

### 2.2 Nulls — the mechanism installed but switched off

| run | switched off how | the control for |
|---|---|---|
| `-PkBudg1000-PFMgate-v6` | present, θ = 0, budget enforced | rule C and ratio mode; must reproduce `-PFMgateRef` |
| `-PkBudg1000-PFMgateBfix-v6` | present, θ = 0, budget forcing off, **anchor pinned to `-PFMgate-v6`** | rule B (the quantity headline); must reproduce `-PFMgate-v6` |

### 2.3 The science runs — 1000 Gt budget (wave 1, both resolutions)

| run | closure | θ |
|---|---|---|
| `-PFMlevelBfix-v6`, `-PFMlevelBfixTh325-v6`, `-PFMlevelBfixTh675-v6` | rule B | 0.50, 0.325, 0.675 |
| `-PFMlevelC-v6`, `-PFMlevelCTh325-v6`, `-PFMlevelCTh675-v6` | rule C | 0.50, 0.325, 0.675 |
| `-PFMlevelBfix-held-v6`, `-PFMlevelC-held-v6` | rules B and C, institutions held at their anchor values | 0.50 |

The **institutions-held twins** travel with the headline (author decision of 2026-10-06): in Phase 1
institutions carried about half of the Bulk strength's fall by 2100.

### 2.4 The sensitivity arms (wave 2, θ = 0.50)

| group | rows (rule) | varies | resolutions |
|---|---|---|---|
| ranking u | uniform, permuted 1–3, reversed (B); uniform, permuted 1 (C) | `pfmPhiOrdering` | EU21; H12 for B uniform and permuted 1 |
| uncovered countries | all-median, all-low, nearest donors (B and C); USA donor, USA low (B) | variant Run-Groups `v6-<rule>` | EU21 |
| markup and ratio | `-Min` (B and C), `-PFMratio` | `cm_pfmSectorMarkup = 0`; bind mode 1 | EU21 and H12 |
| curve shape (main-text robustness) | saturation 0.5× and 2× (B) | `v6-sat05`, `v6-sat2` | EU21 |
| family B / annual data (SI) | `specalt` (B and C), `annual` (B) | `v6-specalt`, `v6-annual` | EU21 |
| formulation | E-hold (B), hold 2060 (B and C), regional k (B) | `pfmPhiHold`, `pfmPhiHoldYear`, `pfmPhiStrength` | EU21 |
| declared closure κ | 0.027, 0.02, 0.05 (B and C) | `pfmPhiKappa` | EU21 |
| strength vs ranking (added 2026-10-10) | E-hold (C) | `pfmPhiHold` | EU21, tag `V6CEHOLD` |

**Retired from `v5`** (ADR 0050 and the batch design): mode M (`-PFMmildProg`), the λ arm `GAPCLOSE`,
the unforced rule B (`-PFMlevelB` against `-PFMgateB`), the ratio-mode twin on the pinned path
(`-PFMratioBfix`) and the NPi twins. Their `v5` readings are in the archived `v5` document.

### 2.5 Running them

```r
library(pfm)
cfg <- "config/scenario_config_PFM_v6.csv"
submitPFM("V6W2EU21", remindDir = "models/remind_pfm-EU21", scenarioConfig = cfg)                  # dry run
submitPFM("V6W2EU21", remindDir = "models/remind_pfm-EU21", scenarioConfig = cfg, dry = FALSE, slurmConfig = "standby")
```

Start tags are `V6W<wave><res>` (`V6W1EU21`, `V6W1H12`, `V6W2EU21`, `V6W2H12`), `<res>BASE` for the
parents, and a tag of its own for a row added after its wave (`V6CEHOLD`), so a re-submission never
re-runs a wave. A start group never mixes resolutions: the H12 rows run from the `-H12` checkout, the
EU21 rows from `-EU21`. `submitPFM` runs a preflight first (repos clean and pushed, packages installed,
groups exported, mappings, the replay control) and refuses on any failure. `RUNNING.md` step 7c.

### 2.5a How an unfinished run earns its place

🔴 **An unfinished run's `fulldata.gdx` is complete and reports success** (`PITFALLS.md` §25).
`analysis/coupled/extractCoupledResults.R` admits an unfinished run only if **zero market-year cells
through 2060 exceed REMIND's own `p80_surplusMaxTolerance`**, and records the reason in
`$admittedUnfinished`. **In the `v6` batch every run finished and none needed admitting.**

---

## 3. Did the runs work?

| check | `v6` batch (64 runs) |
|---|---|
| solve status | `o_modelstat = 2` in **64 of 64** |
| finished | **64 of 64**; none admitted unfinished |
| early-period markets (≤ 2060) | **zero cells over tolerance**; worst exactly 1.00× (EU21 `-PFMlevelC-permuted1-v6`) |
| PFM converged | final change in the share path **≤ 0.0019** in every run, against `cm_pfmConvTol = 0.002` |
| PFM calls | **2 to 15** per coupled run |
| iteration cap | **no run ends at `cm_iteration_max`** |
| budget (rule C, ratio) | **held in every budget-forced run**: cumulative CO₂ 2100 989.0–1001.1 Gt (EU21), 989.7–998.2 (H12) |
| never peaks before 2150 | every rule-B run (by design: the budget is not enforced) and one budget-forced run, EU21 `-PFMlevelCMin-v6` (1011.6 Gt at 2150) — disclose (`PITFALLS.md` §26) |
| infeasibility code | `pm_pfmInfesCode = 0` in every coupled run |
| legislated floor | `cm_taxCO2_lowerBound_path_gdx_ref = 0` in every row |
| cache read | every coupled run read the staged Run-Group cache (`RUNNING.md` step 8); the shared-cache files and the REMIND input archives the runs used are in `records/v6/` and archived (`tools/archiveRunGroupInputs.sh`) |

### 3.1 The interface gate — a tolerance, not bit-identity

`-PFMgate-v6` (θ = 0, mechanism present) against `-PFMgateRef` (mechanism absent), same REMIND version:

| resolution | `pm_taxCO2eq` cells 2030–2100 | differing | max difference | cum. CO₂ 2100 | Nash iterations |
|---|---:|---:|---:|---|---|
| EU21 | 231 | **0** | \$0 | 1000.91 vs 1000.91 Gt | — |
| H12 | 132 | **132** | **\$1.57** | 1000.07 vs 1000.81 Gt | 35 vs 38 |

φ and the share path are exactly 1 in both nulls, so it is not the political layer. At H12 the
difference is **identical across all 12 regions in every year** (0.13% in 2030 rising to 0.32% in
2090): one global path drawn slightly lower because REMIND's budget loop stopped at another iteration.
Both runs meet the budget inside REMIND's own `cm_budgetCO2_absDevTol` (2 Gt). It is outside the
gate's \$1 / 0.2 Gt limits, which were set from `v5`'s size (\$0.71 / \$0.89); **waived and disclosed**
(0005 Phase 3, "H12 gate check"), the limits not re-tuned. **Do not write "bit-identical"** for H12.

**The held-price pinning.** `-PFMgateBfix-v6` reproduces `-PFMgate-v6` within 5 Gt: **+2.2 Gt** at EU21
(1003.2 Gt; `v5` +2.1) and **−1.5 Gt** at H12 (998.6 Gt; `v5` +3.5). If a future re-run moves this by
more than a few Gt, the pinning failed and §4.2a is not interpretable.

> ⚠️ The gate is **structurally blind** to defects that only exist at θ > 0. It proves the
> plumbing, nothing else; §3.3 is the real test.

### 3.2 Convergence — on the whole share path

`v6` checks convergence on the share **path**: at each PFM call the largest change in φ over the
checkpoint years 2035, 2050, 2070 and 2100, against 0.002, after at least two calls; two successive
moves in opposite directions are damped (α = 0.5) rather than the tolerance loosened. Every run
converged: 2–15 calls, final change ≤ 0.0019.

### 3.3 φ and the markup reach the solver

- The share path is loaded in every θ > 0 run, with the formulation `v6-anchor` in its history, and
  φ < 1 somewhere (`phase3Gate.R` at both resolutions).
- Rule C's rebuild reproduces the R-side cap to **9.1e-7** (`p45_pfmBoundCheck_iter`) at both
  resolutions.
- **Markup written vs seen.** In a finished run's gdx, `p45_pfmMarkupSeen` is read at the start of the
  last presolve (what the presolve before wrote) and `p45_pfmMarkupWritten` at its end, so the two
  differ whenever the markup moved in the final iteration. In the `v6` batch every run where they
  differ had its markup move in the last iteration, and no run with an unmoved markup shows a
  difference. The `markupMismatch` list in `coupled-facts.json` is a "still moving" flag, not an
  erasure (`PITFALLS.md` §16).

### 3.4 Settling — four short rule-C runs to quote with a note

Four EU21 rule-C runs were still moving in their last ten iterations, which overlap the budget loop's
final adjustment: `-PFMlevelC-kappa05-v6` (34 iterations; price range up to 16.7%, budget miss up to
28.5 Gt), `-PFMlevelC-specalt-v6` (29; 16.5%, 13.0 Gt), `-PFMlevelC-uniform-v6` (40; 14.9%, 16.8 Gt) and
`-PFMlevelCTh325-v6` (38; 3.5%, 28.0 Gt). All ended within 1.6 Gt of the budget. The deployed rule-C run
moved 0.6% and 3.2 Gt; every H12 rule-C run settled (at most 1.4% and 5.5 Gt). `convergence-audit.rds`.

---

## 4. What the results say

Cumulative figures are `pm_actualbudgetco2("2100")` in Gt CO₂ unless marked **peak** (the PkBudg
budget is a peak budget); prices are 2050, \$2005/tCO₂, and name their market. Price ratios are
"× the θ = 0 run" (`-PFMgate-v6`).

### 4.1 Ratio mode — continuity with `v5`

Each region pays φ times the anchor, budget enforced. It holds the budget at both resolutions. The
2050 anchor is **×1.287** the θ = 0 run's at EU21 (×1.264 H12) and the median regional price ×1.060
(×1.048); it moves 19.7 Gt CO₂eq of abatement between regions at EU21 (17.4 at H12).

**The price splits within regions, both ways.** ES/ETS in 2050 runs **0.56–1.17** at EU21 (ES below ETS
in 16 of 21 regions) and **0.57–1.29** at H12 (4 of 12). The lowest is China at both resolutions: its
Diffuse market is the most constrained, its Bulk market is not (§6.2a); the highest is Other Asia.
The finding is the width and region-specificity, not a direction.

### 4.2 Rule B on the unforced anchor — not in `v6`

The unforced family (`-PFMlevelB` against `-PFMgateB`, whose null emits about 1700 Gt) was an SI
sensitivity in `v5` and is not part of the `v6` batch. The quantity headline is §4.2a.

### 4.2a The quantity headline — the cap on the price path that holds the budget

Both runs read the anchor `-PFMgate-v6` converged to and switch budget forcing off, so the null meets
the budget (§3.1, the pinning) and the difference is the extra CO₂ the ceiling adds to the 1000 Gt
pathway.

| | EU21 | H12 |
|---|---:|---:|
| `-PFMgateBfix-v6` (θ = 0 null) | 1003.2 | 998.6 |
| **`-PFMlevelBfix-v6`** (θ = 0.50) | **1121.4** | **1111.4** |
| **Δ at θ = 0.50** | **+118.2** | **+112.8** |
| Δ at θ = 0.325 / 0.675 | +73.0 / +181.5 | +69.6 / +169.6 |
| slope | **264 Gt per unit θ** | **247 Gt per unit θ** |
| institutions held | +117.3 | +107.8 |
| markup off (`-Min`) | +159.7 | +154.2 |
| bind share (last iteration) | 0.986 | 0.994 |
| Bulk strength k 2050 / 2100 | 0.686 / 0.525 | 0.684 / 0.516 |

**Political feasibility adds about 115 Gt CO₂ to the 1000 Gt pathway** at the central severity, 70–182
Gt across the declared θ range. The two resolutions agree within 5%.

- **Holding institutions changes almost nothing** (−0.9 / −5.0 Gt), although it moves the strength a
  lot (Bulk k 2100 0.525 → 0.417, Diffuse 0.723 → 1.001 at EU21): the two sectors' changes cancel in
  the headline. The headline does not rest on projected institutions.
- **Sectoral differentiation buys back about 41 Gt** (26% EU21, 27% H12) (§4.5).
- **The cap binds almost everywhere** (bind share 0.986 / 0.994).
- **Emissions do not peak inside the horizon** in any rule-B run (EU21 1183.5 Gt at 2150): that is
  what "the budget is not enforced" means. Quote the 2100 cumulative, never a peak, for this family.

### 4.3 Rule C — the budget holds under the cap

Every rule-C run holds the budget (§3). What the cap changes is where the price and the abatement
sit. The anchor rises to make up for the capped regions; in 2050, against the θ = 0 run:

| | EU21 anchor | EU21 median region | H12 anchor | H12 median region |
|---|---:|---:|---:|---:|
| θ = 0.325 | 1.152 | 1.089 | 1.141 | 1.039 |
| **θ = 0.50** | **1.259** | **1.153** | **1.251** | **1.075** |
| θ = 0.675 | 1.417 | 1.232 | 1.383 | 1.115 |
| institutions held | 1.261 | 1.158 | 1.245 | 1.068 |
| markup off | 1.351 | 1.120 | 1.343 | 1.046 |

The cheapest region in 2050 is REF at both resolutions (×0.91); the dearest is CHA (×1.25–1.26) or a
northern European region at EU21 (NEN ×1.26).

> ⚠️ **Do not compare the regional median across resolutions.** 11 of EU21's 21 regions are European
> and all sit at ×1.12–1.26, so the EU21 median is a European price. Counting Europe once, as H12 does,
> the EU21 median is ×1.037, below H12's ×1.075. Quote rule C by the abatement moved (§4.8) or the
> emissions-weighted price (×0.984 EU21, ×1.037 H12, `held-budget-prices-levelC.rds`).

**Reading.** Rule C is not "the budget cannot be held". It is "the budget holds, the global price
rises by a quarter, and the capped regions' share of the effort moves elsewhere" (§4.8).

### 4.4 Mode M — retired

Mode M generated the price from observed political momentum at the speed λ. With λ removed
(ADR 0050) it has no mechanism left and is not in `v6`. Its `v5` reading (far past any 1000 Gt budget,
not a corroboration of the level cap) is in the archived document.

### 4.5 The markup-off counterfactual

| | EU21 | H12 |
|---|---:|---:|
| quantity headline with markup (`-PFMlevelBfix-v6`) | +118.2 | +112.8 |
| without (`-PFMlevelBfixMin-v6`) | +159.7 | +154.2 |
| **bought back by pricing two markets separately** | **41.5 Gt = 26%** | **41.3 Gt = 27%** |
| rule C anchor 2050, markup on / off | ×1.259 / ×1.351 | ×1.251 / ×1.343 |

**Sectoral differentiation buys back about a quarter of the carbon cost of political feasibility.**
It also lowers the anchor rise rule C needs, without removing it. EU21 `-PFMlevelCMin-v6` never peaks
before 2150 (1011.6 Gt there) — quote its 2100 value with that note.

### 4.6 The θ sweep

Quantity headline: **+73.0 / +118.2 / +181.5 Gt** at EU21 and **+69.6 / +112.8 / +169.6 Gt** at H12 for
θ = 0.325 / 0.50 / 0.675 — 264 and 247 Gt per unit θ, steeper above 0.50. Rule C: the anchor goes ×1.152
→ 1.259 → 1.417 (EU21) and the relocated abatement 15.0 → 22.7 → 45.0 Gt CO₂eq. The sweep is declared;
none of its points is an estimate. Figure: `v6-coupled-theta`.

### 4.7 The NPi twins — not in `v6`

The current-policies twins and their confound (`cm_taxCO2_regiDiff` 6 → 11 alone moves emissions six
to seven times more than politics) were a `v5` display; they are not in the `v6` batch.

### 4.8 Where abatement goes, and what it costs in GDP

`coupledCostsAndAbatement.R` → `coupled-costs.json`: regional `vm_co2eq`, `vm_cesIO` ("inco") and
`vm_cons` over 2020–2100, each run against its matched θ = 0 null; money discounted at 5%/yr.
**Relocated** is half the sum of the absolute regional changes — the volume that moved, not the net.

| | net Δ CO₂eq | relocated | ρ(φ, relative change) | GDP | consumption |
|---|---:|---:|---:|---:|---:|
| **rule C** EU21 / H12 | **−0.1 / −3.0** | **22.7 / 19.9** | −0.47 / −0.67 | +0.035% / +0.019% | +0.017% / +0.012% |
| ratio mode EU21 / H12 | −3.1 / −2.6 | 19.7 / 17.4 | −0.72 / −0.56 | +0.036% / +0.027% | +0.017% / +0.017% |
| **rule B** (quantity headline) EU21 / H12 | +127.9 / +121.5 | 66.7 / 60.7 | −0.36 / −0.59 | +0.19% / +0.16% | +0.20% / +0.18% |

**Under a held budget the ceiling moves abatement rather than reducing it**: the net change is a few
Gt while about 20 Gt changes region, and the more constrained a region the more it emits relative to
its own baseline (negative ρ). Rule C, EU21 / H12: CHA −10.2 / −8.9, IND +8.1 / +7.0, MEA +7.9 / +5.1,
EUR (summed) −6.0 / −3.8, SSA −3.7 / −5.9, REF +3.7 / +3.8 — the same sign in 11 of 12 H12 regions.
Under κ the relocation falls to 9.5 / 8.4 / 5.3 Gt (κ = 0.02 / 0.027 / 0.05), with uniform shares to
11.7 Gt.

**Under the cap, the extra emissions land** (EU21, rule B) in MEA +37.5, IND +22.4, OAS +22.2, SSA
+16.8, REF +11.2 and USA +7.7 Gt (H12 alike).

> 🔴 **GDP rises, and that is not a benefit.** REMIND carries no climate damages, so any run that
> abates less looks richer. Quote it only in the same sentence as the extra CO₂, or not at all.
> Regional GDP is not reported.

### 4.9 The sensitivity arms — what the quantity headline is sensitive to

Rule B, θ = 0.50, EU21, extra cumulative CO₂ by 2100 (deployed **+118.2 Gt**). Each arm records the
options its last PFM call ran with (`coupled-facts.json` `arms`); a recorded option that differs from
the declared one would make the arm unusable, and none does. Figure: `v6-coupled-arms`.

| arm | Δ Gt | vs deployed | reading |
|---|---:|---:|---|
| **κ = 0.02 / 0.027 / 0.05** | +53.5 / **+41.2** / +22.1 | −64.7 / −77.1 / −96.1 | **the largest effect**: at the central κ, 35% of the headline is left — the result depends on whether politics improves by itself |
| static share, k ≈ 1 (E-hold) | +189.1 | +70.9 | the moving strength removes 37% of the static result |
| institutions held | +117.3 | −0.9 | §4.2a |
| hold 2060 / regional k | +125.6 / +121.5 | +7.4 / +3.3 | small |
| ranking: uniform | +105.8 | −12.4 | size alone carries most of the effect |
| ranking: permuted 1 / 2 / 3 | +102.1 / +126.4 / +89.3 | | the model's ranking (+118) sits inside the range of random orders |
| ranking: reversed | +67.9 | −50.3 | the ranking is not irrelevant: reversing it costs 50 Gt |
| uncovered countries: all median / all low / nearest donors / USA donor / USA low | +109.5 / +154.6 / +133.6 / +117.4 / +134.8 | −8.7 to +36.4 | **the widest data-side band, 110–155 Gt** |
| saturation 0.5× / 2× | +115.2 / +130.0 | −3.0 / +11.8 | curve shape: small |
| family B (`specalt`) / annual data | +107.5 / +164.4 | −10.7 / +46.2 | the annual rung keeps Bulk k above 1 (1.19 / 1.12 in 2050 / 2100) |

Rule C under the same arms (median 2050 regional price, EU21): κ ×1.069 / 1.055 / 1.031, uniform ×1.043,
permuted 1 ×1.114, all-median ×1.137, all-low ×1.217, nearest ×1.178, family B ×1.136, hold 2060 ×1.163.

### 4.10 Against `v5`

`analysis/v6/coupledV5V6Contrast.R` → `v5-v6-coupled-contrast.json`. Each headline against its own
version's θ = 0 null, so REMIND's drift between 3.7.0.dev29 and 3.7.1 (+9 to +11 Gt on the nulls)
cancels to first order.

| | `v5` EU21 / H12 | `v6` EU21 / H12 |
|---|---|---|
| quantity headline, θ = 0.50 | +159.3 / +163.8 | **+118.2 / +112.8** |
| slope per unit θ | 330 / 346 | 264 / 247 |
| markup buy-back | 46.2 / 58.6 | 41.5 / 41.3 |
| rule C anchor 2050 | ×1.305 / ×1.326 | ×1.259 / ×1.251 |
| rule C abatement relocated | 76.7 / 84.5 | **22.7 / 19.9** |

**The quantity headline shrinks by a quarter to a third.** Offline, most of that is removing λ
(ADR 0050): the paper must say the weaker constraint comes mostly from dropping an unidentified rate,
not from new evidence of feasibility.

**Rule C moves about three quarters less abatement, almost all of it after 2050**
(`analysis/v6/ruleCRelocationDecomp.R` → `rulec-relocation-decomp.rds`; figures `v6-rulec-relocation`,
`v6-price-catchup`). Gross relocation 2020–2050 is 10.9 → 8.8 Gt; 2051–2100 it is 66.2 → 16.7 Gt (EU21).

1. **In `v6` the constrained regions' price catches up with the θ = 0 run's by about 2070.** ETS price
   over the null's in 2030 / 2070: REF 0.58 / 1.03, MEA 0.56 / 1.03, IND 0.52 / 1.00 (`v6`), against REF
   0.59 / 0.68, MEA 0.81 / 0.95, SSA 0.76 / 0.89 (`v5`). In `v5` those regions kept a cheaper price for
   the whole second half of the century and emitted more (SSA ETS +14.4, MEA ETS +17.3, REF ETS +10.2 Gt
   after 2050), which China's power sector absorbed (−42.6 Gt). That is the moving strength k(t) at
   work; `v5` held φ fixed after 2035. The κ arms confirm it dose by dose: post-2050 relocation 16.7 →
   9.4 / 8.9 / 5.7 Gt as the 2070 price wedge narrows 0.117 → 0.037 / 0.026 / 0.008.
2. **The ranking moved.** China's Diffuse market and India's Bulk market are now the most constrained
   (u = 1). CHA's Bulk market is unconstrained in both versions (ETS ×1.32–1.37 in 2100) while its
   ES+other market emits +8.6 Gt, so 16.1 Gt of the `v6` shift nets out inside regions (`v5`: 5.0).

**Open:** how much of part 1 is the fading strength and how much the new ranking. The test is the
rule-C static-share run `-PFMlevelC-Ehold-v6` (§2.4): near 77 Gt relocated means the strength explains
the drop; near 23 Gt, the ranking does.

---

## 5. Limitations — read this before quoting anything

1. **θ and κ are declared, not estimated.** θ carries the main-text band; κ is the largest single
   sensitivity of the quantity headline (§4.9). Neither may be presented as a finding.
2. **The `v5` → `v6` drop is mostly a modelling decision** (removing an unidentified λ), not new
   evidence; say so wherever the two are compared (§4.10).
3. **Two regions per sector are pinned by the parameter, not by data.** φ = 1 − θ·k(t) exactly for the
   region at u = 1 in each sector (**CHA** in Diffuse, **IND** in Bulk, at both resolutions, under the
   deployed spec; REF under family B, REF and ECS under the annual rung), and 1 for the region at u = 0.
   φ is a *ranking* (§6.2).
4. **Legislated prices may be rolled back in every run** (§6.3), and rarely are: from 2030 to 2100 both
   market prices sit below the current-policy reference in 1.7% of region-years under rule B at EU21
   (100 of 5775 across 25 runs; 0.8% at H12), 0.5% under rule C (0.2%) and 6.1% in ratio mode (0.8%),
   always in European regions, whose reference rises to \$179.5 by 2050.
5. **The co-evolution feedback is real and not causal.** The coupled strength differs from the offline
   one (Bulk k 2050 0.69 coupled against 0.63 offline at κ = 0), and the PFM loop takes 2–15 calls. Call
   it conditional scenario accounting (`MODEL.md` §8.1).
6. **The United States has no covered country.** Its φ comes from the donor rule; the USA-donor and
   USA-low arms bound it (+117.4 / +134.8 Gt, §4.9).
7. **The assignment of uncovered countries is the widest data-side band** (110–155 Gt). Report it.
8. **The interface gate is verified to a tolerance**, and at H12 outside the `v5`-derived limits
   (§3.1, waived and disclosed).
9. **Four short rule-C runs were still settling** (§3.4); one budget-forced run never peaks (§4.5).
10. **Every φ is conditional on modelling choices the data do not settle** — the frontier family
    (family B in §4.9), the curve shape, the institution projections (held twins), the hold rule
    (E-hold). No φ here is a measured property of a region.
11. **Which sector binds** is a property of the specification family: Bulk in 15 of 21 EU21 regions
    under family A, in 3 of 21 under family B and the annual rung (§6.2a). Do not write it as a fact
    about regions.

---

## 6. Diagnosis: mechanisms that shape every result

### 6.1 The reference path is the hidden driver

The level cap acts on the *increment* over the current-policy price `SSP2[-EU21]-NPi2025` (REMIND
3.7.1). Its 2050 price, the higher of the two markets:

| region | NPi 2050 price |
|---|---:|
| the 9 EU/UK regions (EU21) / EUR (H12) | **\$179.5** |
| Canada/Australia/NZ | \$29.7 |
| Latin America | \$22.4 |
| Japan | \$18.9 |
| Non-EU Nordic (EU21 NEN) / Non-EU Europe (H12 NEU) | \$16.4 / \$14.1 |
| Non-EU S. Europe (EU21 NES) | \$13.7 |
| China, Other Asia | \$11.2 |
| Sub-Saharan Africa | \$5.7 |
| India | \$4.3 |
| Russia & Central Asia | \$4.0 |
| Middle East & N. Africa | \$3.8 |
| United States | **−\$6.1** (see below) |

Regions with near-zero reference prices have almost all of their cost-optimal price exposed to φ.

**The US reference is negative by REMIND's input, not by the coupling.** REMIND's `NPi2025` realization
(`45_carbonprice/NPi2025/datainput.gms`) holds the price from 2030 at the input value
`fm_taxCO2eqHist("2030")` for the USA and SSA, and the input data (revision 8.24) give the USA **−\$6.16**
(after \$24.6 in 2020 and \$12.3 in 2025; SSA \$5.71). `v5`'s reference had no US value at all. Under the
level cap the US increment is therefore $A + 6.2$, and $P^{*} = -6.2 + \varphi\,(A + 6.2)$. Quote any US
number with its reference: "against a current-policy path that turns the US carbon price slightly
negative from 2030".

### 6.2 Why φ = 1 − θ·k for some regions — it is a *ranking*, not a capability

```
phi_{r,s}(t) = 1 - theta * k_s(t) * u_{r,s}       u = (gap - gap_min) / (gap_max - gap_min), at 2023
```

`u` is the region's **position between the best and worst region**, per sector, read once at the
anchor year. The largest gap is handed u = 1, the smallest u = 0; **both endpoints are guaranteed by
construction**. In 2025 (k = 1) φ = 0.50 at θ = 0.50 means "ranked last"; later φ rises as k(t) falls.

In the batch (`-PFMlevelBfix-v6`, θ = 0.50, the 2025 share): **EU21** floor **CHA** (Diffuse) and **IND**
(Bulk), top **NEN 0.900**, median 0.619; **H12** floor **CHA** and **IND** again, top **NEU 0.869**, median
0.610. The `v5` floor pairs (ECS, REF at EU21; LAM, REF at H12) are gone: the ranking moved with the
v6 specification and anchor year.

**For the paper.** Do not write "India can only sustain 50% of the cost-optimal price". Write "these
regions rank at the bottom of the feasibility distribution in one sector; how far below the rest is
set by θ, a parameter we declare."

### 6.2a Which sector binds, at region level

From `p45_pfmPhiMkt` of `-PFMlevelBfix-v6` (the 2025 share):

| | Diffuse binds | Bulk binds |
|---|---:|---:|
| **EU21 regions** | **6** — CHA, ECS, FRA, EWN, ESW, NES | **15 of 21** |
| **H12 regions** | **1** — CHA | **11 of 12** |

The clearest cases at EU21:

| region | ES (Diffuse) φ | ETS (Bulk) φ | binds |
|---|---:|---:|---|
| China (CHA) | **0.500** | 1.000 | **Diffuse**, by 0.500 (ETS on the ceiling clamp) |
| India (IND) | 0.729 | **0.500** | **Bulk**, by 0.229 |
| Other Asia (OAS) | 0.808 | **0.536** | **Bulk**, by 0.272 |
| Middle East & N. Africa (MEA) | 0.729 | **0.540** | **Bulk**, by 0.189 |
| West-North Europe (EWN) | **0.619** | 0.836 | **Diffuse**, by 0.217 |

**This depends on the specification family, not on `v5` versus `v6`.** Across the EU21 rule-B runs
(`coupled-runs.rds` `$phi`, the 2025 share):

| run | Bulk binds | floor regions (φ = 0.50) |
|---|---:|---|
| deployed (family A) | 15 of 21 | CHA, IND |
| saturation 0.5× / 2× (family A) | 13 / 14 | CHA, IND / CHA, ECE |
| **family B** (`specalt`) | **3** (CAZ, ENC, NEN) | REF |
| **annual data** | **3** (CAZ, NEN, REF) | REF, ECS |
| all-median / all-low / nearest donors | 15 / 15 / 15 | CHA, IND / MEA, CHA / CHA, IND |

Eight regions keep their binding sector in every run (CAZ, NEN on Bulk; CHA, ECS, ESW, EWN, FRA, NES on
Diffuse); thirteen change with the specification. Under family B the attribution is close to `v5`
(Diffuse in 14 of 21): Diffuse binds in 17 of 21 under family B (REF ties) and 18 under the annual rung. The assignment of uncovered countries does not move it. **So which sector binds
is decided by how incumbent power is assumed to behave below the observed range** (family A vs B,
`MODEL.md` §2.3) — not by the data. A sector φ of exactly 1.000 is a ceiling clamp, not a measurement —
do not report "China's electricity and industry face no political constraint". Never quote a
country-level figure for a coupled regional result.

### 6.3 The legislated price floor is off in every run

`cm_taxCO2_lowerBound_path_gdx_ref` defaults to **on**, and
`45_carbonprice/functionalForm/postsolve.gms` applies

```gams
pm_taxCO2eq(t,regi) = max(pm_taxCO2eq(t,regi), p45_taxCO2eq_path_gdx_ref(t,regi));
```

inside the `cm_iterative_target_adj eq 5/7/9` block. **It is 0 in every `v6` row** (the matrix sets it
on both parents), so prices below the reference path are permitted. **Methods must say which policy
world this is**, in one sentence: a feasibility ceiling that cannot bind below legislated policy would
be legislation plus a ceiling; a model that lets a region abolish its ETS is also a choice.

### 6.4 The level-cap ratchet — fixed, confirmed absent

A past defect: the level cap read the optimal price from the run's own already-capped
`pm_taxCO2eq`, collapsing the bound onto the reference within 3–4 calls. `iterativePFM.R` takes it
from `p45_taxCO2eq_anchor`. **Confirmed absent on `v6`**: the lowest 2050 market price under rule B is
\$135.9 (CHA, EU21; \$133.9 H12), against China's \$11.2 reference.

---

## 7. Needed improvements, in priority order

1. ⏳ **The rule-C static-share run** (`-PFMlevelC-Ehold-v6`, §4.10): strength vs ranking. Submitted
   2026-10-10.
2. ✅ **The US reference price** (2026-10-10): REMIND's own `NPi2025` input, −\$6.16 from 2030 (§6.1).
   Quote US numbers with it.
3. 🟠 **Extend the budget warning to peak budgets** (`PITFALLS.md` §26): EU21 `-PFMlevelCMin-v6` never
   peaks before 2150 and nothing warned.
4. ✅ **The sector-binding diagnostic across specifications** (2026-10-10, §6.2a): the attribution
   follows the specification family.
5. ✅ **Floor violations re-measured on `v6`** (2026-10-10, limitation 4): 0.5–6.1% of region-years, all
   European.

---

## 8. How to use these in the paper

| display | runs | numbers | must travel with it |
|---|---|---|---|
| **the cost of political feasibility** (quantity headline; `v6-coupled-theta`) | `-PFMlevelBfix-v6` vs `-PFMgateBfix-v6`, both resolutions, with `Th325/Th675`, `-held`, `-Min` | **+118 / +113 Gt**; θ range 70–182 | θ declared; κ (§4.9); floor-off world; the null reproduces `-PFMgate-v6` within 2 Gt |
| **what it is sensitive to** (`v6-coupled-arms`) | the wave-2 arms, EU21 | κ 41 Gt left at 0.027; assignment 110–155; ranking inside random orders | κ declared; one seed per permutation |
| **where the abatement goes** (rule C) | `-PFMlevelC-v6` vs `-PFMgate-v6`, per region | net −0.1 / −3.0 Gt against 22.7 / 19.9 Gt moved; anchor ×1.26 / ×1.25 | emissions only; never the regional median across resolutions |
| **against `v5`** (`v6-rulec-relocation`, `v6-price-catchup`) | §4.10 | headline −26% / −31%; relocation −70% / −76%, almost all after 2050 | the drop is mostly λ's removal; the strength-vs-ranking split is open until `-PFMlevelC-Ehold-v6` |
| **politics splits the carbon price** (ratio mode) | `-PFMratio-v6`, 2050 | ES/ETS 0.56–1.17 EU21 | both directions |
| **Methods: which policy world** | every row | floor off | one sentence |
| **Discussion: the feedback** | the coupled strength | Bulk k coupled 0.69 vs offline 0.63 (2050) | not causal |

**Do not use for:** any `v5` number as current; "rule C cannot hold the budget"; a regional median
compared across resolutions; any floor-region claim without flagging that φ is ordinal; any
country-level binding-sector figure as a statement about regions; any price without naming its
market; "the constraint lands on households" or "on industry" (it follows the specification family,
§6.2a); a US number without its negative reference (§6.1); the GDP gain without the CO₂ it buys.

---

## 9. How to re-derive every number here

```bash
Rscript analysis/coupled/runCoupledStage.R v6      # extract (coupled-runs.rds), admission, facts, costs,
                                                   # held-budget prices, rule-C freeze, convergence audit, provenance
Rscript analysis/v6/coupledV5V6Contrast.R          # -> v5-v6-coupled-contrast.{rds,json}
Rscript analysis/v6/ruleCRelocationDecomp.R        # -> rulec-relocation-decomp.rds
Rscript analysis/v6/phase3Gate.R output/remind-runs/v6/EU21            # the gate, per resolution
Rscript analysis/v6/phase3Gate.R output/remind-runs/v6/H12 --res H12
Rscript analysis/figures/build-figures.R --group=v6                    # the figures
```

The extractor keeps the newest run per (resolution, scenario), checks `log.txt` for `REMIND run
finished`, and applies the early-market admission rule (§2.5a).

By hand, `gdxdump fulldata.gdx symb=<name> format=csv`:

| what | symbol |
|---|---|
| cumulative CO₂ | `pm_actualbudgetco2` — element `"2100"`. **It runs to 2150**; the peak is the budget quantity |
| the **floor** every market pays | `pm_taxCO2eq` — **multiply by 272 to get \$2005/tCO₂**. ⚠️ **This is not the ES price** |
| **ES** / **ETS** market price | `pm_taxCO2eq + pm_taxemiMkt(t,regi,"ES"/"ETS")` — dims **(year, region, market)** |
| emissions by market | `vm_co2eqMkt(t, regi, market)` (GtC; ×44/12) |
| the cost-optimal anchor | `p45_taxCO2eq_anchor(ttot)` — ×272 |
| the share path | `p45_pfmPhiPath(ttot, regi)`, per market `p45_pfmPhiMktPath(ttot, regi, market)`; per iteration `p45_pfmPhiPath_iter` |
| φ per region / per market (2025 value) | `p45_regiDiff_phi` / `p45_pfmPhiMkt(regi, market)` |
| the strength and options a call used | the run's `pfm-phi-history.rds` (last entry: `k`, `options`, `formulation`) |
| did the markup reach the solver? | `p45_pfmMarkupWritten` vs `p45_pfmMarkupSeen` — different iterations (§3.3) |
| rule C's rebuild | `p45_pfmBoundCheck_iter` (~1e-6 on call iterations) |
| path convergence | `p45_pfmDelta_iter` — **entries before the first PFM call are a 1e6 sentinel**; `p45_pfmCallCount` |
| how hard the cap bit | `p45_pfmBindShare_iter` — ⚠️ **written only under bind mode 2** |
| did Nash converge? | `cm_iteration_max` — the count actually used; 100 means it hit the cap |
| did the **budget** converge? | `p80_globalBudget_absDev_iter` at the last iteration against `cm_budgetCO2_absDevTol`; `pm_pfmBudgetWarn`; `p45_pfmBudgetNoPeak_iter` |
| solve status | `o_modelstat` (2 = locally optimal) — **reads 2 on an unfinished run too** |
| did the markets clear? | `p80_surplusMax_iter` at the last iteration over `p80_surplusMaxTolerance`; split at 2060 |
| the REMIND version | `c_model_version` (3-7-1) |
| the dial | `cm_pfmTheta`, `cm_pfmBindMode`, `cm_pfmSectorMarkup`, `cm_pfmPhiPath`, `cm_pfmBoundRebuild`, `cm_pfmAnchorFromGdx`, `cm_iterative_target_adj` |

`cm_iterative_target_adj` tells you which family a run belongs to: 9 = budget enforced by iteration,
0 = not. It must match before two runs are differenced.

> 🔴 **Before reading any symbol by hand, check the run finished.** `grep -q "REMIND run finished"
> <rundir>/log.txt`. `PITFALLS.md` §25.
