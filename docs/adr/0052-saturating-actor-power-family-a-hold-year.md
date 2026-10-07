# ADR 0052 — Saturating actor power: family A in the main text, family B in the SI; the curve's shape; no hold year

- **Status:** Proposed (draft, 2026-10-07); ready to accept — the decisions are the author's (0005 D6,
  2026-10-01; D7, 2026-10-02; §7a decisions 6 and 8, 2026-10-07) and the Phase 2 gate is passed.
- **Extends:** [ADR 0040](0040-saturating-actor-power-and-support-gate.md) (the `satAP` transform and the support gate),
  [ADR 0045](0045-extrapolation-gate-at-0275-and-declared-theta-sweep.md) (the 0.275 tolerance).
  **Keeps** [ADR 0043](0043-ceiling-collapse-selection-gate.md) (flagged for review).
- **Changes:** `MODEL.md` §7's "no scenario differences past ~2060" becomes a reporting duty.
- **Run-Groups:** `v6` and later.
- **Evidence:** `analysis/v6/{specBand,satShape,ceilingGate}.R` → `output/pfm/v6/phase1/{spec-band,spec-band-ceilingRejected,sat-shape,ceiling-gate}.rds`;
  `output/pfm/v6/{sweep,sanity-pool,selection-bootstrap}.rds`; test `test-apSatScale.R`.

## Decision

1. **The actor-power form is selected, under an extrapolation gate** (D7). Every split spec is fitted
   linear, both-saturating (`satAP`), innovator-only (`satInn`) and incumbent-only (`satInc`); the
   composite Actor Power Index is dropped. A severe gate rejects specs whose actor-power drivers lie
   more than 1 training SD beyond support in more than 27.5% of in-coverage country-years, 2025–2100.
   The other clamps stay.
2. **Family A in the main text, family B in the SI** (decision 6). The deployed `X-1791 … satAP`
   saturates innovators *and* incumbents (family A). Family B (`satInn`) is reported through its most
   frequent bootstrap winner, `X-2079 … satInn` (Run-Group `v6-specalt`).
3. **The curve's shape is a main-text robustness check.** The half-saturation point is set to 0.5×,
   1× and 2× the training median (`apSatScale`; Run-Groups `v6-sat05`, `v6-sat2`).
4. **No hold year in the central case** (D6): $k$ follows the ceilings to 2100; holding at 2060 is the
   sensitivity. The out-of-support share is reported per year with every $k(t)$ and φ(t).
5. **The ceiling-fall gate stays** at 0.90 for `v6`, and is flagged for revision (decision 8).

## Context

- **The sanity-passing specs split on the transform.** All 9 on the `v6` panel, Bulk $k_{2050}$ on
  PkBudg1000: family A (49% of the bootstrap's conditional wins) 0.63 (deployed), 0.72, 0.90; family
  B (51%) 0.86–1.22. The annual rung `v6-annual` selected `X-1860 satInn`, which gives 1.22 on the
  `v6` panel too: the rung's opposite result is the spec, not the panel.
- **The families differ only below the observed range.** In PkBudg1000 2050, 56% of countries sit below
  the training 5th percentile of the Bulk incumbent share (20% below its minimum), and 59% above the
  innovator maximum. Family A's curve $x/(x+\bar x)$ is steepest at zero, so incumbent power collapses
  fast as incumbents vanish; family B keeps incumbents linear.
- **Why family A:** the joint fit of the shared spec (the best family-A specs beat the best family-B
  ones by about 50 BIC, from Diffuse; in Bulk alone family B is 14 better); symmetric treatment of the
  two actor groups; and ADR 0040's own rationale, that no share should extrapolate linearly into a
  range no country has occupied. Disclosed: the bootstrap splits about 49 / 51.
- **The shape check:** all three shapes pass the sanity walk; ranking Spearman ≥ 0.97 with 1×.

  | half-saturation | Bulk $k$ on PkBudg1000, 2050 / 2100 | ΔBIC vs 1×, Bulk / Diffuse |
  |---|---|---|
  | 0.5× median | 0.57 / 0.40 | +16 / −14 |
  | 1× (deployed) | 0.63 / 0.48 | 0 / 0 |
  | 2× | 0.75 / 0.63 | −14 / +19 |

- **The ceiling gate decides the sign of Bulk $k$ for the specs it alone rejects.** Those four are all
  family A (three `splitAPpc`, and `X-1860 satAP`). Their Bulk ceilings fall to 0.64–0.72, and their Bulk
  $k_{2050}$ on PkBudg1000 is 1.31–1.54. The deployed spec passes by a wide margin (1.21 / 1.27
  against 0.90; `v5` passed by 0.003).
- **The Bulk institution terms are not identified** (satP wild-cluster p 0.6–0.9, signs differing
  between satP and the frontier). Part of the deployed spec's Bulk fall rests on them.
- **Out of support**, `v6` EU21: 2.3% of the weighted drivers in 2025, 6% in 2050, 11% in 2100.

## Consequences

- The paper says in one sentence that the size of the Bulk loosening rests on how incumbent power
  behaves below anything observed, and reports family B and the gate-rejected family-A specs in the SI.
- Quote the Bulk result as a band (the shape range 0.57–0.75 in 2050), not as the deployed value
  alone.
- `apSatScale` enters the fit and bootstrap cache keys only when it is not 1, so every existing cache
  entry stays valid. It is forwarded by every hand-listed fit call (tested).
- Revisit ADR 0043 when the future projections are revised (the PoliClim-informed institution paths,
  ADR 0051): a new projection can move specs across the gate.
- `MODEL.md` §7 is revised at the v6 documentation pass (0005 G3).

## Alternatives rejected

- Declare the innovator-only form (the earlier recommendation), or saturate both groups by
  declaration (D7).
- Keep the composite Actor Power Index.
- Present the deployed spec alone, or put family B in the main text.
- Hold $k$ from 2060 in the central case (D6).
