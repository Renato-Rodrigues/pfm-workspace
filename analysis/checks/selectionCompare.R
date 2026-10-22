# The selected specification of a Run-Group against another group's, step by step (design note 0007 section 16).
#   Rscript analysis/checks/selectionCompare.R [group] [reference group]   (repo root; default v7 against v6)
#   -> output/pfm/<group>/selection-compare.rds
# Reads each group's diagnostics artifacts: frontier.rds (gamma, log-likelihood, coefficients), inference.rds (wild
# cluster bootstrap), influence.rds (leave one country out), temporal-validation.rds (trained to 2015),
# historical-replay.rds, and the sweep's walk (sweep.rds). Prints the interest terms side by side.
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v7"; r <- if (length(args) >= 2) args[2] else "v6"
rd <- function(gg, f) readRDS(file.path("output/pfm", gg, paste0(f, ".rds")))
short <- function(t) {
  t <- sub("Government.Effectiveness..WGI.", "GE", t); t <- sub("Rule.of.Law..VDem.", "RoL", t)
  t <- sub("[A-Za-z]+.Accountability..VDem.", "Acc", t)
  sub("Incumbent.Power", "Fossil", sub("Innovator.Power", "Clean", t))
}
summ <- function(gg) {
  fr <- rd(gg, "frontier"); inf <- rd(gg, "inference"); tv <- rd(gg, "temporal-validation"); hr <- rd(gg, "historical-replay")
  infl <- rd(gg, "influence")
  per <- lapply(c("Bulk", "Diffuse"), function(sec) {
    f <- fr$bySector[[sec]]; ll <- f$vcovCheck$logLikReported %||% NA_real_
    it <- inf$bySector[[sec]]$table; it <- it[grepl("Power", it$term), c("term", "estimate", "pWild")]
    il <- infl$bySector[[sec]]$byTerm; it$pMaxLOO <- il$pMax[match(it$term, il$term)]
    it$top <- il$topInfluencer[match(it$term, il$term)]
    list(sector = sec, gamma = f$gamma, logLik = ll,
         oosPearson = tv$bySector[[sec]]$metrics$pearson, oosRmse = tv$bySector[[sec]]$metrics$rmse,
         replayRmse = hr$bySector[[sec]]$metrics$rmseCoupled, replayPass = hr$bySector[[sec]]$metrics$pass, terms = it)
  })
  stats::setNames(per, c("Bulk", "Diffuse"))
}
a <- summ(g); b <- summ(r)
spec <- c(rd(g, "frontier")$spec, rd(r, "frontier")$spec)
cat(g, ":", spec[1], "\n", r, ":", spec[2], "\n")
options(width = 250)
for (sec in c("Bulk", "Diffuse")) {
  cat("\n=====", sec, "=====\n")
  cat(sprintf("%-28s %12s %12s\n", "", g, r))
  for (k in c("gamma", "logLik", "oosPearson", "oosRmse", "replayRmse")) cat(sprintf("%-28s %12.4g %12.4g\n", k, a[[sec]][[k]], b[[sec]][[k]]))
  ta <- a[[sec]]$terms; tb <- b[[sec]]$terms
  m <- merge(ta, tb, by = "term", all = TRUE, suffixes = c(paste0(".", g), paste0(".", r)))
  m$term <- short(m$term)
  print(m, row.names = FALSE, digits = 3)
}
saveRDS(list(group = g, reference = r, specs = spec, made = format(Sys.time(), "%Y-%m-%d %H:%M"), group_ = a, reference_ = b),
        file.path("output/pfm", g, "selection-compare.rds"))
