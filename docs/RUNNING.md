# Running a model version on the cluster — step by step

From an empty folder to coupled results on the workstation. The example is Run-Group **`v6`** in
`/p/projects/elevate/WP3.4-v6`. For another version, change the group name and the folder.

Where a step is done differently on the workstation, the step says how ("**Locally:**"). Things
that still need attention before this procedure counts as finished are listed at the end.

Read `PITFALLS.md` §1–§3 before the first cluster session.

---

## Step 1 — Get the project

```bash
cd /p/projects/elevate
git clone https://github.com/Renato-Rodrigues/pfm-workspace.git WP3.4-v6
cd WP3.4-v6
```

## Step 2 — Check `config.yml`

Three parts matter.

**Where the madrat cache files come from.** Example: `/p/tmp/benke/clean-cache-aug`, read
before madrat's own cache:

```yaml
madrat:
  cachefolder: "data/madrat/{group}"        # one cache per Run-Group: data/madrat/v6
  cacheSources:
    - "/p/tmp/benke/clean-cache-aug"        # 1st place to copy a missing file from
  useMadratConfig: true                     # 2nd: madrat's own cache; last: compute from madrat's sources
  compute: true
```

A missing file is looked for in this order:
1. `data/madrat/v6` itself;
2. each `cacheSources` folder, top to bottom;
3. madrat's own cache (on the cluster, PIK's shared input-data cache);
4. computed from the raw sources.

Paths that do not exist on a machine are skipped. The workstation's paths can therefore stay in
the list.

**The baseline runs** (`scenarios:`). Each entry points to the `fulldata.gdx` of an uncoupled
REMIND run, under `output/remind-runs/<group>/<res>/`. Step 5 puts them there.

**The Run-Group** (`group:`). Set it to `v6`.

## Step 3 — Set up the workspace

```bash
./tools/setup.sh --cluster --install --no-cache
```

This does four things:
- clones `models/mrpfm`, `models/pfm`, `models/remind_pfm-EU21` and `models/remind_pfm-H12`
  (`papers/` and `docs/` are left out). Repositories already there are left as they are, so the
  script can be re-run after a failure;
- installs `mrpfm` and `pfm` **once into your R library**, with `R CMD INSTALL` (what `pfmRun()`
  and the cache preparation load from the project root);
- installs them **into each REMIND checkout's renv library**, with `renv::install()` (Step 4);
- writes the commit of every repository to `output/workspace-commits.txt`.

`--no-cache` leaves the madrat cache to Step 3b: for `v6` it computes the IEA 2025 edition, which
takes long and is better run where a disconnect does not stop it. Without `--no-cache`, add
`--group v6` and the script prepares it at the end.

**Why `R CMD INSTALL` and not `devtools::install()`.** `devtools` resolves dependencies through
`remotes`, which fails on packages installed by renv or pak:
`can't convert package magclass with RemoteType 'repository' to remote` (the cluster,
2026-10-02). `R CMD INSTALL` resolves nothing. The dependencies are already in your library on the
cluster; if one is missing, its error names it - `install.packages()` it and re-run the script.
The PIK message listing the packages in your personal library is information, not an error.

**Locally:** `./tools/setup.sh --install --no-cache`. This clones one REMIND checkout,
`models/remind_pfm`, and uses the workstation paths in `config.yml`.

### Step 3b — Prepare the madrat cache of each Run-Group

In `screen` or `tmux`, or an interactive job:

```bash
Rscript tools/prepareMadratCache.R --group v6
Rscript tools/prepareMadratCache.R --group v6-annual
```

The first line of its report names the panel it prepares: for `v6`,
`panel: 2000-2023, 5-year moving average, IEA 2025 edition, geothermal in the baseload control (config)`.
The IEA 2025 edition can only be computed on the cluster (`DATA.md` §7).

## Step 4 — `pfm` in each REMIND checkout, and the check

The coupling runs inside REMIND, which loads **only its own renv library** (`renv/library`, set by
REMIND's `.Rprofile`), never yours. So `pfm` is installed twice: once in your library for the
estimation, and once into each checkout's renv for the coupled runs. **Step 3 does both.** After
every change to `pfm` or `mrpfm`:

```bash
git pull                                                   # the project repo only
./tools/setup.sh --cluster --update --install --no-cache    # --update: fetch and fast-forward models/*
```

`git pull` in the project root does **not** update `models/pfm`, `models/mrpfm` or the REMIND
checkouts: each is its own repository, and `setup.sh` leaves existing ones as they are unless given
`--update` (it then fast-forwards every one that has no local changes). Without it, `--install`
re-installs the old code - which happened on 2026-10-02. `pfmPreflight()` now fetches and fails a
repository that is behind its remote. Per checkout, `--install`:

1. copies `mrpfm`'s and `pfm`'s dependencies from **your library** into the checkout's renv with
   `renv::hydrate()` - nothing is downloaded, and what the checkout already has (REMIND's own
   `madrat`, `magclass`) is left alone;
2. removes the `mrpfm`/`pfm` that hydrate linked from renv's cache;
3. installs them from `models/` with `R CMD INSTALL -l <renv library>`, run from the project root;
4. prints `<checkout> loads pfm … | mrpfm … | mrremind …` from inside the checkout.

Why this way (all three were hit on the cluster, 2026-10-02):
- `renv::install("../mrpfm")` resolves the dependency tree from the repositories, and failed on it
  twice: `dependency 'mrremind' is not available`, then `package 'Deriv' is not available`. Your
  library already holds the whole working set, so hydrating from it needs no repository.
- renv's cache is keyed by version, and commits land without a version change: a cached
  `pfm 0.8.0` can be older code than `models/pfm`. Installing `mrpfm`/`pfm` directly keeps them out
  of the cache.
- Inside a REMIND checkout, `R CMD INSTALL` (and `install.packages`) fail: REMIND's `.Rprofile`
  calls `installed.packages()` before `utils` is loaded. Hence `-l` from the project root.

The first R start in a freshly cloned checkout bootstraps that library (REMIND's `.Rprofile` runs
`renv::hydrate`), which takes several minutes.

Then check, from the project root, with GAMS available as for a REMIND run:

```bash
Rscript -e 'pfm::pfmPreflight(checks = c("repos", "installed", "mappings", "replay"))'
```

Every line must say `ok`. `installed` compares a fingerprint of every function in each checkout's
renv with `models/pfm` and `models/mrpfm`: the version number alone no longer identifies the code,
because commits land between releases.

**Locally:** the same, for `models/remind_pfm` only.

## Step 5 — Put the baseline runs in place

The estimation needs the uncoupled baselines named in `config.yml`. The coupled runs also need
them as reference runs, by title, in the REMIND checkout's `output/`. Copy each complete run
folder, `full.log` included, to both places:

```bash
run=SSP2-EU21-NPi2025_2026-08-26_16.51.07          # repeat for SSP2-EU21-PkBudg1000_2026-08-26_19.58.59
mkdir -p output/remind-runs/v5/EU21
cp -rp <old REMIND checkout>/output/$run output/remind-runs/v5/EU21/
cp -rp <old REMIND checkout>/output/$run models/remind_pfm-EU21/output/
```

**Locally:** `output/remind-runs/v5/EU21/` already holds them.

## Step 6 — Estimate, in one call

```r
library(pfm)
pfmRun(group = "v6", stage = c("sweep", "diagnostics", "downstream", "remind"),
       cluster = "slurm", config = "config.yml")
```

This is one SLURM job. It runs every step in order:
1. estimation and selection;
2. diagnostics;
3. projection and coupling bound;
4. the REMIND inputs folder `output/remind-inputs/v6`, which includes the coupling's madrat
   cache files.

Before submitting, `pfmRun` checks the madrat cache again.

The log is `output/pfm/v6/pfm-v6-<job>.out`. Its last line says `DONE`,
`DONE WITH GAPS` (it names the steps that produced nothing) or `FAILED`.

Then commit the list of input files the estimation read. `pfmRun` writes it to
`records/v6/madrat-cache-manifest.tsv`:

```bash
git add records/v6 && git commit -m "v6: madrat cache record" && git push
```

For several Run-Groups, make one call per group. Each call returns once its job is submitted, so
the jobs run side by side:

```r
for (g in c("v6", "v6-specalt")) pfmRun(group = g, stage = c("sweep", "diagnostics", "downstream", "remind"),
                                          cluster = "slurm", config = "config.yml")
```

`stage = "all"` is the same as listing all four stages.

**Locally:** `cluster = "local"`. The sweep is cluster-sized: 4 392 specifications on `v5`.
Locally, run the later stages only:
`stage = c("diagnostics", "downstream", "remind")`.

### Step 6b — Re-running Run-Groups after a code change, in one call

```bash
tools/clusterRun.sh --priority v6 --standby v6-annual --dry-run   # plans only
tools/clusterRun.sh --priority v6 --standby v6-annual
```

It does Step 4 (`git pull`, `setup.sh --cluster --update --install --no-cache`) and the
`repos`/`installed` preflight. It deletes what `pfmRun(clean = "group")` leaves behind: the REMIND
export `output/remind-inputs/<group>` and the coupling bound's scenario-panel cache. Then it submits
each group on its queue: `--priority` uses the auto-sized priority QOS, `--standby` uses
`qos=standby` on the `priority` partition, sized by `prioritySizing()`. `--require f1,f2` fails
unless the installed `pfm` has those functions, which proves the new code is in. The Fit Cache,
panels, boot-cache and madrat cache are never touched: `clean` re-runs the steps, not the fits.
`tools/clusterSubmit.R` refuses when `sbatch` is missing, because `pfmRun` would silently run
locally. Bring everything back with `syncFromCluster.sh … --estimation --remind-inputs` (Step 9).

## Step 7 — Run the coupled REMIND batch

Each coupled row names its Run-Group in the scenario config's column `pfmGroup`. It still says
`v5`, so set it to `v6`, commit and push. Then, for each resolution, from the project root:

```r
library(pfm)
submitPFM("EU21", remindDir = "models/remind_pfm-EU21")                # dry run: checks + plan
submitPFM("EU21", remindDir = "models/remind_pfm-EU21", dry = FALSE, slurmConfig = "priority")   # submits
```

`slurmConfig` (`"priority"`, `"standby"`, a REMIND choice `"1"`-`"16"` or an sbatch string) is required
when a row of the group sets none: `start.R` would otherwise ask on a terminal `submitPFM()`
captures, and wait unseen (2026-10-07). Rows that set their own keep it.

`submitPFM()` (design note 0005 F3) does in one call what this step did by hand, and refuses on
any failure:
- `pfmPreflight()` (F2): every repository clean and pushed; the `pfm` and `mrpfm` installed in
  the checkout's own library are the working tree's code (a fingerprint of every function, since
  the version number no longer moves with every change; `PITFALLS.md` §23); every Run-Group the
  start group names is exported completely to `output/remind-inputs/`; the region mappings
  resolve to `mrpfm`'s copies (§1); each coupled row's SSP equals its reference run's (D9); the
  replay harness and its negative control pass;
- `analysis/run-groups/validatePFMScenarioConfig.R`;
- `start.R --test`, which must report 0 errors;
- then, only with `dry = FALSE`, a **batch manifest** in `output/remind-runs/batches/` (every
  repository's commit, the installed versions, the scenario config's md5, the rows) and
  `start.R` itself, its output saved beside the manifest.

For H12, the same with `"H12"` and `models/remind_pfm-H12`. By hand, the old way still works:
`validatePFMScenarioConfig.R`, then `Rscript start.R --test config/scenario_config_PFM.csv
startgroup=EU21` and `Rscript start.R config/scenario_config_PFM.csv startgroup=EU21` in the
checkout.

- Start one start group at a time.
- Start the sensitivity groups (`SCENARIOS.md` §2.5, e.g. `EU21FIXPRICE`) only after the plain
  group's runs have finished.
- A run that does not converge is never given a higher iteration cap. Fix the cause, or start a
  new run from its gdx.

**Locally:** REMIND cannot run, because its input data is not on the workstation. Run only the
`--test` line, in `models/remind_pfm`.

### Step 7b — The v6 Phase 3 gate on REMIND 3.7.1 (start tag `EU21V371`)

The fork moved to REMIND 3.7.1 on 2026-10-07, so the uncoupled bases are re-run first (`PITFALLS.md`
§34). Once per cluster checkout, after `pfm` carries the merge:

```bash
tools/setup.sh --cluster --update                  # every repo; remind_pfm-* move to 3.7.1
(cd models/remind_pfm-EU21 && make ensure-reqs)    # 3.7.1's new R requirements (gdx2, piamenv >= 0.8.1, ...)
tools/setup.sh --cluster --install                 # mrpfm and pfm back into the renv
```

Three tags in `config/scenario_config_PFM.csv`:

| tag | starts |
|---|---|
| `EU21V371` | everything below, in one call: REMIND chains the rows by their `path_gdx*` columns |
| `EU21BASE` | the uncoupled bases `SSP2-EU21-NPi2025`, `SSP2-EU21-PkBudg1000` and `-PFMgateRef` |
| `EU21V6GATE` | the four gate rows alone, once the 3.7.1 bases exist in the output folder |

The gate rows (section `v6_phase3_gate_EU21`), all `pfmGroup = v6`, `cm_pfmPhiPath = 1`:
- `SSP2-EU21-PkBudg1000-PFMgate-v6`: the θ = 0 null; must reproduce `-PFMgateRef` on the same
  REMIND version (no longer `v5`'s `-PFMgate`);
- `SSP2-EU21-PkBudg1000-PFMgateBfix-v6`: the held-price null; starts after it;
- `SSP2-EU21-PkBudg1000-PFMlevelBfix-v6`: rule B, θ = 0.5; starts after the held-price null;
- `SSP2-EU21-PkBudg1000-PFMlevelC-v6`: rule C, θ = 0.5, with the GAMS rebuild.

Needs `output/remind-inputs/v6` with `phi-anchor.rds` (`pfmRun(group = "v6", steps =
c("pfm-anchor", "pfm-remind-inputs"))`).

```r
library(pfm)
submitPFM("EU21V371", remindDir = "models/remind_pfm-EU21")               # dry run: checks + plan
submitPFM("EU21V371", remindDir = "models/remind_pfm-EU21", dry = FALSE, slurmConfig = "priority")  # submits
```

The dry run lists only the four coupled rows; `start.R` starts all seven. Or directly in the
checkout: `Rscript start.R --test config/scenario_config_PFM.csv startgroup=EU21V371`, then without
`--test`. When the seven runs have finished:
`Rscript analysis/v6/phase3Gate.R models/remind_pfm-EU21/output` prints a verdict per gate
criterion (design note 0005 Phase 3), the REMIND version of every run (`c_model_version` in the
gdx) included.

### Step 7c — The v6 batch, from the scenario matrix (after the Phase 3 gate)

The v6 batch is **generated** (ADR 0055): edit `analysis/run-groups/scenario-matrix-v6.yml`, never
the CSV. On the workstation, from the project root:

```bash
Rscript analysis/run-groups/buildPFMScenarioConfig.R   # writes models/remind_pfm/config/scenario_config_PFM_v6.csv,
                                                       # then the validator and REMIND's reader
```

Commit the matrix (project repo) and the CSV (`remind_pfm`), push, and on the cluster
`tools/setup.sh --cluster --update`. Tags: `V6W<wave><res>` (`V6W1EU21`, `V6W1H12`, `V6W2EU21`,
`V6W2H12`); `H12BASE` and `EU21BASE` for the parents. `V6W1H12` also starts the H12 3.7.1 bases and
`-PFMgateRef`, chained. The EU21 rows already run in the gate keep `EU21V6GATE`, so `V6W1EU21` does not
re-run them. Wave 2 needs the variant Run-Groups exported first (the preflight checks each).

```r
library(pfm)
cfg <- "config/scenario_config_PFM_v6.csv"
submitPFM("V6W1EU21", remindDir = "models/remind_pfm-EU21", scenarioConfig = cfg)                     # dry run
submitPFM("V6W1EU21", remindDir = "models/remind_pfm-EU21", scenarioConfig = cfg, dry = FALSE, slurmConfig = "priority")
submitPFM("V6W1H12",  remindDir = "models/remind_pfm-H12",  scenarioConfig = cfg, dry = FALSE, slurmConfig = "standby")
```

The H12 rows run from the `-H12` checkout, the EU21 rows from `-EU21`: a start group never mixes
resolutions.

## Step 8 — Check that the runs used the Run-Group's cache

```bash
grep -L "madrat cache: pfm/madrat-cache" models/remind_pfm-*/output/*PFM*/log.txt
```

This lists the coupled runs that did **not** read the staged cache. The list should be empty.

## Step 9 — Bring the results to the workstation

On the workstation, in the project folder:

```bash
tools/syncFromCluster.sh <user>@<host> /p/projects/elevate/WP3.4-v6 v6 --dry-run
tools/syncFromCluster.sh <user>@<host> /p/projects/elevate/WP3.4-v6 v6 --estimation --panels --remind-inputs
tools/syncFromCluster.sh <user>@<host> /p/projects/elevate/WP3.4-v6 v6 --runs '*PFM*'
```

Per run, this fetches `fulldata.gdx`, `log.txt` and a few small records into
`output/remind-runs/v6/<res>/<run>/`: about 70 MB a run, not the whole folder.

**Without ssh from the workstation** (copy by hand, e.g. WinSCP): stage the same files on the cluster,
in the workstation's layout, then copy that one folder:

```bash
bash tools/stageRunsForCopy.sh v6 --res EU21 --runs 'SSP2-EU21-*_2026-10-0[78]_*' --dry-run   # list
bash tools/stageRunsForCopy.sh v6 --res EU21 --runs 'SSP2-EU21-*_2026-10-0[78]_*'
```

Then copy the cluster's `output/remind-runs/v6/` to the workstation's `output/remind-runs/v6/`.

## Step 10 — Analyse

```bash
git pull                                   # brings records/v6 from Step 6
Rscript tools/listMadratCacheUsed.R output/remind-runs/v6/*/* --out records/v6/madrat-cache-used-runs.tsv
git add records/v6 && git commit -m "v6: what the coupled runs read"
Rscript analysis/coupled/runCoupledStage.R v6                # the whole post-batch chain
```

`runCoupledStage.R` (design note 0005 F4) runs `extractCoupledResults`, then **stops** if a run
is still in flight and fails the early-market test (`PITFALLS.md` §25) or a finished run has an
early-period market over tolerance (§25a), and otherwise runs the facts scripts in order
(`coupledBatchFacts` → `coupled-facts.json`, costs, held-budget prices, rule-C freeze,
convergence, provenance), stopping on the first that fails. `--allow-skipped` goes on without the
in-flight runs, listing them.

---

## Showing that a version reproduces

| what | how | passes when |
|---|---|---|
| code | `tools/setup.sh --ref <tag>` | every repository is at the tag |
| input data | `Rscript tools/prepareMadratCache.R --group <group> --check` | nothing would have to be computed |
| estimation | refit into a new group, then `Rscript tools/compareRunGroups.R <group>-repro <group>` | estimates, λ and donor assignments equal within optimizer tolerance |
| one coupling call | `Rscript tools/replayCouplingCall.R <run> <reference run> <group>` | shares within the run's `cm_pfmConvTol` |
| REMIND interface | `pfm::pfmReplayInterface()` (needs GAMS) | the replay passes and the negative control is caught |
| REMIND config | `start.R --test` | 0 errors |
| paper numbers | rebuild the paper's evidence bundle | data files byte-identical |

The `v5` test of 2026-10-01, with every result, is kept in
`../_archive/_wip/2026-10-01/docs/RUNNING.md`.

---

## Still to do before this procedure is finished

1. **Not yet run on the cluster.** Every step above was tested on the workstation only.
   - The single-job chain of Step 6 was tested with the submission mocked.
   - Reading `/p/tmp/benke/clean-cache-aug` was not tested.
   - Neither was the cache preparation on the login node, which can take several minutes for a
     new group.
2. ✅ **Done 2026-10-01:** the project repository is
   <https://github.com/Renato-Rodrigues/pfm-workspace>, in the commands above and in `README.md`.
3. **`/p/tmp` is scratch space and may be cleaned up.** Once `data/madrat/v6` is prepared, it
   holds its own copies. For the long term, deposit the files listed in
   `records/v6/madrat-cache-manifest.tsv` with the version.
4. **Which baselines `v6` uses is not decided.** The options are `v5`'s SSP2 pair (Step 5), or new
   runs with the SSP axis (`design-notes/0005`, P2). Two gaps follow from this:
   - The path `<old REMIND checkout>` in Step 5 still needs filling in.
   - There is no start group that runs only the baselines.
5. **A failed step does not stop the chain** (`design-notes/0005` E23). In one job, the steps after
   it run on whatever artifacts are already there, and the job still ends normally. Until this
   is fixed, read the last lines of the log (`DONE WITH GAPS` names the steps).
6. **The cache preparation uses two internal madrat functions** (ADR 0047). After a madrat
   upgrade, check that `pfmPrepareCache()` gives no warning.
7. **`v5`'s coupled runs read PIK's shared cache, not their Run-Group's.** Fetch the 48 files
   they read (`records/v5/madrat-cache-used-runs.tsv`) before that cache is cleaned up.
