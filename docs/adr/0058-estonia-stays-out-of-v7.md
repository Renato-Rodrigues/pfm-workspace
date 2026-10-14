# ADR 0058 — Estonia stays out of the estimation in v7

- **Status:** **Accepted 2026-10-14** (author). Supersedes the plan to bring Estonia back in v7 (`TODO.md`, deferred
  items, 2026-10-13; `PITFALLS.md` §27).
- **Run-Groups:** `v7`. `v6` and earlier already exclude Estonia; nothing changes for them.
- **Evidence:** `analysis/checks/estoniaEnergy.R` → `output/checks/estonia-energy-v6.rds` (2026-10-14), on the
  `v6` caches that v7 will rebuild from the same sources (IEA 2025 edition; `calcPE`, `calcFE`, and the IEA balances
  of the workstation REMIND input cache).

## Decision

1. **Estonia is excluded from every v7 estimation**, as in v6. No code changes: `preparePanelData` keeps
   `excludeCountries = getOption("pfm.excludeCountries", "EST")`, and the v7 sweep runs with that default. Do not set
   `options(pfm.excludeCountries = character(0))`.
2. The v7 sample is therefore the same 48 countries as v6 (51 CAPMF countries, less the United States and Brazil,
   which have no stringency values, less Estonia), unless a new CAPMF release adds countries.
3. **Estonia comes back only after its oil shale is in the energy data.** Either:
   - **upstream**: mrenergy maps the `OILSHALE` inputs to power, CHP and heat plants like coal (`pecoal`); or
   - **here**: Estonia's `PE|Coal` is corrected in `iamHistoricalData()` with the IEA flows, as a declared and tested
     adjustment.

   Then `estoniaEnergy.R` is re-run, Estonia's PE / TES must be in line with other countries, and the coefficients
   are compared with and without Estonia, as PITFALLS §27 says.
4. Estonia still receives a ceiling in projections, like every country without CAPMF data (the coverage rule); the
   exclusion concerns estimation only.

## Context

- **Why it was excluded in v6:** the 2024 IEA edition gave Estonia a negative `PE|Coal` (PITFALLS §27). In the 2025
  edition that error is gone, and no country has a negative value in any energy item the panel uses (2000–2023).
- **What the check found instead:**
  - The mrenergy IO mapping (`structuremappingIO_inputs.csv`) carries only three oil-shale flows into REMIND items:
    industry, non-energy use and distribution losses.
  - The oil shale burned in Estonia's power, CHP and heat plants maps to nothing. That is 0.02–0.12 EJ a year: 49% of
    Estonia's total energy supply in 2010, 26% in 2022.
  - Estonia's PE / TES is 0.64 in 2022, the second lowest of 178 countries (median 1.02).
  - Its fossil share of PE reads 0.51–0.78 instead of 0.58–0.88. Its fossil dependence in the panel (power &
    industry, 0.33 in 2023) is below Poland's, Czechia's and Germany's, for the EU's most oil-shale-dependent power
    system.
  - Final energy is complete. No other country is affected (Israel's oil shale in power is 0.1% of its supply).
- **Why exclusion, not inclusion with the gap:** the gap would put a heavily fossil-dependent country among the
  medium ones, a wrong value that looks plausible and moves the interest coefficients unseen. The same reasoning
  kept Estonia out rather than clamping its coal in v6 (PITFALLS §27). One country in 49 is a small loss of data.

## Consequences

- RUNNING Step 6a: "keep Estonia excluded" is a decision, not a check.
- v6 and v7 have the same sample, so sample changes do not confound a v6–v7 comparison (design note 0007 §5).
- Reader-facing texts say Estonia is excluded because the energy data do not yet capture its oil shale, not that it
  "will be reconsidered in the next version": `communication/D3.3/source/content.txt`, the v6 paper's methods
  (`papers/pfm-paper-v6/docs/methods-v6.md`).
- `TODO.md` keeps one deferred item: the oil-shale correction, and Estonia's return after it.

## Alternatives rejected

- **Bring Estonia back as planned:** its fossil share of primary energy would enter 0.07–0.16 too low (a tenth to a
  fifth of its value).
- **Correct Estonia's PE in our code now:** possible, but it is a new data adjustment needing its own test and
  record. It is not worth delaying v7 for one country; it stays as the deferred route.
