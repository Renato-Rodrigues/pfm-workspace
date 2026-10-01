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
git clone <project-repo> WP3.4-v6
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
./tools/setup.sh --cluster --install --group v6
```

This does four things:
- clones `models/mrpfm`, `models/pfm`, `models/remind_pfm-EU21` and `models/remind_pfm-H12`
  (`papers/` and `docs/` are left out);
- installs `mrpfm` and `pfm` into your R library;
- fills the madrat cache `data/madrat/v6` as described in Step 2;
- writes the commit of every repository to `output/workspace-commits.txt`.

**Locally:** `./tools/setup.sh --install --group v6`. This clones one REMIND checkout,
`models/remind_pfm`, and uses the workstation paths in `config.yml`.

## Step 4 — Install `pfm` in each REMIND checkout

The coupling runs inside REMIND, which has its own R library. The first R start in a checkout
builds that library, which takes a few minutes.

```bash
for r in models/remind_pfm-EU21 models/remind_pfm-H12; do
  (cd $r && Rscript -e 'devtools::install("../mrpfm", quick=TRUE, upgrade="never");
                        devtools::install("../pfm",   quick=TRUE, upgrade="never");
                        cat("pfm", format(packageVersion("pfm")), "\n")')
done
```

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

## Step 7 — Run the coupled REMIND batch

Each coupled row names its Run-Group in the scenario config's column `pfmGroup`. It still says
`v5`, so set it to `v6`, commit and push. Then, for each resolution:

```bash
Rscript analysis/run-groups/validatePFMScenarioConfig.R models/remind_pfm-EU21/config/scenario_config_PFM.csv
cd models/remind_pfm-EU21
git pull
Rscript start.R --test config/scenario_config_PFM.csv startgroup=EU21     # must report 0 errors
Rscript start.R config/scenario_config_PFM.csv startgroup=EU21
cd ../..
```

For H12, do the same from `models/remind_pfm-H12` with `startgroup=H12`.

- Start one start group at a time.
- Start the sensitivity groups (`SCENARIOS.md` §2.5, e.g. `EU21FIXPRICE`) only after the plain
  group's runs have finished.
- A run that does not converge is never given a higher iteration cap. Fix the cause, or start a
  new run from its gdx.

**Locally:** REMIND cannot run, because its input data is not on the workstation. Run only the
`--test` line, in `models/remind_pfm`.

## Step 8 — Check that the runs used the Run-Group's cache

```bash
grep -L "madrat cache: pfm/madrat-cache" models/remind_pfm-*/output/*PFM*/log.txt
```

This lists the coupled runs that did **not** read the staged cache. The list should be empty.

## Step 9 — Bring the results to the workstation

On the workstation, in the project folder:

```bash
tools/syncFromCluster.sh <user>@<host> /p/projects/elevate/WP3.4-v6 v6 --dry-run
tools/syncFromCluster.sh <user>@<host> /p/projects/elevate/WP3.4-v6 v6 --estimation --panels
tools/syncFromCluster.sh <user>@<host> /p/projects/elevate/WP3.4-v6 v6 --runs '*PFM*'
```

Per run, this fetches `fulldata.gdx`, `log.txt` and a few small records into
`output/remind-runs/v6/<res>/<run>/`: about 70 MB a run, not the whole folder.

## Step 10 — Analyse

```bash
git pull                                   # brings records/v6 from Step 6
Rscript tools/listMadratCacheUsed.R output/remind-runs/v6/*/* --out records/v6/madrat-cache-used-runs.tsv
git add records/v6 && git commit -m "v6: what the coupled runs read"
Rscript analysis/coupled/extractCoupledResults.R output/remind-runs/v6 v6
```

Then run the rest of the post-batch chain, in the order of `analysis/README.md` (`coupled/`).

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
2. **`<project-repo>` does not exist yet.** Create the GitHub repository and put its URL here
   and in `README.md`.
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
8. **The `psm` → `pfm` rename is still pending.** It was decided to come first, and it changes
   step and file names used above (`psm-*` steps, `selected-models-psm.yml`).
