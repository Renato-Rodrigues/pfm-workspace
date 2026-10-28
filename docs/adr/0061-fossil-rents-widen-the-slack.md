# ADR 0061 — Fossil rents set the size of the slack in buildings & transport, not the ceiling

- **Status:** **Proposed 2026-10-28.** For acceptance before the `v8` sweep. It extends ADR 0056's reading; it changes
  neither ADR 0056 nor the ceiling of ADR 0060.
- **Run-Groups:** `v8` (config.yml: panel key `fossilRents`, sweep `slackDrivers: {Diffuse: [Fossil Rents]}`). Every
  group up to `v7` is unchanged; their frontiers have no slack terms, and the coupling reads them as before.
- **Evidence:** design note 0009 §§3, 6.1, 8, 9, 10; `output/pfm/v7/` (`v8-rents-test.rds`, `v8-rents-gates.rds`,
  `v8-slack-determinants.rds`, `v8-het-slack.rds`, `v8-het-slack-cv.rds`, `v8-het-coupling-dryrun.rds`,
  `v8-rents-remind-vs-wdi.rds`). Every number below is from Run-Group `v7` and its coupled batch.

## Decision

1. **In buildings & transport, the size of the distance below the ceiling depends on fossil rents.** The frontier keeps
   its ceiling, and only the slack changes:
   $$y^{*}_{it} = \mathbf{x}_{it}'\boldsymbol\beta + v_{it} - u_{it},\qquad u_{it} \sim |N(0, \sigma_{u,it}^2)|,\qquad \log\sigma_{u,it} = c + w\,z_{it}$$
   - $z$ is the World Bank's oil, gas and coal rents, as $\log(1+\%\text{ of GDP})$, read with the drivers' one-year lag
     and standardised on the training rows.
   - With $w = 0$ this is the homoscedastic frontier of every earlier group.
2. **Power & industry keeps the homoscedastic slack.**
3. **Rents do not enter the ceiling, in any form.**
4. **In the coupling, a country's distance below its ceiling follows its rents.**
   $$q_c(t) = q_c\,e^{\,w\,(z_c(t) - z_{c,2023})}$$
   - $z_c(t)$ is the country's 2023 rents times its REMIND region's rents relative to 2025.
   - The regional rents are valued at the region's own primary-energy price.
   - The ratio is bounded to [0, 3].
   - A country without a rents series keeps its distance as anchored.
5. **The declared erosion κ and the persistence ladder stay as they are.** κ still stands for the channels the model does
   not measure (ADR 0056 §3). The rents channel is measured, so it is no longer part of what κ covers.

## Why this reading

ADR 0056 reads fossil dependence as a proxy for **structural power**: governments anticipate what would hurt a
dominant sector, and the frontier, a ceiling on what countries have sustained, is the natural place for it. Rents carry a
different claim. Producer interests that earn rents do not change what a country's institutions *could* carry; they hold
actual policy *below* it. This is in line with the rentier-state and oil-curse literature, in which resource revenue shapes what
governments choose to do with the capacity they have (Ross 2012). The data show it where pricing reaches consumers
directly, through fuel taxes and subsidies in buildings and transport. In the model, it is a statement about the slack,
not the ceiling.

## The evidence

**Rents in the ceiling contradict the theory (design note 0009 §§3, 6.1).** Four forms were tested: a fourth
actor-power term, a replacement for fossil interests per person, a continuous control, and an exporter dummy.

- **Power & industry:** rents *raise* the ceiling (+0.27 to +0.36). Rent-rich democracies (Norway, Canada, Australia)
  price strictly.
- **Gates:** γ reaches 1.000 in two forms, H1 fails in one, and the edge gate fails in two.
- **The exporter dummy:** passes every gate, but is zero in power & industry and moves no exporter's E.

**The slack form fits.** Heteroscedastic half-normal (Caudill, Ford & Gropper 1995), estimated together with the
ceiling (§8.2).

| | buildings & transport | power & industry |
|---|---|---|
| w, its *z* | **0.25, 10.8** | 0.11, 3.9 |
| gain in log-likelihood over v7 (1 parameter) | **85.1** (LR 170) | 8.2 (LR 16.5) |
| with the institutions also shaping the slack | rents 0.22, *z* 5.0 | rents −0.01 |
| exporter dummy instead | widens (+0.80) | **narrows (−0.30)** |

Power & industry gives no consistent answer.

**It predicts better out of sample, in buildings & transport only (§9.2).** Each covered country was left out and
predicted from a refit on the others:

| slack size on | buildings & transport | power & industry |
|---|---|---|
| rents | **better in 37 of 48** (*p* < 0.001) | 27 of 48 (*p* 0.47) |
| institutions | 29 of 48 (*p* 0.19) | 29 of 48 (*p* 0.19) |
| rents and institutions | 29 of 48; Saudi Arabia fails badly | 28 of 48 |

This is why the institutions stay out of the slack (Alternatives rejected).

**What it changes in 2023 (buildings & transport):**
- Saudi Arabia's share of the ceiling used falls from 0.94 to 0.72.
- In the EU21 ranking from the full anchor, MEA moves from 0.58 to 0.72, second after REF (§9.4).

## REMIND's rents are good enough for a ratio, not for a level (design note 0009 §10)

The coupling multiplies each country's World Bank rents by its REMIND region's rents relative to 2025, so it needs
REMIND's *path*, not its level.

- **Levels at the regional price are about half the World Bank's** for the exporters (MEA 9–10% against 17–25% of GDP in
  2010–2020; REF 5–6% against 8–13%). The regional price `pm_PEPrice` is the price inside the region, below the world
  price by the trade costs. For MEA oil in 2015 it was 6.25 $/GJ against 9.82 world.
- **GDP is on the same basis:** `vm_cesIO("inco")` matches the World Bank's market-exchange-rate GDP within about 5% for
  most regions. LAM, REF, IND and NES are 20–44% higher in 2020, which lowers their rent shares somewhat, but not the ratio
  the coupling uses.
- **At the world price the exporters match the World Bank from 2015 on:** MEA 18.2% and 16.7% against 17.7% and 16.6%
  (2015, 2020), REF 9.6% and 10.9% against 8.5% and 10.1%.
  - **Importers:** at the world price their rents turn noisy or negative (China −0.19%), and the US ratio swings to 6.
- **REMIND's historical periods do not reproduce price volatility** (the 2010–2014 boom). That does not matter here:
  REMIND's rents are used only after 2023.
- **The ranking across the 21 regions agrees:** rank correlation 0.86–0.94 (2010–2020) at the regional price.
- **The ratios the coupling uses barely depend on the valuation for the exporters.** MEA in 2050 is at 0.28 of 2025 at the
  regional price and 0.23 at the world price (coupled run); REF at 0.33 and 0.30; SSA at 0.11 and 0.12.

**Hence:** the regional price, which behaves for every region, with the world price as a sensitivity.

## Consequences

- **The exporters' constraint in buildings & transport fades for a measured reason.**
  - On the coupled 1000 Gt pathway, Saudi Arabia keeps 0.72 of its 2023 distance in 2050 and 0.45 in 2100.
  - The buildings & transport strength k falls to 0.40 in 2100 (v7: 0.49); power & industry is unchanged (dry run: slack
    only, EU21, θ 0.5, §9.4).
- **Part of the fading is not climate policy.** In the current-policy run MEA's rents also fall, to 0.50 of 2025 by 2050
  (0.28 on the 1000 Gt pathway): depletion and costs. The paper must not attribute the whole fading to mitigation.
- **With the common strength, an exporter's fading distance relaxes every region's constraint a little.** The regional
  strength (`pfmPhiStrength = regional`) keeps it with the exporter; it is the natural sensitivity for v8.
- **The institutions stay in the ceiling only.** The in-sample result that they also shape the slack (LR 194 in buildings &
  transport, 442 in power & industry) is reported as a diagnostic: γ near 1 hides a slack that is not homogeneous.
- **Disclosure:** rents enter as a share of GDP, a proxy for the resources of producer interests, not their political
  activity (as ADR 0056 says of actor power).
- **Code:**
  - pfm: `estimatePolicyStringencyModel(slackDrivers)` (class `pfmHetFrontier`), `.pfmCeilingBeta`, panel key
    `fossilRents`, `.pfmScenarioFossilRents`, the anchor's `slackShiftAnchor`.
  - mrpfm: `calcFossilRents` (source `WDIRents/wdi-fossil-rents.csv`, which must also be in the cluster's source folder).
- **If the `v8` sweep selects a specification whose buildings & transport slack weight is not significant (|z| < 2.58), or
  that loses the out-of-sample advantage, this ADR lapses.** v8 then runs without `slackDrivers`.

## Alternatives rejected

- **Rents in the ceiling** (four forms): against the theory in power & industry, γ at the boundary, gates failed (above).
- **Rents shifting the mean slack** (Battese & Coelli 1995): not identified on this panel. The coefficients run off to
  thousands, γ goes to 1, and countries land above their ceiling (design note 0009 §8.1).
- **Institutions in the slack:** better in sample, not out of sample, and they fail on Saudi Arabia with rents.
- **Rents in the power & industry slack:** no consistent sign (rents +, exporter dummy −), and no out-of-sample gain.
- **The world price for REMIND's rents:** right for exporters, misleading for importers. Kept as the sensitivity.
- **REMIND's rent levels instead of the World Bank's history times REMIND's ratio:** REMIND's levels at the regional price
  are about half the observed ones, and the frontier was estimated on the World Bank's.

## References

- Caudill, S. B., Ford, J. M. & Gropper, D. M. Frontier estimation and firm-specific inefficiency measures in the presence
  of heteroscedasticity. *J. Bus. Econ. Stat.* **13**, 105–111 (1995).
- Battese, G. E. & Coelli, T. J. A model for technical inefficiency effects in a stochastic frontier production function
  for panel data. *Empir. Econ.* **20**, 325–332 (1995).
- Ross, M. L. *The Oil Curse: How Petroleum Wealth Shapes the Development of Nations* (Princeton Univ. Press, 2012).
- World Bank. World Development Indicators: oil, natural gas and coal rents (% of GDP); GDP (current US$).
