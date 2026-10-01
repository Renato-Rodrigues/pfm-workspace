# 37. No selection on statistical significance — within-band inference-fragility preference + post-selection influence diagnostics

Date: 2026-07-13

## Status

Accepted — decided in a grill-with-docs session; implementation queued with the country-level
re-run work. Glossary: [[Inference-Fragility Preference]], [[Influence Diagnostics (LOCO)]] in
CONTEXT.md.

## Context

The PSM's wild-cluster survivors are thin (Bulk AP×RoL p=.042, Diffuse AP p=.040, AP×VerAcc
marginal at .059, no IQ mains), raising the request to "avoid terms being non-significant just by
a little" at selection time. A hard p-value gate in the sweep would guarantee a clean coefficient
table but is textbook selection-on-significance: the surviving p-values become uninterpretable
*because* they were selected for, contradicting the project's report-failures-against-ourselves
posture (pfm-paper CLAUDE.md) and, with 25 clusters, would gate out nearly everything including
the deployed spec.

## Decision

1. **Never gate the sweep on p-values.** Statistical significance of theory terms is not an
   admission criterion for specs.
2. **Within-near-tie-band preference only:** among theory-equivalent specs (inside the maximin
   ε-band), prefer the spec whose theory terms carry stronger cluster-robust t-statistics — the
   same soft-preference pattern as `softVifGate` / `dropIdleControls` / low-trend-reliance
   (ADR 0022/0023/0033). A mild, disclosed reordering; tier/ΔR² still drive selection.
3. **Diagnose, don't launder, marginality post-selection:** a new influence diagnostic
   (`computeInfluenceDiagnostics`, step `psm-influence`, artifact `influence.rds`) on the deployed
   spec, per sector and theory term: leave-one-country-out refits with analytic cluster-robust
   p-value and coefficient paths flagging **pivotal clusters** (removal crosses .05 in
   either direction), per-cluster DFBETA ranking, and a β-vs-SE decomposition (is marginality
   coefficient shrinkage or SE inflation?). SEs are CR1 with the Cameron–Gelbach–Miller small-G
   adjustment and t(G−1) p-values — the suite's existing clustered-SE convention (`vcovCL` HC1 /
   the wild bootstrap's internals), chosen over CR2 so the LOCO p-paths are directly comparable
   to every other reported p. Wild-cluster bootstrap is re-run only at flagged
   pivotal folds, not all folds (full-WCB-everywhere rejected: ~50× compute for noisy Webb-weight
   inference at 24 clusters per fold; DFBETA-only rejected: misses joint within-cluster influence).
4. The legitimate power lever for marginal inference is the **country-level re-run** (25 → ~50
   clusters), not selection pressure.
