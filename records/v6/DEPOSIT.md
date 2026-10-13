# Deposit manifest — Run-Group `v6` (0005 D-M3, Phase 6 step 6)

Prepared 2026-10-13. **Nothing is tagged or uploaded yet**: tags are set and the Zenodo record is made at
submission, from the commits current then. This file says what goes in, where it is, how large it is and
what must be checked before it can be published.

## 1. Code, at a tag per repository

| Repository | Remote | Branch | HEAD on 2026-10-13 | Tag at submission |
| --- | --- | --- | --- | --- |
| project (`pfm-workspace`) | github.com/Renato-Rodrigues/pfm-workspace | main | `9d7aad2` | `v6-paper` |
| `pfm` (model) | github.com/Renato-Rodrigues/pfm | main | `bf5501b` | `v6-paper` |
| `mrpfm` (data layer) | github.com/Renato-Rodrigues/mrpfm | main | `2d4b46a` | `v6-paper` |
| `remind_pfm` (REMIND 3.7.1 fork, coupling module) | github.com/Renato-Rodrigues/remind | pfm | `e4648fcb4` | `v6-paper` |
| `papers/pfm-paper-v6` (manuscript, evidence bundle, figures) | local only, no remote yet | main | — | `submission` |

The batch was run from earlier commits of `pfm` and `remind_pfm` (the provenance of each run is in
`output/pfm/v6/coupling/run-provenance.rds`); the later commits change comments, scenario descriptions and
one test expectation only, no setting. The deposit names both: the commits each run used, and the tag.

## 2. Artifacts

| What | Path | Size | Deposit |
| --- | --- | --- | --- |
| Estimation and selection (frontier, sweep, bootstrap, inference, anchor, projections) | `output/pfm/v6/` | 114 MB | yes, whole |
| Coupled results as analysed (facts, costs, ladder, decomposition, convergence audit, provenance, strength support) | `output/pfm/v6/coupling/` | 3.4 MB | yes (inside the above) |
| What REMIND read (exported anchor, coupling config) | `output/remind-inputs/v6/` | 17 MB | yes |
| Reproduction records (madrat cache manifest, pins) | `records/v6/` | 16 kB | yes |
| Scenario matrix and generated config | `analysis/run-groups/scenario-matrix-v6.yml`, `models/remind_pfm/config/scenario_config_PFM_v6.csv` | small | yes (in the code) |
| Per-run records: `pfm-coupling.yml`, `pfm-phi-history.rds`, `log.txt`, `config.Rdata` | `output/remind-runs/v6/<res>/<run>/` | under 1 MB a run | yes, for all 71 runs |
| Per-run `fulldata.gdx` and `EDGE-T/` | same | 9.1 GB for 71 runs (about 100 MB of gdx and 55 MB of EDGE-T each) | a separate Zenodo record, linked; or on request |
| The `v6` input archive (REMIND input data as staged for the batch) | cluster: `/p/projects/elevate/WP3.4/archive/v6-inputs-2026-10-10/` | 876 MB | **check licences first (§3)** |
| The prepared madrat cache | `data/madrat/v6/` | 16 MB | **check licences first (§3)** |
| The paper's evidence bundle | `papers/pfm-paper-v6/paper-data/output/` | — (built by the loop) | yes |

**Copy the input archive off the cluster** (it lives only there), into the project's archive folder:

```bash
# from the workstation, project root; <user>@<host> as in RUNNING.md step 9
mkdir -p ../_archive/deposit/v6
rsync -av --progress <user>@<host>:/p/projects/elevate/WP3.4/archive/v6-inputs-2026-10-10/ ../_archive/deposit/v6/v6-inputs-2026-10-10/
# without ssh from the workstation: copy that folder with WinSCP to the same place
```

## 3. Before publishing: licences

- **IEA World Energy Balances** feed the energy drivers (`calcPE`, `calcFE` in the madrat cache and in
  REMIND's input data). They are licensed, not open: deposit only derived, aggregated quantities that the
  licence allows, or exclude the cache and say how to rebuild it.
- **OECD CAPMF**: check the terms for redistributing the index; at least deposit the code that reads it.
- **WGI, V-Dem, SSP projections**: open, with citation.
- **REMIND input data**: the input archive mixes sources with different terms; deposit the archive's
  manifest and REMIND's input-data version rather than the files where the terms are unclear.

## 4. At submission

1. Tag the four repositories (§1) and push the tags; give `papers/pfm-paper-v6` a remote.
2. Rebuild the evidence bundle and the figures from the tagged code (`papers/pfm-paper-v6`, `paper-data`).
3. Make the Zenodo record(s): code + artifacts (§2) in one, the `fulldata.gdx` set in a second, linked.
4. Put the DOIs in the paper's code and data availability statements (Methods §9).
