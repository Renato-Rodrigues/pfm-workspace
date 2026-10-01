# 40. Saturating actor power, the physical-domain guard, and the support-share gate

Date: 2026-08-10

## Status

Accepted. Implemented in `pfm` (2026-08-10); pending the Phase-0.5 re-sweep.

Supersedes nothing; extends ADR 0036 (PSM), ADR 0039 (Tournament v2) and the
driver-support guard introduced 2026-07-06 (R3).

## Context

The 0.1/0.2 diagnosis (`docs/psm-ceiling-feedback-diagnosis.md`) established that
two symptoms of the deployed model share one cause, and that the cause is
functional form rather than politics:

1. The ambitious pathway *lowered* the political ceiling for 65–83% of countries.
2. Projected Bulk stringency *declined* over the century (median 6.96 → 3.75),
   despite the index being an accumulating policy stock.

Mechanism, measured:

- The actor-power drivers are energy-system shares. Bulk innovator power spans
  **0.029–0.433** in training (95th percentile 0.225; only 1.4% of rows above
  0.30) and REMIND takes it to **0.58–0.68**.
- The model is **linear** in that share, so its slopes — including the negative
  `Innovator × GovEff` interaction (−0.232) — are extrapolated ~3× beyond the
  range that identifies them.
- The extrapolation guard then clamps innovator power at the empirical maximum.
  By 2050 **78–100%** of countries are above it in *both* scenarios, so both
  clamp to the same value and the guarded scenario delta is **exactly 0.000**.
  The whole scenario signal is left to travel through incumbent power, whose
  interaction with state capability is **positively** signed for 70% of
  countries — hence "less fossil ⇒ lower ceiling".
- The trend freeze is *not* implicated: the trend regressor is constant (0.345)
  in every projection year and contributes exactly zero.

The user accepted a re-sweep to fix this properly rather than caveat around it.

## Decision

### 1. Saturating actor-power transform (swept, not asserted)

Actor-power drivers may enter through a diminishing-returns map applied **before**
standardization:

```
xTilde = x / (x + xBar),     xBar = training MEDIAN of x
```

- **No estimated parameters.** The model stays a linear GLM in `xTilde`, so
  AIC/BIC/McFadden, the maximin machinery, the frontier, the ECM, the wild
  bootstrap and the AMEs all work unchanged.
- **Frozen like every other application transform.** `xBar` is stored *inside* the
  `driverScaling` entry as the `sat` element, so every existing apply-mode caller
  (which already passes `driverScaling = fit$driverScaling`) reproduces it with no
  signature change.
- **Applied only to strictly-positive actor-power columns.** The composite Actor
  Power Index is a difference (innovator − incumbent, ~[−0.8, 0.1]); "diminishing
  returns in a share" is undefined for it, so it is skipped with a warning and
  `sat = NA`.
- **Swept as an axis**, not imposed: `psmSpecs()` appends `" satAP"` twins for
  split-AP specs only. Linear originals keep their X-numbers.

Substantive reading for the paper: *political power saturates in economic weight —
the first tenth of renewable capacity creates a constituency where none existed;
the eighth tenth adds little that is politically new.*

### 2. The guard follows the transform: physical domain, not empirical range

For saturating columns the driver-support guard winsorizes at the **physical**
limits of the underlying share (`x ∈ [0,1] ⇒ xTilde ∈ [0, 1/(1+xBar)]`) rather
than at the empirical sample range.

Rationale: the guard is load-bearing under the *linear* form because the marginal
effect is constant, so a 4-SD extrapolation moves the linear predictor by 4 SD
worth of slope. Under `x/(x+xBar)` the marginal effect decays as `1/(x+xBar)²` —
measured, the projections sit **0.33–0.48 SD (Bulk) / 0.77–1.66 SD (Diffuse)**
past the training max and **100% inside the physical domain**. Clamping them at
the empirical max would winsorize both scenarios to the same edge and re-create
the exact artifact the transform exists to remove.

**The out-of-sample audit is not weakened.** `.psmDriverGuard()` now returns
`outOfSample` alongside `outOfSupport`: the former always measures distance from
the *empirical* training range, the latter what was actually clamped. Both are
carried on projections (`driverOutOfSupport`, `driverOutOfSample`).

### 3. Support-share severe gate

New severe rule `extrapolationDominated`: reject a spec whose mean
`driverOutOfSupport` over in-coverage rows within the responsiveness window
exceeds `supportShareGate` (default **0.25**). A spec whose projection in the
evaluation window is mostly winsorized is scoring the guard, not the model.

Calibrated, not guessed — measured on the deployed spec over 2040–2060:

| Form | responsiveness delta | mean `driverOutOfSupport` | gate outcome |
|---|---:|---:|---|
| linear | 0.460 | **0.318** | **rejected** (> 0.25) |
| saturating | **0.779** | **0.048** | passes |

The saturating form is *both* better supported and **more** scenario-responsive.

### 4. The gate window stays at 2040–2060

Tested and rejected: moving the evaluation window to 2025–2040 (the in-support
window under the linear form) makes the responsiveness delta **0.0004 / 0.0001**,
i.e. below `minScenarioDelta` — every spec would fail and selection would
collapse. The two REMIND pathways barely diverge before ~2040, so there is no
window where the *linear* form is both in-support and scenario-differentiated.
That tension is itself the argument for the transform: under saturation, support
holds through 2060 and beyond, so the existing window works.

### 5. Ratchet monotonicity is reported, not enforced

A policy-stringency index is an accumulating stock. A `nonMonotone` **warning**
(not a gate) fires when >5% of projected year-on-year steps decrease. Enforcing
`S(t+1) ≥ S(t)` would *mask* the decline; decision 1 is the fix, and this
diagnostic is how we tell whether it worked.

## Consequences

- The linear form is likely to be gated out at long horizons, so the deployment
  will probably be a **saturating split-AP** spec. That is a consequence of the
  evidence, not a preference: only such specs are simultaneously in-support and
  scenario-responsive.
- **Selection re-opens a fifth time.** After the Phase-0.5 re-sweep it is frozen:
  no further re-selection before submission.
- Cost is bounded: linear specs hit the existing fit cache (the transform changes
  the data hash *and* the cache key only for twins), so only the ~744 split-AP
  twins × 2 sectors are new fits.
- Every number in `PSM_EQUATIONS.md` must be refreshed from the new Run-Group.

## What this does NOT fix (stated so it is not rediscovered)

**The exposure confound.** `Incumbent × GovEff > 0` is most plausibly a *need /
exposure* effect rather than a *power* effect: CAPMF counts instruments, and a
capable state with a large fossil sector has more to regulate. Saturation bounds
the damage but does not separate the two channels. The principled fix needs
fossil rents / employment / reserves as pre-determined exposure — **no such
reader exists in `mrpfm`** (checked 2026-08-10), so it is a data-acquisition
project (item 5.3), not a sweep option. It stays a stated limitation, and it also
explains why the shift-share IV returns a null: the instrument targets
incumbency-as-power while the coefficient is partly incumbency-as-exposure.

**A strong feedback.** The scenarios differ from history precisely where there is
no data, so no transform can create information there. Expect a bounded, honest,
modest feedback — a usable coupling, not a bigger effect.

## Alternatives considered

- **S-curve `plogis((x−m)/s)`.** The obvious "saturating" choice. **Rejected on
  measurement**: it compresses every country to 1.000 by 2050, giving a scenario
  delta of 0.0000/0.0010 — it re-creates the scenario-blindness the
  responsiveness gate exists to catch.
- **Re-standardizing or re-scaling the drivers.** Rejected: standardization is
  affine, so the clamp lands in exactly the same place. This was the author's
  first instinct and it is wrong.
- **Enforcing monotonicity instead.** Rejected as the primary fix: it masks the
  symptom without touching the cause. Retained as a diagnostic (decision 5).
- **Capping the horizon at ~2040 and coupling one-way.** This was the
  pre-re-sweep recommendation and remains the fallback if the re-sweep does not
  clear the gates.
- **Dropping the AP × IQ interactions.** Rejected: they are the paper's mechanism
  finding, and dropping terms because their extrapolation is inconvenient is
  selection on results.
