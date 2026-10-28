# 0009 — v8 candidates: the countries at the edge, fossil rents, and what else the next version could represent

**Status: Partly decided 2026-10-27; v8 implemented 2026-10-28 (§9)** (§6.3 coverage rule, §6.2 κ reference; the other candidates open) — the author asked, before any new run or paper formulation, (1) why some
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

## 6. Results of the tests (2026-10-27)

All offline on the `v7` estimation panel; Run-Group `v7`.

### 6.1 Fossil rents through the gates, and rents as a control

`analysis/v8/rentsGates.R v7` → `output/pfm/v7/v8-rents-gates.rds`. The gates are applied as in the sweep
(config.yml `v7`): H1–H2 on the mean regression's coefficient table (`.pfmTheoryScreen`; asymptotic clustered *p*), and
γ ≤ 0.999, H3 ≥ 0.75 and the edge-of-data gate on the frontier (`.pfmCeilingTrajectory`). The scenario is the coupled
hold-the-price headline run (EU21, PkBudg1000), with rents after 2023 either held or linked to the run's REMIND rents
(`analysis/v8/_rents.R`). Two control forms were added to the two forms of §3: C, log(1 + rents) as a control (main effect
only); D, an exporter dummy (rents > 5% of GDP: Saudi Arabia, Russia, Norway).

| variant | H1–H2 | γ | H3 | edge (held / linked) | BIC, both sectors | passes |
|---|---|---|---|---|---:|---|
| v7 | ✓ | ✓ (0.998 / 0.973) | ✓ | ✓ / ✓ | 3925 | **yes** |
| A: rents an actor-power term | ✓ | ✗ (1.000 in P&I) | ✓ | ✗ / ✗ (B&T: clean energy against expectation in LAM 31%, fossil dependence in MEA 30%) | 3696 | no |
| B: rents in place of fossil per person | ✗ (H1 in P&I: fossil −0.34, *p* 0.19) | ✓ | ✓ | ✗ / ✗ (P&I: clean energy in CAZ 71%, ENC 33%) | 4022 | no |
| C: rents a control | ✓ | ✗ (1.000 in P&I) | ✓ | ✓ / ✓ | 3831 | no |
| D: exporter dummy a control | ✓ | ✓ | ✓ | ✓ / ✓ | 3889 | yes |

- **Controls do not carry the producer-interest effect either.** The continuous control is again *positive* in power &
  industry (frontier +0.36, *p* < 0.001; mean +0.24, *p* 0.001) and puts γ at the boundary. The exporter dummy passes every
  gate, but in power & industry it is zero on the frontier (+0.003, *p* 0.94; BIC 2706 against 2699) and leaves every
  exporter's E unchanged (Saudi Arabia 0.55, Russia 0.46, Norway 0.90). Its gain is in buildings & transport (BIC
  1226 → 1183; frontier +0.11, *p* < 0.001, mean +0.06, *p* 0.36). There it moves several regional ranks by up to 0.17
  (ESW 0.66 → 0.49, FRA 0.66 → 0.50), with no evidence in the mean regression.
- **The REMIND link barely matters.** Between held and linked rents the 2100/2025 ceiling ratio changes by at most 0.017
  (C: 1.210 → 1.193), and no gate verdict changes. The direction is the reverse of the producer-interest story: the
  estimated rents effect in power & industry is positive, so falling rents on a 1000 Gt pathway *lower* the ceilings
  slightly. The REMIND rents themselves are plausible: MEA 10.9% of GDP in 2025, 3.0% in 2050, 0.4% in 2100; REF 6.6, 2.2
  and 0.3%.
- **Conclusion.** No rents form both passes the gates and improves anything that matters for the coupling. The one form that
  passes (D) adds nothing where the extreme exporters are (power & industry). Fossil rents stay a disclosed omission
  (MODEL.md §3.4.3), not a `v8` term.

**A pitfall found on the way.** `.pfmEdgeGate` reads the final-energy weights with `pfmCouplingWeights()` inside a
`tryCatch`. Without the Run-Group's madrat cache (and `options(pfm.panel)`), the call fails, the weights are `NULL`, no
region is scored, and the gate *passes* with "cap shift 0". The first run of this test did exactly that for every variant,
`v7` included. The cluster sweep sets the cache, so `v7`'s selection is not affected. Any offline use must set it, as
`rentsGates.R` now does. Fixed 2026-10-27 (pfm): without weights the gate now returns pass `NA`, "edge gate not evaluable" with the reason, which the sanity walk treats as a severe flag, not a pass.

### 6.2 How long the limit lasts

`analysis/v8/persistentSlack.R v7` → `output/pfm/v7/v8-persistent-slack.rds`.

- **The four-component frontier does not identify persistent slack.** The country effects of the random-intercept step are
  skewed the wrong way for a one-sided term (skew +0.62 in P&I, +0.08 in B&T). The half-normal fit on them puts γ at 0.003 and
  0.015: the country effects are heterogeneity, and persistent slack cannot be told apart from it. The transient part is
  identified (γ 0.87 / 0.81, residual skew −1.50 / −3.44) and persistent from year to year (AR(1) 0.93 / 0.95). This is the
  known limit of the model class: persistent inefficiency and country heterogeneity are separated only by their assumed
  distributions.
- **The time-decay frontier (Battese & Coelli 1992)** gives η 0.156 / 0.113, but with γ 0.06 / 0.22 and slack ranks unrelated
  to the headline's (rank correlation 0.03 / 0.66). It is not a usable rate.
- **The direct counterpart of κ.** κ erodes the strength k (MODEL.md §5.2a), the size of the political differences, so its
  counterpart in the data is how fast the spread of the gaps g = 1 − E narrows:

  | | P&I | B&T |
  |---|---:|---:|
  | sd of country gaps, 2008 → 2023 | 0.188 → 0.154 | 0.186 → 0.099 |
  | yearly narrowing, countries, 2008–2023 / 2013–2023 | 1.1% / 1.4% | 4.6% / 3.7% |
  | yearly narrowing, EU21 regions (covered countries), 2008–2023 / 2013–2023 | 1.1% / 3.3% | 3.6% / −0.5% |
  | rank correlation of the gaps, 2013 → 2023: countries / regions | 0.66 / 0.85 | 0.36 / 0.15 |

  The spread narrowed by 1–5% a year. That brackets the declared κ (2%, 2.7% central) and lies below 5%. It is evidence
  against a constant or growing limit, not an estimate: it covers 15 years, CAPMF's early years, and 20 regions. Power &
  industry narrows more slowly than buildings & transport, so a sector-specific κ would be the data-consistent refinement
  (about 1–3% and 4%).
- **Positions churn faster than gaps close.** The pooled autocorrelation of the relative gaps at five years (0.45 / 0.56) would
  imply 12–16% a year. That reflects countries changing places, inflated by measurement noise, not the spread closing. It is
  not a κ.
- **For the paper.** The persistence ladder stays declared (ADR 0050). The Methods can add one sentence: "Between 2008 and
  2023 the cross-country spread of the distance below the ceiling narrowed by 1–5% a year (power & industry about 1%,
  buildings & transport about 4%), within the declared erosion range and against a constant limit."

### 6.3 The countries without CAPMF data

`analysis/v8/uncoveredRule.R v7` → `output/pfm/v7/v8-uncovered-rule.rds`. Each covered country in turn was treated as
uncovered. The rule reproduces the stored assignment exactly.

| E in 2023, predicted out of sample | MAE, P&I | MAE, B&T |
|---|---:|---:|
| the rule (donors / low band / median) | 0.151 | 0.087 |
| the covered median for everyone | 0.119 | 0.080 |
| the 3 nearest donors always | 0.154 | 0.091 |
| ridge regression on the base drivers | 0.126 | 0.082 |
| government effectiveness alone | **0.111** | **0.079** |

- **E is not predictable from the drivers** (rank correlations −0.66 to +0.29), and the donor transfer adds error. The
  frontier has already used what the drivers say; the distance below the ceiling is what they do not explain. The note in
  `computeDonorAssignment` already says this: "if it were [a function of the drivers], it would be predicted and would not
  need transferring."
- **Effect on the coupling.** With the covered median for every uncovered country, the EU21 regional ranking is nearly
  unchanged (rank correlation 1.00 P&I, 0.98 B&T; largest shifts OAS 0.78 → 0.66 and MEA 0.58 → 0.44). The ridge moves
  Sub-Saharan Africa from 0.48 to 0.98 in P&I: rejected.
- **Option for `v8`.** Replace the donor and band rule by the covered median (with the USA as now). It is simpler to state,
  better out of sample, and changes little. Cost: OAS and MEA move down by about 0.1, and the existing low-band sensitivity
  needs a new meaning (a low quantile for the countries below the covered range).

**Decided 2026-10-27 (author):** the covered median is the rule from `v8` (config.yml `coverage:`,
`computeDonorAssignment(rule = "median")`); the tested donor rule goes to the Supplementary Information (Note S-cov of the
paper outline). The historical reference for κ (§6.2) goes into the Methods (§7) and the Supplementary Information
(Note S-kappa); κ stays declared. MODEL.md §5.2a and §5.4 carry both.

### 6.4 What this leaves for `v8`

None of the tests yields a new driver. Two changes are supported, and neither needs a new sweep:

1. **The uncovered countries at the covered median** (§6.3): a change of the assignment, which only needs a new anchor and
   coupled runs.
2. **The persistence ladder, anchored**: the historical narrowing of the spread (§6.2) as a reported reference for κ;
   optionally sector-specific κ. A declared input, so it only needs coupled runs.

Fossil rents (§6.1), the saturating form (§2) and the persistent-slack frontier (§6.2) are not carried forward. The
remaining candidates (§4.4–4.7) are untested.

## 7. Quick tests for the extreme countries (2026-10-27)

Offline, on the `v7` panel; Run-Group `v7`.

### 7.1 Fixes in the form

`analysis/v8/edgeFixes.R v7` → `output/pfm/v7/v8-edge-fixes.rds`. The frontier was refitted with `frontier::sfa` on its
own prepared frame; the `v7` fit is reproduced (logLik −1265.3 / −529.1).

| variant | P&I: BIC (v7 2699) | B&T: BIC (v7 1226) | Iceland E, P&I | Russia E, P&I | Saudi Arabia E, P&I | regional u, rank correlation with v7 (P&I / B&T) |
|---|---:|---:|---:|---:|---:|---:|
| clip5: all base drivers clipped at the sample's 5th/95th percentiles | 2737 | 1318 | 0.43 | 0.23 | 0.61 | 0.72 / 0.89 |
| clip10: the same at the 10th/90th | 2798 | 1331 | 0.48 | 0.19 | 0.63 | 0.76 / 0.72 |
| **fosLow: the two fossil terms bounded below at their 5th percentile** | **2672** | **1220** | **0.40** | 0.46 | 0.54 | **0.98 / 1.00** |
| noInstMain: the three institution main effects dropped | 2741 (LR *p* 1e−13) | 1306 (*p* 1e−21) | 0.54 | 0.27 | 0.58 | 0.82 / 0.94 |
| noNegMain: only the negative institution main effects dropped | 2749 (*p* 1e−14) | 1221 (*p* 0.26) | 0.54 | 0.27 | 0.58 | 0.82 / 1.00 |

- **fosLow is the only variant that improves the fit in both sectors** (P&I ΔBIC −27, B&T −6). The fossil effect becomes
  stronger (P&I −0.55 → −0.70, *z* −9.1), H3 is 1.00 in both sectors, and Iceland moves from 0.33 to 0.40. The regional
  ranking is unchanged (0.98 / 1.00). Reading: the linear fossil term is mis-specified at the low edge. Below about the
  5th percentile, less fossil dependence no longer predicts a higher ceiling. It is the same edge logic as the driver
  guard, applied in the estimation.
- **Clipping every driver costs fit and reorders the regions.** It does not fix Indonesia (0.33 → 0.34) and makes Russia
  more extreme. Rejected.
- **The data reject dropping the institution main effects in power & industry** (LR *p* < 1e−13). Saudi Arabia barely
  moves (0.55 → 0.58). The Saudi case cannot be fixed by restricting the form; it stays disclosed. In buildings &
  transport the negative rule-of-law main effect can be dropped (*p* 0.26, BIC 1226 → 1221, u unchanged). That would
  break the shared-specification rule for a gain too small to matter.
- **Indonesia, Peru and Argentina are robust** to every variant (0.31–0.44). Their low E is not an artefact of one term
  that a restriction can remove.

**What fosLow would need for `v8`.** A lower bound on the fossil terms at the estimation sample's 5th percentile, recorded
in the driver scaling and applied identically in the scenarios. This is consequential: the driver guard would then hold a
country's fossil terms at that bound once its fossil dependence falls below it. On a 1000 Gt pathway most countries do so
in the second half of the century, so the ceiling would stop rising from decarbonisation earlier. That changes the strength
path $k(t)$, so a coupled test is needed before adoption. It is a transform option for the sweep (the gates re-run on it)
plus one coupled pair.

### 7.2 Fixes on the coupling side (no refit)

| option | regional u, rank correlation with v7 (P&I / B&T) | largest moves |
|---|---:|---|
| the anchor as the 2019–2023 mean of E (anchorMean) | 0.98 / 0.98 | P&I: MEA 0.77 → 1.00, REF 1.00 → 0.79 |
| country E floored at the covered 10th percentile (floorE) | 0.99 / 1.00 | P&I: MEA +0.11, ECE +0.10, OAS −0.12 |

Both change little overall. The five-year anchor swaps the most constrained region in power & industry, so it is not a
neutral smoothing. Neither is recommended.

### 7.3 How firmly the ranking is pinned down

`analysis/v8/rankingUncertainty.R v7` → `output/pfm/v7/v8-ranking-uncertainty.rds`: 1000 draws of the frontier
coefficients from their covariance.

- **Coefficient uncertainty is small.** The 90% bands of the extreme countries' E are narrow (Iceland 0.30–0.38, Indonesia
  0.31–0.36, Russia 0.39–0.56). Iceland, Indonesia, Peru and Argentina are among the five lowest in every draw, Russia in
  89%. REF is the most constrained region in 96% of draws (P&I) and 75% (B&T). The extremes are a matter of form (§7.1),
  not of imprecision.
- **Many regions rest on one covered country.** REF on Russia, MEA on Saudi Arabia (91% of its covered final energy), CHA,
  IND, SSA (South Africa) and NES (Turkey) on one country each. Leaving out the largest country moves OAS from 0.73 to 1.00
  (without Korea, Indonesia dominates) and MEA from 0.77 to 0.67 (P&I). With the covered median for the uncovered
  countries (§6.3), regions with little coverage (SSA 14% observed, MEA 22%, OAS 39%, LAM 41% of final energy) are pulled
  toward the median. The extreme countries then weigh less in their regions. This is the coverage rule's main effect on
  the extremes.

### 7.4 For `v8`

1. **Candidate: fosLow**, the lower bound on the fossil terms. It improves the fit in both sectors and removes part of the
   Iceland artefact, but it changes the late-century strength path, so it needs a sweep transform plus a coupled pair.
2. **Not fixable by form:** Saudi Arabia (the data keep the institution main effects), Russia (consistent with its drivers),
   Indonesia/Peru/Argentina (robust). They stay disclosed (MODEL.md §3.4.3). The covered-median rule already reduces their
   weight in the poorly covered regions.
3. **Report the single-country dependence** of each region's u (§7.3) with the coverage shares: it is the honest frame for
   REF, MEA, CHA, IND, SSA and NES.

**Implemented 2026-10-27 (author's request).** The fossil lower bound is the sweep option `fossilFloors` (pfm
`preparePanelData(fossilFloor)`). The bound is a training quantile, applied to the raw fossil terms before the transform,
frozen in `driverScaling` (`floor`) and so held in every projection; the fit-cache key carries it. Run-Group `v8` in
config.yml uses `fossilFloors: ["0.05"]` (every spec with a fossil term replaced by its bounded twin, suffix ` fos5`) and
`coverage: rule: median`. The package reproduces the offline result on `v7`'s spec (BIC 2671.9 / 1219.6; Iceland 0.40).
Its power & industry γ is 0.999004, just above the γ gate (0.999), so the `v8` sweep will not select `v7`'s spec: the
selection may move. No sweep has been run.

## 8. What explains the distance below the ceiling? (2026-10-27)

Offline, on the `v7` panel; Run-Group `v7`. The ceiling terms are unchanged; only the model of the slack $u \ge 0$ varies.

### 8.1 Slack whose mean depends on z (Battese & Coelli 1995): not identified

`analysis/v8/slackDeterminants.R v7` → `output/pfm/v7/v8-slack-determinants.rds` (`frontier::sfa`, `y ~ X | z`).

- **The z coefficients run off** (P&I: rents δ +1420 with intercept −11 217, *z* 0.89; exporter −2022, *z* −1.17;
  institutions δ in the hundreds, |*z*| < 1). γ goes to 1.000, and in buildings & transport several countries land above
  their ceiling (Norway, Canada, Colombia, Argentina: E 1.0–1.05). This is the known degeneracy of the mean-shift form when
  the slack is nearly the whole residual. Not usable.
- **One result that holds:** a truncated-normal slack (constant mean) fits much better than the half-normal (LR 300 P&I,
  138 B&T; *p* < 1e−30) and moves the ranking little (rank correlation 0.96 / 0.97). It already is the robustness
  battery's rung. A candidate sensitivity, not a change: in B&T it puts Norway at E 1.02.

### 8.2 Slack whose spread depends on z (Caudill, Ford & Gropper 1995)

`analysis/v8/hetSlack.R v7` → `output/pfm/v7/v8-het-slack.rds`. Maximum likelihood written in the script; the
homoscedastic fit reproduces the `v7` frontier (logLik −1265.3 / −529.1). $\log \sigma_{u,it} = c + z_{it}'w$; $w > 0$
means more slack where z is high.

| z | P&I: LR (df), w (*z*) | B&T: LR (df), w (*z*) | regional u, rank correlation with v7 (P&I / B&T) |
|---|---|---|---|
| rents | 16.5 (1), +0.11 (3.9) | **170.3 (1), +0.25 (10.8)** | 1.00 / 0.75 |
| exporter dummy | 11.8 (1), **−0.30** (−3.7) | 110.1 (1), +0.80 (8.6) | 0.99 / 0.90 |
| the three institutions | 442.2 (3): GE −0.83 (−16.8), RoL +0.58 (8.5), VerAcc −0.13 (−3.1) | 193.9 (3): GE −0.35, RoL +0.53, VerAcc −0.44 | 0.93 / 0.65 |
| rents and institutions | 442.3 (4): rents −0.01 (−0.2) | 219.6 (4): **rents +0.22 (5.1)** | 0.93 / 0.60 |

- **Buildings & transport: producer interests widen the slack.** It is the first form in which fossil rents act as the
  theory says (policy held below what the institutions allow, ADR 0056), and it survives the institutions. Saudi Arabia's
  E falls from 0.94 to 0.72, and MEA's u rises from 0.09 to 0.73. With the institutions also in, MEA becomes the most
  constrained region in buildings & transport (u 1.00).
- **Power & industry: no consistent rents effect** (rents +, exporter −, rents 0 with the institutions).
- **Institutions explain much of the spread of the slack** (LR 442 / 194): it is narrower where government
  effectiveness and accountability are high. The rule-of-law sign (+) mirrors its negative main effect in the ceiling. This
  is the institutions acting twice, in the ceiling and in the slack, which blurs the reading "the ceiling is what
  institutions allow". It is also what γ at 0.998 hides: the slack is not homogeneous.
- **For the coupling, an endogenous erosion.** With $\sigma_u$ depending on rents, a country's expected slack in a scenario
  scales as $\sigma_u(t)/\sigma_u(2023) = e^{w(z_t - z_{2023})}$. With rents linked to REMIND (they fall about 95% by 2100
  on the 1000 Gt pathway, §6.1), the exporters' limit in buildings & transport would fade at a rate set by the data, not
  declared.
- **What adoption would take.** A heteroscedastic frontier estimator in pfm. A decision on whether institutions enter the
  ceiling, the slack, or both (an ADR revising ADR 0056's reading). The anchor's hold rule changed from "keep the 2023 logit
  distance" to "scale it by $\sigma_u(t)/\sigma_u(2023)$". The rents series in the scenario panel. A sweep with the new
  estimator, then coupled runs. This is the largest change of the candidates, and the most substantive.

### 8.3 Done alongside

- **A separate fading rate for each sector (point 2): implemented.** The coupling's `kappa` takes one rate per sector
  (`pfmPhiKappa = "Bulk=0.011,Diffuse=0.046"` in a scenario row; pfm `.pfmKappaParse`), and the validator accepts it.
  Tested on the real v6 anchor. A coupled pair would test it; no row has been added.
- **Single-country dependence of the regional ranking (point 4): reported** in MODEL.md §5.4, with the 90% bands.

## 9. Iceland, the out-of-sample test, and the implementation (2026-10-28)

### 9.1 Should Iceland leave the estimation sample? No.

`analysis/v8/icelandExclusion.R v7` → `output/pfm/v7/v8-iceland-exclusion.rds` (the package's exclusion switch,
`options(pfm.excludeCountries)`).

| | P&I: γ | P&I: other countries' E, rank correlation / largest change | B&T: other countries' E | regional u, rank correlation (P&I / B&T) |
|---|---:|---|---|---:|
| v7 without Iceland | 0.9998 (v7 0.9984) | 0.990 / 0.05 (South Africa) | 0.991 / 0.04 (Russia) | 0.97 / 0.99 |
| with the fossil bound, without Iceland | **1.0000** (with Iceland 0.9990) | 0.987 / 0.04 | 0.993 / 0.04 | 0.99 / 0.99 |

Removing Iceland changes almost nothing for the other countries or the ranking (NEN stays at u ≈ 0 in power & industry).
It pushes the power & industry γ to the boundary, where the γ gate would reject the specification. Iceland is a genuine
observation: its low E reflects how the outcome is measured (few instruments are needed in an almost fully renewable
power system), not a data error. The fossil lower bound (§7.1) already treats the edge it sits on. Kept in, and disclosed
(MODEL.md §3.4.3).

### 9.2 Is the heteroscedastic slack a better model out of sample? Yes, in buildings & transport.

`analysis/v8/hetSlackCV.R v7` → `output/pfm/v7/v8-het-slack-cv.rds`. Each covered country left out in turn, every model
refitted on the others, scored by the log-likelihood of the left-out country's rows. A few countries that the v7
frontier itself cannot predict (P&I: Mexico, Slovenia, South Africa; B&T: Norway) dominate the sums by orders of
magnitude, so the comparison is per country:

| slack size on | P&I: better in / median gain | B&T: better in / median gain (sign test *p*) |
|---|---|---|
| rents | 27 of 48 / +0.8 (*p* 0.47) | **37 of 48 / +3.1 (*p* < 0.001)** |
| exporter dummy | 13 of 48 / −0.5 | 37 of 48 / +1.8 (*p* < 0.001) |
| the three institutions | 29 of 48 / +3.0 (*p* 0.19) | 29 of 48 / +1.9 (*p* 0.19) |
| rents and institutions | 28 of 48 / +2.8 | 29 of 48 / +1.7; Saudi Arabia −1693 |

The rents form is the one that generalises, in buildings & transport only. The institutions in the slack fit better in
sample (§8.2) but do not predict better, and with rents they fail on Saudi Arabia. **v8: rents, buildings & transport.**

### 9.3 Implemented (pfm, mrpfm, config.yml `v8`)

- **Data (mrpfm):** `downloadWDIRents` / `readWDIRents` / `convertWDIRents` / `calcFossilRents`. Oil + gas + coal rents,
  % of GDP, gaps interpolated, held after the last reported year (2021). The source file `WDIRents/wdi-fossil-rents.csv`
  was seeded on the workstation from the 2026-10-27 download; the cluster's source folder needs the same file.
- **Panels (pfm):** panel key `fossilRents` → `"Fossil Rents"`, log(1 + rents), moving-averaged like every column. In the
  scenario panel: history to 2023, then each country's last value times its REMIND region's rents relative to 2025
  (`.pfmREMINDFossilRents`, `.pfmScenarioFossilRents`; the ratio bounded to [0, 3]).
- **Estimator (pfm):** `estimatePolicyStringencyModel(slackDrivers = list(Diffuse = "Fossil Rents"))`, frontier only.
  The rents are read with the drivers' lag and standardised (frozen in `driverScaling`), but not put in the ceiling's
  formula. The likelihood is maximised from the homoscedastic fit (`.pfmHetFrontierFit`, class `pfmHetFrontier`). Its
  coefficients are the ceiling, `sigmaSq` / `gamma` at average rents, and `slack_(Intercept)`, `slack_Fossil.Rents`. Every
  reader of the ceiling drops the slack terms (`.pfmCeilingBeta`); the Jondrow decomposition uses each row's own slack
  scale. On `v7` the package reproduces the offline fit exactly (logLik −444.01, w 0.252, Saudi Arabia E 0.72).
- **Selection:** sweep option `slackDrivers` (by sector), carried on every spec, so every frontier fit (sanity walk,
  frontier step) uses it. The satP selection fits are unchanged.
- **Coupling:** the anchor keeps each country's 2023 slack shift $w'z$; the strength path scales the distance kept,
  $q_c(t) = q_c\,e^{w'(z_c(t) - z_{c,2023})}$ (logit hold). Groups without slack terms are unchanged.
- **Config:** `v8` = v7's panel + `fossilRents`, sweep + `fossilFloors: ["0.05"]` + `slackDrivers: {Diffuse: [Fossil
  Rents]}`, `coverage: rule: median`.

### 9.4 Dry run of the coupling (slack only)

`analysis/v8/hetCouplingDryRun.R v7` → `output/pfm/v7/v8-het-coupling-dryrun.rds`. The v7 spec with the heteroscedastic
B&T frontier, through `computeAnchorGap` and `pfmV6Shares`, on the coupled hold-the-price headline run (EU21, 1000 Gt,
θ 0.5). The fossil bound and the coverage rule are not applied.

| | 2050 | 2100 |
|---|---:|---:|
| B&T strength k, v7 / with the slack | 0.596 / 0.580 | 0.489 / 0.403 |
| P&I strength k (unchanged) | 0.706 | 0.666 |
| Saudi Arabia, distance kept relative to 2023 | 0.72 | 0.45 |

The B&T ranking moves: MEA from 0.58 to 0.72 (second after REF), and NES, ECS and ECE down by about 0.15–0.23. MEA's share in
2050 falls from 0.83 to 0.79. The regional strength (`pfmPhiStrength = regional`) gives MEA 0.81 in 2050 and 0.91 in 2100,
as its own gap closes.

**Not yet done:** the v8 madrat cache and the cluster source file; the v8 sweep (`pfmRun(group = "v8", stage = "all")`);
an ADR for the slack (it extends ADR 0056's reading: producer interests act on the distance below the ceiling in
buildings & transport); and the coupled runs.

## 10. REMIND's fossil rents against the World Bank's (2026-10-28)

`analysis/v8/rentsREMINDvsWDI.R v7` → `output/pfm/v7/v8-rents-remind-vs-wdi.rds`. REMIND's regional rents in the
current-policy run (historical periods 2005–2020) against the World Bank's, aggregated to EU21 with market-exchange-rate
GDP (3-year means). REMIND is valued two ways: at the region's own price (`pm_PEPrice`, as pfm uses) and at the world
price (`pm_pvp` of the fuel over `pm_pvp("good")`).

| % of GDP | 2010 | 2015 | 2020 |
|---|---|---|---|
| MEA: World Bank / REMIND regional price / REMIND world price | 25.1 / 9.4 / 16.3 | 17.7 / 9.3 / 18.2 | 16.6 / 9.9 / 16.7 |
| REF | 13.2 / 5.2 / 8.0 | 8.5 / 5.3 / 9.6 | 10.1 / 6.0 / 10.9 |
| SSA | 9.1 / 4.2 / 4.0 | 3.9 / 3.6 / 4.0 | 4.2 / 2.1 / 2.1 |
| world | 3.0 / 1.2 / 1.2 | 1.7 / 1.3 / 1.3 | 1.7 / 1.4 / 1.3 |
| rank correlation over 21 regions, regional / world price | 0.93 / 0.85 | 0.94 / 0.75 | 0.86 / 0.91 |

- **At the regional price, levels are about half the World Bank's for the exporters.** The regional price is the price
  inside the region, below the world price by the trade costs (MEA oil 2015: 6.25 against 9.82 $/GJ). GDP is not the
  cause: `vm_cesIO("inco")` matches market-exchange-rate GDP within about 5% for most regions.
- **At the world price, the exporters match from 2015 on.** Importers then turn noisy (China −0.19%), and the US ratio to
  2025 swings to 2–6.
- **REMIND's history is smooth.** It misses the 2010–2014 price boom; this does not matter, since REMIND is used only after
  2023.
- **The coupling uses each region's rents relative to 2025, and for the exporters this hardly depends on the valuation.**
  MEA in 2050 is at 0.28 (regional) and 0.23 (world) of 2025 on the coupled run; REF at 0.33 and 0.30; SSA at 0.11 and 0.12.
  The rents also fall without climate policy: MEA 0.50 by 2050 in the current-policy run.
- **Decision (ADR 0061):** keep the regional price (stable for every region), with the world price as the sensitivity, and
  the World Bank's levels times REMIND's ratio, never REMIND's levels.

## 11. Rents in both sectors' slack, for a single model form? (2026-10-28)

`analysis/v8/hetCouplingDryRun.R v7 Bulk,Diffuse` → `output/pfm/v7/v8-het-coupling-dryrun-Bulk-Diffuse.rds` (slack only,
EU21 hold the price, θ 0.5).

| | v7 | rents in B&T | rents in both |
|---|---:|---:|---:|
| P&I strength k, 2050 / 2100 | 0.706 / 0.666 | 0.706 / 0.666 | 0.661 / 0.591 |
| B&T strength k, 2050 / 2100 | 0.596 / 0.489 | 0.580 / 0.403 | 0.580 / 0.403 |
| Saudi Arabia, P&I distance kept, 2050 / 2100 | 1 / 1 | 1 / 1 | 0.87 / 0.71 |

- **The P&I ranking hardly moves** (rank correlation 0.99), **but the P&I constraint fades about a tenth more by 2100.** The
  P&I slack is wide (typical size e^0.38 = 1.46 against 0.58 in B&T), and REMIND's rents fall in almost every region, so
  the small weight (w = 0.11, *z* 3.9) shrinks many distances.
- **The evidence in P&I is weak:** no out-of-sample gain (27 of 48), the exporter dummy has the opposite sign, and the
  effect is gone with the institutions.
- **Decision (ADR 0061):** buildings & transport only in the central v8. "Rents in both" is a declared sensitivity pair.
  The estimator and the ceiling are shared; which sector's slack depends on rents is decided by the out-of-sample test.

## 12. The shape of the slack: truncated normal and exponential (2026-10-28)

`analysis/v8/truncSlack.R v7` → `output/pfm/v7/v8-trunc-slack.rds`. Scaling form (Wang & Schmidt 2002), $u = h\,u^*$,
$h = e^{c + wz}$, so the v8 coupling rule $q_c(t) = q_c e^{w(z_t - z_{2023})}$ stays exact whatever the shape of $u^*$.

| | P&I: in sample (LR vs half-normal) | P&I: out of sample, better in | B&T: in sample | B&T: out of sample, better in |
|---|---|---|---|---|
| truncated normal | 452.7 | 38 of 48 (*p* < 0.001) | 216.0 | 36 of 48 (*p* < 0.001) |
| truncated normal with rents, against half-normal with rents (v8) | | | 102.4 | 30 of 48 (*p* 0.11) |

- **The rents effect does not depend on the slack's shape:** w = 0.248 with the truncated normal, against 0.252.
- **The truncated normal is degenerate.** τ runs to about −200 and the scale to e^4–e^5: a normal truncated far in its tail,
  which is in effect an exponential slack (most countries near the ceiling, few far below). Its gain over the half-normal is
  the gain of that shape. With rents, it is no longer significant against the v8 form (30 of 48).
- **It changes the level of the ceiling:** country E rises (P&I: India 0.70 → 0.83, Germany 0.72 → 0.78; rank correlation
  0.95). In B&T, Norway and Iceland end up above their ceiling (E 1.03–1.04).
- **The exponential slack fitted directly** (Meeusen & van den Broeck 1977; stable form of the likelihood) reproduces the
  truncated normal exactly: logLik −1039 P&I, −421.1 / −392.8 B&T without / with rents. The degenerate truncated normal
  *is* the exponential.
  - Out of sample, the exponential is better than the half-normal (P&I 38 of 48; B&T 36 of 48).
  - Rents still help under it (34 of 48, *p* 0.006).
  - With rents, it is not significantly better than v8's half-normal with rents (30 of 48, *p* 0.11), and it puts Norway
    above its ceiling (E 1.04).
- **For v8: keep the half-normal.** The exponential is the robustness check of the slack's shape; the rents result holds
  under both.

## 13. The coefficient uncertainty in the coupling (2026-10-28)

`analysis/v8/couplingBand.R v7 500` → `output/pfm/v7/v8-coupling-band.rds`. 500 draws of the frontier's ceiling coefficients
from their covariance (`frontier.rds`). For each draw, the 2023 anchor is rebuilt (countries' distances and the ranking u),
then the strength and the shares on the coupled hold-the-price headline (EU21, θ 0.5, **common strength**). The central draw
reproduces the package's anchor exactly.

| | central | 5–95% band |
|---|---:|---|
| P&I strength k, 2050 / 2100 | 0.705 / 0.667 | 0.593–0.841 / 0.507–0.859 |
| B&T strength k, 2050 / 2100 | 0.596 / 0.489 | 0.518–0.675 / 0.421–0.557 |
| median width of a region's share φ in 2050: coefficients / θ 0.325–0.675 | | P&I 0.115 / 0.117; B&T 0.065 / 0.109 |

- **The coefficient uncertainty is as large as the declared severity θ in power & industry**, and about 60% of it in
  buildings & transport. It comes mostly from the strength path (how the drivers move the ceiling), less from the ranking
  (widest u bands: NES 0.03–0.33 P&I; China 0.18–0.49 B&T).
- **The draws are from the frontier's asymptotic covariance**, with γ near its boundary in power & industry (MODEL.md §3.4):
  an approximation, probably on the narrow side.
- **For the paper:** coefficient uncertainty belongs next to θ and κ, not in a footnote. Turning it into an emissions band
  needs coupled runs at the band's edges (e.g. the draws at the 5th and 95th percentile of the 2050 world share).
- **Under the regional strength** (v8's central form; `couplingBand.R v7 500 regional` → `v8-coupling-band-regional.rds`) the
  median widths of the regional shares are about the same: P&I 0.114 / 0.127 (2050 / 2100), B&T 0.068 / 0.069 (common: 0.115 /
  0.131, 0.065 / 0.053). Regions differ more: the US share in P&I spans 0.53–0.76 (as wide as its θ spread), REF's a third of its
  θ spread.

## 14. Newer data? None yet (2026-10-28)

- World Bank oil, gas and coal rents: still end in 2021 (checked through the WDI API).
- CAPMF: the OECD API returns no records from 2024; 2023 is the last year, so the anchor stays 2023.
- V-Dem v16 (data to 2025) and WGI 2025 (data to 2024) are already in the source folder.

## 15. Decisions of 2026-10-28 (author)

- Rents in the slack of **buildings & transport only** (§11); rents in both is a sensitivity.
- **The regional strength is the central coupling form of v8**; the common strength is its sensitivity pair
  (`analysis/run-groups/scenario-matrix-v8.yml`, first wave: no-politics references, both closures at three θ, the common-
  strength and world-price-rents pairs; 24 coupled rows over EU21 and H12; built and validated, not submitted).
- REMIND's rents valued at the region's price; the world price is the sensitivity (`pfmRentsPrice`, pfm `rentsPrice`).

## References

- Kumbhakar, S. C., Lien, G. & Hardaker, J. B. Technical efficiency in competing panel data models: a study of Norwegian
  grain farming. *J. Prod. Anal.* **41**, 321–337 (2014).
- Jondrow, J., Lovell, C. A. K., Materov, I. S. & Schmidt, P. On the estimation of technical inefficiency in the stochastic
  frontier production function model. *J. Econom.* **19**, 233–238 (1982).
- Battese, G. E. & Coelli, T. J. A model for technical inefficiency effects in a stochastic frontier production function
  for panel data. *Empir. Econ.* **20**, 325–332 (1995).
- Caudill, S. B., Ford, J. M. & Gropper, D. M. Frontier estimation and firm-specific inefficiency measures in the
  presence of heteroscedasticity. *J. Bus. Econ. Stat.* **13**, 105–111 (1995).
- Battese, G. E. & Coelli, T. J. Frontier production functions, technical efficiency and panel data. *J. Prod. Anal.* **3**,
  153–169 (1992).
- World Bank. World Development Indicators: total natural resources rents by type (oil, natural gas, coal), % of GDP.
