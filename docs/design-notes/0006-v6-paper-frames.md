# 0006 — v6 paper frames: which question the v6 paper asks

**Status: Open** — the spine is the author's choice. Recommendation: frame 2 (today's politics versus
tomorrow's), led by frame 6's result, with the other frames as its sections.

**Provenance.** Run-Group `v6`, EU21 unless stated, θ = 0.50, 1000 Gt budget. Every number is read from
`output/pfm/v6/coupling/`: `persistence-ladder.json` (`analysis/v6/persistenceLadder.R`),
`coupled-facts.json`, `coupled-costs.json`, `coupled-runs.rds` and `rulec-relocation-decomp.rds`, as of
2026-10-12. The note was drafted as a Claude Doc
(https://claude.ai/code/artifact/101af937-af7a-4318-a328-cc8e2c0e8935); this file is the record. Like
every design note it is not authoritative: re-derive a number from its artifact before quoting it.

**Revisions.** 2026-10-12: first version, five frames and six further messages. Same day: messages A–C
promoted to frames 6–8, an evidence subsection added to every frame, and the estimated range corrected
to 68–164 Gt (it now includes the annual-data variant).

## Purpose and basis

The v6 results support eight paper frames. All of them rest on one finding: a single setting, how long the
political drag lasts, orders every result under both closures. This note sets the frames side by side so
the spine can be chosen. Each frame has a pitch, a draft abstract, the evidence behind it, its appeal and
its weakness.

The common evidence is the persistence ladder. The drag is the political strength k(t) on the
carbon-price ceiling; κ is the declared erosion (ADR 0050).

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

- **H12 matches EU21 on the deployed runs:** +112.8 against +118.2 Gt of extra CO₂, and 19.9 against
  22.7 Gt moved. The ladder itself was run on EU21 only (`V6PERSH12` will add H12).
- **Severity θ** from 0.325 to 0.675 gives +73.0 to +181.5 Gt (hold the price), or a global price ×1.15
  to ×1.42 (hold the budget).
- **The estimated parts span less than the declared ones** (hold the price, extra CO₂ by 2100):

  | Estimated part | Extra CO₂ (Gt) |
  | --- | --- |
  | Ranking permutations | 89–126 |
  | Reversed ranking | 67.9 |
  | Uniform ranking | 105.8 |
  | Assignment band | 110–155 |
  | Frontier shape (sat 0.5, sat 2) | 115–130 |
  | Specification family B | 107.5 |
  | Annual data | 164.4 |

## Frame 1. What gives: the budget or the price (the current spine)

**Pitch:** if politics caps carbon prices, the world has to give up either the budget or the price.

> Cost-optimal mitigation pathways assume carbon prices are politically unconstrained. We estimate a
> feasibility frontier that turns institutions and actor coalitions into a ceiling on carbon-price
> stringency in each region, and couple it into the REMIND model. If governments hold the carbon price
> the ceiling allows, a 1000 Gt pathway emits about 118 Gt more by 2100. If they keep the budget instead,
> the global price must rise by about a quarter, and about 23 Gt of abatement moves from constrained to
> less constrained regions, at negligible aggregate cost. Political feasibility shows up either as
> overshoot or as a higher, redistributed price.

**Evidence.**
- *Hold the price:* `-PFMlevelBfix-v6` against its null `-PFMgateBfix-v6`, which runs θ = 0 on the same
  pinned price path. +118.2 Gt (EU21) and +112.8 Gt (H12) of cumulative CO₂ by 2100.
- *Hold the budget:* `-PFMlevelC-v6` meets the budget (997.7 Gt EU21, 994.6 Gt H12 in 2100). Its 2050
  global price is ×1.259 (EU21) and ×1.251 (H12) that of `-PFMgate-v6`. It moves 22.7 / 19.9 Gt of
  abatement, and changes discounted GDP by +0.035% and consumption by +0.017%.
- *Severity:* θ = 0.325 and 0.675 give +73.0 and +181.5 Gt, or ×1.15 and ×1.42.
- *What it rests on:* the estimated frontier and ranking, θ declared at 0.50, and persistence as
  deployed. The ladder shows the last of these is the decisive and unstated choice.

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

**Evidence.**
- *Frozen politics is a run, not an extrapolation.* `-PFMlevelBfix-Ehold-v6` and `-PFMlevelC-Ehold-v6`
  hold the strength at today's level (k 0.99–1.00 through 2100; the ratio hold, D2 / C5).
- *Developing politics is the deployed k(t).* It is projected from the drivers as fossil coalitions
  shrink with the transition (Bulk 0.69 in 2050, 0.53 in 2100). The κ arms add erosion that was
  declared on 2026-10-08, before any wave-2 run (ADR 0050).
- *The dividend* (static minus each rung, `persistence-ladder.json`):

  | Rung | Hold the price (Gt) | Hold the budget (Gt) |
  | --- | --- | --- |
  | Deployed | 70.9 | 42.9 |
  | κ = 0.02 | 135.6 | 56.1 |
  | κ = 0.027 | 147.9 | 57.2 |
  | κ = 0.05 | 167.0 | 60.3 |

- *Cross-check from v5 → v6.* Holding k restores 42.9 of the 54.0 Gt by which the relocation fell
  (79%). The v5 model behaved like frozen politics.
- *Limits:* the ladder is EU21 only (`V6PERSH12` pending), and the worse-than-today side is not run yet
  (`V6BACK`). The causal feedback from policy to politics is not identified.

- **Appeal:**
  - It gives one headline quantity, the "political dividend" of the transition: 71 Gt from the model's
    own fading alone, and up to 167 Gt with declared erosion.
  - It speaks directly to the literature on feasibility spaces and on policy sequencing and winning
    coalitions, and it critiques static feasibility constraints in scenario work.
  - It is newsworthy without overclaiming.
- **Risk:**
  - The fading strength k(t) comes from the projected drivers, and κ is declared. The paper can say "*if*
    politics develops", not "policy *causes* politics to develop".
  - Wording has to hold that line throughout.
- **Optional extra:** a backsliding arm, where strength rises above today's level, would make the
  comparison two-sided ("better or worse than today"). The coupling accepts a negative κ since
  2026-10-12, and the rows are in the matrix (`V6BACK`). The rate stays at the proposed −0.005 a year
  until it is declared.

## Frame 3. Persistence decides (option B as written)

**Pitch:** the cost of political feasibility hinges on one unidentified quantity, how long political drag
lasts.

> Coupling an estimated feasibility frontier into REMIND, we show that the effect of political
> constraints on a 1000 Gt pathway is ordered by a single quantity: the persistence of the political
> drag. This holds whether the price or the budget is held. Persistence sets both the size of the effect
> (22–189 Gt of overshoot; 5–66 Gt of relocated abatement) and its geography: China absorbs relocated
> abatement only when the drag persists. Because persistence cannot be identified from the historical
> record, we report the mapping from assumption to outcome rather than a point estimate.

**Evidence.**
- *One order, every measure.* Down the ladder, each rung is lower than the one above on all four
  measures: extra CO₂, global price, abatement moved and price gap.
- *Size and direction separate.* Persistence sets the size: holding k accounts for 79% of the v5 → v6
  drop in relocation. The ranking sets the direction: the rank correlation between a region's share φ
  and its relative change in emissions is −0.47 with today's politics frozen and −0.465 as deployed.
- *Not identified.* The estimation fixes the 2023 ranking and the drivers' effect; the future path of
  the drag comes from projections (k) and declarations (κ).

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

**Evidence** (hold the budget, cumulative 2020–2100 against `-PFMgate-v6`, Gt CO₂eq):

| Region | Frozen politics | Deployed | v5 |
| --- | --- | --- | --- |
| China (CHA) | −45.1 (power sector −48.4) | −10.2 | −54.2 |
| Sub-Saharan Africa (SSA) | −7.1 | −3.7 | +30.0 |
| Middle East (MEA) | +23.7 | +7.9 | +25.4 |
| India (IND) | +18.4 | +8.1 | −5.4 |
| Other Asia (OAS) | +15.4 | +2.8 | −5.2 |
| Russia and reforming (REF) | +7.0 | +3.7 | +14.8 |

India and Other Asia abated more in v5 and emit more in v6: the new ranking moves them, as the static run
shows. Under frozen politics, 5 regions emit more and 12 less (deployed: 4 and 10). The binding sector depends on
the specification family: Bulk binds in 15 of 21 regions under family A and 3 of 21 under family B
(`SCENARIOS.md` §6.2a).

- **Appeal:** concrete and geopolitical, with a story about equity and burden-sharing.
- **Weakness:**
  - The relocation is small under the deployed setting (23 Gt).
  - The China result depends on the persistence assumption.
  - There can be no sector-level claims.
- **Best use:** the second figure of frame 2 rather than a paper of its own.

## Frame 5. The unknowable cost of politics (non-identification as the headline)

**Pitch:** the quantities that matter most for feasible pathways are precisely the ones the data cannot
pin down.

> We estimate what can be estimated about political feasibility — a frontier linking institutions and
> coalitions to carbon-price ceilings — and show that the quantities that drive outcomes in a coupled
> model are declared, not identified: severity and persistence. Together they span 22–189 Gt of
> overshoot. Everything we estimate moves the result less (68–164 Gt across rankings, assignments,
> specifications and data frequency). We argue that feasibility-constrained scenarios should report these
> as explicit, declared dimensions.

**Evidence.**
- *Declared:* θ, which gives +73 to +182 Gt over 0.325–0.675, and persistence, which gives +22 to
  +189 Gt across the ladder.
- *Estimated:* every alternative the batch ran (table above), +67.9 to +164.4 Gt. That is a 2.4× range,
  against 2.5× for θ and 8.6× for persistence.
- *Status:* θ and κ are declared in ADR 0050. The frontier, the ranking and the drivers are estimated
  (`MODEL.md`).

- **Appeal:** a strong methodological message for the modelling community.
- **Weakness:** a negative framing that is hard to sell to Nature Climate Change. It suits a perspective
  or a methods journal better.

## Frame 6. Unless politics changes, net zero slips past the horizon (promoted from message A)

**Pitch:** if political ceilings do not erode, holding the politically feasible carbon price never brings
CO₂ to net zero within the model horizon.

> Climate targets are now set as net-zero dates. We couple an estimated feasibility frontier, which caps
> carbon prices where institutions and fossil-fuel coalitions resist, into REMIND, and hold each region to
> the price its politics allows. Without the ceilings, a 1000 Gt pathway reaches net-zero CO₂ around 2100.
> With them, cumulative CO₂ is still rising in 2150 in 21 of 25 model variants, whether politics is frozen
> at today's level or fades as the transition proceeds. Only when the political drag erodes at a declared
> rate does net zero return, around 2100–2110. Whether net zero is reached is decided by whether politics
> changes, not by the carbon price a model would choose.

**Evidence** (`coupled-runs.rds`, the year cumulative CO₂ peaks, at the model's period resolution):

| Run | Peak year | Cumulative CO₂ at the peak (Gt) |
| --- | --- | --- |
| θ = 0 run (held-price null) | 2100 | 1003 |
| Static drag | not by 2150 | 1315 in 2150 |
| Deployed (EU21 / H12) | not by 2150 | 1184 / 1183 in 2150 |
| κ = 0.02 | 2110 | 1058 |
| κ = 0.027 | 2100 | 1044 |
| κ = 0.05 | 2100 | 1025 |

- 21 of the 25 EU21 hold-the-price runs never peak by 2150. The four that do are the three κ arms and
  the reversed ranking (2130). At H12, 5 of 7 never peak (the held-institutions and uniform-ranking runs
  peak in 2130). Even mild severity (θ = 0.325) never peaks (1130 Gt in 2150).
- Under hold-the-budget, the frozen-politics run meets the budget in 2100 (1001 Gt) but is still rising
  in 2150 (1019 Gt).

- **Appeal:** net zero is the currency of climate policy, and the result is a yes/no that holds across
  almost every estimated variant. The only lever that restores it is political change.
- **Weakness:**
  - Hold-the-price is a modelling closure (the null's price path, no budget). "Never" means "not by
    2150", the end of the horizon.
  - Peak years are read at the model's periods (2100, 2110, 2130, 2150).
  - It is a statement about the price path, not about what governments would do after 2100.
- **Best use:** the lead result of frame 2 ("frozen politics means no net zero"), or a spine of its own if
  a net-zero headline is wanted.

## Frame 7. The near-term cost of politics is robust; the long-run cost is a bet on political change (promoted from message B)

**Pitch:** whatever happens to politics, its cost by 2050 is 15–45 Gt; what comes after depends on
whether politics changes.

> Decisions on 2030 and 2050 targets cannot wait for political science to predict how coalitions evolve.
> We show that they do not have to. In a coupled model with an estimated feasibility frontier, political
> ceilings add 15–45 Gt of CO₂ by 2050 however long the political drag lasts. That range is three-fold,
> against nine-fold by 2100 and thirty-fold by 2150. If the 1000 Gt budget is held instead, 5–10 Gt of
> abatement moves between regions before 2050 in every setting, against 6–57 Gt afterwards. The near-term
> cost of political feasibility is a planning quantity; the long-run cost is a bet on political change.

**Evidence** (`persistence-ladder.json`):

| Persistence setting | Hold the price: extra CO₂ by 2050 (Gt) | by 2100 | by 2150 | Hold the budget: moved 2020–2050 (Gt) | moved 2051–2100 |
| --- | --- | --- | --- | --- | --- |
| Static | 44.7 | 189.1 | 337.1 | 9.7 | 56.6 |
| Deployed | 37.4 | 118.2 | 205.2 | 8.8 | 16.7 |
| κ = 0.02 | 25.2 | 53.5 | 58.9 | 7.5 | 9.4 |
| κ = 0.027 | 21.6 | 41.2 | 36.6 | 6.8 | 8.9 |
| κ = 0.05 | 15.2 | 22.1 | 11.2 | 5.4 | 5.7 |

The regional price gap in 2030 is similar in every setting (SD 0.17–0.24). At H12, the deployed run adds
34.6 Gt by 2050 (EU21 37.4).

- **Appeal:** decision-relevant for near-term targets (NDCs, 2050), with a robust claim next to a
  conditional one.
- **Weakness:** part of the near-term robustness is built in. Both k and the κ fade start from k(2025) =
  1, so the rungs can only diverge with time. The paper must say so, and quote the 2050 spread (3×)
  rather than call it negligible.
- **Best use:** a section of frame 2 (what is robust), or the policy-facing summary.

## Frame 8. The budget survives politics (promoted from message C)

**Pitch:** political ceilings do not break the 1000 Gt budget; they make it dearer and move it between
regions.

> Political resistance to carbon pricing is often read as a reason to abandon ambitious budgets. We test
> this in a coupled model where an estimated feasibility frontier caps each region's carbon price. When
> the global budget is held, every variant meets it. The global price rises by about a quarter (by 45%
> if today's politics never changes), and aggregate output barely moves (+0.035% of discounted GDP). No
> region loses more than 0.2% of GDP. What politics changes is who abates and when, not whether the
> budget can be met.

**Evidence.**
- *Every hold-the-budget run meets the budget:* 989–1001 Gt in 2100 across the EU21 rule-C runs and
  994.6 Gt at H12.
- *Global price in 2050 against `-PFMgate-v6`:* ×1.26 deployed; ×1.15–1.42 over θ; ×1.45 frozen;
  ×1.05–1.13 under declared erosion. With one price across markets (markup off), ×1.35.
- *Costs* (`coupled-costs.json`):

  | Run | Discounted GDP (%) | Consumption (%) | Worst region (GDP %) |
  | --- | --- | --- | --- |
  | Deployed | +0.035 | +0.017 | ESC, −0.08 |
  | Frozen | +0.005 | +0.010 | SSA, −0.18 |

- *Caveat from the runs:* the frozen-politics run meets the budget in 2100 but is still rising in 2150
  (frame 6).

- **Appeal:** a positive, policy-relevant counterpoint that answers "is the budget still feasible?"
- **Weakness:**
  - REMIND is welfare-optimising and the GDP metric is narrow.
  - The closure assumes that the less constrained regions accept the higher price. This is consistent
    with their own ceilings, which do not bind, but not a political prediction.
  - The burden lands on particular regions (frame 4).
- **Best use:** the hold-the-budget half of frame 1 or frame 2, paired with frame 4.

## Supporting messages (not frames)

Messages A–C of the first version are now frames 6–8. The three below support a frame but cannot carry
one.

### D. It is not who is constrained, but how hard and for how long

- **Message:** which regions are politically constrained moves the hold-the-price result by a factor of
  under 2; persistence moves it 9×.
- **Evidence:** ranking variants (permuted, uniform, reversed) give +68 to +126 Gt, against +22 to +189 Gt
  across persistence.
- **Caveat:** the reversed ranking (+67.9 Gt) is a sizeable effect on its own.
- **Fits:** frame 2 or frame 5, as the robustness argument.

### E. An exchange rate between overshoot and price

- **Message:** each step in political severity costs either tonnes (hold the price) or price (hold the
  budget). Over θ 0.325–0.675: +73 to +182 Gt, or a global price ×1.15 to ×1.42.
- **Fits:** frame 1's natural figure, or a supplementary panel elsewhere.

### F. Instrument design: sector-differentiated ceilings recover part of the cost

- **Message:** letting the political ceiling differ by market (the per-market markup) recovers about
  41 Gt under hold-the-price (+121 against +163 Gt without it). Under hold-the-budget it lowers the global
  price premium from ×1.35 to ×1.26.
- **Caveat:** which sector binds depends on the specification family, so this cannot be a sector-specific
  claim.
- **Fits:** a discussion point.

### Open questions the v6 results raise (not yet answerable)

- What if politics gets worse than today (backsliding)? The runs are set up (`V6BACK`) and wait for the
  declared rate.
- Does a higher-price, budget-holding world change politics itself? This is the causal feedback, which
  is not identified. It is the next paper, not this one.
- Do the persistence results hold at H12? The deployed H12 runs match EU21. The H12 ladder runs are set up
  (`V6PERSH12`).

## Comparison and recommendation

Frame 2 is the publishable spine, and frame 6 gives it its sharpest headline: frozen politics means no net
zero within the horizon. Frames 7 and 8 are its robust near-term claim and its hold-the-budget
counterpart; frames 3–5 and messages D–F are its sections and robustness. Frame 1's numbers become the
"deployed" row.

| Frame | Question it answers | Appeal for NCC | Main risk | Extra work |
| --- | --- | --- | --- | --- |
| 1. Budget or price | What gives under political caps? | Medium: familiar, but numbers fragile | Headline moves 5–9× with persistence | None |
| 2. Today's vs tomorrow's politics | Is today's political constraint permanent, and what does assuming so cost? | High: clear question, one headline (71–167 Gt dividend) | Implying policy causes political change | H12 ladder (4 runs); backsliding (2 runs, rate to declare) |
| 3. Persistence decides | Which unknown drives the result? | Low–medium: reads as sensitivity | Seen as a methods paper | Same as frame 2 |
| 4. Who abates | Where does abatement go? | Medium: geopolitical | Small at deployed setting; no sector claims | None |
| 5. The unknowable cost | What can and cannot be known? | Low for NCC; good as a perspective | Negative framing | None |
| 6. Net zero slips | Does political resistance put net zero out of reach? | High: net zero is the policy currency; holds in 21 of 25 variants | Held-price closure and the 2150 horizon | H12 ladder confirms it at H12 |
| 7. Robust near term | What can be said now, whatever politics does? | Medium–high: decision-relevant | Robustness partly built in (k(2025) = 1) | Extra CO₂ by 2050 at H12 (from `V6PERSH12`) |
| 8. The budget survives | Is the budget still feasible under political caps? | Medium–high: positive message | Welfare-optimal closure; burden shifts to regions | None |

A possible structure for frame 2:

1. The frontier and the two closures.
2. Frozen versus developing politics, under both closures: the persistence ladder, led by frame 6.
3. What is robust: the near term (frame 7), and that it is not who but how long (message D).
4. Who abates (frame 4), and that the budget survives at a price (frame 8).
5. What is declared rather than identified (frame 5).

What frame 2 still needs before writing:

- [x] Extract the rule-C global price for the static and κ runs (`persistence-ladder.json`, 2026-10-12).
- [x] Extract extra CO₂ by 2050 under hold-the-price for each persistence setting (frame 7).
- [x] Extract regional GDP effects under hold-the-budget (frame 8).
- [ ] Declare the backsliding rate (kept at the proposed κ = −0.005 a year for now: k = 1.13 in 2050,
  1.45 in 2100). Then run `V6BACK` (2 EU21 runs).
- [ ] Run the persistence ladder at H12: `V6PERSH12`, the static and central-κ runs under both closures
  (4 runs).
- [ ] Choose the spine, then set up `papers/pfm-paper-v6`.
