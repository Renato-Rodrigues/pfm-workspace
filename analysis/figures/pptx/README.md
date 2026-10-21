# `analysis/figures/pptx/` — the editable schematics

Figures that are diagrams, or charts the author edits by hand, are built as one-slide PowerPoint decks of native
shapes: every box, arrow, line and label is a named shape (`objectName`), so it can be moved or restyled in PowerPoint.
They share palette, font and sizes with the R charts through `../style/figure-style.json` (`style.js` reads it), and
each slide is drawn at its printed size (6.5 in wide), so the type sizes in the JSON are the printed sizes.

```bash
npm install                                   # once, here: pptxgenjs, pinned in package.json
Rscript analysis/figures/build-doc-figures.R  # from the project root: data, both decks, and their PNGs
```

| builder | figure | data |
|---|---|---|
| `fig-gap.js` | the ceiling and the gap, observed and projected, for one country | `gap-data.json`, written by R (`docGapData()` in `R/fig-doc.R`) |
| `fig-coupling-estimation.js` | the coupling between the PFM and REMIND, with what the PFM estimates | none |

`export-png.ps1` exports a deck to PNG at 220 dpi through PowerPoint (Windows). Rebuilding overwrites hand edits in
`output/doc/*.pptx`: change the builder, not the output, if an edit should last.
