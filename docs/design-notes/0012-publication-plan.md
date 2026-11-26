# 0012 — Publication plan: which papers, in which order, with which headlines

**Status: Decided 2026-11-23 (D1–D18).** Set up the same day: `papers/pfm-gmd`, `papers/pfm-ncc`, GMD support in paper-forge, the batch in `scenario-matrix-v8.yml` (§12, §14). The author approved the
split into a model paper (*Geoscientific Model Development*), which frames the PFM as a feasibility module for any
integrated assessment model with REMIND as the case study, and a *Nature Climate Change* paper with the working
headline *Mitigation pathways that treat political limits as permanent overstate their emissions cost*. D1–D12 are
answered. No third paper for now: Options B and C are parked here.

**Provenance.** Drafted 2026-11-23 as a Claude Doc (https://claude.ai/artifact/PdSxQxm1AER1s2aX9aNtYi); this file is
the record and holds everything the doc holds. Sources read: `../_archive/_wip/2026-11-23/papers/pfm-paper-v5/manuscript/paper-v18.md`,
`../_archive/_wip/2026-11-23/papers/pfm-model-paper/manuscript/paper-v06.md` and its `docs/framing.md`, `docs/allocation.md`, `docs/claims.md`,
`docs/gap-plan.md`; `../_archive/_wip/2026-11-23/papers/elevate-d3.3/manuscript/paper-v13.md`; `docs/SCENARIOS.md`, `docs/MODEL.md` §5.6a,
`docs/COUPLING.md` §14.1. Every number is Run-Group `v8` (SSP2, REMIND 3.7.1, 21 regions, θ = 0.50, fading limit,
to 2100, unless stated) and is orientation only: like every design note this one is not authoritative, so re-read a
number from its artifact (`coupled-facts.json`, `shrinking-future.rds`, `coupled-costs.json`,
`open-loop-strength.rds`) before it enters a paper.

**Related.** 0006 (the `v6` paper frames: the persistence ladder as the common finding) is the predecessor of this
note's Option A and F; 0010 §11 holds the persistence evidence.

---

## 1. What is decided

| date | decision | by |
|---|---|---|
| 2026-11-23 | Two papers: a model paper (GMD) carrying the rigour, and a Nature paper on one question the selection rules do not decide | author |
| 2026-11-23 | Nature paper's working headline: *Mitigation pathways that treat political limits as permanent overstate their emissions cost* (Option A, candidate A2) | author |
| 2026-11-23 | The model paper presents the PFM's ideas, formulation and coupling accessibly and concisely first; the step-by-step detail (search, fossil rents, estimation) goes to appendices, as the explainer videos moved them to their SI episodes | author |
| 2026-11-23 | No third paper for now; Options B and C stay on record here | author |
| 2026-11-23 | The GMD paper frames the PFM as a module to couple with IAMs generically; REMIND is the case study, and the paper underlines that other models can use it | author |
| 2026-11-23 | D1–D12 answered (§13) | author |
| 2026-11-23 | D13–D18 answered (§13); the GMD title drops "applied with REMIND 3.7" (REMIND is named in the abstract and the paper) | author |
| 2026-11-23 | Workspaces: `papers/pfm-gmd` (new, built from `../_archive/_wip/2026-11-23/papers/pfm-model-paper`'s history, first version v01) and `papers/pfm-ncc`; `../_archive/_wip/2026-11-23/papers/pfm-model-paper` frozen as a quarry | author |
| 2026-11-24 | The GMD title and spine say "an estimated ceiling on climate-policy stringency" in place of "an estimated limit on carbon-price stringency" (GMD review-v03 M1: the ceiling is estimated, the price limit adds the declared severity and persistence) | author |

## 2. What the earlier drafts teach

Every earlier headline was about the **direction** in which the limit moves, and that direction is set by the paper
itself: the selection requires fossil dependence to lower the ceiling (H1–H3), and the fading limit is declared. So
referees and the desk read each headline as "a property of the model presented as a finding".

| draft | headline it tried | what it showed | why it stalled |
|---|---|---|---|
| `pfm-paper-v5` v18 (`v5`) | *What politics permits*: hold the budget redistributes the price; hold the price adds CO₂ | +159.3 to +163.8 Gt at the central severity; abatement moves to China | sizes declared; the ordering did not survive the error structure; no finding a non-modeller repeats |
| `elevate-d3.3` v13 | none by design: describes the model and the assessments it enables | the menu of assessments (horizon, net zero, who abates, sectors, institutions, relaxation) | a deliverable, not a paper; a useful menu of questions |
| `pfm-model-paper` v06 (`v8`) | six titles in five reviews, ending at *Political limits on carbon prices can be weaker on ambitious pathways than on current policies* | pathway contrast in 2050: 0.82 / 0.75 on current policies against 0.61–0.64 / 0.62–0.63 on 1000 Gt pathways | direction built in; size fragile in power and industry; no CO₂ for the contrast; desk: "reads as a model description" |

**The rule that follows.** A Nature headline must come from one of three places the selection rules do not reach:
(1) REMIND's response to the limit (investment, expectations, where abatement goes); (2) the most clearly estimated
quantity, each country's 2023 distance below its ceiling; (3) a comparison with other practice (governance caps,
current-policies pathways, observed prices). The model paper keeps the rest, where hedging is a strength.

## 3. The catalogue of possible papers

| id | paper | working headline | state | home |
|---|---|---|---|---|
| P1 | **The model paper** | *The Political Feasibility Model (PFM v1.0): an estimated ceiling on climate-policy stringency for integrated assessment models* | **active** | GMD, `papers/pfm-gmd` (§4) |
| P2 | **The Nature paper: persistence and expectations (Option A)** | *Mitigation pathways that treat political limits as permanent overstate their emissions cost* | **active** | *Nature Climate Change* Article, `papers/pfm-ncc` (§5) |
| N | Calibrating the severity from current policies (Option N) | *Political limits explain how unevenly carbon is priced today* (only if the fit holds) | active **inside P1** | P1 §6 and Appendix J (§7) |
| B | Political headroom and the emissions gap | *Today's politics already allows much of the effort current policies miss* (or the reverse) | **parked** 2026-11-23 | a later paper; its offline check may feed P1 (§8.1) |
| C | Sequencing: cutting fossil dependence first | *Cutting fossil dependence first makes higher carbon prices feasible later* | **parked** 2026-11-23 | *Nature Energy* or a third paper (§8.2) |
| D | Governance caps limit the wrong regions | *Governance indicators put political limits on carbon prices in the wrong places* | reserve | short Analysis, or P1 §6 (§9) |
| E | Lock-in where limits bind | *Where political limits bind hardest, they entrench themselves* | reserve | a section of P2, or P1 §6 (§9) |
| F | Persistence as a scenario dimension | *How long political limits last is the missing dimension of mitigation scenarios* | reserve | NCC Perspective, after P2 (§9) |
| G | Budget floor | *Political limits put a floor under the carbon budget a pathway can reach* | reserve | only if A fails; close to Bertram et al. 2024 (§9) |

## 4. Paper 1: the model paper (GMD)

The model paper presents the PFM as **a feasibility module for integrated assessment models in general, with REMIND as
the case study** (author, 2026-11-23). It is model-paper v06 in **two layers**: a main paper that presents the PFM's
ideas, formulation and model-independent interface briefly and accessibly, then appendices that go through each step.
About 80% of the text exists in v06 and its SI.

**Why the generic framing holds.** The PFM computes everything at country level for 249 countries and aggregates to any
regional set; it already runs at two REMIND resolutions (21 and 12 regions). It needs from a model only regional
energy-system quantities that IAMs report in the IAMC template, plus SSP income and population, and it returns one
table: a feasibility share by region, period and carbon market (D3.3 Table 5). Since the feedback is second order for
most regions (C51, C58), a model without an iteration loop can use one evaluation per pathway. The claim stays
"designed for any IAM, demonstrated with REMIND": no second model has been coupled. Use with other models is stated as
future work (D18).

**Why GMD allows this.** GMD has no length limit and expects appendices; a model description paper should be
"detailed, complete, rigorous, and accessible", and "all technical details which could substantially affect the
numerical output should be described"
([manuscript types](https://www.geoscientific-model-development.net/about/manuscript_types.html)). Reviewers check
that the description allows reproduction
([review criteria](https://www.geoscientific-model-development.net/peer_review/review_criteria.html)). So the search,
the rents slack and the estimation detail may leave the main text, but they go to **appendices** (peer reviewed),
not to a supplement only: GMD's supplement is for the code, the user manual and material without a DOI. GMD also
requires the model name and version number in the title and a "Code availability" section at the end.

**Title** (author, 2026-11-23; revised 2026-11-24 after the GMD review-v03 M1, was "an estimated limit on carbon-price stringency"). *The Political Feasibility Model (PFM v1.0): an estimated ceiling on climate-policy stringency for integrated assessment models.* REMIND is named in the abstract and the paper, not in the title. The
version label is D9 (a release tag); no package version is changed for it.

**Layer 1, the main paper** (about 6,000 words, 8 figures; videos 1–3 are its source):

1. **Why IAMs need an estimated, pathway-responsive feasibility limit.** Carbon prices today against what a 1000 Gt
   pathway asks; how models treat feasibility now (after-the-fact scoring, fixed governance caps, stylized endogenous
   policy). Written for every IAM, not for one. Fig. 1.
2. **The PFM in brief, independent of any IAM.** In words first: politics sets a ceiling, governments choose how close
   to it they go, so a frontier and not an average. The three ingredients: the economic weight of fossil and
   clean-energy interests, three institutional channels, and their interaction weighted by freedom of expression. Two
   display equations (the ceiling; the price share), the frontier inline. What is estimated, declared and not
   identified, in one table. Fig. 2 schematic.
3. **The interface: how any IAM uses the PFM.** What it reads (regional energy-system shares, fossil income, SSP income
   and population), what it returns (a share by region, period and market), how 249 countries map to any regional set.
   Three modes of use: a two-way iteration; one evaluation per pathway; a fixed table used as a constraint or a
   diagnostic. How the share acts on a carbon price (the step above current policy), with the two closures (hold the
   price, hold the budget) as choices any model can make. Fig. 3.
4. **Case study: the coupling with REMIND.** Where it sits (the carbon-price module), what REMIND passes and receives,
   convergence in one paragraph, two resolutions as a test of the regional mapping. Fig. 4.
5. **The estimated frontier.** Net effects of each group of terms; the ends of the regional order; one paragraph on
   fossil rents in the buildings-and-transport gap; **one sentence on the selection**, pointing to Appendix D.
   Figs. 5–6.
6. **What the coupling does in REMIND, and what carries over to other models.** Pathway dependence and the
   second-order feedback (one evaluation per pathway is a fair approximation, except for the most limited region);
   severity and persistence; hold the budget; governance caps; θ calibrated from current policies (Option N, if run);
   the PFM applied to another IAM's published pathway (D18). Figs. 7–8.
7. **Evaluation and limits.** What the model must not be used for; the four quantities not identified; only REMIND has
   been coupled. These stay in the main text: moving them out reads as hiding them (`allocation.md` §1).
8. **Code and data availability.**

**Layer 2, the appendices** (step by step, no length limit; videos 4–6 and the v06 SI are their source):

| app. | step by step | from |
|---|---|---|
| A | the full model: every equation, the symbol and parameter tables, one coupling round as an algorithm | v06 SI S1 |
| B | data: sources and editions, the panel, transformations, coverage, country lists | v06 SI S2 |
| C | estimation and inference: likelihood, the two estimators kept apart, the wild cluster bootstrap, leave-one-out, coefficient tables | v06 Methods, SI S3 |
| D | the specification search: the menu, 36,384 candidates, the gates, the theory gate as a requirement, the funnel, the walk, split-sample replication, selection bootstrap | video 6; SI S4 |
| E | fossil rents and the gap: the rentier argument, the estimate, the out-of-sample test, how REMIND's fossil income moves it | video 5; SI S6 |
| F | assessing the estimated model: quantile frontiers, error structures, γ, interaction subsets, the index maximum, the abatement-cost refit | video 4; SI S5, S8 |
| G | projecting the drivers: harmonisation, the fossil bound, saturation, gap-closure institutions, edge-of-data checks | v06 Methods |
| H | the coupling in detail: country to region, countries without data, normalisation and what it does to θ, the strength by driver group, the convergence audit | SI S9 |
| I | the scenario set: every run, its switches and its result | SI S10 |
| J | calibrating θ from current policies, step by step | Option N (new) |
| K | worked example: one country's ceiling built term by term | video 1 (Poland); SI S11 |
| L | what the model does not do: the historical replay, the forecast test, the instrument | SI S7 |
| M | coupling another IAM: the interface specification (variables, units, IAMC names), the country-to-region mapping, what the IAM must implement (a regional price limit), the three modes of use, a checklist, the offline demonstration of D18 | D3.3 Table 5; `COUPLING.md` (new section) |

**The supplement.** The code (data package, model package, REMIND fork, analysis scripts) at tagged commits; a user
manual (running `pfmRun()`, and a section for coupling another IAM that mirrors Appendix M); the evidence bundle; the
six explainer videos, once revised (D11), as video supplements in a DOI-bearing repository.

**What it deliberately does not claim.** No headline finding about politics. The frontier *encodes* structural power,
the declared quantities are reported as declared, the coupled results are model behaviour.

## 5. Paper 2: the Nature paper (Option A, persistence and expectations)

With the price path held, a political limit known to last adds **+75.1 Gt** CO₂ by 2100. The same limit applied
decade by decade, each decade expecting it to lift afterwards, adds **+39.4 Gt**. The limit in each decade is within
±0.005 of the one-shot run's and the prices paid are the same (193 vs 191 $/t CO₂ in 2050): only the expectation
differs (`shrinking-future.rds`; `MODEL.md` §5.6a).

**Question.** How much of the climate cost of political limits comes from treating them as permanent, rather than from
the limits themselves?

**Why it is new.** Existing feasibility work fixes limits in advance (Bertram et al. 2024) or scores pathways
afterwards; none asks what expectations about political change do. The answer comes from REMIND's investment
response: each step invests for the full price it expects after its decade, and the next step inherits that capital.

**Titles.** A2 (accepted): *Mitigation pathways that treat political limits as permanent overstate their emissions
cost*. Sharper, once the grid holds: A1 *Expecting political limits to lift halves their climate cost*; A3 *Believing
political limits will ease does more than easing them by a third*. Fallback if gate G1 fails (§13 D6): *Mitigation
pathways planned once overstate the emissions cost of political limits*.

**Abstract sketch.** Mitigation pathways that represent political feasibility fix the limit in advance. In an
integrated assessment model with a carbon-price limit estimated from institutions and the economic weight of fossil
and clean-energy interests, a limit applied decade by decade, each decade expecting it to lift, adds about half the CO₂
of the same limit known to last. Each decade's plan under-promises the emissions that follow. Expecting the limit to
lift does more than cutting its severity by a third.

**Design: persistence × expectations** (hold the price, 21 regions, θ 0.50 unless stated):

| persistence ↓ / expectations → | one-shot: known to last | re-planned each decade, known to last (control) | chain: expected to lift after each decade | chain: expected to lift after 20 years |
|---|---|---|---|---|
| constant limit | +123.8 Gt (have) | to run | to run | optional |
| fading limit | +75.1 Gt (have) | to run ("version A") | +39.4 Gt (have) | to run |
| fading + erosion 2.7%/yr | +29.4 Gt (have) | — | to run | — |

The control column separates re-planning from expectation: if it stays near +75.1 Gt, the effect is expectation. The
20-year column gives a dose-response. Further chains: fading at θ 0.325 and 0.675 (for A3), 12 regions, 5-year steps.
Hold the budget carries a timing result that exists (5.8 Gt more emitted in 2030–2060, 5.9 Gt less after; 2100 price
535 vs 500 $/t). **All variants are configuration only** (`COUPLING.md` §14.1): the control leaves `pfmPhiWindowEnd`
open in every step, the 20-year lift sets it to start + 20, persistence uses the strength and κ columns.

**Mechanism to show.** Clean capacity and energy investment in 2030–2050, one-shot against chain, at equal prices
paid. Needs a new extraction script.

**Main risk.** REMIND has perfect foresight within each step, so the effect is as strong as that foresight; say so in
the abstract. The control, the 20-year variant and the step length bound it; a limited-foresight REMIND variant would
be the strongest check, if one exists.

**Format.** *Nature Climate Change* Article, 3,000 words, the format already designed in
`../_archive/_wip/2026-11-23/papers/pfm-model-paper/docs/allocation.md` §3 (findings as subheadings, headline in title, abstract and Fig. 1).
Methods point to the GMD paper for the model.

**Display items.** Fig. 1 the idea (one-shot vs chain) and the headline pair; Fig. 2 the grid as a dot plot with the
θ-equivalence marked; Fig. 3 plans against outcome, step by step; Fig. 4 the investment mechanism. Supplementary:
regions, 12 regions, step length, hold the budget. Option E (lock-in where limits bind) can enter as a section.

## 6. The headline search (14 candidates)

"Built in?" asks whether the answer follows from the required sign or a declared rule.

| # | headline | option | built in? | evidence now (`v8`) | verdict |
|---|---|---|---|---|---|
| A2 | Mitigation pathways that treat political limits as permanent overstate their emissions cost | A | no: investment under expected prices | +75.1 Gt one-shot vs +39.4 Gt chain, same prices paid | **accepted** |
| A1 | Expecting political limits to lift halves their climate cost | A | no | same pair; "halves" needs the grid | sharper, later |
| A3 | Believing political limits will ease does more than easing them by a third | A | no | chain at θ 0.50 (+39.4) below one-shot at θ 0.325 (+44.4) | needs θ chains |
| A4 | Mitigation plans that expect politics to ease under-deliver at every step | A | no | planned 2100 overshoot +7.5, +11.5, +20.8, +24.6 Gt; result +39.4 | second message of A |
| N1 | Political limits explain how unevenly carbon is priced today | N | partly: ordering estimated, fit a test | not run; rank correlation with explicit prices −0.24 to −0.55 | inside P1 |
| B1 | Today's politics already allows much of the effort current policies miss | B | partly: rests on the 2023 distance | not run; needs a declared price mapping | parked |
| C1 | Cutting fossil dependence first makes higher carbon prices feasible later | C | direction yes, size no | offline upper bound only: 2050 strength 0.82 vs 0.62 | parked |
| C2 | Non-price climate policy pays a political dividend for carbon pricing | C | as C1 | not run | parked |
| D1 | Governance indicators put political limits in the wrong places | D | no | rank correlation 0.38–0.39; 1.58–1.97× the CO₂; two runs prepared | reserve |
| E1 | Where political limits bind hardest, they entrench themselves | E | partly | Russia and reforming economies: 0.81 coupled vs 0.58 reference (P&I, 2050) | reserve |
| H1 | Meeting a carbon budget despite political limits moves about 20 Gt of abatement between regions | v5 | partly | 20.6 Gt relocated; 2050 anchor ×1.16 | P1 |
| F1 | How long political limits last is the missing dimension of mitigation scenarios | F | no, but argues rather than finds | persistence ladder +19 to +160 Gt | Perspective only |
| N2 | Today's uneven carbon prices cost more than one price for the same emissions | N | no | not run; mostly a REMIND result | P1 side result |
| — | Political limits on carbon prices can be weaker on ambitious pathways than on current policies | v06 | yes | fully evidenced | dropped as a headline; P1 §6 |

## 7. Option N: a uniform-price run that reproduces the current-policies budget (inside P1)

**The run (N0).** Read the cumulative CO₂ 2020–2100 of REMIND's current-policies run. Run REMIND with budget forcing on
that same budget (end-of-century, since current policies do not reach net zero), keeping the non-price policies of
current policies and replacing only the regional carbon prices. The budget loop returns the uniform price path A_cp
that delivers the same emissions. One run at 21 regions, one at 12.

**What it can tell us, in order of value.**

1. **A revealed severity (P1).** Per region and market, φ_cp = P_cp / A_cp. The PFM says φ = 1 − θ k ρ; regressing
   1 − φ_cp on ρ through the origin gives θ_revealed, and the 184 bootstrap resamples of ρ give it a band. If it
   holds, every coupled size can be quoted at a calibrated θ rather than a declared sweep.
2. **A test of the ordering (N1).** Does the estimated ranking explain how unevenly carbon is priced today? A poor fit
   is still a P1 result: current prices are not ordered by estimated political room.
3. **The cost of uneven prices (N2).** Current policies and N0 emit the same CO₂, so GDP and consumption compare
   fairly (unlike the coupled runs, where REMIND has no damages and abating less looks richer).
4. **Who does more, or less, than their politics predicts.** A coupled hold-the-budget run at the current-policies
   budget, with θ_revealed, against the actual current-policies pathway: over-performers (the EU, $179.5/t in 2050
   under current policies) and regions with headroom. Links N to B.
5. **A staircase of the emissions gap.** Current policies → N0 (same CO₂, lower cost) → at the ceiling (B) → 1000 Gt
   (what needs political change).

**Risks.** The earlier attempt to get θ from observed country prices gave a band containing zero (−0.61 to 0.80, power
and industry; `thetaFromPrices.R`); N may fail the same way. Some current-policy prices exceed A_cp (the EU), and the
US price turns slightly negative from 2030 in REMIND's input (−$6.16, `SCENARIOS.md` §6.1): clip φ_cp to [0, 1] or
exclude. Current-policy prices from 2030 are held input values, so θ_revealed is calibrated to today's legislated
prices.

**Cost.** Two REMIND runs, one offline regression, then two coupled runs for item 4. About a week with staging.

## 8. Parked options (author, 2026-11-23)

### 8.1 Option B: political headroom and the emissions gap

B reads the gap the other way round: not a constraint but **unused room**, stringency that countries with the same
interests and institutions already sustain. Question: how much of the emissions gap could close without any change in
politics?

1. **Where each region stands.** The frontier gives each region's 2023 stringency S and ceiling S*; S* − S is the
   headroom in index points.
2. **Headroom into a price** (the declared step). P_ceil = P_cp + m × (S* − S), with the slope m ($/t per index point)
   from the cross-country relation of explicit prices to the index (World Bank data, as read by `thetaFromPrices.R`);
   sweep m over its band.
3. **Three REMIND runs on one axis.** Current policies (have), at the ceiling (new, one per m), cost-optimal 1000 Gt
   (have).
4. **Split the gap.** CO₂(current policies) − CO₂(at the ceiling) is within today's politics; CO₂(at the ceiling) −
   CO₂(1000 Gt) needs the ceiling itself to move.

Either answer is publishable. It does not use θ or the normalisation on the most limited region; the size depends on
one declared slope with an empirical band. Risks: in power and industry γ = 0.9989, so "room" is largely what the model
does not explain (frame it as "room comparable countries have used"); the index scores all instruments, so mapping it
to a price is crude where countries regulate; only the ends of the order are resolved. **Cheapest first step (a day,
offline):** tabulate S, S* and the headroom by region from the `v8` artifacts and fit m; if at-ceiling prices are
trivially small or absurdly large, B is dead before any run.

### 8.2 Option C: sequencing, cutting fossil dependence first

Does non-price policy now buy political room for carbon prices later? Task 3.4's original question ("linking possible
carbon pricing increases to the existence of low-carbon industries"; Pahle et al. 2018; Meckling).

1. **The lever.** In the frontier the ceiling rises as fossil dependence falls; standards, mandates, phase-outs and
   subsidies cut fossil dependence without a carbon price.
2. **A sequencing scenario.** An early non-price push in the coupled hold-the-price run (e.g. coal-power exit and
   electrification targets 2025–2040); which REMIND switches carry it is to be checked.
3. **Run it coupled** against the same run without the push.
4. **The political dividend.** The extra price the limit allows and the CO₂ it saves beyond the push's direct effect;
   separated by the push with the PFM held at the no-push strength path (`pfmPhiStrengthGdx`, prepared).
5. **Price it.** The push's cost against the dividend's CO₂.

Exists already: an offline upper bound (2050 strength about 0.62 on a decarbonising 1000 Gt energy system against 0.82
on current policies, power and industry; `open-loop-strength.rds`). Limits: the direction is built in (the result is
size and cost-effectiveness); it exists only under the fading limit; it acts only through fossil dependence (the
clean-energy terms are not identified); the average feedback is second order (at most 0.03 in 2050), so the push must
be large. Home: *Nature Energy* or a third paper, framed "if political distances persist in relative terms".

## 9. Reserve options

| option | question | evidence now (`v8`) | needs | best home |
|---|---|---|---|---|
| D governance caps | Do governance indicators limit the same regions as the estimated ceiling? | rank correlation 0.38–0.39 (0.34–0.58 over the 16 mostly estimated regions); a fixed governance cap adds 1.58–1.97× the CO₂ | the two prepared runs at the estimated mean (`V8EXO2EU21`) | short Analysis, or P1 §6 |
| E lock-in | Does a limit entrench itself where it binds most? | Russia and reforming economies: 2050 strength 0.81 coupled vs 0.58 on the reference (P&I); share left 0.53 if computed from current policies vs 0.71 from the reference | the prepared open-loop runs (`V8OPENEU21`) for CO₂ | a section of P2, or P1 §6 |
| F persistence as a scenario axis | Should scenarios carry political persistence like technology assumptions? | ladder +19 to +160 Gt vs θ range +44 to +110; 2008–2023 erosion 2–8%/yr (P&I), 5–16%/yr (B&T) | no runs; an argued piece | NCC Perspective, after P2 |
| G budget floor | Lowest budget reachable with every region at its limit? | none | budget sweep (e.g. 500–1150 Gt), both closures, least-limited regions also capped | only if A fails |

The v5 result (hold the budget moves abatement rather than removing it: 20.6 Gt relocated, anchor ×1.16 in 2050)
stays in P1; it follows persistence (41.1 Gt under the growing limit down to 4.8 Gt with 5% erosion), which supports
A's framing.

## 10. Claims ledger (both papers)

Tiers as in `../_archive/_wip/2026-11-23/papers/pfm-model-paper/docs/claims.md`: established · provisional · directional · ordering-only ·
pending. M-rows map to that ledger's ids; A-, B-, C-, N-rows go into the Nature paper's own ledger (B, C parked).

| id | claim | paper | tier | evidence (`v8`) | status |
|---|---|---|---|---|---|
| M1 | In the selected frontier fossil dependence lowers the ceiling in both sectors (required; encoded, not tested) | P1 | provisional | C1–C4; `frontier.rds`; −0.81 / −0.17 per s.d. | have |
| M2 | Fossil rents widen the distance below the buildings-and-transport ceiling | P1 | provisional | C5; ω = +0.28; better out of sample in 38 of 48 | have |
| M3 | The selection is disclosed: 36,384 candidates, theory gate added after an earlier result, poor split-sample replication | P1 | established | C8–C10; ratio 0.97–1.66 to base rate | have |
| M4 | Only the ends of the regional order are resolved | P1 | ordering-only | C19–C20; most limited in 89% / 69% of resamples (72% before the 2026-11-23 re-evaluation) | have |
| M5 | The two-way loop converges in every coupled run | P1 | established | C37; 73 of 73 | have |
| M6 | Under the fading limit the strength depends on the pathway it is computed from | P1 | directional | C50, C52, C57; 2050: 0.82 / 0.75 vs 0.61–0.64 / 0.62–0.63; positive in 89% / 95% | have |
| M7 | The feedback on its own pathway is second order, except for the most limited region | P1 | established | C51, C58; ≤ 0.03 in 2050; CO₂ needs `V8OPENEU21` | partial |
| M8 | The extra CO₂ scales with declared severity and persistence | P1 | established (declared size) | C28, C31; +44.4 / +75.1 / +109.8 Gt over θ | have |
| M9 | Holding the budget raises the 2050 anchor 1.16-fold and moves 20.6 Gt | P1 | established | C33–C34; `coupled-costs.json` | have |
| M10 | Governance rankings agree only weakly with the estimated one | P1 | ordering-only | C21, C39, C54; 0.38–0.39; separation needs `V8EXO2EU21` | partial |
| M11 | Current-policy prices reveal a severity θ with a band | P1 | pending | Option N | to run |
| M12 | Today's uneven prices cost more than one price for the same CO₂ | P1 | pending | Option N | to run |
| M13 | The PFM's interface is model-independent: it reads regional energy-system quantities and returns a share by region, period and market for any regional set | P1 | established for REMIND; a design statement for other models | two REMIND resolutions (21, 12 regions); another IAM only through D18 | partial |
| A1 | A limit expected to lift after each decade adds about half the CO₂ of the same limit known to last, at the same limit and prices | P2 | established (model result) | C43 (pending by decision, D4); +39.4 vs +75.1 Gt; φ ±0.005; 193 vs 191 $/t | author decision |
| A2 | Every decade's plan under-promises the emissions that follow | P2 | established | +7.5, +11.5, +20.8, +24.6 → +39.4 Gt | author decision |
| A3 | Expecting the limit to lift does more than cutting its severity by a third | P2 | provisional (one pair) | chain θ 0.50 +39.4 vs one-shot θ 0.325 +44.4 | partial |
| A4 | The effect is expectation, not re-planning | P2 | pending | control chain | to run |
| A5 | The effect holds under the constant limit and with erosion | P2 | pending | two chains | to run |
| A6 | Holding the budget, expectations move effort later and raise late prices | P2 | established | 5.8 / 5.9 Gt; 535 vs 500 $/t in 2100 | have |
| A7 | The mechanism is earlier clean investment at equal prices | P2 | pending | new extraction | to run |
| A8 | Robust to 12 regions and 5-year steps | P2 | pending | two chains | to run |
| A9 | The effect is as strong as REMIND's within-step foresight (limitation) | P2 | established | `MODEL.md` §5.6a | have |
| A10 | Where limits bind hardest they entrench themselves | P2 | directional | C58; 0.81 vs 0.58; CO₂ needs `V8OPENEU21` | partial |
| B1 | A stated share of the emissions gap lies within today's ceilings | parked | pending | Option B | parked |
| C1 | A non-price push buys carbon-price room under the fading limit | parked | pending | Option C | parked |
| N1 | The estimated ranking explains how unevenly carbon is priced today | P1 | pending | Option N regression | to run |

## 11. Figures

**P1, the model paper.**

| fig. | shows | exists as | work |
|---|---|---|---|
| 1 | the price gap today vs a 1000 Gt pathway; how IAMs treat feasibility | v06 Fig. 1a–b (`../_archive/_wip/2026-11-23/papers/pfm-model-paper/paper-figures/R/fig1.R`) | drop panels c–d |
| 2 | the PFM schematic (ceiling, gap, price share, loop) | v06 Fig. 1a | redraw as its own figure |
| 3 | from the ceiling to a price limit; the regional order and each region's price | v06 Fig. 3 | none |
| 4 | strength over time, fading vs constant, by driver group | v06 Fig. 4 | none |
| 5 | net effects of each group of terms | v06 Fig. 2 | none |
| 6 | pathway contrast and feedback | v06 Fig. 1c–d | re-panel |
| 7 | extra CO₂ by severity and persistence; hold-the-budget price and relocation; governance | v06 Figs. 5–6 | add the rescaled governance runs |
| 8 | revealed severity: φ_cp against ρ with fitted θ and band | none | Option N |
| app. | convergence, selection landscape, theory-gate funnel, worked example | `analysis/figures/R/fig-coupled-convergence.R`, `fig-selection-landscape.R`; `analysis/v8/theoryGateFunnel.R` | rebuild on `v8` where still on v6/v7 |

**P2, the Nature paper.**

| fig. | shows | exists as | work |
|---|---|---|---|
| 1 | the idea (one-shot vs chain) and the headline pair +75.1 vs +39.4 Gt | `analysis/figures/output/v8/chain-schematic.png`, `doc/fig-shrinking-future-chain.png` | redraw in journal style |
| 2 | the grid: extra CO₂ by persistence × expectations, one-shot θ results as reference | partly `v6-coupled-arms.png`, `v6-coupled-theta.png` | new script after the chains |
| 3 | plans against outcome; prices paid nearly equal | `output/pfm/v8/coupling/fig-shrinking-future-plans.png`, `fig-shrinking-future-price-plans.png` | restyle |
| 4 | mechanism: clean capacity and investment 2030–2050 | none | new extraction + script |
| SI | regions; hold the budget timing; 12 regions; step length | `fig-shrinking-future-regional-co2-box.png`, `fig-shrinking-future-regional-prices-budget.png` | restyle; new chains |

**Parked options.** B and N share the staircase figure (uneven prices → one price at equal CO₂ → at the ceiling →
cost-optimal); C needs a strength-and-price panel with and without the push. None exist.

## 12. What exists and what still needs doing

**Already in the results (`v8`).** 79 REMIND runs, 73 coupled and all converged: the severity sweep, the persistence
ladder (growing, constant, fading, four erosion cases), the institution rules, the robustness and governance-cap runs,
the shrinking-future chain in both closures. Offline: the 184-resample country bootstrap, three quantile frontiers,
the fossil-bound refits, the pathway contrast and feedback (`open-loop-strength.rds`), the split-sample replication,
the index-maximum test.

| # | item | for | type | cost | status |
|---|---|---|---|---|---|
| 0 | Commit and push the open-loop option (`models/pfm` `7fca356`, `models/remind_pfm` `a4db0bac7`) | item 2 | code | — | **done** 2026-11-23 |
| 1 | Release claim C43 (the chain) | A | decision | — | decided (D4: yes) |
| 2 | Open-loop runs (`V8OPENEU21`, 3) | M7, A10 | cluster | — | **done** 2026-11-24, all converged (`scenario-set-price.rds`, `-budget.rds`): hold the price, limit once on the reference pathway +74.16 Gt (coupled +75.13), once on current policies +98.14; hold the budget, current-policies limit: price ratio 2050 0.948 (coupled 0.972) |
| 3 | Governance ranking at the estimated mean (`V8EXO2EU21`, 2) | M10, D | cluster | `exogenousCap.R v8 stage` on the cluster first | **done** 2026-11-24, both converged: fixed +128.57 Gt, fading +83.47 (`scenario-set-price.rds`) |
| 4 | Expectation chains: the control (`V8EXPEU21`, 5 rows, `holdPrice-replanned<year>`); constant, erosion 2.7%, 20-year lift, θ 0.325 and 0.675, 5-year steps (`V8EXP2EU21`, 33 rows, `holdPrice-<variant>-chain<year>`); 12 regions (`V8EXPH12`, 5) | C3–C5, C8 of the NCC ledger | cluster | configuration only | **done** 2026-11-26, every step converged; five-year steps +31.12 Gt against one-shot +75.13 (0.414), θ 0.675 +57.44 against +109.84 (0.523); NCC ledger C1, C3–C5, C8 updated (`papers/pfm-ncc` 5acda05). Earlier (2026-11-25, `expectations-grid.rds`, v8, EU21, extra cumulative CO2 2020–2100 against the no-politics hold-the-price reference): chain +39.41 Gt against one-shot +75.13 (0.525); **G1 passes (expectation)**: the control +73.55, 1.6 Gt from the one-shot and 34.1 from the chain; constant limit +65.90 against +123.84 (0.532); erosion 2.7% +12.23 against +29.39 (0.416); 20-year lift +62.32 (0.830); θ 0.325 +24.02 against +44.38 (0.541); 12 regions +34.45 against +64.33 (0.536). θ 0.675 2070 was restarted 2026-11-25 after its hand-over failed (PITFALLS §41) |
| 5 | Mechanism extraction, one-shot vs chain (`analysis/v8/expectationsMechanism.R`) | A7 (NCC C7) | offline script | — | **done** 2026-11-23: +236 GW wind and solar in 2040, +232 GW in 2050, −140 GW unabated fossil in 2050; NCC C7 supported |
| 6 | Option N0 test, `SSP2-EU21-NPi2025-uniformPrice` (`V8NPIBUDEU21`, 1, uncoupled; budget 2981 Gt; the linear price path starts from 14.3 $/t, the emissions-weighted mean current-policy price in 2025, not REMIND's default maximum 71.9, which aborts) | M11, M12, N1 | cluster | — | **done** 2026-11-24 (`theta-revealed.rds`): 2978.2 Gt against 2981.4 (REMIND flags it not converged at 100 iterations: the 2 Gt budget tolerance; markets clear); A_cp 13.8 $/t in 2030 falling to 12.0 in 2050 (the linear shape through the 2025 anchor); 13 of 21 regions price above A_cp (φ_cp = 1); N1 Spearman 0.07–0.36; revealed θ through the origin 0.87–1.05 (bands exclude 0, by construction near-certain), slope 0.56–0.91 (excludes 0 for the diffuse sector only); M12 consumption +0.048%, GDP +0.022% (N0 over current policies). D7 to the author |
| 6a | Emissions band (GP-12): `pfm` `80f5423`, bootstrap re-evaluated, `v8-bandLow` / `v8-bandHigh` staged (mean constraint 2050 0.1138 / 0.2221, central 0.1333); rows `V8BANDEU21` (2) | M8 (C42) | cluster | copy the two groups up first (`docs/RUNNING.md`) | **done** 2026-11-24: low edge +63.15 Gt (converged), high edge +146.81 (100 iterations, the PFM fixed point cycling at δ ≈ 0.004 against 0.002; cumulative CO2 1149–1152 over the last 40 iterations); central +75.13 (`scenario-set-price.rds`) |
| 6b | Offline demonstration on another IAM | — | — | — | future work (D18) |
| 7 | Revealed-severity regression with bootstrap band | M11, N1 | offline script | a day after N0 | to run |
| 8 | Coupled hold the budget at the current-policies budget, revealed θ | N item 4 | cluster, 2 runs | after 7 | to run |
| 9 | Headroom table and price slope m | B1 | offline | a day | parked |
| 10 | Sequencing scenario, 2–3 coupled runs | C1 | design + cluster | a week | parked |
| 11 | Restructure v06 into the two-layer GMD paper; deposits (GP-16) | P1 | writing | 1–2 weeks | partial |
| 12 | Abatement-cost refit (`analysis/v8/abatementCost.R`): restarted from the base estimates (log-likelihood −1215.6 > base −1232.1, γ 1.000); fossil dependence −0.92 (base −0.81); 2050 contrast 0.174 (0.207) P&I, 0.125 (0.130) B&T | GMD (Appendix F) | offline | — | **done** 2026-11-23 |

**The emissions band was blocked (found 2026-11-23 while staging it) and unblocked the same day** (`pfm` `80f5423`;
the bootstrap re-evaluated with a guard and provenance, `frontierBlockBootstrap.R`; old results kept as `*-pre20261123.rds`). The
re-evaluation reproduced the test below: no NaN in 184 resamples, load 0.114 / 0.159 / 0.222, strength bands unchanged to 0.001;
REF most limited in 89% (P&I, unchanged) and 69% (B&T, 72% before) of resamples. The diagnosis, as found:

*Issue 1, NaN shares.* Under the regional strength the share is φ = 1 − θ·k_r·u with k_r = g(t)/g(2025)
(`models/pfm/R/pfmCouplingV6.R` l. 198). When a region's 2025 gap is exactly zero (its countries at or above their
re-estimated ceiling), k_r is 0/0 and φ is NaN. Re-evaluating all 184 resamples: 124 have at least one NaN share in 2050;
236 of the 237 NaN rows are the least limited region (u = 0, where φ should simply be 1), most often NES (power and
industry, 40), NEN and CHA (buildings and transport). The bootstrap took quantiles with `na.rm`, so the 2050 load
distribution and the band's edges rest on the 60–61 resamples without a NaN, and each region's share band drops the
resamples in which it was least limited. The aggregate strength k and the rankings u are not affected (no division by a
regional gap). The coupled runs are not affected: the coupled anchor's smallest 2025 gap is 0.131 (P&I) and 0.073 (B&T).
With φ = 1 − θ·u where the 2025 gap is zero (k_r = 1; φ = 1 for u = 0): no NaN in 184 resamples; the 2050 load is
0.114 / 0.159 / 0.222 (5 / 50 / 95%) against a central 0.133, so the edges move from 0.105 / 0.189 to 0.114 / 0.222
and the band is asymmetric; the median share-band width moves 0.236 → 0.245 (P&I) and 0.224 → 0.227 (B&T), 5.0 and 3.6
times the ML band (4.8 and 3.5 before); REF's P&I band widens most (0.367 → 0.469).

*Issue 2, the bootstrap's centre.* Its central ranking (2026-11-15) differs from the coupled anchor (the group's
export, which today's code reproduces exactly) by up to 0.064 in u (NES, P&I); the order is unchanged (rank
correlation 1.000 / 0.996), the ends are the same regions (REF most, NEN least limited), and the median shift is 1.8% of
the band width. Not reproducible from anything committed: no `pfm` commit between 2026-11-01 and 2026-11-23, no
`config.yml` change, the madrat cache files unchanged since 2026-10-28, the loader uses the source tree, and recomputing
the anchor under other weights does not reproduce it. Most likely an uncommitted working state at the time, since
reverted.

*Recommended* (author to decide): (1) in `pfmV6Shares`, set k_r = 1 where the 2025 gap is zero, with a count in the
log and a test; it changes no coupled run. (2) Re-run the bootstrap's evaluation (the refits are cached), which also
re-centres it on the export, and add a guard that stops if its central u differs from the export's and records the
`pfm` commit and whether the tree was clean. (3) Re-select the edges and stage them (`emissionsBand.R`), then submit
`V8BANDEU21`. (4) Re-read every bootstrap number the papers quote (share bands, rank intervals, the shares at the ends).

## 13. Decisions

All answered by the author on 2026-11-23; D13–D18 came out of checking the plan against D1–D12. Not needed now, at submission: authorship, funding and ELEVATE acknowledgement,
cover letters, suggested reviewers.

| # | decision | answer or recommendation | state |
|---|---|---|---|
| D1 | which workspace holds which paper | (a): `../_archive/_wip/2026-11-23/papers/pfm-model-paper` becomes the GMD paper; the Nature paper gets a new workspace from paper-forge | decided |
| D2 | journal for the Nature paper | *Nature Climate Change*, the journal of Bertram et al. (2024), Bi, Bauer & Jewell (2023) and Muttitt et al. (2023) | decided |
| D3 | order of submission | GMD first or the same day, so the Nature submission carries the GMD preprint DOI | decided |
| D4 | release claim C43 (the decade chain) | yes | decided |
| D5 | how much of the grid | run all 8 chains, but include in the paper only what makes it clearer ("less is usually better"); the inclusion rule is D14 | decided |
| D6 | the headline if the control chain also halves the overshoot | as recommended: A2 holds if the control stays nearer the one-shot result than the chain; otherwise *Mitigation pathways planned once overstate the emissions cost of political limits* | decided |
| D7 | severity for coupled sizes | declared for now; if Option N runs and gives a band excluding zero, reconsider. **Reconsidered 2026-11-24 (author): θ 0.50 stays central.** N0 gives 0.87–1.05 through the origin (bands exclude 0 near-certainly by construction) and 0.56–0.91 as a slope (bands from −0.57 for power and industry): the revealed range is reported as a bound on top of the declared sweep, from two runs at θ 0.60 and 0.90 (`V8THREVEU21`), never as the central value | decided The bound (2026-11-25, `scenario-set-price.rds`, v8, EU21, hold the price, `V8THREVEU21`): θ 0.60 +95.06 Gt (converged, 53 iterations; GDP +0.144%, consumption +0.155% against the no-politics reference, discounted) and θ 0.90 +157.08 (not converged: 100 iterations, only the PFM criterion failing, δ 0.0038 against 0.002; cumulative CO2 1160.7–1165.2 Gt over the last 40 iterations; GDP +0.232%, consumption +0.230%), beside the declared 0.325 / 0.50 / 0.675: +44.38 / +75.13 / +109.84. Restarted from its own final state (`V8WARMEU21`, 2026-11-26, GMD GP-53) θ 0.90 converges at +160.62 Gt (44 iterations; GDP +0.224%, consumption +0.231%); the emissions band's high edge at +145.71 (28 iterations), against +146.81 cycling. With PFM calls every 6 iterations the band converges (+146.63) and θ 0.90 does not (+156.90). |
| D8 | where N lives | the model paper (§6, Appendix J) | decided |
| D9 | model name and version in the GMD title | a release tag "PFM v1.0" on the existing commits; no package version changed | decided |
| D10 | Run-Group | `v8` for both papers | decided |
| D11 | the six explainer videos | later: revise them after the papers are written, then submit with the GMD paper if ready | decided (deferred) |
| D12 | evidence the GMD paper needs | run both required and optional: `V8OPENEU21` (3), `V8EXO2EU21` (2), the abatement-cost refit, the deposits (GP-16), and the emissions band (GP-12, 2 runs plus a staging step) | decided |
| D13 | run Option N as a test? | **yes** (author): one uncoupled test run at 21 regions, `SSP2-EU21-NPi2025-uniformPrice` (start tag `V8NPIBUDEU21`): current policies with one uniform price from 2030 at their own cumulative CO₂ 2020–2100, 2981.4 Gt (`pm_actualbudgetco2`, read 2026-11-23); REMIND's uniform end-of-century budget recipe (`cm_iterative_target_adj` 5, `cm_taxCO2_regiDiff` 0, interpolation off, `cm_peakBudgYr` 2100); the open point is whether the budget loop converges | decided |
| D14 | what enters the Nature paper (from D5) | as recommended, to revisit after the batch: **main text** one-shot vs chain vs control (G1), the constant-limit chain, the θ-equivalence pair, the mechanism; **Supplementary** erosion chain, 20-year lift, θ 0.675, 12 regions, 5-year steps | decided |
| D15 | name of the Nature workspace | `papers/pfm-ncc` (author) | decided |
| D16 | the model paper's workspace | a **new** workspace `papers/pfm-gmd`, built from `../_archive/_wip/2026-11-23/papers/pfm-model-paper`'s history (ledger, gap plan, runbook, literature, bundle, figure scripts carried; v06 and its design quarantined in `drafts/`); its first version is **v01**; `../_archive/_wip/2026-11-23/papers/pfm-model-paper` frozen as a quarry (author) | decided |
| D17 | GMD support in paper-forge | **done**: `profiles/gmd.yml` and `skills/paper-design/REFERENCE-gmd.md` (paper-forge `fb3b581`) | decided |
| D18 | show the PFM with another IAM | **not now** (author): stated as future work in the GMD paper | decided |

## 14. Build plan, step by step

Both papers share one cluster batch, then go their own ways; three gates decide what the Nature paper may say.

```
               1 Set up          2 Offline          3 Batch            4 Gates                5 Draft, submit
Model paper    push code,      → two layers,     ─┐                  ┌→ G2 θ band excl. 0? → draft first, GMD (preprint DOI)
(GMD)          retarget GMD      appendices A–M,   │  one batch:      │                                 │ cited by
               D16, D17          IAMC demo         ├→ open-loop 3,  ──┤                                 ▼
Nature paper   new workspace  →  ledger A1–A10,    │  governance 2,   └→ G1 control ≈ one-shot? → draft, G3 desk check, NCC
(NCC)          D6, D14 rules     mechanism        ─┘  N0 test 1,
                                                      chains 8, band 2
                                                      (PITFALLS first)
```

Steps 1–3 are the next steps and need no cluster time.

1. **Secure the code (first).** Commit and push the open-loop option, which exists only as uncommitted changes in
   `models/pfm` and `models/remind_pfm` (§12 item 0), with no package version change; then the workspace
   (`analysis/run-groups/scenario-matrix-v8.yml`, the modified and untracked `analysis/v8` scripts).
2. **Set up the two papers.** In paper-forge, add `profiles/gmd.yml` (D17). Retarget `../_archive/_wip/2026-11-23/papers/pfm-model-paper`:
   `paper.yml` (journal GMD, kind model, a descriptive claim with the generic framing) and its `CLAUDE.md`; the next
   draft is v07 (D16). Create the Nature workspace:
   `Rscript papers/paper-forge/bin/new-paper.R papers/pfm-expectations --slug pfm-expectations --journal nature-climate-change`
   (D15), with the A2 title as its claim and the D6 and D14 rules in its docs.
3. **Prepare the batch and the offline work (no cluster).** Add to `scenario-matrix-v8.yml` the 8 expectation chains
   (configuration only), the N0 test row (D13) and the emissions-band rows; write the band staging step (§12 item 6a).
   Offline in parallel: the abatement-cost refit; the mechanism extraction; the IAMC reader and the D18 demonstration;
   the interface specification for Appendix M and `COUPLING.md`; `allocation.md` rewritten for the two layers.
4. **One cluster batch.** Re-read `docs/PITFALLS.md` §1–§3, install `pfm` and `remind_pfm` on the cluster, check the
   cache. Run together: `V8OPENEU21` (3), `V8EXO2EU21` (2), the 8 chains (about 40 sequential runs), N0 (1), the band (2).
5. **Read the batch through the gates.** **G1** (D6): control chain vs chain decides the headline. **G2** (D7): only if
   N0 converged, the revealed-severity regression; then the two follow-up runs of Option N item 4. Update both ledgers;
   build the grid, plans-vs-outcome and P1 Fig. 8; apply D14 to decide what the Nature paper shows.
6. **Draft.** In each workspace: `paper-claims` → `paper-design` → `paper-data` → `paper-figures` → `/paper-loop`; P1
   first (D3). **G3**, before P2 leaves: its title, the first two sentences of the abstract and Fig. 1 state a finding
   that the selection rules do not decide.
7. **Deposit and submit.** Tag "PFM v1.0" on the three repositories (D9); deposit code, evidence bundle and, once
   revised, the videos (D11) with DOIs (GP-16); submit to GMD; submit the Nature paper with the GMD preprint DOI.

## Sources

- GMD manuscript types: https://www.geoscientific-model-development.net/about/manuscript_types.html (read 2026-11-23)
- GMD review criteria: https://www.geoscientific-model-development.net/peer_review/review_criteria.html (read 2026-11-23)
