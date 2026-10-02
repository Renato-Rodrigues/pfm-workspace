# Data — sources, panel definition, projections and assumptions

*Every input the PFM reads, which edition of it, how far it reaches, how it is turned into the
panel, and how each series is projected into the future. Written to be the reference for the
paper's data section and SI, and for reproducing a Run-Group.*

**Provenance.** Coverage counts in §2 are read from the madrat cache Run-Group **`v5`** was fitted
on (`data/madrat/v5/`): for each cache file, the countries with any finite, non-zero value in
that year. The 2022/2023 completeness figures
in §4 are read from the IEA World Energy Balances 2025 edition raw files
(`<madrat sources>/IEA/IEA-Energy-Balances-2025/WBIG{1,2,3}.zip`), not from any Run-Group. SSP
coverage in §5 is read from the cached Andrijevic et al. extension (`convertSSPextensions`) and the
mrdrivers GDP/population caches. Re-read from those sources rather than copying numbers from here.

**Scope.** What goes into the panel and the scenario panel. What the model does with them is
`MODEL.md`. The coupling's own inputs (the REMIND gdx, the run folder's staged cache) are
`COUPLING.md`. Cache preparation is ADR 0047 and `RUNNING.md` step 2.

---

## 1. The pipeline in one paragraph

`mrpfm` (madrat) reads and converts each raw source to a country × year magpie object
(`read*` → `convert*` → `calc*`). `pfm::panelDataHistorical()` assembles the historical panel:
outcomes (Policy Stringency, effective carbon price), actor-power drivers built from energy data,
institution indices, controls; normalises each to [0, 1]; applies the moving average. The sweep
fits on that panel. `pfm::panelDataScenario()` builds the same variables for the future from a
REMIND gdx (energy), the SSP series (income, population, three governance indices, urbanisation,
inequality) and a declared rule (institutions with no SSP projection), and harmonises them to the
last historical panel year. The coupled run calls the same function on its own gdx at every
iteration.

## 2. Sources

| Block | Source (madrat type) | Edition in hand | Years | Countries with data 2022 / 2023 (v5 cache) | Enters as |
|---|---|---|---|---|---|
| **Outcome** | OECD CAPMF (`CAPMF` → `calcPolicyStringency`) | official database, downloaded June 2026 | 1990–2023 | 49 / 49 | Policy Stringency Bulk (mean of Electricity, Industry), Diffuse (Buildings, Transport); never imputed |
| Outcome (legacy, retired model) | World Bank Carbon Pricing Dashboard (`WBCarbonPricingDashboard` → `calcCarbonPrice`) | `data_2025.xlsx` | 1994–2025 | 45 / 45 | effective carbon price, Bulk / Diffuse; 2023 emission shares carried to 2024–25 |
| Energy (actor power) | IEA World Energy Balances via mrremind `calcPE`, `calcFE` | **2024 edition** (`ieaVersion = "default"`, complete to 2022) — v5; **2025 edition** (`"latest"`, complete to 2023) — v6 | 1960–2022 (2024 ed.) / –2023 (2025 ed.) | 208 / – (2024 ed.) | primary and final energy by carrier → innovator / incumbent power, energy intensity, hydro + nuclear share |
| Energy (electricity) | Ember yearly electricity data (`Ember`, `subtype = "generation"`) | cache to 2024 | 2000–2024 | 212 / 210 | wind, solar and total electricity generation |
| Institutions | World Bank WGI (`WGIindicator`) | 2025 release (`wgidataset_with_sourcedata-2025.xlsx`) | 1996–2024 | 249 / 249 | Government Effectiveness, Voice and Accountability, Political Stability, Regulatory Quality, Control of Corruption, Rule of Law |
| Institutions | V-Dem Country-Year Core (`VDem`) | **v16** (`V-Dem-CY-Core-v16.csv`) | 1789–2025 | 249 / 249 | Rule of Law, Vertical / Horizontal / Diagonal Accountability; state capacity (Policy Implementation, Absence of Corruption, Meritocracy, …) |
| Income, population | mrdrivers `GDP`, `Population` (WDI + UN WPP history, SSP projections) | mrdrivers 7.2.1 | 1960–2150 (history to 2023) | 249 / 249 | log GDP, log population, log GDP per capita, GDP per capita Q-centred |
| Area | FAO land area (`FAOLandArea`) | 2023 snapshot | time-invariant | — | log land area |
| SSP extensions | Andrijevic et al. (2020) and successors (`SSPextensions`) | `ssp-extensions_all_data.xlsx` (copy of Dec 2025) | 2000–2100 (cache to 2150, held) | 249 / 249 (after median fill, §5.3) | urban share, Gini, Gender Inequality Index (history and future); Government Effectiveness, Control of Corruption, Rule of Law (future) |

Not in the panel but read by the project: Climate-policy support (Vlasceanu et al. 2024, Andre et al.
2024; `ClimatePolicySupport`), OECD EPS (`OECD_EPS`, discontinued, 1990–2020; superseded by CAPMF),
OECD value added (`OECDValueAdded`, sector weights), EDGAR GHG (`EDGARghg`), Global Economy data.

**Rule of Law: V-Dem, not WGI.** The candidate set the sweep searches over uses the V-Dem Rule of
Law index. WGI Rule of Law is built and normalised but not a candidate (author's decision; it stays
so in v6). The `v5` deployed spec `X-2079 WGIge|noRoL|VerAcc …` carries no Rule-of-Law term at all.
Consequence for projections: the Rule of Law the sweep can pick has **no** SSP projection; it
follows the institution rule (§5.4), not the Andrijevic Rule-of-Law path.

## 3. The panel definition

Three settings decide what the historical panel *is*. They are a Run-Group property, resolved once
and recorded (`pfm::pfmPanelDef()`):

| | `v5` and earlier (legacy) | `v6` | `v6-annual` |
|---|---|---|---|
| years | 2000–2022 | **2000–2023** | 2000–2023 |
| moving average | centred, 5 years | centred, 5 years | **none (annual values)** |
| IEA edition | 2024 (`default`) | **2025 (`latest`)** | 2025 (`latest`) |

- **Where it is set.** `config.yml` → `panel:` (default for new groups, with `groups:` overrides).
  The sweep writes the effective definition into the group's `manifest.json` (`panel`). Every later
  step, the REMIND export and `iterativePFM()` read it from there. A group swept before the record
  existed (a `panel_hash` but no `panel`) is resolved to the legacy definition, so editing
  `config.yml` never changes `v5`. `pfmRun()` prints the definition and its source in the plan and
  carries it into SLURM jobs (`options(pfm.panel = …)` in the job script).
- **The moving average is applied to every panel series, outcomes included**, after normalisation.
  It is centred and shrinks at the edges (the 2022 value of `v5` is the mean of 2020–2022; the
  2023 value of `v6` the mean of 2021–2023), so no year is lost.
- **Why smoothed is the deployed fit and annual the sibling** (design note 0005 D3): the anchor
  reads the ranking in one year, and single-year CAPMF noise would enter it directly. `v6-annual`
  is the robustness rung: same candidate set, same selection, unsmoothed panel. It is a separate
  Run-Group, so it has its own panel hash, fit cache entries and manifest.
- **The scenario panel follows the group.** Its harmonisation (§5.5) is anchored on the last
  year of the group's own historical panel, built with the same definition. A smoothed fit
  harmonised to an annual anchor, or the reverse, would run without error and be wrong; the
  definition is therefore never passed by hand.
- **Training years.** The estimation sample is `v5`'s 2001–2022 (n = 1056 = 48 × 22, `MODEL.md`
  header); the first panel year is consumed by the lag. `v6` adds 2023.

## 4. Is 2023 complete? IEA 2025 edition, 2022 vs 2023

The 2025 edition is the first to carry 2023 for every country (its documentation: 1960–2023 OECD,
1971–2023 non-OECD, plus provisional 2024 for a few). The comparison below checks that 2023 is as
complete as 2022 *within the same edition*. Unit: non-zero KTOE cells (country × product × flow).

| check | result |
|---|---|
| countries (aggregates dropped) | 164; all 164 have total energy supply (TES) in both years |
| non-zero cells | 66 087 (2022) → 65 809 (2023): **99.58 %** |
| TES 2023 / 2022 | median 1.01; 5–95 %: 0.928–1.087 |
| World TES | +1.8 % |
| outliers | 1 country beyond −20 % / +25 % TES; 1 country losing > 10 % of its cells |

Both outliers are real events, not gaps:

- **Libya**, TES +74 %: crude-oil production recovers from the 2022 blockades (48.5 → 58.8 Mtoe) and
  the 2022 statistical difference (+8.0 Mtoe) disappears in 2023 (−0.01). Final consumption moves
  only +4.8 %.
- **New Zealand**, 507 → 453 cells: the Marsden Point refinery stopped refining in 2022. The missing
  2023 cells are refinery flows (refinery intake, transformation, refinery gas, feedstocks, some
  coal and lignite flows). TES −0.5 %, final consumption +0.1 %.

**Qualifier flags on the 2023 cells** (the IEA's SDMX-style "qualifier" column): A (observed)
7 457; I (imputed by the IEA, which *includes* aggregations and unit conversions, not only
estimates) 61 901; O (missing) 43 872; C (confidential) 447. No P (provisional) cells: 2023 is final
in this edition.

**Conclusion: 2023 is complete in the 2025 edition.** The other panel sources cover 2023 natively
(§2: CAPMF, WGI, V-Dem, Ember, mrdrivers), so 2023 needs no imputation anywhere. The 2025 edition
also *revises* earlier years; `v6` therefore changes more than the last year, and the `v5` → `v6`
comparison must be read as one change set (0005 D8). A 2022-only fit on the 2025 edition was
considered and not built (author's decision): the comparison above answers the completeness
question without it.

## 5. The future: what each scenario-panel series comes from

### 5.1 The rule

One SSP per run (0005 D9). Every series that has an SSP projection takes the **run's** SSP. In a
coupled run that is REMIND's `cm_GDPpopScen` (`preparePFM.R` writes it to `pfm-coupling.yml` as
`weightScenario`). Offline, it is the scenario registry entry's `ssp` (`config.yml`), default SSP2.
The same SSP drives the aggregation weights (`pfmCouplingWeights`).

### 5.2 Series and their sources

| Series | Future from | SSP-dependent | Notes |
|---|---|---|---|
| actor power, energy intensity, hydro + nuclear share | the REMIND gdx | through REMIND | the same code path as history (`iamCalculatedDrivers`) |
| population, GDP, GDP per capita | mrdrivers SSP*x* | yes | SSP1–5 identical until 2029 |
| urban share, Gini, Gender Inequality Index | SSP extensions, SSP*x* | yes | the SSPs depart from each other between 2010 and 2021, so the "historical" values are SSP2's |
| Government Effectiveness, Control of Corruption | SSP extensions, SSP*x* | yes | replaces the WGI series after harmonisation |
| Rule of Law (Andrijevic) | SSP extensions, SSP1–3 | SSP1–3 only | **SSP4 and SSP5 not published: SSP2 path used** (`calcSSPextensions` says so in the log). Not a sweep candidate (§2) |
| V-Dem Rule of Law, Vertical / Horizontal / Diagonal Accountability, state capacity | **declared institution rule (§5.4)** | only under `storyline` | no SSP projection exists |
| WGI Voice and Accountability, Political Stability, Regulatory Quality | **declared institution rule (§5.4)** | only under `storyline` | idem |
| land area | constant | no | |

### 5.3 SSP-extension coverage and gaps

From the cached extension (`convertSSPextensions`), countries with data per variable: Government
Effectiveness, Control of Corruption and the composite Governance Index 173 (SSP1–5); Rule of Law
170 (SSP1–3 only); Gini 184; Gender Inequality Index 153; urban share 188. Horizon 2100; held
constant from 2100 to 2150. Countries without a series are filled with the cross-country median
(`mrpfm::toolImputeMedians`), so every country has a value — the filled ones carry no SSP signal
of their own.

### 5.4 Institutions without an SSP projection — the declared rule

`pfm::pfmInstitutionProjection(rule, ssp)`; the rule is set per run (`cfg$pfmInstitutions` in
REMIND's `default.cfg`, scenario-config column `pfmInstitutions`; registry key `institutions`
offline). The author's choice (2026-10-02) is **(b) storyline as the headline, (a) convergence and
(d) hold as sensitivities**:

| rule | what it does |
|---|---|
| **(b) `storyline`** (default) | logistic convergence of each country to a target percentile of the cross-section at the last observed year, with SSP-specific target and speed (table below). SSP2 is identical to (a), so every SSP2 result — and all of `v5` — is unchanged |
| (a) `convergence` | the same logistic path for every SSP: 75th percentile, half the gap closed by 2080, complete by 2150. What every Run-Group up to `v5` used. The SSPs then differ only through the series in §5.2 that have an SSP projection |
| (d) `hold` | the last observed value, held. No institutional change: the bound |

| SSP | target percentile | half the gap closed by | converged by | storyline |
|---|---|---|---|---|
| SSP1 | 90 | 2060 | 2100 | sustainability: fast, broad improvement in governance |
| SSP2 | 75 | 2080 | 2150 | middle of the road (= rule (a)) |
| SSP3 | 50 | 2100 | 2150 | regional rivalry: slow, partial |
| SSP4 | 50 | 2100 | 2150 | inequality: approximated by SSP3's slow, partial convergence (one cross-sectional target cannot express "strong at the top, stagnant below") |
| SSP5 | 90 | 2060 | 2100 | fossil-fuelled development: fast, as SSP1 |

The table is a declared assumption (`pfmInstitutionStorylines()`), from the SSP governance
narratives (Andrijevic et al. 2020), not an estimate. In every rule a country already above its
target keeps its value. The path starts from the last *observed* value of the source (V-Dem 2025,
WGI 2024), which can be later than the panel's last year. Whether the storyline rule matters at all
depends on whether the `v6` spec keeps an accountability or V-Dem Rule-of-Law term (0005 D10).

### 5.5 Harmonisation to history

Every scenario series except those projected by the institution rule is shifted by its offset to
the historical panel at the panel's last year (2022 for `v5`, 2023 for `v6`): the full offset up to
that year, fading linearly to zero by 2040 (`harmonizeScenarioYear`). If REMIND has no time step at
the anchor year, the scenario is interpolated to it for the offset only. Normalisation bounds and
the GDP-per-capita quartile breaks are the historical panel's, so a scenario value outside the
historical range is clamped (`MODEL.md` §7, design note 0005 D7).

## 6. Assumptions, in one list

1. **Outcomes are never imputed.** A country-year with no CAPMF value is out of the sample; a region
   aggregates over its data-bearing members only.
2. **Panel definition** per §3: smoothed (5-year centred, outcomes included) for the deployed fit,
   annual as the sibling rung.
3. **2023 from the 2025 IEA edition**, which also revises earlier years (§4).
4. **Institution indices** are imputed over gaps by time interpolation and, where a country has
   fewer than two observations, the cross-country median; then min–max normalised on the global
   country-level range (WGI, V-Dem) so 0 = worst, 1 = best; three "bad when high" V-Dem variables are
   inverted first.
5. **Income, population, area** enter in logs, min–max normalised on the historical range.
6. **Energy intensity** is final energy / GDP, `log1p`, normalised on [0, `log1p(600)`]: a fixed
   ceiling rather than the sample maximum, the same in the historical and the scenario panel.
7. **SSP extensions:** missing countries median-filled; SSP4/5 Rule of Law = SSP2's; held constant
   after 2100 (§5.3).
8. **Institutions without an SSP projection:** the declared rule of §5.4.
9. **Harmonisation:** additive, fading to zero by 2040 (§5.5).
10. **Carbon price (retired model only):** 2023 emission shares carried forward to 2024–2025.

## 7. Reproducing the data of a Run-Group

- **One cache per group.** `config.yml` `madrat: cachefolder: data/madrat/{group}`;
  `pfm::pfmPrepareCache()` fills it, and `records/<group>/` (tracked) holds the manifest and pins
  (ADR 0047). A group's panel definition is part of what the cache key covers (the IEA edition
  changes the madrat calls; the years change what is read).
- **The definition is in the manifest** (`output/pfm/<group>/manifest.json` → `panel`), so a
  reproduction needs no configuration beyond the group name.
- **Sources differ between machines.** The workstation's raw Ember file is the January 2024
  release while the `v5` cache holds Ember to 2024; raw sources are only read for calculations no
  cache has. Reproduce from the group's cache, not from a fresh compute.
- **SSPs beyond SSP2** need the mrdrivers SSP*x* GDP and population calculations in the cache. On
  the cluster they compute from madrat's sources; on the workstation the population source (PEAP)
  is not available, so they must be copied from a cache that has them.
- **Coupled runs** read the group's REMIND export, which stages the coupling's subset of the cache
  into the run folder (`pfm/madrat-cache`) and carries the manifest, so the run builds its scenario
  panel on the group's own definition.
