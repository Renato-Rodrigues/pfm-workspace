# Why does a hold-the-budget run not peak? The path of cumulative CO2 after 2100 and where the late emissions come from
# (PITFALLS.md 26: a peak year at the horizon end is a failed budget).
#   Rscript analysis/checks/budgetPeak.R <group>   (repo root) -> output/pfm/<group>/coupling/budget-peak.rds
# For every hold-the-budget (-PFMlevelC*) run and the no-politics reference of each resolution: cumulative CO2
# (pm_actualbudgetco2) 2090-2150, and the regional CO2 emissions (vm_emiAll, co2, summed over sectors as REMIND reports
# them in emiCO2 when available) in 2100-2150 against the no-politics run.
a <- commandArgs(trailingOnly = TRUE); g <- a[1]
ex <- new.env(); sys.source("analysis/coupled/extractCoupledResults.R", envir = ex); bin <- ex$gdxdumpBin()
cr <- readRDS(file.path("output/pfm", g, "coupling", "coupled-runs.rds"))$runs
cr <- cr[!cr$superseded, ]
rd <- function(res, dir, s) { d <- ex$readSymbol(file.path("output/remind-runs", g, res, dir, "fulldata.gdx"), s, bin); d }
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), paths = list(), regional = list())
for (res in unique(cr$resolution)) {
  R <- cr[cr$resolution == res & grepl("PFMlevelC|PFMgate-", cr$scenario), ]
  for (i in seq_len(nrow(R))) {
    b <- rd(res, R$dir[i], "pm_actualbudgetco2"); y <- as.integer(b[[1]]); v <- as.numeric(b[[ncol(b)]])
    out$paths[[paste(res, R$scenario[i])]] <- data.frame(resolution = res, scenario = R$scenario[i], year = y, cum = v)
  }
  gate <- R[grepl("PFMgate-", R$scenario), ]
  emi <- function(dir) { d <- tryCatch(rd(res, dir, "vm_emiAll"), error = function(e) NULL)
    if (is.null(d)) return(NULL)
    names(d)[1:2] <- c("year", "region"); d <- d[d[[ncol(d) - 1]] == "co2" | grepl("^co2$", d[[ncol(d) - 1]]), , drop = FALSE]
    data.frame(year = as.integer(d$year), region = d$region, v = as.numeric(d[[ncol(d)]])) }
  e0 <- emi(gate$dir[1])
  if (!is.null(e0)) for (i in which(grepl("PFMlevelC", R$scenario))) {
    e1 <- emi(R$dir[i]); if (is.null(e1)) next
    m <- merge(stats::aggregate(v ~ year + region, e1, sum), stats::aggregate(v ~ year + region, e0, sum), by = c("year", "region"), suffixes = c(".run", ".gate"))
    m <- m[m$year >= 2100, ]
    out$regional[[paste(res, R$scenario[i])]] <- cbind(resolution = res, scenario = R$scenario[i], m)
  }
}
saveRDS(out, file.path("output/pfm", g, "coupling", "budget-peak.rds"))
P <- do.call(rbind, out$paths); P <- P[P$year %in% c(2090, 2100, 2110, 2130, 2150), ]
W <- reshape(P, idvar = c("resolution", "scenario"), timevar = "year", direction = "wide")
options(width = 200); cat("cumulative CO2 (Gt), from 2020:\n"); print(transform(W, scenario = sub("^SSP2-(EU21-)?PkBudg1000-", "", scenario)), row.names = FALSE, digits = 5)
if (length(out$regional)) {
  cat("\nregional CO2 emissions after 2100, run minus no-politics (GtC/yr as in the gdx), mean 2110-2150:\n")
  Rg <- do.call(rbind, out$regional); Rg <- Rg[Rg$year >= 2110, ]
  s <- stats::aggregate(cbind(d = v.run - v.gate, run = v.run) ~ resolution + scenario + region, Rg, mean)
  for (k in unique(paste(s$resolution, s$scenario))) { x <- s[paste(s$resolution, s$scenario) == k, ]
    x <- x[order(-x$d), ]; cat(sub("SSP2-(EU21-)?PkBudg1000-", "", k), ": total", round(sum(x$d), 3), "| largest:",
      paste(sprintf("%s %+.3f", x$region[1:4], x$d[1:4]), collapse = ", "), "\n") }
}
