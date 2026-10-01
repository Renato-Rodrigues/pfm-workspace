# 44. Actor power carries the incumbent share **and** its per-capita level (`bothIncAP`)

Date: 2026-08-25

## Status

Accepted. Deployed in Run-Group `v3` as
`X-2367 noGE|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP`.

Closes `design-notes/0001` (share vs level), whose recommendation this record **overturns**.
Extends ADR 0036 (maximin selection), ADR 0039 (Tournament v2), ADR 0040 (saturating actor power)
and ADR 0043 (ceiling-collapse gate). Supersedes nothing, but **changes the index definition that
ADR 0040's saturating transform is applied to**, so read the two together.

## Context

`Innovator Power` and `Incumbent Power` were weighted **shares** of the energy system
(`pfm/R/actorPowerIndex.R`). `design-notes/0001` argued that share and level are not two
measurements of one construct but two *different* constructs from the political-economy
literature — **structural power** (the economy depends on the sector, so policy is constrained
whether or not anyone lobbies; Lindblom/Block, Unruh's lock-in) is inherently a share, while
**instrumental power** (lobbying, campaign finance, litigation — agency that costs resources;
Stigler/Peltzman, Grossman–Helpman) is inherently a level.

The note concluded that the incumbent index should **switch** from share to per-capita level
(`mixedAP`: innovator share, incumbent per-capita), on two grounds: the interaction the model
relies on is Incumbent × Government Effectiveness, which is the instrumental channel; and a
share-based incumbent index is extrapolated ~5 SD beyond its estimation range at 2100 against ~1 SD
for a level.

That recommendation was put into the sweep as four competing forms rather than adopted directly.
Run-Group `v3` answered it, and **the answer is that the note framed the question wrongly**: the
two channels are complements, not rivals.

**One prerequisite has to be recorded because it invalidates an entire Run-Group.** Run-Group `v2`
reported all 2160 per-capita specifications as non-converged. That was **a name-resolution bug, not
a finding**: `preparePanelData()`'s `known_indices` listed only the share-based names, so the
`|<sector>` suffix was never appended to the `*pc` variants and every such spec failed the
missing-variable check before any fitting. Fixed 2026-08-25 in `preparePanelData.R` and
`runPSMSectorSpeeds.R` (the same hard-coded literal aliased the four-sector outcomes), guarded by
`tests/testthat/test-actorPowerPerCapitaNames.R`, committed as `b835c99`. **`v2`'s per-capita rows
are void and must never be quoted.** `v3` fits all five forms at convergence 1.000, `nFailed 0`.

## Decision

**Deploy `bothIncAP`.** Actor power enters as three terms:

```
Innovator Power        (share)        # structural/feedback channel, unchanged
Incumbent Power        (share)        # structural dependence
Incumbent Power pc     (per capita)   # instrumental capacity
```

(`pfm/R/createChannelConfigs.R`, `BOTHINC`.) The form **nests** both `splitAP` (the previous status
quo) and `mixedAP` (the design note's recommendation), so the comparison is a proper one: if either
nested form were sufficient, the extra parameters would not pay for themselves.

ADR 0040's `satAP` saturating transform continues to apply, to the per-capita term as well.

## Evidence

Three independent cuts, all from `output/v3`. Sources are named per column because they differ.

**1. Full-sample sweep** — `sweep.rds$maximin$PolicyStringency` (4392 candidates) for rank and
count; `sweep.rds$results` (per-sector rows) for tier rate and VIF.

| form | candidates | best rank | in top 50 | Green rate¹ | median maxVIF¹ |
|---|---:|---:|---:|---:|---:|
| `splitAPpc` | 720 | **1** *(sanity-rejected)* | 11 | 0.442 | 18.4 |
| **`bothIncAP`** | 720 | **2 → deployed** | **20** | **0.544** | 18.4 |
| `mixedAP` *(the note's pick)* | 720 | 8 | 11 | 0.487 | 16.8 |
| `splitAP` *(status quo)* | **1488** | **41** | 6 | 0.403 | 15.6 |
| `compAP` | 744 | 44 | 2 | 0.216 | 14.6 |

¹ from `$results`, whose rows are spec×sector; Green rate is the share of sector-rows at Green.

Two things are unambiguous. **Per-capita information is worth having** — every form carrying a
per-capita term beats pure-share `splitAP` on every column, and `splitAP` had **twice as many
candidates as any pc form** (1488) yet its best ranked 41st. **But the share is still doing work** —
`bothIncAP` beats `mixedAP`, which drops it, while paying more parameters.

**2. Resampling** — `selection-bootstrap.rds`, job 1889071, `bootstrapTopK = 60`, 200 block
resamples over 36 region blocks, 188 decided (12 leave the ceiling gate empty).

🔴 **This is a top-K bootstrap: raw win shares are confounded by how many of the 60 pool slots a
form holds.** Wins are therefore compared against those expected if wins were proportional to slots
(two-sided binomial). That null treats candidates as exchangeable, which they are not — slot count
is itself an output of the full-sample ranking — so it is a **benchmark that removes the
composition artifact, not a formal test**.

| form | slots | wins | expected | obs/exp | *p* |
|---|---:|---:|---:|---:|---:|
| **`bothIncAP`** | 23 | 93 | 72.1 | **1.29** | **0.002** |
| `splitAPpc` | 13 | 36 | 40.7 | 0.88 | 0.427 |
| `mixedAP` | 16 | 43 | 50.1 | 0.86 | 0.250 |
| **`splitAP`** | 6 | 8 | 18.8 | **0.43** | **0.007** |
| `compAP` | 2 | 8 | 6.3 | 1.28 | 0.416 |

χ² = 14.33, df 4, *p* = 0.0063. **Exactly the two forms this ADR is about separate from the field**,
in opposite directions. `splitAPpc` and `mixedAP` are indistinguishable from proportional.

The deployed spec's own channel set `noGE|RoL|VerAcc` is the most favoured set in the pool (7 slots,
46 wins, 2.10× expected, *p* < 0.0001), and the set that leads on raw share alone,
`WGIge|RoL|VerAcc`, is significantly *dis*favoured (0.53×) — it held 27 of 60 slots.

**3. Interaction with the ceiling gate** (ADR 0043). The rank-1 spec `X-1746` (`splitAPpc`) is
admissible but was rejected by the projection-sanity walk under `ceilingCollapse` — median frontier
ceiling falling to 90% of its 2025 value by 2100, 78% of covered countries falling — plus three
other severe flags. `X-2367` passes with **0 severe flags and a rising ceiling** (Bulk 1.11,
Diffuse 1.25). The gate cost **0.8% of mean ΔR² and rank 1 → 2**, against `v1`'s ~8% and rank
1 → 11.

## Consequences

**The theory changes, not just the fit.** Structural dependence and instrumental capacity are
measuring different things about incumbent power, and the data wants both. `design-notes/0001`'s
error was treating them as rival operationalisations of one construct. **`docs/MODEL.md` §2 still
describes actor power as a share and is now wrong** — it is the one document this ADR obliges
someone to rewrite.

**Report the incumbent block, never its two coefficients separately.** `bothIncAP` runs at median
`maxVIF` **18.4** against `splitAP`'s 15.6. Entering a share and its level is collinear by
construction. The block is identified; the individual coefficients are not. **A claim of the form
"the per-capita channel contributes X and the share Y" is not supported at VIF 18.**

**"`splitAP` never wins" is not a finding and must not be written.** An earlier `topK = 40` run
(job 1886490, since overwritten in place) reported `splitAP` at 0 of 200 resamples. `splitAP`'s
best spec ranks **41** and the pool was the top **40** — it was excluded by one place and could not
have won. Two further claims from that run ("Government Effectiveness robust at 0.772", "the
deployed channel set ranks 4th") were pool-composition artifacts in the same way. The `topK = 60`
run above exists because of that failure. **Any future bootstrap must be quoted with its `topK` and
its slot counts.**

**The ceiling gate remains necessary and this ADR does not weaken it.** The rank-1 spec was the
falling-ceiling one, so without ADR 0043 `v3` would have deployed it. What has changed is the
price: the gate and the per-capita reformulation address the same defect from two directions, and
having both makes the gate nearly free *in fit terms*. It is not free in selection terms — it
empties the candidate pool in 12 of 200 resamples and leaves a median of 9 of 60 standing.

**The specification is selected; the channel set is not, and no individual spec is stable.** The
best single specification wins 0.085 of resamples and the deployed one 0.045 (median rank 5 of 60).
The **accountability channel remains unidentified** — `VerAcc`, `noAcc` and `DiagAcc` all sit within
±25% of proportional. This is consistent with `CLAUDE.md`'s standing position that the
accountability channel is deliberately not identified, and the paper must report the form as
selected while reporting the channel set as set-identified.

**Selection-honesty exhibits need re-cutting for `v3`.** The `v1` triple — `selection-stability`
(C17), `selection-landscape` (C27), `sharing-cost` (C30) — is quoted together precisely because any
one alone understates fragility. All three are `v1` numbers against a different deployed spec.

**Not established by this ADR** (TODO item 14, open): whether the forms differ on the frontier's own
diagnostics — γ, `driverOutOfSupport`, scenario responsiveness — or only on ΔR²
(`driverOutOfSupport` is not a column in `sweep.rds$results` and must be pulled from the frontier
diagnostics per form); and whether λ moves, since the ECM is fitted on the same drivers and TODO
item 12 depends on the answer.

**What would overturn this.** A frontier-diagnostic result showing `bothIncAP` buys its ΔR² with
worse out-of-support behaviour than `mixedAP` would reopen the note's original argument, which
rested on extrapolation range rather than fit. So would a demonstration that the VIF-18 block makes
the coupled φ unstable across specifications. Neither is tested.

**To restore the previous behaviour**, pin `actorPowerDrivers` to the two share terms; the
`splitAP` form remains in the grid and is not removed by this decision.
