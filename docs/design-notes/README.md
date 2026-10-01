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
| [0001](0001-actor-power-share-vs-level.md) | Should the actor-power indices be shares or per-capita levels? | **Closed** (ADR 0044, ADR 0045) — `v5` deploys `bothIncAP`: innovator share, incumbent share **and** per capita; 76% of bootstrap winners |
| [0002](0002-institutional-channel-set-for-coupling.md) | Is the deployed institutional channel set the right one for the coupling? | **Open** — on `v5` state capability is settled (100% of pool and winners); rule of law is in 92% of the pool but not in the deployed set, and no accountability channel is identified |
| [0003](0003-lambda-in-or-out.md) | Does λ belong in the paper at all? | **Open** — two draft abstracts (with / without), the 6 claims dropped and the 15 weakened, and the asymmetry: λ = 0 is conservative for the cost headline and generous for the split |
| [0004](0004-v6-formulation-tests.md) | What could a v6 change — clamps, smoothing, tier years, SSPs? | **Open** — offline tests on `v5`: the innovator clamp is harmless at 2035 but shapes everything after; annual data leave the frontier intact but raise λ 1.7–4×; the λ projection alone moves the 2035 ordering (Spearman 0.52 vs a frozen gap) |
| [0005](0005-v6-implementation-plan.md) | How to build v6 — formulation, data, coupling, run tooling, paper? | **Open** — plan agreed 2026-10-01: rename first; no hold year (hold 2060 as sensitivity); new paper workspace replacing `papers/pfm-paper-v5`; 22 decisions, a master checklist, phases 0–6 |
