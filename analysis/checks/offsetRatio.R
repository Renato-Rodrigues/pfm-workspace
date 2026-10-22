# Offsetting interaction terms: does a spec's conditional effect rest on large terms of opposite sign that cancel?
#   Rscript analysis/checks/offsetRatio.R [group] [top]   (repo root; default v7, top 300) -> output/pfm/<group>/offset-ratio.rds
# For each interest driver d (clean energy, fossil; share or per-person form) and sector, over the sample's
# country-years, the contribution of its interactions is c_k = beta_dk * z_k * w (z_k the standardised moderator, w the
# interaction weight where the spec has one). The offset ratio is
#     R_d = sum_k sd(c_k) / sd(sum_k c_k):
# 1 when the terms add up, large when they cancel (opposite signs on correlated moderators: rule of law correlates
# 0.84 with overall accountability, 0.79 with vertical accountability on v7's sample). Coefficients: sweep.rds
# `coefficients` (the satP fits). Specs: the top `top` maximin ranks, plus the selected one. Design note 0007 section 14.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v7"; TOP <- if (length(args) >= 2) as.integer(args[2]) else 300
GD <- file.path("output/pfm", g)
s <- readRDS(file.path(GD, "sweep.rds")); m <- s$maximin$PolicyStringency; cf <- s$coefficients
specs <- stats::setNames(s$specs, vapply(s$specs, `[[`, "", "name"))
man <- jsonlite::read_json(file.path(GD, "manifest.json"))
panel <- loadTrainingPanel(man$panel_hash, "output/pfm/fit-cache")
smp <- unique(as.character(readRDS(file.path(GD, "frontier.rds"))$bySector[[1]]$scores$region))
yrs <- intersect(2000:2023, as.integer(sub("y", "", getYears(panel))))
col <- function(v) { x <- as.vector(panel[smp, yrs, v]); (x - mean(x, na.rm = TRUE)) / stats::sd(x, na.rm = TRUE) }
raw <- function(v) as.vector(panel[smp, yrs, v])
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))[[1]]$name
want <- unique(c(m$model[m$rank <= TOP], sel))
cfs <- cf[cf$model %in% want & grepl("_x_", cf$term) & grepl("Power", cf$term), ]
one <- function(nm, sec) {
  x <- cfs[cfs$model == nm & cfs$sector == sec, ]
  if (!nrow(x)) return(NULL)
  wv <- pfm:::.pfmIwParse(specs[[nm]]$interactionWeight)
  w <- if (!is.null(wv$variable) && !identical(wv$variable, "none")) pmin(pmax(raw(wv$variable), 0), 1) else 1
  pr <- do.call(rbind, strsplit(x$term, "_x_", fixed = TRUE))
  instName <- function(safe) { i <- match(safe, make.names(unlist(specs[[nm]]$instQualityDrivers))); unlist(specs[[nm]]$instQualityDrivers)[i] }
  do.call(rbind, lapply(unique(pr[, 1]), function(d) {
    k <- which(pr[, 1] == d)
    cc <- sapply(k, function(i) {
      wi <- if (identical(w, 1)) 1 else pfm:::.pfmIwFactor(data.frame(interactionWeight__ = w,
                     interactionWeightScope__ = if (is.null(wv$scope)) NA else match(wv$scope, names(pfm:::.pfmIwScopes))), pr[i, 2])
      x$estimate[i] * col(instName(pr[i, 2])) * wi
    })
    gross <- sum(apply(cc, 2, stats::sd, na.rm = TRUE)); net <- stats::sd(rowSums(cc), na.rm = TRUE)
    data.frame(model = nm, sector = sec, driver = d, gross = gross, net = net, ratio = gross / net,
               maxAbsCoef = max(abs(x$estimate[k])))
  }))
}
tab <- do.call(rbind, lapply(want, function(nm) do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) one(nm, sec)))))
tab$rank <- m$rank[match(tab$model, m$model)]
worst <- stats::aggregate(ratio ~ model + rank, tab, max)
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), top = TOP, table = tab, worstBySpec = worst),
        file.path(GD, "offset-ratio.rds"))
options(width = 250)
cat("largest offset ratio per spec, top", TOP, "maximin ranks: quantiles\n"); print(round(quantile(worst$ratio, c(.1, .25, .5, .75, .9, 1)), 2))
cat("\nselected (", sel, "):\n"); print(tab[tab$model == sel, ], row.names = FALSE, digits = 3)
x <- tab[grepl("^X-1791 .*satAP( iw:fexp| iw:poly)?$", tab$model), ]; cat("\nv6 spec and its weighted twins:\n"); print(x, row.names = FALSE, digits = 3)
