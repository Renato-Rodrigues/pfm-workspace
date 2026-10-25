# The Political Feasibility Model — definition and mathematics

*The canonical mathematical statement of the selected PFM. A reader should be able to
implement the model, and evaluate it by hand, from this document alone.*

**Provenance.** Every number is Run-Group **`v7`** unless it says otherwise. Selected specification
**`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satInn iw:fexp`** (ADR 0060), country
resolution, n = 1104 = 48 countries × 23 years (2001–2023; Estonia excluded, ADR 0058), IEA 2025 edition,
five-year moving average, geothermal in the clean-baseload control (ADR 0053), trend logistic (midpoint 2010,
steepness 0.20, standardized, frozen at 2023). Estimation-side numbers are collected by
`Rscript analysis/checks/docFacts.R v7` into `output/pfm/v7/doc-facts/facts.json`. Re-read from there, never from
this page.

> **Coupled results** are from the first `v7` REMIND 3.7.1 batch (30 runs, EU21 and H12, plus five hold-the-budget
> re-runs), in `output/pfm/v7/coupling/coupled-facts.json`. This document quotes only what the model definition
> needs; the full reading is `SCENARIOS.md`. **Results are reported to 2100 and no later.**

> **Analyses not re-run on `v7`** are labelled "measured on `v6`" (or `v5`) where they appear: the offline
> strength and specification band (`phase1/`, §5.2, §5.3.0), the coupled specification and coverage
> sensitivities (§5.3.2, §5.4) and the λ placebo audit (§4.3.2). Their conclusions are about the method; their
> numbers are not `v7` numbers. The `v6` version of this document is `../_archive/_wip/2026-10-25/docs/MODEL-v6.md`.

**Scope.** The model *as selected*. How the spec was selected is ADR 0036/0039/0045/0046/0052, the edge-of-data
gate design note 0007 §5, the theory gate ADR 0059; the formulation of the share is ADR 0049, 0050 and 0054. The
REMIND interface is `COUPLING.md` (§14). Traps are `PITFALLS.md`.

**Naming.** This document says **PFM** throughout (`pfm*` in code since 2026-10-02; artifacts of
`v5` and earlier may still carry `psm*`).

---

## 1. Notation

| Symbol | Meaning | Units / range |
|---|---|---|
| $c$ | country (48 in estimation; 248 projected) | — |
| $r$ | REMIND region (21 at EU21, 12 at H12) | — |
| $t$ | year | 2001–2023 estimation; 2025–2100 projection |
| $t_a$, $t_0$ | anchor year (last panel year, **2023**); reference year of the strength (**2025**) | — |
| $s$ | sector: power & industry (electricity + industry) or buildings & transport (buildings + transport) | — |
| $S_{c,t,s}$ | observed CAPMF policy-stringency index | $[0,10]$ |
| $M$ | structural index ceiling, `indexMax` | $10$ |
| $y^{*}$ | transformed response, $\operatorname{logit}(S/M)$ squeezed | $\mathbb{R}$ |
| $\eta$ | linear predictor | $\mathbb{R}$ |
| $A^{\text{in}}$ | Clean-energy build-out, **share**, saturating (§2.3) | standardized |
| $A^{\text{ic}}$ | Fossil dependence, **share** — the dependence / lock-in channel, linear | standardized |
| $A^{\text{ic,pc}}$ | Fossil interests **per person** = share × primary energy per capita — the scale channel, linear | standardized |
| $G$ | Government Effectiveness (WGI) — state capability | standardized |
| $R$ | Rule of Law (V-Dem) | standardized |
| $V$ | Vertical Accountability (V-Dem) — electoral accountability of rulers to citizens | standardized |
| $w$ | **interaction weight**: V-Dem freedom of expression and alternative information (`v2x_freexp_altinf`) — new in `v7` | $[0,1]$, unstandardized |
| $T(t)$ | logistic time trend, frozen at the last historical year | standardized |
| $v, u$ | symmetric noise $N(0,\sigma_v^2)$; one-sided political slack $N^{+}(0,\sigma_u^2)$ | — |
| $\gamma$ | slack variance share $\sigma_u^2/\sigma^2$ | $[0,1]$ |
| $S^{*}$ | **feasibility frontier** (ceiling) | $[0,10]$ |
| $E = S/S^{*}$ | efficiency ratio — the implementability factor | $(0,1]$ |
| $q_{c,s}$ | anchored distance below the ceiling, on the logit scale, $\eta - y$ at $t_a$ | $\geq 0$ |
| $g_{r,s}$ | regional relative gap $1 - E$ | $[0,1]$ |
| $u_{r,s}$ | regional **ranking**, min–max of $g$ at $t_a$ | $[0,1]$ |
| $k_s(t)$ | **strength**: weighted mean gap relative to $t_0$ | $k(t_0) = 1$ |
| $\varphi_{r,s}(t)$ | **feasibility share** — fraction of the extra effort beyond current policy a region carries | $[0,1]$ |
| $\theta$ | severity — declared and swept, never estimated | $[0,1)$ |
| $\kappa$ | erosion rate of the strength (a declared sensitivity, ADR 0050) | per year |
| $\lambda_s$ | ECM adjustment speed — a reported diagnostic only, **not in the coupling** (§4) | per year |
| $A_t$, $P^{\text{ref}}$ | cost-optimal anchor and current-policy carbon price | \$/tCO₂ |

---

## 2. The estimating equation

### 2.1 Response transform

The outcome is bounded by construction, so it is mapped to the real line before fitting (the
"satP" engine, ADR 0026, with CAPMF's true ceiling $M = 10$):

$$p = \frac{S}{M}, \qquad \tilde p = \frac{p(n-1)+0.5}{n}, \qquad y^{*} = \operatorname{logit}(\tilde p)$$

with $n$ the number of estimation rows (Smithson–Verkuilen squeeze, `.pfmSqueeze`).

> *In words:* the 0–10 index becomes a proportion, nudged just off the boundaries so the
> logit is finite, and is modelled on the logit scale. The squeeze is an estimation device
> only — never undone when reporting.

**Back-transform:** $\hat S = M\cdot\operatorname{logit}^{-1}(\hat\eta)$. Nothing the model
produces can leave $[0,10]$.

**Boundary check.** 5.1% of power & industry rows and 0.4% of buildings & transport rows sit at exactly 0; **no**
row sits at the maximum (`frontier.rds` scores). That is the empirical gate that closed the two-limit Tobit rung as
unnecessary.

### 2.2 The selected specification

`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satInn iw:fexp`, fitted separately per
sector on an identical design (the Shared Specification rule):

$$
\begin{aligned}
\eta_{c,t} = \;&\alpha
+ \sum_{a\in\{\text{in},\text{ic},\text{ic,pc}\}} \beta_a A^{a}
+ \beta_G G + \beta_R R + \beta_V V
+ \sum_{a}\sum_{k\in\{G,R,V\}} \delta_{a k}\, A^{a}\!\cdot\! k\cdot w_{c,t} \\
&+ \tau\, T(t) + \boldsymbol\psi'\mathbf{z}
+ \mu_{\text{OECD}}\mathbb{1}[c \in \text{OECD}] + \mu_{\text{other}}\mathbb{1}[c \in \text{other}]
\end{aligned}
$$

Three actor-power terms, three institutions, **nine weighted interactions**, three controls $\mathbf{z}$ (GDP
per capita Q-centred, log population, clean-baseload share: hydro, nuclear and geothermal) and the
trend: **19 slope terms**. **No lagged outcome, no Mundlak, levels transform; clean-energy build-out saturates, the
two fossil terms enter linearly** (`satInn`, §2.3). The drivers and the weight enter at $t-1$; the lag counts
years, so on a scenario panel in REMIND's 5- to 20-year steps the driver at $t-1$ is interpolated
(`PITFALLS.md` §31).

**The interaction weight (design note 0007, ADR 0060).** Every interest × institution product is multiplied by
$w_{c,t}$, read year by year and kept on its own 0–1 scale; the product of the two standardized factors is not
re-standardized. In scenarios $w$ is held at its last observed value. *In words:* an institution moderates the
effect of an interest in proportion to how freely information and opinion circulate — the condition under which
an institutional channel can be used by the public against an interest. Where $w \to 0$ the institutional
moderation vanishes and only the main effects remain. The weight is the comparability device that removed `v6`'s
edge effects (§2.4a); it costs 9 log-likelihood points in power & industry and 25 in buildings & transport against
the unweighted `v6` specification (ADR 0060).

Two estimators use this design and they are **different estimands** — never compare their
coefficients as though one were a refit of the other:

| | estimator | what it estimates | inference | artifact |
|---|---|---|---|---|
| **mean regression** | satP: `glm(gaussian(identity))` on $y^{*}$ | conditional **mean** of $y^{*}$ | country-clustered CR1; wild-cluster bootstrap-$t$, $B$ = 999, $G$ = 48 | `inference.rds` (§2.5) |
| **frontier** | half-normal SFA on $y^{*}$ | conditional **maximum attainable** $y^{*}$ | ML standard errors (no clustered sandwich exists for the SFA likelihood), checked by `vcovCheck` | `frontier.rds` (§3.3) |

The coupling consumes only the frontier. The mean regression is the inferential companion that
the selection metrics (ΔR²(theory), significance counts, the theory gate) are computed on.

> *In words:* stringency is explained by how strong the clean-energy coalition is, how dependent
> the economy is on fossil interests and how large they are per person, how capable the state is,
> how firmly the rule of law holds, how accountable rulers are to voters, **how those forces
> multiply each other where opinion is free**, a common time trend, and a coarse three-way group effect.

### 2.3 The components

**Actor power** (`actorPowerIndex()`), computed from the IAM's own energy system — this is the
channel through which a REMIND pathway talks back to the model:

$$A^{\text{in},\text{Bulk}} = \frac{1.0\,\text{VRE} + 0.6\,\text{Elec}}{1.6},\qquad
A^{\text{ic},\text{Bulk}} = \frac{1.0\,\text{Coal} + 1.0\,\text{OilGas} + 0.5\,\text{FossInd}}{2.5}$$

$$A^{\text{in},\text{Diffuse}} = \frac{0.5\,\text{VRE} + 1.0\,\text{Elec} + 0.4\,\text{Biofuel}}{1.9},\qquad
A^{\text{ic},\text{Diffuse}} = \frac{0.2\,\text{Coal} + 0.2\,\text{OilGas} + 1.0\,\text{FossInd}}{1.4}$$

$$A^{\text{ic,pc}} = A^{\text{ic}} \times \text{primary energy per capita}$$

Weights are fixed design constants, not estimated. The drivers measure the economic weight of fossil and
clean-energy interests, a structural-power proxy (ADR 0056).

**Saturation (`satInn`, the clean-energy-only family; ADR 0040, 0052).** Clean-energy build-out enters as
$x/(x+\bar x)$, with $\bar x$ the training median, before standardization: the curve is steepest at zero and
flattens above the median, so the clean-energy share does not extrapolate linearly into a range no country has
occupied. **The two fossil terms enter linearly** (on `v6` they saturated too, `satAP`). Below the observed
fossil range they therefore extrapolate linearly; the edge-of-data gate (§2.4a) is what checks that this does not
move the projected ceilings by more than a declared amount. On the coupled 1000 Gt pathway (hold the price, EU21,
final-energy-weighted share of countries; `coupling/strength-support.rds`), clean-energy build-out is above
anything observed for 89% of countries in 2050 and 94% in 2100 in power & industry (97% / 99% in buildings &
transport); fossil dependence is below anything observed for 1% in 2050 and **50% in 2100** in power & industry
(2% / 19% in buildings & transport); fossil interests per person below for 14% / 18% (17% / 17%).

**The `bothIncAP` form (ADR 0044, ADR 0045).** Fossil interests enter twice — as a share (how
dependent the energy system is) and per capita (how large the fossil interest is) — which
nests both the share-only and per-capita-only forms. Clean-energy build-out enters as a share.

> 🔴 **The two fossil channels pull in OPPOSITE directions, and only the pair is
> interpretable.** On the frontier the power & industry share is **−0.555** and the per-capita term **+0.474**;
> in buildings & transport −0.160 and +0.086 (§3.3). Their interactions with the institutions differ in sign too.
> A sentence that names one channel and not the other inverts the sign of the other half. The
> channels are not orthogonal (share × energy per capita), so this is a decomposition, not two
> independent findings. The paper reports the fossil effect's dependence on an institution, not one coefficient
> (ADR 0060).

**The split form is load-bearing.** A composite $A = A^{\text{in}} - A^{\text{ic}}$ makes
projections *scenario-blind* under the extrapolation guard. Splitting keeps the feedback channel
alive. **Never revert.**

**Institutional channels.** $G$ = WGI Government Effectiveness; $R$ = V-Dem Rule of Law (in 100% of bootstrap
winners, §6); $V$ = V-Dem Vertical Accountability. The institution series are harmonised to the anchor year in
every scenario (ADR 0051). **The institution main effects are not identified in power & industry** (§2.5, §3.3),
nor in the poorest countries with very low fossil energy per person (ADR 0060).

**Smoothing.** `panelDataHistorical(movingAverage = 5)` applies a centred five-year moving average
(window shortened at the panel ends, so 2023 = mean of 2021–2023) to every panel column after
normalisation, the outcome included. Annual data were a robustness rung on `v6` (`v6-annual`, ADR 0053); there is
no `v7` annual sibling.

**Standardization.** Every driver and interaction factor is standardized on the estimation rows;
means/SDs are **frozen** in `driverScaling` and reused for scenario panels. Coefficients are per
standard deviation — including the trend. The weight $w$ is not standardized.

**Time trend.** Logistic in calendar year, evaluated at $\min(t, 2023)$ for any projection year,
then standardized like every other driver:

$$T(t) = \big[1+\exp(-k(t-m))\big]^{-1},\qquad m = 2010,\; k = 0.20$$

Read the shape from the artifact, never from here: `manifest.json$trend` and
`selected-models-pfm.yml`.

> *In words:* a time effect cannot be extrapolated, so it is held at its last historical value
> and the scenario drivers — not the calendar — carry all future differentiation.

**Fixed effects.** `regionmapping_EU_OECDp.csv` → three blocks: **EU** (reference), **OECD**
non-EU, **other**. Country dummies are an agreement rung only.

#### 2.3.1 The trend shape is DECLARED, not selected

The trend shape is not a selection dimension: `createChannelConfigs()` hard-codes one $(m,k)$, so the
selected specification is conditional on that constant. Holding the selected specification fixed and varying only
the trend (`analysis/checks/trendShapeGrid.R v7` → `output/pfm/v7/trend-shape-grid.rds`; one subprocess per fit,
120 s cap), frontier logLik at **identical parameter count**:

| $(m,k)$ | Power & industry Δ logLik vs selected | Power & industry $\gamma$ | Buildings & transport Δ logLik | Buildings & transport $\gamma$ |
|---|---:|---:|---:|---:|
| 2005 / 0.10 | +8.4 | 1.0000 ⚠️ | −9.3 | 0.9694 |
| **2010 / 0.30** | **+2.4** | 0.9956 | **+25.9** | 0.9810 |
| 2005 / 0.20 | −81.0 (covariance corrupt) | 0.8981 | +25.1 | 0.9820 |
| 2005 / 0.30 | −15.7 | 0.9824 | +7.7 | 0.9867 |
| **2010 / 0.20 — selected** | — | 0.9984 | — | 0.9725 |
| 2010 / 0.10 | −10.7 | 1.0000 ⚠️ | −31.7 | 0.9661 |
| linear | −17.0 | 1.0000 ⚠️ | −47.7 | 0.9644 |
| 2015–2020 | −32 to −235 (2020 / 0.20 not estimable) | mostly 1.0000 ⚠️ | −62 to −225 | 0.960–1.000 |
| no trend | −325.5 | 1.0000 ⚠️ | −257.3 | 1.0000 ⚠️ |

Later midpoints are monotonically worse, and in power & industry most of the other settings reach the γ boundary
(ADR 0046: a setting with γ ≥ 0.999 must not be selected however well it fits). The only setting better than the
selected one in both sectors at an interior γ is **2010 / 0.30** (+2.4 and +25.9; trend share 0.666 and 0.535, clear of
the 0.90 gate). It was the same on `v6` (+1.2 and +25.7). On `v6` that shape barely moved φ (Spearman 0.976, median
|Δφ| 0.009; `v6` `trend-shape-phi.rds`); `trendShapePhi.R` has not been run on `v7`.

**Why the declared shape is kept.**

1. **It is interior and close to the best in power & industry** (2.4 logLik behind 2010 / 0.30).
2. **Likelihood and the selection rule pull against each other in places**: the boundary settings fit better in
   power & industry; sweeping the trend would add a selection dimension on which the γ gate, the trend-dominance gate
   and the likelihood disagree.
3. **It was declared before the search**, and changing it after the result is known is the kind of revision ADR 0059
   asks to be disclosed.

> **The cost, stated plainly.** The selected trend is **25.9 logLik worse in buildings & transport** than the best
> shape at equal parameter count, and 2.4 worse in power & industry. It is a declared choice, not a fitted one, and
> should be described in those words.

**What would change this.** The condition this section set on `v6` — a sector-common shape that beats the selected
one in both sectors at an interior γ with the trend share clear of the gate — is met by 2010 / 0.30 on `v6` and `v7`.
It is a candidate for the trend in the next Run-Group's sweep, not a change to this one.

### 2.4 Fit of the selected specification (`sweep.rds`)

| | Power & industry | Buildings & transport |
|---|---:|---:|
| ΔR²(theory) | **0.128** | **0.161** |
| pseudo-R² | 0.727 | 0.780 |
| trend share of linear-predictor variance | 0.685 | 0.535 |
| max VIF | 7.51 | 7.62 |
| significant actor-power / institution / interaction terms | 5 / 3 / 3 | 2 / 2 / 1 |
| smallest significant theory $\lvert t\rvert$ | 3.12 | 3.15 |
| tier | Green | Green |
| $n$ | 1104 | 1104 |

**Selection position.** 36,384 specifications ranked; **84** pass every gate (the admissibility gates, the
edge-of-data gate and the theory gate; 5,930 pass the gates before the theory gate). The maximin order sorts by
trend share first (`trendKey`); the selected specification is **rank 18** (mean ΔR²(theory) 0.1445, minimum
0.128, ΣBIC 4718.8, fragility 0). Of the seventeen ahead of it, thirteen fail a gate (most the theory gate's H2 in
buildings & transport) and four pass and are rejected by the **sanity walk** (four or five severe flags each:
the all-linear variants of X-1791, X-1794 and X-1860, and the `satInc` variant of X-1860). It is accepted with 0 severe flags and
47 warnings (`forced = FALSE`).

Gates in force: `supportShareGate` **0.275** (ADR 0045, 0052), `ceilingFallGate` 0.90 (ADR 0043; the selected
specification ends at 1.15 / 1.26 of its 2025 ceiling on the 1000 Gt pathway), `gammaGate` 0.999 (ADR 0046),
VIF hard 10 / soft 6; the edge-of-data gate and the theory gate (§2.4a).

> ⚠️ **Rank 18 is not dominance.** The best *per-sector* specifications fit more: power & industry
> `X-2980 WGIge|RoL|OvAcc … satInn` reaches ΔR² 0.140 and buildings & transport `X-1854 … satInc` 0.202 — a
> **sharing cost** of 0.012 (8.6%) in power & industry and 0.041 (20.3%) in buildings & transport
> (`selection-variants.rds`).

#### 2.4a The two gates new in `v7`

**The edge-of-data gate** (`.pfmEdgeGate`, design note 0007 §5). A specification is admitted only if, on the
coupled 1000 Gt drivers mapped to EU21, (i) the share of a region's weight on which the fossil effect acts against
the theoretical expectation is below 0.25, (ii) the size of that adverse effect is below 0.25, and (iii) capping
the drivers at the observed range moves the projected ceilings by less than 0.5 (cap quantiles 0.05 / 0.95). The
selected specification: cap shift **0.21** (power & industry) and **0.09** (buildings & transport). `v6`'s
specification on the `v7` data fails it (0.56 and 1.29; ADR 0060).

**The theory gate** (ADR 0059). The hypotheses are stated before the estimate (paper Methods §1) and required of
the specification, on the mean regression with wild-cluster $p$:

| | hypothesis | requirement | power & industry | buildings & transport |
|---|---|---|---|---|
| **H1** | structural power | fossil dependence lowers stringency, $p < 0.05$ | −0.731 ($p$ .008) | −0.199 ($p$ .015) |
| **H2** | contingency | at least one fossil × institution term significant after Bonferroni correction over the sector's fossil × institution terms; share and per-person terms both count; **sign free** | fossil pc × GovEff −1.021, fossil pc × RoL +1.346 (both $p$ < .001) | fossil pc × VerAcc +0.698 ($p$ .001) |
| **H3** | coherence | the fossil effect, including its interactions, is negative in ≥ 75% of country-years | 100% | 95% |

Declared sensitivities of the gate (ADR 0059 acceptance): H3 at 0.70 and 0.80, $p$ at 0.10 (Run-Groups
`v7-h3070`, `v7-h3080`, `v7-p10`; `RUNNING.md` Step 6c).

> ⚠️ **Post-selection inference.** The selection requires H1–H2, so the reported $p$-values of the terms the gate
> reads are biased downwards; they are conditional on a specification chosen in part for them. The rule was
> revised for `v7` after the `v6` result was known (ADR 0059). Both facts travel with every estimate.

### 2.5 Fitted coefficients — mean regression (`inference.rds`)

Selected specification, country-clustered, $G = 48$, $n = 1104$. $p_{\text{wild}}$ is a Rademacher
wild-cluster bootstrap-$t$, $B$ = 999 — **these are the quotable $p$-values**; 48 clusters is too
few for asymptotic inference, and $p_{\text{asym}}$ is shown so the gap is visible. AME is the
average marginal effect in index points per SD (§2.7). Interaction rows are the weighted products (§2.2).

| Term | Power & industry $\hat\beta$ | $p_{\text{asym}}$ | $p_{\text{wild}}$ | AME | Buildings & transport $\hat\beta$ | $p_{\text{asym}}$ | $p_{\text{wild}}$ | AME |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Clean-energy build-out | −0.122 | .254 | .238 | −0.181 | 0.046 | .480 | .549 | 0.088 |
| Fossil dependence (share) | **−0.731** | .002 | **.008** | −1.085 | **−0.199** | .002 | **.015** | −0.385 |
| Fossil interests (pc) | **0.518** | <.001 | **<.001** | 0.768 | 0.050 | .459 | .547 | 0.096 |
| Gov. Effectiveness | 0.067 | .649 | .642 | 0.100 | **0.316** | .001 | **.003** | 0.612 |
| Rule of Law | 0.293 | .113 | .193 | 0.434 | −0.154 | .139 | .214 | −0.297 |
| Vertical Accountability | −0.189 | .189 | .373 | −0.280 | 0.114 | .174 | .334 | 0.221 |
| Innov × GovEff | **−0.377** | <.001 | **.001** | −0.560 | 0.062 | .393 | .470 | 0.120 |
| Innov × RoL | 0.398 | .130 | .170 | 0.591 | 0.102 | .343 | .413 | 0.197 |
| Innov × VerAcc | −0.189 | .596 | .606 | −0.280 | −0.283 | .239 | .349 | −0.546 |
| Fossil × GovEff | 0.131 | .480 | .559 | 0.195 | 0.060 | .453 | .487 | 0.116 |
| Fossil × RoL | 0.684 | .119 | .231 | 1.015 | 0.260 | .058 | .074 | 0.503 |
| Fossil × VerAcc | −0.557 | .328 | .397 | −0.827 | −0.292 | .108 | .149 | −0.564 |
| Fossil pc × GovEff | **−1.021** | <.001 | **<.001** | −1.515 | −0.084 | .567 | .659 | −0.162 |
| Fossil pc × RoL | **1.346** | <.001 | **<.001** | 1.997 | −0.327 | .113 | .209 | −0.633 |
| Fossil pc × VerAcc | −0.357 | .231 | .380 | −0.530 | **0.698** | <.001 | **.001** | 1.349 |
| GDP p.c. (Q-centred) | 0.100 | .252 | .325 | 0.149 | −0.059 | .250 | .355 | −0.114 |
| Population (log) | **0.378** | <.001 | **<.001** | 0.562 | **0.293** | <.001 | **<.001** | 0.566 |
| Clean baseload share | **−0.297** | .023 | **.040** | −0.441 | 0.021 | .698 | .767 | 0.040 |
| Logistic trend | **1.300** | <.001 | **<.001** | 1.929 | **0.621** | <.001 | **<.001** | 1.201 |

> No term changes verdict between the asymptotic and the wild-cluster $p$ at 0.05 (on `v6` one did).

**What the table says, on signs and wild $p$:**

- **Structural power (H1) in both sectors.** Fossil dependence lowers stringency: −0.731 in power & industry,
  −0.199 in buildings & transport.
- **No institution main effect is significant in power & industry** ($p_{\text{wild}}$ .64 / .19 / .37), and the
  frontier gives GovEff and VerAcc the opposite sign (§3.3). **The power & industry institution main effects are
  not identified.**
- **State capability is significant in buildings & transport** (GovEff +0.316, $p_{\text{wild}}$ .003; positive in
  6 of 7 estimators, §2.5.1).
- **Contingency (H2) acts through fossil interests per person in both sectors.** In power & industry with state
  capability (−1.021) and rule of law (+1.346); in buildings & transport with accountability (+0.698). On `v6` the
  buildings & transport contingency ran through the fossil *share* × accountability (−0.492, $p$ < .001); on `v7`
  that term is −0.292 ($p$ .149). Only the pair of fossil terms is interpretable (§2.3).
- **Fossil interests per person raise power & industry stringency** (+0.518) — the scale reading the design
  carries alongside the dependence reading, and a disclosed tension (§8.3).
- **Population and the trend are significant in both sectors**; the clean-baseload share is negative in power &
  industry (−0.297, $p_{\text{wild}}$ .040).

#### 2.5.1 Sign stability across estimators (`estimator-agreement.rds`)

Seven estimators on the same design — satP, fractional logit, beta, levels OLS, satP random
effects, satP with year FE, levels two-way FE. A term's sign **agrees** if all agree (the trend is
absent from the year-FE estimators):

| | Power & industry | Buildings & transport |
|---|---|---|
| terms with every sign agreeing | **6 of 19** | **9 of 19** |
| which | fossil dependence (−), `Fossil pc × RoL` (+), `Fossil × RoL` (+), `Fossil × VerAcc` (−), `Innov × VerAcc` (−), trend (+) | fossil dependence (−), `Fossil pc × VerAcc` (+), clean-energy (+), `Innov × GovEff` (+), `Innov × VerAcc` (−), population (+), RoL (−), VerAcc (+), trend (+) |
| fossil dependence | − in 7, significant in 6 | − in 7, significant in 6 |
| GovEff | + in 5, − in 2 | + in 6, − in 1 |

> ⚠️ **Sign agreement is weak in power & industry.** Thirteen of nineteen power & industry terms change sign
> somewhere in the battery, the institution main effects and `Fossil pc × GovEff` (− in 6) among them. The two
> hypotheses' anchors hold: fossil dependence is negative under every estimator in both sectors, and the
> contingency terms the gate reads keep their sign in six or seven of seven.

### 2.6 How much of this survives dropping one country (`influence.rds`)

Leave-one-country-out over the 48 clusters, α = 0.05. $p_{\max}$ is the worst $p$ across the 48
refits; **pivotal** counts the countries whose removal alone flips the term's verdict. The theory terms
significant at full sample:

| Term | $p$ | $p_{\max}$ over refits | pivotal | verdict |
|---|---:|---:|---|---|
| **Power & industry** fossil dependence | .003 | .031 | — | robust |
| Power & industry fossil interests per person | <.001 | .004 | — | robust |
| Power & industry Fossil pc × GovEff | <.001 | .0002 | — | robust |
| Power & industry Fossil pc × RoL | <.001 | .0001 | — | robust |
| Power & industry Innov × GovEff | <.001 | .009 | — | robust |
| **Buildings & transport** fossil dependence | .003 | .052 | 1 — RUS | 🟠 borderline |
| Buildings & transport GovEff | .003 | .045 | — | robust |
| Buildings & transport Fossil pc × VerAcc | <.001 | .809 | 2 — CHN, SAU | 🟠 holds except two |

> **H1 is more robust than on `v6`** (power & industry largest leave-one-out $p$ .031 against .243). The buildings &
> transport contingency rests on two countries: without China or without Saudi Arabia, `Fossil pc × VerAcc` is not
> significant.

Terms not significant at full sample whose removal of one country would *create* significance
exist in both sectors (buildings & transport `Fossil × RoL`: seven countries; power & industry RoL: three).
**No claim rests on any of them, and dropping a country to obtain a result is exactly what must
not be done.**

#### 2.6.1 One country with leverage: Saudi Arabia

SAU is the top influencer on **eight of fifteen** buildings & transport theory terms (every per-capita term and
its interactions, rule of law, GovEff, and two clean-energy interactions) and on four power & industry terms
(RoL, `Innov × GovEff`, `Fossil pc × RoL`, `Fossil pc × VerAcc`), and pivotal in buildings & transport
`Fossil pc × VerAcc`. It combines the lowest Vertical Accountability in the sample with the highest fossil
interests per person — the plane the accountability × fossil interests interaction identifies. The conjunction
has n = 1. **No control fixes this**: the binding constraint is support, and no covariate creates data where there
is none (§2.7).

### 2.7 Marginal effects

Because the response is non-linear, report average marginal effects on the natural scale:

$$\text{AME}_k = \frac{1}{N}\sum_{c,t} M\,\operatorname{logit}^{-1}(\eta)\big(1-\operatorname{logit}^{-1}(\eta)\big)\frac{\partial\eta}{\partial x_k}$$

with $\partial\eta/\partial x_k$ including interaction terms (and the weight $w$) and delta-method clustered SEs;
tabulated in §2.5 and persisted in `inference.rds`. Every driver is standardized, so every AME is per
SD. Examples: buildings & transport **GovEff** AME **0.612** index points per SD (SE 0.190); power & industry
**fossil dependence** **−1.085** (SE 0.346), the largest identified power & industry main-effect AME.

**Support discipline:** AMEs are reported only over the driver range where they are identified
(`computeMarginalEffectSupport`). An interaction evaluated outside the observed joint support is
extrapolation, not a finding.

---

## 3. The feasibility frontier

### 3.1 The composed error

The same design is estimated as a production frontier — the conditional *maximum attainable*:

$$y^{*}_{c,t} = \mathbf{x}'\boldsymbol\beta_F + v_{c,t} - u_{c,t},\qquad
v\sim N(0,\sigma_v^2),\quad u\sim N^{+}(0,\sigma_u^2)$$

> *In words:* a country can sit below what its politics would support, but not above. The
> one-sided term $u$ is the shortfall — political slack.

Slack is separated from noise by Jondrow et al. (1982): with $\varepsilon = v-u$,
$\mu^{*} = -\varepsilon\gamma$, $\sigma^{*} = \sqrt{\gamma(1-\gamma)\sigma^2}$, and
$\mathbb{E}[u\mid\varepsilon] = \mu^{*} + \sigma^{*}\phi(\mu^{*}/\sigma^{*})/\Phi(\mu^{*}/\sigma^{*})$.

### 3.2 In index units

$$\boxed{\,S^{*} = M\cdot\operatorname{logit}^{-1}(\eta_F)\,}\qquad
\hat S^{\text{exp}} = M\cdot\operatorname{logit}^{-1}\!\big(\eta_F - \mathbb{E}[u\mid\varepsilon]\big)$$

$$G^{\text{ap}} = S^{*} - \hat S^{\text{exp}},\qquad E = \frac{S}{S^{*}} \in (0,1]$$

> $E$ is the implementability factor: it compares each polity to **its own** political
> possibility rather than to a universal maximum. **Never use $S/10$.** $E$ is built from the
> ceiling alone (`efficiencyRatio = observedIndex / frontierIndex`), with no Jondrow term.

### 3.3 Estimated frontier (`frontier.rds`)

Half-normal SFA, both sectors on the identical design, $n = 1104$ each.

| | Power & industry | Buildings & transport |
|---|---:|---:|
| $\gamma = \sigma_u^2/\sigma^2$ | **0.9984** | **0.9725** |
| $\sigma^2$ | 2.206 | 0.488 |
| LR test against OLS | 518.0 | 317.7 |
| logLik | −1265.3 | −529.1 |
| covariance check (`vcovCheck`) | ok, ratio 1.01 | ok, ratio 0.98 |
| converged | yes | yes |

**Frontier coefficients** (ML standard errors; $p$ asymptotic — see §2.2 for why there is no
clustered alternative):

| Term | Power & industry $\hat\beta_F$ | $p$ | Buildings & transport $\hat\beta_F$ | $p$ |
|---|---:|---:|---:|---:|
| Clean-energy build-out | **0.125** | <.001 | **0.138** | <.001 |
| Fossil dependence (share) | **−0.555** | <.001 | **−0.160** | <.001 |
| Fossil interests (pc) | **0.474** | <.001 | **0.086** | <.001 |
| Gov. Effectiveness | **−0.493** | <.001 | **0.250** | <.001 |
| Rule of Law | **0.694** | <.001 | −0.056 | .26 |
| Vertical Accountability | **−0.391** | <.001 | 0.060 | .12 |
| Innov × GovEff | **−0.175** | <.001 | 0.018 | .53 |
| Innov × RoL | **0.250** | <.001 | **0.156** | <.001 |
| Innov × VerAcc | **−0.266** | .011 | **−0.317** | <.001 |
| Fossil × GovEff | **0.373** | <.001 | 0.064 | .075 |
| Fossil × RoL | −0.145 | .36 | **0.244** | <.001 |
| Fossil × VerAcc | −0.143 | .49 | **−0.304** | .004 |
| Fossil pc × GovEff | **−1.084** | <.001 | **−0.121** | .001 |
| Fossil pc × RoL | **1.475** | <.001 | **−0.261** | <.001 |
| Fossil pc × VerAcc | −0.106 | .29 | **0.567** | <.001 |
| GDP p.c. (Q-centred) | 0.060 | .090 | 0.001 | .95 |
| Population (log) | **0.261** | <.001 | **0.256** | <.001 |
| Clean baseload share | **−0.206** | <.001 | 0.031 | .11 |
| Logistic trend | **0.901** | <.001 | **0.497** | <.001 |
| FE OECD / other (vs EU) | **−0.200** (<.001) / **−1.090** (<.001) | | **−0.146** (<.001) / **−0.380** (<.001) | |

> ⚠️ **The two estimators disagree about power & industry institutions.** The mean regression finds no power &
> industry institution main effect (GovEff +0.067, RoL +0.293, VerAcc −0.189, all $p_{\text{wild}}$ > .19); the
> frontier finds GovEff **−0.493**, VerAcc **−0.391** and RoL **+0.694**. They estimate different
> things — the average versus the attainable maximum — but "state capability raises the power & industry
> *ceiling*" is **not** a supported sentence, and nor is its negation. In buildings & transport both estimators
> agree on GovEff (+0.316 mean, +0.250 frontier).
>
> ✅ **The terms the theory gate reads agree in sign across the two estimators**: fossil dependence (−/−), fossil pc
> × GovEff and × RoL in power & industry, fossil pc × VerAcc in buildings & transport.
>
> ⚠️ **Frontier $p$-values are ML and understate uncertainty.** The design effect of country clustering
> on the same design is **1.93×** (power & industry) and **2.20×** (buildings & transport) in the mean regression
> (`efficiency-ratio-band.rds`, §5.3.1). Quote frontier signs; quote mean-regression $p$.

### 3.4 ⚠️ The $\gamma$ caveat — read before using any ceiling

$\gamma$ = 0.998 / 0.973 attributes nearly all composed error to slack. Both are inside the γ gate
(0.999, ADR 0046); power & industry γ is close enough to 1 that the noise/slack split is weakly identified and
the *level* of a single country's ceiling is the least trustworthy thing the model produces (accepted with
disclosure since ADR 0053). The coupling reads the ceilings as an **ordering** (§5.2). The robustness battery
re-estimates under three alternative error structures; $\rho$ is the Spearman correlation of country slack ranks
against the headline:

| Rung | Power & industry $\gamma$ | Power & industry $\rho$ | Buildings & transport $\gamma$ | Buildings & transport $\rho$ |
|---|---:|---:|---:|---:|
| headline (pooled half-normal) | **0.9984** | — | **0.9725** | — |
| truncated-normal $u$ | 0.997 | 0.39 | 0.979 | **0.78** |
| panel (Battese–Coelli 92) | 0.916 | 0.05 | 0.909 | 0.46 |
| time-decay (BC), $\eta$ | 0.064, $\eta$ = 0.156 | 0.03 | 0.217, $\eta$ = 0.113 | **0.66** |

> 🔴 **Power & industry slack ranks are not robust on any rung** (0.39 / 0.05 / 0.03). Buildings & transport holds
> on two of three (0.78 / 0.66) and weakens on the panel rung (0.46). **Report tiers, never named country
> rankings of slack, in both sectors.**

#### 3.4.1 Propagated to what the coupling consumes (`frontier-rung-phi.rds`)

`slackRankCor` ranks countries on absolute slack, which the coupling never sees; it consumes $E$,
then $\varphi$. Rebuilt per rung (`analysis/checks/propagateFrontierRungsToPhi.R v7 2023`, the anchor
year, 48 covered countries, θ = 0.50; offline, not through the coupling's anchor artifact):

**Country $E$ versus the headline:**

| Rung | Power & industry $\rho$ | median $\lvert\Delta E\rvert$ | Buildings & transport $\rho$ | median $\lvert\Delta E\rvert$ |
|---|---:|---:|---:|---:|
| truncated-normal | **0.974** | 0.049 | **0.979** | 0.052 |
| panel (BC92) | 0.610 | 0.113 | 0.340 | 0.099 |
| time-decay | 0.740 | 0.186 | 0.632 | 0.135 |

**Delivered $\varphi = \min(\varphi^{\text{Bulk}},\varphi^{\text{Diffuse}})$, GDP weights, the regions
with a covered country (20 at EU21, 11 at H12):**

| Rung | EU21 Spearman | median / max $\lvert\Delta\varphi\rvert$ | H12 Spearman | median / max $\lvert\Delta\varphi\rvert$ |
|---|---:|---|---:|---|
| truncated-normal | **0.920** | 0.041 / 0.081 (IND) | 0.845 | 0.041 / 0.081 (IND) |
| panel (BC92) | 0.507 | 0.091 / 0.216 (NES) | 0.418 | 0.114 / 0.287 (SSA) |
| time-decay | 0.419 | **0.114** / 0.380 (NES) | 0.214 | 0.113 / 0.500 (SSA) |

> 🔴 **The γ band is NOT small, as on `v6`.** The truncated-normal rung moves $\varphi$ little, but the panel and
> decay rungs reorder it (Spearman 0.51 / 0.42 at EU21) and move it by a median of about 0.1 — the size of a θ
> step. The frontier error structure is a first-order uncertainty in $\varphi$ and belongs beside θ in any φ band.

**Rank intervals** across the four rungs (`rankInterval`): EU21 max width **18.5 of 20**, 60%
separable; H12 max width 9.5 of 11, 45% separable. **A range over four fitted models, not a sampling
confidence interval.**

**Which sector binds is not robust.** In this offline reconstruction (GDP weights) power & industry binds in
6 / 4 / 8 / 12 of 20 EU21 regions across headline / truncated-normal / panel / decay, 14 of 20 regions change
binding sector, four are always buildings & transport (ENC, ESW, EWN, FRA) and two always power & industry (LAM,
SSA). At country level power & industry binds in 33 / 30 / 32 / 23 of 48, and 19 countries flip. In the coupled
anchor, with final-energy weights, power & industry has the larger rank in 11 of 21 EU21 regions and 6 of 12 H12
regions, with REF tied at the top of both sectors (`SCENARIOS.md` §6.2a). **Any sentence of the form "the
constraint binds on sector X" is a statement about one rung and one weighting.**

#### 3.4.2 The sector ordering in the estimation sample

On $E$ read straight out of `frontier.rds`, **power & industry is the more constrained sector in 33 of 48
countries at 2023** (median $E$: power & industry 0.704, buildings & transport 0.754).

**`projection.rds$implementability` is $S/10$, not $E$** (`computeImplementabilityFactor()` is
`index / indexMax`). Nothing in the coupling reads it; any offline figure built from that column is
on the prohibited measure (§7).

---

## 4. Dynamics: the ECM — a reported diagnostic, not in the coupling

> **ADR 0050: λ is not in the coupling.** The error-correction model stays in `pfm-temporal` as a
> reported finding (forecast skill, placebo). No λ enters any price; the only gap-closure
> assumption is the declared κ sensitivity (§5.2a).

### 4.1 Error-correction form

$$\Delta y^{*}_{c,t} = c_0 + \phi\,y^{*}_{c,t-1} + \boldsymbol\theta'\mathbf{x}_{c,t} + \epsilon,\qquad \phi<0,\qquad \lambda = -\phi$$

$$y^{*,\text{eq}} = \frac{c_0+\boldsymbol\theta'\mathbf{x}}{-\phi},\qquad
S^{\text{eq}} = M\cdot\operatorname{logit}^{-1}(y^{*,\text{eq}}),\qquad
t_{1/2} = \frac{\ln 0.5}{\ln(1-\lambda)}$$

> *In words:* each year a country would close a fixed fraction $\lambda$ of the distance between
> where its policy is and where its drivers say it should be.

### 4.2 ⚠️ The scale $\lambda$ lives on

The ECM is estimated on $y^{*}$, **not** on the 0–10 index: $\lambda$ is a gap-closure rate **on the
logit scale**, and applying it to natural-scale gaps is a scale error. Its attractor is
$S^{\text{eq}}$, **never** $S^{*}$.

### 4.3 Estimated speeds (`temporal-validation.rds`, `sector-speeds.rds`)

Protocol: fit on $t\le2015$, recursively forecast 2016–2023, score against persistence; $n = 384$
scored rows per sector.

| Sector | $\lambda$ | $t_{1/2}$ | ECM skill vs persistence | static-level skill | event AUC |
|---|---:|---:|---:|---:|---:|
| Power & industry | 0.109 | 6.0 y | −0.164 | −0.676 | 0.47 |
| Buildings & transport | 0.076 | 8.8 y | −0.787 | −0.599 | 0.41 |

| Four sectors | $\lambda$ | $t_{1/2}$ | skill |
|---|---:|---:|---:|
| Electricity | 0.117 | 5.6 y | **+0.087** |
| Industry | 0.166 | 3.8 y | −0.484 |
| Buildings | 0.109 | 6.0 y | −0.682 |
| Transport | 0.147 | 4.3 y | −0.986 |

> **Only electricity beats "assume nothing changes"**, and narrowly. Everything else is a
> descriptive rate, not a forecast. The static level forecast loses to persistence in both sectors —
> which is why this model delivers ceilings and rankings and never level paths. The out-of-sample correlation of
> the static forecast is 0.565 (power & industry) and 0.810 (buildings & transport), against 0.554 / 0.802 on `v6`
> (ADR 0060).

#### 4.3.1 Why λ cannot carry a coupling (ADR 0050)

λ does not beat persistence, and on annual data it was 1.7× (power & industry) and 4× (buildings & transport) the
smoothed value on `v6`, largely a smoothing artefact (0005 §2). In `v5` it set the speed of the projection and of
the price bound; removing it was most of the `v5` → `v6` change in the quantity headline (measured on `v6`:
`output/pfm/v6/phase1/offline-headline.rds`).

#### 4.3.2 What the λ audit found (measured on `v5`)

On `v5` a placebo battery on panels built with no adjustment by construction returned
λ̂ **0.291 [0.181, 0.419]** (power & industry) and **0.104 [0.062, 0.209]** (buildings & transport): the published
power & industry rate sat below its null and the buildings & transport rate inside it, and two-thirds of buildings
& transport countries had a non-positive own-country λ (`output/pfm/v5/lambda-explained/`). The pooled λ measures
the estimator's pull on a bounded, trending index, not a demonstrated political adjustment. Not re-run since.

---

## 5. The feasibility share $\varphi$

> **No index→price exchange rate (ADR 0041).** A bounded index times a constant is a bounded price
> cap that makes ambitious scenarios infeasible for an arithmetic reason rather than a political one.
> (The κ of ADR 0041 is unrelated to the erosion rate κ of §5.2a.)

### 5.1 Couple in relative terms

With $A_t$ the cost-optimal anchor and $P^{\text{ref}}$ the current-policy price:

$$\boxed{\;P^{*}_{r,t} = \min\Big(A_t,\; P^{\text{ref}}_{r,t} + \varphi_r(t)\,\max\big(A_t - P^{\text{ref}}_{r,t},\,0\big)\Big)\;}$$

> *In words:* the political constraint applies to the *extra* mitigation effort an ambitious
> pathway demands, not to the policy a region already has.

The current-policy scenario reproduces itself exactly, and $P^{*}\le A$ always — politics can only
slow, never accelerate (ADR 0024).

**This is the floor, not the whole price (ADR 0042).** $\varphi_r = \min_s \varphi_{r,s}$ is the
most-constrained sector, and $P^{*}$ is what every emission market pays as a minimum. **Each market
then carries its own sector's price on top:**

$$P^{m}_{r,t} = P^{*}_{r,t} + \underbrace{\max\!\big(P^{s(m)}_{r,t}-P^{*}_{r,t},\,0\big)}_{\text{markup}},
\qquad s(\text{ETS}) = \text{Bulk},\quad s(\text{ES}) = s(\text{other}) = \text{Diffuse}$$

`cm_pfmSectorMarkup = 1` (default) delivers this; `0` collapses to the pure `min`. See
`COUPLING.md` §11.

> **The invariant:** $P^{*} + \text{markup}(m)$ reproduces market $m$'s own sector price exactly.
> ⚠️ **Never quote "the carbon price" of a coupled run without naming the market**, and never add
> the markups together.

### 5.2 $\varphi(t)$: a fixed ranking with a moving strength (ADR 0049)

**Anchor.** Each country's distance below its ceiling is read **once**, at the last panel year
$t_a = 2023$, on the logit scale, and held:

$$q_{c,s} = \eta_{c,s,t_a} - y_{c,s,t_a},\qquad S_{c,s}(t) = M\,\operatorname{logit}^{-1}\!\big(\eta_{c,s}(t) - q_{c,s}\big)$$

The ceiling $\eta(t)$ moves with the scenario's drivers (REMIND's energy system, SSP income and
population, the harmonised institution projections; the weight $w$ held at its last value); the distance does
not. Uncovered countries take $y$ from the band rule (§5.4).

**Ranking.** Regional relative gaps at $t_a$, final-energy weighted, give

$$g_{r,s} = 1 - E_{r,s},\qquad \boxed{\;u_{r,s} = \frac{g_{r,s}-\min_r g}{\max_r g-\min_r g}\;}$$

computed once per Run-Group and staged as `phi-anchor.rds`. **Relative**, not absolute, because an
absolute gap ranks regions by how much they *could* do rather than how far they fall short.

**Strength.**

$$G_s(t) = \sum_r w_r\, g_{r,s}(t),\qquad \boxed{\;k_s(t) = \frac{G_s(t)}{G_s(t_0)}\;},\quad t_0 = 2025$$

so $k(t_0) = 1$ in every scenario. $k$ is endogenous: each PFM call recomputes it on the current
REMIND solution.

**Share.**

$$\boxed{\;\varphi_{r,s}(t) = \operatorname{clip}_{[0,1]}\big(1 - \theta\,k_s(t)\,u_{r,s}\big)\;}$$

θ means *severity at 2025*. A clip at 0 is flagged as a run defect; $k_s > 1/\theta$ is logged.

**Three disciplines:** a ranking, not levels; **the ranking is fixed at the anchor year**, only the
strength moves; $\varphi$ is a **parameter** refreshed between coupling iterations, never a decision
variable.

**The ranking on `v7`** (`output/remind-inputs/v7/phi-anchor.rds`, EU21). Russia & reforming countries (REF) are
the most constrained region in both sectors ($u$ = 1). China is no longer the floor in buildings & transport ($u$
0.35; `v6` 1.00), nor India in power & industry (0.51; `v6` 1.00); the Spearman correlation with the `v6` ranking is
0.92 in power & industry and 0.68 in buildings & transport (ADR 0060). At θ = 0.50 and $k = 1$ the delivered
share ranges from 0.50 (REF) to 0.99 (NEN) at EU21 and from 0.50 (REF) to 0.86 (CHA) at H12.

**What the strength does on the coupled energy system** (`coupling/strength-support.rds`, EU21, hold the price,
fading limit, θ = 0.50; `analysis/v6/couplingMechanism.R v7`). Power & industry $k$ is **0.707 / 0.667** in 2050 /
2100 (H12 0.705 / 0.664); buildings & transport 0.597 / 0.488 (H12 0.598 / 0.491). One driver group moving at a time
(the others held at 2025), in 2100:

| moving | power & industry $k_{2100}$ | buildings & transport $k_{2100}$ |
|---|---:|---:|
| the economic weight of fossil and clean-energy interests (actor power) | **0.42** | 0.56 |
| institutions | **1.36** | 0.85 |
| income and population | 0.95 | 1.01 |
| all (the run) | 0.67 | 0.49 |

**In power & industry the energy transition relaxes the constraint and the projected institutions tighten it**,
through power & industry institution terms that are not identified (§2.5). Holding the institutions at their anchor
values changes the hold-the-price result by −0.4 Gt CO₂ (EU21; `SCENARIOS.md`), so the effect on the coupled
quantity is small although the effect on $k$ is not. On `v6` the buildings & transport strength rose again after
mid-century (to 0.96 in 2060); on `v7` it falls throughout (ADR 0060).

**Out of training support** (the drivers with a guard range: income, population and institutions; SSP2
projections, so the same in every run of the selected specification): 5% of weighted drivers in 2030, 10% in
2050, 19% in 2100 in power & industry (5% / 9% / 16% in buildings & transport), reported with every $k(t)$. The
actor-power terms are reported separately, as the share of countries beyond the observed range (§2.3): the fade
after mid-century is read through the saturating clean-energy curve and the linear fossil terms on energy systems
beyond the observed range for most countries.

*Offline* (`phase1/strength.rds`, uncoupled REMIND bases) was **measured on `v6`** and is not re-run on `v7`.

#### 5.2a Options on the strength (each one a declared sensitivity; `COUPLING.md` §14)

| option | form | headline | sensitivity run |
|---|---|---|---|
| **κ, the erosion rate** | $k_s(t)\,(1-\kappa)^{t-2025}$ | κ = 0 | 0.027 central (half-life 25 y), 0.02, 0.05; fixed 2026-10-08 before any run (ADR 0050 decision 5); `v7` wave 2 |
| growing limit | $k$ rising at a declared rate (ADR 0057) | none | `v7` wave 2 |
| hold year | drivers held after 2060 | none (to 2100) | `pfmPhiHoldYear = 2060` |
| constant limit | hold $E$ instead of $q$ ($k \approx 1$) | distance kept | `pfmPhiHold = ratio` |
| regional strength | $k_{r,s}(t)$ per region | common | `pfmPhiStrength = regional` |
| ordering | $u$ uniform, permuted or reversed | the model's | `pfmPhiOrdering` |
| institutions | held at their anchor values | harmonised projection | `pfmInstitutions = hold` |

### 5.3 $\theta$ is declared and swept, not estimated

No historical experiment assigned carbon prices by political gap, so $\theta$ is not identified.

| $\theta$ | role |
|---:|---|
| **0** | uncoupled no-politics reference — every φ = 1 (`-PFMgate-v7`, `-PFMgateBfix-v7`) |
| **0.325** | declared low point of the sweep |
| **0.50** | **declared central value** (`cm_pfmTheta`); every headline uses it |
| **0.675** | declared high point, symmetric about 0.50 |

**The efficiency analogy, and why it anchors nothing.** Solving $1-\theta\bar u=\bar E$ for the median
region (`coupling-summary.rds$anchorDerivation`, region resolution, 2025, $n$ = 21) gives θ = **0.708**
(power & industry: median $E$ 0.748, median $u$ 0.356) and **0.498** (buildings & transport: 0.768, 0.466). Both
are admissible, but the analogy is resolution-dependent ($u$ is normalised over whatever units the frame holds;
on `v6` it gave 0.372 / 0.468) and **no θ value may be called "the efficiency anchor"**.

**Coupled**, hold the price adds +59.4 / +98.8 / +144.8 Gt CO₂ by 2100 at θ = 0.325 / 0.50 / 0.675 (EU21), 212 Gt
per unit θ; H12 +55.2 / +87.9 / +125.6, 185 Gt per unit θ (`SCENARIOS.md` §4).

#### 5.3.0 $\varphi$ is also specification-dependent

The specification is as undetermined as θ: the selected specification wins **1%** of bootstrap resamples (**24%**
conditional on sanity-eligible winners, §6). The conditional winners are all weighted X-1791 or X-1860
specifications with both fossil terms, and they split about **57 / 43** between the clean-energy-only family
(`satInn`, selected) and the both-saturate family (`satAP`).

**Measured on `v6`** (`v6` `phase1/spec-band.rds`, `SCENARIOS-v6` §4.9): the two families gave a power & industry
$k_{2050}$ of 0.63–0.90 (both-saturate) and 0.86–1.22 (clean-energy-only) on the uncoupled 1000 Gt energy system;
coupled, the clean-energy-only `X-2079 satInn` gave +107.5 Gt against +118.2 for the selected both-saturate spec;
saturation 0.5× / 2× +115.2 / +130.0; annual data +164.4. No `v7` specification band has been run.

> **The discipline this implies.** $\varphi$ is a property of a region **given a specification, a
> frontier error structure and a declared severity**, never a measured property of the region.
> Report it as a declared choice with a disclosed band.

#### 5.3.1 Routes to θ other than declaring it

| route | what it needs | what it buys | verdict |
|---|---|---|---|
| **1. Declare + sweep** *(selected)* | nothing | honesty; θ becomes a scenario axis | **selected**; the sweep *is* the deliverable |
| **2. Efficiency analogy** | median $E$ and median $u$ | one point | admissible, resolution-dependent (§5.3) |
| **3. Price–efficiency elasticity** | a carbon-price panel + the stringency panel | an *empirical* θ range | the most promising; open |
| **4. Calibration** | observed regional price dispersion | θ that best reproduces history | feasible, circular risk |
| **5. Partial identification (bounds)** | revealed-preference restrictions | an interval | **empty on `v7`**, for the multiplicative cap only (below) |
| **6. Expert elicitation** | a structured protocol | a documented prior | out of scope |

**Route 5 — bounds** (`analysis/checks/computeThetaBounds.R`, `analysis/checks/efficiencyRatioBand.R v7`
→ `coupling/theta-bounds.rds`, `efficiency-ratio-band.rds`). These bound θ for a **multiplicative**
level cap, $\varphi_r P^{\circ}$, read on the offline bound's price paths.

*Upper bound — revealed preference.* A region cannot credibly be modelled below the price it has
already legislated: $\theta \le (1-P^{\text{ref}}_{r,t}/P^{\circ}_{r,t})/u_r$, minimised over
region-years with $P^{\circ}>P^{\text{ref}}$ and $t\ge2030$: $\theta_{\max} = $ **0.063**, binding at
ECE in 2030. At θ = 0.50 eight regions violate it (DEU, ECE, ECS, ENC, ESC, ESW, EWN, FRA).

*Lower bound — resolution.* $u$ is min–max normalised, so the spread θ induces in $\varphi$ is exactly
θ; below the width at which $E$ itself is resolved the differentiation is inside its own noise. A CI on
$\eta_F$ maps to $E$ by transforming the endpoints. Median 95% CI width on $E$ at 2023: ML band 0.068
(power & industry) / 0.054 (buildings & transport); **cluster-scaled 0.124 / 0.119**, pooled 0.119 (design effect
1.93× / 2.20×).

$$\boxed{\;\theta \in [0.119,\ 0.063]\;=\;\varnothing\;}\qquad\text{empty on `v7`, as on `v5` (on `v6` it was }[0.134,\ 0.164])$$

> **What it says, and what it does not.** Every declared θ is above the upper bound: **the multiplicative level cap
> is incompatible with revealed preference at any θ that differentiates regions beyond the noise of $E$.** The
> selected cap is **relative** (§5.1) — it caps the increment over current policy, so $P^{*}\ge P^{\text{ref}}$ by
> construction wherever $A \ge P^{\text{ref}}$ — and the revealed-preference bound does not bind it. The
> resolution floor (0.119) does apply to the selected share: every declared θ is above it.

#### 5.3.2 Sources of uncertainty in $\varphi$, and where each is reported

| source | what varies | size | reported in |
|---|---|---|---|
| **1. Severity θ** | declared, 0.325 / 0.50 / 0.675 | hold the price +59 to +145 Gt (EU21) | **main text** |
| **2. How long the limit lasts** (erosion κ; growing / constant limit) | κ 0.02 / 0.027 / 0.05; growing; constant | constant limit +167.6 Gt (EU21) / +145.3 (H12) against +98.8 / +87.9; the κ ladder and the growing limit are `v7` wave 2 | **main text** (the largest single sensitivity) |
| 3. Specification family | clean-energy-only (selected) vs both-saturate | measured on `v6` only (§5.3.0) | SI |
| 4. Curve shape | half-saturation 0.5× / 2× | measured on `v6` only | SI |
| 5. Frontier error structure | four frontier variants | median \|Δφ\| up to 0.114, Spearman down to 0.42 (EU21, offline, §3.4.1) | SI — rank intervals |
| 6. Out-of-coverage assignment | donor / low band / median; nearest donors; USA | measured on `v6`: hold the price 110–155 Gt | SI (the widest data-side band) |
| 7. Institution projections | harmonised vs held | hold the price −0.4 Gt (EU21), +0.7 (H12); $k$ moves a lot (§5.2) | main text (fixed-institutions variants) |
| 8. Energy-system feedback | φ recomputed on the live energy system | power & industry $k_{2050}$ 0.71 on the coupled pathway | **main text** as a result, not an uncertainty |
| 9. Theory-gate thresholds | H3 0.70 / 0.80; $p$ 0.10 | pending (`v7-h3070`, `v7-h3080`, `v7-p10`) | SI |

**The reporting rule.** The main text carries θ and κ as declared bands and treats $\varphi$ as
**ordinal**. Any sentence about **which sector binds** carries source 5's caveat.

### 5.4 Countries the sample never saw — the band rule

Uncovered countries keep their **own** ceiling and inherit only a relative gap,
$\hat S = \hat E\cdot S^{*}_{\text{own}}$. Placement uses the model's own signed linear index
$\ell_i = \sum_k\beta_k x_{ik}$:

| branch | assigned $E$ | when |
|---|---|---|
| **donor** | inverse-distance blend of the $k=3$ nearest covered countries | a match exists within the covered sample's own nearest-neighbour spread |
| **lowBand** | lower quartile of covered $E$ | $\ell_i$ below every covered country's — extrapolation past the low end of support |
| **median** | median of covered $E$ | $\ell_i$ inside or above the covered range — unmatched for structural reasons |

Distance is in the model's own metric over the nine base drivers, $w_k = |\beta_k|/\sum|\beta|$.

`v7` assignment (`donor-assignment-band-<sector>.rds`, 200 uncovered countries per sector):

| | donor | lowBand | median |
|---|---:|---:|---:|
| Power & industry | 46 | 54 | **100** |
| Buildings & transport | 37 | **108** | 55 |

> ⚠️ **Most uncovered countries are placed by a quantile rule, not a donor**: 154 of 200 in power & industry and
> 163 in buildings & transport. On `v6` the coupled sensitivity runs (all-median, all-low, nearest donors always,
> USA donor and USA low) moved the hold-the-price headline from +110 to +155 Gt (`SCENARIOS-v6` §4.9); they are not
> re-run on `v7`. Disclose it with any coverage figure.

**One documented override:** `basisOverride = c(USA = "median")`. US federal policy spans states with
world-leading regulation and states with almost none; donor transfer would assign it a polity it is
not. **The USA must be reported as a range** (on `v6`: USA donor +117.4, USA low +134.8 Gt).

**Provenance travels with the number.** Each region reports
`shareObserved / shareDonor / shareLowBand / shareMedian`.

### 5.5 Aggregation weights

Countries aggregate to IAM regions by **final energy**, the closest available correlate of what a
carbon price acts on:

$$w_i = \mathrm{FE}_i(t_{\text{base}})\cdot\frac{\mathrm{GDP}^{\text{ssp}}_i(t_w)}{\mathrm{GDP}^{\text{ssp}}_i(t_{\text{base}})},\qquad t_w = 2025$$

Only relative within-region shares matter, so uniform growth cancels and the SSP enters through
differential growth only. The anchor's weights are reused unless the run's SSP or weight year
differs. `iterativePFM()` calls `pfmAssertSizeWeights()`, which fails on any weight vector with
max/median < 20 — the signature of accidentally equal weights (`PITFALLS.md` §20).

### 5.6 The bind modes and closures — how $\varphi$ becomes a price

Notation: $A_t$ the global anchor path, $P^{\text{ref}}$ the current-policy (NPi) price.

**Mode R — $\varphi$ bounds the price *ratio*** (`cm_pfmBindMode = 1`): $P_{t,r} = \varphi_r(t)\,A_t$,
each market its own path times the anchor. The budget is always met. Not in the `v7` batch.

**Mode L — $\varphi$ caps the increment** (`cm_pfmBindMode = 2`): the boxed form of §5.1, with
$\varphi(t)$ and **no speed limit**. The budget may become unreachable — **that is the finding, not a
bug.** $A$ must come from a path the cap cannot touch: reading it from the run's own capped price
makes the recursion a contraction onto $P^{\text{ref}}$ within a few calls (`SCENARIOS.md` §6.4).

**Mode M** (mild progression) is **retired** (ADR 0050): its mechanism was λ.

**Closures — mode L**, when the political bound and the budget cannot both hold:

| closure | mechanism | the headline it supports | `v7` rows |
|---|---|---|---|
| **hold the price** | pin the anchor to the θ = 0 budget-holding run (`cm_pfmAnchorFromGdx`), budget forcing off | *political feasibility adds $X$ Gt CO₂ to the 1000 Gt pathway by 2100* | `-PFMlevelBfix…` |
| **hold the budget** | keep the budget (`cm_iterative_target_adj = 9`), rebuild the cap every iteration from the live anchor and that period's share (`cm_pfmBoundRebuild = 1`) | *the budget holds; the price rises and abatement moves* | `-PFMlevelC…` |
| delay | allow the budget to be met later | *politics delays the price path by $N$ years* | never run |

**What the `v7` batch shows** (θ = 0.50; `SCENARIOS.md` §4):

| | EU21 | H12 |
|---|---:|---:|
| **hold the price**: Δ cumulative CO₂ 2020–2100 vs `-PFMgateBfix-v7` | **+98.8 Gt** | **+87.9 Gt** |
| hold the price across θ 0.325 / 0.675 | +59.4 / +144.8 | +55.2 / +125.6 |
| hold the price, constant limit | +167.6 | +145.3 |
| **hold the budget**: cumulative CO₂ 2020–2100, every run | 999.3–1001.1 Gt | 997.6–1001.7 Gt |
| hold the budget: anchor 2050 vs θ = 0 | ×1.21 | ×1.19 |
| hold the budget: abatement moved between regions, 2020–2100 | 17.1 Gt CO₂eq | 18.4 Gt CO₂eq |

---

## 6. Selection stability (`selection-bootstrap.rds`, 200 resamples)

Selected specification `X-1791 … satInn iw:fexp`. Top-**40** pool, 200 resamples; **35** pool members are rejected
by the full-sample sanity walk and are never eligible.

> ⚠️ **A raw selection frequency is not evidence.** The menu offers several accountability options;
> a selector choosing at random takes *some* accountability most of the time. Read every frequency
> against the menu and the pool.

| element | among winners | conditional on sanity-eligible winners |
|---|---:|---:|
| Government Effectiveness (`WGIge`) | **100%** | 100% |
| Rule of Law (`RoL`) *(selected)* | **100%** | 100% |
| channel set `WGIge|RoL|VerAcc` *(selected)* | **47.5%** | **72.5%** |
| channel set `WGIge|RoL|HorAcc` | 42.0% | 27.5% |
| channel sets with Overall / Diagonal accountability | 7.4% / 3.1% | — |
| actor power `bothIncAP` *(selected)* | **100%** | 100% |

**The selected specification.** Wins **1%** of resamples (**24%** conditional on the walk's rejections; 44% of the
resamples that yield an admissible winner, `specFreqConditional`; `v6`: 15% on the first measure). The other
conditional winners: `X-1791 … satAP iw:fexp` 16.5%, `X-1860 WGIge|RoL|HorAcc … satAP iw:fexp@accRoL` 14.7%,
`X-1860 … satInn iw:fexp` 12.8%, `X-1791 … satAP iw:poly` (electoral democracy as the weight) 11.9%. **Every
conditional winner is weighted.**

> ✅ **State capability and rule of law belong**: 100% of winners. ✅ **Fossil interests in both share and
> per-capita form belong**: `bothIncAP` 100%. ✅ **A democracy weight on the interactions belongs**: every
> conditional winner carries one.
>
> 🔴 **Which accountability channel, which democracy index and which actor-power transform are not identified.**
> The selected channel set is the conditional majority (72.5%) but not the raw one; the transform splits about
> 57 / 43.

> **What may be claimed.** *State capability, rule of law, the two fossil terms and a democracy weight belong.*
> **Neither the channel set nor the specification is uniquely selected**; the selected specification is a 1% (24%
> conditional) winner. Any sentence asserting the model *is* `X-1791` rather than *was run at* `X-1791` is false.

---

## 7. What must NOT be done

Validated exclusions — each rejected by this project's own tests, not by preference:

| Prohibited | Why |
|---|---|
| Projected policy-level paths as IAM inputs | Static level forecasts lose to persistence (§4.3) |
| The $S/10$ implementability multiplier | Compares countries to a universal maximum; use $E = S/S^{*}$ (§3.2) |
| Point frontier ceilings or named slack rankings | Slack ranks not robust across rungs in either sector; use tiers (§3.4) |
| $S^{*}$ as an ECM attractor; λ as a coupling input | λ is a diagnostic only (ADR 0050, §4) |
| Describing λ as a measured political adjustment speed | It does not beat persistence and sat inside its placebo null (§4.3) |
| Ceilings for out-of-coverage countries | 200 of 248 projected countries are outside the sample; they receive a transferred *relative* gap only (§5.4) |
| Any index→price exchange rate | Retired (ADR 0041) |
| An unqualified "carbon price" for a coupled run | ETS and ES face different prices; name the market (§5.1) |
| Adding $P^{*}$ and a markup to get "the" price | A floor and a market-specific increment |
| Calling any $\theta$ *the efficiency anchor* | θ is declared (§5.3) |
| Presenting κ as an estimate | Declared, like θ (ADR 0050) |
| Quoting a country-resolution anchor for the coupling | $u$ is normalised over regions (§5.3) |
| Comparing mean-regression and frontier coefficients as refits of each other | Different estimands (§2.2) |
| Quoting frontier $p$-values as clustered inference | ML SEs; no clustered sandwich for SFA (§3.3) |
| A power & industry institution main effect as a finding | Not identified: insignificant in the mean regression, opposite signs on the frontier (§2.5, §3.3) |
| One fossil coefficient without the other | The share and per-person terms pull in opposite directions; only the pair is interpretable (§2.3) |
| Theory-gate $p$-values as unconditional inference | The selection requires H1–H2 (§2.4a, ADR 0059) |
| Scenario results late in the century without their out-of-support share | A reporting duty since ADR 0052: 19% of guarded drivers out of support by 2100, the energy system beyond the observed range for most countries by 2050 (§2.3, §5.2) |
| Any result after 2100 in paper-facing text | Results are reported to 2100 (author, 2026-10-25) |
| Ranking estimators on AIC/BIC across families | Different response scales and quasi-likelihoods |
| Calling the feedback causal | The IV is an endogeneity-confirmed null (§8.1) |

---

## 8. Open scientific questions

**8.1 Causal status of the feedback.** The shift-share IV (base-year fossil interests × leave-one-out
global VRE diffusion) **confirms endogeneity** but **identifies no causal fossil effect**
(`iv.rds`, $n = 1152$):

| rung | Fossil dependence $\hat\beta$ (2SLS) | SE | $p$ | first-stage $F$ | Wu–Hausman $p$ |
|---|---:|---:|---:|---:|---:|
| Power & industry, with trend | 15.9 | **40.9** | .70 | 3.4 | 4e−33 |
| Power & industry, no trend | 10.3 | 49.0 | .83 | 10.5 | 8e−92 |
| Buildings & transport, with trend | −3.1 | 3.5 | .37 | 8.8 | 2e−22 |
| Buildings & transport, no trend | 97.0 | **2467** | .97 | 4.4 | 2e−94 |

Three of four rungs are weakly instrumented ($F$ < 10), and no estimate is distinguishable from zero. **Do not
report the point estimates.** Report that endogeneity is confirmed at $p < 10^{-21}$ in every rung and
that the instrument cannot identify the effect — *we can show the relationship is endogenous; we
cannot show what it is.* Label the feedback **conditional scenario accounting**, and **do not write
"causes" anywhere near the loop.**

**8.2 The ceiling-feedback sign.** The feedback is live in both sectors: on the coupled 1000 Gt pathway the power &
industry strength falls to 0.71 by 2050 and buildings & transport to 0.60 (§5.2), and the median covered ceiling
rises (to 1.15 / 1.26 of its 2025 value by 2100). The power & industry direction rests on how fossil dependence
behaves below anything observed — linearly on `v7` (§2.3) — and on power & industry institution terms that are not
identified. It is not causal (§8.1).

**8.3 The exposure confound.** `Fossil × GovEff` (share) is **positive** where theory expects
negative — +0.131 in the power & industry mean regression (not significant), +0.373 on the power & industry
frontier, positive in six of seven estimators — and power & industry fossil interests per person is positive and
significant (+0.518). Large, capable fossil economies also regulate more; the model cannot tell exposure from
resistance. A fossil-rents reader would be needed and none exists.

**8.4 The historical-replay gate — passes, and cannot discriminate.** Running the coupled system
over the historical panel (seed year 2000) must reproduce observed stringency at least as well as
the uncoupled ECM (`historical-replay.rds`, `$pass = TRUE`):

| Sector | RMSE coupled | RMSE ECM | skill vs ECM | skill vs persistence | ceiling binds |
|---|---:|---:|---:|---:|---:|
| Power & industry | 0.808 | 0.808 | +0.0005 | +0.730 | **0.45%** of rows |
| Buildings & transport | 0.520 | 0.522 | +0.0048 | +0.768 | 2.17% of rows |

> **Read the margin before the verdict.** The ceiling binds in under 3% of rows, so the coupled and
> uncoupled systems are almost the same model on history and the "pass" is a tie. In the coupled `v7`
> runs the hold-the-price cap binds in 99% of region-periods — a regime this gate says nothing about.

**Re-scoped to where it can discriminate** (`analysis/checks/replayRescoped.R v7`): on the rows where
the coupled path differs from the uncoupled one — 67 power & industry country-years in 4 countries (6.1%) and 157
buildings & transport in 8 (14.2%) — RMSE is 0.503 against 0.514 (skill **+0.021**) in power & industry and 0.472
against 0.491 (skill **+0.039**) in buildings & transport. Where the ceiling acts on history it improves the fit a
little in both sectors (`v6`: +0.036 / +0.009). Quote this, not the diluted full-sample figure.

**8.5 The time trend does most of the explanatory work.**

| | Power & industry | Buildings & transport |
|---|---:|---:|
| $\hat\beta$ on $T(t)$ per SD, frontier | **0.901** | **0.497** |
| $\hat\beta$ on $T(t)$ per SD, mean regression (§2.5) | 1.300 | 0.621 |
| trend share of linear-predictor variance (§2.4) | **0.685** | **0.535** |

**So is the model usable?** Yes, with the framing kept ordinal:

1. **$\varphi$ is a cross-sectional ranking and the trend is common to everyone.** $T(t)$ has no
   $r$ subscript; it shifts every region's ceiling together and largely cancels out of $u_r$.
2. **The trend cannot leak into projections** — it is frozen at the last historical year, so the
   strength $k(t)$ moves only through the drivers.
3. **Dropping it is worse**: on `v6` the no-trend frontier was 363 logLik below the selected one in power & industry
   and 344 in buildings & transport, at the γ boundary (§2.3.1).

**What it costs.** In power & industry two-thirds of the linear predictor's variance is secular drift the
model does not attribute to institutions or actor power. The defensible claim is about
**cross-sectional ordering** and **how the drivers move the ceilings**, not about how the ceiling got
where it is. Nothing here should be phrased as "institutions caused the ceiling to rise".

---

## 9. Artifact map

All in `output/pfm/v7/`.

| Quantity | File | Path within |
|---|---|---|
| Selected specification | `selected-models-pfm.yml` | — |
| Every estimation number in this document | `doc-facts/facts.json` | written by `analysis/checks/docFacts.R v7` |
| ΔR²(theory), trend share, VIF, tier, maximin, gates, sanity walk | `sweep.rds`, `sanity-pool.rds` | `$results`, `$maximin`, `$theory`, `$sanity` |
| Theory gate: screen, calibration | `theory-term-screen.rds`, `theory-gate-calibration.rds`, `inference-screen.rds` | — |
| Edge-of-data gate | `edge-of-data.rds`, `edge-gate-preview.rds` | — |
| Sharing cost, per-tier winners | `selection-variants.rds` | `$perSector`, `$winners` |
| Selection stability; `v6`/`v7` comparison | `selection-bootstrap.rds`, `selection-compare.rds`, `v6v7-reproduction.rds` | — |
| Mean regression: coefficients, wild-cluster $p$, AMEs | `inference.rds` | `$bySector$<s>$table` |
| Sign agreement across 7 estimators | `estimator-agreement.rds` | `$bySector$<s>$agreement` |
| Leave-one-country-out influence | `influence.rds` | `$bySector$<s>$byTerm` |
| Shift-share IV | `iv.rds` | `$bySector$<s>.<variant>` |
| Frontier $\beta_F$, $\gamma$, LR, covariance check, rungs | `frontier.rds` | `$bySector$<s>$coefTable`, `$gamma`, `$lr`, `$vcovCheck`, `$robustness` |
| Rungs propagated to $E$ and φ | `frontier-rung-phi.rds` | `$minRule`, `$countryBind` |
| Ceilings, gaps, efficiency per country-year | `frontier.rds` | `$bySector$<s>$scores` |
| The anchor: $q$, $u$, weights, frontier design | `phi-anchor.rds` (staged in `output/remind-inputs/v7/`) | step `pfm-anchor` |
| λ, half-life, skill (2 and 4 sectors) — diagnostic | `temporal-validation.rds`, `sector-speeds.rds` | — |
| Historical-replay gate | `historical-replay.rds` | `$pass`, `$bySector$<s>$metrics` |
| Country projections | `projection.rds`, `projections/<scenario>.rds` | — |
| Donor / band assignment | `coverage/`, `donor-assignment-band-<sector>.rds` | — |
| Offline bound, efficiency analogy, θ bounds | `coupling/coupling-summary.rds`, `coupling/theta-bounds.rds`, `efficiency-ratio-band.rds` | `$anchorDerivation` |
| Coupled runs: prices, φ per market, convergence, run QC | `coupling/coupled-runs.rds` | `$runs`, `$prices`, `$phi`, `$convergence` |
| Strength on the coupled runs: support, decomposition, beyond-range shares | `coupling/strength-support.rds` | `$support`, `$decomposition`, `$beyond` |
| Every coupled number quoted in the docs | `coupling/coupled-facts.json`, `coupled-costs.json`, `budget-peak.rds`, `gate-ref-compare.rds`, `emissions-2100.rds` | written by `runCoupledStage.R v7` and `analysis/checks/` |

**Code entry points.** `estimatePolicyStringencyModel()`, `computeFeasibilityFrontier()`,
`computeAnchorGap()`, `computeStrengthPath()`, `pfmV6Shares()`, `pfmV6CouplingDefaults()`,
`computeDonorAssignment()`, `runPFMTemporalValidation()`, `computeWildClusterBootstrap()`,
`projectFeasiblePath()`, `exportFeasibilityBound()`, `iterativePFM()`; the gates `.pfmEdgeGate()`,
`.pfmTheoryScreen()`, `.pfmTheoryCoherence()`; the weight `.pfmIwParse()`, `.pfmIwFactor()`.
