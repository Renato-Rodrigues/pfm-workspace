# 0008 — The SSP2 institution projection: gap closure, calibrated to PoliClim

**Status: Open (one parameter choice, §6)** — the author decided on 2026-10-27 that the gap-closure rule replaces the
quick convergence rule as the SSP2 central projection of the institutions without an SSP projection. The rule is
implemented in `pfm` (`pfmInstitutionProjection(rule = "gapclosure")`); the coupled batch under it is not run yet (§7).
It revises ADR 0051 item 2 once the coupled batch has run.

**Provenance.** Run-Group `v7` (selected specification `X-1791 … satInn iw:fexp`). PoliClim institution forecasts
(`../PoliClim projections/pol_institutions_forecast.csv`, received 2026-10-06); SSP extensions (Andrijevic et al.
2020) from the madrat sources. Scripts `analysis/checks/policlimRuleFit.R` (the rule's fit) and
`analysis/checks/institutionRule.R v7` → `output/pfm/v7/institution-rule.rds` (everything below); figures
`inst-*`, `ge-*`, `rol-literature` (`analysis/figures/R/fig-institution-rule.R`, `analysis/figures/output/v7/`).
Re-derive any number from the artifact before quoting it.

## 1. The rule, in one sentence

**Every country closes a fixed share of its distance to the best value observed in the data each year, starting from
its last value in the estimation panel.**

$$x_c(t) = 1 - (1 - x_{c,2023})\,e^{-\lambda (t - 2023)}$$

on the panel's normalised scale (0 = worst, 1 = best value observed; for a series where high is bad, after the
inversion the model already applies). One parameter, the rate λ. Countries further from the top improve faster; no
country declines; by 2100 a country closes $1 - e^{-77\lambda}$ of its gap.

**The democracy weight** (freedom of expression, ADR 0060) is not projected by the rule. It moves to the higher of its
2023 value and its 2014–2023 mean and is held there (author, 2026-10-27): no regime change is projected, but countries
in the recent decline recover part of it. The move follows a half cosine reaching the level in 2040.

**Government effectiveness** keeps its published SSP2 projection (Andrijevic et al. 2020; §4).

## 2. Why this form (the SSP2 principles)

The SSP2 narrative is "middle of the road": development follows historical patterns, progress is slow and uneven, and
countries converge only partly. Andrijevic et al. (2020) state it for governance: SSP2 "is largely consistent with
historical dynamics … Institutions in SSP2 are modestly effective and uneven". The rule encodes exactly that:

| SSP2 principle | the rule |
|---|---|
| slow, continued progress | a small constant rate; the gap halves only over 70–125 years |
| uneven: laggards catch up, but only partly | the change is proportional to the distance to the top; by 2100 a third to a half of each gap is closed |
| historical patterns, no regime reversal | every country keeps its own rank order; no country declines |

## 3. Why this rate: the fit to PoliClim's SSP2

λ is the least-squares fit of the rule to PoliClim's SSP2 country paths, 2030–2100, with the top at the best value
PoliClim observes (1996–2025), as in the model (`policlimRuleFit.R`; `pfmInstitutionGapClosureRates()`):

| PoliClim indicator (SSP2) | λ (per year) | half-life | R² of the country change 2025–2100 | current rule R² |
|---|---:|---:|---:|---:|
| rule of law (V-Dem `v2xcl_rol`) | 0.96% | 72 y | 0.78 | 0.44 |
| overall accountability | 0.56% | 124 y | 0.70 | −0.78 |

The current rule (75th percentile, half the gap closed by 2080, complete by 2150, no decline) is slow until about
2060 and then fast (`inst-policlim-paths`). Of the simple alternatives tested, a fitted common target adds little
(the fitted target is close to the top), a regional target fits worse, and a country's own best level fits much worse
(`policlimRuleFit.R`). **The rate is taken from PoliClim, the series is not**: the model reads V-Dem's `v2x_rule` and
vertical accountability; PoliClim's rule of law and accountability are the nearest indicators.

## 4. Anchored in the literature

1. **Andrijevic et al. (2020)** project governance from income, education and its gender gap, with country effects
   that converge to the 75th percentile of today's distribution **by 2250 in SSP2** (2130 in SSP1). Linear
   convergence over 2015–2250 closes 36% of the gap by 2100. The accountability rate closes 34% by 2025–2100; the
   current rule closes almost all of it by 2150, faster than Andrijevic's own SSP2.
2. **Andrijevic's Rule-of-Law Index (SSP1–3)** is an independent reference for rule of law (`rol-literature`): mean
   change 2025–2099 +0.11 (SSP2), +0.19 (SSP1). PoliClim's SSP2: +0.15.
3. **Government effectiveness** is the one institution series the model takes from the literature
   (`ge-ssp`, `ge-adaptation`): Andrijevic's SSP2 path, normalised by its own observed range and harmonised to the
   WGI-based panel value in 2023, the offset fading by 2040. The model therefore uses Andrijevic's *change*, anchored
   to the WGI *level*. PoliClim's government effectiveness is not used: it reverts to the mean (29% of countries
   decline by 2100 under SSP2, Andrijevic 0%; `ge-literatures`), because it is fitted on the WGI, which is
   re-standardised every year.

## 5. What it does

- **Against PoliClim** (`inst-policlim-*`): the mean path and the narrowing spread follow PoliClim SSP2 in both
  indicators. The rule cannot reproduce PoliClim's declines (about one country in ten for accountability) or its
  near-term dip to about 2030, and it lifts persistent autocracies without regional peers more than PoliClim does
  (China's rule of law 0.61 against 0.36 by 2100, Saudi Arabia 0.60 against 0.44). A two-parameter variant (each
  country's own best plus a share of the remaining gap) fits only slightly better (R² 0.84 / 0.75) and was not taken.
- **On the model's series** (`inst-model-series`): rule of law rises from a cross-country mean of 0.58 by +0.21 to
  2100 (current rule +0.21, held 0); vertical accountability by +0.11 (current +0.14).
- **No step from history** (`inst-model-seam`): the projection starts from the panel's 2023 value. The largest
  year-on-year move from 2023 into the projection is 0.009 (rule of law) and 0.006 (accountability), against a 95th
  percentile of 0.034 and 0.027 for history's own annual changes. The current and held rules start from V-Dem's raw
  2025 value and step by up to 0.14 a year for countries with recent regime shifts.
- **The constraint barely moves** (`inst-strength`, offline, EU21, θ = 0.50, the 1000 Gt hold-the-price energy
  system): power & industry k in 2100 0.685 (current rule 0.667, held 0.695), buildings & transport 0.494 (0.489,
  0.452). Expected effect on the coupled headline: of the order of a gigatonne.
- **The smooth harmonisation** of every other series (a half cosine to 2040 instead of a straight line) removes the
  kink at 2040; it is part of the gap-closure scenario family only, so every `v7` run is reproducible unchanged.

## 6. Open: one rate per indicator, or one rate for all

On the model's own rule-of-law series, the rule-of-law rate (0.96%) gives +0.21 by 2100, **above both published SSP2
references** (PoliClim +0.15, Andrijevic +0.11; about Andrijevic's SSP1, +0.19), because the model's countries start
further from the top (0.58 on the panel scale, PoliClim's 0.66).

| option | rule-of-law change on the model's series, 2025–2100 | PoliClim rule-of-law R² | parameters |
|---|---:|---:|---:|
| **A. one rate per indicator** (implemented): 0.96% rule of law, 0.56% every other series | +0.21 | 0.78 | 2 |
| **B. one rate for every series: 0.56%** | **+0.14** | 0.65 | **1** |

**Recommendation: B.** It is the simplest statement ("every institution closes 0.56% of its gap a year"), and it is
anchored three ways on what the model reads: the PoliClim SSP2 fit for accountability, Andrijevic's SSP2 convergence
pace (34% against 36% of the gap by 2100), and a rule-of-law change that lies between the two published SSP2
references. It costs fit to PoliClim's own rule-of-law index, a different V-Dem series from the model's. Changing it is
one row in `pfmInstitutionGapClosureRates()` and a re-run of `institutionRule.R`.

## 6a. Tested: the rule applied to government effectiveness (author's question, 2026-10-27)

`institutionRule.R` part 5, figures `ge-rule-series`, `ge-rule-strength`. Government effectiveness after 2023 replaced by
the rule from its 2023 panel value, on the gap-closure panel; strength k(t) at θ = 0.50, EU21, 1000 Gt hold-the-price
energy system, offline:

| government effectiveness | rule fit to Andrijevic SSP2 (R² of the change) | mean 2100 | power & industry k 2100 | buildings & transport k 2100 |
|---|---:|---:|---:|---:|
| Andrijevic SSP2 (the model) | — | 0.78 | 0.685 | 0.494 |
| gap closure at 0.81% a year (fitted to Andrijevic SSP2) | 0.67 | 0.75 | 0.571 | 0.521 |
| gap closure at 0.56% a year (the shared rate) | 0.12 | 0.70 | 0.513 | 0.542 |
| held at 2023 (bound) | — | 0.54 | 0.367 | 0.609 |

- **The rule describes Andrijevic's SSP2 path reasonably at its own rate** (0.81% a year; SSP1 1.49%, R² 0.88; SSP3 not
  representable). PoliClim's government effectiveness is nearly flat (+0.02 by 2100, 29% of countries declining) and
  no positive rate represents it.
- **Unlike the V-Dem series, the government-effectiveness projection moves the strength**: power & industry k in 2100
  falls from 0.685 to 0.57 (fitted rate) or 0.51 (shared rate), buildings & transport rises from 0.49 to 0.52–0.54.
  Andrijevic's path differs from the rule in its country pattern (driven by income and education) and lifts the best
  performers to the top of the scale by 2060.
- **The channel is not identified in power & industry**: the government-effectiveness main effect is insignificant in the
  mean regression and negative on the frontier (`MODEL.md` §2.5, §3.3). Better government effectiveness there tightens
  the projected constraint through that term, so the power & industry k is sensitive to a coefficient the paper does
  not interpret.
- **Reading.** Keeping Andrijevic's published SSP2 path for government effectiveness is the better-anchored choice: it is
  the literature projection, and the rule at its fitted rate is an approximation of it, not an independent source.
  The difference (power & industry k 0.685 against 0.57) is a sensitivity to report beside the held-institutions run,
  not a reason to change the central series. A coupled run would size it in CO₂.

## 7. Implementation

Done (2026-10-27): `pfmInstitutionProjection("gapclosure")`, `pfmInstitutionGapClosureRates()`,
`.pfmGapClosurePanel()` (the rule and the weight level, on the panel scale after harmonisation),
`panelDataScenario(harmonizeShape)` (smooth by default under the rule), tests `test-institutionGapClosure.R`; the
REMIND fork's `preparePFM.R` accepts `pfmInstitutions = gapclosure`.

To do, in order:

1. Decide §6 (and set the rates).
2. Commit and push `pfm` and the REMIND fork; install `pfm` on the cluster (`setup.sh --update`), so the preflight
   sees matching versions. No estimation re-run: the frontier, the anchor and the ranking are `v7`'s; institutions only
   enter through the scenario panel.
3. A `v7` scenario family under the rule (the matrix's `institutions: gapclosure`, run titles with the variant `gc`):
   the fading-limit θ sweep under both closures at both resolutions (12 runs) and the erosion ladder (κ 0.02, 0.027,
   0.05 at EU21, both closures; κ 0.027 at H12: 8 runs). The no-politics references, the constant and growing limits
   and the held-institutions rows do not depend on the institution rule and are reused.
4. `runCoupledStage.R v7`, then `SCENARIOS.md`, `MODEL.md` §5.2 and the paper's numbers on the new central rows; the
   current-rule rows become the sensitivity "quick convergence".
5. ADR revising ADR 0051 item 2 and `DATA.md` §5.4; the Methods' institutions paragraph (one sentence on the rule,
   one on the rate's source).

## References

- Andrijevic, M., Crespo Cuaresma, J., Muttarak, R. & Schleussner, C.-F. Governance in socioeconomic pathways and its
  role for future adaptive capacity. *Nat. Sustain.* **3**, 35–41 (2020).
- PoliClim institution forecasts (V-Dem v16, WGI 2025), SSP1–5, received 2026-10-06; unpublished.
