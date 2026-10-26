# Global net CO2 emissions by period to 2100, and the year they reach zero, for the hold-the-price runs of a group.
#   Rscript analysis/checks/emissions2100.R <group>   (repo root) -> output/pfm/<group>/coupling/emissions-2100.rds
# Within the reporting horizon only (author, 2026-10-25: results are reported to 2100, nothing after). Reads vm_emiAll
# (co2) from each run's fulldata.gdx, summed over regions and sectors, in Gt CO2 a year (the gdx is in GtC).
a <- commandArgs(trailingOnly = TRUE); g <- a[1]
ex <- new.env(); sys.source("analysis/coupled/extractCoupledResults.R", envir = ex); bin <- ex$gdxdumpBin()
cr <- readRDS(file.path("output/pfm", g, "coupling", "coupled-runs.rds"))$runs
cr <- cr[!cr$superseded & grepl("PFMlevelBfix|PFMgateBfix", cr$scenario) & !grepl("Min", cr$scenario), ]
C2CO2 <- 44 / 12
one <- function(res, dir, scen) {
  d <- ex$readSymbol(file.path("output/remind-runs", g, res, dir, "fulldata.gdx"), "vm_emiAll", bin)
  names(d)[1:2] <- c("year", "region"); d <- d[d[[ncol(d) - 1]] == "co2", , drop = FALSE]
  y <- as.integer(d$year); v <- as.numeric(d[[ncol(d)]]) * C2CO2
  e <- tapply(v, y, sum); e <- e[as.integer(names(e)) >= 2020 & as.integer(names(e)) <= 2100]
  yrs <- as.integer(names(e)); z <- yrs[which(e <= 0)][1]
  # cumulative 2020-2050 and 2020-2100, Gt CO2, annual interpolation between the periods
  cum <- function(y1) { a <- stats::approx(yrs, as.numeric(e), xout = 2020:y1, rule = 2)$y; sum(a) }
  data.frame(resolution = res, scenario = sub("^SSP2-(EU21-)?PkBudg1000-", "", scen), e2050 = e[["2050"]],
             e2070 = e[["2070"]], e2090 = e[["2090"]], e2100 = e[["2100"]], netZeroYear = if (is.na(z)) NA_integer_ else z,
             cum2050 = cum(2050), cum2100 = cum(2100))
}
out <- do.call(rbind, lapply(seq_len(nrow(cr)), function(i) one(cr$resolution[i], cr$dir[i], cr$scenario[i])))
out <- out[order(out$resolution, out$scenario), ]
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), table = out),
        file.path("output/pfm", g, "coupling", "emissions-2100.rds"))
options(width = 160); cat("global net CO2 (Gt CO2 a year), hold the price; netZeroYear = first period at or below zero (NA: not by 2100)\n")
print(out, row.names = FALSE, digits = 3)
