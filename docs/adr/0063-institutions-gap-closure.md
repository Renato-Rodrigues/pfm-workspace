# ADR 0063 — The SSP2 institution projection: every country closes 0.6% of its gap to the best observed value each year

- **Status:** **Proposed 2026-10-29.** It records the author's decision of 2026-10-27 (design note 0008, Decided). It revises
  ADR 0051 item 2 (the institution rule of the scenario panel); ADR 0051's other items stand.
- **Run-Groups:** `v8` (central: `pfmInstitutions = gapclosure` on every coupled row, `scenario-matrix-v8.yml`), and `v7`'s third
  wave (`V7W3EU21`, `V7W3H12`). Every earlier run keeps the rule it was run with: storyline convergence, or hold.
- **Evidence:** design note 0008 (§§1–7); `output/pfm/v7/gap-closure-history.rds`, `institution-rule.rds`, `ge-income.rds`;
  figures `inst-*`, `ge-*`, `rol-literature` (`analysis/figures/output/v7/`). Implemented in pfm
  (`pfmInstitutionProjection(rule = "gapclosure")`, `pfmInstitutionGapClosureRates()`).

## Decision

1. **Institution series without an SSP projection follow one rule.** Every country closes 0.6% of its distance to the best
   value observed in the data each year, starting from its 2023 value in the estimation panel:
   $$x_c(t) = 1 - (1 - x_{c,2023})\,e^{-0.006\,(t-2023)}$$
   on the panel's normalised scale (0 = worst, 1 = best observed since 1789).
2. **It covers every institution series:**
   - V-Dem rule of law, the accountability series, and the state-capacity indicators;
   - the WGI series;
   - government effectiveness, control of corruption and the Rule-of-Law Index, whose published SSP projections (Andrijevic
     et al. 2020) it replaces.
3. **Andrijevic et al.'s published SSP2 path for government effectiveness** is named in the paper as the reference the rule
   is compared with. It is run as the sensitivity `gapclosureAndrijevic`.
4. **The democracy weight** (freedom of expression, ADR 0060) is not projected by the rule. It moves to the higher of its
   2023 value and its 2014–2023 mean, along a half cosine reaching that level in 2040, and is held there. No regime change
   is projected; countries in the recent decline recover part of it.
5. **No step at the seam with history.** The rule starts from the panel's own 2023 value. Every other series' harmonisation
   offset fades along a half cosine to 2040 (no kink); this smooth fade applies to this scenario family only, so earlier
   runs reproduce unchanged.

## Why this rule

- **The SSP2 principles in one parameter** ("middle of the road": slow and uneven progress, partial convergence, no
  reversal):
  - a gap halves in 116 years;
  - by 2100 every country has closed 37% of its 2023 gap;
  - laggards gain most in absolute terms;
  - no country declines, and the countries' order is kept.
- **The rate is declared, and bounded by two published or observed sources** (not by PoliClim, which is unpublished):
  - **Andrijevic et al.'s SSP2 convergence assumption** (linear convergence to 2250) corresponds to 0.54–0.62% a year. That
    range comes from matching either the share of the gap closed by 2100 or the half-way year.
  - **V-Dem's own history**, the same rule fitted since 1900: 0.2–0.8% a year over the century, and 0.4–0.6% since 2000.
  - 0.6% lies inside both, rounded to one significant digit.
- **PoliClim as a consistency check only.** At 0.6% the rule reproduces PoliClim's SSP2 country changes 2025–2100 with R²
  0.69.
- **The previous rule was much faster.** Storyline convergence (half the gap by 2080, all of it by 2150) is 1.3–2.1% a year,
  faster than Andrijevic's SSP1. It also started from raw recent values, which stepped by up to 0.14 a year at the seam for
  countries with recent regime changes.

## What it does (v7's anchor, offline, EU21, θ 0.50, the 1000 Gt hold-the-price energy system; design note 0008 §4)

| institutions | strength k 2100, power & industry | buildings & transport |
|---|---:|---:|
| gap closure, every series (central) | 0.568 | 0.538 |
| gap closure, government effectiveness from Andrijevic SSP2 | 0.736 | 0.494 |
| previous rule (storyline convergence) | 0.667 | 0.489 |
| held | 0.695 | 0.452 |

- **Most of the difference from the previous rule comes from government effectiveness.** It acts through a term not
  identified in power & industry; the V-Dem series move k by a few hundredths.
- **On the series:** rule of law rises by +0.15 to 2100, between the published SSP2 references (Andrijevic +0.11, PoliClim
  +0.15). Government effectiveness rises by +0.17, against +0.10 to +0.18 implied by SSP2 income and +0.21–0.24 in
  Andrijevic's path.
- **The rule cannot reproduce declines, or PoliClim's near-term dip.** It lifts persistent autocracies without regional peers
  (China, Saudi Arabia) more than PoliClim does, and Russia and India less.

## Consequences

- **The v8 batch runs with it as central**, and the `gapclosureAndrijevic` sensitivity can be run as in v7's third wave.
- **The paper's Methods sentence** (design note 0008 §3): *Institution series without an SSP projection close 0.6% of their
  distance to the best observed value each year from their 2023 value, the pace of the SSP2 convergence assumption of
  Andrijevic et al. (2020) and within the range observed in V-Dem since 1900.*
- **Combined with v8's rents slack (ADR 0061):** the institutions move the ceiling, and the rents move the distance below it
  in buildings & transport; the two act on different parts.
- **Remaining sensitivities:** institutions held (as in every batch), and the published Andrijevic path for government
  effectiveness.

## Alternatives rejected

- **Storyline convergence (the previous central rule):** faster than SSP1, and stepping at the seam.
- **PoliClim's projections as the source:** unpublished and subject to change; used as a check only.
- **A rate per series:** two sources bound one common pace; per-series rates would add precision neither supports.
- **A common target other than the best observed value, or a regional target:** they fit PoliClim's SSP2 paths no better,
  or worse (design note 0008 §2).
