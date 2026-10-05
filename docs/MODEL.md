# The Political Feasibility Model — definition and mathematics

*The canonical mathematical statement of the deployed PFM. A reader should be able to
implement the model, and evaluate it by hand, from this document alone.*

**Provenance.** Every number is Run-Group **`v5`** unless it says otherwise. Deployed spec
**`X-2079 WGIge|noRoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp`**, country resolution,
n = 1056 = 48 countries × 22 years (2001–2022), panel hash `f8845f66fb39d316`, trend
logistic (midpoint 2010, steepness 0.20, standardized). Estimation-side numbers are collected
by `analysis/checks/docFacts.R` into `output/pfm/v5/doc-facts/facts.json`; the λ audit behind §4 is
`output/pfm/v5/lambda-explained/facts.json` and `output/pfm/v5/lambda-explained/LAMBDA-EXPLAINED.html`. Re-read from those,
never from this page.

> **Coupled results** are from the `v5` REMIND batch (`output/remind-runs/v5/{EU21,H12}/`, 62 runs over two
> submissions, 2026-09-16 and 2026-09-17),
> collected in `output/pfm/v5/coupling/coupled-facts.json`. This document quotes only what the model
> definition needs; the full reading is `SCENARIOS.md` §3–§8. The offline PFM-side bound
> (`output/pfm/v5/coupling/coupling-summary.rds`) is a different object — REMIND not re-optimising.

**Scope.** The model *as deployed*. How the spec was selected is ADR 0036/0039/0045/0046 and
`../_archive/_wip/2026-10-01/docs/reference/spec-selection-2026-09-15/DECISION-RECORD.md`. The REMIND interface is
`COUPLING.md`. Traps are `PITFALLS.md`.

**Naming.** This document says **PFM** throughout. Code, artifact paths and step names still
carry the older `psm*` prefix (`runPFMSweep()`, `selected-models-pfm.yml`); they mean the same
object. See `TODO.md` § Rename.

---

## 1. Notation

| Symbol | Meaning | Units / range |
|---|---|---|
| $c$ | country (48 in estimation; 248 projected) | — |
| $t$ | year | 2001–2022 estimation; 2025–2150 projection |
| $s$ | sector: Bulk (electricity + industry) or Diffuse (buildings + transport) | — |
| $S_{c,t,s}$ | observed CAPMF policy-stringency index | $[0,10]$ |
| $M$ | structural index ceiling, `indexMax` | $10$ |
| $y^{*}$ | transformed response, $\operatorname{logit}(S/M)$ squeezed | $\mathbb{R}$ |
| $\eta$ | linear predictor | $\mathbb{R}$ |
| $A^{\text{in}}$ | Innovator Power, **share** | standardized |
| $A^{\text{ic}}$ | Incumbent Power, **share** — the dependence / lock-in channel | standardized |
| $A^{\text{ic,pc}}$ | Incumbent Power **per capita** = share × primary energy per capita — the scale channel | standardized |
| $G$ | Government Effectiveness (WGI) — state capability | standardized |
| $V$ | **Vertical Accountability (V-Dem)** — electoral accountability of rulers to citizens | standardized |
| $T(t)$ | logistic time trend, frozen at the last historical year | standardized |
| $v, u$ | symmetric noise $N(0,\sigma_v^2)$; one-sided political slack $N^{+}(0,\sigma_u^2)$ | — |
| $\gamma$ | slack variance share $\sigma_u^2/\sigma^2$ | $[0,1]$ |
| $S^{*}$ | **feasibility frontier** (ceiling) | $[0,10]$ |
| $S^{\text{eq}}$ | ECM equilibrium (the attractor) | $[0,10]$ |
| $E = S/S^{*}$ | efficiency ratio — the implementability factor | $(0,1]$ |
| $\lambda_s$ | adjustment speed, **on the logit scale** (§4.2) | per year |
| $\varphi_r$ | **feasibility share** — fraction of incremental mitigation effort a region can realize | $(0,1]$ |
| $\theta$ | coupling severity — declared and swept, never estimated | $[0,1)$ |
| $P^{\circ}, P^{\text{ref}}$ | cost-optimal and current-policy carbon price | \$/tCO₂ |

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

**Boundary check.** 5.3% of Bulk rows and 0.4% of Diffuse rows sit at exactly 0; **no** row sits
at the maximum. That is the empirical gate that closed the two-limit-Tobit rung as unnecessary.

### 2.2 The deployed specification

`X-2079 WGIge|noRoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp`, fitted separately per
sector on an identical design (the Shared Specification rule):

$$
\begin{aligned}
\eta_{c,t} = \;&\alpha
+ \beta_1 A^{\text{in}} + \beta_2 A^{\text{ic}} + \beta_3 A^{\text{ic,pc}} + \beta_4 G + \beta_5 V \\
&+ \beta_6 A^{\text{in}}\!\cdot\! G + \beta_7 A^{\text{in}}\!\cdot\! V
+ \beta_8 A^{\text{ic}}\!\cdot\! G + \beta_9 A^{\text{ic}}\!\cdot\! V
+ \beta_{10} A^{\text{ic,pc}}\!\cdot\! G + \beta_{11} A^{\text{ic,pc}}\!\cdot\! V \\
&+ \beta_{12} T(t) + \boldsymbol\psi'\mathbf{z}
+ \delta_{\text{OECD}}\mathbb{1}[c \in \text{OECD}] + \delta_{\text{other}}\mathbb{1}[c \in \text{other}]
\end{aligned}
$$

$\mathbf{z}$ is three controls — GDP per capita (Q-centred), log Population, Hydro/Nuclear share.
Fifteen slope terms. **No lags, no Mundlak, levels transform, no saturating transform.**

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
> how accountable rulers are to voters, **how those forces multiply each other**, a common time
> trend, and a coarse three-way group effect.

### 2.3 The components

**Actor power** (`actorPowerIndex()`), computed from the IAM's own energy system — this is the
channel through which a REMIND pathway talks back to the model:

$$A^{\text{in},\text{Bulk}} = \frac{1.0\,\text{VRE} + 0.6\,\text{Elec}}{1.6},\qquad
A^{\text{ic},\text{Bulk}} = \frac{1.0\,\text{Coal} + 1.0\,\text{OilGas} + 0.5\,\text{FossInd}}{2.5}$$

$$A^{\text{in},\text{Diffuse}} = \frac{0.5\,\text{VRE} + 1.0\,\text{Elec} + 0.4\,\text{Biofuel}}{1.9},\qquad
A^{\text{ic},\text{Diffuse}} = \frac{0.2\,\text{Coal} + 0.2\,\text{OilGas} + 1.0\,\text{FossInd}}{1.4}$$

$$A^{\text{ic,pc}} = A^{\text{ic}} \times \text{primary energy per capita}$$

Weights are fixed design constants, not estimated.

**The `bothIncAP` form (ADR 0044, ADR 0045).** Incumbency enters twice — as a share (how
dependent the energy system is) and per capita (how large the incumbent interest is) — which
nests both the share-only and per-capita-only forms, so the sweep tests directly whether each
channel carries information once the other is present. Innovator power enters as a share.

> 🔴 **The two incumbency channels pull in OPPOSITE directions, and only the pair is
> interpretable.** Marginal effects on the ceiling from the frontier covariance matrix (Fig 2b,
> `analysis/figures/R/fig-marginal-effect-incumbency.R`), at the observed minimum, mean and maximum of
> government effectiveness:
>
> | | GovEff −2.22 | mean | +1.64 |
> |---|---:|---:|---:|
> | Bulk, share | **−0.642** | −0.190 | +0.144 |
> | Bulk, per capita | **+0.649** | +0.308 | +0.056 |
> | Diffuse, share | **−0.498** | −0.130 | +0.141 |
> | Diffuse, per capita | **+0.421** | +0.132 | −0.081 |
>
> Where the state is weak, a more fossil-**dependent** energy system lowers the ceiling while a
> **larger** fossil interest per head raises it; both effects fade, and in Diffuse reverse, as
> capability rises. Neither column is a statement about "incumbency" on its own — a sentence that
> names one channel and not the other inverts the sign of the other half. The channels are not
> orthogonal (share × energy per capita), so this is a decomposition, not two independent findings.

**The split form is load-bearing.** A composite $A = A^{\text{in}} - A^{\text{ic}}$ makes
projections *scenario-blind* under the extrapolation guard (both pathways winsorize to the same
boundary). Splitting keeps the feedback channel alive. **Never revert.**

**Institutional channels.** $G$ = WGI Government Effectiveness; $V$ = V-Dem Vertical
Accountability. Rule of Law is absent (`noRoL`). The accountability channel is the least stable
element of selection (§6).

**Smoothing.** `panelDataHistorical(movingAverage = 5)` applies a centred five-year moving average
(window shortened at the panel ends, so 2022 = mean of 2020-2022) to **every** panel column after
normalisation, the stringency outcome included. Verified for v5 by `analysis/checks/inputVintages.R`, which
rebuilds the panel exactly from the cached WGI 2025 / V-Dem v16 / CAPMF reads
(`output/pfm/v5/input-vintages.rds`).

**Standardization.** Every driver and interaction factor is standardized on the estimation rows;
means/SDs are **frozen** in `driverScaling` and reused for scenario panels. Coefficients are per
standard deviation — including the trend.

**Time trend.** Logistic in calendar year, evaluated at $\min(t, 2022)$ for any projection year
(`projectFeasiblePath.R:160`), then standardized like every other driver:

$$T(t) = \big[1+\exp(-k(t-m))\big]^{-1},\qquad m = 2010,\; k = 0.20$$

Read the shape from the artifact, never from here: `manifest.json$trend` (`form`, `midpoint`,
`steepness`, `scaled`) and `selected-models-pfm.yml`'s `trendMidpoint` / `trendSteepness`.

> *In words:* a time effect cannot be extrapolated, so it is held at its last historical value
> and the scenario drivers — not the calendar — carry all future differentiation. Over the
> estimation window the raw curve runs 0.142 → 0.917, so the freeze pins it near its plateau.

**Fixed effects.** `regionmapping_EU_OECDp.csv` → three blocks: **EU** (reference), **OECD**
non-EU, **other**. Country dummies are an agreement rung only — unit FE absorb the
cross-sectional variation that identifies slow-moving institutional channels.

#### 2.3.1 The trend shape is DECLARED, not selected

Every other element of the specification is chosen by the maximin tournament over 4,392
candidates. The trend shape is not: `createChannelConfigs()` hard-codes one $(m,k)$, so the
sweep never sees it as a choice and the selected specification is conditional on that constant.

**The deployed shape is close to the best-fitting one in Bulk and not in Diffuse.** Holding the
deployed specification fixed and varying only the trend (`analysis/checks/trendShapeGrid.R v5` →
`output/pfm/v5/trend-shape-grid.rds`; one subprocess per fit with a 120 s cap). Frontier logLik at
**identical parameter count** — the trend contributes one coefficient whatever its shape:

| $(m,k)$ | Bulk logLik | Δ vs deployed | Bulk $\gamma$ | Diffuse logLik | Δ vs deployed | Diffuse $\gamma$ |
|---|---:|---:|---:|---:|---:|---:|
| 2005 / 0.10 | **−1293.6** | **+4.1** | 0.9889 | −513.9 | −7.7 | 0.9777 |
| 2005 / 0.20 | not estimable | — | — | −488.4 | +17.8 | 0.9853 |
| 2010 / 0.30 | −1294.8 | +2.9 | 0.9847 | **−485.0** | **+21.2** | 0.9884 |
| **2010 / 0.20 — deployed** | −1297.7 | — | 0.9868 | −506.2 | — | 0.9819 |
| linear | −1314.9 | −17.2 | 0.9919 | −543.6 | −37.4 | 0.9766 |
| 2020 / 0.20 | −1424.5 | −126.7 | **1.0000** ⚠️ | −688.4 | −182.2 | 0.9709 |
| no trend | −1634.5 | −336.8 | 0.9930 (vcov corrupt) | not estimable | — | — |

Later midpoints are monotonically worse in both sectors, and two Bulk settings at 2015–2020 reach the
γ boundary.

**Why the declared shape is kept.**

1. **It is interior and nearly ML-best in Bulk.** No Bulk shape beats it by more than 4.1 logLik.
2. **Likelihood and the selection rule pull against each other.** A trend that fits better absorbs
   more variance: Diffuse `trendShare` is 0.550 at the ML-best shape and 0.594 at 2005 / 0.20, against
   0.552 deployed, and in Bulk the best shape (2005 / 0.10) carries 0.773 against 0.736. Sweeping the
   trend would add a selection dimension with no ADR on which the trend-dominance gate and the
   likelihood disagree.
3. **One shape for both sectors.** The Diffuse optimum (2010 / 0.30) and the Bulk optimum
   (2005 / 0.10) differ, and the Shared Specification rule (§2.2) requires one.

> **The cost, stated plainly.** The deployed trend is **21.2 logLik worse in Diffuse** than the
> best shape at equal parameter count, and 4.1 worse in Bulk. It is a declared choice, not a fitted
> one, and should be described in those words.
>
> **It barely moves φ.** Delivered φ under the best-fitting shapes (`analysis/checks/trendShapePhi.R v5` →
> `output/pfm/v5/trend-shape-phi.rds`, EU21, GDP weights, θ = 0.50, 2022 seed): 2005 / 0.10 Spearman
> 0.998, median |Δφ| **0.006**; 2010 / 0.30 Spearman 0.986, median |Δφ| **0.013**; linear 0.988,
> **0.027**. The trend shape is the smallest of the φ uncertainties — far below the frontier rungs
> (§3.4.1).

**What would change this.** If a sector-common shape beats the deployed one in both sectors at an
interior γ with `trendShare` clear of the 0.90 gate, the trend should go into the sweep.

### 2.4 Fit of the deployed spec (`sweep.rds`)

| | Bulk | Diffuse |
|---|---:|---:|
| ΔR²(theory) | **0.112** | **0.166** |
| pseudo-R² | 0.703 | 0.785 |
| trend share of linear-predictor variance | 0.736 | 0.552 |
| max VIF | 3.41 | 2.89 |
| significant actor-power / institution / interaction terms | 4 / 4 / 3 | 2 / 2 / 1 |
| smallest significant theory $\lvert t\rvert$ | 2.08 | 2.46 |
| tier | Green | Green |
| $n$ | 1056 | 1056 |

**Selection position.** 4,392 specifications ranked; **519** pass the admissibility gates. The
deployed spec is **rank 1** on the multi-criteria maximin rule (worse-sector tier, then theory
content, then parsimony and fragility): mean ΔR²(theory) 0.139, minimum 0.112, ΣBIC 4537.8,
fragility 1. The sanity walk accepted it first (`forced = FALSE`, 0 severe flags, 30 warnings).

Gates in force: `supportShareGate` **0.275** over 2040–2060 (ADR 0045), `ceilingFallGate` 0.90
(ADR 0043), `gammaGate` 0.999 (ADR 0046), VIF hard 10 / soft 6 (soft as tie-break only). All
three are now the code defaults of `runPFMSweep()`.

> ⚠️ **Rank 1 is not dominance.** Rank 1 is on the maximin rule's ordering, not on any single
> column. The best *per-sector* specifications fit more: Bulk `X-1791` (no `satAP` suffix) reaches ΔR² 0.139
> and Diffuse `X-1854 …satAP` 0.207 — a **sharing cost** of 0.027 (19.4%) in Bulk and 0.041
> (19.8%) in Diffuse (`selection-variants.rds`). `X-1791` passes the sanity walk too (190
> warnings), and several higher-fit candidates are removed by the γ gate. The full comparison is
> `../_archive/_wip/2026-10-01/docs/reference/spec-selection-2026-09-15/`.

### 2.5 Fitted coefficients — mean regression (`inference.rds`)

Deployed spec, country-clustered, $G = 48$, $n = 1056$. $p_{\text{wild}}$ is a Rademacher
wild-cluster bootstrap-$t$, $B$ = 999 — **these are the quotable $p$-values**; 48 clusters is too
few for asymptotic inference, and $p_{\text{asym}}$ is shown so the gap is visible. AME is the
average marginal effect in index points per SD (§2.7).

| Term | Bulk $\hat\beta$ | $p_{\text{asym}}$ | $p_{\text{wild}}$ | AME | Diffuse $\hat\beta$ | $p_{\text{asym}}$ | $p_{\text{wild}}$ | AME |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Innovator Power | −0.077 | .442 | .479 | −0.112 | 0.022 | .678 | .763 | 0.042 |
| Incumbent Power (share) | −0.193 | .312 | .418 | −0.279 | **−0.173** | .004 | **.030** | −0.331 |
| Incumbent Power (pc) | **0.489** | .000 | **.000** | 0.709 | 0.069 | .520 | .593 | 0.131 |
| Gov. Effectiveness | **0.240** | .031 | **.048** | 0.349 | **0.333** | .005 | **.006** | 0.637 |
| Vertical Accountability | 0.347 | .098 | .125 | 0.504 | −0.187 | .380 | .657 | −0.359 |
| Innov × GovEff | −0.149 | .106 | .158 | −0.217 | 0.076 | .114 | .167 | 0.146 |
| Innov × VerAcc | 0.014 | .882 | .890 | 0.020 | −0.054 | .454 | .523 | −0.103 |
| Incumb × GovEff | 0.151 | .214 | .288 | 0.219 | 0.145 | .014 | .058 🔴 | 0.277 |
| Incumb × VerAcc | −0.451 | .037 | .057 🔴 | −0.654 | 0.102 | .601 | .834 | 0.196 |
| Incumb pc × GovEff | −0.308 | .017 | .077 🔴 | −0.447 | −0.067 | .646 | .854 | −0.128 |
| Incumb pc × VerAcc | **0.261** | .003 | **.015** | 0.379 | 0.043 | .756 | .965 | 0.083 |
| GDP p.c. (Q-centred) | 0.076 | .488 | .532 | 0.110 | −0.081 | .177 | .322 | −0.155 |
| Population (log) | **0.485** | .002 | **.027** | 0.704 | **0.279** | .000 | **.000** | 0.534 |
| Hydro/Nuclear share | −0.183 | .155 | .235 | −0.266 | 0.046 | .389 | .498 | 0.088 |
| Logistic trend | **1.327** | .000 | **.000** | 1.925 | **0.635** | .000 | **.000** | 1.216 |

> 🔴 **Three theory terms change verdict under the bootstrap** (30 term-sector cells): Bulk
> `Incumb × VerAcc` (.037 → .057), Bulk `Incumb pc × GovEff` (.017 → .077), Diffuse
> `Incumb × GovEff` (.014 → .058). **Do not report them as significant.** No term that the
> asymptotic $p$ calls insignificant is rescued by the bootstrap.

**What the table says, on signs and wild $p$:**

- **State capability is the one institutional channel significant in both sectors** — GovEff
  +0.240 ($p_{\text{wild}}$ .048) Bulk and +0.333 (.006) Diffuse. Its sign is positive in 6 of 7
  estimators in both sectors (§2.5.1). The Bulk result is fragile (§2.6).
- **Vertical Accountability is not significant as a main effect in either sector.** Its Bulk
  contribution runs through the per-capita incumbency interaction (+0.261, .015).
- **Per-capita incumbency is positive and significant in Bulk** (+0.489, <.001): larger
  incumbents per head are associated with a *higher* fitted Bulk stringency, conditional on the
  share. The share itself is negative in both sectors, significant in Diffuse (−0.173, .030). The
  two readings — dependence lowers stringency, scale raises it — are the design's reason for
  carrying both, and the positive scale term is a disclosed tension (§8.3), not a channel finding.
- **Population and the trend are significant in both sectors.**

#### 2.5.1 Sign stability across estimators (`estimator-agreement.rds`)

Seven estimators on the same design — satP, fractional logit, beta, levels OLS, satP random
effects, satP with year FE, levels two-way FE. A term's sign **agrees** if all seven agree:

| | Bulk | Diffuse |
|---|---|---|
| terms with all 7 signs agreeing | **4 of 15** | **7 of 15** |
| which | `Incumb pc × VerAcc` (+), `Incumb × GovEff` (+), `Incumb × VerAcc` (−), trend (+) | GDP (−), `Incumb` share (−), `Incumb pc × VerAcc` (+), `Innov × GovEff` (+), `Innov × VerAcc` (−), trend (+), Population (+) |
| GovEff | + in 6, − in 1 | + in 6, − in 1 |

> ⚠️ **Sign agreement is weak in Bulk.** Eleven of fifteen Bulk terms change sign somewhere in the
> battery. Coefficient-level claims about Bulk should be limited to the terms above and to GovEff
> with its caveats.

### 2.6 How much of this survives dropping one country (`influence.rds`)

Leave-one-country-out over the 48 clusters, α = 0.05. $p_{\max}$ is the worst $p$ across the 48
refits; **pivotal** counts the countries whose removal alone flips the term's verdict.

| Term | $p$ | $p$ range over refits | pivotal | verdict |
|---|---:|---|---|---|
| **Bulk** Incumbent Power (pc) | <.001 | 5e−05 – .0007 | — | robust |
| Bulk Incumb pc × VerAcc | .005 | .001 – .269 | 2 — CHN, SAU | 🟠 holds except two |
| Bulk Incumb pc × GovEff | .021 | .005 – .056 | 1 — PER | 🟠 borderline |
| Bulk **GovEff** | .036 | .009 – **.268** | **14** — ARG, AUT, BGR, CHE, CRI, DNK, GBR, IDN, IND, ISL, MLT, NZL, RUS, SAU | 🔴 **fragile** |
| Bulk Incumb × VerAcc | .043 | .014 – **.440** | **15** — CHN, COL, CRI, CZE, GRC, HUN, ISL, ISR, JPN, NOR, PER, RUS, SAU, SVK, TUR | 🔴 **fragile** |
| **Diffuse** GovEff | .007 | .0007 – .056 | 1 — ISL | 🟠 borderline |
| Diffuse Incumbent Power (share) | .006 | .001 – .081 | 1 — RUS | 🟠 borderline |
| Diffuse Incumb × GovEff | .018 | .006 – .147 | 3 — CHN, CRI, NOR | 🟠 fragile |

Terms not significant at full sample whose removal of one country would *create* significance
(pivotal *gains*): Bulk VerAcc (CAN), Bulk `Innov × GovEff` (IDN, ZAF), Bulk `Incumb × GovEff`
(MEX); Diffuse `Incumb pc` (SAU), `Innov × GovEff` (CHN, SAU), `Incumb pc × GovEff` (SAU).
**No claim rests on any of them, and dropping a country to obtain a result is exactly what must
not be done.**

> 🔴 **The Bulk GovEff main effect is not a robust finding.** Fourteen single-country removals take
> it above .05. Report the coefficient with its leave-one-out range, not a point $p$-value. The
> Diffuse GovEff effect is the stronger result — one pivotal country (ISL), $p_{\max}$ .056.

#### 2.6.1 One country with leverage: Saudi Arabia

SAU is the top influencer on four of eleven Diffuse theory terms, pivotal in Bulk
`Incumb pc × VerAcc`, and the sole pivotal gain on three Diffuse terms. Its position explains why
(country means 2001–2022, 48 estimation countries, `v5` panel):

| driver | SAU z | rank of 48 |
|---|---:|---:|
| Vertical Accountability | **−4.63** | 48 (lowest in the sample) |
| Government Effectiveness | −1.20 | 42 |
| Incumbent Power, Diffuse share / pc | +2.43 / **+3.50** | 1 / 1 |
| Incumbent Power, Bulk share / pc | +1.85 / **+3.21** | 1 / 1 |

It is the only country combining the lowest electoral accountability with the highest incumbency
— the exact plane the deployed `Incumb × VerAcc` and `Incumb pc × VerAcc` interactions identify.
The conjunction has n = 1.

> **No control fixes this.** The fossil variables already in the panel are the *components* of
> Incumbent Power, so adding them is collinear rather than corrective. A fossil-**rents** measure
> is a different construct, worth adding for §8.3, never to move one country's result. The binding
> constraint is **support**, and no covariate creates data where there is none (§2.7).

### 2.7 Marginal effects

Because the response is non-linear, report average marginal effects on the natural scale:

$$\text{AME}_k = \frac{1}{N}\sum_{c,t} M\,\operatorname{logit}^{-1}(\eta)\big(1-\operatorname{logit}^{-1}(\eta)\big)\frac{\partial\eta}{\partial x_k}$$

with $\partial\eta/\partial x_k$ including interaction terms and delta-method clustered SEs;
tabulated in §2.5 and persisted in `inference.rds`. Every driver is standardized, so every AME,
including the trend's, is per SD.

Examples: Diffuse **GovEff** AME = **0.637** index points per SD (SE 0.224); Bulk **Incumbent
Power (pc)** AME = **0.709** (SE 0.163), the largest identified Bulk marginal effect and the one
whose sign needs the §8.3 caveat.

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

Half-normal SFA, both sectors on the identical design, $n = 1056$ each.

| | Bulk | Diffuse |
|---|---:|---:|
| $\gamma = \sigma_u^2/\sigma^2$ | **0.9868** | **0.9819** |
| $\sigma^2$ | 2.372 | 0.510 |
| LR test against OLS | 409.9 | 283.3 |
| logLik | −1297.7 | −506.2 |
| covariance check (`vcovCheck`) | ok, ratio 0.97 | ok, ratio 1.01 |
| converged | yes | yes |

**Frontier coefficients** (ML standard errors; $p$ asymptotic — see the §2.2 table for why there
is no clustered alternative):

| Term | Bulk $\hat\beta_F$ | $p$ | Diffuse $\hat\beta_F$ | $p$ |
|---|---:|---:|---:|---:|
| Innovator Power | 0.008 | .85 | **0.130** | <.001 |
| Incumbent Power (share) | **−0.190** | .004 | **−0.130** | <.001 |
| Incumbent Power (pc) | **0.308** | <.001 | **0.132** | <.001 |
| Gov. Effectiveness | 0.064 | .32 | **0.251** | <.001 |
| Vertical Accountability | 0.029 | .78 | −0.037 | .37 |
| Innov × GovEff | −0.034 | .33 | **0.039** | .041 |
| Innov × VerAcc | 0.017 | .84 | **−0.106** | <.001 |
| Incumb × GovEff | **0.203** | <.001 | **0.165** | <.001 |
| Incumb × VerAcc | −0.116 | .26 | −0.059 | .13 |
| Incumb pc × GovEff | **−0.153** | .002 | **−0.130** | <.001 |
| Incumb pc × VerAcc | 0.082 | .052 | **0.087** | <.001 |
| GDP p.c. (Q-centred) | −0.004 | .90 | −0.006 | .68 |
| Population (log) | **0.311** | <.001 | **0.246** | <.001 |
| Hydro/Nuclear share | −0.007 | .88 | **0.060** | <.001 |
| Logistic trend | **0.959** | <.001 | **0.491** | <.001 |
| FE OECD / other (vs EU) | −0.444 / −0.884 | <.001 | −0.170 / −0.352 | <.001 |

> ⚠️ **The two estimators disagree about Bulk state capability.** The mean regression finds GovEff
> +0.240 ($p_{\text{wild}}$ .048); the frontier finds +0.064 ($p$ .32). They estimate different
> things — the average versus the attainable maximum — so this is not a contradiction, but it
> means "state capability raises the Bulk *ceiling*" is **not** a supported sentence. In Diffuse
> both estimators agree (+0.333 mean, +0.251 frontier, both significant).
>
> ⚠️ **Frontier $p$-values are ML and understate uncertainty.** With 48 clusters over 22 years
> the design effect on the same design runs 2.2× (Bulk) and 3.1× (Diffuse) in the mean regression
> (§5.3.1). Many frontier terms that look very significant here would not survive that scaling.
> Quote frontier signs; quote mean-regression $p$.

### 3.4 ⚠️ The $\gamma$ caveat — read before using any ceiling

$\gamma$ = 0.987 / 0.982 attributes nearly all composed error to slack. Both are interior and
inside the γ gate (0.999, ADR 0046), but close enough to 1 that the noise/slack split is weakly
identified and the *level* of a single country's ceiling is the least trustworthy thing the
model produces. The robustness battery (`frontier.rds$bySector$<s>$robustness`) re-estimates
under three alternative error structures; $\rho$ is the Spearman correlation of country slack
ranks against the headline:

| Rung | Bulk $\gamma$ | Bulk $\rho$ | Diffuse $\gamma$ | Diffuse $\rho$ |
|---|---:|---:|---:|---:|
| headline (pooled half-normal) | **0.9868** | — | **0.9819** | — |
| truncated-normal $u$ | 0.997 | 0.40 | 0.986 | **0.83** |
| panel (Battese–Coelli 92) | 0.822 | 0.19 | 0.995 | 0.14 |
| time-decay (BC), $\eta$ | 0.082, $\eta$ = 0.153 | −0.04 | 0.260, $\eta$ = 0.113 | **0.74** |

> 🔴 **Bulk slack ranks are not robust on any rung** (0.40 / 0.19 / −0.04). Diffuse holds on two
> of three (0.83 / 0.74) and collapses on the panel rung (0.14). **Report tiers, never named
> country rankings of slack, in both sectors.**

#### 3.4.1 Propagated to what the coupling consumes (`frontier-rung-phi.rds`)

`slackRankCor` ranks countries on absolute slack, which the coupling never sees. It consumes
$E$, then $\varphi$. Rebuilt per rung (`analysis/checks/propagateFrontierRungsToPhi.R v5`, seed year 2022,
48 covered countries, θ = 0.50):

**Country $E$ versus the headline:**

| Rung | Bulk $\rho$ | median $\lvert\Delta E\rvert$ | Diffuse $\rho$ | median $\lvert\Delta E\rvert$ |
|---|---:|---:|---:|---:|
| truncated-normal | **0.942** | 0.046 | **0.959** | 0.044 |
| panel (BC92) | 0.622 | 0.108 | 0.603 | 0.260 |
| time-decay | 0.663 | 0.166 | 0.690 | 0.158 |

**Delivered $\varphi = \min(\varphi^{\text{Bulk}},\varphi^{\text{Diffuse}})$, EU21, GDP weights,
20 regions (USA has no covered country):**

| Rung | Spearman | median $\lvert\Delta\varphi\rvert$ | max $\lvert\Delta\varphi\rvert$ | median rank shift |
|---|---:|---:|---|---:|
| truncated-normal | **0.961** | 0.024 | 0.083 (NES) | 1 |
| panel (BC92) | 0.529 | 0.055 | 0.253 (SSA) | 3 |
| time-decay | 0.439 | **0.171** | 0.296 (CHA) | 4 |

At H12 (11 regions): 0.973 / 0.045 / 0.237 Spearman; median shifts 0.025 / 0.059 / 0.154.

> 🔴 **On `v5` the γ band is NOT small.** The truncated-normal rung barely moves $\varphi$, but the
> panel rung reorders it (Spearman 0.53) and the decay rung moves it by a median 0.171 — the size of
> a θ step. The frontier error structure is therefore a first-order uncertainty in $\varphi$ and
> belongs beside θ in any φ band. The specification band on `v5` is of the same kind: small in the
> median, up to 0.271 where it binds, and it moves the floor region (§5.3.0).

**Rank intervals.** A point rank hides how much of it is rung choice, so ranks are reported as
the interval a unit spans across the four rungs (`rankInterval`: `rankLo / rankMed / rankHi`).
EU21 delivered $\varphi$: max width **13 of 20**, median width 7, **40% separable**. H12: max
width 9 of 11, 36% separable. Country $E$: max width 41.5 (Bulk) and 47 (Diffuse) of 48, median
12–13. **This is a range over four fitted models, not a sampling confidence interval** — never
attach a coverage probability to it.

**Which sector binds is not robust.** In this 2022 offline reconstruction the headline puts
Bulk as the binding sector in **1 of 20** EU21 regions; the decay rung puts it in 10; 11 of 20
regions change binding sector across rungs, and only nine are always-Diffuse (DEU, ENC, ESC,
ESW, EWN, FRA, IND, MEA, NES). At country level Bulk binds in 32 / 31 / 10 / 26 of 48 across
headline / truncated-normal / panel / decay, and 30 of 48 countries flip. **Any sentence of the
form "the constraint binds on the Diffuse sector" is a statement about the headline rung.** The
coupled attribution is decided inside the gdx at the tier year 2035, and it differs from this
reconstruction: Diffuse binds in **14 of 21** EU21 regions and **9 of 12** H12 regions in
`-PFMlevelB` (`SCENARIOS.md` §6.2a), against 19 of 20 here. The offline check shows the attribution
is rung-sensitive; it does not predict the coupled split.

**Scope.** Seed year 2022 historical, not the projected tier year; donor/band transfer (§5.4) not
simulated; equal and GDP weights bracket the final-energy weights and agree to within 0.03 on
every Spearman above.

#### 3.4.2 The sector ordering in the estimation sample

On $E$ read straight out of `frontier.rds`, **Bulk is the more constrained sector in 32 of 48
countries at 2022** (median $E$: Bulk 0.707, Diffuse 0.746), and it has been throughout the
sample (35 of 48 at 2010 and at 2018). Whatever the coupling reports about which sector binds is
therefore produced after estimation — by the projection, the per-sector min–max normalisation
and aggregation — not read off the estimated cross-section.

**`projection.rds$implementability` is $S/10$, not $E$** (`computeImplementabilityFactor()` is
`index / indexMax`). Nothing in the coupling reads it — `iterativePFM()` and
`runPFMCouplingBound()` take $E$ = `feasibleIndex / ceilingIndex` from `projectFeasiblePath()` —
but any offline figure built from that column is on the prohibited measure (§7).

---

## 4. Dynamics: the speed of the ratchet

### 4.1 Error-correction form

$$\Delta y^{*}_{c,t} = c_0 + \phi\,y^{*}_{c,t-1} + \boldsymbol\theta'\mathbf{x}_{c,t} + \epsilon,\qquad \phi<0,\qquad \lambda = -\phi$$

implemented with response `ecp` $= y^{*}_t - y^{*}_{t-1}$ and `lagged_ecp` $= y^{*}_{t-1}$.

$$\boxed{\,y^{*,\text{eq}} = \frac{c_0+\boldsymbol\theta'\mathbf{x}}{-\phi},\qquad
S^{\text{eq}} = M\cdot\operatorname{logit}^{-1}(y^{*,\text{eq}})\,}\qquad
t_{1/2} = \frac{\ln 0.5}{\ln(1-\lambda)}$$

> *In words:* each year a country closes a fixed fraction $\lambda$ of the distance between where
> its policy is and where its drivers say it should be.

### 4.2 ⚠️ The scale $\lambda$ lives on

The ECM is estimated on $y^{*}$, **not** on the 0–10 index. The validated recursion is
$y^{*}_t = \eta^{\text{fixed}}_t + (1+\phi)y^{*}_{t-1}$, seeded at the observed transformed level in
the last training year. $\lambda$ is a gap-closure rate **on the logit scale**. Applying it to
natural-scale gaps is a scale error — the equivalent natural-scale rates are 0.011 (Bulk) and
0.035 (Diffuse). `projectFeasiblePath()` runs the recursion on the logit scale and transforms
once at the end; use it rather than hand-rolling the loop.

**Attractor discipline.** The target is $S^{\text{eq}}$, **never** $S^{*}$. $\lambda$ was
validated as the rate of convergence to $S^{\text{eq}}$; $S^{*}$ is a **bound and an exhibit**,
never an operational attractor. Retargeting the same recursion at the frontier does not rescue
forecast skill (`output/pfm/v5/lambda-explained/LAMBDA-EXPLAINED.html`).

For irregular steps (REMIND runs 5-year periods): $\lambda^{\text{eff}} = 1-(1-\lambda_s)^{\Delta t}$.

### 4.3 Estimated speeds (`temporal-validation.rds`, `sector-speeds.rds`)

Protocol: fit on $t\le2015$, recursively forecast 2016–2022, score against persistence;
$n = 336$ scored rows per sector.

**Two-sector** — the rates exported to REMIND as `p45_pfmLambdaMkt`:

| Sector | $\lambda$ | $t_{1/2}$ | ECM skill vs persistence | static-level skill | event AUC |
|---|---:|---:|---:|---:|---:|
| Bulk | **0.1094** | 5.98 y | −0.180 | −0.911 | 0.48 |
| Diffuse | **0.0769** | 8.66 y | −0.698 | −0.807 | 0.33 |

Sector ratio 1.42×.

**Four-sector** — the honest resolution:

| Sector | $\lambda$ | $t_{1/2}$ | skill | label |
|---|---:|---:|---:|---|
| **Electricity** | 0.1142 | 5.72 y | **+0.140** | **the only rate that beats persistence** |
| Industry | 0.1662 | 3.81 y | −0.630 | fast but not forecastable |
| Buildings | 0.1039 | 6.32 y | −0.617 | persistence-dominated |
| Transport | 0.1633 | 3.89 y | −1.172 | persistence-dominated |

> **Only electricity beats "assume nothing changes."** Everything else is a *descriptive rate*,
> not a forecast. The static level forecast loses to persistence in both sectors; that negative
> result is why this model delivers ceilings and speeds and never level paths.

> 🔴 **λ is a DECLARED switch, not only an estimate.** `cm_pfmGapClosure` = **0** (deployed)
> forces every gap-closure rate to zero — the political gap persists — and **1** uses the rates
> above as a declared sensitivity. The default is 0 because the estimates cannot carry the claim:
> **neither two-sector rate beats persistence**, and a placebo battery says the estimator returns
> rates of this size when no adjustment exists (§4.3.2). The switch reaches bind modes 1 and 2
> only; mode 3's λ is a momentum rate and is never zeroed (`iterativePFM.R`, the note at the λ
> read). **Measured on the `v5` batch, it points opposite ways**: λ = 0 lowers the mode-L cost
> headline by 33–38% on the unforced anchor (+128 / +149 Gt against +192 / +240 Gt with gap closure;
> on the pinned budget path +159 / +164 against +254 / +266, i.e. 37–38%) and raises the mode-R
> regional spread by 62–71% (1.88× / 1.76× against 1.10× / 1.09×). The scoping control passes:
> `-PFMmildProgGapC` is identical to `-PFMmildProg`. `SCENARIOS.md` §1.2.

#### 4.3.1 Two estimates of the same rate, with two jobs — decided 2026-09-17

The same error-correction model is estimated twice, on two windows:

| | Bulk | Diffuse | ratio | window | job |
|---|---:|---:|---:|---|---|
| **validation estimate** | 0.1094 | 0.0769 | 1.42× | 2001–2015 | scored out of sample on 2016–2022 (§4.3); the rate the `GAPCLOSE` sensitivity applies to prices |
| **projection estimate** | **0.1027** | **0.0621** | **1.65×** | 2001–2022 | used by `projectFeasiblePath()` to project stringency to the tier year, from which $E$ and $\varphi$ are read |

**Decision: both are documented and both are kept.** The projection uses the full panel, for three
reasons:

1. **The hold-out exists to test the estimator, not to fix the number.** Truncating the sample at 2015
   is what makes an out-of-sample score possible; once the model form has been scored, the defensible
   estimate for projection is the one that uses all available information.
2. **The two estimates are close.** Adding 2016–2022 moves the rate by 6% (Bulk) and 19% (Diffuse), so
   the out-of-sample behaviour of the 2015 fit is informative about the full-panel fit — the in-sample
   and out-of-sample estimates describe the same object.
3. **Discarding a third of the time dimension cannot be justified for projection.** The panel has 22
   years; dropping the last 7 removes the period in which policy moved most, for a rate whose
   identification is already weak (§4.3.2).

The two rates are labelled wherever either is quoted: the validation estimate carries the skill scores
and the placebo comparison; the projection estimate is the one inside every $\varphi$. At the deployed
`cm_pfmGapClosure = 0` neither rate enters a price in modes R and L. `runPFMCouplingBound()` logs both
roles.

#### 4.3.2 What the λ audit found (`output/pfm/v5/lambda-explained/LAMBDA-EXPLAINED.html`)

| | Bulk | Diffuse |
|---|---:|---:|
| published λ | 0.1094 | 0.0769 |
| placebo null, deployed RHS, no adjustment by construction — median [95%] | 0.291 [0.181, 0.419] | 0.104 [0.062, 0.209] |
| placebo null, bare ECM | 0.268 [0.230, 0.303] | 0.100 [0.081, 0.119] |
| per-country λ, median (share ≤ 0) | 0.042 (21%) | −0.022 (67%) |
| simple estimators: within / leader-gap / fractional closure | 0.036 / 0.084 / 0.270 | 0.021 / 0.049 / 0.114 |

> 🔴 **The Diffuse λ sits inside its own placebo null**, and Bulk sits *below* its null. A panel
> in which nothing closes any gap returns rates of this size, so the pooled λ measures the
> estimator's mechanical pull on a bounded, trending index, not a demonstrated political
> adjustment. Two-thirds of Diffuse countries have a non-positive own-country λ. This is why
> gap closure is off by default.

The audit also records: attractor $S^{\text{eq}}$ rank-correlates with observed stringency at
0.40 (Bulk) / 0.48 (Diffuse), against 0.65 / 0.90 for $S^{*}$; the frozen ceiling falls 10% in
Bulk (75% of countries decline) and rises 21% in Diffuse to 2100; and drivers out of estimation
support rise from 1% to 43% of rows by 2100.

---

## 5. The feasibility share $\varphi$

> **$\kappa$ is retired (ADR 0041).** A bounded index times a constant is a bounded price cap
> that makes ambitious scenarios infeasible for an arithmetic reason rather than a political one.
> No index→price exchange rate is used anywhere.

### 5.1 Couple in relative terms

With $P^{\circ}$ the unconstrained cost-optimal price and $P^{\text{ref}}$ the current-policy
price:

$$\boxed{\;P^{*}_{r,t} = P^{\text{ref}}_{r,t} + \varphi_r\big[P^{\circ}_{r,t} - P^{\text{ref}}_{r,t}\big]\;}$$

> *In words:* the political constraint applies to the *extra* mitigation effort an ambitious
> pathway demands, not to the policy a region already has.

Two consequences: the current-policy scenario reproduces itself exactly, and $P^{*}\le P^{\circ}$
always — politics can only slow, never accelerate (ADR 0024).

**This is the floor, not the whole price (ADR 0042).** $\varphi_r$ above is the most-constrained
combination across sectors, and $P^{*}$ is what every emission market pays as a minimum. **Each
market then carries its own sector's price on top:**

$$P^{m}_{r,t} = P^{*}_{r,t} + \underbrace{\max\!\big(P^{s(m)}_{r,t}-P^{*}_{r,t},\,0\big)}_{\text{markup}},
\qquad s(\text{ETS}) = \text{Bulk},\quad s(\text{ES}) = s(\text{other}) = \text{Diffuse}$$

`cm_pfmSectorMarkup = 1` (default) delivers this; `0` collapses to the pure `min`. See
`COUPLING.md` §11.

> **The invariant:** $P^{*} + \text{markup}(m)$ reproduces market $m$'s own sector price exactly.
>
> ⚠️ **The floor can sit below both sector prices**, because `min` takes the worse *share* and the
> slower *speed* and those can come from different sectors — yet every consumer of
> `pm_taxCO2eqSum` (MAC curves, land-use tax, trade tariffs, net-negative penalty) sees it.
>
> ⚠️ **Never quote "the carbon price" of a coupled run without naming the market**, and never add
> the markups together.

### 5.2 $\varphi$ from the **relative** gap, continuously

$$g_r = 1 - E_r = 1 - \frac{S_r}{S^{*}_r} \qquad\text{(not the absolute gap } S^{*}-S)$$

$$\boxed{\;\varphi_r = 1 - \theta\,u_r,\qquad u_r = \frac{g_r-g_{\min}}{g_{\max}-g_{\min}}\;}$$

over regions with a valid ceiling at the tier year.

**Why relative** (`gapMeasure = "relative"`): an absolute ranking is dominated by ceiling size —
it ranks regions by how much they *could* do rather than how far they *fall short*. `"absolute"`
is retained as a disclosed sensitivity.

**Why continuous** (`phiRule = "continuous"`): the tiered form moved $\varphi$ in steps of
$\theta/(K-1)$, and relative gaps cluster tightly enough that a small change in $E$ could cross
two boundaries. Endpoints match the tiered rule, so $\theta=0$ remains the exact uncoupled null.
`tier` survives as a descriptive label only.

**Three disciplines:** ranking, not levels; **assigned once at the tier year and held fixed**
(`aggregateFeasibilityToRegions.R`); $\varphi$ is a **parameter** refreshed between coupling
iterations, never a decision variable.

**The tier year.** Inside REMIND it is `cm_startyear + 5` (`iterativePFM.R`), the first period
REMIND is free to change — **2035** for every coupled scenario, all of which run
`cm_startyear = 2030`. The offline bound (`runPFMCouplingBound`) uses **2025**. Offline and
coupled $\varphi$ are therefore read at different years and are not interchangeable.

**The offline bound at θ = 0.50** (`coupling/coupling-summary.rds`, EU21, 2025, final-energy
weights): median $\varphi$ **0.669**; floor regions ($\varphi = 1-\theta$) **CHA, REF**;
unconstrained **UKI**; tier counts 5 / 5 / 5 / 6.

**The coupled φ at θ = 0.50** (`-PFMlevelB`, 2035, `coupled-facts.json$phi`): median **0.738** at
both resolutions; floor regions **ECS, REF** (EU21) and **LAM, REF** (H12), identical in every run at
every θ; top NEN 0.938 (EU21) / CAZ 0.877 (H12). The floor pair differs from the offline one because
the tier year and the energy system differ. Across the eleven θ = 0.50 budget runs a region's φ
moves by up to **0.077** — the energy-system feedback — and the PFM loop contracts over 3–8 calls.

### 5.3 $\theta$ is declared and swept, not estimated

No historical experiment assigned carbon prices by political gap, so $\theta$ is not identified.

**The deployed set (ADR 0045):**

| $\theta$ | role |
|---:|---|
| **0** | uncoupled null — reproduces the standard run *exactly* (`PFMgate` rows) |
| **0.325** | declared low point of the sweep |
| **0.50** | **declared central value** (`cm_pfmTheta`); every headline uses it |
| **0.675** | declared high point, symmetric about 0.50 |

The offline bound additionally sweeps 0 / 0.25 / 0.50 / 0.75 / 0.95 / 0.99
(`coupling-summary.rds$thetas`) as a diagnostic grid.

**The efficiency analogy, and why it no longer anchors anything.** Solving $1-\theta\bar u=\bar E$
for the median region (region resolution, tier year 2025, $n$ = 21,
`coupling-summary.rds$anchorDerivation`):

| sector | median $E$ | median $u$ | gap range | $\theta$ |
|---|---:|---:|---:|---:|
| Diffuse | 0.783 | 0.662 | 0.085–0.285 | **0.328** |
| Bulk | 0.773 | 0.222 | 0.098–0.677 | **1.019 ✗** (outside $[0,1)$) |

> 🔴 **Bulk is inadmissible and Diffuse alone lands near the low point.** The analogy therefore
> cannot bracket the sweep from both sides, and **no θ value may be called "the efficiency
> anchor"**. 0.325 / 0.50 / 0.675 is a declared, symmetric sweep; 0.325 sits close to the Diffuse
> analogy and that is a coincidence of the numbers, not a calibration. `runPFMCouplingBound()`
> records the derivation on every run (`computeEfficiencyAnchor()`, carrying `resolution` and
> `tierYear`), so it stays re-checkable.

> ⚠️ **The analogy is not resolution-invariant.** $u$ is normalised over whatever units the frame
> holds. **Country-level anchor figures must not be quoted for the coupling.**

**Offline θ sweep** (`coupling-summary.rds$thetaSweep`, mode L bound, EU21, λ published):

| θ | 0 | 0.25 | 0.50 | 0.75 | 0.95 | 0.99 |
|---|---:|---:|---:|---:|---:|---:|
| median 2050 shortfall vs $P^{\circ}$ | 35.5% | 37.5% | 39.4% | 42.1% | 44.2% | 44.7% |
| median 2050 bound, \$/tCO₂ | 228.7 | 221.6 | 215.1 | 205.5 | 197.8 | 196.3 |

$P^{\circ}_{2050}$ median 354.8 \$/tCO₂; bind share 84.5% of region-years at every θ. The θ = 0
shortfall is the speed limit alone. $P^{\circ}$ and $P^{\text{ref}}$ come from the uncoupled
gdx recorded in `coupling-summary.rds$optGdx/$refGdx`.

#### 5.3.0 $\varphi$ is also specification-dependent

$\theta$ is not the only undetermined choice entering $\varphi$. The **specification** is equally
undetermined: the deployed spec wins **8.5%** of bootstrap resamples (§6), and the per-sector
optima differ from it (§2.4). That uncertainty must be carried to $\varphi$, not stopped at the
coefficient table.

**Measured on `v5`, 2026-09-17** (`output/pfm/v5-specalt`: Bulk pinned to its per-sector optimum
`X-1791 WGIge|RoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp`, Diffuse left at the deployed
`X-2079`; five steps re-run from the frontier to the coupling bound, compared at a common θ = 0.50 by
`analysis/checks/compareSpecVariantPhi.R` → `output/pfm/v5/coupling/spec-band-v5-specalt.rds`):

| | `v5` | `v5-specalt` |
|---|---|---|
| Spearman of φ across 21 regions | — | **0.775** |
| median / max $\lvert\Delta\varphi\rvert$ | — | **0.0001** / **0.271** (IND) |
| median rank shift | — | **1 of 21** |
| regions with $\lvert\Delta\varphi\rvert > 0.05$ | — | **5 of 21** (IND −0.271, OAS −0.187, CAZ −0.101, REF +0.090, ENC −0.070) |
| floor region(s) | CHA, REF | **CHA, IND** |

> 🔴 **Read this as a few large moves, not a narrow band.** The median is ~0 because 15 of 21 regions
> barely move — for two of them because the Diffuse sector binds and the `min()` absorbs the change
> entirely. Where the Bulk spec does bind it moves φ by up to 0.271, more than a θ step, and it
> **changes which region sits on the floor** (REF → IND). The floor region is what the coupling reads
> first, so quote the max and the rank shift with the median, never the median alone (claim C31).

The previous deployment `X-1959` was not run: one admissible alternative answers C31, and the
per-sector optimum is the harder test of the two.

**Two disciplines for that comparison, both learned the hard way:**

- **Compare at a common θ.** `anchorTheta` is a property of the artifact. Recover the θ-invariant
  $u = (1-\varphi)/\theta$ and re-apply one θ; `compareSpecVariantPhi.R` does this unconditionally.
- **A defect shared by both arms does not cancel in a normalised rank statistic** — it suppresses
  the between-region spread in both at once. Re-derive; never argue that it cancels.

> **The discipline this implies.** $\varphi$ is a property of a region **given a specification
> and a frontier error structure**, never a measured property of the region. Report it the way
> $\theta$ is reported — a declared choice with a disclosed band.

**The statement to use wherever the Shared Specification is defended** (numbers `v5`; the band
figures ⏳):

> We deploy one specification across both sectors. That is a choice with a price — each sector
> gives up about a fifth of the explanatory content it could reach alone (19.4% supply side,
> 19.8% demand side) — and we make it because the coupling compares the two sectors' feasibility
> scores against each other, and a comparison between two differently-built scores would not be
> meaningful. The price is that the feasibility share is a property of a region *given a model*:
> refitting under another admissible specification moves it by ⏳, and changing the frontier's
> error structure moves it by a median of up to 0.17. We therefore report it as a band, for the
> same reason we sweep the severity parameter rather than estimating it.

#### 5.3.1 Routes to θ other than declaring it

| route | what it needs | what it buys | verdict |
|---|---|---|---|
| **1. Declare + sweep** *(deployed)* | nothing | honesty; θ becomes a scenario axis | **deployed**; the sweep *is* the deliverable |
| **2. Efficiency analogy** | median $E$ and median $u$ | one point | **fails on `v5`** — Bulk inadmissible (§5.3) |
| **3. Price–efficiency elasticity** | a carbon-price panel + the stringency panel | an *empirical* θ range | the most promising; `TODO.md` |
| **4. Calibration** | observed regional price dispersion | θ that best reproduces history | feasible, circular risk |
| **5. Partial identification (bounds)** | revealed-preference restrictions | an interval | computed below |
| **6. Expert elicitation** | a structured protocol | a documented prior | out of scope |

**Route 3.** $\log(1+P_{r,t}) = \alpha_r + \tau_t + \beta E_{r,t} + \varepsilon_{r,t}$; the implied
best-to-worst price ratio $\exp(\beta\,\Delta E)$ maps onto the range $\varphi$ may span. It can
fail — $\alpha_r$ absorbs the cross-section that identifies slow-moving institutions, and §8.1's
IV is a null — and a failure would not block the coupling.

**Route 5 — bounds** (`analysis/checks/computeThetaBounds.R v5`, `analysis/checks/efficiencyRatioBand.R v5`).

*Upper bound — revealed preference.* A region cannot credibly be modelled below the price it has
already legislated. Under mode L the cap is $\varphi_r P^{\circ}$, so
$\theta \le (1-P^{\text{ref}}_{r,t}/P^{\circ}_{r,t})/u_r$. Minimised over region-years with
$P^{\circ}>P^{\text{ref}}$ and $t\ge2030$:

$$\boxed{\;\theta_{\max}=0.159\;}\qquad\text{binding: ECS at 2040}$$

At θ = 0.25 one region violates it (ECS); at θ = 0.50 seven (DEU, ECE, ECS, ESC, ESW, EWN, FRA);
at θ = 0.75 nine. The 21 region-years at 2025 have $P^{\circ}=P^{\text{ref}}$ exactly, where no
positive θ is admissible under a multiplicative level cap.

*Lower bound — resolution.* $u$ is min–max normalised, so the spread θ induces in $\varphi$ is
exactly θ; below the width at which $E$ itself is resolved the differentiation is inside its own
noise. $E = S/(M\operatorname{logit}^{-1}(\eta_F))$ is monotone in $\eta_F$, so a CI on $\eta_F$
maps to $E$ by transforming the endpoints:

$$\mathrm{se}(\eta_F) = \sqrt{\mathbf x'\boldsymbol\Sigma_\beta\mathbf x},\qquad
E^{\mathrm{hi}} = \frac{S}{M\operatorname{logit}^{-1}(\eta_F - z\,\mathrm{se})},\qquad
E^{\mathrm{lo}} = \frac{S}{M\operatorname{logit}^{-1}(\eta_F + z\,\mathrm{se})}$$

| median 95% CI width on $E$, 2022 | Bulk | Diffuse | pooled |
|---|---:|---:|---:|
| ML band | 0.082 | 0.058 | 0.067 |
| design effect (clustered / naive SE, same design, mean regression) | 2.20× | 3.07× | — |
| **cluster-scaled — the one to quote** | **0.184** | **0.176** | **0.183** |

> 🔴 **On `v5` the interval is EMPTY:** $[0.183,\ 0.159]$. The resolution floor sits above the
> revealed-preference ceiling, so **no θ is both resolvable and consistent with legislated prices
> under the multiplicative level cap.** (On the ML band alone it is $[0.067, 0.159]$, but the ML
> band understates; the cluster scaling is an approximation — there is no clustered sandwich for
> the SFA likelihood — and it is the defensible one.)

**Why this is not fatal, and what it does say.**

1. **It does not restrict mode R.** The relative coupling (§5.1) satisfies $P^{*}\ge P^{\text{ref}}$
   by construction at every θ. The bound concerns the absolute-level formulation only.
2. **REMIND's legislated-price floor is what makes mode L usable.**
   `cm_taxCO2_lowerBound_path_gdx_ref` enforces $P\ge P^{\text{ref}}$ directly, and the regions the
   bound flags are the regions the floor rescues.
3. **Every declared θ (0.325 / 0.50 / 0.675) is above $\theta_{\max}$.** That is a statement about
   multiplying a level rather than an increment, not about severity.

> **What to write.** Not "θ must be below 0.159". The defensible sentence is: **the multiplicative
> level cap is incompatible with revealed preference over the whole declared θ range, and only
> REMIND's legislated-price floor makes it usable; the relative formulation needs no such rescue.**

### 5.3.2 Sources of uncertainty in $\varphi$, and where each is reported — decided 2026-09-17

$\varphi$ is a property of a region **given a set of modelling choices**, not a measured property of
the region. Every choice below moves it; none is identified by the data.

| source | what varies | size on `v5` | reported in |
|---|---|---|---|
| **1. Severity θ** | declared dial, 0.325 / 0.50 / 0.675 | the whole spread: floor regions sit at $1-\theta$ | **main text** — swept through REMIND (Fig 3c, Fig 5b) |
| 2. Frontier error structure | four defensible frontier variants (half-normal, truncated-normal, panel, time-decay) | median $\lvert\Delta\varphi\rvert$ **0.024 / 0.055 / 0.171**; Spearman 0.96 / 0.53 / 0.44 (EU21, offline, §3.4.1) | SI — rank intervals |
| 3. Specification | Bulk refitted on its per-sector optimum `X-1791` (`v5-specalt`) | median $\lvert\Delta\varphi\rvert$ **0.0001** but max **0.271** (IND), Spearman **0.775**, and the floor region moves REF → IND (§5.3.0) | SI — with the max and the rank shift, not the median alone |
| 4. Frontier coefficients | sampling error of $\eta_F$ | median 95% CI width on $E$ **0.183** (cluster-scaled, §5.3.1) | SI (also the θ lower bound) |
| 5. Projection speed | validation vs full-panel λ (§4.3.1) | rates differ 6% / 19%; effect on $\varphi$ not separately measured | SI (Methods states which rate builds $\varphi$) |
| 6. Out-of-coverage assignment | donor / low-band / median rule for 200 countries; USA override | Bulk low band covers 109 of 200 countries; USA φ set by override (0.649 / 0.567 coupled) | SI; USA as a range (`TODO.md` item 6) |
| 7. Aggregation weights | final energy vs GDP vs equal | Spearman agreement within 0.03 on every rung comparison (§3.4.1) | SI, one sentence |
| 8. Tier year | where $\varphi$ is read: 2025 offline, 2035 coupled | floor regions CHA, REF (offline 2025) vs ECS, REF (coupled EU21 2035) | Methods, one sentence |
| 9. Energy-system feedback | φ recomputed on the live REMIND energy system | up to **0.077** per region across coupled runs (claim C23) | **main text** as a result, not an uncertainty |

**The reporting rule.** The main text carries θ as the band and treats $\varphi$ as **ordinal** — a
ranking of regions, not a level. Sources 2–8 are reported in the SI, with the rank-interval figure for
source 2 and the specification band for source 3. Any sentence about **which sector binds** carries the
source-2 caveat, because the attribution moves with the frontier variant.

### 5.4 Countries the sample never saw — the band rule

Uncovered countries keep their **own** ceiling and inherit only a relative gap,
$\hat S = \hat E\cdot S^{*}_{\text{own}}$. Placement uses the model's own signed linear index
$\ell_i = \sum_k\beta_k x_{ik}$:

| branch | assigned $E$ | when |
|---|---|---|
| **donor** | inverse-distance blend of the $k=3$ nearest covered countries | a match exists within the covered sample's own nearest-neighbour spread |
| **lowBand** | lower quartile of covered $E$ | $\ell_i$ below every covered country's — extrapolation past the low end of support |
| **median** | median of covered $E$ | $\ell_i$ inside or above the covered range — unmatched for structural reasons |

Distance is in the model's own metric, $d(i,j)^2 = \sum_k w_k(x_{ik}-x_{jk})^2$,
$w_k = |\beta_k|/\sum|\beta|$.

`v5` assignment (`donor-assignment-band-<sector>.rds`, 200 uncovered countries per sector):

| | donor | lowBand ($E$) | median ($E$) |
|---|---:|---:|---:|
| Bulk | 72 | **109** (0.628) | 19 (0.707) |
| Diffuse | 59 | 78 (0.690) | 63 (0.746) |

> ⚠️ **In Bulk the low band is the majority branch** — 55% of uncovered countries sit below the
> covered range of the linear index. That is a large share of the world assigned by a quantile
> rule, and it should be disclosed alongside any coverage figure.

**One documented override:** `basisOverride = c(USA = "median")`. Donor transfer assumes $E$ is a
function of the drivers — but if it were, it would be *predicted*, not transferred. US drivers
match it to high-capability, high-willingness polities, while US federal policy spans states with
world-leading regulation and states with almost none. The USA's tier **must be reported as a
range, never a point**.

**Provenance travels with the number.** Each region reports
`shareObserved / shareDonor / shareLowBand / shareMedian`. The coupling weights countries by
final energy, not by GDP; if a GDP coverage figure is used, say so in the same sentence.

### 5.5 Aggregation weights

Countries aggregate to IAM regions by **final energy**, the closest available correlate of what a
carbon price acts on:

$$w_i = \mathrm{FE}_i(t_0)\cdot\frac{\mathrm{GDP}^{\text{ssp}}_i(t_w)}{\mathrm{GDP}^{\text{ssp}}_i(t_0)}$$

`v5`: final energy `fe_total` at base year 2022, scaled by SSP2 GDP to 2025, 208 countries,
max/median weight **417**. Only relative within-region shares matter, so uniform growth cancels
and the SSP enters through differential growth only.

Both `iterativePFM()` and `runPFMCouplingBound()` call `pfmAssertSizeWeights()`, which fails on
any weight vector with max/median < 20 — the signature of accidentally equal weights
(`PITFALLS.md` §20).

### 5.6 The three bind modes — how $\varphi$ becomes a price

Three formulations; **they are alternatives, not stages** — each makes a different claim.
Notation: $A_t$ the global anchor path, $P^{\circ}$ the unconstrained cost-optimal price,
$P^{\text{ref}}$ the current-policy (NPi) price, $\lambda_r$ the closure rate (§4), $t^0_r$ the
start year.

**Mode R — $\varphi$ bounds the price *ratio*** (`cm_pfmBindMode = 1`)

$$\boxed{\;P_{t,r} = \rho_{t,r}\,A_t,\qquad
\rho_{t,r} = 1-(1-\varphi_r)\,(1-\lambda_r)^{\,t-t^0_r}\;}$$

Every region pays a share of the common anchor. **Claim:** politics changes **where** abatement
happens. The budget is always met. With `cm_pfmGapClosure = 0`, $\lambda_r = 0$ and
$\rho = \varphi$ for the whole horizon.

> **Structural weakness.** $\varphi$ multiplies the anchor, so a rising anchor raises the
> constrained region's price with it. With the §5.1 markup live the burden separates by market
> instead of being absorbed by an anchor rescale.

**Mode L — $\varphi$ caps the absolute *level*** (`cm_pfmBindMode = 2`)

$$\boxed{\;P_{t,r} = \min\big(A_t,\;\varphi_r P^{\circ}_{t,r}\big)\;}$$

in the relative form of §5.1 ($P^{\text{ref}} + \varphi(P^{\circ}-P^{\text{ref}})$), approached
at speed limit $\lambda$ (immediately when $\lambda = 0$). **Claim:** politics caps **how much**
a region can do. The budget may become unreachable — **that is the finding, not a bug.**

> ⚠️ $P^{\circ}$ must come from a path the cap cannot touch. Reading it from the run's own capped
> price makes the recursion a contraction onto $P^{\text{ref}}$ within a few coupling calls
> regardless of the politics.

**Mode M — mild progression** (`cm_pfmBindMode = 3`)

$$\boxed{\;P_{t+1,r} = P_{t,r}\Big(1+\lambda_r\,\frac{S^{*}_{t+1,r}-S_{t,r}}{S_{t,r}}\Big),
\qquad P_{t_0,r} = P^{\text{NPi}}_{t_0,r}\;}$$

The price is **generated** by political momentum — no anchor, no budget. **Claim:** where does
observed political momentum take us? Its λ is never zeroed by `cm_pfmGapClosure` — at 0 the price
would freeze at its seed, a tautology rather than a finding.

> ⚠️ **Two gap definitions coexist.** Mode M uses $(S^{*}-S)/S = 1/E-1$ — unbounded as $S\to0$,
> bounded by a `maxGrowth` cap. Everything else uses $1-E\in[0,1]$. A path with a high
> `cappedShare` is driven by the cap, not by the politics.

**All three feed the same delivery step** — the mode chooses how politics limits the price;
ADR 0042's markup chooses how that limit is distributed across markets.

**Conflict rules — mode L only**, when the political bound and the budget cannot both hold:

| rule | mechanism | the headline it supports | scenario rows |
|---|---|---|---|
| **B** | drop the budget forcing (`cm_iterative_target_adj = 0`) | *political feasibility costs $X$ Gt CO₂, against the same unforced price path* | `PFMlevelB`, `PFMlevelBTh325/Th675` |
| **C** | keep the budget (`= 9`), report the required violation | *region $r$ must sustain $N\times$ its feasible price* | `PFMlevelC` |
| **D** | allow the budget to be met later | *politics delays the price path by $N$ years* | never run |

**What the `v5` batch shows** (θ = 0.50, λ = 0; `SCENARIOS.md` §4):

| | EU21 | H12 |
|---|---:|---:|
| **mode R**: peak cumulative CO₂ (budget 1000) | 1001.5 | 998.9 |
| mode R: anchor 2050 relative to θ = 0 | 1.33× | 1.35× |
| mode R: within-region ES/ETS, 2050 | 0.66–1.37 | 0.70–1.31 |
| **quantity headline**: Δ cumulative CO₂ 2100, `-PFMlevelBfix` vs `-PFMgateBfix` (pinned budget path) | **+159.3 Gt** | **+163.8 Gt** |
| quantity headline across θ 0.325 / 0.675 | +100.0 / +224.1 | +100.3 / +235.6 |
| mode L rule B vs `-PFMgateB` (unforced anchor, SI) | +128.4 Gt | +148.8 Gt |
| rule B across θ 0.325 / 0.675 | +73.9 / +204.1 | +76.9 / +217.5 |
| **mode L rule C**: peak cumulative CO₂ | 1000.4 (restarted, converged) | 998.8 |
| **mode M**: Δ cumulative CO₂ 2100 vs `-PFMgateB` | +873.0 Gt | +1204.4 Gt |

Rule C holds the budget in **all six** of its runs once the EU21 deployed run is allowed to finish
converging. Mode M is six to eight times mode L and does not corroborate it.

> ⚠️ **What rule B is measured against.** With budget forcing off, REMIND never raises the anchor: the
> θ = 0 null `-PFMgateB` runs a **uniform price of \$75 (2030) → \$86 (2050) → \$104 (2100)** and
> emits **1710 Gt** by 2100 (peak 2319 Gt), not 1000. Headline B is therefore the extra CO₂ when
> politics caps prices *below that low path* — not the cost relative to the 1000 Gt pathway. The same
> low path puts EU/UK prices below their \$199 current-policy level in the null already, so the
> rollback in rule-B runs is a property of the unforced family, not of the political cap.
>
> **Decided 2026-09-17, measured 2026-09-18** (`TODO.md` 14g): the quantity headline is the anchor
> pinned to the budget-held `-PFMgate` path with budget forcing off (`FIXPRICE`: `-PFMlevelBfix` vs
> `-PFMgateBfix`, read from the donor's gdx through `cm_pfmAnchorFromGdx`; `COUPLING.md` §11.7). The
> null reproduces `-PFMgate` to **0.21% / 0.35%** (993.7 against 991.6 Gt EU21; 992.6 against 989.1
> H12) at an identical 2050 anchor, and the cap then adds **+159.3 / +163.8 Gt** (claim C35,
> `SCENARIOS.md` §4.2a). The rows above are the SI sensitivity. Mode R stays the price headline.

---

## 6. Selection stability (`selection-bootstrap.rds`, 200 resamples)

> 🔴 **The `satAP` figures below are not valid (PITFALLS §29, found 2026-10-06).** The bootstrap
> cache did not tell a spec from its `satAP` twin, so each linear/`satAP` pair was represented by
> whichever was cached first. The `satAP` row of the table and the `X-2010 … satAP` modal-winner
> share must not be quoted. Channel-set and actor-power-form shares are approximately right.

Deployed spec `X-2079`. Top-**60** pool, 200 resamples, of which **196** produced a winner
(`gateEmptyShare` 0.02); 11 pool members are rejected by the sanity walk and are never eligible.

> ⚠️ **A raw selection frequency is not evidence.** The menu offers three accountability options
> against one "none", so a selector choosing at random takes *some* accountability ~79% of the
> time. Every frequency below is reported against both the menu rate and the top-60 pool share.
> **The gaps are the evidence.**

| element | in the menu (4,392) | in the top-60 pool | among 196 winners | winners vs pool |
|---|---:|---:|---:|---|
| Government Effectiveness (`WGIge`) | 52.5% | **100.0%** | **100.0%** | stable ($p$ = 1) |
| Rule of Law (`RoL`) | 52.5% | 91.7% | 74.0% | drift down ($p$ < .001) |
| **any** accountability channel | 78.7% | 90.0% | 79.6% | drift down ($p$ < .001) |
| Vertical Accountability (`VerAcc`) *(deployed)* | 26.2% | 35.0% | 42.9% | drift **up** ($p$ = .02) |
| actor power `bothIncAP` *(deployed)* | 16.4% | 43.3% | **76.0%** | drift **up** ($p$ < .001) |
| actor power `splitAPpc` | 16.4% | 26.7% | 17.3% | drift down ($p$ = .003) |
| saturating transform `satAP` | 41.5% | 43.3% | 45.9% | stable ($p$ = .47) |

Two-sided exact binomial against the pool share, $n$ = 196.

**The deployed spec.** Wins **8.5%** of resamples (10.0% conditional on sanity-eligible winners);
passes the gate in 54% of resamples; rank quantiles 5% = 1, 25% = 2, median = **8**, 75% = 14,
95% = 27. The modal winner is `X-2010 WGIge|RoL|noAcc bothIncAP … satAP` at 12.2%, which the
full-sample sanity walk rejects (ceiling collapse to 0.576).

**Channel sets.** Among winners: `RoL|VerAcc` 29.6%, `RoL|noAcc` 20.4%, `noRoL|VerAcc`
*(deployed)* 13.3%, conditional 16.0%. Individual accountability: Vertical 42.9%, Diagonal 23.5%,
none 20.4%, Horizontal 13.3%.

**Slot-corrected** (wins against the share of pool slots a set holds):

| channel set | pool slots | wins | obs/exp | $p$ |
|---|---:|---:|---:|---:|
| **`WGIge|noRoL|VerAcc`** *(deployed)* | 2 | 26 | **3.98** | 3e−09 |
| `WGIge|noRoL|DiagAcc` | 3 | 25 | 2.55 | 2e−05 |
| `WGIge|RoL|noAcc` | 6 | 40 | 2.04 | 1e−05 |
| `WGIge|RoL|HorAcc` | 8 | 26 | 0.99 | 1 |
| `WGIge|RoL|VerAcc` | 19 | 58 | 0.93 | .59 |
| `WGIge|RoL|DiagAcc` | 22 | 21 | 0.29 | 3e−16 |

> ✅ **State capability is point-identified in the token sense** — 100% of pool and winners against
> a 52.5% menu rate. *State capability belongs in the model* is a claim the evidence carries without
> qualification.
>
> ✅ **The actor-power form is settled by resampling.** `bothIncAP` takes 76% of winners against a
> 43% pool share — the largest drift in the table — and it is the deployed form.
>
> ⚠️ **The deployed channel set is favoured per slot and a minority in absolute terms — both are
> true.** Rule of Law is in 92% of the pool and 74% of winners, yet the deployed spec omits it.
> Per pool slot, `noRoL|VerAcc` is the most over-selected set (3.98×). The full-sample filter keeps
> RoL; resampling within the survivors rewards the two `noRoL` accountability sets. Report both.
>
> 🔴 **Which accountability channel is not identified.** No option reaches half of winners.

> **What may be claimed.** *State capability belongs.* *Incumbency belongs in both share and
> per-capita form.* **Neither the channel set nor the specification is uniquely selected**; the
> deployed spec is an 8.5%-frequency winner at median bootstrap rank 8. Any sentence asserting the
> model *is* `X-2079` rather than *was run at* `X-2079` is false.

---

## 7. What must NOT be done

Validated exclusions — each rejected by this project's own tests, not by preference:

| Prohibited | Why |
|---|---|
| Projected policy-level paths as IAM inputs | Static level forecasts lose to persistence (§4.3) |
| The $S/10$ implementability multiplier | Compares countries to a universal maximum; use $E = S/S^{*}$ (§3.2) |
| Point frontier ceilings or named slack rankings | Slack ranks not robust across rungs in either sector; use tiers and rank intervals (§3.4) |
| $S^{*}$ as the ECM attractor | $\lambda$ was validated against $S^{\text{eq}}$ (§4.2) |
| Ceilings for out-of-coverage countries | 200 of 248 projected countries are outside the sample; they receive a transferred *relative* gap only (§5.4) |
| Any index→price exchange rate $\kappa$ | Retired (ADR 0041) |
| An unqualified "carbon price" for a coupled run | ETS and ES face different prices; name the market (§5.1) |
| Adding $P^{*}$ and a markup to get "the" price | A floor and a market-specific increment |
| Calling any $\theta$ *the efficiency anchor* | Bulk analogy inadmissible on `v5`; θ is declared (§5.3) |
| Quoting a country-resolution anchor for the coupling | $u$ is normalised over regions (§5.3) |
| Comparing mean-regression and frontier coefficients as refits of each other | Different estimands (§2.2) |
| Quoting frontier $p$-values as clustered inference | ML SEs; no clustered sandwich for SFA (§3.3) |
| Quoting the validation λ as the rate that produces $\varphi$ | $\varphi$ uses the full-panel projection estimate (§4.3.1) |
| Describing λ as a measured political adjustment speed | Inside or below its placebo null (§4.3.2) |
| Scenario differences past ~2060 | Driver out-of-support share grows large late-century (§4.3.2) |
| Ranking estimators on AIC/BIC across families | Different response scales and quasi-likelihoods |
| Calling the feedback causal | The IV is an endogeneity-confirmed null (§8.1) |

---

## 8. Open scientific questions

**8.1 Causal status of the feedback.** The shift-share IV (base-year incumbency × leave-one-out
global VRE diffusion) **confirms endogeneity** but **identifies no causal incumbency effect**
(`iv.rds`, $n = 1104$):

| rung | Incumbency $\hat\beta$ (2SLS) | SE | $p$ | first-stage $F$ | Wu–Hausman $p$ |
|---|---:|---:|---:|---:|---:|
| Bulk, with trend | −118.5 | **2 238.8** | .96 | 9.3 | 4e−29 |
| Bulk, no trend | −62.1 | **654.0** | .92 | 7.1 | 7e−88 |
| Diffuse, with trend | −2.14 | 3.33 | .52 | 12.7 | 3e−22 |
| Diffuse, no trend | 14.1 | 62.6 | .82 | 6.2 | 2e−98 |

The Bulk standard errors are three orders of magnitude above the estimate: the coefficient is
**unidentified**, not merely insignificant. Three of four rungs are weakly instrumented
($F$ < 10). **Do not report the point estimates.** Report that endogeneity is confirmed at
$p < 10^{-20}$ in every rung and that the instrument cannot identify the effect — *we can show the
relationship is endogenous; we cannot show what it is.* Until this changes, label the feedback
**conditional scenario accounting**, and **do not write "causes" anywhere near the loop.**

**8.2 The ceiling-feedback sign.** The feedback channel is live and small. Between the
current-policy and the 1000 Gt budget pathways (`projections/`), ambition raises the projected
index in **32 of 48** countries in Bulk and **30 of 48** in Diffuse at 2050, by a paired median of
+0.05 in both. Over 2040–2060 the Bulk mean is nevertheless **−0.075** — a minority of countries
fall sharply — against **+0.229** in Diffuse. On the sanity-gate
scenario panel, trend frozen and drivers guarded, the median Bulk ceiling falls 10% by 2100
(`ceilingFallGate` ratio 0.90) and the Diffuse ceiling rises 21% (1.21); the Bulk fall is driven by the incumbency terms (`Incumb × GovEff` −0.76 logit, `Incumb` share +0.65,
`Incumb pc` −0.40; net −0.28). This is a *balanced* feedback, **not** a confirmation of a
sequencing story, and it is not causal (§8.1).

**8.3 The exposure confound.** `Incumb × GovEff` (share) is **positive** where theory expects
negative — +0.151 in the Bulk mean regression, +0.203 on the Bulk frontier, positive in all seven
Bulk estimators — and Bulk per-capita incumbency is positive and significant. Large, capable
fossil economies also regulate more; the model cannot tell exposure from resistance. A
fossil-rents reader would be needed and none exists.

**8.4 The historical-replay gate — passes, and cannot discriminate.** Running the coupled system
over the historical panel (seed year 2000) must reproduce observed stringency at least as well as
the uncoupled ECM (`historical-replay.rds`, `$pass = TRUE`):

| Sector | RMSE coupled | RMSE ECM | skill vs ECM | skill vs persistence | ceiling binds |
|---|---:|---:|---:|---:|---:|
| Bulk | 0.821 | 0.821 | +0.0001 | +0.715 | **0.66%** of rows |
| Diffuse | 0.572 | 0.580 | +0.013 | +0.737 | 2.56% of rows |

> **Read the margin before the verdict.** The ceiling binds in under 1% of Bulk rows, so the
> coupled and uncoupled systems are the same model in 99% of the sample and the Bulk "pass" is a
> tie. The defensible reading is **"uninformative in Bulk, marginally positive in Diffuse"** — not
> "the coupling is validated". Out of sample the offline bound binds in 84.5% of region-years, and
> the coupled mode-L cap binds in 57% (EU21) / 96% (H12) of region-periods
> (§5.3); this gate says nothing about that regime.

**Re-scoped to where it can discriminate** (`analysis/checks/replayRescoped.R v5` →
`historical-replay-rescoped.rds`): on the rows where the coupled path differs from the uncoupled one —
88 Bulk country-years in 4 countries (8.3%) and 190 Diffuse in 9 (18.0%) — RMSE is 0.706 against 0.707
(skill **+0.001**) in Bulk and 0.589 against 0.629 (skill **+0.064**) in Diffuse. Where the ceiling acts
on history it improves the Diffuse fit and is neutral in Bulk. Quote this, not the diluted full-sample
figure (claim C29).

**8.5 The time trend does most of the explanatory work.**

| | Bulk | Diffuse |
|---|---:|---:|
| $\hat\beta$ on $T(t)$ per SD, frontier | **0.959** | **0.491** |
| $\hat\beta$ on $T(t)$ per SD, mean regression (§2.5) | 1.327 | 0.635 |
| trend share of linear-predictor variance (§2.4) | **0.736** | **0.552** |
| frontier $\lvert\hat\beta\cdot\mathrm{SD}\rvert$: trend vs sum over the 11 theory terms | 0.92 vs 1.35 | 0.47 vs 1.42 |

The trend is standardized, so these coefficients are directly comparable with every other row.
Freezing $T$ at 2022 leaves it 0.32 SD short of its plateau; unfreezing would lift the ceiling by
0.30 (Bulk) and 0.15 (Diffuse) logits — a small lever.

**So is the model usable?** Yes, for three reasons — with the framing kept ordinal.

1. **$\varphi$ is a cross-sectional ranking and the trend is common to everyone.** $T(t)$ has no
   $r$ subscript, so it shifts every region's ceiling together and largely cancels out of $u_r$.
2. **The trend cannot leak into projections** — it is frozen at the last historical year.
3. **Dropping it is worse, and measured:** the no-trend IV rungs are more weakly instrumented
   ($F$ 7.1 / 6.2 against 9.3 / 12.7 with the trend), and the no-trend frontier fits far worse.

**What it costs.** In Bulk three-quarters of the linear predictor's variance is secular drift the
model does not attribute to institutions or actor power. The defensible claim is about
**cross-sectional ordering** — who sits where relative to whom — not about how the ceiling got
where it is. Combined with §8.1's null and the event-timing failure (AUC 0.48 / 0.33, §4.3),
nothing here should be phrased as "institutions caused the ceiling to rise". Report the variance
share in the SI rather than waiting to be asked.

---

## 9. Artifact map

All in `output/pfm/v5/`.

| Quantity | File | Path within |
|---|---|---|
| Deployed spec | `selected-models-pfm.yml` | — |
| Every estimation number in this document | `doc-facts/facts.json` | written by `analysis/checks/docFacts.R` |
| ΔR²(theory), trend share, VIF, tier, maximin, sanity walk | `sweep.rds` | `$results`, `$maximin`, `$sanity` |
| Sharing cost, per-tier winners | `selection-variants.rds` | `$perSector`, `$winners` |
| Selection stability | `selection-bootstrap.rds` | `$channelSetFreq`, `$apFormFreq`, `$pool` |
| Mean regression: coefficients, wild-cluster $p$, AMEs | `inference.rds` | `$bySector$<s>$table` |
| Sign agreement across 7 estimators | `estimator-agreement.rds` | `$bySector$<s>$agreement` |
| Leave-one-country-out influence | `influence.rds` | `$bySector$<s>$byTerm` |
| Shift-share IV | `iv.rds` | `$bySector$<s>.<variant>` |
| Frontier $\beta_F$, $\gamma$, LR, covariance check | `frontier.rds` | `$bySector$<s>$coefTable`, `$gamma`, `$lr`, `$vcovCheck` |
| Ceilings, gaps, efficiency per country-year | `frontier.rds` | `$bySector$<s>$scores` |
| Frontier robustness rungs | `frontier.rds` | `$bySector$<s>$robustness` |
| Rungs propagated to $E$, $\varphi$, binding sector, rank intervals | `frontier-rung-phi.rds` | `$bySector`, `$minRule$<res>$<weights>`, `$countryBind` |
| 95% CI band on $E$ (θ lower bound) | `efficiency-ratio-band.rds` | `$bySector$<s>$medianWidthClustered` |
| $\lambda$, half-life, skill (2 sectors) | `temporal-validation.rds` | `$bySector$<s>$ecm$metrics` |
| $\lambda$ (4 sectors) | `sector-speeds.rds` | `$bySector$<s>$metrics` |
| λ audit: placebo, operational λ, attractors, ceiling path | `lambda-explained/facts.json` | rendered in `output/pfm/v5/lambda-explained/LAMBDA-EXPLAINED.html` |
| Historical-replay gate | `historical-replay.rds` | `$pass`, `$bySector$<s>$metrics` |
| Country projections | `projection.rds`, `projections/<scenario>.rds` | — |
| Donor / band assignment | `coverage/donor-assumptions.rds`, `donor-assignment-band-<sector>.rds` | — |
| Offline coupling bound: φ, tiers, θ sweep, anchor derivation | `coupling/coupling-summary.rds`, `coupling/feasibility-bound-theta*.csv` | — |
| Scenario-panel seam checks | `seam-diagnostics.rds` | — |
| Coupled runs: prices, φ per market, convergence, run QC | `coupling/coupled-runs.rds` | `$runs`, `$prices`, `$phi`, `$convergence` |
| Every coupled number quoted in the docs | `coupling/coupled-facts.json` | written by `analysis/coupled/coupledBatchFacts.R` |

**Code entry points.** `estimatePolicyStringencyModel()`, `computeFeasibilityFrontier()`,
`runPFMTemporalValidation()`, `runPFMSectorSpeeds()`, `computeWildClusterBootstrap()`,
`predictPolicyStringency()`, `projectFeasiblePath()`, `computeDonorAssignment()`,
`aggregateFeasibilityToRegions()`, `exportFeasibilityBound()`, `runPFMCouplingBound()`,
`iterativePFM()`.
