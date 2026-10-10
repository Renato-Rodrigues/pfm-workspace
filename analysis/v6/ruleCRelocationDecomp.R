# Design note 0005 Phase 6: why rule C (held budget) moves far less abatement between regions in v6
# than in v5, although its 2050 regional prices move about as much (coupledV5V6Contrast.R).
#   Rscript analysis/v6/ruleCRelocationDecomp.R [old] [new]     (repo root; default v5 v6)
# For each group and resolution it compares -PFMlevelC with its theta = 0 null -PFMgate:
#   1. where the abatement moves: cumulative GHG change 2020-2100 per region and market (ETS, ES,
#      other; vm_co2eqMkt) and the remainder outside the markets (vm_co2eq minus their sum), by period;
#   2. how much nets out inside a region: gross relocation counted per region vs per region-market;
#   3. the price wedge that drives it: per region, market and year, the price over the null's, and its
#      dispersion across region-markets weighted by the null's emissions (relocation needs the price to
#      differ BETWEEN places; a uniform rise moves nothing);
#   4. the change between the groups, region by region: 1/2 (|d_new| - |d_old|).
# Emissions as coupledCostsAndAbatement.R: GtCeq x 44/12, annual interpolation, summed 2020-2100.
# Prices as the facts: the coupled-runs.rds market prices (ets, es; "other" pays the ES price).
# Output: output/pfm/<new>/coupling/rulec-relocation-decomp.rds and a printed summary.
`%||%` <- function(a, b) if (is.null(a)) b else a
a <- commandArgs(trailingOnly = TRUE)
OLD <- if (length(a) > 0) a[1] else "v5"; NEW <- if (length(a) > 1) a[2] else "v6"
ex <- new.env(); sys.source("analysis/coupled/extractCoupledResults.R", envir = ex); bin <- ex$gdxdumpBin()
C2C <- 44 / 12; YEARS <- 2020:2100
PERIODS <- list(`2020-2050` = 2020:2050, `2051-2100` = 2051:2100)
RES <- c("EU21", "H12")
suf <- c(OLD = "", NEW = "-v6"); names(suf) <- c(OLD, NEW)

art <- lapply(stats::setNames(c(OLD, NEW), c(OLD, NEW)), function(g) readRDS(file.path("output/pfm", g, "coupling/coupled-runs.rds")))
runOf <- function(g, res, key) {
  R <- art[[g]]$runs; R <- R[!R$superseded & R$resolution == res, ]
  t <- paste0(if (res == "EU21") "SSP2-EU21-" else "SSP2-", key, suf[[g]])
  r <- R[R$scenario == t, ]; if (nrow(r) != 1) stop(g, " ", res, " ", t, ": ", nrow(r), " live runs")
  list(title = t, gdx = file.path("output/remind-runs", g, res, r$dir, "fulldata.gdx"))
}
annual <- function(d) {   # d: year, region, [market], v -> annual series 2020-2100 per group
  key <- setdiff(names(d), c("year", "v"))
  do.call(rbind, lapply(split(d, d[key], drop = TRUE), function(x) {
    x <- x[order(x$year), ]
    cbind(x[rep(1, length(YEARS)), key, drop = FALSE], year = YEARS, v = stats::approx(x$year, x$v, xout = YEARS, rule = 2)$y)
  }))
}
emissions <- function(gdx) {   # annual GtCO2eq by region and market, plus the non-market remainder
  m <- ex$readSymbol(gdx, "vm_co2eqMkt", bin)
  m <- data.frame(year = as.integer(m[[1]]), region = m[[2]], market = m[[3]], v = C2C * as.numeric(m[[4]]))
  tot <- ex$readSymbol(gdx, "vm_co2eq", bin)
  tot <- data.frame(year = as.integer(tot[[1]]), region = tot[[2]], v = C2C * as.numeric(tot[[3]]))
  m <- annual(m); tot <- annual(tot)
  s <- stats::aggregate(v ~ region + year, m, sum)
  rest <- merge(tot, s, by = c("region", "year")); rest <- data.frame(region = rest$region, market = "non-market",
                                                                     year = rest$year, v = rest$v.x - rest$v.y)
  rbind(m[, c("region", "market", "year", "v")], rest)
}
prices <- function(g, res, title) {
  P <- art[[g]]$prices; P <- P[P$resolution == res & P$scenario == title & P$year >= 2030 & P$year <= 2100, ]
  rbind(data.frame(region = P$region, market = "ETS", year = P$year, p = P$ets),
        data.frame(region = P$region, market = "ES", year = P$year, p = P$es),
        data.frame(region = P$region, market = "other", year = P$year, p = P$es))
}
gross <- function(d) round(sum(abs(d)) / 2, 1)

out <- list(); summ <- list()
for (g in c(OLD, NEW)) for (res in RES) {
  c1 <- runOf(g, res, "PkBudg1000-PFMlevelC"); c0 <- runOf(g, res, "PkBudg1000-PFMgate")
  e1 <- emissions(c1$gdx); e0 <- emissions(c0$gdx)
  e <- merge(e1, e0, by = c("region", "market", "year"), suffixes = c("", "0")); e$d <- e$v - e$v0
  per <- lapply(PERIODS, function(y) {
    x <- e[e$year %in% y, ]
    stats::aggregate(cbind(d, v0) ~ region + market, x, sum)
  })
  all <- stats::aggregate(cbind(d, v0) ~ region + market, e, sum)
  reg <- stats::aggregate(cbind(d, v0) ~ region, all, sum)
  # the price wedge, weighted by the null's emissions in that region-market-year (markets only)
  p1 <- prices(g, res, c1$title); p0 <- prices(g, res, c0$title)
  w <- merge(merge(p1, p0, by = c("region", "market", "year"), suffixes = c("", "0")),
             e[e$market != "non-market", c("region", "market", "year", "v0")], by = c("region", "market", "year"))
  w <- w[w$p0 > 0 & w$v0 > 0, ]; w$lr <- log(w$p / w$p0)
  wedge <- do.call(rbind, lapply(split(w, w$year), function(x) {
    mu <- sum(x$v0 * x$lr) / sum(x$v0)
    data.frame(year = x$year[1], meanRatio = round(exp(mu), 3),
               sdLogRatio = round(sqrt(sum(x$v0 * (x$lr - mu)^2) / sum(x$v0)), 3))
  }))
  out[[g]][[res]] <- list(byRegionMarket = all, byRegion = reg, byPeriod = per, wedge = wedge,
                          runs = c(levelC = c1$title, null = c0$title))
  summ[[length(summ) + 1]] <- data.frame(group = g, res = res,
    netGlobal = round(sum(all$d), 1),
    grossRegion = gross(reg$d), grossRegionMarket = gross(all$d),
    grossMarketsOnly = gross(all$d[all$market != "non-market"]),
    nonMarketNet = round(sum(all$d[all$market == "non-market"]), 1),
    gross2050 = gross(stats::aggregate(d ~ region, per[[1]], sum)$d),
    gross2100 = gross(stats::aggregate(d ~ region, per[[2]], sum)$d),
    wedgeSd2030 = wedge$sdLogRatio[wedge$year == 2030], wedgeSd2050 = wedge$sdLogRatio[wedge$year == 2050],
    wedgeSd2070 = wedge$sdLogRatio[wedge$year == 2070], wedgeSd2100 = wedge$sdLogRatio[wedge$year == 2100],
    wedgeMean2050 = wedge$meanRatio[wedge$year == 2050])
}
S <- do.call(rbind, summ)
cat("\n== Rule C against its null: gross relocation (Gt CO2eq, 2020-2100) and the price wedge\n")
cat("   grossRegion = 1/2 sum_r |d_r| (as coupled-costs.json); grossRegionMarket counts the same per market;\n")
cat("   wedgeSd = emissions-weighted SD across region-markets of log(price / null price)\n")
print(S, row.names = FALSE)

contrib <- list()
for (res in RES) {
  o <- out[[OLD]][[res]]$byRegion; n <- out[[NEW]][[res]]$byRegion
  m <- merge(o[, c("region", "d")], n[, c("region", "d")], by = "region", all = TRUE, suffixes = c(".old", ".new"))
  m[is.na(m)] <- 0; m$contribution <- round((abs(m$d.new) - abs(m$d.old)) / 2, 1)
  m$d.old <- round(m$d.old, 1); m$d.new <- round(m$d.new, 1)
  m <- m[order(m$contribution), ]; contrib[[res]] <- m
  cat(sprintf("\n== %s: change in gross relocation by region, %s -> %s (sum %.1f Gt)\n", res, OLD, NEW, sum(m$contribution)))
  print(m, row.names = FALSE)
  for (g in c(OLD, NEW)) {
    x <- out[[g]][[res]]$byRegionMarket; x <- x[order(x$d), ]; x$d <- round(x$d, 1)
    big <- x[abs(x$d) >= 3, c("region", "market", "d")]
    cat(sprintf("   %s %s region-markets moving >= 3 Gt: %s\n", g, res,
                paste(sprintf("%s/%s %+.1f", big$region, big$market, big$d), collapse = ", ")))
  }
}
res <- list(groups = c(OLD, NEW), generated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), summary = S,
            contributions = contrib, detail = out)
saveRDS(res, file.path("output/pfm", NEW, "coupling/rulec-relocation-decomp.rds"))
cat("\nwrote", file.path("output/pfm", NEW, "coupling/rulec-relocation-decomp.rds"), "\n")
