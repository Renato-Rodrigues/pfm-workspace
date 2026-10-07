# Pitfalls — rules paid for in lost hours

*Every entry here cost a debugging session, a wasted cluster run, or a wrong number that
reached a document. They are not style preferences. Read this before touching the panel,
the mappings, the cache, or the gdx interface.*

---

## 1. Editing a mapping is not installing one

`preparePanelData()` resolves region mappings through

```r
madrat::toolGetMapping(name, type = "regional", where = "mappingfolder")
```

and `madrat::getConfig("mappingfolder")` is **not** this repo:

| path | role |
|---|---|
| `C:/Users/renatoro/Desktop/Input Data/remind_inputdata/mappings/` | what madrat actually reads **locally** |
| `/p/projects/rd3mod/inputdata/mappings/` | what it reads **on the cluster** — a *shared PIK RSE* directory, not `/p/projects/elevate/WP3.4/` |
| `_code/data/mappings/` | a staging mirror, outside all git repos |

**What went wrong:** a corrected FE mapping was written to the repo mirror and the estimation
kept using the old one for an entire session while every document claimed the bug was fixed.
Every result produced before 2026-08-10 was pre-fix.

**Found again 2026-10-02, the other way round.** `mrpfm`'s bundled H12/EU21 were a future update of
the regions (15 countries elsewhere, Ukraine among them), and so is the workstation's REMIND input data
(`C:/_data/work/remind_input_data/mappings`). The cluster read REMIND's version from its
mappingfolder; the workstation read the future one either way - so local replays disagreed with
cluster runs by 0.0395 in φ, long blamed on the madrat cache, and `v5`'s workstation-computed
regional artifacts (the offline coupling bound) used other regions than its coupled runs (0005 E26). The bundled copies are now the
REMIND fork's `config/` files, and `pfmPreflight()` checks the resolved mapping against them
(`tools/compareMappings.R` shows all three copies side by side).

**The rule:** verify through the resolver, never by reading the file you just edited —
`toolGetMapping(..., returnPathOnly = TRUE)`. Because `data/` sits outside every package repo,
`git pull` will never carry a mapping to the cluster; copy it explicitly and re-verify there.

## 2. The cluster builds from the git remote

The cluster installs `pfm`/`mrpfm`/`remind_pfm` from GitHub, not from your working tree. An
uncommitted fix **does not run**, and the job completes happily using the old code.

Verify what is actually installed by introspecting it, not by reading source:

```r
Rscript -e 'any(grepl("<new-symbol>", deparse(body(pfm::<function>))))'
```

## 3. Two caches, and they are not interchangeable

| config key | what it is |
|---|---|
| `madrat: cachefolder` | the **madrat data cache**, one per Run-Group (`data/madrat/{group}`) — where CarbonPrice, CAPMF, EDGAR, V-Dem, SSP2 come from. Prepared by `pfmPrepareCache()` (ADR 0047) |
| `modelDir` | the **Fit Cache / model store** — content-addressed fits, `index.json`, `panels/` |

**A copied cache file is trusted on its name alone (2026-10-03).** Under `forcecache` madrat loads
any file whose arguments match, whatever code or configuration produced it, and the file name
covers the calculation's *arguments* only. `calcPolicyStringency`'s coverage filter read madrat's
global `regionmapping` - not an argument - so a copy from a shared cluster cache, filtered by
other regions, served the `v6` cache: 37 countries instead of 48. The regions are now an
argument (`coverageMapping`, 0005 E27). Anything a calculation takes from the global madrat
configuration must become an argument before its result can be shared between caches.

Never point one at the other. Locally, madrat also needs **`forcecache = TRUE`**: local package
fingerprints never match the cluster's, and without it madrat rebuilds from source data that
only exists at PIK. Parallel workers must have the madrat config propagated into them
(`cachefolder`/`mappingfolder`/`forcecache`) or they silently rebuild.

## 4. `config.yml` paths resolve against the config file's own folder

Not the working directory. The **root** copy therefore uses `data/...`; a leading `../`
climbs out of the project.

## 5. `gdxRegionMapping` must match the gdx's own native resolution

It is a property of *that gdx*, not a target: an H12 gdx stays H12 even when the coupling is
delivered at EU21. Getting it wrong mis-assigns every region, silently. Verify when swapping
gdxs:

```r
length(gdx::readGDX(f, "all_regi"))
```

Related: the current registry is **EU21 at a 1000 Gt budget**. Price levels are **not**
comparable with anything quoted from the earlier H12 / 750 Gt runs. Never mix budgets in one
projection fan-out.

## 6. The gdx interface: test through GAMS's eyes, not R's

Full contract in `COUPLING.md` §7. The meta-rule: a round-trip test that uses **your own
reader** proves nothing about what GAMS sees — the original one read back through magclass,
which rebuilds a magpie from any rank, so it could never catch the rank defect. Assert
GAMS-visible rank, index order and UEL format.

**`pfm::pfmReplayInterface()` is the check that actually asks GAMS** (`COUPLING.md` §12). Two
things about it are the point, not the implementation detail: it **declares the symbols by
reading `declarations.gms`**, so it cannot drift from what REMIND declares; and it **asserts
values, not `execError`**, because a transposed symbol raises no GAMS error at all and loads as
`( ALL 0.000 )`. It ships with a negative control that must abort — a control that passes
silently means the check is incapable of detecting the defect it exists for.

Two related traps: `gdxrrw::rgdx()$uels` behaviour **depends on the writer** (for a domain-less
symbol it is the global UEL list repeated per dimension), and `nA` is unusable as a GAMS
identifier — GAMS is case-insensitive and `NA` is reserved.

## 7. Absolute gap and relative gap are different objects

$1-E = 1 - S/S^{*}$ (bounded, frontier-relative) versus $S^{*}-S$ (index points) versus
$(S^{*}-S)/S = 1/E - 1$ (unbounded as $S\to0$, used only by bind mode 3). Ranking on the
absolute gap ranks regions by **ceiling size** — how much they *could* do — not by how far
they fall short. Never mix them in one sentence, one table, or one figure.

## 8. A script's printed verdict is not a result

The re-selection risk check printed "LEAD CHANGED → re-sweep with cause". It was **wrong**:
the candidates were tied on the primary criterion and the script broke the tie on mean ΔR²,
which the real selection machinery does not use. Applying the same crude tiebreak to the
*pre-fix* data reproduced the same "flip", which is what disproved it.

Two lasting consequences: **check a verdict against the machinery that actually decides**, and
remember that a maximin rank is decided on secondary criteria wherever the primary one ties. The
deployed spec is rank 1 on `v5`, but it is not first on fit, on mean ΔR²(theory) or on minimum
ΔR²(theory) taken alone (`MODEL.md` §2.4). Any selection-stability wording must say so.

## 9. Numbers must name their Run-Group

Artifacts are per-Run-Group and Run-Groups are re-cut often; the current one is `v5`.
The same quantity legitimately differs between them. A number without its group is not
checkable — and worse, silently invites comparison against a different vintage. Every table in
`MODEL.md` names its source file; keep that discipline everywhere, including the paper.

Corollary: **do not assume a Run-Group exists locally.** Groups quoted by archived documents may
not be on this machine at all; list `output/` before reading from one. And a group can exist with
only part of its artifact set — check `manifest.json$run$incompleteSteps`.

## 10. Absence of data is not a neutral assumption

The old coverage rule gave unobserved countries $\varphi = 1$ — *maximal* assumed political
capability. That is a strong claim dressed as a fallback: the USA (0% CAPMF coverage) was
handed full capability while Japan was held to 21%. Whenever a default is chosen for missing
data, ask what claim the default is making.

## 11. `logistf` does not populate `$fitted.values`

It is `NULL`; use `$predict`. (Firth's penalized logit, used by the retired hurdle model's
adoption stage — kept because the object is still constructed in legacy code paths.)

## 12. magpie objects are 3-dimensional

`pb[cbind(region, year)] <- value` is not valid indexing for a magpie, and year labels are
`"y2030"` not `"2030"`. This killed every coupled run on its first call.

## 13. The silent failures — the ones with no error message

Ranked by how long they went unnoticed:

| failure | what you see | how to detect it |
|---|---|---|
| region-first gdx index order | **nothing** — loads cleanly, all values 0.000 | check a non-zero record count in GAMS |
| wrong mappingfolder | nothing — the old mapping is used | `toolGetMapping(returnPathOnly = TRUE)` |
| unpushed fix on the cluster | nothing — the job succeeds | introspect the installed function |
| φ stuck at 1 | nothing — GAMS keeps the previous φ by design | `p45_pfmDelta`, the runtime log |
| price explosion | the solve **succeeds** and the numbers look like results | `p45_pfmInfesCode = 1` |
| year UEL `"y2030"` | loads, every record dropped | record count |
| a diagnostic fitted on the wrong spec | nothing — the artifact carries the deployed spec's *name* (§14) | its BIC must match that spec's row in `sweep.rds$results` |
| a country-resolution group diagnosed at R54 | nothing — plausible output, wrong clusters | check the region/cluster count against the group's own |
| a normalised quantity quoted at the wrong resolution | nothing — a plausible number, wrong by ~50% | θ-anchor §15; check `resolution` on the artifact |
| a cached fit reused after the spec moved | nothing — the run completes on the old model | cache keys must include the spec (§14) |
| the sector markup degrading to the old `min` | nothing — by design it falls back silently | `p45_pfmMarkupShare_iter`; the liveness abort (`COUPLING.md` §11.4) |
| a unit mismatch between history and scenario | nothing until 2040 — the harmonisation offset hides it at the seam | compare both sides in physical units past 2040 (§28) |
| a scenario gate whose input was never passed | `0 severe … PASS` — the gate simply is not there | `responsivenessGate` / `sanityGate` in `manifest.json` (§28) |
| a cache key that misses a fit-changing field | twins silently share results; one of them "never wins" | the key function vs every spec field that differs between variants (§29) |
| a scenario series exempt from harmonisation | a seam at the anchor year, only for some countries | `.pfmHarmoniseScenario` covers every shared series (§30) |
| a lag counted in rows on a panel with uneven steps | nothing — the scenario reads 5- to 20-year-old drivers | the lag counts years since 2026-10-06; compare η on the annual-interpolated panel (§31) |
| a nested call reading the panel definition from a global option | nothing — the coupling uses another IEA edition than the estimation | `iterativePFM()` sets `pfm.panel` for the call (§32) |
| a share path with missing periods, or `cm_pfmPhiPath` not matching the group | a constant or zero φ under a v6 label | the path covers every `ttot`; R and `pfmPreflight` check the switch (§33) |
| a cache prepared for a frozen Run-Group with today's code | a modified `records/<group>/madrat-cache-manifest.tsv`; preflight fails `repos` | restore the record; prepare only the current group (§35) |
| a comparison across REMIND versions, or a registry gdx from an older REMIND | a null that "fails" by model drift; offline numbers on another model than the runs | `c_model_version` in each gdx; one version per comparison and per Run-Group's registry (§34) |

When something looks fine, these are what to check first.

## 14. An artifact labelled with the deployed spec is not proof it fitted the deployed spec

The post-selection steps read `selected-models-pfm.yml`, stamp `cfg$name` onto their output, and
then call the estimator with a **hand-written argument list**. That list omitted `apTransform`,
so the estimator fell back to its `"linear"` default while the artifact carried the deployed
spec's name — which ends in `satAP`. `estimator-agreement.rds`, `iv.rds` and `influence.rds`
therefore described a different model from the deployed one, with nothing anywhere reporting it.

Two rules follow:

1. **Derive forwarded arguments from `formals()`, never restate them.** `.pfmSpecArgs()` does
   this, so a spec field added later is forwarded automatically instead of being silently
   dropped until someone notices the numbers are subtly off. Callers pass their own overrides
   explicitly via `exclude =`.
2. **Absent is not the same as default.** For the driver blocks and
   `regionMappingFixedEffects`, a spec that does not name the field means *none*. Their
   estimator defaults are substantive (`"regionmappingH12.csv"`, full default driver blocks), so
   letting them apply hands a spec fixed effects it never asked for. `.pfmSpecArgs()` passes
   those five as `NULL` when absent; every other field falls through to the default.

**How it was caught, and how to check it again:** the agreement fit's BIC matched the
**non-`satAP`** sweep row exactly, in both sectors (3367.546 / 1666.977) — a spec's BIC should
match its own row in `sweep.rds$results`. That is the cheap test. Do not rely on
`driverScaling$sat` as the indicator; it is absent in the corrected fit too.

**It reached further than the diagnostics.** `runPFMFrontier()` and
`runPFMTemporalValidation()` carried the same hand-written list, so **the frontier itself** — the
ceiling, the efficiency ratio, every gap and tier, φ and the coupling bound — and **λ**, the
coupling's speed limit, were also estimated on linear actor power. Six files and ~13 call sites
share this pattern. When you touch any of them, convert to `.pfmSpecArgs()` rather than
adding one more argument to the list.

The same call sites had a second, independent instance of the family: `pfm-iv` and
`pfm-influence` were invoked without dots forwarding, so `outputRegionMappingFile` kept its
`"regionmapping_54.csv"` default and diagnosed a country-resolution Run-Group at R54 — visible
only as `influence.rds` reporting 36 clusters named `ANZ`/`BELUX` rather than 48 countries. The
code's own comment above the `pfm-agreement` call had warned about exactly this.

**Audited 2026-08-17 — the estimator call sites are clean.** All six sites that fit from a
deployed spec now forward `apTransform`, including `iterativePFM()`, which is the coupling
itself.  What the audit *did* find was the same family one level up: the ECM fit cached inside
`iterativePFM()` was named by **sector alone**, so a spec or panel change could not invalidate
it and a stale fit would be reused under the new spec's name. It is now content-addressed on
the spec and a panel hash. **The lesson generalises: a cache key that omits the spec is the
same defect as an argument list that omits a spec field.**


## 15. A normalised quantity is meaningless without its resolution

The anchor-by-analogy solves $1-\theta\bar u = \bar E$, where $u$ is the gap **normalised over
the units in the frame**. The number it returns depends on which units those are: over 48
countries a few extreme single-country gaps stretch the min–max range, while aggregation to
regions compresses it, moving median $u$ and therefore θ. When this was first measured the
country-level Bulk value fell outside $[0,1)$ and read as a finding — *"no legal θ reproduces
median Bulk efficiency"* — that evaporated at region resolution.

Nothing is wrong with either number. What is wrong is quoting one at the resolution of the
other. On `v5`, at the region resolution the coupling assigns φ on, the analogy gives Diffuse
0.328 and Bulk **1.019** — inadmissible at the resolution that matters, which is why it may be
reported (`MODEL.md` §5.3).

**The rule:** any quantity normalised by a min–max over units — $u$, gap position, tier
boundaries — must be computed at the resolution it will be *used* at, and must carry that
resolution wherever it is quoted. `computeEfficiencyAnchor()` returns `resolution` and
`tierYear` in the same row as `theta` for exactly this reason, and
`coupling-summary.rds$anchorDerivation` records it every run.

**The general form:** this is §9 (numbers must name their Run-Group) one level deeper. A
Run-Group pins *which fit*; the resolution pins *which population the normalisation ran over*.
Both are needed before a normalised number is checkable.

## 16. Reading a coupled `fulldata.gdx` — four traps that all fail silently

`gdxdump` is the tool; it ships with every GAMS system and needs no licence.

```bash
gdxdump fulldata.gdx symb=<name> format=csv
```

> ⚠️ **Two GAMS systems are installed and only one runs.** `C:\Program Files\GAMS)`
> (51.4.0, Sep 2025) works; `C:\Program Files\GAMS` itself held 54.3.1, which the PIK licence
> refuses — *"License file too old for this version of GAMS, maintenance expired"*. Both
> directories are on `PATH`, with `%GAMSDIR%` (→ the `51` subfolder) ahead of the parent, so a
> **freshly started** shell gets the right one and a session older than the 51 install does not.
> If `gams` or `gdxdump` misbehaves, check `gams` with no arguments and read the version line
> before debugging anything else. `gdxdump` itself is version-tolerant, so only `gams` is
> actually affected.

*(An earlier version of this section said there is no `gamstransfer` on this workstation.
There is — 3.0.9 — and `pfm`'s gdx tests use it because it reads a gdx the way GAMS does,
rank and real domain names, which is what catches a transposed symbol. `gdxdump` is still the
right tool for ad-hoc reading.)*

Every one of the following produces a plausible-looking wrong answer rather than an error.

**`pm_taxemiMkt` is `(year, region, market)`.** Reading it as `(year, market, region)` filters
on a market name that is never present, so every markup reads as **exactly zero** — which is
indistinguishable from "the markup is switched off", the precise thing you are usually checking.
This cost a wrong conclusion on 2026-08-18 before `p45_pfmMarkupWritten` contradicted it. When a
markup looks identically zero, verify against `p45_pfmMarkupWritten` / `p45_pfmMarkupSeen` and
`p45_pfmPhiMktSpread` before believing it.

**`pm_actualbudgetco2` runs to 2150, not 2100.** The last element is *not* the cumulative-to-2100
figure, and for budget runs it is materially lower (EU21 `-PFMgate`: 992.5 Gt at 2100, 917.1 at
2150, peak 999.5 at 2090) because emissions go net-negative. Always index the element `"2100"`
explicitly, and take the peak as a max over years rather than as the last entry.

**`p45_pfmDelta_iter` opens with a 1e6 sentinel.** The first four entries are placeholders, not
divergence. Skip them before reporting a convergence sequence.

**`cm_iteration_max` is the count actually used, not the configured cap.** A value of 100 means
the run hit the cap; anything else is the iteration it settled at. Do not read it as a setting.

## 17. `cm_iterative_target_adj` decides whether the EU price floor exists

`cm_taxCO2_lowerBound_path_gdx_ref` being `1` does **not** mean the floor is applied. The
postsolve statement that applies it
(`45_carbonprice/functionalForm/postsolve.gms:432-433`) sits *inside* the
`if((cm_emiscen eq 9) AND (cm_iterative_target_adj eq 5/7/9), ...)` block that closes at line
480. Every `adj = 0` run — `-PFMgateB`, `-PFMlevelB`, `-PFMmildProg` and **all NPi twins** —
skips it entirely, and nothing in the config or the log says so.

Measured on the 2026-08-17 batch: 0 of 280 region-years below the floor in the `adj = 9` family,
**126 of 280** in the `adj = 0` family at EU21. A third case: in `-PFMlevelC` (`adj = 9`,
mode 2) Step IV.4 re-applies the political cap *after* Step IV.3, so the cap overrides the floor.

**Consequence:** price *levels* are not comparable across the two families, because one models a
world where legislated EU policy cannot be repealed and the other does not. Check `adj` before
any cross-run price comparison. (`TODO.md` item 3, closed 2026-08-22: the floor is `0` on all
40 runs of the 2026-08-26/29 batch — `SCENARIOS.md` §6.3.)

## 18. A step that self-skips still reports `DONE` — read the audit, not the exit status

`runModelGroup()` calls each step in turn, and a step that cannot run — a missing input, an
uninstalled optional package — writes one line and returns quietly:

```
[PFM-BOUND:v5-specalt] skipped — missing: temporal-validation.rds
```

It does **not** raise. The run then printed `done: <every requested step>` and exited 0. On a
cluster log carrying madrat cache chatter and thirty warnings, that single line is invisible,
and the first symptom is the next tool failing to find an artifact nobody wrote.

**Fixed 2026-08-18.** `runModelGroup()` now audits the file system after the step loop rather
than trusting the steps, and distinguishes two failures:

| verdict | meaning |
|---|---|
| **INCOMPLETE** | the artifact does not exist — the step did nothing |
| **NOT REFRESHED** | the artifact exists but predates this run, so anything downstream consumed the **previous** run's version |

Both raise a `warning()`, both print a block in the log, `startRun()` repeats the list as the
**last line**, and the manifest records `status: "incomplete"` — a third value alongside
`completed` and `failed`, because "completed" must not mean "every requested step ran".

> ⚠️ **NOT REFRESHED is the more dangerous of the two** and is what the ordering bug in §17 was
> silently doing: `pfm-projection` ran before `pfm-frontier`, found the *previous* frontier
> already on disk, and projected against it. Nothing was missing, so nothing complained.
> Suppressed under `resume = TRUE`, where reusing an artifact is the point.

**What to check on any cluster run:** the last line. `DONE` means every audited step wrote a
fresh artifact; `DONE WITH GAPS` means it did not, and names the steps.

**Since 2026-10-02 (design note 0005 E23) a run with gaps fails.** `startRun()` raises an error
after writing the manifest and the last log lines when the run ends `failed` or `incomplete`, so
`Rscript` and the SLURM job exit non-zero (`failOnGaps = FALSE` returns the status instead). A
NOT REFRESHED artifact is **moved aside** to `<file>.stale`: left in place, the next step, the
next run or the REMIND export would read the previous run's version as this one's. It is renamed,
not deleted, so it can be inspected or restored by hand.

## 19. A rendered figure whose medium was un-declared is never rewritten again

`analysis/figures/build-figures.R` renders each figure only to the media it is asked for. Change what a
figure declares — or change the media table itself — and the previously rendered
`analysis/figures/output/<medium>/<id>.png` is **not deleted**. Nothing rewrites it, nothing warns, and it
sits beside current files looking exactly like one.

> **Reorganised 2026-09-18.** Every figure now renders to `output/all/` (one PNG) and the paper's
> figures also to `output/paper2/`; `slide` and `poster` are opt-in (`--media=slide,poster`) and
> the `report` medium is gone, folded into `all`. Four renders of one plot was three chances for a
> stale one to be read as current — the pitfall below is the same pitfall, made less likely by
> rendering less. **An opt-in medium is stale the moment the figure changes**, so rebuild the deck
> renders when you build a deck, never trust the ones sitting on disk.

On 2026-08-18 five such orphans were present, all dated 2026-08-17. One of them
(`shortfall-regions`) was opened to verify a stamp correction and appeared to show the
correction had not been applied — it had, in the media the figure actually declares. Ten
minutes were spent debugging a build that was working.

**The build now checks for this.** After rendering it diffs `analysis/figures/output/` against the set
the registry declares:

```bash
Rscript analysis/figures/build-figures.R            # lists orphans and warns
Rscript analysis/figures/build-figures.R --prune    # removes them
```

> **Same class as §18.** In both cases the pipeline reported success while something on disk
> silently disagreed with what was asked for: there, a step that produced nothing; here, a file
> nothing produces. **Verify against the declaration, not against the presence of a file** —
> a file existing proves only that it existed once.

**When reading a rendered figure to check your own work, check its `consumers` first.** If the
medium you opened is not in the list, you are looking at history.

## 20. A weight built from the training panel is a normalised index, not a size

The panel `pfm` estimates on carries a column called **`Energy Intensity`** and one called
**`GDP`**. Both are *drivers*: `panelDataHistorical.R` constructs them as `energyIntensityNorm`
and its GDP counterpart, min–max normalised into $[0,1]$ so the frontier's coefficients are
comparable. They are **not levels**, and their product is not a size.

`runPFMCouplingBound()` used exactly that product as its country aggregation weight, for
months. The tell that nobody looked for:

| weight | max / median over positive weights |
|---|---|
| final energy, 208 countries | **417** |
| equal weights | 1 |
| the broken GDP × Energy-Intensity proxy | **1.4** |

At a dispersion of 1.4 every multi-country region aggregates its members almost equally.
**China received 31.8% of the CHA region instead of 96.2%**; the USA, a single-country region,
was unaffected, which is why the defect survived every spot check that looked at the USA.

**Blast radius, and it is narrower than it first looks.** `iterativePFM()` — the runtime that
runs *inside* a coupled REMIND job — resolves its weights through `pfmCouplingWeights()` and
always has. So:

- **unaffected:** every gdx in the 2026-08-17 batch, `SCENARIOS.md`, headline B, the sector
  split, the interface gate. These do not pass through the offline bound.
- **affected:** the Run-Group's `coupling/coupling-summary.rds` — `boundAnchor` $\varphi$, the tier
  table, `inCoverageShare`, and everything downstream of them (Figs 3a/3b, coverage-by-region,
  claims C1–C4 region detail, C18).

Sizing the correction at $\theta = 0.50$: Spearman 0.961, median $|\Delta\varphi|$ 0.024, max
0.121 (UKI), median rank shift 1 of 21 — **but the floor region moves**, LAM,MEA → SSA,MEA.
A shifted floor region changes which region the whole bound is anchored on, so this is a
re-run, not a footnote.

**The guard.** `pfmAssertSizeWeights()` (`models/pfm/R/pfmCouplingWeights.R`, exported) rejects any
weight vector whose max/median over positive entries is below 20. It is now called on **both**
paths — `runPFMCouplingBound()` and `iterativePFM()`. `iterativePFM()` previously *warned* and
fell back to equal weights when the madrat cache was missing; inside a multi-hour batch that
warning scrolls past unread, so it now **errors**. `weights = NULL` remains the deliberate
opt-out and is left alone (it says so out loud).

> **The general rule: never build a weight out of the estimation panel.** The panel exists to
> be normalised. Weights are levels and come from `pfmCouplingWeights()`. If a new step needs
> country weights, call that function and assert the result — the two lines are the whole fix.

## 21. Two series on one axis must be the same quantity

**This entry replaces a wrong one.** It first claimed a `Population` normalisation defect between
the fitted and scenario panels, with a decomposition showing 88% of a −2.08 η step. That
diagnosis was an artefact of the test, and there is no defect. What is left is a rule about
figures, and it is the more useful of the two.

### What happened

`frontier-projected` (SI-11) plotted `frontier.rds$scores$frontierIndex` for 2001–2022 and
`projections/*.rds$index` for 2025 onward, and the two did not meet — a step down in 48 of 48
countries. Those are **different quantities**:

| series | what it is | from |
|---|---|---|
| `frontierIndex` | the **SFA frontier** — the ceiling | `runPFMFrontier` |
| `index` | **projected policy stringency** — the mean level | `projectPFMSpecScenario`, via `estimatePolicyStringencyModel` |

`projectFeasiblePath()` says so in its own header: *"the path converges to the ECM equilibrium,
**not** to the SFA frontier … the frontier enters only as an upper bound and as the gap exhibit."*

So the "step" was the model's **slack term** — the gap between a ceiling and a mean, which is the
central estimated quantity of the whole project — misread as a discontinuity. Against the right
historical counterpart the projection is continuous:

| projection 2025 `index` vs historical 2022 … | median |
|---|---:|
| `frontierIndex` | −1.232 ← the apparent seam |
| `expectedIndex` | **+0.924** |
| `observedIndex` | **+0.948** |

### How two wrong diagnoses got as far as they did

1. **A correlation across countries is not a decomposition.** The first suspect was
   `Fossil share in Industry`, on a −0.649 correlation with the per-country step that tracked the
   driver weights (−0.649 at weight 1.0, −0.289 at weight 0.5 — an apparent dose–response across
   two independently fitted sectors). At a common year it barely moves. It was a proxy for
   population size.
2. **A decomposition is only as good as its inputs.** The second suspect was `Population`, from a
   same-year η decomposition that looked airtight. But the scenario panel had been built with
   `outputRegionMappingFile = "regionmapping_54.csv"` while the fitted panel is at country
   resolution — **a mismatch the pipeline explicitly guards against**
   (`runPFMPostProcessing.R`, the 2026-08-10 resolution guard). Rebuilt at `"country"`, the panels
   agree to four decimals (ARG Population 2020: 0.8362 vs 0.8360) and flagged variable-region
   pairs fall from 189/1560 to 119/9711.

> **The rules.** Before explaining a gap between two series, **prove they are the same quantity** —
> check the function that produced each. When a diagnostic harness disagrees with production, ask
> what the harness is doing differently before believing it; here the harness reproduced a defect
> the pipeline is built to prevent. And when a project already has a guard for exactly the failure
> you think you have found, **that is evidence against the finding**, not a coincidence.

### What survived

`computeSeamDiagnostics()` had been exported for months **without a single call site** — which is
why nothing had ever compared the panels. It is now wired into the projection step
(`runPFMPostProcessing.R`) and writes `<group>/seam-diagnostics.rds` every run. It is what
eventually produced the right answer, and it is the only lasting change from this episode.

---

## 22. A convenience column can be a prohibited measure — `implementability` is `S/10`

**Found 2026-08-19, in `SCENARIOS.md` §1.1 and in Fig 4b, after both had been quoted for months.**

`computeImplementabilityFactor()` is one line:

```r
projection$implementability <- pmin(pmax(projection$index / indexMax, 0), 1)
```

so `projection.rds$implementability` is exactly **`S/10`** — the multiplier `MODEL.md` §7 lists
as *prohibited*, because it compares every polity to a universal maximum instead of to its own
ceiling. The column is a legacy ADR 0036 rescale; its own docstring says the raw `index` is "the
canonical, coupling-agnostic output". It is **not** the efficiency ratio, and nothing downstream
of the coupling reads it.

**What it cost.** Two consumers took it for $E$:

| consumer | what it claimed | what it plotted / quoted |
|---|---|---|
| `SCENARIOS.md` §1.1 | "Diffuse is the binding sector in 45 of 48 countries (94%)" | the sector with the lower **`S/10`** |
| Fig 4b `fig-implementability-ranked` | subtitle: "Efficiency ratio E = S/S*" | `implementability`, i.e. **`S/10`** |

On the correct measure the ordering reverses: on $E$ Bulk is the more constrained sector in most
countries (32 of 48 at 2022 on `v5`, claim C10), the opposite of the retracted claim.
`MODEL.md` §3.4.2.

**No coupled result was affected.** `iterativePFM()` and `runPFMCouplingBound()` never read the
column; they build $E$ = `feasibleIndex / ceilingIndex` from `projectFeasiblePath()`. This is
the §20 shape again: **runtime correct, offline reporting artifact wrong.**

> **The tell that should have caught it.** Two builders in the same layer —
> `fig-efficiency-distribution.R` and `fig-implementability-map.R` — already carried explicit
> warnings not to use the column, one of them noting it had been *verified equal to `index/10`
> to machine precision for all 7,440 rows*. The knowledge existed and lived only in code
> comments. It never reached `PITFALLS.md`, so the third builder and an authoritative document
> both walked into it.

**The rules.**

1. **A convenience column named after a concept is not that concept.** Open the function. Here
   the name (`implementability`) matches a CONTEXT.md term while the arithmetic does not.
2. **When a figure's label names a quantity, assert the label against the data.** Fig 4b's
   subtitle said $E = S/S^{*}$ for months while it plotted `S/10`.
3. **A warning that lives only in a code comment will be missed.** If a trap is worth a comment
   in one builder, it is worth an entry here — that is what this file is for.
4. **Check the prohibition list when you reach for a ratio.** `MODEL.md` §7 already banned
   `S/10`; nobody looked.

## 23. `library(pfm)` on the workstation can be months older than the working tree

**Local twin of §2** (the cluster installs from the git remote, so unpushed fixes are invisible
there). Same failure, different library path.

On 2026-08-25 `analysis/checks/propagateFrontierRungsToPhi.R` opened with `library(pfm)` and got the
**installed 0.3.0** while the working tree was **0.4.0**. The two differ in `preparePanelData()`'s
`known_indices`, so every per-capita actor-power driver failed to resolve its `|<sector>` suffix
and the run died with `missing from the data: Incumbent Power pc` — the signature of a bug that had
already been fixed in source that morning.

**Dying was the lucky outcome.** A stale install that merely lacks a *later* refinement runs to
completion and writes a plausible artifact from a specification nobody is looking at.

**The rule:** an analysis script that reasons about the current model must load `pfm` from the
source tree, not the library — and must say which build it used.

```r
if (dir.exists("pfm")) pkgload::load_all("pfm", quiet = TRUE) else library(pfm)
message("pfm ", read.dcf("models/pfm/DESCRIPTION")[1, "Version"])
```

`propagateFrontierRungsToPhi.R` does this and prints `[rung-phi] pfm loaded from SOURCE pfm (0.4.0)`.
**Every other script in `analysis/` still calls `library(pfm)` and carries this exposure.**
Before trusting any local analysis output, check which build produced it.

## 24. `qos=priority` needs `partition=priority` — and a dry run does not prove a call will run

Two traps from one submission, 2026-08-25.

**(a) The QOS and the partition travel together.** `qos="priority"` with the default
`partition="standard"` is rejected as:

```
sbatch: error: Batch job submission failed: Invalid qos specification
```

That message reads like *"no such QOS"* or *"your account lacks it"* — it sent a whole session into
`sacctmgr` association checks. **The QOS existed and the account had it; the `standard` partition
simply does not allow it.** `pfm::prioritySizing()` resolves this by reading `AllowQos` off the
partitions and reports what it found:

```
qos=priority partition=priority
  [QOS priority: cpu=64 mem=NA wall=1-00:00:00 | partition -> priority (allows priority: priority)]
```

**Do not hand-set `qos`.** `priority` is a formal of **`pfmRun()`**, not `startRun()`, and
`pfmRun` only auto-sizes when `qos` is *absent* — so passing `qos="priority"` disables the very
mechanism that would have made it work. Use `pfmRun(..., priority = TRUE)` and pass **no**
`qos`/`partition`/`nCores`/`mem`/`time`; each one you set switches auto-sizing off for that axis.

**(b) `dryRun = TRUE` printed a clean plan for a call that could not execute.** The same invocation,
run live, died in `do.call(startRun, args)` because `pfmRun` spliced `...` into the same `list()`
as its resolved defaults and `cachefolder` appeared twice. dryRun returned *before* that assembly.

Fixed (caller now wins via `modifyList`, and unknown dots are warned about before the dryRun exit),
but the general lesson outlives the bug: **a dry run that does not exercise argument assembly
manufactures confidence.** When you add a preview mode, make it fail on everything the real path
would fail on, or say plainly what it does not check.

---

## 25. An unfinished REMIND run's `fulldata.gdx` is complete, readable, and reports success

Found 2026-09-14, on a batch where 8 of 48 runs were still in their Nash loop when the results
were copied off the cluster.

REMIND rewrites `fulldata.gdx` **at every Nash iteration**, not once at the end. So a run that is
still going has a full, well-formed gdx carrying a complete price surface — and every status
symbol reads clean:

| symbol | in-flight run | finished run |
|---|---|---|
| `o_modelstat` | **2** (locally optimal) | 2 |
| `pm_pfmConverged` | **1** | 1 |
| `p45_pfmCallCount` | **2** | 2 |
| `cm_iteration_max` | a plausible number | a plausible number |
| `pm_pfmInfesCode` | **0** | 0 |

**There is no symbol in the gdx that distinguishes the two.** The comparison above is
EU21 `-PFMratio` mid-loop against the finished `-PFMgate` beside it; every scalar matched.

The only marker is in `log.txt`, which sits in the same folder:

```bash
grep -q "REMIND run finished" "$d/log.txt"
```

`analysis/coupled/extractCoupledResults.R` now requires that line, skips the run if it is absent, prints
the skip list, and records it in the artifact as `$inFlight`. Two figures
(`coupled-sector-split`, `markup-counterfactual`) already refuse to build when a run they name is
missing, which is the behaviour that caught this — **their errors are the guard working, not a
bug to route around.**

> **Why this is worse than an ordinary stale-file trap.** A mid-run gdx is not obviously wrong:
> its prices are a real REMIND solution, just not the converged one. On the run that exposed
> this, the mid-loop prices sat well away from where the same run had landed in the previous
> batch — enough to move a headline, not enough to look absurd. The failure mode is a number
> that is plausible, quotable, and irreproducible.

**Rule: anything that reads `output/remind-runs/` checks the log first.** That includes ad-hoc `gdxdump` in a
scratch script, not just the extractor.

### 25a. …but "unfinished" is not the same as "unusable", and the test is not the iteration count

Added 2026-09-14, when five EU21 runs had to be used before they finished.

REMIND converges the **near term first** and leaves its residual market imbalance in the
far-future periods. So the useful question is not *how far did the run get* but *do the markets
clear in the years the analysis uses*. One rule, applied to every run:

```
admit an unfinished run  <=>  zero market-year cells through EARLY_THROUGH (2060)
                              exceed REMIND's own p80_surplusMaxTolerance
```

`p80_surplusMax_iter` at the last completed iteration, divided by `p80_surplusMaxTolerance` for
that market, split at 2060 — which is where `MODEL.md` §7 already stops trusting scenario
differences. Measured on the 2026-09-14 batch:

| | worst early surplus / tolerance | early cells over |
|---|---:|---:|
| the 5 unfinished runs (iteration 83–90) | **0.10 – 0.44×** | **0 of 42 each** |
| 42 of the 43 finished runs | 0.13 – 0.90× | 0 |
| **H12 `-PFMratioMin`, finished, iteration 100** | **4.86×** (good, 2035) | **7 of 42** |

**The unfinished runs were cleaner than several finished ones, and the one genuine failure had
finished.** Judging by completion alone would have thrown away five good runs and kept the bad
one.

`analysis/coupled/extractCoupledResults.R` applies this automatically and records `finished`,
`nashIter`, `earlySurplusMax`, `earlySurplusOver`, `lateSurplusMax`, `lateSurplusOver` on every
run, with `$admittedUnfinished` naming those let through. A late-period surplus over tolerance is
normal residue and appears in runs that converged perfectly; an **early**-period one is not.

### 25b. The iteration cap is 100 whatever the scenario config says — and "iterations" lies for unfinished runs

Found 2026-09-23 on the RULECFIX batch. `modules/80_optimization/nash/datainput.gms` sets
`cm_iteration_max = 100` whenever `cm_nash_autoconverge > 0` (the default), overwriting any value
in a scenario config. The 150 once set for the RULECFIX rows had no effect, and H12
`-PFMlevelCMin` stopped at 100.

**The rule (2026-10-01): never raise the iteration cap.** The `cm_iteration_max` column has been
removed from `scenario_config_PFM.csv`. A run that does not converge is handled in one of two ways:
- **remove the source of non-convergence** — find the criterion still failing (below) and fix its
  cause; or
- **start a new run from its gdx** (`path_gdx` = the unfinished run). This is how EU21 `-PFMlevelC`
  was finished: restarted from its own gdx for 57 more iterations, it converged to 1000.4 Gt.

On convergence `postsolve.gms` rewrites `cm_iteration_max` to the count used, which is why
`coupled-runs.rds$iterations` reads correctly for converged runs. For a run that is **unfinished,
crashed, or stopped at the cap** it still reads 100. Use `nashIter` (last iteration in
`p80_surplusMax_iter`) — `analysis/coupled/coupledRunConvergence.R` reports it, together with which REMIND
criteria were still failing and whether the run was still moving over its last ten iterations.

A run at the cap can be in a **limit cycle**, not converging slowly: both RULECFIX `-PFMlevelCMin`
runs flip `o45_peakBudgYr_Itr` between 2080 and 2090 every 5-6 iterations (global net CO2 in 2080 is
~0), so the post-peak price rescaling makes the late-century price jump by ~18% per cycle while 2050
emissions move by ~2% and the 2050 anchor by ~0.7%. More iterations do not help; quote such a run
over the cycle band, not at its last iteration.

## 26. A peak budget is read on the peak, not on 2100 — and the budget warning only sees one of them

`PkBudg1000` is a **peak** budget: cumulative CO₂ may peak at 1000 Gt and then fall as emissions go
net-negative. `pm_actualbudgetco2("2100")` is therefore not the budget test. On the `v5` batch the
gap-closure rule-C runs end 2100 at 954 / 963 Gt with a peak of 998.6 / 1001.8 — the budget held,
the 2100 figure just looks 40 Gt short. The opposite trap is worse: H12 `-PFMratioMin` reads 1003.7 Gt
at 2100 but keeps rising to **1068 Gt at 2150**, never peaking, and **`pm_pfmBudgetWarn` stayed 0**.
The warning fires on `p80_globalBudget_absDev_iter` at the iteration cap; it did fire on EU21
`-PFMlevelC` (−14.2), but it does not see a post-2100 rise.

> Both of those runs were re-submitted on 2026-09-17 and now converge (`-PFMratioMin` peaks at
> 1003.0 Gt in 2090; `-PFMlevelC` at 1000.4 Gt with warn 0), so **the batch no longer contains a live
> example** — the blind spot in the GAMS check is unchanged, and the next run to hit it will again
> pass silently.

**The rule:** judge budget adherence on the maximum of `pm_actualbudgetco2` and its year
(`coupled-runs.rds$peak`, `$peakYear`). A peak year at the horizon end is a failed budget whatever
the 2100 figure or the warning says. Differences between rule-B runs, which have no budget, stay on
the 2100 figure. `TODO.md` item 32.


## 27. Estonia's `PE|Coal` is negative upstream — it is excluded from estimation, not clamped

`calcOutput("PE")` gives Estonia a **negative `PE|Coal`**, the only one of 249 countries. Measured
2026-08-12, EJ/yr (`mrremind` 0.240.2, `mrcommons` 1.67.0, `madrat` 3.36.2, IEA Energy Balances
default version; not a Run-Group number):

| | 2010 | 2016 | 2022 |
|---|---:|---:|---:|
| `PE|Coal` | −0.0003 | −0.0120 | −0.0121 |
| `PE|Coal|Gases` | −0.0092 | −0.0160 | −0.0165 |
| `PE|Coal|Solids` | −0.0024 | −0.0131 | −0.0124 |
| `PE` (total) | 0.1112 | 0.1102 | 0.1163 |

**Cause.** The `calcIO` items `pecoal.segafos.coalgas` and `pecoal.sesofos.coaltr` (IEA products
`BLFURGS`, `COKEOVGS`, `GASWKSGS`, `OGASES`) book derived coal gases and coke as primary coal.
Estonia burns coke-oven and gas-works gas in power and CHP plants but has no coke ovens or gas
works. Every non-zero flow is therefore a (negatively signed) consumption flow, with no
production to cancel it. Where a country does both, the two sides roughly cancel and any
double-count stays invisible. The open upstream question is whether these secondary carriers
should enter `pecoal` at all. Oil shale may also play a part: Estonia's `PE|Oil|Liquids` is
about half its PE, and there is no oil-shale carrier. This belongs in `mrcommons`, where `calcIO`
and `calcPE` live. The drafted issue text is in
`../_archive/_wip/2026-10-01/docs/reference/psm-pecoal-estonia-issue.md`.

**Why exclusion, not a clamp.** Clamping turns Estonia's coal share into `0.0`. That reads as a
*clean* energy system for one of Europe's most carbon-intensive ones: a wrong value that looks
plausible and moves the coefficients unseen. A dropped country is visible in the sample size. The
same negative values are also the likely source of `toolAggregateWeighted`'s
`Negative numbers in weight` warnings.

**The rule:**
- `preparePanelData(excludeCountries = getOption("pfm.excludeCountries", "EST"))` drops Estonia
  from every estimation.
- Every exclusion is reported at fit time: `[preparePanelData] excluding <n> row(s) for EST`.
- When upstream is fixed, set `options(pfm.excludeCountries = character(0))`, refit, and compare
  the deployed spec's coefficients with the current ones.

## 28. History is EJ, a REMIND gdx is TWa — and a scenario gate that is not passed does not run

Two defects, found together on 2026-10-05 while checking Run-Group `v6`. Each one hid the other.

**The unit.** The per-capita actor-power drivers (`Innovator Power pc`, `Incumbent Power pc`) are
share × total primary energy per person (`.energyPerCapita`). History reads `PE (EJ/yr)` from the
IEA (`iamHistoricalData`); the scenario reads REMIND's `vm_prodPe`, which is **TWa**
(`downscaleREMINDResults`). Nothing converted it. The shares are ratios, so they were unaffected.
The per-capita series were not. The harmonisation offset (DATA.md §5.5) matched the two sides at
the last panel year and faded to zero by 2040, so the error **appeared gradually and then stayed**:

| median, 49 estimation countries, v6 panels | hist 2023 | scen 2030 | 2040 | 2050 |
|---|---:|---:|---:|---:|
| `Innovator Power pc|Bulk`, before the fix | 0.0206 | 0.0129 | **0.0021** | **0.0021** |
| `Incumbent Power pc|Bulk`, before the fix | 0.0457 | 0.0272 | **0.0009** | **0.0005** |
| `Innovator Power pc|Bulk`, after (PkBudg1000) | 0.0206 | 0.0429 | 0.0655 | 0.0672 |
| `Incumbent Power pc|Bulk`, after (PkBudg1000 / NPi) | 0.0457 | 0.0416 / 0.0412 | 0.0280 / 0.0335 | 0.0166 / 0.0236 |

Before the fix, innovator power per capita **fell** tenfold while the innovator share rose from 0.17
to 0.65. The implied energy per capita fits the unit exactly: Germany is 0.14 EJ per million in
2023 and 0.0033 in 2050, and 0.0033 × 31.536 = 0.10.

What it broke (estimation, the frontier and the 2023 anchor read history only, so they are intact):
- **every scenario panel since the per-capita forms entered (2026-08-24)**: `v5` and `v6`,
  offline and inside the coupled REMIND runs (`iterativePFM` builds the same panel). After 2040
  any per-capita term carried no scenario signal. `v5`'s deployed `X-2079` has `Incumbent Power pc`
  in it;
- **every scenario-side selection gate**, which scored projections built on those drivers. `v6`'s
  deployed `X-1950 … splitAPpc` uses only per-capita actor power. Its ambitious and reference
  projections differed by a median **0.004** (Bulk) and **0.001** (Diffuse) index points over
  2040–2060, against `scenarioBlind`'s 0.05 (`v5`'s `X-2079`: 0.236 / 0.104). It passed
  `ceilingCollapse` most likely *because* its actor-power drivers went flat in both scenarios;
- **`v5`'s `scenarioBlind` rejections of `X-1746` and `X-1743` (splitAPpc, ~0.005)**: most likely
  this defect, not the form.

**The missing gate.** `scenarioBlind` (ADR 0039) needs a reference scenario panel. `runPFMSweep`
takes `referenceGdxFile`, but **no caller ever passed it**, so in a `pfmRun` sweep the gate never ran.
`v5` applied it by hand (`gate275v.R` in the 2026-09-15 spec-selection evidence); `v6` did not apply
it at all. Nothing said so. The walk printed `0 severe / 21 warnings - PASS`, and the gate that
would have caught the unit defect was not there.

**The rules:**
- `.energyPerCapita(…, peUnit = )` has **no default**: `"EJ"` for history, `"TWa"` for a gdx.
  Any new quantity read from both sides is compared **in physical units, at a year past the
  harmonisation fade (2040+)**: the seam diagnostics compare at the anchor year, where the offset
  makes every scale error vanish.
- `pfmRun` passes the registry's non-gating scenario (`scenarioReferenceEntry`, the rule
  `runPFMCouplingBound` uses for P_ref) as `referenceGdxFile`. A sweep that has a gating panel
  but no reference prints `WARNING: … scenarioBlind is NOT applied`. `manifest.json` records
  `sanityGate` and `responsivenessGate` under the `sweep-pfm` step: **read them before trusting a
  selection** (§18).
- The coupling bound's scenario-panel cache is now `<group>-scen-ca-peEJ.rds`. The old
  `*-scen-ca.rds` files hold the defective panel and are never read; delete them.
- Run-Groups selected before 2026-10-05 (`v5`, `v6`, `v6-annual`) were selected on defective
  scenario panels. Their **fits** stay valid (the history panel and its hash are unchanged, so
  the Fit Cache is reused), but their **selections and every scenario-side artifact** must be
  re-run.

(The historical energy intensity multiplies EJ by 31.536 as if it were TWa, the same class of
defect. Only the retired model reads `Energy Intensity`, so it is left as it is.)

## 29. A cache key must hold every field that changes the fit — the bootstrap's did not hold `apTransform`

Found 2026-10-06 on Run-Group `v6`, whose selection bootstrap reported **0% wins and 0% gate passes**
for the deployed `X-1791 … satAP`, while the same spec's resample refits all succeed.

`.pfmBootCacheKey()` hashed the spec's drivers, controls, FE and trend, but not `apTransform`. The
four actor-power twins of a spec (`linear`, `satAP`, `satInn`, `satInc`) differ **only** there, so
they shared one cache file per sector. The first twin computed wrote its 200 resample rows,
labelled with its own name. Each later twin found that file, counted it as a full hit, and fed
those rows into the re-ranking. In every resample the table therefore held one twin's rows several
times and the other twins not at all. The sweep's own Fit Cache keys the twins correctly: their
full-sample results differ.

What it invalidated (rankings across *different* specs are mostly unaffected; the comparison
*between twins* is meaningless):
- `v6` (both runs): every win share and gate-pass share of a spec whose twin was cached first,
  the deployed one included, and the actor-power **transform** shares (e.g. "satInc 54% of wins").
- ADR 0048's bootstrap figures for transforms and twins ("satInc 1.44×", "satAP 0.24×", the 6.5%
  of `X-1791 satInc`). See the erratum there.
- `v5` (`MODEL.md` §6): the linear vs `satAP` comparison ("satAP 45.9% vs 43.3%", the modal winner
  `X-2010 satAP` at 12.2%). Channel-set and actor-power-form shares are approximately right.

**The rules:**
- The key includes `apTransform` (a spec without one is `linear`). This orphans every earlier
  `pfmboot_` file, which is deliberate: any of them may hold a twin's rows.
- Cached rows must carry the spec's own name. A file whose rows name another model is ignored and
  refit, with a message, so a future key gap cannot relabel silently.
- **Any new field that changes a fit goes into every cache key that covers that fit.** Grep for
  the key functions when adding a spec field. The Fit Cache, the bootstrap cache and the panel
  caches are separate keys.

## 30. "Anchored by its own projection" is not anchored on the panel — harmonise every shared series

Found 2026-10-06 on Run-Group `v6`, in the Phase 1 seam test (design note 0005 C8).

`panelDataScenario` harmonised every scenario series to the historical panel at the panel's last
year **except** the institution-rule series (V-Dem Rule of Law, accountability and state capacity;
WGI Voice and Accountability, Political Stability and Regulatory Quality). The reason given was that
they were "already anchored by their own projection method". But that method starts from the last
**raw** observation (V-Dem 2025, WGI 2024), while the panel holds a centred moving average at its
last year. Where a country's institutions moved sharply around the anchor year (coups: Myanmar
2021, Mali, Niger; Qatar's Vertical Accountability), the two differ by 0.1–0.4 on the normalised
scale. That moved the country's frontier at the anchor seam by up to 6 index points.

**The rule:** every series the scenario panel shares with history is harmonised
(`.pfmHarmoniseScenario`). A country with no history value keeps its projection. Derived series
(the state-capacity principal component) are computed from the harmonised inputs. Effect on `v6`
(seam test with the lag in years, §31): band-rule countries' seam, Bulk 95th percentile 1.93 → 0.93
index points, maximum 6.2 → 1.65; Bulk $k$ +0.02 to +0.05 (`output/pfm/v6/phase1/lag-seam.rds`).
Scenario panels built before 2026-10-06 carry the seam. The coupling bound's panel cache is renamed
`<group>-scen-ca-peEJ-harm.rds` so it can never read one.

## 31. The driver lag was one ROW, not one year — on REMIND's time steps it was 5 to 20 years

Found and fixed 2026-10-06 on Run-Group `v6`.

`preparePanelData(lag = 1)` read the drivers at `yi - lag`, the previous **index** of the panel's
year axis. The estimation panel is annual, so the fitted frontier is $S(t) = f(X_{t-1})$. Every
scenario path (`projectFeasiblePath`, the sanity walk, the projection sanity check, the coupling
bound, `computeAnchorGap`'s η) calls the same function on the REMIND-period panel (2020, 2025, …,
2060, 2070, …, 2100, 2110, 2130, 2150). There the same "lag 1" was 5 years up to 2060, 10 years to
2100, then 20 years. For example, η(2025) read the 2020 drivers, and η(2100) read 2090's. The
EU-membership dummy alone already lagged in years.

Nothing failed. The lagged driver was a plausible value, only an older one. What it moved (`v6`,
EU21, institution-harmonised panels; `output/pfm/v6/phase1/strength.rds`; H12 within 0.003):

| $k$ | row lag (before) | year lag (now) |
|---|---|---|
| Bulk PkBudg1000, 2050 / 2100 | 0.87 / 0.54 | 0.63 / 0.48 |
| Bulk NPi, 2050 / 2100 | 1.37 / 1.10 | 1.09 / 0.92 |
| Diffuse PkBudg1000, 2050 / 2100 | 0.78 / 0.71 | 0.91 / 0.73 |

It also confounded the anchor-year seam test: the scenario side read another year than history.
The C8 seam figures quoted before 2026-10-06 (Myanmar −6.6, Qatar +5.6) mix this lag with §30.

**The fix:** `lag` counts years. A lagged year that is not on the axis is linearly interpolated
between its neighbours (`.pfmLagLookup`), and one before the first year is NA, as before. On the
annual training panel nothing changes: the prepared `v6` design is `identical()` before and after,
for both sectors, so fits, frontier and the Fit Cache stay valid. The ECM recursion in
`projectFeasiblePath` already compounds λ over the step length.

**What must be re-run:** every scenario-side artifact built before 2026-10-06, i.e. the sanity walk's
scenario gates (`extrapolationDominated`, `actorPowerExtrapolation`, `scenarioBlind`), and with
them possibly the selection; the sanity pool and the bootstrap's sanity verdicts; projections; the
coupling bound; the REMIND export. `v5`'s coupled bounds were computed with the row lag; `v5` is
frozen, so this is a disclosed difference, not a re-run.

**Check:** η on a scenario panel and on the same panel interpolated to annual steps
(`magclass::time_interpolate`) should differ only by genuine within-period change
(`tests/testthat/test-driverLagYears.R`).

## 32. Inside a coupled run, nested calls read the panel definition from a global option

Found 2026-10-07 while testing the v6 coupling offline, before any v6 coupled run.

`pfmCouplingWeights()` and the downscaling of REMIND results (`iamHistoricalData()`) take the IEA
edition and the geothermal setting from `pfmPanelDef()`, i.e. the `pfm.panel` option. A REMIND run
never sets it, so for a `v6` group those calls read the **`v5` definition** (2024 edition, no
geothermal) while the estimation read the 2025 edition. On the cluster the 2024 files exist, so
nothing fails: the weights and the downscaled drivers silently come from another data version.

**The rule:** `iterativePFM()` sets `options(pfm.panel = <the group's panel definition>)` for the
duration of the call (restored on exit). Any new function that reads IEA data must take the edition
as an argument or read `pfmPanelDef()` *inside* such a scope, never a hard default.

## 33. The v6 share path: three ways to deliver a constant φ under a v6 label

The v6 coupling (`COUPLING.md` §14) exports φ(t) as `p45_pfmPhiPath` / `p45_pfmPhiMktPath`. Each of
these would run, converge and report a v6 result while GAMS used something else:
- **A period without a record loads as zero.** The scenario panel starts in 2010; REMIND's `ttot`
  starts in 1900. The R side completes the path over every `ttot` of the gdx (2025 value before,
  last value after). Do not filter the export to the scenario's years.
- **`cm_pfmPhiPath = 0` on a v6 group.** Mode 1 and the rule-C rebuild then use the one-dimensional
  symbols, which carry the 2025 value: a constant share. The R side stops such a call (the runtime
  file carries `phiPath`), and `pfmPreflight(checks = "groups")` fails the row before submission.
  The reverse (a v5 group with 1) fails there too: GAMS would wait for a path that never comes and
  keep φ = 1.
- **An SSP mismatch** between GAMS (`cm_GDPpopScen`) and `pfm-coupling.yml` (`weightScenario`): the
  scenario panel and weights would describe another world. The runtime file carries `ssp` and the R
  side stops.

- **A variant Run-Group carrying its base's anchor.** An assignment twin is a copy of `output/pfm/v6`
  with only the donor step re-run; the copy also holds v6's `phi-anchor.rds`, whose ranking $u$ was
  built from v6's assignment. Exported as it is, the twin couples exactly like v6. Since 2026-10-07
  `makeGroupVariants.R` deletes the copied anchor, rebuilds it (`pfm-anchor`) and stops if it equals
  the base's; `makeSpecVariantGroup.R` copies no anchor and prints a step list with `pfm-anchor` (the
  export refuses a manifest that records the step without the file). A shape twin keeps the spec's
  name, so the spec check in the coupling would not have caught a stale anchor.

And one for reading results: a `v6` φ and a `v5` φ at the same θ are not the same severity (θ means
"severity at 2025" under v6, D12), so never compare them across the θ dial (`TODO.md` 7a's trap).

## 34. A REMIND version change: compare within one version, and move the registry with it

On 2026-10-07 the fork moved from REMIND 3.7.0.dev29 to 3.7.1 (`remind_pfm` merge `41f21ec3b`; 343
upstream commits; `v5-final` keeps the old state). Three consequences, all silent:
- **Nulls compare within one version.** A θ = 0 run on 3.7.1 against a θ = 0 run on 3.7.0.dev measures
  REMIND's drift, not the coupling. The Phase 3 null is gated against `-PFMgateRef` re-run on 3.7.1;
  `phase3Gate.R` reads `c_model_version` from every gdx and fails a mixed pair. For scale, the
  same-version `v5` pair `-PFMgate` / `-PFMgateRef` differs by at most $0.71 per `pm_taxCO2eq` cell.
- **The scenario registry is a model version too.** `config.yml` `scenarios:` points at the `v5`
  bases. Everything that reads it offline (the projection, the coupling bound, the Phase 1 panels and
  $k$, `analysis/v6/offlineHeadline.R`, `sspGovernanceSwap.R`, `ceilingGate.R`) describes 3.7.0.dev
  until it is re-pointed at the 3.7.1 bases. A coupled run reads its own gdx and `input_ref.gdx`, so
  it is consistent by construction; the offline numbers quoted beside it are not.
  **Re-point only with `analysis/v6/refreshBases.R`**: it snapshots `phase1/`, edits the two registry
  lines, re-runs the analyses and prints old vs new. The scripts read the registry (`bases.R`), and a
  cached scenario panel built from another gdx is refused - before 2026-10-07 the scripts named the
  v5 run folders themselves and `scen-<role>.rds` was reused whatever it had been built from.
- **The renv moves.** 3.7.1 replaced `gdx` by `gdx2` in REMIND's own DESCRIPTION and raised
  `piamenv`. `pfm` still imports `gdx`, which `setup.sh --install` keeps in the run renv; run
  `make ensure-reqs` in each checkout before `setup.sh --install`.

A merge of upstream REMIND conflicts only in `not_used.txt` when the fork's GAMS changes stay inside
`45_carbonprice/functionalForm`: resolve as the union, then `gms::codeCheck(strict = TRUE)`, which
also lists every PFM switch a realization does not address.

## 35. Preparing a frozen group's cache with today's code rewrites its record

`setup.sh --install` and a bare `pfmRun()` prepare the madrat cache of the **default** Run-Group
(`config.yml` `group:`). On 2026-10-07 the default was still `v5`, so the cluster install prepared
`data/madrat/v5` with pfm 0.8.0 and rewrote the tracked `records/v5/madrat-cache-manifest.tsv`: a new
key, new madrat fingerprints (`calcEmber-Fc06f7a5c…` → `-F345228d4…`, because mrpfm's code changed
since v5), and new md5s for the two files without a fingerprint in their name (`calcCarbonPrice.rds`,
`calcFAOLandArea.rds`), which were rebuilt in place. `pfmPreflight(checks = "repos")` then failed on
the project checkout.
- **The record of a frozen group describes its tagged code.** `v5` is reproduced from `v5-final`
  (`setup.sh --ref v5-final`), never from the current packages. Restore the record
  (`git checkout -- records/v5/madrat-cache-manifest.tsv`); do not commit the rewrite.
- **The default group is `v6` since 2026-10-07**, and `setup.sh --group <g>` names it explicitly.
- **Files without a fingerprint are overwritten in place.** After such a rewrite, `data/madrat/v5` on
  that machine may no longer match the recorded md5s; `pfmPrepareCache(group = "v5", verify = "md5")`
  under `v5-final` says which.
