# ADR 0057 — The growing-limit rate is declared at κ = −0.005 a year, as a bound

- **Status:** **Accepted 2026-10-13** (author). The rate was proposed on 2026-10-12, when the growing limit was added
  to the matrix for the paper frames (design note 0006), and run at that value (`V6BACK`, landed 2026-10-13). This
  ADR declares it, after the runs, on two checks that do not depend on their results.
- **Run-Groups:** `v6` and later.
- **Evidence:** `analysis/v6/growingLimitRate.R` → `output/pfm/v6/coupling/growing-limit-rate.{rds,json}`
  (2026-10-13); the runs `SSP2-EU21-PkBudg1000-PFMlevelBfix-backslide-v6` and `-PFMlevelC-backslide-v6`.

## Decision

1. **κ = −0.005 a year** for the growing limit: the constant limit times $(1-\kappa)^{t-2025}$, so the limit
   tightens 0.5% a year from 2025. In the hold-the-price run, $k$ = 1.12 / 1.45 (power & industry) and 1.13 / 1.46
   (buildings & transport) in 2050 / 2100.
2. **It is a bound, not a case.** The paper presents it as the worse-than-today end of the persistence ladder:
   what holding today's ordering *and* tightening it would cost. It is never a central case, and its numbers are
   quoted with the rate.
3. **No other rate is run.** Faster rates are outside what the share formula represents (Context 1). A slower
   bracketing rate (−0.0025) would show the dose response; it was considered and not taken, because the
   constant limit (κ = 0) already brackets the growing limit from below on the same ladder.
4. Like θ and κ > 0 (ADR 0050), the rate is a declared assumption, never an estimate.

## Context

1. **The bound: −0.005 is the fastest rate the share formula represents at every declared severity.** The share is
   $\varphi = 1 - \theta\,k\,u$, clipped at 0, and the most constrained country has $u = 1$ (the min–max
   normalisation), so its share reaches 0 once $k = 1/\theta$: 1.48 at the highest declared severity, θ = 0.675.
   A share of 0 is a policy freeze for that country, which the model was not built to represent. With $k$ of the
   constant limit read from the growing-limit run itself (the larger of the two sectors), the most constrained
   share in 2100 at θ = 0.675 is:

   | κ a year | $k$ 2050 | $k$ 2100 | most constrained share 2100 (θ = 0.675) |
   |---|---|---|---|
   | −0.003 | 1.08 | 1.25 | 0.15 |
   | −0.004 | 1.11 | 1.35 | 0.09 |
   | **−0.005** | **1.13** | **1.46** | **0.02** |
   | −0.006 | 1.16 | 1.57 | 0 from 2100 |
   | −0.008 | 1.22 | 1.82 | 0 from 2080 |
   | −0.010 | 1.28 | 2.11 | 0 from 2070 |

   The exact limit is −0.0052 a year; −0.005 is the fastest rate in steps of 0.1 point that stays inside it. The
   proposal of 2026-10-12 gave the same reason at θ = 0.50 (the most constrained share stays above 0.27,
   `scenario-matrix-v6.yml`), before the runs; the run reproduces it (0.275 power & industry, 0.272 buildings &
   transport, 2100).
2. **History: the rate is a persistent but not an extreme deterioration.** The gap below the ceiling
   ($1 - $ the share of the ceiling realised), 2008–2023, yearly log trend per country (`frontier.rds`), weighted
   by 2025 final energy:

   | | power & industry (43 countries) | buildings & transport (37) |
   |---|---|---|
   | weighted mean gap | shrank 3.1% a year | widened 5.0% a year |
   | share of countries whose gap widened (weighted / unweighted) | 13% / 33% | 79% / 60% |
   | median country (unweighted) | −1.7% a year | +0.6% a year |
   | without China: weighted median / 90th percentile | −3.0% / +4.1% a year | +0.5% / +11.1% a year |

   China carries 46% and 52% of the weight; its gap shrank 10% a year in power & industry and widened 11% a year
   in buildings & transport, so the weighted figures are largely China's. In power & industry, where gaps mostly
   closed, 0.5% a year of tightening is a sustained reversal. In buildings & transport it is about what the median
   country showed. Faster sustained widening was observed in some countries, so the rate is not the worst case
   history allows, but it is the fastest the formula represents (Context 1). The panel is a five-year moving
   average, and fifteen years is short: this is a plausibility check on the size of the rate, not an estimate,
   for the reason ADR 0050 rejected estimating κ from the drift of the gap.
3. **Declared after the runs.** The declaration rests only on the two checks above, which use the formula, the
   declared severities and the historical panel. Neither uses a coupled result. The coupled results at this rate
   (`SCENARIOS.md` §4.9: +245.3 Gt under hold the price; ×1.64 on the global price and 97.5 Gt moved under hold
   the budget) played no part in the choice, and the paper says that the rate was proposed, run and then declared.

## Consequences

- The paper and the SI quote the growing limit as a bound "at a declared 0.5% a year", with the reason in one
  sentence (the formula's limit at the highest severity) and the historical check in the SI.
- The growing limit runs only at θ = 0.50; at θ = 0.675 it would leave the most constrained country a share of
  0.02 by 2100. Any later run of it at a higher severity checks this bound first (`growingLimitRate.R`).
- `TODO.md` item 2, 0005 and 0006 record the declaration; the persistence ladder needs no re-run.

## Alternatives rejected

- **A rate matching the central erosion rate (−0.027):** $k$ reaches 1/θ for θ = 0.675 by 2040; most of the
  century would sit at the zero-share clip, and the result would measure the clip, not the politics.
- **A rate estimated from the widening of the gap:** the identification problem of λ (ADR 0050), and in buildings
  & transport it would mostly be China's trend.
- **Two growing rates (−0.0025 and −0.005):** two more EU21 runs for a dose response the constant limit already
  bounds from below; kept as an option if a referee asks.
