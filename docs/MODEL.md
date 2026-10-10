# The Political Feasibility Model — definition and mathematics

*The canonical mathematical statement of the deployed PFM. A reader should be able to
implement the model, and evaluate it by hand, from this document alone.*

**Provenance.** Every number is Run-Group **`v6`** unless it says otherwise. Deployed spec
**`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP`**, country resolution,
n = 1104 = 48 countries × 23 years (2001–2023), IEA 2025 edition, five-year moving average,
geothermal in the clean-baseload control (ADR 0053), trend logistic (midpoint 2010, steepness 0.20,
standardized, frozen at 2023). Estimation-side numbers are collected by
`Rscript analysis/checks/docFacts.R v6` into `output/pfm/v6/doc-facts/facts.json`; the offline
formulation results (strength, anchors, bands) are in `output/pfm/v6/phase1/`. Re-read from those,
never from this page.

> **Coupled results** are from the `v6` REMIND 3.7.1 batch (64 runs, EU21 and H12, 2026-10-07 to
> 2026-10-10), in `output/pfm/v6/coupling/coupled-facts.json`. This document quotes only what the
> model definition needs; the full reading is `SCENARIOS.md`.

> **Some analyses were measured on `v5` and not re-run on `v6`**: the trend-shape grid (§2.3.1), the
> frontier rungs propagated to φ (§3.4.1), the λ placebo audit (§4.3.2) and the θ bounds (§5.3.1).
> They are kept, labelled "measured on `v5`", because their conclusions are about the method; their
> numbers are not `v6` numbers. The `v5` version of this document is
> `../_archive/_wip/2026-10-10/docs/MODEL-v5.md`.

**Scope.** The model *as deployed*. How the spec was selected is ADR 0036/0039/0045/0046/0052; the
`v6` formulation of the share is ADR 0049, 0050 and 0054. The REMIND interface is `COUPLING.md`
(§14 for `v6`). Traps are `PITFALLS.md`.

**Naming.** This document says **PFM** throughout (`pfm*` in code since 2026-10-02; artifacts of
`v5` and earlier may still carry `psm*`).

---

## 1. Notation

| Symbol | Meaning | Units / range |
|---|---|---|
| $c$ | country (48 in estimation; 248 projected) | — |
| $r$ | REMIND region (21 at EU21, 12 at H12) | — |
| $t$ | year | 2001–2023 estimation; 2025–2150 projection |
| $t_a$, $t_0$ | anchor year (last panel year, **2023**); reference year of the strength (**2025**) | — |
| $s$ | sector: Bulk (electricity + industry) or Diffuse (buildings + transport) | — |
| $S_{c,t,s}$ | observed CAPMF policy-stringency index | $[0,10]$ |
| $M$ | structural index ceiling, `indexMax` | $10$ |
| $y^{*}$ | transformed response, $\operatorname{logit}(S/M)$ squeezed | $\mathbb{R}$ |
| $\eta$ | linear predictor | $\mathbb{R}$ |
| $A^{\text{in}}$ | Innovator Power, **share**, saturating (§2.3) | standardized |
| $A^{\text{ic}}$ | Incumbent Power, **share** — the dependence / lock-in channel, saturating | standardized |
| $A^{\text{ic,pc}}$ | Incumbent Power **per capita** = share × primary energy per capita — the scale channel, saturating | standardized |
| $G$ | Government Effectiveness (WGI) — state capability | standardized |
| $R$ | **Rule of Law (V-Dem)** — new in `v6` | standardized |
| $V$ | Vertical Accountability (V-Dem) — electoral accountability of rulers to citizens | standardized |
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
| $\kappa$ | declared erosion of the strength (one sensitivity arm, ADR 0050) | per year |
| $\lambda_s$ | ECM adjustment speed — a reported diagnostic only, **not in the `v6` coupling** (§4) | per year |
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

**Boundary check.** 5.1% of Bulk rows and 0.4% of Diffuse rows sit at exactly 0; **no** row sits
at the maximum (`frontier.rds` scores, `v6`). That is the empirical gate that closed the two-limit
Tobit rung as unnecessary.

### 2.2 The deployed specification

`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp satAP`, fitted separately per
sector on an identical design (the Shared Specification rule):

$$
\begin{aligned}
\eta_{c,t} = \;&\alpha
+ \sum_{a\in\{\text{in},\text{ic},\text{ic,pc}\}} \beta_a A^{a}
+ \beta_G G + \beta_R R + \beta_V V
+ \sum_{a}\sum_{k\in\{G,R,V\}} \delta_{a k}\, A^{a}\!\cdot\! k \\
&+ \tau\, T(t) + \boldsymbol\psi'\mathbf{z}
+ \mu_{\text{OECD}}\mathbb{1}[c \in \text{OECD}] + \mu_{\text{other}}\mathbb{1}[c \in \text{other}]
\end{aligned}
$$

Three actor-power terms, three institutions, **nine interactions**, three controls $\mathbf{z}$ (GDP
per capita Q-centred, log population, clean-baseload share: hydro, nuclear and geothermal) and the
trend: **19 slope terms**. **No lagged outcome, no Mundlak, levels transform; the three actor-power
terms saturate** (`satAP`, §2.3). The drivers enter at $t-1$; the lag counts years, so on a scenario
panel in REMIND's 5- to 20-year steps the driver at $t-1$ is interpolated (`PITFALLS.md` §31).

Two estimators use this design and they are **different estimands** — never compare their
coefficients as though one were a refit of the other:

| | estimator | what it estimates | inference | artifact |
|---|---|---|---|---|
| **mean regression** | satP: `glm(gaussian(identity))` on $y^{*}$ | conditional **mean** of $y^{*}$ | country-clustered CR1; wild-cluster bootstrap-$t$, $B$ = 999, $G$ = 48 | `inference.rds` (§2.5) |
| **frontier** | half-normal SFA on $y^{*}$ | conditional **maximum attainable** $y^{*}$ | ML standard errors (no clustered sandwich exists for the SFA likelihood), checked by `vcovCheck` | `frontier.rds` (§3.3) |

The coupling consumes only the frontier. The mean regression is the inferential companion that
the selection metrics (ΔR²(theory), significance counts) are computed on.

> *In words:* stringency is explained by how strong the clean-energy coalition is, how dependent
> the economy is on fossil incumbents and how large they are per person, how capable the state is,
> how firmly the rule of law holds, how accountable rulers are to voters, **how those forces
> multiply each other**, a common time trend, and a coarse three-way group effect.

### 2.3 The components

**Actor power** (`actorPowerIndex()`), computed from the IAM's own energy system — this is the
channel through which a REMIND pathway talks back to the model:

$$A^{\text{in},\text{Bulk}} = \frac{1.0\,\text{VRE} + 0.6\,\text{Elec}}{1.6},\qquad
A^{\text{ic},\text{Bulk}} = \frac{1.0\,\text{Coal} + 1.0\,\text{OilGas} + 0.5\,\text{FossInd}}{2.5}$$

$$A^{\text{in},\text{Diffuse}} = \frac{0.5\,\text{VRE} + 1.0\,\text{Elec} + 0.4\,\text{Biofuel}}{1.9},\qquad
A^{\text{ic},\text{Diffuse}} = \frac{0.2\,\text{Coal} + 0.2\,\text{OilGas} + 1.0\,\text{FossInd}}{1.4}$$

$$A^{\text{ic,pc}} = A^{\text{ic}} \times \text{primary energy per capita}$$

Weights are fixed design constants, not estimated.

**Saturation (`satAP`, family A; ADR 0040, 0052).** Each actor-power driver enters as
$x/(x+\bar x)$, with $\bar x$ the training median, before standardization. The curve is steepest at
zero and flattens above the median, so no share extrapolates linearly into a range no country has
occupied. Family A saturates innovators **and** incumbents; family B (`satInn`, innovators only) is
the SI alternative (`v6-specalt`, §5.3.0). The two families differ only below the observed range:
in the 1000 Gt pathway in 2050, 56% of countries sit below the training 5th percentile of the Bulk
incumbent share and 59% above the innovator maximum (ADR 0052). The half-saturation point ($\bar x$
at 0.5×, 1×, 2× the median) is a main-text robustness check.

**The `bothIncAP` form (ADR 0044, ADR 0045).** Incumbency enters twice — as a share (how
dependent the energy system is) and per capita (how large the incumbent interest is) — which
nests both the share-only and per-capita-only forms. Innovator power enters as a share.

> 🔴 **The two incumbency channels pull in OPPOSITE directions, and only the pair is
> interpretable.** On the frontier the Bulk share is **−0.615** and the per-capita term **+0.352**;
> in Diffuse −0.154 and +0.100 (§3.3). Their interactions with the institutions differ in sign too.
> A sentence that names one channel and not the other inverts the sign of the other half. The
> channels are not orthogonal (share × energy per capita), so this is a decomposition, not two
> independent findings. The marginal effects across government effectiveness are Fig 2b
> (`fig-marginal-effect-incumbency.R`), read from the frontier covariance.

**The split form is load-bearing.** A composite $A = A^{\text{in}} - A^{\text{ic}}$ makes
projections *scenario-blind* under the extrapolation guard. Splitting keeps the feedback channel
alive. **Never revert.**

**Institutional channels.** $G$ = WGI Government Effectiveness; $R$ = V-Dem Rule of Law (new in
`v6`; the bootstrap carries it in 86% of winners, §6); $V$ = V-Dem Vertical Accountability. The
institution series are harmonised to the anchor year in every scenario (ADR 0051). **The Bulk
institution terms are not identified** (§2.5, §3.3).

**Smoothing.** `panelDataHistorical(movingAverage = 5)` applies a centred five-year moving average
(window shortened at the panel ends, so 2023 = mean of 2021–2023) to every panel column after
normalisation, the outcome included. Annual data are a robustness rung, the sibling Run-Group
`v6-annual` (ADR 0053).

**Standardization.** Every driver and interaction factor is standardized on the estimation rows;
means/SDs are **frozen** in `driverScaling` and reused for scenario panels. Coefficients are per
standard deviation — including the trend.

**Time trend.** Logistic in calendar year, evaluated at $\min(t, 2023)$ for any projection year,
then standardized like every other driver:

$$T(t) = \big[1+\exp(-k(t-m))\big]^{-1},\qquad m = 2010,\; k = 0.20$$

Read the shape from the artifact, never from here: `manifest.json$trend` and
`selected-models-pfm.yml`.

> *In words:* a time effect cannot be extrapolated, so it is held at its last historical value
> and the scenario drivers — not the calendar — carry all future differentiation.

**Fixed effects.** `regionmapping_EU_OECDp.csv` → three blocks: **EU** (reference), **OECD**
non-EU, **other**. Country dummies are an agreement rung only.

#### 2.3.1 The trend shape is DECLARED, not selected (measured on `v5`)

The trend shape is not a selection dimension: `createChannelConfigs()` hard-codes one $(m,k)$. On
`v5` (`analysis/checks/trendShapeGrid.R v5`) the deployed 2010 / 0.20 was within 4.1 logLik of the
best shape in Bulk and 21.2 worse in Diffuse at equal parameter count, and the best-fitting shapes
moved φ by a median 0.006–0.027 — the smallest φ uncertainty measured. It is kept for the reasons
recorded there: interior and near-best in Bulk, one shape for both sectors (the Shared
Specification rule), and a better-fitting trend absorbs more of the variance the selection rule
penalises. **Not re-measured on `v6`.** Describe it as a declared choice.

### 2.4 Fit of the deployed spec (`sweep.rds`)

| | Bulk | Diffuse |
|---|---:|---:|
| ΔR²(theory) | **0.131** | **0.175** |
| pseudo-R² | 0.730 | 0.794 |
| trend share of linear-predictor variance | 0.733 | 0.558 |
| max VIF | 7.74 | 7.89 |
| significant actor-power / institution / interaction terms | 6 / 4 / 4 | 5 / 5 / 4 |
| smallest significant theory $\lvert t\rvert$ | 2.17 | 2.28 |
| tier | Green | Green |
| $n$ | 1104 | 1104 |

**Selection position.** 7,296 specifications ranked; **891** pass the admissibility gates. The
deployed spec is **rank 6** on the maximin rule (mean ΔR²(theory) 0.153, minimum 0.131, ΣBIC 4633,
fragility 0): the **sanity walk** rejected the five ahead of it (four to seven severe flags each)
and accepted it with 0 severe flags and 97 warnings (`forced = FALSE`). Two specs ahead of it were its
own `satInc` twin and a near-twin (`X-1794`).

Gates in force: `supportShareGate` **0.275** (ADR 0045, extended to the actor-power forms by ADR
0052), `ceilingFallGate` 0.90 (ADR 0043; the deployed spec ends at 1.21 / 1.27 of its 2025 ceiling
on the 1000 Gt pathway, ADR 0052), `gammaGate` 0.999 (ADR 0046), VIF hard 10 / soft 6.

> ⚠️ **Rank 6 is not dominance.** The best *per-sector* specifications fit more: Bulk `X-1791 …
> satInn` reaches ΔR² 0.140 and Diffuse `X-1854 … satInc` 0.198 — a **sharing cost** of 0.009 (6.4%)
> in Bulk and 0.023 (11.6%) in Diffuse (`selection-variants.rds`).

### 2.5 Fitted coefficients — mean regression (`inference.rds`)

Deployed spec, country-clustered, $G = 48$, $n = 1104$. $p_{\text{wild}}$ is a Rademacher
wild-cluster bootstrap-$t$, $B$ = 999 — **these are the quotable $p$-values**; 48 clusters is too
few for asymptotic inference, and $p_{\text{asym}}$ is shown so the gap is visible. AME is the
average marginal effect in index points per SD (§2.7).

| Term | Bulk $\hat\beta$ | $p_{\text{asym}}$ | $p_{\text{wild}}$ | AME | Diffuse $\hat\beta$ | $p_{\text{asym}}$ | $p_{\text{wild}}$ | AME |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Innovator Power | −0.194 | .065 | .079 | −0.288 | 0.015 | .825 | .847 | 0.029 |
| Incumbent Power (share) | **−0.645** | .010 | **.030** | −0.956 | **−0.180** | .001 | **.006** | −0.349 |
| Incumbent Power (pc) | **0.478** | <.001 | **.007** | 0.709 | 0.110 | .183 | .298 | 0.214 |
| Gov. Effectiveness | 0.113 | .536 | .608 | 0.168 | **0.279** | .002 | **<.001** | 0.541 |
| Rule of Law | 0.049 | .858 | .893 | 0.073 | −0.161 | .076 | .073 | −0.312 |
| Vertical Accountability | 0.136 | .630 | .703 | 0.202 | 0.208 | .086 | .076 | 0.402 |
| Innov × GovEff | **−0.257** | .005 | **.012** | −0.381 | 0.056 | .435 | .515 | 0.108 |
| Innov × RoL | 0.336 | .083 | .145 | 0.498 | 0.138 | .135 | .191 | 0.268 |
| Innov × VerAcc | −0.111 | .495 | .536 | −0.165 | **−0.296** | .023 | **.034** | −0.574 |
| Incumb × GovEff | 0.180 | .357 | .497 | 0.268 | 0.096 | .096 | .096 | 0.185 |
| Incumb × RoL | 0.721 | .095 | .194 | 1.069 | **0.317** | .007 | **.018** | 0.614 |
| Incumb × VerAcc | −0.778 | .030 | .078 🔴 | −1.153 | **−0.492** | <.001 | **<.001** | −0.954 |
| Incumb pc × GovEff | **−0.565** | <.001 | **.001** | −0.839 | −0.071 | .474 | .554 | −0.137 |
| Incumb pc × RoL | **0.737** | <.001 | **<.001** | 1.094 | −0.114 | .217 | .309 | −0.221 |
| Incumb pc × VerAcc | −0.125 | .214 | .311 | −0.185 | **0.290** | <.001 | **<.001** | 0.561 |
| GDP p.c. (Q-centred) | 0.123 | .172 | .237 | 0.182 | −0.050 | .316 | .413 | −0.096 |
| Population (log) | **0.360** | <.001 | **.002** | 0.533 | **0.273** | <.001 | **<.001** | 0.528 |
| Clean baseload share | −0.178 | .197 | .223 | −0.264 | 0.031 | .549 | .626 | 0.059 |
| Logistic trend | **1.347** | <.001 | **<.001** | 1.998 | **0.640** | <.001 | **<.001** | 1.240 |

> 🔴 **One theory term changes verdict under the bootstrap**: Bulk `Incumb × VerAcc` (.030 → .078).
> **Do not report it as significant.** No term the asymptotic $p$ calls insignificant is rescued.

**What the table says, on signs and wild $p$:**

- **No institution main effect is significant in Bulk** ($p_{\text{wild}}$ .61 / .89 / .70), and the
  Bulk frontier gives GovEff and VerAcc the opposite sign (§3.3). **The Bulk institution terms are
  not identified** (ADR 0052) — and part of the Bulk strength's fall rests on them (§5.2a).
- **State capability is significant in Diffuse** (GovEff +0.279, $p_{\text{wild}}$ <.001; positive in
  6 of 7 estimators in both sectors, §2.5.1).
- **Incumbency, as a share, lowers stringency in both sectors** (−0.645 Bulk, −0.180 Diffuse);
  **per capita it raises Bulk stringency** (+0.478) — the dependence and scale readings the design
  carries both for, and the positive scale term is a disclosed tension (§8.3).
- **The interactions carry most of the institutional signal**: in Bulk the per-capita incumbency
  terms with GovEff (−0.565) and RoL (+0.737); in Diffuse the incumbency share with RoL (+0.317) and
  VerAcc (−0.492), the per-capita term with VerAcc (+0.290), and innovators with VerAcc (−0.296).
- **Population and the trend are significant in both sectors.**

#### 2.5.1 Sign stability across estimators (`estimator-agreement.rds`)

Seven estimators on the same design — satP, fractional logit, beta, levels OLS, satP random
effects, satP with year FE, levels two-way FE. A term's sign **agrees** if all agree (the trend is
absent from the year-FE estimators):

| | Bulk | Diffuse |
|---|---|---|
| terms with every sign agreeing | **7 of 19** | **9 of 19** |
| which | `Incumb pc × GovEff` (−), `Incumb pc × RoL` (+), `Incumb × GovEff` (+), `Incumb × RoL` (+), `Incumb × VerAcc` (−), `Innov × VerAcc` (−), trend (+) | GDP (−), `Incumb` share (−), `Incumb pc` (+), `Incumb pc × GovEff` (−), `Incumb pc × VerAcc` (+), Innovator (+), `Innov × GovEff` (+), `Innov × VerAcc` (−), trend (+) |
| GovEff | + in 6, − in 1 | + in 6, − in 1 |

> ⚠️ **Sign agreement is weak in Bulk.** Twelve of nineteen Bulk terms change sign somewhere in the
> battery, the institution main effects among them.

### 2.6 How much of this survives dropping one country (`influence.rds`)

Leave-one-country-out over the 48 clusters, α = 0.05. $p_{\max}$ is the worst $p$ across the 48
refits; **pivotal** counts the countries whose removal alone flips the term's verdict. The terms
significant at full sample:

| Term | $p$ | $p_{\max}$ over refits | pivotal | verdict |
|---|---:|---:|---|---|
| **Bulk** Incumbent Power (pc) | .001 | .049 | — | robust |
| Bulk Incumb pc × GovEff | <.001 | .005 | — | robust |
| Bulk Incumb pc × RoL | <.001 | .0007 | — | robust |
| Bulk Innov × GovEff | .008 | .041 | — | robust |
| Bulk Incumbent Power (share) | .013 | .243 | 2 — IND, RUS | 🟠 holds except two |
| Bulk Incumb × VerAcc | .035 | **.522** | **7** — CHN, CRI, HUN, IND, ISL, LTU, ZAF | 🔴 fragile |
| **Diffuse** Incumbent Power (share) | .002 | .195 | 1 — RUS | 🟠 borderline |
| Diffuse GovEff | .003 | .193 | 1 — ISL | 🟠 borderline |
| Diffuse Incumb × VerAcc | <.001 | .051 | 1 — CRI | 🟠 borderline |
| Diffuse Incumb pc × VerAcc | <.001 | .761 | 2 — CHN, SAU | 🟠 holds except two |
| Diffuse Incumb × RoL | .009 | .283 | 2 — ISL, RUS | 🟠 holds except two |
| Diffuse Innov × VerAcc | .027 | .897 | 2 — CRI, SAU | 🟠 holds except two |

Terms not significant at full sample whose removal of one country would *create* significance
exist in both sectors (Bulk Innovator Power: seven countries; Diffuse RoL: six; Diffuse VerAcc: five).
**No claim rests on any of them, and dropping a country to obtain a result is exactly what must
not be done.**

#### 2.6.1 One country with leverage: Saudi Arabia

SAU is the top influencer on **six of fifteen** Diffuse theory terms (every innovator and per-capita
interaction) and on three Bulk terms, and pivotal in Diffuse `Incumb pc × VerAcc`, `Innov × VerAcc`,
`Innov × GovEff` and `Incumb pc × GovEff`. On the `v5` panel it combined the lowest Vertical
Accountability in the sample (z −4.63) with the highest incumbency per capita in both sectors (z
+3.50 Diffuse, +3.21 Bulk) — the exact plane the accountability × incumbency interactions identify.
The conjunction has n = 1. **No control fixes this**: the binding constraint is support, and no
covariate creates data where there is none (§2.7).

### 2.7 Marginal effects

Because the response is non-linear, report average marginal effects on the natural scale:

$$\text{AME}_k = \frac{1}{N}\sum_{c,t} M\,\operatorname{logit}^{-1}(\eta)\big(1-\operatorname{logit}^{-1}(\eta)\big)\frac{\partial\eta}{\partial x_k}$$

with $\partial\eta/\partial x_k$ including interaction terms and delta-method clustered SEs;
tabulated in §2.5 and persisted in `inference.rds`. Every driver is standardized, so every AME is per
SD. Examples: Diffuse **GovEff** AME **0.541** index points per SD (SE 0.172); Bulk **Incumbent Power
(pc)** **0.709** (SE 0.197), the largest identified Bulk main-effect AME and the one whose sign needs
the §8.3 caveat.

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

| | Bulk | Diffuse |
|---|---:|---:|
| $\gamma = \sigma_u^2/\sigma^2$ | **0.9968** | **0.9715** |
| $\sigma^2$ | 2.128 | 0.465 |
| LR test against OLS | 524.8 | 294.0 |
| logLik | −1256.2 | −503.8 |
| covariance check (`vcovCheck`) | ok, ratio 0.90 | ok, ratio 0.98 |
| converged | yes | yes |

**Frontier coefficients** (ML standard errors; $p$ asymptotic — see §2.2 for why there is no
clustered alternative):

| Term | Bulk $\hat\beta_F$ | $p$ | Diffuse $\hat\beta_F$ | $p$ |
|---|---:|---:|---:|---:|
| Innovator Power | −0.032 | .20 | **0.101** | <.001 |
| Incumbent Power (share) | **−0.615** | <.001 | **−0.154** | <.001 |
| Incumbent Power (pc) | **0.352** | <.001 | **0.100** | <.001 |
| Gov. Effectiveness | **−0.308** | <.001 | **0.241** | <.001 |
| Rule of Law | **0.393** | <.001 | −0.090 | .056 |
| Vertical Accountability | **−0.289** | .008 | **0.231** | <.001 |
| Innov × GovEff | **−0.170** | <.001 | 0.033 | .14 |
| Innov × RoL | **0.255** | <.001 | **0.145** | <.001 |
| Innov × VerAcc | −0.056 | .17 | **−0.292** | <.001 |
| Incumb × GovEff | **0.194** | <.001 | **0.105** | <.001 |
| Incumb × RoL | **0.510** | <.001 | **0.309** | <.001 |
| Incumb × VerAcc | **−0.326** | .033 | **−0.536** | <.001 |
| Incumb pc × GovEff | **−0.569** | <.001 | **−0.111** | <.001 |
| Incumb pc × RoL | **0.814** | <.001 | **−0.090** | .007 |
| Incumb pc × VerAcc | **−0.252** | <.001 | **0.250** | <.001 |
| GDP p.c. (Q-centred) | **0.110** | <.001 | 0.013 | .34 |
| Population (log) | **0.222** | <.001 | **0.251** | <.001 |
| Clean baseload share | −0.065 | .18 | **0.053** | .004 |
| Logistic trend | **0.966** | <.001 | **0.501** | <.001 |
| FE OECD / other (vs EU) | −0.006 (.91) / **−0.972** (<.001) | | **−0.119** (.002) / **−0.303** (<.001) | |

> ⚠️ **The two estimators disagree about Bulk institutions.** The mean regression finds no Bulk
> institution main effect (GovEff +0.113, RoL +0.049, VerAcc +0.136, all $p_{\text{wild}}$ > .6); the
> frontier finds GovEff **−0.308** and VerAcc **−0.289**, RoL **+0.393**. They estimate different
> things — the average versus the attainable maximum — but a sign flip on GovEff means "state
> capability raises the Bulk *ceiling*" is **not** a supported sentence, and nor is its negation. In
> Diffuse both estimators agree on GovEff (+0.279 mean, +0.241 frontier).
>
> ⚠️ **Frontier $p$-values are ML and understate uncertainty.** On `v5` the design effect of country
> clustering on the same design ran 2.2× (Bulk) and 3.1× (Diffuse) in the mean regression (§5.3.1).
> Quote frontier signs; quote mean-regression $p$.

### 3.4 ⚠️ The $\gamma$ caveat — read before using any ceiling

$\gamma$ = 0.997 / 0.972 attributes nearly all composed error to slack. Both are inside the γ gate
(0.999, ADR 0046); **Bulk γ = 0.997 was accepted at the Phase 2 gate with disclosure** (ADR 0053,
author decision 4), close enough to 1 that the noise/slack split is weakly identified and the *level*
of a single country's ceiling is the least trustworthy thing the model produces. The coupling reads
the ceilings as an **ordering** (§5.2). The robustness battery re-estimates under three alternative
error structures; $\rho$ is the Spearman correlation of country slack ranks against the headline:

| Rung | Bulk $\gamma$ | Bulk $\rho$ | Diffuse $\gamma$ | Diffuse $\rho$ |
|---|---:|---:|---:|---:|
| headline (pooled half-normal) | **0.9968** | — | **0.9715** | — |
| truncated-normal $u$ | 0.998 | 0.50 | 0.978 | **0.78** |
| panel (Battese–Coelli 92) | 0.929 | 0.30 | 0.981 | 0.35 |
| time-decay (BC), $\eta$ | 0.058, $\eta$ = 0.157 | 0.16 | 0.285, $\eta$ = 0.109 | **0.63** |

> 🔴 **Bulk slack ranks are not robust on any rung** (0.50 / 0.30 / 0.16). Diffuse holds on two of
> three (0.78 / 0.63) and weakens on the panel rung (0.35). **Report tiers, never named country
> rankings of slack, in both sectors.**

#### 3.4.1 Propagated to what the coupling consumes (measured on `v5`)

`slackRankCor` ranks countries on absolute slack, which the coupling never sees; it consumes $E$,
then $\varphi$. On `v5` (`analysis/checks/propagateFrontierRungsToPhi.R v5`) the truncated-normal rung
barely moved φ (Spearman 0.96, median |Δφ| 0.024 at EU21), but the panel rung reordered it (0.53)
and the decay rung moved it by a median 0.171 — the size of a θ step — and the sector that binds
changed in 11 of 20 regions across rungs. **The frontier error structure is a first-order uncertainty
in φ**, and rank intervals across rungs (`rankInterval`) are a range over fitted models, not a
sampling interval. **Not re-run on `v6`**; until it is, quote this as the `v5` measurement.

#### 3.4.2 The sector ordering in the estimation sample

On $E$ read straight out of `frontier.rds`, **Bulk is the more constrained sector in 32 of 48
countries at 2023** (median $E$: Bulk 0.736, Diffuse 0.780). The coupled regional ranking agrees in
`v6` (Bulk binds in 15 of 21 EU21 regions and 11 of 12 H12 regions, `SCENARIOS.md` §6.2a); in `v5`,
whose φ was read after a λ projection to 2035, it did not.

**`projection.rds$implementability` is $S/10$, not $E$** (`computeImplementabilityFactor()` is
`index / indexMax`). Nothing in the coupling reads it; any offline figure built from that column is
on the prohibited measure (§7).

---

## 4. Dynamics: the ECM — a reported diagnostic, not in the coupling

> **ADR 0050: λ leaves the `v6` coupling.** The error-correction model stays in `pfm-temporal` as a
> reported finding (forecast skill, placebo). No λ enters any `v6` price; the only gap-closure
> assumption is the declared κ arm (§5.2a).

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
| Bulk | 0.117 | 5.6 y | −0.156 | −0.700 | 0.54 |
| Diffuse | 0.074 | 9.1 y | −0.827 | −0.733 | 0.39 |

| Four sectors | $\lambda$ | $t_{1/2}$ | skill |
|---|---:|---:|---:|
| Electricity | 0.121 | 5.4 y | **+0.014** |
| Industry | 0.174 | 3.6 y | −0.435 |
| Buildings | 0.108 | 6.1 y | −0.660 |
| Transport | 0.162 | 3.9 y | −1.09 |

> **Only electricity is level with "assume nothing changes"**, and only just. Everything else is a
> descriptive rate, not a forecast. The static level forecast loses to persistence in both sectors —
> which is why this model delivers ceilings and rankings and never level paths.

#### 4.3.1 Why λ cannot carry a coupling (ADR 0050)

λ does not beat persistence, and on annual data it is 1.7× (Bulk) and 4× (Diffuse) the smoothed
value, largely a smoothing artefact (0005 §2). In `v5` it set the speed of the 2022 → 2035 projection
and of the price bound; removing it is most of the `v5` → `v6` change in the quantity headline
(offline: the 2050 price shortfall is 39% under the `v5` formulation and 18% under `v6`; putting a
`v5`-style λ speed limit back on the `v6` shares gives 48%; `output/pfm/v6/phase1/offline-headline.rds`).

#### 4.3.2 What the λ audit found (measured on `v5`)

On `v5` a placebo battery on panels built with no adjustment by construction returned
λ̂ **0.291 [0.181, 0.419]** (Bulk) and **0.104 [0.062, 0.209]** (Diffuse): the published Bulk rate sat
below its null and the Diffuse rate inside it, and two-thirds of Diffuse countries had a non-positive
own-country λ (`output/pfm/v5/lambda-explained/`). The pooled λ measures the estimator's pull on a
bounded, trending index, not a demonstrated political adjustment. Not re-run on `v6`.

---

## 5. The feasibility share $\varphi$

> **No index→price exchange rate (ADR 0041).** A bounded index times a constant is a bounded price
> cap that makes ambitious scenarios infeasible for an arithmetic reason rather than a political one.
> (The κ of ADR 0041 is unrelated to the declared erosion κ of §5.2a.)

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
population, the harmonised institution projections); the distance does not. Uncovered countries
take $y$ from the band rule (§5.4).

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

**What the strength does, offline** (`phase1/strength.rds`, EU21, REMIND 3.7.1 bases): Bulk $k$ falls
to **0.63 / 0.49** in 2050 / 2100 on the 1000 Gt energy system and stays near 1 on current policies
(1.09 / 0.92); Diffuse 0.86 / 0.72 and 0.66 / 0.70. The difference between the two is the
energy-system feedback. One driver group moving at a time (1000 Gt, 2100): actor power alone gives
Bulk **0.34** (Diffuse 1.02), institutions alone **1.29** (0.94), income and population alone 0.91
(1.00). **In Bulk the energy transition relaxes the constraint and better institutions tighten it**,
through Bulk institution terms that are not identified (§2.5) — hence the institutions-held twins.
Out of training support: 2% of weighted drivers in 2025, 6% in 2050, 11% in 2100, reported with
every $k(t)$.

**Coupled** (θ = 0.50, `coupled-facts.json`): Bulk $k$ **0.686 / 0.525** (EU21) and 0.684 / 0.516
(H12) in 2050 / 2100 — the coupled energy system relaxes the constraint a little less than the
uncoupled base. In 2025 ($k = 1$) the floor regions are **CHA** (Diffuse) and **IND** (Bulk) at both
resolutions; the top region NEN (0.900, EU21) / NEU (0.869, H12).

#### 5.2a Options on the strength (each one declared arm; `COUPLING.md` §14)

| option | form | headline | arm |
|---|---|---|---|
| **κ, declared erosion** | $k_s(t)\,(1-\kappa)^{t-2025}$ | κ = 0 | 0.027 central (half-life 25 y), 0.02, 0.05; fixed 2026-10-08 before any run (ADR 0050 decision 5) |
| hold year | drivers held after 2060 | none (to 2100) | `pfmPhiHoldYear = 2060` |
| E-hold | hold $E$ instead of $q$ (static share, $k \approx 1$) | logit hold | `pfmPhiHold = ratio` |
| regional strength | $k_{r,s}(t)$ per region | common | `pfmPhiStrength = regional` |
| ordering | $u$ uniform, permuted or reversed | the model's | `pfmPhiOrdering` |
| institutions | held at their anchor values | harmonised projection | `pfmInstitutions = hold` |

### 5.3 $\theta$ is declared and swept, not estimated

No historical experiment assigned carbon prices by political gap, so $\theta$ is not identified.

| $\theta$ | role |
|---:|---|
| **0** | uncoupled null — every φ = 1 (`-PFMgate-v6`, `-PFMgateBfix-v6`) |
| **0.325** | declared low point of the sweep |
| **0.50** | **declared central value** (`cm_pfmTheta`); every headline uses it |
| **0.675** | declared high point, symmetric about 0.50 |

**The efficiency analogy, and why it anchors nothing.** Solving $1-\theta\bar u=\bar E$ for the median
region (`coupling-summary.rds$anchorDerivation`, region resolution, 2025, $n$ = 21) gives θ = **0.372**
(Bulk: median $E$ 0.743, median $u$ 0.690) and **0.468** (Diffuse: 0.784, 0.461). Both are admissible
on `v6` — on `v5` Bulk was not — but the analogy is resolution-dependent ($u$ is normalised over
whatever units the frame holds) and **no θ value may be called "the efficiency anchor"**.

**Offline, what θ and the formulation do** (`phase1/offline-headline.rds`, EU21, one round, θ = 0.50,
median 2050 price shortfall against the cost-optimal path): `v5` formulation 39%; `v6` φ(t) 18%; `v6`
with φ held at 2025 ($k = 1$) 24%; `v6` with a `v5`-style λ speed limit 48%. **Coupled**, rule B adds
+73.0 / +118.2 / +181.5 Gt CO₂ by 2100 at θ = 0.325 / 0.50 / 0.675 (EU21), 264 Gt per unit θ
(`SCENARIOS.md` §4.6).

#### 5.3.0 $\varphi$ is also specification-dependent

The specification is as undetermined as θ: the deployed spec wins **2.5%** of bootstrap resamples
(15% conditional on sanity-eligible winners, §6). Nine specifications pass every gate, and they split
on the actor-power transform (ADR 0052; `phase1/spec-band.rds`): **family A** (both groups saturate,
deployed) gives a Bulk $k_{2050}$ of **0.63–0.90** on the 1000 Gt energy system, **family B**
(innovators only) **0.86–1.22**. The bootstrap splits about 49 / 51 between them. The half-saturation
point moves Bulk $k$ to 0.57 / 0.40 (0.5×) and 0.75 / 0.63 (2×) in 2050 / 2100 against 0.63 / 0.48.

**Coupled** (rule B, θ = 0.50, EU21, `SCENARIOS.md` §4.9): family B `X-2079 satInn` +107.5 Gt against
+118.2 deployed; saturation 0.5× / 2× +115.2 / +130.0; annual data +164.4 (its Bulk $k$ stays above 1).

> **The discipline this implies.** $\varphi$ is a property of a region **given a specification, a
> frontier error structure and a declared severity**, never a measured property of the region.
> Report it as a declared choice with a disclosed band. Family A is the main text; family B, the
> shape and the annual rung are the band.

#### 5.3.1 Routes to θ other than declaring it

| route | what it needs | what it buys | verdict |
|---|---|---|---|
| **1. Declare + sweep** *(deployed)* | nothing | honesty; θ becomes a scenario axis | **deployed**; the sweep *is* the deliverable |
| **2. Efficiency analogy** | median $E$ and median $u$ | one point | admissible on `v6`, resolution-dependent (§5.3) |
| **3. Price–efficiency elasticity** | a carbon-price panel + the stringency panel | an *empirical* θ range | the most promising; open |
| **4. Calibration** | observed regional price dispersion | θ that best reproduces history | feasible, circular risk |
| **5. Partial identification (bounds)** | revealed-preference restrictions | an interval | computed on `v5` (below) |
| **6. Expert elicitation** | a structured protocol | a documented prior | out of scope |

**Route 5, measured on `v5`** (`computeThetaBounds.R v5`, `efficiencyRatioBand.R v5`). The
revealed-preference upper bound under a *multiplicative* level cap was θ ≤ 0.159; the resolution
lower bound (cluster-scaled 95% CI width on $E$) 0.183; the interval was empty. That result concerns
the multiplicative cap. **The deployed cap is relative** (§5.1): $P^{*}\ge P^{\text{ref}}$ by
construction wherever $A \ge P^{\text{ref}}$, so the revealed-preference bound does not bind it. Not
re-computed on `v6`.

#### 5.3.2 Sources of uncertainty in $\varphi$, and where each is reported

| source | what varies | size on `v6` | reported in |
|---|---|---|---|
| **1. Severity θ** | declared, 0.325 / 0.50 / 0.675 | the whole spread; rule B +73 to +182 Gt | **main text** |
| **2. Declared erosion κ** | 0.02 / 0.027 / 0.05 | rule B +54 / +41 / +22 Gt against +118 | **main text** (the largest single sensitivity) |
| 3. Specification family | A (deployed) vs B | Bulk $k_{2050}$ 0.63–0.90 vs 0.86–1.22; rule B −11 Gt for B | main text robustness (family A), SI (family B) |
| 4. Curve shape | half-saturation 0.5× / 2× | rule B −3 / +12 Gt | main text robustness |
| 5. Frontier error structure | four frontier variants | `v5`: median \|Δφ\| up to 0.171 (§3.4.1) | SI |
| 6. Out-of-coverage assignment | donor / low band / median; nearest donors; USA | rule B 110–155 Gt | SI (the widest data-side band) |
| 7. Institution projections | harmonised vs held | rule B −0.9 Gt (EU21), but $k$ moves a lot | main text (held twins) |
| 8. Hold rule and horizon | logit hold vs E-hold; hold 2060 | rule B +71 / +7 Gt | SI |
| 9. Energy-system feedback | φ recomputed on the live energy system | coupled Bulk $k_{2050}$ 0.69 vs offline 0.63 | **main text** as a result, not an uncertainty |

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

`v6` assignment (`donor-assignment-band-<sector>.rds`, 200 uncovered countries per sector):

| | donor | lowBand | median |
|---|---:|---:|---:|
| Bulk | 50 | 56 | **94** |
| Diffuse | 33 | **100** | 67 |

> ⚠️ **Most uncovered countries are placed by a quantile rule, not a donor**: 150 of 200 in Bulk and
> 167 in Diffuse. The coupled arms bound what that does: all-median, all-low, nearest donors always,
> USA donor and USA low move the rule-B headline from +110 to +155 Gt (`SCENARIOS.md` §4.9). Disclose
> it with any coverage figure.

**One documented override:** `basisOverride = c(USA = "median")`. US federal policy spans states with
world-leading regulation and states with almost none; donor transfer would assign it a polity it is
not. **The USA must be reported as a range** (USA donor +117.4, USA low +134.8 Gt).

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
each market its own path times the anchor. The budget is always met. Continuity with `v5`.

**Mode L — $\varphi$ caps the increment** (`cm_pfmBindMode = 2`): the boxed form of §5.1, with
$\varphi(t)$ and **no speed limit**. The budget may become unreachable — **that is the finding, not a
bug.** $A$ must come from a path the cap cannot touch: reading it from the run's own capped price
makes the recursion a contraction onto $P^{\text{ref}}$ within a few calls (`SCENARIOS.md` §6.4).

**Mode M** (mild progression) is **retired** (ADR 0050): its mechanism was λ.

**Closures — mode L**, when the political bound and the budget cannot both hold:

| rule | mechanism | the headline it supports | `v6` rows |
|---|---|---|---|
| **B** | pin the anchor to the θ = 0 budget-holding run (`cm_pfmAnchorFromGdx`), budget forcing off | *political feasibility adds $X$ Gt CO₂ to the 1000 Gt pathway* | `-PFMlevelBfix…` |
| **C** | keep the budget (`cm_iterative_target_adj = 9`), rebuild the cap every iteration from the live anchor and that period's share (`cm_pfmBoundRebuild = 1`) | *the budget holds; the price rises and abatement moves* | `-PFMlevelC…` |
| **D** | allow the budget to be met later | *politics delays the price path by $N$ years* | never run |

**What the `v6` batch shows** (θ = 0.50; `SCENARIOS.md` §4):

| | EU21 | H12 |
|---|---:|---:|
| **rule B**: Δ cumulative CO₂ 2100 vs `-PFMgateBfix-v6` | **+118.2 Gt** | **+112.8 Gt** |
| rule B across θ 0.325 / 0.675 | +73.0 / +181.5 | +69.6 / +169.6 |
| **rule C**: cumulative CO₂ 2100, every run | 989.0–1001.1 Gt | 989.7–998.2 Gt |
| rule C: anchor 2050 vs θ = 0 | ×1.259 | ×1.251 |
| rule C: abatement moved between regions, 2020–2100 | 22.7 Gt CO₂eq | 19.9 Gt CO₂eq |
| ratio mode: anchor 2050 vs θ = 0; within-region ES/ETS 2050 | ×1.287; 0.56–1.17 | ×1.264; 0.57–1.29 |

---

## 6. Selection stability (`selection-bootstrap.rds`, 200 resamples)

Deployed spec `X-1791 … satAP`. Top-**40** pool, 200 resamples; 31 pool members are rejected by the
full-sample sanity walk and are never eligible.

> ⚠️ **A raw selection frequency is not evidence.** The menu offers several accountability options;
> a selector choosing at random takes *some* accountability most of the time. Read every frequency
> against the menu and the pool.

| element | among winners | conditional on sanity-eligible winners |
|---|---:|---:|
| Government Effectiveness (`WGIge`) | **100%** | 100% |
| Rule of Law (`RoL`) *(deployed)* | **86.2%** | — |
| Vertical Accountability (`VerAcc`) *(deployed)* | 60.6% | — |
| channel set `WGIge|RoL|VerAcc` *(deployed)* | **46.8%** | **49.3%** |
| channel set `WGIge|noRoL|VerAcc` (the `v5` set) | 13.8% | 32.5% |
| channel sets with Horizontal / Diagonal accountability | 25.5% / 13.8% | 9.7% / 8.4% |
| actor power `bothIncAP` *(deployed)* | **85.1%** | 100% |

**The deployed spec.** Wins **2.5%** of resamples (**15%** conditional), tied for the modal
conditional winner with `X-1794 … satAP` (19.5% each of the conditional, by spec), ahead of `X-2079 …
satInn` (14.3%), the family-B spec. Family A and family B split the conditional wins about 49 / 51.

> ✅ **State capability belongs**: 100% of winners. ✅ **Incumbency in both share and per-capita
> form belongs**: `bothIncAP` 85% of winners, 100% conditional. ✅ **Rule of Law belongs** (86%) — it
> was absent from `v5`'s deployed spec.
>
> 🔴 **Which accountability channel, and which actor-power transform, are not identified.** The
> deployed channel set is the plurality, not a majority; the transform splits evenly.

> **What may be claimed.** *State capability, Rule of Law and two-form incumbency belong.* **Neither
> the channel set nor the specification is uniquely selected**; the deployed spec is a 2.5% (15%
> conditional) winner. Any sentence asserting the model *is* `X-1791` rather than *was run at*
> `X-1791` is false.

---

## 7. What must NOT be done

Validated exclusions — each rejected by this project's own tests, not by preference:

| Prohibited | Why |
|---|---|
| Projected policy-level paths as IAM inputs | Static level forecasts lose to persistence (§4.3) |
| The $S/10$ implementability multiplier | Compares countries to a universal maximum; use $E = S/S^{*}$ (§3.2) |
| Point frontier ceilings or named slack rankings | Slack ranks not robust across rungs in either sector; use tiers (§3.4) |
| $S^{*}$ as an ECM attractor; λ as a coupling input | λ is a diagnostic only in `v6` (ADR 0050, §4) |
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
| A Bulk institution coefficient as a finding | Not identified: insignificant in the mean regression, opposite signs on the frontier (§2.5, §3.3) |
| Scenario results late in the century without their out-of-support share | A reporting duty since ADR 0052: 11% of weighted drivers out of support by 2100 (§5.2) |
| Ranking estimators on AIC/BIC across families | Different response scales and quasi-likelihoods |
| Calling the feedback causal | The IV is an endogeneity-confirmed null (§8.1) |

---

## 8. Open scientific questions

**8.1 Causal status of the feedback.** The shift-share IV (base-year incumbency × leave-one-out
global VRE diffusion) **confirms endogeneity** but **identifies no causal incumbency effect**
(`iv.rds`, $n = 1152$):

| rung | Incumbency $\hat\beta$ (2SLS) | SE | $p$ | first-stage $F$ | Wu–Hausman $p$ |
|---|---:|---:|---:|---:|---:|
| Bulk, with trend | −64.4 | **354** | .86 | 5.8 | 3e−31 |
| Bulk, no trend | −18.5 | 20.0 | .36 | 9.1 | 3e−87 |
| Diffuse, with trend | 1.85 | 16.8 | .91 | 7.2 | 1e−25 |
| Diffuse, no trend | 1.23 | 18.1 | .95 | 4.1 | 1e−91 |

Every rung is weakly instrumented ($F$ < 10) and no estimate is distinguishable from zero. **Do not
report the point estimates.** Report that endogeneity is confirmed at $p < 10^{-24}$ in every rung and
that the instrument cannot identify the effect — *we can show the relationship is endogenous; we
cannot show what it is.* Label the feedback **conditional scenario accounting**, and **do not write
"causes" anywhere near the loop.**

**8.2 The ceiling-feedback sign.** The feedback is live and large in Bulk: on the 1000 Gt energy
system the Bulk strength falls to 0.63 by 2050, on current policies it is 1.09 (§5.2). The median
covered ceiling rises on the 1000 Gt pathway in both sectors (to 1.21 / 1.27 of its 2025 value,
ADR 0052). The Bulk direction rests on how incumbent power behaves below anything observed (family A
vs B, §5.3.0) and on Bulk institution terms that are not identified. It is not causal (§8.1).

**8.3 The exposure confound.** `Incumb × GovEff` (share) is **positive** where theory expects
negative — +0.180 in the Bulk mean regression, +0.194 on the Bulk frontier, positive in all seven
Bulk estimators — and Bulk per-capita incumbency is positive and significant. Large, capable
fossil economies also regulate more; the model cannot tell exposure from resistance. A
fossil-rents reader would be needed and none exists.

**8.4 The historical-replay gate — passes, and cannot discriminate.** Running the coupled system
over the historical panel (seed year 2000) must reproduce observed stringency at least as well as
the uncoupled ECM (`historical-replay.rds`, `$pass = TRUE`):

| Sector | RMSE coupled | RMSE ECM | skill vs ECM | skill vs persistence | ceiling binds |
|---|---:|---:|---:|---:|---:|
| Bulk | 0.806 | 0.807 | +0.0007 | +0.730 | **0.63%** of rows |
| Diffuse | 0.525 | 0.526 | +0.0014 | +0.766 | 2.63% of rows |

> **Read the margin before the verdict.** The ceiling binds in under 3% of rows, so the coupled and
> uncoupled systems are almost the same model on history and the "pass" is a tie. On `v5` the replay
> re-scoped to the rows where the ceiling acts improved the Diffuse fit (skill +0.064) and was neutral
> in Bulk (`replayRescoped.R v5`); not re-run on `v6`. In the coupled `v6` runs the rule-B cap binds in
> 99% of region-periods — a regime this gate says nothing about.

**8.5 The time trend does most of the explanatory work.**

| | Bulk | Diffuse |
|---|---:|---:|
| $\hat\beta$ on $T(t)$ per SD, frontier | **0.966** | **0.501** |
| $\hat\beta$ on $T(t)$ per SD, mean regression (§2.5) | 1.347 | 0.640 |
| trend share of linear-predictor variance (§2.4) | **0.733** | **0.558** |

**So is the model usable?** Yes, with the framing kept ordinal:

1. **$\varphi$ is a cross-sectional ranking and the trend is common to everyone.** $T(t)$ has no
   $r$ subscript; it shifts every region's ceiling together and largely cancels out of $u_r$.
2. **The trend cannot leak into projections** — it is frozen at the last historical year, so the
   strength $k(t)$ moves only through the drivers.
3. **Dropping it is worse**: on `v5` the no-trend frontier was 337 logLik below the deployed one in
   Bulk and not estimable in Diffuse (§2.3.1); not re-measured on `v6`.

**What it costs.** In Bulk three-quarters of the linear predictor's variance is secular drift the
model does not attribute to institutions or actor power. The defensible claim is about
**cross-sectional ordering** and **how the drivers move the ceilings**, not about how the ceiling got
where it is. Nothing here should be phrased as "institutions caused the ceiling to rise".

---

## 9. Artifact map

All in `output/pfm/v6/`.

| Quantity | File | Path within |
|---|---|---|
| Deployed spec | `selected-models-pfm.yml` | — |
| Every estimation number in this document | `doc-facts/facts.json` | written by `analysis/checks/docFacts.R v6` |
| ΔR²(theory), trend share, VIF, tier, maximin, sanity walk | `sweep.rds`, `sanity-pool.rds` | `$results`, `$maximin`, `$sanity` |
| Sharing cost, per-tier winners | `selection-variants.rds` | `$perSector`, `$winners` |
| Selection stability | `selection-bootstrap.rds` | — |
| Mean regression: coefficients, wild-cluster $p$, AMEs | `inference.rds` | `$bySector$<s>$table` |
| Sign agreement across 7 estimators | `estimator-agreement.rds` | `$bySector$<s>$agreement` |
| Leave-one-country-out influence | `influence.rds` | `$bySector$<s>$byTerm` |
| Shift-share IV | `iv.rds` | `$bySector$<s>.<variant>` |
| Frontier $\beta_F$, $\gamma$, LR, covariance check, rungs | `frontier.rds` | `$bySector$<s>$coefTable`, `$gamma`, `$lr`, `$vcovCheck`, `$robustness` |
| Ceilings, gaps, efficiency per country-year | `frontier.rds` | `$bySector$<s>$scores` |
| The anchor: $q$, $u$, weights, frontier design | `phi-anchor.rds` | step `pfm-anchor` |
| Strength, anchors, decomposition, spec band, shape, ceiling gate, offline headline | `phase1/` | `strength.rds`, `anchors.rds`, `spec-band.rds`, `sat-shape.rds`, `ceiling-gate.rds`, `offline-headline.rds` |
| λ, half-life, skill (2 and 4 sectors) — diagnostic | `temporal-validation.rds`, `sector-speeds.rds` | — |
| Historical-replay gate | `historical-replay.rds` | `$pass`, `$bySector$<s>$metrics` |
| Country projections | `projection.rds`, `projections/<scenario>.rds` | — |
| Donor / band assignment | `coverage/`, `donor-assignment-band-<sector>.rds` | — |
| Offline bound (`v5`-style pipeline), efficiency analogy | `coupling/coupling-summary.rds` | `$anchorDerivation` |
| Coupled runs: prices, φ per market, convergence, run QC | `coupling/coupled-runs.rds` | `$runs`, `$prices`, `$phi`, `$convergence` |
| Every coupled number quoted in the docs | `coupling/coupled-facts.json`, `coupled-costs.json`, `v5-v6-coupled-contrast.json`, `rulec-relocation-decomp.rds` | written by `runCoupledStage.R v6` and `analysis/v6/` |

**Code entry points.** `estimatePolicyStringencyModel()`, `computeFeasibilityFrontier()`,
`computeAnchorGap()`, `computeStrengthPath()`, `pfmV6Shares()`, `pfmV6CouplingDefaults()`,
`computeDonorAssignment()`, `runPFMTemporalValidation()`, `computeWildClusterBootstrap()`,
`projectFeasiblePath()`, `exportFeasibilityBound()`, `iterativePFM()`.
