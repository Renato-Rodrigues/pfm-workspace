# 39. PSM Tournament v2 — worse-sector ΔR² ranking, tier gate, scenario-responsiveness gate, country resolution

Date: 2026-07-15

## Status

Accepted — decided in a grill-with-docs session. Glossary: [[Tournament v2 (PSM Selection)]],
[[Specification-Sharing Cost]] in CONTEXT.md. Supersedes the tier-first ranking for the PSM
only (the price model keeps ADR 0012/0022/0033 semantics).

## Context

The Maximin Selection Rule's stated principle is "a spec is scored by its worse sector", but
its implementation ranks worse-sector *tier* first and *mean* ΔR²(theory) second. Two
documented consequences for the PSM: the tier metric structurally favors composite-AP specs
(interaction-carried signal demotes split forms to Blue — the R1 attribution finding), and
mean-ΔR² lets a strong Diffuse compensate a weak Bulk (deployed X-1203: Bulk 0.039 vs
Diffuse 0.163). Separately, composite-AP deployments are scenario-blind under the
driver-support guard (|CA−NPi| ≈ 0 by 2050), making them unusable for IAM coupling; and the
corrected country-resolution sweep raises the achievable worse-sector theory contribution
substantially (Green-tier min-ΔR² 0.105 vs 0.067 at R54).

## Decision

1. **Ranking (PSM only): worse-sector ΔR²(theory)** — `min(ΔR²_Bulk, ΔR²_Diffuse)` is the
   primary sort among gate-passers; this is the more faithful operationalisation of the
   already-documented maximin principle, not a new principle. The near-tie band and its
   within-band preferences (ADR 0022/0037) operate on this metric.
2. **Tier becomes a gate, not the ranking**: the deployment requires **Green** in both
   sectors; a **Blue-gate** run is also computed and its winner *documented* as the
   tier-relaxed row (it deploys only if the responsiveness gate empties the Green pool).
3. **Scenario-responsiveness is a selection gate now** (handoff queue item 7 delivered):
   inside the sanity walk each candidate is projected on the gating scenario AND a
   reference scenario; a spec whose median |gating − reference| index delta over
   in-coverage region-years in the evaluation window falls below `minScenarioDelta`
   (default 0.05 index points, window 2040–2060) is severe-flagged **scenario-blind** and
   deselected. Rationale: a feasibility layer that cannot distinguish a 1.5 °C pathway from
   current policies cannot inform coupling; empirically composite-AP ≈ 0.00 vs split-AP
   ≈ 0.56 at 2050, so the gate separates cleanly without tuning.
4. **Country resolution carries the v2 deployment** (~48 clusters, n = 1,012; corrected
   sample): selection and the gate-closing evidence batch run on the country panel; REMIND
   delivery still maps ceilings/speeds to H12/R54 (unchanged runbook decision). The R54
   deployment (X-1203) remains documented as the prior version.
5. **Per-sector winners are a documented exhibit, never a deployment**: the
   [[Shared Specification]] rule stands; the v2 selection artifact additionally records each
   sector's own best spec and the ΔR² it gives up under the shared winner (the
   [[Specification-Sharing Cost]] exhibit). Re-opening dual deployment requires its own
   session with the exhibit as evidence.
6. **Disclosure discipline**: v2 is a post-hoc refinement made after seeing v1/v2 results;
   Methods must say so, the selection bootstrap (ADR 0025) is re-run under the v2 rule for
   the publication run, and both tier-gate winners plus the sharing-cost exhibit ship in the
   selection report.

## Consequences

Selection can no longer be finalised offline (the responsiveness gate projects candidates on
two scenario panels) — the v2 selection is a cluster step, though cheap (fits are cache-hits
from the existing country sweep). Every paper number churns once more (v3); this is intended
to be the final selection change before submission.
