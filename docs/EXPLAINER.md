# The Political Feasibility Model, explained

*A plain-language walkthrough for readers who do not run the code — colleagues, WP partners,
reviewers. Twelve steps, a handful of equations. Derivations, caveats and fitted values are in
`MODEL.md`; the REMIND interface is in `COUPLING.md`; the results in full are in `SCENARIOS.md`.
Numbers here are from Run-Group `v8` (the `v6` version of this page is `../_archive/_wip/2026-10-31/docs/EXPLAINER-v6.md`).*

📊 **Charts.** Everything is built by `analysis/figures/build-figures.R` from the registry in
`analysis/figures/R/registry.R`, and rendered into `analysis/figures/output/<group>/all/` (one PNG per figure, always) and
`analysis/figures/output/<group>/paper2/` (the paper's PDFs), one folder per Run-Group. Slides and poster renders are opt-in
(`--media=slide,poster`). **`analysis/figures/output/<group>/all/index.html` shows every figure on one page.**
`analysis/figures/output/<group>/FIGURE-GUIDE.md` is generated from the same registry and explains, for every
figure, what it shows, what to read off it and what must not be claimed from it — start there.

```bash
Rscript analysis/figures/build-figures.R --group=v8                 # everything, every medium
Rscript analysis/figures/build-figures.R --group=v8 --only=<id>     # one figure
```

> Step 11 reports the coupled REMIND runs for the current model (66 runs, October 2026); Step 12 the sequential
> "shrinking future" runs.

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

- **Power & industry** — electricity and industry. Few, large, organised actors.
- **Buildings & transport** — buildings and transport. Costs land on households directly.

Call this observed stringency $S$. It exists for **48 countries**, 2001–2023; the model must
eventually speak for **248**.

## Step 2 — Explain it with drivers

$$\operatorname{logit}\!\left(\frac{S}{10}\right) = \beta'x + \varepsilon$$

The logit is there because $S$ is bounded at 0 and 10 — without it the model would happily
predict a stringency of 14.

| group | in the model | idea |
|---|---|---|
| **actor power** | clean-energy build-out; fossil dependence; fossil interests per person | the economic weight of fossil and clean-energy interests |
| **institutional quality** | government effectiveness; rule of law; vertical accountability (can voters hold rulers to account) | can the state deliver, are its rules kept, and does it have to answer for it |
| **how they combine** | each actor-power term multiplied by each institution, **weighted by how freely opinion and information circulate** | the same interest matters differently in different states, and an institution can only be used against an interest where people can speak |
| **controls** | income, population, clean baseload (hydro, nuclear, geothermal), a common time trend | structure |

Fossil interests enter **twice** on purpose. The *share* of fossil fuels in the energy system measures
dependence; fossil interests per person measures how large the fossil interest is. They pull in
different directions — dependence goes with less stringent policy, scale in power and industry
with more — and carrying both lets the model tell them apart. Read at each country's own values, fossil dependence
lowers the ceiling for every country.

The actor-power terms **saturate**: each enters as $x/(x+\text{median})$, so a share far outside
anything observed cannot push the prediction along a straight line. The fossil terms are also **bounded below** at the
cleanest twentieth of the sample, so a country with almost no fossil energy (Iceland) is read at that edge rather than
extrapolated beyond it.

## Step 3 — Ask what a country *could* do

The central move. Instead of one line through the data, we fit a **frontier**: the best
stringency achieved by countries with comparable drivers. Real countries sit *below* it.

$$\varepsilon = v - u, \qquad u \ge 0$$

$v$ is ordinary symmetric noise; $u$ is the **shortfall**, one-sided by construction — the
distance between what a country's drivers permit and what it actually did. Call the frontier
$S^{*}$.

**In buildings and transport, how far below the frontier a country sits depends on its fossil rents** — the income
from oil, gas and coal. Countries that earn a lot from them price fuels less than their institutions and interests
would allow (the "rentier state"). The rents change the shortfall, not the frontier: put into the frontier they gave
results against the theory. Left out of the shortfall, they would leave a country like Saudi Arabia looking as if it
used almost all of its potential; with them, it uses about two-thirds.

What sets the frontier: fossil dependence is the clearest channel in both sectors; **state capability** is the
clearest institutional channel in buildings and transport; in power and industry the institution terms are **not
identified** (they are insignificant on average and flip sign at the frontier), and read together they lower that
sector's ceiling. A common upward time trend does a large share of the work, which is why the model is used to *rank*
countries, not to explain how policy rose.

## Step 4 — Define the gap

$$E = \frac{S}{S^{*}} \in (0,1]$$

$E$ is the share of its own potential a country has realised. **The gap is $1-E$** — always
relative to that country's own frontier, never an absolute number of index points.

> **Why relative matters.** A weak-institution country has a low ceiling, so its absolute gap
> is small. Ranking on absolute gaps rewards that — it reads "little left to do" where it
> should read "little capacity".

In 2023 the median country realises about **72%** (power & industry) and **80%** (buildings & transport) of its own
ceiling. Power & industry is the more constrained sector in 39 of the 48 countries.

**Which country sits where is less certain than that.** Re-estimating the frontier with different,
equally defensible assumptions about the shortfall reshuffles the country ranking considerably.
So we report groups and ranges, never a named league table.

## Step 5 — Read the gap once, and hold it

Each country's distance below its ceiling is read **once, in 2023**, the last year with data, and
then **held**: as the scenario changes the country's drivers, its ceiling moves, and the country
stays the same distance below it (measured on the logit scale). **In buildings and transport the distance follows the
country's fossil rents**: as a pathway lowers fossil income, an exporter's shortfall shrinks. Part of that would happen
without climate policy too (depletion, costs), and the paper says so.

**Why not let gaps close at a historical speed?** An earlier version did, at an estimated speed of
about 0.1 a year. But that speed does not forecast better than "assume nothing changes", and the
same estimator returns speeds of that size on artificial data in which *nothing* ever closes. So it
cannot show that politics catches up. **The model assumes the gap persists**, and asks the
question the other way round as one declared assumption (κ, Step 7): *what if politics improves by
itself?*

## Step 6 — Cover the countries the data never saw

CAPMF covers 48 countries; REMIND needs all of them. Giving uncovered regions *no constraint at
all* would reward missing data with **maximum assumed political capability**.

Every uncovered country instead takes **the median share of their own ceiling that the covered countries realise**,
and keeps **its own** ceiling. An earlier version borrowed the share of the most similar covered countries; tested on
the covered countries themselves (each treated in turn as unobserved), the median predicted better: similar drivers do
not mean a similar shortfall, because the ceiling has already absorbed what the drivers say.

The United States has no policy data at all and is at the median; its result should be read as a range.

## Step 7 — Turn the gap into one number per region, per sector, per year

Countries aggregate to REMIND regions, weighted by **final energy**. Three quantities follow:

- **The ranking $u$.** Where each region sits among all regions in 2023, from the one closest to
  its frontier (0) to the furthest (1). Read once, separately for each sector, and **fixed**. Russia and the reforming
  economies are the most constrained region in both sectors.
- **The strength $k(t)$.** How large the region's own political shortfall is, relative to 2025 ($k = 1$
  in 2025). It moves every period, because the ceilings move with REMIND's energy system, income and
  institutions (and the shortfall with fossil rents). Each region's strength follows its own gap, so an exporter whose
  rents fall loosens its own constraint, not everyone's. On the 1000 Gt pathway the strength is about 0.6 by 2050 in
  both sectors.
- **The feasibility share**:

$$\varphi_{r,s}(t) = 1 - \theta\,k_{r,s}(t)\,u_{r,s}$$

So $\varphi = 1$ means no political discount, and in 2025 the most constrained region in a sector
sits at $1-\theta$; later each region moves with its own strength.

$\theta$ is the **severity dial** — a choice, not an estimate — so it is swept: **0.325, 0.50 and
0.675**. There is no historical experiment that would let us estimate it. **$\theta = 0$ switches the
whole thing off**, which is how we test the machinery is wired correctly.

**Institutions** are projected by one rule: every country closes 0.6% of its distance to the best observed value each
year — the pace of the published SSP2 governance assumption, and of the last century of V-Dem data.

**κ, the erosion rate** — one sensitivity, not the headline: the strength also shrinks by κ a
year, whatever the drivers do — "politics improves by itself". Declared at **0.027** (the limit halves
by mid-century), with 0.02, 0.05 and the historical rates (1.1% and 4.6% a year), before any run that uses it.

## Step 8 — Connect it to REMIND

The share caps how far each region's carbon price can rise above its current policy:

$$P = \min\big(A,\ P^{\text{ref}} + \varphi\,(A - P^{\text{ref}})\big)$$

with $A$ the cost-optimal global price and $P^{\text{ref}}$ today's policy. What REMIND may do in
response is the experiment, run two ways:

**Hold the price.** The global price stays on the path that meets the budget without
politics; the cap binds; emissions are what they are. *Says:* how much carbon budget does political
feasibility cost?

**Hold the budget.** The budget must still be met; REMIND raises the global price until it
is. *Says:* who pays more, who pays less, and where does abatement move?

REMIND prices two markets — electricity-and-industry, and everything else — so each market
carries its own sector's feasibility on top of a shared floor, rather than both collapsing to the
more constrained one.

## Step 9 — The loop

```
REMIND solves  →  new energy system
      ↓
drivers change (fossil share, electrification, fossil rents …)
      ↓
PFM recomputes ceilings, the strength k(t), and φ(t) for every period
      ↓
carbon price updates
      ↓
REMIND solves again …
```

A **fixed point**: converged when another PFM call stops changing the share path, measured as the
largest change anywhere over 2035, 2050, 2070 and 2100. A *maximum*, not an average — one region
still moving keeps the loop open. In the batch it took 2 to 20 calls.

Three failure modes are watched explicitly, because the dangerous one is silent: a runaway carbon
price makes the model *succeed* while producing nonsense.

## Step 10 — The scenarios

| run | what it answers |
|---|---|
| **reference** | uncoupled — the plain baselines (current policies, the 1000 Gt budget) |
| **no-politics reference** (θ = 0) | is the machinery wired correctly? Must match a uniform-price reference |
| **hold the price** | how much carbon budget does political feasibility cost? |
| **hold the budget** | where does the price and the abatement move? |
| **θ = 0.325 / 0.675** | how much of the answer is the severity dial? |
| **how long the limit lasts** | constant, growing, or eroding at 2% / 2.7% / 5% or the historical rates |
| **institutions** | held at 2023; the published government-effectiveness path; the older, faster rule |
| **strength** | one world strength instead of each region's own; the gap normalised first |
| **rents** | REMIND's fossil rents at the world price instead of the region's own |
| **the shrinking future** | politics decided decade by decade (Step 12) |

**Always compare against the θ = 0 reference, not the plain baseline**: switching the machinery on also
changes REMIND settings whose effect can be larger than the politics.

## Step 11 — What the runs say

The full set ran in October 2026 — 66 runs at two different ways of carving the world into
regions (21 and 12), so that anything resolution-specific shows up as a disagreement.

**The first finding is the cost.** Holding the price, respecting what politics permits adds about
**70 billion tonnes of CO₂** by 2100 (75 at the finer regional detail, 64 at the coarser) to the
pathway that meets a 1000 Gt budget. The severity dial moves it between **39 and 110**.

**The second is how much it depends on how long the political limit lasts.** If it erodes by itself at the declared
central rate, three-fifths of that cost goes (29 left); if today's limit simply stays, the cost rises to 124; if it
tightens, to 160. That assumption matters more than anything else we tested.

**The third is what happens when the budget is held.** It holds in every run — the model raises
the global carbon price by about a sixth, and moves about **20 billion tonnes of CO₂-equivalent**
of abatement between regions: Russia and the reforming economies and Sub-Saharan Africa abate less; the Middle East,
China and other Asia more. The Middle East switches side compared with the previous version because its fossil rents
fall along the pathway, and its constraint with them.

**The fourth is that politics responds.** As REMIND changes the energy system, the strength moves, and the model and
the political layer settle together over several rounds. It is not a causal claim.

**The fifth is how it compares with the previous version.** The cost is about a quarter smaller. Most of that comes
from the rule for the countries without data and the form of the fossil terms — modelling decisions, not new evidence
that politics is easier. Projected institutions now matter a little: holding them at today's values adds about 10.

## Step 12 — Politics decade by decade: the shrinking future

In the runs above, REMIND plans the whole century at once and knows that the political limit will still be there in
every later year. In reality decisions are taken step by step: what has been built is locked in, and politics
constrains what is being decided now.

So we also ran **a chain of five runs**, one per decade from 2030 to 2070. Each run inherits the energy system the
previous one built, applies the political limit to its own decade only, and plans the rest of the century as if the
limit would then lift. The last run is the chain's result.

- **Holding the price, the chain ends at about 39 billion tonnes over the no-politics pathway — half the 75 of the
  one-shot run — although the prices actually paid are the same.** Each decade invests for a future price that never
  comes, and the next decade inherits that cleaner energy system. Expectations about future politics turn out to matter
  as much as the severity dial.
- **Each decade over-promises.** The first decade plans to end 7.5 above the pathway; the chain delivers 39.
- **Holding the budget, the budget is still met**, but the effort moves later, with a higher carbon price at the end.

One severity, one regional detail and ten-year steps so far; the version in which each decade knows the limit will
last, and five-year steps, are next.

---

## What this can and cannot say

**It can:** place regions in groups by how far they sit below their own political potential; show
what a cost-optimal pathway implies for regions that have never sustained anything like the
required price; measure what an optimising model does when it must respect that.

**It cannot:** predict elections, treat the gap as a physical constraint, claim the frontier is a
hard limit, or say that institutions *cause* the ceiling. It is a *statistical* frontier — the best
observed among comparable countries, not a law.

**Nine honest limitations:**

1. **Coverage.** 48 of 248 countries are observed. The rest take the covered median — better than assuming no
   constraint, but still an assumption.
2. **Two dials are choices.** The severity θ and the erosion κ are declared, not estimated. Any
   result that only exists at one setting is a result about the setting.
3. **Expectations are a choice too.** The one-shot runs and the shrinking future bracket the cost at about 39 to 75;
   which one politics resembles is not something the model knows.
4. **The power-and-industry institutions are not identified**, and part of how that sector's
   strength moves rests on them. Every headline run has a variant with institutions held.
5. **The specification is not unique.** Across resampled data, state capability and rule of law are
   in the winning model every time, and fossil interests in two forms; but the exact selected model wins about one
   admissible draw in three, and two families of saturation split the wins.
6. **Some regions are pinned by the dial, not by their data.** The construction guarantees that
   *somebody* sits at the bottom of each sector's scale — Russia and the reforming economies in both sectors. Their
   number says "ranked last", not "can only manage half".
7. **The gap is held, not forecast** (moved only by fossil rents in buildings and transport). We do not know how fast
   political gaps close; we assume they persist and report κ as the alternative.
8. **The feasibility share depends on modelling choices, not only on the region.** Other
   assumptions about how countries fall short of their frontier move it. It is a property of a region *given a model*,
   reported as a band.
9. **Which world the runs are in.** Whether existing legislated carbon prices can be rolled back is
   a model switch. Every run is configured to allow it — the less conservative of the two choices —
   and the paper must say so in one sentence.
