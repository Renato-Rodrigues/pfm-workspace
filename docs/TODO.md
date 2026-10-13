# TODO — what is open

*Open items only. Anything closed lives in `_archive/<date>/`, not here.*

**Legend:** 🔴 blocking · 🟠 required for submission · 🟢 improves the work · ⚪ optional

Last reviewed **2026-10-12** (Phases 0–5 done; Phase 6 in progress). The list before this review is
`../_archive/_wip/2026-10-12/TODO-pre-review-2026-10-12.md`.

**The work plan is `docs/design-notes/0005-v6-implementation-plan.md`.** Its §0a (2026-10-12) is the
status review this list follows; IDs such as C10 or D-M3 refer to that note. **The `v6` paper reports
`v6` only** (author, 2026-10-12; 0005 §7b). `v5` stays frozen at its `v5-final` tags as a record.

> **Item numbers are stable identifiers.** Other documents cite them, so a surviving item keeps its
> number and §22 maps every retired one.

---

## 🧭 What to do next

**Where it stands.** Run-Group `v6` is estimated and coupled: 71 runs, all admitted, at EU21 and H12
(0005 Phase 5; `SCENARIOS.md`). The candidate paper spines are design note 0006: eight frames on one
finding, that how long the political limit lasts orders every result of both closures. Their common
evidence is the persistence ladder (`analysis/v6/persistenceLadder.R` →
`output/pfm/v6/coupling/persistence-ladder.{rds,json}`).

**Next, in order:**

1. 🟠 **Choose the spine** (author; 0006). Recommended: today's politics versus tomorrow's, led by "net
   zero slips unless politics changes" (22 of 26 EU21 hold-the-price runs never peak by 2150).
2. ✅ **The growing-limit rate is declared** (author, 2026-10-13, ADR 0057): κ = −0.005 a year, as a bound (the
   fastest rate the share formula represents at θ = 0.675 to 2100; `analysis/v6/growingLimitRate.R`). `V6BACK`
   ran at it (hold the price +245.3 Gt; hold the budget ×1.64 global price, 97.5 Gt moved); no re-run.
3. ✅ **`V6PERSH12` and `V6BACK` processed** (2026-10-13): 71 runs admitted, the ladder at H12 matches EU21
   (+176.3 / +112.8 / +39.3 Gt against +189.1 / +118.2 / +41.2), 0006 and the methodology updated.
4. ✅ **The paper workspace** (2026-10-13): `papers/pfm-paper-v6`, set up from paper-forge **without** the
   `v5` draft (D19 as amended, author 2026-10-13). Literature and the D-m drafting checklist carried over; the
   Methods written fresh (`docs/methods-v6.md`, with D-M2 (i) and D-M4); `pfm-paper-v5` marked superseded.
   **Next, once the spine is chosen:** the claim in `paper.yml`, then `paper-claims` and `paper-design`.
5. ✅ **The paper's figures, `v6` only** (2026-10-12/13): `v6-persistence-ladder`, `v6-cumulative-co2`
   (peak years), `v6-mechanism` (C3, C10), and `v6`-only versions of the coupled figures (`*-only`).
6. 🟠 **The deposit** (D-M3, Phase 6 step 6): Zenodo at tags of `pfm`, `mrpfm`, the fork and the project
   repo, with the `v6` artifacts and batch manifests. Copy the `v6` input archive
   (`/p/projects/elevate/WP3.4/archive/v6-inputs-2026-10-10/`, 876 MB) off the cluster for it.

**Improves the work:**
- ✅ **C10** (2026-10-13): beyond the observed range, clean-energy build-out for 89% of countries by 2050,
  fossil dependence for 50% by 2100 (power & industry); figure `v6-mechanism`, `MODEL.md` §5.2.
- ✅ **G2, part:** design note 0004 closed (2026-10-13). 0006 closes with the spine, 0005 at the end of Phase 6.
- ✅ **G3, part:** the `v6` terms are in `CONTEXT.md` (anchor year, distance kept, strength factor, the
  closures, the persistence cases, ADR 0056's wording). `PRESENTATION.md` is rewritten once the spine is chosen.
- ✅ **G4:** the methodology is `v6` only (rebuilt 2026-10-12; the earlier draft is archived).
- ✅ **Workstation** (2026-10-13): local `pfm` reinstalled from the repository; `test-couplingV6.R:101` updated to
  0.4884. R 4.3.2 is the working version; 4.6.1 is still installed as the machine default.
- 🟢 **F5:** promote the reproduction-chain scripts into `pfm` (improves the deposit, does not block it).

**Done since the review:** ✅ D-GP8 / GP-11 / GP-13 run on `v6` (2026-10-12; results in 0005 §0a item 9,
files `output/pfm/v6/{income-screen,ordering-checks,residual-ordering-phi}.rds`).

**Optional:** ⚪ C11, the price–efficiency elasticity (a separate workstream).

**Deferred beyond the `v6` paper (author, 2026-10-07):**
- **The SSP axis** (A1d, third batch, φ(t) fans by SSP; 0005 §7a decision 7). The machinery stays; the
  governance-only measurement is on record (`output/pfm/v6/phase1/ssp-governance.rds`).
- **Institution projections informed by the PoliClim forecasts** (`analysis/checks/policlimInstitutions.R`);
  then revisit the ceiling-fall gate (ADR 0043; 0005 §7a decision 8).
- **Version control for `../communication/`** (E4). The new paper workspace is its own repository.

**Dropped 2026-10-12** (the paper reports `v6` only; 0005 §0a): D-GP20 / GP-26 and E7 (the `v5` → `v6`
contrast in the paper); E25 for `v5` (fetching `v5`'s shared-cache files, now optional archival); B7;
the `v5`-manuscript minors of D-m1…m10. The `v5` → `v6` contrasts already computed (0005 Phase 6 step 1
and §8) stay as the internal record.

The variant Run-Groups (`v6-specalt`, `v6-sat05`, `v6-sat2`, the assignment variants) were built and ran in
second batch. Never re-run them with `clean = "group"`: it deletes the pinned spec file.

---

## 22. Where the retired items went

The next steps of the 2026-10-02 review are done: the cluster setup and the `v6` cache (2026-10-03;
E27 found there), the `v6` and `v6-annual` sweeps (2026-10-05, re-run 2026-10-06 with `PITFALLS.md`
§28–§31 fixed), and Phase 1 (2026-10-06/07). E23 and E19 are done (0005 §3 E).

Pre-review files: `../_archive/_wip/2026-10-07/TODO-pre-review-2026-10-07.md`,
`../_archive/_wip/2026-09-11/TODO-pre-cleanup-2026-09-11.md`,
`../_archive/_wip/2026-09-14/TODO-pre-cleanup-2026-09-14.md`, `../_archive/_wip/2026-09-16/docs-pre-v5-sweep/TODO.md`,
`../_archive/_wip/2026-09-17/TODO-pre-review-2026-09-17.md`,
`../_archive/_wip/2026-10-02/TODO-pre-v6-review-2026-10-02.md` (the full text of every item retired
on 2026-10-02), and the bodies of the items closed on 2026-09-17/18 are in
`../_archive/_wip/2026-09-18/TODO-closed-2026-09-18.md`.

| item | status | where it went |
|---|---|---|
| **36** | ⛔ superseded 2026-10-02 | no `v5` manuscript: `papers/pfm-paper-v5` is frozen at v18 and the `v6` paper replaces it (0005 D19, Phase 6) |
| **41** | ⛔ superseded 2026-10-02 | no `v5` runs (author, 2026-10-01); hold the budget at θ 0.325 / 0.50 / 0.675 is `v6` first batch (0005 Phase 5) |
| **6** | ⛔ superseded 2026-10-02 | the USA assignment rules (donor / low) are `v6` second batch (0005 Phase 5, D-M2) |
| **12** | ⛔ superseded 2026-10-02 | λ is removed from the coupling in `v6` (0005 D13); the `v5` disclosure question lapsed with the `v5` paper |
| **7a** (open part) | ⛔ decided 2026-10-02 | one shared spec is held fixed in `v6` (0005 D17); the measured band (C31) is reported in the `v6` paper |
| **11a** | ⛔ superseded 2026-10-02 | the ceiling-fall gate is re-examined on `v6` (0005 C9); the guard clean-up is E14 |
| **40** | → E13 | 0005 Phase 0, step 2 |
| **20** | → E10 | 0005 Phase 0, step 2 |
| **21** | → E12 | 0005 Phase 3 (or Phase 0, step 2) |
| **32** | → E11 | analysis side done 2026-09-17; the GAMS side is 0005 Phase 3 |
| **4** | ⛔ superseded 2026-10-02 | the `v6` decomposition of $k_s(t)$ by driver group (0005 C3) |
| **8** | → C11 | optional, a separate workstream (0005 §6) |
| **9** | ⛔ obsolete 2026-10-02 | the coupling uses no `.Rprofile`: since 2026-08-11 the run folder carries its configuration (`pfm-coupling.yml` from REMIND's `preparePFM.R`, `pfm-coupling-runtime.yml` from `presolve.gms`; `COUPLING.md` §2, corrected 2026-10-02). The item's other points: the SSP check → D9, the cost of a PFM call → E17 |
| **38** | → D-M3 | the deposit, built into `v6` (0005 Phase 6) |
| **39** | ✅ done 2026-10-01/02 | project repo created and pushed; everything tagged `v5-final`; the rest is E4 (deferred) |
| **35** | ✅ done 2026-10-02 | citation slots filled 2026-09-18; the two hazards resolved 2026-10-02 with copies placed in `papers/pfm-paper-v5/literature/sources/`: the publisher's PDF of Battese & Coelli 1992 (note re-appraised, now INCLUDE) and the authors' final manuscript of Douenne & Fabre 2022 with its online appendix (70 / 14 / 22% unchanged; locators §3.1, fn. 21). Port with the literature to the `v6` paper (0005 D19); its uncited-note hygiene goes with it |
| **7** | ✅ done 2026-10-02 | `psm*` → `pfm*` renamed in `pfm`, `preparePFM.R`, `analysis/` and the governed docs, after the `v5-final` tags (`design-notes/0005` D21, F9). Legacy names are still read: `selected-models-psm.yml`, `psm-*` steps, and deprecated aliases for the old exported functions. Released as `pfm` 0.5.0 |
| **33** | ✅ done 2026-09-18 | costs and abatement relocation adopted as claims **C36** (hold the budget relocates: net +3/+4 Gt against 72/81 Gt moved) and **C37** (where it lands, + the GDP caveat) — `SCENARIOS.md` §4.8, **Fig 5d**, P3.7b |
| **37** | ✅ done 2026-09-18 | Fig 4b re-pointed to region rank intervals; Fig 2b carries both fossil terms (opposite signs) — `MODEL.md` §2.3, claim C9 |
| **28** | ✅ resolved 2026-09-17 | replay gate re-scoped to the rows where the ceiling acts (+0.001 power & industry / +0.064 buildings & transport) — claim C29, `MODEL.md` §8.4 |
| **14g** | ✅ decided 2026-09-17, measured 2026-09-18 | two headlines; the quantity one is `-PFMlevelBfix` vs `-PFMgateBfix` (+159.3 / +163.8 Gt) — `SCENARIOS.md` §4.2a, claim C35, `COUPLING.md` §11.7 |
| **30** | ✅ closed 2026-09-17 | H12 `-PFMratioMin` re-run: peaks 1003.0 Gt at 2090, 73 iterations; C20 quotes both resolutions |
| **31** | ✅ closed 2026-09-17 | H12 `-PFMratioTh325` re-run: markup written = seen (0.340), 94 iterations |
| **17** | ✅ closed 2026-09-17 | EU21 `-PFMlevelC` restarted from its own gdx for 57 more iterations: 1000.4 Gt, bind share 0.585, warn 0 — hold the budget holds in 6 of 6 (C34) |
| **7a** | ✅ closed 2026-09-17 | specification band measured on `v5-specalt` — `MODEL.md` §5.3.0, claim C31 |
| **1c** | ✅ decided 2026-09-17 | both λ estimates documented, full panel justified for projection — `MODEL.md` §4.3.1; log line fixed in `runPFMCouplingBound.R` |
| **1** | ✅ decided 2026-09-17 | θ in the main text, sources 2–8 of φ uncertainty in the SI — `MODEL.md` §5.3.2; the specification band (source 3) measured the same day, item 7a |
| **26** | ✅ done 2026-09-17 | the `v5` coupled batch; checks and floor regions in `SCENARIOS.md` §3, §6.2 |
| **27** | ✅ resolved 2026-09-17 | frontier and mean regression are different estimands; rule in `MODEL.md` §2.2 and the claims header |
| **1e-a** | ✅ closed 2026-09-17 | gap persists; switch costs measured (`SCENARIOS.md` §1.2); Methods wording fixed in `paper-design.md` M3 and abstract conditions |
| **19** | ✅ closed 2026-09-17 | gate matches to $0.71 / $0.89; wording in claim C6 and the design referee line |
| **14** | ✅ closed 2026-09-17 | gate 0.275 / γ 0.999 are code defaults; margins disclosed in claim C27 and ADR 0045; covariance screen → item 40 |
| **24a** | ✅ closed 2026-09-17 | all 35 figures rendered on `v5`, 104 outputs fresh; the build already continues past a failing figure (`analysis/figures/R/build.R`); design mismatches → item 37 |
| **25** | ✅ retired 2026-09-17 | `analysis/bindingSectorOnE.R` archived to `../_archive/_wip/2026-09-17/analysis-retired/`; superseded by `frontier.rds` (C10) and the coupled attribution (C24) |
| **29** | ✅ closed 2026-09-17 | `remind_pfm` comments updated to `v5` λ (commit with item 39) |
| **28** | ✅ resolved 2026-09-17 | re-scoped replay, body kept above until written into C29 |
| 5, 14h | ✅ closed | the claims ledger and `MODEL.md` are on `v5` |
| 13 | ✅ closed | the trend-shape grid; defence in `MODEL.md` §2.3.1 |
| 15, 16, 18, 23, 24 | ✅ closed | previous batch's coupling artifact, detectors, θ sweep, map figures, estimation figures |
| 1e | ✅ closed | the mode-R floor's λ |
| 0, 0b, 1d | ✅ closed | aggregation weight; country-resolution re-sweep; θ lower bound → 14g |
| 2, 2.1, 2.4, 3a, 7b | ⛔ superseded | → items 19, 26, 17, 14g |
| 3 | ✅ closed | reference price floor switch → claim C21 |
| 10 | ✅ closed | no seam; `PITFALLS.md` §21 |
| 11 | ✅ resolved | residue → item 11a |
| 14b–14f, 14i | ✅ closed | the specification decision (ADR 0045/0046) and its sub-items |
| 20 (registry) | ✅ closed | `config.yml`'s scenario registry |
