# The Political Feasibility Model, explained

*A plain-language walkthrough for readers who do not run the code — colleagues, WP partners,
reviewers. Eleven steps, a handful of equations. Derivations, caveats and fitted values are in
`MODEL.md`; the REMIND interface is in `COUPLING.md`. Numbers here are from Run-Group `v5`.*

📊 **Charts.** Everything is built by `analysis/figures/build-figures.R` from the registry in
`analysis/figures/R/registry.R`, and rendered into `analysis/figures/output/all/` (one PNG per figure, always) and
`analysis/figures/output/paper2/` (the paper's PDFs). Slides and poster renders are opt-in
(`--media=slide,poster`). **`analysis/figures/output/all/index.html` shows every figure on one page.**
`analysis/figures/output/FIGURE-GUIDE.md` is generated from the same registry and explains, for every
figure, what it shows, what to read off it and what must not be claimed from it — start there.

```bash
Rscript analysis/figures/build-figures.R                 # everything, every medium
Rscript analysis/figures/build-figures.R --only=<id>     # one figure
```

> Step 11 reports the coupled REMIND runs for the current model (62 runs, September 2026).

---

## The question

Integrated assessment models like REMIND answer *"what is the cheapest way to meet a carbon
budget?"* They assume every region can adopt whatever carbon price the optimisation asks for.

Politics says otherwise. Countries with similar economies adopt very different climate policy,
and they change it at a limited speed.

**This model asks a different question: what is a region politically able to do, and what
happens to the mitigation pathway once you take that seriously?**

---

## Step 1 — Measure what countries actually do

The OECD's Climate Actions and Policies Measurement Framework (CAPMF) scores national climate
policy stringency on a **0–10** index. We use two sector groups, because the politics differ:

- **Bulk** — electricity and industry. Few, large, organised actors.
- **Diffuse** — buildings and transport. Costs land on households directly.

Call this observed stringency $S$. It exists for **48 countries**; the model must eventually
speak for **248**.

## Step 2 — Explain it with drivers

$$\operatorname{logit}\!\left(\frac{S}{10}\right) = \beta'x + \varepsilon$$

The logit is there because $S$ is bounded at 0 and 10 — without it the model would happily
predict a stringency of 14.

| group | in the model | idea |
|---|---|---|
| **actor power** | clean-energy (innovator) share; fossil incumbent share; fossil incumbency per person | who wins the fight, and how big the losers are |
| **institutional quality** | government effectiveness; vertical accountability (can voters hold rulers to account) | can the state deliver, and does it have to answer for it |
| **how they combine** | each actor-power term multiplied by each institution | the same lobby matters differently in different states |
| **controls** | income, population, hydro/nuclear share, a common time trend | structure |

Incumbency enters **twice** on purpose. The *share* of fossil fuels in the energy system measures
dependence; incumbency *per person* measures how large the fossil interest is. They pull in
different directions in the data — dependence goes with less stringent policy, scale in power and
industry with more — and carrying both lets the model tell them apart.

## Step 3 — Ask what a country *could* do

The central move. Instead of one line through the data, we fit a **frontier**: the best
stringency achieved by countries with comparable drivers. Real countries sit *below* it.

$$\varepsilon = v - u, \qquad u \ge 0$$

$v$ is ordinary symmetric noise; $u$ is the **shortfall**, one-sided by construction — the
distance between what a country's drivers permit and what it actually did. Call the frontier
$S^{*}$.

What sets the frontier: **state capability** is the clearest institutional channel — strongly in
buildings and transport, weakly and fragilely in power and industry. Accountability has no clear
effect on its own. A common upward time trend does a large share of the work, which is why the
model is used to *rank* countries, not to explain how policy rose over time.

## Step 4 — Define the gap

$$E = \frac{S}{S^{*}} \in (0,1]$$

$E$ is the share of its own potential a country has realised. **The gap is $1-E$** — always
relative to that country's own frontier, never an absolute number of index points.

> **Why relative matters.** A weak-institution country has a low ceiling, so its absolute gap
> is small. Ranking on absolute gaps rewards that — it reads "little left to do" where it
> should read "little capacity".

In 2022 the median country realises about **71%** (Bulk) and **75%** (Diffuse) of its own ceiling,
and every one of the 48 sits below both.

**Which country sits where is less certain than that.** Re-estimating the frontier with different,
equally defensible assumptions about the shortfall reshuffles the country ranking considerably.
So we report groups and ranges, never a named league table.

## Step 5 — Ask how fast gaps close

Countries do not jump to their frontier:

$$\Delta S_t = \lambda\big(S^{\text{eq}} - S_{t-1}\big)$$

Estimated from history, $\lambda$ comes out at about **0.11** (Bulk) and **0.08** (Diffuse) per
year — half-lives of 6 and 9 years.

**Two honesty notes, and they decide how the number is used.** First, of the four finer sectors
**only electricity's speed beats "assume nothing changes" out of sample.** Second, when we feed the
same estimator artificial data in which *nothing* ever closes any gap, it still returns speeds of
this size. So we cannot show the historical speed is political catching-up rather than an artefact
of the method. **The coupled runs therefore assume the political gap persists**, and run the
estimated speed only as a sensitivity.

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
borrows only the gap. Every number carries its provenance, because once everything has a value
the output stops *looking* uncertain even though the evidence has not changed. In power and
industry, more than half the uncovered countries fall into the low band.

**How much of the world is actually measured depends on how you weight it:** roughly a fifth of
countries, but by final energy — what a carbon price acts on — **eleven of twenty-one** world
regions are fully covered, China is 96% covered, and apart from the United States only Sub-Saharan
Africa (15%) and the Middle East (22%) fall below a quarter. Quote the weighting alongside the number, always.

The residual is **concentrated**: the United States has no policy data at all, which is why the
single documented override for the USA carries so much weight — and why its feasibility share must
be reported as a range, not a point.

## Step 7 — Turn the gap into one number per region

Countries aggregate to REMIND regions, weighted by **final energy**. Each region gets a
**feasibility share**:

$$\varphi_r = 1 - \theta\,u_r$$

where $u_r$ is the region's position in the range of relative gaps: 0 for the region closest to
its frontier, 1 for the furthest. So $\varphi = 1$ means no political discount and
$\varphi = 1-\theta$ the most constrained region.

$\theta$ is the **severity dial** — a choice, not an estimate — so it is swept: **0.325, 0.50 and
0.675**. There is no historical experiment that would let us estimate it, and the one shortcut that
used to suggest a value no longer works for power and industry. **$\theta = 0$ switches the whole
thing off**, which is how we test the machinery is wired correctly.

## Step 8 — Connect it to REMIND

Three ways to apply $\varphi$, run as alternatives because they make **different claims**:

**A. Ratio** — politics rescales each region's share of the global price. *Says:* politics
changes **where** abatement happens. The budget is always met.

**B. Level** — politics caps how much of the *extra* effort beyond current policy a region
delivers. *Says:* politics caps **how much** a region can do. The budget may become unreachable —
and that is the finding, not a failure.

**C. Mild progression** — the price is *generated* by politics rather than constrained, starting
from today's observed price. *Says:* where does current political momentum actually take us? No
budget, so it cannot be infeasible.

A and B constrain the optimiser; C ignores it entirely. **B and C agreeing would not by itself be
corroboration**: an earlier version had them nearly identical, and that turned out to be a bug
pulling both towards the same reference price. Two methods agreeing is only evidence if they are
genuinely independent.

REMIND prices two markets — electricity-and-industry, and everything else — so each market
carries its own sector's feasibility on top of a shared floor rather than both collapsing to the
more constrained one.

## Step 9 — The loop

```
REMIND solves  →  new energy system
      ↓
drivers change (fossil share, electrification …)
      ↓
PFM recomputes ceilings, gaps, and φ
      ↓
carbon price updates
      ↓
REMIND solves again …
```

A **fixed point**: converged when another PFM call stops changing $\varphi$, measured as
$\delta = \max_r|\varphi_r^{\text{new}} - \varphi_r^{\text{old}}|$. A *maximum*, not an average —
one region still moving keeps the loop open. $\varphi$ is read at 2035, the first period REMIND is
free to change.

Three failure modes are watched explicitly, because the dangerous one is silent: a runaway carbon
price makes the model *succeed* while producing nonsense.

## Step 10 — The scenarios

| run | what it answers |
|---|---|
| **reference** | uncoupled — the plain baseline |
| **gate** (θ = 0) | is the machinery wired correctly? Must match the reference within tolerance |
| **ratio** | does politics redistribute effort between regions and markets? |
| **level, budget kept** | who would have to exceed their political limit, and by how much? |
| **level, budget relaxed** | how much carbon budget does political feasibility cost? |
| **mild progression** | where does current momentum take us on its own? |
| **θ = 0.325 / 0.675** | how much of the answer is the severity dial? |
| **gap closes** | what changes if the political gap is assumed to close at the historical speed? |
| **one price per region** | what is lost if the two markets cannot be priced separately? |

Each also runs on a current-policies pathway, so an effect can be attributed to the coupling
rather than to the mechanism acting on any price path. **Always compare against the θ = 0 gate,
not the plain reference**: switching the machinery on also changes an unrelated REMIND setting
whose effect can be larger than the politics.

**The headline is chosen after the results, against a rule agreed in advance** — and that rule
includes: if the political constraint turns out *not* to bind, we report that rather than hunting
for a version that does.

## Step 11 — What the runs say

The full set ran in September 2026 — 62 runs at two different ways of carving the world into regions,
so that anything resolution-specific shows up as a disagreement, with both free parameters swept.

**The first finding is the cost.** When the carbon budget is not forced to hold, respecting what
politics permits adds about **130 billion tonnes of CO₂** at the finer regional detail and **150** at
the coarser one. How severe the constraint is taken to be moves it between **75 and 220**. Assuming
the political gap closes over time — the choice most people expect to be the optimistic one — moves
it *up*, to **190–240**, because a permanent limit binds early and a closing one leaves more to catch
up later.

**The second is what happens when the budget is held.** It survives — but only because the model
raises the global carbon price by about a third, and it does not raise it evenly. Within a region the
industrial and household-facing prices move apart, by up to one and a half to one. Households pay
*less* than industry in 15 of 21 regions and *more* in the other 6, Russia among them. The honest
finding is the width and the region-specificity, not a direction. Being able to price the two markets
separately buys back about a fifth of the carbon cost.

**The third is that politics responds.** As REMIND changes the energy system, the feasibility shares
move — by up to 0.08 for a region — and the model and the political layer settle together over several
rounds. The loop of Step 9 is visible in the numbers. It is not a causal claim.

**The fourth is a warning about controls.** Measured against the right control — the same machinery
with the dial at zero — politics raises emissions. Measured against the plain uncoupled run, it appears
to *lower* them, because switching the machinery on also changes an unrelated REMIND setting whose
effect is six to seven times larger.

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
   rules — better than assuming no constraint, but still assumption.
2. **Two gap definitions coexist.** Steps 4–7 use $1-E$ (bounded, frontier-relative); mild
   progression uses $(S^{*}-S)/S$ (unbounded). They are not interchangeable.
3. **The severity dial $\theta$ is a choice.** Any result that only exists at high $\theta$ is a
   result about $\theta$, not about politics. It is swept through REMIND at three values.
4. **The specification is not unique.** Across resampled data, state capability is in the winning
   model every time and incumbency-in-two-forms three times in four; but the particular set of
   institutions wins only about one draw in eight, and the exact deployed model about one in
   twelve. Which accountability measure belongs is not settled.
5. **Some regions are pinned by the dial, not by their data.** The construction guarantees that
   *somebody* sits at the bottom of the scale — in the coupled runs, Central Europe and Russia at the
   finer regional detail, Latin America and Russia at the coarser one. Their number says "ranked
   last", not "can only manage half".
6. **The historical speed of political change is not demonstrated.** A method that finds the same
   speed in data where nothing changes cannot show that anything did. We assume gaps persist and
   report the alternative.
7. **The feasibility share depends on modelling choices, not only on the country.** Changing an
   equally defensible assumption about how countries fall short of their frontier moves a region's
   feasibility share by a median of up to about 0.17. Refitting the supply-side sector under a
   different equally defensible specification leaves most regions where they were, but moves the
   ones it touches by up to 0.27 — and changes which region sits lowest of all. **We keep one shared specification for both
   sectors deliberately, because their scores are compared against each other — but the price is
   that the number is a property of a region *given a model*, not a measured property of the
   region.** We report it as a band rather than a point.
8. **Which world the runs are in.** Whether existing legislated carbon prices can be rolled back is
   a model switch. Every run is configured to allow it — the less conservative of the two choices —
   and the paper must say so in one sentence.
