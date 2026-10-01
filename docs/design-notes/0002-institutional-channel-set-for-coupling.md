# 0002. Is the deployed institutional channel set the right one for the coupling?

Date: 2026-08-25; rewritten 2026-09-17 on Run-Group `v5`
Status: **Open.** The deployed set is **`WGIge|noRoL|VerAcc`** — state capability plus electoral
accountability, rule of law dropped — in `X-2079 WGIge|noRoL|VerAcc bothIncAP lev
ctl:GDPq.Pop.Hyd fe:OECDp` (ADR 0045). It was reached by a gate decision about actor-power form,
not by a decision about channels, so the channel set has not itself been defended. This note lays
out what the grid offers, what selection and estimation say on `v5`, and which alternatives are
defensible on theory. Earlier sweep-by-sweep versions are in
`../_archive/_wip/2026-09-16/docs-pre-v5-sweep/design-notes/`.
Related: ADR 0036 (maximin), ADR 0038 (context controls, not channels), ADR 0039 (tournament),
ADR 0043 (ceiling gate), ADR 0045 (extrapolation gate), ADR 0046 (γ gate), note 0001, TODO item 7a,
`../_archive/_wip/2026-10-01/docs/reference/spec-selection-2026-09-15/`.

---

## The institutional channels in the grid

| token | variable | what it is meant to capture |
|---|---|---|
| `WGIge` / `noGE` | Government Effectiveness (WGI) | **State capability** — can the bureaucracy design, administer and collect a carbon price at all |
| `RoL` / `noRoL` | Rule of Law (V-Dem) | **Credible commitment** — will the price still exist in ten years; can firms be made to comply |
| `VerAcc` | Vertical Accountability (V-Dem) | **Electoral sanction** — voters can remove a government, so unpopular costs are punished |
| `DiagAcc` | Diagonal Accountability (V-Dem) | **Civil-society / media** — organised publics and press scrutinise policy between elections |
| `HorAcc` | Horizontal Accountability (V-Dem) | **Checks and balances** — legislatures and courts constrain the executive |
| `noAcc` | — | accountability omitted |

Controls (`GDPq`, `sq`, `Pop`, `Hyd`) are **context, not channels** (ADR 0038) and carry no
political interpretation. `fe:OECDp` is the fixed-effect block.

---

## What the grid contains on `v5`

`output/pfm/v5/sweep.rds$maximin$PolicyStringency`, 4,392 candidates, 288 per three-token channel set.
"gate" = passes the admissibility gates; best min ΔR² is over gate-passing members.

| channel set | Green | gate-passing | best maximin rank | best min ΔR²(theory) |
|---|---:|---:|---:|---:|
| **`WGIge\|noRoL\|VerAcc`** *(deployed)* | 125 | 41 | **1** | 0.112 |
| `WGIge\|RoL\|noAcc` | 134 | 70 | 3 | 0.116 |
| `WGIge\|noRoL\|DiagAcc` | 145 | 60 | 5 | 0.120 |
| `WGIge\|RoL\|DiagAcc` | 156 | 87 | 7 | **0.136** |
| `WGIge\|RoL\|VerAcc` | 94 | 37 | 8 | **0.135** |
| `WGIge\|RoL\|HorAcc` | 190 | 65 | 17 | 0.134 |
| `WGIge\|noRoL\|HorAcc` | 126 | 57 | 81 | 0.111 |
| `WGIge\|noRoL\|noAcc` | 68 | 32 | 97 | 0.103 |
| best `noGE` set (`noGE\|RoL\|VerAcc`) | 58 | 9 | 156 | 0.097 |

**Two things follow.**

1. **Three institutional channels can enter together at country resolution.** The sets carrying
   capability, rule of law *and* an accountability measure are admissible and carry the highest
   theory content in the grid (0.134–0.136 against the deployed 0.112). The "at most two strong
   channels" constraint recorded in earlier versions of this note (every three-channel set failing
   the VIF gate) does not hold on `v5`.
2. **Every `noGE` set ranks far down.** State capability is not a contested choice.

**Why the deployed set is first anyway.** The maximin rule is tier first, then theory content, then
parsimony and fragility, and the sanity walk then rejects projections that are scenario-blind,
extrapolation-dominated, collapsing or at the γ boundary. Walking down the ranking
(`sweep.rds$sanity`): rank 3 (`WGIge|RoL|noAcc`, `satAP`) collapses its ceiling; ranks 5–6
(`noRoL|DiagAcc`) collapse; rank 7 (`RoL|DiagAcc`) is extrapolation-dominated; ranks 8–10
(`RoL|VerAcc`, `RoL|DiagAcc`) are scenario-blind; several `RoL|VerAcc` and `RoL|HorAcc` members are
rejected at the γ boundary (ADR 0046). The deployed set survives because its best member passes,
not because it carries the most theory.

---

## What resampling says (`output/pfm/v5/selection-bootstrap.rds`, 196 winners, top-60 pool)

| token | menu | pool | winners |
|---|---:|---:|---:|
| `WGIge` | 52.5% | 100.0% | **100.0%** |
| `RoL` | 52.5% | 91.7% | 74.0% |
| any accountability | 78.7% | 90.0% | 79.6% |
| `VerAcc` | 26.2% | 35.0% | 42.9% |

**Slot-corrected** (wins against the share of pool slots a set holds):

| channel set | pool slots | wins | obs/exp | $p$ |
|---|---:|---:|---:|---:|
| **`WGIge\|noRoL\|VerAcc`** *(deployed)* | 2 | 26 | **3.98** | 3e−09 |
| `WGIge\|noRoL\|DiagAcc` | 3 | 25 | 2.55 | 2e−05 |
| `WGIge\|RoL\|noAcc` | 6 | 40 | 2.04 | 1e−05 |
| `WGIge\|RoL\|HorAcc` | 8 | 26 | 0.99 | 1 |
| `WGIge\|RoL\|VerAcc` | 19 | 58 | 0.93 | .59 |
| `WGIge\|RoL\|DiagAcc` | 22 | 21 | 0.29 | 3e−16 |

**The full-sample filter and the resampling disagree about rule of law, and both are right.** The
pool is dominated by `RoL` sets (92% of slots), so in absolute terms `RoL` wins most draws (74%) and
`RoL|VerAcc` is the modal set (29.6%). Per slot, the two `noRoL` accountability sets are the most
over-selected, and the deployed set most of all. The filter says rule of law usually belongs; the
resampling says that when a `noRoL` set makes the pool it wins out of proportion. Report both.

**Which accountability channel is not identified**: Vertical 42.9%, Diagonal 23.5%, none 20.4%,
Horizontal 13.3% of winners. No option reaches half.

---

## What estimation says about the deployed channels (`MODEL.md` §2.5–§3.3)

| term | Bulk mean ($p_{wild}$) | Bulk frontier ($p$) | Diffuse mean ($p_{wild}$) | Diffuse frontier ($p$) |
|---|---:|---:|---:|---:|
| Government Effectiveness | **+0.240 (.048)** | +0.064 (.32) | **+0.333 (.006)** | **+0.251 (<.001)** |
| Vertical Accountability | +0.347 (.125) | +0.029 (.78) | −0.187 (.657) | −0.037 (.37) |
| `Incumb pc × VerAcc` | **+0.261 (.015)** | +0.082 (.052) | +0.043 (.965) | **+0.087 (<.001)** |
| `Incumb × VerAcc` | −0.451 (.057) | −0.116 (.26) | +0.102 (.834) | −0.059 (.13) |

- **Capability carries the institutional signal**, robustly in Diffuse, fragilely in Bulk (14
  pivotal countries) and absent from the Bulk frontier.
- **Vertical Accountability carries no main effect** in either sector or estimator. Its role is one
  Bulk interaction with per-capita incumbency, which depends on China and Saudi Arabia; Saudi Arabia
  is the sample's extreme on exactly this plane (lowest accountability, highest incumbency;
  `MODEL.md` §2.6.1).
- **Capability and vertical accountability correlate at 0.45** in both sectors
  (`frontier.rds$bySector$<s>$correlation`) — enough to share variance, not enough to be redundant.

So on `v5` the deployed set is, in effect, **capability plus an accountability term that the data do
not identify**.

---

## The theoretical case for and against the deployed set

**`WGIge|noRoL|VerAcc` — capability plus electoral sanction, commitment dropped.**

*For.* A carbon price must be administered (capability) and survived at the ballot box (electoral
sanction). That is the most direct democratic-accountability reading of *political* feasibility,
and it is the set resampling favours most per slot.

*Against.* It drops **credible commitment**, the channel with the cleanest mapping onto a
long-horizon price path — investors act on whether the price will still exist in ten years — and
the one 92% of the bootstrap's top-60 pool includes. And its accountability term is not identified, so the
set's political content rests on capability alone.

**The defensible alternatives, on theory and evidence:**

| set | best member | case for | case against |
|---|---|---|---|
| **`WGIge\|RoL\|VerAcc`** | `X-1791 … bothIncAP … satAP` (passes the sanity walk, 190 warnings); its linear twin is the Bulk per-sector optimum (ΔR² 0.139) | all three mechanisms — administer, commit, survive the ballot; modal channel set under resampling | many members scenario-blind or at the γ boundary; the passing member leans on the saturating transform and carries far more warnings |
| **`WGIge\|RoL\|noAcc`** | `X-1959 … splitAPpc` (passes at the 0.25 gate) | a state-centred account — capability plus commitment — with accountability dropped because it is not identified anyway | says the ceiling is administrative and legal, not electoral: a defensible political economy, but a different paper |
| **`WGIge\|RoL\|DiagAcc`** | rank 7, extrapolation-dominated | highest theory content in the grid (0.136) | its best member fails a gate; least-selected per slot (0.29×) |

---

## What this note does not settle

- **Whether the channel set should be a paper-level robustness dimension.** The φ specification band
  is not yet measured on `v5` (TODO item 7a, claim C31). Pinning `X-1791` would answer "does
  adding commitment change who is constrained?" directly.
- **Whether rule of law should be forced in on theory.** That would be a declared choice against the
  selection rule and needs an ADR, with the fit and gate consequences above disclosed.
- **Whether any accountability measure belongs.** On `v5` none is identified as a main effect, and
  resampling cannot choose between them.

## Provenance

All numbers from Run-Group `v5` (`panel_hash f8845f66fb39d316`): `sweep.rds`
(`$maximin`, `$sanity`, `$results`), `selection-bootstrap.rds`, `inference.rds`, `frontier.rds`,
`influence.rds`. Collected by `analysis/checks/docFacts.R` into `output/pfm/v5/doc-facts/facts.json`; the
per-set grid table and slot-corrected table were computed directly from `sweep.rds` and
`selection-bootstrap.rds` on 2026-09-17.
