# ADR 0054 — A time-indexed φ interface, and convergence on the φ path

- **Status:** **Accepted 2026-10-08** (author), at the Phase 3 gate (passed 2026-10-08, batch
  `EU21V371`: rule B converged in 7 calls, rule C in 8 with the rebuild check at 9.1e-7).
  Implemented 2026-10-07 on both sides and verified offline (`COUPLING.md` §14). Records 0005 D5
  and D14. As built: `cm_pfmPhiPath` is the switch; the path covers every `ttot` of the REMIND gdx;
  the oscillation test is the cosine of two successive moves (below −0.5).
- **Run-Groups:** `v6` and later. `v5` runs with the existing symbols (the reproduction switch).

## Decision

1. **A `formulation` switch in `iterativePFM()`**: `"v6-anchor"` (default for `v6` groups, read from the
   group's manifest) or `"v5-tier"`. The v6 path reads the anchor artifact (ADR 0049), builds the
   scenario panel, computes η per country, then $S$, $g_{r,s}(t)$, $k_s(t)$ and φ(t). No ECM, no λ.
2. **New GDX symbols, old ones kept** (D14): `p45_pfmPhiPath(ttot, all_regi)` and
   `p45_pfmPhiMktPath(ttot, all_regi, all_emiMkt)`, `ttot` first, behind `cm_pfmPhiPath` (default 0).
   The old symbols carry the $t_0$ value. Rule B needs nothing new (`p45_pfmPriceBound` is already
   year-indexed). Rule C's rebuild and mode R read the path, mirrored in `postsolve.gms` Step IV.4.
3. **Converge on the φ path** (D5): the largest change over regions, markets and checkpoint years
   (2035, 2050, 2070, 2100; 2035, 2050, 2060 under the hold-2060 sensitivity), at the existing
   tolerance 0.002. The all-period δ is logged. Damping (α = 0.5) only on oscillation, recorded.
4. The history file stores φ(t), $k_s(t)$, δ, the all-period δ and α per call.
5. The SSP comes from the runtime configuration and is asserted equal to the weights' and the anchor
   artifact's (ADR 0051).

## Context

- With $d = k$ and $\max u = 1$, $\max_r|\Delta\varphi_r| = \theta\,|\Delta k|$ exactly, so checking φ is
  the methodology's rule, without dividing by θ (undefined for the θ = 0 nulls).
- `v5` checked only the economy-wide floor; market shares are covered since 2026-10-02 (E8). The path
  adds the time dimension.
- Re-ranking an existing symbol is how a silent all-zero load happened before (`COUPLING.md` §7), hence
  new symbols.

## Consequences

- New pitfalls to document with the code: a φ path loaded with the wrong year labels loads as zeros;
  a rule-C run with `cm_pfmPhiPath = 0` on a `v6` group rebuilds from the $t_0$ value; an SSP mismatch
  between the row and the export.
- Gate (Phase 3): the θ = 0 null on the v6 fork reproduces `-PFMgateRef` on the same REMIND version
  (3.7.1) within tolerance (the `v5` null ran on an older REMIND, `PITFALLS.md` §34); one EU21 rule-B run
  converges with the path and $k$ logged; one rule-C run shows a rebuild error near 1e-6.

## Alternatives rejected

- Converge on $k$ with tolerance tol/θ (D5).
- Re-rank the existing symbols (D14).
