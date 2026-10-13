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

Re-estimating on new data (Estonia back in, `TODO.md`; possible new CAPMF countries) changes the sample and so the
edge. Run the evaluation after every re-estimation, not once. Run `analysis/checks/edgeOptions.R <group>` with it
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

**Suggested for `v7`** (to decide there, with the acceptance criteria fixed before the results):
1. Adopt O1 as the minimum safeguard, and test its percentile bounds (2.5–97.5, 5–95, 10–90) as a declared
   sensitivity.
2. Add the edge criteria (a)–(b) to the specification sweep as a gate (O4 applied to all 7,296 candidates, not the
   band), and compare its winner with "selected + O1".
3. Report O3b and O5a as sensitivities of the power & industry relaxation, with the coupled runs re-done for the
   option kept.
4. Develop O9 (§7) before adding any exporter term to the frontier.

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

**The direction to develop is O9:** measure the production interest directly, with a projected counterpart from
REMIND's extraction, and test it in the sweep. Before relying on E1's buildings & transport term, check it by
dropping one exporter at a time.
