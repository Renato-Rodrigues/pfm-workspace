# ADR 0048 — The soft fragility keys leave the within-band order; the baseload control stays

- **Status:** Accepted (2026-10-05), implemented, and declared in `config.yml` **before** the
  corrected `v6` re-run's sanity results were read (PITFALLS §28).
- **Supersedes:** item 2 of [ADR 0037](0037-no-selection-on-significance.md) (the within-band
  inference-fragility preference, `inferenceTGate = 2.33`) and the soft collinearity preference
  (`softVifGate = 6`, `computeMaximinScore`, 2026-06-24). ADR 0037 items 1 and 3 (no gate on
  significance; the influence diagnostics) stand.
- **Keeps:** the hard VIF gate at 10, every other hard gate, the near-tie band of
  [ADR 0039](0039-psm-tournament-v2.md), and the remaining within-band keys (idle control,
  ADR 0022; trend reliance, ADR 0033; BIC parsimony, ADR 0012). The hydro/nuclear/geothermal
  control stays in the grid exactly as it is (design note 0005 A4).
- **Run-Groups:** `v6`, `v6-annual` and later. `v5` keeps the rule it was selected under.
- **Evidence:** `analysis/checks/baseloadControl.R v6 v5` → `output/pfm/v6/baseload-control.rds`;
  `output/pfm/{v5,v6}/sweep.rds`, `selection-bootstrap.rds`. All of it is estimation-side: the
  scenario-panel unit fix of PITFALLS §28 does not change any number below.

## Decision

1. **Within the near-tie band, no soft fragility key.** `softVifGate = Inf` and
   `inferenceTGate = 0`, in the sweep and in the selection bootstrap alike. The band is ordered by
   idle control, then trend share, then BIC. Collinearity is still bounded by the hard gate
   (VIF < 10). Significance is still never an admission criterion (ADR 0037, item 1).
2. **The hydro/nuclear/geothermal control is kept.** No population-only control sets are added.
3. **The two knobs become declared group settings:** keys of `config.yml` `sweep:` and fields of
   `manifest.json` `sweepOptions`, so a group records the rule it was selected under. The code
   defaults stay at 6 / 2.33, so a rebuild of `v5` reproduces `v5`.

## Context

### What the soft keys decided

Both keys were added as mild tie-breakers among theory-equivalent specs. On `v6` they no longer
break ties. They select:

- The first near-tie band of `v6` holds **147** specs. **143** have a max VIF above 6, and **126**
  have a significant theory term below |t| 2.33. Only **2** carry neither flag:
  `X-1950 WGIge|RoL|noAcc splitAPpc lev ctl:GDPq` and its `GDPq.sq` twin. They lead the band
  although they have its highest trend share (0.853 Bulk).
- `X-1950`'s clean status rests on a Bulk |t| of **2.37** against 2.33. In the selection
  bootstrap it wins **1.6%** of resamples (3 of 184).
- Moving the soft VIF limit alone does not settle it. Each threshold deploys a different spec, and
  none of them is one the bootstrap favours:

| softVifGate | inferenceTGate | band leader | bootstrap win share (`v6`) |
|---:|---:|---|---:|
| 6 | 2.33 | `X-1950 RoL\|noAcc splitAPpc GDPq` *(deployed)* | 1.6% |
| 7 | 2.33 | `X-1731 RoL\|VerAcc splitAPpc ctlNone satInn` | 3.3% |
| 8 | 2.33 | `X-1908 RoL\|DiagAcc mixedAP Pop.Hyd satInc` | 1.1% |
| off | 2.33 | `X-1914 RoL\|DiagAcc mixedAP GDPq.sq.Pop.Hyd satInc` | 0.5% |
| 6 | off | `X-1959 RoL\|noAcc splitAPpc GDPq.Pop.Hyd` (`v4`'s deployment) | 7.1% |
| **off** | **off** | **`X-1791 RoL\|VerAcc bothIncAP GDPq.Pop.Hyd satInc`** | **6.5%** |

With both keys off, the leader carries every element the bootstrap supports: Government
Effectiveness (100% of winners), Rule of Law (90%), `bothIncAP` (61%; 1.35× its pool share,
p = 2e−5), the most frequent accountability channel (`VerAcc`), and a favoured transform (`satInc`,
1.44×). Its runner-up `X-1794` differs only by the GDP square. The 6.5% is measured under the old
rule. It is re-measured under this one (Consequences).

### Where the VIF comes from

The VIF that the soft key reads has two sources (`baseload-control.rds`, X-2079 design):

| | `v5` | `v6` |
|---|---:|---:|
| Bulk VIF, incumbent share | 3.29 | **6.59** |
| Bulk VIF, hydro/nuclear/geothermal share | 2.30 | **4.65** |
| corr(Bulk incumbent share, baseload share) | −0.69 | **−0.84** |
| share of hard-gate passers with VIF > 6: baseload control, no RoL+accountability | 6% | **32%** |
| share with VIF > 6: Rule of Law together with an accountability channel | 90–97% | 93–96% |

1. **The baseload control against the Bulk incumbent share. New in `v6`.** Counting geothermal (A4)
   makes the control a closer complement of the fossil share. Iceland moves from 0.18 to 0.70
   (dropping Iceland takes X-2079 from 6.59 to 5.11). This is **correct measurement, not a
   defect**: Iceland's clean baseload is 70%.
2. **Rule of Law with an accountability channel. Present in `v5` too.** The V-Dem indices overlap
   with each other and with Government Effectiveness. No control set changes it.

**This is the key that decided the institutional channels.** It kept `X-2079` (`noRoL|VerAcc`,
VIF 3.41) ahead in `v5` and demoted it to rank 24 in `v6` (VIF 6.63). It is why `v5` deployed
"accountability without Rule of Law" and `v6` "Rule of Law without accountability". Neither
version had evidence for that choice. The penalty only says the model cannot hold both
comfortably. MODEL.md §6 already records that the accountability channel is not identified.

### Why the baseload control stays

A control that is never significant (Bulk −0.25, p .13; Diffuse +0.02, p .69, X-2079 `v6`) looks
like the obvious thing to drop, and a population-only control set would remove the `v6` VIF
problem (X-2079: 6.59 → 2.94). It would also remove the incumbency effect. Same design, population
kept, `v6` Bulk mean regression:

| | with control | population only |
|---|---:|---:|
| incumbent share | **−0.268** | **−0.020** |
| incumbent per capita | 0.537 | 0.454 |
| Government Effectiveness | 0.159 | 0.202 |
| R² | 0.713 | 0.710 |

France, Sweden and Norway have a low fossil share because of legacy nuclear and hydro, not
because of climate politics. With the control, the model can separate "low fossil dependence"
from "inherited clean baseload". Without it, the incumbent-share effect vanishes in Bulk. The
countries it moves are the nuclear and hydro ones. France goes from 43rd to **46th** of 48 on the
residual (observed − fitted, 2019–2023), Norway from 19th to 23rd, New Zealand from 22nd to 29th,
Slovakia from 30th to 33rd. Finland (45 → 34) and Sweden (44 → 38) move the other way, because
their fossil share is very low. The overall ranking holds (Spearman 0.959). Diffuse is unaffected
(incumbent share −0.183 vs −0.200, Spearman 0.996), because its incumbency is industrial fossil
use. The collinearity is the price of identifying a partial effect the theory asks for. The hard
gate at 10 bounds it.

## Alternatives considered

| alternative | why not |
|---|---|
| Keep both keys (status quo) | A 0.04 margin in \|t\| decides the deployment; 1.6% bootstrap support; the highest trend reliance in the band |
| Raise `softVifGate` to 7, 8, … | a knife-edge with a different winner at every value (table above) |
| Drop only the VIF key | the \|t\| key then decides alone, and picks `X-1914`, a mixedAP + DiagAcc spec. Both elements are under-selected (0.45×, 0.48×) |
| Drop only the \|t\| key | picks `X-1959` (the splitAPpc family again, 7.1%); the VIF key still decides the channels |
| Population-only control sets (`Pop`, `GDPq.Pop`, `GDPq.sq.Pop`) | remove the Bulk incumbent-share effect (−0.268 → −0.020) and penalise nuclear/hydro countries |
| Hydro/nuclear without geothermal | undercounts Iceland's clean baseload (0.70 → 0.18); a new panel column changes the panel hash and refits every spec |

## Consequences

- **The rule is fixed here, not the spec.** The deployed spec is still the first in this order
  that clears the sanity walk on the corrected scenario panels (PITFALLS §28), now with
  `scenarioBlind` active. On today's `v6` ranking, the walk would start at `X-1791 … satInc`. No
  scenario gate has been run on it yet. Its `v5` relatives `X-1779` (linear and satAP) failed the
  γ gate, so γ must be read.
- **The bootstrap is re-run under the same knobs.** Its win shares, the 6.5% included, were
  measured under the old rule.
- **Thinner terms.** `X-1791 satInc`'s weakest significant theory term is |t| 2.05 / 2.20. Only
  wild-cluster p-values are quoted (MODEL.md §2.5), and the influence diagnostics of ADR 0037
  item 3 report any pivotal cluster. VIF up to 10 means standard errors up to about 3× wider on
  the affected terms. The terms concerned are the Bulk incumbent share, the baseload control and
  the institutional mains. Report it.
- 🔴 **Disclosure.** This rule is decided after the `v6` deployment under the old rule was known.
  Like ADR 0045's threshold move, the paper says so. What limits the damage: it is decided before
  the corrected sanity results are read; it removes knobs rather than tuning a threshold; and it
  reaches the specification that both resampling and an element-level reading of the bootstrap
  point to.
- **The institutional channel stops being an artefact of the penalty.** Whether Rule of Law and an
  accountability channel enter together is now decided by fit and trend reliance. The claim about
  accountability does not change: it is still not identified.
- **Implementation** (2026-10-05, `pfm` after 0.8.0; `tests/testthat/test-softSelectionKeys.R`):
  - `config.yml` `sweep:` declares `softVifGate: "off"` and `inferenceTGate: "off"`.
    `.pfmSweepOptionsNormalise` reads `"off"`, an unquoted YAML `off` (which arrives as `FALSE`)
    and numbers. Off is stored as `Inf` / `0`, never `NULL`, because `modifyList` drops a `NULL`
    and the default would come back.
  - `runPFMSweep` records both keys in `manifest.json` `sweepOptions` (`"off"` when disabled).
  - **Resolution is per key** (`.pfmSweepOptionsForGroup`): the manifest record wins for every key
    it holds, and a key it lacks comes from `config.yml`. `v6` and `v6-annual`, swept before this
    ADR with a record of the actor-power keys only, take the new rule on their re-sweep and record
    it. `v5` has no record, so it keeps 6 / 2.33 whatever the config says. `pfmRun`'s plan prints
    the rule in force and where it came from.
  - `runPFMSelectionBootstrap` reads the group's recorded keys when the caller does not pass them,
    so its resamples are re-ranked under the rule the group was selected under.
  - Code defaults unchanged (6 / 2.33).
