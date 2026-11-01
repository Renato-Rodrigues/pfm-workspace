# The Political Feasibility Model — definition and mathematics

*The canonical mathematical statement of the selected PFM. A reader should be able to
implement the model, and evaluate it by hand, from this document alone.*

**Provenance.** Every number is Run-Group **`v8`** unless it says otherwise. Selected specification
**`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP iw:fexp fos5`** (ADR 0062), with fossil
rents setting the size of the buildings & transport slack (ADR 0061), country resolution, n = 1104 = 48 countries ×
23 years (2001–2023; Estonia excluded, ADR 0058), IEA 2025 edition, five-year moving average, geothermal in the
clean-baseload control (ADR 0053), trend logistic (midpoint 2010, steepness 0.20, standardized, frozen at 2023).
Estimation-side numbers are collected by `Rscript analysis/checks/docFacts.R v8` into
`output/pfm/v8/doc-facts/facts.json`. Re-read from there, never from this page.

> **What `v8` changes against `v7`** (design note 0009; ADRs 0061–0063): (1) the two fossil terms are bounded below
> at the training 5th percentile (`fos5`); (2) every actor-power term saturates (`satAP`; `v7`: clean energy only);
> (3) in buildings & transport the World Bank fossil rents set the size of the slack, not the ceiling (§3.1a);
> (4) countries without policy data take the covered median share of their ceiling (§5.4); (5) each region's
> constraint fades with its own gap, the **regional strength** (§5.2); (6) institution series close 0.6% of their gap
> to the best observed value a year (ADR 0063). The channels, the weight and the selection rule are `v7`'s.

> **Coupled results** are from the `v8` REMIND 3.7.1 batch (52 coupled runs, EU21 and H12) and the two
> shrinking-future chains (EU21), in `output/pfm/v8/coupling/coupled-facts.json` and `shrinking-future.rds`. This
> document quotes only what the model definition needs; the full reading is `SCENARIOS.md`. **Results are reported to
> 2100 and no later.**

> **Analyses not re-run on `v8`** are labelled "measured on `v7`" (or `v6`, `v5`) where they appear: the trend-shape
> grid (§2.3.1), the ranking-uncertainty test (§5.4), the offline strength and specification band (`phase1/`, §5.3.0),
> the theory-gate threshold sensitivities (§2.4a) and the λ placebo audit (§4.3.2). Re-run on `v8` on 2026-11-01: the
> strength decomposition and support shares (§2.3, §5.2), the edge-of-data cap test (§2.4a), the θ bounds (§5.3.1),
> the re-scoped replay (§8.4), H3 (`theory-gate-calibration.rds`), the net effects on the coupled panel, the coverage
> test (§5.4), the κ reference (§5.2a) and the coefficient band (§5.3.2). Their conclusions are about the method; their numbers are not `v8` numbers. The `v7` version of this
> document is `../_archive/_wip/2026-10-31/docs/MODEL-v7.md` (the `v6` version: `../_archive/_wip/2026-10-25/docs/MODEL-v6.md`).

**Scope.** The model *as selected*. How the spec was selected is ADR 0036/0039/0045/0046/0052, the edge-of-data
gate design note 0007 §5, the theory gate ADR 0059, the `v8` changes ADR 0061–0063; the formulation of the share is ADR
0049, 0050, 0054 and 0062. The REMIND interface is `COUPLING.md` (§14, §14.1 for the sequential runs). Traps are
`PITFALLS.md`.

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
| $A^{\text{ic}}$ | Fossil dependence, **share** — the dependence / lock-in channel, bounded below at the training 5th percentile, saturating | standardized |
| $A^{\text{ic,pc}}$ | Fossil interests **per person** = share × primary energy per capita — the scale channel, bounded and saturating like $A^{\text{ic}}$ | standardized |
| $z$ | fossil rents (World Bank oil, gas and coal rents), $\log(1 + \%\text{ of GDP})$ — the size of the buildings & transport slack (§3.1a) | standardized |
| $G$ | Government Effectiveness (WGI) — state capability | standardized |
| $R$ | Rule of Law (V-Dem) | standardized |
| $V$ | Vertical Accountability (V-Dem) — electoral accountability of rulers to citizens | standardized |
| $w$ | **interaction weight**: V-Dem freedom of expression and alternative information (`v2x_freexp_altinf`) — new in `v7` | $[0,1]$, unstandardized |
| $T(t)$ | logistic time trend, frozen at the last historical year | standardized |
| $v, u$ | symmetric noise $N(0,\sigma_v^2)$; one-sided political slack $N^{+}(0,\sigma_u^2)$, with $\log\sigma_u = c + \omega z$ in buildings & transport | — |
| $\gamma$ | slack variance share $\sigma_u^2/\sigma^2$ (buildings & transport: at average rents) | $[0,1]$ |
| $S^{*}$ | **feasibility frontier** (ceiling) | $[0,10]$ |
| $E = S/S^{*}$ | efficiency ratio — the implementability factor | $(0,1]$ |
| $q_{c,s}$ | anchored distance below the ceiling, on the logit scale, $\eta - y$ at $t_a$ | $\geq 0$ |
| $g_{r,s}$ | regional relative gap $1 - E$ | $[0,1]$ |
| $u_{r,s}$ | regional **ranking**, min–max of $g$ at $t_a$ | $[0,1]$ |
| $k_{r,s}(t)$ | **strength**: the region's own gap relative to $t_0$ (regional, central from `v8`); $k_s(t)$ the world's weighted mean gap (common, the sensitivity) | $k(t_0) = 1$ |
| $\varphi_{r,s}(t)$ | **feasibility share** — fraction of the extra effort beyond current policy a region carries | $[0,1]$ |
| $t_s$, $\varphi^{(t_s)}$ | start year of a step of a **sequential (shrinking-future) run**, and its windowed share (§5.6a; COUPLING.md writes τ) | — |
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

`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP iw:fexp fos5`, fitted separately per
sector on an identical design (the Shared Specification rule; selecting each sector alone gives power & industry a
worse-fitting specification and buildings & transport one whose fit comes from region effects and whose fossil and
institution effects are unstable, design note 0009 §20):

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
trend: **19 slope terms**. **No lagged outcome, no Mundlak, levels transform; every actor-power term saturates, and
the two fossil terms are first bounded below at the training 5th percentile** (`satAP`, `fos5`, §2.3). In buildings &
transport the slack's size depends on fossil rents (§3.1a); the ceiling $\eta$ does not contain them. The drivers and
the weight enter at $t-1$; the lag counts
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
| **frontier** | half-normal SFA on $y^{*}$; buildings & transport with a heteroscedastic slack (Caudill, Ford & Gropper 1995) | conditional **maximum attainable** $y^{*}$ | ML standard errors (no clustered sandwich exists for the SFA likelihood), checked by `vcovCheck` | `frontier.rds` (§3.3) |

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

**The fossil bound (`fos5`; design note 0009 §7.1, ADR 0062).** Before saturation and standardization, each fossil
term is bounded below at its training 5th percentile: $A^{\text{ic}} \leftarrow \max(A^{\text{ic}}, a_{0.05})$, the same
bound frozen in `driverScaling` and applied to every scenario panel. A country whose fossil share falls below anything
but the cleanest twentieth of the sample is read at that edge, not extrapolated beyond it. It removes part of the
Iceland artefact (§3.4.3) and improves the fit in both sectors.

**Saturation (`satAP`, every actor-power term; ADR 0040, 0052, 0062).** Each actor-power term enters as
$x/(x+\bar x)$, with $\bar x$ the training median, before standardization: the curve is steepest at zero and
flattens above the median, so no share extrapolates linearly into a range no country has occupied. `v7` saturated
clean energy only (`satInn`); with the bound, that form reaches power & industry γ 0.999004, above the declared gate
(ADR 0046), and the selection walk moves to `satAP` (ADR 0062). The edge-of-data gate (§2.4a) checks that the low end
does not move the projected ceilings by more than a declared amount. **On the coupled 1000 Gt pathway** (hold the
price, EU21, final-energy-weighted share of countries; `analysis/v6/couplingMechanism.R v8` → `coupling/strength-support.rds`,
2026-11-01): clean-energy build-out is above anything observed for 89% of countries in 2050 and 94% in 2100 in power &
industry (97% / 99% in buildings & transport); fossil dependence is below the observed minimum for 79% in 2050 and 92%
in 2100 in power & industry (71% / 96% in buildings & transport), fossil interests per person for 22% / 60% (22% /
27%). There the bound holds the fossil terms at the 5th percentile, so **by mid-century the interests stop moving the
ceiling for most of the world's final energy** (`v7`, unbounded and linear: fossil dependence below the range for 1% in
2050 and 50% in 2100).

**The `bothIncAP` form (ADR 0044, ADR 0045).** Fossil interests enter twice — as a share (how
dependent the energy system is) and per capita (how large the fossil interest is) — which
nests both the share-only and per-capita-only forms. Clean-energy build-out enters as a share.

> 🔴 **The two fossil channels pull in OPPOSITE directions, and only the pair is
> interpretable.** On the frontier the power & industry share is **−0.813** and the per-capita term **+0.491**;
> in buildings & transport −0.168 and +0.162 (§3.3). Their interactions with the institutions differ in sign too.
> Read at each country's own values, the net effect of fossil dependence keeps its sign in every country-year in power
> & industry and in 99% in buildings & transport (`net-effects.rds`; design note 0009 §19, figure `net-effects`).
> A sentence that names one channel and not the other inverts the sign of the other half. The
> channels are not orthogonal (share × energy per capita), so this is a decomposition, not two
> independent findings. The paper reports the fossil effect's dependence on an institution, not one coefficient
> (ADR 0060).

**The split form is load-bearing.** A composite $A = A^{\text{in}} - A^{\text{ic}}$ makes
projections *scenario-blind* under the extrapolation guard. Splitting keeps the feedback channel
alive. **Never revert.**

**Institutional channels.** $G$ = WGI Government Effectiveness; $R$ = V-Dem Rule of Law (in 100% of bootstrap
winners, §6); $V$ = V-Dem Vertical Accountability. The institution series are harmonised to the anchor year in
every scenario (ADR 0051) and projected by **gap closure** (ADR 0063): every country closes 0.6% of its distance to the
best observed value a year from its 2023 value,
$$x_c(t) = 1 - (1 - x_{c,2023})\,e^{-0.006\,(t-2023)},$$
the pace of Andrijevic et al.'s SSP2 convergence and within V-Dem's own history; the weight $w$ moves to the higher of
its 2023 value and its 2014–2023 mean by 2040 and is held. **The institution main effects are not identified in power
& industry** (§2.5, §3.3), nor in the poorest countries with very low fossil energy per person (ADR 0060). Read jointly
(the three moved together), their net effect is negative in power & industry and positive in buildings & transport
(design note 0009 §19).

**Smoothing.** `panelDataHistorical(movingAverage = 5)` applies a centred five-year moving average
(window shortened at the panel ends, so 2023 = mean of 2021–2023) to every panel column after
normalisation, the outcome included. Annual data were a robustness rung on `v6` (`v6-annual`, ADR 0053); there is
no `v7` or `v8` annual sibling.

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
selected specification is conditional on that constant. **Measured on `v7`** (the grid has not been re-run on `v8`'s
specification): holding the selected specification fixed and varying only the trend
(`analysis/checks/trendShapeGrid.R v7` → `output/pfm/v7/trend-shape-grid.rds`; one subprocess per fit, 120 s cap),
frontier logLik at **identical parameter count**:

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
| ΔR²(theory) | **0.140** | **0.159** |
| pseudo-R² | 0.739 | 0.778 |
| trend share of linear-predictor variance | 0.672 | 0.535 |
| max VIF | 7.67 | 7.83 |
| significant actor-power / institution / interaction terms | 6 / 4 / 4 | 3 / 3 / 2 |
| smallest significant theory $\lvert t\rvert$ | 2.52 | 2.29 |
| tier | Green | Green |
| $n$ | 1104 | 1104 |

**Selection position.** 36,384 specifications ranked; **80** pass every gate (the admissibility gates, the
edge-of-data gate and the theory gate; 5,786 pass the gates before the theory gate). The maximin order sorts by
trend share first (`trendKey`); the selected specification is **rank 18** (mean ΔR²(theory) 0.1495, minimum
0.140, ΣBIC 4677.4, fragility 0). The sanity walk rejects the six candidates ahead of it in the pool (one to six
severe flags each; `v7`'s own form with the bound, `… satInn iw:fexp fos5`, on one flag only: power & industry γ
0.999004, above the gate) and accepts it with 0 severe flags and 85 warnings (`forced = FALSE`; ADR 0062).

Gates in force: `supportShareGate` **0.275** (ADR 0045, 0052), `ceilingFallGate` 0.90 (ADR 0043; the selected
specification ends at 1.07 / 1.27 of its 2025 ceiling on the 1000 Gt pathway), `gammaGate` 0.999 (ADR 0046),
VIF hard 10 / soft 6; the edge-of-data gate and the theory gate (§2.4a).

> ⚠️ **Rank 18 is not dominance.** The best *per-sector* specifications fit more: power & industry
> `X-1791 … satInn fos5` reaches ΔR² 0.144 and buildings & transport `X-1854 WGIge|RoL|HorAcc … satInc fos5` 0.206 —
> a **sharing cost** of 0.004 (2.8%) in power & industry and 0.047 (22.8%) in buildings & transport
> (`selection-variants.rds`). Selected sector by sector with the same gates, power & industry picks a worse-fitting
> specification and buildings & transport one whose BIC gain comes from twelve region effects and whose fossil and
> institution effects lose their sign for most final energy by 2100 (design note 0009 §20): the shared specification
> is kept.

#### 2.4a The two gates (from `v7`)

**The edge-of-data gate** (`.pfmEdgeGate`, design note 0007 §5). A specification is admitted only if, on the
coupled 1000 Gt drivers mapped to EU21, (i) the share of a region's weight on which the fossil effect acts against
the theoretical expectation is below 0.25, (ii) the size of that adverse effect is below 0.25, and (iii) capping
the drivers at the observed range moves the projected ceilings by less than 0.5 (cap quantiles 0.05 / 0.95). The
selected `v8` specification passes it; the `v8` sweep keeps the verdict, not the cap shifts (on `v7`: 0.21 and 0.09;
`v6`'s specification on the `v7` data failed at 0.56 and 1.29, ADR 0060). Offline on the coupled hold-the-price panel
(`analysis/checks/edgeOfData.R v8` → `edge-of-data.rds`, 2026-11-01): capping the institutions inside the interactions
at the 5th–95th percentiles moves no regional rank $u$ by 0.15 or more and the strength by at most 0.01 (`v7`: one rank
by 0.16, the strength by 0.02); fossil dependence acts against the reading in no region's final energy above 10%,
fossil interests per person in 11% of the Middle East's (power & industry), below the 0.25 limit. The clean-energy direction check applies
only where the sample-centre sign is the expected one, so it does not apply in power & industry on `v8` (ADR 0062).

**The theory gate** (ADR 0059). The hypotheses are stated before the estimate (paper Methods §1) and required of
the specification, on the mean regression with wild-cluster $p$:

| | hypothesis | requirement | power & industry | buildings & transport |
|---|---|---|---|---|
| **H1** | structural power | fossil dependence lowers stringency, $p < 0.05$ | −0.883 ($p_{\text{wild}}$ < .001) | −0.249 ($p_{\text{wild}}$ < .001) |
| **H2** | contingency | at least one fossil × institution term significant after Bonferroni correction over the sector's fossil × institution terms; share and per-person terms both count; **sign free** | fossil pc × GovEff −0.761, fossil pc × RoL +1.376 (both $p$ < .001) | fossil pc × VerAcc +0.632 ($p_{\text{asym}}$ .004; $p_{\text{wild}}$ .068) |
| **H3** | coherence | the fossil effect, including its interactions, is negative in ≥ 75% of country-years | 100% | 99% |

> ⚠️ **H2 in buildings & transport passes on the asymptotic clustered $p$ the gate reads, not under the wild
> bootstrap**: the smallest wild-bootstrap fossil × institution $p$ is .024 (fossil dependence × accountability),
> above the Bonferroni level 0.05/6 = .008 (`v7`: .001). Treat the buildings & transport contingency as suggestive, not
> established, and quote the wild value with H2 (ADR 0062).

Declared sensitivities of the gate (ADR 0059 acceptance), **run on `v7`**: H3 at 0.70 and 0.80, $p$ at 0.10
(Run-Groups `v7-h3070`, `v7-h3080`, `v7-p10`; `RUNNING.md` Step 6c) all selected `v7`'s specification at the same rank;
H3 never bound. They have not been re-run on `v8`.

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
| Clean-energy build-out | −0.137 | .254 | .297 | −0.203 | 0.052 | .439 | .524 | 0.100 |
| Fossil dependence (share) | **−0.883** | <.001 | **<.001** | −1.309 | **−0.249** | <.001 | **<.001** | −0.482 |
| Fossil interests (pc) | **0.625** | <.001 | **<.001** | 0.925 | 0.056 | .523 | .635 | 0.109 |
| Gov. Effectiveness | −0.044 | .790 | .798 | −0.065 | **0.286** | .007 | **.014** | 0.553 |
| Rule of Law | 0.365 | .052 | .130 | 0.540 | −0.145 | .146 | .263 | −0.280 |
| Vertical Accountability | −0.264 | .067 | .162 | −0.391 | 0.150 | .080 | .251 | 0.289 |
| Innov × GovEff | **−0.333** | <.001 | **.004** | −0.493 | 0.083 | .234 | .305 | 0.160 |
| Innov × RoL | 0.291 | .246 | .288 | 0.432 | 0.138 | .274 | .366 | 0.267 |
| Innov × VerAcc | 0.013 | .967 | .971 | 0.019 | −0.404 | .162 | .315 | −0.781 |
| Fossil × GovEff | 0.209 | .239 | .342 | 0.309 | 0.103 | .120 | .141 | 0.200 |
| Fossil × RoL | 0.494 | .247 | .366 | 0.732 | 0.262 | .074 | .129 | 0.507 |
| Fossil × VerAcc | −0.501 | .383 | .464 | −0.742 | **−0.371** | .022 | **.024** | −0.717 |
| Fossil pc × GovEff | **−0.761** | <.001 | **<.001** | −1.127 | −0.087 | .441 | .521 | −0.168 |
| Fossil pc × RoL | **1.376** | <.001 | **<.001** | 2.038 | −0.234 | .221 | .409 | −0.453 |
| Fossil pc × VerAcc | **−0.715** | .012 | **.049** | −1.059 | 0.632 | .004 | .068 | 1.221 |
| GDP p.c. (Q-centred) | 0.128 | .135 | .207 | 0.190 | −0.054 | .304 | .411 | −0.104 |
| Population (log) | **0.411** | <.001 | **.001** | 0.608 | **0.316** | <.001 | **<.001** | 0.611 |
| Clean baseload share | **−0.376** | .002 | **.006** | −0.557 | 0.011 | .833 | .871 | 0.021 |
| Logistic trend | **1.298** | <.001 | **<.001** | 1.923 | **0.620** | <.001 | **<.001** | 1.199 |

> **One term changes verdict between the asymptotic and the wild-cluster $p$ at 0.05**: buildings & transport
> `Fossil pc × VerAcc` (.004 asymptotic, .068 wild) — the term the theory gate's H2 reads in that sector (§2.4a).

**What the table says, on signs and wild $p$:**

- **Structural power (H1) is stronger than on `v7` in both sectors.** Fossil dependence lowers stringency: −0.883 in
  power & industry, −0.249 in buildings & transport (both $p_{\text{wild}}$ < .001; `v7`: −0.731 / −0.199).
- **No institution main effect is significant in power & industry** ($p_{\text{wild}}$ .80 / .13 / .16), and the
  frontier gives GovEff and VerAcc the opposite sign (§3.3). **The power & industry institution main effects are
  not identified.**
- **State capability is significant in buildings & transport** (GovEff +0.286, $p_{\text{wild}}$ .014).
- **Contingency (H2) in power & industry acts through fossil interests per person** with state capability (−0.761),
  rule of law (+1.376) and accountability (−0.715). **In buildings & transport it is suggestive only**: fossil
  dependence × accountability −0.371 ($p_{\text{wild}}$ .024) and fossil pc × accountability +0.632 (.068), neither
  below the Bonferroni level. Only the pair of fossil terms is interpretable (§2.3), and the separate institution
  effects are read jointly (design note 0009 §19).
- **Fossil interests per person raise power & industry stringency** (+0.625) — the scale reading the design
  carries alongside the dependence reading, and a disclosed tension (§8.3).
- **Population and the trend are significant in both sectors**; the clean-baseload share is negative in power &
  industry (−0.376, $p_{\text{wild}}$ .006).

#### 2.5.1 Sign stability across estimators (`estimator-agreement.rds`)

Seven estimators on the same design — satP, fractional logit, beta, levels OLS, satP random
effects, satP with year FE, levels two-way FE. A term's sign **agrees** if all agree (the trend is
absent from the year-FE estimators):

| | Power & industry | Buildings & transport |
|---|---|---|
| terms with every sign agreeing | **5 of 19** | **9 of 19** |
| which | fossil dependence (−), `Fossil × RoL` (+), `Fossil × VerAcc` (−), clean baseload (−), trend (+) | fossil dependence (−), fossil pc (+), `Fossil pc × GovEff` (−), `Fossil pc × VerAcc` (+), `Innov × GovEff` (+), `Innov × VerAcc` (−), GDP (−), population (+), trend (+) |
| fossil dependence | − in 7, significant in 7 | − in 7, significant in 6 |
| GovEff | + in 3, − in 4 | + in 6, − in 1 |

> ⚠️ **Sign agreement is weak in power & industry.** Fourteen of nineteen power & industry terms change sign
> somewhere in the battery, the institution main effects among them; `Fossil pc × GovEff` and `Fossil pc × RoL` keep
> their sign in six of seven. The two hypotheses' anchors hold: fossil dependence is negative under every estimator in
> both sectors.

### 2.6 How much of this survives dropping one country (`influence.rds`)

Leave-one-country-out over the 48 clusters, α = 0.05. $p_{\max}$ is the worst $p$ across the 48
refits; **pivotal** counts the countries whose removal alone flips the term's verdict. The theory terms
significant at full sample:

| Term | $p$ | $p_{\max}$ over refits | pivotal | verdict |
|---|---:|---:|---|---|
| **Power & industry** fossil dependence | <.001 | .002 | — | robust |
| Power & industry fossil interests per person | <.001 | .0003 | — | robust |
| Power & industry Fossil pc × GovEff | <.001 | .0003 | — | robust |
| Power & industry Fossil pc × RoL | <.001 | <.0001 | — | robust |
| Power & industry Innov × GovEff | .002 | .019 | — | robust |
| Power & industry Fossil pc × VerAcc | .015 | .051 | 1 — ZAF | 🟠 borderline |
| **Buildings & transport** fossil dependence | <.001 | .044 | — | robust |
| Buildings & transport GovEff | .010 | .082 | 1 — ISL | 🟠 borderline |
| Buildings & transport Fossil × VerAcc | .027 | .383 | 7 — ARG, CHE, CRI, ISL, LUX, LVA, MLT | 🔴 fragile |
| Buildings & transport Fossil pc × VerAcc | .006 | .994 | 2 — CHN, SAU | 🟠 holds except two |

> **H1 is robust in both sectors** (largest leave-one-out $p$ .002 in power & industry, .044 in buildings & transport;
> `v7`: .031 / .052). The buildings & transport contingency is not: one of its two candidate terms loses significance
> without any of seven countries, the other without China or Saudi Arabia.

Terms not significant at full sample whose removal of one country would *create* significance
exist in both sectors (power & industry RoL: six countries, VerAcc: five; buildings & transport `Fossil × RoL`: six).
**No claim rests on any of them, and dropping a country to obtain a result is exactly what must
not be done.**

#### 2.6.1 One country with leverage: Saudi Arabia

SAU is the top influencer on **eight of fifteen** buildings & transport theory terms (fossil interests per person,
the three institutions, two clean-energy interactions, `Fossil pc × RoL`, `Fossil pc × VerAcc`) and on one power &
industry term (`Fossil pc × RoL`), and pivotal in buildings & transport `Fossil pc × VerAcc`. It combines the lowest
Vertical Accountability in the sample with the highest fossil interests per person — the plane the accountability ×
fossil interests interaction identifies. The conjunction has n = 1. **No control fixes this in the ceiling**: the
binding constraint is support, and no covariate creates data where there is none (§2.7). On `v8` its distance below the
buildings & transport ceiling is partly explained by its rents, through the slack (§3.1a): its share of the ceiling used
falls from 0.94 to 0.66 in 2023 (ADR 0062).

### 2.7 Marginal effects

Because the response is non-linear, report average marginal effects on the natural scale:

$$\text{AME}_k = \frac{1}{N}\sum_{c,t} M\,\operatorname{logit}^{-1}(\eta)\big(1-\operatorname{logit}^{-1}(\eta)\big)\frac{\partial\eta}{\partial x_k}$$

with $\partial\eta/\partial x_k$ including interaction terms (and the weight $w$) and delta-method clustered SEs;
tabulated in §2.5 and persisted in `inference.rds`. Every driver is standardized, so every AME is per
SD. Examples: buildings & transport **GovEff** AME **0.553** index points per SD (SE 0.205); power & industry
**fossil dependence** **−1.309** (SE 0.309), the largest identified power & industry main-effect AME.

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
$\mathbb{E}[u\mid\varepsilon] = \mu^{*} + \sigma^{*}\phi(\mu^{*}/\sigma^{*})/\Phi(\mu^{*}/\sigma^{*})$
(with $\gamma$ and $\sigma$ evaluated row by row where the slack is heteroscedastic).

### 3.1a Fossil rents set the size of the buildings & transport slack (ADR 0061)

In buildings & transport the slack's scale depends on fossil rents; the ceiling does not:

$$u_{c,t} \sim \big|N(0,\sigma_{u,c,t}^2)\big|,\qquad \log\sigma_{u,c,t} = c + \omega\, z_{c,t-1}$$

with $z$ the World Bank's oil, gas and coal rents, $\log(1 + \%\text{ of GDP})$, standardized on the training rows.
Estimated with the ceiling (Caudill, Ford & Gropper 1995): **ω = +0.277** (z 12.1), $c$ = −0.587. Countries with large
rents sit further below a ceiling their institutions and interests would allow — the rentier reading (Ross 2012) — so
the rents are a statement about the slack, not the ceiling: in the ceiling they raised power & industry stringency
and failed the gates (design note 0009 §§3, 6.1). Out of sample (each covered country left out in turn), the rents
slack predicts better than the homoscedastic one in **38 of 48** countries in buildings & transport (sign test $p$
0.0001) and in 27 of 48 in power & industry ($p$ 0.47), which therefore keeps the homoscedastic slack
(`v8-het-slack-cv.rds`). **In the coupling** a country's distance below the buildings & transport ceiling follows its
rents (§5.2):

$$q_c(t) = q_c\, e^{\,\omega\,(z_c(t) - z_{c,2023})},$$

with $z_c(t)$ the country's 2023 rents moved by its REMIND region's rents relative to 2025 (valued at the region's own
primary-energy price; the ratio bounded to [0, 3]). A country without a rents series keeps its anchored distance.

### 3.2 In index units

$$\boxed{\,S^{*} = M\cdot\operatorname{logit}^{-1}(\eta_F)\,}\qquad
\hat S^{\text{exp}} = M\cdot\operatorname{logit}^{-1}\!\big(\eta_F - \mathbb{E}[u\mid\varepsilon]\big)$$

$$G^{\text{ap}} = S^{*} - \hat S^{\text{exp}},\qquad E = \frac{S}{S^{*}} \in (0,1]$$

> $E$ is the implementability factor: it compares each polity to **its own** political
> possibility rather than to a universal maximum. **Never use $S/10$.** $E$ is built from the
> ceiling alone (`efficiencyRatio = observedIndex / frontierIndex`), with no Jondrow term.

### 3.3 Estimated frontier (`frontier.rds`)

Half-normal SFA, both sectors on the identical design, $n = 1104$ each; buildings & transport with the rents slack
(§3.1a).

| | Power & industry | Buildings & transport |
|---|---:|---:|
| $\gamma = \sigma_u^2/\sigma^2$ | **0.9989** | **0.9178** (at average rents) |
| $\sigma^2$ | 2.095 | 0.337 (at average rents) |
| slack weight ω on rents | — | **+0.277** (z 12.1) |
| LR test against OLS | 534.8 | 512.9 |
| logLik | −1232.1 | −435.6 |
| covariance check (`vcovCheck`) | ok, ratio 1.02 | ok |
| converged | yes | yes |

**Frontier coefficients** (ML standard errors; $p$ asymptotic — see §2.2 for why there is no
clustered alternative):

| Term | Power & industry $\hat\beta_F$ | $p$ | Buildings & transport $\hat\beta_F$ | $p$ |
|---|---:|---:|---:|---:|
| Clean-energy build-out | −0.031 | .41 | **0.083** | <.001 |
| Fossil dependence (share) | **−0.813** | <.001 | **−0.168** | <.001 |
| Fossil interests (pc) | **0.491** | <.001 | **0.162** | <.001 |
| Gov. Effectiveness | **−0.518** | <.001 | **0.167** | <.001 |
| Rule of Law | **0.670** | <.001 | 0.029 | .48 |
| Vertical Accountability | **−0.431** | <.001 | 0.035 | .29 |
| Innov × GovEff | **−0.210** | <.001 | **0.066** | .008 |
| Innov × RoL | **0.224** | .011 | 0.052 | .28 |
| Innov × VerAcc | 0.056 | .61 | −0.079 | .32 |
| Fossil × GovEff | **0.439** | <.001 | **0.092** | <.001 |
| Fossil × RoL | **−0.267** | .028 | **0.149** | .016 |
| Fossil × VerAcc | 0.008 | .96 | **−0.339** | <.001 |
| Fossil pc × GovEff | **−0.813** | <.001 | **−0.110** | <.001 |
| Fossil pc × RoL | **1.180** | <.001 | −0.074 | .16 |
| Fossil pc × VerAcc | −0.050 | .66 | **0.262** | .002 |
| GDP p.c. (Q-centred) | **0.113** | <.001 | 0.011 | .38 |
| Population (log) | **0.253** | <.001 | **0.273** | <.001 |
| Clean baseload share | **−0.354** | <.001 | −0.009 | .57 |
| Logistic trend | **0.974** | <.001 | **0.481** | <.001 |
| FE OECD / other (vs EU) | 0.052 (.26) / **−1.039** (<.001) | | **−0.129** (<.001) / **−0.269** (<.001) | |
| slack: constant $c$ / rents ω | — | | −0.587 (<.001) / **+0.277** (<.001) | |

> ⚠️ **The clean-energy main effect in power & industry is gone** (−0.031, $p$ .41; `v7` +0.125). The clean-energy
> terms carry no requirement (ADR 0059) and were already reported as not identified (ADR 0062).
>
> ⚠️ **The two estimators disagree about power & industry institutions.** The mean regression finds no power &
> industry institution main effect (GovEff −0.044, RoL +0.365, VerAcc −0.264, all $p_{\text{wild}}$ > .13); the
> frontier finds GovEff **−0.518**, VerAcc **−0.431** and RoL **+0.670**. They estimate different
> things — the average versus the attainable maximum — but "state capability raises the power & industry
> *ceiling*" is **not** a supported sentence, and nor is its negation. In buildings & transport both estimators
> agree on GovEff (+0.286 mean, +0.167 frontier).
>
> ✅ **The terms the theory gate reads agree in sign across the two estimators**: fossil dependence (−/−), fossil pc
> × GovEff and × RoL in power & industry, fossil pc × VerAcc in buildings & transport.
>
> ⚠️ **Frontier $p$-values are ML and understate uncertainty.** The design effect of country clustering
> on the same design is **1.94×** (power & industry) and **2.46×** (buildings & transport) in the `v8` mean regression
> (`efficiency-ratio-band.rds`, §5.3.1). Quote frontier signs; quote mean-regression $p$.

### 3.4 ⚠️ The $\gamma$ caveat — read before using any ceiling

$\gamma$ = 0.9989 / 0.918 attributes nearly all composed error to slack. Both are inside the γ gate
(0.999, ADR 0046), but **the power & industry margin is 0.0001**: `v7`'s own form with the bound crossed it (§2.4), and
a small change of panel or form could push this one over. The noise/slack split is weakly identified there and the
*level* of a single country's ceiling is the least trustworthy thing the model produces (accepted with disclosure
since ADR 0053). The rents slack lowers buildings & transport γ (0.973 → 0.918 at average rents): part of what looked
like slack is now its measured size. The coupling reads the ceilings as an **ordering** (§5.2). The robustness battery
re-estimates under three alternative error structures (homoscedastic in both sectors); $\rho$ is the Spearman
correlation of country slack ranks against the headline:

| Rung | Power & industry $\gamma$ | Power & industry $\rho$ | Buildings & transport $\gamma$ | Buildings & transport $\rho$ |
|---|---:|---:|---:|---:|
| headline (pooled half-normal) | **0.9989** | — | **0.9178** | — |
| truncated-normal $u$ | 0.997 | 0.38 | 0.981 | **0.90** |
| panel (Battese–Coelli 92) | 0.871 | 0.42 | 0.872 | 0.65 |
| time-decay (BC), $\eta$ | 0.051, $\eta$ = 0.161 | 0.03 | 0.221, $\eta$ = 0.114 | **0.79** |

> 🔴 **Power & industry slack ranks are not robust on any rung** (0.38 / 0.42 / 0.03). Buildings & transport holds
> on two of three (0.90 / 0.79) and weakens on the panel rung (0.65). **Report tiers, never named country
> rankings of slack, in both sectors.**

#### 3.4.1 Propagated to what the coupling consumes (`frontier-rung-phi.rds`)

`slackRankCor` ranks countries on absolute slack, which the coupling never sees; it consumes $E$,
then $\varphi$. Rebuilt per rung (`analysis/checks/propagateFrontierRungsToPhi.R v8 2023`, the anchor
year, 48 covered countries, θ = 0.50; offline, not through the coupling's anchor artifact):

**Country $E$ versus the headline:**

| Rung | Power & industry $\rho$ | median $\lvert\Delta E\rvert$ | Buildings & transport $\rho$ | median $\lvert\Delta E\rvert$ |
|---|---:|---:|---:|---:|
| truncated-normal | **0.962** | 0.052 | **0.900** | 0.018 |
| panel (BC92) | 0.685 | 0.106 | 0.546 | 0.111 |
| time-decay | 0.766 | 0.187 | 0.838 | 0.102 |

**Delivered $\varphi = \min(\varphi^{\text{Bulk}},\varphi^{\text{Diffuse}})$, GDP weights, the regions
with a covered country (20 at EU21, 11 at H12):**

| Rung | EU21 Spearman | median / max $\lvert\Delta\varphi\rvert$ | H12 Spearman | median / max $\lvert\Delta\varphi\rvert$ |
|---|---:|---|---:|---|
| truncated-normal | **0.907** | 0.047 / 0.152 (IND) | 0.818 | 0.036 / 0.152 (IND) |
| panel (BC92) | 0.636 | 0.034 / 0.274 (SSA) | 0.682 | 0.028 / 0.305 (SSA) |
| time-decay | 0.457 | **0.100** / 0.450 (SSA) | 0.369 | 0.068 / 0.500 (SSA) |

> 🔴 **The γ band is NOT small.** The truncated-normal rung moves $\varphi$ little, but the decay rung reorders it
> (Spearman 0.46 at EU21) and moves it by a median of 0.1 — the size of a θ step. The frontier error structure is a
> first-order uncertainty in $\varphi$ and belongs beside θ in any φ band.

**Rank intervals** across the four rungs (`rankInterval`): EU21 max width **18.5 of 20**, 55%
separable; H12 max width 9.5 of 11, 45% separable. **A range over four fitted models, not a sampling
confidence interval.**

**Which sector binds is not robust.** In this offline reconstruction (GDP weights) power & industry binds in
5 / 3 / 4 / 12 of 20 EU21 regions across headline / truncated-normal / panel / decay, 13 of 20 regions change
binding sector, six are always buildings & transport (ENC, ESW, EWN, FRA, MEA, NES) and one always power & industry
(SSA). At country level power & industry binds in 39 / 33 / 32 / 22 of 48, and 25 countries flip. **Any sentence of the
form "the constraint binds on sector X" is a statement about one rung and one weighting.**

#### 3.4.2 The sector ordering in the estimation sample

On $E$ read straight out of `frontier.rds`, **power & industry is the more constrained sector in 39 of 48
countries at 2023** (median $E$: power & industry 0.718, buildings & transport 0.799).

**`projection.rds$implementability` is $S/10$, not $E$** (`computeImplementabilityFactor()` is
`index / indexMax`). Nothing in the coupling reads it; any offline figure built from that column is
on the prohibited measure (§7).

#### 3.4.3 The countries at the edge

**Measured on `v7`** (`output/pfm/v7/efficiency-extremes.rds`): the lowest $E$ in power & industry at 2023 were
Iceland 0.33, Indonesia 0.33, Peru 0.35, Argentina 0.39, Russia 0.46; Saudi Arabia 0.55. Decomposed by term
(`analysis/checks/efficiencyExtremes.R`), three were artefacts of the form, not measured slack:

- **Iceland**: the linear fossil-dependence term evaluated below the sample's 5th percentile (+2.0
  logit), and an outcome (instruments scored) that is low where a renewable power system needs few;
- **Indonesia** (and in part Peru, Argentina): the fossil-per-person × rule-of-law interaction
  outside the joint support (+2.4; design note 0007);
- **Saudi Arabia**: the vertical-accountability main effect, not identified in power & industry (+1.8).

**What `v8` changes** (ADR 0062; rank correlation of country $E$ with `v7`: 0.97 power & industry, 0.84 buildings &
transport): the fossil bound lifts Iceland to 0.39 and Peru to 0.41; the saturating fossil terms lower Russia to 0.33;
the rents slack lowers Saudi Arabia's buildings & transport share used from 0.94 to 0.66. Russia's low ceiling follows
from its drivers. This is why country $E$ is reported only as tiers. In the coupling, Russia is 73% of REF, Saudi
Arabia 20% of MEA, Indonesia 18% of OAS, and Iceland 8% of NEN (no effect).

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
| Power & industry | 0.117 | 5.6 y | −0.175 | −0.524 | 0.47 |
| Buildings & transport | 0.079 | 8.4 y | −0.737 | −0.511 | 0.41 |

| Four sectors | $\lambda$ | $t_{1/2}$ | skill |
|---|---:|---:|---:|
| Electricity | 0.123 | 5.3 y | **+0.057** |
| Industry | 0.174 | 3.6 y | −0.523 |
| Buildings | 0.108 | 6.1 y | −0.657 |
| Transport | 0.147 | 4.4 y | −1.002 |

> **Only electricity beats "assume nothing changes"**, and narrowly. Everything else is a
> descriptive rate, not a forecast. The static level forecast loses to persistence in both sectors —
> which is why this model delivers ceilings and rankings and never level paths. The out-of-sample correlation of
> the static forecast is 0.628 (power & industry) and 0.829 (buildings & transport), against 0.565 / 0.810 on `v7`.

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
population, the institutions under gap closure; the weight $w$ as in §2.3). The distance is held in power & industry;
**in buildings & transport it follows the country's fossil rents**, $q_{c,s}(t) = q_{c,s}\,e^{\omega(z_c(t)-z_{c,2023})}$
(§3.1a), recomputed from the current REMIND solution at every coupling call. Uncovered countries take the covered
median share of their own ceiling (§5.4).

**Ranking.** Regional relative gaps at $t_a$, final-energy weighted, give

$$g_{r,s} = 1 - E_{r,s},\qquad \boxed{\;u_{r,s} = \frac{g_{r,s}-\min_r g}{\max_r g-\min_r g}\;}$$

computed once per Run-Group and staged as `phi-anchor.rds`. **Relative**, not absolute, because an
absolute gap ranks regions by how much they *could* do rather than how far they fall short.

**Strength — regional, the `v8` central form (ADR 0062 decision 5).** Each region's constraint fades with its own
gap:

$$\boxed{\;k_{r,s}(t) = \frac{g_{r,s}(t)}{g_{r,s}(t_0)}\;},\quad t_0 = 2025$$

The **common** strength of `v6`–`v7`, $G_s(t) = \sum_r w_r\, g_{r,s}(t)$, $k_s(t) = G_s(t)/G_s(t_0)$, is the sensitivity
pair (`pfmPhiStrength = common`). Why regional: with the rents in the distance, an exporter's fading constraint would
otherwise lower the world's mean gap and loosen every region's constraint, those without fossil income included; the
regional form keeps it with the exporter. Either way $k(t_0) = 1$ in every scenario, and $k$ is endogenous: each PFM
call recomputes it on the current REMIND solution.

**Share.**

$$\boxed{\;\varphi_{r,s}(t) = \operatorname{clip}_{[0,1]}\big(1 - \theta\,k_{r,s}(t)\,u_{r,s}\big)\;}$$

A third form, **gap first** (`pfmPhiStrength = gapfirst`, the order of the steps proposed at the meeting of 9 October:
the gap, then its normalisation with the 2023 range held, then θ), is a declared sensitivity:
$\varphi_{r,s}(t) = 1 - \theta\,\operatorname{clip}_{[0,1]}\big((g_{r,s}(t) - g^{\min}_{s,t_a})/(g^{\max}_{s,t_a} - g^{\min}_{s,t_a})\big)$
(`gap-order.rds`, design note 0009; `COUPLING.md` §14).

θ means *severity at 2025*. A clip at 0 is flagged as a run defect; $k_s > 1/\theta$ is logged.

**Three disciplines:** a ranking, not levels; **the ranking is fixed at the anchor year**, only the
strength moves; $\varphi$ is a **parameter** refreshed between coupling iterations, never a decision
variable.

**The ranking on `v8`** (`output/remind-inputs/v8/phi-anchor.rds`). Russia & reforming countries (REF) are
the most constrained region in both sectors ($u$ = 1), as on `v7` (rank correlation with `v7` 0.96 power & industry,
0.95 buildings & transport). The rest compress, mainly through the coverage rule: in power & industry OAS 0.49, MEA 0.43,
LAM 0.45 (`v7` 0.78 / 0.68 / 0.63); in buildings & transport NES 0.60, ECS 0.60, MEA 0.58. At θ = 0.50 and $k = 1$ the
delivered share (the worse sector) ranges from 0.50 (REF) to 1.00 (NEN) at EU21 and from 0.50 (REF) to 0.93 (CHA) at
H12; ECE is next to REF at EU21 (0.65).

**What the strength does on the coupled energy system** (`coupled-facts.json`, EU21, hold the price, fading limit,
θ = 0.50, the final-energy-weighted strength). Power & industry $k$ is **0.632 / 0.727** in 2050 / 2100 (H12 0.629 /
0.724); buildings & transport 0.624 / 0.494 (H12 0.622 / 0.493). With institutions held at 2023, power & industry $k$
is 0.86 in 2100. One driver group moving at a time (the others held at 2025), on the hold-the-price headline's final
energy system (`analysis/v6/couplingMechanism.R v8` → `coupling/strength-support.rds`, 2026-11-01; the run's own
institution rule and rents; the recomputation matches the last call's $k$ within 0.002; the world's final-energy-weighted
strength):

| moving | power & industry $k_{2050}$ / $k_{2100}$ | buildings & transport $k_{2050}$ / $k_{2100}$ |
|---|---:|---:|
| the economic weight of fossil and clean-energy interests (actor power) | **0.63 / 0.63** | 0.66 / 0.58 |
| institutions (gap closure) | 1.07 / **1.21** | 0.80 / 0.68 |
| income and population | 0.92 / 0.91 | 0.82 / 0.74 |
| all (the run) | 0.63 / 0.73 | 0.62 / 0.49 |

(`v7`, 2100: actor power 0.42 / 0.56, institutions 1.36 / 0.85, income and population 0.95 / 1.01, all 0.67 / 0.49.)
**The interests do their work by 2050 and then stop** in power & industry (clean energy saturated, the fossil terms at
their bound, §2.3); the rents are not in the actor-power group and are held at 2025 in its row.

**In power & industry the energy transition relaxes the constraint and the projected institutions tighten it**,
through power & industry institution terms that are not identified (§2.5); read jointly, the three institutions' net
effect in power & industry is negative (design note 0009 §19). On `v8` the power & industry strength rises again after
2050 (0.63 → 0.73), where `v7`'s fell (0.71 → 0.67): with the interests at rest after 2050, the institutions set the
late path. In buildings & transport every driver group relaxes the constraint. Holding the institutions at their anchor values adds 10.3 Gt CO₂ to
the hold-the-price result at EU21 and 5.9 at H12 (`v7`: −0.4 / +0.7): under gap closure the institutions now take a
tenth off the overshoot (`SCENARIOS.md`). The buildings & transport strength falls throughout, as on `v7`.

**Out of training support** (the drivers with a guard range: income, population and institutions; the coupled
hold-the-price headline, `strength-support.rds`): 2% of weighted drivers in 2030, 5% in 2050, 6% in 2100 in both sectors
(`v7`: 10% / 19% in 2050 / 2100 in power & industry): under gap closure the institutions stay inside the observed range.
Reported with every $k(t)$. The actor-power terms are reported separately, as the share
of countries beyond the observed range (§2.3): on `v8` the fade after mid-century is read through saturating curves
and, at the low end, through the fossil bound.

*Offline* (`phase1/strength.rds`, uncoupled REMIND bases) was **measured on `v6`** and is not re-run since.

#### 5.2a Options on the strength (each one a declared sensitivity; `COUPLING.md` §14)

| option | form | headline | sensitivity run |
|---|---|---|---|
| **κ, the erosion rate** | $k(t)\,(1-\kappa)^{t-2025}$ | κ = 0 | 0.027 central (half-life 25 y), 0.02, 0.05, and the historical per-sector rates (1.1% / 4.6%); fixed before any run (ADR 0050 decision 5); `v8` batch, `SCENARIOS.md` §4.9 |
| growing limit | $k$ rising at a declared rate (ADR 0057) | none | `v8` batch, `SCENARIOS.md` §4.9 |
| hold year | drivers held after 2060 | none (to 2100) | `pfmPhiHoldYear = 2060` |
| constant limit | hold $E$ instead of $q$ ($k \approx 1$; the rents do not act) | distance kept | `pfmPhiHold = ratio` |
| common strength | the world's $k_s(t)$ | **regional** (from `v8`) | `pfmPhiStrength = common` |
| gap first | gap normalised with the 2023 range, then θ | regional | `pfmPhiStrength = gapfirst` |
| ordering | $u$ uniform, permuted or reversed | the model's | `pfmPhiOrdering` |
| institutions | held at 2023; Andrijevic's government effectiveness; the previous storyline rule | gap closure (ADR 0063) | `pfmInstitutions = hold`, `gapclosureAndrijevic`, `storyline` |
| rents valuation | REMIND's rents at the world price | the region's own price | `pfmRentsPrice = world` |
| window (the shrinking future) | φ only before a year, 1 after it | none | `pfmPhiWindowEnd`; §5.6a |

**A historical reference for κ** (not an estimate; `analysis/v8/persistentSlack.R v8` → `output/pfm/v8/v8-persistent-slack.rds`,
2026-11-01; design note 0009 §6.2). κ shrinks the political differences, so its counterpart in the data is how fast the
spread of the gaps $g = 1-E$ narrowed. Between 2008 and 2023 the cross-country standard deviation fell from 0.193 to 0.159
in power & industry (0.7% a year) and from 0.199 to 0.097 in buildings & transport (5.7% a year); across the EU21 regions
(covered countries) the rates are 0.4% and 5.7%. The declared values 2% and 2.7% lie between the two sectors' rates; 5% is
near the faster one; the constant limit is slower than both. **The historical-erosion runs use the rates measured on `v7`**
(1.1% / 4.6%; `v7`: 0.188 → 0.154 and 0.186 → 0.099), fixed in the scenario matrix before this measurement; disclose it.
Both `v7` rates lie between the two `v8` rates. A four-component frontier does not identify persistent slack
on this panel (country effects skewed the wrong way), so no rate is estimated.

### 5.3 $\theta$ is declared and swept, not estimated

No historical experiment assigned carbon prices by political gap, so $\theta$ is not identified.

| $\theta$ | role |
|---:|---|
| **0** | uncoupled no-politics reference — every φ = 1 (`-PFM-noPolitics-holdBudget-v8`, `-PFM-noPolitics-holdPrice-v8`) |
| **0.325** | declared low point of the sweep |
| **0.50** | **declared central value** (`cm_pfmTheta`); every headline uses it |
| **0.675** | declared high point, symmetric about 0.50 |

**The efficiency analogy, and why it anchors nothing.** Solving $1-\theta\bar u=\bar E$ for the median
region (`coupling-summary.rds$anchorDerivation`, region resolution, 2025, $n$ = 21) gives θ = **0.805**
(power & industry: median $E$ 0.756, median $u$ 0.303) and **0.384** (buildings & transport: 0.822, 0.463). Both
are admissible, but the analogy is resolution- and version-dependent (`v7` 0.708 / 0.498, `v6` 0.372 / 0.468) and
**no θ value may be called "the efficiency anchor"**.

**Coupled**, hold the price adds +44.4 / +75.1 / +109.8 Gt CO₂ by 2100 at θ = 0.325 / 0.50 / 0.675 (EU21), 161 Gt
per unit θ; H12 +39.4 / +64.3 / +95.1, 139 Gt per unit θ (`SCENARIOS.md` §4; `v7`: +99 / +88 at θ 0.50).

#### 5.3.0 $\varphi$ is also specification-dependent

The specification is as undetermined as θ: the selected specification wins **1%** of bootstrap resamples (**31%**
conditional on sanity-eligible winners, §6). The conditional winners are all weighted X-1791 or X-1860
specifications with both fossil terms and the bound, and they split about **55 / 45** between the both-saturate family
(`satAP`, selected) and the clean-energy-only family (`satInn`).

**Measured on `v6`** (`v6` `phase1/spec-band.rds`, `SCENARIOS-v6` §4.9): the two families gave a power & industry
$k_{2050}$ of 0.63–0.90 (both-saturate) and 0.86–1.22 (clean-energy-only) on the uncoupled 1000 Gt energy system;
coupled, the clean-energy-only `X-2079 satInn` gave +107.5 Gt against +118.2 for the selected both-saturate spec;
saturation 0.5× / 2× +115.2 / +130.0; annual data +164.4. No `v7` or `v8` specification band has been run.

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
| **5. Partial identification (bounds)** | revealed-preference restrictions | an interval | **empty on `v8`**, for the multiplicative cap only (below) |
| **6. Expert elicitation** | a structured protocol | a documented prior | out of scope |

**Route 5 — bounds** (`analysis/checks/efficiencyRatioBand.R v8`, `analysis/checks/computeThetaBounds.R v8` →
`efficiency-ratio-band.rds`, `coupling/theta-bounds.rds`, 2026-11-01). These bound θ for a **multiplicative** level cap,
$\varphi_r P^{\circ}$, read on the offline bound's price paths.

*Upper bound — revealed preference.* A region cannot credibly be modelled below the price it has
already legislated: $\theta \le (1-P^{\text{ref}}_{r,t}/P^{\circ}_{r,t})/u_r$, minimised over
region-years with $P^{\circ}>P^{\text{ref}}$ and $t\ge2030$: $\theta_{\max} = $ **0.061**, binding at
ECE in 2030 (`v7` 0.063). At θ = 0.50 eight regions violate it (DEU, ECE, ECS, ENC, ESC, ESW, EWN, FRA).

*Lower bound — resolution.* $u$ is min–max normalised, so the spread θ induces in $\varphi$ is exactly
θ; below the width at which $E$ itself is resolved the differentiation is inside its own noise. A CI on
$\eta_F$ maps to $E$ by transforming the endpoints. Median 95% CI width on $E$ at 2023: ML band 0.056
(power & industry) / 0.057 (buildings & transport); **cluster-scaled 0.105 / 0.142**, pooled 0.127 (design effect
1.94× / 2.46×; `v7`: cluster-scaled 0.124 / 0.119, pooled 0.119).

$$\boxed{\;\theta \in [0.127,\ 0.061]\;=\;\varnothing\;}\qquad\text{empty on `v8`, as on `v7` and `v5` (on `v6` it was }[0.134,\ 0.164])$$

> **What it says, and what it does not.** Every declared θ is above the upper bound: **the multiplicative level cap
> is incompatible with revealed preference at any θ that differentiates regions beyond the noise of $E$.** The
> selected cap is **relative** (§5.1) — it caps the increment over current policy, so $P^{*}\ge P^{\text{ref}}$ by
> construction wherever $A \ge P^{\text{ref}}$ — and the revealed-preference bound does not bind it. The
> resolution floor (0.127) does apply to the selected share: every declared θ is above it.

#### 5.3.2 Sources of uncertainty in $\varphi$, and where each is reported

| source | what varies | size | reported in |
|---|---|---|---|
| **1. Severity θ** | declared, 0.325 / 0.50 / 0.675 | hold the price +44 to +110 Gt (EU21) | **main text** |
| **2. How long the limit lasts** (erosion κ; growing / constant limit) | κ 0.02 / 0.027 / 0.05 / historical; growing; constant | hold the price +159.9 (growing), +123.8 (constant), +75.1 (fading), +34.7 / +29.4 / +19.3 (erosion 2% / 2.7% / 5%), +38.9 (historical rates) Gt at EU21; H12 erosion 2.7% +23.0 | **main text** (the largest single sensitivity) |
| 3. Strength form | regional (central) / common / gap first | +75.1 / +75.5 / +55.0 Gt (EU21) | SI |
| 4. Expectations: the shrinking future | the limit applied decade by decade, each step expecting it to lift | hold the price +39.4 against +75.1 Gt (EU21, §5.6a) | main text or SI (author) |
| 5. Specification family | both-saturate (selected) vs clean-energy-only | measured on `v6` only (§5.3.0) | SI |
| 6. Frontier error structure | four frontier variants | median \|Δφ\| up to 0.100, Spearman down to 0.46 (EU21, offline, §3.4.1) | SI — rank intervals |
| 7. Out-of-coverage assignment | the covered median (from `v8`) against the donor / band rule | rule tested out of sample (§5.4): median MAE 0.125 / 0.080 against 0.153 / 0.088; not coupled | SI |
| 7a. Frontier coefficients | 200 draws from the frontier's covariance, the anchor rebuilt (`analysis/v8/couplingBand.R v8 200 regional` → `v8-coupling-band-regional.rds`) | 2050 share, median 5–95% width 0.049 (P&I) / 0.064 (B&T), about 60% of θ's spread (0.081 / 0.103); $k_{2100}$ 0.64–0.82 / 0.45–0.54 | main text, next to θ and κ |
| 8. Institution projections | gap closure / held / Andrijevic / storyline | hold the price +75.1 / +85.5 / +82.4 / +83.9 Gt (EU21); H12 held +70.3 | main text (fixed-institutions variants) |
| 9. Rents valuation | regional / world price | +75.1 / +73.5 Gt (EU21) | SI |
| 10. Energy-system feedback | φ recomputed on the live energy system | power & industry $k_{2050}$ 0.63 on the coupled pathway | **main text** as a result, not an uncertainty |
| 11. Theory-gate thresholds | H3 0.70 / 0.80; $p$ 0.10 | none on `v7` (the same specification selected); not re-run on `v8` (a cluster sweep) | SI, one sentence |

**The reporting rule.** The main text carries θ and κ as declared bands and treats $\varphi$ as
**ordinal**. Any sentence about **which sector binds** carries source 5's caveat.

### 5.4 Countries the sample never saw — the covered median

Uncovered countries keep their **own** ceiling and inherit only a relative gap,
$\hat S = \hat E\cdot S^{*}_{\text{own}}$. **From `v8`, $\hat E$ is the covered countries' median** for every uncovered
country (config.yml `coverage: v8: median`; `computeDonorAssignment(rule = "median")`; ADR 0062 decision 4). Out of
sample, the median predicts a covered country's $E$ better than the band rule and its donors do (mean absolute error
0.125 against 0.153 and 0.159 in power & industry, 0.080 against 0.088 and 0.089 in buildings & transport; a ridge
regression on the drivers 0.126 / 0.081; `v7`: 0.119 / 0.080 against 0.151 / 0.087): similar drivers do not predict a
similar share used, because the ceiling has already absorbed what the drivers say (`analysis/v8/uncoveredRule.R v8` →
`output/pfm/v8/v8-uncovered-rule.rds`, 2026-11-01; design note 0009 §6.3). Between the two rules the EU21 ranking $u$ has
rank correlation 0.99 (power & industry) and 0.98 (buildings & transport), the Middle East moving most (0.12 / 0.16). On `v8` it is
the main reason the regions compress (§5.2): regions dominated by uncovered countries (OAS, MEA, LAM, SSA) no longer
carry low-band countries. The donors are still found and reported as diagnostics.

**The band rule of `v7` and earlier.** Placement used the model's own signed linear index
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

> ⚠️ **On `v7` most uncovered countries were placed by a quantile rule, not a donor**: 154 of 200 in power & industry
> and 163 in buildings & transport. On `v6` the coupled sensitivity runs (all-median, all-low, nearest donors always,
> USA donor and USA low) moved the hold-the-price headline from +110 to +155 Gt (`SCENARIOS-v6` §4.9). The band rule
> stays the rule of every group up to `v7`.

**How much of each region's u rests on one observed country** (**measured on `v7`**; covered countries only, EU21,
anchor 2023;
`analysis/v8/rankingUncertainty.R` → `output/pfm/v7/v8-ranking-uncertainty.rds`, 1000 draws of the frontier coefficients;
design note 0009 §7.3). Report these with any regional ranking.

| region | P&I u (90% band) | B&T u (90% band) | largest covered country, share of the covered final energy |
|---|---|---|---|
| REF | 1.00 (1.00–1.00) | 1.00 (0.92–1.00) | Russia, 100% |
| MEA | 0.77 (0.66–0.95) | 0.09 (0.00–0.29) | Saudi Arabia, 91% |
| OAS | 0.73 (0.61–0.94) | 0.39 (0.30–0.50) | Korea, 53% (without it, P&I u 1.00: Indonesia dominates) |
| CHA, IND, SSA, NES | 0.22 / 0.44 / 0.20 / 0.10 | 0.45 / 0.69 / 0.00 / 0.92 | China, India, South Africa, Turkey: 100% each |

The bands are narrow: the extremes come from the specification, not from imprecision (§3.4.3). From `v8` on, the
uncovered countries at the covered median dilute the single-country regions in proportion to their uncovered final
energy (observed share of final energy: SSA 14%, MEA 22%, OAS 39%, LAM 41%).

**The USA**, outside the CAPMF panel, is at the median under either rule (`basisOverride = c(USA = "median")` up to
`v7`). US federal policy spans states with world-leading regulation and states with almost none. **The USA must be
reported as a range** (on `v6`: USA donor +117.4, USA low +134.8 Gt).

**Provenance travels with the number.** Each region reports
`shareObserved / shareDonor / shareLowBand / shareMedian` (on `v8` the uncovered share is all `shareMedian`).

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
each market its own path times the anchor. The budget is always met. Not in the `v7` or `v8` batch.

**Mode L — $\varphi$ caps the increment** (`cm_pfmBindMode = 2`): the boxed form of §5.1, with
$\varphi(t)$ and **no speed limit**. The budget may become unreachable — **that is the finding, not a
bug.** $A$ must come from a path the cap cannot touch: reading it from the run's own capped price
makes the recursion a contraction onto $P^{\text{ref}}$ within a few calls (`SCENARIOS.md` §6.4).

**Mode M** (mild progression) is **retired** (ADR 0050): its mechanism was λ.

**Closures — mode L**, when the political bound and the budget cannot both hold:

| closure | mechanism | the headline it supports | `v8` rows |
|---|---|---|---|
| **hold the price** | pin the anchor to the θ = 0 budget-holding run (`cm_pfmAnchorFromGdx`), budget forcing off | *political feasibility adds $X$ Gt CO₂ to the 1000 Gt pathway by 2100* | `-PFM-holdPrice…` |
| **hold the budget** | keep the budget (`cm_iterative_target_adj = 9`), rebuild the cap every iteration from the live anchor and that period's share (`cm_pfmBoundRebuild = 1`; the reference price from `cm_pfmRefPrice`) | *the budget holds; the price rises and abatement moves* | `-PFM-holdBudget…` |
| delay | allow the budget to be met later | *politics delays the price path by $N$ years* | never run |

**What the `v8` batch shows** (θ = 0.50; `SCENARIOS.md` §4; `coupled-facts.json`):

| | EU21 | H12 |
|---|---:|---:|
| **hold the price**: Δ cumulative CO₂ 2020–2100 vs `-PFM-noPolitics-holdPrice-v8` | **+75.1 Gt** | **+64.3 Gt** |
| hold the price across θ 0.325 / 0.675 | +44.4 / +109.8 | +39.4 / +95.1 |
| hold the price, constant limit | +123.8 | — |
| **hold the budget**: cumulative CO₂ 2020–2100, every run | 995–1002 Gt | 995–1002 Gt |
| hold the budget: anchor 2050 vs θ = 0 | ×1.16 | ×1.14 |
| hold the budget: abatement moved between regions, 2020–2100 | 20.6 Gt CO₂eq | 17.9 Gt CO₂eq |

`v7` gave +98.8 / +87.9 Gt, ×1.21 / ×1.19 and 17.1 / 18.4 Gt CO₂eq: the `v8` overshoot is about a quarter smaller,
mainly through the coverage rule (§5.4) and the fossil terms' form (ADR 0062).

#### 5.6a The shrinking future — the sequential runs (`COUPLING.md` §14.1)

A **chain** of coupled runs, one **step** per decade. Step $t_s$ ∈ {2030, 2040, 2050, 2060, 2070} fixes every period
before $t_s$ to the previous step's solution (REMIND's `cm_startyear` and `path_gdx_ref`) and applies the political
limit only to its own decade:

$$\varphi^{(t_s)}_{r,s}(t) = \varphi_{r,s}(t)\ \text{ for } t_s \le t < t_s + 10,\qquad \varphi^{(t_s)}_{r,s}(t) = 1\ \text{ for } t \ge t_s + 10,$$

so after its decade a step plans as if the limit lifted: with the full anchor (hold the price) or with whatever meets
the budget from its fixed past (hold the budget). The last step leaves its window open; its run is the chain's result.
$P^{\text{ref}}$ comes from the current-policy run (`cm_pfmRefPrice = refpolicycost`), since `path_gdx_ref` now points
at the previous step. A step's run is two things: the realised path to the end of its decade, and the **plan** it made
for the rest, which the next step revises.

**On `v8`** (EU21, θ = 0.50; `analysis/v8/shrinkingFuture.R` → `coupling/shrinking-future.rds`; design note 0009 §22):

| cumulative CO₂ 2020–2100 | no-politics | one-shot | chain | chain − one-shot |
|---|---:|---:|---:|---:|
| hold the price | 1004.8 | 1079.9 (+75.1) | 1044.2 (+39.4) | −35.7 |
| hold the budget | 1001.5 | 996.1 | 996.3 | +0.2 |

- **Hold the price: the chain halves the overshoot at the same prices paid** (emissions-weighted mean 193 against 191
  $/t CO₂ in 2050, 407 against 407 in 2100; φ in each decade within ±0.005). Each step invests for the full price it
  expects after its decade, and the next step inherits that energy system: an **expectation channel** the one-shot run
  does not have. Each step under-promises: the plans for 2100 are +7.5, +11.5, +20.8, +24.6 Gt, the result +39.4.
- **Hold the budget: the effort moves later.** The chain emits 5.8 Gt more than the one-shot run in 2030–2060 and 5.9 Gt
  less after; its price is lower to 2070 and higher after (535 against 500 $/t CO₂ in 2100).
- **Reading.** The one-shot run assumes the limit is known to last; the chain assumes, every decade, that it will lift
  after the next. REMIND has perfect foresight within each step, so the expectation effect is as strong as that
  foresight. One θ, EU21, ten-year steps.

---

## 6. Selection stability (`selection-bootstrap.rds`, 200 resamples)

Selected specification `X-1791 … satAP iw:fexp fos5`. Top-**40** pool, 200 resamples; **37** pool members are rejected
by the full-sample sanity walk and are never eligible.

> ⚠️ **A raw selection frequency is not evidence.** The menu offers several accountability options;
> a selector choosing at random takes *some* accountability most of the time. Read every frequency
> against the menu and the pool.

| element | among winners | conditional on sanity-eligible winners |
|---|---:|---:|
| Government Effectiveness (`WGIge`) | **100%** | 100% |
| Rule of Law (`RoL`) *(selected)* | **100%** | 100% |
| channel set `WGIge|RoL|VerAcc` *(selected)* | **67.9%** | **82.7%** |
| channel set `WGIge|RoL|HorAcc` | 20.0% | 17.3% |
| channel sets with Overall / Diagonal accountability | 9.7% / 2.4% | — |
| actor power `bothIncAP` *(selected)* | **100%** | 100% |

**The selected specification.** Wins **1%** of resamples (**31%** conditional on the walk's rejections; 55% of the
resamples that yield an admissible winner, `specFreqConditional`; `v7`: 1% / 24% / 44%). The other conditional winners:
`X-1791 … satInn iw:fexp@accRoL fos5` (the weight scoped to accountability and rule of law) 27.3%,
`X-1860 WGIge|RoL|HorAcc … satInn iw:fexp fos5` 17.3%. **Every conditional winner is weighted and bounded.**

> ✅ **State capability and rule of law belong**: 100% of winners. ✅ **Fossil interests in both share and
> per-capita form belong**: `bothIncAP` 100%. ✅ **A democracy weight on the interactions belongs**: every
> conditional winner carries one.
>
> 🔴 **Which accountability channel, the weight's scope and which actor-power transform are not identified.**
> The selected channel set is now the raw majority too (67.9%); the transform splits about 55 / 45.

> **What may be claimed.** *State capability, rule of law, the two fossil terms and a democracy weight belong.*
> **Neither the channel set nor the specification is uniquely selected**; the selected specification is a 1% (31%
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
| Scenario results late in the century without their out-of-support share | A reporting duty since ADR 0052: 19% of guarded drivers out of support by 2100 (`v7`), the energy system beyond the observed range for most countries by 2050 (§2.3, §5.2) |
| Fossil rents in the ceiling | Against the theory in power & industry, γ at the boundary, gates failed; rents act on the slack only (§3.1a, ADR 0061) |
| A shrinking-future step's plan quoted as an outcome | Each step's plan for the years after its decade is revised by the next; the chain's result is its last step (§5.6a) |
| The buildings & transport contingency (H2) as established | It passes on the asymptotic $p$ only; not under the wild bootstrap, and fragile to dropping one country (§2.4a, §2.6) |
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
| Power & industry, with trend | 43.2 | **185.7** | .82 | 2.0 | 2e−32 |
| Power & industry, no trend | 21.0 | 137.8 | .88 | 7.7 | 7e−93 |
| Buildings & transport, with trend | −3.0 | 4.2 | .47 | 10.6 | 9e−22 |
| Buildings & transport, no trend | 4.6 | 12.7 | .72 | 4.5 | 2e−94 |

Three of four rungs are weakly instrumented ($F$ < 10), and no estimate is distinguishable from zero. **Do not
report the point estimates.** Report that endogeneity is confirmed at $p < 10^{-21}$ in every rung and
that the instrument cannot identify the effect — *we can show the relationship is endogenous; we
cannot show what it is.* Label the feedback **conditional scenario accounting**, and **do not write
"causes" anywhere near the loop.**

**8.2 The ceiling-feedback sign.** The feedback is live in both sectors: on the coupled 1000 Gt pathway the power &
industry strength falls to 0.63 by 2050 and buildings & transport to 0.62 (§5.2), and the median covered ceiling
rises (to 1.07 / 1.27 of its 2025 value by 2100). The power & industry direction rests on how fossil dependence
behaves at the low edge — bounded and saturating on `v8` (§2.3) — and on power & industry institution terms that are
not identified. In buildings & transport a second feedback acts through the rents: a higher carbon price lowers fossil
rents, the exporters' slack shrinks and their share rises (§3.1a). Part of that fading is not climate policy: rents
also fall in the current-policy world (MEA at 0.50 of 2025 by 2050; ADR 0061). It is not causal (§8.1).

**8.3 The exposure confound.** `Fossil × GovEff` (share) is **positive** where theory expects
negative — +0.209 in the power & industry mean regression (not significant), +0.439 on the power & industry
frontier, positive in six of seven estimators — and power & industry fossil interests per person is positive and
significant (+0.625). Large, capable fossil economies also regulate more; the model cannot tell exposure from
resistance. `v8` adds fossil rents, but on the slack of buildings & transport only: in the ceiling they raise power &
industry stringency (rent-rich democracies price strictly) and fail the gates (ADR 0061), so the confound stays open
in power & industry.

**8.4 The historical-replay gate — fails narrowly in buildings & transport on `v8`, and cannot discriminate.**
Running the coupled system over the historical panel (seed year 2000) must reproduce observed stringency at least as
well as the uncoupled ECM (`historical-replay.rds`, `$pass = FALSE` on `v8`; `TRUE` on `v7`):

| Sector | RMSE coupled | RMSE ECM | skill vs ECM | skill vs persistence | ceiling binds |
|---|---:|---:|---:|---:|---:|
| Power & industry | 0.815 | 0.815 | +0.001 | +0.727 | **0.27%** of rows |
| Buildings & transport | 0.529 | 0.520 | **−0.018** | +0.763 | 2.72% of rows |

> **Read the margin before the verdict.** The ceiling binds in under 3% of rows, so the coupled and uncoupled systems
> are almost the same model on history: on `v7` the "pass" was a tie, and on `v8` the buildings & transport "fail" is
> a 1.8% worse RMSE on the same rows. In the coupled runs the hold-the-price cap binds in about 94% of region-periods —
> a regime this gate says nothing about. **Disclose the `v8` verdict as it is**; the re-scoped check below is the
> discriminating one.

**Re-scoped to where it can discriminate** (`analysis/checks/replayRescoped.R v8` → `historical-replay-rescoped.rds`,
2026-11-01): on the rows where the coupled path differs from the uncoupled one — 46 power & industry country-years in 2
countries (4.2%; Switzerland, Saudi Arabia) and 202 buildings & transport in 9 (18.3%) — RMSE is 0.699 against 0.722
(skill **+0.031**) in power & industry and 0.663 against 0.620 (skill **−0.068**) in buildings & transport (mean pull
of the ceiling on those rows 0.13 index points). **Where the ceiling acts on history it improves the fit in power &
industry and worsens it in buildings & transport** (`v7`: +0.021 / +0.039; `v6`: +0.036 / +0.009). Report it as a
limitation (paper claim C21).

**8.5 The time trend does most of the explanatory work.**

| | Power & industry | Buildings & transport |
|---|---:|---:|
| $\hat\beta$ on $T(t)$ per SD, frontier | **0.974** | **0.481** |
| $\hat\beta$ on $T(t)$ per SD, mean regression (§2.5) | 1.298 | 0.620 |
| trend share of linear-predictor variance (§2.4) | **0.672** | **0.535** |

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

**8.6 What the energy system expects of politics.** The one-shot coupled run lets REMIND know that the limit lasts;
the shrinking future (§5.6a) lets every decade expect it to lift. Under hold the price the two bracket the overshoot at
+39 to +75 Gt (EU21, θ 0.50), with the same prices paid: expectations about future politics are a channel of the
same size as θ's range. The PFM has no estimate of what actors expect, and REMIND's perfect foresight within a step sets
the strength of the effect; five-year steps, version A (the limit known for the whole remaining horizon at each step)
and the θ range are open (`../communication/2026-11-shrinking-future/`).

---

## 9. Artifact map

All in `output/pfm/v8/` unless named (the analyses measured on `v7` are in `output/pfm/v7/`).

| Quantity | File | Path within |
|---|---|---|
| Selected specification | `selected-models-pfm.yml` | — |
| Every estimation number in this document | `doc-facts/facts.json` | written by `analysis/checks/docFacts.R v8` |
| ΔR²(theory), trend share, VIF, tier, maximin, gates, sanity walk | `sweep.rds`, `sanity-pool.rds` | `$results`, `$maximin`, `$theory`, `$sanity` |
| Selection sector by sector; net effects of the interacted terms | `per-sector-selection.rds`, `net-effects.rds`, `net-effects-X-2099.rds` | design note 0009 §§19–20 |
| The rents slack out of sample | `v8-het-slack-cv.rds` | — |
| Sharing cost, per-tier winners | `selection-variants.rds` | `$perSector`, `$winners` |
| Selection stability | `selection-bootstrap.rds` | — |
| Mean regression: coefficients, wild-cluster $p$, AMEs | `inference.rds` | `$bySector$<s>$table` |
| Sign agreement across 7 estimators | `estimator-agreement.rds` | `$bySector$<s>$agreement` |
| Leave-one-country-out influence | `influence.rds` | `$bySector$<s>$byTerm` |
| Shift-share IV | `iv.rds` | `$bySector$<s>.<variant>` |
| Frontier $\beta_F$, $\gamma$, LR, covariance check, rungs | `frontier.rds` | `$bySector$<s>$coefTable`, `$gamma`, `$lr`, `$vcovCheck`, `$robustness` |
| Rungs propagated to $E$ and φ | `frontier-rung-phi.rds` | `$minRule`, `$countryBind` |
| Ceilings, gaps, efficiency per country-year | `frontier.rds` | `$bySector$<s>$scores` |
| The anchor: $q$, $u$, weights, frontier design, the rents slack's anchor | `phi-anchor.rds` (staged in `output/remind-inputs/v8/`) | step `pfm-anchor` |
| λ, half-life, skill (2 and 4 sectors) — diagnostic | `temporal-validation.rds`, `sector-speeds.rds` | — |
| Historical-replay gate | `historical-replay.rds` | `$pass`, `$bySector$<s>$metrics` |
| Country projections | `projection.rds`, `projections/<scenario>.rds` | — |
| Coverage (the covered median), donors as diagnostics | `coverage/`, `donor-assignment-band-<sector>.rds` | — |
| Offline bound, efficiency analogy | `coupling/coupling-summary.rds` | `$anchorDerivation` |
| θ bounds, the strength decomposition (measured on `v7`) | `output/pfm/v7/coupling/theta-bounds.rds`, `efficiency-ratio-band.rds`, `coupling/strength-support.rds` | — |
| Coupled runs: prices, φ per market, convergence, run QC | `coupling/coupled-runs.rds` | `$runs`, `$prices`, `$phi`, `$convergence` |
| The shrinking future: each step's plan, the chain, the one-shot run | `coupling/shrinking-future.rds`, `fig-shrinking-future-*.png` | written by `analysis/v8/shrinkingFuture.R v8` |
| Every coupled number quoted in the docs | `coupling/coupled-facts.json`, `coupled-costs.json`, `convergence-audit.rds`, `rulec-bound-freeze.rds` | written by `runCoupledStage.R v8` |

**Code entry points.** `estimatePolicyStringencyModel()`, `computeFeasibilityFrontier()`,
`computeAnchorGap()`, `computeStrengthPath()`, `pfmV6Shares()`, `pfmV6CouplingDefaults()`,
`computeDonorAssignment()`, `runPFMTemporalValidation()`, `computeWildClusterBootstrap()`,
`projectFeasiblePath()`, `exportFeasibilityBound()`, `iterativePFM()`; the gates `.pfmEdgeGate()`,
`.pfmTheoryScreen()`, `.pfmTheoryCoherence()`; the weight `.pfmIwParse()`, `.pfmIwFactor()`; `v8`: the rents slack
(`estimatePolicyStringencyModel(slackDrivers)`, class `pfmHetFrontier`, `.pfmCeilingBeta()`,
`.pfmScenarioFossilRents()`), the institution rule (`pfmInstitutionProjection(rule = "gapclosure")`), the strength
forms and the window (`pfmCouplingV6.R`: `strength = regional | common | gapfirst`, `windowEnd`).
