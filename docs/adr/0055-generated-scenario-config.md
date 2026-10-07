# ADR 0055 — The scenario config is generated from a compact matrix

- **Status:** **Accepted and implemented 2026-10-07** (author's request). Records 0005 D22 (F1 / E16).
  As built: `pfm::buildPFMScenarioConfig()`, the matrix `analysis/run-groups/scenario-matrix-v6.yml`,
  the output `config/scenario_config_PFM_v6.csv` in the fork. It reproduces the hand-written bases,
  `-PFMgateRef` and the four Phase 3 gate rows exactly. The `v5` rows stay hand-maintained in
  `scenario_config_PFM.csv` (the `v5` record); the v6 batch is built only from the matrix.
- **Run-Groups:** the `v6` coupled batch and later.

## Decision

1. One YAML matrix lists the canonical parents per SSP and resolution, the arms (closure, θ, markup,
   ordering test, hold year, spread, κ, institution rule, actor-power shape), the Run-Group per arm,
   the warm-start chain and the start tags.
2. `buildPFMScenarioConfig()` writes `scenario_config_PFM.csv`, and `validatePFMScenarioConfig()` runs on
   the output. Section separators and `path_gdx` chains are generated, not typed. The CSV becomes a
   build artifact.
3. The generator never writes `cm_iteration_max` (the author's rule: a non-converging run is
   diagnosed or restarted from its gdx, never given a higher cap).

## Context

- The CSV has 83 columns per row, almost all copied from a parent. It has been hand-maintained since
  2026-09-18, and the old generator no longer reproduces it ("regenerating … DESTROYS work").
- The failure the generator was written to prevent - a PkBudg1000 family carrying a PkBudg750 parent's
  switches - is therefore possible again.
- The `v6` batch adds the institutions-held twins, the shape twins and family B as Run-Group variants
  (ADR 0051, 0052), and later an SSP axis.

## Consequences

- Adding an arm or an SSP becomes one line of the matrix.
- The variant Run-Groups (`v6-specalt`, `v6-sat05`, `v6-sat2`, the assignment-rule twins) are named in
  the matrix, so `pfmPreflight` can check each one's export before submission.

## Alternatives rejected

- Keep hand-editing the CSV.
