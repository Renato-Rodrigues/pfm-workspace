# TODO — what is open

*Open items only. Anything closed lives in `_archive/<date>/`, not here.*

**Legend:** 🔴 blocking · 🟠 required for submission · 🟢 improves the work · ⚪ optional

Last reviewed **2026-10-10** (Phase 5 complete at both resolutions; Phase 6 started).

**`v5` is frozen.** `v5-final` is tagged in the project repo, `pfm`, `mrpfm`, `remind_pfm` and
`paper-forge`, after a reproduction check on a fresh clone of those commits. The tag covers:
- Run-Group `output/pfm/v5` (`panel_hash f8845f66fb39d316`);
- its 62-run coupled batch;
- the evidence bundle of `papers/pfm-paper-v5`, which is frozen at v18 and will not be submitted.

The current release is **`pfm` 0.8.0** / **`mrpfm` 0.4.0**. Everything since is commits under
those versions; the version moves when the author decides.

**The work plan is `docs/design-notes/0005-v6-implementation-plan.md`** (Phases 0–6). This list
orders its next steps; every open item is a step of that plan, placed below, or marked as
outside it. IDs such as E13 or D17 refer to that note.

> **Item numbers are stable identifiers.** `MODEL.md`, `SCENARIOS.md`, `COUPLING.md`,
> `PITFALLS.md`, design note 0005 and `papers/pfm-paper-v5/docs/*` cite them, so a surviving item
> keeps its number and §22 maps every retired one. The file before this review is
> `../_archive/_wip/2026-10-07/TODO-pre-review-2026-10-07.md`.

---

## 🧭 What to do next

**Where it stands (2026-10-10).**
- **Phases 0 and 2 are done.** Run-Groups `v6` (X-1791 satAP) and `v6-annual` (X-1860 satInn) were
  re-run on the cluster on 2026-10-06 with the scenario-panel fixes (`PITFALLS.md` §30–§31). The
  Phase 2 gate passed (Bulk γ 0.997 accepted). The `v5` → `v6` comparison is 0005 §8.
- **Phase 1 is done except G4** (the methodology document). Its results:
  - the anchor artifact `phi-anchor.rds` and the step `pfm-anchor` (C6 / F6);
  - the offline headline (step 9);
  - the spec band, the curve-shape check and the ceiling-gate re-check (C9);
  - the ADR drafts 0049–0055.
- **Phase 3 is done (2026-10-08):** the gate passed on REMIND 3.7.1, and the Phase 1 results were
  re-run on the 3.7.1 bases.
- **Phase 5 is done (2026-10-10):** waves 1 and 2 at EU21 (39 coupled runs) and H12 (15), all admitted;
  64 runs with the bases and nulls (0005 Phase 5, "Results as they land", with an EU21-vs-H12 table).
  The quantity headline is +118.2 Gt (EU21) / +112.8 Gt (H12).
- **Phase 6 has started:** step 1, the `v5` → `v6` coupled contrast, is done (0005 Phase 6).
- **Author decisions of 2026-10-06/07** are in 0005 §7a:
  1. institutions-held twins;
  2. harmonise the institution series;
  3. keep the donor rule, plus a nearest-donors arm;
  4. accept Bulk γ;
  5. the driver lag counts years;
  6. family A in the main text, family B in the SI;
  7. **the `v6` paper is SSP2 only**;
  8. keep the ceiling gate, flagged for revision.

**Next, in order:**

1. ✅ **Committed and pushed** (2026-10-07/08): the work of 2026-10-06/07 in `pfm`, `remind_pfm` and
   the project repo; all three in sync with their remotes on 2026-10-08.
2. ✅ **The anchor artifact and the `v6` export on the cluster**: the gate runs coupled by
   `v6-anchor` (their `pfm-phi-history.rds`), so `phi-anchor.rds` was in the cluster export. The
   workstation's `output/remind-inputs/v6` is the 2026-10-07 09:05 export (with `phi-anchor.rds`).
3. ✅ **Phase 3 — the gate passed 2026-10-08** (0005 Phase 3, "Gate result"; `COUPLING.md` §14). Batch
   `2026-10-07_12.30.39_EU21V371`, all seven runs on REMIND 3-7-1, synced to
   `output/remind-runs/v6/EU21`; `Rscript analysis/v6/phase3Gate.R output/remind-runs/v6/EU21`, 18 of 18.
   - ✅ **The offline analyses are on the 3.7.1 bases** (`refreshBases.R --apply`, 2026-10-08):
     `config.yml` re-pointed; the 3.7.0.dev results are in `output/pfm/v6/phase1-remind-3-7-0-dev29/`;
     old vs new in `output/pfm/v6/phase1/base-refresh.rds`. Every change is small (largest: Diffuse
     $k_{2050}$ on PkBudg1000 −0.054); `couplingOffline.R` still reproduces the Phase 1 shares exactly.
     Numbers quoted before 2026-10-08 from `phase1/` describe 3.7.0.dev29.
   - ✅ ADRs 0049, 0050, 0054 accepted 2026-10-08.
4a. **Wave 1 submitted 2026-10-08 (standby); EU21 wave 2 submitted 2026-10-08 23:17**: `V6W1EU21` (6 runs, batch `2026-10-08_21.55.29`) and
   `V6W1H12` (3 H12 3.7.1 bases, then 10 coupled rows, chained; batch `2026-10-08_22.09.48`). When they land:
   sync (`syncFromCluster.sh … v6 --runs …`), then
   - `Rscript analysis/v6/phase3Gate.R output/remind-runs/v6/H12 --res H12`: the H12 null against its
     `-PFMgateRef`, the held-price pinning (within 5 Gt), rule B and rule C, as at EU21;
   - `Rscript analysis/coupled/runCoupledStage.R v6`: admission, then the v6 facts
     (`coupledBatchFactsV6.R`: θ sweep and slope, the institutions-held twins, rule C's price relocation,
     $k$ per run, every option arm with the options its last call ran with). The cost and held-budget
     scripts now read `-v6` titles and skip comparisons whose runs are not there yet.
   - ✅ **EU21 waves 1 and 2 complete and admitted (2026-10-09)**: all 39 coupled runs (6 wave 1, 33
     wave 2) finished, none at the iteration cap; `runCoupledStage.R v6` ran on 46 EU21 runs. Results in
     0005 Phase 5, "Results as they land". Disclose: `-PFMlevelCMin`'s peak in 2150 (`PITFALLS.md` §26);
     four short rule-C runs that still moved in their last ten iterations (κ 0.05, `specalt`, uniform,
     θ 0.325). ✅ The 0.2–0.4% markup written/seen difference is explained (2026-10-10): the two come from
     different iterations, and differ exactly when the markup moved in the last one (`PITFALLS.md` §16).
   - ✅ **H12 waves 1 and 2 complete and admitted (2026-10-10)**: 15 coupled runs (`V6W1H12` 10,
     `V6W2H12` 5) and the three 3.7.1 bases, none at the cap, every rule-C run settled;
     `runCoupledStage.R v6` on all 64 runs. Gate check 17 of 19: the null misses `-PFMgateRef` by up to
     $1.57 / 0.74 Gt, uniform across regions (budget loop, not the coupling); waived and disclosed (0005
     Phase 3, "H12 gate check"; `SCENARIOS.md` §3.1). Rule B agrees with EU21 within about 10%; rule C's
     price relocation is about half the EU21 size (0005 Phase 5, "H12").
   - ✅ **κ start decided 2026-10-09 (author): no effect in 2025, an effect from 2030 onwards**, i.e. the
     fade counted from $t_0$ = 2025 as committed (ADR 0050 decision 5). The wave-2 κ runs stand as submitted.
4. **Phase 4, alongside:**
   - ✅ **F1 / E16 done 2026-10-07**: `analysis/run-groups/scenario-matrix-v6.yml` →
     `scenario_config_PFM_v6.csv` (58 runs since κ; `RUNNING.md` step 7c). ✅ **κ declared 2026-10-08**:
     0.027 a year, sensitivities 0.02 and 0.05, rule B and C each (ADR 0050 decision 5);
   - **F8**, typed options: ordering tests on $u$, hold year, κ, institution rule;
   - **F5**, the reproduction scripts promoted into `pfm`.
5. ✅ **ADRs 0049–0055 all accepted**: 0051, 0052, 0053, 0055 on 2026-10-07; 0049, 0050, 0054 on
   2026-10-08 at the Phase 3 gate.
6. **G4 — `../communication/methodology/PFM-Methodology.docx` to v6** (B1–B7). Phase 1 and Phase 5
   now have the numbers; the changed sections can be drafted as text to paste.
7. **Phase 6 (0005 Phase 6), in order:**
   - ✅ step 1, the `v5` → `v6` coupled contrast (2026-10-10, `analysis/v6/coupledV5V6Contrast.R`). The
     quantity headline shrinks by a quarter to a third; rule C's price relocation barely moves, but the
     abatement it moves falls by about three quarters (76.7 → 22.7 Gt CO₂eq at EU21);
   - ✅ **that rule-C change decomposed** (2026-10-10, `analysis/v6/ruleCRelocationDecomp.R`; 0005 Phase 6
     step 1): almost all of it is after 2050 (66.2 → 16.7 Gt), where `v6`'s constrained regions' prices
     return to the null's as the strength fades (`v5` held them below it to 2100); the κ arms confirm
     it dose by dose. The new ranking (CHA Diffuse, IND Bulk at u = 1) makes part of it net out inside
     regions (16.1 Gt);
   - ⏳ **one EU21 run to separate the fading strength from the new ranking**: rule C with the static
     share, `SSP2-EU21-PkBudg1000-PFMlevelC-Ehold-v6` (twin of the rule-B arm). In the matrix since
     2026-10-10 (row `CEhold`, start tag `V6CEHOLD`, `remind_pfm` `73e4cf550`); to submit (`RUNNING.md`
     step 7c). When it lands: `runCoupledStage.R v6`, then `ruleCRelocationDecomp.R`. Reading: if it
     relocates near `v5`'s 76.7 Gt, the fading strength explains the drop; if near 22.7, the ranking does;
   - 🟠 **why H12's rule-C relocation is half EU21's** (median 2050 ×1.075 vs ×1.153, anchors alike);
   - step 2, the figures; step 3, the offline re-runs on `v6`; step 4, the governed documents
     (`SCENARIOS.md`, `COUPLING.md`, `MODEL.md` still describe `v5`'s batch); step 5, the `v6` paper
     workspace; step 6, the deposit.

The variant Run-Groups (`v6-specalt`, `v6-sat05`, `v6-sat2`, the assignment twins) were built and ran in
wave 2. Never re-run them with `clean = "group"`: it deletes the pinned spec file.

**Deferred beyond the `v6` paper (author, 2026-10-07):**
- 🟢 **The SSP axis** (0005 A1d, wave 3; decision 7). The machinery stays. The governance-only
  measurement is on record (`output/pfm/v6/phase1/ssp-governance.rds`).
- 🟢 **Revised institution projections informed by the PoliClim forecasts**
  (`analysis/checks/policlimInstitutions.R`). PoliClim uses the same sources, but `v2xcl_rol` for
  "Rule of Law" and overall accountability. Its projections allow backsliding. **When this is done,
  revisit the ceiling-fall gate** (ADR 0043, review flag; decision 8): a new projection can move specs
  across it.

**Not needed for the `v6` run: your call, and time-sensitive if you want it.**
- 🟢 **E25: keep `v5` rebuildable from scratch.** The `v5` artifacts themselves are on disk, and the
  `v6` paper's `v5` → `v6` contrasts read those. What the `v5-final` tags cannot give is a rebuild
  of `v5`'s inputs on a new machine. For that:
  - fetch the 45 shared-cache files the `v5` coupled runs read from
    `/p/projects/rd3mod/inputdata/cache` before that cache is cleaned
    (`records/v5/madrat-cache-used-runs.tsv`; its size and md5 columns are still empty);
  - deposit the 8 of 12 pinned estimation files that exist only in this workstation's
    `data/madrat/` (`records/v5/madrat-cache-used-pfm.tsv`; found by the reproduction check of
    2026-10-01; `RUNNING.md`, still to do 3 and 7).

**Deferred by the author:** version control for `../communication/` and `papers/pfm-paper-v5/`
(E4). A repository may come only with the `v6` paper.

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
| **41** | ⛔ superseded 2026-10-02 | no `v5` runs (author, 2026-10-01); rule C at θ 0.325 / 0.50 / 0.675 is `v6` wave 1 (0005 Phase 5) |
| **6** | ⛔ superseded 2026-10-02 | the USA assignment rules (donor / low) are `v6` wave 2 (0005 Phase 5, D-M2) |
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
| **33** | ✅ done 2026-09-18 | costs and abatement relocation adopted as claims **C36** (held budget relocates: net +3/+4 Gt against 72/81 Gt moved) and **C37** (where it lands, + the GDP caveat) — `SCENARIOS.md` §4.8, **Fig 5d**, P3.7b |
| **37** | ✅ done 2026-09-18 | Fig 4b re-pointed to region rank intervals; Fig 2b carries both incumbency terms (opposite signs) — `MODEL.md` §2.3, claim C9 |
| **28** | ✅ resolved 2026-09-17 | replay gate re-scoped to the rows where the ceiling acts (+0.001 Bulk / +0.064 Diffuse) — claim C29, `MODEL.md` §8.4 |
| **14g** | ✅ decided 2026-09-17, measured 2026-09-18 | two headlines; the quantity one is `-PFMlevelBfix` vs `-PFMgateBfix` (+159.3 / +163.8 Gt) — `SCENARIOS.md` §4.2a, claim C35, `COUPLING.md` §11.7 |
| **30** | ✅ closed 2026-09-17 | H12 `-PFMratioMin` re-run: peaks 1003.0 Gt at 2090, 73 iterations; C20 quotes both resolutions |
| **31** | ✅ closed 2026-09-17 | H12 `-PFMratioTh325` re-run: markup written = seen (0.340), 94 iterations |
| **17** | ✅ closed 2026-09-17 | EU21 `-PFMlevelC` restarted from its own gdx for 57 more iterations: 1000.4 Gt, bind share 0.585, warn 0 — rule C holds in 6 of 6 (C34) |
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
