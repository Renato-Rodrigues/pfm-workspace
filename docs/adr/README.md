# Architecture Decision Records — index

All 44 records are kept: an ADR is an append-only audit trail, and a superseded decision is
still the reason the code looks the way it does. This index exists so a session knows **which
few actually govern current behaviour** without opening them all.

**Status column:**

- **Active** — governs how the deployed model, coupling or infrastructure behaves today.
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
| 0026 | Saturating stringency response (satP engine) | **Active** — the deployed response transform |
| 0027 | Temporal-stability frontier | **Active** |
| 0028 | Saturating stringency swept as a twin | Supersedes the sweep half of 0026 |
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
| 0043 | Ceiling-collapse selection gate | **Active, flagged for review (2026-10-07)** — extends 0036/0039/0040; `ceilingFallGate = 0.90` by default, unsafe without 0040's support gate. Under v6 it decides the sign of Bulk $k$ for the specs it alone rejects; revisit with the revised (PoliClim-informed) projections (0005 §7a decision 8) |
| 0044 | Actor power = incumbent share **and** per-capita level (`bothIncAP`) | **Active** — deployed as `X-2367` in `v3`, and again as `X-2079` in **`v5`** via ADR 0045. `MODEL.md` §2 still describes the old share form |
| 0045 | Extrapolation gate at **0.275**; θ sweep **declared** `{0.325, 0.50, 0.675}`, not anchored | **Active** — deploys `X-2079 bothIncAP` in `v5`. Threshold moved *after* candidates were known; Bulk has no admissible θ anchor. Both disclosed in the ADR |
| 0046 | γ-boundary gate **on at 0.999** | **Active** — completes ADR 0043, which asked for this and implemented nothing. Rejects 7 of 19 surveyed specs incl. maximin rank 3; the `v5` deployment is unaffected (γ 0.987/0.982) |
| 0047 | One prepared madrat cache per Run-Group, staged into every coupled run | **Active** from `v6` — estimation and coupling read one set of data versions (`data/madrat/<group>/cache-manifest.tsv`); `v5`'s runs read the shared PIK cache |
| 0048 | Soft fragility keys (`softVifGate`, `inferenceTGate`) leave the within-band order; the hydro/nuclear/geothermal control stays | **Active** from `v6` (2026-10-05) — supersedes ADR 0037 item 2 and the soft VIF preference; declared in `config.yml` `sweep:` and recorded per group in `manifest.json`; decided before the corrected `v6` sanity results were read |
| 0049 | The v6 coupling: anchored gap, logit hold, mean-gap strength, anchor artifact | **Accepted** (2026-10-08, at the 0005 Phase 3 gate) — refines 0041 (φ becomes a path) |
| 0050 | λ leaves the coupling; mode M and `GAPCLOSE` retire; κ arm | **Accepted** (2026-10-08, at the 0005 Phase 3 gate) — closes design note 0003; offline, most of the v5 → v6 change in the bound; κ = 0.027 (0.02, 0.05 sensitivities) declared 2026-10-08 |
| 0051 | Scenario panel: one SSP per run, institution rule, every series harmonised, driver lag in years | **Accepted** (2026-10-07); items 1–4 implemented and in the `v6` re-run; the `v6` paper is SSP2 only |
| 0052 | Saturating actor power: family A main text, family B SI, curve-shape check, no hold year | **Accepted** (2026-10-07; author's decisions D6, D7, 0005 §7a 6 and 8); keeps 0043, flagged |
| 0053 | The `v6` panel: 2023 (IEA 2025), geothermal, one re-sweep; Bulk γ 0.997 accepted | **Accepted** (2026-10-07; D3, D8 decided; Phase 2 gate passed) |
| 0054 | Time-indexed φ interface; convergence on the φ path | **Accepted** (2026-10-08, at the 0005 Phase 3 gate, runs `EU21V371`) — implemented 2026-10-07 |
| 0055 | Generated scenario config | **Accepted** (2026-10-07), implemented: `pfm::buildPFMScenarioConfig()`, `analysis/run-groups/scenario-matrix-v6.yml` |

**The eight that govern the current model most directly:** 0036 (what the model is), 0039 + 0043
(how it was selected), 0044 (what actor power *is*), 0040 (actor-power transform), 0026 (response
transform), 0041 (how it couples), 0042 (how the two sectors reach REMIND), 0024 (why it couples
that way).
