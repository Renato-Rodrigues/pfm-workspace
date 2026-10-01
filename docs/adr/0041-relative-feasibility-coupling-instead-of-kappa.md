# 41. Relative feasibility coupling: a tiered share of the cost-optimal price, not an index→price exchange rate

Date: 2026-08-10

## Status

Accepted (design). Supersedes the κ-based coupling in ADR 0024 / the v1–v2 maths
explainers / `PSM_EQUATIONS.md` §5 as the **primary** mechanism. κ survives only as
an *ex-post reporting* device (see Consequences).

## Context

Every prior coupling design routed through an exchange rate

```
κ_s = ∂P/∂S      [$/tCO₂ per index point]
```

estimated by regressing observed effective carbon prices on CAPMF stringency, and
then used as `P(t+1) ≤ P(t) + κ·λ·[S* − S]`. It was never estimated, and it has
been the single blocking item on the coupling for months. On inspection it should
not be estimated, for four reasons:

1. **It re-creates the pathology we just removed.** A *bounded* index (0–10) times a
   constant gives a *bounded* price ceiling. At any plausible κ the implied cap
   (index 8 × ~$30 ≈ $240/tCO₂) is far below what a 1.5 °C pathway needs, so the
   constraint would make ambitious scenarios infeasible for an arithmetic reason,
   not a political one. This is the same bounded-driver → unbounded-target
   extrapolation error that ADR 0040 just eliminated on the driver side.
2. **The identification range is wrong.** Historical effective carbon prices top out
   around $130/tCO₂; the pathways need $10²–10³. κ would be estimated on one range
   and applied on another — the exact failure mode diagnosed in
   `psm-ceiling-feedback-diagnosis.md`.
3. **The outcome is not a price.** CAPMF is ~90% non-price instruments. A
   $/index-point conversion asks a portfolio-count index to denominate a tax.
4. **It leans on the frontier's weakest part.** κ·S* uses the *level* of the
   frontier — precisely what the γ-at-boundary caveat (γ = 0.996/0.982) says is
   least trustworthy. The frontier's *relative/rank* information is what survived
   the robustness battery (rank ρ 0.73–0.84).

Meanwhile REMIND's carbon price is not a literal tax either: it is the model's
composite mitigation-effort signal, standing in for policies the model does not
represent explicitly.

## Decision

**Couple in relative, dimensionless terms: politics determines what *share* of the
cost-optimal mitigation effort a region can realize, tiered by its ambition gap.
No index→price conversion anywhere.**

### 1. The feasibility share

Let `P°(r,t)` be REMIND's **unconstrained cost-optimal** carbon price (the reference
run with no political constraint) and `P^ref(r,t)` the **current-policy** price path
(NPi). Define a per-region feasibility share `φ(r,t) ∈ (0,1]` and set the political
target

```
P*(r,t) = P^ref(r,t) + φ(r,t) · [ P°(r,t) − P^ref(r,t) ]
```

> **The constraint applies to the *incremental* mitigation effort**, not to the
> whole price. A region already at its current-policy price is, by construction,
> doing what its politics presently supports; what politics governs is how much
> *more* it can be pushed. This also makes the current-policy scenario reproduce
> itself exactly (φ drops out when `P° = P^ref`), giving a clean scenario pair.

### 2. φ comes from ambition-gap **tiers**, not from point gaps

Consistent with the standing doctrine (*tiers, never point ceilings*):

```
φ(r) = 1 − θ · (k_r − 1)/(K − 1)        k_r = tier 1..K, 1 = nearest the frontier
```

With `K = 4`: tier 1 → `φ = 1`; tier 4 → `φ = 1 − θ`.

- Tiers are assigned from the **2022** gap and **held fixed** through the run (the
  frozen-ceiling decision from the diagnosis memo). Tier migration is a sensitivity,
  not a default.
- **Out-of-coverage regions get `φ = 1`** — uncoupled. Consistent with "speeds only,
  never invented ceilings" for the 203 of 249 countries outside the sample.
- φ is a **parameter**, refreshed between Gauss–Seidel iterations, never a variable.
  So the tier discontinuity raises no solver-differentiability problem (the concern
  raised in `adoption-vs-frontier-analysis.md` about binary gates does not apply).

### 3. The speed limit is unchanged and does the dynamic work

The validated λ still governs how fast the price may approach that target — the same
gap dynamics as the stringency model, now in price space:

```
P(r,t) = P(r,t−1) + λ_s · [ P*(r,t) − P(r,t−1) ]
```

**κ has vanished.** The two estimated quantities that enter are exactly the two the
model supports: the **relative gap** (frontier ranks/tiers — robust) and **λ** (the
out-of-sample-validated adjustment speed). Nothing is converted into dollars.

### 4. θ is a declared scenario parameter, swept — not an estimate

There is no historical experiment assigning carbon prices by political gap, so θ is
not identified. It is declared, swept, and reported as a family:

| θ | reading |
|---:|---|
| **0** | uncoupled null — reproduces the standard REMIND run exactly (the reference) |
| 0.25 | mild — the largest-gap tier realizes 75% of the incremental effort |
| 0.50 | central-low |
| **0.79** | **efficiency-anchored** (see below) |

**The efficiency anchor.** The median in-coverage polity operates at 62% (Bulk) /
69% (Diffuse) of its own political ceiling, with a median gap 0.48 of the maximum
gap. Setting `1 − θ·0.48 = 0.624` gives **θ ≈ 0.79**: the value at which the median
region's price discount equals its *observed* efficiency ratio. This is a
transparent **anchor by analogy, not an estimate** — the index-space efficiency
ratio and the price-space effort share are different objects — and must be labelled
as such wherever it is quoted.

> ⚠️ **Superseded on this point (2026-08-17) — see `MODEL.md` §5.3.** The derivation above
> used the pre-`satAP` frontier (median Bulk E = 0.624, u ≈ 0.48) *and* anchored on Bulk. Two
> things changed. The frontier was regenerated on the deployed spec, and **ADR 0042** made the
> economy-wide price the **worse** sector's — whichever that is per region — so Bulk no
> longer sets the headline price. Re-derived on the regenerated artifact: **Diffuse gives
> θ ≈ 0.74**; Bulk gives θ = 1.19, **outside the admissible [0,1)**. The rest of this ADR —
> the relative-gap coupling, the retirement of κ, θ as declared-and-swept — stands unchanged.
> Runs already made at θ = 0.79 remain valid as a swept point; only the "efficiency-anchored"
> label is withdrawn.

### 5. The residual empirical task (replaces κ estimation)

Not a $/index-point regression, but a **dimensionless elasticity** — estimable, and
informative about θ:

```
log(1 + P_{r,t}) = α_r + τ_t + β · E_{r,t} + ε      E = efficiency ratio = S/S*
```

β is unit-free; the implied best-to-worst price ratio `exp(β·ΔE)` maps directly onto
the θ range. If β is weak or unstable, we say so and present the θ sweep as a pure
sensitivity — which is what it is anyway. **This is a bounded, low-risk task that
cannot block the coupling**, unlike κ, which could.

## Consequences

- **The coupling is unblocked.** The item that has blocked it for months is removed
  rather than solved, and the substitute is better founded.
- **The headline changes in kind.** We can no longer say "policy speed implies a
  $X/yr price-growth bound". We say: *politically constrained regions realize a
  smaller, tiered share of the cost-optimal mitigation effort, phased in at the
  politically exhibited speed.* Weaker in physical units, stronger in defensibility.
- **κ becomes a diagnostic, not an input.** After a coupled run one can read the
  realized $/tCO₂ difference straight off REMIND's own output ("tier-4 regions ran
  $X below cost-optimal"). That is a *result*, not an assumption.
- **θ = 0 is a free, exact null**, which makes the coupled-vs-uncoupled comparison
  clean and gives the paper an honest reference case.
- Scenario runs multiply by |θ|; with 4 values and the 3-member stochastic ensemble
  (ADR 0040 / TODO 2.2) budget the run count deliberately — the ensemble and the θ
  sweep should not be crossed naively (run the ensemble at the anchored θ only).
- The `Implementability Factor` term in CONTEXT.md should be re-pointed at φ; the
  `index/10` form remains rejected.

## Alternatives considered

- **Estimate κ as planned.** Rejected: four independent reasons above, the decisive
  one being that a bounded index × constant is a bounded price cap that would make
  ambitious pathways infeasible arithmetically.
- **φ = the efficiency ratio E directly.** Rejected: it applies a ~35% discount to
  *every* region including the frontier leaders, penalising good performers. The
  relative/tiered form gives φ = 1 at the frontier, which is the correct behaviour.
- **Continuous φ in the normalized gap `G/G_max`.** Rejected as the default: it is
  hostage to the single worst region and uses the point gap, contradicting the
  tiers-only doctrine. Retained as a sensitivity.
- **Apply φ to the whole price rather than the increment.** Rejected: it discounts
  policy that is already in place, double-counting against the NPi calibration, and
  it destroys the clean current-policy reference.
