# ADR 0059 — The specification search requires the political-economy hypotheses it is built on

- **Status:** **Accepted 2026-10-25** (author). Proposed 2026-10-22. Applies from Run-Group `v7`; `v6` and earlier are
  unchanged. Accepted with three conditions: the paper states that the selection rule was revised for v7 and why; it
  reports the post-selection caveat; the H3 (0.70 / 0.80) and p (0.10) sensitivities are run before the results are final.
- **Run-Groups:** `v7` (`config.yml` `sweep: groups: v7: theoryGate`).
- **Evidence:** design note 0007 §§13–15; `analysis/checks/theoryTermScreen.R`, `inferenceScreen.R`, `offsetRatio.R`,
  `theoryGateCalibration.R` → `output/pfm/v7/theory-term-screen.rds`, `inference-screen.rds`, `offset-ratio.rds`,
  `theory-gate-calibration.rds`.

## Decision

A specification is selected only if its fits show the three hypotheses the frontier is built to represent (ADR 0056:
fossil dependence as a proxy for the structural power of fossil interests, contingent on institutions). The gate is
`pfm::.pfmTheoryScreen` (H1–H2, on the ranked pool before the sanity walk) and the severe walk flag `theoryCoherence`
(H3). Defaults (`.pfmTheoryGateDefaults`): `p` 0.05, `coherence` 0.75.

| | Hypothesis | Test, in every sector |
|---|---|---|
| H1 | **Structural power.** Fossil dependence lowers the most stringent policy that comparable countries sustain. | Main effect of the fossil term < 0, cluster-robust p < 0.05. The fossil term is the share; the per-person form only where a spec has no share. |
| H2 | **Contingency.** That power depends on institutions. | At least one fossil × institution term (share or per-person) at p < 0.05 / their number (Bonferroni). Sign free. |
| H3 | **Coherence.** Fossil dependence is a constraint across the observed sample, not only at its centre. | The fossil effect, its interactions (and their weight) included, is negative in at least 75% of the estimation country-years. |

Within the pool that passes, the declared maximin order (ADR 0036, 0048) and every other gate apply unchanged.

## Why these three, and not others

- **H1 is the frontier's premise.** Structural power works by anticipation (Lindblom 1977; Przeworski & Wallerstein
  1988): governments do not adopt what would hurt investment, jobs or revenue in a dominant sector. A ceiling on the
  stringency comparable countries sustain is where this should show (Culpepper & Reinke 2014; Colgan, Green & Hale
  2021). A specification in which fossil dependence does not lower that ceiling cannot carry the paper's mechanism.
- **H2 is the reason for the interactions.** Structural power is contingent on context (Hacker & Pierson 2002;
  Culpepper 2011). The model represents that context by state capability, rule of law and accountability.
- **H2 fixes no sign, on purpose.** The literature predicts both directions for accountability: it can empower the
  diffuse public against concentrated interests (Olson 1965; Bättig & Bernauer 2009; Povitkina 2018), or carry
  energy-cost backlash and the political weight of fossil regions into policy (Mildenberger 2020, "double
  representation"; Stokes 2020). Requiring a sign would choose between theories by selection; the data decide it.
- **H3 refuses an artefact, not a finding.** The three institutions are strongly correlated on the sample (rule of law
  with the accountability indices 0.79–0.90). Large interaction terms of opposite sign can then fit the data while
  turning the fossil effect positive across much of the sample, as in X-2929 (fossil dependence a constraint in 29% of
  power & industry country-years). Such a specification no longer says that fossil interests constrain policy.
- **The clean-energy terms carry no requirement.** Their early influence is mostly instrumental; their structural
  weight grows only as the sector does (ADR 0056, limits). In power & industry their centre sign is negative in v6.

## Consequences

- `v7`'s first selection, X-2929, fails H1 in both sectors and H3 in power & industry (0007 §13–14). 84 of the 5,930
  specs of the maximin pool pass H1–H2 (38 in the top 100); v6's selected specification passes H1–H2 on v6's sweep
  and H3 at 100% / 84%. The gated re-selection (job 2667134) selected X-1791 `satInn iw:fexp`, v6's specification with
  saturating clean-energy interests and the freedom-of-expression weight (0007 §16).
- **Post-selection inference.** Selecting on significance biases the winner's p-values downwards. The paper reports
  the wild-cluster-bootstrap p-values of the selected spec (`inference.rds`) with this caveat, and the share of the
  pool that passes, so a reader sees how selective the hypotheses are.
- The p-values the gate reads are the fits' cluster-robust asymptotic ones (48 clusters); the wild bootstrap, which is
  stricter, is computed for the winner only.
- `sweep.rds$theory` keeps every spec's verdict; the walk's `theoryCoherence` flag names the share.

## Alternatives rejected

- **Keep the first selection (X-2929).** It follows the declared rule, but it does not show the mechanism the model
  exists to represent; the paper could not use it as evidence for it.
- **Select by fit (log-likelihood).** It would prefer whatever predicts best, theory or not, and change the rule after
  seeing the results without a reason from the theory.
- **Require v6's pattern (fossil × accountability < 0).** It would pick a side in an open debate (above) and make v7
  confirm v6 by construction.
- **A gate on offsetting itself (gross / net spread of the interaction contributions).** Offsetting is common across
  the grid (median 3.9 in the top 300) because of the correlated institutions; such a gate would remove most of the
  grid without separating meaningful from artefactual specs. The lasting remedy is in the formulation (one
  institutional moderator per interest, or a composite of rule of law and accountability), for `v8`.
