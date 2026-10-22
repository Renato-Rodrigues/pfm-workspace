# 0007 — Edge of the data: when a driver acts against the frontier's logic (evaluation for v7)

**Status: Open** — to be evaluated in `v7` (author, 2026-10-13). The `v6` baseline is measured; no option
is decided. Graduates into an ADR once `v7` picks an option.

**Provenance.** Run-Group `v6`, selected specification `X-1791 … bothIncAP lev … satAP`, frontier coefficients
held as estimated (nothing refitted). The scenario values are the coupled hold-the-price headline run
(`output/pfm/v6/coupling/scen-PFMlevelBfix-v6.rds`). Script `analysis/checks/edgeOfData.R`, artifact
`output/pfm/v6/edge-of-data.rds`, 2026-10-13. The script reproduces the model exactly: the 2023 ranking $u$ to 0,
and the strength $k(t)$ of the run in both sectors. Like every design note this is not authoritative: re-derive a
number from the artifact before quoting it.

## 1. What was found

The buildings & transport strength rises in the middle of the century (0.75 in 2040, 0.96 in 2060) where every
other region would loosen it. Without China it falls steadily (0.73, 0.57). The cause is China's ceiling, split
term by term (logit scale, `analysis/checks/edgeOfData.R`, same design matrix as `.pfmFrontierEta`):

| China, buildings & transport | 2025 | 2035 | 2050 | 2060 | 2100 |
|---|---|---|---|---|---|
| fossil and clean-energy terms (main effects) | +0.10 | +0.34 | +0.68 | +0.88 | +0.95 |
| interest × accountability terms | **+2.26** | **+2.55** | −0.52 | **−2.58** | −0.86 |
| everything else | −0.82 | −0.70 | +0.82 | +1.74 | +1.18 |
| ceiling (0–10) | 8.2 | 9.0 | 7.3 | 5.1 | 7.8 |

- **The main effects behave as the frontier is read.** As China's energy system becomes clean, they raise the
  ceiling.
- **The interaction terms override them.** China sits 4.1 standard deviations below the sample mean on vertical
  accountability, and Saudi Arabia 4.7 below; the next country is Russia, at 2.3. Because the interaction terms are
  linear in accountability, at China's value they reverse the fossil-dependence effect: +1.15 per SD against
  −0.15 at the sample centre.
- **The starting rank depends on the same terms.** China's high 2023 ceiling, and with it its place as the most
  constrained region in buildings & transport ($u = 1$), comes mostly from the +2.26.

The ceiling is read as "the most stringent policy that countries with similar institutions and interests have
sustained". For China and Saudi Arabia there are almost no similar countries, so their ceiling is a fitted value
carried to the edge of the data, not a comparison. The question is how often, and where, this happens.

## 2. The logic a result is checked against

Two references for each driver's direction:

| Driver | Theory (ADR 0056; D3.3 §3.2) | Sample centre, power & industry | Sample centre, buildings & transport |
|---|---|---|---|
| clean-energy build-out | + | − (n.s.) | + |
| fossil dependence | − | − | − |
| fossil interest per person | none (only the pair) | + | + |
| state capability | + | − | + |
| rule of law | + | + | − (p = .056) |
| vertical accountability | + | − | + |

In power & industry, three directions are already against theory at the sample centre: clean energy, state
capability and accountability. This is the known non-identification of the power & industry institution terms
(`MODEL.md` §3.3). Flags there are therefore model-wide, not edge effects. The edge question is where a country's
own values turn a direction that holds at the centre into its opposite.

## 3. The `v6` baseline

**Sample countries at the edge of the institution space** (Mahalanobis distance above the χ²₃ 0.99 quantile, or
fewer than 3 sample countries within 1.5 SD): Saudi Arabia (D 5.2), China (4.0), Turkey (3.7), Russia (2.9). Of the
248 countries the model assigns a ceiling to, 71 are at the edge, most of them without CAPMF data.

**Regions and drivers to watch** (EU21; the share of the region's final energy in countries where the driver works
against theory with an effect of at least 0.25 logit units by 2050 or 2100):

| Sector | Driver | Regions (share of final energy) | Edge of… |
|---|---|---|---|
| buildings & transport | fossil dependence | China 97%, Middle East 53%, Other Asia 28% | institutions (accountability) |
| buildings & transport | vertical accountability | China 97%, non-EU South Europe 90% (Turkey), Other Asia 37%, Middle East 25% | institutions |
| buildings & transport | rule of law | Russia & reforming 86%, Sub-Saharan Africa 63% | institutions and interests |
| power & industry | rule of law | India 100%, Sub-Saharan Africa 84%, Latin America 56%, Other Asia 52% | Sub-Saharan Africa: interests (very low fossil energy per person); India: neither — India is inside the sample, so the reversal is the interaction structure itself |
| power & industry | vertical accountability | China 97%, Russia & reforming 93%, Middle East 91%, non-EU South Europe 87% | institutions |
| power & industry | clean-energy build-out | most non-OECD regions (India, Russia, Turkey, China, Middle East 91–100%) | model-wide (centre sign already −) |
| power & industry | state capability | almost every region | model-wide (centre sign already −) |

At H12 the same regions appear (EUR stays clean; NEU carries Turkey).

**The largest single effects** are in power & industry, for countries without CAPMF data: rule of law in poor
countries with very low fossil energy per person (DR Congo, Haiti, Uganda, Cameroon …). Their effective slope is
−4 to −7 per SD, so SSP2's improving institutions lower their ceilings by up to 15 logit units by 2100. This is an
edge in the *interest* space (fossil interest per person far below the sample), not in institutions. It may
explain part of C3's finding that institutions alone tighten the power & industry constraint (k = 1.29 by 2100);
that link is not yet tested.

**Cap test** (the moderators inside the interaction terms capped at the sample's 5th–95th percentiles; main effects
untouched; observed 2023 policy fixed, borrowed efficiency fixed):

| | as run | capped |
|---|---|---|
| buildings & transport: China's rank $u$ (EU21 and H12) | 1.00 (most constrained) | **0.00 (least constrained)** |
| buildings & transport: strength 2040 / 2050 / 2060 / 2100 | 0.75 / 0.85 / 0.96 / 0.72 | 0.75 / 0.64 / 0.58 / 0.52 |
| power & industry: Middle East rank $u$ | 0.92 | 0.38 |
| power & industry: India rank $u$ | 1.00 (most constrained) | 0.84 (Russia & reforming becomes 1.00; 0.87 in the exact 2023 evaluation of §6) |
| power & industry: strength 2040 / 2050 / 2100 | 0.92 / 0.68 / 0.52 | 1.00 / 0.75 / 0.54 |

Among the regions inside the bulk of the data (the European regions, Japan, Canada/Australia/NZ, the United States)
the ordering within each sector keeps its order under the cap, apart from swaps between regions less than 0.05
apart. Their $u$ values shift mostly because the min–max normalisation loses China at the top.

**What this means for `v6`:**
- The buildings & transport time path, and China's buildings & transport rank, are edge effects. They are not
  reported as results (D3.3 v0.3 §4.4; the paper's Methods should say so).
- The power & industry ranks of the Middle East and India depend partly on the same terms; the hold-the-budget
  relocation onto China and away from the Middle East and India (0006 *Who abates*) should carry that caveat.
- The headline quantities move less, because they aggregate over all regions, but the cap test does not refit
  anything and is not a substitute for testing the options below.

## 4. Options for `v7`

| # | Option | What it does | Cost / risk |
|---|---|---|---|
| O1 | **Cap the moderators inside the interactions** at the bulk of the sample (5th–95th percentile, as in the test) | Stops linear interactions from reversing a driver beyond the data | Ad hoc limits; the capped region is treated as if it were at the edge of the bulk |
| O2 | **Cap the interest terms inside the interactions** in the same way (for the per-person fossil edge in poor countries) | The power & industry rule-of-law effect above | Same; interests also drive the endogenous strength, so cap only inside interactions |
| O3 | **Refit without China and Saudi Arabia together** (and with Turkey and Russia out) | Shows whether the interaction estimates are carried by the edge countries; the leave-one-out check drops one at a time only | Smaller sample; changes the selected specification |
| O4 | **An edge-of-data gate in the selection** (like ADR 0045's extrapolation gate): reject specifications whose drivers act against theory, beyond a threshold, in regions holding a material share of final energy | Chooses among the close competitors (9 pass every gate in `v6`; the selected one wins 15% of resamples among them) | Another gate; thresholds must be fixed before the results are seen |
| O5 | **Fewer interactions in buildings & transport** (no accountability interactions, or one institution per interest term) | Removes the terms that reverse | Loses the conditional effects the literature argues for |
| O6 | **Shrink the interactions** (penalised or hierarchical estimation) | Dampens extrapolation smoothly instead of a hard cap | A different estimator; the frontier machinery would need extending |
| O7 | **Treat edge countries like uncovered ones** for the ceiling's *movement*: hold their ceiling or borrow the trajectory of their nearest bulk neighbours | Keeps the observed 2023 position, removes the extrapolated dynamics | Removes the energy-system feedback for those countries |
| O8 | **Report only**: flag edge regions in every output (the D3.3 v0.3 minimum) | Honest, no model change | The ranking and the strength still carry the effect |
| O10 | **Regime split** (added 2026-10-13, §8): the interest × institution terms act in democracies only; autocracies get the main effects and their own level | Removes the extrapolation where it happens (the edge countries are autocracies) and keeps the conditional effects where they are estimated | A declared regime threshold; India, Hungary and Indonesia sit near it; regime status must be projected or held |
| O9 | **A production-based fossil interest** (added 2026-10-13, §7): fossil production or net exports per person or per GDP, from the IEA balances historically and from REMIND's extraction in scenarios | Measures the interest that exporters' consumption-based drivers miss | A new driver, so a new sweep; REMIND's extraction must be downscaled to countries |

## 5. The evaluation to run in `v7` (and on every later Run-Group)

1. **Run `analysis/checks/edgeOfData.R <group>`** on the selected specification, with the scenario panel of the
   coupled headline run (`analysis/v6/couplingMechanism.R <group>` builds it), at EU21 and H12. Before reading it,
   check that it reproduces the run: $u$ reproduced exactly and $k$ equal to the run's.
2. **Run it on every specification in the passing band** (the `v6` band is 9 specifications) and on the v7
   candidates for O3 and O5. The script reads drivers and interactions from the term names, so it needs no changes
   for another specification.
3. **Acceptance criteria**, declared before the `v7` results are read:
   - (a) no region in which countries holding 25% or more of its final energy have fossil dependence or clean-energy
     build-out acting against theory, with an effect of 0.25 logit units or more by 2050 or 2100, in a sector
     where the sample centre agrees with theory;
   - (b) the cap test moves no region's rank $u$ by more than 0.25, and the strength $k$ by less than 0.10 in
     2050 and 2100;
   - (c) both resolutions pass;
   - (d) every flag that remains is listed in the Methods, with its regions.
4. **If the selected specification fails,** test the options in this order: O4 (another specification from the
   band), O3, O5, then O1/O2 or O6. Rerun the coupled headline runs only for the option kept.
5. **Record the outcome** as an ADR, update `MODEL.md` §3 (what the ceiling means at the edge of the data) and §7
   (what must not be done), and close this note.

Re-estimating on new data (possible new CAPMF countries; Estonia once its oil shale is in the energy data, which is
after v7: ADR 0058) changes the sample and so the edge. Run the evaluation after every re-estimation, not once. Run `analysis/checks/edgeOptions.R <group>` with it
(§6): it tries the options on the selected model and gives the comparison to decide on.

## 6. The options tried on `v6` (2026-10-13)

`analysis/checks/edgeOptions.R v6` → `output/pfm/v6/edge-options.rds`. Offline: the frontier is refitted on the same
standardised estimation data (`frontier::sfa`, the selected formula; the plain refit reproduces `frontier.rds` to
1e-9). Every variant is scored by one evaluator that reproduces the run's ranking exactly. It reads the 2023 ranking
$u$ and the strength $k(t)$ on the coupled hold-the-price energy system. Countries without CAPMF data keep their
borrowed efficiency ratio, and covered countries keep their observed 2023 policy. Nothing is re-run in REMIND, so
the emission results of an option are not known; $k$ and $u$ are what the coupling would read.

EU21; "against" = regions failing criterion (a); "cap Δu / Δk" = criterion (b), the O1 cap applied on top.

| Variant | P&I: Spearman of u with v6 | P&I: k 2050 / 2100 | P&I: pass | B&T: Spearman | B&T: k 2040 / 2050 / 2060 / 2100 | B&T: China u | B&T: against | B&T: pass |
|---|---|---|---|---|---|---|---|---|
| v6 as selected | 1 | 0.68 / 0.52 | no (cap Δu 0.55: Middle East) | 1 | 0.75 / 0.85 / 0.96 / 0.72 | 1.00 | China, Middle East, Other Asia | no |
| O1 cap institutions | 0.85 | 0.75 / 0.54 | yes | 0.63 | 0.76 / 0.64 / 0.58 / 0.52 | 0.00 | — | yes |
| O2 cap institutions + interests | 0.89 | 0.71 / 0.38 | yes | 0.64 | 0.76 / 0.66 / 0.58 / 0.49 | 0.00 | — | yes |
| O6 interactions × 0.5 (proxy) | 0.85 | 0.59 / 0.37 | yes | 0.71 | 0.77 / 0.72 / 0.70 / 0.53 | 0.32 | China, Middle East | no |
| O7 edge countries frozen | 1 | 0.79 / 0.67 | yes | 1 | 0.88 / 0.82 / 0.78 / 0.75 | 1.00 | (unchanged) | no |
| O3a refit without China, Saudi Arabia | 0.98 | 0.84 / 0.68 | no | 0.64 | 0.93 / 0.88 / 0.83 / 0.59 | 0.05 | China, Middle East, Other Asia, SSA | no |
| O3b … and without Turkey, Russia | 0.95 | 0.95 / 0.81 | yes | 0.60 | 0.99 / 0.95 / 0.90 / 0.68 | 0.00 | + Russia & reforming | no |
| O5a no interactions | 0.54 | 0.93 / 0.83 | yes | 0.64 | 0.81 / 0.71 / 0.64 / 0.54 | 0.18 | — | yes |
| O5b no accountability terms | 0.82 | 1.30 / 1.36 | no (China, non-EU South Europe) | 0.68 | 0.63 / 0.48 / 0.41 / 0.49 | 0.55 | — | yes |
| E1 exporter terms (§7) | 0.99 | 0.71 / 0.53 | no | 0.87 | 1.03 / 1.14 / 1.17 / 0.99 | 0.68 | China, EU Central-East, Middle East, Other Asia, SSA | no |
| O4: the 8 other band specifications | 0.54–0.96 | 0.77–1.20 / 0.56–1.23 | none | 0.52–1.00 | — | 0.07–1.00 | every one fails | none |

H12 gives the same passes.

**What it says:**
- **Only the caps (O1, O2) and dropping all interactions (O5a) pass in both sectors.** O1 changes the model least: the
  power & industry strength moves from 0.68 to 0.75 in 2050 and stays at 0.54 in 2100, and the mid-century rise in
  buildings & transport disappears. The price is the ranking of three large regions: China in buildings &
  transport (1 → 0), and the Middle East (0.92 → 0.37) and India (1.00 → 0.87) in power & industry.
- **Refitting without the edge countries (O3) does not fix buildings & transport.** The accountability interaction
  keeps most of its size without them (−0.54 → −0.44 / −0.41) and is still applied at China's −4 SD. The problem is
  the extrapolation, not only the countries that are in the sample.
- **In power & industry the relaxation of the limit is partly carried by the edge countries.** Without China, Saudi
  Arabia, Turkey and Russia the 2050 strength is 0.95 instead of 0.68; with no interactions, 0.93; with the edge
  countries' ceilings frozen, 0.79. The caps keep it (0.71–0.75). This is the most consequential finding for the
  results, because the extra CO₂ under hold the price follows the strength.
- **No other specification of the band passes.** An edge-of-data gate (O4) would have to act inside the full sweep,
  not only on the band.
- **O5b (no accountability terms) reverses the power & industry strength** (1.30 in 2050): the band's known split on
  the direction of the power & industry constraint (`MODEL.md` §5.3.0) reappears.

**Suggested for `v7`** (to decide there, with the acceptance criteria fixed before the results; updated with §7–§8):
1. Adopt O1 as the minimum safeguard, and test its percentile bounds (2.5–97.5, 5–95, 10–90) as a declared
   sensitivity.
2. Add the edge criteria (a)–(b) to the specification sweep as a gate (O4 applied to all 7,296 candidates, not the
   band), and compare its winner with "selected + O1". Include the regime split (O10, §8) as a candidate design in
   that comparison, in its smooth form (A3, §8), which needs no threshold and keeps the power & industry ranking
   closest to `v6`.
3. Report O3b and O5a as sensitivities of the power & industry relaxation, with the coupled runs re-done for the
   option kept.
4. Develop O9 (§7) before adding any exporter term to the frontier. Exporter controls (E2–E4) do not address the
   edge problem.

## 7. Energy exporters

**Why they may differ.** The fossil-interest drivers are built from domestic energy use: primary energy shares,
the fossil share in industry, fossil energy per person. An exporter's fossil interest is mostly production and
export rent, which those drivers do not see.
- Norway, with an almost entirely hydro-based power system and large petroleum exports, looks "clean" to the model.
- Resource rents can weaken accountability and fund domestic fuel subsidies (the resource-curse and rentier-state
  literature, not yet appraised in the paper's notes), which would lower household-sector stringency.
- Domestic fossil use is an opportunity cost for an exporter, which can push the other way (subsidy reform to free up
  exports).
- In a decarbonising world exporters lose extraction rents. REMIND models that through extraction, but the drivers,
  which see only domestic use, do not.

**What the `v6` data show** (net energy exports above half of total supply, mean 2019–2023, IEA 2025 edition):
- **Exporters in the sample:** Australia, Canada, Colombia, Indonesia, Norway, Russia, Saudi Arabia. Saudi Arabia and
  Russia are also at the institutional edge, as are most of the uncovered exporters (Gulf states, Iraq, Libya,
  Venezuela, Nigeria, Angola, Turkmenistan …).
- **Power & industry:** exporters use less of their ceiling (median efficiency 0.60 against 0.74), with a wide spread
  (Norway 0.87, Canada 0.80, Colombia 0.81; Australia 0.55, Saudi Arabia 0.54, Indonesia 0.31). This fits a
  production interest the drivers miss, strongest where exports are coal or where institutions are weak.
- **Buildings & transport:** in the refit with exporter terms (E1), fossil dependence lowers the ceiling much more
  among exporters (exporter × fossil dependence −0.58; ML z −15, which overstates precision by about 2.4×).
- **The exporter terms absorb part of the edge effect, not most of it.** The fossil × accountability term moves from
  −0.54 to −0.41.
- **E1 as specified worsens the projection** (more regions against theory, a larger rise in buildings & transport).
  Exporter status is held fixed while the domestic fossil share falls, so it is not a usable option.

**Exporter status as a control** (a level shift of the ceiling, no interaction; each held at its 2019–2023 value):

| Variant | P&I: k 2050 / 2100 | P&I: pass | B&T: k 2050 / 2060 / 2100 | B&T: China u | B&T: pass | Coefficient (ML z) |
|---|---|---|---|---|---|---|
| E2 exporter dummy | 0.72 / 0.54 | no | 0.87 / 0.99 / 0.77 | 1.00 | no | P&I +0.26 (3.7), B&T +0.14 (3.1) |
| E3 net export ratio | 0.69 / 0.53 | no | 0.94 / 1.04 / 0.90 | 0.87 | no | P&I +0.09 (2.3), B&T +0.09 (8.8) |
| E4 fossil production per person | 0.95 / 0.57 | no | 0.87 / 0.98 / 0.74 | 1.00 | no | about 0 in both |

- **Controls cannot fix this problem.** The reversal is in the *slope* of a driver at extreme institutional values, and
  a control shifts only the *level*. The rise in buildings & transport stays (+0.19 to +0.22), and so do China's
  flags and the cap-test movement. As a level, exporter status is positive (exporters' ceilings sit higher
  given their drivers): it describes exporters, but it does not handle the edge.
- **E4 changes the power & industry path through the rest of the fit, not through its own term.** Its coefficient
  is about 0, but γ moves from 0.997 to 0.967 and the strength in 2050 goes to 0.95. The frontier is sensitive to
  small changes of design, which is itself a reason to choose a `v7` design by the full sweep, not by hand.

**The direction to develop is O9:** measure the production interest directly, with a projected counterpart from
REMIND's extraction, and test it in the sweep. Before relying on E1's buildings & transport term, check it by
dropping one exporter at a time.

## 8. Autocracy: regime type as a control or as a split (O10)

**Why.** The edge countries are autocracies. With autocracy defined as a V-Dem electoral democracy index
(`v2x_polyarchy`) below 0.5 (2019–2023 mean; the main threshold of the Regimes of the World classification), the
sample's autocracies are Saudi Arabia, China, Russia and Turkey (the four edge countries), plus India (0.40) and
Hungary (0.45). Of the 71 edge countries overall, 63 are autocracies; the other 8 are small territories with sparse
data. The interaction terms read "accountability moderates the power of interests", which is a mechanism of
electoral politics. Applying it, with linear extrapolation, to closed autocracies is where the reversals come from.
Regime type and exporter status overlap (Saudi Arabia, Russia; most uncovered Gulf states), consistent with the
rentier-state argument.

**Variants** (same offline evaluator as §6; autocracy status held at 2019–2023 in every projection year):
- **A1, autocracy as a control.** Does nothing for the edge, for the same reason as the exporter controls. In
  buildings & transport the level is positive (+0.18, ML z 3.7).
- **A2, regime split (O10).** The interest × institution terms are multiplied by "democracy" (1 − autocracy), so
  they act only where they are estimated from comparable countries. Autocracies keep the main effects and get their
  own level.

| A2 at threshold | Sample autocracies | P&I: Spearman of u with v6 (EU21 / H12) | P&I: k 2050 / 2100 | P&I: India u | B&T: Spearman (EU21 / H12) | B&T: k 2050 / 2060 / 2100 | B&T: China u | γ P&I / B&T | Pass |
|---|---|---|---|---|---|---|---|---|---|
| 0.35 | CHN RUS SAU TUR | 0.95 / 0.95 | 0.75 / 0.62 | 0.56 | 0.68 / 0.29 | 0.60 / 0.49 / 0.41 | 0.20 | 0.998 / 0.969 | all |
| 0.50 | + IND HUN | 0.70 / 0.50 | 0.71 / 0.45 | 0.00 | 0.66 / 0.21 | 0.61 / 0.53 / 0.43 | 0.25 | **0.999** / 0.972 | all |
| 0.60 | + IDN | 0.65 / 0.43 | 0.77 / 0.41 | 0.32 | 0.71 / 0.31 | 0.57 / 0.48 / 0.40 | 0.31 | 0.912 / 0.971 | all |
| v6 as selected | — | 1 | 0.68 / 0.52 | 1.00 | 1 | 0.85 / 0.96 / 0.72 | 1.00 | 0.997 / 0.972 | no |

**What it says:**
- **A2 passes every criterion at every threshold, in both sectors and at both resolutions.** The cap test moves
  nothing (Δu ≤ 0.03, Δk ≤ 0.04), because the extrapolation it tests no longer exists.
- **It keeps the power & industry relaxation.** The 2050 strength is 0.71–0.77, against 0.68 as run and 0.93–0.95
  for O3b and O5a.
- **It removes the buildings & transport rise.** The strength falls steadily to 0.40–0.43 by 2100.
- **Theoretically it is the most defensible option**: the conditional effect is kept where it was observed and not
  carried into regimes where the mechanism does not apply.
- **The interaction estimated on democracies stays strong** (P&I −0.49, B&T −0.37 for fossil × accountability; ML z
  −2.3 / −3.1).

**What it costs, and what must be settled before adopting it:**
- **The threshold matters for the regions near it.** The P&I ranking correlates 0.95 with v6 at 0.35 but 0.65–0.70 at
  0.5–0.6. India moves from the most constrained power & industry region (v6) to 0.56, 0.00 or 0.32 depending on the
  threshold, because India's index (0.40) lies between them. The threshold has to be declared before the results,
  with the other two as sensitivities, or replaced by a smooth weight (below).
- **At 0.5 the power & industry fit reaches γ = 0.999**, the boundary at which ADR 0046's gate rejects a
  specification. At 0.35 it does not (0.998).
- **H12 rankings move more than EU21** (Spearman 0.21–0.31 in buildings & transport), because the 12-region
  aggregates mix democracies and autocracies differently.
- **Few autocracies in the sample** (4–7 countries, about 90–160 country-years). Their own slopes cannot be
  estimated, only a level; the main effects are shared with democracies.
- **Regime status has to be projected.** Here it is held at 2019–2023. A `v7` version could derive it from the
  projected accountability path (the SSP institution projections the model already uses), or hold it and say so.

**Smooth weights, and weighting the accountability terms only (tested 2026-10-13,
`output/pfm/v6/edge-options-aut0.5-noband.rds`).**
- **A3**: every interest × institution term multiplied by the democracy index itself.
- **A4**: a soft step, the logistic of the index (midpoint 0.5, scale 0.1).
- **A5 / A6**: the smooth weight / the hard split on the *accountability* interactions only, so the state-capability
  and rule-of-law interactions act in every regime (a capable state can counter opposition in an autocracy too).

| Variant | P&I: Spearman (EU21 / H12) | P&I: k 2050 / 2100 | P&I: India u | B&T: Spearman (EU21 / H12) | B&T: k 2050 / 2060 / 2100 | B&T: China u | γ P&I | Pass |
|---|---|---|---|---|---|---|---|---|
| v6 as selected | 1 / 1 | 0.68 / 0.52 | 1.00 | 1 / 1 | 0.85 / 0.96 / 0.72 | 1.00 | 0.997 | no |
| A2 hard split (0.5) | 0.70 / 0.50 | 0.71 / 0.45 | 0.00 | 0.66 / 0.21 | 0.61 / 0.53 / 0.43 | 0.25 | 0.999 | all |
| **A3 smooth weight** | **0.96 / 0.91** | 0.83 / 0.60 | 0.51 | 0.68 / 0.27 | 0.62 / 0.54 / 0.45 | 0.24 | 0.998 | **all** |
| A4 soft step | 0.93 / 0.85 | 0.77 / 0.55 | 0.35 | 0.66 / 0.24 | 0.60 / 0.51 / 0.42 | 0.26 | 0.999 | all |
| A5 smooth, accountability only | 0.78 / 0.66 | **1.14 / 1.16** | 0.39 | 0.85 / 0.79 | 0.52 / 0.46 / 0.63 | 0.85 | 0.928 | P&I yes; B&T no (SSA) |
| A6 split, accountability only | 0.97 / 0.94 | 0.96 / 0.95 | 0.51 | 0.76 / 0.49 | 0.40 / 0.35 / 0.49 | 0.86 | 0.997 | P&I yes; B&T no at H12 |

- **A3 is the best of the regime options.**
  - It passes every criterion in both sectors at both resolutions, with no threshold to declare.
  - Its power & industry ranking stays closest to `v6` (Spearman 0.96 / 0.91).
  - Its γ (0.998) stays clear of the ADR 0046 boundary.
  - Its democracy-weighted terms are well estimated: fossil dependence × accountability −0.76 (ML z −3.2) in power &
    industry, −0.65 (z −6.0) in buildings & transport.
  - The cost: the power & industry relaxation is smaller (k 2050 0.83, against 0.68 as run). India and other
    middle regimes get partial interactions instead of a cut at a threshold.
- **Weighting the accountability terms only is theoretically appealing but fails.**
  - The state-capability and rule-of-law interactions then do the extrapolating instead. That is the edge in
    *interests*, where poor countries with very low fossil energy per person sit (§3).
  - The power & industry strength reverses (A5: 1.14 in 2050; A6: 0.96 with almost no relaxation), as when the
    accountability terms are dropped (O5b).
  - Buildings & transport fails in Sub-Saharan Africa (A5) or at H12 (A6).
  - The reversals are therefore not only an accountability problem. Every interaction is extrapolated where the
    sample has no comparable countries, so the weight has to act on all of them.

**Two more subsets, by institution (2026-10-21; same script and artifact, A7 and A8 added).** The theoretical case
for the weight differs by moderator (accountability: the mechanism is electoral and absent in closed autocracies; rule
of law: credible commitment and constraints on the executive, largely a liberal-democratic feature; state capability:
implementation and compensation, which a capable autocracy also has). Two cuts follow from it:
- **A7**: weight on the accountability and rule-of-law interactions; state capability acts in every regime.
- **A8**: weight on the accountability and state-capability interactions; rule of law acts in every regime.

| Variant | P&I: Spearman (EU21 / H12) | P&I: k 2050 / 2100 | B&T: Spearman (EU21 / H12) | B&T: k 2050 / 2060 / 2100 | B&T: China u | log-likelihood P&I / B&T | Pass |
|---|---|---|---|---|---|---|---|
| v6 as selected | 1 / 1 | 0.68 / 0.52 | 1 / 1 | 0.85 / 0.96 / 0.72 | 1.00 | −1256.2 / −503.8 | no |
| A3 all terms | 0.96 / 0.91 | 0.83 / 0.60 | 0.68 / 0.27 | 0.62 / 0.54 / 0.45 | 0.24 | −1255.4 / −554.9 | all |
| A7 accountability + rule of law | 0.65 / 0.62 | 0.50 / 0.23 | 0.71 / 0.36 | 0.76 / 0.75 / 0.75 | 0.35 | **−1384.0** / −545.1 | all |
| A8 accountability + state capability | 0.95 / 0.90 | **1.07 / 0.95** | 0.86 / 0.78 | 0.44 / 0.37 / 0.52 | 0.88 | −1286.1 / −510.8 | all |

- **A7's power & industry fit is not a maximum.** It nests a model with only the state-capability interactions, which
  nests O5a (−1365.4), yet it ends at −1384.0 (γ 0.964). A5 (−1396.9) has the same defect. The refits use one default
  start (`frontier::sfa`); both need a multi-start before their power & industry rows can be read.
- **A8 passes, and fits buildings & transport almost as v6** (−510.8 against −503.8; A3 −554.9). But its power &
  industry strength is above or near 1 (1.07 in 2050): the limit tightens instead of relaxing, the split already seen
  in O5b and A5 (`MODEL.md` §5.3.0). China keeps a high buildings & transport rank (0.88).
- **The direction of the power & industry constraint depends on whether the rule-of-law interactions are weighted.**
  Weighted (A3, A7): it relaxes. Unweighted (A5, A6, A8): it does not.

**Fit (log-likelihood, same estimation data; `edge-options-aut0.5-noband.rds`).**

| | P&I | B&T | parameters |
|---|---|---|---|
| v6 as selected | −1256.2 | −503.8 | 24 |
| A3 smooth weight | −1255.4 | **−554.9** | 24 |
| A2 hard split (0.5) | −1278.4 | −581.8 | 25 |
| A4 soft step | −1263.2 | −569.5 | 24 |
| O5a no interactions | −1365.4 | −631.0 | 15 |

The smooth weight fits power & industry as well as v6, but buildings & transport clearly worse: part of what the
unweighted interactions explain there is China's and Saudi Arabia's own observed policy. It recovers about three
fifths of the fit that dropping the interactions would lose. The trade, in-sample fit against a projection that does
not rest on extrapolated lines, is a judgement for `v7`, not a result. E4 (§7) ends below the model it extends
(P&I −1328.0 against −1256.2 with one more parameter): its optimisation did not reach the maximum, so its row is
unreliable.

The plain-language write-up of this note, with the comparison of the smooth weight against v6, is
`communication/edge-of-data/Edge-of-data-PFM.docx` (built by `build-edge-doc.R` from these artifacts).

**Other alternatives, not yet tested:**
- **Regime-specific caps**: O1 with its bounds taken from the democracies only.
- **A regime-type group effect** in place of the OECD/EU/other groups (`fe:` in the specification grammar), combined
  with the split. This is a sweep dimension, so it belongs in the gate comparison of suggestion 2.

Data: V-Dem v16 core (`v2x_polyarchy`), already in the sources the model reads; no new data are needed for A2 or
the smooth weight. The quick runs are `Rscript analysis/checks/edgeOptions.R v6 <threshold> noband` →
`output/pfm/v6/edge-options-aut<threshold>-noband.rds`.

## 9. Implementation for `v7` (2026-10-13)

The smooth democracy weight (O10) and the edge-of-data gate are in the code, switched on only for `v7`. Every group up
to v6 is unchanged.

**Data (`mrpfm`).** `readVDem` / `calcVDem` subtype `"democracy"` returns three V-Dem indices, the candidate weights:
`Electoral Democracy (VDem)` (`v2x_polyarchy`), `Liberal Democracy (VDem)` (`v2x_libdem`) and `Freedom of Expression
(VDem)` (`v2x_freexp_altinf`); the last two were added after the screen of §10 (2026-10-14). The default `"all"` set
is unchanged.

**Panels (`pfm`).**
- The panel definition has a new key, `democracy` (`pfmPanelDef`; off by default). It is carried into SLURM jobs
  (`startRun`), `pfmRun`, `iterativePFM` and `pfmPrepareCache`.
- When the key is on, `panelDataHistorical` adds the index on its own 0–1 scale (interpolated, gaps filled with
  medians, not min–max normalised).
- `panelDataScenario` holds it at its last observed value in every scenario year (a declared rule: no regime path is
  projected).

**The specification.**
- A spec field, `interactionWeight` (e.g. `"Electoral Democracy (VDem)"`), reaches the estimator through
  `.pfmSpecArgs`. It is also passed explicitly at the five calls that list the spec's fields by hand (the sweep's fit
  grid, the sanity projection, `projectFeasiblePath`, the donor assignment and the ECM path).
- `preparePanelData` reads the weight with the drivers' one-year lag and multiplies every actor-power × institution
  interaction by it.
- It records the weight on the frozen `driverScaling` as an attribute, so every projection that passes
  `driverScaling = fit$driverScaling` applies it unchanged. `.pfmDriverGuard` keeps the weight when it rebuilds the
  interactions.
- The fit-cache key gains `+iw:<weight>`.

**The search.**
- `pfmSpecs(interactionWeights = ...)` appends a weighted twin of every spec with interactions, one per listed weight
  (suffix ` iw:poly`, ` iw:libdem` or ` iw:fexp`).
  Selection then chooses between weighted and unweighted forms like any other dimension.
- `runPFMSweep` takes `interactionWeights` and `edgeGate`, passes the gate to both sanity walks (the tier-relaxed
  one too) and records both in `manifest.json` (`sweepOptions`). `runPFMSanityPool` reads the record.
- `config.yml` carries both for `v7` only (`panel: groups: v7`, `sweep: groups: v7`).

**The gate.**
- `.pfmEdgeGate` (`R/pfmEdgeGate.R`) implements §5 criteria (a) direction and (b) cap shift.
- It runs on the frontier fit the sanity walk already makes for the ceiling-collapse and γ gates
  (`.pfmCeilingTrajectory`), so it costs no extra fit.
- It flags `edgeOfData` (severe). The thresholds are declared in `config.yml` (`edgeGate`): share 0.25, effect 0.25,
  cap shift 0.5 logit, cap 5–95%, regions of `regionmapping_21_EU11.csv`.

**Tests.** `tests/testthat/test-interactionWeight.R` covers:
- the weighted interactions in fit and apply mode;
- the guard;
- the spec twins;
- option parsing;
- the panel key;
- the gate on a toy case.

The whole `pfm` suite passes (458 tests, 2026-10-13).

**End-to-end check on v6's data** (`analysis/checks/edgeGateValidation.R` → `output/pfm/v6/edge-gate-validation.rds`):
- **Index (2023):** China 0.074, Saudi Arabia 0.014, Russia 0.19, India 0.374, Hungary 0.434, Germany 0.855, USA 0.857.
- **Historical panel, rebuilt with the key on:** identical to v6's training panel on its 49 columns (largest
  difference 2e-16), plus the index. The scenario panel holds the index (China 0.073 → 0.072).
- **Selected v6 spec, refitted through the new code:** reproduces v6 (n 1104, γ 0.9968, log-likelihood −1256.2).

The gate, on the coupled hold-the-price energy system:

| | power & industry | buildings & transport |
|---|---|---|
| v6 as selected | **fails**: cap shift 0.56 (Middle East) > 0.5 | **fails**: China, Middle East, Other Asia against expectation; cap shift 1.25 (China) |
| its democracy-weighted twin | **passes** (cap shift 0.19) | **passes** (cap shift 0.09) |
| twin: γ / log-likelihood | 0.9836 / −1312.4 (v6 −1256.2) | 0.9719 / −555.2 (v6 −503.8) |
| twin: fossil dependence × accountability | −0.99 (v6 −0.33) | −0.64 (v6 −0.54) |

The package's twin differs from the offline A3 of §8 in one respect: it reads the index **year by year** (lagged,
smoothed like the other drivers). The offline A3 held the 2019–2023 mean. Within history, the declines in Hungary,
Turkey and India therefore enter the fit, and power & industry fits worse (−1312.4 against −1255.4 offline). Which
form v7 keeps is part of the decision. A constant-weight variant would be one more spec field, not implemented yet.

**The weight's scope, A7 as an alternative configuration (2026-10-21).** A weight name may end in `@accRoL`
(`"Liberal Democracy (VDem)@accRoL"`): only the accountability and rule-of-law interactions are weighted, and the
state-capability interactions act in every regime (A7 of §8). The scope travels in the name, so the spec field, the
fit-cache key (`+iw:Liberal.Democracy..VDem..accRoL`) and the frozen `driverScaling` carry it unchanged.
`preparePanelData`, `.pfmDriverGuard` and `.pfmEdgeGate` read it through `.pfmIwFactor` (`R/pfmInteractionWeight.R`).
Twins are suffixed ` iw:fexp@accRoL`. A scoped twin is added only to specs that interact with state capability and
with accountability or rule of law; elsewhere it repeats the unweighted spec or the A3 twin. Tests:
`test-interactionWeight.R` (the whole suite passes, 2026-10-21).

**The v7 search (author, 2026-10-21):** weights freedom of expression and electoral democracy (liberal democracy
dropped), each in scope A3 and A7; overall accountability as a fifth accountability option; the gate at the values of
§9. 36,384 specs, 5.0 times v6's 7,296.

**A7 through the package** (`edgeGateValidation.R v6`, section 4: the selected spec, year-by-year index, refitted by
`estimatePolicyStringencyModel` and gated by the sanity walk; `output/pfm/v6/edge-gate-validation.rds`, 2026-10-21):

| Weight | log-likelihood P&I / B&T (v6 −1256.2 / −503.8) | Gate P&I | Gate B&T (cap shift) |
|---|---|---|---|
| freedom of expression, A3 | −1254.6 / −543.3 | pass (0.22) | pass (0.08) |
| freedom of expression, A7 | −1263.9 / **−539.1** | **fail**: clean energy against expectation in IND, LAM, OAS | pass (0.24) |
| electoral democracy, A3 | −1312.4 / −555.2 | pass (0.19) | pass (0.09) |
| electoral democracy, A7 | **−1266.6** / −546.5 | pass (0.26) | pass (0.26) |

- The package reaches a proper optimum for A7 (−1264 / −1267 in power & industry), unlike the offline refit of §8
  (−1384): that row was an optimisation failure, not a property of A7.
- With electoral democracy, A7 fits power & industry 46 points better than A3 and passes the gate in both sectors.
- With freedom of expression, A7 fits buildings & transport best of the four but fails the power & industry gate on
  clean-energy build-out (now unweighted in its state-capability interaction).

**How to run the v7 search:** `docs/RUNNING.md`, Step 6a.

## 10. Other V-Dem indicators: a screen (2026-10-13)

`analysis/checks/vdemScreen.R v6` → `output/pfm/v6/vdem-screen.rds`. 27 V-Dem v16 indicators were declared with a role
before any result was read:
- 12 democracy and accountability indices replacing vertical accountability;
- 5 administration and corruption indicators replacing state capability (WGI);
- 7 political-economy-of-distribution indicators replacing vertical accountability (clientelism, particularistic vs
  public-goods spending, party linkages, universalism, socio-economic exclusion, party institutionalisation,
  equal distribution of resources);
- 7 bounded indices as the interaction weight.

Each variant is the selected specification with that one change, refitted as a frontier and scored by the sanity
walk's ceiling trajectory with the edge gate at its defaults, on the coupled hold-the-price energy system. These are
single-change variants of the selected specification, not a new search.

**Where China and Saudi Arabia sit** (SD on the 48-country sample, 2023):
- **Every democracy or accountability index** puts both at −2.2 to −3.5, with 0–3 sample neighbours. These indices
  correlate 0.79–0.96 with vertical accountability. Swapping one for another keeps the edge.
- **The indicators on which China is not at the edge** are corruption (+1.2), clientelism (−0.1), party linkages
  (0.0), particularistic spending (+0.1), universalism (−1.0) and impartial administration (−1.6, 11 neighbours).
- Saudi Arabia is still extreme on some of these (party institutionalisation −4.3).

**Replacing a channel: no indicator works.**

| Family | Δ log-likelihood P&I / B&T | Edge gate |
|---|---|---|
| other accountability / democracy indices for vertical accountability | −122 to +32 / −37 to +1 | fails in both sectors, every one; cap shifts up to 11.5 |
| administration / corruption for state capability | −70 to +5 / −43 to +3 | fails in both sectors |
| political-economy indicators for vertical accountability | −153 to −39 / −24 to +18 | fails in both sectors |

Even where China is not at the edge of the swapped indicator, the gate still fails, because the other interactions
(rule of law: China −2.9 SD) still extrapolate. The selected channels fit best overall. **The edge problem belongs to
the interaction structure, not to one indicator.**

**As the interaction weight: several indices pass, and two fit better than the electoral democracy index.**

| Weight (every interaction × index) | Δ log-likelihood P&I / B&T | Gate P&I / B&T (cap shift) |
|---|---|---|
| electoral democracy (`v2x_polyarchy`, implemented) | −56.5 / −51.6 | pass / pass (0.20 / 0.10) |
| **freedom of expression and alternative information** (`v2x_freexp_altinf`) | **+0.8 / −39.9** | pass / pass (0.23 / 0.08) |
| **liberal democracy** (`v2x_libdem`) | **+1.1 / −50.3** | pass / pass (0.28 / 0.06) |
| clean elections (`v2xel_frefair`) | +0.9 / −59.6 | pass / pass (0.27 / 0.09) |
| regime class (`v2x_regime` / 3) | −63.7 / −66.1 | pass / pass (0.25 / 0.08) |
| civil liberties (`v2x_civlib`) | +4.3 / −23.7 | pass / **fail** (China, Middle East) |
| participatory democracy (`v2x_partipdem`) | −0.2 / −48.6 | fail (one region) / fail |

Freedom of expression and liberal democracy pass the gate in both sectors and keep the power & industry fit of v6,
which the electoral democracy weight loses (−56.5). Freedom of expression also loses the least in buildings &
transport. Reading: the moderation of interest power by institutions works through what citizens and media can say
and know (freedom of expression and alternative information) or through constraints on the executive (liberal
democracy), more than through elections alone.

**For v7:**
- Add `v2x_freexp_altinf` and `v2x_libdem` to the weights the search can choose from (`interactionWeights`). That
  needs them in the `mrpfm` `democracy` subtype and in the panels, as the electoral democracy index already is.
  **Done 2026-10-14**: both are in the subtype and the panels, and `config.yml` lists both for `v7` (author: keep both
  as alternatives, decide later or let the search choose). Electoral democracy stays available but is not listed.
- Each weight adds one twin of every specification with interactions: two weights make the grid about three times
  v6's, one about twice.

**Through the package** (`edgeGateValidation.R v6`, year-by-year index as the panels build it, not the moving average
above; `output/pfm/v6/edge-gate-validation.rds`):

| Weight | log-likelihood P&I / B&T (v6 −1256.2 / −503.8) | Gate P&I / B&T (cap shift) |
|---|---|---|
| electoral democracy | −1312.4 / −555.2 | pass / pass (0.19 / 0.09) |
| liberal democracy | −1254.4 / −553.9 | pass / pass (0.28 / 0.06) |
| freedom of expression | −1254.6 / −543.3 | pass / pass (0.22 / 0.08) |
| none (v6 as selected) | — | fail / fail (0.56 / 1.25; B&T also direction in CHA, MEA, OAS) |

The screen's ranking holds. The existing panel columns are unchanged (max difference 2e-16).

Caveats:
- ML z values overstate precision (about 2.2–2.4×).
- The index is a 5-year moving average from the raw V-Dem file here, not the panel builder's.
- The political-economy indicators were tested only as replacements, not as additions.

## 11. Overall accountability as a fifth accountability option (2026-10-14)

Why: the PoliClim institution projections (IDOS) use V-Dem's overall accountability (`v2x_accountability_osp`), and
the v6 bootstrap does not settle the accountability slot (vertical 61%, horizontal 26%, diagonal 14%).
`communication/institutional-indicators/` compares both indicator sets; `analysis/checks/policlimFormulation.R` →
`output/pfm/v6/policlim-formulation.rds`.

**Implemented** (off for every group up to v6; v6 is reproduced):
- `mrpfm`: `calcVDem(subtype = "accountabilityOverall")` → "Overall Accountability (VDem)".
- `pfm`: panel key `overallAccountability`. The index enters both panels like the three parts: min-max normalised on
  the country range, and projected in scenarios by the `institutions` rule, then harmonised.
- Search: `extraAccountability = "OvAcc"` (sweep option; `channelSpecs`) appends the four institution sets with OvAcc,
  crossed exactly as VerAcc (base levels and hybridFD, context dummies, per-capita forms). The existing X-numbers are
  unchanged. With the weights, the grid is about 3.8 times v6's.
- Fixed on the way: `runPFMSweep` recorded only five panel-definition keys in `manifest.json`. A v7 manifest would
  have said `democracy: false`, and every stage after the sweep would have built panels without the weights. It now
  records every key, and the harmonisation's history-cache key carries the V-Dem keys when they are on.
- Tests: `test-overallAccountability.R` (`pfm`), `test-VDem.R` (`mrpfm`).
- `config.yml`: `panel: groups: v7: overallAccountability: true`; `sweep: groups: v7: extraAccountability: [OvAcc]`.

**Through the package** (`edgeGateValidation.R v6`, section 5; the selected spec with OvAcc in place of vertical
accountability, on the sweep panel, where OvAcc follows the storyline rule; `output/pfm/v6/edge-gate-validation.rds`):

| Variant | log-likelihood P&I / B&T (v6 −1256.2 / −503.8) | Gate P&I | Gate B&T |
|---|---|---|---|
| OvAcc, no weight | −1251.1 / −515.9 | fail (direction in 8 regions; cap shift 1.21) | fail (7 regions; 0.81) |
| OvAcc + liberal democracy | −1257.0 / −552.7 | fail (direction: MEA, 27%) | pass |
| OvAcc + freedom of expression | −1318.3 / −550.1 | pass | pass |
| OvAcc + electoral democracy | −1260.8 / −553.6 | fail (NES, REF) | fail (MEA, REF) |

Reading:
- The existing panel columns are unchanged (largest difference 2e-16).
- Overall accountability correlates 0.92 with vertical accountability in 2023.
- With the projected OvAcc, the power & industry gate fails on *direction*, where the held-index screen
  (`policlimFormulation.R`) failed only on the cap shift.
- The one P&I pass (with freedom of expression) comes from a worse optimum: γ 0.981, log-likelihood −1318. In the
  screen the same variant reached −1261.8; the covariance warnings point to a local optimum.
- The search will decide. On this evidence OvAcc rarely survives the gate in power & industry.

## 12. The first v7 sweep ran without the gate (2026-10-22)

Job 2663614 (`output/pfm/v7`, copy of its key files in `output/pfm/v7-run1-nogate/`): 36,384 specs, 72,768 fits,
every step `DONE`, selected **X-2929 WGIge|RoL|OvAcc splitAPpc lev ctl:GDPq.sq fe:OECDp satAP iw:poly** (electoral
democracy weight, every term weighted; overall accountability; per-person actor power, saturating). The walk
rejected nine `bothIncAP` candidates on actor-power extrapolation and one on ceiling collapse.

**The edge gate did not run.** The job script carried its thresholds as `c(0.25, 0.25, 0.5, c(0.05, 0.95), "...")`,
six unnamed strings (`.rlit`, `R/startRun.R`); `.pfmEdgeGate` errored, the error became `pass = NA`, and the walk
flagged only `pass = FALSE`. Fixed in `pfm` `e9fbd14`: lists are deparsed with their names, a requested gate that
cannot be evaluated is a severe flag, and `.pfmEdgeGate` refuses a gate that is not a named list.

**A second gap, fixed in the same commit.** Criterion (a) read only the share forms `Innovator.Power` and
`Incumbent.Power`; a `splitAPpc` spec, whose interests are measured per person only, was tested on the cap shift
alone. The criterion now reads an interest on its per-person form when the spec has no share form (next to the share
form the per-person fossil term still carries no expectation, §2).

**Preview of the gated verdict on the winner** (`analysis/checks/edgeGatePreview.R v7 v6`: v6 data with the V-Dem
keys, the sweep's gating scenario; `output/pfm/v7/edge-gate-preview.rds`):

| X-2929 | γ | ceiling 2100/2025 | gate |
|---|---|---|---|
| power & industry | 0.9963 | 0.951 | pass (cap shift 0.14) |
| buildings & transport | 0.9756 | 1.367 | **fail**: clean energy per person against expectation in CHA 97%, REF 89%, NES 87%, MEA 67%, SSA 42%, ECS 29%, OAS 26%; fossil per person in REF 86%, MEA 38% (cap shift 0.28) |

Under the per-person reading the winner fails; under the share-only reading it would pass (cap shift below 0.5).
The gated re-run selects again from the cached fits.

**The gated sweep (job 2664565, 2026-10-22; `pfm` `e9fbd14`).** The job script carries the gate as a named list; the
walk rejected two candidates on the edge (X-1794 `iw:fexp` and `iw:poly`, power & industry: clean energy against
expectation in ENC, NEN, LAM) and selected **X-2929 again**, passing the gate in both sectors. The preview's failure
in buildings & transport came from its data: rebuilt from the v6 cache, it halves the per-person main effects there
(clean energy +0.071 against +0.199 in v7's `frontier.rds`, fossil −0.066 against −0.152); with weaker main effects
the interactions reverse them in more regions. The v7 fit is the valid one.

X-2929 (`frontier.rds`, ML z in brackets; these overstate precision, §10):

| | clean energy pc | fossil pc | fossil pc × rule of law | fossil pc × overall accountability | γ |
|---|---|---|---|---|---|
| power & industry | +0.137 (1.5) | **+0.111** (1.7) | +1.454 (6.3) | −1.678 (−5.5) | 0.9961 |
| buildings & transport | +0.199 (3.6) | −0.152 (−3.4) | +0.671 (3.8) | −0.697 (−2.6) | 0.9730 |

In power & industry the fossil main effect is against theory at the sample centre (not significant), so the gate
treats it as model-wide and does not test its direction there (§2). `edgeOfData.R` and `edgeOptions.R` now read the
per-person forms and overall accountability, for the v7 checks.

## 13. v7 results before the downstream stages (2026-10-22)

Run-Group `v7` (job 2664565). Scripts: `analysis/checks/sweepOverview.R v7` → `output/pfm/v7/sweep-overview.rds`;
`analysis/checks/edgeGatePreview.R v7 v6 <specs>` → `output/pfm/v7/edge-gate-preview.rds` (on v7's own training
panel `87362d16967f873f`; it reproduces `frontier.rds` for X-2929, log-likelihood −1317.0 / −685.7).

**The grid.** 49 of the top 50 maximin ranks are weighted (freedom of expression 24, electoral democracy 25); A3 holds
47, A7 2; overall accountability is the most frequent accountability option there (28%). Every top-50 spec has both
state capability and rule of law. X-2929 is maximin rank 11: ranks 1–9 (`bothIncAP`, linear actor power) fail the
actor-power extrapolation gate, two of them also the edge gate; rank 10 fails ceiling collapse.

**Why X-2929 and not the weighted v6 spec.** Within the Green tier the maximin order sorts on `trendKey` (the
trend's share of the fit): X-2929 0.679, X-1791 `satAP iw:fexp` 0.713 (rank 56). The walk stops at the first pass,
so the saturating, weighted twins of v6's spec were not reached. Scored on the same panel and gate:

| Spec (all on v7's training panel) | maximin rank | log-likelihood P&I / B&T | gate P&I / B&T (cap shift) |
|---|---|---|---|
| **X-2929** OvAcc splitAPpc satAP iw:poly (selected) | 11 | −1317.0 / −685.7 | pass 0.14 / pass 0.26 |
| X-1791 VerAcc bothIncAP satInn iw:fexp | 18 | −1265.3 / −529.1 | pass 0.21 / pass 0.09 |
| X-1791 … satInc iw:fexp | 21 | −1259.0 / −541.1 | pass 0.31 / pass 0.09 |
| X-1791 … satAP iw:fexp | 56 | −1255.6 / −540.5 | pass 0.25 / pass 0.08 |
| X-1791 … satAP iw:poly | 75 | −1253.6 / −553.3 | pass 0.29 / pass 0.10 |
| X-1791 … satAP iw:fexp@accRoL (A7) | 112 | −1262.7 / −535.1 | pass 0.33 / **fail** (NEN, fossil 41%) |
| X-1791 … satAP (v6's spec, unweighted) | 100 | −1257.0 / −500.8 | **fail** 0.56 / **fail** (CHA, MEA, NEN, OAS; 1.29) |

The weighted v6 twins fit about 60 log-likelihood points better in power & industry and 145–160 better in buildings &
transport, and pass the gate; whether they pass the rest of the walk is not known (the actor-power extrapolation gate
passes saturating columns by construction). The selection followed the declared rule; preferring a twin by fit
would change the rule after seeing the results.

**The selected spec's evidence** (`inference.rds`, wild cluster bootstrap, 48 clusters; `influence.rds`, leave one
country out; `temporal-validation.rds`, trained to 2015):

| | v6 X-1791 | v7 X-2929 |
|---|---|---|
| frontier log-likelihood P&I / B&T | −1256.2 / −503.8 | −1317.0 / −685.7 |
| out-of-sample correlation P&I / B&T | 0.55 / 0.80 | 0.34 / 0.62 |
| historical replay RMSE P&I / B&T (gate) | 0.806 / 0.525 (pass) | 0.856 / 0.578 (pass) |
| B&T interest main effects, p (wild) | fossil share 0.006; clean 0.85 | fossil pc 0.88; clean pc 0.93 |
| B&T fossil × accountability, p (wild) | 0.000 (vertical) | 0.82 (overall) |
| P&I fossil × rule of law, p (wild) | 0.19 (share), 0.000 (pc) | 0.008 (pc); p ≤ 0.017 leaving out any one country |
| P&I fossil × accountability, p (wild) | 0.078 (share) | 0.032 (overall) |

In buildings & transport no interest or interest × institution term of X-2929 is significant except clean energy pc
× rule of law (p 0.045); China is the most influential country for most of them. The conditional mechanism is weaker
in v7's selected spec than in v6's.
