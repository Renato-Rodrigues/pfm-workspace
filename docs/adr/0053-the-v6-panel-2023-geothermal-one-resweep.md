# ADR 0053 — The `v6` panel: 2023 on the IEA 2025 edition, geothermal, one re-sweep

- **Status:** **Accepted 2026-10-07** (author) — D3 and D8 were decided by the author on
  2026-10-02, and the Phase 2 gate passed on 2026-10-06 (with decision 4, Bulk γ).
- **Run-Groups:** `v6` (5-year moving average) and its sibling rung `v6-annual`.
- **Evidence:** `DATA.md` §3–§4, §7; `output/pfm/{v5,v6,v6-annual}/manifest.json`, `sweep.rds`,
  `frontier.rds`, `historical-replay.rds`; the `v5` → `v6` comparison, design note 0005 §8
  (`analysis/v6/v5v6Comparison.R`).

## Decision

1. **The panel runs to 2023.** The energy data come from the IEA 2025 edition, which is complete for
   2023 and also revises earlier years. The definition (years, smoothing, edition, geothermal) is a
   recorded Run-Group property (`pfmPanelDef`, `config.yml` `panel:`).
2. **The deployed fit stays on the 5-year moving average**, anchored at its last year (D3). Annual data
   are a robustness rung, the sibling Run-Group `v6-annual`.
3. **Geothermal joins hydro and nuclear** in the clean-baseload control, on both the history and the
   REMIND side (A4).
4. **One re-sweep** carries all of it, with the actor-power forms of ADR 0052 (D8).
5. **Bulk γ = 0.997 is accepted** at the Phase 2 gate, below the 0.999 boundary gate, with disclosure
   (decision 4).

## Context

- Each change alters the panel hash or the candidate set, so each would force a selection on its own.
  Done together, the bootstrap, diagnostics and specification band run once, and `v5` → `v6` is one
  documented change set.
- With λ gone (ADR 0050) the moving average biases nothing the coupling uses, and the anchor reading
  benefits from it: the ranking is read in one year.
- **The result** (0005 §8): `X-1791 WGIge|RoL|VerAcc bothIncAP … satAP`, Green in both sectors,
  ΔR²(theory) 0.131 / 0.175 (`v5`: 0.112 / 0.166), 48 covered countries. Rule of Law enters next to
  GovEff, so max VIF rises to 7.7 / 7.9 (ADR 0048 keeps the soft VIF key off). Over the same 48
  countries the efficiency ordering at the anchor keeps a Spearman of 0.82 / 0.87 with `v5`.
- **The annual rung** selects `X-1860 WGIge|RoL|HorAcc … satInn` (family B, ADR 0052). Its Bulk
  historical replay fails by 4e-5 in RMSE (the ceiling binds in 1 of 1104 rows), identically before
  and after the fixes of ADR 0051.

## Consequences

- The anchor year is 2023 and the trend freezes there, automatically (the last panel year).
- `v5`'s panel and its results stay reproducible under their own definition (`v5`: 2000–2022, default
  IEA edition, no geothermal).
- The paper reports the `v5` → `v6` differences from 0005 §8: the Bulk ranking changes (Spearman
  0.58; India from among the least to the most constrained region), and China is the floor in both.

## Alternatives rejected

- Three separate refits (D8).
- Switch the deployed fit to annual data (D3).
- A 2022-only fit on the 2025 edition.
