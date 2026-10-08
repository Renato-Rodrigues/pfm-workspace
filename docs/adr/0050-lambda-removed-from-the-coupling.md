# ADR 0050 — λ leaves the coupling; mode M and `GAPCLOSE` retire; a declared closure arm κ

- **Status:** **Accepted 2026-10-08** (author), at the Phase 3 gate of design note 0005 (passed
  2026-10-08, batch `EU21V371`). Drafted 2026-10-07. Records 0005 D13 and closes design note 0003 (λ
  in or out). κ itself is still to be declared before wave 2.
- **Supersedes:** the λ speed limit inside the coupled price (the ECM adjustment speed from
  `temporal-validation.rds`); mode M and the `GAPCLOSE` arm in the batch. Their code stays for `v5`
  reproduction.
- **Run-Groups:** `v6` and later.
- **Evidence:** 0005 D1 / D13; `analysis/v6/offlineHeadline.R` → `output/pfm/v6/phase1/offline-headline.rds`.

## Decision

1. The coupled price bound uses the share path $\varphi(t)$ (ADR 0049) with **no speed limit**.
2. **Mode M**, whose mechanism is λ, leaves the `v6` batch, and so does the **`GAPCLOSE`** arm.
3. Gap closure becomes one declared SI arm on the strength: $k_s(t)\,(1 - \kappa)^{t - t_0}$, κ declared.
4. The ECM stays in `pfm-temporal` as a reported finding (forecast skill, placebo), not as a model
   input.

## Context

- λ is not identified. It sits inside or below its placebo null (0.291 [0.181, 0.419] Bulk / 0.104
  [0.062, 0.209] Diffuse, `TODO.md` 12b). It does not beat persistence, and on annual data it is 1.7×
  (Bulk) and 4× (Diffuse) the smoothed value, largely a smoothing artefact (0004 §2).
- Under ADR 0049 the 2022 → 2035 projection is gone, so λ has no job left. `cm_pfmGapClosure = 0`
  already zeroed it inside the price.
- **The size of the change, offline** (first round, EU21, the `v5` reference and optimal price paths,
  θ = 0.5, median 2050 bound against an optimal $355/tCO2):

  | case | bound | shortfall |
  |---|---|---|
  | `v5` formulation, `v6` spec | $173 | 51% |
  | `v6` φ(t) with the `v6` λ (0.117 Bulk / 0.074 Diffuse) | $182 | 49% |
  | `v6` φ held at $t_0$, no speed limit | $270 | 24% |
  | **`v6` φ(t), no speed limit** | **$291** | **18%** |

  Almost all of the change from `v5` is removing λ; the moving strength adds about 6 points. These
  are offline numbers with no REMIND response.

## Consequences

- The offline bound is λ-free and consistent with the coupled result (D-GP2).
- **Convention:** `exportFeasibilityBound(lambda = 0)` means *no* speed limit. A λ outside (0, 1)
  gives $\lambda^{eff} = 1$, so the bound sits at the political target. Do not read λ = 0 as "frozen
  at the reference price".
- The paper must say that the weaker constraint against `v5` comes mostly from dropping an
  unidentified rate, not from new evidence of feasibility.
- The κ arm runs for rules B and C (0005 Phase 5, wave 2).

## Alternatives rejected

- Keep λ for the 2022 → 2035 step (D13): that step no longer exists.
- Keep `GAPCLOSE` as the closure test: it closes at λ, which is the unidentified quantity.
