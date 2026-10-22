# Wild-cluster-bootstrap inference for named specifications of a swept Run-Group (design note 0007 section 14).
#   Rscript analysis/checks/inferenceScreen.R <group> <B> <spec name> [spec name ...]   (repo root)
# The same refit and bootstrap as the group's pfm-inference step (runPFMInference: satP refit, Rademacher wild cluster
# bootstrap-t on country, seed 42), on the group's own training panel, for specs other than the selected one.
# Writes output/pfm/<group>/inference-screen.rds.
source("analysis/_common/_loadPfm.R")
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- args[1]; B <- as.integer(args[2]); want <- args[-(1:2)]
GD <- file.path("output/pfm", g)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
man <- jsonlite::read_json(file.path(GD, "manifest.json"))
options(pfm.panel = man$panel)
panel <- loadTrainingPanel(man$panel_hash, rc$modelDir %||% "output/pfm/fit-cache")
specs <- readRDS(file.path(GD, "sweep.rds"))$specs
specs <- stats::setNames(specs, vapply(specs, `[[`, "", "name"))
out <- list()
for (nm in want) for (sec in c("Bulk", "Diffuse")) {
  fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "satP", indexMax = 10,
                                                       modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(specs[[nm]])))
  w <- computeWildClusterBootstrap(fit, B = B, seed = 42)
  ct <- unclass(fit$coeftest); w$pAsymptotic <- ct[match(w$term, rownames(ct)), 4]
  out[[paste(nm, sec)]] <- cbind(spec = nm, sector = sec, w)
  message("[inference-screen:", g, "] ", nm, " | ", sec, " done")
}
tab <- do.call(rbind, out); rownames(tab) <- NULL
saveRDS(list(group = g, B = B, made = format(Sys.time(), "%Y-%m-%d %H:%M"), table = tab), file.path(GD, "inference-screen.rds"))
options(width = 250)
th <- tab[grepl("Power", tab$term) & !grepl("Government|GDP", tab$term), ]
th$spec <- sub(" lev ctl:[^ ]* fe:OECDp", "", sub("WGIge\|RoL\|", "", th$spec))
print(th[, c("spec", "sector", "term", "estimate", "pAsymptotic", "pWild")], row.names = FALSE, digits = 3)
