# 38. von Dulong 2025 enters as context controls, not new IQ channels; year-FE rung answers trend dominance

Date: 2026-07-13

## Status

Accepted — decided in a grill-with-docs session. Glossary: [[Context Dummies (control block)]],
[[Year-FE Rung]] in CONTEXT.md.

## Context

von Dulong & Hagen 2025 (ERL, appraised INCLUDE) find institutions (freedom, government
effectiveness, corruption control) are the top ML predictors of climate-policy stringency, and the
PSM's deployed spec is trend-heavy (first-sweep median trendShare 0.64; `trendDominanceGate` 0.9).
The obvious move — adding corruption/freedom as new channel candidates — would revise the
2026-06-12 three-channel Institutional Quality rule.

## Decision

1. **No new IQ channels.** The three-channel rule stands; von Dulong is cited as independent
   *validation* of the existing channels (GovEff + accountability/freedom family), not as a source
   of new ones. (Rejected: a fourth "Corruption Control" slot — WGI CC is near-collinear with
   GovEff, the Channel Screen would mostly forbid co-entry, and channel-set stability across the
   two papers is worth more than a marginal candidate.)
2. **Context controls instead:** EU membership (time-varying accession dummy; frozen at the last
   historical year in projections) + transition economy (static), as **one** ±block switch on the
   control axis (8 → 16 combos). EU is the load-bearing one (the only robust context control in
   von Dulong's own OLS) and carries the EU climate acquis — the one control that can genuinely
   absorb common temporal rise from the time trend. Excluded: island/Gini/CRI/aid/education
   (no sample variation, projection burden, or weak theory) and emissions/energy-intensity
   predictors (overlap Actor Power drivers → would contaminate the theory/control split).
   Static in-code tables derived from region + year in `preparePanelData` (pfm), following
   the R7 EU-dummy precedent — no external reader, no mrpfm chain; the tables cover both
   R54 codes (unambiguous aggregates only) and ISO3 for the country-resolution run.
3. **Trend dominance:** no gate change now (0.5 would gut the pool; ADR 0027 lesson). Instead a
   report-only **year-FE rung**: the deployed spec re-fit with year dummies replacing the logistic
   trend, demonstrating the channels survive within-year identification. Revisit the gate only
   after the country-level + EU-control rerun shows whether trendShare drops organically.
