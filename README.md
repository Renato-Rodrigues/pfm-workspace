# PFM — political feasibility frontier, coupled into REMIND

This tree builds **one line of work**:
- a feasibility frontier estimated from institutions and actor coalitions;
- its coupling into REMIND as an endogenous ceiling on carbon-price stringency;
- the Nature Climate Change paper that reports what the ceiling does to a cost-optimal mitigation
  pathway.

The work advances in **model versions**. A model version is a **Run-Group**: one estimation panel,
one deployed specification, one coupled batch. Each paper version is written on exactly one
Run-Group. Everything that differs between versions is keyed by the Run-Group name. Everything
that does not differ exists once.

| model version (Run-Group) | status | paper workspace | PFM results | coupled runs | design |
|---|---|---|---|---|---|
| `v5` (country resolution, spec `X-2079`) | **frozen** — the `v5` record, tagged `v5-final` | `papers/pfm-paper-v5/` (frozen at v18; superseded by the v6 paper) | `output/pfm/v5/` (+ `v5-noinc`, `v5-specalt`) | `output/remind-runs/v5/{EU21,H12}/` | `docs/` as of 2026-10-01, ADRs ≤ 0046 |
| `v6` (country resolution, spec `X-1791 … satAP`; share path φ(t)) | **current** — estimation, offline formulation and the coupled batch complete (64 runs, REMIND 3.7.1, 2026-10-10); analysis and paper in progress | `papers/pfm-paper-v6/` (to be created like `pfm-paper-v5`) | `output/pfm/v6/` (+ `v6-annual`, `v6-specalt`, `v6-sat05`, `v6-sat2`, the assignment twins) | `output/remind-runs/v6/{EU21,H12}/` | `docs/` (rewritten for `v6` 2026-10-10), ADRs 0049–0055, `docs/design-notes/0005-v6-implementation-plan.md` |
| `v1`–`v4` | superseded, never quoted | — | archived | archived | archived |

**Lineage to keep with `v5`.** `v5`'s specification selection is a re-cut of the `v4` sweep under a
changed gate (`output/pfm/v5/recut-provenance.json`). `output/pfm/v5/sweep.rds` already carries
everything it inherited, so `v5` reads nothing from `v4`. But the `v4` sweep is its provenance: it
is in `../_archive/_wip/2026-10-01/output/v4/sweep.rds` and belongs in the `v5` deposit.

Agent instructions are in `CLAUDE.md`; project vocabulary is in `docs/CONTEXT.md`.

---

## Layout

```
README.md  CLAUDE.md
config.yml           paths, scenario registry, default Run-Group (paths resolve against this folder)

tools/               OPERATING A WORKSPACE (not evidence)
  setup.sh             create or update a workspace, on the workstation or the cluster
  repos.txt            the model and paper repositories and where they go (read by setup.sh)
  prepareMadratCache.R, listMadratCacheUsed.R   the madrat cache and its records (ADR 0047)
  clusterRun.sh        cluster: update, install, verify, clean and submit Run-Groups (priority / standby) in one call
  clusterSubmit.R      cluster: submit one Run-Group on a chosen queue (called by clusterRun.sh)
  syncFromCluster.sh   cluster → workstation: runs, Run-Groups, panels, REMIND exports
  compareRunGroups.R, replayCouplingCall.R      did a version reproduce? one coupling call, replayed

models/              MODEL CODE — each folder is its own git repository (not in the project repo)
  mrpfm/               data layer (madrat): read/convert/calc → magpie objects
  pfm/                 compute layer: panel, estimation, selection, frontier, coupling export (pfmRun)
  remind_pfm/          REMIND fork, branch `pfm` (workstation: one checkout, for configs)
  remind_pfm-EU21/ remind_pfm-H12/   (cluster: one checkout per resolution)

analysis/            EVIDENCE — scripts that turn artifacts and runs into results (index: its README)
  run-groups/          Run-Group variants, donor step, REMIND scenario config build/validate
  coupled/             after a batch: extract → facts → costs → prices → audit → provenance
  checks/              evidence checks behind claims
  v6/                  v6 preparation tests
  figures/             the shared figure layer: one registry, one builder per figure, every medium
  _common/             _loadPfm.R (load pfm from source)

docs/                KNOWLEDGE
  *.md                 the governed documents: what the model IS, for the current version
  adr/                 decisions taken, with their reasons
  design-notes/        open questions and plans (decision support); 0005 = the v6 plan

records/             REPRODUCTION RECORDS, tracked in git, one folder per Run-Group (records/README.md)
  <group>/madrat-cache-manifest.tsv   the madrat input files the group reads, with md5 (ADR 0047)
  <group>/madrat-cache-used-*.tsv     the pin (estimation) and what the coupled runs read

papers/              PAPERS — each folder is its own git repository (not in the project repo)
  paper-forge/         the paper toolkit
  pfm-paper-v5/        the v5 paper workspace (paper-forge layout; frozen at v18; repo still to be created)

data/                INPUTS from outside (not in git)
  madrat/<group>/      the Run-Group's prepared madrat cache + cache-manifest.tsv (ADR 0047)
  madrat/legacy/       the flat project cache as it stood before 2026-10-01; a copy source, never read directly

output/              EVERYTHING THIS PROJECT PRODUCES (not in git), keyed by Run-Group
  pfm/<group>/         PFM artifacts of one Run-Group (v5, v5-noinc, v5-specalt, …)
  pfm/fit-cache/       the shared, content-addressed model store (models/, panels/, index.json, boot-cache/)
  pfm/panel-cache/     scenario panels per Run-Group, written by the coupling-bound step
  remind-inputs/<group>/   what pfmRun(stage = "remind") exports for REMIND (cfg$pfm$source)
  remind-runs/<group>/<res>/<run>/   REMIND runs, copied from the cluster (fulldata.gdx, log.txt, …)
  workspace-commits.txt   the commit of every repository, written by tools/setup.sh
```

Outside the project, next to it:
- the archive, `../_archive/_wip/<date>/<original path>`, with a `MOVES.md` per date;
- `../communication/`: derived write-ups for people outside the loop (methodology docx, decks).

**What the project repository tracks:** the root files, `analysis/` (code, not
`analysis/figures/output/`), `docs/` and `records/`. Everything else is either its own repository
(`models/*`, `papers/*`, listed in `tools/repos.txt`) or data and output (`data/`, `output/`).

---

## Running a version

The full procedure, step by step, is in **`docs/RUNNING.md`**: create the cluster folder, set up,
estimate, run the coupled batch, bring the results back, and show that a version reproduces. In
short:

```bash
# workstation
./tools/setup.sh --install                # models/, R packages, then the madrat cache data/madrat/<group>

# cluster, once per model version
git clone https://github.com/Renato-Rodrigues/pfm-workspace.git /p/projects/elevate/WP3.4-v6 && cd /p/projects/elevate/WP3.4-v6
./tools/setup.sh --cluster --install --group v6   # models/ incl. one REMIND checkout per resolution; data/madrat/v6
#   then: pfm into each REMIND checkout's own library, the baseline runs, then ONE estimation job:
#   Rscript -e 'library(pfm); pfmRun(group="v6", stage=c("sweep","diagnostics","downstream","remind"), cluster="slurm", config="config.yml")'
#   then start.R --test and start.R per resolution

# back on the workstation
tools/syncFromCluster.sh <user>@<host> /p/projects/elevate/WP3.4-v6 v6 --estimation --panels
tools/syncFromCluster.sh <user>@<host> /p/projects/elevate/WP3.4-v6 v6 --runs '*PFM*'
```

Two rules from the 2026-10-01 reproduction test:
- **One prepared madrat cache per Run-Group.** Under `forcecache`, the version madrat reads is
  decided by the cache contents and file timestamps, not by the code. So `data/madrat/<group>/`
  holds exactly what the pipeline reads, listed in its `cache-manifest.tsv`, and the REMIND export
  stages the coupling's part into every run folder. Machine paths (cache sources, raw sources)
  go in `config.yml` `madrat:`, not in environment variables. ADR 0047.
- **A run that does not converge is never given a higher iteration cap.** Fix the cause, or
  restart it from its gdx.

---

## Where a new model version goes

Adding `v6` changes no existing folder's contents. It adds one entry per version-keyed place:

| what | where |
|---|---|
| estimation artifacts | `output/pfm/v6/` (and `output/pfm/v6-<variant>/`) |
| REMIND input export | `output/remind-inputs/v6/` |
| coupled runs | `output/remind-runs/v6/{EU21,H12}/` |
| analysis | the same scripts, run with `v6` and `output/remind-runs/v6` |
| figures | the same builders, run with `--group=v6` |
| paper | `papers/pfm-paper-v6/`, scaffolded with the toolkit from `papers/pfm-paper-v5/` as the draft |
| design and decisions | `docs/design-notes/` → ADRs in `docs/adr/` |
| a tag in every repository | `v6-final` when the version is frozen |

**Governed documents** describe only the current version. When v6 replaces v5, the `v5` versions
of `docs/*.md` move to the archive (`../_archive/_wip/<date>/docs/`), and the documents are
rewritten.

## Rules that keep this tree consistent

- **Numbers carry their Run-Group.** A number is re-read from `output/pfm/<group>/…`, never copied
  between documents.
- **Superseded material is archived, not deleted.** It goes to `../_archive/_wip/<yyyy-mm-dd>/<path
  as it was in the project>` (the archive keeps the project's former folder name, `_wip`), with a line in that date's `MOVES.md`. Live documents point at the archive
  path.
- **One home per thing.**
  - code: `models/`;
  - evidence and figures: `analysis/`;
  - the model description and decisions: `docs/`;
  - papers: `papers/`;
  - inputs: `data/`;
  - everything produced: `output/`.

  A copy elsewhere is a duplicate to remove.
- **Model code is versioned in its own repositories.** Tag every repository at the commit that
  produced a Run-Group (e.g. `v5-final`). `output/workspace-commits.txt` records what a workspace
  was built from.
