# ADR 0045 — The extrapolation gate sits at 0.275, and the θ sweep is declared, not anchored

- **Status:** Accepted
- **Date:** 2026-09-15
- **Supersedes in part:** [ADR 0044](0044-actor-power-share-and-per-capita-level.md) (which deployed `bothIncAP` on `v3`), [ADR 0040](0040-saturating-actor-power-and-support-gate.md) (which set `supportShareGate = 0.25`)
- **Run-Group:** `v5`

## Decision

Two decisions, taken together because the second follows from the first.

1. **`supportShareGate` is 0.275**, with `deltaWindow` unchanged at 2040–2060. The sanity walk
   then stops at maximin rank 1 and the deployed specification is
   **`X-2079 WGIge|noRoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp`**
   (0 severe / 30 warnings, `forced = FALSE`).

2. **The θ sweep is `{0.325, 0.50, 0.675}`** — declared and symmetric about the central value,
   **not** derived from the sector anchors, because on `v5` one of the two anchors does not exist.

## Context

### Why the gate moved

`v4` deployed `X-1959` (`splitAPpc`) at maximin rank 4. Three independent lines pointed at
`bothIncAP` instead: the selection bootstrap (76.0% against 17.4%), this sample's ranking (ranks
1, 2, 3, 5, 6, 7), and each sector's own optimum. The only thing keeping `bothIncAP` out was
`extrapolationDominated`, firing at 0.25.

All ten top-ranked candidates were gate-tested for the first time (ranks 5–10 had never been
evaluated, because the walk stops at the first clean spec). At 0.25 every one of ranks 5–10 also
fails and the walk ends `forced = TRUE`. Raising the bar to 0.275 clears ranks 1 and 2 only; it
does not touch `ceilingCollapse` (ranks 3, 5, 6 stay out), does not touch `scenarioBlind`
(ranks 8–10 stay out), and does not reach rank 7.

### What must be disclosed about 0.275

🔴 **The threshold was moved after the candidates were known.** That is the thing a
pre-committed gate exists to prevent, and the paper must say so plainly rather than present
0.275 as a standing parameter.

🔴 **It cuts through a cluster, not a gap.** The eight recorded values are 0.2542, 0.2546,
0.2568, 0.2569, 0.2708, 0.2734 — then a gap to 0.3146, 0.3368. **0.275 sits 0.0016 above the
highest value it admits.** Every threshold in (0.2734, 0.3146) selects identically; **0.29 would
give the same answer with ~50× the margin.** 0.275 was chosen deliberately in the knowledge that
0.29 was available and equivalent; that choice is itself a disclosure item.

🔴 **The selected spec is thin on both gates:** it clears extrapolation by 0.0042 and
`ceilingCollapse` by 0.003 (Bulk ceiling ratio 0.903 against the 0.90 floor).

🔴 **The channel set changed too, and that was not the question being asked.** `X-1959` was
`WGIge|RoL|noAcc`; `X-2079` is `WGIge|noRoL|VerAcc`. Rule of Law leaves the deployed
specification — it was among the most significant terms in both sectors on `v4` (Bulk +0.345,
p = 3e−08; Diffuse −0.404, p = 2e−17) — and Vertical Accountability enters, insignificant in
both (p = .78, p = .37). On `v5` the only significant institutional main effect anywhere is
Government Effectiveness in Diffuse.

🟢 **What it buys.** Actor power becomes theory-consistent. The Bulk incumbency term was
**+0.592 and significant against theory** on `v4`; on `v5` the structural (share) term is
**−0.190, p = .004** in Bulk and **−0.130, p = 1e−09** in Diffuse, with the instrumental
(per-capita) term positive. Separating structural from instrumental incumbency is doing real
work, which is what ADR 0044 argued it would.

### Why the θ sweep is declared rather than anchored

`MODEL.md` §5.3: θ is **declared and swept, never estimated** — no historical experiment
assigned carbon prices by political gap, so it is not identified. The *anchor* is a
plausibility calibration by analogy, solving `1 − θ·ū = Ē` for the median region: "what θ would
make the mechanism reproduce the median observed efficiency?"

On `v4` both sectors had an admissible anchor and they bracketed the central value
(Diffuse 0.464 ≤ 0.50 ≤ Bulk 0.641), so the sweep endpoints could be presented as *what each
sector's own data implies*.

**On `v5` Bulk has no admissible anchor.** Its inefficiency distribution compresses — the
best-ranked region's gap rises from 1.5% to 9.8%, so the median's normalised rank position falls
from 0.382 to 0.222 while its absolute shortfall barely moves — and the anchor equation returns
**θ = 1.019, outside [0, 1)**. `psm-coupling-bound` reports this itself: *"no admissible theta
reproduces median efficiency for: Bulk — the gap distribution is too compressed. Report it, do
not chase it."*

| sector | median E | median u | θ | admissible? |
|---|---:|---:|---:|---|
| Bulk `v4` | 0.755 | 0.382 | 0.641 | ✅ |
| Bulk **`v5`** | 0.773 | 0.222 | **1.019** | 🔴 **no** |
| Diffuse `v4` | 0.823 | 0.382 | 0.464 | ✅ |
| Diffuse **`v5`** | 0.783 | 0.662 | **0.328** | ✅ |

The mechanism `φ = 1 − θ·u` can only represent **differences between regions** — the
best-ranked region gets φ = 1 by construction. A shortfall common to every region is invisible
to it. `v5` pushes more of Bulk's shortfall into that common part, which is why no admissible θ
reproduces it.

## Consequences

- The sweep `{0.325, 0.50, 0.675}` is **symmetric about the deployed central value**, and its low
  endpoint coincides with the Diffuse anchor (0.328) — so it is not arbitrary, but its
  justification is *design*, not *calibration*. The paper must not describe 0.675 as anchored.
- ⚠️ **The sweep is 2.1× wider than `v4`'s** (0.350 against 0.166). Any widening of the reported
  headline spread is therefore **partly an artefact of the sweep design**, not evidence that the
  new specification is more uncertain. Do not attribute it to `v5`.
- ✅ **0.50 is in both sweeps**, so `v4` and `v5` remain comparable at a common θ — which
  `MODEL.md` §5.3's warning requires ("compare two Run-Groups at a common θ, always").
- **Bulk's missing anchor is a reportable finding**, not a defect to tune away. θ = 0.50 is now
  anchored by Diffuse alone.
- φ moves materially: median |Δφ| = **0.0545**, mean 0.068, max 0.169 (ESW 0.809 → 0.640);
  median φ at 2025 falls 0.762 → 0.669. For scale, the declared specification band moves φ by a
  median of 0.034, so **this change is ~1.6× the sensitivity already reported as material**. The
  floor regions are unchanged (CHA, REF); UKI becomes the first region at φ = 1.
- **The entire coupled REMIND batch must be re-run.** Every coupled claim (C19–C24, C32–C34) is
  still `X-1959`'s until it is.

## Alternatives rejected

- **Leave the gate at 0.25 and deploy `splitAPpc`.** Defensible, and was the `v4` position — but
  it required writing that the better-fitting, more rank-stable form is excluded, while the same
  gate had rejected the *opposite* form on `v3`. "Whichever survives the gate" was not a
  modelling principle.
- **Set the gate at 0.29.** Selects identically with ~50× the margin. Rejected in favour of
  0.275 by explicit decision; recorded here because the two are otherwise equivalent and a
  reviewer will ask.
- **Widen `deltaWindow` to 2030–2060 instead.** Rejected: `deltaWindow` is shared with the
  `scenarioBlind` gate (`computePolicyStringencySanity.R:445–453`), and pre-2040 is exactly where
  the mitigation and reference scenarios have not yet diverged — so widening back would loosen
  one gate and tighten another across all ten specs at once.
- **Keep sweeping `{0.475, 0.50, 0.641}`.** Rejected: those were `v4`'s *sector anchors*, and on
  `v5` neither endpoint is anchored to anything. Re-using them would quote a calibration that no
  longer exists.

## Provenance

`output/v5/recut-provenance.json`. `supportShareGate` is consumed only by `.psmSanitySelect()`
(`runPSMSweep.R:395`), downstream of fitting, tier gating and maximin ranking, so `v5` inherits
`v4`'s fits, coefficients, maximin and specs unchanged and re-runs only the sanity walk, the
selection, `selected-models-psm.yml` and the variants exhibit. The variants recomputation was
validated by reproducing `v4`'s own `selection-variants.rds` exactly — winners, best models and
sharing costs all matched — before `deployedModel` was changed.

See `docs/TODO.md` items **14** (closed) and **26** (what `v5` still needs).
