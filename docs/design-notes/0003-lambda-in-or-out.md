# 0003. Does λ belong in the paper?

Date: 2026-09-18, on Run-Group `v5` (62 coupled runs, `v5-specalt` specification variant)
Status: **Closed 2026-10-08** by [ADR 0050](../adr/0050-lambda-removed-from-the-coupling.md) (accepted): λ leaves
the coupling from `v6`. Written to support a decision, not to record one. Everything below is
re-derivable from `output/pfm/v5/`; nothing here may be quoted in the paper without re-reading it
from an artifact (`docs/design-notes/README.md`).
Related: `docs/MODEL.md` §4 (the dynamics) and §4.3.1 (two estimates), `docs/TODO.md` item 12,
claims C12–C16, C19b, C25, C29, C35, C36.

---

## 0. The question, stated precisely

λ is the **gap-closure rate**: the fraction of the distance between where a country's policy is and
where its drivers say it settles that closes each year. "Dropping λ" is ambiguous, and the ambiguity
matters more than the decision, because λ does **two unrelated jobs**:

| | job A — *inside REMIND* | job B — *inside the projection* |
|---|---|---|
| switch | `cm_pfmGapClosure` | none: always on |
| what it does | does a region's political gap close over the century, or persist? | carries observed stringency from the last data year to the tier year (2035), where **E and φ are read** |
| deployed | **0 — the gap persists** | the full-panel ECM rate (Bulk 0.1027, Diffuse 0.0621) |
| dropping it | changes **no result**: every headline run already has λ = 0. You lose the `GAPCLOSE` arm and the λ claims | there is no projected stringency, so **no E, no φ, no coupling** |

**A paper without job A is a real option. A paper without job B is a different paper** — you would
have to read φ at the last observed year instead of 2035, which changes every coupled number and
needs the whole batch re-run.

Everything below assumes **job A**: λ = 0 stated as an assumption, the estimation of λ and its
sensitivity arm removed from the paper.

---

## 1. Two abstracts

Both are ~150 words, the Nature Climate Change limit (`../_archive/_wip/2026-10-01/paper/docs/paper-design.md`). Numbers are
from `../_archive/_wip/2026-10-01/paper/paper-data/output/numbers.csv` on `v5`. **Draft language, not approved text.**

### A. With λ — "the ceiling is measured, and its persistence is defended"

> Integrated assessment models assume governments levy whatever carbon price a cost-optimal pathway
> requires. We estimate the price politics can sustain — a stochastic frontier over institutional
> quality and actor power across 48 countries — and impose it inside REMIND as a constraint. We also
> estimate how fast the political shortfall closes, and find we cannot: the adjustment rate fails an
> out-of-sample test against no change in every sector but electricity, and a placebo panel with no
> adjustment by construction returns rates of the same size. Treating the shortfall as persistent is
> therefore an assumption we test rather than one we adopt. Under it, holding the 1000 Gt budget
> requires raising the global carbon price by a third and separating industrial from household prices
> within regions by up to 1.5 to 1; holding the price path instead adds about 160 Gt CO₂, concentrated
> in the most constrained regions.

### B. Without λ — "the ceiling is measured; persistence is assumed"

> Integrated assessment models assume governments levy whatever carbon price a cost-optimal pathway
> requires. We estimate the price politics can sustain — a stochastic frontier over institutional
> quality and actor power across 48 countries, in which each country's shortfall to its own ceiling is
> the political space it has not claimed — and impose that ceiling inside REMIND as a constraint on a
> 1000 Gt pathway. Holding the budget requires raising the global carbon price by a third and
> separating the industrial from the household carbon price within regions by up to 1.5 to 1, in a
> direction that differs by region. Holding the price path instead adds about 160 Gt CO₂ over the
> century, concentrated in the regions the ceiling binds hardest. The shortfall is held fixed over the
> horizon; how fast it might close is outside what this analysis identifies.

**The tell is the fourth sentence.** In A the paper says *we tried to measure the speed and could not,
so we assume persistence*. In B it says *we assume persistence*. Same runs, same numbers, different
epistemic standing.

---

## 2. What each claim does under B

39 claims in `../_archive/_wip/2026-10-01/paper/docs/claims.md`.

**Excluded (6)** — the claims that *are* λ: **C12** (half-life 4–6 years), **C13** (the ECM beats
no-change only in electricity), **C14** (no-change is hard to beat where policy barely moved),
**C16** (event timing unpredictable, AUC 0.48 / 0.33), **C25** (the ceiling's historical rise is
mostly secular drift), **C29** (the coupled replay improves the Diffuse fit where the ceiling acts —
its comparator *is* the uncoupled ECM).

**Unchanged (18)** — the estimation spine and the limitations: C3, C7–C11, C15, C17, C18, C21, C22,
C24, C26–C28, C30, C31, C34.

**Kept but weaker (15)** — C1, C2, C4, C5, C6, C19, C19b, C19c, C20, C23, C32, C33, C35, C36, C37.
They survive numerically (λ = 0 is what produced them) but lose the arm that shows how much they
depend on it.

### The numbers B can no longer show

| result | λ = 0 (deployed) | λ = estimated | what B loses |
|---|---|---|---|
| quantity headline, EU21 / H12 | **+159.3 / +163.8 Gt** | +254.4 / +266.0 | that λ = 0 is the **conservative** choice, by 37–38% |
| within-region ES/ETS split, EU21 | **0.66–1.37** | 0.92–1.03 | that λ = 0 is the **generous** choice — the split nearly vanishes |
| mode-R regional spread, EU21 / H12 | **1.88× / 1.76×** | 1.10× / 1.09× | same, 62–71% |
| abatement relocated, budget held | **72 / 81 Gt** | 6 / 7 Gt | that the relocation exists *because the gap persists* |

---

## 3. The asymmetry that decides it

λ = 0 does not push every result the same way, and that is the whole argument.

- For the **cost headlines** it is conservative: assuming persistence *lowers* the CO₂ cost. A
  sceptical referee cannot say we inflated it.
- For the **split and the relocation** — the paper's other headline — it is **generous**: the split
  and the relocation exist *because* the gap persists, and both nearly vanish at the estimated rate.

So under B the paper's second headline rests on an assumption the paper neither tests nor discloses
the sensitivity of. That is the exposure. It is not fatal — the assumption is stated — but it is the
kind of thing a referee finds in one question: *"what if the gap closes?"*

Under A the answer is already in the paper: *we measured the rate, it failed its own forecast test
(skill −0.180 Bulk, −0.698 Diffuse against persistence), a placebo returns 0.291 / 0.104 where
nothing adjusts, two-thirds of Diffuse countries have a non-positive own rate — so we hold the gap
fixed, and here is the arm that shows what closing it would do.*

---

## 4. What A costs

Roughly **one SI subsection plus two numbers per affected claim**: the ECM form, the hold-out
protocol, the four-sector table, the placebo, and the `GAPCLOSE` column in the results tables. It is
already measured, already in the bundle, and the eight `GAPCLOSE` runs are done.

The real cost is **tonal**: A spends its most technical paragraphs telling the reader what the model
cannot do. That is the house style (`CLAUDE.md`: "claim ≤ evidence"), and C13–C16 are where the paper
is most obviously honest — but it is a choice about what kind of paper this is.

---

## 5. A third option, if B is tempting for length

**B′ — drop the λ *estimation*, keep the λ *sensitivity*.** No C12–C16, no ECM validation section;
keep the `GAPCLOSE` arm as a declared robustness column and one sentence: *"the gap is held fixed;
an arm in which it closes at a rate estimated from the panel moves the cost headline to 254–266 Gt
and nearly removes the split."* Costs about 80 words. Keeps the defence of the assumption the split
rests on; loses the honesty exhibits.

**Ranking on the paper's own standard (claim ≤ evidence): A > B′ > B.** B is only coherent if the
paper also drops the split headline and presents the quantity headline alone — a narrower, still
publishable paper.

---

## 6. What would settle it

- **A referee test.** Give someone B and ask what they would challenge first. If "what if the gap
  closes?" is in their first three questions, B is not viable.
- **Length.** If S2 and Methods come in under budget, A costs nothing that matters.
- **Item 12a** (retarget the ECM at the frontier) is a *separate* question and should not be bundled
  in: recommendation there is still to decline, with the limitation stated in the SI.
