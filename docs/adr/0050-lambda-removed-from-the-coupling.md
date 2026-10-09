# ADR 0050 — λ leaves the coupling; mode M and `GAPCLOSE` retire; a declared closure arm κ

- **Status:** **Accepted 2026-10-08** (author), at the Phase 3 gate of design note 0005 (passed
  2026-10-08, batch `EU21V371`). Drafted 2026-10-07. Records 0005 D13 and closes design note 0003 (λ
  in or out). **κ declared 2026-10-08** (author), before any wave-2 run: 0.027 a year, with 0.02 and 0.05
  as sensitivities (decision 5 below).
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
5. **κ = 0.027 a year** (declared 2026-10-08): *beyond what the drivers already do, the political drag
   halves by mid-century* (half-life 25 years). Sensitivities **0.02** (about 35 years) and **0.05**
   (about 14 years). Each runs for rule B and rule C at θ = 0.50, EU21, wave 2: `-PFMlevelBfix-kappa`,
   `-kappa02`, `-kappa05` and the three `-PFMlevelC-` twins (`scenario-matrix-v6.yml`, option
   `pfmPhiKappa`). κ is a declared assumption like θ, never an estimate: the rate it stands in for, λ,
   is not identified (Context). **Start (decided 2026-10-09):** the fade is counted from $t_0$ = 2025,
   $(1-\kappa)^{t-2025}$, so κ has no effect in 2025 and acts from 2030, REMIND's first free period,
   which already carries five years of it (13% less drag at 0.027). Counting from 2030 was considered
   and not taken: it would have left 2030 untouched too.

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
- The κ arm runs for rules B and C (0005 Phase 5, wave 2), at three values.
- What κ does, offline (Run-Group `v6`, EU21, the uncoupled 3.7.1 `SSP2-EU21-PkBudg1000` base,
  `output/pfm/v6/phase1/strength.rds`, 2026-10-08). Floor φ = the most constrained region's share at θ = 0.50:

  | κ per year | half-life | Bulk $k$ 2050 / 2100 | floor φ Bulk 2050 / 2100 | floor φ Diffuse 2050 / 2100 |
  |---|---|---|---|---|
  | 0 (headline) | none | 0.63 / 0.49 | 0.69 / 0.76 | 0.57 / 0.64 |
  | 0.02 | 34 y | 0.38 / 0.11 | 0.81 / 0.95 | 0.74 / 0.92 |
  | **0.027** | **25 y** | **0.32 / 0.06** | **0.84 / 0.97** | **0.78 / 0.95** |
  | 0.05 | 14 y | 0.17 / 0.01 | 0.91 / 0.99 | 0.88 / 0.99 |

## Alternatives rejected

- Keep λ for the 2022 → 2035 step (D13): that step no longer exists.
- Keep `GAPCLOSE` as the closure test: it closes at λ, which is the unidentified quantity.
- κ = λ (`v5`'s 0.11 a year, half-life 6 years): the same unidentified rate under another name; it
  removes the constraint by about 2040, which the θ = 0 null `-PFMgateBfix` already shows.
- κ estimated from the 2000–2023 drift of the gap: the same identification problem as λ, and an
  estimate would present an assumption as evidence.
- One κ only: chosen against, because two sensitivities show how fast the result fades, at four EU21 runs.
