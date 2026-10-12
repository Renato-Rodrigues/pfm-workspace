# 0006 — v6 paper frames: which question the v6 paper asks

**Status: Open** — the spine is the author's choice. Recommendation: frame 2 (today's politics versus
tomorrow's), with frames 3–5 and messages A–F as its sections.

**Provenance.** Run-Group `v6`, EU21, θ = 0.50, 1000 Gt budget; every number is read from
`output/pfm/v6/coupling/` (`persistence-ladder.json` from `analysis/v6/persistenceLadder.R`,
`coupled-facts.json`, `coupled-costs.json`, `rulec-relocation-decomp.rds`), 2026-10-12. Drafted as a
Claude Doc (https://claude.ai/code/artifact/101af937-af7a-4318-a328-cc8e2c0e8935) and saved here; this
file is the record. Like every design note it is not authoritative: re-derive a number from the
artifact before quoting it (README.md).

## Purpose and basis

The v6 results support five paper frames and several further messages. All of them rest on one finding:
a single setting, how long the political drag lasts, orders every result under both closures. This
document sets the frames side by side so the spine can be chosen.

The evidence every frame draws on is the persistence ladder below. The drag is the political strength
k(t) on the carbon-price ceiling; κ is the declared erosion.

| How long the drag lasts | k, Bulk (2050 → 2100) | Hold the price: extra CO₂ by 2100 (Gt) | Hold the budget: global price 2050 (× θ = 0 run) | Hold the budget: abatement moved (Gt CO₂eq) | Regional price gap, 2100 (SD) |
| --- | --- | --- | --- | --- | --- |
| Never fades: today's politics frozen (Ehold) | 0.99 → 1.00 | +189.1 | ×1.45 | 65.6 | 0.138 |
| Fades with the transition (deployed v6) | 0.69 → 0.53 | +118.2 | ×1.26 | 22.7 | 0.081 |
| Plus declared erosion, κ = 0.02 | 0.40 → 0.11 | +53.5 | ×1.13 | 9.5 | 0.014 |
| κ = 0.027 | 0.33 → 0.06 | +41.2 | ×1.10 | 8.4 | 0.008 |
| κ = 0.05 | 0.18 → 0.01 | +22.1 | ×1.05 | 5.3 | 0.001 |

k is shown for the hold-the-price runs. The hold-the-budget runs settle a little lower (deployed 0.62 →
0.50).

Other quantities the frames cite:

- **Under hold-the-budget, the global price rises** by ×1.26 at the deployed setting. H12 matches EU21 on
  the deployed runs: +112.8 against +118.2 Gt of extra CO₂, and 19.9 against 22.7 Gt moved. The ladder
  itself was run on EU21 only.
- **Severity θ** from 0.325 to 0.675 gives +73.0 to +181.5 Gt.
- **The estimated parts span less than the declared ones:**

  | Estimated part | Extra CO₂ (Gt) |
  | --- | --- |
  | Ranking permutations | 89–126 |
  | Reversed ranking | 67.9 |
  | Uniform ranking | 105.8 |
  | Assignment band | 110–155 |
  | Specification family B | 107.5 |

## Frame 1. What gives: the budget or the price (the current spine)

**Pitch:** if politics caps carbon prices, the world has to give up either the budget or the price.

> Cost-optimal mitigation pathways assume carbon prices are politically unconstrained. We estimate a
> feasibility frontier that turns institutions and actor coalitions into a ceiling on carbon-price
> stringency in each region, and couple it into the REMIND model. If governments hold the carbon price
> the ceiling allows, a 1000 Gt pathway emits about 118 Gt more by 2100. If they keep the budget instead,
> the global price must rise by about a quarter, and about 23 Gt of abatement moves from constrained to
> less constrained regions, at negligible aggregate cost. Political feasibility shows up either as
> overshoot or as a higher, redistributed price.

- **Appeal:** familiar to modellers, with clean headline numbers.
- **Weakness:**
  - The numbers change 5–9× with the persistence assumption, so a referee will ask "under which
    persistence?"
  - The budget horn is small in v6.
  - The frame has no account of why v6 differs from v5.

## Frame 2. Today's politics versus tomorrow's (persistence, made concrete)

**Pitch:** scenarios that build in today's political constraints overstate the cost of politics, because
those constraints erode as the transition proceeds.

> Mitigation scenarios increasingly include political feasibility, usually as constraints calibrated to
> present-day politics. We ask what happens if those constraints are not permanent. Our estimated
> feasibility frontier links the ceiling on carbon prices to institutions and to the strength of
> fossil-fuel coalitions. Coupled into REMIND, it compares a world that keeps today's politics with one
> whose politics develop as the energy transition proceeds.
>
> With today's politics frozen, holding the politically feasible price adds 189 Gt to a 1000 Gt pathway,
> about a fifth of the budget. Keeping the budget instead moves 66 Gt of abatement between regions,
> mostly onto China. When the political drag weakens as the transition shrinks fossil-fuel coalitions,
> these fall to 118 Gt and 23 Gt. Under faster declared erosion they fall to 22 Gt and 5 Gt. Most of the
> cost of political feasibility is the cost of assuming politics does not change.

- **Appeal:**
  - It gives one headline quantity, the "political dividend" of the transition: 71 Gt from the model's
    own fading alone, and up to 167 Gt with declared erosion.
  - It speaks directly to the literature on feasibility spaces and on policy sequencing and winning
    coalitions, and it critiques static feasibility constraints in scenario work.
  - It is newsworthy without overclaiming.
- **Risk:**
  - The fading strength k(t) comes from the projected drivers, and κ is declared. The paper can say "*if*
    politics develops", not "policy *causes* politics to develop", because the causal feedback is not
    identified.
  - Wording has to hold that line throughout.
- **Optional extra:** a backsliding arm, where strength rises above today's level, would make the
  comparison two-sided ("better or worse than today"). That is topical. Since 2026-10-12 the coupling
  accepts a negative κ; the rows are in the matrix (`V6BACK`), and the rate is still to be declared.

## Frame 3. Persistence decides (option B as written)

**Pitch:** the cost of political feasibility hinges on one unidentified quantity, how long political drag
lasts.

> Coupling an estimated feasibility frontier into REMIND, we show that the effect of political
> constraints on a 1000 Gt pathway is ordered by a single quantity: the persistence of the political
> drag. This holds whether the price or the budget is held. Persistence sets both the size of the effect
> (22–189 Gt of overshoot; 5–66 Gt of relocated abatement) and its geography: China absorbs relocated
> abatement only when the drag persists. Because persistence cannot be identified from the historical
> record, we report the mapping from assumption to outcome rather than a point estimate.

- **Appeal:** rigorous and honest.
- **Weakness:** it reads as a methods or sensitivity paper. Frame 2 is the same evidence with a question
  attached.

## Frame 4. Where politics binds decides who abates (distributional)

**Pitch:** political ceilings don't just add emissions; they redraw the map of who mitigates.

> When politics caps carbon prices in some regions and the global budget is kept, abatement moves to
> regions whose politics allow higher prices. We show that how much moves depends on how strong the
> political drag is, and where it moves depends on the regional ranking of constraints. Under today's
> politics China absorbs 45 Gt of additional abatement, while emissions rise in the Middle East (+23.7
> Gt), India (+18.4) and other Asian economies (+15.4). If the drag fades with the transition, China's
> extra burden shrinks to 10 Gt.

- **Appeal:** concrete and geopolitical, with a story about equity and burden-sharing.
- **Weakness:**
  - The relocation is small under the deployed setting (23 Gt).
  - The China result depends on the persistence assumption.
  - The binding sector depends on the specification family, so there can be no sector-level claims.
- **Best use:** this works better as the second figure of frame 2 than as a paper of its own.

## Frame 5. The unknowable cost of politics (non-identification as the headline)

**Pitch:** the quantities that matter most for feasible pathways are precisely the ones the data cannot
pin down.

> We estimate what can be estimated about political feasibility — a frontier linking institutions and
> coalitions to carbon-price ceilings — and show that the quantities that drive outcomes in a coupled
> model are declared, not identified: severity and persistence. Together they span 22–189 Gt of
> overshoot. Everything we estimate moves the result less (68–155 Gt across rankings, assignments and
> specifications). We argue that feasibility-constrained scenarios should report these as explicit,
> declared dimensions.

- **Appeal:** a strong methodological message for the modelling community.
- **Weakness:** a negative framing that is hard to sell to Nature Climate Change. It suits a perspective
  or a methods journal better.

## Further alternatives found in the v6 results

A second pass over the v6 outputs finds six more messages. Two of them (A and B) are strong enough to sit
in the abstract of frame 2. The rest are sections, figures or questions.

### A. Persistent politics pushes the peak in cumulative CO₂ past the horizon

- **Message:** under hold-the-price, frozen or slowly fading politics doesn't just add CO₂; cumulative
  CO₂ never peaks by 2150, so net-zero CO₂ is not reached within the model horizon.
- **Evidence** (`coupled-runs.rds`, year cumulative CO₂ peaks):

  | Run | Peak year |
  | --- | --- |
  | θ = 0 run | 2100 |
  | Static drag | never by 2150 (1315 Gt in 2150) |
  | Deployed | never by 2150 (1184 Gt) |
  | κ = 0.02 | 2110 |
  | κ = 0.027 | 2100 |
  | κ = 0.05 | 2100 |

  The overshoot keeps growing after 2100: at the deployed setting, cumulative CO₂ is 1121 Gt in 2100 and
  1184 Gt in 2150, while the θ = 0 run peaks at 1003 Gt.
- **Caveat:** hold-the-price does not enforce the budget by design, and 2150 is the end of the horizon.
- **Fits:** frame 2, as the sharpest form of "assuming politics doesn't change".

### B. The near-term cost of politics is robust; the long-run cost is a bet on political change

- **Message:** before 2050, the effect of the ceilings depends much less on persistence. After 2050,
  persistence decides almost everything.
- **Evidence:**

  | Persistence setting | Hold the price: extra CO₂ by 2050 (Gt) | by 2100 | by 2150 | Hold the budget: moved 2020–2050 (Gt) | moved 2051–2100 |
  | --- | --- | --- | --- | --- | --- |
  | Static | 44.7 | 189.1 | 337.1 | 9.7 | 56.6 |
  | Deployed | 37.4 | 118.2 | 205.2 | 8.8 | 16.7 |
  | κ = 0.02 | 25.2 | 53.5 | 58.9 | 7.5 | 9.4 |
  | κ = 0.027 | 21.6 | 41.2 | 36.6 | 6.8 | 8.9 |
  | κ = 0.05 | 15.2 | 22.1 | 11.2 | 5.4 | 5.7 |

  The spread across persistence settings is 3× by 2050, 9× by 2100 and 30× by 2150 under
  hold-the-price, and 2× before 2050 against 10× after under hold-the-budget. The regional price gap in
  2030 is similar in every setting (SD 0.17–0.24).
- **Fits:** frame 2. It gives the paper a near-term claim (15–45 Gt by 2050) alongside the conditional
  long-run one.

### C. Keeping the budget is affordable; the problem is distribution and timing, not aggregate cost

- **Message:** under hold-the-budget, the budget holds at a global price ×1.26 higher (×1.15 to ×1.42
  over θ 0.325–0.675; ×1.45 with today's politics frozen). The discounted GDP change is +0.035% against
  the null. No region loses more than 0.08% (ESC); with today's politics frozen, no region loses more
  than 0.18% (SSA).
- **Caveat:** this is a welfare-optimising model, and the GDP metric is narrow.
- **Fits:** frame 1's budget horn, or a short section in frame 2.

### D. It is not who is constrained, but how hard and for how long

- **Message:** which regions are politically constrained moves the hold-the-price result by a factor of
  under 2. Persistence moves it 9×.
- **Evidence:** ranking variants (permuted, uniform, reversed) give +68 to +126 Gt, against +22 to +189
  Gt across persistence.
- **Caveat:** the reversed ranking (+67.9 Gt) is a sizeable effect on its own.
- **Fits:** frame 2 or frame 5, as the robustness argument.

### E. An exchange rate between overshoot and price

- **Message:** each step in political severity costs either tonnes (hold the price) or price (hold the
  budget). Over θ 0.325–0.675, +73 to +182 Gt, or a global price ×1.15 to ×1.42.
- **Fits:** frame 1's natural figure, or a supplementary panel elsewhere.

### F. Instrument design: sector-differentiated ceilings recover part of the cost

- **Message:** allowing the political ceiling to differ by market (the per-market markup) recovers about
  41 Gt under hold-the-price (+121 against +163 Gt without it). Under hold-the-budget it lowers the
  global price premium from ×1.35 to ×1.26.
- **Caveat:** which sector binds depends on the specification family, so this cannot be a
  sector-specific claim.
- **Fits:** a discussion point.

### Open questions the v6 results raise (not yet answerable)

- What if politics gets worse than today (backsliding)? The runs are set up (`V6BACK`) and wait for the
  declared rate.
- Does a higher-price, budget-holding world change politics itself? This is the causal feedback, which
  is not identified. It is the next paper, not this one.
- Do the persistence results hold at H12? The ladder is EU21 only, although the deployed H12 runs match
  EU21. The H12 runs are set up (`V6PERSH12`).

## Comparison and recommendation

Frame 2 is the publishable spine. Frames 3–5 and messages A–F become its sections, and frame 1's numbers
become its "deployed" row.

| Frame | Question it answers | Appeal for NCC | Main risk | Extra work |
| --- | --- | --- | --- | --- |
| 1. Budget or price | What gives under political caps? | Medium: familiar, but numbers fragile | Headline moves 5–9× with persistence | None |
| 2. Today's vs tomorrow's politics | Is today's political constraint permanent, and what does assuming so cost? | High: clear question, one headline (71–167 Gt dividend) | Implying policy causes political change | H12 ladder (4 runs); backsliding run (2 runs, rate to declare) |
| 3. Persistence decides | Which unknown drives the result? | Low–medium: reads as sensitivity | Seen as a methods paper | Same as frame 2 |
| 4. Who abates | Where does abatement go? | Medium: geopolitical | Small at deployed setting; no sector claims | None (regional costs now extracted) |
| 5. The unknowable cost | What can and cannot be known? | Low for NCC; good as a perspective | Negative framing | None |

A possible structure for frame 2:

1. The frontier and the two closures.
2. Frozen versus developing politics, under both closures (the persistence ladder, plus message A).
3. What is robust: the near term (message B), and that it is not who but how long (message D).
4. Who abates (frame 4), and the affordability of the budget (message C).
5. What is declared rather than identified (frame 5).

What frame 2 still needs before writing:

- [x] Extract the rule-C global price for the static and κ runs (`persistence-ladder.json`, 2026-10-12).
- [x] Extract extra CO₂ by 2050 under hold-the-price for each persistence setting (message B).
- [x] Extract regional GDP effects under hold-the-budget (message C).
- [ ] Declare the backsliding rate. Proposed: κ = −0.005 a year on today's strength (k = 1.13 in 2050,
  1.45 in 2100). Then run `V6BACK` (2 EU21 runs).
- [ ] Run the persistence ladder at H12: `V6PERSH12`, the static and central-κ runs under both closures
  (4 runs).
- [ ] Choose the spine, then set up `papers/pfm-paper-v6`.
