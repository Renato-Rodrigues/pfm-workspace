# 0005 — v6: implementation plan for the model, the coupling and the next paper version

**Status: Open — plan agreed, nothing implemented.** It turns `../communication/methodology/PFM-Methodology.docx`
("Next implementation steps" 1–5) into an ordered work plan. It also folds in the open referee
points from `papers/pfm-paper-v5/`, the defects found in the current code, and the refactors that would make
coupled runs easier to set up and submit.

**Author decisions, 2026-10-01** (§7 has the full list). The author accepted every recommendation
except two, which were reversed:
- **No hold year is the central case**; holding $k$ at 2060 is the sensitivity (D6).
- **No `v5` runs.** The ordering tests are done on `v6` only.

Also confirmed:
- the `psm` → `pfm` rename comes **before anything else** (D21);
- `papers/pfm-paper-v5` is frozen at v18;
- a new paper workspace is built the way `papers/pfm-paper-v5` was, with `papers/pfm-paper-v5` v18 as its draft. The v6 paper
  **replaces** the `v5` paper as the one to submit (D19).

**Provenance.** Written 2026-10-01. Sources read:
- `../communication/methodology/PFM-Methodology.docx` (2026-09-30)
- `docs/TODO.md` (reviewed 2026-09-18)
- `docs/design-notes/0003`, `0004`
- `../_archive/_wip/2026-10-01/docs/pfm_dynamic_ssp_coupling_architecture.md` (v2)
- `../_archive/_wip/2026-10-01/docs/pfm_remind_coupling_step_by_step.md` (v3)
- `papers/pfm-paper-v5/docs/gap-plan.md`, `papers/pfm-paper-v5/reviews/review-v16.md`, `decisions-v18.md`, `NEXT-SESSION-PROMPT.md`
- the code: `models/pfm/R/{iterativePFM, projectFeasiblePath, aggregateFeasibilityToRegions, exportFeasibilityBound, panelDataScenario}.R`, `models/mrpfm/R/calcSSPextensions.R`, `models/remind_pfm/modules/45_carbonprice/functionalForm/presolve.gms`, `models/remind_pfm/scripts/start/preparePFM.R`, `analysis/run-groups/buildPFMScenarioConfig.R`, `config.yml`
- the git state of each sub-project on 2026-10-01

Every number below is Run-Group **`v5`** and comes from the document named beside it. As
`docs/design-notes/README.md` requires, none of them may be quoted without re-deriving it.

---

## 0. Summary

v6 changes **what the coupling reads**, not what the frontier is.

- **The ranking of regions is read on observed data at the last panel year.** It is no longer read
  in 2035 after a projection at λ.
- **Each country keeps its 2022 shortfall below its own ceiling**, measured on the logit scale.
- **One world-wide strength factor $k_s(t)$ per sector** follows the ceilings as REMIND's energy
  system and the SSP's institutions and income move them.

This removes λ from everything the coupling delivers. It makes the shares SSP-aware, and the
uncertainty already computed on 2022 data then applies to what REMIND receives.

The work is front-loaded with things that are cheap and decisive:
1. **Phase 0:** the `psm` → `pfm` rename first, then commit, push and clean up. No `v5` runs.
2. **Phase 1:** prove the formulation offline on existing `v5` gdx files before writing GAMS code.
3. **Phase 2:** pay for **one** re-sweep that carries every specification change at once (panel to
   2023, geothermal, saturating innovator power).

| phase | what | where | gate to the next phase |
|---|---|---|---|
| **0** | `psm` → `pfm` rename first; then commit and push, version control, small code fixes | workstation | the rename is one isolated commit per repo; `v5` artifacts still read through aliases; everything is pushed |
| **1** | Offline prototype of the v6 formulation on `v5` artifacts and gdx files | workstation | the prototype reproduces the methodology's $k_s(t)$ values; ADRs drafted |
| **2** | Data and estimation, Run-Group **`v6`**: SSP-aware panel, accountability rule, geothermal, panel to 2023, re-sweep with saturating innovator power | cluster (sweep) | spec selected; diagnostics pass; v5→v6 ordering comparison written |
| **3** | Coupling code: R (`iterativePFM` v6 path) and GAMS (time-indexed φ, rule-C rebuild, mode R) | workstation + test runs | replay harness and negative control pass; θ = 0 gate run passes |
| **4** | Run tooling: scenario matrix → generated config, preflight, submit wrapper, post-batch stage | workstation (in parallel with 3) | the v6 batch config is generated, not hand-edited |
| **5** | Coupled batch `v6`: SSP2 core → sensitivities → SSP1 / SSP3 | cluster | every run converged or admitted by the §25a rule |
| **6** | Analysis, figures, governed docs, ADRs, new paper workspace (replaces `papers/pfm-paper-v5`), deposit | workstation | `paper-check` READY on the first v6 draft |

---

## 1. The v6 formulation in one page

Notation follows the methodology document. Here $c$ is country, $r$ region, $s$ sector, $m$
market, $t$ year, $t_a$ the anchor year (2022, or 2023 if the panel is extended), and $t_0 = 2025$
the first model period.

1. **The frontier is unchanged in form:** $y = \eta + v - u$ on the logit scale, with
   $S^* = S_{\max}\,\mathrm{logit}^{-1}(\eta)$. It is refitted on the v6 panel (§3, Phase 2).
2. **Distance held on the logit scale.** $q_{c,s} = \eta_{c,s,t_a} - y_{c,s,t_a}$. For an
   uncovered country, $y_{c,s,t_a} = \mathrm{logit}(E_c S^*_{c,s,t_a}/S_{\max})$, using the
   band-rule $E_c$. Then $S_{c,s,t} = S_{\max}\,\mathrm{logit}^{-1}(\eta_{c,s,t} - q_{c,s})$.
3. **Ranking from the anchor year:** aggregate with the deployed final-energy weights to
   $g_{r,s,t_a}$, then $u_{r,s} = (g_{r,s} - g_{\min,s})/(g_{\max,s} - g_{\min,s})$. Computed
   **once, offline**, per Run-Group, and staged as an artifact.
4. **Strength from the world mean gap:** $G_s(t) = \sum_r w_r\,g_{r,s}(t)$, with
   $k_s(t) = G_s(t)/G_s(t_0)$. Here $w_r$ is the region's share of world final energy, fixed at
   $t_0$. In the central case $k_s$ follows the ceilings in every period to 2100 and is held at its
   2100 value only in REMIND's terminal periods (2110–2150). The sensitivity holds it from 2060
   (decision D6).
5. **Share:** $\varphi_{r,s}(t) = \mathrm{clip}_{[0,1]}\big(1 - \theta\,[\,k_s(t)\,\bar u_s + d_s(t)\,(u_{r,s} - \bar u_s)\,]\big)$.
   The deployed setting is $d_s = k_s$, which reduces to $1 - \theta\,k_s(t)\,u_{r,s}$.
6. **Delivery is unchanged:** the floor is $\min_s$; ETS ← Bulk; ES and other ← Diffuse; the level
   cap $P = \min(A, P^{ref} + \varphi\,\max(A - P^{ref}, 0))$, now with $\varphi(t)$.

What REMIND can still move: $k_s(t)$, through actor power, in every period up to the hold year.
What it can no longer move: the ranking. That limitation is stated in the methodology and kept
here (D1).

---

## 2. Decisions, and why

| id | decision | rejected alternative(s) | status |
|---|---|---|---|
| D1 | Deploy the **anchor + mean-gap strength** formulation ("Next step 1") as the v6 coupling. Keep the v5 2035 reading only as a reproduction switch | keep the 2035 reading; extra tier years under the λ projection | recommended |
| D2 | Hold each country's distance on the **logit scale** ($q = \eta - y$), not the efficiency ratio $E$ | hold $E$ (natural scale); hold the index-point gap | recommended — **must be stated as the mechanism** |
| D3 | Anchor at the last panel year on the moving-average panel; fit the frontier on that panel; annual data as a robustness rung, built as the **sibling Run-Group `v6-annual`** with its own panel | switch the deployed fit to annual data | **decided by the author, 2026-10-02** |
| D4 | Normalise $k$ at $t_0 = 2025$ in every scenario; $u$ from anchor-year data; $\varphi(t_0) = 1 - \theta u$ | normalise at 2022 | recommended |
| D5 | Converge on the **φ path** (max over regions, markets and checkpoint years) at the existing tolerance 0.002; log the all-period δ; switch to the strict rule if it ends above 2 × tol | converge on $k$ with tolerance tol/θ | agreed |
| D6 | **No hold year in the central case:** $k_s$ follows the ceilings to 2100. **Hold at 2060 is the sensitivity.** The out-of-support share is reported per year with every run | hold at 2060 as the central case | **decided by the author, 2026-10-01** |
| D7 | Actor-power form **selected, under an extrapolation gate**: every split actor-power spec is fitted linear, both-saturating, innovator-only and incumbent-only saturating; the composite Actor Power Index is dropped; a new sanity gate rejects specs whose actor-power drivers extrapolate beyond the training support over 2025–2100 (gating and reference). Every other clamp kept | innovator saturating, declared (the earlier recommendation); saturate both groups; keep the composite | **decided by the author, 2026-10-02** (options 1C, 2C, 3A); implemented |
| D8 | **One** re-sweep (Run-Group `v6`) carrying panel-to-2023, geothermal and saturating innovator power together. 2023 comes from the **IEA 2025 edition**, which also revises earlier years | three separate refits; a 2022-only fit on the 2025 edition | **decided by the author, 2026-10-02** (2023 and its edition) |
| D9 | One SSP per run, taken from `cm_GDPpopScen` and threaded to the panel, the weights, $P^{ref}$ and the anchor donor; **asserted** | SSP2 everywhere (today) | recommended |
| D10 | Institutions with no SSP projection (all V-Dem series, Rule of Law included; WGI Voice and Accountability, Political Stability, Regulatory Quality): **(b) declared storyline convergence** (target percentile and speed per SSP, SSP2 unchanged) in the headline; **(a)** the same convergence for every SSP and **(d)** hold at the last observed value as sensitivities. Rule of Law stays V-Dem, not WGI | (c) map from the Andrijevic composite index; WGI Rule of Law | **decided by the author, 2026-10-02**; implemented (`pfmInstitutionProjection`, `DATA.md` §5.4) |
| D11 | Spread: $d_s = k_s$ in every headline run; a declared storyline spread $d_s = \rho_{SSP}(t)\,k_s$ only as an SI arm; the model-derived $D_s(t)/D_s(t_0)$ reported as a diagnostic only | model-derived spread in the headline | recommended |
| D12 | Clip φ to [0, 1]; redefine θ as "severity at $t_0$"; log the clipped share, and flag $k_s > 1/\theta$ | let φ float below $1-\theta$ unbounded | recommended |
| D13 | **Remove λ from the coupling.** Retire mode M and the `GAPCLOSE` arm from the v6 batch. Replace gap closure by one declared closure arm on the strength. Keep the ECM in diagnostics only | keep λ for the 2022→2035 step; keep `GAPCLOSE` | recommended |
| D14 | New time-indexed GDX symbols behind a switch; keep the old symbols; rule B needs no GAMS change | re-rank the existing symbols | recommended |
| D15 | Ordering tests (uniform, permuted, reversed, set) become a ranking option on **$u$**, composing with $k(t)$. This replaces `phi-override.yml` for v6 | keep overriding φ after the fact | recommended |
| D16 | Region-specific strength $k_{r,s}(t)$ only as an SI sensitivity | deploy it | recommended |
| D17 | **Hold fixed** in v6: one shared spec for both sectors, min–max normalisation, final-energy weights, the USA override, the θ grid {0.325, 0.50, 0.675} | change any of these too | recommended |
| D18 | Re-run the θ = 0 nulls once on the v6 fork and gate them against `v5`. **Amended 2026-10-07:** the fork moved to REMIND 3.7.1, so the null is gated against `-PFMgateRef` on the same version, and the uncoupled bases are re-run on 3.7.1 first (`PITFALLS.md` §34) | reuse the `v5` nulls | recommended; amended |
| D19 | **New paper workspace** on Run-Group `v6`, built the way `papers/pfm-paper-v5` was built from `paper`. `papers/pfm-paper-v5` v18 is the draft; `papers/pfm-paper-v5`'s design, claims and literature are the seed. `papers/pfm-paper-v5` is frozen at v18 as the `v5` record and **is not submitted**: the v6 paper replaces it | continue `papers/pfm-paper-v5` and switch its Run-Group; submit `papers/pfm-paper-v5` on `v5` in parallel | **decided by the author, 2026-10-01** |
| D20 | Put the project layer (`analysis/`, `analysis/figures/`, `docs/`, `docs/design-notes/`, `config.yml`, paper workspaces) under git, excluding data, output and gdx | keep it workstation-only | agreed |
| D21 | The `psm*` → `pfm*` rename is **the first step of v6, before anything else**, with read-aliases so the frozen `v5` artifacts and the `papers/pfm-paper-v5` bundle stay readable | defer to after submission | **decided by the author, 2026-10-01** |
| D22 | The scenario config is **generated** from a compact matrix file; the CSV becomes a build artifact | keep hand-editing an 83-column CSV | recommended |

### Why, decision by decision

**D1 — the anchor + mean-gap formulation.**

- **It removes the one unidentified rate the share depended on.** λ sits inside or below its
  placebo null (0.291 [0.181, 0.419] / 0.104 [0.062, 0.209], `TODO.md` 12b). It does not beat
  persistence. On annual data it is 1.7× (Bulk) and 4× (Diffuse) the smoothed value, so much of it
  is a smoothing artefact (0004 §2).
- **The λ step is first-order for the ordering REMIND receives.** At 2035, the speed-limited and
  frozen-gap rules agree at a Spearman of only 0.52, and the floor pair changes (0004 §3). The
  2022 and 2035 readings agree at only 0.30 (GP-20).
- **The rank intervals, specification band and frontier rungs are all computed on 2022 data.**
  Under v6 they describe the delivered share directly; under v5 they describe a different object.
- **It removes a v5 inconsistency inside every region.** Covered countries are projected at λ;
  uncovered countries hold their ratio $E$ (`aggregateFeasibilityToRegions.R` fills
  $E \cdot S^*$). Both rules are mixed in one regional aggregate (methodology, Step 2).
- **It makes GP-26 and the `chinaseed` arm of GP-23 moot by construction**, and implements GP-27,
  the share that moves after the tier year.
- **The cost:** a region's own energy transition can no longer change its rank. It is stated, and
  D16 tests it.

**D2 — hold the distance on the logit scale. This choice is the mechanism, not a detail.**

- In 0004 §3 (E3b), holding $E$ fixed leaves the median relative gap at 0.30 / 0.30 / 0.30 (Bulk)
  for 2035 / 2050 / 2070. That makes $k_s \approx 1$, and the formulation collapses to a static
  share.
- Holding $q$ on the logit scale lets the gap shrink as a ceiling rises toward saturation, and
  widen as it falls. **Every movement of $k_s(t)$ comes from this choice.**
- **Why it is defensible:** the frontier, its composed error $u - v$ and the one-sided shortfall
  are all defined on the logit scale. Holding the shortfall where the model defines it is the
  model-consistent version of "the gap persists".
- **What must travel with it:** Methods states that the strength factor exists because the
  shortfall is held on the logit scale. The $E$-hold run is reported as the static-share bound.
  The methodology lists this as "a new declared assumption"; the plan makes it a named sensitivity.

**D3 — anchor on the moving-average panel; annual data as a rung.**

- With λ gone, the moving average no longer biases anything the coupling uses: the frontier is
  robust to it (Spearman of $E_{2022}$ 0.981 / 0.932; 14 / 17 and 17 / 17 signs agree; 0004 §2).
- The anchor reading **benefits** from smoothing. The ranking is now read in a single year, and
  the end-of-panel value is already a three-year mean (2020–2022).
- An annual deployed fit would put single-year CAPMF noise straight into the ranking. It stays a
  robustness rung (methodology Next step 5).

**D4 — normalise $k$ at 2025.**

- $k(t_0) = 1$ by construction in every scenario, including the nulls and every SSP. SSP
  differences then come only from trajectories after 2025, where REMIND and the SSPs differ.
- The ranking still comes from observed data at $t_a$.
- This also removes an ambiguity in the methodology, which writes both $\varphi(2022)$ and
  $k(2025) = 1$.

**D5 — converge on the φ path.**

- With $d = k$ and $\max u = 1$, $\max_r|\Delta\varphi_r| = \theta\,|\Delta k|$ exactly. Checking φ
  is therefore identical to the methodology's rule.
- It avoids dividing by θ, which is undefined for the θ = 0 nulls.
- It keeps `cm_pfmConvTol` meaning what it means today.
- It extends naturally to $d \ne k$ and to the per-market shares. v5 checks only the
  economy-wide floor (`iterativePFM.R`, step 4), so a market share could still be moving when the
  run is declared converged.
- **Checkpoints:** 2035, 2050, 2070 and 2100 in the central (no-hold) case; 2035, 2050 and 2060
  in the hold-2060 sensitivity.
- **Damping** ($\alpha = 0.5$) is used only if a run oscillates. It is recorded in the history file,
  and the undamped δ is always logged.

**D6 — no hold year in the central case; hold at 2060 as the sensitivity (author's decision).**

- **Why no hold is defensible as the central case.** It is the methodology's own default. It lets
  the energy system, the SSP institutions and income act on the constraint over the whole horizon
  REMIND optimises. And the methodology's offline values show $k_s(t)$ flattening by itself after
  about 2050, so the 2060–2100 tail is not where most of the movement is.
- **What it requires, and the plan now carries:**
  - **Revise `MODEL.md` §7.** Its prohibition of "scenario differences past ~2060" no longer holds
    for the delivered share. ADR 0052 records the change and its reason. The rule is replaced by
    a reporting duty: the out-of-support share per year travels with every $k_s(t)$ and φ(t).
  - **Saturating innovator power becomes necessary, not optional (D7).** Without a hold, $k_s$
    reads ceilings to 2100. By 2050, 56–65% of countries are above the innovator range on `v5`
    (0004 §1).
  - **The hold-2060 arm is the honest bound** on how much of each headline comes from late-century
    extrapolation. It runs for both closures at EU21 (Phase 5, wave 2).
  - **Late-century SSP differences are partly clamp-driven:** GovEff reaches the scale maximum by
    2070 under SSP1 and SSP5, and 60% of countries are above the GDP range by 2100 on SSP2 (0004
    §1, §4). The SSP results are therefore always reported next to their hold-2060 twin.

**D7 — the actor-power form: selected, under an extrapolation gate (decided 2026-10-02).**

- **Decision** (author, options 1C, 2C, 3A of the D7 brief):
  - *1C, incumbents:* selection chooses whether incumbent power (share and per capita) is
    saturated, as for innovators.
  - *2C, innovators:* the linear form stays in the grid; what removes the extrapolation problem is
    a gate, not a declaration. **Actor-power extrapolation gate:** severe when more than 27.5% of
    the in-coverage country-years in 2025–2100 have an actor-power driver more than 1 training SD
    beyond its support, on the gating or the reference projection. Saturating columns are guarded
    at their physical domain, so they pass by construction; a linear term passes only if the
    scenario keeps it near the data. 0.275 is the existing support-share gate's tolerance
    (ADR 0045); both thresholds are declared, and recorded per group.
  - *3A:* the composite Actor Power Index specs leave the grid: a difference cannot be saturated
    and would extrapolate innovators linearly through the back door (≤ 6.7% of `v5` bootstrap
    winners used any form other than `bothIncAP` / `splitAPpc`).
  - **Why selection rather than declaration:** in sample the data are indifferent between linear and
    saturating (`satAP` 45.9% of `v5` bootstrap winners against 43.3% of the pool, p = 0.47,
    `MODEL.md` §6); the gate makes the out-of-sample behaviour the deciding evidence instead of an
    assumption.
  - **Implemented:** `apTransform` gains `"saturating-innovator"` / `"saturating-incumbent"`
    (twins `" satInn"` / `" satInc"`; `" satAP"` stays both); `pfmSpecs(apTransforms,
    dropCompositeAP)`; the gate in the sanity walk (`apExtrapolationGate`, `apExtrapolationSd`,
    `apExtrapolationWindow`); all set in `config.yml` `sweep:` and recorded in the group's
    manifest (`sweepOptions`), so `v5` keeps its grid.
- **What it does not cover:** the gate is scored on the registry's gating and reference gdxs
  (SSP2). An SSP3/SSP5 run can push incumbent per capita further; Phase 1 step 4 measures that on
  the `v5` gdxs, and the out-of-support share is reported per year with every run (C10).
- Background, unchanged:
- v6 reads ceilings to 2060–2100. The linear innovator term is then extrapolated 5–9 SD beyond the
  data for most countries (0004 §1). Without the clamp, half of all Diffuse ceilings exceed 9 by
  2100 and the ordering compresses.
- The saturating form $x/(x + \bar x)$ already exists (ADR 0040, `satAP`). It decays at the
  physical domain, not at the sample edge.
- The other clamps stay: log population (up to 130 SD), the upper bound on incumbent power per
  capita (40–75 SD outliers), GDP and GovEff. They cost nothing today and stop explosions under
  SSP inputs (0004 §1).
- **Rungs:** the selected spec's other actor-power forms (its linear and saturating twins) are
  reported as SI rungs, so the effect of the form is shown, whichever wins. (`bothIncAP`, 76% of
  `v5` bootstrap winners, is the incumbency *structure*, share plus per capita; it is independent of
  the linear/saturating form.)

**D8 — one re-sweep.** Each of panel-to-2023, geothermal and the saturating transform changes the
panel hash or the candidate set, so each would force selection on its own. Done together, the
selection bootstrap, diagnostics and specification band are run once. The `v5` → `v6` comparison
is reported as one documented change set, not three drifting ones.

**D9 — one SSP per run, asserted.**

- Today the scenario panel hard-codes SSP2 in five places (`panelDataScenario.R` lines 63, 80, 106,
  183, 224–231), and `calcSSPextensions()` exposes only `drivers_SSP2`.
- Meanwhile `preparePFM.R` already derives the run's SSP from `cm_GDPpopScen`, but only for the
  weights. A non-SSP2 run would therefore silently mix SSP2 institutions with SSPx weights.
- Fix: one value, threaded everywhere, checked in R and by the scenario-config validator. GAMS
  cannot check it (`TODO.md` 9).

**D10 — vertical accountability under SSPs.**

- No SSP projection exists. The cached SSP extensions (Andrijevic et al.) carry the composite
  Governance Index, Government Effectiveness and Control of Corruption for SSP1–5 and a Rule of Law
  index for SSP1–3 only, to 2100, but **no voice or accountability series** (checked in
  `data/madrat/convertSSPextensions.rds`).
- A declared storyline table, swept, is the honest option; Leininger et al. (2024) give the
  storyline language.
- **Ordering matters:** no accountability option reaches half the bootstrap winners on `v5`, so
  the re-sweep may drop the channel. Implement the declared rule only if the `v6` spec keeps it.
- **Correction (2026-10-02):** the Rule of Law in the candidate set is **V-Dem's**, not WGI's, and
  stays so (author). It has no SSP projection: it follows the declared rule like the accountability
  series. The Andrijevic Rule-of-Law path (SSP1–3; SSP4/5 fall back to SSP2) only replaces the WGI
  series, which is not a candidate. The earlier note here ("Rule of Law *is* SSP-projected, its SSP
  path is free") was wrong.
- **Decided 2026-10-02 and implemented** whatever the re-sweep keeps, since it costs nothing when
  the spec has no such term: `pfmInstitutionProjection(rule, ssp)` with rules `storyline` (default),
  `convergence`, `hold`; the storyline table is `pfmInstitutionStorylines()`; REMIND
  `cfg$pfmInstitutions` → `pfm-coupling.yml` `institutions`; registry key `institutions`.
  `DATA.md` §5.4 is the reference.

**D11 — no model-derived spread in the headline.**

- The methodology defines $D_s(t)$ from the model's gaps but then says the spread is "declared from
  the storyline". These are two different objects.
- The model's own spread is driven by extrapolated drivers and clamps, which is exactly what the
  hold year guards against.
- Stacking a second declared dial onto the headline would make the SSP fan uninterpretable. The
  headline uses $d = k$ for every SSP; the storyline spread is one SI arm per SSP; the model-derived
  ratio is reported as a diagnostic.

**D12 — clip φ and redefine θ.**

- With $k_s > 1$ the largest-gap region drops below $1 - \theta$. The methodology's offline values
  give $k_{Bulk} = 1.08 / 1.18 / 1.21$ in 2035 / 2050 / 2070, so the floor falls toward 0.40 at
  θ = 0.50. With $d \ne k$, φ can exceed 1.
- Clipping keeps the share meaningful; θ's meaning becomes "severity at 2025".
- A clip at 0 is flagged as a run defect, not absorbed.

**D13 — remove λ from the coupling.**

- `cm_pfmGapClosure = 0` already zeroes λ inside the price. Under D1 the 2022→2035 projection is
  gone as well, so λ has no job left in the coupling.
- **Mode M** uses λ as its mechanism, and was never corroboration (`SCENARIOS.md` §4.4). It
  leaves the batch; its code stays.
- **`GAPCLOSE`** answered "what if the gap closes at λ". Under v6 the declared equivalent is a
  closure on the strength, $k_s(t)\,(1 - \kappa)^{t - t_0}$, with κ declared. This follows the
  third option of 0004 §3. One SI arm.
- **The ECM stays** in `psm-temporal` as a reported finding (forecast skill, placebo), not as a
  model input. This closes design-note 0003.

**D14 — new GDX symbols, old ones kept.**

- Re-ranking an existing symbol is how defect 4 produced a silent all-zero load (`COUPLING.md` §7).
- Add `p45_pfmPhiPath(ttot, all_regi)` and `p45_pfmPhiMktPath(ttot, all_regi, all_emiMkt)`, `ttot`
  first, behind `cm_pfmPhiPath` (default 0). The old rank-1 / rank-2 symbols carry the $t_0$ value.
- Rule B needs nothing new: `p45_pfmPriceBound(ttot, …)` is already year-indexed, and
  `exportFeasibilityBound()` already takes φ per region-year.
- Rule C's rebuild and mode R must read the path (`presolve.gms` around lines 297–336 and 365–368,
  plus the `postsolve.gms` Step IV.4 mirror). Otherwise rule C silently rebuilds from a constant φ
  after convergence — the GP-18 failure in a new form.

**D15 — ordering tests on $u$.**

- `phi-override.yml` overwrites φ after it is computed. Under v6 that would freeze $k(t)$ out of
  the test arm.
- Testing at the level of $u$ (uniform at $\bar u$; permuted; reversed; set) keeps the strength
  dynamics identical between deployed and test arms. The contrast then isolates the estimated
  ordering, which is exactly referee point v16 M1.
- As a first-class option it is also logged, typed and testable, instead of a file that a stale
  run folder can carry over (the reason `preparePFM.R` has to delete it).

**D16 — regional strength as a sensitivity only.** $k_{r,s}(t) = g_{r,s}(t)/g_{r,s}(t_0)$ restores
region-specific feedback but lets regions reorder on extrapolated drivers. That is the v5 problem
in a new form. One SI arm answers "what does the common factor cost?" (methodology limitation 1).

**D17 — change one thing at a time.** Every quantity the referee has already accepted keeps its
definition, so the `v5` → `v6` difference can be attributed to the formulation and the re-sweep.
The open questions on these choices stay open, but are not v6 work:
- whether both sectors should share one spec (`TODO.md` 7a): it costs about 19% ΔR²(theory);
- the endpoint spacing of the min–max (GP-14): measured at most 3.9% on the headline;
- the weighting.

**D18 — re-run the nulls.** In principle a θ = 0 null is formulation-independent (φ ≡ 1). But v6
adds GAMS code paths, and the fork may merge upstream REMIND. Four nulls per resolution are cheap
next to an unexplained drift in every contrast. The gate reuses `COUPLING.md` §6.6.

**D19 — a new paper workspace that replaces `papers/pfm-paper-v5` (author's decision).**

- Every number in `papers/pfm-paper-v5` carries Run-Group `v5`, and its bundle is frozen. Switching the group
  inside it would invalidate the claims ledger, the manifest and 18 versions of review history at
  once.
- **Procedure:** the `paper` → `papers/pfm-paper-v5` precedent (`papers/pfm-paper-v5/docs/NEXT-SESSION-PROMPT.md` §2).
  1. Scaffold with `Rscript papers/paper-forge/bin/new-paper.R <dir> --slug <slug> --journal
     nature-climate-change --artifacts ../output --draft papers/pfm-paper-v5/manuscript/paper-v18.md`.
  2. Treat the v18 prose as a quarantined draft (a guide to the argument, never a source).
  3. Port `papers/pfm-paper-v5`'s design, claims ledger (re-tiered on `v6`), glossary and appraised literature.
  4. Build a fresh evidence bundle on `v6`.
- **`papers/pfm-paper-v5` is frozen and not submitted.** It stays reproducible as the `v5` record, through the
  rename aliases (D21). It does **not** need the E7 disclosure or any further `v5` runs.
- **What carries over from the referee rounds:** the open majors and minors of review-v16 (§3 D)
  become the new workspace's opening checklist, so the new loop does not re-raise them.

**D20 — version control for the project layer.**

- `analysis/`, `analysis/figures/`, `paper*/`, `docs/` and `docs/design-notes/` are not under git.
  `models/pfm-reports` had a broken `.git`; it was deprecated and archived on 2026-10-01.
- This is `TODO.md` 39 and paper2's oldest open referee point (GP-16 / v16 M3, carried since v04).
  A v6 built the same way recreates the same blocker.

**D21 — the rename comes first (author's decision).**

- **Why first.** The rename was deferred because it invalidates artifact paths the `v5` bundle
  traces to (`TODO.md` 7). Before any `v6` artifact exists, the only cost is a read-alias for the
  `v5` names. Done later, the same cost recurs with the `v6` bundle. Done first, every v6 change is
  written once, against the final names.
- **Scope:**
  - function names (`runPSM*` → `runPFM*`, `.psm*` → `.pfm*`);
  - step names (`psm-*` → `pfm-*`);
  - artifact file names (`selected-models-psm.yml` → `selected-models-pfm.yml`, and any other
    `psm` stem);
  - `pfmRun()`'s plan and logs;
  - `preparePFM.R`'s marker lookup;
  - `analysis/` and `analysis/figures/` callers;
  - the DESCRIPTION text ("Policy Stringency Model (PSM)").
- **Out of scope:**
  - GAMS symbols, already `p45_pfm*`;
  - the madrat `calc*` names in `mrpfm`;
  - the frozen `papers/pfm-paper-v5` workspace, which is left untouched.
- **Compatibility:**
  - deprecated aliases for the old exported function names (one minor version, with a warning);
  - readers that accept either artifact name, so `output/pfm/v5/` and `output/remind-inputs/v5/` keep working
    unmodified;
  - a test that loads the `v5` group through the new code.
- **Discipline:** one isolated commit per repository (`pfm`, `remind_pfm` for
  `preparePFM.R`, the project repo for `analysis/` and `analysis/figures/`), containing nothing else, so
  the rename can be reviewed as a mechanical diff. Afterwards, update `CLAUDE.md` ("Naming") and
  close `TODO.md` 7.

**D22 — a generated scenario config.**

- `scenario_config_PFM.csv` has 83 columns per row, and almost all of them are copied from the
  parent.
- It has been hand-maintained since 2026-09-18, and the generator no longer reproduces it
  (`buildPFMScenarioConfig.R` header: "regenerating … DESTROYS work").
- The failure the generator was written to prevent — a PkBudg1000 family carrying a PkBudg750
  parent's switches — is therefore back in play.
- v6 adds an SSP axis, which roughly triples the rows.

---

## 3. Master checklist — every item this plan must cover

Each item names the phase that closes it (P0–P6) and its source.

### A. The methodology document's own "Next implementation steps"

- [ ] **A1 — Next step 1: the anchored gap with mean-gap strength.** Implement $q$, $u$, $G_s$,
      $k_s$, φ(t) in R (P1 prototype, P3 coupling), with the checkpoint convergence rule and the
      all-period diagnostic (D5). Run held-price and held-budget at both resolutions (P5).
- [ ] **A1a — time horizon:** no hold year in the central case; hold-2060 as the sensitivity (D6;
      P5). Revise `MODEL.md` §7 through ADR 0052.
- [x] **A1b — stability and damping:** damping in R, logged, used only on oscillation (D5; P3).
      ✅ Code 2026-10-07 (`.pfmV6Damp`), awaiting the Phase 3 gate runs.
- [x] **A1c — interface changes:** history file stores φ(t) and $k_s(t)$ per call; time-indexed
      φ for ratio mode and the rule-C rebuild (D14; P3). ✅ Code 2026-10-07 (`COUPLING.md` §14).
- [ ] **A1d — SSP level and spread:** $k_s$ per SSP; declared spread as an SI arm (D11; P5).
      **Deferred beyond this paper version** (decision 7 of §7a): the SSP machinery stays, the
      `v6` paper is SSP2 only.
- [ ] **A2 — Next step 2a: panel to 2023.** Verify that CAPMF, WGI, V-Dem and the energy data
      cover 2023 without imputation (CAPMF is in the vintages through 2023: GP-19 /
      `input-vintages.rds`). Move the anchor and the trend freeze year to 2023 (D8; P2).
      **Coverage verified and the panel definition built, 2026-10-02:** every source covers 2023;
      the energy data need the IEA 2025 edition, which is complete for 2023 (`DATA.md` §4). The
      definition (years, smoothing, IEA edition) is a recorded Run-Group property
      (`pfmPanelDef`, `config.yml` `panel:`). Open: the anchor and trend freeze year, in the sweep.
- [x] **A3 — Next step 2b: SSP projections.** ✅ **Done 2026-10-02.** `calcSSPextensions(subtype =
      "drivers_SSP1…5")`; `panelDataScenario(ssp, institutions)`; GDP, population and the
      extensions by SSP; the institution rule (D9, D10; `DATA.md` §5). The SSP reaches the
      coupled run from `cm_GDPpopScen` and the offline steps from the registry key `ssp`.
- [x] **A4 — Next step 3: geothermal in the hydro/nuclear control.** ✅ **Code done 2026-10-02.**
      Both sides compute the share in `pfm::iamCalculatedDrivers()` from `pegeo`, which history
      (IEA) and the REMIND downscale already carried; it is the panel-definition field
      `geothermal` (`v5` false, `v6` true), so `v5` rebuilds unchanged. 29 countries move by more
      than 0.01 (`DATA.md` §3). Refit inside the one re-sweep (D8; P2).
- [x] **A5 — Next step 4: actor-power clamps.** ✅ **Code done 2026-10-02** as decided in D7: the
      four actor-power forms selected under the actor-power extrapolation gate, composite specs
      dropped, other clamps kept (`config.yml` `sweep:`). Open: report `driverOutOfSupport` per year
      with every run (P3).
- [ ] **A6 — Next step 5: annual estimation** as a robustness rung on `v6` (D3; P2). The sibling
      group `v6-annual` is declared in `config.yml` (`panel: groups:`); it runs with the sweep.

### B. Problems in the methodology document itself (fix before it is used as the spec)

- [ ] **B1** — The spread $d_s$ is defined twice: as model-derived ($D_s(t)/D_s(2025)$) and as
      declared per storyline. Adopt D11 and rewrite the section.
- [ ] **B2** — The convergence tolerance $\text{cm\_pfmConvTol}/\theta$ is undefined at θ = 0 (the
      nulls). Adopt D5.
- [ ] **B3** — $\varphi_{r,s}(2022)$ and $k_s(2025) = 1$ are mixed. Adopt D4 and write it once.
- [ ] **B4** — "No hold year (default)" conflicts with `MODEL.md` §7 ("no scenario differences past
      ~2060"). Resolved by D6 in favour of the methodology: `MODEL.md` §7 is revised, and the
      prohibition becomes the per-year out-of-support reporting duty.
- [ ] **B5** — The logit-scale hold is presented as one limitation among six. It is the source of
      every movement in $k$ (D2). Promote it to the formulation section, and add the $E$-hold bound.
- [ ] **B6** — φ can leave [0, 1] once $k_s > 1$ or $d \ne k$. Add the clip and θ's new meaning (D12).
- [ ] **B7** — The "Current scenarios" and walkthrough sections describe `v5`. Mark them as `v5`
      when the v6 version of the document is written. Several paragraphs appear twice in the docx
      (text-box duplication in the extraction; check in Word).

### C. Further model improvements proposed for v6

- [ ] **C1** — Built-in ordering tests on $u$ (uniform, permuted ×3, reversed) at both closures (D15;
      P3/P5). This is the v6 form of GP-24.
- [ ] **C2** — A declared closure arm on the strength, $\kappa$ (D13; P5), replacing `GAPCLOSE`.
      **κ declared 2026-10-08:** 0.027 a year (the drag halves by mid-century), sensitivities 0.02 and
      0.05, rule B and C each (ADR 0050 decision 5). Open: the six wave-2 runs.
- [ ] **C3** — Decompose $k_s(t)$ by driver group: actor power (the REMIND feedback), institutions
      (SSP), controls (income, population), plus a composition term. This is the mechanism figure,
      and the v6 form of `TODO.md` 4 (P1 prototype, P6 figure).
- [ ] **C4** — Regional strength $k_{r,s}$ as one SI arm (D16; P5).
- [ ] **C5** — $E$-hold (static-share) bound as one SI arm (D2; P5).
- [x] **C6** — ✅ **Done 2026-10-07** (`pfm::runPFMAnchor`, step `pfm-anchor` after `pfm-donor`;
      `pfmAnchorFor()` reads it). 28 KB on `v6`; $k(t)$ from the artifact alone equals Phase 1's
      exactly, at both resolutions. Was: a precomputed **anchor artifact** per Run-Group (`phi-anchor.rds`: $q_{c,s}$,
      $u_{r,s}$ per resolution, weights, provenance shares). It is written by a new step after
      `psm-donor`, so the in-REMIND call no longer needs the ECM, `temporal-validation.rds` or the
      seed panel (P2/P3).
- [ ] **C7** — Propagate the anchor-year uncertainty to the coupled share: rank intervals,
      frontier rungs and the spec band, all now on the delivered object. Offline first (P1/P6);
      coupled only for the rung that moves the floor region.
- [ ] **C8** — Seam test at the anchor: $\eta^{scen}_{c,s,t_a} = \eta^{hist}_{c,s,t_a}$ per country,
      after `panelDataScenario()`'s harmonisation. A seam would enter $k$ directly (P1 acceptance
      test, `PITFALLS.md` §21).
- [x] **C9** — ✅ **Re-examined 2026-10-07** (`analysis/v6/ceilingGate.R`, `phase1/ceiling-gate.rds`).
      The deployed spec passes by a wide margin: 1.21 (Bulk) and 1.27 (Diffuse) against 0.90 (v5:
      0.003). 12.5% of covered Bulk ceilings fall by 2100 on PkBudg1000 (v5: 75%). **But under v6
      the gate decides the sign of Bulk $k$:** the 4 pool specs it alone rejects are all family A
      (satAP; three `splitAPpc`, plus X-1860 satAP), with Bulk ceilings at 0.64–0.72 and Bulk
      $k_{2050}$ on PkBudg1000 of 1.31–1.54 (`phase1/spec-band-ceilingRejected.rds`). The gate is
      ADR 0043's (2026-08-23, before any `v6` result), and it targets the same thing as decision 6:
      incumbent interactions extrapolated below the observed incumbency. **Kept for `v6`, flagged
      for revision** (§7a decision 8): its consequence is reported in the SI with family B. Was:
      re-examine the ceiling-fall gate (`TODO.md` 11a). Under v6 the ceiling trajectory
      *is* the driver of $k$: 75% of Bulk ceilings fall by 2100 on `v5`, and the gate passes by
      0.003. Re-check it on the `v6` spec (P2).
- [ ] **C10** — Report the out-of-support share per year beside every $k_s(t)$ (P3/P6).
- [ ] **C11 (optional)** — The price–efficiency elasticity, the only empirical route to θ
      (`TODO.md` 8, GP-6). A separate workstream; it cannot block v6.

### D. Referee and gap-plan points from `papers/pfm-paper-v5` that belong in v6

- [ ] **D-M1 (review-v16 M1, GP-24)** — What the *estimated* ordering adds to size and location.
      Run the uniform and permuted arms in the v6 core batch (C1; wave 2). **Not run on `v5`**
      (author's decision, 2026-10-01). Phase 1 gives an offline first read on `v5` artifacts at
      no cluster cost.
- [ ] **D-M2 (v16 M2, GP-23)** — The held-budget horn.
  - (i) State the arithmetic: implied $1/\bar\varphi$ against the realised anchor (wording).
  - (ii) Run rule C under the all-median and all-low assignment rules (P5).
  - (iii) `chinaseed` is moot under v6, which reads 2022 by construction. Record that as the answer.
- [ ] **D-M3 (v16 M3, GP-4/9/16)** — The deposit. Build it into v6 from the start: version
      control (D20), tagged `pfm` / `mrpfm` / fork commits per batch, run configurations,
      `analysis/` promoted to package code (F5), a Zenodo deposit at submission (P6).
- [ ] **D-M4 (v16 M4)** — The within-region split is read against a sector ordering it does not
      share, because of the per-sector min–max. Write it into Methods and Results of the new paper,
      and add a diagnostic: which sector binds per region, country vs region (P6).
- [ ] **D-m1…m10 (v16 minors)** — Carry them as a drafting checklist into the new workspace:
  - one denominator per share;
  - the convergence-audit criterion, not "stopped before the cap";
  - "machinery changes nothing" scoped to the budget family;
  - both resolutions quoted for the markup-off anchor;
  - roundings at the bundle's precision;
  - Abstract ≤ 150 words with no undefined terms;
  - the near-1:1 point in Fig. 1b;
  - the limits list relabelled;
  - name which rule moves the cost by 8.3%;
  - the stale claims header and `REPRODUCE.md` paths.
- [ ] **D-GP2** — The offline bound at a held gap. Under v6 the offline bound is λ-free
      automatically. Recompute it with the v6 formulation so it is consistent with the coupled
      result (P6).
- [ ] **D-GP5** — The binding-sector attribution across frontier variants. Under v6 the ranking is
      at 2022, so the rung propagation is offline and cheap (P1/P6). Coupled only if the floor
      region changes.
- [ ] **D-GP8 / GP-11 / GP-13 / GP-15** — The income screen, the GovEff correlate of the shortfall,
      the residual ordering and the trend cancellation. Re-run each on `v6` with the existing
      scripts. Under v6 the GP-13 "coupled version" needs no code hook, because the delivered
      ranking *is* the 2022 regional ranking (P6).
- [ ] **D-GP20 / GP-26** — Dissolved by D1. The new paper reports the `v5` → `v6` ordering change
      as the evidence for the switch (P6).
- [ ] **D-GP27** — Implemented by v6 (A1, A3).
- [ ] **D-A1…A7 (decisions-v18)** — The Methods account of the projection to the tier year is
      replaced: no projection, logit-scale hold, strength factor. Rewrite M6 and SI S2 / S13 in the
      new workspace (P6).

### E. Fixes needed in the current code and structure

Blocking for Phase 0:
- [x] **E1** — ✅ committed (`d6d5ac0`), in `v5-final`. Was: `pfm` had uncommitted work: the 0.4.1 `phi-override` hook (`R/psmPhiOverride.R`,
      `R/iterativePFM.R`, `DESCRIPTION`, test, man page). Commit it **as it stands, before the
      rename**, so the rename diff contains nothing else. It is the `v5` record of the prepared
      GP-23 / GP-24 instrument, and D15 supersedes it for v6.
- [x] **E2** — ✅ committed and pushed, in `v5-final`. Was: `remind_pfm` had uncommitted changes: `scripts/start/preparePFM.R` (copies the
      override) and `config/scenario_config_PFM.csv` (18 GP-23 / GP-24 rows, now never to be run on
      `v5`). Commit them as they stand, before the rename, then push. The v6 config is generated
      (D22) and drops those rows.
- [x] **E3** — `models/pfm-reports` was deprecated and archived on 2026-10-01 (`../_archive/_wip/2026-10-01/models/pfm-reports`); `pfm` no longer shells out to it.
- [ ] **E4** — partly done: `analysis/`, `analysis/figures/` (code) and the governed docs are in the project repo since 2026-10-01; still outside version control: `../communication/` and `papers/pfm-paper-v5/` (author: deferred to the v6 paper). Was: `analysis/`, `analysis/figures/`, `../communication/`, `papers/pfm-paper-v5/` and the governed docs are not
      under version control (`TODO.md` 39) → D20. (`paper/` was archived on 2026-10-01.)

Latent defects (P0 unless noted):
- [x] **E5** — ✅ **Done 2026-10-02** (`pfm` 0.5.1): defaults `group = "v5"`,
      `weightYear = 2025`; help and comments corrected; `nTiers` documented as tiered-rule only.
      Was: `iterativePFM()` defaults are stale. `group = "psm-country-v3"`. `weightYear = 2050`,
      while the deployed runs use 2025 via `preparePFM.R`, so an offline call silently uses
      different weights. The help text points to `docs/psm-coupling-scenario-design.md`, which does
      not exist. Comments say "phi is time-invariant by construction (tiers fixed at 2022)". `nTiers`
      is unused under the continuous rule. Fix the defaults and comments.
- [ ] **E6** — `projectFeasiblePath(rule = "frozen-gap")` returns NA on the coupled scenario frame:
      the seed ceiling comes from the earliest frame year (0004 caveats). Replace it with the v6
      anchor computation (C6) rather than patching it (P1). *Waits for Phase 1 (C6).*
- [ ] **E7** — `v5` inconsistency: covered countries are λ-projected while uncovered ones hold
      $E$, inside one regional aggregate (D1). Removed in v6. `papers/pfm-paper-v5` is not submitted (D19), so it
      needs no disclosure. The new paper's `v5` → `v6` comparison names it as one reason for the
      change.
- [x] **E8** — ✅ **Done 2026-10-02.** The convergence delta written to `p45_pfmDelta` is now the
      largest change over the floor φ **and every per-market share** (`.pfmPhiDelta`);
      `pfm-phi-history.rds` records the market shares with each call (`COUPLING.md` §5). The rest of
      D5 (the φ *path* over checkpoint years) comes with the time-indexed φ in Phase 3.
      Was: convergence checks only the economy-wide floor φ, not the per-market shares (D5; P3).
- [x] **E9** — ✅ **Done 2026-10-02.** SSP2 was hard-coded in the scenario panel and in
      `calcSSPextensions()` (D9; P2); both now take the SSP.
- [x] **E10** — ✅ **Done 2026-10-02.** The file was git-ignored (REMIND ignores `input/`), so it
      was moved to `../_archive/_wip/2026-10-02/` rather than committed away. `datainput.gms` sets
      φ = 1, λ = 0 before its `$ifthen exist` include, so runs now start uncoupled until the first
      call. H12 runs had been starting from its stale shares; EU21 runs ignored it. **The cluster
      checkouts may hold their own copy: delete it there by hand.**
      Was: the stale seed `input/p45_regiDiff_feasibility.inc`, an H12-shaped export from
      2026-08-10 (`TODO.md` 20).
- [x] **E11** — ✅ **Done 2026-10-07** (`p45_pfmBudgetPeak*_iter`, warning at the cap). Was: No GAMS peak-budget check next to `pm_pfmBudgetWarn` (`TODO.md` 32, `PITFALLS.md`
      §26). Add it in the P3 GAMS pass. *Analysis side in place: `extractCoupledResults` reports a
      budget-forced run that never peaks, and `runCoupledStage.R` prints it (F4).*
- [x] **E12** — ✅ **Done 2026-10-07** (`p45_pfmBindShare_iter` in mode 1). Was: No bind-share diagnostic for mode R (`TODO.md` 21). Needed if ratio mode stays as
      rule C's sensitivity (P3). Mode M is retired (D13).
- [x] **E13** — ✅ **Done 2026-10-02** (`pfm` 0.6.0). The sanity walk raises a severe
      `frontierVcov` flag for the statuses in `vcovGate` (default `likelihood-mismatch`, `flat`).
      `corrupt` is not gated, because the recomputed matrix replaces FRONTIER's (TODO 14f);
      `boundary` stays the γ gate's. The status is recorded for every evaluated spec.
      Was: nothing screens a corrupt frontier covariance in `runPSMSweep()` (`TODO.md` 40).
- [x] **E14** — ✅ **Done 2026-10-02.** `.driverSupportRanges()` excludes the trend from the guard
      (`TODO.md` 11a): kept, and documented why — the projection freezes the trend at the last panel
      year (`projectFeasiblePath`), so guarding it is a no-op.
- [x] **E15** — ✅ **Done 2026-10-02.** The stale `psm` comment is fixed; the keys no code reads
  are removed (`outputDir`, `dashboardModelsDir`, `couplingRegionMapping` and the hurdle model's
  `modelName`, `regionMappingFE`, `includeLagged`, `adoptionThreshold`); the registry carries the
  SSP dimension (`ssp`, `institutions` per entry, explicit `ssp: SSP2` on the pair). SSP1/SSP3
  entries are added when their `v6` gdxs exist.
  Was: `config.yml` is stale (comments reference `psm-country-v4`; only the SSP2 pair; legacy
  hurdle keys).
- [x] **E16** — ✅ **Done 2026-10-07** (F1, ADR 0055). Was: The scenario-config generator is out of sync with the hand-maintained CSV
      (`buildPFMScenarioConfig.R`, 🔴 note) → D22 (P4). *Waits for the Phase 3 switches the v6
      matrix is made of (formulation, hold year, κ).*
- [x] **E17** — ✅ **Done 2026-10-02.** Profiled on a replay of `v5`'s EU21 `-PFMlevelBfix`
      (workstation): **99 s per call**, 95% in `panelDataScenario()` — the institution projections
      (`toolProjectScenario`) 38 s, the downscaling of REMIND results (`toolIPFDownscale`) 29 s, the
      harmonisation's historical panel 9 s. The first two were element-wise magpie indexing; both now
      go through plain arrays (`mrpfm`, output `identical()`). The historical panel is cached in the
      run folder (F7). **Now 27 s for a run's first call, 11 s for every later one**; the replayed
      shares are unchanged (max |replay − run| 0.0395 before and after). That gap turned out to be
      the region mapping, not the cache: see E26.
      Was: each PFM call takes 128–189 s (median 159 s, `TODO.md` 9).
- [x] **E18** — **Done 2026-10-01.** Non-governed files left `docs/`:
      - `PFM-Methodology.docx` and `MODEL_NOTATION_TABLE.html` → `../communication/methodology/`;
      - `LAMBDA-EXPLAINED.html` → `output/pfm/v5/lambda-explained/`;
      - the two `pfm_*coupling*.md` notes → `../_archive/_wip/2026-10-01/docs/`.

      See `../_archive/_wip/2026-10-01/MOVES.md`.
- [x] **E19** — ✅ **Done 2026-10-02** (`paper-forge` `bdb7eb5`). Manifest source paths are relative
      to the project; the data check now resolves them against every folder above the paper root
      too. From inside `papers/pfm-paper-v5/` the old check reported 42 of 42 sources missing, the
      fixed one reports the bundle complete. The frozen `v5` workspace keeps its copy.
      Was: `paper-check` run from inside `papers/pfm-paper-v5/` reports every data source as missing.
- [x] **E20** — **Done 2026-10-01** (`../_archive/_wip/2026-10-01/MOVES.md`).
      - Root clutter, `_bckp/`, `tmp/` and `slide_assets/` were archived.
      - Run-Groups `v1`–`v4` (output, gdx, output/remind-inputs), `paper/`, `data/runs/` and 12 dead
        `analysis/` scripts were archived.
      - `output/remind-runs/` now holds runs as `output/remind-runs/<group>/<resolution>/`.
      - `paper-skills/` (locked when the move ran) was moved by the author afterwards
        (`../_archive/_wip/2026-10-01/paper-skills/`).
      - The layout is described in the root `README.md`.

Found by the local reproduction test of 2026-10-01 (`../_archive/_wip/2026-10-01/docs/RUNNING.md`, §6):
- [x] **E21** — With the Fit Cache in its own folder, the fitted panel was not found, and every
      step silently rebuilt it from madrat. **Fixed** in `pfm` (`.psmPanelCandidates()`, with a
      test). The fix must be committed and pushed before any v6 run.
- [x] **E22** — `pfmReplayInterface()` looked for REMIND at `../remind_pfm` and skipped silently.
      **Fixed** (searches `models/remind_pfm*`).
- [x] **E23** — ✅ **Done 2026-10-02.** `startRun()` raises an error after the manifest and the
      last log lines when a run ends `failed` or `incomplete` (`failOnGaps = TRUE`), so `Rscript`
      and the SLURM job exit non-zero; a NOT REFRESHED artifact is moved aside to `<file>.stale`
      (`PITFALLS.md` §18).
      Was: a step that fails inside still lets `pfmRun()` exit 0, and the previous artifact stays.
- [x] **E24 — decided: ADR 0047** — The coupling inside REMIND read madrat's default cache
      (PIK's shared cache), while estimation read `data/madrat`. On `v5` the two held different
      FE/PE versions, and those versions moved a regional share by 0.14 in a local refit.
      **Done 2026-10-01:**
      - one prepared cache per Run-Group (`data/madrat/{group}`, `pfmPrepareCache()`), run by
        `tools/setup.sh` and `pfmRun()`;
      - the REMIND export stages its coupling files, `preparePFM.R` copies them into the run
        folder, and `iterativePFM()` reads them;
      - replay test: all 11 staged files read, nothing else;
      - machine paths in `config.yml` `madrat:`; the environment variable is gone.
- [x] **E26** — ✅ **Found and fixed 2026-10-02** (`pfmPreflight`, cluster). The H12 and EU21
      mappings bundled with `mrpfm` are a **future update** of the region definitions: 15 countries
      in other regions than REMIND solves on (Ukraine, Georgia, Moldova, Mongolia, North Korea,
      Greenland, four Sahel states, five small territories). The workstation's REMIND input data
      (`C:/_data/work/remind_input_data/mappings`) holds the same future version; the cluster's
      (`/p/projects/rd3mod/inputdata/mappings`) is identical to the fork's `config/`
      (`tools/compareMappings.R`).
      - **What used which.** The `v5` **coupled runs** (cluster) aggregated with REMIND's regions.
        The `v5` Run-Group's downstream steps were computed **on the workstation** (manifest: host
        `LT1177`, local, 2026-09-15: frontier, temporal, sector speeds, donor, projection, coupling
        bound, REMIND export), so those that aggregate to H12/EU21 - the offline coupling bound
        (`coupling-summary.rds`) and the regional projections - used the future regions. The fitted
        model is at country resolution and its fixed-effects mapping (`regionmapping_EU_OECDp`) is
        not affected. `v5` is frozen: this is recorded, not repaired.
      - **Fix (author: keep the regions consistent with REMIND).** The bundled copies are now the
        fork's `config/` files; the future ones are kept as `regionmappingH12_future.csv` /
        `regionmapping_21_EU11_future.csv`; `pfmPreflight()` checks the resolved mapping against
        REMIND's `config/` (so a machine whose mappingfolder holds the future version fails it).
      - **Effect.** The workstation replay of `v5` `-PFMlevelBfix` moved from max |replay − run|
        **0.0395 to 0.00226** (tolerance 0.002): the "cluster-cache gap" was almost all mapping.
- [x] **E27** — ✅ **Found and fixed 2026-10-03** (the cluster's first `v6` cache). The outcome's
      coverage filter (`calcPolicyStringency`: drop every country of a region whose data-bearing
      members cover less than 80% of its GDP or population) grouped countries by madrat's **global**
      `regionmapping` setting, which madrat's cache key does not cover. `pfmPrepareCache()` copied a
      result from a shared cluster cache that had been filtered by other regions, and under
      `forcecache` it was loaded as this group's: **37 countries with both outcomes in 2021-2023
      instead of 48**. Now the regions are an argument (`coverageMapping`, mrpfm), passed explicitly
      by `panelDataHistorical()`, so they enter the cache key; checked locally: the explicit call is
      computed under the country mapping and keeps 49 countries. The legacy (`v5`) call is left as
      it was so its cache file keeps its name; its copy was computed under the country mapping and
      holds 49 countries. General lesson (`PITFALLS.md` §3): under `forcecache` a copied file is
      trusted on its name alone - anything a calculation reads from the global madrat configuration
      must be an argument.
- [ ] **E25** — Under `forcecache`, madrat reads the newest-timestamped file among those whose
      arguments match. **For new groups, solved by ADR 0047**: the prepared cache holds one
      version of each calculation, and its `cache-manifest.tsv` is the record. Deposit those
      files with the version. **Still open for `v5`:** fetch the 48 shared-cache files its
      coupled runs read from `/p/projects/rd3mod/inputdata/cache` before they are cleaned up
      (`records/v5/madrat-cache-used-runs.tsv`).

### F. Refactors to make model and scenario runs easier to create and submit

- [x] **F1 — Scenario matrix → generated config (D22).** ✅ **Done 2026-10-07**:
  `pfm::buildPFMScenarioConfig()` + `analysis/run-groups/scenario-matrix-v6.yml` →
  `config/scenario_config_PFM_v6.csv`, 54 coupled runs (wave 1: 20, wave 2: 34), tags `V6W<wave><res>`;
  the bases, `-PFMgateRef` and the gate rows come out identical to the hand-written ones. The v6
  option columns are declared in the fork's `default.cfg` (REMIND's reader stops on unknown columns).
  κ was declared on 2026-10-08 (0.027, with 0.02 and 0.05; ADR 0050). One YAML lists:
  - the canonical parents per SSP and resolution;
  - the arms (closure, θ, markup, ordering test, hold year, spread, κ);
  - the Run-Group per arm;
  - the warm-start chain and the start tags.

  `buildPFMScenarioConfig()` writes the CSV, and `validatePFMScenarioConfig()` runs on the output.
  Section separators and `path_gdx` chains are generated, not typed. Adding an SSP becomes one line.
- [x] **F2 — `pfmPreflight()`.** ✅ **Done 2026-10-02.** Every check below except the anchor
      artifact, which joins with F6. "Installed equals the working tree" compares a fingerprint of
      every function, not the version. On the workstation it found the local REMIND checkout's own
      library has no `pfm` (expected: REMIND does not run there).
      One call, before any submission, checking what `PITFALLS.md` §1–§3 and §23 leave to memory:
  - every sub-repo is clean and pushed;
  - the `pfm` version *installed in the run library* equals the working tree;
  - every `pfmGroup` named in the start group exists in `output/remind-inputs` with its anchor artifact;
  - the mappings are installed;
  - the replay harness and negative control pass;
  - the SSP is consistent across row, NPi reference and anchor donor (D9).

  It refuses to proceed on any failure.
- [x] **F3 — A submit wrapper.** ✅ **Done 2026-10-02** (`RUNNING.md` step 7): preflight, the
      config validator, `start.R --test`, the plan; with `dry = FALSE` the batch manifest
      (`output/remind-runs/batches/`) and `start.R`. Tested with the REMIND calls mocked: the
      workstation's REMIND library lacks `gms`, so `start.R --test` cannot run here.
      `submitPFM(startgroup, dry = TRUE)` runs the preflight, prints the
      rows and Run-Groups it will start, then calls REMIND's `start.R`. It records the commits used
      into a batch manifest (this answers the per-run provenance that `runProvenance.R`
      reconstructs today after the fact).
- [x] **F4 — A post-batch stage.** ✅ **Done 2026-10-02 as `analysis/coupled/runCoupledStage.R
      <group>`** (`RUNNING.md` step 10): the chain below, stopping on §25/§25a. It is project
      tooling that runs the `analysis/` scripts; it becomes `pfmRun(stage = "coupled")` when F5
      moves them into `pfm` (a package shelling out to project scripts is what `pfm-reports` did).
      Checked on the `v5` batch under a scratch group: 89 runs admitted (1 unfinished, on the
      §25a test), every step ran, and `coupled-facts.json` equals `v5`'s in every value.
      Was: `pfmRun(stage = "coupled", batch = …)`. It runs, in order:
  - `extractCoupledResults`, then its flags;
  - `coupledBatchFacts`, `coupledCostsAndAbatement`, `heldBudgetPrices`, `ruleCBoundFreeze`,
    `coupledRunConvergence`, `runProvenance`.

  It writes `coupled-facts.json` stamped with the Run-Group, and **stops on the §25 / §25a
  admission rules** instead of leaving them to the reader. This is today's checklist after a batch
  lands, as one command.
- [ ] **F5 — Promote the reproduction-chain scripts into package code.** *After Phase 3: the
      extraction reads the coupling symbols, which the time-indexed φ interface (D14) changes.* Move the `analysis/`
      scripts the paper's numbers depend on (the F4 list, `makeGroupVariants.R`,
      `buildPFMScenarioConfig.R`, `validatePFMScenarioConfig.R`) into `pfm` (compute: extraction,
      facts) or `analysis/figures/` (rendering), with tests. One-off scripts stay in `analysis/`. This is
      the code half of the deposit (D-M3).
- [x] **F6 — The anchor artifact as a pipeline step** (C6). ✅ **Done 2026-10-07:** in the
      `downstream` stage; `runPFMExportREMINDInputs` ships it, and refuses when a completed
      `pfm-anchor` step left no file; `preparePFM.R` copies it into the run folder (and removes a
      stale one); `pfmPreflight` fails an export whose manifest records the step without the file.
      `pfmRun(stage = "remind")` exports it
      with the rest. The in-REMIND call then reads one small file instead of re-deriving the ranking.
- [x] **F7 — Cache the exogenous scenario panel per SSP** (E17). ✅ **Done 2026-10-02**, measured:
      the harmonisation's historical panel, with the state it leaves for the scenario panel, is built
      on a run's first call and read from `pfm/hist-harmonisation-cache.rds` afterwards (keyed on
      every argument). Done in `iterativePFM()` rather than `preparePFM`: same effect, nothing to
      keep in step. The institution projections no longer need a cache (0.2 s). 27 s → 11 s per
      later call; the second call's shares are identical to the first's.
      Was: cache it in `preparePFM`; measure before and after.
- [ ] **F8 — Typed options instead of side files.** *The institution rule is already typed
      (`pfm-coupling.yml` `institutions`); the rest are Phase 3 switches.* Ordering tests (D15), hold year (D6), spread
      (D11), κ (D13) and the formulation switch become `pfm-coupling.yml` or runtime-config fields.
      Each is echoed in the log and recorded in `pfm-phi-history.rds`. `phi-override.yml` is kept
      only for `v5` reproduction.
- [x] **F9 — The `psm*` → `pfm*` rename** (D21): the first step of Phase 0. One isolated commit
      per repository, with read-aliases for `selected-models-psm.yml`, the `psm-*` step names and
      the old exported functions. ✅ Done 2026-10-02; see Phase 0, step 1.

### G. Documentation and governance

- [x] **G1 — ADRs** (P1 drafts, accepted at the P2/P3 gates). **Drafted 2026-10-07**, all seven, status
  *Proposed*. **0051, 0052, 0053 and 0055 accepted 2026-10-07** (author); **0049, 0050 and 0054 accepted
  2026-10-08** (author) at the Phase 3 gate. *Renumbered 2026-10-06: 0047 went
  to the prepared madrat cache (E24) and 0048 to the soft selection keys, so the planned records
  start at 0049.*
  - 0049 anchored gap with logit hold and mean-gap strength (D1, D2, D4, D12);
  - 0050 λ removed from the coupling, mode M and `GAPCLOSE` retired, the κ arm (D13);
  - 0051 SSP-consistent scenario panel and accountability rule (D9, D10, D11);
  - 0052 saturating actor power (family A in the main text, family B in the SI, the shape sensitivity), clamp policy and hold year (D6, D7, decision 6 of §7a);
  - 0053 the `v6` panel: 2023, geothermal, one re-sweep (D3, D8);
  - 0054 time-indexed φ interface and convergence on the φ path (D5, D14);
  - 0055 the generated scenario config (D22).
- [ ] **G2 — Close the design notes.** 0003 (λ in or out) → ADR 0050. 0004 → ADRs 0049 / 0052 /
      0053. 0002 stays open, informed by the re-sweep. This note → closed when Phase 6 ends.
- [ ] **G3 — Archive the governed documents first** (`_archive/<date>/docs-pre-v6/`), then rewrite
      them for `v6`:
  - `MODEL.md` §4 shrinks to "diagnostic only"; §5 gets the v6 φ(t); §7 gets the hold-year rule;
  - `COUPLING.md` gets the new symbols, switches and convergence rule;
  - `SCENARIOS.md` gets the v6 matrix;
  - `PITFALLS.md` gets the new traps (P3 lists them);
  - `TODO.md` is reset;
  - `EXPLAINER.md` and `PRESENTATION.md` get the new one-page story;
  - `CONTEXT.md` gets the new terms: anchor year, strength factor, logit hold.
- [ ] **G4 — Update `../communication/methodology/PFM-Methodology.docx` to v6** once Phase 1 has numbers (B1–B7).

---

## 4. Implementation phases

### Phase 0 — The rename, then unblock and clean (about a week; workstation only)

0. **Snapshot what exists, unchanged** — the precondition for an isolated rename diff, not separate
   work.
   - Commit E1 (`pfm`) and E2 (`remind_pfm`) as they stand.
   - Freeze-tag the `v5` state in every repository, e.g. `v5-final`, so `papers/pfm-paper-v5` can always be
     rebuilt from a named commit.
   - Create the project repository for `pfm-workspace/` (formerly `_wip/`; D20) with its first commit = today's tree. Its
     `.gitignore` excludes `data/`, `output/`, `output/remind-runs/`, `output/remind-inputs/`, `_archive/`, `_bckp/`, the
     sub-repos and the large binaries.

   ✅ **Done 2026-10-01/02.** E1 and E2 committed; the project repo created and pushed; `pfm-reports`
   archived (E3). `v5-final` is tagged and pushed in the project repo (`0a974c5`), `pfm` (`973ea5e`),
   `mrpfm` (`0db350a`), `remind_pfm` (`a36c41495`) and `paper-forge` (`ab52f1e`), after a
   reproduction check on a fresh clone of exactly those commits. The check matched the
   2026-10-01 baseline (`../_archive/_wip/2026-10-01/docs/RUNNING.md` §6.3): 16 of 21 shared
   artifacts reproduce with the 5 known differences, `pfmReplayInterface()` passes,
   `start.R --test` gives 0 errors, and the paper bundle rebuilds byte-identical.
   **Not covered by the tag:**
   - `papers/pfm-paper-v5` has no version control (author's decision: a repository may come
     only with the v6 paper);
   - 8 of the 12 madrat files pinned in `records/v5/` exist only in this workstation's
     `data/madrat/` (`RUNNING.md`, still to do 3);
   - the 45 shared-cache files the coupled runs read are not fetched (still to do 7).
1. **The `psm` → `pfm` rename (D21, F9)** — before anything else is changed.
   1. Inventory every `psm` / `PSM` occurrence per repository. Classify each as function, step,
      artifact file name, option, documentation or comment.
   2. Rename in `pfm`, `models/remind_pfm/scripts/start/preparePFM.R`, `analysis/`,
      `analysis/figures/`, `config.yml` and the governed docs. Leave `papers/pfm-paper-v5/` and `_archive/` untouched.
   3. Add the compatibility layer: deprecated function aliases, artifact readers that accept either
      name, step-name aliases in `pfmRun()`.
   4. Verify:
      - `devtools::test()` and `devtools::check()` pass in `pfm`;
      - `pfmRun(group = "v5", stage = "downstream")` in dry-run mode resolves every `v5` artifact
        through the aliases;
      - `preparePFM.R` stages `output/remind-inputs/v5/` (old names) and a group exported under the new names;
      - `papers/pfm-paper-v5`'s `paper-data` rebuild (`papers/pfm-paper-v5/paper-data/run.R`) still reproduces its manifest
        hashes from `output/pfm/v5/`.
   5. One commit per repository, nothing else in it. Push. Then update `CLAUDE.md` ("Naming") and
      close `TODO.md` 7.

   ✅ **Done 2026-10-02**. Released as **`pfm` 0.5.0** through `lucode2::buildLibrary`, its
   first validated build since 0.3.0. Clearing the linter refactored `computeMaximinScore`,
   `.pfmFrontierVcov` and `.pfmApplyPhiOverride`; each was checked `identical()` to its
   original, the first on `v5`'s 4 396-spec sweep over 144 setting combinations.
   - **Inventory.** About 1 480 hits in `pfm`, 244 in the project repo, 4 in `preparePFM.R`.
   - **Renamed:** 21 exported and about 65 internal functions, 31 source and test files, the 17
     step names, `selected-models-pfm.yml`, the log tags (`[PFM-BOUND]` …) and the prose
     (*Political Feasibility Model*).
   - **Compatibility.** `.pfmSelectedModels()` reads either spec-file name, and writers use the
     new one. `.pfmLegacySteps()` maps `psm-*` in `pfmRun`, `startRun`, `runModelGroup`,
     `pfmStepArtifacts`/`pfmCleanSteps` and `runStatus`. `pfm-sweep` resumes on `sweep.rds`,
     which old and new groups both have. 21 deprecated aliases warn and forward
     (`R/pfmDeprecated.R`). `preparePFM.R` accepts either marker.
   - **Kept on purpose:**
     - the bootstrap digest's internal `"psm"` tag. Since 2026-10-02 new cache entries are
       `pfm-<estimator>` and `pfmboot_`, and pre-rename `psm-`/`psmboot_` entries are read as a
       fallback (`2108de9`);
     - old Run-Group names, archived file names, the ADRs, `mrpfm`, `papers/pfm-paper-v5`.
   - **Verified:**
     - `devtools::test()`: 6 802 passed, 0 failed, including `test-pfmLegacyNames.R` (which reads
       `v5`);
     - `devtools::check()`: 0 errors, and warnings and notes identical to `v5-final`'s (the
       vignette is skipped: no pandoc on the workstation);
     - the `v5` downstream dry run resolves, and every `pfm-*` resume key exists in `v5`;
     - `preparePFM()` stages both an old-name and a new-name export, and the replay of
       `-PFMlevelBfix` gives the pre-rename result (max 0.0395, then thought a cluster-cache gap;
       it was the region mapping, E26);
     - the paper bundle reads `output/pfm/v5/` directly and calls no `pfm` function, so its
       byte-identical rebuild of 2026-10-01 is unaffected.
2. **Small fixes:** E5, E10, E13, E20. ✅ **All done 2026-10-02** (`pfm` 0.6.0). E11 and E12 go
   into the P3 GAMS pass. (Revised 2026-10-02: E5 and E20 are done. E14 moves to Phase 2, as its own entry
   says ("do it with D7"). E19 is a `paper-forge` fix needed by the paper workspace, not by a run,
   so it is due before Phase 6.)
3. **Push everything** and reinstall `pfm` on the cluster. Verify the installed version from inside
   `models/remind_pfm/` (`PITFALLS.md` §2, §23). *Workstation half done 2026-10-02; what remains is
   the cluster (pull, install, replay gate). `pfmPreflight()` (F2) now checks both the push and the
   installed code.*

**No `v5` runs** (author's decision, 2026-10-01). The ordering question (GP-24) is answered on `v6`
in Phase 5, with an offline first read in Phase 1.

**Gate:**
- every repository is clean, pushed and tagged `v5-final` before the rename;
- the rename commits contain nothing but the rename;
- `v5` artifacts and the `papers/pfm-paper-v5` bundle still resolve;
- `pfmReplayInterface()` and its negative control pass on the pushed fork.

### Phase 1 — Offline prototype on `v5` (one to two weeks; workstation only)

Extend `analysis/v6/v6FormulationTests.R`, whose part E3b already builds the logit-u hold anchored at
2025. Then move the stable parts into `pfm` as functions with tests.

1. **`computeAnchorGap(group, resolution)`** returns $q_{c,s}$ (covered from observed data;
   uncovered from band-rule $E$), $u_{r,s}$ and the provenance shares, for EU21 and H12. Test:
   uniform $u$ is all equal; θ = 0 gives φ ≡ 1.
2. **`computeStrengthPath(scenarioPanel, anchor, hold)`** returns $G_s(t)$, $k_s(t)$,
   $D_s(t)/D_s(t_0)$, the clip share and the out-of-support share. Test: $k(t_0) = 1$; with $d = k$
   the ranking is invariant in $t$.
3. **Reproduce the methodology's numbers** on the `SSP2-EU21-PkBudg1000-PFMlevelBfix` energy system:
   $k_{Diffuse} = 0.70 / 0.54 / 0.56$ and $k_{Bulk} = 1.08 / 1.18 / 1.21$ (2035 / 2050 / 2070). If
   they do not match, find out why before going further. This is the acceptance test for the code
   that later goes into REMIND.
   ⚠️ **(2026-10-06) These numbers predate the PITFALLS §28 fix.** They were computed on a `v5`
   scenario panel whose per-capita actor-power drivers fell to 1/31.5 of scale after 2040, and
   `v5`'s `X-2079` carries `Incumbent Power pc`. Reproduce them on the **defective** panel (the
   cached `output/pfm/panel-cache/v5-scen-ca.rds`, written before the fix) to accept the code,
   then recompute with the fixed panel and on `v6`. Expect 2035 to move little and 2050 / 2070 to
   move.
4. **Compute $k_s(t)$ on every `v5` gdx:** NPi, PkBudg1000, `-PFMgate`, `-PFMlevelBfix`,
   `-PFMlevelC`. Answer: how much does REMIND's energy system move $k$ between pathways? That is the
   size of the v6 feedback.
5. **Run the variants:**
   - logit hold vs $E$ hold (D2);
   - no hold (central) vs hold 2060 (D6), with the out-of-support share per year;
   - $d = k$ vs model-derived $d$ (D11);
   - regional $k_{r,s}$ (D16);
   - uniform and permuted $u$ (D15). This is the offline first read on GP-24 that replaces the
     dropped `v5` runs.
6. **SSP governance swap** (0004 §5 step 5): SSP1 and SSP3 GovEff on the SSP2 energy system, with
   SSP GDP and population if the madrat cache can build them (0004 notes the full rebuild took more
   than 10 minutes and was stopped — run it on the cluster). Measure the SSP spread of $k_s(t)$
   against the spread across θ.
7. **C3 decomposition** of $k_s(t)$ by driver group.
8. **C8 seam test** at the anchor year.
9. **The first-round headline change.** Use the offline bound machinery
   (`runPSMCouplingBound()`) with v6 φ(t) on the `v5` anchor and reference paths. This gives the
   *direction* of the change against `v5` before any REMIND run. It is labelled offline, as GP-2
   requires.

**Status 2026-10-06** (Run-Group `v6`; `analysis/v6/phase1.R` → `output/pfm/v6/phase1/`):
- ✅ **Steps 1–2.** `pfm::computeAnchorGap()`, `computeStrengthPath()` and `computeSharePath()`, with unit
  tests (`test-anchorGap.R`): $k(t_0) = 1$, θ = 0 gives φ ≡ 1, uniform $u$ gives one share, the
  ranking is invariant under $d = k$. η is built through the coupling's own preparation and guard,
  with the deployed frontier coefficients. No ECM, no λ. The covered countries' η matches
  `frontier.rds` exactly.
- ✅ **Step 3 (acceptance).** On `v5`'s pre-fix panel with the prototype's anchoring
  (`anchorRule = "t0-ceiling"`): Bulk 1.076 / 1.180 / 1.206 exactly, Diffuse 0.699 / 0.542 / 0.561
  against 0.700 / 0.544 / 0.563. The 0.002 is the prototype's ECM scaling against the frontier's own.
  The §1 anchor-year rule gives practically the same on `v5`.
- ✅ **Step 4** on `v6` (fixed panels, both resolutions; H12 within 0.003 of EU21). See `strength.rds`.
- ✅ **Step 5** (`variants.rds`), **step 7** (C3, `decomposition.rds`), **step 8** (C8, `seam.rds`; since
  2026-10-06 on the annual-interpolated panel, `PITFALLS.md` §31).
- ✅ **Cluster re-run, 2026-10-06** (lag in years, institution series harmonised; `v6` and `v6-annual`,
  `clean = "group"`). The fit side is unchanged: same selection (`v6`: X-1791 satAP; `v6-annual`:
  X-1860 satInn), frontier coefficients identical, replay identical. `v6-annual`'s Bulk replay fails
  by 4e-5 in RMSE (the ceiling binds in 1 of 1104 rows), exactly as before the fixes. Sanity pool: 9 of
  40 pass, the same set as before; bootstrap unchanged. The offline coupling bound moved: median 2050
  price at θ = 0.5 went from 182 to 173. Phase 1 on the new artifacts reproduces the workstation
  numbers.
- ⚠️ **The spec band (`analysis/v6/specBand.R`, `phase1/spec-band.rds`) splits on the actor-power
  transform.** All 9 sanity-passing specs on the `v6` panel; Bulk $k_{2050}$ on PkBudg1000:
  - satAP specs (bootstrap conditional wins 49%): 0.63 (deployed), 0.72, 0.90;
  - satInn specs (51%): 0.86–1.22.

  The deployed spec gives the strongest fall in the band. `v6-annual`'s opposite result is the spec
  (X-1860 satInn gives 1.22 on the `v6` panel too), not the panel. The Bulk institution main effects
  behind part of the fall are not identified: satP wild-cluster p = 0.6–0.9, and their signs differ
  between satP and the frontier. **The Bulk mechanism must be reported as a band, not as the deployed
  spec.** That makes the satInn rung of wave 2 (D7) a headline companion.
- ✅ **Step 6, governance part, 2026-10-07** (`analysis/v6/sspGovernanceSwap.R`, `phase1/ssp-governance.rds`).
  SSP1 and SSP3 institutions go on the SSP2 energy system: the storyline V-Dem series and the
  SSP-extension GE, rebuilt as `panelDataScenario` builds them (the SSP2 rebuild matches the panel to
  1e-16). Measure: the floor region's φ range across SSP1–3 (θ = 0.5) against θ's range
  (0.325–0.675).
  - **Diffuse:** small at all horizons (ratio ≤ 0.46).
  - **Bulk:** small to 2050 (ratio 0.15–0.25), then large (PkBudg1000: 1.2 in 2070, 1.9 in 2100).
    SSP1 institutions *raise* Bulk $k$ (0.98 in 2100 against 0.48 under SSP2). That runs through the
    Bulk institution terms, which are not identified (Phase 1 status above).

  The full version, with SSP GDP and population (SSP1 / SSP3 scenario panels, cluster,
  `pfmPrepareCache`), is **deferred with the SSP axis** (§7a decision 7).
- ✅ **Step 9, 2026-10-07** (`analysis/v6/offlineHeadline.R`, `phase1/offline-headline.rds`). OFFLINE,
  first round, EU21; v5 reference and optimal price paths; median 2050 bound at θ = 0.5, optimal $355:
  | case | bound | shortfall |
  |---|---|---|
  | v5 formulation, v6 spec | $173 | 51% |
  | v6 φ(t) with the v5-style λ speed limit | $182 | 49% |
  | v6 φ held at $t_0$ | $270 | 24% |
  | **v6 φ(t)** | **$291** | **18%** |

  The change from v5 is almost all the removal of λ (D13). The moving strength adds about 6 points.
- ✅ **ADR drafts 0049–0055, 2026-10-07** (`docs/adr/`), status *Proposed*.

**Gate, and the decision it feeds:**
- ~~**If the SSP spread of $k$ is small next to θ's range** (hypothesis H1 of the architecture note),
  the SSP axis goes to the SI as "measured and small". The main batch is SSP2 only, plus one SSP
  pair. Otherwise SSP1 / SSP3 become a main-text axis.~~ **Decided 2026-10-07 (§7a decision 7):
  the `v6` paper is SSP2 only;** the SSP axis is not reported in this version. The governance-only
  measurement above stays on record for the next one.
- ADRs 0049–0054 drafted. Methodology document updated (G4).

### Phase 2 — Data and estimation, Run-Group `v6` (two to three weeks; cluster for the sweep)

1. **`mrpfm`:**
   - ✅ `calcSSPextensions(subtype = "drivers_SSPx")` for x = 1…5 (2026-10-02);
   - ✅ geothermal in the clean-baseload control (A4, 2026-10-02; in `pfm`, panel-definition field);
   - ✅ panel inputs to 2023: coverage checked, IEA 2025 edition selected by the panel definition
     (A2, `DATA.md` §3–§4; 2026-10-02);
   - ✅ the institution rule (D10), in `pfm` rather than `toolProjectScenario()`: SSP2 reproduces
     today exactly (2026-10-02).
2. **`pfm` scenario panel:** ✅ an `ssp` argument everywhere SSP2 was hard-coded (E9, 2026-10-02;
   the `v5` scenario panel rebuilds to within 2e-15). Open: split the exogenous part, which is
   cacheable per SSP (F7), from the REMIND-dependent actor power.
3. **The REMIND-side driver computation:** geothermal included, so the scenario control matches the
   historical one. Check with the seam test (C8).
4. **The sweep (D7, D8):** the four actor-power forms under the extrapolation gate, no composite
   specs (`config.yml` `sweep:`, done); the trend freeze at the anchor year (automatic: the last
   panel year);
   the covariance screen in place (E13). Then:
   - selection, selection bootstrap, frontier, diagnostics and inference;
   - the spec band (the `v6-specalt` analogue);
   - the ceiling-fall gate re-checked (C9);
   - the annual-data rung (A6);
   - the selected spec's other actor-power forms as rungs (D7).
5. **Donor assignment at the anchor year,** then the **anchor artifact** (C6, F6). Then
   `pfmRun(group = "v6", stage = "remind")`. ✅ Code done 2026-10-07 (`pfm-anchor`); on the cluster
   it runs with the next `downstream` stage, and the next export ships it.
6. **Write the `v5` → `v6` comparison:** spec, coefficients, $E$ ordering at the anchor, regional
   $u$, floor regions. This becomes Methods and SI material for the new paper. ✅ **Done 2026-10-07:
   §8** (`analysis/v6/v5v6Comparison.R`).

**Gate:** deployed `v6` spec diagnostics at least as clean as `v5` (γ, gates, influence, sign
stability). *Passed 2026-10-06 with one disclosed exception (decision 4 of §7a):* the Bulk γ of
0.997 is accepted, below the 0.999 `gammaBoundary` gate but close to it, and is reported as such. The 2023 coverage decision is recorded (`DATA.md` §4). D10 decided 2026-10-02; the
re-sweep only says whether it matters (an accountability or V-Dem Rule-of-Law term kept or dropped).

### Phase 3 — Coupling code (two to three weeks; workstation + test runs)

**R (`pfm`):**
1. Add a `formulation` switch to `iterativePFM()` (`"v6-anchor"` / `"v5-tier"`; default
   `"v6-anchor"` for `v6` groups, read from the group's manifest).
2. The v6 path reads the anchor artifact, builds the SSP scenario panel (exogenous part cached),
   computes $\eta_{c,s,t}$ per country, then $S$, $S^*$ via $q$, $g_{r,s}(t)$, $k_s(t)$ and φ(t).
   **No ECM fit, no λ.**
3. Exports:
   - the existing symbols, carrying the $t_0$ value;
   - the new `p45_pfmPhiPath` / `p45_pfmPhiMktPath` (D14);
   - bounds built by `exportFeasibilityBound()` with φ(t) and λ ≡ 0.
4. δ on the φ path at the checkpoints; the all-period δ logged; damping only on oscillation; the
   history file stores φ(t), $k_s(t)$, δ, the all-period δ and α (D5).
5. The SSP from `pfm-coupling.yml` / the runtime config, **asserted** equal to `weightScenario`
   and to the anchor artifact's SSP-independent contents (D9).
6. Typed options: ordering test, hold year, spread, κ (F8, D15).
7. Tests: extend `test-gdxRoundTrip.R`, `test-pfmReplayInterface.R` (new symbols declared, plus the
   negative control) and `test-exportFeasibilityBound.R` (year-varying φ). Add a regression test
   against the Phase 1 offline numbers.

**GAMS (`remind_pfm`, branch `pfm`):**
1. `main.gms`: the switch `cm_pfmPhiPath` (0/1, default 0); runtime-config fields for the SSP and the
   v6 options, written by `presolve.gms`.
2. `declarations.gms` / `datainput.gms`: the new symbols; the per-iteration record
   `p45_pfmPhiPath_iter`.
3. `presolve.gms`: load the paths under the freshness stamp. **Mode R** uses the path. The
   **rule-C rebuild** (`cm_pfmBoundRebuild = 1`) uses $\varphi_{r,m}(t)$. Mirror it in
   `postsolve.gms` Step IV.4 (the `>>> MIRRORS` markers).
4. E11 (the peak-budget check) and E12 (the mode-R bind share) in the same pass.
5. Run `pfmReplayInterface()` with the negative control on the new symbols before any submission
   (`COUPLING.md` §12).

**New pitfalls to document (G3):**
- a φ path that loads with the wrong year labels (`y2030` vs `2030`) loads as zeros;
- a rule-C run with `cm_pfmPhiPath = 0` on a `v6` group silently rebuilds from the $t_0$ value;
- an SSP mismatch between the row and `output/remind-inputs`;
- comparing a `v6` φ with a `v5` φ across the θ dial (`TODO.md` 7a's θ-dial trap applies unchanged).

**Status 2026-10-07: code done, verified offline; the gate below is the next cluster task.**
`COUPLING.md` §14 is the reference.
- **R (`pfm`):**
  - `iterativePFM(formulation = "auto")`: a group with `phi-anchor.rds` couples by v6
    (`pfmV6Shares`, `R/pfmCouplingV6.R`), any other by v5, unchanged.
  - λ is 0 and mode 3 is refused; the one-dimensional symbols carry the t0 value.
  - `p45_pfmPhiPath` / `p45_pfmPhiMktPath` cover every `ttot`.
  - Convergence on the path at the checkpoints; damping only on oscillation (cosine of successive
    moves below −0.5).
  - The history stores φ(t), $k(t)$, δ, the all-period δ and α.
  - Typed options: hold year, hold rule, spread, ordering, seed, κ, regional strength
    (`pfmV6CouplingDefaults`; scenario columns `pfmPhi*`, written by `preparePFM.R`).
  - **SSP:** the run's SSP drives the scenario panel; the weights are recomputed when it, or the
    weight year, differs from the anchor's; a runtime `ssp` must match `weightScenario`.
- **GAMS (`remind_pfm`):**
  - `cm_pfmPhiPath` (default 0, so earlier runs are bit-identical) and the path loads;
  - mode 1: ratio = path, per-market price = market path · anchor (presolve and the postsolve
    Step III.3 mirror);
  - the mode-2 rebuild targets per period (presolve and the Step IV.4 mirror);
  - the runtime file carries `ssp` and `phiPath`;
  - **E11** (peak-budget record and warning) and **E12** (mode-1 bind share) done.
- **Checks:**
  - `pfmPreflight` fails a row whose `cm_pfmPhiPath` does not match its group;
  - `pfmReplayInterface()` covers the path symbols (positive and negative control pass, GAMS 51);
  - a GAMS harness on a real v6 gdx: the ratio equals the path, and the rebuild uses each period's
    share;
  - `analysis/v6/couplingOffline.R`: the coupling call reproduces Phase 1's shares exactly (Bulk $k$
    0.629 / 0.481) in 25 s.
- **Found on the way:** the coupling's nested IEA reads used the `v5` panel definition
  (`PITFALLS.md` §32), fixed before any v6 run.

**After the gate**, the offline analyses move to the 3.7.1 bases with `analysis/v6/refreshBases.R`
(`PITFALLS.md` §34).

**Gate:**
- 0. the uncoupled bases `SSP2-EU21-NPi2025`, `SSP2-EU21-PkBudg1000` and `-PFMgateRef` re-run on REMIND
  3.7.1 (start tag `EU21V371`, which also starts the four gate rows, chained);
- the θ = 0 null on the v6 fork reproduces `-PFMgateRef` (uncoupled, uniform price) run on the **same REMIND version** within the `SCENARIOS.md` §3.1 tolerance. Since the fork moved to REMIND 3.7.1 (2026-10-07) the `v5` null (3.7.0.dev29) is a different model and is shown for information only; for scale, the `v5` pair `-PFMgate` / `-PFMgateRef` differs by at most $0.71 per cell (`PITFALLS.md` §34);
- one EU21 rule-B test run converges, with the φ path and $k$ in its log and history;
- one EU21 rule-C test run shows a rebuild error of about 1e-6 (`p45_pfmBoundCheck_iter`) with the
  path loaded;
- the call time is measured (E17).

**Gate result: ✅ passed 2026-10-08** (batch `2026-10-07_12.30.39_EU21V371`, all seven runs on REMIND
3-7-1; synced to `output/remind-runs/v6/EU21`; `Rscript analysis/v6/phase3Gate.R
output/remind-runs/v6/EU21`, 18 of 18 checks):
- the null `-PFMgate-v6` against `-PFMgateRef`: 0 of 231 `pm_taxCO2eq` cells differ (2030–2100),
  cumulative CO2 2100 1000.91 Gt both, φ and the path exactly 1. Against the `v5` null (information
  only, REMIND drift): max |dP| $68.81, 1000.91 vs 991.61 Gt;
- the held-price null `-PFMgateBfix-v6`: 1003.2 Gt at 2100, +2.2 Gt on `-PFMgate-v6` (0.22%; `v5`
  +2.1 Gt) — the pinning holds (`SCENARIOS.md` §4.2a);
- rule B `-PFMlevelBfix-v6` (θ 0.50): 7 calls, last δ 0.00024 (all-period 0.0016), one damped call;
  Bulk $k$ 0.686 / 0.525 and Diffuse 0.846 / 0.723 at 2050 / 2100; 2050 path min 0.577, median
  0.699; bind share 0.986. Cumulative CO2 1121.4 Gt at 2100 (**+118.2 Gt** on `-PFMgateBfix-v6`;
  the `v5` quantity headline was +159.3) and still rising, 1183.5 Gt at 2150 — the E11 "never peaked"
  flag, expected for a held price, not budget-forced;
- rule C `-PFMlevelC-v6` (θ 0.50): 8 calls, last δ 0.0012, two damped calls; Bulk $k$ 0.619 / 0.500,
  Diffuse 0.871 / 0.725; rebuild check max 9.1e-7; budget held (997.7 Gt at 2100, peak 1001.6 in
  2090); bind share 0.997;
- call time on the cluster: 56–59 s for a run's first call, about 30 s for each later one (the
  workstation profile of E17 was 27 / 11 s).

These are single test runs; the wave-1 batch supersedes their numbers.

**H12 gate check (2026-10-09; `V6W1H12`, batch `2026-10-08_22.09.48`, all runs on REMIND 3-7-1;
`Rscript analysis/v6/phase3Gate.R models/remind_pfm-H12/output --res H12`): 17 of 19, the two misses
waived and disclosed.**
- The null `-PFMgate-v6` against `-PFMgateRef`: **outside the §3.1 tolerance** ($1 / 0.2 Gt). All 132
  `pm_taxCO2eq` cells differ, by at most $1.57 (mean $0.81); cumulative CO2 2100 1000.07 vs 1000.81 Gt.
  **Waived:** the difference is the same in every region in every year (a spread of 0 across the 12
  regions). The null's price is lower by 0.13% in 2030, rising to 0.32% in 2090, $0.121 more every
  five years. That is one global, linear path drawn a little lower, i.e. REMIND's budget loop stopping
  at another point (35 vs 38 Nash iterations), not the political layer: φ and the path are exactly 1.
  Both runs meet the budget inside REMIND's own `cm_budgetCO2_absDevTol` (2 Gt). The lower price comes
  with *lower* cumulative CO2, so this is noise in where the solution stopped, not a price response.
  The limits in `phase3Gate.R` stay as they are; this is disclosed, not re-tuned.
- The held-price null `-PFMgateBfix-v6`: 998.6 Gt at 2100, −1.5 Gt on the null (`v5` H12 +3.5).
- Rule B `-PFMlevelBfix-v6` (θ 0.50): 7 calls, last δ 0.0019, one damped call; Bulk $k$ 0.684 / 0.516,
  Diffuse 0.841 / 0.724 at 2050 / 2100; 2050 path min 0.579, median 0.733; bind share 0.994; never
  peaks (1183.0 Gt in 2150, as at EU21).
- Rule C `-PFMlevelC-v6` (θ 0.50): 6 calls, last δ 0.0012, one damped call; Bulk $k$ 0.621 / 0.489,
  Diffuse 0.867 / 0.726; rebuild check max 9.1e-7; budget held (peak 998.8 Gt in 2090); bind share 1.000.

**Offline analyses moved to the 3.7.1 bases (2026-10-08,** `Rscript analysis/v6/refreshBases.R
--apply`; `PITFALLS.md` §34). `config.yml` now points the SSP2 pair at
`output/remind-runs/v6/EU21/SSP2-EU21-{NPi2025_2026-10-07_12.36.43, PkBudg1000_2026-10-07_19.04.46}`.
The 3.7.0.dev29 results are kept in `output/pfm/v6/phase1-remind-3-7-0-dev29/`; old vs new is
`output/pfm/v6/phase1/base-refresh.rds`. Run-Group `v6`, EU21:

| quantity | 3.7.0.dev29 | 3.7.1 | change |
|---|---:|---:|---:|
| $k$ NPi Bulk 2050 / 2100 | 1.092 / 0.919 | 1.091 / 0.924 | −0.001 / +0.005 |
| $k$ NPi Diffuse 2050 / 2100 | 0.665 / 0.706 | 0.656 / 0.701 | −0.009 / −0.005 |
| $k$ PkBudg1000 Bulk 2050 / 2100 | 0.629 / 0.481 | 0.629 / 0.488 | 0.000 / +0.007 |
| $k$ PkBudg1000 Diffuse 2050 / 2100 | 0.914 / 0.727 | 0.860 / 0.716 | −0.054 / −0.011 |
| shortfall 2050, θ 0.5: φ(t), $k$ on PkBudg1000 | 18.0% | 17.8% | −0.2 |
| shortfall 2050, θ 0.5: φ(t), $k$ on NPi | 22.7% | 22.5% | −0.2 |
| shortfall 2050, θ 0.5: φ held at t₀ | 23.8% | 23.7% | −0.1 |
| shortfall 2050, θ 0.5: φ(t) + `v5`-style λ | 48.6% | 47.9% | −0.7 |
| ceiling gate Bulk / Diffuse | 1.215 / 1.271 | 1.215 / 1.271 | 0 |

The REMIND version moves nothing that a Phase 1 conclusion rests on. `couplingOffline.R` still
reproduces the Phase 1 share path exactly (756 values, difference 0). Numbers quoted in §7a, §8 and the
ADRs from `phase1/` before 2026-10-08 describe 3.7.0.dev29 and are left as written.

**Offline against coupled $k$** (all 3.7.1, θ 0.50, Bulk 2050 / 2100): uncoupled PkBudg1000 0.629 /
0.488; rule C 0.619 / 0.500; rule B 0.686 / 0.525. Rule C holds the budget and stays within 0.012 of
the offline value. Rule B, whose energy system departs further from the base (+118 Gt), is 0.057
higher in 2050. The gap is the feedback of the coupled energy system on $k$. Its mechanism is not
decomposed here.

### Phase 4 — Run tooling (in parallel with Phase 3; about a week)

F1 (scenario matrix → generated CSV), F2 (preflight), F3 (submit wrapper with batch manifest), F4
(post-batch stage), F5 (promote scripts), F8 (typed options).

**Gate:** the v6 batch config is produced by the generator, the validator is clean, and a dry-run
submit prints the expected rows, groups and commits.

### Phase 5 — The coupled `v6` batch (cluster; in waves)

| wave | runs | per resolution | count | purpose |
|---|---|---|---|---|
| 1 | SSP2 nulls `-PFMgate`, `-PFMgateBfix` (+ NPi twin null if quoted) | EU21, H12 | 4–6 | D18 gate; anchors for rule B |
| 1 | SSP2 `-PFMlevelBfix`, `-PFMlevelC` at θ 0.325 / 0.50 / 0.675 | EU21, H12 | 12 | the two horns with severity |
| 1 | "institutions held" twin of each headline cell: `-PFMlevelBfix`, `-PFMlevelC` at θ 0.50 with `pfmInstitutions = hold` | EU21, H12 | 4 | D10, decision 1A of 2026-10-06: institutions carry about half of Bulk $k$'s 2100 fall on PkBudg1000 (Phase 1 C3), so the headline always travels with its held twin |
| 2 | ordering tests: Bfix uniform, permuted 1–3, reversed; C uniform, permuted 1 | EU21 (H12 for Bfix uniform + 1 permuted) | 7 + 2 | D-M1 / GP-24 |
| 2 | assignment rules: Bfix and C × all-median, all-low, nearest donors always (no "none" class); USA donor / low (Bfix) | EU21 | 8 | D-M2 (ii), GP-3 / 10; the nearest-donors arm is decision 3 of 2026-10-06 (§7a): it moves LAM and SSA in the ranking, not $k$ |
| 2 | markup off (`-Min`) for B and C; ratio mode for C | EU21, H12 | 6 | v5 continuity |
| 2 | family A shape twins (main-text robustness): Bfix at θ 0.50 on `v6-sat05` and `v6-sat2` (deployed spec, half-saturation 0.5× and 2× the median) | EU21 | 2 | D7, decision 6 of §7a |
| 2 | family B (SI): Bfix and C at θ 0.50 on `v6-specalt` (X-2079 satInn, the bootstrap's most frequent family-B winner); annual rung | EU21 | 3 | D7, D3, decision 6 of §7a |
| 2 | formulation arms: $E$ hold (Bfix), hold 2060 (Bfix **and** C), regional $k$ (Bfix), closure κ at 0.027, 0.02 and 0.05 (Bfix and C each) | EU21 | 10 | D2, D6, D16, D13 |
| ~~3~~ | ~~hold-2060 twin of each SSP's `-PFMlevelBfix`~~ | EU21 | ~~2~~ | deferred (§7a decision 7) |
| ~~3~~ | ~~SSP1, SSP3: uncoupled NPi and PkBudg1000 (if not canonical), `-PFMgate`, `-PFMgateBfix`, `-PFMlevelBfix`, `-PFMlevelC`~~ | EU21 | ~~12~~ | deferred (§7a decision 7) |
| ~~3~~ | ~~declared spread arm per SSP~~ | EU21 | ~~2~~ | deferred (§7a decision 7) |

About 62 runs in total (waves 1–2), the size of the `v5` core batch. Wave 3, the SSP axis, is
deferred to a later paper version (§7a decision 7).

*(For the deferred SSP wave.)* **SSP3 at 1000 Gt may be infeasible in REMIND regardless of politics** (architecture note, H6).
Test the uncoupled SSP3 PkBudg1000 first. If it fails, use a budget that SSP3 can meet and say so;
do not reuse the SSP2 budget.

**Results as they land.** **Phase 5 is complete (2026-10-10): EU21 waves 1 and 2 (39 coupled runs,
2026-10-09) and H12 waves 1 and 2 (15 coupled runs, 2026-10-10), all admitted.** Run-Group `v6`, REMIND
3.7.1, read from `output/pfm/v6/coupling/coupled-facts.json` (64 runs with the bases and nulls: 46 EU21,
18 H12), `coupled-costs.json` and `convergence-audit.rds`. The EU21 tables follow; H12 is under "H12"
below.

*Quality.* Every run finished (modelstat 2); none at the iteration cap; 2–15 PFM calls, final δ ≤
0.0019; no early-period (≤ 2060) market cell over tolerance (worst exactly 1.00×, `-PFMlevelC-permuted1`).
One disclosure: `-PFMlevelCMin` never peaks before 2150 (1011.6 Gt there, `PITFALLS.md` §26). The
markup written/seen difference in three runs (`-PFMlevelBfixTh675`, `-PFMlevelC-allmedian`,
`-PFMlevelC-specalt`, 0.2–0.4%) is **explained, not a fault** (2026-10-10): the gdx keeps `Seen` from
the start of the last presolve and `Written` from its end, so they differ when the markup moved in
the final iteration, and in every such run it did (`PITFALLS.md` §16).

*Rule B (held price), cumulative CO₂ 2100 against `-PFMgateBfix` (1003.2 Gt).* Deployed, θ = 0.50:
**+118.2 Gt**.

| arm | Δ Gt | vs deployed | reading |
|---|---|---|---|
| θ = 0.325 / 0.675 | +73.0 / +181.5 | | 264 Gt per unit θ, steeper above 0.50 |
| institutions held | +117.3 | −0.9 | holding institutions moves Bulk $k_{2100}$ 0.525 → 0.417 and Diffuse 0.723 → 1.001, and the two cancel in the headline |
| markup off (`Min`) | +159.7 | +41.5 | the sector markup buys back 26% |
| κ = 0.02 / 0.027 / 0.05 | +53.5 / +41.2 / +22.1 | −64.7 / −77.1 / −96.1 | the central κ removes 65% of the headline |
| $E$ hold (static share) | +189.1 | +70.9 | $k \approx 1$: the moving strength removes 37% of the static-share result |
| hold 2060 / regional $k$ | +125.6 / +121.5 | +7.4 / +3.3 | small |
| ordering: uniform / permuted 1–3 / reversed | +105.8 / +102.1, +126.4, +89.3 / +67.9 | −12.5 / −28.9 to +8.2 / −50.4 | size alone (uniform) gives 106 Gt; the model's ranking adds 12, within the range of random orders (89–126); reversing it costs 50 |
| assignment: all-median / all-low / nearest / USA donor / USA low | +109.5 / +154.6 / +133.6 / +117.4 / +134.8 | −8.7 / +36.4 / +15.4 / −0.8 / +16.5 | the assignment of uncovered countries is the largest data-side band (110–155) |
| saturation 0.5× / 2× | +115.2 / +130.0 | −3.0 / +11.8 | |
| family B (`specalt`) / annual panel | +107.5 / +164.4 | −10.7 / +46.2 | the annual rung keeps Bulk $k$ above 1 (1.19 / 1.12) |

*Rule C (held budget).* Every run holds the budget (cumulative CO₂ 2100: 989–1001 Gt). 2050 regional
prices against the θ = 0 run, median (anchor):

| arm | median ×, 2050 | anchor × | reading |
|---|---|---|---|
| θ = 0.325 / 0.50 / 0.675 | 1.089 / 1.153 / 1.232 | 1.152 / 1.259 / 1.417 | monotone in θ; θ = 0.675 took 73 iterations and ends 11 Gt under |
| institutions held | 1.158 | 1.261 | as deployed |
| markup off / ratio mode | 1.120 / 1.060 | 1.351 / 1.287 | `Min` never peaks (above) |
| κ = 0.02 / 0.027 / 0.05 | 1.069 / 1.055 / 1.031 | | κ removes most of the price relocation |
| uniform / permuted 1 | 1.043 / 1.114 | | without the ranking, half the relocation goes (gross CO₂eq relocated 11.7 vs 22.7 Gt) |
| all-median / all-low / nearest | 1.137 / 1.217 / 1.178 | | |
| family B / hold 2060 | 1.136 / 1.163 | | |

*Settling.* Four short rule-C runs were still moving in their last ten iterations, which overlap the
budget loop's final adjustment: `-PFMlevelC-kappa05` (34 iterations; maximum price range 16.7%, budget
miss up to 28.5 Gt), `-PFMlevelC-specalt` (29; 16.5%, 13.0 Gt), `-PFMlevelC-uniform` (40; 14.9%, 16.8 Gt) and
`-PFMlevelCTh325` (38; 3.5%, 28.0 Gt). All ended within 1.6 Gt of the budget. The deployed rule-C run moved
0.6% and 3.2 Gt. Quote those four with that disclosure (`convergence-audit.rds`).

*Costs and relocation* (`coupled-costs.json`; GHG in CO₂eq 2020–2100 against the matched null; GDP and
consumption discounted at 5%):

- **Rule B**, deployed: **+127.9 Gt CO₂eq**, 66.7 Gt relocated between regions, GDP +0.19%, consumption
  +0.20% (the cap lowers mitigation cost). Across the arms GDP moves from +0.06% (κ = 0.05) to +0.27%
  (θ = 0.675).
- **Rule C**: net CO₂eq between −6.8 and +2.1 Gt, so the budget is met by moving abatement. Gross
  relocation 22.7 Gt deployed; 15.0 / 45.0 at θ = 0.325 / 0.675; 11.7 with every region at the mean rank;
  5.3–9.5 under κ. GDP +0.02% to +0.04%. Ratio mode relocates 19.7 Gt.

**H12 (waves 1 and 2, landed 2026-10-10).** 15 coupled runs plus the three 3.7.1 bases, all finished
(modelstat 2), none at the cap, all admitted. The gate check is 17 of 19 with the null-vs-`-PFMgateRef`
miss waived (Phase 3, "H12 gate check"). No early-period market cell over tolerance. Every rule-C run
settled: in the last ten iterations the anchor moved at most 1.4% and the budget miss at most 5.5 Gt
(`-PFMlevelCTh325`), so H12 needs no settling disclosure. **The two resolutions agree on rule B** (every
H12 number within about 10% of its EU21 twin) and on every sign and ordering; **rule C's price relocation
is about half as large at H12**.

| | EU21 | H12 |
|---|---|---|
| rule B, deployed: Δ cumulative CO₂ 2100 vs `-PFMgateBfix` | +118.2 (null 1003.2) | **+112.8** (null 998.6) |
| rule B, θ = 0.325 / 0.675; slope per unit θ | +73.0 / +181.5; 264 | +69.6 / +169.6; 247 |
| rule B, institutions held | +117.3 (−0.9) | +107.8 (−5.0) |
| rule B, markup off: buys back | +159.7: 41.5 (26%) | +154.2: 41.3 (27%) |
| rule B, ordering: uniform / permuted 1 | +105.8 / +102.1 | +96.2 / +108.5 |
| rule B, Bulk $k$ 2050 / 2100 | 0.686 / 0.525 | 0.684 / 0.516 |
| rule C, cumulative CO₂ 2100 (peak) | 989–1001 | 989.7–998.2 (998.3–1000.7) |
| rule C, median 2050 price × θ = 0: θ 0.325 / 0.50 / 0.675 | 1.089 / 1.153 / 1.232 | 1.039 / 1.075 / 1.115 |
| rule C, anchor ×: θ 0.325 / 0.50 / 0.675 | 1.152 / 1.259 / 1.417 | 1.141 / 1.251 / 1.383 |
| rule C, held / markup off / ratio: median (anchor) | 1.158 (1.261) / 1.120 (1.351) / 1.060 (1.287) | 1.068 (1.245) / 1.046 (1.343) / 1.048 (1.264) |
| costs, rule B deployed: CO₂eq, relocated, GDP | +127.9, 66.7, +0.19% | +121.5, 60.7, +0.16% |
| costs, rule C deployed: net CO₂eq, relocated | −0.1, 22.7 | −3.0, 19.9 |

Reading:
- **The quantity headline holds at both resolutions:** +118 (EU21) and +113 Gt (H12). The θ slope, the
  markup's buy-back (about 41 Gt) and the near-zero effect of holding institutions all repeat.
- **The held-budget relocation is weaker at H12:** the median 2050 price moves ×1.075 against ×1.153,
  although the anchor rises about as much (×1.251 against ×1.259). The median is taken over 12 regions
  at H12 and 21 at EU21, so the two are not the same statistic; why the H12 median sits lower is not yet
  decomposed. The cheapest region is REF at both resolutions (×0.91); the dearest is CHA at H12 and NEN at
  EU21. Gross abatement relocated: 19.9 Gt (H12) against 22.7 (EU21). Emissions-weighted, the realised
  price is ×1.037 the null at H12 and ×0.984 at EU21 (`held-budget-prices-levelC.rds`).
- **The ranking adds less at H12 than at EU21, and is again within the random-order range.** Uniform
  gives +96.2 and the model's ranking +112.8. Permuted 1 gives +108.5. EU21 has three permutations
  (89–126); H12 has one, so H12 alone cannot place the ranking in a distribution.
- H12 costs: rule B across the arms from +74.5 (θ 0.325) to +184.1 Gt CO₂eq (θ 0.675), GDP +0.10% to
  +0.23%; rule C net −6.1 to −0.5 Gt, relocated 11.2–37.0 Gt (θ 0.325–0.675), GDP +0.02% to +0.03%.

**Admission:** every run is judged by the F4 stage against `PITFALLS.md` §25 / §25a. A run at the
iteration cap is admitted only by the written rule.

**Non-convergence (author's rule, 2026-10-01): never raise the iteration cap.** The scenario config
has no `cm_iteration_max` column, and the generator (F1) must not add one. A run that does not
converge is handled in one of two ways:
1. **Diagnose and remove the cause.** Use the criteria still failing
   (`coupledRunConvergence.R`, F4). Typical causes: a limit cycle in the peak year, a φ path still
   moving, a market surplus.
2. **Start a new run from its gdx.** Set `path_gdx` to the unfinished run. The submit wrapper (F3)
   should offer this as a one-line restart, and record the restart in the batch manifest.

### Phase 6 — Analysis, documents, paper (three to six weeks)

1. `pfmRun(stage = "coupled")` per wave (F4). The `v5` → `v6` contrasts for every headline.
   **Done 2026-10-10:** `Rscript analysis/v6/coupledV5V6Contrast.R` →
   `output/pfm/v6/coupling/v5-v6-coupled-contrast.rds` / `.json` (each headline against its own group's
   θ = 0 null, so the REMIND drift between 3.7.0.dev29 and 3.7.1, +9 to +11 Gt on the nulls, cancels to
   first order). What changes, EU21 / H12:
   - **the quantity headline shrinks by a quarter to a third**: +159.3 → +118.2 Gt / +163.8 → +112.8 Gt;
     the θ slope 330 → 264 / 346 → 247 Gt per unit θ. ADR 0050 attributes the drop to removing λ offline;
     the coupled contrast shows its size, not its cause;
   - **the markup still buys back about 41 Gt** (46.2 → 41.5 / 58.6 → 41.3);
   - **rule C's price relocation barely moves**: median 2050 price ×1.173 → 1.153 / 1.123 → 1.075, anchor
     ×1.305 → 1.259 / 1.326 → 1.251;
   - **but the abatement it moves between regions falls by about three quarters**: 76.7 → 22.7 / 84.5 →
     19.9 Gt CO₂eq. This is the "China absorbs" composition named in step 5: in `v5` CHA alone took
     −54.2 Gt of it (`v5` `coupled-costs.json`); in `v6` CHA takes −10.2 Gt (EU21) / −8.9 (H12), and
     IND turns from −5.4 to +8.1 Gt. **First look (2026-10-10, EU21 `-PFMlevelC`, `coupled-runs.rds`):
     the ranking moved.** (φ as `p45_regiDiff_phi` records it; in `v6` 0.50 at θ = 0.50 means u = 1.)
     CHA's Bulk market is unconstrained in both versions (φ_ETS = 1, 2050 ETS price
     $331 `v5` / $286 `v6`), but its Diffuse market went from φ 0.78 to 0.50, the most constrained, and its
     2050 ES price from $262 to $166. IND's Bulk went from 0.78 to 0.50. The two regions that absorbed
     the abatement in `v5` are now the most constrained in at least one sector, so less is moved to
     them. A full decomposition (by sector and region) is still to do before the paper's spine is
     re-decided;
   - rule B's relocated abatement also falls (114.3 → 66.7 / 115.1 → 60.7 Gt), and its GDP gain stays
     small (+0.21 → +0.19% / +0.22 → +0.16%).
2. Figures in the shared layer:
   - $k_s(t)$ with its decomposition (C3) and the out-of-support share;
   - φ(t) fans by SSP;
   - the ordering-test contrast (size vs location);
   - the sector-binding diagnostic (D-M4).
3. Offline re-runs on `v6`: the income screen, GovEff correlate, residual ordering, trend shape,
   offline bound, rung propagation (D-GP2 / 5 / 8 / 11 / 13 / 15; C7).
4. Governed documents and ADRs (G1–G4); the archive sweep (E18).
5. **The new paper workspace (D19), replacing `papers/pfm-paper-v5`.**
   - Scaffold it the way `papers/pfm-paper-v5` was built, with `--draft papers/pfm-paper-v5/manuscript/paper-v18.md`.
   - Port the design, claims (re-tiered on `v6`), glossary and literature; then build the bundle,
     figures and drafts.
   - Carry the review-v16 points (§3 D) as the opening checklist.
   - Re-decide the spine with the results. Under v6 both horns survive, but the "China absorbs"
     composition and the ~160 Gt size will both change.
   - Mark `papers/pfm-paper-v5` as superseded in its own `CLAUDE.md` and `VERSIONS.md`, pointing to the new
     workspace.
6. **The deposit (D-M3):** a Zenodo archive at a tag of `pfm`, `mrpfm`, the fork and the project
   repo, plus the `v6` artifacts and batch manifest. The referee link goes in at submission.

---

## 5. Risks and how the plan handles them

| risk | where it shows | mitigation |
|---|---|---|
| $k_s(t)$ is mostly link-function curvature, not politics | Phase 1 step 5 ($E$ hold gives $k \approx 1$) | stated as the mechanism (D2); $E$ hold reported as the bound; C3 decomposition shows which drivers move $k$ |
| The SSP signal is small after normalisation | Phase 1 step 6 | the gate demotes the SSP axis to the SI; the plan does not depend on a large fan |
| With no hold year, late-century results are driven by extrapolated or clamped drivers | Phase 1 step 5, wave 2–3 | saturating innovator power (D7); out-of-support share reported per year; every headline and every SSP result travels with its hold-2060 twin; if the two differ materially, the paper says which part of the result comes after 2060 |
| The rename breaks a `v5` reader or the `papers/pfm-paper-v5` bundle silently | Phase 0 | `v5-final` tags before the rename; read-aliases; the `papers/pfm-paper-v5` bundle rebuild must reproduce its manifest hashes |
| The headline moves a lot from `v5` | Phase 1 step 9 | expected: v6 reads 2022, and $k_{Diffuse}$ falls to ~0.55 by 2050 in the methodology's offline numbers. Reported as a formulation change, with the `v5` → `v6` contrast |
| The re-sweep picks a different spec | Phase 2 | the `v5` spec refitted on the `v6` panel is kept as a rung, so the change can be split into "data" and "selection" |
| Rule C oscillates with a time-varying cap | Phase 3 gate, wave 1 | damping, logged (D5); the checkpoint rule; the strict-rule fallback; the rule-C test run before the batch |
| A silent interface failure (wrong rank or year labels) | Phase 3 | new symbols only (D14); replay harness plus negative control; preflight (F2) |
| An unpushed fix or stale install on the cluster | every wave | preflight (F2), batch manifest (F3) |
| Hand-edited config drift | every wave | generated config (D22, F1) |
| SSP3 infeasible at 1000 Gt | wave 3 | test the uncoupled run first; declare the budget used |

---

## 6. Deliberately not in v6

- Per-sector specifications, a different normalisation, emissions weights (D17).
- An estimated θ. The price–efficiency elasticity (C11) is a separate workstream.
- Making the feedback causal. The IV stays an endogeneity-confirmed null (`MODEL.md` §8.1); "causes"
  stays out of the loop's description.
- Unclamping drivers other than innovator power (0004 §1: they bind only where they protect).
- A new estimator for the shortfall (JLMS $E[u \mid \varepsilon]$ instead of the composed residual
  $u - v$). The composed residual is what the methodology defines; JLMS is not consistent
  (Jondrow et al. 1982, appraised in `papers/pfm-paper-v5/literature/`).

---

## 7. Author decisions (2026-10-01)

1. **D6 — no hold year is the central case;** holding $k$ at 2060 is the sensitivity. This reverses
   the plan's recommendation. Its consequences are carried in D6, A1a, B4, Phase 1 step 5, the
   wave 2–3 rows and the risks table.
2. **D19 — a new paper workspace,** built the same way `papers/pfm-paper-v5` was built for `v5`, with `papers/pfm-paper-v5`
   v18 as the draft. All other recommendations are agreed.
3. **D21 — the `psm` → `pfm` rename comes before anything else** (Phase 0, step 1). Only the
   commit-and-tag snapshot of today's state precedes it, so the rename diff is isolated.
4. **No `v5` runs.** v6 is the focus; the ordering tests (GP-24), and GP-23 where it still applies,
   run on `v6` (wave 2).
5. **The v6 paper replaces the `v5` paper.** `papers/pfm-paper-v5` is frozen at v18, not submitted, and kept
   reproducible as the `v5` record.

## 7a. Author decisions (2026-10-06), after the Phase 1 results

1. **D10 stays: the storyline institution rule in the headline (option A).** Each headline cell
   gets an "institutions held" twin in wave 1 (rule B and rule C at θ = 0.5, EU21 and H12; four
   runs, Phase 5 table). Reason: with institutions held, Bulk $k_{2100}$ on PkBudg1000 is 0.28
   instead of 0.48 (Run-Group `v6`, lag in years, institution-harmonised panel). That is too large
   to leave to the SI alone.
2. **The institution-rule series are harmonised to history like every other series (option B).**
   They start from the panel's anchor value and fade to the rule's path by 2040. $q$ stays anchored
   on history. Implemented in `panelDataScenario` (`DATA.md` §5.4–§5.5, `PITFALLS.md` §30). On a
   lag-consistent seam test, the band-rule seam goes from Bulk 95th percentile 1.93 / maximum 6.2 to
   0.93 / 1.65 index points (`lag-seam.rds`, `v6`). Every scenario-side `v6` artifact built
   before it (the sanity walk's scenario gates, the projection, the coupling bound, the Phase 1
   outputs) is rebuilt.
3. **Donor rule: the deployed rule stays** (9 base drivers weighted by $|eta|$; close ≤ q50,
   far ≤ q90 of the covered nearest-neighbour distances). The alternatives were quantified
   (`analysis/v6/donorAlternatives.R`, `output/pfm/v6/phase1/donor-alternatives.rds`). Fewer
   drivers add few donors and match worse in the full space. Looser bounds add donors only by
   matching countries further apart than 90% of covered pairs. No rule moves $k$ by more than 0.01.
   What they move is the ranking: LAM's and SSA's $u$ rise when more of their weight gets donors.
   That sensitivity is a wave 2 arm, "nearest donors always" (`qualityQuantiles = c(0.5, Inf)`),
   for rule B and rule C.
4. **The Bulk γ of 0.997 is accepted at the Phase 2 gate,** with disclosure in Methods and the SI.
5. **The driver lag counts years (fixed, author's go-ahead the same day).** It used to count panel
   rows, so on REMIND's time steps it was 5 to 20 years instead of the estimated 1 (`PITFALLS.md`
   §31). The fit is unchanged. On the scenario side, Bulk $k_{2050}$ on PkBudg1000 is 0.63 instead
   of 0.87, and on NPi 1.09 instead of 1.37. Every scenario-side `v6` artifact is re-run on the
   cluster, together with decision 2: sweep (sanity walk scenario gates), sanity pool, bootstrap,
   downstream and the REMIND export.
6. **Family A in the main text, family B in the SI (2026-10-07).** The sanity-passing specs split on
   the actor-power transform (Phase 1 status, `spec-band.rds`):
   - family A, satAP: the saturating curve on innovators *and* incumbents. Bulk $k$ falls strongly on
     PkBudg1000;
   - family B, satInn: innovators only. Bulk $k$ flat or rising.

   The families differ only below the observed range: in PkBudg1000 2050, 56% of countries sit below
   the training 5th percentile of the Bulk incumbent share, and 59% above its innovator maximum. No
   re-sweep on 2000–2023 data can decide between them.

   The main text uses family A (the deployed X-1791 satAP), for three reasons:
   - the joint fit of the shared spec: the best family-A specs beat the best family-B ones by about 50
     BIC, from Diffuse; in Bulk alone family B is 14 BIC better;
   - treating both groups symmetrically;
   - ADR 0040's own rationale: no linear extrapolation of a share into a range no country occupied.

   Disclosed: the bootstrap splits about 49 / 51 between the families.

   **The shape check** (`analysis/v6/satShape.R`, `phase1/sat-shape.rds`; `pfm` option `apSatScale`)
   sets the half-saturation point to 0.5×, 1× and 2× the median. All three pass the sanity walk, and
   the ranking is stable (Spearman ≥ 0.97 with 1×):

   | half-saturation | Bulk $k$ on PkBudg1000, 2050 / 2100 | ΔBIC vs 1×, Bulk / Diffuse |
   |---|---|---|
   | 0.5× median | 0.57 / 0.40 | +16 / −14 |
   | 1× (deployed) | 0.63 / 0.48 | 0 / 0 |
   | 2× | 0.75 / 0.63 | −14 / +19 |

   The direction holds at every shape; the size is the band to quote. The sectors pull in opposite
   directions, so the median is close to the joint optimum. Coupled runs: the two shape twins in wave
   2 (main text), and family B's X-2079 as `v6-specalt` (SI). Both are built with
   `analysis/run-groups/makeSpecVariantGroup.R` (sector `both`, `apSatScale=` for the twins). The main
   text says in one sentence that the size of the Bulk loosening rests on how incumbent power behaves
   below anything observed, and points to the SI.
7. **The `v6` paper is SSP2 only (2026-10-07).** The SSP workflow stays: `ssp` arguments, the
   institution storyline rule, `calcSSPextensions(drivers_SSPx)`, `analysis/v6/sspGovernanceSwap.R`.
   It is not used for this paper version. Consequences:
   - Phase 1 step 6 and the gate's SSP clause are closed for `v6`; the governance-only measurement
     stays on record (`phase1/ssp-governance.rds`);
   - wave 3 of Phase 5 (16 runs) is deferred, so the batch is about 62 runs;
   - A1d (SSP level and spread) is deferred;
   - nothing in the code is removed. The registry keeps `ssp: SSP2` explicit.
8. **The ceiling-fall gate stays for `v6`, flagged for revision (2026-10-07).** ADR 0043's
   `ceilingFallGate = 0.90` is kept as set before any `v6` result. Its four sole rejections (family
   A, Bulk $k$ rising) are reported in the SI with family B (C9). **Revisit it** when the future
   projections are revised, above all the institution projections in the light of the PoliClim
   forecasts (`analysis/checks/policlimInstitutions.R`). Under v6 the ceiling path drives $k$, and
   the institution paths move the ceiling: Bulk $k$ rises with better institutions under the
   deployed frontier. So a new projection can move specs across the gate, and the gate's premise
   (a ceiling must not collapse as the transition succeeds) has to be re-argued for the projection
   actually used, not carried over.

## 8. The `v5` → `v6` comparison (Phase 2, step 6)

Methods / SI material for the `v6` paper. Every number is from `analysis/v6/v5v6Comparison.R`
(`output/pfm/v6/phase1/v5-v6-comparison.rds`), read from Run-Groups `v5` and `v6`. The regional
ranking $u$ is computed **by the v6 rule for both groups** (each at its own anchor year, the same 2025
final-energy weights, the REMIND-consistent EU21 mapping), so it compares the models, not the
formulations.

**Panel and spec.**

| | `v5` | `v6` |
|---|---|---|
| panel | 2000–2022, 5-year MA, IEA default edition, no geothermal (`f8845f66fb39d316`) | 2000–2023, 5-year MA, IEA 2025 edition, geothermal in the baseload control (`7aaa8f84eb630326`) |
| covered countries | 48 | 48 |
| deployed spec | X-2079 `WGIge|noRoL|VerAcc bothIncAP … linear` | X-1791 `WGIge|RoL|VerAcc bothIncAP … satAP` |
| institutions | GovEff (WGI), Vertical Accountability | GovEff (WGI), **V-Dem Rule of Law**, Vertical Accountability |
| actor power | innovator and incumbent shares, incumbent per capita, linear | the same, **saturating** (ADR 0040; decision 6) |
| controls, FE | GDP pc (Q-centred), log population, hydro/nuclear; EU / OECD / other | the same; hydro/nuclear **+ geothermal** |

**Selection statistics** (deployed spec; Bulk / Diffuse):
- ΔR²(theory): `v5` 0.112 / 0.166; `v6` 0.131 / 0.175. Both Green.
- max VIF: `v5` 3.4 / 2.9; `v6` 7.7 / 7.9. Rule of Law enters next to GovEff (r = 0.82); ADR 0048 keeps the
  soft VIF key off.
- frontier γ: `v5` 0.987 / 0.982; `v6` 0.997 / 0.972. Bulk is accepted with disclosure, decision 4.
- bootstrap: `v6` wins 2.5% of 200 resamples, 15% among sanity-passing winners. `v5`'s 8.5% / 10% are
  affected by PITFALLS §29 (twin cache) and are not comparable.

**Coefficients** (main effects; frontier = what the coupling uses, satP with wild-cluster p =
what is quotable):
- **Bulk incumbency is stronger and now significant:** incumbent share satP −0.64 (p = 0.03; `v5`
  −0.19, p = 0.42); per capita +0.48 (p = 0.007), unchanged in sign and size.
- **Bulk GovEff changes sign in the frontier** (+0.06 → −0.31), while the satP estimate stays
  positive and loses significance (+0.24, p = 0.05 → +0.11, p = 0.61). Bulk Vertical Accountability
  does the same (frontier +0.03 → −0.29; satP p = 0.70). The new Rule of Law term is +0.39 in the
  Bulk frontier, satP p = 0.89. **The Bulk institution terms are not identified in `v6`** (Phase 1
  status); they are what makes better institutions raise Bulk $k$.
- **Diffuse is stable and better identified:** GovEff +0.25 → +0.24 (p = 0.006 → < 0.001),
  incumbency −0.13 → −0.15 (p = 0.03 → 0.006), Vertical Accountability changes sign to +0.23
  (p = 0.08).

**The efficiency ordering at the anchor year** (covered countries, `v5` 2022, `v6` 2023): Spearman
0.82 (Bulk) and 0.87 (Diffuse) over the same 48 countries. The median $E$ rises slightly, 0.71 →
0.74 and 0.75 → 0.78. The five least efficient: Bulk `v5` RUS, PER, ISL, IDN, ARG → `v6` IDN, PER,
ISL, ARG, NZL; Diffuse PER, ISR, RUS, ROU, BGR → PER, ISR, LTU, ROU, CRI.

**The regional ranking $u$ (EU21) changes more in Bulk than in Diffuse.** Spearman 0.58 (Bulk),
0.82 (Diffuse).

| | Bulk | Diffuse |
|---|---|---|
| most constrained, `v5` | REF, MEA, JPN | REF, NES, CHA |
| most constrained, `v6` | **IND**, ECE, OAS | CHA, ECS, ECE |
| least constrained, `v5` | UKI, NEN, IND | UKI, NEN, CAZ |
| least constrained, `v6` | CHA, NEN, UKI | NEN, UKI, CAZ |
| largest move | IND, Δu = 0.86 | NES, Δu = 0.48 |

India moves from among the least to the most constrained Bulk region. China is the most constrained
Diffuse region in `v6` and the least constrained Bulk one.

**Floor regions** (the share's minimum over sectors at θ = 0.5): `v6` at $t_0$, CHA and IND at 0.50,
then ECE 0.52, OAS 0.54, MEA 0.54. `v5`'s operational shares (v5 formulation, `coupling-summary.rds`,
future mapping, E26): CHA and REF at 0.50, LAM 0.54, NES 0.55, USA 0.58. **China is the floor in
both.** India, REF, NES and USA change most.

**What changes for the paper.** The `v5` spine's "China absorbs" composition and its ~160 Gt
(`v5` coupled) must be re-derived: the floor is now China *and* India, and the size changes with the
removal of λ (offline first round: the 2050 shortfall at θ = 0.5 goes from 51% to 18%, Phase 1 step
9). Both are coupled results to come (Phase 5).

