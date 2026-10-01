# Presenting the PFM — deck, figures and the one-page asset

*What to say, in what order, with which figure, and what not to claim. Plus the build spec for
a single-page poster carrying the whole model.*

This document is **derivative**: every number belongs to `MODEL.md`, every interface detail to
`COUPLING.md`, every run to `SCENARIOS.md`. It adds only sequencing, emphasis and the asset
spec. **Do not put a number here that is not in one of those** — re-read it from the artifact
and cite the source file, per the Run-Group rule. Numbers here are Run-Group **`v5`**, deployed
spec `X-2079 WGIge|noRoL|VerAcc bothIncAP lev ctl:GDPq.Pop.Hyd fe:OECDp`.

> Coupled numbers are from the `v5` batch (`output/remind-runs/v5/{EU21,H12}/*_2026-09-16_*`), collected in
> `output/pfm/v5/coupling/coupled-facts.json` and read in `SCENARIOS.md` §3–§8. Re-render the coupled
> figures on `v5` before building the deck.

**Audience assumed:** modellers and climate-policy researchers who know what an IAM is and
have not seen this model. A 20-minute talk is 12 content slides; a 45-minute seminar is the
same spine with the SI slides folded in.

---

## 1. The spine — the whole argument in six sentences

Say this out loud before building any slide. If a slide does not serve one of these, cut it.

1. Cost-optimal mitigation pathways assume any carbon price is implementable; politics says
   otherwise, and IAMs have no principled way to say *how much* otherwise.
2. Policy stringency is bounded above by what a polity's institutions and actor coalitions
   can support — so the right object is a **ceiling**, not a mean, and that makes it a
   **stochastic frontier**.
3. Each country's distance below its own ceiling is its **political slack**; the ratio
   $E = S/S^{*}$ compares a polity to *its own* possibility, not to a universal maximum.
4. That ratio becomes a **feasibility share** $\varphi$ on the *incremental* mitigation effort
   an ambitious pathway demands, and enters REMIND as an endogenous constraint that the
   energy system talks back to.
5. The result is a pathway that is cost-optimal **subject to political feasibility** — and the
   honest finding is how much of the cost-optimal price is unreachable, and where.
6. Several central quantities are **deliberately not identified** — $\theta$, the speed of
   political adjustment, the causal feedback, the accountability channel. **Reporting that is the
   contribution**, not a weakness to write around.

> **The one-sentence version:** *we turn institutions into a ceiling on carbon-price
> stringency, and couple that ceiling into an IAM so ambition is limited by politics
> endogenously rather than by assumption.*

---

## 2. Deck outline

Each slide: **message** (the one thing they should remember) · **figure** · **equation if
any** · **the rail** (what must not be claimed). Figure IDs match
`papers/pfm-paper-v5/docs/paper-design.md` so the deck and the paper share display items — build once.

### Act I — the problem and the object (slides 1–4)

**S1 · Why feasibility is an IAM problem**
*Message:* cost-optimal pathways price carbon as if implementation were free of politics; the
usual fix is an exogenous haircut nobody can defend.
*Figure:* **none** — one line of text and a cost-optimal price path climbing past anything
ever legislated.
*Rail:* do not claim existing IAMs are "wrong"; they answer a different question.

**S2 · The chain: polity → politics → policy**
*Message:* institutions (state capability, accountability) and actor coalitions (clean
innovators vs fossil incumbents) jointly bound what policy is possible.
*Figure:* **Fig 1a** — schematic of the chain resolving into $\varphi$. Conceptual, no data.
*Rail:* this is a *bound*, not a prediction of what a country will do.

**S3 · Why a frontier and not a regression**
*Message:* we want the conditional **maximum attainable**, not the conditional mean — so the
error is composed: symmetric noise minus a one-sided shortfall.
*Equation:* the composed error (§4, Eq. 3).
*Figure:* **schematic** — a scatter with a mean line and a frontier above it, the vertical
distance labelled *political slack*. The single most valuable slide in the deck.
*Rail:* do not present the frontier as an efficiency score in the productivity sense.

**S4 · The data**
*Message:* 48 countries × 22 years (2001–2022), OECD CAPMF stringency 0–10, two sectors —
Bulk (electricity + industry) and Diffuse (buildings + transport).
*Figure:* CAPMF coverage map, with **out-of-coverage rendered as absent, never as zero**.
*Rail:* 200 of 248 projected countries are outside the estimation sample. Say it here.

### Act II — building the ceiling (slides 5–8)

**S5 · The estimating equation**
*Message:* stringency responds to actor power, institutional quality, and **their
interactions**. State capability is the one institutional channel supported in both sectors —
strongly for buildings and transport, fragilely for power and industry. Incumbency enters twice:
its **share** (dependence) goes with lower stringency, its **per-capita size** with higher.
*Equation:* the linear predictor (§4, Eq. 2) with the bounded-response transform (Eq. 1).
*Figure:* **Fig 2a** — each frontier term's contribution to the ceiling, $\hat\beta\times\mathrm{SD}(x)$,
both sectors faceted.
*Rail:* significance on this slide comes from the **mean regression with wild-cluster bootstrap**
(`inference.rds`), not from the frontier's ML standard errors — say which estimator each number
is from. GovEff: +0.240 ($p_{\text{wild}}$ .048) Bulk, +0.333 (.006) Diffuse in the mean; on the
Bulk frontier it is +0.064, $p$ .32. **Do not say capability raises the Bulk ceiling.**
*Rail:* Vertical Accountability is **not significant** as a main effect in either sector. Do not
present an accountability finding.
*Rail:* the positive per-capita Bulk incumbency term (+0.489, $p_{\text{wild}}$ < .001) is the
exposure confound — large, capable fossil economies also regulate more (`MODEL.md` §8.3). Do
not present it as incumbents raising ambition.
*Rail:* the trend is the largest single term and carries **74% (Bulk) / 55% (Diffuse)** of
linear-predictor variance. Volunteer it (`MODEL.md` §8.5).

**S6 · Incumbency: dependence and scale**
*Message:* the same fossil interest shows up two ways — how much of the energy system depends on
it, and how large it is per person — and the data separate them.
*Figure:* **Fig 2b** — marginal effect of each incumbency term across the observed range of
government effectiveness, over observed support only.
*Rail:* one conditional term survives cluster-robust inference (`Incumb pc × VerAcc`, Bulk,
$p_{\text{wild}}$ .015) and it depends on China and Saudi Arabia (`MODEL.md` §2.6). Say "partly
conditional", not "works through institutions".

**S7 · The ceiling and the gap**
*Message:* every country-year gets a ceiling $S^{*}$ and a ratio $E = S/S^{*}$; the median country
sits at about **71% (Bulk) / 75% (Diffuse)** of its own ceiling in 2022.
*Equation:* $S^{*} = M\cdot\text{logit}^{-1}(\eta_F)$ and $E = S/S^{*}$ (§4, Eqs. 4–5).
*Figure:* **Fig 1b** — observed stringency against the fitted frontier, both sectors, 2022.
*Rail:* **tiers and rank intervals, never point ceilings or named country rankings** — slack
ranks do not survive the frontier robustness rungs in **either** sector on `v5`.

**S8 · How fast can a ceiling be approached**
*Message:* an error-correction model gives a speed at which policy closes the distance to its
equilibrium — and the data cannot tell that speed from no adjustment at all.
*Equation:* the ECM and its half-life (§4, Eq. 6).
*Figure:* four-sector speeds as a dot plot, **skill-vs-persistence annotated on each point**, with
the two-sector placebo null drawn as a band.
*Rail:* 🔴 **only electricity beats "assume nothing changes"** (+0.140). The published Diffuse λ
(0.077) sits **inside** a no-adjustment placebo null and Bulk (0.109) below it. That is why the
coupling assumes the gap persists. Both labels on the slide, not in the notes.

### Act III — coupling (slides 9–11)

**S9 · From ratio to price**
*Message:* the constraint applies to the **incremental** effort an ambitious pathway demands, not
to the policy a region already has.
*Equation:* the feasibility share and the coupling (§4, Eqs. 7–8).
*Figure:* a two-line schematic — $P^{\text{ref}}$, $P^{\circ}$, and $P^{*}$ between them, with
the shaded increment labelled *what politics governs*.
*Rail:* the current-policy scenario reproduces itself exactly, and $P^{*} \le P^{\circ}$ always —
politics can only slow, never accelerate.

**S10 · Two sectors, two markets**
*Message:* the model estimates two sectors and REMIND prices two markets, so each market carries
its own sector's price over a common floor.
*Equation:* the per-market markup (§4, Eq. 9).
*Figure:* a bar per market showing floor + markup, one region where each sector binds.
*Rail:* never quote "the carbon price" of a coupled run without naming the market.

**S11 · The loop**
*Message:* deploying clean energy changes who holds power, which changes what policy is possible,
which changes what the model may deploy next.
*Figure:* the loop diagram — IAM → energy → actor power → ceiling → price → IAM.
*Rail:* 🔴 **the feedback is not causal.** The shift-share IV confirms endogeneity overwhelmingly
and cannot identify the effect (Bulk standard errors in the hundreds to thousands). Say
"conditional scenario accounting", never "causes".

### Act IV — results and honesty (slides 12–14)

**S12a · What the ceiling means for the price — before REMIND responds**
*Message:* the politically feasible price bound sits well below the cost-optimal one and binds
nearly everywhere.
*Figure:* **Fig 3c** — the $\theta$ sweep: median 2050 feasible price and shortfall share, binding
share overlaid flat.
*Numbers (`output/pfm/v5/coupling/coupling-summary.rds`):* at $\theta = 0.50$, median 2050 feasible
bound **\$215** against a cost-optimal **\$355** — a **39.4%** shortfall, binding in **84.5%** of
region-years. The binding share is flat across $\theta$.
*Rail:* ⚠️ **this is the PFM-side bound, not a coupled REMIND result** — S12b is that. And 35.5
of the 39.4 points are already there at $\theta = 0$: the speed limit, not politics.

**S12b · What REMIND does when it feels the ceiling** — *the payoff slide*
*Message:* respecting the political ceiling either costs carbon or reshapes prices. Hold the price
path that meets the 1000 Gt budget and the ceiling adds **159 Gt CO₂ (EU21) / 164 Gt (H12)**; hold
the budget instead and it survives, but the global price rises a third and the industrial and
household carbon prices separate within regions — **in both directions**.
*Figure:* **Fig 5b** (`-PFMgateBfix` vs `-PFMlevelBfix`, both resolutions, with the θ 0.325–0.675 range
74–218 Gt and the gap-closure point 192–240 Gt) and **Fig 5a** (EU21 `-PFMratio`, 2050: ES/ETS
0.66–1.37; households pay less than industry in 15 of 21 regions, more in 6, including Russia).
*Rail:* name the market every time; every run permits rollback of legislated prices; the split
exists because the gap persists — at the estimated closure rate it nearly vanishes, while the cost
rises. Do not say "the constraint lands on households".

**S13 · Where it binds**
*Message:* the constraint is uneven across regions, and part of the ordering is a modelling choice.
*Figure:* **Fig 4a/4b** — efficiency ratio map and region rank **intervals** across the frontier
rungs, with a coverage inset.
*Rail:* out-of-coverage regions receive a transferred *relative* gap, never a ceiling. The USA has
no covered country — **a range, not a point**. The regions on the θ floor (offline: China and
Russia) are *ranked last*, not measured at 50%.

**S14 · What is not identified**
*Message:* several central quantities are deliberately not identified, and saying so is the
contribution.
*Figure:* **Fig 2c** — selection-bootstrap frequencies against pool and menu base rates.
Government Effectiveness is in **100%** of winners; the two-term incumbency form `bothIncAP` in
**76%**; the deployed channel set `WGIge|noRoL|VerAcc` in **13%** (most over-selected per pool slot,
3.98×); the exact specification in **8.5%**.
*Rail:* what may be claimed is **state capability belongs in the model** and **incumbency enters
in both forms**. What may **not** be claimed is that the deployed channel set or specification was
chosen by the data: Rule of Law is in 74% of winners and the deployed spec omits it; no
accountability measure wins half the draws. Pair with the fact that the deployed spec ranks first
only after a disclosed threshold choice (ADR 0045) and that each sector alone gives up about a
fifth of its explanatory content to share one specification.

> **Close on S14, not S12.** The uncomfortable slide is the one that makes the rest credible.

---

## 3. Current status — say this if asked, and do not overstate

- The PFM side is estimated, diagnosed and quotable from Run-Group `output/pfm/v5`: frontier,
  mean-regression inference with wild-cluster bootstrap, influence, IV, estimator agreement,
  selection bootstrap, temporal validation, historical replay, projections and the offline
  coupling bound.
- The REMIND interface is built and **verified against GAMS itself** (`COUPLING.md` §12). The
  θ = 0 gate reproduces its reference **to a tolerance**, not bit-for-bit.
- ✅ **The `v5` coupled batch is in**: 62 runs, EU21 + H12, all finished, zero early-period market
  failures. The unforced-anchor level cap adds +128 / +149 Gt (now an SI sensitivity; the quantity headline is re-measured on the pinned budget path, `FIXPRICE`, pending); mode R holds the budget with a 1.33× anchor and a within-region
  split; rule C holds the budget in six of six runs; φ moves by up to 0.08 as the energy system
  changes. The quantity headline — the ceiling on the price path that holds the budget — adds
  **+159 / +164 Gt CO₂** (`SCENARIOS.md` §4.2a). Every run that hit the iteration cap on 2026-09-16
  has been re-run and converges. **Where it lands is now measured too** (Fig 5d, §4.8): under a held
  budget the ceiling relocates 72–81 Gt of abatement rather than reducing it, and under the cap the
  extra emissions concentrate in the most constrained regions.
- 🟠 The historical replay: on the country-years where the ceiling changes the path, the coupled
  replay beats the uncoupled ECM by **6%** in Diffuse (190 rows, 9 countries) and ties in Bulk (88 rows,
  4 countries). An in-sample check, not validation. `MODEL.md` §8.4, claim C29.
- 🔴 Under the raw multiplicative level cap there is **no admissible θ**: the revealed-preference
  ceiling (0.159) sits below the resolution floor (0.183). The deployed mode L is anchored on
  current policy and is unaffected (`MODEL.md` §5.3.1).

If someone asks "what does the coupled model say?", the honest answer is: *respecting the political
ceiling costs about 130–150 Gt CO₂ at the central severity, 74–218 Gt across the severity range; if
the budget is held instead, it survives, but the global carbon price rises a third and each region
prices industry and households differently — in a direction that depends on the region.*

---

## 4. The equations that must appear

The minimum set to follow the build-up. Symbols are `MODEL.md` §1.

**(1) Bounded response.** Stringency is 0–10 by construction, so it is modelled on the logit
scale:

$$y^{*} = \operatorname{logit}\!\left(\tfrac{p(n-1)+0.5}{n}\right), \qquad p = S/M,\quad M = 10$$

**(2) The linear predictor.** Actor power, institutions, and their interactions:

$$\eta = \alpha + \beta_1 A^{\text{in}} + \beta_2 A^{\text{ic}} + \beta_3 A^{\text{ic,pc}} + \beta_4 G + \beta_5 V
+ \underbrace{\textstyle\sum_{j}\sum_{k\in\{G,V\}}\beta_{jk} A^{j}\!\cdot\! k}_{\text{6 interactions}}
+ \beta_T T(t) + \boldsymbol\psi'\mathbf{z} + \delta_{g(c)}$$

**(3) The frontier** — the composed error is what makes it a ceiling:

$$y^{*}_{c,t} = \mathbf{x}'\boldsymbol\beta_F + v_{c,t} - u_{c,t},
\qquad v \sim N(0,\sigma_v^2), \quad u \sim N^{+}(0,\sigma_u^2)$$

**(4) The ceiling in index units:**

$$S^{*} = M\cdot\operatorname{logit}^{-1}(\eta_F)$$

**(5) The efficiency ratio** — each polity against *its own* possibility:

$$E = S/S^{*} \in (0,1]$$

**(6) Speed** — error-correction, on the logit scale:

$$\Delta y^{*}_{t} = c_0 + \phi\,y^{*}_{t-1} + \boldsymbol\theta'\mathbf{x}_{t} + \epsilon,
\qquad \lambda = -\phi, \qquad t_{1/2} = \frac{\ln 0.5}{\ln(1-\lambda)}$$

**(7) The feasibility share** — from the *relative* gap, continuously:

$$g_r = 1 - E_r, \qquad u_r = \frac{g_r - g_{\min}}{g_{\max} - g_{\min}},
\qquad \varphi_r = 1 - \theta\,u_r$$

**(8) The coupling** — on the increment, not the level:

$$P^{*}_{r,t} = P^{\text{ref}}_{r,t} + \varphi_r\big[P^{\circ}_{r,t} - P^{\text{ref}}_{r,t}\big]$$

**(9) Per-market delivery** — each market carries its own sector over a common floor:

$$P^{m}_{r,t} = P^{*}_{r,t} + \max\!\big(P^{s(m)}_{r,t} - P^{*}_{r,t},\ 0\big)$$

**(10) The three bind modes** — alternatives, not stages. R says where, L says how much, M asks
where momentum alone goes.

$$\text{R (ratio)}\quad P_{t,r} = \rho_{t,r}A_t,\qquad \rho_{t,r}=1-(1-\varphi_r)(1-\lambda_r)^{t-t^0_r}$$

$$\text{L (level)}\quad P_{t,r} = \min\big(A_t,\ P^{\text{ref}}_{t,r} + \varphi_r[P^{\circ}_{t,r} - P^{\text{ref}}_{t,r}]\big)$$

$$\text{M (mild progression)}\quad P_{t+1,r} = P_{t,r}\Big(1+\lambda_r\tfrac{S^{*}_{t+1,r}-S_{t,r}}{S_{t,r}}\Big)$$

*Rail:* mode M uses a **different gap definition** — $(S^{*}-S)/S$, unbounded — from everything
else, which uses $1-E$. At the deployed `cm_pfmGapClosure = 0`, $\lambda_r = 0$ in R and L but not
in M. Modes L and M must not be presented as corroborating each other.

> **If you must cut, cut (1) and (9).** Equations 2–8 and 10 are the irreducible spine:
> predictor → frontier → ceiling → ratio → share → price → how it binds.

---

## 5. Scenario formulation, in presentation form

Three **bind modes** — alternatives, not variants, because they make different claims:

| mode | what $\varphi$ does | the claim | infeasibility |
|---|---|---|---|
| **R** ratio | scales the global anchor | politics changes **where** abatement happens | impossible by construction |
| **L** level | caps the price at current policy plus φ × the extra effort | politics caps **how much** a region can do | possible — *and that is the finding* |
| **M** mild progression | generates the path from political momentum | **where does observed momentum take us?** | no anchor, no budget |

$\theta$ is **declared and swept, never estimated**: 0 is the uncoupled null, 0.50 the central
value, 0.325 and 0.675 the sweep.

> ⚠️ **Do not call any θ "the efficiency anchor" on a slide.** The analogy that once motivated a
> value is inadmissible for Bulk on `v5` (1.019) and gives 0.328 for Diffuse; it anchors nothing.
> Never quote a country-resolution figure for the coupling (`PITFALLS.md` §15). **If asked "where
> does 0.50 come from?", the honest answer is "we declared it, and we sweep it — here is the
> sweep."**

**The ladder, in order**: `-PFMgate` at $\theta = 0$ must reproduce its reference within tolerance
(an interface test, not a result) → `-PFMratio` → `-PFMlevelC` → `-PFMlevelB` → `-PFMmildProg` →
the NPi twins → the `THETA` and `GAPCLOSE` sensitivities.

*Figure for this section:* a small-multiples grid, one per scenario, each showing the anchor and the
realised price, built from `output/pfm/v5/coupling/coupled-runs.rds`.

---

## 6. The single-page asset

One page carrying the model, the scenarios and the results — for a poster board, a one-pager, or
the slide you leave up during questions.

### 6.1 Format

**Build it as self-contained HTML and print to PDF.** The equations need real typesetting, the
layout must reflow between A0 and A4, and a text-based source stays diffable.

- **A1 portrait (594 × 841 mm)** for a poster board; the same source prints readably at A3.
- **Print CSS with `@page { size: A1 portrait; margin: 15mm }`**, every dimension in `mm` or `rem`.
- **Self-contained**: inline the CSS, embed figures as base64 `data:` URIs, typeset the equations as
  **inline SVG**, so it renders with no network and no runtime.
- Body text ≥ 6 mm cap height at A1 — readable from ~1.5 m.

### 6.2 Layout — five bands, top to bottom

```
┌──────────────────────────────────────────────────────────────┐
│ TITLE · one-sentence claim · authors                    [1]  │
├───────────────────────────┬──────────────────────────────────┤
│ WHY  the problem          │ WHAT  polity→politics→policy [2] │
│ cost-optimal vs feasible  │ chain schematic (Fig 1a)         │
├───────────────────────────┴──────────────────────────────────┤
│ HOW — the build-up, left to right as a pipeline         [3]  │
│  Eq2 predictor → Eq3 frontier → Eq4 ceiling → Eq5 ratio      │
│  → Eq7 share → Eq8 price     [frontier scatter: Fig 1b]      │
├───────────────────────────┬──────────────────────────────────┤
│ SCENARIOS  3 bind modes   │ RESULTS  θ sweep (Fig 3c)   [4]  │
│ + θ sweep table           │ + coupled result (Fig 5b)        │
├──────────────────────────────────────────────────────────────┤
│ WHAT WE CANNOT SAY — θ, λ, causality, channel (Fig 2c)  [5]  │
└──────────────────────────────────────────────────────────────┘
```

**Band 3 is the poster.** Lay the six equations out as a **left-to-right pipeline with arrows**,
each with a three-word plain-language gloss beneath. A reader who only looks at band 3 should still
leave understanding the model.

**Band 5 is not optional.**

### 6.3 Build instructions

1. **Draft the content** as a single Markdown file, `../communication/onepager/pfm-onepager.md`, holding only text
   and equations.
2. **Generate the figures** at final size, vector, from `output/pfm/v5` artifacts (§7).
3. **Assemble** `../communication/onepager/pfm-onepager.html` — CSS Grid, five band rows, band 3 a nested
   six-column pipeline. Inline everything.
4. **Verify at size**: print to PDF at A1, then view at 25%.
5. **Check both themes** if it will be shown on a screen as well as printed.

> **Every number on the asset names its Run-Group** — `output/pfm/v5` — in the footer, with the date.

### 6.4 Honesty rails for the asset

Three things must be *printed*, not spoken:

- **"PFM-side bound, before REMIND re-optimises"** wherever a shortfall number appears.
- **"Only electricity beats a no-change forecast; the speed is not distinguishable from no
  adjustment"** on any speed figure.
- **"Not causal"** on the loop diagram.

---

## 7. Figure inventory — what exists, what must be built

**Figures are built by `analysis/figures/`** — a registry, one builder per figure, rendered per medium
(`analysis/figures/README.md`). The explainer for each is generated into `analysis/figures/output/FIGURE-GUIDE.md`,
and every figure is on one page at `analysis/figures/output/all/index.html`. **Slide renders are opt-in**:
`Rscript analysis/figures/build-figures.R --media=slide` before building a deck.

```bash
Rscript analysis/figures/build-figures.R --media=slide     # the deck
Rscript analysis/figures/build-figures.R --media=poster    # the one-pager
```

🔴 **Every figure must be re-rendered on `v5`**, and the coupled figures once the batch lands. Check
output dates against artifact dates rather than trusting a clean run (`TODO.md` item 24a).

| ID | panel | source artifact (`output/pfm/v5/`) | status |
|---|---|---|---|
| Fig 1a | polity→politics→policy chain | conceptual | `chain-schematic` |
| Fig 1b | observed vs fitted frontier, 2022 | `frontier.rds` | `frontier-fit` — re-render |
| Fig 1c | efficiency-ratio distribution, by provenance | `frontier.rds`, donor bands | `efficiency-distribution` — re-render |
| Fig 2a | term contributions β×SD(x) | `frontier.rds` (+ `inference.rds` for significance) | `frontier-coefficients` — re-render; mark significance from the mean regression |
| Fig 2b | marginal effect of incumbency across GovEff | `frontier.rds` (`$vcov`, `$support`) | `marginal-effect-incumbency` — re-render; must name which of the two incumbency terms |
| Fig 2c | selection-bootstrap frequencies | `selection-bootstrap.rds` | `selection-stability` — re-render |
| Fig 3a | anchor vs bound vs gap, 2025–2100 | `coupling/coupling-summary.rds` | `anchor-bound-gap` — re-render |
| Fig 3b | 2050 regional shortfall distribution | `coupling/coupling-summary.rds` | `shortfall-regions` — re-render |
| Fig 3c | theta sweep | `coupling/coupling-summary.rds` | `theta-sweep` — re-render |
| Fig 4a | choropleth, out-of-coverage left uncoloured | `frontier.rds`, donor bands | `implementability-map` — re-render |
| Fig 4b | region rank intervals across frontier rungs | `frontier-rung-phi.rds` | `implementability-ranked` — **re-point** from a country point ranking to intervals |
| Fig 4c | coverage inset per REMIND region | `coupling/coupling-summary.rds` | `coverage-by-region` — re-render |
| **Fig 5a** | **ES vs ETS price by region, 2050** | `coupling/coupled-runs.rds` | `coupled-sector-split` — re-render on `v5` |
| **Fig 5b** | **cumulative CO₂, `-PFMgateB` vs `-PFMlevelB`, both resolutions** | `coupling/coupled-runs.rds` | `coupled-budget-cost` — re-render on `v5` |
| **Fig 5c** | **NPi twins vs the θ = 0 null** | `coupling/coupled-runs.rds` | `coupled-npi-twins` — re-render on `v5` |
| — | four-sector speeds with skill annotation | `sector-speeds.rds` | `sector-speeds` — re-render; add the placebo band |
| — | driver correlation matrix | `frontier.rds` | `driver-correlations` — re-render |
| — | the IV null | `iv.rds` | `iv-null` — re-render |
| — | selection landscape, 4392 candidates | `sweep.rds` | `selection-landscape` — re-render |
| — | coupled φ convergence | `coupling/coupled-runs.rds` | `coupled-convergence` — re-render on `v5` |
| — | estimator sign agreement | `estimator-agreement.rds` | `estimator-agreement` — re-render |
| — | the historical-replay gate | `historical-replay.rds` | `historical-replay` — re-render |
| — | cost of one shared specification | `selection-variants.rds` | `sharing-cost` — re-render |

> ⚠️ **The `saturating-map` figure no longer describes the deployed model** — the deployed spec
> carries no saturating transform. Keep it out of the deck unless the talk is about the
> specification menu.

**One figure is deck-only and worth building first**: the **frontier schematic** for S3 (mean line
vs frontier with slack labelled — hand-drawn is fine and probably better).

---

## 8. Rails — the complete list

Every one of these is a claim the evidence does not support. They apply to slides, the asset, and
answers to questions.

| Do not | Because |
|---|---|
| say the feedback "causes" anything | the IV is an endogeneity-confirmed **null** |
| name countries in a slack ranking, in either sector | slack ranks do not survive the frontier robustness rungs |
| present a point ceiling | $\gamma$ is close to 1 — tiers and intervals only |
| say state capability raises the Bulk ceiling | absent from the Bulk frontier; fragile in the Bulk mean |
| present an accountability finding | Vertical Accountability is insignificant in both sectors, and no channel wins half the bootstrap |
| present a speed as political catching-up | λ is inside or below its no-adjustment placebo null |
| show a sector speed as a forecast | only electricity beats persistence |
| quote frontier p-values as the paper's inference | ML at 48 clusters; use the wild-cluster mean regression |
| pair modes L and M as "convergent validity" | they are anchored on the same NPi path; an earlier agreement was a defect |
| call any $\theta$ the anchor | the analogy is inadmissible in Bulk; θ is declared |
| quote a country-resolution anchor for the coupling | $u$ is normalised over 21 regions |
| give the USA a point feasibility share | no covered country; it is set by an override |
| say "the carbon price" of a coupled run | ETS and ES face different prices |
| call the θ = 0 gate "bit-identical" | it matches to a tolerance |
| cite the replay gate as validation | it is in-sample, and ties in Bulk |
| show scenario differences past ~2060 | drivers out of support reach 43% of rows by 2100 |
| give an out-of-coverage region a ceiling | they receive a transferred relative gap only |
| say the constraint "lands on households" | households pay less than industry in 15 of 21 regions |
| say rule C cannot hold the budget | it holds in six of six runs |
| quote +128 / +149 Gt as the headline | that is the unforced-anchor SI sensitivity; the headline is +159 / +164 Gt on the pinned budget path (`SCENARIOS.md` §4.2a) |

---

## 9. Where each claim comes from

| Section | Source |
|---|---|
| §1 spine, §4 equations | `MODEL.md` §2–§5 |
| §5 scenarios | `COUPLING.md` §3, `SCENARIOS.md` §2 |
| §2 S5–S8 numbers | `output/pfm/v5/doc-facts/facts.json` (`MODEL.md` §2–§4) |
| §2 S12a numbers | `output/pfm/v5/coupling/coupling-summary.rds` |
| §2 S12b numbers | `output/pfm/v5/coupling/coupled-facts.json` (`SCENARIOS.md` §4) |
| §2 S14 numbers | `output/pfm/v5/selection-bootstrap.rds` (`MODEL.md` §6) |
| §3 status | `TODO.md`, `COUPLING.md` preamble |
| §8 rails | `MODEL.md` §7, `PITFALLS.md` §15 |
