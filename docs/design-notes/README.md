# Design notes — open questions about how the model should be defined

This folder holds **deeper analysis of modelling choices that are not yet settled**: the question,
the theory on each side, whatever was measured to inform it, and a recommendation. It is decision
*support*, not decision *record*.

## How this differs from the other two places

| | holds | status of its contents |
|---|---|---|
| `docs/` (the eight authoritative documents) | what the model **is** | current and true of the code |
| `docs/adr/` | decisions **already taken**, with their rationale | binding until superseded |
| **`docs/design-notes/`** (here) | questions **still open**, with evidence and options | explicitly *not* decided |

A note graduates out of here: once its question is answered it becomes an ADR (if it changes a
decision) and its outcome lands in the relevant `docs/` file. The note then gets a `Status:
Closed` header pointing at the ADR rather than being deleted — the reasoning behind a rejected
option is worth keeping.

## Reading rules

- **Nothing here is authoritative.** A number in a design note describes an experiment, usually a
  sensitivity run outside the normal pipeline. Do not quote one in the paper, `MODEL.md` or
  `claims.md` without re-deriving it from a Run-Group artifact.
- **Every note states its provenance and its caveats** — which Run-Group, which scenario, whether
  coefficients were refitted or held fixed, what resolution the data was at. Read those before the
  conclusion.
- Notes are numbered for ordering only; there is no dependency between them.

## Index

| # | Question | Status |
|---|---|---|
| [0001](0001-actor-power-share-vs-level.md) | Should the actor-power indices be shares or per-capita levels? | **Closed** (ADR 0044, ADR 0045) — `v5` deploys `bothIncAP`: clean-energy build-out, fossil dependence **and** per capita; 76% of bootstrap winners |
| [0002](0002-institutional-channel-set-for-coupling.md) | Is the selected institutional channel set the right one for the coupling? | **Open** — on `v5` state capability is settled (100% of pool and winners); rule of law is in 92% of the pool but not in the selected set, and no accountability channel is identified |
| [0003](0003-lambda-in-or-out.md) | Does λ belong in the paper at all? | **Open** — two draft abstracts (with / without), the 6 claims dropped and the 15 weakened, and the asymmetry: λ = 0 is conservative for the cost headline and generous for the split |
| [0004](0004-v6-formulation-tests.md) | What could a v6 change — clamps, smoothing, tier years, SSPs? | **Closed** (2026-10-13; decided in ADR 0049, 0052, 0053) — offline tests on `v5`: the clean-energy clamp is harmless at 2035 but shapes everything after; annual data leave the frontier intact but raise λ 1.7–4×; the λ projection alone moves the 2035 ordering (Spearman 0.52 vs a frozen gap) |
| [0005](0005-v6-implementation-plan.md) | How to build v6 — formulation, data, coupling, run tooling, paper? | **Open** — Phases 0–5 done, Phase 6 in progress; §0a (2026-10-12) lists what is still to do, dropped and deferred; §7b: the `v6` paper reports `v6` only |
| [0007](0007-edge-of-data-interactions.md) | Where does a driver act against the frontier's logic because the interaction terms are evaluated far from the sample, and how should `v7` handle it? | **Open** (evaluation for `v7`) — `v6` baseline: China's buildings & transport rank and the mid-century rise of its strength are edge effects (cap test: China $u$ 1 → 0); regions and drivers to watch listed; options and an acceptance protocol (`analysis/checks/edgeOfData.R`); options tried on `v6` (`edgeOptions.R`): only the caps, no interactions and the regime split pass; exporter and autocracy controls do not |
| [0008](0008-institution-gap-closure.md) | How should the institutions without an SSP projection be projected in SSP2, simply and on the SSP2 principles? | **Decided 2026-10-27** — gap closure: every country closes 0.6% of its distance to the best observed value each year from its 2023 panel value; the rate from Andrijevic et al.'s SSP2 convergence (0.54–0.62%) and V-Dem history (0.2–1.1%), PoliClim a check; government effectiveness under the rule, Andrijevic et al.'s published path the sensitivity (`gapclosureAndrijevic`) |
| [0009](0009-v8-candidates.md) | Why do some countries have extreme efficiency ratios, can fossil rents enter the frontier and be linked to REMIND, and what else should `v8` represent? | **Open** (tests done 2026-10-27) — no rents form passes the gates and helps (controls neither: continuous fails γ, positive sign; the exporter dummy is null in power & industry); persistent slack not identified, the gap spread narrowed 1–5% a year (brackets κ); the donor rule loses to the covered median out of sample. Earlier: Iceland, Indonesia, Saudi Arabia are artefacts of the form (linear fossil term at the low edge; interaction outside the support; unidentified main effect); the saturating twin does not fix Iceland; fossil rents improve buildings & transport strongly but raise the power & industry ceiling (against the theory, γ at the boundary); REMIND link from the gdx; other candidates ranked, persistence from the data first |
| [0006](0006-v6-paper-frames.md) | Which question does the `v6` paper ask? | **Open** — eight frames, each with its evidence, on one finding: how long the political limit lasts orders every result of both closures (22–189 Gt hold-the-price overshoot; 5–66 Gt relocated). Recommended: today's politics versus tomorrow's, led by "net zero slips unless politics changes" (22 of 26 EU21 hold-the-price runs never peak by 2150) |
| [0010](0010-evaluation-and-next-sweep.md) | How good are the formulation and the coupling on `v8`, what should the next sweep carry, and what would make the work relevant to the literature? | **Open** (2026-11-10) — evaluation, twelve offline tests and seven coupled runs in detail; tested the same day: four to six of the nine interactions carry the fit and the weight off accountability is admissible with a smaller block (§8); the ordering does not rest on γ, the distance below the ceiling erodes at 2–16% a year, the fading and the constant limit are a bracket, the most constrained region sets the scale of θ, the trend 2010 / 0.30 is not better on `v8` (§11) |
| [0011](0011-next-sweep-design.md) | What does the next sweep (`v9`) search, what must be implemented for it, and how is it run? | **Open** (2026-11-10), a design — an interaction-block dimension (four theory-defined levels), the weight scope on state capacity and rule of law, H1–H2 confirmed under the wild bootstrap in the walk; seven decisions for the author (D1–D7) before the ADR; nothing implemented |
| [0012](0012-publication-plan.md) | Which papers, in which order, with which headlines? | **Decided 2026-11-23** (D1–D12; D13–D18 recommended) — two papers: a GMD model paper framing the PFM as a module for any IAM with REMIND as the case study (accessible main text, step-by-step appendices) and a *Nature Climate Change* paper on persistence and expectations, *Mitigation pathways that treat political limits as permanent overstate their emissions cost*; the catalogue of possible papers (B and C parked, D–G in reserve), claims ledger, figures, decisions D1–D12 and the build plan |
