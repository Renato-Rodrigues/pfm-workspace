# 0008 — The SSP2 institution projection: gap closure at 0.6% a year

**Status: Decided 2026-10-27 (author); coupled batch not run yet (§7).** The gap-closure rule replaces the quick
convergence rule as the SSP2 central projection of the institutions without an SSP projection, with one declared rate
for every series, **0.6% a year**, justified without PoliClim (§3). Implemented in `pfm`
(`pfmInstitutionProjection(rule = "gapclosure")`, `pfmInstitutionGapClosureRates()`). It revises ADR 0051 item 2 once
the coupled batch has run. Open: government effectiveness (§6).

**Provenance.** Run-Group `v7` (selected specification `X-1791 … satInn iw:fexp`). V-Dem v16 and WGI 2025 from the
`v7` madrat cache; SSP extensions (Andrijevic et al. 2020) from the madrat sources; PoliClim institution forecasts
(`../PoliClim projections/pol_institutions_forecast.csv`, received 2026-10-06, unpublished) as a consistency check only.
Scripts and artifacts:

| script | artifact | what |
|---|---|---|
| `analysis/checks/gapClosureHistory.R v7` | `output/pfm/v7/gap-closure-history.rds` | the rate from V-Dem history and from Andrijevic's assumption (§3) |
| `analysis/checks/institutionRule.R v7` | `output/pfm/v7/institution-rule.rds` | the rule against PoliClim, the model's scenario panels, the strength k, the literature series (§4–§6) |
| `analysis/checks/geIncome.R v7` | `output/pfm/v7/ge-income.rds` | government effectiveness and income (§6) |
| `analysis/checks/policlimRuleFit.R` | `output/checks/policlim-rule-fit.rds` | simple rules fitted to PoliClim (§2) |

Figures `inst-*`, `ge-*`, `rol-literature` (`analysis/figures/R/fig-institution-rule.R`, rendered in
`analysis/figures/output/v7/`). Re-derive any number from the artifact before quoting it.

## 1. The rule, in one sentence

**Every country closes 0.6% of its distance to the best value observed in the data each year, starting from its last
value in the estimation panel.**

$$x_c(t) = 1 - (1 - x_{c,2023})\,e^{-0.006\,(t - 2023)}$$

on the panel's normalised scale (0 = worst, 1 = best value observed since 1789; for a series where high is bad, after
the inversion the model already applies). One parameter. A country's gap halves in 116 years; by 2100 every country has
closed 37% of its 2023 gap. Countries further from the top improve more in absolute terms; no country declines; the rank
order of countries is kept.

The rule applies to every institution series with no SSP projection: V-Dem rule of law, vertical, horizontal, diagonal
and overall accountability, the state-capacity indicators, and WGI voice and accountability, political stability and
regulatory quality. Of these, the selected specification reads rule of law and vertical accountability.

**The democracy weight** (freedom of expression, ADR 0060) is not projected by the rule. It moves to the higher of its
2023 value and its 2014–2023 mean and is held there (author, 2026-10-27): no regime change is projected, but countries
in the recent decline recover part of it. The move follows a half cosine reaching the level in 2040.

**Government effectiveness** keeps its published SSP2 projection (Andrijevic et al. 2020) for now (§6).

**No step from history.** The path starts from the panel's own 2023 value, so the projection begins where the fitted
history ends. Every other scenario series is harmonised to 2023 as before, its offset now fading along a half cosine
to 2040 (no kink); the smooth fade belongs to this scenario family only, so every `v7` run is reproducible unchanged.

## 2. Why this form: the SSP2 principles

SSP2 is "middle of the road": development follows historical patterns, progress is slow and uneven, countries converge
only partly. Andrijevic et al. (2020) state it for governance: SSP2 "is largely consistent with historical dynamics …
Institutions in SSP2 are modestly effective and uneven". The rule encodes that:

| SSP2 principle | the rule |
|---|---|
| slow, continued progress | one small constant rate; a gap halves over 116 years |
| uneven: laggards catch up, but only partly | the change is proportional to the distance to the top; 37% of each gap closed by 2100 |
| historical patterns, no regime reversal | every country keeps its rank; no country declines |

Of the simple forms tested against PoliClim's SSP2 country paths (`policlimRuleFit.R`), gap closure to the top fits as
well as a fitted common target (the fitted target is close to the top); a regional target, a country's own best level
and a common linear trend fit worse; the current rule fits worst (R² of the country change 2025–2100: 0.44 for rule of
law, −0.78 for accountability).

## 3. Why 0.6% a year: the calculation

The rate is declared, not estimated. Two sources that do not depend on unpublished projections bound it, and 0.6% lies
inside both (`gapClosureHistory.R`; figure `inst-rate-justification`).

**3.1 Andrijevic et al. (2020), the published SSP2 assumption.** Their governance projection lets the country effects
converge *linearly* to a common level (the 75th percentile of today's distribution), reached in 2250 in SSP2 and in
2130 in SSP1. The rule is exponential, so representing the linear path means choosing what to match, from the rule's
start in 2025:

- **the same share of the gap closed by 2100.** A linear path from 2025 to 2250 closes $(2100-2025)/(2250-2025) = 75/225
  = 33\%$ of the 2025 gap by 2100. The exponential rule closes the same share when
  $1 - e^{-75\lambda} = 0.333$, so $\lambda = -\ln(0.667)/75 = $ **0.54% a year**;
- **the same half-way year.** The linear path closes half of the gap halfway, in $2025 + 225/2 = 2137.5$. The rule
  halves the gap after $\ln 2/\lambda$ years, so $\lambda = \ln 2/112.5 = $ **0.62% a year**.

So Andrijevic's SSP2 corresponds to **0.54–0.62% a year**. (SSP1: 1.3–1.7% a year. The current rule, half the gap by
2080 and all of it by 2150, is 1.3–2.1% a year: faster than Andrijevic's SSP1.)

**3.2 V-Dem's own history.** The same rule, $x(s+h) = 1 - (1 - x(s))\,e^{-\lambda h}$, fitted by least squares to every
country's observed values, on the panel's normalised scale: pooled over start years $s$ every five years from 1900
with horizons $h$ of 25 and 50 years, and for single windows.

| sample | rule of law λ | vertical accountability λ |
|---|---:|---:|
| pooled 1900–2025, 25-year horizon | 0.29% | 0.74% |
| pooled 1900–2025, 50-year horizon | 0.22% | 0.77% |
| 1900–1950 | 0.21% | 0.36% |
| 1950–2000 | 0.22% | 1.02% |
| 1975–2025 | 0.53% | 1.08% |
| 1990–2025 | 0.34% | 0.77% |
| 2000–2025 | 0.42% | 0.56% |

History is noisy (regime changes; the rule explains 4–32% of the country changes), so it bounds the average pace, not a
country's path: 0.2–0.8% a year over the century, 0.5–1.1% over the last half-century, 0.4–0.6% since 2000.

**3.3 The value.** 0.6% a year lies inside Andrijevic's SSP2 range (0.54–0.62%) and inside the historical range of both
series, between rule of law's long-run pace and accountability's. It is rounded to one significant digit, so it does
not claim more precision than either source.

**3.4 Consistency check: PoliClim** (unpublished, may change; not the source). Fitted to PoliClim's SSP2 country paths,
the rule's best rate is 0.56% a year for overall accountability and 0.96% for rule of law (`policlimRuleFit.R`). At
0.6% the rule reproduces PoliClim's SSP2 country changes 2025–2100 with R² 0.69 for both indicators (mean change: rule of
law +0.12 against PoliClim's +0.15; accountability +0.11 against +0.09; `inst-policlim-paths`, `inst-policlim-change`).

**Sentence for the paper (Methods).** *Institution series without an SSP projection close 0.6% of their distance to the
best observed value each year from their 2023 value, the pace of the SSP2 convergence assumption of Andrijevic et al.
(2020) and within the range observed in V-Dem since 1900.*

## 4. What it does

- **On the model's series** (`inst-model-series`): rule of law rises from a cross-country mean of 0.58 by +0.15 to
  2100 (current rule +0.21, held 0); vertical accountability by +0.11 (current +0.14). The rule-of-law change lies
  between the two published SSP2 references, Andrijevic's Rule-of-Law Index (+0.11) and PoliClim (+0.15)
  (`rol-literature`).
- **No step from history** (`inst-model-seam`): the largest year-on-year move from 2023 into the projection is 0.006
  for rule of law and for accountability, against a 95th percentile of 0.034 and 0.027 for history's own annual
  changes. The current and held rules start from V-Dem's raw 2025 value and step by up to 0.14 a year for countries
  with recent regime shifts.
- **The constraint moves a little** (`inst-strength`; offline, EU21, θ = 0.50, the 1000 Gt hold-the-price energy
  system): power & industry k in 2100 0.736 (current rule 0.667, held 0.695), buildings & transport 0.494 (0.489,
  0.452). The coupled run sizes it in CO₂.
- **Against PoliClim, by country** (`inst-policlim-countries-*`): the rule cannot reproduce PoliClim's declines (one
  country in ten for accountability) or its near-term dip to about 2030, and it lifts persistent autocracies without
  regional peers more than PoliClim does (rule of law 2100: China 0.50 against 0.36, Saudi Arabia 0.49 against 0.44);
  it lifts Russia and India less (0.54 against 0.66; 0.72 against 0.82).

## 5. Government effectiveness in the literature

Government effectiveness is the one institution series the model takes from a published projection (`ge-ssp`,
`ge-adaptation`): Andrijevic et al.'s SSP2 path, a panel regression on income, education and its gender gap with
converging country effects, normalised by its own observed range and harmonised to the WGI-based panel value in 2023,
the offset fading by 2040. The model uses Andrijevic's *change*, anchored to the WGI *level*. PoliClim's government
effectiveness is not used: it reverts to the mean (29% of countries decline by 2100 under SSP2, Andrijevic 0%;
`ge-literatures`), because it is fitted on the WGI, which is re-standardised every year.

## 6. Open: government effectiveness under the rule?

**6.1 The rule applied to government effectiveness** (`institutionRule.R` part 5; `ge-rule-series`, `ge-rule-strength`).
Government effectiveness after 2023 replaced by the rule from its 2023 panel value; strength at θ = 0.50, EU21, 1000 Gt
hold-the-price energy system, offline:

| government effectiveness | mean 2100 | power & industry k 2100 | buildings & transport k 2100 |
|---|---:|---:|---:|
| Andrijevic SSP2 (now) | 0.78 | 0.736 | 0.494 |
| gap closure at 0.81% a year (the rule's best fit to Andrijevic SSP2, R² 0.67) | 0.75 | 0.620 | 0.521 |
| **gap closure at 0.6% a year (the shared rate)** | 0.71 | 0.568 | 0.538 |
| held at 2023 (bound) | 0.54 | 0.398 | 0.609 |

Unlike the V-Dem series, the government-effectiveness projection moves the strength, through a term that is not
identified in power & industry (insignificant in the mean regression, negative on the frontier; `MODEL.md` §2.5, §3.3).

**6.2 Government effectiveness and income** (`geIncome.R`). Across countries in 2023, government effectiveness
correlates 0.80 with log GDP per capita (slope 0.135 per log point); within countries (country and year effects,
1996–2023) the slope is 0.074 and the long changes correlate only 0.27 with income growth. SSP2 income converges
(countries with weaker government today grow faster: correlation −0.63; mean income ×3.9 by 2100). The path SSP2
income implies (each country's 2023 value plus the slope times its log income growth) rises +0.10 (within slope) to
+0.18 (cross slope) by 2100:

| formulation (country change 2023–2100) | mean change | correlation with the income-implied change (within / cross) | RMSE (within / cross) |
|---|---:|---:|---:|
| **gap closure at 0.6% a year** | **+0.17** | **0.63 / 0.64** | **0.095 / 0.102** |
| gap closure at 0.81% a year | +0.22 | 0.63 / 0.64 | 0.136 / 0.106 |
| Andrijevic SSP2 (now) | +0.24 | 0.49 / 0.50 | 0.177 / 0.140 |
| held at 2023 | 0 | −0.05 | 0.123 / 0.224 |

**6.3 The choice.** Judged against SSP2's income path, the shared rule is the closest formulation; judged as a literature
source, Andrijevic's published SSP2 path is the stronger anchor (it adds education and its gender gap, and rises more
than income alone implies). Under the shared rule one sentence covers every institution series, and power & industry k
in 2100 is 0.57 instead of 0.74. Whichever is central, the other is the sensitivity.

## 7. Implementation

Done (2026-10-27): `pfmInstitutionProjection("gapclosure")`, `pfmInstitutionGapClosureRates()` (one row, 0.6%),
`.pfmGapClosurePanel()` (the rule and the weight level, on the panel scale after harmonisation),
`panelDataScenario(harmonizeShape)` (smooth under the rule), tests `test-institutionGapClosure.R`; the REMIND fork's
`preparePFM.R` accepts `pfmInstitutions = gapclosure`.

To do, in order:

1. Decide §6.3.
2. Push `pfm`, the REMIND fork and the project; on the cluster `setup.sh --update` (the preflight checks installed
   against the working tree). No estimation re-run: the frontier, the anchor and the ranking are `v7`'s; institutions
   enter only through the scenario panel.
3. A `v7` scenario family under the rule (the matrix's `institutions: gapclosure`, run titles with the variant `gc`):
   the fading-limit θ sweep under both closures at both resolutions (12 runs) and the erosion ladder (κ 0.02, 0.027,
   0.05 at EU21, both closures; κ 0.027 at H12: 8 runs). The no-politics references, the constant and growing limits
   and the held-institutions rows do not depend on the institution rule and are reused.
4. `runCoupledStage.R v7`, then `SCENARIOS.md`, `MODEL.md` §5.2 and the paper's numbers on the new central rows; the
   current-rule rows become the sensitivity "quick convergence".
5. An ADR revising ADR 0051 item 2, `DATA.md` §5.4, and the Methods' institutions paragraph (§3, the sentence for the
   paper).

## References

- Andrijevic, M., Crespo Cuaresma, J., Muttarak, R. & Schleussner, C.-F. Governance in socioeconomic pathways and its
  role for future adaptive capacity. *Nat. Sustain.* **3**, 35–41 (2020).
- Coppedge, M. et al. V-Dem Country–Year Dataset v16. Varieties of Democracy Project (2026).
- PoliClim institution forecasts (V-Dem v16, WGI 2025), SSP1–5, received 2026-10-06; unpublished. Consistency check only.
