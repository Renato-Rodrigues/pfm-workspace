# The coupled scenario set — what each run is for, and what the batch says

*A plain-language guide to the coupled REMIND runs: why each one exists, what it may and may
not be used to conclude, and where it belongs in the paper.*

**Status.** The **`v7` batch** is in (2026-10-26): **40 runs** on REMIND 3.7.1, 24 at EU21 and 16 at H12, of which 34
are coupled, on Run-Group **`v7`** (selected specification
`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satInn iw:fexp`, ADR 0060): the first wave (30 runs)
and the second, the persistence ladder (10 runs). Hold-the-budget runs that had not peaked their budget were re-run
from another start point (§3.4); the re-runs replace them. Every row is generated from
`analysis/run-groups/scenario-matrix-v7.yml` (ADR 0055). **One run does not peak its budget from either start** (EU21
hold the budget, growing limit; disclosed, §3.4); it meets the budget at 2100. The theory-gate sensitivities (`v7-h3070`, `v7-h3080`, `v7-p10`) select
the same specification (`MODEL.md` §2.4a), so they need no coupled runs. The `v6` version of this
document, with the `v6` batch's 71 runs, is archived at `../_archive/_wip/2026-10-25/docs/SCENARIOS-v6.md`.

**Every number below** is read from `output/pfm/v7/coupling/`: `coupled-facts.json` (results per run and
sensitivity run), `coupled-costs.json` (emissions moved, GDP), `convergence-audit.rds`, `held-budget-prices-levelC.rds`,
`gate-ref-compare.rds`, `budget-peak.rds`, `emissions-2100.rds` and `strength-support.rds`. `Rscript
analysis/coupled/runCoupledStage.R v7` rebuilds the first five (§9). Re-read them from there.

**Horizon.** Results are reported to **2100 and no later** (author, 2026-10-25): cumulative CO₂ to 2100, net CO₂ in
2100, the net-zero year by 2100. The budget-peak admission check (§3, `PITFALLS.md` §26) reads later periods; it is an
internal check and is phrased for the paper without post-2100 numbers.

> ⚠️ **Every price in this document names its market.** With the markup on
> (`cm_pfmSectorMarkup = 1`) *both* markets carry one: ES (buildings and transport) faces
> `pm_taxCO2eq + pm_taxemiMkt("ES")`, ETS (electricity and industry) faces
> `pm_taxCO2eq + pm_taxemiMkt("ETS")`, and `pm_taxCO2eq` alone is the **floor** that neither
> market actually pays. `COUPLING.md` §11.6.

**The batch in five sentences.**

1. **Holding the price, political feasibility adds 99 Gt CO₂ by 2100 at EU21 and 88 Gt at H12** (θ = 0.50; 55–145 Gt
   across the declared θ range), and net CO₂ in 2100 is 1.3 / 1.2 Gt a year where the no-politics reference is at
   0.1 / −0.05 (§4.2a).
2. **The headline rests most on how long today's limit lasts** (§4.9): kept constant it adds 168 / 145 Gt; if it
   also erodes at 2.7% a year, 36 / 32 Gt, about a third of the headline; if it tightens 0.5% a year, 221 Gt (EU21).
3. **Holding the budget, every admitted run meets it**, the global price rises by about a fifth (×1.21 / ×1.19 in
   2050), and the ceiling moves about 18 Gt CO₂eq of abatement between regions (17.1 EU21 / 18.4 H12) (§4.3, §4.8).
4. **`v7` is weaker than `v6` on both counts, and the relocation changes composition**: the quantity headline is
   a sixth to a fifth smaller; under hold the budget the extra emissions go to Russia & reforming countries, the Middle
   East and Other Asia rather than India, and China absorbs about half as much (§4.10).
5. **The two resolutions agree** within about 10% on the quantity headline and in sign region by region on the
   relocation (§4.2a, §4.8).

Companion documents: `COUPLING.md` (how the interface works and how to run one), `MODEL.md`
(the mathematics), `PITFALLS.md` (what silently breaks), design note 0007 (the `v7` formulation and its
first results).

---

## 1. The idea in one page, no equations

REMIND normally answers: *what is the cheapest way to hit a carbon budget?* Its answer is a
carbon price path. Left alone it will happily propose that every region charge several hundred
dollars a tonne by mid-century, because that is cost-efficient.

The PFM asks a different question: **could that region's politics actually deliver that price?**
It estimates, from institutions and the economic weight of fossil and clean-energy interests, a ceiling on how
stringent a country's climate policy can plausibly get, and how far below that ceiling each country sits. The
coupling feeds that into REMIND so the model has to respect it while it optimises.

The moving parts:

**The anchor.** The global, cost-optimal carbon price path REMIND builds. Everything regional is
derived from it.

**u, the ranking.** Where each region sits, from least to most constrained (0 to 1), read **once**,
from observed 2023 data, separately for each sector. It does not change over the century.

**k(t), the strength.** How large the political shortfall is overall, relative to 2025 (k = 1 in
2025). It moves every period, because the ceilings move with REMIND's energy system, income and
institutions. On the 1000 Gt pathway the power & industry strength falls to about 0.71 by 2050 and 0.67 by 2100;
buildings & transport to 0.60 and 0.49.

**φ ("phi"), the feasibility share.** φ = 1 − θ · k(t) · u, per region, sector and period. φ = 1 means
"politics is no obstacle here". φ = 0.6 means "this region carries 60% of the *extra* price the
cost-optimal answer asks beyond current policy" (both closures, §1.2) — a ranking at a declared
severity, not a measured capability (§6.2).

**θ ("theta"), the severity dial.** How hard the constraint bites. θ = 0 switches the mechanism off
(every φ = 1). **θ = 0.50 is the central setting**, with **0.325** and **0.675** as the declared range.
Declared, never estimated (`MODEL.md` §5.3).

**κ ("kappa"), the erosion rate.** An optional extra fade on the strength, k(t)·(1−κ)^(t−2025):
"politics improves by itself at κ a year". **κ = 0 in every headline run**; 0.027 (central), 0.02 and
0.05 are the second wave (ADR 0050 decision 5).

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
| 0 | collapse to `min(φ_Bulk, φ_Diffuse)` — one price, the worse sector wins | the `-Min` variants (not in the `v7` batch) |
| 1 | floor + markup: `pm_taxCO2eq` = the worse sector, `pm_taxemiMkt(m)` = market *m*'s own increment over it | every coupled row |

**Which sector binds is split** on `v7` (§6.2a): power & industry in **11 of 21 EU21 regions and 6 of 12 H12
regions**, buildings & transport in 9 and 5, Russia & reforming countries tied. Neither "the limit on household
energy costs constrains the economy-wide price" nor its opposite is a robust statement.

### 1.2 Two closures: hold the price, or hold the budget

The level cap caps each region's price at current policy plus φ times the extra effort,
P = min(A, P_ref + φ · max(A − P_ref, 0)). What REMIND may do in response defines the closure:

| closure | rows | anchor | budget | the sentence it produces |
|---|---|---|---|---|
| **hold the price** | `-PFMlevelBfix…` | pinned to the θ = 0 run's converged anchor (`cm_pfmAnchorFromGdx`) | not enforced | "political feasibility adds X Gt CO₂ to the 1000 Gt pathway by 2100" — the **quantity headline** |
| **hold the budget** | `-PFMlevelC…` | rises until the budget holds; the cap is rebuilt every iteration (`cm_pfmBoundRebuild = 1`) | enforced | "the budget holds, and abatement moves between regions" |

**No adjustment speed λ** (ADR 0050). The gap is read at the anchor year and held; the only gap-closure assumption
is the declared erosion rate κ, run as a sensitivity.

---

## 2. The scenario map

**The file is generated, not hand-written** (ADR 0055): edit the matrix, rebuild, commit both.

```bash
Rscript analysis/run-groups/buildPFMScenarioConfig.R analysis/run-groups/scenario-matrix-v7.yml
#   -> models/remind_pfm/config/scenario_config_PFM_v7.csv, then the validator and REMIND's own reader
```

Every row is REMIND's canonical scenario plus named deltas; every coupled row carries
`cm_taxCO2_regiDiff = 11`, `cm_pfmPhiPath = 1` (the share path), `cm_pfmGapClosure = 0` (no λ),
`cm_pfmSectorMarkup = 1`, and `cm_taxCO2_lowerBound_path_gdx_ref = 0` (§6.3).
H12 titles carry no resolution infix; EU21 titles carry `-EU21-`; coupled titles end in `-v7`.

### 2.1 Uncoupled baselines (REMIND 3.7.1, shared with `v6`)

| run | why it exists |
|---|---|
| `SSP2[-EU21]-NPi2025` | current policies: the reference price P_ref, and the `path_gdx_ref` of every other row |
| `SSP2[-EU21]-PkBudg1000` | REMIND's own 1000 Gt cost-optimal answer |
| `SSP2[-EU21]-PkBudg1000-PFMgateRef` | the uniform-price reference: the interface check (§3.1) |

### 2.2 No-politics references — the mechanism installed but switched off

| run | switched off how | the control for |
|---|---|---|
| `-PkBudg1000-PFMgate-v7` | present, θ = 0, budget enforced | hold the budget; must reproduce `-PFMgateRef` |
| `-PkBudg1000-PFMgateBfix-v7` | present, θ = 0, budget forcing off, **anchor pinned to `-PFMgate-v7`** | hold the price (the quantity headline); must reproduce `-PFMgate-v7` |

### 2.3 The first wave — 1000 Gt budget, both resolutions (`V7W1EU21`, `V7W1H12`)

| run | closure | θ |
|---|---|---|
| `-PFMlevelBfix-v7`, `-PFMlevelBfixTh325-v7`, `-PFMlevelBfixTh675-v7` | hold the price | 0.50, 0.325, 0.675 |
| `-PFMlevelC-v7`, `-PFMlevelCTh325-v7`, `-PFMlevelCTh675-v7` | hold the budget | 0.50, 0.325, 0.675 |
| `-PFMlevelBfix-held-v7`, `-PFMlevelC-held-v7` | both closures, institutions held at their anchor values | 0.50 |
| `-PFMlevelBfix-Ehold-v7`, `-PFMlevelC-Ehold-v7` | both closures, **constant limit** | 0.50 |

The constant-limit pair is in the first wave because the `v7` ranking moved (China and India are no longer the
most constrained regions, ADR 0060): it separates the effect of the new ranking from the limit's fading (§4.10).

### 2.4 The second wave and the other sensitivities

| group | rows | varies | resolutions | status |
|---|---|---|---|---|
| erosion rate κ | 0.027 (both closures); 0.02, 0.05 (both closures) | `pfmPhiKappa` | 0.027 at EU21 and H12; 0.02, 0.05 at EU21 | landed 2026-10-26, `V7W2EU21` (8 rows), `V7W2H12` (2 rows) |
| growing limit | the limit tightens 0.5% a year (both closures) | `pfmPhiHold = ratio`, `pfmPhiKappa = -0.005` (ADR 0057) | EU21 | landed 2026-10-26, `V7W2EU21` |
| theory-gate thresholds | the selection re-run at H3 0.70 / 0.80 and $p$ 0.10 | variant Run-Groups | — | done 2026-10-26 (`RUNNING.md` Step 6c): the same specification is selected in all three, so no coupled runs |

**Not re-run on `v7`** (their `v6` readings are in the archived document and are not `v7` numbers): the ranking
(uniform, permuted, reversed), the uncovered countries (all-median, all-low, nearest donors, USA), the markup-off and
proportional-mode rows, the curve shape and the specification family, the annual rung, drivers stopping in 2060 and
the regional strength.

### 2.5 Running them

```r
library(pfm)
cfg <- "config/scenario_config_PFM_v7.csv"
submitPFM("V7W2EU21", remindDir = "models/remind_pfm-EU21", scenarioConfig = cfg)                  # dry run
submitPFM("V7W2EU21", remindDir = "models/remind_pfm-EU21", scenarioConfig = cfg, dry = FALSE, slurmConfig = "standby")
```

Start tags are `V7W<wave><res>`, and a tag of its own for a re-run (`V7RERUNEU21`, `V7RERUNH12`, `V7RERUN2EU21`, `V7RERUN3EU21`),
so a re-submission never re-runs a batch. A start group never mixes resolutions: the H12 rows run from the `-H12`
checkout, the EU21 rows from `-EU21`. `submitPFM` runs a preflight first (repos clean and pushed, packages installed,
groups exported, mappings, the replay control) and refuses on any failure. `RUNNING.md` Step 7.

### 2.5a How an unfinished run earns its place

🔴 **An unfinished run's `fulldata.gdx` is complete and reports success** (`PITFALLS.md` §25).
`analysis/coupled/extractCoupledResults.R` admits an unfinished run only if **zero market-year cells
through 2060 exceed REMIND's own `p80_surplusMaxTolerance`**, and records the reason in
`$admittedUnfinished`. **In the `v7` batch every run finished and none needed admitting.** Where a scenario was
re-run, the newest run is admitted and the older one is flagged `superseded`.

### 2.6 Run names and the labels the documents use

Up to `v7`, run titles, start tags and config switches keep their original names: they are identifiers that the
cluster, the artifacts and the extraction scripts key on. The letters in them are the old closure labels
(B = hold the price, C = hold the budget). Documents, figures and the methodology use the labels below;
a title is quoted in code font when it is needed. The old labels are listed in
`../_archive/_wip/LABELS-2026-10-12.md`.

**From `v8` on, the titles carry the labels** (`scenario-matrix-v8.yml`). The analysis scripts translate each title to
the internal key of the left column in one place, `analysis/coupled/_runKey.R`, so every script reads every group.
The artifacts keep the run's own title in `title` and the key in `scenario`.

| `v8` title part | internal key (the table below) |
|---|---|
| `-PFM-noPolitics-holdBudget` / `-PFM-noPolitics-holdPrice` | `-PFMgate` / `-PFMgateBfix` |
| `-PFM-holdPrice` / `-PFM-holdBudget` | `-PFMlevelBfix` / `-PFMlevelC` |
| `-theta325`, `-theta675` | `Th325`, `Th675` |
| `-constantLimit`, `-growingLimit` | `-Ehold`, `-backslide` |
| `-erosion2`, `-erosion2p7`, `-erosion5`, `-erosionHistorical` | `-kappa02`, `-kappa`, `-kappa05`, `-kappaHist` |
| `-commonStrength`, `-gapFirst`, `-rentsWorldPrice` | `-common`, `-gapfirst`, `-rentsWorld` |
| `-institutionsHeld`, `-institutionsAndrijevic`, `-institutionsStoryline` | `-held`, `-gcA`, `-story` |
| `-shrinkingFuture2030` … `-shrinkingFuture2070` | `-seq2030` … `-seq2070` |

| in the run title | label | what it sets |
|---|---|---|
| `-PFMgateRef` | uniform-price reference (uncoupled) | `cm_taxCO2_regiDiff = 0` |
| `-PFMgate-v7` | no-politics reference (θ = 0), budget held | `cm_pfmTheta = 0`, budget enforced |
| `-PFMgateBfix-v7` | no-politics reference (θ = 0), price held | anchor pinned to `-PFMgate-v7`, budget not enforced |
| `-PFMlevelBfix…` | **hold the price** | anchor pinned to `-PFMgate-v7` (`cm_pfmAnchorFromGdx = on`, `cm_iterative_target_adj = 0`), level cap |
| `-PFMlevelC…` | **hold the budget** | budget enforced, level cap rebuilt every iteration (`cm_pfmBoundRebuild = 1`) |
| no further suffix, e.g. `-PFMlevelBfix-v7` | **fading limit** (the limit weakens as the energy system changes), θ = 0.50: the headline | the defaults |
| `Th325`, `Th675` | severity θ = 0.325, 0.675 | `cm_pfmTheta` |
| `-Ehold` | **constant limit** (today's limit kept, k ≈ 1) | `pfmPhiHold = ratio` |
| `-backslide` | **growing limit** (the limit tightens 0.5% a year) | `pfmPhiHold = ratio`, `pfmPhiKappa = -0.005` |
| `-kappa02`, `-kappa`, `-kappa05` | **fading + erosion** 2% / 2.7% / 5% a year (κ = 0.02 / 0.027 / 0.05) | `pfmPhiKappa` |
| `-held` | fixed institutions (held at their anchor values) | `pfmInstitutions = hold` |
| `-EU21-` infix / none | 21 regions with the EU split / 12 regions (H12) | `regionmapping` |
| start tag `V7W1<res>` / `V7W2<res>` | first / second wave | — |
| start tag `V7RERUN<res>`, `V7RERUN2EU21`, `V7RERUN3EU21` | hold-the-budget re-runs from another start point (§3.4) | `warm` in the matrix |

---

## 3. Did the runs work?

| check | `v7` batch (40 runs, re-runs admitted) |
|---|---|
| solve status | `o_modelstat = 2` in **40 of 40** |
| finished | **40 of 40**; none admitted unfinished |
| early-period markets (≤ 2060) | **zero cells over tolerance**; worst 0.94× (EU21 `-PFMgate-v7`) |
| PFM converged | final change in the share path **≤ 0.0019** in every run, against `cm_pfmConvTol = 0.002` |
| PFM calls | **2 to 8** per coupled run |
| iteration cap | **no run ends at `cm_iteration_max`** |
| budget (hold the budget) | **held in every budget-forced run**: cumulative CO₂ to 2100 997.2–1002.1 Gt (EU21), 997.6–1001.7 (H12) |
| budget peak | every admitted hold-the-budget run peaks its budget by 2100 **except two EU21 ladder runs**: `-PFMlevelC-backslide-v7` (growing limit) meets the budget at 2100 (1000.5 Gt) but has not peaked from either start; `-PFMlevelC-kappa02-v7` (erosion 2%) peaks after 2100, 6.5 Gt above the budget (§3.4). Every hold-the-price run is unpeaked by design (the budget is not enforced) |
| infeasibility code | `pm_pfmInfesCode = 0` in every coupled run |
| legislated floor | `cm_taxCO2_lowerBound_path_gdx_ref = 0` in every row |
| cache read | every coupled run read the staged Run-Group cache (`RUNNING.md` Step 8); the cache manifest and the runs' cache use are in `records/v7/` |

### 3.1 The interface gate — a tolerance, not bit-identity

`-PFMgate-v7` (θ = 0, mechanism present) against `-PFMgateRef` (mechanism absent), same REMIND version
(`gate-ref-compare.rds`):

| resolution | `pm_taxCO2eq` cells 2030–2100 | differing | max difference | cum. CO₂ to 2100 |
|---|---:|---:|---:|---|
| EU21 | 231 | **0** | \$0 | 1000.91 vs 1000.91 Gt |
| H12 | 132 | **132** | **\$0.41** | 997.04 vs 1000.81 Gt |

φ and the share path are exactly 1 in both no-politics references, so it is not the political layer. At H12 the
difference is **identical across all 12 regions in every year** (+0.035% in 2030 rising to +0.085% in 2100): one
global path, as on `v6`, because REMIND's budget loop stopped at another iteration. The price difference is inside the
gate's \$1 limit; the cumulative difference (3.8 Gt) is outside its 0.2 Gt limit and outside REMIND's own
`cm_budgetCO2_absDevTol` (2 Gt). **Disclosed**, the limits not re-tuned. **Do not write "bit-identical"** for H12.

**The hold-the-price pinning.** `-PFMgateBfix-v7` reproduces `-PFMgate-v7` within 5 Gt: **+2.2 Gt** at EU21
(1003.2 Gt) and **+3.8 Gt** at H12 (1000.8 Gt). The H12 reference therefore sits at the `-PFMgateRef` value, not at
`-PFMgate-v7`'s. If a future re-run moves this by more than a few Gt, the pinning failed and §4.2a is not
interpretable.

> ⚠️ The gate is **structurally blind** to defects that only exist at θ > 0. It proves the
> plumbing, nothing else; §3.3 is the real test.

### 3.2 Convergence — on the whole share path

Convergence is checked on the share **path**: at each PFM call the largest change in φ over the
checkpoint years 2035, 2050, 2070 and 2100, against 0.002, after at least two calls; two successive
moves in opposite directions are damped (α = 0.5) rather than the tolerance loosened. Every run
converged: 2–8 calls, final change ≤ 0.0019.

### 3.3 φ and the markup reach the solver

- The share path is loaded in every θ > 0 run, with the formulation `v6-anchor` in its history (the share-path
  formulation of ADR 0049, unchanged in `v7`), and φ < 1 somewhere.
- **Markup written vs seen.** Two H12 hold-the-budget runs (`-PFMlevelC-v7`, `-PFMlevelCTh325-v7`) differ by 0.0015
  and 0.0013; in both the markup moved in the final iteration. The `markupMismatch` list in `coupled-facts.json` is a
  "still moving" flag, not an erasure (`PITFALLS.md` §16).

### 3.4 Re-runs and settling

**Five hold-the-budget runs had not peaked their budget** in the first wave (EU21 `-PFMlevelC-v7`,
`-PFMlevelCTh325-v7`, `-PFMlevelCTh675-v7`; H12 `-PFMlevelC-held-v7`, `-PFMlevelCTh675-v7`; `PITFALLS.md` §26). In all
five the Middle East kept positive emissions late in the horizon that the passing runs drove down, and the failures
did not follow θ, so the start point, not the political limit, decided it (design note 0007 §17). They were re-run from
the no-politics reference (`V7RERUNEU21`, `V7RERUNH12`; `budget-peak.rds`). Four then peaked by 2100. EU21 θ = 0.675 did
not; its second attempt, from the passing θ = 0.50 run (`V7RERUN2EU21`), peaks in 2090 at 999.0 Gt.

**Two second-wave runs had not peaked** (EU21 `-PFMlevelC-kappa-v7`, started from `-PFMlevelC-v7`, and
`-PFMlevelC-backslide-v7`, started from `-PFMlevelC-Ehold-v7`). Both were re-run from the no-politics reference
(`V7RERUN3EU21`, 2026-10-26; `budget-peak.rds`):

- **Erosion 2.7% now peaks** (2090, 1000.7 Gt). The re-run replaces the first start.
- **The growing limit does not peak from either start.** It meets the budget at 2100 (1000.5 Gt), and cumulative CO₂
  then rises (1074 Gt by 2150 from the no-politics start; 1003 Gt from the constant-limit start). The emissions after
  2100 are in the Middle East and REF, the two most constrained regions. Unlike the first-wave failures, this one does
  not depend on the start point: under a limit that tightens without end, the constrained regions' share keeps
  falling after 2100, so the budget is met at 2100 and not held after it. **Disclosed, not re-run again.** Quote its
  hold-the-budget numbers to 2100 with this note; its hold-the-price result is unaffected.
- **Erosion 2% peaks in 2130, 6.5 Gt above the budget** (Middle East and China after 2100). Within the 2 Gt tolerance at
  2100 (1001.9 Gt); disclosed with the growing limit.

**Settling** (`convergence-audit.rds`, the last ten iterations). The two constant-limit hold-the-budget runs were
still moving: EU21 `-PFMlevelC-Ehold-v7` (price range up to 15.7%) and H12 `-PFMlevelC-Ehold-v7` (16.1%), both ending
within 2 Gt of the budget. Quote them with that note. The headline hold-the-budget runs moved less than 1% (EU21 0.7%,
H12 0.4%); of the second wave, the re-runs moved 4.3% (erosion 2.7%) and 1.8% (growing limit), the others less than
1%.

---

## 4. What the results say

Cumulative figures are `pm_actualbudgetco2("2100")` in Gt CO₂; prices are 2050, \$2005/tCO₂, and name their market.
Price ratios are "× the θ = 0 run" (`-PFMgate-v7`).

### 4.2a The quantity headline — the cap on the price path that holds the budget

Both runs read the anchor `-PFMgate-v7` converged to and switch budget forcing off, so the no-politics reference meets
the budget (§3.1, the pinning) and the difference is the extra CO₂ the ceiling adds to the 1000 Gt pathway.

| | EU21 | H12 |
|---|---:|---:|
| `-PFMgateBfix-v7` (no-politics reference, θ = 0) | 1003.2 | 1000.8 |
| **`-PFMlevelBfix-v7`** (θ = 0.50) | **1101.9** | **1088.7** |
| **Δ at θ = 0.50** | **+98.8** | **+87.9** |
| Δ at θ = 0.325 / 0.675 | +59.4 / +144.8 | +55.2 / +125.6 |
| slope | **212 Gt per unit θ** | **185 Gt per unit θ** |
| institutions held | +98.4 | +88.6 |
| constant limit | +167.6 | +145.3 |
| bind share (last iteration) | 0.986 | 0.994 |
| power & industry strength k 2050 / 2100 | 0.707 / 0.667 | 0.705 / 0.664 |
| buildings & transport strength k 2050 / 2100 | 0.597 / 0.488 | 0.598 / 0.491 |

**Political feasibility adds about 90–100 Gt CO₂ to the 1000 Gt pathway by 2100** at the central severity, 55–145 Gt
across the declared θ range. The two resolutions agree within 12%.

**Net CO₂ in 2100** (`analysis/checks/emissions2100.R v7` → `emissions-2100.rds`; global, Gt CO₂ a year):

| | EU21 | H12 |
|---|---:|---:|
| no-politics reference (θ = 0) | 0.11 | −0.05 (net zero in 2100) |
| θ = 0.325 / **0.50** / 0.675, fading limit | 0.86 / **1.33** / 2.02 | 0.78 / **1.17** / 1.62 |
| institutions held | 1.35 | 1.20 |
| constant limit | 2.52 | 2.10 |

No hold-the-price run reaches net zero by 2100. In 2050 the fading limit emits 10.6 / 10.5 Gt a year against 8.8 / 8.9
in the no-politics reference.

- **Holding institutions changes almost nothing** (−0.4 / +0.7 Gt), although it moves the strength (power & industry
  k 2100 0.667 → 0.695, buildings & transport 0.488 → 0.451 at EU21). The headline does not rest on projected
  institutions.
- **The cap binds almost everywhere** (bind share 0.986 / 0.994).
- **Emissions keep accumulating to 2100** in every hold-the-price run: that is what "the budget is not enforced"
  means. Quote the 2100 cumulative, never a peak, for this family.

### 4.3 Hold the budget — the budget holds under the cap

Every admitted hold-the-budget run holds the budget (§3). What the cap changes is where the price and the abatement
sit. The anchor rises to make up for the capped regions; in 2050, against the θ = 0 run:

| | EU21 anchor | EU21 median region | H12 anchor | H12 median region |
|---|---:|---:|---:|---:|
| θ = 0.325 | 1.119 | 1.076 | 1.107 | 1.024 |
| **θ = 0.50** | **1.206** | **1.132** | **1.185** | **1.047** |
| θ = 0.675 | 1.321 | 1.194 | 1.283 | 1.080 |
| institutions held | 1.211 | 1.137 | 1.192 | 1.053 |
| constant limit | 1.385 | 1.230 | 1.342 | 1.072 |
| growing limit (not peaked after 2100, §3.4) | 1.552 | 1.341 | — | — |
| fading + erosion 2% / 2.7% / 5% | 1.103 / 1.080 / 1.042 | 1.064 / 1.048 / 1.026 | — / 1.071 / — | — / 1.008 / — |

The cheapest region in 2050 is REF at both resolutions (×0.86 EU21, ×0.84 H12); the dearest is a northern European
region (NEN at EU21, NEU at H12, at the anchor's ratio).

> ⚠️ **Do not compare the regional median across resolutions.** 11 of EU21's 21 regions are European, so the EU21
> median is close to a European price. Quote hold the budget by the abatement moved (§4.8) or the emissions-weighted
> price (×1.02 EU21, ×1.03 H12, `held-budget-prices-levelC.rds`; 8 of 42 and 8 of 24 markets are below the
> no-politics price).

**Reading.** Hold the budget is not "the budget cannot be held". It is "the budget holds, the global price
rises by about a fifth, and the capped regions' share of the effort moves elsewhere" (§4.8).

### 4.6 The θ sweep

Quantity headline: **+59.4 / +98.8 / +144.8 Gt** at EU21 and **+55.2 / +87.9 / +125.6 Gt** at H12 for
θ = 0.325 / 0.50 / 0.675 — 212 and 185 Gt per unit θ, steeper above 0.50. Hold the budget: the anchor goes ×1.119
→ 1.206 → 1.321 (EU21) and the relocated abatement 11.3 → 17.1 → 25.6 Gt CO₂eq. The sweep is declared; none of its
points is an estimate. Figure: `v6-coupled-theta` (`v7` against `v6`).

### 4.8 Where abatement goes, and what it costs in GDP

`coupledCostsAndAbatement.R` → `coupled-costs.json`: regional `vm_co2eq`, `vm_cesIO` ("inco") and
`vm_cons` over 2020–2100, each run against its matched no-politics reference (θ = 0); money discounted at 5%/yr.
**Relocated** is half the sum of the absolute regional changes — the volume that moved, not the net.

| | net Δ CO₂eq | relocated | ρ(φ, relative change) | GDP | consumption |
|---|---:|---:|---:|---:|---:|
| **hold the budget** EU21 / H12 | **−0.7 / +3.2** | **17.1 / 18.4** | −0.49 / −0.63 | +0.024% / +0.017% | +0.004% / +0.002% |
| hold the budget, constant limit EU21 / H12 | +0.6 / +1.9 | 35.0 / 37.1 | −0.58 / −0.73 | +0.011% / +0.004% | −0.006% / −0.007% |
| hold the budget, growing limit EU21 | +0.7 | 51.9 | −0.58 | | |
| hold the budget, erosion 2% / 2.7% / 5% EU21 | +1.9 / −1.9 / −1.1 | 8.2 / 7.5 / 5.0 | −0.40 / −0.28 / −0.30 | | |
| **hold the price** (quantity headline) EU21 / H12 | +104.8 / +93.3 | 54.3 / 47.4 | −0.52 / −0.68 | +0.15% / +0.13% | +0.16% / +0.15% |

**Under hold the budget the ceiling moves abatement rather than reducing it**: the net change is a few
Gt while about 18 Gt changes region, and the more constrained a region the more it emits relative to
its own baseline (negative ρ). Hold the budget, EU21 / H12: REF +7.1 / +8.2, MEA +4.7 / +6.7, OAS +4.0 / +4.7,
IND +0.8 / +0.3; SSA −5.0 / −5.3, CHA −4.9 / −6.4, Europe (summed) −5.7 / −3.0 (EUR). The sign agrees in 11 of 12 H12
regions (the USA is near zero at both). With the constant limit the relocation doubles (35.0 / 37.1 Gt) with the same
regions: REF +19.9 / +21.4, CHA −12.9 / −14.1. **The relocation follows the persistence of the limit**: 51.9 (growing),
35.0 (constant), 17.1 (fading), 8.2 / 7.5 / 5.0 Gt (erosion 2% / 2.7% / 5%) at EU21; with the growing limit China takes
−19.1 Gt and REF +27.0.

**Under the cap, the extra emissions land** (EU21, hold the price) in MEA +30.9, OAS +21.9, REF +13.9, SSA +10.7,
IND +9.6, LAM +7.1 and USA +6.1 Gt CO₂eq (H12 alike).

> 🔴 **GDP rises, and that is not a benefit.** REMIND carries no climate damages, so any run that
> abates less looks richer. Quote it only in the same sentence as the extra CO₂, or not at all.
> Regional GDP is not reported.

### 4.9 The sensitivity runs — what the quantity headline is sensitive to

Hold the price, θ = 0.50, extra cumulative CO₂ by 2100 (fading limit, the headline: **+98.8 Gt** EU21, **+87.9 Gt**
H12). Each sensitivity run records the options its last PFM call ran with (`coupled-facts.json` `arms`); a recorded
option that differs from the declared one would make the run unusable, and none does.

| sensitivity run | EU21 Δ Gt | vs fading limit | H12 Δ Gt | reading |
|---|---:|---:|---:|---|
| growing limit (tightens 0.5% a year; k 1.13 / 1.47 in 2050 / 2100) | +221.1 | +122.3 | — | the worse-than-today side, a bound (ADR 0057): 2.2 times the headline, 54 Gt above the constant limit |
| constant limit, k ≈ 1 | +167.6 | +68.8 | +145.3 | the moving strength removes 41% (EU21) / 40% (H12) of the constant-limit result |
| fading limit (the headline) | +98.8 | — | +87.9 | |
| fixed institutions | +98.4 | −0.4 | +88.6 | §4.2a |
| **fading + erosion 2% / 2.7% / 5% a year** | +44.4 / **+35.5** / +19.3 | −54.4 / −63.3 / −79.4 | 2.7%: **+31.9** | **the largest effect**: at the central κ, 36% of the headline is left at both resolutions |

**The persistence ladder** (`coupled-facts.json` `arms`; figure `v6-coupled-arms`): growing → constant → fading → fading +
erosion orders the headline monotonically, from +221 to +19 Gt at EU21, an elevenfold range, against a θ range of
+59 to +145. As on `v6` (κ = 0.027 left 35%), **whether the limit erodes by itself is the assumption the result rests
on most**; θ is second. Net CO₂ in 2100 follows (`emissions-2100.rds`): 4.16 Gt a year with the growing limit, 2.52
constant, 1.33 fading, 0.33 / 0.24 / 0.13 with erosion (EU21; H12 erosion 2.7%: 0.05), against 0.11 in the no-politics
reference; no hold-the-price run reaches net zero by 2100.

The EU21 hold-the-budget run with the growing limit meets its budget at 2100 but does not hold it after (§3.4); its
numbers in §4.3 and §4.8 are quoted with that note. The hold-the-price ladder is unaffected.

### 4.10 Against `v6`

Each headline against its own version's no-politics reference (θ = 0), on the same REMIND 3.7.1 bases.

| | `v6` EU21 / H12 | `v7` EU21 / H12 |
|---|---|---|
| quantity headline, θ = 0.50 | +118.2 / +112.8 | **+98.8 / +87.9** |
| slope per unit θ | 264 / 247 | 212 / 185 |
| constant limit | +189.1 / +176.3 | +167.6 / +145.3 |
| hold the budget anchor 2050 | ×1.259 / ×1.251 | ×1.206 / ×1.185 |
| hold the budget abatement relocated | 22.7 / 19.9 | **17.1 / 18.4** |
| hold the budget: China / India / Middle East / Russia & reforming | −10.2 / +8.1 / +7.9 / +3.7 (EU21) | −4.9 / +0.8 / +4.7 / +7.1 (EU21) |

**The quantity headline shrinks by a sixth (EU21) to a fifth (H12).** The cause is the specification (ADR 0060): the
democracy weight removes `v6`'s edge effects, under which fossil dependence acted against the theory in China, the
Middle East and Other Asia, and the strength no longer rises again after mid-century in buildings & transport.

**The relocation changes composition more than size.** The ranking moved (`MODEL.md` §5.2): Russia & reforming
countries are now the most constrained region in both sectors, China is no longer the floor in buildings & transport
nor India in power & industry. The extra emissions under hold the budget follow it: Russia & reforming countries
doubles, India nearly vanishes, and China absorbs about half as much. **"China absorbs" remains a constant-limit
result**: with the limit held constant China takes −12.9 Gt (EU21), and less when the limit fades.

**The most constrained region's price does not catch up.** Under hold the budget at EU21, REF's power & industry
(ETS) price is 0.57 of the θ = 0 run's in 2030, 0.80 in 2050 and 0.85 in 2100; MEA and OAS return to within 3–6% of it
by 2070 (0.98 / 0.95), as the `v6` constrained regions did (`coupled-runs.rds`; figure `v6-price-catchup`, `v7`
against `v6`). On `v6` the catch-up by about 2070 was the reason the relocation fell after 2050; on `v7` it holds for
every constrained region except REF, which is why REF's share of the extra emissions grows. Abatement moved before and
after 2050: 7.5 and 12.5 Gt (EU21), against 8.8 and 16.7 on `v6` (`rulec-relocation-decomp.rds`, `ruleCRelocationDecomp.R
v6 v7`; figure `v6-rulec-relocation`).

---

## 5. Limitations — read this before quoting anything

1. **θ and κ are declared, not estimated.** θ carries the main-text band; the persistence of the limit moves the
   headline more than θ does, from +221 (growing) to +19 Gt (erosion 5%) at EU21 (§4.9). Neither may be presented as a
   finding.
2. **The specification is selected for the hypotheses** (ADR 0059): the theory gate requires H1–H2, and the rule was
   revised for `v7` after the `v6` result. The coupled numbers are conditional on a specification chosen in part for
   its significance; say so with the headline (`MODEL.md` §2.4a).
3. **One region per resolution is pinned by the parameter, not by data.** φ = 1 − θ·k(t) exactly for the region at
   u = 1: **REF** in both sectors at both resolutions; 1 for the region at u = 0 (in power & industry UKI at EU21 and
   NEU at H12; in buildings & transport NEN and CAZ). φ is a *ranking* (§6.2).
4. **Legislated prices may be rolled back in every run** (§6.3), and rarely are: from 2030 to 2100 both market prices
   sit below the current-policy reference in 1.7% of region-years under hold the price at EU21 (20 of 1155; 0.8% at
   H12) and 0.4% under hold the budget (0.5% at H12).
5. **The co-evolution feedback is real and not causal.** The coupled strength moves with REMIND's energy system, and
   the PFM loop takes 2–8 calls. Call it conditional scenario accounting (`MODEL.md` §8.1).
6. **The United States has no covered country.** Its φ comes from the band rule (`MODEL.md` §5.4); the USA
   sensitivity runs are not re-run on `v7`.
7. **The assignment of uncovered countries was the widest data-side band on `v6`** (110–155 Gt). Not re-measured on
   `v7`; report the `v6` band as such or re-run it.
8. **The interface gate is verified to a tolerance**, and at H12 the no-politics reference is 3.8 Gt below the
   uniform-price reference (§3.1, disclosed).
9. **The constant-limit hold-the-budget runs were still settling** (§3.4). EU21 hold the budget with the growing
   limit meets the budget at 2100 but does not peak from either start, and with erosion 2% it peaks after 2100 above
   the budget (§3.4): disclose both with any hold-the-budget number from them.
10. **Every φ is conditional on modelling choices the data do not settle** — the specification family, the curve
    shape, the frontier error structure (`MODEL.md` §3.4.1), the institution projections, the hold rule. No φ here is
    a measured property of a region.
11. **Which sector binds** is split on `v7` (11 / 9 of 21 at EU21) and moves with the frontier rung and the weights
    (`MODEL.md` §3.4.1). Do not write it as a fact about regions.

---

## 6. Diagnosis: mechanisms that shape every result

### 6.1 The reference path is the hidden driver

The level cap acts on the *increment* over the current-policy price `SSP2[-EU21]-NPi2025` (REMIND
3.7.1, shared with `v6`). Its 2050 price, the higher of the two markets:

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

Regions with near-zero reference prices have almost all of their cost-optimal price exposed to φ — on `v7` that
includes the most constrained region, REF.

**The US reference is negative by REMIND's input, not by the coupling.** REMIND's `NPi2025` realization
(`45_carbonprice/NPi2025/datainput.gms`) holds the price from 2030 at the input value
`fm_taxCO2eqHist("2030")` for the USA and SSA, and the input data (revision 8.24) give the USA **−\$6.16**
(after \$24.6 in 2020 and \$12.3 in 2025; SSA \$5.71). Under the level cap the US increment is therefore $A + 6.2$,
and $P^{*} = -6.2 + \varphi\,(A + 6.2)$. Quote any US number with its reference: "against a current-policy path that
turns the US carbon price slightly negative from 2030".

### 6.2 Why φ = 1 − θ·k for some regions — it is a *ranking*, not a capability

```
phi_{r,s}(t) = 1 - theta * k_s(t) * u_{r,s}       u = (gap - gap_min) / (gap_max - gap_min), at 2023
```

`u` is the region's **position between the best and worst region**, per sector, read once at the
anchor year. The largest gap is handed u = 1, the smallest u = 0; **both endpoints are guaranteed by
construction**. In 2025 (k = 1) φ = 0.50 at θ = 0.50 means "ranked last"; later φ rises as k(t) falls.

In the batch (`-PFMlevelBfix-v7`, θ = 0.50, the 2025 share): **EU21** floor **REF** (both sectors), then NES 0.52
(buildings & transport) and ECS 0.57; top **NEN 0.993**, median 0.692; **H12** floor **REF**, then OAS 0.63 (power &
industry); top **CHA 0.861**, median 0.720. The `v6` floor pair (CHA in buildings & transport, IND in power & industry)
is gone: the ranking moved with the `v7` specification.

**For the paper.** Do not write "Russia can only sustain 50% of the cost-optimal price". Write "this region ranks at
the bottom of the feasibility distribution in both sectors; how far below the rest is set by θ, a parameter we
declare."

### 6.2a Which sector binds, at region level

From `p45_pfmPhiMkt` of `-PFMlevelBfix-v7` (the 2025 share):

| | Buildings & transport binds | Power & industry binds | tie |
|---|---:|---:|---:|
| **EU21 regions** | **9** — NES, ECS, EWN, IND, ESW, FRA, USA, CHA, UKI | **11** | REF |
| **H12 regions** | **5** — NEU, IND, USA, EUR, CHA | **6** | REF |

The clearest cases at EU21:

| region | ES (buildings & transport) φ | ETS (power & industry) φ | binds |
|---|---:|---:|---|
| Non-EU S. Europe (NES) | **0.522** | 0.909 | **buildings & transport**, by 0.387 |
| West-North Europe (EWN) | **0.663** | 0.870 | **buildings & transport**, by 0.207 |
| Canada/Australia/NZ (CAZ) | 0.949 | **0.779** | **power & industry**, by 0.170 |
| Other Asia (OAS) | 0.768 | **0.609** | **power & industry**, by 0.159 |
| Russia & reforming (REF) | **0.500** | **0.500** | both at the floor |

**This depends on the frontier error structure and the weights** (`MODEL.md` §3.4.1): offline, with GDP weights,
power & industry binds in 6 / 4 / 8 / 12 of 20 EU21 regions across the four frontier rungs, and 14 of 20 change binding
sector. On `v6` it also followed the specification family (15 of 21 under the both-saturate family, 3 under the
clean-energy-only family, `SCENARIOS-v6` §6.2a); `v7` selects the clean-energy-only family with a democracy weight and
lands in between. A sector φ of exactly 1.000 is a ceiling clamp, not a measurement — do not report "the UK's
electricity and industry face no political constraint". Never quote a country-level figure for a coupled regional
result.

### 6.3 The legislated price floor is off in every run

`cm_taxCO2_lowerBound_path_gdx_ref` defaults to **on**, and
`45_carbonprice/functionalForm/postsolve.gms` applies

```gams
pm_taxCO2eq(t,regi) = max(pm_taxCO2eq(t,regi), p45_taxCO2eq_path_gdx_ref(t,regi));
```

inside the `cm_iterative_target_adj eq 5/7/9` block. **It is 0 in every `v7` row** (the matrix sets it
on both parents), so prices below the reference path are permitted. **Methods must say which policy
world this is**, in one sentence: a feasibility ceiling that cannot bind below legislated policy would
be legislation plus a ceiling; a model that lets a region abolish its ETS is also a choice.

### 6.4 The level-cap ratchet — fixed, confirmed absent

A past defect: the level cap read the optimal price from the run's own already-capped
`pm_taxCO2eq`, collapsing the bound onto the reference within 3–4 calls. `iterativePFM.R` takes it
from `p45_taxCO2eq_anchor`. **Confirmed absent on `v7`**: the lowest 2050 market price under hold the price is
\$148.5 (REF, EU21; \$146.3 H12), against REF's \$4.0 reference.

---

## 7. Needed improvements, in priority order

1. ✅ **Wave 2, the persistence ladder** (2026-10-26, §4.9): erosion leaves about a third of the headline, the
   growing limit doubles it.
2. ✅ **The hold-the-budget re-runs** (2026-10-26): θ = 0.675 and erosion 2.7% peak; the growing limit does not, from
   either start, and is disclosed (§3.4).
3. ✅ **The theory-gate sensitivities** (2026-10-26): the selection does not move (`MODEL.md` §2.4a).
4. ✅ **The coupled figures for `v7`** (2026-10-25): `v6-coupled-theta`, `v6-coupled-arms`, `v6-rulec-relocation` and
   `v6-price-catchup` build for any group from `v6` on with coupled runs, against the previous version. Three figures
   need rows the `v7` batch does not have (`coupled-sector-split`, `coupled-npi-twins`, `markup-counterfactual`: the
   proportional-mode, NPi and markup-off rows) and are listed as not built.
5. ⚪ **Re-run the uncovered-country sensitivities on `v7`** if the paper quotes a data-side band; the `v6` band is not
   a `v7` number.

---

## 8. How to use these in the paper

| display | runs | numbers | must travel with it |
|---|---|---|---|
| **the cost of political feasibility** (quantity headline) | `-PFMlevelBfix-v7` vs `-PFMgateBfix-v7`, both resolutions, with `Th325/Th675`, `-held` | **+99 / +88 Gt** to 2100; θ range 55–145; net CO₂ in 2100 1.3 / 1.2 Gt a year against 0.1 / −0.05 | θ declared; persistence (§4.9); floor-off world; the selection's theory gate |
| **what it rests on** (`v6-coupled-arms`) | the persistence ladder | growing +221, constant +168, fading +99, erosion 2% / 2.7% / 5% +44 / +36 / +19 (EU21); H12 constant +145, erosion 2.7% +32 | κ declared; the growing limit a bound (ADR 0057) |
| **where the abatement goes** (hold the budget) | `-PFMlevelC-v7` vs `-PFMgate-v7`, per region | net −0.7 / +3.2 Gt against 17.1 / 18.4 Gt moved; anchor ×1.21 / ×1.19 | emissions only; never the regional median across resolutions |
| **against `v6`** | §4.10 | headline −16% / −22%; relocation −25% / −8%, composition changed | the change is the specification (ADR 0060), not new evidence on feasibility |
| **Methods: which policy world** | every row | floor off | one sentence |
| **Discussion: the feedback** | the coupled strength | power & industry k 0.71 / 0.67 in 2050 / 2100 | not causal |

**Do not use for:** any `v6` number as current; any number after 2100; "hold the budget cannot hold the budget"; a
regional median compared across resolutions; any floor-region claim without flagging that φ is ordinal; any
country-level binding-sector figure as a statement about regions; any price without naming its market; "the
constraint lands on households" or "on industry" (§6.2a); a US number without its negative reference (§6.1); the GDP
gain without the CO₂ it buys.

---

## 9. How to re-derive every number here

```bash
Rscript analysis/coupled/runCoupledStage.R v7      # extract (coupled-runs.rds), admission, facts, costs,
                                                   # hold-the-budget prices and freeze, convergence audit, provenance
Rscript analysis/checks/gateRefCompare.R v7        # -> gate-ref-compare.rds (the H12 gate, per year)
Rscript analysis/checks/budgetPeak.R v7            # -> budget-peak.rds (which hold-the-budget runs peak)
Rscript analysis/checks/emissions2100.R v7         # -> emissions-2100.rds (net CO2 to 2100, net-zero year)
Rscript analysis/v6/couplingMechanism.R v7         # -> strength-support.rds (k, support, decomposition)
Rscript analysis/v6/ruleCRelocationDecomp.R v6 v7  # -> rulec-relocation-decomp.rds (relocation by period, v6 against v7)
Rscript analysis/figures/build-figures.R --group=v7                    # the figures
```

The extractor keeps the newest run per (resolution, scenario), flags the older ones `superseded`, checks `log.txt`
for `REMIND run finished`, and applies the early-market admission rule (§2.5a).

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
| the strength and options a call used | the run's `pfm-phi-history.rds` (last entry: `k`, `options`, `formulation`) |
| did the markup reach the solver? | `p45_pfmMarkupWritten` vs `p45_pfmMarkupSeen` — different iterations (§3.3) |
| the hold-the-budget rebuild | `p45_pfmBoundCheck_iter` (~1e-6 on call iterations) |
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
