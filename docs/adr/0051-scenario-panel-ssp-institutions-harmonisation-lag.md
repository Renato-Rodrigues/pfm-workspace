# ADR 0051 — The scenario panel: one SSP per run, the institution rule, harmonisation of every series, and a driver lag in years

- **Status:** **Accepted 2026-10-07** (author). Items 1–4 are implemented and in the `v6` re-run of
  2026-10-06; item 5 is the author's decision 7; item 6 is the implemented default. Records 0005 D9, D10, D11 (SSP part), and §7a decisions 1A, 2B and 7.
- **Run-Groups:** `v6`, `v6-annual` and later. `v5`'s scenario panels were built without items 3–4.
- **Evidence:** `DATA.md` §5.4–§5.5; `PITFALLS.md` §30–§31; `output/pfm/v6/phase1/{lag-seam,decomposition,ssp-governance}.rds`;
  `analysis/checks/policlimInstitutions.R` → `output/checks/policlim-institutions.rds`; tests
  `test-scenarioHarmonisation.R`, `test-driverLagYears.R`.

## Decision

1. **One SSP per run** (D9), taken from `cm_GDPpopScen` and threaded to the panel, the weights and the
   reference price; asserted equal across them.
2. **Institutions without an SSP projection** (all V-Dem series; WGI Voice and Accountability,
   Political Stability, Regulatory Quality) follow a declared rule (D10): **storyline** convergence in
   the headline; uniform convergence and **hold** as sensitivities. Rule of Law stays V-Dem's
   `v2x_rule`. Every headline cell runs with an **institutions-held twin** (decision 1A).
3. **Every scenario series shared with history is harmonised** to the panel's last year, fading to
   zero by 2040, the institution-rule series included (decision 2B). Derived series (the
   state-capacity components) are computed from the harmonised inputs. A country without a history
   value keeps its projection.
4. **The driver lag counts years.** `preparePanelData(lag = 1)` reads the drivers at $t - 1$ year,
   interpolating when that year is not on the panel's axis. The annual estimation panel is unchanged.
5. **The `v6` paper is SSP2 only** (decision 7). The SSP machinery stays for later versions.
6. The headline spread is $d = k$ in every SSP; a declared storyline spread is one SI arm (D11),
   deferred with the SSP axis.

## Context

- **Harmonisation (2B).** The institution-rule path starts from the last *raw* observation (V-Dem
  2025, WGI 2024). The panel holds a moving average at its last year. For countries with recent
  shocks (Myanmar, Mali, Niger, Qatar's accountability) the two differ by 0.1–0.4 on the normalised
  scale. After harmonising, band-rule countries' seam at 2023 is a 95th percentile of 0.93 index points
  (Bulk) and 0.45 (Diffuse), down from 1.93 and 0.86. Bulk $k$ moves by +0.02 to +0.05.
- **The lag (PITFALLS §31).** The lag counted panel rows. On REMIND's 5-, 10- and 20-year steps the
  scenario therefore read drivers 5 to 20 years old. On `v6` EU21 this moved Bulk $k$ on PkBudg1000
  from 0.63 to 0.87 in 2050 (row lag), and Diffuse from 0.91 to 0.78. The fix leaves the prepared
  training design `identical()`, so fits, selection and the Fit Cache are unchanged; the cluster
  re-run of 2026-10-06 confirmed the same selection and frontier.
- **Institutions matter for $k$.** With institutions held at 2025, Bulk $k_{2100}$ on PkBudg1000 is
  0.28 instead of 0.48 (`v6`). So better institutions *tighten* the Bulk constraint in the deployed
  frontier, through Bulk institution terms that are not identified (wild-cluster p 0.6–0.9; ADR 0052).
  Hence the held twin travels with the headline.
- **SSP2 only (decision 7).** A governance-only swap (SSP1 / SSP3 institutions on the SSP2 energy
  system) gives a small SSP spread to 2050 and a large one in Bulk after 2070, through those same
  Bulk terms. The paper version does not report the SSP axis; the measurement is kept on record.
- **PoliClim** uses the same V-Dem v16 and WGI 2025 data, but its "Rule of Law" is V-Dem `v2xcl_rol`
  (equality before the law and individual liberty) and its accountability is overall, not vertical.
  Its projections allow backsliding and keep countries different, where the storyline rule converges
  monotonically. A revision of the institution projections is planned and would revisit this ADR
  and ADR 0043.

## Consequences

- Scenario panels and scenario-side artifacts built before 2026-10-06 are invalid (seam, lag). The
  coupling bound's panel cache is renamed `…-scen-ca-peEJ-harm.rds`.
- Under the hold rule, institutions now move from the panel's anchor value to the raw last observation
  by 2040, instead of staying flat from 2023 (`DATA.md` §5.4).
- The harmonisation shifts every pre-stitch year by the 2023 offset, so the institution series match
  history at 2023 but less well at 2020. Replacing pre-2023 scenario years with history would move $k$
  by at most 0.03; not done.

## Alternatives rejected

- Keep the institution-rule series exempt from harmonisation, as "anchored by their own projection".
- Annualise the scenario panel before every scenario call, instead of a year-based lag in one place.
- WGI Rule of Law, or a map from the Andrijevic composite index (D10).
