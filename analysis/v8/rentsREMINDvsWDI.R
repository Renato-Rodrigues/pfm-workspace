# v8 check (design note 0009 section 10): are REMIND's fossil rents good enough to drive the slack in the coupling?
#   Rscript analysis/v8/rentsREMINDvsWDI.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-rents-remind-vs-wdi.rds
# REMIND: per region and fuel, (pm_PEPrice x vm_fuExtr - vm_costFuEx) / vm_cesIO("inco"), % of GDP (as pfm's
# .pfmREMINDFossilRents), in the current-policy reference (NPi), the uncoupled 1000 Gt run and the coupled
# hold-the-price headline (EU21). World Bank: oil, gas and coal rents (% of GDP, the WDI cache of the v8 tests)
# aggregated to the EU21 regions with GDP at market exchange rates (WDI NY.GDP.MKTP.CD, downloaded once, cached).
# Reported: levels by region and fuel in the historical periods (REMIND 2005-2020 against WDI 3-year means centred on
# those years), the rank correlation across regions, and what the coupling actually uses: each region's rents
# relative to 2025 to 2100 in the three runs.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g); RD <- file.path("output/remind-runs", g, "EU21")
runOf <- function(pat) { d <- list.files(RD, pattern = pat); d <- d[!grepl("PFM", d) | grepl("PFMlevelBfix-", d)]; file.path(RD, sort(d, decreasing = TRUE)[1], "fulldata.gdx") }
RUNS <- c(NPi = runOf("^SSP2-EU21-NPi2025_"), PkBudg1000 = runOf("^SSP2-EU21-PkBudg1000_"), coupled = runOf(paste0("^SSP2-EU21-PkBudg1000-PFMlevelBfix-", g, "_")))
stopifnot(all(file.exists(RUNS)))
FU <- c(coal = "pecoal", oil = "peoil", gas = "pegas")

# price = "regional": pm_PEPrice, the price inside the region (below the world price for an exporter, by the trade
# costs); price = "world": pm_pvp(fuel) / pm_pvp(good), the world-market price, the World Bank's valuation.
remindRents <- function(gdx, price = c("regional", "world")) {
  price <- match.arg(price)
  rd <- function(s, ...) suppressWarnings(gdx::readGDX(gdx, s, react = "silent", restore_zeros = FALSE, ...))
  ex <- rd("vm_fuExtr", field = "l"); pr <- rd("pm_PEPrice"); co <- rd("vm_costFuEx", field = "l"); gdp <- rd("vm_cesIO", field = "l")[, , "inco"]
  if (price == "world") {
    pv <- rd("pm_pvp"); yy0 <- intersect(getYears(pr), getYears(pv))
    for (f in FU) for (r in getItems(pr, dim = 1)) pr[r, yy0, f] <- as.numeric(pv[, yy0, f] / pv[, yy0, "good"])
  }
  yy <- intersect(intersect(getYears(ex, as.integer = TRUE), getYears(pr, as.integer = TRUE)), getYears(gdp, as.integer = TRUE))
  yy <- yy[yy >= 2005 & yy <= 2100]
  out <- do.call(rbind, lapply(names(FU), function(f) {
    e <- dimSums(ex[, yy, grep(paste0("^", FU[[f]], "\\."), getNames(ex), value = TRUE)], dim = 3)
    r <- as.array(pr[, yy, FU[[f]]] * e - co[, yy, FU[[f]]])[, , 1]; gd <- as.array(gdp[, yy, ])[, , 1]
    data.frame(region = rep(rownames(r), ncol(r)), year = rep(yy, each = nrow(r)), fuel = f, rent = as.vector(r), gdp = as.vector(gd),
               value = as.vector(e) * as.vector(as.array(pr[, yy, FU[[f]]])[, , 1]), extraction = as.vector(as.array(e)[, , 1]),
               price = as.vector(as.array(pr[, yy, FU[[f]]])[, , 1]))
  }))
  out$pct <- 100 * out$rent / out$gdp
  out
}
R <- lapply(RUNS, remindRents)
RW <- lapply(RUNS, remindRents, price = "world")

# World Bank, aggregated to EU21 with GDP at market exchange rates
wdi <- readRDS(file.path(GD, "v8-wdi-rents.rds")); wdi <- wdi[nchar(wdi$iso3c) == 3, ]
gdpCache <- file.path(GD, "v8-wdi-gdp.rds")
gdpW <- if (file.exists(gdpCache)) readRDS(gdpCache) else {
  options(timeout = 900)
  x <- WDI::WDI(country = "all", indicator = c(gdp = "NY.GDP.MKTP.CD"), start = 1995, end = 2023, extra = FALSE)
  x <- x[nchar(x$iso3c) == 3, c("iso3c", "year", "gdp")]; saveRDS(x, gdpCache); x }
map <- utils::read.csv2("models/mrpfm/inst/extdata/regional/regionmapping_21_EU11.csv"); rmap <- stats::setNames(map$RegionCode, map$CountryCode)
w <- merge(wdi, gdpW, by = c("iso3c", "year")); w$region <- rmap[w$iso3c]; w <- w[!is.na(w$region) & is.finite(w$gdp), ]
wl <- do.call(rbind, lapply(names(FU), function(f) data.frame(region = w$region, year = w$year, fuel = f, pct = w[[f]], gdp = w$gdp)))
wl <- wl[is.finite(wl$pct), ]
wdiReg <- stats::aggregate(cbind(num = pct * gdp, gdp) ~ region + year + fuel, wl, sum); wdiReg$pct <- wdiReg$num / wdiReg$gdp
# 3-year means centred on REMIND's historical periods (2020: 2019-2021)
hy <- c(2005, 2010, 2015, 2020)
wdi3 <- do.call(rbind, lapply(hy, function(y) { d <- wdiReg[wdiReg$year %in% (y - 1):(y + 1), ]
  a <- stats::aggregate(pct ~ region + fuel, d, mean); a$year <- y; a }))
tot <- function(d) stats::aggregate(pct ~ region + year, d, sum)
cmp <- merge(tot(wdi3), tot(R$NPi[R$NPi$year %in% hy, ]), by = c("region", "year"), suffixes = c("_WDI", "_REMIND"))
tw <- tot(RW$NPi[RW$NPi$year %in% hy, ]); cmp$pct_REMINDworld <- tw$pct[match(paste(cmp$region, cmp$year), paste(tw$region, tw$year))]
cmpFuel <- merge(wdi3, R$NPi[R$NPi$year %in% hy, c("region", "year", "fuel", "pct")], by = c("region", "year", "fuel"), suffixes = c("_WDI", "_REMIND"))
rho <- sapply(hy, function(y) { d <- cmp[cmp$year == y, ]; stats::cor(d$pct_WDI, d$pct_REMIND, method = "spearman") })
rhoW <- sapply(hy, function(y) { d <- cmp[cmp$year == y, ]; stats::cor(d$pct_WDI, d$pct_REMINDworld, method = "spearman") })
# the world: rents over GDP summed over regions
world <- function(d, yrs) sapply(yrs, function(y) { x <- d[d$year == y, ]; 100 * sum(x$rent) / sum(x$gdp[!duplicated(x$region)]) })
worldW <- sapply(hy, function(y) { x <- wdi3[wdi3$year == y, ]; gd <- stats::aggregate(gdp ~ region, wdiReg[wdiReg$year %in% (y - 1):(y + 1), ], mean)
  t <- tot(x); sum(t$pct * gd$gdp[match(t$region, gd$region)]) / sum(gd$gdp) })
# what the coupling uses: rents relative to 2025
ratioOf <- function(RR, lab) do.call(rbind, lapply(names(RR), function(rn) { t <- tot(RR[[rn]]); b <- t[t$year == 2025, ]
  t$ratio <- t$pct / b$pct[match(t$region, b$region)]; t$run <- rn; t$price <- lab; t[t$year %in% c(2030, 2050, 2070, 2100), ] }))
ratio <- rbind(ratioOf(R, "regional"), ratioOf(RW, "world"))
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), runs = RUNS, remind = R, remindWorldPrice = RW, wdiRegional = wdiReg,
             compare = cmp, compareFuel = cmpFuel, spearman = stats::setNames(rho, hy), spearmanWorldPrice = stats::setNames(rhoW, hy),
             world = rbind(WDI = worldW, REMIND_NPi = world(R$NPi, hy), REMIND_NPi_worldPrice = world(RW$NPi, hy)), ratio = ratio),
        file.path(GD, "v8-rents-remind-vs-wdi.rds"))

options(width = 220)
cat("world fossil rents, % of GDP (", paste(hy, collapse = ", "), "):\n")
print(round(rbind(WDI = worldW, REMIND_NPi = world(R$NPi, hy), REMIND_NPi_worldPrice = world(RW$NPi, hy)), 2))
cat("\nrank correlation across the 21 regions (total rents), regional price:", paste(hy, round(rho, 2), collapse = " | "),
    "| world price:", paste(hy, round(rhoW, 2), collapse = " | "), "\n")
cat("\ntotal rents by region, % of GDP (WDI 3-year mean | REMIND NPi at the regional price | at the world price):\n")
x <- reshape(cmp, idvar = "region", timevar = "year", direction = "wide"); x <- x[order(-x$pct_WDI.2015), ]
print(x[1:9, ], digits = 2, row.names = FALSE)
cat("\nby fuel, 2015, regions with WDI rents > 1% of GDP in any fuel:\n")
f15 <- cmpFuel[cmpFuel$year == 2015, ]; keep <- unique(f15$region[f15$pct_WDI > 1])
print(reshape(f15[f15$region %in% keep, c("region", "fuel", "pct_WDI", "pct_REMIND")], idvar = "region", timevar = "fuel", direction = "wide"), digits = 2, row.names = FALSE)
cat("\nrents relative to 2025 (what the coupling uses), main exporters:\n")
r <- ratio[ratio$region %in% c("MEA", "REF", "CAZ", "SSA", "NEN", "USA"), c("price", "run", "region", "year", "ratio")]
rr <- reshape(r, idvar = c("price", "run", "region"), timevar = "year", direction = "wide")
print(rr[order(rr$region, rr$price, rr$run), ], digits = 2, row.names = FALSE)
