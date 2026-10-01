# 0004 — What a v6 formulation could change: clamps, smoothing, tier years, SSPs

**Status: Open.** Evidence for a possible v6 definition; nothing here is decided or deployed.

**Provenance.** Run-Group `v5`, offline, 2026-09-29. Script `analysis/v6/v6FormulationTests.R`
(parts `guard`, `annual`, `tiers`, `ssp`); outputs in `output/pfm/v5/v6-tests/*.rds`. Unless stated,
coefficients are the deployed `v5` fits (`X-2079`), the energy system is the **final** state of one
coupled run (`SSP2-EU21-PkBudg1000-PFMlevelBfix`, EU21), shares are aggregated with the deployed
final-energy weights and band assignments at θ = 0.50. REMIND is **not** re-optimised, so no
energy-system feedback responds to any variant. Shares below 2035 read "φ"; "Spearman" is across the
21 EU21 regions against the stated reference.

---

## 1. Actor-power clamps (and the others)

**What the guard does now.** `psmDriverGuard()` winsorises *every* standardised base driver of the
linear (`lev`) spec at its 2001–2022 training range, then rebuilds the interactions from the clamped
factors. The scenario panel clamps GovEff, GDP and population a second time during normalisation.

**Which clamps bind, when, and by how much** (share of all 248 countries outside the training range;
excess in training SDs; `guard.rds$audit`):

| driver | 2035 out | 2050 out | 2100 out | typical excess | reading |
|---|---:|---:|---:|---|---|
| **Innovator power** (above) | 8 / 10% | 56 / 65% | 63 / 78% | p95 **5–9 SD** | **the clamp that shapes results after 2035** |
| Innovator power (below) | 19 / 20% | 15% | 15% | < 1 SD | low-VRE uncovered countries |
| Incumbent share (below) | 17% | 19–21% | 37–38% | ≤ 1.3 SD | bounded by 0; harmless |
| Incumbent per capita (below) | 52–54% | 98% | 98% | ≤ 0.2 SD | harmless |
| Incumbent per capita (**above**) | 1% | 0 | 0 | **up to 40–75 SD** in 2025–35 | a few extreme per-capita fossil economies — **keep** |
| Log population (below) | 26% | 26% | 26% | up to **130 SD** | tiny territories, structural — **keep** |
| GDP per capita (above) | 4% | 15% | 60% | p95 5.7 SD by 2100 | grows with SSP income — **keep** |
| GovEff (above) | 0.4% | 6% | 16% | ≤ 0.12 SD | already clamped upstream |
| Vertical accountability | 0.4% | 0 | 0 | — | never binds |
| Hydro/nuclear share | 1% | 2% | 2% | small | never matters |

(Bulk / Diffuse where they differ.)

**Removing clamps** (`guard.rds$phiCompare`, `$ceiling`):

| variant | φ 2035 vs deployed | φ 2050 | φ 2070 | Diffuse ceiling 2100 (median; share > 9) | Bulk median E 2100 |
|---|---|---|---|---|---|
| innovator unclamped | Spearman **0.977**, median \|Δφ\| 0.005, max 0.031, same floor | 0.878 / 0.100 / 0.238 | 0.824 / 0.116 / 0.286 | 9.00; **50%** (deployed 7.43; 0%) | **0.18** (deployed 0.45) |
| all actor power unclamped | 0.977 / 0.006 / 0.031 | 0.885 / 0.101 / 0.252 | 0.840 / 0.118 / 0.279 | 8.99; 50% | 0.17 |
| no guard at all | 0.979 / 0.006 / 0.072 | 0.876 / 0.101 / 0.252 | 0.835 / 0.120 / 0.284 | 8.99; 50% | 0.19 |

**Answers.**

- **Can the innovator clamp go?** *For the deployed single 2035 reading, yes, at almost no cost*:
  φ moves by a median 0.005 and at most 0.03, and the floor is unchanged. By 2035 few countries have
  left the innovator range.
- **What plays against it** — everything after 2035. Most countries end up 5–9 SD beyond any observed
  innovator share, and a *linear* coefficient is then extrapolated that far:
  - the Diffuse ceiling runs into the logit bound: half of all countries above 9 by 2100, so the
    ordering compresses at the top and stops discriminating;
  - Bulk stringency is projected to **fall** as renewables grow (median E 0.45 → 0.18), because the
    Bulk ECM innovator coefficient is negative (−0.077, not significant). An insignificant sign
    becomes a first-order projection.
- **Relaxing the other clamps** changes nothing measurable (`noGuard` ≈ `noActorPower` at every
  tier year), because in this SSP2 run they barely bind. That is also why they should **stay**: they
  cost nothing now and are exactly what stops explosions once SSP inputs move. Keep, in order of
  importance: log population (structural, 130 SD), incumbent per capita *upper* bound (40–75 SD
  outliers), GDP per capita (60% out by 2100, more under SSP5), GovEff upper bound (SSP1/5 reach the
  scale maximum by 2070, §4). VerAcc and hydro/nuclear never bind and can stay as insurance.
- **The principled way to "unclamp" innovators** is the saturating transform already in the code
  (`apTransform = "saturating"`, ADR 0040): `x / (x + x̄)` has a marginal effect that decays, and the
  guard then clamps it only at the *physical* domain (share = 1), not the sample edge. It is in the
  sweep's menu (`satAP`); the best per-sector Diffuse spec `X-1854` uses it. A v6 with later tier
  years should adopt it for innovator power, and re-run selection to do so; dropping the clamp on a
  linear term is not a defensible alternative.

## 2. Annual data instead of the 5-year moving average

The deployed specification refitted on an **annual** panel against the smoothed one, both rebuilt
from the madrat cache (the smoothed rebuild reproduces the `v5` panel to 0.018; `annual.rds`):

| | Bulk MA5 | Bulk annual | Diffuse MA5 | Diffuse annual |
|---|---:|---:|---:|---:|
| frontier slack share γ | 0.987 | 0.984 | 0.982 | 0.957 |
| frontier coefficient signs agreeing | — | **14 / 17** (flips: three near-zero terms) | — | **17 / 17** |
| E 2022, Spearman across 48 countries | — | **0.981** | — | **0.932** |
| median E 2022 | 0.707 | 0.694 | 0.746 | 0.727 |
| ECM λ (full panel) | 0.103 | **0.171** | 0.062 | **0.256** |
| lag-1 autocorrelation of yearly changes | 0.73 | −0.15 | 0.80 | 0.05 |
| share of zero year-on-year changes | 10% | 26% | 4% | 21% |

**Answers.**

- **The frontier does not depend on the smoothing.** Same signs, same slack structure, the same
  2022 ordering (0.98 / 0.93). Switching the *ceiling* to annual data changes little and removes a
  disclosed choice.
- **λ does.** Annual estimates are 1.7× (Bulk) and 4× (Diffuse) the smoothed ones: the moving
  average makes yearly changes strongly autocorrelated (0.73–0.80 vs ~0), which reads as slow
  adjustment. A large part of the deployed λ is a smoothing artefact. The placebo battery that puts λ
  inside its null was run on smoothed panels and would have to be re-run on annual ones before any
  annual λ is used.
- **It does not go against REMIND.** The frontier is a levels model without dynamics; REMIND's
  5-year periods only matter for the projection recursion, which already compounds an annual rate
  over each period (`1 − (1 − λ)^Δt`). What *would* change for REMIND is the 2022 → 2035 projection:
  at the annual Diffuse λ (half-life 2.3 yr) almost every country would reach its equilibrium by
  2035, so the 2035 share would measure the ratio of two fitted models (S_eq / S*) rather than
  observed shortfall. That strengthens the case for §3's frozen-gap reading.
- **Recommendation:** fit the frontier on annual data in v6 (or report it as a robustness rung);
  do not carry any λ into the coupling without a re-run placebo on the same data.

## 3. Extra tier years (2050, 2070)

`tiers.rds`. Two projection rules for the stringency S that the gap needs:
**speed-limited** (deployed: S moves toward the ECM equilibrium at λ, capped by S\*) and
**frozen gap** (each country keeps its fitted 2022 ratio E = S/S\*; only the ceiling moves).

| reading | speed-limited | frozen gap |
|---|---|---|
| φ 2050 vs 2035 | Spearman **0.46**, median \|Δφ\| 0.175, floor ECS,REF → CHA | Spearman 0.998, median 0.000 |
| φ 2070 vs 2035 | Spearman **0.10**, median 0.125, floor → CHA,IND | Spearman 0.996, median 0.002 |
| median relative gap, Bulk 2035 / 2050 / 2070 | 0.23 / 0.38 / 0.47 | 0.30 / 0.30 / 0.30 |
| median relative gap, Diffuse 2035 / 2050 / 2070 | 0.19 / 0.19 / 0.09 | 0.25 / 0.25 / 0.25 |

**And the finding that matters for the paper as it stands:** at the 2035 tier year itself, the two
rules give **Spearman 0.52, median \|Δφ\| 0.067, max 0.245 (UKI), floor ECS,REF → REF**. The λ
projection is a first-order determinant of the ordering the coupling receives — the question costed
as `papers/pfm-paper-v5/docs/gap-plan.md` GP-26, now answered offline.

**Answers.**

- **Under the deployed rule, later tiers reorder the world** — by 2070 the ordering is unrelated to
  2035's (0.10). What drives it is not politics: the Bulk gap widens because the projected Bulk
  equilibrium falls with decarbonisation (the incumbency and innovator coefficients of §1), and by
  2070 88% of Diffuse innovator values are out of support. That is `MODEL.md` §7's "no scenario
  differences past ~2060" in numbers.
- **Under a frozen gap, extra tiers are redundant** — and the energy-system feedback almost vanishes
  with them, because a fixed E moves the regional gap only through composition.
- **So "how to define the gap" is the real decision, not "how many tiers".** Three coherent options:

  | gap definition | tiers add | feedback | honesty |
  |---|---|---|---|
  | projected S at λ (deployed) | large reordering, model-structural after 2050 | yes | rests on an unidentified λ |
  | frozen 2022 E | nothing | nearly none | no unsupported parameter |
  | frozen E **plus a declared closure path** θ(t) = θ(1−κ)^(t−2035), κ swept | a severity path, not an ordering | through the ceiling only | declared, like θ |

- **If tiers are added anyway**, the mechanics are simple and keep the paper manageable: read φ at
  2035 and 2050, interpolate linearly between them, hold the 2050 value afterwards; do **not** go to
  2070 (support). The mode-L bound is already indexed by year (`p45_pfmPriceBound(ttot, …)`), so the
  held-price runs need no GDX change; rule C and ratio mode need a year-indexed share
  (`../_archive/_wip/2026-10-01/docs/pfm_dynamic_ssp_coupling_architecture.md` §4.4). Report it as one SI sensitivity against the
  2035-only main result, not as a second headline.

## 4. SSPs, controls, actor power and tier years together

**What exists.** The Andrijevic et al. governance paths for SSP1–5 are in the madrat cache
(`convertSSPextensions.rds`); GDP and population by SSP come from mrdrivers (not cached for all five —
a full rebuild took > 10 minutes and was stopped); actor power comes from REMIND; accountability has
**no** SSP projection. GovEff on the 0–1 index (`ssp.rds`; estimation-sample SD 0.166):

| median (p10–p90) | 2035 | 2050 | 2070 |
|---|---|---|---|
| SSP1 | 0.62 (0.45–0.93) | 0.69 (0.55–0.98) | 0.78 (0.65–1.00) |
| SSP2 | 0.57 (0.38–0.92) | 0.61 (0.45–0.96) | 0.68 (0.53–1.00) |
| SSP3 | 0.53 (0.30–0.88) | 0.55 (0.31–0.91) | 0.56 (0.33–0.95) |
| SSP4 | 0.56 (0.34–0.90) | 0.59 (0.37–0.92) | 0.63 (0.42–0.94) |
| SSP5 | 0.62 (0.44–0.93) | 0.69 (0.54–0.98) | 0.78 (0.66–1.00) |

SSP1 − SSP3 at the median: **0.55 SD in 2035, 0.87 SD in 2050, 1.32 SD in 2070.** SSP1 and SSP5 are
indistinguishable on governance, and the top decile reaches the scale maximum by 2070 under both,
where the normalisation clamp takes over.

**Answer.** Technically yes — every input exists or can be built, and the pipeline would carry them
through the same projection. But the three questions are one question:

1. SSP differences in institutions only reach the price through **later tier years** (at 2035 the
   spread is about half an SD), so SSPs need §3's decision first.
2. Later tier years only mean something with **bounded actor-power extrapolation** (§1's saturating
   transform) and a **gap definition that does not rest on λ** (§3).
3. Under min–max normalisation a shift common to all regions cancels; only *divergence* survives
   (SSP3's flat lower decile against SSP1's rising one). The SSP signal is therefore smaller than the
   governance numbers suggest and has to be measured, not assumed.

## 5. A v6 sequence this evidence supports

| step | what | cost | why first |
|---|---|---|---|
| 1 | a projection-rule switch in `iterativePFM()` (frozen 2022 E vs λ) and a frozen-gap `v5` sensitivity run | small code, 2 runs per resolution | 2035 floor and ordering depend on it (Spearman 0.52) — the paper's own open GP-26 |
| 2 | frontier on the annual panel as a rung (or as the deployed fit) | one re-fit | removes the smoothing choice; ordering already robust |
| 3 | innovator power on the saturating transform, re-select | a sweep | prerequisite for any reading after 2035 |
| 4 | a 2050 tier as an SI sensitivity: linear 2035 → 2050, held after | GDX symbol for rule C / ratio | only after 1–3 |
| 5 | SSP governance swap (SSP1 / SSP3) on the SSP2 energy system, offline | a day | measures whether the SSP signal survives normalisation before any SSP run |

## Caveats

- One coupled run's final energy system, EU21 only, θ = 0.50; REMIND does not respond to any variant,
  so these are first-round effects, not coupled results.
- Shares in §1 and §3 use deployed coefficients; §2 re-fits on rebuilt panels (control 0.018 max
  difference to the `v5` panel).
- `pfm::projectFeasiblePath(rule = "frozen-gap")` returns `NA` for every row on the coupled scenario
  frame (the seed ceiling is taken from the earliest frame year). The frozen gap here is built in the
  script from `frontier.rds` 2022 E. The coupling never calls that rule, but it is a latent defect to
  fix before step 1.
- The GovEff comparison uses the SSP index's own 0–1 normalisation, which is close to but not the same
  object as the WGI scale the model was fitted on (harmonised to observed 2022 in the scenario panel).
