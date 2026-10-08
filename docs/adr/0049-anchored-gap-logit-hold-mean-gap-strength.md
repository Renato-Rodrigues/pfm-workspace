# ADR 0049 — The v6 coupling: an anchored gap, held on the logit scale, with a mean-gap strength

- **Status:** **Accepted 2026-10-08** (author), at the Phase 3 gate of design note 0005 (passed
  2026-10-08, batch `EU21V371`; 0005 Phase 3, "Gate result"). Drafted 2026-10-07. The decisions it
  records are 0005 D1, D2, D4, D11 (headline part), D12, and §7a decision 3 (donor rule).
- **Refines:** [ADR 0041](0041-relative-feasibility-coupling-instead-of-kappa.md) (relative feasibility coupling): the
  share becomes a path $\varphi_{r,s}(t)$ instead of a value fixed at a tier year. ADR 0042's delivery
  (the floor over sectors, ETS ← Bulk, ES and other ← Diffuse) is unchanged.
- **Run-Groups:** `v6` and later. `v5` keeps its formulation (a reproduction switch, 0005 Phase 3).
- **Evidence:** `analysis/v6/phase1.R` → `output/pfm/v6/phase1/{anchors,strength,variants,decomposition,seam}.rds`;
  `analysis/v6/offlineHeadline.R` → `offline-headline.rds`; `pfm::computeAnchorGap`,
  `computeStrengthPath`, `computeSharePath`, `runPFMAnchor` and their tests.

## Decision

1. **Anchor.** Each country's distance below its frontier ceiling is read once, at the last panel
   year $t_a$ (2023 for `v6`), on the logit scale: $q_{c,s} = \eta_{c,s,t_a} - y_{c,s,t_a}$. Uncovered
   countries take $y$ from the band rule ($E_c$ from donors, the low band or the median; the USA on
   the median).
2. **Logit hold.** $q$ is held: $S_{c,s}(t) = S_{\max}\,\mathrm{logit}^{-1}(\eta_{c,s}(t) - q_{c,s})$.
   The ceiling $\eta(t)$ moves with the scenario's drivers; the distance does not.
3. **Ranking.** Regional gaps at $t_a$ (final-energy weights, Step 2 aggregation) give
   $u_{r,s} = \mathrm{minmax}_r(g_{r,s})$. It is computed once per Run-Group and staged as the anchor
   artifact `phi-anchor.rds` (step `pfm-anchor`).
4. **Strength.** $G_s(t) = \sum_r w_r g_{r,s}(t)$, $k_s(t) = G_s(t)/G_s(t_0)$, $t_0 = 2025$, so
   $k(t_0) = 1$ in every scenario.
5. **Share.** $\varphi_{r,s}(t) = \mathrm{clip}_{[0,1]}(1 - \theta\,k_s(t)\,u_{r,s})$ (the headline spread
   $d = k$). θ means *severity at 2025*; a clip at 0 is flagged as a run defect, and $k_s > 1/\theta$
   is logged.
6. **Donor rule** for the uncovered countries: unchanged (9 base drivers weighted by $|\beta|$; close ≤
   q50, far ≤ q90 of the covered nearest-neighbour distances), with a "nearest donors always" arm in
   the batch.

## Context

- The `v5` share was read at a tier year (2035) after projecting covered countries with the ECM speed
  λ, while uncovered countries held their ratio $E$ inside the same regional aggregate. λ is not
  identified (its placebo null covers it, 0005 D1). The 2035 reading and the 2022 reading agreed at
  a Spearman of only 0.30 (GP-20).
- **The logit hold is the mechanism, not a detail (D2).** Holding $E$ instead makes $k \approx 1$
  (0004 §3, E3b), so the formulation collapses to a static share. Holding the shortfall where the
  frontier defines it lets a gap shrink as a ceiling rises towards saturation and widen as it
  falls. Every movement of $k$ comes from this choice.
- **Acceptance** (0005 Phase 1 step 3): the code reproduces the methodology's prototype on `v5`'s
  pre-fix panel, Bulk 1.076 / 1.180 / 1.206 (2035 / 2050 / 2070) against 1.08 / 1.18 / 1.21.
- **On `v6`** (EU21, lag in years, institution series harmonised): Bulk $k$ on PkBudg1000 is 0.63 in
  2050 and 0.48 in 2100, on NPi 1.09 and 0.92; Diffuse PkBudg1000 0.91 and 0.73. H12 is within 0.003.
- **The artifact** is 28 KB; $k(t)$ computed from it alone equals the Phase 1 values exactly at both
  resolutions.
- **Donors** (decision 3): no alternative matching rule moves $k$ by more than 0.006. What they move
  is the ranking of LAM and SSA, which the nearest-donors arm reports.

## Consequences

- A region's own transition can no longer change its rank; only the common strength moves.
  Region-specific strength is one SI arm (D16).
- Methods states that the strength factor exists because the shortfall is held on the logit scale.
  The $E$-hold run is reported as the static-share bound (C5; on `v6` it moves the Bulk share by a
  median 0.10 in 2050).
- The anchor artifact is what the in-REMIND call reads (Phase 3). `runPFMExportREMINDInputs` ships it,
  `preparePFM.R` copies it, and `pfmPreflight` fails an export whose manifest records a completed
  `pfm-anchor` step without the file.
- The anchor seam is tested (C8): after the institution harmonisation and the lag fix (ADR 0051),
  band-rule countries' η at 2023 agree with history to a 95th percentile of 0.93 index points
  (Bulk) and 0.45 (Diffuse).

## Alternatives rejected

- Keep the `v5` 2035 reading, or add tier years under the λ projection (D1).
- Hold the efficiency ratio $E$, or the index-point gap (D2).
- Normalise $k$ at 2022 (D4).
- A model-derived spread $d = D_s(t)/D_s(t_0)$ in the headline (D11): reported as a diagnostic only.
- Let φ float below $1 - \theta$ unbounded (D12).
