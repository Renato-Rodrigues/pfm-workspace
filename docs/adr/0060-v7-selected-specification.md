# ADR 0060 — The v7 specification: v6's channels, democracy-weighted interactions, saturating clean-energy interests

- **Status:** **Proposed 2026-10-22** (author to accept, with ADR 0059).
- **Run-Groups:** `v7` (sweep job 2667134, downstream job 2668570). `v6` is unchanged and stays the basis of the `v6`
  paper.
- **Evidence:** design note 0007 §§12–17; `output/pfm/v7/` (`selected-models-pfm.yml`, `frontier.rds`,
  `inference.rds`, `influence.rds`, `selection-bootstrap.rds`, `sanity-pool.rds`, `edge-of-data.rds`,
  `selection-compare.rds`).

## Decision

1. **The v7 specification is X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satInn iw:fexp**, as
   selected by the declared search with the edge-of-data gate (0007 §5) and the theory gate (ADR 0059):
   - v6's drivers and institutions (state capability, rule of law, vertical accountability; fossil dependence, fossil
     interests per person, clean-energy build-out; GDP, population, hydro and nuclear share; OECD/other levels);
   - the clean-energy interests saturating, the fossil interests linear (`satInn`; v6 saturated both);
   - every interest × institution term weighted by V-Dem's freedom of expression and alternative information
     (`v2x_freexp_altinf`), read year by year with the drivers' lag and held at its last value in scenarios.
2. **No O1 cap in the projections.** The cap test of the edge-of-data check moves the strength k by at most 0.02 and one
   regional rank by more than 0.15 (Middle East, H12, buildings & transport: 0.16).
3. **Estonia stays excluded** (ADR 0058).

## What the evidence supports, and what it does not

| | power & industry | buildings & transport |
|---|---|---|
| fossil dependence (wild p; largest p leaving one country out) | −0.73 (0.008; 0.031) | −0.20 (0.015; 0.052) |
| contingency (strongest fossil × institution term) | fossil pc × state capability −1.02, × rule of law +1.35 (both p < 0.001) | fossil pc × accountability +0.70 (0.001) |
| fossil dependence × accountability | −0.56 (0.40) | −0.29 (0.15); v6 −0.49 (< 0.001) |
| out-of-sample correlation (trained to 2015) / v6 | 0.565 / 0.554 | 0.810 / 0.802 |
| historical replay RMSE / v6 | 0.808 / 0.806 | 0.520 / 0.525 |
| frontier log-likelihood / v6 | −1265.3 / −1256.2 | −529.1 / −503.8 |
| edge gate, cap shift (v6's spec on v7 data) | 0.21, pass (0.56, fail) | 0.09, pass (1.29, fail) |

- **Structural power (H1) is supported in both sectors**, more robustly than in v6 (power & industry: v6's largest
  leave-one-out p 0.24). Same sign under all 7 estimators, significant under 6.
- **Contingency (H2) is supported; its form in buildings & transport is not v6's.** The accountability channel acts
  through the per-person fossil term, not the share. Only the pair is interpretable (ADR 0056): the paper reports the
  fossil effect's dependence on accountability, not one coefficient.
- **The selection is more stable than v6's**: the deployed spec wins 44% of the selection bootstrap's resamples among
  the specs that pass the walk (v6: 15%); every conditional winner is a weighted X-1791 or X-1860 (`bothIncAP`).
- **The edge effects of v6 are gone.** No region has fossil dependence acting against theory (v6: China 97%, Middle
  East 53%, Other Asia 28% in buildings & transport); the mid-century rise of the buildings & transport strength is
  gone (k 0.91, 0.71, 0.59, 0.53, 0.48 in 2030–2100; v6 rose to 0.96 in 2060).
- **The price** is 9 and 25 log-likelihood points against v6 on (nearly) the same data, the cost of weighting the
  interactions by democracy; out-of-sample accuracy does not fall.
- **Not identified, as in v6:** the clean-energy terms (centre sign in power & industry negative, not significant);
  the institution main effects in poor countries with very low fossil energy per person (Sub-Saharan Africa, Other
  Asia: the remaining edge, in the interest space).

## Consequences

- **The regional ranking changes** (EU21; Spearman with v6 0.92 in power & industry, 0.68 in buildings & transport):
  China is no longer the most constrained region in buildings & transport (u 1.00 → 0.35), India no longer in power &
  industry (1.00 → 0.51); Russia & reforming countries become the most constrained in both sectors. The v6
  results that rest on those ranks (the hold-the-budget relocation onto China, away from the Middle East and India)
  are expected to change in the coupled v7 batch.
- **The coupled batch confirms it** (0007 §17). Hold the price: +98.8 Gt (EU21) and +87.9 Gt (H12) at θ 0.5, against
  +118.2 / +112.8 in v6; India leaves the regions that emit more, Russia & reforming enters. Hold the budget: the
  relocation onto China halves (θ 0.5: −4.9 / −6.4 Gt, v6 −10.2 / −8.9) and India no longer emits more (+0.8 / +0.3, v6
  +8.1 / +7.0).
- The paper's methods describe the search, the two gates and the weight; the post-selection caveat of ADR 0059.
- Declared sensitivities (TODO): X-2929 (the search without the theory gate), v6's unweighted spec, the theory gate's
  thresholds.

## Alternatives rejected

- **X-2929** (the search without the theory gate): fails H1 in both sectors; fossil dependence a constraint in 29% of
  power & industry country-years (0007 §13–14).
- **v6's spec unweighted, on v7 data:** fails the edge gate in both sectors (China, Middle East, non-EU North, Other
  Asia), as in v6.
- **X-1791 `satAP iw:fexp`** (v6's transform with the weight): ranks below in the declared order (56 against 18); it
  passes the walk and wins 16.5% of the bootstrap's conditional resamples, so it is the nearest alternative.
