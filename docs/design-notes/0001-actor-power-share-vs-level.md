# 0001. Should the actor-power indices be shares or per-capita levels?

Date: 2026-08-24; closed 2026-09-15
Status: **Closed by [ADR 0044](../docs/adr/0044-actor-power-share-and-per-capita-level.md) and
[ADR 0045](../docs/adr/0045-extrapolation-gate-at-0275-and-declared-theta-sweep.md).** The selected form on
Run-Group `v5` is **`bothIncAP`** — clean-energy build-out as a share, fossil dependence as **both** a
share and a per-capita level — in `X-2079 WGIge|noRoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd
fe:OECDp`. The theory below is kept because it is the reason both fossil terms are carried;
the outcome is at the end. Earlier sweep-by-sweep evidence is in
`../_archive/_wip/2026-09-16/docs-pre-v5-sweep/design-notes/`.
Related: ADR 0040 (saturating actor power), ADR 0043 (ceiling gate), `MODEL.md` §2.3.

---

## The question

`Innovator Power` and `Incumbent Power` are currently weighted **shares** of the energy system
(`models/pfm/R/actorPowerIndex.R`):

```
Innovator Power (Bulk) = (1·VRE + 0.6·Electrification) / 1.6
Incumbent Power (Bulk) = (1·coal + 1·oil/gas + 0.5·fossil-in-industry) / 2.5
```

Both are shares of primary energy, bounded [0, 1]. The alternative is a **per-capita level** —
fossil energy per person rather than fossil energy as a fraction of the mix.

This is not a tuning choice. The two operationalise **different mechanisms**, and a share-only
model commits to one of them without saying so.

---

## Why it matters: two channels of business power

Political economy separates two routes by which a sector shapes policy, and share and level
measure different ones.

**Structural power** — the economy *depends* on the sector, so policy is constrained whether or
not anyone lobbies. Disruption is credible because the sector is load-bearing. This is the
"privileged position of business" tradition (Lindblom, Block) and, for energy specifically,
carbon lock-in (Unruh). **Inherently relative — it is a share.**

**Instrumental power** — deliberate agency: lobbying, campaign finance, revolving doors,
litigation, media. It requires resources, and resources scale with absolute rents and headcount.
This is the regulatory-capture tradition (Stigler, Peltzman) and Grossman–Helpman "protection for
sale", where contributions scale with the profits at stake. **Inherently absolute — it is a
level.**

Fairfield's structural/instrumental split maps almost exactly onto the two candidates. **A
share-only model represents structural power only.**

---

## Share

**For**

- Directly operationalises dependence and lock-in — the constraint that binds regardless of agency.
- Captures **disruption leverage**: one refinery among five has more veto power than one among five
  hundred. That is a ratio.
- Scale-free, so a 48-country panel is comparable without a size control.
- Bounded [0, 1], which suits a bounded ceiling and keeps the frontier well behaved.
- Natural under a contest reading of the policy arena, where the outcome depends on relative
  coalition weight.

**Against**

- Implies a small, poor, mostly-fossil country has *maximal* fossil dependence — Nigeria above
  Germany. Defensible as dependence; indefensible as capacity to influence.
- Insensitive to absolute resources: 20% of a vast system funds far more lobbying than 90% of a
  small one.
- **Denominator contamination.** The share falls when clean energy grows even if the fossil sector
  is untouched, so "fossil interests lost relative position" and "fossil interests shrank" are the same number.
- In a deep-mitigation scenario it is driven to a floor **by construction**, not by politics.

## Per-capita level

**For**

- Operationalises instrumental power: resources, employment, rents — what actually buys influence.
- Normalises by the **electorate**, the right denominator if the channel is constituency and votes.
  Fossil energy per person proxies how many people hold a material stake.
- Tracks stranded value, which the carbon-bubble literature identifies as driving resistance
  intensity.
- Falls only when the sector actually shrinks, not when a rival grows.

**Against**

- Ignores dependence entirely. High fossil-per-capita *with* abundant alternatives is treated the
  same as high fossil-per-capita with none.
- Confounded with development and climate: energy per capita rises with income and with
  heating/cooling demand, so the index partly measures wealth. The GDP control absorbs some of
  this, not cleanly.
- Unbounded and heavily right-skewed (Gulf states); needs care in a bounded-ceiling model.
- Loses the contest interpretation — two coalitions on absolute scales are not obviously
  comparable.

## Per GDP — considered, ranked third

Normalising by the economy rather than the electorate gives "how much of this economy is this
sector", which is closest to what structural power of business means and fits Culpepper's argument
that business power is greatest where the sector is economically weighty. But fossil energy per
unit GDP is among the most confounded variables in energy economics — it tracks industrial
structure, development stage and climate at once. Theoretically attractive, empirically muddy.

---

## The two sides are not symmetric

- **Fossil interests** have both structural and instrumental power. The structural component is real and
  share-like.
- **Clean-energy interests** have almost **no structural power** — the economy does not yet depend on them.
  Their influence is instrumental plus a policy-feedback channel: deployment creates constituencies
  that defend and extend policy (green spirals — Jacobs & Weaver, Aklin & Urpelainen; Meckling's
  carbon coalitions). That literature conventionally operationalises this as **deployment share**,
  because what matters is how established and normalised the clean sector has become.

So the theoretically clean position may be the opposite of uniform: **share for clean-energy interests, level
for fossil interests.**

The usual objection to mixed forms — that the composite `innovator − incumbent` becomes incoherent
across scales — **does not apply here.** The split forms enter the two separately
with their own coefficients and their own institution interactions. The difference is never taken.

---

## The identifiability tiebreaker

Not a theoretical argument, but decisive when both constructs are defensible.

Coefficients are estimated on 2000–2022 and applied to 2100. Measured when this note was written
(2026-08-24), on the share-only specification then selected, median over covered countries:

| Fossil index | median z at 2100 | Power & industry ceiling ratio 2100/2025 |
|---|---:|---:|
| fossil PE **share** | **−4.76** | 0.637 |
| fossil PE **per capita** | −1.08 | 0.877 |
| fossil **capacity** per capita | −1.07 | 0.876 |
| fossil **capital** per capita | −1.02 | 0.885 |

A share-based fossil index is extrapolated roughly **five standard deviations** beyond its
estimation range; a per-capita level about **one**. Both are extrapolation; one is five times
further out.

**Two secondary findings from the same runs.** (a) Capacity and capital add nothing over the flow
level — the trajectories correlate 0.983 and the ceiling ratios are within noise, so the gain is
share → level, *not* flow → stock. (b) Changing the clean-energy index alone moves power & industry 0.624 → 0.615,
i.e. nothing. The whole effect is on fossil.

Buildings & transport for completeness: 1.047 (share) → 1.158 (per capita). Already rising; not the problem
sector.

---
---

## Outcome on `v5`

**The sweep carries four per-capita-aware forms** (`createChannelConfigs.R`): `splitAPpc` (both
per capita), `mixedAP` (clean-energy build-out, fossil interests per person), `bothIncAP` (clean-energy build-out,
fossil dependence **and** per capita — nesting the other two) and the share-only `splitAP`.

**1. Selection.** `bothIncAP` holds maximin ranks 1, 2, 3, 5, 6 and 7 of 4,392
(`output/pfm/v5/sweep.rds`) and is selected. Of the gate-passing specifications, 124 are `bothIncAP`,
96 `splitAPpc`, 81 `mixedAP`, 194 `splitAP`.

**2. Resampling** (`output/pfm/v5/selection-bootstrap.rds`, 196 winners, top-60 pool). `bothIncAP` takes
**76.0%** of winners against a 43.3% pool share (exact binomial $p$ < 1e-19) — the largest drift of
any element; `splitAPpc` 17.3% against 26.7% ($p$ = .003); `mixedAP` 6.6%.

**3. What the two fossil terms say** (`output/pfm/v5/inference.rds`, mean regression, wild-cluster
$p$; `output/pfm/v5/frontier.rds`):

| term | Power & industry mean ($p_{wild}$) | Power & industry frontier | Buildings & transport mean ($p_{wild}$) | Buildings & transport frontier |
|---|---:|---:|---:|---:|
| Fossil dependence, share (structural) | −0.193 (.418) | **−0.190** | **−0.173 (.030)** | **−0.130** |
| Fossil dependence, per capita (instrumental) | **+0.489 (<.001)** | **+0.308** | +0.069 (.593) | **+0.132** |

The two carry **opposite signs**, which is what separating them was for: dependence goes with lower
stringency, size with higher. The structural term is theory-signed in both sectors and both
estimators. The positive instrumental term is the exposure confound (`MODEL.md` §8.3) — large,
capable fossil economies also regulate more — and is not evidence that fossil interests raise ambition.

**4. What was wrong in this note's original recommendation.** It proposed `mixedAP` (replace the
fossil dependence by a per-capita level). The data never favoured dropping the share: `mixedAP` is the
least-selected form (6.6% of bootstrap winners). The theory above anticipated the reason — structural and
instrumental power are different channels — but the recommendation then chose one of them.

**5. Costs to disclose.** Carrying both fossil terms adds collinearity (selected max VIF 3.41
Power & industry, 2.89 buildings & transport — well inside the gate) and two extra interactions per institution. Sign
agreement across seven estimators is weak in power & industry (4 of 15 terms, `MODEL.md` §2.5.1), and neither
fossil main effect is among the stable ones there.
