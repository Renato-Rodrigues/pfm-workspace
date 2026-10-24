# 0006 — v6 paper frames: which question the v6 paper asks

**Status: Open** — the spine is the author's choice. Recommendation: *Today vs tomorrow*, led by the
result of *Net zero slips*, with the other frames as its sections.

> **Re-read on `v7` (2026-10-25): see the last section.** The paper is now on Run-Group `v7` (ADR 0059, 0060).

**Provenance.** Run-Group `v6`, EU21 unless stated, θ = 0.50, 1000 Gt budget. Every number is read from
`output/pfm/v6/coupling/`: `persistence-ladder.json` (`analysis/v6/persistenceLadder.R`),
`coupled-facts.json`, `coupled-costs.json`, `coupled-runs.rds` and `rulec-relocation-decomp.rds`, as of
2026-10-12. The note was drafted as a Claude Doc
(https://claude.ai/code/artifact/101af937-af7a-4318-a328-cc8e2c0e8935); this file is the record. Like
every design note it is not authoritative: re-derive a number from its artifact before quoting it.

**Revisions.** 2026-10-12: first version, five frames and six further messages. Same day: three of the
messages promoted to frames (*Net zero slips*, *Robust now, a bet later*, *The budget survives*), an
evidence subsection added to every frame, and the estimated range corrected to 68–164 Gt (it now
includes the annual-data variant). Same day: every frame rests on `v6` results only, since the paper
does not report the earlier model version (author, 2026-10-12; 0005 §7b). Same day: frames and messages
named instead of numbered, and the project labels renamed (`SCENARIOS.md` §2.6; the old labels are
listed in `../_archive/_wip/LABELS-2026-10-12.md`). 2026-10-13: `V6PERSH12` and `V6BACK` landed; the growing
limit and the ladder at H12 are added (71 runs, all admitted).

## Purpose and basis

The v6 results support eight paper frames. All of them rest on one finding: a single setting, how long the
political limit lasts, orders every result under both closures (hold the price, hold the budget). This
note sets the frames side by side so the spine can be chosen. Each frame has a pitch, a draft abstract,
the evidence behind it, its appeal and its weakness.

The common evidence is the persistence ladder. The limit is the political strength k(t) on the
carbon-price ceiling; κ is the erosion rate (ADR 0050).

| How long the limit lasts | k, power & industry (2050 → 2100) | Hold the price: extra CO₂ by 2100 (Gt) | Hold the budget: global price 2050 (× θ = 0 run) | Hold the budget: abatement moved (Gt CO₂eq) | Regional price gap, 2100 (SD) |
| --- | --- | --- | --- | --- | --- |
| Growing limit: tightens 0.5% a year (κ = −0.005, declared, ADR 0057) | 1.12 → 1.45 | +245.3 | ×1.64 | 97.5 | 0.271 |
| Constant limit: today's limit kept | 0.99 → 1.00 | +189.1 | ×1.45 | 65.6 | 0.138 |
| Fading limit: weakens with the transition (headline) | 0.69 → 0.53 | +118.2 | ×1.26 | 22.7 | 0.081 |
| Fading + erosion 2% a year (κ = 0.02) | 0.40 → 0.11 | +53.5 | ×1.13 | 9.5 | 0.014 |
| Fading + erosion 2.7% a year (κ = 0.027) | 0.33 → 0.06 | +41.2 | ×1.10 | 8.4 | 0.008 |
| Fading + erosion 5% a year (κ = 0.05) | 0.18 → 0.01 | +22.1 | ×1.05 | 5.3 | 0.001 |

**A robustness caveat on the fading limit (2026-10-13, design note 0007).** The power & industry relaxation behind the
fading-limit row rests partly on countries at the edge of the institutional data. The interest × institution
interactions are linear and are evaluated far from the sample for China and Saudi Arabia, so they can reverse a
driver's direction. Offline, on the coupled hold-the-price energy system (`output/pfm/v6/edge-options.rds`), the 2050
power & industry k is:

| Variant | Power & industry k, 2050 |
| --- | --- |
| as run | 0.68 |
| interactions capped at the sample's 5th–95th percentiles | 0.75 |
| interactions in democracies only (regime split, threshold 0.35–0.6) | 0.71–0.77 |
| edge countries' ceilings held at 2025 | 0.79 |
| no interactions | 0.93 |
| refit without China, Saudi Arabia, Turkey and Russia | 0.95 |

The extra CO₂ under hold the price follows k, so the fading-limit numbers carry this sensitivity until it is re-run
coupled. Whichever frame is chosen must quote it, and must not interpret the regional positions of China (buildings &
transport), the Middle East or India.

k is shown for the hold-the-price runs. The hold-the-budget runs settle a little lower (fading limit
0.62 → 0.50). The growing limit ran at κ = −0.005 a year (`V6BACK`), declared on 2026-10-13 as a bound (ADR 0057).

Other quantities the frames cite:

- **H12 matches EU21 on the fading-limit runs:** +112.8 against +118.2 Gt of extra CO₂, and 19.9 against
  22.7 Gt moved. **The ladder holds at H12** (`V6PERSH12`): hold the price +176.3 / +112.8 / +39.3 Gt
  (constant limit / fading / erosion 2.7%) against +189.1 / +118.2 / +41.2 at EU21; hold the budget ×1.42 /
  ×1.25 / ×1.10 and 60.1 / 19.9 / 9.3 Gt moved (EU21 ×1.45 / ×1.26 / ×1.10; 65.6 / 22.7 / 8.4).
- **Severity θ** from 0.325 to 0.675 gives +73.0 to +181.5 Gt (hold the price), or a global price ×1.15
  to ×1.42 (hold the budget).
- **The estimated parts span less than the declared ones** (hold the price, extra CO₂ by 2100):

  | Estimated part | Extra CO₂ (Gt) |
  | --- | --- |
  | Ranking permutations | 89–126 |
  | Reversed ranking | 67.9 |
  | Uniform ranking | 105.8 |
  | Assignment band | 110–155 |
  | Frontier shape (saturation 0.5×, 2×) | 115–130 |
  | Specification: only clean-energy interests saturate | 107.5 |
  | Annual data | 164.4 |

## Budget or price: what gives, the budget or the price (the current spine)

**Pitch:** if politics caps carbon prices, the world has to give up either the budget or the price.

> Cost-optimal mitigation pathways assume carbon prices are politically unconstrained. We estimate a
> feasibility frontier that turns institutions and actor coalitions into a ceiling on carbon-price
> stringency in each region, and couple it into the REMIND model. If governments hold the carbon price
> the ceiling allows, a 1000 Gt pathway emits about 118 Gt more by 2100. If they keep the budget instead,
> the global price must rise by about a quarter, and about 23 Gt of abatement moves from constrained to
> less constrained regions, at negligible aggregate cost. Political feasibility shows up either as
> overshoot or as a higher, redistributed price.

**Evidence.**
- *Hold the price:* `-PFMlevelBfix-v6` against its no-politics reference `-PFMgateBfix-v6`, which runs
  θ = 0 on the same pinned price path. +118.2 Gt (EU21) and +112.8 Gt (H12) of cumulative CO₂ by 2100.
- *Hold the budget:* `-PFMlevelC-v6` meets the budget (997.7 Gt EU21, 994.6 Gt H12 in 2100). Its 2050
  global price is ×1.259 (EU21) and ×1.251 (H12) that of `-PFMgate-v6`. It moves 22.7 / 19.9 Gt of
  abatement, and changes discounted GDP by +0.035% and consumption by +0.017%.
- *Severity:* θ = 0.325 and 0.675 give +73.0 and +181.5 Gt, or ×1.15 and ×1.42.
- *What it rests on:* the estimated frontier and ranking, θ declared at 0.50, and the fading limit as the
  persistence setting. The ladder shows the last of these is the decisive and unstated choice.

- **Appeal:** familiar to modellers, with clean headline numbers.
- **Weakness:**
  - The numbers change 5–9× with the persistence assumption, so a referee will ask "under which
    persistence?"
  - The hold-the-budget result is small (23 Gt moved).
  - It treats persistence as a robustness check, although persistence is the main condition on both
    numbers.

## Today vs tomorrow: today's politics versus tomorrow's (persistence, made concrete)

**Pitch:** scenarios that build in today's political constraints overstate the cost of politics, because
those constraints erode as the transition proceeds.

> Mitigation scenarios increasingly include political feasibility, usually as constraints calibrated to
> present-day politics. We ask what happens if those constraints are not permanent. Our estimated
> feasibility frontier links the ceiling on carbon prices to institutions and to the strength of
> fossil-fuel coalitions. Coupled into REMIND, it compares a world that keeps today's politics with one
> whose politics develop as the energy transition proceeds.
>
> If today's political limit is kept, holding the politically feasible price adds 189 Gt to a 1000 Gt
> pathway, about a fifth of the budget. Keeping the budget instead moves 66 Gt of abatement between
> regions, mostly onto China. When the political limit weakens as the transition shrinks fossil-fuel
> coalitions, these fall to 118 Gt and 23 Gt. With faster erosion they fall to 22 Gt and 5 Gt; if politics
> instead grows worse than today, they rise to 245 Gt and 98 Gt. Most of the cost of political feasibility is
> the cost of assuming politics does not change.

**Evidence.**
- *The constant limit is a run, not an extrapolation.* `-PFMlevelBfix-Ehold-v6` and `-PFMlevelC-Ehold-v6`
  hold the strength at today's level (k 0.99–1.00 through 2100; the share held, D2 / C5).
- *Developing politics is the fading limit k(t).* It is projected from the drivers as fossil coalitions
  shrink with the transition (power & industry 0.69 in 2050, 0.53 in 2100). The κ sensitivity runs add
  erosion that was declared on 2026-10-08, before any second-batch run (ADR 0050).
- *The dividend* (constant limit minus each case, `persistence-ladder.json`):

  | Case | Hold the price (Gt) | Hold the budget (Gt) |
  | --- | --- | --- |
  | Growing limit | −56.2 | −31.9 |
  | Fading limit | 70.9 | 42.9 |
  | Fading + erosion 2% a year | 135.6 | 56.1 |
  | Fading + erosion 2.7% a year | 147.9 | 57.2 |
  | Fading + erosion 5% a year | 167.0 | 60.3 |

- *Strength, not ranking.* The constant-limit and fading-limit runs share the ranking and differ only in
  the strength. Abatement moved is 65.6 against 22.7 Gt, and the 2100 regional price gap 0.138 against
  0.081.
- *Limits:* the ladder holds at H12 (constant limit +176.3, fading +112.8, erosion 2.7% +39.3 Gt). The
  worse-than-today side is a bound at a declared rate (growing limit, +245.3 Gt; ADR 0057). The causal
  feedback from policy to politics is not identified.

- **Appeal:**
  - It gives one headline quantity, the "political dividend" of the transition: 71 Gt from the model's
    own fading alone, and up to 167 Gt with erosion.
  - It speaks directly to the literature on feasibility spaces and on policy sequencing and winning
    coalitions, and it critiques static feasibility constraints in scenario work.
  - It is newsworthy without overclaiming.
- **Risk:**
  - The fading limit k(t) comes from the projected drivers, and κ is declared. The paper can say "*if*
    politics develops", not "policy *causes* politics to develop".
  - Wording has to hold that line throughout.
- **Two-sided now:** the growing-limit run (`V6BACK`, the limit tightening 0.5% a year) adds +245.3 Gt under
  hold the price, 56 Gt above the constant limit, and under hold the budget a global price ×1.64 with 97.5 Gt
  moved. The rate (−0.005 a year) is declared as a bound (ADR 0057): the fastest the share formula represents at the highest severity.

## Persistence decides: the cost hinges on how long the limit lasts

**Pitch:** the cost of political feasibility hinges on one unidentified quantity, how long the political
limit lasts.

> Coupling an estimated feasibility frontier into REMIND, we show that the effect of political
> constraints on a 1000 Gt pathway is ordered by a single quantity: the persistence of the political
> limit. This holds whether the price or the budget is held. Persistence sets both the size of the effect
> (22–245 Gt of overshoot; 5–98 Gt of relocated abatement) and its geography: China absorbs relocated
> abatement only when the limit persists. Because persistence cannot be identified from the historical
> record, we report the mapping from assumption to outcome rather than a point estimate.

**Evidence.**
- *One order, every measure.* Down the ladder, each case is lower than the one above on all four
  measures: extra CO₂, global price, abatement moved and price gap.
- *Size and direction separate.* Persistence sets the size: the constant-limit and fading-limit runs
  share the ranking, and the abatement moved is 65.6 against 22.7 Gt. The ranking sets the direction: the
  rank correlation between a region's share φ and its relative change in emissions is −0.47 under the
  constant limit and −0.465 under the fading limit.
- *Not identified.* The estimation fixes the 2023 ranking and the drivers' effect; the future path of
  the limit comes from projections (k) and declarations (κ).

- **Appeal:** rigorous and honest.
- **Weakness:** it reads as a methods or sensitivity paper. *Today vs tomorrow* is the same evidence with
  a question attached.

## Who abates: where politics binds decides who abates (distributional)

**Pitch:** political ceilings don't just add emissions; they redraw the map of who mitigates.

> When politics caps carbon prices in some regions and the global budget is kept, abatement moves to
> regions whose politics allow higher prices. We show that how much moves depends on how strong the
> political limit is, and where it moves depends on the regional ranking of constraints. Under today's
> politics China absorbs 45 Gt of additional abatement, while emissions rise in the Middle East (+23.7
> Gt), India (+18.4) and other Asian economies (+15.4). If the limit fades with the transition, China's
> extra burden shrinks to 10 Gt.

**Evidence** (hold the budget, cumulative 2020–2100 against `-PFMgate-v6`, Gt CO₂eq):

| Region | Constant limit | Fading limit | Fading + erosion 2.7% |
| --- | --- | --- | --- |
| China (CHA) | −45.1 (power sector −48.4) | −10.2 | −1.0 |
| Sub-Saharan Africa (SSA) | −7.1 | −3.7 | −2.4 |
| Middle East (MEA) | +23.7 | +7.9 | −2.8 |
| India (IND) | +18.4 | +8.1 | +3.2 |
| Other Asia (OAS) | +15.4 | +2.8 | −0.2 |
| Russia and reforming (REF) | +7.0 | +3.7 | +2.5 |

The constant and fading limits send the extra emissions to the same regions, in different amounts. With
erosion little moves at all (8.4 Gt), and the Middle East and Other Asia turn to abating more. Under the
constant limit, 5 regions emit more and 12 less (fading limit: 4 and 10). The binding sector depends on
the specification: power & industry binds in 15 of 21 regions when clean-energy and fossil interests both
saturate, and in 3 of 21 when only clean-energy interests saturate (`SCENARIOS.md` §6.2a).

- **Appeal:** concrete and geopolitical, with a story about equity and burden-sharing.
- **Weakness:**
  - The relocation is small under the fading limit (23 Gt).
  - The China result depends on the persistence assumption.
  - The ranks it rests on are edge-affected (0007): capping the interactions moves the Middle East from 0.92 to 0.37
    and India from 1.00 to 0.87 in power & industry, and China from most to least constrained in buildings &
    transport. Of the frames, this is the most exposed.
  - There can be no sector-level claims.
- **Best use:** the second figure of *Today vs tomorrow* rather than a paper of its own.

## The unknowable cost: the cost of politics cannot be estimated (non-identification as the headline)

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

## Net zero slips: unless politics changes, net zero slips past the horizon

**Pitch:** if political ceilings do not erode, holding the politically feasible carbon price never brings
CO₂ to net zero within the model horizon.

> Climate targets are now set as net-zero dates. We couple an estimated feasibility frontier, which caps
> carbon prices where institutions and fossil-fuel coalitions resist, into REMIND, and hold each region to
> the price its politics allows. Without the ceilings, a 1000 Gt pathway reaches net-zero CO₂ around 2100.
> With them, cumulative CO₂ is still rising in 2150 in 22 of 26 model variants, whether today's political
> limit is kept or fades as the transition proceeds. Only when the political limit erodes at a declared
> rate does net zero return, around 2100–2110. Whether net zero is reached is decided by whether politics
> changes, not by the carbon price a model would choose.

**Evidence** (`coupled-runs.rds`, the year cumulative CO₂ peaks, at the model's period resolution):

| Run | Peak year | Cumulative CO₂ at the peak (Gt) |
| --- | --- | --- |
| No-politics reference (θ = 0), price held | 2100 | 1003 |
| Growing limit | not by 2150 | 1505 in 2150 |
| Constant limit | not by 2150 | 1315 in 2150 |
| Fading limit (EU21 / H12) | not by 2150 | 1184 / 1183 in 2150 |
| Fading + erosion 2% a year | 2110 | 1058 |
| Fading + erosion 2.7% a year | 2100 | 1044 |
| Fading + erosion 5% a year | 2100 | 1025 |

- 22 of the 26 EU21 hold-the-price runs never peak by 2150. The four that do are the three erosion runs
  and the reversed ranking (2130). At H12, 6 of 9 never peak (the erosion run peaks in 2100, the
  fixed-institutions and uniform-ranking runs in 2130). Even mild severity (θ = 0.325) never peaks (1130 Gt in 2150).
- Under hold the budget, the constant-limit run meets the budget in 2100 (1001 Gt) but is still rising
  in 2150 (1019 Gt; H12 1017 Gt), and so is the growing-limit run (1000 Gt in 2100, 1037 Gt in 2150).

- **Appeal:** net zero is the currency of climate policy, and the result is a yes/no that holds across
  almost every estimated variant. The only lever that restores it is political change.
- **Weakness:**
  - Hold the price is a modelling closure (the no-politics reference's price path, no budget). "Never"
    means "not by 2150", the end of the horizon.
  - Peak years are read at the model's periods (2100, 2110, 2130, 2150).
  - It is a statement about the price path, not about what governments would do after 2100.
- **Best use:** the lead result of *Today vs tomorrow* ("if today's limit is kept, there is no net
  zero"), or a spine of its own if a net-zero headline is wanted.

## Robust now, a bet later: the near-term cost of politics is robust; the long-run cost is a bet on political change

**Pitch:** whatever happens to politics, its cost by 2050 is 15–45 Gt; what comes after depends on
whether politics changes.

> Decisions on 2030 and 2050 targets cannot wait for political science to predict how coalitions evolve.
> We show that they do not have to. In a coupled model with an estimated feasibility frontier, political
> ceilings add 15–45 Gt of CO₂ by 2050 however long the political limit lasts. That range is three-fold,
> against nine-fold by 2100 and thirty-fold by 2150. If the 1000 Gt budget is held instead, 5–10 Gt of
> abatement moves between regions before 2050 in every setting, against 6–57 Gt afterwards. The near-term
> cost of political feasibility is a planning quantity; the long-run cost is a bet on political change.

**Evidence** (`persistence-ladder.json`):

| Persistence case | Hold the price: extra CO₂ by 2050 (Gt) | by 2100 | by 2150 | Hold the budget: moved 2020–2050 (Gt) | moved 2051–2100 |
| --- | --- | --- | --- | --- | --- |
| Growing limit | 51.4 | 245.3 | 526.7 | 10.4 | 87.1 |
| Constant limit | 44.7 | 189.1 | 337.1 | 9.7 | 56.6 |
| Fading limit | 37.4 | 118.2 | 205.2 | 8.8 | 16.7 |
| Fading + erosion 2% a year | 25.2 | 53.5 | 58.9 | 7.5 | 9.4 |
| Fading + erosion 2.7% a year | 21.6 | 41.2 | 36.6 | 6.8 | 8.9 |
| Fading + erosion 5% a year | 15.2 | 22.1 | 11.2 | 5.4 | 5.7 |

The ranges quoted above use the declared cases; the growing limit, a bound at its declared rate, widens the 2050 range
only to 15–51 Gt, and the 2100 range to 22–245 Gt. The regional price gap in 2030 is similar in every case
(SD 0.17–0.24). At H12 the 2050 figures are +43.3 / +34.6 / +20.3 Gt (constant limit / fading / erosion
2.7%; EU21 +44.7 / +37.4 / +21.6).

- **Appeal:** decision-relevant for near-term targets (NDCs, 2050), with a robust claim next to a
  conditional one.
- **Weakness:** part of the near-term robustness is built in. Both k and the erosion start from
  k(2025) = 1, so the cases can only diverge with time. The paper must say so, and quote the 2050 spread
  (3×) rather than call it negligible.
- **Best use:** a section of *Today vs tomorrow* (what is robust), or the policy-facing summary.

## The budget survives: political ceilings make the budget dearer, not impossible

**Pitch:** political ceilings do not break the 1000 Gt budget; they make it dearer and move it between
regions.

> Political resistance to carbon pricing is often read as a reason to abandon ambitious budgets. We test
> this in a coupled model where an estimated feasibility frontier caps each region's carbon price. When
> the global budget is held, every variant meets it. The global price rises by about a quarter (by 45%
> if today's politics never changes, by 64% if it grows worse), and aggregate output barely moves (+0.035% of discounted GDP). No
> region loses more than 0.2% of GDP. What politics changes is who abates and when, not whether the
> budget can be met.

**Evidence.**
- *Every hold-the-budget run meets the budget:* 989–1001 Gt in 2100 across the EU21 hold-the-budget runs
  and 994.6 Gt at H12.
- *Global price in 2050 against `-PFMgate-v6`:* ×1.26 under the fading limit; ×1.15–1.42 over θ; ×1.45
  under the constant limit; ×1.64 under the growing limit; ×1.05–1.13 with erosion. With one price across markets (markup off), ×1.35.
- *Costs* (`coupled-costs.json`):

  | Run | Discounted GDP (%) | Consumption (%) | Worst region (GDP %) |
  | --- | --- | --- | --- |
  | Fading limit | +0.035 | +0.017 | ESC, −0.08 |
  | Constant limit | +0.005 | +0.010 | SSA, −0.18 |
  | Growing limit | −0.021 | −0.034 | SSA, −0.24 |

- *Caveat from the runs:* the constant-limit run meets the budget in 2100 but is still rising in 2150
  (*Net zero slips*).

- **Appeal:** a positive, policy-relevant counterpoint that answers "is the budget still feasible?"
- **Weakness:**
  - REMIND is welfare-optimising and the GDP metric is narrow.
  - The closure assumes that the less constrained regions accept the higher price. This is consistent
    with their own ceilings, which do not bind, but not a political prediction.
  - The burden lands on particular regions (*Who abates*).
- **Best use:** the hold-the-budget half of *Budget or price* or *Today vs tomorrow*, paired with *Who
  abates*.

## Supporting messages (not frames)

Three messages of the first version are now frames (*Net zero slips*, *Robust now, a bet later*, *The
budget survives*). The three below support a frame but cannot carry one.

### How hard and how long, not who

- **Message:** which regions are politically constrained moves the hold-the-price result by a factor of
  under 2; persistence moves it 9×.
- **Evidence:** ranking variants (permuted, uniform, reversed) give +68 to +126 Gt, against +22 to +189 Gt
  across persistence.
- **Caveat:** the reversed ranking (+67.9 Gt) is a sizeable effect on its own.
- **Fits:** *Today vs tomorrow* or *The unknowable cost*, as the robustness argument.

### Overshoot–price exchange rate

- **Message:** each step in political severity costs either tonnes (hold the price) or price (hold the
  budget). Over θ 0.325–0.675: +73 to +182 Gt, or a global price ×1.15 to ×1.42.
- **Fits:** the natural figure of *Budget or price*, or a supplementary panel elsewhere.

### Sector-specific ceilings: they recover part of the cost

- **Message:** letting the political ceiling differ by market (the per-market markup) recovers about
  41 Gt under hold the price (+121 against +163 Gt without it). Under hold the budget it lowers the global
  price premium from ×1.35 to ×1.26.
- **Caveat:** which sector binds depends on the specification, so this cannot be a sector-specific
  claim.
- **Fits:** a discussion point.

### Open questions the v6 results raise (not yet answerable)

- What if politics gets worse than today? Answered as a bound at a declared rate (growing limit, +245.3 Gt; ×1.64 and
  97.5 Gt moved; ADR 0057).
- Does a higher-price, budget-holding world change politics itself? This is the causal feedback, which
  is not identified. It is the next paper, not this one.
- Do the persistence results hold at H12? Yes: the constant-limit, fading and erosion-2.7% cases at H12 are
  within 7% of EU21 under hold the price, and in the same order under hold the budget (`V6PERSH12`).

## Comparison and recommendation

*Today vs tomorrow* is the publishable spine, and *Net zero slips* gives it its sharpest headline: if
today's limit is kept, there is no net zero within the horizon. *Robust now, a bet later* and *The budget
survives* are its robust near-term claim and its hold-the-budget counterpart; *Persistence decides*, *Who
abates*, *The unknowable cost* and the three supporting messages are its sections and robustness. The
numbers of *Budget or price* become the fading-limit row.

| Frame | Question it answers | Appeal for NCC | Main risk | Extra work |
| --- | --- | --- | --- | --- |
| Budget or price | What gives under political caps? | Medium: familiar, but numbers fragile | Headline moves 5–9× with persistence | None |
| Today vs tomorrow | Is today's political constraint permanent, and what does assuming so cost? | High: clear question, one headline (71–167 Gt dividend) | Implying policy causes political change | Declare the growing-limit rate |
| Persistence decides | Which unknown drives the result? | Low–medium: reads as sensitivity | Seen as a methods paper | Same as *Today vs tomorrow* |
| Who abates | Where does abatement go? | Medium: geopolitical | Small under the fading limit; no sector claims | None |
| The unknowable cost | What can and cannot be known? | Low for NCC; good as a perspective | Negative framing | None |
| Net zero slips | Does political resistance put net zero out of reach? | High: net zero is the policy currency; holds in 22 of 26 variants | The hold-the-price closure and the 2150 horizon | None: holds at H12 (6 of 9) |
| Robust now, a bet later | What can be said now, whatever politics does? | Medium–high: decision-relevant | Robustness partly built in (k(2025) = 1) | None: holds at H12 |
| The budget survives | Is the budget still feasible under political caps? | Medium–high: positive message | Welfare-optimal closure; burden shifts to regions | None |

A possible structure for *Today vs tomorrow*:

1. The frontier and the two closures.
2. Today's limit kept versus developing politics, under both closures: the persistence ladder, led by
   *Net zero slips*.
3. What is robust: the near term (*Robust now, a bet later*), and that it is how hard and how long, not
   who.
4. Who abates, and that the budget survives at a price.
5. What is declared rather than identified (*The unknowable cost*).

What *Today vs tomorrow* still needs before writing:

- [x] Extract the hold-the-budget global price for the constant-limit and erosion runs
  (`persistence-ladder.json`, 2026-10-12).
- [x] Extract extra CO₂ by 2050 under hold the price for each persistence case (*Robust now, a bet
  later*).
- [x] Extract regional GDP effects under hold the budget (*The budget survives*).
- [x] Run `V6BACK` at the proposed rate, since declared (2026-10-13).
- [x] Declare the growing-limit rate: κ = −0.005 a year (k = 1.12 in 2050, 1.45 in 2100), as a bound (ADR 0057,
  2026-10-13).
- [x] Run the persistence ladder at H12: `V6PERSH12` (2026-10-13).
- [x] Set up `papers/pfm-paper-v6` without the `v5` draft, Methods written (2026-10-13).
- [ ] Choose the spine; then the claim in its `paper.yml`, the claims ledger and the design.
- [ ] Carry the edge-of-data sensitivity (0007 §6) into the claims ledger: the fading-limit headline with the
  power & industry k range above. Decide whether a coupled re-run of the capped variant (O1) is needed before
  submission or is reported as an offline sensitivity.

## Re-read on `v7` (2026-10-25)

The paper moved to Run-Group `v7`. Every frame above rests on `v6` numbers; this section says which survive, from the
first `v7` batch (`output/pfm/v7/coupling/coupled-facts.json`, `coupled-costs.json`, `coupled-runs.rds`; θ = 0.50).

| Frame | On `v7` | Evidence (EU21 / H12) |
| --- | --- | --- |
| Net zero slips | **holds** | 11 of the 12 political hold-the-price runs still rising in 2150 (only EU21 θ 0.325 peaks, in 2130); fading limit 1168 / 1153 Gt in 2150 (v6 1184 / 1183); no-politics reference peaks 2100 |
| Today vs tomorrow | **core holds; ladder incomplete** | constant minus fading limit 68.8 / 57.5 Gt under hold the price (v6 70.9 / 63.5); abatement moved 35.0 / 37.1 against 17.1 / 18.4 Gt under hold the budget. Erosion and growing-limit rows not yet run on `v7` (second wave, tags `V7W2EU21`, `V7W2H12`) |
| Budget or price | holds, smaller | extra CO₂ +98.8 / +87.9 Gt (v6 +118.2 / +112.8) |
| The budget survives | **stronger** | anchor ×1.21 / ×1.19 (v6 ×1.26), abatement moved 17.1 / 18.4 Gt |
| Who abates | **weaker, and changed** | relocation onto China halves (−4.9 / −6.4 Gt), India leaves (+0.8 / +0.3), Russia & reforming and the Middle East take up: v6's large relocation onto China was largely an edge-of-data effect (0007 §1, §17) |
| Robust now, a bet later | to re-derive | needs the 2050 extra CO₂ per persistence case on `v7` (the second wave) |

**Recommendation on `v7`: keep *Today vs tomorrow*, led by *Net zero slips*, and open with the theory.** The order the
author set (assumptions before the estimated model) adds what `v6` lacked: the ceiling is a tested statement of
political-economy theory (structural power, contingent on institutions, coherent across the sample; ADR 0059), and the
democracy weight removes the edge-of-data artefacts that drove `v6`'s regional story. A spine sentence:

> *Unless politics changes, holding each country to the carbon price its political economy has sustained keeps
> cumulative CO₂ rising past 2150; most of that cost is the assumption that today's politics persists.*

Before writing on it: run the second wave (the persistence ladder on `v7`); re-derive *Robust now, a bet later*;
drop the China-centred reading of *Who abates* and report the relocation as small and redistributed.
