# CLAUDE.md

Guidance for Claude Code working in this repository. **Read this file plus the one topic doc
your task needs — not the whole `docs/` tree.**

## What we are building

One thing, with one output: **a Nature Climate Change paper showing what political feasibility
does to a cost-optimal mitigation pathway.**

The mechanism is a **feasibility frontier** — a stochastic frontier that turns institutions and
actor coalitions into a ceiling on carbon-price stringency — coupled into **REMIND** so the
ceiling acts as an endogenous constraint rather than an exogenous assumption. Everything in
this repo exists to estimate that frontier, couple it, and write that paper.

Two consequences for how work is judged here:

- **Claim ≤ evidence.** Several central quantities are deliberately *not* identified ($\theta$,
  the causal feedback, the accountability channel). Reporting that honestly is the contribution,
  not a weakness to write around.
- **The coupled result is the paper.** Estimation improvements that do not change what the
  coupling delivers are not the priority.

## Where to look

| You are working on | Read |
|---|---|
| the model, its maths, its numbers | `docs/MODEL.md` |
| the REMIND interface, running or debugging a coupled run | `docs/COUPLING.md` |
| what a coupled scenario is for, and what its results mean | `docs/SCENARIOS.md` |
| what to do next | `docs/TODO.md` |
| anything that touches mappings, caches, the cluster, or the gdx | `docs/PITFALLS.md` — **read before, not after** |
| explaining the work to a non-modeller | `docs/EXPLAINER.md` |
| presenting it — a deck, a poster, which figure goes where | `docs/PRESENTATION.md` |
| why something is built the way it is | `docs/adr/README.md`, then the ADR |
| what a project word means | `docs/CONTEXT.md` |
| how the tree is organised, and where a new version goes | `README.md` |
| setting up, running on the cluster, syncing back, reproducing a version | `docs/RUNNING.md` |
| the next model version (v6) | `docs/design-notes/0005-v6-implementation-plan.md` |
| the `v5` paper (frozen) | `papers/pfm-paper-v5/CLAUDE.md` |

Nothing else at `docs/` top level is authoritative. Its subfolders hold decisions (`adr/`) and open
questions (`design-notes/`). Derived write-ups for people outside the loop (methodology docx, decks)
live outside the project, in `../communication/`. External and evidence references (the
spec-selection evidence of 2026-09-15, the Estonia PE-coal note, the HPC2024 guide) are in the
archive, `../_archive/_wip/2026-10-01/docs/reference/`.

Superseded material leaves the project. It moves to `../_archive/_wip/<date>/<original path>`,
with a line in that date's `MOVES.md`. The most recent move is **2026-10-01**, the pre-`v5`-tag
cleanup and regrouping. `../_archive/_wip/2026-09-16/docs-pre-v5-sweep/` carries the governed
documents as they stood before they were rewritten on Run-Group `v5`.
The governed documents describe **only the current version**; anything they no longer need is in
the archive with a pointer left behind.

## Layout

Full description, the version-keyed layout and the cluster procedure are in `README.md`.

```
models/         MODEL CODE, one git repo each:
                mrpfm/        data layer — madrat read*/calc*/convert*/tool* producing magpie objects
                pfm/          compute layer — panel, estimation, selection, frontier, projection,
                              coupling export. Standalone: library(pfm). Entry point pfmRun().
                remind_pfm/   REMIND fork, module 45_carbonprice/functionalForm and the coupling
                              (on the cluster: remind_pfm-EU21/ and remind_pfm-H12/)
analysis/       EVIDENCE: run-groups/ coupled/ checks/ v6/ figures/ (its README)
tools/          OPERATING A WORKSPACE: setup.sh, repos.txt, madrat cache, cluster sync, reproduction checks
docs/           the governed documents + adr/ design-notes/
papers/         own git repos, not in the project repo: paper-forge/ (the toolkit — edit
                skills HERE, never in a workspace's copy), pfm-paper-v5/ (frozen at v18); the v6
                paper becomes pfm-paper-v6/
records/<group>/ tracked reproduction records: madrat cache manifest and pins (ADR 0047)
data/madrat/<group>/ the Run-Group's prepared madrat cache (pfmPrepareCache; config.yml madrat:, ADR 0047)
output/         pfm/<group>/  pfm/fit-cache/  remind-inputs/<group>/  remind-runs/<group>/<res>/
config.yml      scenario registry, paths, Run-Group. Paths resolve against THIS file's folder.
```

## Commands

Compute goes through one entry point, from an R session or `Rscript`:

```r
pfmRun(group = "v5", stage = "sweep",       cluster = "slurm")  # estimate + select
pfmRun(group = "v5", stage = "diagnostics", cluster = "slurm")  # inference + replay gate
pfmRun(group = "v5", stage = "downstream",  config = "config.yml")
pfmRun(group = "v5", stage = "remind",      remindDir = "output/remind-inputs")
pfmRun(group = "v5", stage = "all",         cluster = "slurm")  # every step, in order
pfmRun()                                                        # interactive; shows its plan
```

Package work, from inside `models/mrpfm/` or `models/pfm/`:

```r
devtools::install_deps(); devtools::test(); devtools::document()
testthat::test_file("tests/testthat/test-<name>.R")
lucode2::buildLibrary()      # full PIK validation
```

Requires `options(repos = c(CRAN = "@CRAN@", pik = "https://rse.pik-potsdam.de/r/packages"))`.
Pre-commit hooks enforce: parsable R, deps-in-desc, no `browser()`/`debug()`, tidy DESCRIPTION.

## Rules

**Naming.** Documents, code and the paper say **PFM** and *feasibility frontier*. The older
`psm*` prefix was renamed to `pfm*` on 2026-10-02 (`design-notes/0005` D21). What still says
`psm`, on purpose:
- artifacts written before the rename (`v5` and earlier: `selected-models-psm.yml`, `psm-*`
  step names in `manifest.json`). They are frozen, and the code reads both names;
- cache identity: the fit-cache key `psm-<estimator>`, the bootstrap-cache tag and its
  `psmboot_` files. Renaming them would invalidate every cached fit;
- old Run-Group names (`psm-country-v3` …), archived file names, the ADRs, and
  `papers/pfm-paper-v5`.

Do not "fix" any of these.

**Layer boundaries.** `mrpfm` produces magpie objects; `pfm` consumes them. The `calc*` prefix
is exclusive to `mrpfm` (madrat convention) — in `pfm` the equivalent is `compute*`, and a
`calc*` in `pfm` is a naming error. `pfm` computes and never renders; `analysis/figures/` renders and
never fits or selects. The contract between them is the Run-Group artifact set.

**Numbers carry their Run-Group.** Every quoted figure names the artifact it came from. Run-Groups
are re-cut often and the same quantity legitimately differs between them; a number without its
group is not checkable. Do not copy numbers between documents — re-read them from the artifact.

**The retired model.** The original two-stage hurdle model (adoption logit + stringency GLM)
is superseded by the frontier. Its code still exists and its config keys still parse; do not
extend it, and do not describe it as current.

**Before a cluster run**, re-read `docs/PITFALLS.md` §1–§3. The three failures that have cost
the most time — a mapping that was edited but not installed, a fix that was never pushed, and a
cache pointed at the wrong place — are all silent.
