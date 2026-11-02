# The coupled scenario set — what each run is for, and what the batch says

*A plain-language guide to the coupled REMIND runs: why each one exists, what it may and may
not be used to conclude, and where it belongs in the paper.*

**Status.** The **`v8` batch** is in (2026-11-01): **66 runs** on REMIND 3.7.1, of which **60 are coupled** — 42 at
EU21 and 18 at H12 — on Run-Group **`v8`** (selected specification
`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP iw:fexp fos5`, ADR 0062; the rents slack, ADR
0061; gap-closure institutions, ADR 0063; the regional strength as the central coupling form). The coupled rows are the
headline and its θ sweep, the persistence ladder, the strength forms, the rents valuation, three institution rules, and
the two **shrinking-future chains** (§4.11). Every row is generated from `analysis/run-groups/scenario-matrix-v8.yml`
(ADR 0055). Every run finished; **one does not peak its budget** (EU21 hold the budget, growing limit; it meets the
budget at 2100, as on `v7`; §3.4). The `v7` version of this document, with the `v7` batch's 40 runs, is archived at
`../_archive/_wip/2026-10-31/docs/SCENARIOS-v7.md` (`v6`: `../_archive/_wip/2026-10-25/docs/SCENARIOS-v6.md`).
**`v8` is the paper's basis since 2026-11-01** (author; `v7` was 2026-10-25 to 2026-10-31); this document describes
the current version.

**Every number below** is read from `output/pfm/v8/coupling/`: `coupled-facts.json` (results per run and
sensitivity run), `coupled-costs.json` (emissions moved, GDP), `convergence-audit.rds`, `held-budget-prices-levelC.rds`,
`gate-ref-compare.rds`, `budget-peak.rds`, `emissions-2100.rds` and `shrinking-future.rds`. §9 rebuilds them. Re-read
them from there.

**Horizon.** Results are reported to **2100 and no later** (author, 2026-10-25): cumulative CO₂ to 2100, net CO₂ in
2100, the net-zero year by 2100. The budget-peak admission check (§3, `PITFALLS.md` §26) reads later periods; it is an
internal check and is phrased for the paper without post-2100 numbers.

> ⚠️ **Every price in this document names its market.** With the markup on
> (`cm_pfmSectorMarkup = 1`) *both* markets carry one: ES (buildings and transport) faces
> `pm_taxCO2eq + pm_taxemiMkt("ES")`, ETS (electricity and industry) faces
> `pm_taxCO2eq + pm_taxemiMkt("ETS")`, and `pm_taxCO2eq` alone is the **floor** that neither
> market actually pays. `COUPLING.md` §11.6.

**The batch in six sentences.**

1. **Holding the price, political feasibility adds 75 Gt CO₂ by 2100 at EU21 and 64 Gt at H12** (θ = 0.50; 39–110 Gt
   across the declared θ range), and net CO₂ in 2100 is 1.3 / 0.9 Gt a year where the no-politics reference is at
   0.2 / −0.1 (§4.2a).
2. **The headline rests most on how long today's limit lasts** (§4.9): kept constant it adds 124 Gt; if it also erodes
   at 2.7% a year, 29 / 23 Gt, about two-fifths of the headline; if it tightens 0.5% a year, 160 Gt (EU21).
3. **Holding the budget, every admitted run meets it**, the global price rises by about a sixth (×1.16 / ×1.14 in 2050),
   and the ceiling moves about 20 Gt CO₂eq of abatement between regions (20.6 EU21 / 17.9 H12) (§4.3, §4.8).
4. **What a decade-by-decade politics does depends on expectations** (§4.11): if each decade expects the limit to lift
   after it, hold the price ends at +39 Gt instead of +75, at the same prices paid; hold the budget still holds, with the
   effort moved later.
5. **`v8` is a quarter weaker than `v7`, and the relocation changes composition**: Russia & reforming countries still
   take the most, but the Middle East now *gives* abatement under hold the budget (its fossil rents fall, and with them
   its distance below the ceiling) and Sub-Saharan Africa takes more (§4.10).
6. **The two resolutions agree** within about 15% on the quantity headline and in sign on the main relocations (§4.2a,
   §4.8).

Companion documents: `COUPLING.md` (how the interface works and how to run one; §14.1 the sequential runs), `MODEL.md`
(the mathematics), `PITFALLS.md` (what silently breaks), design note 0009 (the `v8` formulation and its results).

---

## 1. The idea in one page, no equations

REMIND normally answers: *what is the cheapest way to hit a carbon budget?* Its answer is a
carbon price path. Left alone it will happily propose that every region charge several hundred
dollars a tonne by mid-century, because that is cost-efficient.

The PFM asks a different question: **could that region's politics actually deliver that price?**
It estimates, from institutions and the economic weight of fossil and clean-energy interests, a ceiling on how
stringent a country's climate policy can plausibly get, and how far below that ceiling each country sits. In
buildings & transport, how far below also depends on the country's fossil rents. The coupling feeds that into REMIND so
the model has to respect it while it optimises.

The moving parts:

**The anchor.** The global, cost-optimal carbon price path REMIND builds. Everything regional is
derived from it.

**u, the ranking.** Where each region sits, from least to most constrained (0 to 1), read **once**,
from observed 2023 data, separately for each sector. It does not change over the century.

**k(t), the strength.** How large the region's political shortfall is, relative to its own 2025 gap (k = 1 in 2025).
It moves every period, because the ceilings move with REMIND's energy system, income and institutions, and in
buildings & transport the distance below the ceiling moves with fossil rents. On the 1000 Gt pathway the
final-energy-weighted power & industry strength is about 0.63 in 2050 and 0.73 in 2100; buildings & transport 0.62
and 0.49.

**φ ("phi"), the feasibility share.** φ = 1 − θ · k(t) · u, per region, sector and period. φ = 1 means
"politics is no obstacle here". φ = 0.6 means "this region carries 60% of the *extra* price the
cost-optimal answer asks beyond current policy" (both closures, §1.2) — a ranking at a declared
severity, not a measured capability (§6.2).

**θ ("theta"), the severity dial.** How hard the constraint bites. θ = 0 switches the mechanism off
(every φ = 1). **θ = 0.50 is the central setting**, with **0.325** and **0.675** as the declared range.
Declared, never estimated (`MODEL.md` §5.3).

**κ ("kappa"), the erosion rate.** An optional extra fade on the strength, k(t)·(1−κ)^(t−2025):
"politics improves by itself at κ a year". **κ = 0 in every headline run**; 0.027 (central), 0.02, 0.05 and the
historical per-sector rates are sensitivities (ADR 0050 decision 5).

**The window (the shrinking future).** A step of a sequential run applies φ only to its own decade and plans the rest
as if the limit lifted (§4.11, `MODEL.md` §5.6a).

### 1.1 Two political regimes, one carbon price

The PFM is **estimated separately for two sectors**, on one shared specification
(`CONTEXT.md`, `MODEL.md` §2.2):

| sector | what is in it | the politics | market in REMIND |
|---|---|---|---|
| **Power & industry** | electricity + industry | few, large, organised actors — utilities, heavy industry | ETS |
| **Buildings & transport** | buildings + transport | costs land on households, visibly and immediately | ES and "other" |

Each sector gets its own ranking u and its own strength k(t). REMIND needs the two reconciled:

| `cm_pfmSectorMarkup` | delivery | rows |
|---|---|---|
| 0 | collapse to `min(φ_Bulk, φ_Diffuse)` — one price, the worse sector wins | the markup-off variants (not in the `v8` batch) |
| 1 | floor + markup: `pm_taxCO2eq` = the worse sector, `pm_taxemiMkt(m)` = market *m*'s own increment over it | every coupled row |

**Buildings & transport binds in most EU21 regions** on `v8` (§6.2a): in **15 of 21 EU21 regions** (power & industry
in 4, ties in REF and NEN) and in 5 of 12 H12 regions (power & industry in 6, REF tied). `v7` was split (9 / 11). It
moves with the frontier error structure (`MODEL.md` §3.4.1): treat it as a property of the specification, not of the
regions.

### 1.2 Two closures: hold the price, or hold the budget

The level cap caps each region's price at current policy plus φ times the extra effort,
P = min(A, P_ref + φ · max(A − P_ref, 0)). What REMIND may do in response defines the closure:

| closure | rows | anchor | budget | the sentence it produces |
|---|---|---|---|---|
| **hold the price** | `-PFM-holdPrice…` | pinned to the θ = 0 run's converged anchor (`cm_pfmAnchorFromGdx`) | not enforced | "political feasibility adds X Gt CO₂ to the 1000 Gt pathway by 2100" — the **quantity headline** |
| **hold the budget** | `-PFM-holdBudget…` | rises until the budget holds; the cap is rebuilt every iteration (`cm_pfmBoundRebuild = 1`) | enforced | "the budget holds, and abatement moves between regions" |

**No adjustment speed λ** (ADR 0050). The gap is read at the anchor year and held (moved by the rents in buildings &
transport); the only declared gap-closure assumption is the erosion rate κ, run as a sensitivity.

---

## 2. The scenario map

**The file is generated, not hand-written** (ADR 0055): edit the matrix, rebuild, commit both.

```bash
Rscript analysis/run-groups/buildPFMScenarioConfig.R analysis/run-groups/scenario-matrix-v8.yml
#   -> models/remind_pfm/config/scenario_config_PFM_v8.csv, then the validator and REMIND's own reader
```

Every row is REMIND's canonical scenario plus named deltas; every coupled row carries
`cm_taxCO2_regiDiff = 11`, `cm_pfmPhiPath = 1` (the share path), `cm_pfmGapClosure = 0` (no λ),
`cm_pfmSectorMarkup = 1`, `pfmPhiStrength = regional`, `pfmInstitutions = gapclosure`, and
`cm_taxCO2_lowerBound_path_gdx_ref = 0` (§6.3). H12 titles carry no resolution infix; EU21 titles carry `-EU21-`;
coupled titles end in `-v8` and carry the labels of §2.6. **Every coupled row starts from the no-politics reference**
(`@noPolitics`), except the chain steps, which start from the step before them: on `v7`, five hold-the-budget rows did
not peak from a cold start and two more from a politics start (`PITFALLS.md` §26).

### 2.1 Uncoupled baselines (REMIND 3.7.1, shared with `v6`–`v7`)

| run | why it exists |
|---|---|
| `SSP2[-EU21]-NPi2025` | current policies: the reference price P_ref, and the `path_gdx_ref` of every other row |
| `SSP2[-EU21]-PkBudg1000` | REMIND's own 1000 Gt cost-optimal answer |
| `SSP2[-EU21]-PkBudg1000-PFMgateRef` | the uniform-price reference: the interface check (§3.1) |

### 2.2 No-politics references — the mechanism installed but switched off

| run | switched off how | the control for |
|---|---|---|
| `-PkBudg1000-PFM-noPolitics-holdBudget-v8` | present, θ = 0, budget enforced | hold the budget; must reproduce `-PFMgateRef` |
| `-PkBudg1000-PFM-noPolitics-holdPrice-v8` | present, θ = 0, budget forcing off, **anchor pinned to the run above** | hold the price (the quantity headline); must reproduce it |

### 2.3 The batch (`V8W1EU21`, `V8W1H12`; the chain steps `V8SEQEU21`, `V8RERUNEU21`)

| section | rows (both closures each) | varies | resolutions |
|---|---|---|---|
| the headline and θ | central; `-theta325`, `-theta675` | `cm_pfmTheta` | EU21, H12 |
| strength | `-commonStrength` (`v7`'s form); `-gapFirst` (the meeting's order of steps) | `pfmPhiStrength` | common: both; gap first: EU21 |
| rents | `-rentsWorldPrice` (REMIND's rents at the world price) | `pfmRentsPrice` | EU21, H12 |
| persistence | `-constantLimit`, `-growingLimit`, `-erosion2`, `-erosion2p7`, `-erosion5`, `-erosionHistorical` | `pfmPhiHold`, `pfmPhiKappa` | EU21 (2.7% also H12) |
| institutions | `-institutionsHeld`, `-institutionsAndrijevic`, `-institutionsStoryline` | `pfmInstitutions` | held, Andrijevic: both; storyline: EU21 |
| the shrinking future | `-shrinkingFuture2030` … `-shrinkingFuture2070`, two chains of five | `cm_startyear`, `path_gdx_ref`, `pfmPhiWindowEnd`, `cm_pfmRefPrice` (`COUPLING.md` §14.1) | EU21 |

**Not re-run on `v8`** (their earlier readings are in the archived documents and are not `v8` numbers): the ranking
(uniform, permuted, reversed), the uncovered countries (all-median, all-low, nearest donors, USA), the markup-off and
proportional-mode rows, the curve shape and the specification family, the annual rung, drivers stopping in 2060, and
the theory-gate sensitivities (selected `v7`'s specification unchanged; `MODEL.md` §2.4a).

### 2.5 Running them

```r
library(pfm)
cfg <- "config/scenario_config_PFM_v8.csv"
submitPFM("V8W1EU21", remindDir = "models/remind_pfm-EU21", scenarioConfig = cfg, slurmConfig = "standby")      # dry run
submitPFM("V8W1EU21", remindDir = "models/remind_pfm-EU21", scenarioConfig = cfg, dry = FALSE, slurmConfig = "standby")
```

`slurmConfig` is required in the dry run too. A tag of its own for a re-run (`V8RERUN<res>`) or a later wave
(`V8SEQEU21`), so a re-submission never re-runs a batch. A start group never mixes resolutions: the H12 rows run from
the `-H12` checkout, the EU21 rows from `-EU21`. `submitPFM` runs a preflight first (repos clean and pushed, packages
installed, groups exported, mappings, the replay control) and refuses on any failure. `RUNNING.md` Step 7 (v8), which
also records the two fixes the chains needed and the manual restart of a chain step (`PITFALLS.md` §41).

### 2.5a How an unfinished run earns its place

🔴 **An unfinished run's `fulldata.gdx` is complete and reports success** (`PITFALLS.md` §25).
`analysis/coupled/extractCoupledResults.R` admits an unfinished run only if **zero market-year cells
through 2060 exceed REMIND's own `p80_surplusMaxTolerance`**, and records the reason in
`$admittedUnfinished`. **In the final `v8` batch every run finished and none needed admitting.** Where a scenario was
re-run, the newest run is admitted and the older one is flagged `superseded`. Copies taken while a run was still
iterating were replaced by the finished runs.

### 2.6 Run names and the labels the documents use

Up to `v7`, run titles, start tags and config switches keep their original names (the letters B = hold the price,
C = hold the budget; `../_archive/_wip/LABELS-2026-10-12.md`). **From `v8` on, the titles carry the labels**
(`scenario-matrix-v8.yml`). The analysis scripts translate each title to the internal key of the left column in one
place, `analysis/coupled/_runKey.R`, so every script reads every group. The artifacts keep the run's own title in
`title` and the key in `scenario`.

| `v8` title part | label | internal key |
|---|---|---|
| `-PFM-noPolitics-holdBudget` / `-PFM-noPolitics-holdPrice` | no-politics reference (θ = 0), budget held / price held | `-PFMgate` / `-PFMgateBfix` |
| `-PFM-holdPrice` / `-PFM-holdBudget` | **hold the price** / **hold the budget** | `-PFMlevelBfix` / `-PFMlevelC` |
| no further suffix | **fading limit**, regional strength, gap-closure institutions, θ = 0.50: the headline | — |
| `-theta325`, `-theta675` | severity θ = 0.325, 0.675 | `Th325`, `Th675` |
| `-constantLimit`, `-growingLimit` | **constant limit** (k ≈ 1) / **growing limit** (tightens 0.5% a year) | `-Ehold`, `-backslide` |
| `-erosion2`, `-erosion2p7`, `-erosion5`, `-erosionHistorical` | **fading + erosion** 2% / 2.7% / 5% a year / the historical per-sector rates (1.1% / 4.6%, measured on `v7`; on `v8` 0.7% / 5.7%, `MODEL.md` §5.2a) | `-kappa02`, `-kappa`, `-kappa05`, `-kappaHist` |
| `-commonStrength`, `-gapFirst` | the world's strength (`v7`'s form) / gap first | `-common`, `-gapfirst` |
| `-rentsWorldPrice` | REMIND's rents at the world price | `-rentsWorld` |
| `-institutionsHeld`, `-institutionsAndrijevic`, `-institutionsStoryline` | institutions held at 2023 / Andrijevic's government effectiveness / the previous storyline rule | `-held`, `-gcA`, `-story` |
| `-shrinkingFuture2030` … `-shrinkingFuture2070` | a step of the **shrinking future**; 2070 is the chain's result | `-seq2030` … `-seq2070` |
| `-EU21-` infix / none | 21 regions with the EU split / 12 regions (H12) | — |

---

## 3. Did the runs work?

| check | `v8` batch (66 runs) |
|---|---|
| solve status | `o_modelstat = 2` in **66 of 66** |
| finished | **66 of 66**; none admitted unfinished |
| early-period markets (≤ 2060) | **zero cells over tolerance**; worst 0.94× (EU21 `-PFMgateRef`) |
| PFM converged | final change in the share path **≤ 0.0020** in every run, against `cm_pfmConvTol = 0.002` |
| PFM calls | **2 to 20** per coupled run (20: EU21 hold the budget, gap first, 93 iterations) |
| iteration cap | **no run ends at `cm_iteration_max`** |
| budget (hold the budget) | **held in every budget-forced run**: cumulative CO₂ to 2100 995.9–1002.0 Gt (EU21), 995.1–1001.7 (H12) |
| budget peak | every hold-the-budget run peaks by 2100 (most in 2090) **except EU21 `-holdBudget-growingLimit`**, which meets the budget at 2100 (1000.1 Gt) and has not peaked (§3.4). Every hold-the-price run is unpeaked by design |
| infeasibility code | `pm_pfmInfesCode = 0` in every coupled run |
| legislated floor | `cm_taxCO2_lowerBound_path_gdx_ref = 0` in every row |
| cache read | to be confirmed on the cluster (`RUNNING.md` Step 8) and recorded in `records/v8/` |

### 3.1 The interface gate — a tolerance, not bit-identity

`-PFM-noPolitics-holdBudget-v8` (θ = 0, mechanism present) against `-PFMgateRef` (mechanism absent), same REMIND
version (`gate-ref-compare.rds`):

| resolution | `pm_taxCO2eq` cells 2030–2100 | differing | max difference | cum. CO₂ to 2100 |
|---|---:|---:|---:|---|
| EU21 | 231 | 231 | \$2.27 (2100) | 1001.46 vs 1000.91 Gt |
| H12 | 132 | 132 | \$4.17 (2100) | 1001.69 vs 1000.81 Gt |

φ and the share path are exactly 1 in both no-politics references, so it is not the political layer. The difference
is **identical across all regions in every year** (EU21 −0.17% in 2030 to −0.48% in 2100; H12 −0.35% to −0.85%): one
global path, a slightly lower price level at which REMIND's budget loop stopped, within its tolerance (cumulative
CO₂ within 0.9 Gt). The price difference is outside the gate's \$1 limit and the cumulative difference outside its
0.2 Gt limit; on `v7` EU21 was bit-identical and H12 failed the same way (\$0.41). **Disclosed**, the limits not
re-tuned. **Do not write "bit-identical"**.

**The hold-the-price pinning.** `-PFM-noPolitics-holdPrice-v8` reproduces `-PFM-noPolitics-holdBudget-v8` within 5 Gt:
**+3.3 Gt** at EU21 (1004.8 Gt) and **+2.5 Gt** at H12 (1004.2 Gt). If a future re-run moves this by more than a few
Gt, the pinning failed and §4.2a is not interpretable.

> ⚠️ The gate is **structurally blind** to defects that only exist at θ > 0. It proves the
> plumbing, nothing else; §3.3 is the real test.

### 3.2 Convergence — on the whole share path

Convergence is checked on the share **path**: at each PFM call the largest change in φ over the
checkpoint years 2035, 2050, 2070 and 2100, against 0.002, after at least two calls; two successive
moves in opposite directions are damped (α = 0.5) rather than the tolerance loosened. Every run
converged: final change ≤ 0.0020. With the rents in the buildings & transport distance, φ also follows REMIND's
fossil income, a second feedback (`MODEL.md` §8.2); it did not prevent convergence.

### 3.3 φ and the markup reach the solver

- The share path is loaded in every θ > 0 run, with the formulation `v6-anchor` in its history, and φ < 1 somewhere.
- **Markup written vs seen.** One H12 hold-the-budget run (`-theta325`) differs by 0.001; the markup moved in the final
  iteration. The `markupMismatch` list in `coupled-facts.json` is a "still moving" flag, not an erasure
  (`PITFALLS.md` §16).
- **Markup liveness.** A run whose markets' shares differ but whose markups are all zero aborts
  (`45_carbonprice/functionalForm/presolve.gms`). It caught the hold-the-budget chain step of 2040, whose rebuilt cap read
  the wrong reference price (fixed by `cm_pfmRefPrice`, `COUPLING.md` §14.1).

### 3.4 Re-runs and settling

**Every hold-the-budget run started from the no-politics reference peaks by 2100**, the `v7` failures included
(erosion 2% now peaks in 2090).

- **The growing limit does not peak**, as on `v7`. It meets the budget at 2100 (1000.1 Gt), and cumulative CO₂ then
  rises (1055 Gt by 2150). Under a limit that tightens without end the constrained regions' share keeps falling after
  2100, so the budget is met at 2100 and not held after it. **Disclosed, not re-run.** Quote its hold-the-budget numbers
  to 2100 with this note; its hold-the-price result is unaffected.
- **Copies taken mid-run** (hold the budget, gap first and erosion 2%; the last hold-the-budget chain step) were
  replaced by the finished runs before every number here.

**Settling** (`convergence-audit.rds`, the price range over the last ten iterations). H12 hold the budget with the
common strength was still moving (17.4%), ending within 2 Gt of the budget: quote it with that note. Everything else
moved less than 7% (H12 erosion 2.7% 6.1%, the EU21 no-politics hold-the-budget reference 5.2%, EU21 constant limit 5.0%,
the EU21 headline 3.6%).

---

## 4. What the results say

Cumulative figures are `pm_actualbudgetco2("2100")` in Gt CO₂; prices are 2050, \$2005/tCO₂, and name their market.
Price ratios are "× the θ = 0 run" (`-PFM-noPolitics-holdBudget-v8`).

### 4.2a The quantity headline — the cap on the price path that holds the budget

Both runs read the anchor the no-politics hold-the-budget run converged to and switch budget forcing off, so the
no-politics reference meets the budget (§3.1, the pinning) and the difference is the extra CO₂ the ceiling adds to the
1000 Gt pathway.

| | EU21 | H12 |
|---|---:|---:|
| `-PFM-noPolitics-holdPrice-v8` (θ = 0) | 1004.8 | 1004.2 |
| **`-PFM-holdPrice-v8`** (θ = 0.50) | **1079.9** | **1068.5** |
| **Δ at θ = 0.50** | **+75.1** | **+64.3** |
| Δ at θ = 0.325 / 0.675 | +44.4 / +109.8 | +39.4 / +95.1 |
| slope | **161 Gt per unit θ** | **139 Gt per unit θ** |
| institutions held | +85.5 | +70.3 |
| constant limit | +123.8 | — |
| bind share (last iteration) | 0.939 | 0.994 |
| power & industry strength k 2050 / 2100 | 0.632 / 0.727 | 0.629 / 0.724 |
| buildings & transport strength k 2050 / 2100 | 0.624 / 0.494 | 0.622 / 0.493 |

**Political feasibility adds about 65–75 Gt CO₂ to the 1000 Gt pathway by 2100** at the central severity, 39–110 Gt
across the declared θ range. The two resolutions agree within 15%.

**Net CO₂ in 2100** (`analysis/checks/emissions2100.R v8` → `emissions-2100.rds`; global, Gt CO₂ a year):

| | EU21 | H12 |
|---|---:|---:|
| no-politics reference (θ = 0) | 0.18 | −0.09 (net zero in 2100) |
| θ = 0.325 / **0.50** / 0.675, fading limit | 0.72 / **1.28** / 1.63 | 0.67 / **0.94** / 1.46 |
| institutions held | 1.42 | 1.06 |
| constant limit | 1.91 | — |

No hold-the-price run reaches net zero by 2100. In 2050 the fading limit emits 10.2 / 10.2 Gt a year against 8.9 / 9.0
in the no-politics reference.

- **Holding institutions at 2023 adds 10.3 / 5.9 Gt** (`v7`: −0.4 / +0.7): under gap closure the projected
  institutions take about a tenth off the overshoot. The headline still does not rest on them.
- **The cap binds almost everywhere** (bind share 0.94 / 0.99).
- **The power & industry strength rises again after 2050** (0.63 → 0.73), where `v7`'s fell; buildings & transport falls
  throughout.
- **Emissions keep accumulating to 2100** in every hold-the-price run: that is what "the budget is not enforced"
  means. Quote the 2100 cumulative, never a peak, for this family.

### 4.3 Hold the budget — the budget holds under the cap

Every admitted hold-the-budget run holds the budget (§3). What the cap changes is where the price and the abatement
sit. The anchor rises to make up for the capped regions; in 2050, against the θ = 0 run:

| | EU21 anchor | EU21 median region | H12 anchor | H12 median region |
|---|---:|---:|---:|---:|
| θ = 0.325 | 1.092 | 1.066 | 1.083 | 1.029 |
| **θ = 0.50** | **1.157** | **1.109** | **1.138** | **1.052** |
| θ = 0.675 | 1.226 | 1.149 | 1.206 | 1.082 |
| institutions held | 1.171 | 1.120 | 1.158 | 1.076 |
| constant limit | 1.267 | 1.159 | — | — |
| growing limit (not peaked after 2100, §3.4) | 1.368 | 1.232 | — | — |
| fading + erosion 2% / 2.7% / 5% | 1.078 / 1.063 / 1.033 | 1.055 / 1.044 / 1.023 | — / 1.065 / — | — / 1.024 / — |
| fading + historical erosion rates | 1.082 | 1.062 | — | — |
| common strength / gap first | 1.156 / 1.112 | 1.096 / 1.090 | 1.139 / — | 1.060 / — |

The cheapest region in 2050 is REF at both resolutions (×0.81 EU21, ×0.80 H12); the dearest is a northern European
region (NEN at EU21, NEU at H12, at the anchor's ratio).

> ⚠️ **Do not compare the regional median across resolutions.** 11 of EU21's 21 regions are European, so the EU21
> median is close to a European price. Quote hold the budget by the abatement moved (§4.8) or the emissions-weighted
> price (×1.02 EU21, ×1.04 H12, `held-budget-prices-levelC.rds`; 7 of 42 and 8 of 24 markets are below the
> no-politics price).

**Reading.** Hold the budget is not "the budget cannot be held". It is "the budget holds, the global price
rises by about a sixth, and the capped regions' share of the effort moves elsewhere" (§4.8).

### 4.6 The θ sweep

Quantity headline: **+44.4 / +75.1 / +109.8 Gt** at EU21 and **+39.4 / +64.3 / +95.1 Gt** at H12 for
θ = 0.325 / 0.50 / 0.675 — 161 and 139 Gt per unit θ, steeper above 0.50. Hold the budget: the anchor goes ×1.092
→ 1.157 → 1.226 (EU21). The sweep is declared; none of its points is an estimate. Figure: `v6-coupled-theta` (built for
any group from `v6` on).

### 4.8 Where abatement goes, and what it costs in GDP

`coupledCostsAndAbatement.R` → `coupled-costs.json`: regional `vm_co2eq`, `vm_cesIO` ("inco") and
`vm_cons` over 2020–2100, each run against its matched no-politics reference (θ = 0); money discounted at 5%/yr.
**Relocated** is half the sum of the absolute regional changes — the volume that moved, not the net.

| | net Δ CO₂eq | relocated | ρ(φ, relative change) | GDP | consumption |
|---|---:|---:|---:|---:|---:|
| **hold the budget** EU21 / H12 | **−4.6 / −2.6** | **20.6 / 17.9** | −0.17 / −0.10 | +0.011% / +0.001% | −0.005% / −0.005% |
| hold the budget, constant limit EU21 | +0.8 | 29.3 | −0.34 | +0.009% | −0.003% |
| hold the budget, growing limit EU21 | +0.0 | 41.1 | −0.37 | −0.016% | −0.015% |
| hold the budget, erosion 2% / 2.7% / 5% / historical EU21 | −4.1 / −3.7 / −1.3 / −3.6 | 9.7 / 7.5 / 4.8 / 11.6 | −0.13 / −0.14 / −0.14 / −0.04 | | |
| hold the budget, gap first EU21 | −2.2 | 36.3 | −0.08 | +0.010% | −0.007% |
| **hold the price** (quantity headline) EU21 / H12 | +79.7 / +68.2 | 41.5 / 34.8 | −0.37 / −0.60 | +0.12% / +0.10% | +0.14% / +0.11% |

**Under hold the budget the ceiling moves abatement rather than reducing it**: the net change is a few Gt while about
20 Gt changes region. Hold the budget, EU21 / H12: **REF +9.9 / +11.1, SSA +6.4 / +3.3, USA +1.8 / +1.5; MEA −8.9 /
−6.2, CHA −4.3 / −4.3, OAS −3.5 / −3.7**. The sign agrees across the resolutions for these regions. The correlation
with φ is weak on `v8` (−0.17 / −0.10; `v7` −0.49 / −0.63): the regional strength lets a region's constraint fade on its
own path, so the 2025 ranking predicts less of where the effort goes. **The Middle East gives abatement** because its
buildings & transport constraint fades with its rents (`MODEL.md` §3.1a). With the constant limit, under which the
rents do not act, the relocation rises to 29.3 Gt and returns to the `v7` pattern: REF +23.7, MEA +3.9, IND +2.1; CHA
−10.1, SSA −7.4. **The relocation follows the persistence of the limit**: 41.1 (growing), 29.3 (constant), 20.6
(fading), 11.6 / 9.7 / 7.5 / 4.8 Gt (historical / 2% / 2.7% / 5% erosion) at EU21. Gap first moves 36.3 Gt, most of it
from MEA (−20.2) to SSA (+25.0).

**Under the cap, the extra emissions land** (EU21, hold the price) in SSA +24.4, REF +14.7, MEA +14.5 and OAS +8.2 Gt
CO₂eq (H12: SSA +17.6, REF +16.2, MEA +13.5, OAS +6.2).

> 🔴 **GDP rises, and that is not a benefit.** REMIND carries no climate damages, so any run that
> abates less looks richer. Quote it only in the same sentence as the extra CO₂, or not at all.
> Regional GDP is not reported.

### 4.9 The sensitivity runs — what the quantity headline is sensitive to

Hold the price, θ = 0.50, extra cumulative CO₂ by 2100 (fading limit, the headline: **+75.1 Gt** EU21, **+64.3 Gt**
H12). Each sensitivity run records the options its last PFM call ran with (`coupled-facts.json` `arms`); a recorded
option that differs from the declared one would make the run unusable, and none does.

| sensitivity run | EU21 Δ Gt | vs fading limit | H12 Δ Gt | reading |
|---|---:|---:|---:|---|
| growing limit (tightens 0.5% a year) | +159.9 | +84.8 | — | the worse-than-today side, a bound (ADR 0057): 2.1 times the headline |
| constant limit, k ≈ 1 | +123.8 | +48.7 | — | the moving strength removes 39% of the constant-limit result |
| **fading limit (the headline)** | **+75.1** | — | **+64.3** | |
| common strength (`v7`'s form) | +75.5 | +0.4 | +63.4 | the regional form redistributes, it does not change the total |
| world-price rents | +73.5 | −1.6 | +63.7 | the valuation of REMIND's rents barely matters |
| institutions: held / Andrijevic / storyline | +85.5 / +82.4 / +83.9 | +10.4 / +7.3 / +8.8 | +70.3 / +71.5 / — | gap closure is the most favourable of the institution rules |
| gap first | +55.0 | −20.1 | — | the meeting's order of steps, with the 2023 range held |
| **fading + erosion 2% / 2.7% / 5% a year** | +34.7 / **+29.4** / +19.3 | −40.4 / −45.7 / −55.8 | 2.7%: **+23.0** | **the largest effect**: at the central κ, 39% / 36% of the headline is left |
| fading + historical erosion rates (1.1% / 4.6%) | +38.9 | −36.2 | — | the declared rates bracket the historical one |
| **the shrinking future** (chain result, §4.11) | **+39.4** | −35.7 | — | expectations: each decade expects the limit to lift |

**The persistence ladder** (`coupled-facts.json` `arms`; figure `v6-coupled-arms`): growing → constant → fading →
historical erosion → erosion 2% / 2.7% / 5% orders the headline monotonically, from +160 to +19 Gt at EU21, an eightfold
range, against a θ range of +44 to +110. As on `v6` and `v7`, **whether the limit erodes by itself is the assumption the
result rests on most**; θ and expectations (§4.11) are next. Net CO₂ in 2100 follows (`emissions-2100.rds`): 2.85 Gt a
year with the growing limit, 1.91 constant, 1.28 fading, 0.73 historical, 0.36 / 0.29 / 0.58 with erosion 2% / 2.7% /
5% (EU21; H12 erosion 2.7%: 0.04), against 0.18 in the no-politics reference; no hold-the-price run reaches net zero
by 2100.

The EU21 hold-the-budget run with the growing limit meets its budget at 2100 but does not hold it after (§3.4); its
numbers in §4.3 and §4.8 are quoted with that note. The hold-the-price ladder is unaffected.

### 4.10 Against `v7`

Each headline against its own version's no-politics reference (θ = 0), on the same REMIND 3.7.1 bases.

| | `v7` EU21 / H12 | `v8` EU21 / H12 |
|---|---|---|
| quantity headline, θ = 0.50 | +98.8 / +87.9 | **+75.1 / +64.3** |
| slope per unit θ | 212 / 185 | 161 / 139 |
| constant limit | +167.6 / +145.3 | +123.8 / — |
| erosion 2.7% | +35.5 / +31.9 | +29.4 / +23.0 |
| institutions held minus headline | −0.4 / +0.7 | +10.3 / +5.9 |
| hold the budget anchor 2050 | ×1.206 / ×1.185 | ×1.157 / ×1.138 |
| hold the budget abatement relocated | 17.1 / 18.4 | **20.6 / 17.9** |
| hold the budget: REF / MEA / SSA / China (EU21) | +7.1 / +4.7 / −5.0 / −4.9 | +9.9 / −8.9 / +6.4 / −4.3 |

**The quantity headline shrinks by a quarter.** The causes are the `v8` estimation (ADR 0062): the covered-median
coverage rule compresses the ranking (OAS, MEA, LAM and SSA no longer carry low-band countries), the saturating and
bounded fossil terms change the low end, and gap-closure institutions now take a tenth off the overshoot.

**The relocation changes composition.** REF is still the most constrained region in both sectors and takes more. The
Middle East switches side: its fossil rents fall along the pathway, its buildings & transport distance below the
ceiling shrinks, and under the regional strength that loosening stays with it. Sub-Saharan Africa, now at the covered
median rather than in the low band, takes on emissions. **"China absorbs" remains a constant-limit result** (−10.1 Gt).

### 4.11 The shrinking future — politics decade by decade

The sequential runs of `COUPLING.md` §14.1 (`MODEL.md` §5.6a): a chain of five coupled runs per closure, one per decade
from 2030 to 2070. Each step fixes its past to the step before, applies the limit only to its own decade, and plans the
rest as if the limit lifted; the last step (2070) leaves its window open and is the chain's result. EU21, θ = 0.50
(`analysis/v8/shrinkingFuture.R v8` → `shrinking-future.rds`; three figures; design note 0009 §22).

| cumulative CO₂ 2020–2100 | no-politics | one-shot run | chain (2070 step) | chain − one-shot |
|---|---:|---:|---:|---:|
| hold the price | 1004.8 | 1079.9 (**+75.1**) | 1044.2 (**+39.4**) | −35.7 |
| hold the budget | 1001.5 | 996.1 | 996.3 | +0.2 |

- **Hold the price: half the overshoot, at the same prices paid.** The emissions-weighted mean price is 193 against 191
  \$/t CO₂ in 2050 and 407 against 407 in 2100, and φ in each decade is within ±0.005 of the one-shot run's. Emissions
  are lower in every decade (2030–2040: 296.8 against 299.8 Gt; 2070–2100: 43.6 against 54.3). Each step invests for the
  full price it expects after its decade (capital, learning), and the next step inherits that energy system: an
  **expectation channel** the one-shot run does not have.
- **Every step under-promises.** The plans for 2100 rise step by step, +7.5, +11.5, +20.8 and +24.6 Gt above the
  reference, and the result is +39.4: a pathway read at its start year overstates what its politics will deliver.
- **Hold the budget: the effort moves later.** The chain emits 5.8 Gt more than the one-shot run in 2030–2060 and 5.9 Gt
  less after. Its price is lower to 2070 and higher after (2050: 201 against 221 \$/t; 2100: 535 against 500), and net
  CO₂ in 2100 is −0.84 against −0.43 Gt a year. The end-loading is moderate: the chain stops in 2070, and the 1000 Gt
  budget leaves the last step room.
- **Cost:** GDP / consumption against the reference, hold the price: one-shot +0.12% / +0.14%, chain +0.08% / +0.10%
  (it abates more); hold the budget: chain +0.05% / +0.04% (one-shot +0.01% / −0.01%).
- **Reading.** The one-shot run assumes the limit is known to last; the chain assumes, every decade, that it will lift
  after the next. They bracket expectations about politics at +39 to +75 Gt under hold the price. REMIND has perfect
  foresight within each step, so the expectation effect is as strong as that foresight. One θ, EU21, ten-year steps;
  version A (the limit known for the whole remaining horizon at each step) and five-year steps are open. The note for the
  meeting of 3 November: `../communication/2026-11-shrinking-future/`.

---

## 5. Limitations — read this before quoting anything

1. **θ and κ are declared, not estimated.** θ carries the main-text band; the persistence of the limit moves the
   headline more than θ does, from +160 (growing) to +19 Gt (erosion 5%) at EU21 (§4.9). Neither may be presented as a
   finding.
2. **Expectations are a choice of the experiment.** The one-shot run and the shrinking future bracket the headline at
   +75 and +39 Gt (§4.11); neither is the "true" belief, and REMIND's perfect foresight within each step sets the size of
   the effect.
3. **The specification is selected for the hypotheses** (ADR 0059): the theory gate requires H1–H2. The coupled numbers
   are conditional on a specification chosen in part for its significance; say so with the headline (`MODEL.md` §2.4a).
   **The buildings & transport contingency passes the gate on the asymptotic $p$ only** (`MODEL.md` §2.5).
4. **The power & industry γ margin is 0.0001** (0.9989 against the gate's 0.999; `MODEL.md` §3.4): `v7`'s form with the
   bound crossed it.
5. **The historical-replay gate fails narrowly in buildings & transport** (skill −0.018 against the uncoupled ECM;
   `MODEL.md` §8.4). The gate cannot discriminate on history (the ceiling binds in under 3% of rows); disclose it.
6. **One region per resolution is pinned by the parameter, not by data.** φ = 1 − θ·k(t) exactly for the region at
   u = 1: **REF** in both sectors at both resolutions. φ is a *ranking* (§6.2).
7. **Legislated prices may be rolled back in every run** (§6.3), and rarely are: from 2030 to 2100 both market prices
   sit below the current-policy reference in 1.7% of region-years under hold the price at EU21 (0.8% at H12) and 0.4%
   under hold the budget (0.8% at H12).
8. **The co-evolution feedback is real and not causal.** The coupled strength moves with REMIND's energy system and, in
   buildings & transport, with its fossil rents (part of which fall in the current-policy world too). Call it
   conditional scenario accounting (`MODEL.md` §8.1–8.2).
9. **The uncovered countries are at the covered median.** The rule is tested out of sample (`MODEL.md` §5.4) but not
   coupled against its alternatives on `v8`; the `v6` coupled band (110–155 Gt) is not a `v8` number. The United States
   has no covered country and is at the median.
10. **The interface gate is verified to a tolerance**: the no-politics hold-the-budget reference sits 0.5 / 0.9 Gt from
    the uniform-price reference, by a uniform price shift (§3.1, disclosed).
11. **EU21 hold the budget with the growing limit** meets the budget at 2100 but does not peak (§3.4); H12 hold the
    budget with the common strength was still settling.
12. **Every φ is conditional on modelling choices the data do not settle** — the specification family, the frontier
    error structure (`MODEL.md` §3.4.1), the institution projections, the hold rule, the strength form. No φ here is a
    measured property of a region.
13. **Which sector binds** is a property of the specification and the frontier rung (§6.2a): do not write it as a fact
    about regions.

---

## 6. Diagnosis: mechanisms that shape every result

### 6.1 The reference path is the hidden driver

The level cap acts on the *increment* over the current-policy price `SSP2[-EU21]-NPi2025` (REMIND
3.7.1, shared with `v6`–`v7`). Its 2050 price, the higher of the two markets:

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

Regions with near-zero reference prices have almost all of their cost-optimal price exposed to φ — including the most
constrained region, REF.

**The US reference is negative by REMIND's input, not by the coupling.** REMIND's `NPi2025` realization
(`45_carbonprice/NPi2025/datainput.gms`) holds the price from 2030 at the input value
`fm_taxCO2eqHist("2030")` for the USA and SSA, and the input data (revision 8.24) give the USA **−\$6.16**
(after \$24.6 in 2020 and \$12.3 in 2025; SSA \$5.71). Under the level cap the US increment is therefore $A + 6.2$,
and $P^{*} = -6.2 + \varphi\,(A + 6.2)$. Quote any US number with its reference: "against a current-policy path that
turns the US carbon price slightly negative from 2030". The same reference is $P^{\text{ref}}$ of every shrinking-future
step (`cm_pfmRefPrice = refpolicycost`).

### 6.2 Why φ = 1 − θ·k for some regions — it is a *ranking*, not a capability

```
phi_{r,s}(t) = 1 - theta * k_{r,s}(t) * u_{r,s}       u = (gap - gap_min) / (gap_max - gap_min), at 2023
```

`u` is the region's **position between the best and worst region**, per sector, read once at the
anchor year. The largest gap is handed u = 1, the smallest u = 0; **both endpoints are guaranteed by
construction**. In 2025 (k = 1) φ = 0.50 at θ = 0.50 means "ranked last"; later φ moves as the region's own k(t) moves.

In the batch (`-PFM-holdPrice-v8`, θ = 0.50, the 2025 share, the worse sector): **EU21** floor **REF**, then ECE 0.65 and
ECS 0.70; top **NEN 1.00**, median 0.77; **H12** floor **REF**, then MEA 0.76 and OAS 0.77; top **CHA 0.93**, median
0.81. The ranking compressed against `v7` (`MODEL.md` §5.2): fewer regions sit near the floor.

**For the paper.** Do not write "Russia can only sustain 50% of the cost-optimal price". Write "this region ranks at
the bottom of the feasibility distribution in both sectors; how far below the rest is set by θ, a parameter we
declare."

### 6.2a Which sector binds, at region level

From `p45_pfmPhiMkt` of `-PFM-holdPrice-v8` (the 2025 share):

| | Buildings & transport binds | Power & industry binds | tie |
|---|---:|---:|---:|
| **EU21 regions** | **15** — ENC, NES, MEA, SSA, EWN, ECS, CHA, ECE, FRA, DEU, UKI, IND, JPN, ESW, USA | **4** | REF, NEN |
| **H12 regions** | **5** — EUR, NEU, MEA, JPN, USA | **6** | REF |

The clearest cases:

| region | ES (buildings & transport) φ | ETS (power & industry) φ | binds |
|---|---:|---:|---|
| Non-EU S. Europe (NES, EU21) | **0.702** | 0.969 | **buildings & transport**, by 0.267 |
| West-North Europe (EWN, EU21) | **0.703** | 0.932 | **buildings & transport**, by 0.229 |
| Canada/Australia/NZ (CAZ, H12) | 1.000 | **0.838** | **power & industry**, by 0.162 |
| Other Asia (OAS, H12) | 0.907 | **0.765** | **power & industry**, by 0.142 |
| Russia & reforming (REF) | **0.500** | **0.500** | both at the floor |

**This depends on the frontier error structure and the weights** (`MODEL.md` §3.4.1): offline, with GDP weights,
power & industry binds in 5 / 3 / 4 / 12 of 20 EU21 regions across the four frontier rungs, and 13 of 20 change
binding sector. A sector φ of exactly 1.000 is a ceiling clamp, not a measurement — do not report "Canada's buildings
and transport face no political constraint". Never quote a country-level figure for a coupled regional result.

### 6.3 The legislated price floor is off in every run

`cm_taxCO2_lowerBound_path_gdx_ref` defaults to **on**, and
`45_carbonprice/functionalForm/postsolve.gms` applies

```gams
pm_taxCO2eq(t,regi) = max(pm_taxCO2eq(t,regi), p45_taxCO2eq_path_gdx_ref(t,regi));
```

inside the `cm_iterative_target_adj eq 5/7/9` block. **It is 0 in every `v8` row** (the matrix sets it
on both parents), so prices below the reference path are permitted. **Methods must say which policy
world this is**, in one sentence: a feasibility ceiling that cannot bind below legislated policy would
be legislation plus a ceiling; a model that lets a region abolish its ETS is also a choice. In a shrinking-future step
`path_gdx_ref` is the previous step, which is one more reason the floor must stay off there.

### 6.4 The level-cap ratchet — fixed, confirmed absent

A past defect: the level cap read the optimal price from the run's own already-capped
`pm_taxCO2eq`, collapsing the bound onto the reference within 3–4 calls. `iterativePFM.R` takes it
from `p45_taxCO2eq_anchor`. **Confirmed absent on `v8`**: the lowest 2050 market price under hold the price is
\$138.1 (REF, EU21; \$135.0 H12), against REF's \$4.0 reference.

---

## 7. Needed improvements, in priority order

1. ✅ **The paper's basis is `v8`** (author, 2026-11-01): the paper's claims, Methods and outline are on `v8`
   (`papers/pfm-paper-v6/docs/claims.md`, `methods-v8.md`, `paper-outline-v8.md`).
2. 🟢 **The shrinking future after the meeting of 3 November**: version A as a check, five-year steps, the θ range and
   H12 if it goes into the paper.
3. 🟢 **The coupled figures on `v8`**: `v6-coupled-theta`, `v6-coupled-arms`, `v6-rulec-relocation` and
   `v6-price-catchup` build for any group from `v6` on; the shrinking-future figures are drawn by
   `analysis/v8/shrinkingFuture.R` and are not yet in the registry.
4. 🟢 **Re-run on `v8`** what is quoted here as measured on `v7`: the strength decomposition (`couplingMechanism.R`),
   the re-scoped replay, the relocation by period (`ruleCRelocationDecomp.R v7 v8`).
5. ⚪ **The uncovered-country sensitivities** if the paper quotes a data-side band.

---

## 8. How to use these in the paper

| display | runs | numbers | must travel with it |
|---|---|---|---|
| **the cost of political feasibility** (quantity headline) | `-PFM-holdPrice-v8` vs `-PFM-noPolitics-holdPrice-v8`, both resolutions, with `-theta325/-theta675`, `-institutionsHeld` | **+75 / +64 Gt** to 2100; θ range 39–110; net CO₂ in 2100 1.3 / 0.9 Gt a year against 0.2 / −0.1 | θ declared; persistence (§4.9); expectations (§4.11); floor-off world; the selection's theory gate |
| **what it rests on** (`v6-coupled-arms`) | the persistence ladder | growing +160, constant +124, fading +75, historical +39, erosion 2% / 2.7% / 5% +35 / +29 / +19 (EU21); H12 erosion 2.7% +23 | κ declared; the growing limit a bound (ADR 0057) |
| **politics decade by decade** | the two shrinking-future chains | hold the price +39 against +75 Gt at the same prices; the plans +7.5 → +39.4; hold the budget held, effort later | one θ, EU21, ten-year steps; perfect foresight within a step |
| **where the abatement goes** (hold the budget) | `-PFM-holdBudget-v8` vs `-PFM-noPolitics-holdBudget-v8`, per region | net −4.6 / −2.6 Gt against 20.6 / 17.9 Gt moved; anchor ×1.16 / ×1.14; REF +9.9, MEA −8.9 | emissions only; never the regional median across resolutions |
| **against `v7`** | §4.10 | headline −24% / −27% | the change is the estimation (ADR 0062), not new evidence on feasibility |
| **Methods: which policy world** | every row | floor off | one sentence |
| **Discussion: the feedback** | the coupled strength | power & industry k 0.63 / 0.73 in 2050 / 2100; the rents channel | not causal |

**Do not use for:** any `v7` number as current; any number after 2100; "hold the budget cannot hold the budget"; a
regional median compared across resolutions; any floor-region claim without flagging that φ is ordinal; any
country-level binding-sector figure as a statement about regions; any price without naming its market; "the
constraint lands on households" or "on industry" (§6.2a); a US number without its negative reference (§6.1); the GDP
gain without the CO₂ it buys; a shrinking-future step's plan as an outcome.

---

## 9. How to re-derive every number here

```bash
Rscript analysis/coupled/runCoupledStage.R v8      # extract (coupled-runs.rds), admission, facts, costs,
                                                   # hold-the-budget prices and freeze, convergence audit, provenance
Rscript analysis/checks/gateRefCompare.R v8        # -> gate-ref-compare.rds (the gate, per year)
Rscript analysis/checks/budgetPeak.R v8            # -> budget-peak.rds (which hold-the-budget runs peak)
Rscript analysis/checks/emissions2100.R v8         # -> emissions-2100.rds (net CO2 to 2100, net-zero year)
Rscript analysis/v8/shrinkingFuture.R v8           # -> shrinking-future.rds and its three figures
Rscript analysis/v8/shrinkingFutureRegions.R v8    # -> shrinking-future-regions.rds, the chains by region (six figures)
Rscript analysis/v8/scenarioSet.R price v8         # -> scenario-set-price.rds, one closure's set: world and regions
Rscript analysis/v8/scenarioSet.R budget v8        #    (fig-set-<closure>-*.png; prices are the floor pm_taxCO2eq)
node analysis/figures/pptx/fig-closure.js price|budget <out.pptx>; node analysis/figures/pptx/fig-scenario-map.js <out.pptx>
                                                   # the schematics (PNG: analysis/figures/pptx/export-png.ps1)
Rscript analysis/figures/build-figures.R --group=v8                    # the figures
```

The extractor keeps the newest run per (resolution, scenario), flags the older ones `superseded`, checks `log.txt`
for `REMIND run finished`, and applies the early-market admission rule (§2.5a). It reads the `v8` titles through
`analysis/coupled/_runKey.R` (§2.6).

By hand, `gdxdump fulldata.gdx symb=<name> format=csv`:

| what | symbol |
|---|---|
| cumulative CO₂ | `pm_actualbudgetco2` — element `"2100"`. It runs past 2100 for the peak check; report only `"2100"` |
| global net CO₂ by period | `vm_emiAll(t, regi, "co2")` summed over regions (GtC; ×44/12) |
| the **floor** every market pays | `pm_taxCO2eq` — **multiply by 272 to get \$2005/tCO₂**. ⚠️ **This is not the ES price** |
| **ES** / **ETS** market price | `pm_taxCO2eq + pm_taxemiMkt(t,regi,"ES"/"ETS")` — dims **(year, region, market)** |
| emissions by market | `vm_co2eqMkt(t, regi, market)` (GtC; ×44/12) |
| the cost-optimal anchor | `p45_taxCO2eq_anchor(ttot)` — ×272 |
| the share path | `p45_pfmPhiPath(ttot, regi)`, per market `p45_pfmPhiMktPath(ttot, regi, market)`; per iteration `p45_pfmPhiPath_iter` |
| φ per region / per market (2025 value) | `p45_regiDiff_phi` / `p45_pfmPhiMkt(regi, market)` |
| the strength and options a call used | the run's `pfm-phi-history.rds` (last entry: `phiPath`, `strength`, `options` incl. `windowEnd`, `formulation`) |
| did the markup reach the solver? | `p45_pfmMarkupWritten` vs `p45_pfmMarkupSeen` — different iterations (§3.3) |
| the hold-the-budget rebuild and its reference price | `p45_pfmBoundCheck_iter` (~1e-6 on call iterations); `p45_pfmPriceRef` (`cm_pfmRefPrice`) |
| path convergence | `p45_pfmDelta_iter` — **entries before the first PFM call are a 1e6 sentinel**; `p45_pfmCallCount` |
| how hard the cap bit | `p45_pfmBindShare_iter` — ⚠️ **written only under bind mode 2** |
| did Nash converge? | `cm_iteration_max` — the count actually used; 100 means it hit the cap |
| did the **budget** converge? | `p80_globalBudget_absDev_iter` at the last iteration against `cm_budgetCO2_absDevTol`; `pm_pfmBudgetWarn`; `p45_pfmBudgetNoPeak_iter` |
| solve status | `o_modelstat` (2 = locally optimal) — **reads 2 on an unfinished run too** |
| did the markets clear? | `p80_surplusMax_iter` at the last iteration over `p80_surplusMaxTolerance`; split at 2060 |
| the REMIND version | `c_model_version` (3-7-1) |
| a sequential step | `cm_startyear`, the run's `pfm-coupling.yml` (`phiWindowEnd`, `refGdx`) |
| the dial | `cm_pfmTheta`, `cm_pfmBindMode`, `cm_pfmSectorMarkup`, `cm_pfmPhiPath`, `cm_pfmBoundRebuild`, `cm_pfmAnchorFromGdx`, `cm_pfmRefPrice`, `cm_iterative_target_adj` |

`cm_iterative_target_adj` tells you which family a run belongs to: 9 = budget enforced by iteration,
0 = not. It must match before two runs are differenced.

> 🔴 **Before reading any symbol by hand, check the run finished.** `grep -q "REMIND run finished"
> <rundir>/log.txt`. `PITFALLS.md` §25.
