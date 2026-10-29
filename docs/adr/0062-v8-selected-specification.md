# ADR 0062 — The v8 specification: v7's channels, every actor-power term saturating, the fossil terms bounded, the rents slack

- **Status:** **Proposed 2026-10-29.** With ADR 0061 (the rents slack). For acceptance before the v8 coupled batch.
- **Run-Groups:** `v8` (sweep and downstream job 2764125; `records/v8`). `v7` is unchanged and stays the basis of everything
  quoted on it.
- **Evidence:** design note 0009 §§7, 9, 11–17; `output/pfm/v8/` (`selected-models-pfm.yml`, `sweep.rds`, `frontier.rds`,
  `inference.rds`, `selection-bootstrap.rds`, `phi-anchor.rds`); `analysis/v8/checkV8.R`. Every number below is from Run-Group
  `v8` unless it names `v7`.

## Decision

1. **The v8 specification is
   `X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP iw:fexp fos5`**, selected by the declared search
   (v7's grid, gates and selection rule) with v8's three changes:
   - the fossil terms bounded below at the training 5th percentile (`fos5`; design note 0009 §7.1);
   - the World Bank rents setting the size of the buildings & transport slack (ADR 0061);
   - the uncovered countries at the covered median (design note 0009 §6.3).
2. **The same channels and the same weight as v7.** State capability, rule of law and vertical accountability; fossil
   dependence, fossil interests per person, clean-energy build-out; GDP, population, hydro and nuclear; OECD/other levels;
   every interest × institution term weighted by freedom of expression.
3. **The only change of form: every actor-power term saturates (`satAP`), where v7 saturated clean energy only (`satInn`).**
   It follows from the γ gate, not from a preference (below).
4. **Countries without policy data take the covered countries' median share of their ceiling** (config.yml
   `coverage: v8: median`), in place of v7's donor and band rule. Each keeps its own ceiling; only the share it uses is
   assigned. The United States, outside the CAPMF panel, is at the median as before.
5. **The regional strength is the central coupling form** (`pfmPhiStrength = regional` on every v8 row,
   `analysis/run-groups/scenario-matrix-v8.yml`): each region's constraint fades with its own gap, $k_r(t) = g_r(t)/g_r(2025)$.
   The common strength (v7's form) is the v8 sensitivity pair.
6. **The institutions follow the gap-closure rule** (ADR 0063), central since design note 0008.

## Why the covered median (decision 4)

Countries without policy data cannot have a measured share of their ceiling, so one is assigned. Up to v7, a country
borrowed the share of its three most similar observed countries (similar in the model's own weighted drivers), or took a
low band below the observed range, or the median. Tested out of sample on v7, by treating each observed country in turn as
unobserved (design note 0009 §6.3; `analysis/v8/uncoveredRule.R`):

| predicting an observed country's share used, 2023 | mean absolute error, P&I | B&T |
|---|---:|---:|
| the donor and band rule | 0.151 | 0.087 |
| the covered median | **0.119** | **0.080** |
| a regression on the drivers | 0.126 | 0.082 |

Similar drivers do not predict a similar share used: the ceiling has already absorbed what the drivers say. The simpler
rule is also the better one, and it changes the ranking little (rank correlation 1.00 / 0.98 on v7). On v8 it is the main
reason the regions compress and less effort is held back than in v7 (below): regions dominated by uncovered countries (OAS,
MEA, LAM, SSA) no longer carry low-band countries. The tested alternative goes to the Supplementary Information (Note S-cov).

## Why the regional strength (decision 5)

With the rents slack (ADR 0061), an exporter's distance below its ceiling shrinks as its fossil income falls. Under the
common strength that shrinking lowers the world's average gap, which loosens every region's constraint, those without
fossil income included. That is not what the mechanism says. Under the regional strength the loosening stays with the region
whose rents fall. On the preview (below) the world total is nearly unchanged (B&T share held back 2100: 0.105 regional,
0.107 common), but the regions move. MEA's B&T share in 2100 is 0.92 against 0.86, while ECE, Japan and the EU's south and
west are held back more. The cost is that each region's path now rests on its own, noisier, gap rather than the world's.

## Why `satAP` and not v7's `satInn`

The sweep ranks v7's own form with the bound (`… satInn iw:fexp fos5`) 12th and the selected `satAP` form 18th. The
sanity walk rejects `satInn` on one severe flag only: its power & industry γ is 0.999004, above the declared gate of 0.999
(MODEL.md §3.4: at the boundary the slack is not distinguishable from noise). This was predicted before the sweep (design
note 0009 §7.1). The first six walked specifications are all rejected, and the seventh, `satAP`, passes with no severe flag
(power & industry γ 0.9989). Its fit is as good: mean ΔR²(theory) 0.1495 against 0.1470.

**Not done: relaxing the γ gate to keep `satInn`.** The threshold was declared before any v7 or v8 result, and a gate moved
to rescue a preferred form is the specification search the gates exist to prevent.

## What the evidence supports

| | v7 | v8 |
|---|---|---|
| P&I fossil dependence (frontier) | −0.555 (z −8.1) | −0.813 (z −10.4) |
| P&I fossil interests per person | +0.474 (9.5) | +0.491 (12.5) |
| B&T fossil dependence | −0.160 (−5.8) | −0.168 (−6.6) |
| B&T rents slack w | — | +0.277 (z 12.1) |
| H1, mean regression, wild bootstrap: P&I / B&T fossil dependence *p* | 0.008 / 0.015 | < 0.001 / < 0.001 |
| γ P&I / B&T | 0.9984 / 0.9725 | 0.9989 / 0.9178 (B&T at average rents) |
| theory gate: pool specifications passing | 84 of 5,930 | 80 of 5,786 |
| selection bootstrap: conditional win share / gate-pass share / median rank | 0.24 / 0.37 / 7 | 0.31 / 0.42 / 9 |

- **Structural power (H1) is stronger in both sectors**, under the asymptotic and the wild-bootstrap *p*.
- **The rents slack is strong and generalises:** w = 0.277, z 12.1. Out of sample on this specification
  (`analysis/v8/hetSlackCV.R v8`), it predicts better than the homoscedastic slack in 38 of 48 countries in buildings &
  transport (sign test *p* 0.0001). In power & industry it does not (27 of 48, *p* 0.47). ADR 0061's two conditions hold.
- **What it delivers in the coupling** (preview on v7's coupled hold-the-price energy system, EU21, θ 0.50, gap-closure
  institutions; `analysis/v8/v8CouplingPreview.R`). The final-energy-weighted share of the extra effort held back, 1 − φ, is
  smaller than v7's:

  | | 2050 P&I | 2050 B&T | 2100 P&I | 2100 B&T |
  |---|---:|---:|---:|---:|
  | v7 as published (storyline institutions) | 0.177 | 0.152 | 0.167 | 0.125 |
  | v7, gap-closure institutions | 0.154 | 0.162 | 0.142 | 0.137 |
  | v8, regional strength (central) | 0.121 | 0.135 | 0.138 | 0.105 |

  The v8 coupled penalty should therefore come out smaller than v7's, by about a fifth to a quarter in 2050. The regional
  strength barely moves the world total (common: 0.118 / 0.135 / 0.138 / 0.107), but it redistributes. MEA in B&T keeps more
  of its effort by 2100 (φ 0.92 against 0.86); ECE, Japan and the EU's south and west are held back more.
- **The share of the ceiling used**, 2023 (rank correlation with v7: P&I 0.97, B&T 0.84):
  - Saudi Arabia B&T 0.94 → 0.66 (the rents slack);
  - Russia P&I 0.46 → 0.33 (the saturating fossil terms);
  - Iceland P&I 0.33 → 0.39, Peru 0.35 → 0.41 (the bound).
- **The regional ranking:** REF stays the most constrained in both sectors (rank correlation with v7: 0.96 P&I, 0.95 B&T).
  The rest compress, mainly through the coverage rule (uncovered countries at the median, not in the low band). In P&I, OAS
  goes 0.78 → 0.49, MEA 0.68 → 0.43 and LAM 0.63 → 0.45. In B&T, NES goes 0.96 → 0.60 and ECS 0.85 → 0.60, and MEA holds at
  0.58.

## What it does not support, and is disclosed

- **The clean-energy main effect in power & industry is gone:** −0.031 (z −0.8; v7 +0.125, z 3.5). The clean-energy terms carry
  no requirement (ADR 0059) and were already reported as not identified. One consequence for the edge gate: its clean-energy
  direction check applies only where the sample-centre sign is the expected one, so in power & industry it does not apply.
- **The contingency (H2) in buildings & transport is weaker than in v7.** Under the wild bootstrap, the smallest fossil ×
  institution *p* is 0.024 (fossil dependence × accountability), above the Bonferroni level 0.05/6 = 0.008; v7 had 0.001. The
  gate tests H2 on the asymptotic clustered *p*, which it passes. Report the wild-bootstrap value with H2, and treat the B&T
  contingency as suggestive, not established.
- **The γ margin is narrow:** 0.9989 against 0.999 in power & industry. A small change of panel or form could push it over,
  as it did `satInn`. Read with MODEL.md §3.4's γ caveat, which this specification does not escape.
- **The saturating fossil terms change the low end** (Russia lower, Iceland higher). This is the property the saturation test
  of design note 0009 §2 described: the saturating form damps the high end, not the edge.

## A candidate, not adopted

On this specification, the three institutions shaping the **power & industry** slack now predict better out of sample (35 of
48, *p* 0.002; on v7's specification 29 of 48, *p* 0.19). It is not adopted: it was not part of the declared v8 design, and
ADR 0061 rejected institutions in the slack on v7's evidence. Recorded for v9 (design note 0009 §18).

## Consequences

- The v8 coupled batch runs on this specification (`scenario-matrix-v8.yml`; output/remind-inputs/v8, staged by job
  2764125).
- **The paper:**
  - The model section describes the actor-power terms as saturating (both), the fossil bound, the rents slack, and the
    coverage rule.
  - The disclosures above go to the Methods.
  - The comparison with v7 (form, ranking, extremes) goes to the Supplementary Information.
- **Not identified, still:** θ, κ, the causal energy-to-politics effect, and the clean-energy terms (now including their sign
  in power & industry).

## Alternatives rejected

- **v7's `satInn` form with the bound:** fails the declared γ gate.
- **Relaxing the γ gate:** see above.
- **v8 without the fossil bound:** the bound improves the fit in both sectors and removes part of the Iceland artefact (design
  note 0009 §7.1). Without it, v7's specification is re-selected and none of v8's fixes at the low edge apply.
- **The donor and band rule for countries without data:** worse out of sample than the median (decision 4). A regression of
  the share used on the drivers was no better and moved Sub-Saharan Africa from 0.48 to 0.98 in the ranking.
- **The common strength as central:** it spreads an exporter's fading constraint to every region (decision 5). It is kept
  as the sensitivity pair.
