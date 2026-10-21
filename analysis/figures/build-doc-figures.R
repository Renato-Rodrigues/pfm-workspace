# The report figures (ELEVATE D3.3), all five, from one command. Run from the project root:
#   Rscript analysis/figures/build-doc-figures.R [group]        (default v6)
#
# Writes analysis/figures/output/doc/:
#   doc-coefficients.png, doc-frontier-fit.png, doc-shares.png    charts (R, ggplot2, medium `doc`)
#   fig-gap.pptx + .png                                          the gap, observed and projected (editable PowerPoint)
#   fig-coupling-estimation.pptx + .png                          the coupling and estimation diagram (editable PowerPoint)
#   gap-data.json                                                the data the gap slide draws (from R)
#
# Requires: the artifact output/pfm/<group>/interaction-weight-paths.rds
# (analysis/checks/interactionWeightPaths.R); Node with pptxgenjs (`npm install` in analysis/figures/pptx);
# PowerPoint on Windows for the PNG export of the two editable slides (analysis/figures/pptx/export-png.ps1).
# Every figure takes its palette, font and sizes from analysis/figures/style/figure-style.json.
args <- commandArgs(trailingOnly = TRUE); group <- if (length(args)) args[1] else "v6"
source("analysis/figures/R/load.R"); figuresLoad("analysis/figures/R")
out <- figuresOutputDir("doc"); dir.create(out, recursive = TRUE, showWarnings = FALSE)

# 1. the charts
for (id in c("doc-coefficients", "doc-frontier-fit", "doc-shares")) buildFigure(id, group = group, media = "doc")

# 2. the editable slides: data from R, drawing in pptxgenjs, PNG through PowerPoint
docGapData(group, file = file.path(out, "gap-data.json"))
pp <- "analysis/figures/pptx"
run <- function(cmd, args) {
  st <- system2(cmd, args, stdout = TRUE, stderr = TRUE); message(paste(st, collapse = "\n"))
  if (!is.null(attr(st, "status")) && attr(st, "status") != 0) stop(cmd, " failed", call. = FALSE)
}
run("node", c(file.path(pp, "fig-gap.js"), shQuote(file.path(out, "gap-data.json")), shQuote(file.path(out, "fig-gap.pptx"))))
run("node", c(file.path(pp, "fig-coupling-estimation.js"), shQuote(file.path(out, "fig-coupling-estimation.pptx"))))
for (f in c("fig-gap", "fig-coupling-estimation"))
  run("pwsh", c("-NoProfile", "-File", file.path(pp, "export-png.ps1"), shQuote(file.path(out, paste0(f, ".pptx"))),
                shQuote(file.path(out, paste0(f, ".png")))))
message("report figures written to ", out)
