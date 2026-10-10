# The Political Feasibility Model, explained

*A plain-language walkthrough for readers who do not run the code — colleagues, WP partners,
reviewers. Eleven steps, a handful of equations. Derivations, caveats and fitted values are in
`MODEL.md`; the REMIND interface is in `COUPLING.md`; the results in full are in `SCENARIOS.md`.
Numbers here are from Run-Group `v6`.*

📊 **Charts.** Everything is built by `analysis/figures/build-figures.R` from the registry in
`analysis/figures/R/registry.R`, and rendered into `analysis/figures/output/all/` (one PNG per figure, always) and
`analysis/figures/output/paper2/` (the paper's PDFs). Slides and poster renders are opt-in
(`--media=slide,poster`). **`analysis/figures/output/all/index.html` shows every figure on one page.**
`analysis/figures/output/FIGURE-GUIDE.md` is generated from the same registry and explains, for every
figure, what it shows, what to read off it and what must not be claimed from it — start there.

```bash
Rscript analysis/figures/build-figures.R --group=v6                 # everything, every medium
Rscript analysis/figures/build-figures.R --group=v6 --only=<id>     # one figure
```

> Step 11 reports the coupled REMIND runs for the current model (64 runs, October 2026).

---

## The question

Integrated assessment models like REMIND answer *"what is the cheapest way to meet a carbon
budget?"* They assume every region can adopt whatever carbon price the optimisation asks for.

Politics says otherwise. Countries with similar economies adopt very different climate policy.

**This model asks a different question: what is a region politically able to do, and what
happens to the mitigation pathway once you take that seriously?**

---

## Step 1 — Measure what countries actually do

The OECD's Climate Actions and Policies Measurement Framework (CAPMF) scores national climate
policy stringency on a **0–10** index. We use two sector groups, because the politics differ:

- **Bulk** — electricity and industry. Few, large, organised actors.
- **Diffuse** — buildings and transport. Costs land on households directly.

Call this observed stringency $S$. It exists for **48 countries**, 2001–2023; the model must
eventually speak for **248**.

## Step 2 — Explain it with drivers

$$\operatorname{logit}\!\left(\frac{S}{10}\right) = \beta'x + \varepsilon$$

The logit is there because $S$ is bounded at 0 and 10 — without it the model would happily
predict a stringency of 14.

| group | in the model | idea |
|---|---|---|
| **actor power** | clean-energy (innovator) share; fossil incumbent share; fossil incumbency per person | who wins the fight, and how big the losers are |
| **institutional quality** | government effectiveness; rule of law; vertical accountability (can voters hold rulers to account) | can the state deliver, are its rules kept, and does it have to answer for it |
| **how they combine** | each actor-power term multiplied by each institution | the same lobby matters differently in different states |
| **controls** | income, population, clean baseload (hydro, nuclear, geothermal), a common time trend | structure |

Incumbency enters **twice** on purpose. The *share* of fossil fuels in the energy system measures
dependence; incumbency *per person* measures how large the fossil interest is. They pull in
different directions — dependence goes with less stringent policy, scale in power and industry
with more — and carrying both lets the model tell them apart.

The actor-power terms **saturate**: each enters as $x/(x+\text{median})$, so a share far outside
anything observed cannot push the prediction along a straight line. That matters when REMIND's
deep decarbonisation takes fossil shares to near zero.

## Step 3 — Ask what a country *could* do

The central move. Instead of one line through the data, we fit a **frontier**: the best
stringency achieved by countries with comparable drivers. Real countries sit *below* it.

$$\varepsilon = v - u, \qquad u \ge 0$$

$v$ is ordinary symmetric noise; $u$ is the **shortfall**, one-sided by construction — the
distance between what a country's drivers permit and what it actually did. Call the frontier
$S^{*}$.

What sets the frontier: **state capability** is the clearest institutional channel in buildings
and transport; in power and industry the institution terms are **not identified** (they are
insignificant on average and flip sign at the frontier). Most of the institutional signal runs
through how institutions combine with incumbency. A common upward time trend does a large share of
the work, which is why the model is used to *rank* countries, not to explain how policy rose.

## Step 4 — Define the gap

$$E = \frac{S}{S^{*}} \in (0,1]$$

$E$ is the share of its own potential a country has realised. **The gap is $1-E$** — always
relative to that country's own frontier, never an absolute number of index points.

> **Why relative matters.** A weak-institution country has a low ceiling, so its absolute gap
> is small. Ranking on absolute gaps rewards that — it reads "little left to do" where it
> should read "little capacity".

In 2023 the median country realises about **74%** (Bulk) and **78%** (Diffuse) of its own ceiling.
Bulk is the more constrained sector in 32 of the 48 countries.

**Which country sits where is less certain than that.** Re-estimating the frontier with different,
equally defensible assumptions about the shortfall reshuffles the country ranking considerably.
So we report groups and ranges, never a named league table.

## Step 5 — Read the gap once, and hold it

Each country's distance below its ceiling is read **once, in 2023**, the last year with data, and
then **held**: as the scenario changes the country's drivers, its ceiling moves, and the country
stays the same distance below it (measured on the logit scale).

**Why not let gaps close at a historical speed?** The previous version did, at an estimated speed of
about 0.1 a year. But that speed does not forecast better than "assume nothing changes", and the
same estimator returns speeds of that size on artificial data in which *nothing* ever closes. So it
cannot show that politics catches up. **The model now assumes the gap persists**, and asks the
question the other way round as one declared assumption (κ, Step 7): *what if politics improves by
itself?*

## Step 6 — Cover the countries the data never saw

CAPMF covers 48 countries; REMIND needs all of them. Giving uncovered regions *no constraint at
all* would reward missing data with **maximum assumed political capability**.

Every country instead gets $E$ from one of three explicit branches:

| branch | gets | when |
|---|---|---|
| **donor** | blend of the most similar covered countries | a genuine match exists |
| **low band** | 25th percentile of observed $E$ | below anything observed — extrapolating downward |
| **median** | median observed $E$ | unusual, but not weak — no evidence either way |

Similarity is measured in the model's own terms. Each country keeps **its own** ceiling and
borrows only the gap. Every number carries its provenance. **Most uncovered countries are placed by
a rule, not a donor** — 150 of 200 in power and industry, 167 in buildings and transport — and the
choice of rule is the widest data-side uncertainty in the results (Step 11).

The residual is **concentrated**: the United States has no policy data at all, which is why the
single documented override for the USA carries so much weight — and why its result is reported as
a range, not a point.

## Step 7 — Turn the gap into one number per region, per sector, per year

Countries aggregate to REMIND regions, weighted by **final energy**. Three quantities follow:

- **The ranking $u$.** Where each region sits among all regions in 2023, from the one closest to
  its frontier (0) to the furthest (1). Read once, separately for each sector, and **fixed**.
- **The strength $k(t)$.** How large the political shortfall is overall, relative to 2025 ($k = 1$
  in 2025). It moves every period, because the ceilings move with REMIND's energy system, income and
  institutions. On the 1000 Gt pathway the power-and-industry strength falls to about 0.6–0.7 by
  2050: the energy transition itself relaxes the political constraint.
- **The feasibility share**:

$$\varphi_{r,s}(t) = 1 - \theta\,k_s(t)\,u_{r,s}$$

So $\varphi = 1$ means no political discount, and in 2025 the most constrained region in a sector
sits at $1-\theta$; later, as $k$ falls, every region moves the same fraction towards 1.

$\theta$ is the **severity dial** — a choice, not an estimate — so it is swept: **0.325, 0.50 and
0.675**. There is no historical experiment that would let us estimate it. **$\theta = 0$ switches the
whole thing off**, which is how we test the machinery is wired correctly.

**κ, the declared erosion** — one sensitivity, not the headline: the strength also shrinks by κ a
year, whatever the drivers do — "politics improves by itself". Declared at **0.027** (the drag halves
by mid-century), with 0.02 and 0.05, before any run that uses it.

## Step 8 — Connect it to REMIND

The share caps how far each region's carbon price can rise above its current policy:

$$P = \min\big(A,\ P^{\text{ref}} + \varphi\,(A - P^{\text{ref}})\big)$$

with $A$ the cost-optimal global price and $P^{\text{ref}}$ today's policy. What REMIND may do in
response is the experiment, run two ways:

**Hold the price (rule B).** The global price stays on the path that meets the budget without
politics; the cap binds; emissions are what they are. *Says:* how much carbon budget does political
feasibility cost?

**Hold the budget (rule C).** The budget must still be met; REMIND raises the global price until it
is. *Says:* who pays more, who pays less, and where does abatement move?

A third mode from the previous version, which *generated* the price from political momentum, is
retired: its mechanism was the speed of Step 5.

REMIND prices two markets — electricity-and-industry, and everything else — so each market
carries its own sector's feasibility on top of a shared floor, rather than both collapsing to the
more constrained one.

## Step 9 — The loop

```
REMIND solves  →  new energy system
      ↓
drivers change (fossil share, electrification …)
      ↓
PFM recomputes ceilings, the strength k(t), and φ(t) for every period
      ↓
carbon price updates
      ↓
REMIND solves again …
```

A **fixed point**: converged when another PFM call stops changing the share path, measured as the
largest change anywhere over 2035, 2050, 2070 and 2100. A *maximum*, not an average — one region
still moving keeps the loop open. In the batch it took 2 to 15 calls.

Three failure modes are watched explicitly, because the dangerous one is silent: a runaway carbon
price makes the model *succeed* while producing nonsense.

## Step 10 — The scenarios

| run | what it answers |
|---|---|
| **reference** | uncoupled — the plain baselines (current policies, the 1000 Gt budget) |
| **gate** (θ = 0) | is the machinery wired correctly? Must match a uniform-price reference |
| **hold the price** (rule B) | how much carbon budget does political feasibility cost? |
| **hold the budget** (rule C) | where does the price and the abatement move? |
| **θ = 0.325 / 0.675** | how much of the answer is the severity dial? |
| **institutions held** | how much rests on projected institutions? |
| **κ = 0.02 / 0.027 / 0.05** | what if politics improves by itself? |
| **ranking tests** | uniform, shuffled, reversed rankings: is it *who* is constrained, or only *how much*? |
| **uncovered countries** | other rules for the countries without data, the USA among them |
| **specification** | the other family of saturation, the curve's shape, annual data |
| **one price per region** | what is lost if the two markets cannot be priced separately? |

**Always compare against the θ = 0 gate, not the plain reference**: switching the machinery on also
changes REMIND settings whose effect can be larger than the politics.

## Step 11 — What the runs say

The full set ran in October 2026 — 64 runs at two different ways of carving the world into
regions (21 and 12), so that anything resolution-specific shows up as a disagreement.

**The first finding is the cost.** Holding the price, respecting what politics permits adds about
**115 billion tonnes of CO₂** by 2100 (118 at the finer regional detail, 113 at the coarser) to the
pathway that meets a 1000 Gt budget. The severity dial moves it between **70 and 180**. Pricing the
two markets separately buys back about 40 of it.

**The second is how much it depends on politics improving by itself.** If the political drag
erodes by itself at the declared central rate, two thirds of that cost goes (41 left). That
assumption matters more than anything else we tested. The next largest is how the countries without
data are placed: 110 to 155.

**The third is what happens when the budget is held.** It holds in every run — the model raises
the global carbon price by about a quarter, and moves about **20 billion tonnes of CO₂-equivalent**
of abatement between regions: China abates more, India, the Middle East and Russia less. That is far
less than the previous version found (about 80), and almost all of the difference is after 2050:
the constrained regions' prices catch up with the unconstrained run's by about 2070, as the strength
fades.

**The fourth is that politics responds.** As REMIND changes the energy system, the strength moves —
power-and-industry falls to about 0.69 by 2050 in the coupled runs — and the model and the political
layer settle together over several rounds. It is not a causal claim.

**The fifth is how it compares with the previous version.** The cost is a quarter to a third
smaller. Most of that comes from dropping the historical speed of Step 5, which could not be shown
to be real — a modelling decision, not new evidence that politics is easier.

---

## What this can and cannot say

**It can:** place regions in groups by how far they sit below their own political potential; show
what a cost-optimal pathway implies for regions that have never sustained anything like the
required price; measure what an optimising model does when it must respect that.

**It cannot:** predict elections, treat the gap as a physical constraint, claim the frontier is a
hard limit, or say that institutions *cause* the ceiling. It is a *statistical* frontier — the best
observed among comparable countries, not a law.

**Eight honest limitations:**

1. **Coverage.** 48 of 248 countries are observed. The rest are placed by explicit, disclosed
   rules — better than assuming no constraint, but still assumption, and the widest data-side band.
2. **Two dials are choices.** The severity θ and the erosion κ are declared, not estimated. Any
   result that only exists at one setting is a result about the setting.
3. **The power-and-industry institutions are not identified**, and part of how that sector's
   strength moves rests on them. Every headline run has a twin with institutions held, and the
   headline barely moves.
4. **The specification is not unique.** Across resampled data, state capability and rule of law are
   in the winning model almost every time, and incumbency-in-two-forms in most; but the exact
   deployed model wins about one draw in seven among the admissible ones, and two families of
   saturation split the wins evenly. We report the other family and the curve's shape alongside.
5. **Some regions are pinned by the dial, not by their data.** The construction guarantees that
   *somebody* sits at the bottom of each sector's scale — under the deployed specification China in
   buildings and transport and India in power and industry; under the alternative family, Russia. Their number says "ranked last", not "can only manage half".
6. **The gap is held, not forecast.** We do not know how fast political gaps close; we assume they
   persist and report κ as the alternative.
7. **The feasibility share depends on modelling choices, not only on the region.** Other
   assumptions about how countries fall short of their frontier, and the other saturation family,
   move it. It is a property of a region *given a model*, reported as a band.
8. **Which world the runs are in.** Whether existing legislated carbon prices can be rolled back is
   a model switch. Every run is configured to allow it — the less conservative of the two choices —
   and the paper must say so in one sentence.
