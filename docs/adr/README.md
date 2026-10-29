# Architecture Decision Records — index

All 44 records are kept: an ADR is an append-only audit trail, and a superseded decision is
still the reason the code looks the way it does. This index exists so a session knows **which
few actually govern current behaviour** without opening them all.

**Status column:**

- **Active** — governs how the selected model, coupling or infrastructure behaves today.
- **Historical** — accepted and still in force *for the code it describes*, but that code
  belongs to the retired two-stage hurdle model (adoption logit + stringency GLM) or to
  infrastructure that has since been rebuilt. Read for context, not for current rules.
- **Superseded** — explicitly replaced by a later ADR.

The hurdle model was superseded by the frontier formulation on 2026-08-14; its ADRs are marked
Historical rather than removed. Note that ADRs written before that date use *PSM* for what the
current docs call **PFM**, and some cite documents that now live in
`Elevate/_archive/2026-08-14/` (`PSM_EQUATIONS.md`, `PSM_TODO.md`, the roadmap). Those citations
are left as written — an ADR records what was true when it was decided. For current mathematics
read `docs/MODEL.md`, not the archived copy.

| # | Decision | Status |
|---|---|---|
| 0001 | Model serialisation via an RDS wrapper | Superseded by 0009 (storage half) |
| 0002 | V-Dem variable naming convention | **Active** |
| 0003 | `pfmModel` S3 class | **Active** (storage half superseded by 0009) |
| 0004 | Guided model-selection algorithm | Superseded by 0036/0039 (tournament) |
| 0005 | First-difference support, hazard adoption | Historical (hurdle) |
| 0006 | Pure-consumer reports | **Active** — reinforced by 0018 |
| 0007 | Stringency projection robustness | Historical (price-stringency model) |
| 0008 | Lagged stringency recursive projection | Historical (hurdle) |
| 0009 | Split cache + REMIND coupling storage | **Active** — the three-part persistence split |
| 0010 | Out-of-sample time-trend freeze | **Active** — still how $T(t)$ is projected |
| 0011 | Exhaustive control and FE dimensions | **Active** — the sweep's dimension grid |
| 0012 | BIC parsimony tiebreak | **Active** |
| 0013 | Leave-one-region-out robustness | **Active** |
| 0014 | Difference-first selection, falsification gate | Historical |
| 0015 | Temporal-split (out-of-time) validation | **Active** — the skill-vs-persistence protocol |
| 0016 | Subnational coverage toggle | Historical |
| 0017 | SSP2 GDP/population source | **Active** — the aggregation weights depend on it |
| 0018 | Compute/report layering, Results Root | **Active** — `pfm` computes and never renders; the report layer it names (`pfmreports`) was archived 2026-10-01, and rendering is `analysis/figures/` |
| 0019 | Parallel sweep execution, Fit-Cache concurrency | **Active** |
| 0020 | Run entrypoint, SLURM run record | **Active** — `pfmRun()` + `manifest.json` |
| 0021 | `pfmreports` as a package | Historical — `pfm-reports` archived 2026-10-01 (`../_archive/_wip/2026-10-01/models/pfm-reports`) |
| 0022 | FE-discounted parsimony, drop idle controls | **Active** |
| 0023 | Projection plausibility filter, clamp fix | Historical (clamps are unnecessary under satP) |
| 0024 | PFM↔IAM coupling: the feasibility envelope | **Active** as doctrine; its κ mechanism superseded by 0041 |
| 0025 | Selection-uncertainty quantification | **Active** — the selection bootstrap |
| 0026 | Saturating stringency response (satP engine) | **Active** — the selected response transform |
| 0027 | Temporal-stability frontier | **Active** |
| 0028 | Saturating stringency swept as a variant | Supersedes the sweep half of 0026 |
| 0029 | Adopter classification and thresholds | Historical (hurdle) |
| 0030 | Parallel report rendering | **Active** |
| 0031 | Priority-mode autosizing | **Active** (cluster QOS) |
| 0032 | Clamp role and unclamped display | Historical |
| 0033 | Trend-dominance gate | **Active** — the trend-share criterion in selection |
| 0034 | Bootstrap fit cache | **Active** |
| 0035 | Multi-scenario policy projection | **Active** — the scenario registry in `config.yml` |
| 0036 | Policy stringency model on CAPMF | **Active** — constitutes the current model |
| 0037 | No selection on significance | **Active** — except item 2 (the within-band \|t\| preference), superseded from `v6` by 0048 |
| 0038 | Von Dülong context controls, not channels | **Active** |
| 0039 | Tournament v2 selection | **Active** — how `X-0370` was chosen |
| 0040 | Saturating actor power + support gate | **Active** — the `satAP` transform |
| 0041 | Relative feasibility coupling instead of κ | **Active** — supersedes the κ mechanism of 0024 |
| 0042 | Sector-differentiated price via emission markets | **Active** — refines 0041's delivery step; `min` survives only when `cm_pfmSectorMarkup = 0` |
| 0043 | Ceiling-collapse selection gate | **Active, flagged for review (2026-10-07)** — extends 0036/0039/0040; `ceilingFallGate = 0.90` by default, unsafe without 0040's support gate. Under v6 it decides the sign of power & industry $k$ for the specs it alone rejects; revisit with the revised (PoliClim-informed) projections (0005 §7a decision 8) |
| 0044 | Actor power = fossil dependence **and** per-capita level (`bothIncAP`) | **Active** — selected as `X-2367` in `v3`, and again as `X-2079` in **`v5`** via ADR 0045. `MODEL.md` §2 still describes the old share form |
| 0045 | Extrapolation gate at **0.275**; θ sweep **declared** `{0.325, 0.50, 0.675}`, not anchored | **Active** — deploys `X-2079 bothIncAP` in `v5`. Threshold moved *after* candidates were known; power & industry has no admissible θ anchor. Both disclosed in the ADR |
| 0046 | γ-boundary gate **on at 0.999** | **Active** — completes ADR 0043, which asked for this and implemented nothing. Rejects 7 of 19 surveyed specs incl. maximin rank 3; the `v5` deployment is unaffected (γ 0.987/0.982) |
| 0047 | One prepared madrat cache per Run-Group, staged into every coupled run | **Active** from `v6` — estimation and coupling read one set of data versions (`data/madrat/<group>/cache-manifest.tsv`); `v5`'s runs read the shared PIK cache |
| 0048 | Soft fragility keys (`softVifGate`, `inferenceTGate`) leave the within-band order; the hydro/nuclear/geothermal control stays | **Active** from `v6` (2026-10-05) — supersedes ADR 0037 item 2 and the soft VIF preference; declared in `config.yml` `sweep:` and recorded per group in `manifest.json`; decided before the corrected `v6` sanity results were read |
| 0049 | The v6 coupling: anchored gap, distance kept, mean-gap strength, anchor artifact | **Accepted** (2026-10-08, at the 0005 Phase 3 gate) — refines 0041 (φ becomes a path) |
| 0050 | λ leaves the coupling; mode M and `GAPCLOSE` retire; κ sensitivity run | **Accepted** (2026-10-08, at the 0005 Phase 3 gate) — closes design note 0003; offline, most of the v5 → v6 change in the bound; κ = 0.027 (0.02, 0.05 sensitivities) declared 2026-10-08 |
| 0051 | Scenario panel: one SSP per run, institution rule, every series harmonised, driver lag in years | **Accepted** (2026-10-07); items 1–4 implemented and in the `v6` re-run; the `v6` paper is SSP2 only |
| 0052 | Saturating actor power: the both-saturate family main text, the clean-energy-only family SI, curve-shape check, no hold year | **Accepted** (2026-10-07; author's decisions D6, D7, 0005 §7a 6 and 8); keeps 0043, flagged |
| 0053 | The `v6` panel: 2023 (IEA 2025), geothermal, one re-sweep; power & industry γ 0.997 accepted | **Accepted** (2026-10-07; D3, D8 decided; Phase 2 gate passed) |
| 0054 | Time-indexed φ interface; convergence on the φ path | **Accepted** (2026-10-08, at the 0005 Phase 3 gate, runs `EU21V371`) — implemented 2026-10-07 |
| 0055 | Generated scenario config | **Accepted** (2026-10-07), implemented: `pfm::buildPFMScenarioConfig()`, `analysis/run-groups/scenario-matrix-v6.yml` |
| 0057 | The growing-limit rate: κ = −0.005 a year, declared as a bound | **Accepted** (2026-10-13): the fastest rate the share formula represents at θ = 0.675; history as a plausibility check; declared after `V6BACK`, on checks that use no coupled result |
| 0056 | Actor power presented as the economic weight of fossil and clean-energy interests, a proxy for structural power | **Accepted** (2026-10-12): reader-facing wording; model and code names unchanged |
| 0058 | Estonia stays out of the estimation in v7 | **Accepted** (2026-10-14): the oil shale burned in its power, CHP and heat plants is not in `PE` (26–49% of its supply); back only after that is fixed (PITFALLS §27; `analysis/checks/estoniaEnergy.R`) |
| 0059 | The specification search requires the political-economy hypotheses it is built on | **Accepted** (2026-10-25): H1 fossil dependence lowers the ceiling, H2 its effect depends on institutions (sign free), H3 it is a constraint over at least 75% of the sample; theory gate of the v7 search (0007 §15) |
| 0060 | The v7 specification: v6's channels, democracy-weighted interactions, saturating clean-energy interests | **Accepted** (2026-10-25): X-1791 `satInn iw:fexp`; H1 in both sectors, edge effects of v6 gone, ranking changes (China, India); no O1 cap |
| 0061 | Fossil rents set the size of the slack in buildings & transport, not the ceiling | **Proposed** (2026-10-28): log sigma_u = c + w log(1 + rents) in B&T; on the v8 spec w 0.277, z 12.1, better out of sample in 38 of 48 countries; P&I homoscedastic; in the coupling the distance kept follows each country's rents times its REMIND region's ratio to 2025, on top of the ceiling's movement and kappa (not under the constant/growing-limit bounds); `v8` |
| 0062 | The v8 specification and coupling: every actor-power term saturating, the fossil terms bounded, the rents slack, countries without data at the covered median, the regional strength central | **Proposed** (2026-10-29): X-1791 `satAP iw:fexp fos5` (v7's `satInn` form fails the γ gate by 0.000004); H1 stronger; P&I clean-energy term gone and B&T H2 weaker under the wild bootstrap, disclosed; the median beats the donor rule out of sample; less effort held back than v7 |
| 0063 | The SSP2 institution projection: every country closes 0.6% of its gap to the best observed value each year | **Proposed** (2026-10-29), records the author's decision of 2026-10-27 (design note 0008): revises ADR 0051 item 2; rate bounded by Andrijevic SSP2 (0.54–0.62%) and V-Dem history; government effectiveness under the rule, Andrijevic's path the sensitivity; central in `v8` |

**The eight that govern the current model most directly:** 0036 (what the model is), 0039 + 0043
(how it was selected), 0044 (what actor power *is*), 0040 (actor-power transform), 0026 (response
transform), 0041 (how it couples), 0042 (how the two sectors reach REMIND), 0024 (why it couples
that way).
