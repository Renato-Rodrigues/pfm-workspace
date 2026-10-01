# ADR 0047 — One prepared madrat cache per Run-Group, staged into every coupled run

- **Status:** Accepted
- **Date:** 2026-10-01
- **Answers:** `docs/design-notes/0005-v6-implementation-plan.md` E24 (and closes E25 for new groups)
- **Run-Group:** from `v6` on. `v5` is not re-run; its cache is rebuilt for reproduction only (see Consequences)

## Decision

1. **One project cache per Run-Group.** `config.yml` `madrat: cachefolder` is
   `data/madrat/{group}`: the Run-Group fills the tag. A fixed tag (`data/madrat/2026-10`) lets
   several groups share one cache on purpose.
2. **The cache is prepared, not accumulated.** `pfm::pfmPrepareCache()` runs the pipeline's own
   data builders against it and watches every madrat cache lookup. A miss is copied from the
   configured `cacheSources`, in order, choosing the file madrat itself would read there. What no
   cache has is computed from `sourcefolder`. The files read are written to
   `cache-manifest.tsv`, with size, md5, origin and the builders that read them. A Run-Group that
   recorded what it read (`records/<group>/madrat-cache-used-pfm.tsv`) is *pinned*: those exact files are copied
   first.
3. **It runs automatically.** It runs in `tools/setup.sh` once `pfm` is installed, and in
   `pfmRun()` before any step is run or submitted. A complete cache is confirmed from the
   manifest in about 0.1 s.
4. **The coupling reads the same cache.** The REMIND export copies the manifest's
   scenario-panel and coupling-weight files to `output/remind-inputs/<group>/madrat-cache/`.
   `preparePFM.R` copies them into `<run>/pfm/madrat-cache/` and names them in
   `pfm-coupling.yml`. `iterativePFM()` reads them with `forcecache`. The run folder stays
   self-contained, as `preparePFM.R` requires.
5. **Machine paths live in `config.yml`, not in environment variables.** `sourcefolder` and
   `cacheSources` are lists of candidates. A path that does not exist on this machine is skipped,
   so one committed file serves the workstation and the cluster. `useMadratConfig: true` adds
   madrat's own configured cache and sources as the last resort; on the PIK cluster these are the
   shared input data.

## Context

Under `forcecache = TRUE`, madrat accepts any cache file whose arguments match. Among several, it
reads the one with the **newest file time**. The data a step reads was therefore decided by
whatever sat in the cache folder and by `cp` timestamps, not by the code. On `v5`
(the reproduction test of 2026-10-01, kept in `../_archive/_wip/2026-10-01/docs/RUNNING.md`, §1 and §6):

- The estimation read `calcFE-F9005b22a` / `calcPE-F9aca69d1` from the project cache.
- The coupled runs read other versions from PIK's shared cache: EU21 `calcFE-F0d73e4e2` /
  `calcPE-F6699a843`; H12 `calcFE-F865b4193` / `calcPE-F8c2d3ac6`. `iterativePFM()` set no
  cache folder.
- A local refit that picked up the newer 08-26 versions moved China's share from 0.50 to 0.645
  at θ = 0.5.
- Replaying one `v5` coupling call against the project cache gave shares up to 0.039 off the
  shares the run used.

So `v5`'s offline numbers and its coupled runs rest on different data versions. The paper's
coupled result and its offline bound cannot be traced to one input set.

## Alternatives considered

- **Copy everything from the shared caches into one project cache.** Rejected: that is the
  `v5` state. It holds several versions of each calculation, and the newest wins silently.
- **Point the coupling at the project cache by absolute path.** Rejected: it breaks the
  self-contained run folder. Concurrent runs that miss the same file would all compute into one
  folder.
- **Stage every file of the project cache into each run.** For `v5` this would be almost the
  same: the coupling reads 11 of the 13 files, 14.8 of 14.9 MB. Only the coupling's subset is
  staged anyway. The manifest records which builder reads which file, and a later group may
  add files that only the estimation reads.
- **A static list of needed files, derived from the code.** Rejected: the cache file name
  depends on the call's arguments. Only a lookup made with the real arguments says which file
  is needed. The builders make those lookups.

## Consequences

- Estimation, projection, offline bound and coupling of a Run-Group read **one set of data
  versions**, listed with checksums in `data/madrat/<group>/cache-manifest.tsv`. Its portable copy,
  `records/<group>/madrat-cache-manifest.tsv`, is tracked in git: it is what a version deposits
  as its input data.
- **`v5` is unchanged.** Its runs keep reading what they read. `data/madrat/v5` was rebuilt from
  its pin and holds the 12 files the `v5` estimation read, plus the default-argument
  `calcPolicyStringency`. Reproducing `v5`'s *coupled* shares still needs the shared-cache files
  its runs read (`records/v5/madrat-cache-used-runs.tsv`), passed to `replayCouplingCall.R --cachefolder`.
- **A new group's first preparation is real work**: about 5 minutes on the workstation to build
  a 13-file cache from the REMIND input cache and local sources (2026-10-01). On the cluster it
  runs on the login node, before `pfmRun()` submits.
- **What the builders do not cover is not prepared.** Covered: the historical panel (two- and
  four-sector policy stringency), the scenario panel and the coupling weights (`weightYear` 2025,
  SSP2). Not covered:
  - a step calling madrat with other arguments still computes into the cache on a miss;
  - a coupled run under another SSP computes its weights' GDP in its run folder;
  - figures reading other calculations (`calcGDPPast`) look in the cache sources too.
- **Intermediate files stay in the cache folder.** Computing a file leaves its own inputs (read,
  convert, fileHash files) there. They are not in the manifest and do not compete with the files
  the pipeline reads (different calls).
- **It relies on madrat internals.** It traces `madrat:::cacheGet` and calls
  `madrat:::cacheNames(prefix, type, args)`; tested against madrat 3.41.3. If a madrat release
  changes them, `pfmPrepareCache()` warns and stops copying; it does not guess.
- A coupled run whose staged cache misses a file computes it from madrat's sources into
  `<run>/pfm/madrat-cache/`, where it stays visible.
