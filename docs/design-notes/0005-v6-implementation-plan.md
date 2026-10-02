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
| D3 | Anchor at the last panel year on the moving-average panel; fit the frontier on that panel; annual data as a robustness rung | switch the deployed fit to annual data | recommended |
| D4 | Normalise $k$ at $t_0 = 2025$ in every scenario; $u$ from anchor-year data; $\varphi(t_0) = 1 - \theta u$ | normalise at 2022 | recommended |
| D5 | Converge on the **φ path** (max over regions, markets and checkpoint years) at the existing tolerance 0.002; log the all-period δ; switch to the strict rule if it ends above 2 × tol | converge on $k$ with tolerance tol/θ | agreed |
| D6 | **No hold year in the central case:** $k_s$ follows the ceilings to 2100. **Hold at 2060 is the sensitivity.** The out-of-support share is reported per year with every run | hold at 2060 as the central case | **decided by the author, 2026-10-01** |
| D7 | Innovator power on the **saturating transform, declared**; keep every other clamp | linear innovator power with the clamp; drop every clamp | recommended |
| D8 | **One** re-sweep (Run-Group `v6`) carrying panel-to-2023, geothermal and saturating innovator power together | three separate refits | recommended |
| D9 | One SSP per run, taken from `cm_GDPpopScen` and threaded to the panel, the weights, $P^{ref}$ and the anchor donor; **asserted** | SSP2 everywhere (today) | recommended |
| D10 | Vertical accountability under SSPs: a **declared storyline convergence** (target percentile and midpoint per SSP), SSP2 unchanged. Decide only after the re-sweep shows whether accountability is still in the spec | map from the Andrijevic composite index; no SSP variation | recommended, conditional |
| D11 | Spread: $d_s = k_s$ in every headline run; a declared storyline spread $d_s = \rho_{SSP}(t)\,k_s$ only as an SI arm; the model-derived $D_s(t)/D_s(t_0)$ reported as a diagnostic only | model-derived spread in the headline | recommended |
| D12 | Clip φ to [0, 1]; redefine θ as "severity at $t_0$"; log the clipped share, and flag $k_s > 1/\theta$ | let φ float below $1-\theta$ unbounded | recommended |
| D13 | **Remove λ from the coupling.** Retire mode M and the `GAPCLOSE` arm from the v6 batch. Replace gap closure by one declared closure arm on the strength. Keep the ECM in diagnostics only | keep λ for the 2022→2035 step; keep `GAPCLOSE` | recommended |
| D14 | New time-indexed GDX symbols behind a switch; keep the old symbols; rule B needs no GAMS change | re-rank the existing symbols | recommended |
| D15 | Ordering tests (uniform, permuted, reversed, set) become a ranking option on **$u$**, composing with $k(t)$. This replaces `phi-override.yml` for v6 | keep overriding φ after the fact | recommended |
| D16 | Region-specific strength $k_{r,s}(t)$ only as an SI sensitivity | deploy it | recommended |
| D17 | **Hold fixed** in v6: one shared spec for both sectors, min–max normalisation, final-energy weights, the USA override, the θ grid {0.325, 0.50, 0.675} | change any of these too | recommended |
| D18 | Re-run the θ = 0 nulls once on the v6 fork and gate them against `v5` | reuse the `v5` nulls | recommended |
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
    for the delivered share. ADR 0050 records the change and its reason. The rule is replaced by
    a reporting duty: the out-of-support share per year travels with every $k_s(t)$ and φ(t).
  - **Saturating innovator power becomes necessary, not optional (D7).** Without a hold, $k_s$
    reads ceilings to 2100. By 2050, 56–65% of countries are above the innovator range on `v5`
    (0004 §1).
  - **The hold-2060 arm is the honest bound** on how much of each headline comes from late-century
    extrapolation. It runs for both closures at EU21 (Phase 5, wave 2).
  - **Late-century SSP differences are partly clamp-driven:** GovEff reaches the scale maximum by
    2070 under SSP1 and SSP5, and 60% of countries are above the GDP range by 2100 on SSP2 (0004
    §1, §4). The SSP results are therefore always reported next to their hold-2060 twin.

**D7 — saturating innovator power.**

- v6 reads ceilings to 2060–2100. The linear innovator term is then extrapolated 5–9 SD beyond the
  data for most countries (0004 §1). Without the clamp, half of all Diffuse ceilings exceed 9 by
  2100 and the ordering compresses.
- The saturating form $x/(x + \bar x)$ already exists (ADR 0040, `satAP`). It decays at the
  physical domain, not at the sample edge.
- "Declared, not selected" follows the precedent of the trend shape (`MODEL.md` §2.3.1). Selection
  is made over everything else.
- The other clamps stay: log population (up to 130 SD), the upper bound on incumbent power per
  capita (40–75 SD outliers), GDP and GovEff. They cost nothing today and stop explosions under
  SSP inputs (0004 §1).
- **The linear-clamped spec stays as an SI rung**, because it was the `v5` choice and 76% of
  bootstrap winners chose the linear `bothIncAP` form (methodology).

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
  Governance Index, Government Effectiveness, Control of Corruption and Rule of Law for SSP1–5 to
  2100, but **no voice or accountability series** (checked in `data/madrat/convertSSPextensions.rds`).
- A declared storyline table, swept, is the honest option; Leininger et al. (2024) give the
  storyline language.
- **Ordering matters:** no accountability option reaches half the bootstrap winners on `v5`, so
  the re-sweep may drop the channel. Implement the declared rule only if the `v6` spec keeps it.
- Side note: Rule of Law *is* SSP-projected. If the re-sweep picks it (it is in 92% of the `v5`
  top-60), its SSP path is free.

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
      P5). Revise `MODEL.md` §7 through ADR 0050.
- [ ] **A1b — stability and damping:** damping in R, logged, used only on oscillation (D5; P3).
- [ ] **A1c — interface changes:** history file stores φ(t) and $k_s(t)$ per call; time-indexed
      φ for ratio mode and the rule-C rebuild (D14; P3).
- [ ] **A1d — SSP level and spread:** $k_s$ per SSP; declared spread as an SI arm (D11; P5).
- [ ] **A2 — Next step 2a: panel to 2023.** Verify that CAPMF, WGI, V-Dem and the energy data
      cover 2023 without imputation (CAPMF is in the vintages through 2023: GP-19 /
      `input-vintages.rds`). Move the anchor and the trend freeze year to 2023 (D8; P2).
- [ ] **A3 — Next step 2b: SSP projections.** Expose `drivers_SSP1…5` in `calcSSPextensions()`;
      add an `ssp` argument to `panelDataScenario()`; GDP and population by SSP; the
      accountability rule (D9, D10; P2).
- [ ] **A4 — Next step 3: geothermal in the hydro/nuclear control.** Add it in `mrpfm` (historical
      panel) **and** in the REMIND-side computation of the share from primary energy
      (`iamCalculatedDrivers` / `downscaleREMINDResults`); refit inside the one re-sweep (D8; P2).
- [ ] **A5 — Next step 4: actor-power clamps.** Saturating innovator, declared; other clamps kept
      (D7; P2). Report `driverOutOfSupport` per year with every run (P3).
- [ ] **A6 — Next step 5: annual estimation** as a robustness rung on `v6` (D3; P2).

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
- [ ] **C3** — Decompose $k_s(t)$ by driver group: actor power (the REMIND feedback), institutions
      (SSP), controls (income, population), plus a composition term. This is the mechanism figure,
      and the v6 form of `TODO.md` 4 (P1 prototype, P6 figure).
- [ ] **C4** — Regional strength $k_{r,s}$ as one SI arm (D16; P5).
- [ ] **C5** — $E$-hold (static-share) bound as one SI arm (D2; P5).
- [ ] **C6** — A precomputed **anchor artifact** per Run-Group (`phi-anchor.rds`: $q_{c,s}$,
      $u_{r,s}$ per resolution, weights, provenance shares). It is written by a new step after
      `psm-donor`, so the in-REMIND call no longer needs the ECM, `temporal-validation.rds` or the
      seed panel (P2/P3).
- [ ] **C7** — Propagate the anchor-year uncertainty to the coupled share: rank intervals,
      frontier rungs and the spec band, all now on the delivered object. Offline first (P1/P6);
      coupled only for the rung that moves the floor region.
- [ ] **C8** — Seam test at the anchor: $\eta^{scen}_{c,s,t_a} = \eta^{hist}_{c,s,t_a}$ per country,
      after `panelDataScenario()`'s harmonisation. A seam would enter $k$ directly (P1 acceptance
      test, `PITFALLS.md` §21).
- [ ] **C9** — Re-examine the ceiling-fall gate (`TODO.md` 11a). Under v6 the ceiling trajectory
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
- [ ] **E5** — `iterativePFM()` defaults are stale. `group = "psm-country-v3"`. `weightYear = 2050`,
      while the deployed runs use 2025 via `preparePFM.R`, so an offline call silently uses
      different weights. The help text points to `docs/psm-coupling-scenario-design.md`, which does
      not exist. Comments say "phi is time-invariant by construction (tiers fixed at 2022)". `nTiers`
      is unused under the continuous rule. Fix the defaults and comments.
- [ ] **E6** — `projectFeasiblePath(rule = "frozen-gap")` returns NA on the coupled scenario frame:
      the seed ceiling comes from the earliest frame year (0004 caveats). Replace it with the v6
      anchor computation (C6) rather than patching it (P1).
- [ ] **E7** — `v5` inconsistency: covered countries are λ-projected while uncovered ones hold
      $E$, inside one regional aggregate (D1). Removed in v6. `papers/pfm-paper-v5` is not submitted (D19), so it
      needs no disclosure. The new paper's `v5` → `v6` comparison names it as one reason for the
      change.
- [ ] **E8** — Convergence checks only the economy-wide floor φ, not the per-market shares (D5; P3).
- [ ] **E9** — SSP2 is hard-coded in the scenario panel and in `calcSSPextensions()` (D9; P2).
- [ ] **E10** — The stale seed `input/p45_regiDiff_feasibility.inc`, an H12-shaped export from
      2026-08-10 (`TODO.md` 20). Delete it, and let runs start uncoupled until the first call.
- [ ] **E11** — No GAMS peak-budget check next to `pm_pfmBudgetWarn` (`TODO.md` 32, `PITFALLS.md`
      §26). Add it in the P3 GAMS pass.
- [ ] **E12** — No bind-share diagnostic for mode R (`TODO.md` 21). Needed if ratio mode stays as
      rule C's sensitivity (P3). Mode M is retired (D13).
- [ ] **E13** — Nothing screens a corrupt frontier covariance in `runPSMSweep()` (`TODO.md` 40).
      Needed before the `v6` sweep (P2).
- [ ] **E14** — `.driverSupportRanges()` excludes the trend from the guard (`TODO.md` 11a). A
      harmless clean-up; do it with D7.
- [ ] **E15** — `config.yml` is stale:
  - comments reference `psm-country-v4`;
  - the scenario registry has only the 2026-08-26 SSP2 pair;
  - the legacy hurdle keys remain.

  Add the SSP dimension to the registry (P2).
- [ ] **E16** — The scenario-config generator is out of sync with the hand-maintained CSV
      (`buildPFMScenarioConfig.R`, 🔴 note) → D22 (P4).
- [ ] **E17** — Each PFM call takes 128–189 s (median 159 s, `TODO.md` 9). Profile it before
      optimising. The likely cost is `panelDataScenario()` rebuilding every exogenous series and
      calling `panelDataHistorical()` for harmonisation on every call. Cache the exogenous,
      SSP-specific part once per run in `preparePFM` (P3).
- [x] **E18** — **Done 2026-10-01.** Non-governed files left `docs/`:
      - `PFM-Methodology.docx` and `MODEL_NOTATION_TABLE.html` → `../communication/methodology/`;
      - `LAMBDA-EXPLAINED.html` → `output/pfm/v5/lambda-explained/`;
      - the two `pfm_*coupling*.md` notes → `../_archive/_wip/2026-10-01/docs/`.

      See `../_archive/_wip/2026-10-01/MOVES.md`.
- [ ] **E19** — `paper-check` run from inside `papers/pfm-paper-v5/` reports every data source as missing
      (decisions-v18). Fix it in `paper-forge` before the new workspace relies on it.
- [x] **E20** — **Done 2026-10-01** (`../_archive/_wip/2026-10-01/MOVES.md`).
      - Root clutter, `_bckp/`, `tmp/` and `slide_assets/` were archived.
      - Run-Groups `v1`–`v4` (output, gdx, output/remind-inputs), `paper/`, `data/runs/` and 12 dead
        `analysis/` scripts were archived.
      - `output/remind-runs/` now holds runs as `output/remind-runs/<group>/<resolution>/`.
      - **Still pending:** `paper-skills/` (locked by another program when the move ran).
      - The layout is described in the root `README.md`.

Found by the local reproduction test of 2026-10-01 (`../_archive/_wip/2026-10-01/docs/RUNNING.md`, §6):
- [x] **E21** — With the Fit Cache in its own folder, the fitted panel was not found, and every
      step silently rebuilt it from madrat. **Fixed** in `pfm` (`.psmPanelCandidates()`, with a
      test). The fix must be committed and pushed before any v6 run.
- [x] **E22** — `pfmReplayInterface()` looked for REMIND at `../remind_pfm` and skipped silently.
      **Fixed** (searches `models/remind_pfm*`).
- [ ] **E23** — A step that fails inside (for example a scenario panel that cannot be built)
      still lets `pfmRun()` exit 0, and the previous artifact stays in place. Make a failed step
      fail the run, and delete or flag the stale artifact (`PITFALLS.md` §18).
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
- [ ] **E25** — Under `forcecache`, madrat reads the newest-timestamped file among those whose
      arguments match. **For new groups, solved by ADR 0047**: the prepared cache holds one
      version of each calculation, and its `cache-manifest.tsv` is the record. Deposit those
      files with the version. **Still open for `v5`:** fetch the 48 shared-cache files its
      coupled runs read from `/p/projects/rd3mod/inputdata/cache` before they are cleaned up
      (`records/v5/madrat-cache-used-runs.tsv`).

### F. Refactors to make model and scenario runs easier to create and submit

- [ ] **F1 — Scenario matrix → generated config (D22).** One YAML lists:
  - the canonical parents per SSP and resolution;
  - the arms (closure, θ, markup, ordering test, hold year, spread, κ);
  - the Run-Group per arm;
  - the warm-start chain and the start tags.

  `buildPFMScenarioConfig()` writes the CSV, and `validatePFMScenarioConfig()` runs on the output.
  Section separators and `path_gdx` chains are generated, not typed. Adding an SSP becomes one line.
- [ ] **F2 — `pfmPreflight()`.** One call, before any submission, checking what `PITFALLS.md`
      §1–§3 and §23 leave to memory:
  - every sub-repo is clean and pushed;
  - the `pfm` version *installed in the run library* equals the working tree;
  - every `pfmGroup` named in the start group exists in `output/remind-inputs` with its anchor artifact;
  - the mappings are installed;
  - the replay harness and negative control pass;
  - the SSP is consistent across row, NPi reference and anchor donor (D9).

  It refuses to proceed on any failure.
- [ ] **F3 — A submit wrapper.** `submitPFM(startgroup, dry = TRUE)` runs the preflight, prints the
      rows and Run-Groups it will start, then calls REMIND's `start.R`. It records the commits used
      into a batch manifest (this answers the per-run provenance that `runProvenance.R`
      reconstructs today after the fact).
- [ ] **F4 — A post-batch stage:** `pfmRun(stage = "coupled", batch = …)`. It runs, in order:
  - `extractCoupledResults`, then its flags;
  - `coupledBatchFacts`, `coupledCostsAndAbatement`, `heldBudgetPrices`, `ruleCBoundFreeze`,
    `coupledRunConvergence`, `runProvenance`.

  It writes `coupled-facts.json` stamped with the Run-Group, and **stops on the §25 / §25a
  admission rules** instead of leaving them to the reader. This is today's checklist after a batch
  lands, as one command.
- [ ] **F5 — Promote the reproduction-chain scripts into package code.** Move the `analysis/`
      scripts the paper's numbers depend on (the F4 list, `makeGroupVariants.R`,
      `buildPFMScenarioConfig.R`, `validatePFMScenarioConfig.R`) into `pfm` (compute: extraction,
      facts) or `analysis/figures/` (rendering), with tests. One-off scripts stay in `analysis/`. This is
      the code half of the deposit (D-M3).
- [ ] **F6 — The anchor artifact as a pipeline step** (C6). `pfmRun(stage = "remind")` exports it
      with the rest. The in-REMIND call then reads one small file instead of re-deriving the ranking.
- [ ] **F7 — Cache the exogenous scenario panel per SSP** in `preparePFM` (E17). Expected to cut
      each call substantially; measure before and after.
- [ ] **F8 — Typed options instead of side files.** Ordering tests (D15), hold year (D6), spread
      (D11), κ (D13) and the formulation switch become `pfm-coupling.yml` or runtime-config fields.
      Each is echoed in the log and recorded in `pfm-phi-history.rds`. `phi-override.yml` is kept
      only for `v5` reproduction.
- [ ] **F9 — The `psm*` → `pfm*` rename** (D21): the first step of Phase 0. One isolated commit
      per repository, with read-aliases for `selected-models-psm.yml`, the `psm-*` step names and
      the old exported functions.

### G. Documentation and governance

- [ ] **G1 — ADRs** (P1 drafts, accepted at the P2/P3 gates):
  - 0047 anchored gap with logit hold and mean-gap strength (D1, D2, D4, D12);
  - 0048 λ removed from the coupling, mode M and `GAPCLOSE` retired, the κ arm (D13);
  - 0049 SSP-consistent scenario panel and accountability rule (D9, D10, D11);
  - 0050 saturating innovator, clamp policy and hold year (D6, D7);
  - 0051 the `v6` panel: 2023, geothermal, one re-sweep (D3, D8);
  - 0052 time-indexed φ interface and convergence on the φ path (D5, D14);
  - 0053 the generated scenario config (D22).
- [ ] **G2 — Close the design notes.** 0003 (λ in or out) → ADR 0048. 0004 → ADRs 0047 / 0050 /
      0051. 0002 stays open, informed by the re-sweep. This note → closed when Phase 6 ends.
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
2. **Small fixes:** E5, E10, E13, E14, E20; E19 in the forge. Optionally E11 and E12 now; otherwise
   they go into the P3 GAMS pass.
3. **Push everything** and reinstall `pfm` on the cluster. Verify the installed version from inside
   `models/remind_pfm/` (`PITFALLS.md` §2, §23).

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

**Gate, and the decision it feeds:**
- **If the SSP spread of $k$ is small next to θ's range** (hypothesis H1 of the architecture note),
  the SSP axis goes to the SI as "measured and small". The main batch is SSP2 only, plus one SSP
  pair. Otherwise SSP1 / SSP3 become a main-text axis.
- ADRs 0047–0052 drafted. Methodology document updated (G4).

### Phase 2 — Data and estimation, Run-Group `v6` (two to three weeks; cluster for the sweep)

1. **`mrpfm`:**
   - `calcSSPextensions(subtype = "drivers_SSPx")` for x = 1…5 (or a `scenario` argument);
   - geothermal in the clean-baseload control (A4);
   - panel inputs to 2023 after the coverage check (A2);
   - the accountability storyline rule in `toolProjectScenario()`, parameterised, with SSP2
     reproducing today (D10).
2. **`pfm` scenario panel:** an `ssp` argument everywhere SSP2 is hard-coded (E9). Split the
   exogenous part, which is cacheable per SSP (F7), from the REMIND-dependent actor power.
3. **The REMIND-side driver computation:** geothermal included, so the scenario control matches the
   historical one. Check with the seam test (C8).
4. **The sweep (D7, D8):** innovator power declared saturating; the trend freeze at the anchor year;
   the covariance screen in place (E13). Then:
   - selection, selection bootstrap, frontier, diagnostics and inference;
   - the spec band (the `v6-specalt` analogue);
   - the ceiling-fall gate re-checked (C9);
   - the annual-data rung (A6);
   - the linear-clamped rung (D7).
5. **Donor assignment at the anchor year,** then the **anchor artifact** (C6, F6). Then
   `pfmRun(group = "v6", stage = "remind")`.
6. **Write the `v5` → `v6` comparison:** spec, coefficients, $E$ ordering at the anchor, regional
   $u$, floor regions. This becomes Methods and SI material for the new paper.

**Gate:** deployed `v6` spec diagnostics at least as clean as `v5` (γ, gates, influence, sign
stability). The 2023 coverage decision is recorded. D10 resolved: accountability kept or dropped.

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

**Gate:**
- the θ = 0 null on the v6 fork reproduces the `v5` null within the `SCENARIOS.md` §3.1 tolerance;
- one EU21 rule-B test run converges, with the φ path and $k$ in its log and history;
- one EU21 rule-C test run shows a rebuild error of about 1e-6 (`p45_pfmBoundCheck_iter`) with the
  path loaded;
- the call time is measured (E17).

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
| 2 | ordering tests: Bfix uniform, permuted 1–3, reversed; C uniform, permuted 1 | EU21 (H12 for Bfix uniform + 1 permuted) | 7 + 2 | D-M1 / GP-24 |
| 2 | assignment rules: Bfix and C × all-median, all-low; USA donor / low (Bfix) | EU21 | 6 | D-M2 (ii), GP-3 / 10 |
| 2 | markup off (`-Min`) for B and C; ratio mode for C | EU21, H12 | 6 | v5 continuity |
| 2 | spec band and rungs: Bfix on `v6-specalt`, linear-clamped, annual | EU21 | 3 | D7, D3 |
| 2 | formulation arms: $E$ hold (Bfix), hold 2060 (Bfix **and** C), regional $k$ (Bfix), closure κ (Bfix and C) | EU21 | 6 | D2, D6, D16, D13 |
| 3 | hold-2060 twin of each SSP's `-PFMlevelBfix` | EU21 | 2 | D6: SSP results always travel with their hold-2060 twin |
| 3 | SSP1, SSP3: uncoupled NPi and PkBudg1000 (if not canonical), `-PFMgate`, `-PFMgateBfix`, `-PFMlevelBfix`, `-PFMlevelC` | EU21 | 12 | the SSP axis (if Phase 1 keeps it) |
| 3 | declared spread arm per SSP | EU21 | 2 | D11 |

About 70 runs in total, close to the `v5` batch (62 + 16 variants). Wave 3 depends on the Phase 1
gate.

**SSP3 at 1000 Gt may be infeasible in REMIND regardless of politics** (architecture note, H6).
Test the uncoupled SSP3 PkBudg1000 first. If it fails, use a budget that SSP3 can meet and say so;
do not reuse the SSP2 budget.

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
