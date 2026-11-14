# A plausibility range for the severity theta from observed carbon prices (design note 0010 section 9, T6; the model
# paper's gap plan GP-8).
#   Rscript analysis/v8/thetaFromPrices.R [group]     (repo root; default v8) -> output/pfm/<group>/theta-from-prices.rds
# The coupling lets a region climb a share phi = 1 - theta * u of the step from its current-policy price to the
# cost-optimal one, u its ranking by the distance below the ceiling (0 least constrained, 1 most). Today's prices give a
# rough reading of theta: how much lower is the effective carbon price where u is higher? For the covered countries
# (and the EU21 / H12 regions), 2021-2023 means, per sector:
#   P        the effective carbon price (World Bank dashboard through mrpfm calcCarbonPrice: explicit carbon prices
#            scaled by coverage, US$2017/t; NOT fuel excise taxes - the OECD effective carbon rates would add them)
#   P_top    the mean price of the units in the lowest quintile of u (the least constrained)
#   theta    the slope through the origin of 1 - P / P_top on u, with a country bootstrap (999)
# Three caveats travel with the number: (1) CAPMF scores carbon-pricing instruments, so u and P are partly the same
# measurement (MODEL.md 5.3.1); (2) explicit prices only: where buildings & transport are priced through fuel taxes
# the price reads 0; (3) the coupling's theta acts on a step that does not exist yet (the gap to the cost-optimal
# price), today's dispersion is about levels. It is a plausibility range, not identification.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g); say <- function(...) message("[theta-from-prices:", g, "] ", ...)
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
P <- suppressMessages(madrat::calcOutput("CarbonPrice", regionmapping = "regionmapping_country.csv", subtype = "effectivePrice", aggregate = FALSE))
x0 <- readRDS(file.path("output/remind-inputs", g, "phi-anchor.rds")); w <- x0$weights
SEC <- c(Bulk = "bulk", Diffuse = "diffuse"); LAB <- c(Bulk = "P&I", Diffuse = "B&T"); YR <- 2021:2023; NB <- 999L; set.seed(20261114)
# the second price: the OECD net effective carbon rates (mrpfm readOECD_necp; fuel excise + carbon tax + permit price -
# subsidy, EUR/t at constant 2023 prices; 2021 and 2023), power & industry = electricity + industry, buildings &
# transport = buildings + road, each weighted by its emissions base. Read outside the Run-Group's madrat cache (a
# temporary cache folder), so the group's prepared cache is not touched; mrpfm from the source tree if the installed
# build does not have the reader yet.
oecd <- tryCatch({
  if (!exists("readOECD_necp", envir = asNamespace("mrpfm"))) suppressMessages(pkgload::load_all("models/mrpfm", quiet = TRUE))
  old <- madrat::getConfig(verbose = FALSE)[c("cachefolder", "forcecache")]
  suppressMessages(madrat::setConfig(cachefolder = file.path(tempdir(), "madrat-oecd"), forcecache = FALSE, .verbose = FALSE))
  on.exit(suppressMessages(madrat::setConfig(cachefolder = old$cachefolder, forcecache = old$forcecache, .verbose = FALSE)), add = TRUE)
  r <- suppressMessages(madrat::readSource("OECD_necp", subtype = "netRate")); e <- suppressMessages(madrat::readSource("OECD_necp", subtype = "emissions"))
  suppressMessages(madrat::setConfig(cachefolder = old$cachefolder, forcecache = old$forcecache, .verbose = FALSE))
  grp <- list(Bulk = c("electricity.all", "industry.all"), Diffuse = c("buildings.all", "road.all")); yrs <- c(2021, 2023)
  lapply(grp, function(k) { num <- 0; den <- 0
    for (y in yrs) for (v in k) { rr <- as.numeric(r[, y, v]); ee <- as.numeric(e[, y, v]); ok <- is.finite(rr) & is.finite(ee) & ee > 0
      num <- num + ifelse(ok, rr * ee, 0); den <- den + ifelse(ok, ee, 0) }
    stats::setNames(ifelse(den > 0, num / den, NA_real_), getItems(r, 1)) })
}, error = function(e) { say("OECD net effective carbon rates not read: ", conditionMessage(e)); NULL })
PRICES <- list("World Bank explicit carbon price (US$2017/t, 2021-2023)" = function(sec) { z <- P[, YR, SEC[[sec]]]; stats::setNames(rowMeans(as.array(z)[, , 1]), getItems(z, 1)) })
if (!is.null(oecd)) PRICES[["OECD net effective carbon rate (EUR2023/t, 2021 and 2023)"]] <- function(sec) oecd[[sec]]
fit <- function(u, p, q = 0.2) {
  ok <- is.finite(u) & is.finite(p); u <- u[ok]; p <- p[ok]
  top <- mean(p[u <= stats::quantile(u, q)]); if (!is.finite(top) || top <= 0) return(c(theta = NA_real_, pTop = top))
  y <- 1 - p / top; c(theta = sum(u * y) / sum(u^2), pTop = top) }
rows <- list(); pts <- list()
for (src in names(PRICES)) for (sec in names(SEC)) {
  price <- PRICES[[src]]
  cc <- x0$country[x0$country$sector == sec & x0$country$basis == "observed", ]
  gC <- 1 - cc$indexAnchor / cc$ceilingAnchor; u <- stats::setNames((gC - min(gC)) / diff(range(gC)), cc$region); p <- price(sec)[names(u)]
  ok <- is.finite(p); u <- u[ok]; p <- p[ok]
  est <- fit(u, p); b <- replicate(NB, { i <- sample(names(u), replace = TRUE); fit(u[i], p[i])[["theta"]] })
  rows[[paste(src, sec, "countries")]] <- data.frame(price = src, sector = LAB[[sec]], unit = "covered countries with a price series", n = length(u), pTop = est[["pTop"]], shareZeroPrice = mean(p <= 0),
    rankCorrelation = stats::cor(u, p, method = "spearman"), theta = est[["theta"]], p05 = stats::quantile(b, 0.05, na.rm = TRUE), p95 = stats::quantile(b, 0.95, na.rm = TRUE),
    thetaPricedOnly = fit(u[p > 0], p[p > 0])[["theta"]], nPriced = sum(p > 0))
  pts[[paste(src, sec, "countries")]] <- data.frame(price = src, sector = LAB[[sec]], unit = "country", id = names(u), u = u, value = p)
  for (res in names(x0$byResolution)) {
    b0 <- x0$byResolution[[res]]; map <- pfm:::.pfmResolveCountryMap(b0$mapping); r <- b0$region[b0$region$sector == sec, ]
    pa <- price(sec); k <- intersect(names(pa)[is.finite(pa)], names(map)); ww <- w[k]; ww[!is.finite(ww)] <- 0
    cover <- tapply(ww, map[k], sum)[r$region] / tapply(ifelse(is.finite(w[names(map)]), w[names(map)], 0), map, sum)[r$region]
    pr <- (tapply(pa[k] * ww, map[k], sum) / tapply(ww, map[k], sum))[r$region]; ur <- stats::setNames(r$u, r$region)
    keep <- is.finite(pr) & is.finite(cover) & cover >= 0.5; pr <- pr[keep]; ur <- ur[keep]     # regions with a price for at least half of their final energy
    e <- fit(ur, pr)
    rows[[paste(src, sec, res)]] <- data.frame(price = src, sector = LAB[[sec]], unit = paste(res, "regions (final-energy-weighted; a price for at least half of the region)"), n = length(ur), pTop = e[["pTop"]],
      shareZeroPrice = mean(pr <= 0), rankCorrelation = stats::cor(ur, pr, method = "spearman"), theta = e[["theta"]], p05 = NA, p95 = NA,
      thetaPricedOnly = fit(ur[pr > 0], pr[pr > 0])[["theta"]], nPriced = sum(pr > 0))
    pts[[paste(src, sec, res)]] <- data.frame(price = src, sector = LAB[[sec]], unit = res, id = names(ur), u = ur, value = as.numeric(pr))
  }
}
tab <- do.call(rbind, rows); rownames(tab) <- NULL
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), years = YR, prices = names(PRICES), table = tab, points = do.call(rbind, pts), declared = c(0.325, 0.50, 0.675),
            note = paste("theta: slope through the origin of 1 - P/P_top on u; P the effective explicit carbon price (World Bank dashboard, mrpfm calcCarbonPrice,",
                         "US$2017/t, mean 2021-2023), P_top the mean price of the lowest quintile of u; thetaPricedOnly: units with a positive price only.",
                         "Plausibility, not identification: CAPMF scores pricing instruments; fuel taxes are not in P."))
saveRDS(out, file.path(GD, "theta-from-prices.rds")); say("wrote ", file.path(GD, "theta-from-prices.rds"))
options(width = 220); print(tab, row.names = FALSE, digits = 3)
