# ADR 0046 — The γ-boundary gate is on, at 0.999

- **Status:** Accepted
- **Date:** 2026-09-15
- **Completes:** [ADR 0043](0043-ceiling-collapse-selection-gate.md), which directed the project to screen γ on any winner but implemented nothing
- **Run-Group:** `v5` (no change to the deployed specification — see Consequences)

## Decision

`runPSMSweep(gammaGate = ...)` defaults to **0.999** instead of `NA`. A specification whose
frontier γ exceeds 0.999 in either sector now raises a **severe** `gammaBoundary` flag and is
rejected by the sanity walk.

The gate itself was implemented on 2026-08-25 and has been switched off ever since. Its own code
comment asked for the switch to be "a deliberate, dated act" — this ADR is that act.

## Context

γ is the share of the composed error attributed to inefficiency rather than noise. As
γ → 1, σ²_v → 0: the *stochastic* frontier degenerates into a deterministic one, the slack term
becomes very nearly the arithmetic residual (`MODEL.md` §3.4), the likelihood sits on the boundary
of its parameter space, and `frontier::sfa` emits its own warning that *"this can cause convergence
problems and can negatively affect the validity and reliability of statistical tests."*

**This has been happening unremarked for two Run-Groups.** ADR 0043 called out `X-0170` at
γ = 1.0000 exactly. `v3`'s deployed `X-2367` came in at **0.99999999 in both sectors** and nothing
flagged it. The 19-specification survey of 2026-09-15 found γ above 0.9999 in **7 of 19
candidates**, including:

| spec | rank | γ Bulk | γ Diffuse | note |
|---|---:|---:|---:|---|
| `X-2010 satAP` | **3** | 0.9999136 | 0.9659918 | the selection bootstrap's **modal** winner (12.2%) |
| `X-1923 lin` | 7 | 0.9999999677 | **0.9999995870** | degenerate in *both* sectors |
| `X-1779 satAP` | 40 | **0.9999999900** | 0.9764841 | **zero** significant terms in Bulk; vcov `"boundary"` |
| `X-1746 lin` | 8 | 0.9999999761 | 0.9721228 | |
| `X-1854 satAP` | 69 | 0.9999472 | 0.9535858 | Diffuse's per-sector optimum |
| `X-1854 lin` | 71 | 0.9999215 | 0.9714790 | |
| `X-1779 lin` | 529 | 0.9999993 | 0.9901040 | |

`X-1779 satAP` is the clearest case of what the gate is for: γ pinned at the boundary, the
covariance matrix flagged `"boundary"`, and **not one significant coefficient in Bulk** — p-values
of 0.5–0.996 on estimates as large as 0.9. Its maximin rank of 40 is computed from a likelihood
evaluated where the likelihood is not valid.

## Why 0.999

**Placed in an observed gap, not chosen to admit or exclude a preferred model.** Across all 38
sector-fits in the survey, sorted:

```
… 0.99534  0.99576  0.99668  0.99711  0.99799  0.99827  0.99840
                    ← gap of 1.5e-03 →
   0.99991  0.99992  0.99995  0.9999993  0.9999996  0.99999997  0.999999976  0.99999999
```

The healthy fits top out at **0.99840** and the degenerate ones begin at **0.99991**, with nothing
in between. 0.999 sits **0.0006 above the highest healthy value and 0.0009 below the lowest
degenerate one** — near the centre of the gap. Any threshold in (0.99840, 0.99991) gates
identically.

This is deliberately unlike ADR 0045's `supportShareGate = 0.275`, which cuts through a cluster
0.0016 above the highest value it admits. Where a gap exists, the threshold goes in the gap.

## Consequences

- ✅ **The `v5` deployment does not change.** `X-2079` has γ = **0.9868 / 0.9819**, clearing the
  gate by 0.012 and 0.017. The sanity walk still stops at maximin rank 1, `forced = FALSE`.
  Enabling this gate costs nothing already decided.
- **Seven of nineteen surveyed specifications become inadmissible**, including maximin rank 3 and
  the bootstrap's modal winner. Any future sweep will select differently in their neighbourhood —
  which is the point.
- 🔴 **The selection bootstrap does not apply this gate.** `selection-bootstrap.rds` ranks and wins
  are computed without it, so `X-2010 satAP`'s 12.2% modal share is a share of a pool containing
  specifications this gate now rejects. **Claim C17's figures predate the gate** and should be
  re-derived on the next sweep, or quoted with that caveat.
- **γ is reported whether or not the gate fires** (`computePolicyStringencySanity.R:503`), so
  turning it on was never the first time the number was visible — the values above were all
  readable before this change, and nobody read them.
- **Cost: zero additional frontier fits.** The screen reads the γ already returned by the ceiling
  trajectory computed for `ceilingFallGate` (`computePolicyStringencySanity.R:724`).

## Alternatives rejected

- **Leave it off and screen by hand.** This is what ADR 0043 asked for and it did not happen for
  two Run-Groups. A gate nobody runs is not a gate.
- **A tighter threshold (0.99, 0.995).** Would reject `X-1791 lin` (0.99668), `X-1791 satAP`
  (0.99799), `X-1794 satAP` (0.99827) and `X-1908 lin` (0.99840) — specifications whose variance
  decomposition is high but not degenerate, and which the survey uses as sensitivity arms. It would
  also mean choosing a threshold inside a dense region rather than a gap.
- **A hard exclusion at the sweep-scoring stage** rather than a severe sanity flag. Rejected: γ
  comes from the *frontier* fit, and the sweep's scoring stage fits with `estimator = "satP"`,
  which has no γ. Screening at the sanity walk is the earliest point the number exists.

## Files

`pfm/R/runPSMSweep.R` (default and roxygen), `pfm/R/computePolicyStringencySanity.R` (default and
the comment that asked for this decision). Evidence:
`../_archive/_wip/2026-10-01/docs/reference/spec-selection-2026-09-15/` — `data/survey.json` carries every γ, and
`scripts/specsurvey.R` reproduces them.
