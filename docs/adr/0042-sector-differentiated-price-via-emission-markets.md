# 42. Sector-differentiated carbon price: deliver Bulk/Diffuse through `pm_taxemiMkt`, not through a `min`

Date: 2026-08-17

## Status

Accepted. Refines ADR 0041 (the relative-feasibility coupling) at the delivery step
only — φ and the frontier are unchanged. Replaces the `sectorRule = "min"` collapse as
the **default** delivery path; `min` survives as the fallback when the markup is off.

## Context

The PFM is estimated **separately for two sectors**, because they are politically
different regimes (`MODEL.md` §1):

- **Bulk** — electricity + industry. Few, large, organised actors. Speed limit
  λ = 0.1023/yr.
- **Diffuse** — buildings + transport. Costs land on households, visibly. λ = 0.0770/yr.

REMIND's `45_carbonprice` sets one price per region, `pm_taxCO2eq`, so the two shares had
to be collapsed to one number before delivery. The rule was `min` — the worse sector
governs — applied in three places (φ, the mode-L bound, the mode-M path).

Measured on the 48 in-coverage countries at 2030, that rule is doing something much
narrower than it looks:

- ~~**Diffuse binds in 45 of 48 countries (94%).** Bulk binds in 3.~~ 🔴 **RETRACTED 2026-08-19** — computed on S/10 (`PITFALLS.md` §22). On $E$ at the tier year Diffuse binds in **16 of 48 (33%)**; Bulk binds in 32. The ADR's decision stands: it rests on the two sectors disagreeing, not on which one wins.
- ~~Median implementability: Bulk 0.687, Diffuse 0.600; correlation 0.71.~~ 🔴 **RETRACTED
  2026-08-19** — computed on `projection.rds$implementability` = S/10, the measure MODEL.md §7
  prohibits. On $E$ at the tier year the medians are **0.723 / 0.731** — tied — and the
  correlation is **+0.26**. `PITFALLS.md` §22, `SCENARIOS.md` §1.1. The ADR's decision is
  unaffected: it rests on the two sectors being separately estimated, not on their levels.
- Biggest disagreements: Saudi Arabia 0.64/0.28, Russia 0.67/0.38, Indonesia 0.63/0.39,
  South Africa 0.50/0.31, India 0.70/0.53.

Three problems follow.

1. **It discards half the model.** `min` keeps one sector and throws the other away wherever they disagree — which is most of the time, in both directions.
   Two estimated equations, two frontiers and two speed limits reduce to one.
2. **`min` of two noisy estimates is downward-biased.** φ_Bulk and φ_Diffuse are
   estimates with sampling error, correlated at 0.71. The minimum of two noisy draws
   sits below the minimum of the true values, and the bias grows with the noise. `min`
   therefore does not measure "the harder sector's feasibility"; it measures that minus
   an estimation-noise penalty.
3. **The bias runs the wrong way for the claim.** The headline is *political feasibility
   costs X Gt*. `min` maximises X. A conservative choice should shrink the reported
   effect, not inflate it — "we took the worse of two estimates" is not a defence when
   the worse one is biased low.

Pooling the two sectors into a single median frontier was considered and rejected: the
estimated coefficients and speed limits genuinely differ, and the Bulk/Diffuse split is
the structural insight the paper rests on. The sector split is not the problem. **The
collapse is.**

Meanwhile REMIND already carries a sector-differentiated price instrument that nothing in
this project was using.

## Decision

**Deliver the two sector shares as an economy-wide floor plus an ETS markup, through
`pm_taxemiMkt`.**

```
pm_taxCO2eq(t,regi)          <- min(P_Bulk, P_Diffuse)          the economy-wide floor
pm_taxemiMkt(t,regi,"ETS")   <- max(P_Bulk - P_Diffuse, 0)      what Bulk can bear on top
pm_taxemiMkt(t,regi,"ES")    <- 0
pm_taxemiMkt(t,regi,"other") <- 0
```

Four facts make this work, all verified against the code and the gdx:

1. **`pm_taxemiMkt` is strictly additive.** `q21_taxrevGHG` charges `pm_taxCO2eqSum` on
   all CO₂eq; `q21_taxemiMkt` (`21_tax/on/equations.gms:104`) then adds
   `pm_taxemiMkt(m) × vm_co2eqMkt(m)` per market. The effective price on market *m* is
   `pm_taxCO2eqSum + pm_taxemiMkt(m)`. A markup is exactly the shape we need.
2. **The market accounting is always on.** `q_co2eqMkt` (`core/equations.gms:777`) splits
   emissions by market and `vm_co2eq = sum(emiMkt, vm_co2eqMkt)`. `pm_taxemiMkt` is
   declared in **both** realizations of module 47, so it exists whatever `regipol` is.
3. **It is currently unused.** `pm_taxemiMkt` has zero records in every run of the
   2026-08-14/16 batch. Nothing is being overwritten.
4. **Nothing else has to be rewired.** `pm_taxCO2eqSum` is consumed by MAC curves
   (`core/presolve.gms:262-265`), the biofuel emission factor (`21_tax:179`) and trade
   tariffs (`21_tax:268`), none of which see `pm_taxemiMkt`. Because the floor stays in
   `pm_taxCO2eq`, every one of those consumers keeps working unchanged. Putting the whole
   price into `pm_taxemiMkt` instead would have required auditing all of them.

**Market ↔ sector mapping: ETS ≈ Bulk, ES + other ≈ Diffuse.** Measured shares of CO₂ at
2030: ETS 58%, ES 30%, other 11%, with the ETS share ranging from 11% (Nordic EU) to 80%
(China) — behaving exactly like "power + industry". The correspondence is good but **not a
bijection**: `sector2emiMkt` (`core/sets.gms:2095`) maps `indst` to *both* ETS and ES, and
`trans` to ES and other. We accept that industry's ES slice receives the Diffuse price.
That is a deliberate, documented approximation, and it errs toward *less* differentiation,
i.e. toward the old behaviour.

**Controlled by `cm_pfmSectorMarkup`, default 1 (on).** The markup is the decision of
this ADR, so it is what a coupled run does unless told otherwise. Setting it to 0
reproduces the `min` behaviour bit-for-bit — that is the **sensitivity to report
against**, not a fallback to run by accident. The switch is written into every coupled
row by the config generator, so what a run did is visible in the scenario row rather
than implied by a package version.

**Hard abort when a second controller owns the instrument.** `47_regipol/regiCarbonPrice`
iterates `pm_taxemiMkt` against emission-market targets with its own rescale factor
(`postsolve.gms:386`), and module 47's postsolve runs **after** module 45's. Two
controllers on one instrument is the class of failure that produced defect 5 (φ written,
then erased before the solve). The abort fires only when both of these hold:

```
%regipol% == regiCarbonPrice   AND   %cm_emiMktTarget% != off
```

Not on `regipol` alone: the realization carries other machinery that does not touch the
carbon price, and disabling those would be a needless restriction.

## Consequences

**What gets better.**

- Both estimated sectors reach the model. The result becomes *"the political limit on
  household energy costs binds the economy-wide price, but industry and power carry
  more"*, which is a sharper and more defensible claim than *"politics lowers the carbon
  price"*.
- The `min` question dissolves rather than being answered by assertion, and with it the
  downward bias that inflated the headline.
- The mechanism now runs through REMIND's real policy architecture — an ETS and an
  effort-sharing market — instead of a statistical shortcut, which is much closer to how
  the constraint actually operates in the EU.

**What to watch.**

- `pm_taxemiMkt` is a **markup and must stay non-negative**. The floor is `min` over
  sectors and each market's markup is that market's own sector minus the floor, clamped
  at zero, so it can never go negative.
- Adjacent hazard, not guarded here: `cm_regiExoPrice` and `cm_regiExoPrice_fromFile`
  zero both `pm_taxCO2eq` and `pm_taxemiMkt` in `47_regipol` postsolve
  (`postsolve.gms:960, 984`). Those would break the coupling with or without this ADR;
  they are simply incompatible with a coupled run.
- The gdx contract gains four symbols carrying a **market dimension**:
  `p45_pfmPhiMkt(all_regi,all_emiMkt)` and `p45_pfmLambdaMkt(all_regi,all_emiMkt)` at
  rank 2, `p45_pfmPriceBoundMkt(ttot,all_regi,all_emiMkt)` and
  `p45_pfmMPPriceMkt(ttot,all_regi,all_emiMkt)` at rank 3. **This reverses the original
  decision in this ADR** — see the 2026-08-17 amendment below.
- Reporting must not add the two: the price a region faces on ETS emissions is
  `pm_taxCO2eq + pm_taxemiMkt("ETS")`, and on ES emissions it is `pm_taxCO2eq` alone.
  Any figure quoting "the carbon price" for a coupled run must say which market.

**What is deliberately not done.** Splitting `indst` between the two markets by its actual
ETS/ES emission shares, and a third price for `other`. Both are refinements on an
approximation that already errs conservatively; revisit only if the industry split turns
out to move a headline.


---

## Amendment, 2026-08-17: the markup is symmetric, and it carries a market dimension

Two corrections to the decision above. Both were found by instrumenting the deployed
frontier rather than by review.

**1. The markup was one-sided, and that capped the demand side.** As first written, the
markup went on ETS only and `ES`/`other` were set to zero. Where **Bulk** is the worse
sector the floor is already Bulk, the ETS markup is correctly zero — but ES was then
pinned at the *Bulk* price and the Diffuse estimate was discarded. That is the same
information loss this ADR exists to remove, moved to the other sector.

Every market now carries its own sector's markup, and `other` follows `ES` (REMIND's own
convention at `47_regipol/regiCarbonPrice/postsolve.gms:409`, and the mapping this ADR
already states). The map lives in one place: `.psmSectorMarkets()`.

**2. "3 of 48 countries" is withdrawn — it is 14 of 48.** Re-derived from
`output/v1/frontier.rds` (2022, n = 48) using the coupling's own measure, the
within-sector normalised relative gap that φ = 1 − θu is built from: **Bulk is the worse
sector in 14 of 48 countries** — ARG, CAN, FIN, IDN, ISL, JPN, KOR, MLT, NOR, NZL, RUS,
SAU, SWE, ZAF. By raw efficiency it is 38 of 48. Neither is 3, under either measure, on
the regenerated `satAP` frontier. The discarded ES headroom in those countries was a
median 0.12 in φ and up to **0.30** (ISL 0.30, ZAF 0.27, RUS 0.21).

*Caveat:* φ is normalised over the 21 REMIND regions, not over countries, so the exact
region-level count needs `psm-coupling-bound` re-run — which is stale in any case
(`TODO.md` item 1).

**3. The rank-3 rejection is reversed.** The original text rejected a market dimension as
"that trap one dimension up **for no gain**". The no-gain clause no longer holds: a
symmetric markup needs both sectors delivered, which is **eight** flat parameters against
**four** indexed ones. The trap is now answered directly rather than avoided —
`.psmVerifyCouplingGdx()` asserts rank *and* domain names against what REMIND declares,
and `test-gdxRoundTrip.R` pins both rank-2 families (note they lead with *different*
indices: `(ttot, all_regi)` vs `(all_regi, all_emiMkt)`), the rank-3 order, the sector
fan-out, and a deliberately transposed rank-3 symbol that must be refused.

**4. A property to stop assuming: the floor can sit below *both* sector prices.** It is
tempting to reason that, since the floor is `min`, exactly one market carries a positive
markup. **False.** `sectorRule = "min"` takes the worse *share* **and** the slower
*speed*, and those can come from different sectors — so the floor is the most-constrained
*combination*, belonging to neither sector. In the test fixture it is strictly below both
sector prices in 10 of 18 region-years, with both markups positive.

What still holds, and is the invariant to rely on: **floor + markup(m) reproduces market
m's own sector price exactly**, and no markup is ever negative. What follows from it:
`pm_taxCO2eq` is a price *no market actually faces*, and every consumer of
`pm_taxCO2eqSum` sees it — the MAC curves, the land-use tax, the trade tariffs, the
net-negative penalty. Conservative, and deliberate, but a real distortion that should be
stated wherever the floor is quoted.

**Not done, deliberately:** making the floor the elementwise `min` of the two *prices*
rather than of their inputs. That would restore "exactly one markup is positive" and give
`pm_taxCO2eqSum` a price some market actually pays — but it changes every coupled result
and the conservative floor is defensible as it stands. Revisit only with a re-run budget.
