# The theory gate (design note 0007 section 15) on a swept group, offline: H1-H2 on every spec, H3 on named ones.
#   Rscript analysis/checks/theoryGateCalibration.R [group] [spec name ...]   (repo root; default v7)
# H1-H2 read sweep.rds `coefficients` (the sweep's fits), on the maximin pool (gatePass). H3 refits the named specs
# (default: the first 12 of the pool that pass H1-H2, the selected spec, and v6's selected spec) as frontiers on the
# group's training panel. v6's spec is also scored on v6's own panel. Writes output/pfm/<group>/theory-gate-calibration.rds.
source("analysis/_common/_loadPfm.R")
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v7"
GD <- file.path("output/pfm", g)
say <- function(...) message("[theory-gate:", g, "] ", ...)
s <- readRDS(file.path(GD, "sweep.rds")); m <- s$maximin$PolicyStringency
specs <- stats::setNames(s$specs, vapply(s$specs, `[[`, "", "name"))
pool <- m$model[m$gatePass %in% TRUE][order(m$rank[m$gatePass %in% TRUE])]
scr <- pfm:::.pfmTheoryScreen(s$coefficients, pool, c("Bulk", "Diffuse"))
scr$rank <- m$rank[match(scr$model, m$model)]
say("maximin pool ", length(pool), " | pass H1-H2 ", sum(scr$pass), " | in the top 100 ranks ", sum(scr$pass & scr$rank <= 100))
lab <- function(x) sub(" lev ctl:", " ctl:", sub("WGIge\\|RoL\\|", "", x))
fails <- table(unlist(regmatches(scr$reason, gregexpr("H[12]", scr$reason))))
say("failures by hypothesis (sector-level counts): ", paste(names(fails), fails, collapse = ", "))

sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))[[1]]$name
want <- if (length(args) >= 2) args[-1] else unique(c(head(scr$model[scr$pass], 12), sel))
man <- function(gg) jsonlite::read_json(file.path("output/pfm", gg, "manifest.json"))
modelDir <- "output/pfm/fit-cache"
options(pfm.panel = man(g)$panel)
panel <- loadTrainingPanel(man(g)$panel_hash, modelDir)
h3 <- function(cfg, panelData) do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) {
  ff <- do.call(estimatePolicyStringencyModel, c(list(data = panelData, sector = sec, estimator = "frontier", indexMax = 10,
                                                      modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))
  b <- stats::coef(ff$model); b <- b[!names(b) %in% c("sigmaSq", "gamma")]
  co <- pfm:::.pfmTheoryCoherence(b, ff$data)
  data.frame(sector = sec, driver = co$driver, share = co$share, fossil = b[[co$driver]],
             logLik = as.numeric(stats::logLik(ff$model)))
}))
rows <- list()
for (nm in want) {
  r <- h3(specs[[nm]], panel); r$model <- nm; r$rank <- m$rank[match(nm, m$model)]
  r$H1H2 <- scr$pass[match(nm, scr$model)]; rows[[nm]] <- r
  say(lab(nm), " | rank ", r$rank[1], " | H1-H2 ", r$H1H2[1], " | H3 share P&I ", round(r$share[1], 2), ", B&T ", round(r$share[2], 2))
}
sel6 <- yaml::read_yaml(pfm:::.pfmSelectedModels("output/pfm/v6"))[[1]]
options(pfm.panel = man("v6")$panel)
r6 <- h3(sel6, loadTrainingPanel(man("v6")$panel_hash, modelDir)); r6$model <- paste("v6:", sel6$name); r6$rank <- NA; r6$H1H2 <- NA
say("v6 selected on v6's panel | H3 share P&I ", round(r6$share[1], 2), ", B&T ", round(r6$share[2], 2))
v6scr <- pfm:::.pfmTheoryScreen(readRDS("output/pfm/v6/sweep.rds")$coefficients, sel6$name, c("Bulk", "Diffuse"))
say("v6 selected, H1-H2 on v6's sweep: ", if (v6scr$pass) "pass" else v6scr$reason)
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), screen = scr, h3 = do.call(rbind, c(rows, list(r6))),
             v6screen = v6scr), file.path(GD, "theory-gate-calibration.rds"))
options(width = 250)
print(head(transform(scr[scr$pass, c("rank", "model")], model = lab(model)), 15), row.names = FALSE)
