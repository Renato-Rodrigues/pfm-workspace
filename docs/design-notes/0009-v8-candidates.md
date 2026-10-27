# 0009 — v8 candidates: the countries at the edge, fossil rents, and what else the next version could represent

**Status: Open (evaluation, 2026-10-27)** — the author asked, before any new run or paper formulation, (1) why some
countries have extreme efficiency ratios and whether the indicators explain it, (2) whether fossil rents could enter the
model and be linked to REMIND, (3) whether the saturating form fixes Iceland, and (4) what else a `v8` could represent.
Nothing here changes `v7` or its coupled batch.

**Provenance.** Run-Group `v7` (selected specification `X-1791 … satInn iw:fexp`). Scripts, all on the workstation:
`analysis/checks/efficiencyExtremes.R v7` → `output/pfm/v7/efficiency-extremes.rds` (§1);
`analysis/checks/saturationAlternative.R v7` → `output/pfm/v7/saturation-alternative.rds` (§2);
`analysis/v8/rentsTest.R v7` → `output/pfm/v7/v8-rents-test.rds` (§3; World Bank WDI rents downloaded 2026-10-27,
cached in `output/pfm/v7/v8-wdi-rents.rds`). Every refit here is offline (frontier and mean regression with asymptotic
clustered *p*; the wild bootstrap, the sanity walk and the gates are not rerun). Re-derive any number from the artifact.

## 1. The extreme efficiency ratios (power & industry, 2023)

E = observed stringency / ceiling. Lowest of 48: Iceland 0.33, Indonesia 0.33, Peru 0.35, Argentina 0.39, Russia 0.46;
Saudi Arabia 0.55 (8th). Highest: Luxembourg, Switzerland, Ireland 0.95–0.97. Each ceiling was rebuilt from the
frontier's design matrix (as the coupling does) and split by term, against the sample mean (logit scale):

| country | observed / ceiling | what drives it | reading |
|---|---|---|---|
| Iceland | 2.5 / 7.7 | fossil dependence +2.0 (fossil share 0.10, the lowest; below the sample's 5th percentile; the term is linear in `v7`), offset by small population −0.6 and clean baseload −0.8 | the ceiling is an extrapolation at the low edge; the low observed index reflects few instruments needed in an almost fully renewable power system, not political slack |
| Indonesia | 2.3 / 6.9 | fossil interests per person × rule of law +2.4 (very low fossil energy per person and weak rule of law: two negative standardised values) | outside the joint support; the region ADR 0060 lists as not identified (poor countries with very low fossil energy per person) |
| Peru | 1.5 / 4.1 | the same term +0.8, fossil per person × state capability −1.3, the "other" level −0.9 | partly the same artefact; observed policy also very low |
| Argentina | 2.2 / 5.7 | fossil dependence −0.5, rule of law −0.6, fossil per person × rule of law +0.8 | partly the same artefact |
| Russia | 1.4 / 3.0 | rule of law −2.1 (below the 5th percentile), the "other" level −0.9; vertical accountability +0.7 and government effectiveness +0.7 through negative, unidentified main effects | the ceiling is low for theory-consistent reasons; observed policy is lower still |
| Saudi Arabia | 3.9 / 7.0 | vertical accountability +1.8 (the lowest in the sample, times a negative main effect that is not identified in power & industry), fossil per person +1.6 against fossil dependence −1.1 | an artefact of an unidentified term; in buildings & transport Saudi Arabia sits near its (low) ceiling, E 0.94, which is plausible |

**What the indicators do not capture.**

1. *Producer interests.* The fossil terms measure the domestic energy system (shares and energy per person), not
   extraction or export rents (MODEL.md §8.3: "a fossil-rents reader would be needed"). This matters for Saudi Arabia
   and Russia (oil, gas), Indonesia (coal), Argentina (gas) and Peru (mining).
2. *Policy need.* CAPMF scores instruments; a power system without fossil generation needs few, so a low index there
   is not resistance. No indicator in the model separates "little to regulate" from "politically blocked".

**Does it matter for the coupling?** The coupling reads regional E, final-energy weighted (EU21):

| country | region | share of the region | region rank u, P&I / B&T |
|---|---|---:|---|
| Russia | REF | 73% | 1.00 / 1.00 (the most constrained) |
| Saudi Arabia | MEA | 20% | 0.68 / 0.58 |
| Indonesia | OAS | 18% | 0.78 / 0.46 |
| Argentina, Peru | LAM | 9% + 4% | 0.63 / 0.50 |
| Iceland | NEN | 8% | 0.01 / 0.00 (the least constrained) |

Russia dominates REF, the floor region in both sectors; Indonesia and Saudi Arabia raise OAS and MEA in power & industry
through the two artefacts; Iceland moves nothing.

**For the `v7` paper.** Disclosed in MODEL.md §3.4.3: country E is reported as tiers only (§3.4 already), and the two
artefacts (the linear fossil term at the low edge; the unidentified institution main effects and the interaction outside
the joint support) and the missing producer-interest measure are named.

## 2. Does the saturating form fix Iceland? No.

`X-1791 … satAP iw:fexp` (every actor-power term saturating, as `v6`) is in the `v7` search: it passes every gate, rank 56
(behind on the trend-share ordering; mean ΔR²(theory) 0.146 against 0.1445). Refitted:

| | selected (satInn) | twin (satAP) |
|---|---:|---:|
| power & industry logLik / buildings & transport logLik | −1265 / −529 | −1256 / −541 |
| Iceland E, power & industry (rank) | 0.33 (1) | 0.37 (4) |
| Russia E (rank) | 0.46 (5) | 0.33 (2) |
| Indonesia E (rank) | 0.33 (2) | 0.31 (1) |
| rank correlation of country E / of covered regional u | — | 0.97–0.98 / 0.99 |

Saturation $x/(x+\bar x)$ is steepest at zero and flattens above the median: it damps extrapolation into high values,
not at the low end where Iceland is. It moves Russia further down and fits buildings & transport worse. Not an
improvement. Iceland is an in-sample observation; its effect on the coupling is nil (NEN). Left as disclosed.

## 3. Fossil rents: the test

**The indicator.** World Bank WDI oil + gas + coal rents, % of GDP (`NY.GDP.PETR.RT.ZS`, `NY.GDP.NGAS.RT.ZS`,
`NY.GDP.COAL.RT.ZS`), log(1 + rents), held at 2021 (the series ends there), centred five-year mean. In the sample above
2%: Saudi Arabia 25%, Russia 16%, Norway 10%, Colombia 4.3%, Canada 3.7%, South Africa 2.9%, Indonesia 2.8%, Australia
2.8%, Mexico 2.2%. Correlation with fossil dependence 0.29–0.32, with fossil energy per person 0.17–0.18: a distinct
dimension.

**Two formulations**, both on the selected specification:

$$\text{A (add):}\quad \eta = \dots + \beta_{\text{rent}}A^{\text{rent}} + \textstyle\sum_{k}\delta_{\text{rent},k}A^{\text{rent}}\,k\,w \qquad(23\text{ slope terms})$$
$$\text{B (swap):}\quad A^{\text{rent}}\text{ in place of fossil energy per person}\qquad(19\text{ terms})$$

| | v7 | A: add | B: swap |
|---|---:|---:|---:|
| power & industry: logLik / BIC / γ | −1265 / 2699 / 0.998 | −1222 / 2639 / **1.000** | −1328 / 2824 / 0.988 |
| buildings & transport: logLik / BIC / γ | −529 / 1226 / 0.973 | **−430 / 1056** / 0.989 | −515 / 1198 / 0.970 |
| rents main effect, P&I (frontier; mean, *p*) | — | **+0.27; +0.23 (0.011)** | +0.21; +0.26 (0.011) |
| rents × GE / × RoL / × VerAcc, B&T (mean *p*) | — | +0.42 (<.001) / −0.74 (<.001) / +0.61 (0.038) | +0.38 / −0.71 / +0.71 (all < .01) |

- **Power & industry: the sign is against the theory.** Rents *raise* the ceiling (Norway, Canada, Australia: rent-rich
  democracies with strict policy), and γ reaches the boundary: the γ gate would reject A. The exporters do not get lower
  ceilings (Saudi Arabia E 0.55 → 0.52, Russia 0.46 → 0.49); Norway's ceiling rises (E 0.91 → 0.79).
- **Buildings & transport: a strong contingency.** The fit improves by 99 log-likelihood points; the rents effect runs
  through the institutions, as a conditional resource curse would (its sign set by accountability and state capacity on
  one side and rule of law on the other).
- **Reading.** Rents carry information the energy-system terms do not, but as a contingency, not as the producer-interest
  drag on the ceiling the exporters' cases suggested. In a `v8` sweep they would be an actor-power form for the theory
  gate (H1 would fail on the rents main effect in power & industry unless only the fossil-dependence term is read for H1,
  as now) and the γ gate to judge.

**The REMIND link.** Every run's gdx holds, per region, fuel and period, extraction `vm_fuExtr`, world prices `pm_pvp`,
extraction costs `vm_costFuEx` and GDP `vm_cesIO("inco")`:

$$\text{rents}_r(t) = \frac{\sum_f \big(p_f(t)\,\text{extraction}_{r,f}(t) - \text{cost}_{r,f}(t)\big)}{\text{GDP}_r(t)}$$

downscaled to countries with each country's share of its region's rents in the base year (as the energy system is), one
more series of the scenario panel, recomputed at every PFM call. On a 1000 Gt pathway extraction and prices fall, so rents
fall: a new endogenous channel, strongest in the Middle East and REF. Its direction on the ceiling follows the estimated
signs (§3), so it cannot be assumed to relax the constraint.

**Work.** An mrpfm reader (`readWDIRents`, `calcFossilRents`), the panel series, the scenario-side computation from the
gdx (`iamCalculatedDrivers`), a sweep with the two forms (most fits reuse the Fit Cache), the gates, a `v8` Run-Group and a
coupled batch.

## 4. Other candidates for `v8`

Ordered by what they would change in the coupled result.

1. **Persistence from the data.** The largest sensitivity of the headline is how long the limit lasts (κ, declared; the
   persistence ladder spans +19 to +221 Gt). The frontier robustness battery already estimates a time-decay model
   (Battese–Coelli 1992), whose η is a rate at which countries' slack shrinks: 0.156 a year (power & industry), 0.113
   (buildings & transport), against a declared central κ of 0.027. But on that rung γ is low (0.06 / 0.22) and the slack
   ranks do not match the headline (0.03 / 0.66), so η is not yet an estimate of κ. A `v8` could fit a model that separates
   persistent from transient slack (a four-component stochastic frontier) and test whether the persistent part gives an
   empirical bound on κ. *Highest value: it addresses the assumption the result rests on most.*
2. **Fossil rents** (§3): a contingency in buildings & transport; against the theory in power & industry.
3. **The countries the sample never saw.** 154 of 200 uncovered countries in power & industry and 163 in buildings &
   transport are placed by a quantile rule, not a donor (MODEL.md §5.4); in `v6` this was the widest data-side band
   (+110 to +155 Gt). A `v8` could predict their E from their own drivers (a model of E on the drivers, in-sample) in place
   of the quantile rule.
4. **The unidentified institution main effects in power & industry** (negative on the frontier for state capability and
   accountability; behind the Saudi Arabia artefact, and behind the government-effectiveness sensitivity of 0008 §6).
   Options: a sign-restricted frontier, or interactions without main effects in power & industry (which breaks the
   shared-specification rule and needs an ADR).
5. **Policy need** (the Iceland case): the outcome scores instruments, not effort relative to the problem. A control for
   the sector's fossil exposure is largely collinear with fossil dependence; an outcome normalised by need would be a new
   data product. Low priority: no coupled effect found.
6. **The trend** (trend share 0.69 / 0.54 of the linear predictor): a common logistic time effect, frozen at 2023. A peer
   term (lagged leave-one-out mean stringency of other countries, international diffusion) would be a substantive driver
   in its place and could be fed from the coupled run; but it is nearly collinear with time and raises a reflection
   problem. Exploratory only.
7. **Data.** CAPMF and V-Dem editions with 2024; the WDI rents after 2021.

## 5. Proposed test order

1. Fossil rents through the sweep machinery offline: forms A and B with the theory and edge-of-data gates (§3).
2. The persistent / transient frontier on the `v7` panel: does it give a usable persistence rate (§4.1)?
3. The uncovered-country rule (§4.3): E predicted from drivers against the quantile rule, out of sample.
4. Then decide the `v8` specification and only then the cluster sweep.

## References

- Battese, G. E. & Coelli, T. J. Frontier production functions, technical efficiency and panel data. *J. Prod. Anal.* **3**,
  153–169 (1992).
- World Bank. World Development Indicators: total natural resources rents by type (oil, natural gas, coal), % of GDP.
