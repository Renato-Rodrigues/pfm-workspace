# 0010 — Evaluation of the model and the coupling, and what the next sweep should carry

**Status: Open (2026-11-10); tests run the same day in §8 and §11, which revise parts of §1–§7 (table in §11.7); the
sweep's design is design note 0011.** The author asked for an evaluation of the current formulation and coupling: what to
include in the next sweep, what would improve the quality of the PFM and of the coupling, and which changes, tests or
justifications would make the work relevant to the literature. Nothing here changes `v8`, its coupled batch or the paper.

**Provenance.** Run-Group `v8` (selected `X-1791 … satAP iw:fexp fos5`), read from `MODEL.md`, `SCENARIOS.md`,
`COUPLING.md`, the paper's `claims.md` and `paper-outline-v8.md`, and design notes 0007–0009. Three things were
computed for this note, all offline from existing artifacts, none through the pipeline:

- the theory gate by search dimension (§2.1), from `output/pfm/v8/theory-gate-funnel.rds` (0009 §23.2);
- how long the ordering below the ceiling lasted in the sample (§3.2), from `output/pfm/v8/frontier.rds` scores;
- whether the distance below the ceiling moved with the ceiling (§3.1), from the same scores.

The second and third are **indicative**: one-off calculations on the fitted scores, without standard errors. Each is
listed in §5 as a test to run properly. Re-derive any number from the artifact before quoting it. Literature named in §6
is from memory and must be checked against the sources before it is cited.

---

## 1. The verdict in short

**What is sound.** The design choices that protect the result are the right ones and should be kept:

- the constraint is a **ceiling**, read as an ordering, not a forecast of policy levels (the model loses to
  persistence as a forecast, and says so);
- the coupling is **relative**: it caps the increment over current policy, so no index-to-price exchange rate exists;
- severity θ and persistence κ are **declared and swept**, not passed off as estimates;
- inference uses the wild-cluster bootstrap and leave-one-country-out, and the claims ledger caps every estimation
  claim at "provisional".

**What is weak, in order of what it does to the paper.**

1. **The size of the headline is declared, and the paper's novel mechanism rests on a scale choice.** The extra CO₂
   is close to θ × the mean ranking × the exposure to the current-policy price. The endogenous fading of the limit, the
   part no earlier study has, comes entirely from holding the distance below the ceiling on the logit scale (§3.1). It is
   defensible, and the sample gives indicative support, but the paper does not yet show that.
2. **The ordering the coupling fixes for 77 years did not last 15 years in the sample** (§3.2). This is evidence on
   the assumption the result rests on most, and it is not yet in the paper.
3. **The frontier's split between noise and slack is weakly identified** (power & industry γ 0.9989, 0.0001 inside the
   gate; slack ranks not robust on any alternative error structure). The band the paper reports on the coefficients is
   the ML one, which understates clustering by a factor of about two.
4. **Structural power in power & industry appears in one corner of the search only** (§2.1): with both fossil terms
   and the coarse three-group effects. That is a finding to report, not hide.
5. **The institution block is over-parameterised** (§2.2): nine weighted interactions on three collinear institutions.
   It is the source of the unidentified power & industry institution effects, which set the late-century strength.
6. **External validity**: 48 countries, without the United States and Brazil; five regions rest on one observed
   country each; 200 countries take the median.
7. **The position against the nearest published work is not written.** The paper's `literature/index.md` novelty
   sentence and `docs/relevance.md` are still templates.

None of these needs a new sweep to diagnose. Most of the gain for the paper is in §5's offline tests and §4's coupled
runs, not in a new specification. **The next sweep should be small, declared in advance, and run after the tests.**

---

## 2. The formulation

### 2.1 Where the theory gate's passes come from

The 5,786 admissible specifications of `v8`, by search dimension (share passing each requirement at *p* 0.05; the last
column counts the 80):

| dimension | level | admissible | H1 P&I | H2 P&I | H1 B&T | H2 B&T | pass all |
|---|---|---:|---:|---:|---:|---:|---:|
| fossil form | **share and per person** (`bothIncAP`) | 1,791 | 16% | 58% | 28% | 73% | **80** |
| | per person, with clean energy as a share (`mixedAP`) | 1,009 | 0% | 62% | 1% | 44% | 0 |
| | shares only (`splitAP`) | 2,027 | 0% | 6% | 35% | 49% | 0 |
| | per person only (`splitAPpc`) | 959 | 0% | 43% | 23% | 29% | 0 |
| group effects | EU / OECD / other (`OECDp`) | 2,894 | 10% | 40% | 43% | 60% | **80** |
| | H12 regions | 2,892 | 0% | 37% | 7% | 45% | 0 |
| accountability | vertical | 1,020 | 7% | 56% | 20% | 68% | 46 |
| | horizontal / overall / diagonal / none | 4,744 | 2–7% | 29–47% | 20–47% | 38–64% | 16 / 12 / 6 / 0 |
| weight | freedom of expression, all pairs | 1,311 | 6% | 35% | 31% | 50% | 26 |
| | none | 1,168 | 3% | 45% | 31% | 65% | 15 |

The power & industry fossil term by form: with both fossil terms it is negative in 77% of specifications and
significantly so in 16%; with the per-person term alone it is **significantly positive** in 62–82%; with the share alone
it is never significantly negative.

**Reading.**

- **H1 in power & industry holds only when dependence and scale are separated.** A fossil-intensive economy that is
  also large per person regulates more (the exposure confound, `MODEL.md` §8.3). Only with the per-person term in the
  model does the share carry the constraint. This is a substantive result about how structural power has to be measured,
  and it is the honest content of the "80 of 5,786".
- **It never holds with H12 region effects.** In power & industry the fossil effect is identified between the three
  broad groups and within them, not within the twelve regions. The two-way fixed-effects estimator of the agreement
  battery keeps it negative and significant on the selected design (`MODEL.md` §2.5.1); that result should be promoted
  from a robustness row to the paper's answer to "is this only rich against poor?".
- **More than half of the search dies on collinearity**: 19,180 of 36,384 specifications fail the VIF gate. The menu
  itself is collinear (§2.2).

### 2.2 The institution block

Three institutions, each interacted with three sectoral-interest terms and weighted: nine interactions. The
correlations on the estimation sample: government effectiveness with rule of law 0.76; the weight with vertical
accountability 0.93 and with rule of law 0.87 (0009 §23.1). Consequences already on record:

- only 5 of 19 power & industry terms keep their sign across the seven estimators;
- no power & industry institution main effect is identified, and the frontier and the mean regression disagree on
  their signs;
- the pair fossil pc × state capacity (−0.81) and × rule of law (+1.18) largely cancel; only the joint effect is stable;
- read jointly, better institutions **lower** the power & industry ceiling, and under gap closure this raises the
  strength after 2050 (0.63 → 0.73). Holding institutions adds 10.3 Gt. The late-century path of the central result runs
  through terms the model does not identify.

The three clean-energy × institution interactions carry no hypothesis, and the clean-energy terms are not identified
(claim C9). They cost three parameters and add to the Bonferroni divisor of nothing, but they add to the collinearity.

**This is the largest gain available in the formulation**: fewer, less correlated moderators. Options, from least to
most change:

1. **Drop the clean-energy × institution interactions** (9 → 6 interactions). No hypothesis is lost. *(Tested in §8:
   the data use two of them, and it is the fossil-dependence interactions that add nothing. §8.4 replaces this list.)*
2. **One state-capacity index** (the first principal component of government effectiveness and rule of law;
   `computeVDemStateCapacityPC()` exists) in place of the two, with accountability kept separate (6 → 4 fossil
   interactions). Removes the offsetting pair at its source (0009 §19).
3. **Interactions on one fossil term only** (the share, which carries H1), the per-person term as a main effect.

With option 2 the weight question of 0009 §23.1 simplifies: the weight conditions the state-capacity pair and
accountability stays unweighted. Whether the edge-of-data failure of the `geRoL` scope survives the smaller block is
then an empirical question the sweep answers.

### 2.3 The frontier

- **γ.** Power & industry 0.9989 against a gate of 0.999. Almost all residual variation is read as slack, the split is
  weakly identified, and the selection of `satAP` over `satInn` was decided by a γ of 0.999004. A change of panel edition
  could move the selection again.
- **Inference.** The frontier has no clustered covariance. The coefficient band in the coupling
  (`v8-coupling-band-regional.rds`) draws from the ML covariance; the design effect of clustering on the same design is
  1.94× and 2.46×. The band the paper puts next to θ and κ is therefore too narrow by about that factor.
- **Robustness to the error structure** is poor in power & industry (slack rank correlation 0.38 / 0.42 / 0.03) and
  the delivered share reorders on two of three alternatives (Spearman 0.64 and 0.46 at EU21).

Two additions would turn a disclosed weakness into a measured one, without a sweep (§5, T2 and T3): a **country-block
bootstrap** of the frontier through to the ranking, and a **conditional-quantile frontier** (the 90th percentile of the
response given the drivers), which needs no distributional split between noise and slack and has clustered inference.
If the quantile frontier orders the regions as the stochastic frontier does, the ordering no longer rests on γ.

### 2.4 The trend

The trend carries 67% and 54% of the linear predictor's variance and is declared, not selected. The shape 2010 / 0.30
fits better in both sectors at the same parameter count (+2.4 and +25.9 log-likelihood on `v7`) and gives a power &
industry γ of 0.9956, further inside the gate. On `v6` it barely moved the share (Spearman 0.976). **Adopt it as the
declared shape of the next group**, stated as a revision made after seeing the grid (the disclosure ADR 0059 asks for),
after re-running the grid on the `v8` specification. Do not make the trend a search dimension: the γ gate, the
trend-dominance gate and the likelihood disagree along it.

### 2.5 The selection

- **The gate reads the asymptotic clustered *p*; the documents quote the wild bootstrap.** In buildings & transport H2
  passes on the first and not on the second. The next sweep should keep the asymptotic screen (it is cheap) and confirm
  H1–H2 under the wild bootstrap in the sanity walk, as a severe flag. On `v8` this would have rejected the selected
  specification in buildings & transport, so it must be declared before the sweep, not after.
- **Post-selection.** 80 of 5,786, a rule revised after `v6`, 1% raw selection frequency. The paper says so. What it
  lacks is a measure of how much the selection inflates the evidence: a split-sample replication (§5, T1) gives one.
- **Declare the menu and the gates in an ADR before the sweep runs**, with the tests of §5 done first. A smaller menu
  chosen after the dimension table of §2.1 is itself a selection; either keep the forms that never pass (they are the
  evidence for §2.1's reading) or state that they were dropped because of it.

### 2.6 Data and coverage

- 48 countries: the OECD and a few G20 members. **The United States and Brazil are not in the panel.** REF, CHA, IND,
  SSA and NES each rest on one observed country; MEA on Saudi Arabia for 91% of its observed final energy.
- From `v8` every uncovered country takes the covered median. That is the best predictor out of sample, but it also
  means the regions with the least data are, by construction, the least differentiated. The paper should state this
  direction: where the data are poorest the model says least, and that is not evidence that the constraint is weak there.
- Check before the next sweep whether a newer CAPMF edition adds countries or 2024. Coverage, not the specification,
  is the binding constraint on external validity.

---

## 3. The coupling

### 3.1 The fading of the limit is a scale choice, and it can be tested

The strength is $k(t) = g(t)/g(t_0)$ with $g = 1 - S/S^{*}$, $S = M\,\operatorname{logit}^{-1}(\eta - q)$ and $q$ held.
With $q$ fixed, $E = \operatorname{logit}^{-1}(\eta - q)/\operatorname{logit}^{-1}(\eta)$ moves **only** because the
logistic curve flattens towards the index maximum $M = 10$: as a ceiling rises, the same logit distance is a smaller
proportional distance. ADR 0049 says this in one line ("every movement of $k$ comes from this choice"). Its weight in
the result: the constant limit (hold $E$) gives +123.8 Gt, the fading limit +75.1. **The 39% that the endogenous
feedback removes is the difference between two conventions for what is held.**

Why holding $q$ is the defensible one: the estimated frontier assumes the slack is independent of the drivers **on
the logit scale**. Holding $q$ is consistent with the model that was estimated; holding $E$ is not. That argument is
not in the Methods and should be.

It can also be checked on the sample. Within countries, as the ceiling rose (indicative, `frontier.rds` scores):

| | power & industry | buildings & transport |
|---|---:|---:|
| slope of $E$ on the ceiling ($\eta$), within country | +0.092 | +0.099 |
| what holding $q$ implies (mean $dE/d\eta$) | +0.074 | +0.052 |
| what holding $E$ implies | 0 | 0 |
| slope of $q$ on $\eta$, within country | −0.37 | −0.17 |

Countries moved towards their ceiling as it rose, at least as fast as holding $q$ implies: history sides with the
fading limit against the constant one. **Caveat:** $q = \eta - y$ contains $\eta$, so an error in the fitted ceiling
produces a negative slope by construction, and the trend dominates the within-country movement of $\eta$. The clean
version is a frontier whose slack spread depends on the ceiling's own movement (§5, T4), which the heteroscedastic
slack of `v8` can estimate.

Two further dependencies of the same mechanism:

- **The index maximum.** $M = 10$ is CAPMF's scale maximum; the highest observed value is 6.9 (power & industry) and
  7.2 (buildings & transport), the highest fitted ceiling 9.1 and 7.4. The curvature that makes the limit fade depends
  on where $M$ sits. A sensitivity of $k(t)$ to $M$ has not been run (§5, T7).
- **Support.** By 2050 the clean-energy term is above the observed range for 89% of countries and fossil dependence
  below it for 79% (power & industry). The fade to 2050 is real movement inside the form; after 2050 the sectoral
  interests are at rest and the form decides (claim C17). The paper already says this.

### 3.2 The ranking is fixed for 77 years; in the sample it did not last 15

Rank correlation of each country's share of its ceiling used ($E$) with its 2023 value (indicative, `frontier.rds`):

| years before 2023 | 5 (2018) | 10 (2013) | 15 (2008) | 20 (2003) |
|---|---:|---:|---:|---:|
| power & industry | 0.92 | 0.72 | 0.32 | 0.11 |
| buildings & transport | 0.69 | 0.43 | 0.30 | 0.21 |

The spread of the gaps narrowed over the same period (the reference for κ, `MODEL.md` §5.2a: 0.7% and 5.7% a year).
The two say different things:

- **How much** differentiation there is erodes slowly in power & industry and fast in buildings & transport (κ).
- **Who** is at the bottom changes much faster than either rate suggests: after 15 years the ordering has little to do
  with today's in both sectors.

The coupling's third discipline is "the ranking is fixed at the anchor year". The sample says a ranking read in 2008
would have been a poor guide to 2023. **Caveats:** the five-year moving average inflates the short lags; the early
years had low stringency everywhere, so early $E$ is noisy; 48 countries. Properly estimated (§5, T5), this is the
evidence the paper's spine needs: the claim "the result rests mostly on how long today's politics persists" would then
come with a measured answer to "and how long has it persisted?". It also argues for showing the permuted-ordering run
(`pfmPhiOrdering`) next to the persistence ladder: it separates what the total owes to **who** is constrained from
what it owes to **how much**.

### 3.3 The normalisation

$u$ is a min–max over regions, so the most constrained region sets the scale for all the others. At both resolutions
that region is REF, which is Russia for 100% of its observed final energy, with an $E$ of 0.33 that "follows from its
drivers". One country's residual in one year (the mean of 2021–2023) therefore scales every region's share. Two cheap
alternatives to compare offline (§5, T8): a rank-based $u$, and a min–max that excludes the extreme region. The
`v8` regions already compress towards the median, so the choice matters more than it did on `v7`.

### 3.4 What is solid, and small things

- The anchor pinned from the θ = 0 run, the interface gate, the convergence audit and the check that the share reaches
  the solver are in good order. The no-politics reference differs from the uncoupled one by a uniform price shift of at
  most 0.85%, disclosed.
- **The reference price is the hidden driver** (`SCENARIOS.md` §6.1). The United States' current-policy price is
  negative from 2030 by REMIND's input. A run with that reference floored at zero would show whether any regional
  result depends on it.
- **The two resolutions differ by 14%** on the headline. Report it as a resolution uncertainty of the same kind as
  the others.
- **GDP rises when abatement falls**, because REMIND has no damages. Keep the rule already in force: never without the
  CO₂ in the same sentence.

### 3.5 The size of the effect

+75 Gt CO₂ on a 1000 Gt pathway is, at a transient response of about 0.45 °C per 1000 Gt CO₂, of the order of
**0.03 °C** by 2100. A referee who knows Bertram et al. (2024), where institutional constraints cut the likelihood of
holding 1.6 °C from about 50% to 5–45%, will ask why this result is so much smaller. The answer has three parts, and
the paper needs all three:

1. **The size is declared.** The cap acts on the increment over current policy, and the most constrained region still
   carries 1 − θ of it. No value of θ in the sweep can produce a large effect; the size is not a finding.
2. **The findings are structural**: which assumptions the cost depends on (persistence more than severity;
   expectations as much as severity), and that an endogenous limit loosens as the transition proceeds.
3. **Under hold the budget** the effect is on prices and on who abates (a sixth on the 2050 price, about 20 Gt CO₂eq
   moved), which is the comparison closest to a temperature target held.

A run that reproduces an exogenous, governance-indexed absolute cap in the same REMIND (§4, R3) would make the contrast
with the earlier literature quantitative, and it is the single most useful run for placing the paper.

---

## 4. Coupled runs worth their cost

Ordered by what they add to the paper. None needs a new sweep.

| | run | what it settles |
|---|---|---|
| R1 | the **emissions band** at the edges of the coefficient band (two hold-the-price runs), built from the country-block bootstrap of T2 rather than the ML draws | the paper's third band, next to θ and κ; already open |
| R2 | the **coverage sensitivities** on `v8` (uncovered at the lower quartile; nearest donors) | claim C23 is `pending` and the `v6` band (+110 to +155 Gt) is the only one on record |
| R3 | an **exogenous absolute cap** indexed to governance, in the manner of the earlier literature, same REMIND, same budget | the contrast with Bertram et al. (2024); what endogeneity and the relative form each change |
| R4 | the **shrinking future** at five-year steps and at θ 0.325 / 0.675 | whether "expectations halve the overshoot" survives the step length; claim C25 is `pending` |
| R5 | the **permuted ordering** next to the persistence ladder | separates who from how much (§3.2) |
| R6 | the **US reference floored at zero** | §3.4 |
| R7 | the *p* 0.10 specification coupled (EU21, H12) | a specification band on `v8`; the only coupled one is from `v6` |

---

## 5. Tests to run before the sweep (offline)

Each is cheap against a sweep and each either settles a design choice of the sweep or gives the paper evidence it lacks.

| | test | how | what it decides |
|---|---|---|---|
| **T1** | **Split-sample replication of the theory gate** | split the 48 countries in two at random, many times; screen H1–H2 on one half over the admissible pool (the mean regression is a least-squares fit, so 5,786 fits per split are fast); count how often a specification passing on one half passes on the other, against the base rate | a number for how much the selection inflates H1–H2; the strongest answer to "you searched for significance" |
| **T2** | **Country-block bootstrap of the frontier** | resample countries, refit both frontiers, rebuild the anchor and $u$; 200 resamples | an honest band on the ranking (replaces the ML draws, which understate by about 2×); feeds R1 |
| **T3** | **Conditional-quantile frontier** | the 0.90 quantile of the response on the selected design, cluster bootstrap; compare regional $E$ and $u$ with the stochastic frontier | whether the ordering depends on γ |
| **T4** | **Does the slack depend on the ceiling?** | the heteroscedastic frontier with the slack spread on the trend, or on the fitted ceiling from a first pass | holding $q$ against holding $E$ (§3.1): the justification of the fading limit |
| **T5** | **Persistence of the ordering and of the distance** | within-country autoregression of $q$ and rank correlations at 5, 10, 15 years, on annual and smoothed data, with a country bootstrap | a measured reference for κ and for the fixed ranking (§3.2) |
| **T6** | **θ from prices** (route 3 of `MODEL.md` §5.3.1) | the OECD effective carbon rates against the ranking $u$: how much lower is the priced share of emissions, or the rate, per unit of $u$? | an empirical range for θ; turns the first declared axis into a bounded one |
| **T7** | **The index maximum** | refit the selected frontier at $M$ = 8 and 12; recompute $k(t)$ on the coupled panel (`couplingMechanism.R`) | how much of the fade is the scale maximum |
| **T8** | **The normalisation** | $u$ by ranks, and min–max without the extreme region; the final-energy-weighted mean of $\theta k u$ as a proxy for the headline | §3.3 |
| **T9** | **The institution block** (§2.2, options 1–3) on the selected specification, with the gates and the walk, as `weightScopeTest.R` did for the weight | which block the sweep should carry, and whether `geRoL` still fails the edge-of-data gate with it |
| **T10** | **The trend grid on `v8`** (`trendShapeGrid.R v8`, `trendShapePhi.R`) | confirms 2010 / 0.30 before it is declared |
| **T11** | **Direction of the relation** | long differences: the change in fossil dependence 2001–2012 against the change in stringency 2012–2023, and the reverse | the IV is a null; this at least shows which way the lead runs |
| **T12** | **Outside the sample** | the ceiling and $E$ ordering against an independent measure for countries with and without CAPMF data (effective carbon rates; climate laws; `computePFMCrossDataset()` covers the outcome only) | external validity beyond 48 countries |

T1, T2, T4, T5 and T6 matter most for the paper. T9 and T10 decide the sweep.

---

## 6. What would make it relevant to the literature

**The position, to be checked against the sources.** The nearest works impose feasibility on integrated assessment
pathways from outside: Bertram et al. (2024) cap carbon prices by governance indicators; Brutschin et al. (2021) and
Jewell & Cherp (2020) score pathways after the fact; Gidden et al. (2023) differentiate effort by institutional
capacity; Andrijevic et al. (2020) project governance; Muttitt et al. (2023) bound coal phase-out by historical
precedent inside a model. On the political-economy side, Levi et al. (2020), Dolphin et al. (2020) and Linsenmeier et
al. (2022) explain carbon pricing from institutions and interests, without a model of the pathway. Peng et al. (2021)
and Moore et al. (2022) call for, and sketch, the two-way link. **The paper's place is the estimated, two-way link in a
process-based model**, and its novelty sentence could be:

> *A political ceiling on carbon prices that is estimated from sectoral interests and institutions and moves with the
> energy system it constrains: how much it costs is a declared quantity; that it loosens as the transition proceeds,
> that its cost depends on its persistence more than its severity, and that expectations about it matter as much as
> its severity, are results.*

`literature/index.md` (the novelty delta) and `docs/relevance.md` are unfilled templates. They are the first thing to
write: the tests below are chosen against them.

**Five things a referee will ask, and what answers each.**

| question | what the paper has | what would answer it |
|---|---|---|
| "θ and κ are assumptions, so the result is an assumption." | both declared and swept; a historical reference for κ | T5 and T6: measured ranges for both axes; the result becomes "between X and Y on the evidence", not "whatever is declared" |
| "You searched 36,384 specifications for your hypotheses." | the 80 of 5,786; the caveat | T1; §2.1's table as a specification curve in the SI, with the selected specification marked; the menu and gates declared before the next sweep |
| "The endogenous feedback is extrapolation and a functional form." | claim C17; the constant-limit run | §3.1's argument in the Methods; T4 and T7 |
| "48 rich countries tell you about Russia, China and India?" | coverage shares; the median rule tested out of sample | T12; T2's band by region; the direction stated in §2.6 |
| "How does this compare with the institutional constraints already in the literature?" | a citation | R3, and §3.5's three-part answer |

**What to keep saying.** The paper's willingness to list what it does not identify (the clean-energy terms, the power
& industry institutions, the causal direction, which sector binds, θ) is unusual and is a strength with this
readership. It reads as one only if the things that **are** shown carry measured support. At present the estimation
claims do, and the three coupled findings rest on declared axes with thin empirical anchoring. T4, T5 and T6 are where
the paper gains most.

---

## 7. The next sweep: what to carry

To be declared in an ADR before it runs, after T9 and T10.

**Carry.**

| | change | why | condition |
|---|---|---|---|
| S1 | **An interaction-block dimension**, each level defined by theory (§8.4): all nine; the six fossil terms; the three per-person terms; those three with fossil dependence × state capacity. One state-capacity index stays an option to test | fewer free parameters; on `v8` four to six terms fit as well as nine (§8.1) | declared with its theory before the sweep; narrowing H2 to the per-person term is a disclosed revision (§8.3) |
| S2 | **The weight's scope crossed with the block**: every pair; state capacity and rule of law only (author, 2026-11-09); none | accountability unweighted passes every gate with the six- and four-term blocks and makes the buildings & transport evidence robust; it fails with all nine (§8.2) | the gates decide; the unweighted control is admissible again with a smaller block |
| S3 | ~~The trend 2010 / 0.30, declared~~ **withdrawn**: on `v8`'s specification it is 101 log-likelihood points worse in power & industry (§11.5). The declared shape stays | | |
| S4 | **H1–H2 confirmed under the wild bootstrap in the walk** | the gate then reads the inference the documents quote | declared before the sweep; it would reject `v8`'s specification in buildings & transport |
| S5 | **A γ margin**: a gate at 0.995, or the selection reported at both | a selection decided at 0.999004 is not stable | declare the value with its reason |
| S6 | **Newer data if it exists** (CAPMF, V-Dem with 2024; more countries) and **Estonia** once its oil shale is mapped | coverage is the binding constraint | check editions first |

**Keep as it is.** Both fossil terms with the bound and saturation (100% of bootstrap winners; §2.1 shows why); the
shared specification (0009 §20); the rents in the buildings & transport slack; the covered median; the regional
strength; the three-group effects.

**Do not carry.**

- **The trend as a search dimension** (§2.4).
- **Institutions in the power & industry slack** (0009 §18), for now. It predicts better out of sample, but it would
  let the distance move with projected institutions, a second channel through series that are themselves assumed. Test
  what it does to the ranking first.
- **Sign restrictions or caps on net effects** (0009 §19): a search on the coefficients.
- **A peer or diffusion term for the trend** (0009 §4.6): collinear with time, and a reflection problem.
- **H12 region effects in the shared specification** (0009 §20): §2.1 shows H1 never holds in power & industry with them.

**Order of work.** (1) Write the novelty sentence and the relevance criteria. (2) T1, T2, T4, T5, T6 on `v8`: they
serve the paper whatever the sweep does. (3) R1–R3 on `v8`. (4) T9, T10, then the ADR that declares the sweep. (5) The
sweep, only if the paper is to move off `v8`. **The paper can be written on `v8` with (1)–(3); the sweep improves the
formulation but none of the five referee questions is answered by a new specification.**
---

## 8. Fewer interaction terms, and the weight off accountability: tested (2026-11-10)

`analysis/v8/interactionBlockTest.R v8 [walk]` → `output/pfm/v8/interaction-block-test.rds` (the walk's raw results in
`interaction-block-walk.rds`). The selected specification, everything fixed but the set of interactions and the scope
of the weight. Stage A: every subset of the nine interactions (512) on the mean regression the gate reads, under three
scopes (every pair weighted; state capacity and rule of law weighted, accountability not; no weight). The full block
under the selected weight reproduces `sweep.rds` exactly. Stage B: ten candidate blocks through the wild bootstrap,
leave-one-country-out and the sanity walk; the full block under the selected weight reproduces the cluster's verdict.
The package and the fit cache are unchanged (a formula filter and the scope are set for the script's session only).
ΔBIC is against the selected specification, summed over the two sectors; negative is better.

### 8.1 Which interactions the data use

BIC cost of dropping one interaction alone from the full block (selected weight; positive: the data want it):

| interaction | power & industry | buildings & transport |
|---|---:|---:|
| fossil per person × state capacity | **+86.7** | −1.2 |
| fossil per person × rule of law | **+102.9** | +5.9 |
| fossil per person × accountability | +13.4 | **+52.9** |
| clean energy × state capacity | **+19.5** | −1.3 |
| clean energy × accountability | −7.0 | +11.6 |
| clean energy × rule of law | −1.5 | −1.9 |
| fossil dependence × state capacity / × rule of law / × accountability | +0.7 / +0.4 / −2.8 | +1.4 / +4.3 / +3.7 |

- **The contingency sits on the per-person term**, the proxy for the resources behind instrumental power (ADR 0056).
  The three interactions of fossil dependence, the structural-power proxy, add next to nothing.
- **This corrects §2.2's first option.** Dropping the clean-energy interactions as a block is not what the data
  support: two of them matter, one per sector.
- **Six terms fit better than nine** (ΔBIC −13.7): the three per-person terms, fossil dependence × state capacity, and
  clean energy × state capacity and × accountability. Four terms (the per-person three and fossil dependence × state
  capacity) cost 5.6.
- **Across all 512 subsets the fossil-dependence effect is negative in both sectors** (−0.96 to −0.31 in power &
  industry, −0.35 to −0.18 in buildings & transport). H1 holds in buildings & transport in every subset. In power &
  industry it holds in 49%: in 97% of the subsets that keep fossil per person × state capacity and × rule of law, in 33%
  of the others. Without any interaction it fails there (−0.33, not significant).
- 118 of the 512 subsets pass H1–H2 in both sectors under the selected weight, 87 with accountability unweighted, 110
  without a weight.

### 8.2 The candidates through the gates and the walk

"Six" is the three per-person terms, fossil dependence × state capacity, and clean energy × state capacity and ×
accountability; "four" is the three per-person terms and fossil dependence × state capacity.

| weight | block | ΔBIC (P&I / B&T) | severe flags | γ P&I / B&T | H1 P&I: wild *p*, LOO max | H1 B&T: LOO max | H2 B&T: wild *p* (Bonferroni level) |
|---|---|---|---|---|---|---|---|
| every pair (selected) | all nine | 0 | 0 | 0.9989 / 0.918 | <.001, .002 | .044 | .068 (.008) ✗ |
| every pair | six | −13.7 (−8.7 / −5.0) | **1: edge-of-data, B&T** (clean energy against the expectation on 43% of SSA) | 0.9974 / 0.921 | <.001, .002 | .001 | .001 (.0125) ✓, on fossil dependence × state capacity |
| every pair | four | +5.6 (+2.7 / +2.9) | 0 | 0.9979 / 0.927 | <.001, .002 | .001 | .013 (.0125) ✗, narrowly |
| every pair | per-person three | +75.5 | 0 | 0.9923 / 0.929 | **.064**, .049 ✗ | .012 | .104 ✗ |
| **accountability unweighted** | all nine | −82.4 (+11.1 / −93.5) | **1: edge-of-data, B&T** (fossil dependence against the expectation: China 97%, Middle East 74%, Reforming economies 81%) | 0.9982 / 0.925 | .001, .007 | .178 (Russia) | .001 ✓ |
| **accountability unweighted** | six | −77.3 (+26.6 / −104.0) | **0** | 0.9989 / 0.921 | .005, .006 | .009 | <.001 ✓ |
| **accountability unweighted** | four | −26.4 (+36.5 / −63.0) | **0** | 0.9988 / 0.929 | .004, .008 | .005 | <.001 ✓ |
| accountability unweighted | per-person three | +21.0 | 0 | 0.9922 / 0.929 | **.095**, .074 ✗ | .022 | <.001 ✓ |
| no weight | six | −91.2 (+5.1 / −96.3) | 0 | **0.969** / 0.921 | .004, .004 | .003 | <.001 ✓ |
| no weight | per-person three | −7.8 | 0 | 0.9916 / 0.932 | .056, .032 ✗ | .013 | <.001 ✓ |

**What it says.**

1. **The edge-of-data failure of the unweighted accountability (0009 §23.1) came from one term**: fossil dependence ×
   accountability. With that term out of the block (the six, the four), the weight on state capacity and rule of law
   only passes every gate and the walk. The author's formulation of 2026-11-09 is admissible with a smaller block; it is
   not with all nine.
2. **Accountability unweighted, with six or four terms, repairs the two weaknesses of the buildings & transport
   evidence**: H2 holds under the wild bootstrap (fossil per person × accountability, *p* < .001), and H1 survives
   leaving out any country (.005–.009 against .044 for the selected specification and .178 for the unweighted full
   block). The contingency itself still rests on Saudi Arabia (leave-one-out *p* 0.63–0.85): that fragility is in the
   data, not in the block.
3. **It costs fit in power & industry** (+27 to +37 BIC) and buys more in buildings & transport (−63 to −104). In
   power & industry the per-person × accountability term goes to zero (−0.04 to −0.05) once accountability is
   unweighted: the weighted version was carrying an accountability-squared term, the double count the author suspected.
4. **The per-person three alone are not enough**: H1 in power & industry fails under the wild bootstrap under every
   weight. Fossil dependence × state capacity has to stay.
5. **The six under the selected weight fails the edge-of-data gate** (clean energy in SSA). The lowest BIC is not an
   admissible specification: a block chosen on fit alone would have been rejected by the walk.
6. **Without a weight, the six-term block passes everything, with a power & industry γ of 0.969**, far inside the
   gate, and the best fit of the admissible candidates. With fewer interactions the weight is no longer needed to pass
   the edge-of-data gate. This reopens the weight itself (ADR 0060 introduced it to remove `v6`'s edge effects) and is a
   question for the sweep, not a result to act on.
7. **γ stays at the gate** in power & industry with any weight (0.9974–0.9989); only the unweighted block moves it.

### 8.3 May terms be dropped? (author's question, 2026-11-10)

**Not as post-processing.** A block picked from 512 on fit, after the result is known, is a second selection on top of
the first; the gate would then test terms chosen for their significance, over a smaller Bonferroni set. Item 5 above
shows the practical side: the best-fitting block is not admissible.

**What is defensible:**

- **On `v8`: no change to the model.** The subset results go in the SI as robustness: the fossil-dependence sign is
  negative in every one of the 512 subsets in both sectors; its significance in power & industry depends on two
  per-person interactions.
- **For the next sweep: a block defined by theory, declared before the sweep.** ADR 0056 already reads fossil
  dependence as a proxy for structural power, which works by anticipation, and fossil interests per person as the
  resources behind instrumental power, which works through access and lobbying. On the classic reading (Lindblom)
  institutions condition the instrumental channel. ADR 0056 also cites the later view that structural power is itself
  contingent (Hacker & Pierson), and H2 was written to count both terms. Narrowing it is a revision made after seeing
  `v8` and must be disclosed as one (ADR 0059).
- **The clean-energy interactions are all in or all out.** The theory states no hypothesis for them; keeping two of
  three is a choice only the fit makes.
- **The finding is worth more reported than acted on**: *the contingency of fossil interests on institutions shows on
  the size of the interests, not on the dependence of the energy system.*

### 8.4 What the next sweep should offer (replaces S1 and S2 of §7)

An **interaction-block dimension**, each level defined by theory, crossed with the weight's scope:

| block | interactions | reading |
|---|---|---|
| full | all nine | `v8`'s; both fossil terms and clean energy conditioned |
| fossil | six: both fossil terms × three institutions | no hypothesis on clean energy, so no interaction |
| instrumental | three: fossil per person × three institutions | institutions condition the instrumental channel only |
| instrumental + state capacity | four: the three, and fossil dependence × state capacity | as tested here; needs its own justification (the state's capacity to act on a dependent energy system) or it is a fitted block |

| weight scope | reading |
|---|---|
| every pair | `v8`'s |
| state capacity and rule of law (`geRoL`) | the author's decision of 2026-11-09 |
| none | the control; admissible again with a smaller block (item 6) |

Twelve combinations in place of three weights on one block. The gates decide among them as among every other
dimension. The "fossil" block with accountability unweighted keeps fossil dependence × accountability, the term behind
the edge-of-data failure, so it is expected to fail there; that is the gate working, and it should be left to.

**Implementation.** A spec field (`interactionBlock`) read by `buildModelFormula()` and `preparePanelData()`, with the
block in the specification's name and in the fit-cache key; the `geRoL` scope appended to `.pfmIwScopes`. The theory
screen needs no change (it reads the fossil × institution terms present). Not implemented.

---

## 9. The offline tests in detail

Each test names its inputs, the method, what is written, the cost, and the reading that would change a decision. All
on `v8`; none changes the Run-Group. Suggested home: `analysis/v8/`, artifacts in `output/pfm/v8/`.

### T1 — Split-sample replication of the theory gate

- **Question.** How much of H1–H2 is produced by selecting on them?
- **Inputs.** `sweep.rds` (the 5,786 admissible specifications), the training panel.
- **Method.** Prepare each specification's estimation frame once (scaling on the full sample, as in a projection; say
  so). Draw 200 random splits of the 48 countries into two halves of 24. On each half fit the mean regression by least
  squares with country-clustered errors (the routine of `interactionBlockTest.R`), and apply H1 and H2 as the gate does.
- **Reported.** (a) The share of specifications passing on half A that also pass on half B, against the share of all
  specifications passing on B (the base rate), for H1 and H2 per sector. (b) For those passing on A: the ratio of the
  fossil coefficient on B to that on A (the shrinkage, a direct measure of the winner's curse). (c) For the selected
  specification: the share of splits in which the fossil sign holds on both halves, and its coefficient's spread.
- **Cost.** Preparing 5,786 × 2 frames is the slow part (a few hours on the workstation, or one short cluster job);
  the fits are seconds.
- **Reading.** Replication well above the base rate and shrinkage near 1: the caveat becomes a number in the paper's
  favour. Shrinkage of, say, 0.6: every gate-read coefficient is reported with it. With 24 clusters power is low, so
  judge on sign and shrinkage, not on the pass rate alone.
- **Artifact.** `theory-gate-split-sample.rds`.

### T2 — Country-block bootstrap of the frontier, through to the ranking

- **Question.** How uncertain are $u$, $k(t)$ and φ once countries, not rows, are the sampling unit?
- **Inputs.** The training panel, the selected specification, `phi-anchor.rds`, the coupled hold-the-price panel
  (`analysis/v8/couplingBand.R` already rebuilds the anchor from coefficient draws).
- **Method.** 200 resamples of the 48 countries with replacement; refit both frontiers (buildings & transport with the
  rents slack); apply each refit's coefficients to **all** 48 countries' 2023 values to get $q$, then the anchor, $u$ at
  EU21 and H12, and $k(t)$ on the coupled panel, as `couplingBand.R` does for the ML draws. Keep the γ of each refit.
- **Reported.** 5–95% bands of $u$ by region, rank intervals, the 2050 share, $k_{2050}$ and $k_{2100}$; the same from
  the ML draws beside them; the share of resamples with γ ≥ 0.999 in power & industry.
- **Cost.** 400 frontier fits; under an hour if a fit takes a few seconds, a cluster job if not. Non-convergent refits
  are counted and reported, not dropped silently.
- **Reading.** Expect bands about twice the ML ones (design effect 1.94× / 2.46×). The band then stands beside θ and κ
  at its honest width, and its 5th and 95th percentile anchors are the inputs of run R1.
- **Artifact.** `frontier-block-bootstrap.rds`.

### T3 — A conditional-quantile frontier

- **Question.** Does the regional ordering depend on the split between noise and slack (γ)?
- **Method.** Quantile regression of the logit response on the selected design at τ = 0.90 (and 0.80, 0.95), country
  bootstrap; ceiling = the fitted quantile, $E$ = observed over ceiling capped at 1; the anchor and $u$ as usual.
- **Reported.** Rank correlation of regional $E$ and $u$ with the stochastic frontier's, at each τ; the fossil
  coefficients at the quantile with clustered bands.
- **Cost.** Minutes (`quantreg`).
- **Reading.** Rank correlation of 0.8 or more at EU21: the ordering does not rest on γ, and the γ margin becomes a
  disclosure about levels only. Lower: the quantile frontier joins the four error structures in the rank intervals.
- **Artifact.** `frontier-quantile.rds`.

### T4 — Does the distance below the ceiling depend on the ceiling?

- **Question.** Hold the logit distance $q$ (the fading limit) or the ratio $E$ (the constant limit)? This is the
  choice the feedback rests on (§3.1).
- **Method.** The heteroscedastic frontier of `v8` (`slackDrivers`) with the slack's spread depending on the fitted
  ceiling $\hat\eta$ from the homoscedastic fit, both sectors; country bootstrap for the generated regressor. Holding
  $q$ predicts a coefficient of zero. Holding $E$ predicts a positive one, whose size is computed numerically from the
  sample (the spread of $q$ that keeps $E$ constant as $\eta$ rises).
- **Second, model-free reading.** Within country, the slope of $E$ on $\eta$ against the two predictions (§3.1's
  table), on annual data and with $\eta$ lagged five years so that the same fitted value is not on both sides.
- **Cost.** Minutes to an hour.
- **Reading.** A coefficient near zero supports the fading limit as the central case and goes into the Methods. A
  coefficient near the hold-$E$ value makes the constant limit (+123.8 Gt at EU21) the central case: a change of the
  headline, the author's decision.
- **Artifact.** `slack-vs-ceiling.rds`.

### T5 — How long the ordering and the distance last

- **Question.** What does the sample say about persistence, the axis the result depends on most?
- **Method.** On `frontier.rds` scores, from 2008 (policy near zero before): (a) cross-section regressions of
  $q_{c,t+h}$ on $q_{c,t}$ at $h$ = 5, 10, 15 years (non-overlapping with the five-year average), giving a persistence
  per year $\rho_h^{1/h}$; (b) rank correlations of $E$ at the same horizons; (c) the narrowing of the spread, as in
  `persistentSlack.R`; each with a country bootstrap; repeated on regional aggregates (EU21) and on the annual panel.
- **Caveat to carry.** Noise in $q$ lowers the measured persistence; in buildings & transport (γ 0.92) correct with the
  expected slack; in power & industry the correction is negligible.
- **Reported.** An erosion rate per sector with a band, set against κ = 0, 0.02, 0.027, 0.05; and the horizon at which
  the ordering's rank correlation falls below 0.5 (indicative now: about 12 years in both sectors).
- **Cost.** Minutes.
- **Reading.** If the band excludes zero, κ = 0 (the fading limit) is the upper case on the evidence, and an erosion
  case is the central one: the headline would move towards +35 to +39 Gt (EU21). If the spread persists but the ordering
  does not, the total stands and the regional statements (who abates, who emits) are what must be qualified; run R5
  measures that.
- **Artifact.** `persistence-of-ordering.rds`.

### T6 — A range for θ from observed prices

- **Question.** By how much is the carbon price lower where the ranking $u$ is higher?
- **Data.** The World Bank carbon-pricing dashboard is already read (`mrpfm` `readWBCarbonPricingDashboard`,
  `calcCarbonPrice`); the OECD effective carbon rates (2018, 2021, 2023) add fuel taxes and are the better measure.
- **Method.** For the covered countries, 2021–2023: the emissions-weighted effective price $P_c$ per sector; a
  reference price $P^{\text{top}}$ (the mean of the countries with $u$ in the lowest decile); regress
  $1 - P_c/P^{\text{top}}$ on $u_c$ through the origin, country bootstrap. The slope is the θ that reproduces today's
  price dispersion.
- **Caveat to carry.** CAPMF scores carbon-pricing instruments, so $E$ and the price are partly the same measurement
  (the circularity `MODEL.md` §5.3.1 names). Repeat with $E$ built from the non-pricing CAPMF components. It is a
  plausibility range, not identification.
- **Cost.** A day, mostly the data.
- **Reading.** A range that contains 0.325–0.675: the sweep is anchored. A range clearly outside: the declared values
  move, and the batch with them.
- **Artifact.** `theta-from-prices.rds`.

### T7 — The index maximum

- **Method.** Refit the selected frontier with `indexMax` 8 and 12; rebuild the anchor; recompute $k(t)$ on the coupled
  panel (`analysis/v6/couplingMechanism.R` does this for the driver groups).
- **Reported.** $u$ (rank correlation with $M$ = 10), $k_{2050}$, $k_{2100}$ per sector.
- **Cost.** Minutes. **Reading.** $k_{2050}$ within ±0.05: the fade does not hang on the scale's maximum. Otherwise
  $M$ joins the declared choices, with its band.

### T8 — The normalisation of the ranking

- **Method.** From `phi-anchor.rds`: $u$ by ranks; min–max without the extreme region (REF set to 1); min–max on the
  5th–95th percentile range. A proxy for the headline, $\sum_r e_r\,\theta\,k_r u_r$ with $e_r$ the region's share of the
  price increment times emissions, calibrated on the existing runs (the θ sweep, gap first, common strength).
- **Cost.** Minutes. **Reading.** If the proxy moves by more than the θ step, the normalisation is a declared choice
  to show; one coupled run confirms the proxy.

### T9 — The interaction block and the weight's scope

Done: §8.

### T10 — The trend grid on `v8`

`analysis/checks/trendShapeGrid.R v8`, then `trendShapePhi.R` for 2010 / 0.30. An hour (one subprocess per fit).
**Reading.** 2010 / 0.30 better in both sectors at an interior γ, as on `v6` and `v7`: declare it for the next group.

### T11 — Which way the lead runs

- **Method.** Long differences over the 48 countries: the change in fossil dependence 2001–2012 against the change in
  stringency 2012–2023, and the reverse, each controlling for the initial levels; and local projections with country
  effects ($y_{t+h} - y_t$ on $\Delta x_t$, $h$ = 1…8).
- **Cost.** Minutes. **Reading.** It cannot identify a cause (the IV is a null). It can show whether the energy system
  leads policy, policy leads the energy system, or both, which is what "conditional scenario accounting" should be
  qualified with.

### T12 — Outside the sample

- **Question.** Does the ceiling order countries the model never saw?
- **Data.** Measures that exist for most countries: carbon-price coverage and level (World Bank), explicit fossil-fuel
  subsidies (IMF), climate laws (Climate Change Laws of the World). To be acquired; `computePFMCrossDataset()` covers
  the outcome's concordance for covered countries only.
- **Method.** Rank correlation of the projected ceiling with each measure, separately for covered and uncovered
  countries; the covered correlation is the benchmark of what the measure can show.
- **Cost.** A day or two. **Reading.** Similar correlations in and out of sample: the ceiling transports. Much lower
  out of sample: the paper says the ranking outside the 48 is the median by assumption, with no evidence either way.

---

## 10. The coupled runs in detail

All on `v8`'s anchor and bases unless stated, as new rows of `analysis/run-groups/scenario-matrix-v8.yml` under their
own start tags, started from the no-politics reference (`warm: "@noPolitics"`), hold the price at θ 0.50 unless stated.
Re-read `PITFALLS.md` §1–§3 before any submission. The switch names below are the ones the `v8` matrix uses; check each
against `COUPLING.md` §14 when the rows are written.

| | rows | switches | compared with | what would change |
|---|---|---|---|---|
| **R1** the emissions band | 2 at EU21 (2 more at H12 if quoted) | the anchor rebuilt at the 5th and 95th percentile of T2's bootstrap (two staged `phi-anchor` files, or `phi-override.yml`, `COUPLING.md` §13) | the headline +75.1 Gt | the third band of the main text; needs T2 first |
| **R2** coverage | 2–3 at EU21 | the uncovered countries at the lower quartile; nearest donors always; (the upper quartile); a rebuilt anchor each (`coverage:` rule) | +75.1 Gt | claim C23 leaves `pending`; a data-side band on `v8` in place of `v6`'s +110 to +155 |
| **R3** an exogenous cap | 2 at EU21 (hold the price, hold the budget) | φ fixed over time from a governance index (for example each region's state capacity relative to the best, Andrijevic et al.'s series), applied (a) to the increment, as here, and (b) to the price level, mode R (`cm_pfmBindMode = 1`); through `phi-override.yml` | the fading and the constant limit | the contrast with the earlier literature in one figure: what the estimated ranking changes against a governance ranking, and what the endogenous fading changes against a fixed one. Needs a short design note first (which index, which normalisation) |
| **R4** the shrinking future | 5-year steps: 9 steps × 2 closures; θ 0.325 / 0.675: 5 steps × 2 | `pfmPhiWindowEnd` at 5-year spacing; `cm_pfmTheta` | the chain's +39.4 Gt | claim C25 leaves `pending` if the halving holds at the shorter step |
| **R5** who against how much | 2–3 at EU21 | `pfmPhiOrdering`: uniform, permuted (two seeds) | +75.1 Gt and the regional pattern | separates the total from the ordering (§3.2); if the total barely moves, the paper's regional statements, not its headline, carry the ranking's uncertainty |
| **R6** the US reference | 1 at EU21 | the current-policy price floored at zero for the reference (`cm_pfmRefPrice` path) | +75.1 Gt, the US share | a footnote, or a correction to every US number |
| **R7** the *p* 0.10 specification | 2 (EU21, H12) | Run-Group `v8-p10`'s anchor | +75.1 / +64.3 Gt | a specification band on `v8` |

**Order.** R2 and R5 need nothing else and answer open claims. R1 follows T2. R3 is the one that places the paper and
needs its design agreed first. R4 follows the decision on whether the shrinking future is in the paper.
---

## 11. Results of the tests run on 2026-11-10

Run on `v8`, offline; scripts in `analysis/v8/` and `analysis/checks/`, artifacts in `output/pfm/v8/`. Each refits or
reads the selected specification and checks itself against the group's artifacts (the ceilings against `frontier.rds`
to 1e-12; the staged $u$ against the staged gaps). Bands are 5–95% over 999 resamples of the 48 countries. Three
results change what §1–§7 said; they are marked **(revises)**.

| test | script → artifact | result in one line |
|---|---|---|
| T3 quantile frontier | `paperChecks.R` → `paper-checks.rds` | the ordering does not rest on γ |
| T4 slack and the ceiling | same | mixed: the levels support the fading limit, the changes within countries since 2008 do not in power & industry **(revises §3.1)** |
| T5 persistence | same | the distance erodes at 2–8% a year in power & industry and 5–16% in buildings & transport; the ordering is gone in about 15 years |
| T8 normalisation | `normalisationCheck.R` → `normalisation-check.rds` | the most constrained region sets the scale: without it the average constraint is 1.4–1.9 times larger |
| T9 interaction block | `interactionBlockTest.R` → `interaction-block-test.rds` | §8 |
| T10 trend grid | `analysis/checks/trendShapeGrid.R v8` → `trend-shape-grid.rds` | on `v8`'s specification 2010 / 0.30 is **not** better in power & industry **(revises §2.4 and S3)** |
| T11 lead and lag | `paperChecks.R` | no lead in either direction can be seen with 48 countries |
| T2 country bootstrap | `frontierBlockBootstrap.R` (written, **not validated**) | not completed: a trial of 10 resamples produced none in 25 minutes on the workstation and was stopped. The frontier refits on resampled countries stall, as some trend shapes do; the script needs each refit in its own process with a time limit (as `trendShapeGrid.R` does) and a cluster job |
| T1, T6, T7, T12 | — | not run: T1 needs a few hours of frame preparation, T6 and T12 need data, T7 needs frontier refits at other index maxima |

### 11.1 T3 — the ordering does not rest on γ

The 0.80, 0.90 and 0.95 conditional quantiles of the response on the selected design, in place of the stochastic
frontier (no split between noise and slack). Rank correlation of the 2023 share of the ceiling used ($E$) with the
stochastic frontier's:

| quantile | P&I countries / EU21 regions | B&T countries / EU21 regions |
|---|---|---|
| 0.80 | 0.92 / 0.86 | 0.86 / 0.81 |
| 0.90 | 0.96 / 0.92 | 0.95 / 0.96 |
| 0.95 | 0.98 / 0.97 | 0.90 / 0.93 |

The fossil-dependence coefficient at the 0.90 quantile, with the country bootstrap: −0.42 (−0.90 to −0.15) in power &
industry, against −0.81 on the stochastic frontier; −0.15 (−0.38 to +0.03) in buildings & transport, against −0.17.

- **The regional ordering survives a frontier that makes no use of γ** (0.92 and 0.96 at the 0.90 quantile). The γ
  margin of 0.0001 is then a statement about levels and about the selection walk, not about the ranking the coupling
  reads. This is a better defence than the four error structures of `MODEL.md` §3.4.1, two of which reorder the
  ranking: those change the model of the slack over time; this changes only where the envelope sits.
- The fossil effect at the upper quantile is negative in power & industry with a clustered band that excludes zero,
  about half the stochastic frontier's size. In buildings & transport the band reaches zero. The frontier's own
  *p*-values (ML) overstate both.

### 11.2 T4 — holding the logit distance: the evidence is mixed (revises §3.1)

Two readings of the same question, whether the logit distance $q$ is independent of the ceiling (the fading limit) or
grows with it so that $E$ stays (the constant limit).

**(a) Levels: the slack's spread on the fitted ceiling** (the heteroscedastic frontier, $\log\sigma_u = c + \omega\,\hat\eta$):

| | ω, whole sample | ω, from 2008 | ω that would hold $E$ | log-likelihood gain (whole / from 2008) |
|---|---:|---:|---:|---:|
| power & industry | −1.50 (se 0.08) | −0.26 (0.02) | +0.29 to +0.30 | 537 / 48 |
| buildings & transport | −0.82 (0.06) | −0.54 (0.10) | +0.22 to +0.23 | 206 / 27 |

Where ceilings are higher the logit distance is **smaller**, in both sectors and both periods. Holding $E$ (ω positive)
is rejected; the data go further than holding $q$ (ω = 0). The whole-sample values are dominated by 2001–2007, when
policy was near zero and the logit distance very large (5% of power & industry rows are at exactly zero).

**(b) Changes within a country since 2008**: the change of $E$ over 5 and 10 years on the change of the ceiling:

| | slope of Δ$E$ on Δ$\eta$ (5 y / 10 y) | holding $q$ predicts | holding $E$ predicts |
|---|---|---:|---:|
| power & industry | **−0.10 (−0.15 to −0.04) / −0.11 (−0.18 to −0.03)** | +0.07 / +0.06 | 0 |
| buildings & transport | +0.02 (−0.07 to +0.15) / −0.05 (−0.18 to +0.12) | +0.02 / +0.02 | 0 |

In power & industry, when a country's ceiling rose its observed policy followed only about half of the movement
(the slope of Δ$q$ on Δ$\eta$ is +0.46 to +0.54), so its share of the ceiling used **fell**. Neither rule predicts
that; the constant limit is the nearer one. In buildings & transport observed policy followed the ceiling about one
for one and the bands contain both rules. With 2001–2007 included, the bands contain both rules in both sectors.

**Reading.**

- §3.1's indicative check (demeaned levels over 2001–2023) agreed with (a) and is superseded: it was driven by the
  early years.
- **The two readings are about different things.** (a) is mostly a comparison across countries and across the era of
  the policy build-up: where ceilings are high, countries sit closer to them. (b) is what the coupling assumes: that a
  country whose ceiling rises moves with it. In power & industry the sample since 2008 does not show that. It is the
  same fact as the model losing to persistence as a forecast (`MODEL.md` §4.3): the ceiling orders countries well and
  tracks their changes poorly.
- **Both carry a mechanical bias**, in opposite directions: an error in the fitted ceiling enters $q$ one for one,
  which pushes (b) towards "the gap widens" and (a) towards "the slack shrinks".
- **Consequence for the paper.** The fading limit cannot be presented as the case the data favour. The argument that
  it is the model-consistent one stands (the frontier assumes a slack independent of the drivers on the logit scale),
  and (a) says the data reject the constant limit as a description of levels. But on the changes, in the sector where
  the fading does most of its work (power & industry $k$ = 0.63 by 2050), the sample is closer to the constant limit.
  **The honest presentation is the two as a bracket, +75 to +124 Gt at EU21, not a central case with a bound.** That is
  the author's decision; it changes the spine's number if taken.
- **A candidate for the frontier**: a slack whose spread falls as the ceiling rises fits far better (537 and 206
  log-likelihood points for one parameter) and changes the 2023 ordering in power & industry (rank correlation of $E$
  with `v8`'s 0.71–0.76; buildings & transport 0.91–0.95). The homoscedastic half-normal slack is the main
  misspecification of the frontier, and probably the reason γ sits at the boundary. For the robustness battery first
  (0011 §3.5).

### 11.3 T5 — how long the distance and the ordering last

Cross-section regressions of the 2023 logit distance on the distance $h$ years before, and rank correlations of $E$:

| | horizon | slope of $q$ | implied erosion a year | rank correlation of $E$ |
|---|---|---|---|---|
| power & industry | 5 y | 0.91 (0.78–1.08) | 1.8% (−1.5 to 4.8) | 0.92 (0.87–0.95) |
| | 10 y | 0.72 (0.51–1.08) | 3.2% (−0.8 to 6.4) | 0.72 (0.58–0.82) |
| | 15 y | 0.29 (0.10–0.48) | 8.0% (4.8 to 14.3) | 0.32 (0.08–0.54) |
| buildings & transport | 5 y | 0.76 (0.58–0.92) | 5.4% (1.6 to 10.3) | 0.69 (0.47–0.83) |
| | 10 y | 0.26 (0.09–0.50) | 12.5% (6.8 to 21.1) | 0.42 (0.17–0.64) |
| | 15 y | 0.07 (−0.08–0.23) | 15.9% (9.3 and above) | 0.30 (0.01–0.55) |

The spread of the gaps narrowed by 1.3% a year in power & industry (−0.2 to 2.8) and 4.8% in buildings & transport
(3.5 to 6.2), from the 2008 and 2023 values; `persistentSlack.R` fits a log-linear trend over the same years and
reports 0.7% and 5.7% (`MODEL.md` §5.2a). The two methods agree on the order of magnitude.

- **Buildings & transport: the distance below the ceiling erodes faster than any declared κ except 5%.** The band at
  every horizon excludes zero and, at 10 and 15 years, excludes 2.7%.
- **Power & industry: the declared κ of 2–2.7% is inside the band at 5 and 10 years**; zero is inside it too. At 15
  years the erosion is clear (4.8–14.3%).
- **The ordering does not last.** After 15 years the rank correlation with today's is 0.3 in both sectors, with a
  lower bound near zero.
- **Caveats.** Noise in $q$ makes it look less persistent than it is; in buildings & transport (γ 0.92) the true
  erosion is somewhat lower than measured. The five-year average inflates the 5-year figures the other way. 48
  countries; 2008 is close to the start of climate policy in several of them.
- **Consequence.** The persistence axis is not only declared: the sample says the fading limit with no erosion
  (the headline, +75.1 Gt) is the **slow** end in buildings & transport, and that an erosion case (+19 to +39 Gt at
  EU21) is the one consistent with 2008–2023. Together with §11.2 the evidence pulls the central case in opposite
  directions: the changes within countries argue for a limit that fades less, the persistence of the distance for one
  that erodes more. The paper's spine, that the result rests on persistence, is strengthened; which case is central is
  not settled by the data.

### 11.4 T8 — the most constrained region sets the scale

The final-energy-weighted mean of $u$, the average constraint per unit of θ at the reference year, under four
normalisations of the same gaps (relative to the model's min–max):

| | EU21 P&I | EU21 B&T | H12 P&I | H12 B&T |
|---|---:|---:|---:|---:|
| min–max (the model) | 1.00 | 1.00 | 1.00 | 1.00 |
| min–max without the most constrained region | 1.47 | 1.36 | 1.91 | 1.85 |
| min–max on the 5th–95th percentile range | 1.42 | 1.22 | 1.14 | 1.17 |
| by ranks | 1.44 | 0.99 | 1.27 | 1.52 |

The most constrained region is REF at both resolutions and in both sectors; the second-largest gap is 0.72–0.76 of
REF's at EU21 and 0.61–0.66 at H12. The ordering is the same under every normalisation (rank correlation 1.00).

- **θ and the normalisation are not separable.** Because one region (Russia, for all of its observed final energy)
  sits well apart, every other region's $u$ is compressed. A θ of 0.50 under the model's normalisation constrains the
  average region about as much as a θ of 0.34 would under a normalisation that leaves the extreme out (EU21, power &
  industry). The coupled result is close to linear in θ, so to first order the headline would be 1.2–1.9 times larger
  under the other normalisations. This is a proxy (it ignores each region's price exposure and the strength path), not
  a coupled number.
- **For the paper:** "θ = 0.50" has no meaning apart from the normalisation, and the Methods should say that the
  scale is set by the most constrained region. One coupled run with a rank-based $u$ would turn the proxy into a number
  (a variant of run R5).

### 11.5 T10 — the trend shape on `v8` (revises §2.4 and S3)

Frontier log-likelihood against the selected shape (2010 / 0.20), at equal parameter count:

| shape | P&I Δ logLik | P&I γ | B&T Δ logLik | B&T γ |
|---|---:|---:|---:|---:|
| 2005 / 0.20 | +13.4 | 1.0000 (boundary) | +29.3 | 0.940 |
| **2010 / 0.20, selected** | 0 | 0.9989 | 0 | 0.918 |
| 2005 / 0.30 | −30.7 | 0.983 | +12.7 | 0.965 |
| **2010 / 0.30** | **−101.3** (covariance corrupt) | 0.961 | +28.2 | 0.930 |
| 2015 and 2020, any steepness | −44 to −254 | at or near the boundary | −68 to −245 | |
| no trend | −360.0 | 1.0000 | −297.9 | 1.0000 |

Not estimable within the 120-second cap in power & industry: linear, 2005 / 0.10, 2010 / 0.10, 2015 / 0.20 (the grid
ran while other jobs used the machine; re-run them alone before quoting "not estimable").

- **On `v8`'s specification no shape beats the declared one in both sectors at an interior γ.** 2010 / 0.30, the
  candidate of `MODEL.md` §2.3.1 on `v6` and `v7` (+2.4 and +25.9), is 101 log-likelihood points worse in power &
  industry with a corrupt covariance. With every actor-power term saturating and the fossil bound, the trade-off between
  the trend and the drivers changed.
- **S3 of §7 is withdrawn.** The declared shape stays for the next sweep. The cost in buildings & transport (28–29
  points against the best shapes) stands as `MODEL.md` states it.

### 11.6 T11 — lead and lag

Standardised long differences over the 48 countries, controlling for the 2013 levels: the change in fossil dependence
2003–2013 on the change in stringency 2013–2023 is −0.10 (*p* 0.60) in power & industry and +0.04 (0.76) in buildings &
transport; the reverse, the change in stringency 2003–2013 on the change in fossil dependence 2013–2023, is −0.31 (0.37)
and +0.22 (0.31). **Nothing can be read from 48 long differences.** The direction of the relation stays open, as the IV
left it; the test is not worth a line in the paper beyond that.

### 11.7 What the results change

| in §1–§7 | now |
|---|---|
| §1 item 1: the fading limit "is defensible, and the sample gives indicative support" | the support is in the levels only; within countries since 2008, power & industry is nearer the constant limit (§11.2). The two limits are a bracket |
| §1 item 3, §2.3: the ordering may depend on γ | it does not (§11.1); the poor fit of the homoscedastic slack is the larger issue (§11.2) |
| §3.2: the ordering "did not last 15 years", indicative | confirmed with bands (§11.3); and the distance itself erodes, faster than the declared central κ in buildings & transport |
| §3.3: the normalisation "matters more than on `v7`" | measured: a factor 1.2–1.9 on the average constraint (§11.4) |
| §2.4, S3: declare the trend 2010 / 0.30 | withdrawn (§11.5) |
| T11 "can show which way the lead runs" | it cannot, with 48 countries (§11.6) |

**For the paper, in order of weight:** (1) the persistence evidence of §11.3 belongs in the main text, beside the
persistence ladder; (2) the fading and the constant limit as a bracket (§11.2) is a decision on the spine's number;
(3) the quantile frontier (§11.1) replaces the γ caveat about the ordering with a result; (4) the normalisation
(§11.4) is one sentence in the Methods and one coupled run.
