# The PFM ↔ REMIND coupling

*How the two models talk, how to run a coupled scenario, and how to debug one. The
mathematics is `MODEL.md`; the traps that cost whole runs are `PITFALLS.md`.*

**Current state.** Both sides are built and the interface is verified against GAMS itself (§12).
The Run-Group is **`v5`** (deployed spec `X-2079 WGIge|noRoL|VerAcc bothIncAP lev
ctl:GDPq.Pop.Hyd fe:OECDp`, `output/remind-inputs/v5/`, `panel_f8845f66fb39d316`). The scenario set is
**48 scenarios, 24 per resolution** (§3), at the deployed `cm_pfmGapClosure = 0` with `THETA`
(0.325 / 0.675) and `GAPCLOSE` sensitivities.

> ✅ **The `v5` batch is in**: `output/remind-runs/v5/{EU21,H12}/*_2026-09-16_*`, 48 of 48 finished, every log reading
> `group v5`, tier year 2035. Results are read through `SCENARIOS.md` §3–§8 and
> `output/pfm/v5/coupling/coupled-facts.json`. Before another submission,
> `../_archive/_wip/2026-10-01/docs/reference/spec-selection-2026-09-15/CLUSTER-PREFLIGHT.md` and `PITFALLS.md` §1–§3.

What the `v5` batch established about the **interface** (`SCENARIOS.md` §3):

- **The markup arithmetic is live**: `p45_pfmMarkupWritten` = `p45_pfmMarkupSeen` in 47 of 48 runs
  (the exception is H12 `-PFMratioTh325`, at its iteration cap); `p45_pfmPhiMktSpread` is 1.3–2.9
  (EU21) / 0.9–2.0 (H12) in markup-on runs and exactly 0 in all six `-Min` twins and both gates.
- **λ reaches GAMS as configured**: every `cm_pfmGapClosure = 0` log exports
  `Bulk 0.0000 | Diffuse 0.0000`, and the scoping control passes (`-PFMmildProgGapC` ≡
  `-PFMmildProg`).
- **φ is a genuine fixed point**: 3–8 PFM calls per θ > 0 run, 30 of 36 δ sequences contracting
  strictly, every final δ below `cm_pfmConvTol` = 0.002.
- **The θ = 0 gate matches its reference to a tolerance, not bit-for-bit** — 294 of 358 cells differ
  by at most \$0.71 at EU21, 168 of 196 by at most \$0.89 at H12, because the budget loop stops at a
  different iteration (φ is exactly 1 in both). §6.6.
- **The detectors are operative**: `pm_pfmInfesCode = 0` in every coupled run;
  `pm_pfmBudgetWarn` fired on the one budget miss at the iteration cap (EU21 `-PFMlevelC`,
  deviation −14.2). ⚠️ It did **not** fire on H12 `-PFMratioMin`, whose emissions keep rising to
  1068 Gt at 2150 — the warning does not see a post-2100 overshoot of a peak budget (`TODO.md`
  item 32).
- **λ does opposite things in bind modes 1 and 2**, now measured (§11.2b).

---

## 1. What is exchanged

REMIND module `45_carbonprice/functionalForm`, activated by `cm_taxCO2_regiDiff = 11`.

$$\text{REMIND} \xrightarrow{\ \texttt{fulldata.gdx}\ } \text{PFM}
\xrightarrow{\ \texttt{p45\_regiDiff\_phi.gdx}\ } \text{REMIND}$$

`presolve.gms` runs *inside* the Nash loop, so $\varphi$ can respond to the energy system
REMIND has just produced. `$include` is compile-time and cannot change between iterations,
so the exchange mirrors EDGE-Transport's: shell out to R, read the result back through a
gdx. GAMS invokes it with **no arguments**:

```gams
Execute "Rscript -e 'library(pfm); pfm::iterativePFM()'";
```

`iterativePFM()` recomputes the feasible paths along that iteration's drivers, aggregates
countries to regions by final energy, and writes $\varphi_r$, the convergence delta, and —
per bind mode — the price bound $P^{\circ}$ or the mild-progression path.

Since ADR 0042 it also writes **four per-market companions**, each indexed over
`all_emiMkt` — the per-sector share $\varphi^{s}_r$, its closure rate, its price bound and
its mild path — which REMIND turns into per-market markups over the economy-wide floor.
They are exported unconditionally and are inert unless `cm_pfmSectorMarkup = 1`. See §11.

**The loop being closed:** deploying clean energy changes who holds power → changes what
policy is politically possible → changes what the model may deploy next.

$$\text{IAM}(P^{(i)}) \to \text{energy}^{(i)} \to (A^{\text{in}},A^{\text{ic}})^{(i)}
\to (S^{\text{eq}},S^{*})^{(i)} \to P^{(i+1)} \to \text{IAM}$$

---

## 2. Configuration — who owns what

Each coupling call is a **fresh R process**, so settings are split by owner. There is
exactly one home for each.

**GAMS owns the per-scenario switches.** `presolve.gms` writes `pfm-coupling-runtime.yml`
before every call and R overrides its own settings from it — no hand-kept copy can disagree.

| switch | meaning |
|---|---|
| `cm_pfmBindMode` | 1 ratio · 2 absolute cap · 3 mild progression (§4) |
| `cm_pfmTheta` | coupling severity $\theta$; **0 is the uncoupled null** |
| `cm_pfmConvTol` | convergence tolerance on $\varphi$. **0.002** since 2026-08-18; the 2026-08-17 batch used 0.01, at which the 2-call runs cross tolerance on their first comparison and can only *assert* convergence. Governs the PFM loop ONLY — it has no bearing on REMIND's budget-adjustment loop, which is what caps a rule-C run that does not converge (`SCENARIOS.md` §4.3, `TODO.md` item 17) |
| `cm_pfmMaxPrice` | price-explosion guard, **US$/tCO2**. Until 2026-09-11 it was compared against a T$/GtC quantity, i.e. 272x too lax to ever fire (`TODO.md` item 16) |
| `c_pfmIter` | which Nash iterations call PFM — disjoint from `c_edgeTransportIter` |
| `cm_pfmSectorMarkup` | 1 = deliver Bulk/Diffuse as floor + per-market markups (§11) · **0 = collapse with `min`**, bit-identical to pre-ADR-0042 |
| `cm_pfmGapClosure` | **0 (deployed since 2026-09-11)** = the political gap PERSISTS, every gap-closure rate forced to zero · 1 = it closes at the frontier's estimated rates, the declared sensitivity (`startgroup=GAPCLOSE`). Reaches bind modes 1 and 2 **only** — §11.2b |

**What GAMS reports back** (read these, not only `o_modelstat`):

| parameter | meaning |
|---|---|
| `pm_pfmConverged` | 1 once φ has converged |
| `pm_pfmInfesCode` | 0 ok · 1 price explosion · 2 budget-iteration divergence · 3 missing/zero price bound · 4 budget loop stuck against a fully binding cap. Needs `cm_pfmInfesPatience` consecutive flagged iterations |
| `pm_pfmBudgetWarn` / `pm_pfmBudgetWarnDev` | **new 2026-09-14.** 1 when a **budget-forced** run ended on `cm_iteration_max` still outside `cm_budgetCO2_absDevTol`, with the deviation. A **warning, not an infeasibility** — the run is usable and the overshoot is a reportable property. It exists because detector 4 fires only past 10× the tolerance, which left runs 2–20 Gt over budget reporting clean (`SCENARIOS.md` §3.4) |

> ⚠️ **`pm_pfmInfesCode = 0` is not by itself evidence the budget was met.** Check
> `pm_pfmBudgetWarn` too, and on any batch before 2026-09-14 — where neither parameter exists —
> read `p80_globalBudget_absDev_iter` at the last iteration by hand.

**The run folder carries the coupling's whole configuration.** REMIND's own `.Rprofile` is
not used, and nothing in the run folder is edited by hand or changed by PFM while the run is
going. `iterativePFM()` reads two files from the run folder (its working directory when GAMS
calls `Rscript`):

| file | written by | when | holds |
|---|---|---|---|
| `pfm-coupling.yml` | REMIND's `scripts/start/preparePFM.R` | at submission, after the standard `files2export` copy | the Run-Group, `resultsDir`/`modelDir` (`pfm`), the region mapping (the run's own `cfg$regionmapping`), the run's SSP (`weightScenario`, from `cm_GDPpopScen`: the weights **and** the scenario panel's GDP, population and SSP-extension series) and the weight year, the institution rule (`institutions`, from `cfg$pfmInstitutions`; `DATA.md` §5.4), the staged madrat cache, `refGdx: input_ref.gdx` |
| `pfm-coupling-runtime.yml` | `presolve.gms` | before every coupling call | `bindMode`, `theta`, gap closure and the iteration, from the scenario row |

Every path is relative to the run folder, so the folder is self-contained. `preparePFM()` also
copies into `<run>/pfm/` exactly what the coupling opens:
- the spec file, `manifest.json`, `frontier.rds`, `temporal-validation.rds` and the two
  donor-band files;
- the panel named by `panel_hash`;
- the staged madrat cache (ADR 0047);
- `phi-override.yml`, if the Run-Group carries one;
- `phi-anchor.rds`, the v6 anchor artifact (step `pfm-anchor`, design note 0005 C6), if the
  Run-Group carries one. A stale copy in a reused run folder is removed. Nothing reads it yet: the
  v6 coupling path (0005 Phase 3) will.

The `pfm-coupling.yml` mechanism dates from 2026-08-11. It replaced setting PFM options in
REMIND's `.Rprofile`, a file shared by every run, not per-scenario, and carrying absolute
paths. Bind mode and $\theta$ are deliberately absent from `pfm-coupling.yml`, so the
scenario row is the only place they are set.

On the REMIND side, `config/default.cfg` holds the only settings:

```r
cfg$pfm <- list(source = "../../output/remind-inputs",   # one folder per Run-Group, seen from models/remind_pfm*
                weightYear = 2025)
cfg$pfmGroup <- ""   # scenario-config column `pfmGroup`; empty = see below
cfg$pfmInstitutions <- "storyline"   # column `pfmInstitutions`: storyline | convergence | hold
```

A run is coupled when `cm_taxCO2_regiDiff = 11`. The Run-Group is taken from the scenario row's
`pfmGroup`, else the `PFM_GROUP` environment variable, else `cfg$pfm$group`, else auto-detected
as the only group under `cfg$pfm$source`. The spec file identifies a group,
`selected-models-pfm.yml`, or `selected-models-psm.yml` for groups exported before the rename.
Everything else is derived from the run, as in the table. The scenario panel is built on the
group's own panel definition (years, smoothing, IEA edition, geothermal), read from the exported
`manifest.json` (`DATA.md` §3), never from the run.

**Offline calls** have neither file: tests, `tools/replayCouplingCall.R` (which builds the run
folder with `preparePFM()` itself) and analysis scripts. `iterativePFM()` then uses its
arguments, whose defaults read these R options. None of them plays any part in a REMIND run.

| option | default | note |
|---|---|---|
| `pfm.resultsDir` / `pfm.modelDir` | `"pfm"` | the Run-Group folder and the panel store |
| `pfm.couplingGroup` | `"v5"` | the Run-Group |
| `pfm.couplingRefGdx` | none | NPi gdx for $P^{\text{ref}}$; required for bind mode 2 |
| `pfm.couplingMapping` | `regionmapping_21_EU11.csv` | delivery resolution |
| `pfm.gdxRegionMapping` | `regionmapping_21_EU11.csv` | the gdx's **own** native resolution (a property of the gdx, not a target) |
| `pfm.couplingWeightScenario` | `"SSP2"` | SSP for the weight projection; **must match the gdx's SSP** |
| `pfm.couplingWeightYear` | `2025` | year the weights represent, as in the deployed runs |
| `pfm.couplingInstitutions` | `"storyline"` | institution rule of the scenario panel (`DATA.md` §5.4) |

---

## 3. The scenario set

**`SCENARIOS.md` is the long-form guide** to what every run is for, what it currently says, and
what may not be concluded from it. This section is the short version.

**`models/remind_pfm/config/scenario_config_PFM.csv` is GENERATED**, by
`analysis/run-groups/buildPFMScenarioConfig.R`, from REMIND's own `config/scenario_config.csv`.
Every row is *its canonical parent plus a named delta* — nothing else may differ.

Both scripts live in **`analysis/`**, deliberately: they are project tooling and are not
committed to the REMIND fork. Run them from the project root, not from `models/remind_pfm/`.

```bash
Rscript analysis/run-groups/buildPFMScenarioConfig.R
Rscript analysis/run-groups/validatePFMScenarioConfig.R models/remind_pfm/config/scenario_config_PFM.csv
```

The validator exits 1 on any error, so it can gate a submission. Every check in it
corresponds to a defect that shipped and produced a run that looked fine — most importantly
`carbonprice` not being `functionalForm`, which makes `cm_taxCO2_regiDiff = 11` **inert** and
the run silently uncoupled.

> **Why generated.** Hand-copying did not hold. Until 2026-08-17 every coupled PkBudg1000 row
> was a copy of the canonical **PkBudg750** with `cm_budgetCO2from2020` set to 1000: all seven
> of its non-coupling differences from `SSP2-EU21-PkBudg1000` matched PkBudg750 exactly
> (`cm_rcp_scen` rcp20/rcp26, `cm_taxCO2_startyear` 100/75, `cm_peakBudgYr` 2055/2080,
> `cm_taxCO2_regiDiff` 6/7, `cm_wasteIncinerationCCSshare` 0.9/0.5, `cm_CESMkup_ind`
> Elec_Push/blank, `cm_EDGEtr_scen` Mix4ICEban/Mix3ICEban). The runs carried a 750 Gt
> scenario's climate target, transport pathway and industry markup while being compared
> against a genuinely-1000 Gt baseline.

**The delta, in full.** Budget parents already use `carbonprice = functionalForm` with a
`path_gdx_ref`, so a coupled budget row changes only `cm_taxCO2_regiDiff` (7 → 11, or 0 for the
gate reference), adds `cm_pfmBindMode`/`cm_pfmTheta`/`cm_pfmConvTol`, and sets
`cm_iterative_target_adj → 0` for the variants that drop the budget forcing. NPi parents carry
no carbon price, so their twins additionally need `carbonprice`, an anchor (taken from the same
resolution's PkBudg1000 parent), `cm_startyear = 2030` and a `path_gdx_ref`.

**24 scenarios per resolution, 48 in total**, identical in structure at H12 and EU21
(`models/remind_pfm/config/scenario_config_PFM.csv`):

| group | scenarios (prefix `SSP2-` at H12, `SSP2-EU21-` at EU21) |
|---|---|
| baselines | `NPi2025`, `PkBudg1000` — verbatim canonical copies |
| nulls | `PkBudg1000-PFM{gateRef,gate,gateB}`, `NPi2025-PFMgate` |
| science | `PkBudg1000-PFM{ratio,levelB,levelC,mildProg}` |
| NPi twins | `NPi2025-PFM{ratio,level,mildProg}` |
| markup-off twins | `PkBudg1000-PFM{ratioMin,levelBMin,levelCMin}` |
| `<res>THETA` | `PkBudg1000-PFM{ratio,levelB}Th{325,675}` |
| `<res>GAPCLOSE` | `PkBudg1000-PFM{ratio,levelB,levelC,mildProg}GapC` |

There is no `-PFMref`/`-PFMbase` — after alignment those are the baselines run twice — and no
750 Gt rows, which nothing referenced.

**Running them.** The two resolutions are separated by the `start` column, not by separate files. The start groups and the commands are listed once, in `SCENARIOS.md` §2.5. No row carries REMIND's default tag `1`, so a bare `start.R` starts nothing.

The config file is a **positional** argument — `start.R:74` strips anything beginning with `-`
or containing `=`, so a `--scenario_config=…` form is silently discarded and you land in the
interactive chooser. `start.R` chains on `path_gdx_ref` (`RunsUsingTHISgdxAsInput`), so one
submission per family is enough: the NPi baseline runs first and the rest follow.

**Four different runs are called a "null" and they are not interchangeable.** Naming the wrong
one makes a difference unattributable:

| null | what it holds fixed | what a difference against it means |
|---|---|---|
| `-PkBudg1000-PFMgateRef` | `regiDiff = 0`, uniform price | the *interface* is wrong (§6.6) — not a finding |
| `-PkBudg1000-PFMgate` | `regiDiff = 11`, θ = 0, `adj = 9` | the effect of φ under a **held budget** |
| `-PkBudg1000-PFMgateB` | `regiDiff = 11`, θ = 0, `adj = 0`, **bind mode 1** | the effect of the political **cap** — the control for headline B |
| `-NPi2025-PFMgate` | `regiDiff = 11`, θ = 0, current policies | the effect of φ on **any** price path |

> ⚠️ **A bind mode 2 run at θ = 0 is not an uncoupled null.** The cap $\varphi P^{\circ}$ still
> binds through the speed limit $\lambda$ — §9. That is why `-PFMgateB` is bind mode 1.

**Mixing resolutions in one model folder is safe**, for three reasons:

- `preparePFM.R:42-43` derives **both** `couplingMapping` and `gdxRegionMapping` from
  `cfg$regionmapping`, so the coupling always matches the run it is inside. Nothing in
  `config.yml` or the Run-Group is resolution-specific.
- `prepare.R:85` holds `model_lock()` across `updateInputData()` (line 150), which re-extracts
  `input/` whenever the resolution changes. Mixed submissions **serialise** rather than corrupt
  each other. Only two concurrent `start.R` invocations are unsafe.
- Each family carries its **own** `path_gdx_ref` at its own resolution. An H12 run pointing at
  an EU21 baseline reads `input_ref.gdx` against the wrong region set, completes, and reports
  nothing — `validatePFMScenarioConfig.R` check 6 makes that an **error** for every `path_gdx*`
  column.

Price levels are **not** comparable across resolutions, or with anything quoted from the
earlier H12 / 750 Gt pair.

---

## 4. The three bind modes

Run as alternatives because they make different claims.

**Mode R — $\varphi$ bounds the price *ratio*** (`cm_pfmBindMode = 1`)

$$pm\_taxCO2eq_{t,r} = \rho_{t,r}A_t,\qquad \rho_{t,r} = 1-(1-\varphi_r)(1-\lambda_r)^{t-t^0_r}$$

*Claim:* politics changes **where** abatement happens. The budget is always met, so
infeasibility cannot arise. **Weakness:** $\varphi$ multiplies the anchor, so a rising anchor
raises the constrained region's price too — the constraint *weakens as ambition rises*,
which is the regime the paper is about.

> **Mode R is the only mode that builds its path inside GAMS**, so it is the only one that
> needs each sector's closure rate as an explicit symbol for the markup (§11.2). Modes L and M
> receive finished price paths from R with the right speed already baked in.

**Mode L — $\varphi$ caps the absolute *level*** (`cm_pfmBindMode = 2`)

$$pm\_taxCO2eq_{t,r} = \min\big(A_t,\ \varphi_r P^{\circ}_{t,r}\big)$$

$P^{\circ}$ from `exportFeasibilityBound()`. *Claim:* politics caps **how much** a region can
do. The budget may become unreachable — **that is the finding, not a bug.**

**Mode M — mild progression** (`cm_pfmBindMode = 3`)

$$P_{t+1,r} = P_{t,r}\Big(1+\lambda_r\frac{S^{*}_{t+1,r}-S_{t,r}}{S_{t,r}}\Big),\qquad P_{t_0,r} = P^{\text{NPi}}_{t_0,r}$$

*Claim:* where does observed political momentum take us? The price is **generated** by the
political dynamics, not constrained — no anchor, no budget, so it cannot be infeasible.

> ⚠️ **Two gap definitions coexist and must not be conflated.** Mode M uses $(S^{*}-S)/S =
> 1/E-1$, relative to *current* stringency and **unbounded** as $S\to0$; everything else uses
> $1-E$, relative to the frontier and bounded in $[0,1]$. A `maxGrowth` cap bounds the
> recursion and reports `cappedShare` — a path with a high capped share is driven by the cap,
> not by the politics.

**Conflict rules (mode L only)**, when the political bound and the carbon budget are jointly
unsatisfiable:

| rule | mechanism | headline it supports |
|---|---|---|
| **B** | drop the budget forcing (`cm_iterative_target_adj = 0`) | *political feasibility costs $X$ Gt CO₂* |
| **C** | keep the budget, report the required violation | *region $r$ must sustain $N\times$ its feasible price* |
| **D** | allow the budget to be met later | *politics delays the price path by $N$ years* |

B and C are the same experiment read from opposite ends.

---

## 5. Convergence

The coupling is a fixed point: the energy system moves the gaps, which move $\varphi$, which
moves the price, which moves the energy system. Converged when

$$\delta = \max_r\big|\varphi_r^{(n)} - \varphi_r^{(n-1)}\big| \le \texttt{cm\_pfmConvTol}$$

A **max**, not a mean — one region still moving keeps the loop open. **Since 2026-10-02 the max
also runs over every per-market share** $arphi_{r,s}$ (`p45_pfmPhiMkt`), not the floor alone
(design note 0005 E8): with the floor only, a market share could still be moving when the run was
declared converged. `pfm-phi-history.rds` records the market shares with each call; an entry
written before that contributes its floor only. The first call has no
predecessor and is non-convergent by construction. After convergence $\varphi$ is **frozen**,
never reset; the price is still rebuilt every iteration because the budget iteration keeps
moving the anchor.

**Nash cannot converge while $\varphi$ is still moving.** `80_optimization/nash` carries a
`pfm` criterion blocking `s80_bool`, so the two loops close *together* — otherwise Nash could
settle on a price the political layer no longer agrees with. Damping is strong: since
$\lambda \le 0.16$, one iteration moves the feasible path by at most ~16% of the remaining gap.

**Report the iterate norms. Convergence must be demonstrated, not asserted.**

**Infeasibility detection** (requires `cm_pfmInfesPatience` consecutive hits):

| `pm_pfmInfesCode` | meaning |
|---|---|
| 1 | price explosion above `cm_pfmMaxPrice` — the **silent** failure: the solve succeeds and the numbers look like results |
| 2 | budget iteration diverging — expected under mode L with a binding cap |
| 3 | missing or zero price bound / mild-progression path |

---

## 6. Running one

### 6.1 Sync and install

The cluster workspace is created and updated with `tools/setup.sh --cluster`. The steps are in
the root `README.md`, "On the cluster": the project repo, the model repos in `models/`, the
madrat cache, the package installs, and the per-checkout install that REMIND's own R library needs.
The cluster builds from the git remote, so push first. Unpushed means not run (`PITFALLS.md` §2).

### 6.2 Install both packages

`tools/setup.sh --install` installs `mrpfm` and then `pfm`. A stale `mrpfm` has cost test
errors before; installing only `pfm` is not enough.

### 6.3 Artifacts the coupling reads

The Run-Group must contain `selected-models-pfm.yml`, `manifest.json`, `frontier.rds`,
`temporal-validation.rds` and **`donor-assignment-band-{Bulk,Diffuse}.rds`**. The band files
are not optional — `iterativePFM()` **errors** without them rather than silently reverting to
$\varphi = 1$.

### 6.4 Verify the mapping actually resolves

```bash
Rscript -e 'cat(madrat::getConfig("mappingfolder"),"\n");
  m <- madrat::toolGetMapping("regionmapping_21_EU11.csv", type="regional", where="mappingfolder");
  cat("regions:", length(unique(m$RegionCode)), "\n")'
```

Expect 21. **Editing a mapping is not installing one** — see `PITFALLS.md` §1.

### 6.5 Regenerate and validate the scenario config — this gates submission

```bash
Rscript scripts/start/buildPFMScenarioConfig.R
Rscript scripts/start/validatePFMScenarioConfig.R config/scenario_config_PFM.csv
```

Exit code 1 on any error. It catches defects that have actually occurred: dangling
`path_gdx*` names, a coupled row with no bind mode, bind mode 2 without a reference run,
sheared field counts, a missing $\theta = 0$ gate, and a `path_gdx*` pointing at a run at a
**different regional resolution**.

### 6.6 First run is always the θ = 0 correctness gate

**Do not start with the science run.** At $\theta = 0$ every $\varphi$ is 1, so
`-PkBudg1000-PFMgate` (bind mode 1 — no price bound, smallest surface area) must reproduce
`-PkBudg1000-PFMgateRef` **exactly**. Any difference is an interface bug, not a finding.
Submission commands are in §3.

What to check:

| where | expect |
|---|---|
| runtime log | `iterativePFM` entries at the `c_pfmIter` iterations |
| GAMS listing | `p45_regiDiff_phi` displayed, all ≈ 1 at θ = 0 |
| | `p45_pfmMaxPrice`, `p45_pfmInfesCode` — **must be 0** |
| run dir | `p45_regiDiff_phi.gdx`, `pfm-phi-history.rds`, `pfm-coupling-runtime.yml`, `pfm/hist-harmonisation-cache.rds` (from the first call; 0005 E17) |
| convergence | Nash blocked until φ settles |
| emissions | **identical** to `-PkBudg1000-PFMgateRef` |

Then work up the ladder: `-PFMratio` → `-PFMlevelC` → `-PFMgateB` → `-PFMlevelB` →
`-PFMmildProg` → the NPi twins.

### 6.7 Failure modes

| symptom | cause |
|---|---|
| φ stays exactly 1 every iteration | the Rscript call failed; **check the runtime log** — GAMS keeps the previous φ by design and does not stop |
| `iterativePFM: missing band assignment` | §6.3 incomplete |
| `bind mode 2 … no feasibility bound` | no reference gdx: in a REMIND run, `input_ref.gdx` (REMIND's copy of `path_gdx_ref`, declared in `pfm-coupling.yml`) is missing; offline, `refGdx` / `pfm.couplingRefGdx` unset — a deliberate refusal, not a crash |
| `p45_pfmInfesCode = 1 / 2 / 3` | see §5 |
| converged after one call | check `p45_pfmDelta` is region-indexed, not `GLO` |
| regions look shuffled | the gdx returns regions **alphabetically**; never index positionally |

---

## 7. The gdx contract — established against GAMS, not assumed

Four defects invalidated every coupled run before 2026-08-13; all are fixed, and the rules
they establish are permanent.

**Write with GAMS Transfer; read with `gdx::readGDX`.** Both halves are evidence-based:

- *Write* — `gamstransfer` carries real domain **sets** into the gdx, so a region-first record
  against a `(ttot, all_regi)` domain is **refused at write time**. `gdxrrw::wgdx.lst` has no
  domain concept and wrote it happily. Migration verified value-identical: 336 identical
  non-zero records, max abs difference 0.000.
- *Read* — the read sites return **magpie** consumed immediately by magclass sub-dimension
  selection; converting to data frames would reintroduce the exact df→magpie step that caused
  the defects, for no defect prevented. The read path cannot have this class of bug: the
  rank/order contract exists only because *we* hand symbols to GAMS.

**Three rules that are not negotiable:**

1. **Index order is `(ttot, all_regi)` — year FIRST.** A region-first symbol has the correct
   rank, loads with **no error at all**, and yields `( ALL 0.000 )`. That is worse than a
   rank mismatch, because nothing anywhere reports it.
2. **Year UELs must be bare `"2030"`**, not magclass's `"y2030"`, or every record is dropped.
3. A domain-less (`*`) symbol is **not** broken — `Execute_Loadpoint` matches by UEL label.
   Only rank and index order are fatal. Do not flag `*` domains as a failure.

**The ADR 0042 companions carry a market dimension** (since 2026-08-17). The ADR originally
rejected the extra rank — defect 4 *was* a rank/order failure — but the symmetric markup
needs both sectors delivered, which is 8 flat parameters against 4 indexed ones, so the
gain is now real. The trap is answered by `.pfmVerifyCouplingGdx()` and
`test-gdxRoundTrip.R`, not by avoiding the rank. **Note the two rank-2 families lead with
different indices** — `(ttot, all_regi)` vs `(all_regi, all_emiMkt)` — which is exactly the
confusion the order defect was made of, so both are pinned by tests:

| symbol | rank | domain |
|---|---|---|
| `p45_regiDiff_lambda` | 1 | `(all_regi)` — the economy-wide floor rate, §11.2a |
| `p45_pfmPhiMkt` | 2 | `(all_regi, all_emiMkt)` — **region first** |
| `p45_pfmLambdaMkt` | 2 | `(all_regi, all_emiMkt)` — **region first** |
| `p45_pfmPriceBoundMkt` | 3 | `(ttot, all_regi, all_emiMkt)` |
| `p45_pfmMPPriceMkt` | 3 | `(ttot, all_regi, all_emiMkt)` |

The four original defects, for the record: magpie matrix indexing (`pb[cbind(...)]` is invalid
on a 3-D magpie); bind mode 2 running at a zero carbon price for iterations 1–14; the NPi twins
never reaching the solver (`carbonprice = functionalForm` needs a positive
`cm_taxCO2_startyear`/`peakBudgYr`, a `path_gdx_ref`, and `cm_startyear > 2005`); and the gdx
rank/order defect above.

### 7.1 Defect 5 — φ erased between presolve and the solve (fixed 2026-08-16)

**Where φ has to survive to.** `core/loop.gms:54-55` runs `core/presolve.gms` **before** the
module presolves, and `core/presolve.gms:10` is where `pm_taxCO2eq` becomes `pm_taxCO2eqSum`
— the parameter the equations actually see. So the solve consumes whatever `pm_taxCO2eq` was
left holding at the **end of the previous iteration**, i.e. after postsolve. Setting it in
`45_carbonprice/functionalForm/presolve.gms` alone is not enough.

**What went wrong.** `postsolve.gms` Step III.3 recomputes `p45_regiDiff_ratio` for every
`cm_taxCO2_regiDiff` except 0 and 3. Its `= 11` branch was missing — the sibling Step III.1
had one — so mode 11 fell through to the convergence-scenario else-branch, and because
`p45_regiDiff_endYr = 0` for mode 11 (`datainput.gms` Step III.2), the line
`ratio(t,regi)$(t.val ge endYr) = 1` set the ratio to **1 in every year**. Steps III.4 and
Part IV then rebuilt `pm_taxCO2eq` uniform. φ was computed, applied, and erased again before
the solve ever saw it — while `p45_regiDiff_phi`, `p45_pfmPhi_iter`, `p45_pfmDelta_iter` and
`p45_pfmPriceMean_iter` in the gdx all still reported a perfectly healthy coupling.

**Only budget runs were hit**, because the entire postsolve body is inside
`if((cm_emiscen eq 9) AND (cm_iterative_target_adj in {5,7,9}), …)`.

**The fix, in three parts:**

1. `postsolve.gms` Step III.3 gained the `elseif cm_taxCO2_regiDiff = 11` branch, rebuilding
   the ratio from φ/λ exactly as `datainput.gms` and `presolve.gms` do. **This alone repairs
   mode 1**, which is exactly `ratio × anchor` — Steps III.4 and Part IV then reproduce it,
   keeping the `path_gdx_ref` interpolation every other `cm_taxCO2_regiDiff` mode gets.
2. New `postsolve.gms` **Step IV.4** re-applies bind modes **2 and 3** after Part IV. Step
   III.3 cannot repair those: mode 2's cap is `min(anchor, φ·P°)` and mode 3 carries its own
   generated path, and neither is expressible as `ratio × anchor`, so Part IV's rebuild
   discards them regardless. Those two branches are **mirrored** from `presolve.gms` — the
   module file structure is fixed (`declarations`/`datainput`/`presolve`/`postsolve`/
   `realization`/`input`), so a shared include is not an option and both copies carry a
   `>>> MIRRORS …` marker. Mode 1 is deliberately *not* mirrored.
3. A guard at the **top** of `presolve.gms` — before the coupling call, before the ratio is
   rebuilt — aborts if `p45_regiDiff_ratio` is uniform while φ is not. It has to read the
   ratio as the previous postsolve left it; anywhere later in the file presolve has already
   repaired the damage and hidden it, and after the coupling call the first call (φ non-uniform,
   ratio still legitimately uniform) would false-fire.

> ⚠️ **The θ = 0 gate cannot detect this class of defect and never could.** At θ = 0, φ = 1
> and the wipe is a no-op, so `-PFMgate` reproducing `-PFMgateRef` exactly is a true result
> that proves nothing about whether φ reaches the solver. §6.6 is necessary and not
> sufficient. The check that *does* catch it is the guard above, plus asserting on any
> finished θ > 0 run that `p45_regiDiff_ratio` in `fulldata.gdx` is not identically 1.

---

## 8. Diagnostics

Nine `p45_pfm*_iter` parameters are written **every** iteration, including those between
coupling calls — which is where the budget iteration moves the anchor while φ is held fixed.

| parameter | what it shows |
|---|---|
| `p45_pfmDelta_iter` | φ convergence path — the headline chart |
| `p45_pfmPhi_iter(iteration,regi)` | per-region φ trajectory |
| `p45_pfmPriceMean_iter` | **PFM → IAM**: the price the political layer imposed |
| `p45_pfmBoundMean_iter` | **IAM → PFM**: the bound the energy system implied |
| `p45_pfmBindShare_iter` | how hard the political cap bit |
| `p45_pfmMaxPrice_iter`, `p45_pfmInfes_iter` | explosion watch, infeasibility code |
| `p45_pfmAnchor_iter`, `p45_pfmConverged_iter` | the budget iteration; when φ settled |
| `pfm-phi-history.rds` | the R-side record, independent of GAMS |

The two mean-price series are the **mutual-influence pair**: read together they show whether
the two models converged toward each other or one simply dominated.

---

## 9. The PFM-side bound

From `output/pfm/v5/coupling/coupling-summary.rds`, built against the EU21 NPi2025 ($P^{\text{ref}}$)
and PkBudg1000 ($P^{\circ}$) gdxs recorded in `$refGdx` / `$optGdx`: 21 regions, tier year 2025,
48 in-coverage countries, final-energy weights, sector rule `min`, published λ as the speed limit.

| $\theta$ | median 2050 feasible price | 2050 shortfall vs cost-optimal | max regional shortfall |
|---:|---:|---:|---:|
| 0 (null) | \$228.7 | 35.5% | \$131.1 |
| 0.25 | \$221.6 | 37.5% | \$178.5 |
| **0.50** (declared) | **\$215.1** | **39.4%** | **\$226.0** |
| 0.75 | \$205.5 | 42.1% | \$273.5 |
| 0.95 | \$197.8 | 44.2% | \$311.4 |
| 0.99 | \$196.3 | 44.7% | \$319.0 |

Cost-optimal 2050 median: \$354.8/tCO₂. Median 2030 feasible price runs \$37.9 → \$33.3 across the
same range. At θ = 0.50: median φ 0.669, floor regions **CHA, REF**, UKI unconstrained.

**Binding share is 84.5% of region-years at every $\theta$** — the *share* is set by the shape of
the paths, not by the severity parameter; $\theta$ sets how far below the bound sits.

> ⚠️ **At $\theta = 0$ the bound is not the cost-optimal path.** It still shows a 35.5% shortfall,
> because the speed limit $\lambda$ binds even when $\varphi = 1$. The $\theta = 0$ **REMIND run**
> reproduces the reference; the $\theta = 0$ **bound** does not. Two different objects — say which
> one is meant wherever the null is discussed. Note also that inside REMIND at the deployed
> `cm_pfmGapClosure = 0` the speed limit is off, and φ is read at 2035, not 2025.

> ⚠️ **The offline grid is not the coupled sweep.** The bound sweeps 0 / 0.25 / 0.50 / 0.75 / 0.95 /
> 0.99; the coupled runs use 0 / 0.325 / 0.50 / 0.675. Always read `anchorTheta` out of the artifact
> and state it: two artifacts written at different anchors are not comparable region by region.

---

## 10. Entry points, and what was retired

**`pfm::pfmRun()` is the single entry point** for all compute:

```r
pfmRun(group = "v5", stage = "sweep",       cluster = "slurm")  # estimation + selection
pfmRun(group = "v5", stage = "diagnostics", cluster = "slurm")  # inference + the replay gate
pfmRun(group = "v5", stage = "downstream",  config = "config.yml")
pfmRun(group = "v5", stage = "remind",      remindDir = "../../output/remind-inputs")
pfmRun(group = "v5", stage = "all",         cluster = "slurm")  # all 13 steps, in order
```

Stages: `sweep` (pfm-sweep, -frontier, -temporal, -sector-speeds) · `diagnostics`
(pfm-agreement, -iv, -influence, -replay) · `downstream` (pfm-donor, -projection,
-coupling-bound, -selection-bootstrap) · `remind` (pfm-remind-inputs) · `all` (every step, in
dependency order) · `custom`. Called with no arguments it runs interactively and shows its plan
before doing anything.

> **Fixed 2026-08-14.** `stage = "all"` previously assembled itself from the other stages and so
> **skipped the four diagnostics entirely** — they were reachable only through the interactive
> `custom` menu, so a Run-Group built before the fix could lack `estimator-agreement.rds`,
> `iv.rds`, `influence.rds` and `historical-replay.rds` despite a clean run. `test-pfmRun.R` now pins
> the contract that every stage is a subset of `all`.

**Retired in favour of it** (both in `../_archive/_wip/2026-08-14/root-scripts/`):

- `run-sweep-slurm.sh` → `pfmRun(..., cluster = "slurm")`.
- `replay-coupling.R` → **its GAMS half is now `pfm::pfmReplayInterface()`** (TODO item 7, done
  2026-08-17); see §12. The rest of it — replaying a whole coupling call from a finished
  `fulldata.gdx` — still has no equivalent. It replayed the coupling call from a
  finished `fulldata.gdx` in ~90 s instead of a 2–4 h run, in two stages: `[R]` ran
  `iterativePFM()` in a folder staged exactly as `preparePFM.R` stages it, and `[GAMS]`
  generated a stub declaring the symbols as `functionalForm/declarations.gms` does, ran the
  same `Execute_Loadpoint` statements, and checked `execError`. **The GAMS half is what
  `log.txt` cannot show you** — a GAMS execution error surfaces only in `full.lst`, and REMIND
  defers the abort to the next solve, hours later, reported as an unrelated infeasibility.
  If the interface breaks again, retrieve it from the archive rather than re-deriving it, and
  §12 is its replacement.

---

## 11. Sector-differentiated delivery — per-market markups (ADR 0042)

The PFM estimates **two** sectors. Before 2026-08-17 the coupling collapsed them with `min`
and delivered one economy-wide price, throwing away one sector's estimate wherever the two
disagree. (The "~94% of countries" figure this sentence used to carry was computed on S/10 and
is retracted — `PITFALLS.md` §22; on $E$ the split is 33/67 at the tier year. The ADR's
reasoning is unaffected: it rests on the two sectors being separately estimated.) `min` of two noisy estimates is also biased
low — *in the direction that inflates the paper's headline*.

### 11.1 What is delivered

`min` **still applies**, but as the **floor**, not the whole answer:

| quantity | REMIND parameter | sector | markets |
|---|---|---|---|
| economy-wide floor $P^{*}$ | `pm_taxCO2eq` | most-constrained combination (`sectorRule = "min"`) | all |
| per-market markup | `pm_taxemiMkt(m)` | that market's own sector, minus the floor, clamped at 0 | each |

$$P^{m} = \texttt{pm\_taxCO2eq} + \max\!\big(P^{\text{sector}(m)} - \texttt{pm\_taxCO2eq},\ 0\big)$$

**Symmetric since 2026-08-17.** The first version added the markup on ETS only and set
ES and other to zero. That capped the demand side at the Bulk price wherever **Bulk** was
the worse sector — **14 of 48 countries** on the deployed frontier, discarding up to 0.30
of Diffuse $\varphi$ (ISL 0.30, ZAF 0.27, RUS 0.21) — reintroducing on the other sector
exactly the information loss ADR 0042 exists to remove.

> **The invariant:** floor + markup(*m*) reproduces market *m*'s own sector price
> **exactly**. Neither sector is capped by the other. `min` is arithmetic that keeps the
> markup non-negative, not a modelling step that discards a sector.
>
> ⚠️ **It is *not* true that exactly one markup is positive.** `sectorRule = "min"` takes
> the worse *share* **and** the slower *speed*, and those can come from different sectors.
> The floor is the most-constrained **combination**, belonging to neither sector, and can
> sit strictly below both sector prices — in which case both markups are positive.
> Markups are still never negative. But `pm_taxCO2eq` is then a price **no market
> actually faces**, and every consumer of `pm_taxCO2eqSum` sees it: the MAC curves, the
> land-use tax, the trade tariffs, the net-negative penalty. Conservative, deliberate,
> and a real distortion. Pinned by `test-exportFeasibilityBound.R`.

**Why a markup, not a second price.** `pm_taxemiMkt` is *additive*: `q21_taxrevGHG` charges
`pm_taxCO2eqSum` on all CO₂eq and `q21_taxemiMkt` then adds `pm_taxemiMkt(m) * vm_co2eqMkt(m)`
per market. Keeping the floor in `pm_taxCO2eq` means every other consumer of
`pm_taxCO2eqSum` — the MAC curves in `core/presolve.gms`, the biofuel emission factor, the
trade tariffs — keeps working untouched. Putting the whole price into `pm_taxemiMkt` would
have required auditing all of them.

**Sector ↔ market.** One place only: `.pfmSectorMarkets()` in `iterativePFM.R`.

| PFM sector | markets |
|---|---|
| Bulk (electricity + industry) | `ETS` |
| Diffuse (buildings + transport) | `ES`, `other` |

`other` follows `ES` deliberately — REMIND's own convention
(`47_regipol/regiCarbonPrice/postsolve.gms:409` does `other = ES`) and it matches the
mapping this ADR states. Under the asymmetric version `other` silently kept the floor.

Not a bijection: `sector2emiMkt` puts `indst` in **both** ETS and ES, so industry's ES
slice receives the Diffuse price. Deliberate, and it errs toward *less* differentiation —
i.e. toward the old `min`.

**Why `pm_taxCO2eq` is not simply zeroed** (the "put the whole price in `pm_taxemiMkt`,
like module 47" option): `pm_taxCO2eqSum` feeds the MAC curves via `p_priceCO2`
(`core/presolve.gms:246`), the land-use CO₂ tax (`q21_taxrevCO2luc`), the CO₂ sector
markups, the carbon trade tariffs (`q21_tau_Import`) and the net-negative penalty
(`q21_taxrevNetNegEmi`). Zeroing it silently zeroes **all** of them — most importantly
every MAC curve, i.e. all non-CO₂ and process abatement. REMIND *does* have a repair
block that rebuilds `p_priceCO2` from `pm_taxemiMkt` (`core/presolve.gms:255-270`), but
it is gated on `cm_emiMktTarget`, which §11.5 aborts on. **It is unreachable from a
coupled run**, which is why module 47 can take that route and the PFM cannot.

### 11.2 Each sector's own closure rate (fixed 2026-08-17)

Modes 2 and 3 receive finished **per-sector price paths** from R, built with
`sectorRule = <sector>` and that sector's own $\lambda$. **Mode 1 rebuilds its path inside GAMS** from
$\varphi$ and a rate, and originally reused `p45_regiDiff_lambda` — which, having come
through `sectorRule = "min"`, is the **slower** speed (on `v5`: Diffuse 0.0769/yr against Bulk's
0.1094/yr). The mode-1 markup therefore closed on the anchor too slowly for the faster sector.

Fixed by exporting `p45_pfmLambdaMkt` and using it at the mode-1 branch. It defaults to
`p45_regiDiff_lambda`, so an absent export reproduces the old behaviour exactly rather than
inventing a rate.

> **If you add a fourth bind mode, ask which side builds the path.** R-side modes get each
> sector's speed for free; a GAMS-side mode must read `p45_pfmLambdaMkt` explicitly.

### 11.2a The economy-wide closure rate — the other half of 11.2 (fixed 2026-09-11)

The sentence above — "`p45_regiDiff_lambda`, having come through `sectorRule = "min"`, is the
slower speed" — described the **design**. It was not what ran. In a coupled run that parameter
had come through nothing at all:

- `datainput.gms:186` sets it to 0;
- the seed `.inc` from `exportFeasibilityRegiDiff()` writes 0, its documented "the gap
  persists" default;
- `presolve.gms` loaded **only** `p45_pfmLambdaMkt`, never the economy-wide rate.

So every coupled run up to and including the 2026-08-26/29 batch built the mode-1 **floor** at
$\lambda = 0$ — `ratio(t) = φ`, flat for the whole horizon — while the markup block closed each
market on the anchor at the per-sector rates. Fixed in code 2026-09-11 and then made moot by §11.2b:
at the deployed setting every rate is zero by decision, so floor and markets agree trivially.

**Be precise about what that broke; the obvious reading is wrong.** A market pays
`pm_taxCO2eq + max(priceMkt − pm_taxCO2eq, 0)` = `max(floor, priceMkt)`, and `priceMkt` was always
the larger, so **the market prices were already the per-sector λ paths and the fix does not move
them.** It moves the floor, up onto the same path. What was actually wrong:

| | |
|---|---|
| **(a)** | `pm_taxCO2eq` was the price nobody paid — yet `core/presolve.gms` turns it into `p_priceCO2forMAC`, so **every MAC curve, i.e. all non-CO₂ and process abatement**, priced off it. In the batch that exposed it, EU21 `-PFMratio` 2050 had a floor of roughly half the market prices, because the floor sat at φ while the markets had closed most of their gap. |
| **(b)** | `pm_taxemiMkt` conflated a **speed** gap with a **sector** gap. Most of the markup was "λ_m > λ_floor = 0", not "this sector can bear more than the worse one", and the *binding* sector — whose markup is zero by ADR 0042's own invariant — carried a large one. |
| **(c)** | the `-Min` twins were **not a clean counterfactual**: `cm_pfmSectorMarkup = 0` also moved λ from the per-sector rates to 0, so the markup-off comparison measured both changes at once. At the deployed `cm_pfmGapClosure = 0` every rate is 0 in both arms and the confound is gone. |


Fixed by giving the economy-wide rate the same treatment as every other coupled symbol:

| | |
|---|---|
| exported | `iterativePFM()`, as `p45_regiDiff_lambda(all_regi)`, rank 1, broadcast over the same regions as φ |
| value | `min(λ_Bulk, λ_Diffuse)` — the same maximin rule that gives the floor `min(φ)` and `max(tier)` |
| loaded | `presolve.gms`, in the coupling block, immediately after φ |
| guard | freshness stamp **plus** `> 0`, exactly as `p45_pfmLambdaMkt` (§11.3), so a failed export reproduces the pre-fix run rather than inventing a rate |
| pinned by | `test-gdxRoundTrip.R` (rank, domain, value, and that the floor rate is the *slower* sector) and the replay declaration check in `test-pfmReplayInterface.R` |

`.pfmSectorLambda()` is the single resolver both exports call, so the floor's `min()` and the
markets' per-sector lookup cannot drift apart again.

### 11.2b `cm_pfmGapClosure` — λ is a declared switch, decided 2026-09-11

The fix above did not settle whether the gap should close at all, and that question is worth
more than the plumbing was. At the estimated Diffuse rate most of a region's political gap closes
by mid-century, so φ = 0.50 ends up paying close to the full anchor; at λ = 0 it keeps paying
0.50 × anchor. **DECIDED: the gap PERSISTS (`cm_pfmGapClosure = 0`), with the estimated rates run
as a declared sensitivity (`GAPCLOSE`)**, because the estimate cannot carry the claim — neither
two-sector rate beats persistence (−0.180 / −0.698 on `v5`) and a placebo battery on panels with
*no adjustment by construction* returns λ̂ = 0.291 / 0.104 on the deployed right-hand side, above
or around the estimates 0.1094 / 0.0769 (`MODEL.md` §4.3.2).

**Validated on the `v5` batch.** `-PFMmildProgGapC` is **identical** to `-PFMmildProg` at both
resolutions (2583.3 / 2589.2 Gt) — the scoping control below passes. The cost of the switch runs in
**opposite** directions in the two bind modes: at λ = 0 the quantity headline is +159.3 / +163.8 Gt
against +254.4 / +266.0 Gt with gap closure (λ = 0 conservative, −37 / −38%; on the unforced anchor
+128.4 / +148.8 against +192.2 / +239.6), while the mode-R regional spread
is 1.88× / 1.76× against 1.10× / 1.09× and the markup written ~7× larger (λ = 0 generous).
`SCENARIOS.md` §1.2.

**One symbol called λ does three different jobs, and the switch may only touch two.** Verified by
running each branch at λ = 0 (`test-exportFeasibilityBound.R`):

| mode | what λ is there | at λ = 0 | switched? |
|---|---|---|---|
| **1** ratio | the **gap-closure rate** in `ratio(t) = 1 − (1−φ)(1−λ)^(t−t₀)`, delivered as `p45_regiDiff_lambda` and `p45_pfmLambdaMkt` | ratio = φ for the whole horizon — exactly "the gap persists" | **yes** |
| **2** level | the **speed limit** on approaching the φ-scaled target, inside `exportFeasibilityBound()` | that function takes its `lamEff = 1` branch, so the bound *is* `P_ref + φ(P_opt − P_ref)` from the first period instead of ramping to it. Note this makes early bounds **higher**, not lower | **yes** |
| **3** mild progression | the **momentum rate** in `P(t+1) = P(t)(1 + λ(S*−S)/S)`. There is no gap and no anchor in mode M; λ *is* the mechanism | the price freezes at its current-policy seed forever (10.0 → 10.0 → 10.0), so the run would report "momentum takes us nowhere" — a tautology produced by the switch | **no** |

Implemented as `lambdaGap` in `iterativePFM()`, distinct from `lambda`, so the scoping is visible
at each call site rather than implied. Getting it wrong in either direction is silent: mode 3
would still solve and still report a number. `TODO.md` item 1e-a.

> ✅ **The `v5` batch is the first full batch on the fix** with `cm_pfmGapClosure` set explicitly in
> every row, so the `-Min` twins are a clean markup-off counterfactual: markups and
> `p45_pfmPhiMktSpread` are exactly 0 in all six, and the markup buys back 17.7% (EU21) / 21.6% (H12)
> of the rule-B cost (`SCENARIOS.md` §4.5).

### 11.3 Load guards — freshness, not positivity

The economy-wide loads guard each element on `> 0`, because *their* failure mode is
"revert to $\varphi = 1$", i.e. silently uncoupling a coupled run, and no legitimate
economy-wide $\varphi$ is ever 0.

**Neither holds for the Bulk companions.** $\varphi^{\text{Bulk}} = 0$ is a legitimate value
($\theta \to 1$ with Bulk at the bottom of the gap distribution), and `> 0` would discard it
and fall back to the floor — reading a *maximally* constrained Bulk sector as an
unconstrained one, the wrong direction. So the companions are gated on the **iteration
stamp** the R side echoes back (`p45_pfmFresh`), which answers the question `> 0` was really
asking — *is this gdx this call's?* — without conflating it with the value being zero. This
is the same reasoning that retired the `> 0` test on `p45_pfmDelta` after the 2026-08-13
batch looped forever on a perfectly converged delta of exactly 0.

Two further properties:

- The stamp is loaded **once**, at the top of the coupling block, before any symbol is
  copied out, and cached in `p45_pfmFresh`.
- Each companion's `_aux` is **zeroed before its load**, so a gdx that is fresh but *missing*
  one companion cannot copy the previous iteration's value in behind the stamp. Zero degrades
  to the floor — the pre-0042 behaviour, and the safe direction.
- `p45_pfmLambdaMkt` keeps a `> 0` test *on top of* the stamp: 0 is that parameter's
  documented default ("the gap persists"), so absent and deliberately-zero are
  indistinguishable, and falling back to the economy-wide rate is the conservative reading of
  both.

### 11.4 Two survival checks on the markup

`pm_taxemiMkt` is written in **presolve** and read by the solve, but `47_regipol`'s postsolve
runs **after** this module's and both zeroes it (`cm_regiExoPrice`) and rewrites it
(`cm_emiMktTarget`). That is the shape of defect 5. Two aborts, both in `presolve.gms`:

**Erasure** — reads `pm_taxemiMkt` as the previous postsolve left it, *before* the block that
rebuilds it, and aborts if this module wrote a markup last iteration and it is now gone.
Fires only when a markup was actually written, so a legitimately zero one cannot trip it.

**Liveness** — the companions degrade *silently by design*: a missing or stale one lands as a
zero markup, i.e. the pre-0042 `min` behaviour. Safe, but indistinguishable in any output
from "the markup is on and working". So if the per-market shares genuinely differ somewhere
— the only case in which a markup is owed — and every markup is nevertheless zero, the run
aborts rather than quietly delivering the old behaviour under a sector-differentiated label.

> ⚠️ **`-PFMgate` cannot test the markup.** At θ = 0 every φ is 1, so every markup is exactly
> zero and both checks correctly stay silent. The markup is only exercised on a **θ > 0** run.
> Guard the liveness check on the *shares*, never on θ.

### 11.5 Two controllers, one instrument

`47_regipol/regiCarbonPrice` iterates `pm_taxemiMkt` against emission-market targets, and
module 47's postsolve runs **after** module 45's. `datainput.gms` aborts when
`cm_pfmSectorMarkup = 1` and `cm_emiMktTarget` is set — guarded on the *target*, not the
realization, since `regiCarbonPrice` carries plenty of machinery that never touches the price.

**Adjacent hazard, not guarded:** `cm_regiExoPrice` and `cm_regiExoPrice_fromFile` zero both
`pm_taxCO2eq` and `pm_taxemiMkt` in `47_regipol` postsolve. Those break the coupling with or
without this ADR — they are simply incompatible with a coupled run.

### 11.7 Pinning the anchor from another run — `cm_pfmAnchorFromGdx` (added 2026-09-17)

The quantity headline (`TODO.md` 14g) needs rule B on the price path that **holds** the budget,
with nothing allowed to raise it. `cm_regiExoPrice_fromFile` is the obvious tool and the wrong
one: it overwrites the *regional* price in `47_regipol` postsolve and zeroes `pm_taxemiMkt`, which
erases φ and the markup (§11.5). `cm_pfmAnchorFromGdx` takes the idea and applies it to the anchor
only:

| setting | effect |
|---|---|
| `off` (default) | anchor built from `cm_taxCO2_startyear` / `cm_peakBudgYr` as usual |
| `on` | after Parts I–II of `functionalForm/datainput.gms`, `p45_taxCO2eq_anchor` is replaced by the one in `input_carbonprice.gdx`; Part III and `presolve.gms` then build φ, the cap and the markup on it |

Set `path_gdx_carbonprice` to the donor's **title**; `start.R` resolves it to that title's latest
finished run and copies it in as `input_carbonprice.gdx` (`prepare.R`), for any realization. Two
aborts: `cm_iterative_target_adj ≠ 0` (postsolve would rescale the pinned anchor), and a donor with
no positive anchor from `cm_startyear` to 2100.

`fulldata.gdx` stores the anchor the **final solve used**: on the 2026-09-16 gates it equals
`p45_taxCO2eq_anchor_iter` at the last iteration (32 EU21, 51 H12) to the digit. Tested on those
two gdx files in a GAMS harness that runs the real `datainput.gms` block: \$108.56 / \$254.42 /
\$546.14 (EU21, 2030 / 2050 / 2090) and \$96.92 / \$248.98 / \$553.09 (H12). **Not yet tested in a
full REMIND run** — `-PFMgateBfix` reproducing `-PFMgate` is that test.

> ⚠️ **Do not type a price path into the scenario CSV.** The first `FIXPRICE` attempt did, and one
> spreadsheet save turned `108.2663` into `1.082.663` (`TODO.md` 14g).

### 11.6 Reporting

> ⚠️ **Never quote "the carbon price" of a coupled run without naming the market.** ETS
> emissions face `pm_taxCO2eq + pm_taxemiMkt("ETS")`; ES emissions face `pm_taxCO2eq` alone.
> **Do not add the two** — they are a floor and a market-specific increment, not two
> components of one price. Any reporting code that read `pm_taxCO2eq` as "the" price was
> correct before this change and is ambiguous after it.

Diagnostics written every iteration: `p45_pfmMarkupShare_iter` (share of region-periods with
a positive markup) and `p45_pfmMarkupMean_iter` (mean markup, T$/GtC). A share near 0 means
the markup is doing nothing — either the switch is off, the companions are not arriving, or
Bulk is genuinely the worse sector everywhere.

---

## 12. Verifying the gdx contract against GAMS itself

`pfm::pfmReplayInterface()` — the promoted GAMS half of the archived `replay-coupling.R`
(TODO item 7). Everything in §7 is a rule about what R *writes*; this is the only check
that asks **GAMS what it reads**.

```r
pfmReplayInterface(remindDir = "../remind_pfm")
```
```bash
Rscript models/pfm/inst/replay/replay-interface.R --remind ../remind_pfm
# 0 pass · 1 fail · 2 skipped (no GAMS / no gamstransfer)
```

It writes a coupling gdx with the **real** exporters, generates a stub that **declares every
symbol by reading `declarations.gms`** — never by restating it, so the stub cannot drift from
what REMIND actually declares — runs the same `Execute_Loadpoint` statements `presolve.gms`
runs, and asserts the loaded cells against the values R wrote. ~1 s, no REMIND run needed.

### 12.1 Why it asserts values, not `execError`

> 🔴 **`execError` is not sufficient, and believing otherwise is how defect 4 shipped.** A
> symbol with the correct rank *and* the correct domain sets but the wrong index **order**
> raises **no GAMS error at all** and loads as `( ALL 0.000 )`.

Verified against GAMS 45.7 on 2026-08-17 for the rank-3 ADR 0042 symbols, and **re-verified
against GAMS 51.4.0 on 2026-09-11** when `p45_regiDiff_lambda` was added (§11.2a): in the
negative control the *only* execution error in the listing is the replay's own value assertion.
GAMS loaded a transposed `p45_pfmPriceBoundMkt` in silence.

> ⚠️ **Run it with the right GAMS.** Two systems are installed: `C:\Program Files\GAMS)`
> (51.4.0) runs, and `C:\Program Files\GAMS` held 54.3.1, which the PIK licence refuses —
> *"License file too old for this version of GAMS, maintenance expired"*. A wrong-version GAMS
> exits **7 before compiling anything**, so every GAMS test fails at once and
> `skip_unless_gams()` does not catch it (it only tests that `gams` is on `PATH`). If all the
> GAMS tests fail together, run `gams` with no arguments and read the version line first.

### 12.2 The negative control is the load-bearing half

`negativeControl = TRUE` (default) builds a second gdx **by hand** through gamstransfer —
`.pfmCouplingSymMkt2d()` refuses to produce it — with `p45_pfmPriceBoundMkt` transposed to
`(all_regi, ttot, all_emiMkt)`, and feeds it to the same stub. The harness must **abort**.

> A run in which the control passes quietly is a **failure of the harness**, not a pass: it
> means the check cannot detect the defect it exists for. The same logic applies to a
> `SKIP` — no GAMS means nothing was verified.

### 12.3 When to run it

Any change to the gdx contract: a new symbol, a rename, a changed rank or index order in
`declarations.gms`. The cheap half runs without GAMS — `test-pfmReplayInterface.R` asserts
that all 18 symbols the replay loads are still declared in the module, which is what fires
when a symbol is renamed on one side only.

**What it does not cover:** the markup arithmetic inside `presolve.gms` — the
`max(price − floor, 0)` over `emiMkt`, the mode-1 λ, the freshness gating. Those are covered
by the R-side tests and by reading; only a coupled run confirms them. The 2026-09-11 λ fix is
a case in point: the gate proves `p45_regiDiff_lambda` *arrives*, not that the floor built from
it is right.

## 13. Test overrides of the feasibility share — `phi-override.yml` (added 2026-09-23)

**What it is for.** Two questions the paper cannot answer from the deployed runs (paper gap plan
GP-23, GP-24): what does the *estimated* ordering add to either coupled result, and does the
held-budget result depend on China's 2035 reading? Both need coupled runs whose shares carry no
estimated information, or one region's share replaced, with everything else — energy-system feedback,
severity, bind mode, level-cap bound — computed exactly as in the deployed run.

**How.** A Run-Group may carry `phi-override.yml`. `pfm::iterativePFM()` (pfm ≥ 0.4.1,
`R/pfmPhiOverride.R`) applies it to `feas$phi` — the per-sector regional share — right after it is
computed and before the economy-wide share, the per-market shares and the mode-2 bound are derived,
so every symbol GAMS loads sees the same values. No file, no change. `preparePFM.R` copies the file
into the run folder when present and prints `PHI OVERRIDE in this Run-Group: …` in the run log; the
coupling prints `PHI OVERRIDE (…)` on every call. A run with an override must never be read as a
deployed run — the group name and the log line are the markers.

| mode | effect | groups |
|---|---|---|
| `uniform` (`value: mean` or a number) | every region gets the sector's mean share of that call — the level kept, the ordering removed | `v5-uniform` |
| `permute` (`seed: k`) | the call's shares reassigned across regions by a fixed permutation of the sorted region names, the same map for both sectors — the distribution kept, the ordering scrambled | `v5-permuted1..3` |
| `set` (`regions: {CHA: {Bulk: …, Diffuse: …}}`) | named regions pinned; the rest untouched | `v5-chinaseed-EU21`, `v5-chinaseed-H12` (China at its 2022-seed shares, which differ by resolution) |

The groups are built by `analysis/run-groups/makeGroupVariants.R` as copies of the exported `output/remind-inputs/v5` plus
the yml; nothing is re-estimated. Scenario rows: start tags `<res>GP24` (`-PFMlevelBfix-uniform`,
`-permuted1..3`, `-PFMlevelC-uniform`, `-permuted1`) and `<res>GP23` (`-PFMlevelC-allmedian`,
`-alllow`, `-chinaseed`).

The same script builds the **assignment-rule twins**. They are real Run-Groups, not overrides: the
group is a copy of the base with only the donor step re-run. `-usadonor` and `-usalow` change the
USA's basis; `-allmedian` and `-alllow` put every uncovered country on one band. `-nearest`
(2026-10-06, design note 0005 §7a decision 3) matches every uncovered country to its nearest donors,
with no "none" class (`runPFMDonorAssumptions(qualityQuantiles = c(0.5, Inf))`; the USA keeps its
median override). The base defaults to `v5`; `PFM_VARIANT_BASE=v6` builds `v6-…` twins (the
China-seed groups exist for `v5` only).

**Caveats.** Under `uniform` there is no floor region and no least-constrained region: every region
receives the same two sector shares, so the within-region split is identical everywhere and the
markup is the same in every region (the gap between the two sector means). Under `permute` the energy-system feedback still moves the
underlying shares between calls; the permutation is applied to each call's shares, so a region
follows its donor's feedback, not its own.

## 14. The v6 coupling — the share path φ(t) (added 2026-10-07; ADR 0049, 0050, 0054)

> **Status:** implemented on both sides, verified offline, and **run in REMIND: the Phase 3 gate of
> design note 0005 passed on 2026-10-08** (batch `EU21V371`, REMIND 3.7.1; `analysis/v6/phase3Gate.R
> output/remind-runs/v6/EU21`, 18 of 18 checks). The θ = 0 null reproduces `-PFMgateRef` exactly (0
> of 231 price cells differ; 1000.91 Gt both); rule B (`-PFMlevelBfix-v6`) converges in 7 calls, rule
> C (`-PFMlevelC-v6`) in 8 with `p45_pfmBoundCheck_iter` at most 9.1e-7. A call takes 56–59 s first and
> about 30 s after on the cluster (E17). Sections 1–13 still describe every `v5` run.

**Which formulation a run uses.** `iterativePFM(formulation = "auto")`: a Run-Group whose export
carries `phi-anchor.rds` (step `pfm-anchor`) couples by **v6**, any other by **v5**, unchanged.
`pfm-coupling.yml` `formulation:` can force either (`v6-anchor`, `v5-tier`).

**What a v6 call does.**
1. Builds the scenario panel of the current solution for the run's SSP (`weightScenario`, from
   `cm_GDPpopScen`) and institution rule, exactly as v5 does. The group's panel definition is set for
   the duration of the call, so the nested calls that read IEA data use the group's edition
   (`PITFALLS.md` §32).
2. Reads the anchor ($q$, $u$, lean frontier design) for the delivery mapping's resolution, then
   computes $k_s(t)$ and $\varphi_{r,s}(t)$ (`pfm::pfmV6Shares`). **No ECM, no
   `temporal-validation.rds`, no λ** (ADR 0050): both λ symbols are exported as 0.
3. Region weights: the anchor's, unless the run's SSP or weight year differs, in which case they
   are recomputed for the run. $u$ and $q$ come from history and are the same in every SSP.
4. Exports, besides the existing symbols (which carry the **t₀ = 2025 value**):

   | symbol | domain | content |
   |---|---|---|
   | `p45_pfmPhiPath` | `(ttot, all_regi)` | the floor share path, min over sectors |
   | `p45_pfmPhiMktPath` | `(ttot, all_regi, all_emiMkt)` | each market's share path, never below the floor |

   Both cover **every** `ttot` of the REMIND gdx (1900–2150): before 2025 the 2025 value, after the
   scenario's last year the last value. A missing record would load as a zero share.
   `p45_pfmPriceBound(Mkt)` are built from φ(t) with no speed limit (`exportFeasibilityBound`, λ = 0).
5. Convergence (D5): `p45_pfmDelta` is the largest change in φ over regions, sectors (hence markets)
   and the floor **at the checkpoint years** 2035 / 2050 / 2070 / 2100 (2035 / 2050 / 2060 under the
   hold-2060 option); the all-period change is logged beside it. Damping (α = 0.5) only when the path
   oscillates. `pfm-phi-history.rds` stores per call φ(t), $k_s(t)$, δ, the all-period δ, α and the
   options.

**GAMS side.** `cm_pfmPhiPath` (main.gms, default 0 = every earlier run bit-identical). With 1:
- presolve loads both paths, gated on the freshness stamp and on the symbol being present;
- mode 1: the ratio **is** the path, $\varphi(t)$ · anchor, and each market's price is its own path
  · anchor (presolve and the postsolve Step III.3 mirror);
- mode 2 rebuild (`cm_pfmBoundRebuild = 1`, rule C): the target of each period uses that period's
  share (presolve and the postsolve Step IV.4 mirror);
- mode 3 is retired from v6: the R side stops a v6 call in mode 3;
- the runtime file carries `ssp` and `phiPath`, so the R side stops on an SSP mismatch (D9) and on a
  v6 group told `cm_pfmPhiPath = 0`.

**Options** (`pfm::pfmV6CouplingDefaults()`; scenario columns, written into `pfm-coupling.yml` by
`preparePFM.R` only when set): `pfmFormulation`, `pfmPhiHoldYear` (2100 | 2060), `pfmPhiHold`
(logit | ratio = E-hold), `pfmPhiSpread` (k | model), `pfmPhiOrdering` (model | uniform | reversed |
permuted), `pfmPhiOrderingSeed`, `pfmPhiKappa` (closure on the strength), `pfmPhiStrength`
(common | regional). Each is echoed in the log. `phi-override.yml` is refused for v6 groups: the
ordering tests are the `pfmPhiOrdering` option, which keeps $k(t)$.

**Before submission.** `pfmPreflight(checks = "groups")` fails a row whose `cm_pfmPhiPath` does not
match its group (1 for a v6 group, 0 for a v5 group); `pfmReplayInterface()` replays the two path
symbols with the module's own declarations, cell values and totals, next to the negative control.

**Also in this pass** (0005 E11, E12): `p45_pfmBudgetPeak_iter`, `p45_pfmBudgetPeakYr_iter`,
`p45_pfmBudgetNoPeak_iter` record the peak of cumulative CO2 and warn at the iteration cap when it
never peaked (`PITFALLS.md` §26); mode 1 now records `p45_pfmBindShare_iter` (the share of region-periods
whose price the ratio holds below the anchor).

**Verified offline (2026-10-07).**
- A v6 call on the v6 export and the `v5` EU21 PkBudg1000 gdx (`analysis/v6/couplingOffline.R`, 25 s) gives
  a share path identical to Phase 1's (756 values, difference 0) and Bulk $k$ 0.629 / 0.481 in 2050 /
  2100. Re-run on the REMIND 3.7.1 PkBudg1000 base (2026-10-08, `refreshBases.R`): difference 0
  again, Bulk $k$ 0.629 / 0.488.
- A GAMS harness loading that gdx: the mode-1 ratio equals the path exactly, and the rebuild target
  uses each period's share.
- `pfmReplayInterface()` with the path symbols: positive replay OK, negative control caught.
