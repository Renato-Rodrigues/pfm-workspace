# `analysis/figures/` — the shared figure layer

One definition per figure, rendered for every document that needs it. The paper, the deck,
the poster and the reports pull from here, so a figure and its caption cannot say different
things in different places.

```bash
Rscript analysis/figures/build-figures.R                   # every figure -> output/all/ (+ paper2 for the paper)
Rscript analysis/figures/build-figures.R --media=slide,poster   # the deck / poster renders, when needed
Rscript analysis/figures/build-figures.R --only=theta-sweep --media=paper2
Rscript analysis/figures/build-figures.R --guide           # regenerate the guide only
```

**Look at everything at once:** open `analysis/figures/output/all/index.html`. It is generated from the
registry, so each figure appears with its title, what it shows, and the rails that must travel
with it — reviewing a figure without its caveat is how a rail gets lost.

```r
source("analysis/figures/R/load.R")
buildFigure("theta-sweep", group = "v1")          # write files
p <- buildFigure("theta-sweep", write = FALSE)    # get the ggplot, e.g. inside an Rmd
figureRegistry(consumers = "paper")               # what the paper needs
cat(figureExplainer("theta-sweep"))               # caption + what it shows + rails
```

## Layout

| path | what it holds |
|---|---|
| `R/registry.R` | **the registry** — one row per figure: caption, what it shows, what to read off it, rails, sources, consumers |
| `R/fig-<id>.R` | one builder per figure; takes `group`, returns a ggplot, reads nothing but artifacts |
| `R/build.R` | `renderSpec()` (size/device per medium), `buildFigure()`, the guide generator |
| `R/artifacts.R` | `pfmArtifact(group, path)` — the only way a figure reads data |
| `R/theme.R` | theme, palette, and `pfmStamp()` which puts the Run-Group on every figure |
| `R/terms.R` | shared term naming and classification for the coefficient figures |
| `R/load.R` | sources the above; this is a directory, not a package |
| `build-figures.R` | the driver: one clearly-separated chunk per figure |
| `output/all/` | **every figure, one PNG each** — always built; this is where to look |
| `output/all/index.html` | **generated** contact sheet — every figure on one page, with its rails |
| `output/paper2/` | the paper's figures as PDF (183 mm, cairo_pdf) |
| `output/{slide,poster}/` | opt-in renders: `--media=slide,poster`. Not built by default |
| `output/FIGURE-GUIDE.md` | **generated** — do not edit, change the registry |

## The four ideas

**1. The registry is the source of truth.** Caption, explainer and rails live beside the
builder, not in the paper and again in the deck. If a figure is not in the registry it does not exist; if its fields are empty it is not
finished.

**2. One builder, many renders.** A builder returns a ggplot and never sets a size. `build.R`
holds the size, device and text scale per medium — journal single (89 mm) and double column
(183 mm), 16:9 slide, poster panel, report. Differences between media stay **declarative in
one table** instead of spreading as branches through every builder.

**3. Figures are pure consumers.** Everything comes through `pfmArtifact(group, path)`.
Nothing here fits, selects or recomputes. If a figure needs a number that is not in an
artifact, the number does not exist yet and the fix belongs in `pfm`.

**4. Rails travel with the figure.** Several results here are easy to over-claim. The
registry carries a `rails` field, and where a caveat must survive being read without you in
the room, it is stamped **onto the image** — `theta-sweep` and `shortfall-regions` both print
*"PFM-side bound; coupled REMIND results pending"* in the caption strip. Every figure carries
its Run-Group and build date for the same reason (`PITFALLS.md` §9).

## Adding a figure

1. `R/fig-<id>.R` with one function returning a ggplot. Read data only via `pfmArtifact()`.
   Set `attr(p, "pfmGrid")` if the default y-grid is wrong. End with `pfmStamp(p, group)`.
2. A row in `figureRegistry()` — every field, including `rails` if the figure can be
   over-read.
3. A chunk in `build-figures.R`, with a comment saying what it shows and what not to claim.

Nothing else. No registration list to update, no export to declare.

## Current state

**`consumers` is intent, not a render list.** It says who uses a figure (paper / slides / poster /
report); what gets rendered is decided by `buildFigure()`: `all` for everything, `paper2` for the
paper's figures, and slide / poster only when asked for. A figure marked `report` is simply one the
reports use — it renders to `output/all/` like every other.

**All 37 registered figures build** on Run-Group `v5`: 37 PNGs in `output/all/` plus 32 PDFs in
`output/paper2/`, 69 files where the four-media layout produced 105. `output/all/index.html` is the
contact sheet; `output/FIGURE-GUIDE.md` carries the full caption, explainer and rails for each.

Builders that need theme control (only the schematic, so far) attach it as
`attr(p, "pfmTheme")` — `buildFigure()` applies `theme_pfm()` after the builder returns, so a
theme set inside a builder would otherwise be silently overridden.

> ⚠️ **`analysis/figures/` is outside every git repository.** Like `analysis/`, `docs/` and `output/`,
> it is not versioned and will not reach the cluster through `git pull`. The fix is one
> command — `git init` here and add a remote, as `papers/paper-forge/` already does. Until then
> this code exists on one machine only.
