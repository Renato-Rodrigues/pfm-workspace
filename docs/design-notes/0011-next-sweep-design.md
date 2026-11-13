# 0011 — The next sweep (`v9`): what to implement, what it searches, and how it is run

**Status: Open (2026-11-10), a design, nothing implemented.** Design note 0010 evaluated `v8` and tested the candidate
changes offline; this note turns its conclusions into an implementation and a run plan. It changes no code, no
Run-Group and no number. The decisions marked **D** are the author's and are needed before the ADR that declares the
sweep.

**Provenance.** Every number is Run-Group `v8`, from the artifacts named in 0010 §8 and §11
(`interaction-block-test.rds`, `weight-scope-test.rds`, `theory-gate-funnel.rds`, `paper-checks.rds`,
`trend-shape-grid.rds`, `normalisation-check.rds`). Code references are to `models/pfm` as it stands at `v8`.

---

## 1. What the sweep is for

`v8`'s specification stands for the paper (0010 §7, "order of work"). A `v9` sweep is worth its cost for three things
the offline tests established, and only these:

1. **The interaction block is over-parameterised** and the search never tested a smaller one (0010 §8.1): four to six
   of the nine interactions carry the fit.
2. **The weight on the accountability pair is close to a double count** (correlation 0.93 with vertical
   accountability), and leaving it unweighted is admissible once fossil dependence × accountability is not in the block
   (0010 §8.2).
3. **The gate reads the asymptotic *p* while the documents quote the wild bootstrap**; in buildings & transport `v8`
   passes on the first only.

What the sweep does **not** change: the outcome, the panel definition, the frontier's form, the rents slack, the
covered median, the coupling. The trend shape stays as declared: on `v8`'s specification no other shape is better in
both sectors (0010 §11, T10).

---

## 2. The search

### 2.1 A new dimension: the interaction block

Each level is defined by a reading of the theory (ADR 0056), not by its fit on `v8`.

| level | suffix in the name | interactions | reading |
|---|---|---|---|
| `full` | none (as today) | every sectoral-interest term × every institution | `v8`'s block |
| `fossil` | ` ib:fos` | the fossil terms × every institution | the theory states no hypothesis for the clean-energy terms (ADR 0059), so they are not conditioned |
| `instrumental` | ` ib:pc` | fossil interests per person × every institution | institutions condition the instrumental channel; structural power works by anticipation (ADR 0056) |
| `instrumentalState` | ` ib:pcGE` | the three above, and fossil dependence × state capacity | **D1**: tested on `v8` (0010 §8.2: needed for H1 in power & industry under the wild bootstrap); it needs a stated reason, or it is a fitted block and stays a robustness refit outside the search |

Rules:

- A level applies only where it differs from `full`: `fossil` needs a clean-energy term in the interaction set;
  `instrumental` and `instrumentalState` need the per-person fossil term (the forms `bothIncAP`, `splitAPpc`,
  `mixedAP`). A specification gets no duplicate twin.
- The main effects are never dropped.
- H2's Bonferroni level follows the fossil × institution terms **present** (0.05 / 6, / 3, / 4). A smaller block
  faces a less strict level. This is stated with the gate; it is the correct level for the tests made, and it is why the
  block must be declared and not picked.

### 2.2 The weight and its scope

| level | suffix | change against `v8` |
|---|---|---|
| none | — | kept |
| freedom of expression, every pair | ` iw:fexp` | kept |
| freedom of expression, state capacity and rule of law | ` iw:fexp@geRoL` | **new** (author, 2026-11-09) |
| electoral democracy, every pair / state capacity and rule of law | ` iw:poly`, ` iw:poly@geRoL` | kept / new |
| accountability and rule of law (`@accRoL`) | | **D2: dropped.** It weights the pair the weight is nearly identical to. It was a conditional bootstrap winner on `v8` (27%), so dropping it is a disclosed change of the menu |

### 2.3 Everything else

As `v8`: the institution sets with the five accountability options, the four actor-power forms and transforms, the
controls, the two group-effect mappings, the fossil bound at the 5th percentile, the rents slack in buildings &
transport, the declared trend (2010 / 0.20).

**Size.** `v8`: 36,384 specifications. The block multiplies the specifications that have interactions by up to four
(fewer for the forms without a per-person fossil term). Expect 90,000–120,000; with **D1** answered "outside the
search", about a quarter fewer. Fits are cached, so the `full` block's fits with the kept weights are `v8`'s if the
panel is unchanged (§5).

### 2.4 The gates

| gate | `v8` | `v9` | why |
|---|---|---|---|
| admissibility (tier, VIF 10, trend dominance 0.9) | as is | as is | |
| theory gate H1–H2, asymptotic clustered *p* 0.05 | screen of the pool | screen of the pool | cheap; keeps the pool comparable with `v8` |
| **H1–H2 under the wild-cluster bootstrap** | — | **severe flag in the walk** (B = 999, fixed seed) | the inference the documents quote (0010 §2.5). On `v8` it rejects the selected specification in buildings & transport (wild *p* .068 against .008), so it is declared now |
| H3 coherence 0.75, edge-of-data, support share 0.275, ceiling fall 0.90 | as is | as is | |
| γ gate | 0.999 | **D3**: 0.999, or 0.995 | `v8`'s selection turned on 0.999004 against 0.9989. A lower gate removes that knife edge and, on `v8`, every weighted candidate in power & industry (γ 0.9974–0.9989; 0010 §8.2); only an unweighted block stays (0.969). State the value and its reason before the sweep |

**Declared sensitivities**, re-selected from the cached fits as for `v8`: H3 at 0.70 / 0.80; *p* at 0.10; the wild
confirmation off (the `v8` rule); the γ gate at the other value of **D3**.

---

## 3. Implementation (`models/pfm`)

No version change is part of this design (the author bumps versions). Each item names its files and the check that it
leaves `v8` reproducible.

### 3.1 `interactionBlock`

- **One helper** decides which interaction terms a specification has:
  `.pfmInteractionTerms(actorPowerIndex, instQualityDrivers, block = NULL)` in a new `R/pfmInteractionBlock.R`,
  returning the `make.names` terms `<interest>_x_<institution>`. `NULL` or `"full"` returns the cross product, so
  nothing changes for any existing specification.
- **`buildModelFormula()`** (`R/buildModelFormula.R`, the loop at "each actorPowerIndex × each institutional quality
  variable") takes `interactionBlock` and uses the helper. This is the only place the terms enter a fit.
- **`estimatePolicyStringencyModel()`** gains the argument `interactionBlock = NULL`, passed to `buildModelFormula()`
  and stored on the fit. `.pfmSpecArgs()` forwards any spec field the estimator accepts, so the selected-models file,
  the diagnostics steps and the coupling's design pick it up without further change.
- **`preparePanelData()`** keeps building every interaction column (cheap, and the driver guard and the transforms read
  them by name); only the formula selects.
- **Readers of the terms.** These read the interactions from the fitted coefficients' names and need no change:
  `.pfmTheoryScreen()`, `.pfmTheoryCoherence()`, `.pfmEdgeGate()`, `computeMarginalEffectSupport()`,
  `computeDeltaR2Theory()`, `.pfmFrontierEta()`. To check when implementing: `estimateAdoptionModel()`,
  `estimatePolicyRatchetModel()`, `estimatePriceStringencyModel()` call `buildModelFormula()` too (default `NULL`
  keeps them as they are); `computeInfluenceDiagnostics()` and `runPFMInfluence()` build their term lists from the
  fit; the IV rung builds its instruments from the formula's right-hand side.
- **The fit cache.** `computeModelId()` hashes the formula, so a block has its own id. Add the block to `cacheExtra`
  only when set, as the weight and the bound are, so every existing key stays valid.
- **The search axis** (`R/runPFMSweep.R`, before the interaction-weight axis so that every weight covers every block):
  a twin per level of §2.1 where it differs, the suffix in the name, a sentence in the description.
  `scopeDiffers()` then reads the institutions that the block actually interacts.
- **Config** (`config.yml`, `sweep: groups: v9:`): `interactionBlocks: [full, fossil, instrumental, instrumentalState]`.
- **Name parsers** outside the package: `analysis/checks/sweepOverview.R` (the weight and scope regular expressions
  assume `@accRoL`), `analysis/v8/theoryGateFunnel.R` (reads terms, no change), `analysis/coupled/_runKey.R` (run
  titles, no change).

**Acceptance.** (a) With no block set, `v8`'s selected specification refits to the coefficients in `sweep.rds` and
the same cache id. (b) The package's fit of each block equals `interaction-block-test.rds` for that block (the script
filters the formula from outside; the two must agree to 1e-6). (c) A unit test per level on the term list.

### 3.2 The scope `geRoL`

`R/pfmInteractionWeight.R`: append `geRoL = "Government\\.Effectiveness|Rule\\.of\\.Law"` to `.pfmIwScopes`, after
`accRoL`. The scope is stored as its position in that vector, so `accRoL` must stay first or the cached `accRoL` fits
change meaning. `iwSuffix()` and `.pfmIwParse()` need no change. **Acceptance:** the package's fit equals
`weight-scope-test.rds` (`geRoL`), and an `accRoL` fit of `v8` is served from the cache unchanged.

### 3.3 H1–H2 under the wild bootstrap, in the walk

`R/computePolicyStringencySanity.R`, where the walk applies the theory gate (the block that writes the
`theoryCoherence` flag): with `theoryGate$wild = TRUE` (default `FALSE`, so `v8` re-selects identically), refit the
mean regression per sector, run `computeWildClusterBootstrap(B = theoryGate$wildB %||% 999, seed = 42)`, apply H1 and
H2 on `pWild` with the logic of `.pfmTheoryScreen()` (factor the verdict out of it so both use one function), and
write a severe flag `theoryWild` with the failing hypothesis and its *p*. Cost: two bootstraps per walked candidate,
under a minute. **Acceptance:** on `v8`, `wild = FALSE` reproduces the cluster walk; `wild = TRUE` flags the selected
specification in buildings & transport with *p* .068.

### 3.4 The γ gate as a declared setting

`gammaGate` is an argument of the walk with the package default 0.999. If **D3** changes it, set it in the group's
`sweep:` block and record it in `manifest.json`, as the other gates are.

### 3.5 Not in this sweep, kept as candidates

- **A slack whose spread falls as the ceiling rises** (0010 §11, T4): it raises the log-likelihood by 537 / 206 on the
  whole sample (48 / 27 from 2008) and reorders the 2023 ranking in power & industry (rank correlation 0.71–0.76 with
  `v8`'s). A change to the frontier's error structure this large belongs in the robustness battery first
  (`computeFeasibilityFrontier()`, a fifth rung), then in its own decision.
- One state-capacity index in place of government effectiveness and rule of law (0010 §2.2): test on the selected
  specification as the blocks were, before it is a search level.
- Institutions in the power & industry slack; region effects at H12; a peer term for the trend (0010 §7).

---

## 4. Decisions needed before the ADR

| | decision | options | what the tests say |
|---|---|---|---|
| **D1** | Is `instrumentalState` a search level? | in the search, with a stated reason for fossil dependence × state capacity; or a robustness refit only | without that term H1 fails in power & industry under the wild bootstrap under every weight (0010 §8.2) |
| **D2** | Drop the `@accRoL` scope? | drop (disclosed); or keep beside `@geRoL` | it weights the pair nearly identical to the weight; 27% of conditional bootstrap winners on `v8` |
| **D3** | The γ gate | 0.999; 0.995 | at 0.995 no weighted candidate passes in power & industry on `v8` |
| **D4** | Is the wild confirmation a gate, or a reported check? | severe flag (this design); warning only | as a gate it rejects `v8`'s own specification |
| **D5** | The weight when the gates admit both | the rule decides (this design); or the scope `geRoL` declared | with a smaller block the unweighted control passes too, with the best fit and γ 0.969 (0010 §8.2 item 6): the rule may select no weight at all |
| **D6** | New data | CAPMF, V-Dem, WDI editions with 2024 if published; Estonia if its oil shale is mapped | to check; a changed panel means no `v8` fit is reused |
| **D7** | Does the paper move to `v9`? | stay on `v8` and report `v9` as the declared next version; or move | a move re-runs the coupled batch and re-reads every number |

**D5 is the one with consequences beyond the sweep.** ADR 0060 introduced the weight to remove `v6`'s edge effects.
If a smaller block makes the unweighted specification admissible and the rule selects it, the comparability device
leaves the model. That may be the right outcome, but it should be decided knowing it, not discovered in the result.

---

## 5. The run

1. **Decisions D1–D7**, then **an ADR** that declares the menu (§2), the gates (§2.4), the declared sensitivities and
   the tests already seen (0010 §8, §11), in the manner of ADR 0059: what was revised after `v8` was known, and why.
2. **Implement §3** with its acceptance checks, on a branch of `models/pfm`; `devtools::test()`; push (the cluster
   installs from the remote: `PITFALLS.md` §2).
3. **Smoke test** on the workstation: the search restricted to `X-1791`'s family (as `analysis/v8/smokeTestV8.R`),
   every block and weight, the walk on the first candidates. It must reproduce 0010 §8.2's verdicts.
4. **The cache.** If the panel is unchanged, `data/madrat/v9` is `v8`'s (`pfmPrepareCache`, `records/v9`), and the
   `full`-block fits are read from the fit cache. If **D6** brings new data: a new cache, a new panel hash, every fit new.
5. **The sweep** on the cluster: `pfmRun(group = "v9", stage = "sweep", cluster = "slurm")`, after `PITFALLS.md`
   §1–§3 (the mapping installed, the fix pushed, the cache pointed at `v9`).
6. **Read it before anything else is run**: `theoryGateFunnel.R v9` (the funnel by block and weight),
   `sweepOverview.R v9`, `selectionCompare.R v9 v8`, the selection bootstrap. The questions: which block and weight the
   rule selects; whether the selection is `v8`'s family; whether H2 in buildings & transport now holds under the wild
   bootstrap; the γ of the selected frontier.
7. **Diagnostics** (`stage = "diagnostics"`), then `docFacts.R v9`.
8. **Downstream and coupled runs only if D7 says the paper moves**, or as a declared sensitivity: the selected `v9`
   specification coupled under hold the price at θ 0.50 (EU21, H12), against `v8`'s +75.1 / +64.3 Gt. That pair is the
   specification band the paper lacks on `v8` (0010 R7 is its `v8` substitute).

**What would count as a result.** The search selects a smaller block or a narrower weight and the ranking the
coupling reads stays close to `v8`'s (rank correlation of $u$ above 0.9): the paper's model is robust to its most
over-parameterised part, and can say so with a declared search behind it. The search selects something whose ranking
differs: the specification band is wide, and the paper reports it beside θ and κ.
