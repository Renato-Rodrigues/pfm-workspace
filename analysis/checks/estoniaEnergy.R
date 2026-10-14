# Can Estonia come back into the estimation (PITFALLS section 27; TODO "Estonia back into the estimation")?
# The negative PE|Coal is gone in the IEA 2025 edition. This check asks the remaining question: does the energy data
# the panel is built from (calcPE and calcFE, both from calcIO, as cached for the group) describe Estonia's energy
# system, oil shale above all, well enough for its actor-power drivers to be trusted?
#   Rscript analysis/checks/estoniaEnergy.R [group]        (repo root; default v6)
# Reads, all from caches (forcecache):
#   calcIeaEnergyBalances (ieaVersion "latest")   the IEA balances by product and flow: the reference. No installed
#                                                 package defines it any more; the cached file of the workstation
#                                                 REMIND input cache is read directly (2025 edition: data to 2023)
#   calcPE, calcFE (ieaVersion "latest")          what iamHistoricalData() reads for the panel's energy drivers
#   the mrenergy IO mapping (structuremappingIO_inputs.csv)  which oil-shale flows reach REMIND's items
#   the group's training panel                    Estonia's drivers next to its neighbours
# Writes output/checks/estonia-energy-<group>.rds and prints the tables.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass); library(mrremind) })
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v6"
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
GD <- file.path("output/pfm", g)
OUT <- "output/checks"; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
YRS <- 2000:2023
NEI <- c("EST", "LVA", "LTU", "FIN", "POL", "CZE", "DEU", "SWE")
r4 <- function(d) { n <- vapply(d, is.numeric, logical(1)); d[n] <- lapply(d[n], round, 4); d }

# ---- 1. the IEA balances: what Estonia's energy system is --------------------------------------------------------
iebFile <- Sys.glob(file.path(c(rc$cachefolder, unlist(rc$cacheSources), "C:/_data/work/remind_input_data/cache/default"),
                               "calcIeaEnergyBalances-*-3474774a.rds"))[1]
if (is.na(iebFile)) stop("no cached calcIeaEnergyBalances (ieaVersion latest) found")
ieb <- readRDS(iebFile); if (!is.magpie(ieb)) ieb <- ieb$x
message("[estonia] IEA balances: ", iebFile, ", years to ", max(getYears(ieb, as.integer = TRUE)))
yI <- intersect(YRS, getYears(ieb, as.integer = TRUE))
iv <- function(iso, item) as.vector(ieb[iso, yI, item])
osFlows <- c("INDPROD", "TES", "MAINELEC", "MAINCHP", "AUTOELEC", "AUTOCHP", "MAINHEAT", "TCOALLIQ", "TOTIND", "NONENUSE")
os <- data.frame(year = yI, TES_total = iv("EST", "TOTAL.TES"))
for (f in osFlows) { it <- paste0("OILSHALE.", f); os[[paste0("oilshale_", f)]] <- if (it %in% getNames(ieb)) iv("EST", it) else NA_real_ }
os$oilshaleShareOfTES <- os$oilshale_TES / os$TES_total

# ---- 2. which oil-shale flows the IO mapping carries into REMIND items ------------------------------------------------
mp <- utils::read.csv2(system.file("extdata/sectoral/structuremappingIO_inputs.csv", package = "mrenergy"), stringsAsFactors = FALSE)
osMap <- mp[mp$iea_product == "OILSHALE", c("iea_flows", "REMINDitems_in", "REMINDitems_out", "REMINDitems_tech")]
osMapped <- osMap[nzchar(osMap$REMINDitems_in) & !is.na(osMap$REMINDitems_in), ]

# ---- 3. calcPE / calcFE: what the panel reads ---------------------------------------------------------------------------
pe <- calcOutput("PE", ieaVersion = "latest", aggregate = FALSE, warnNA = FALSE)
fe <- calcOutput("FE", ieaVersion = "latest", aggregate = FALSE, warnNA = FALSE)
yP <- intersect(yI, getYears(pe, as.integer = TRUE))
peItems <- c("PE (EJ/yr)", "PE|Coal (EJ/yr)", "PE|Oil (EJ/yr)", "PE|Gas (EJ/yr)", "PE|Biomass (EJ/yr)")
peEST <- data.frame(year = yP, sapply(peItems, function(i) as.vector(pe["EST", yP, i])), check.names = FALSE)
peEST$TES_IEA <- iv("EST", "TOTAL.TES")[match(yP, yI)]
peEST$PEoverTES <- peEST$`PE (EJ/yr)` / peEST$TES_IEA
# PE / TES for every country: is Estonia an outlier? (PE counts inputs to conversion; TES also counts direct use,
# so the ratio is below 1 everywhere; what matters is Estonia against the rest)
cty <- intersect(getItems(pe, 1), getItems(ieb, 1))
ratio <- function(y) { p <- as.vector(pe[cty, y, "PE (EJ/yr)"]); t <- as.vector(ieb[cty, y, "TOTAL.TES"]); ok <- t > 0.01; stats::setNames(p[ok] / t[ok], cty[ok]) }
r22 <- ratio(2022)
peTesRank <- data.frame(iso = names(r22), ratio = unname(r22))[order(r22), ]
# the panel's fossil-dependence numerator and denominator with oil shale added back (inputs to power, CHP, heat)
osPow <- -(os$oilshale_MAINELEC + os$oilshale_MAINCHP + os$oilshale_AUTOELEC + os$oilshale_AUTOCHP + os$oilshale_MAINHEAT)
osPow[!is.finite(osPow)] <- 0
fossil <- peEST$`PE|Coal (EJ/yr)` + peEST$`PE|Oil (EJ/yr)` + peEST$`PE|Gas (EJ/yr)`
fixShare <- data.frame(year = yP, fossilSharePE = fossil / peEST$`PE (EJ/yr)`,
                       oilshalePowerMissing = osPow[match(yP, yI)],
                       fossilSharePEwithOilShale = (fossil + osPow[match(yP, yI)]) / (peEST$`PE (EJ/yr)` + osPow[match(yP, yI)]))
# negatives in the items the panel uses, any country
usedPE <- c("PE|Coal (EJ/yr)", "PE|Oil (EJ/yr)", "PE|Gas (EJ/yr)", "PE|Wind|Electricity (EJ/yr)", "PE|Solar|Electricity (EJ/yr)",
            "PE|Uranium|Electricity (EJ/yr)", "PE|Hydro|Electricity (EJ/yr)", "PE|Geothermal|Electricity (EJ/yr)", "PE (EJ/yr)")
usedFE <- c("FE|Industry|Liquids|Fossil (EJ/yr)", "FE|Industry|Gases|Fossil (EJ/yr)", "FE|Industry|Solids|Fossil (EJ/yr)",
            "FE|Industry (EJ/yr)", "FE|Electricity (EJ/yr)", "FE (EJ/yr)", "FE|Transport|Liquids|Biomass (EJ/yr)",
            "FE|Transport|Liquids|Fossil (EJ/yr)")
negs <- function(x, items, yy) {
  a <- as.array(x[, yy, intersect(items, getNames(x))])
  w <- which(a < -1e-6, arr.ind = TRUE)
  if (!nrow(w)) return(data.frame(iso = character(0), year = integer(0), item = character(0), value = numeric(0)))
  data.frame(iso = dimnames(a)[[1]][w[, 1]], year = dimnames(a)[[2]][w[, 2]], item = dimnames(a)[[3]][w[, 3]], value = a[w])
}
negPE <- negs(pe, usedPE, yP); negFE <- negs(fe, usedFE, intersect(yP, getYears(fe, as.integer = TRUE)))
yF <- intersect(yP, getYears(fe, as.integer = TRUE))
feEST <- data.frame(year = yF, sapply(usedFE, function(i) as.vector(fe["EST", yF, i])), check.names = FALSE)
feEST$FEoverTFC <- feEST$`FE (EJ/yr)` / iv("EST", "TOTAL.TFC")[match(yF, yI)]
r22fe <- { t <- as.vector(ieb[cty, 2022, "TOTAL.TFC"]); f <- as.vector(fe[cty, 2022, "FE (EJ/yr)"]); ok <- t > 0.01; stats::setNames(f[ok] / t[ok], cty[ok]) }

# ---- 4. the panel: Estonia's drivers next to its neighbours ---------------------------------------------------------------
panel <- loadTrainingPanel(jsonlite::read_json(file.path(GD, "manifest.json"))$panel_hash, rc$modelDir %||% "output/pfm/fit-cache")
drv <- grep("^(Incumbent Power|Innovator Power)", getNames(panel), value = TRUE)
drv <- c(drv, grep("^Policy Stringency", getNames(panel), value = TRUE))
pan <- do.call(rbind, lapply(intersect(NEI, getItems(panel, 1)), function(cc) {
  d <- as.data.frame(panel[cc, c(2005, 2015, 2023), drv], rev = 2); names(d) <- c("iso", "year", "var", "value"); d }))
panW <- reshape(pan, idvar = c("var", "year"), timevar = "iso", direction = "wide")
names(panW) <- sub("^value\\.", "", names(panW))

saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), iebFile = iebFile, oilShale = os, oilShaleMapping = osMap,
             oilShaleMapped = osMapped, peEST = peEST, peTesRatio2022 = peTesRank, fossilShareFix = fixShare,
             negativesPE = negPE, negativesFE = negFE, feEST = feEST, feTfcRatio2022 = r22fe, panel = panW),
        file.path(OUT, paste0("estonia-energy-", g, ".rds")))

options(width = 220)
cat("\n== 1. IEA balances (2025 edition), Estonia, EJ: oil shale\n"); print(r4(os[os$year %in% c(2000, 2005, 2010, 2015, 2018, 2020:2023), ]), row.names = FALSE)
cat("\n== 2. Oil-shale flows that the IO mapping carries into REMIND items (all others map to nothing)\n"); print(osMapped, row.names = FALSE)
cat("\n== 3a. calcPE for Estonia against IEA TES\n"); print(r4(peEST[peEST$year %in% c(2000, 2005, 2010, 2015, 2018, 2020:2023), ]), row.names = FALSE)
cat("\n== 3b. PE / TES in 2022, all countries with TES > 0.01 EJ: Estonia's rank\n")
cat("   Estonia:", round(r22[["EST"]], 3), " rank", which(peTesRank$iso == "EST"), "of", nrow(peTesRank),
    "; median", round(stats::median(r22), 3), "; neighbours:", paste(sprintf("%s %.2f", intersect(NEI, names(r22)), r22[intersect(NEI, names(r22))]), collapse = ", "), "\n")
print(r4(head(peTesRank, 8)), row.names = FALSE)
cat("\n== 3c. fossil share of PE, as the panel sees it and with oil shale in power and heat added back\n"); print(r4(fixShare[fixShare$year %in% c(2005, 2010, 2015, 2018, 2020:2023), ]), row.names = FALSE)
cat("\n== 3d. negative values in the PE / FE items the panel uses (any country,", min(yP), "-", max(yP), "):", nrow(negPE), "PE,", nrow(negFE), "FE\n")
if (nrow(negPE)) print(head(negPE, 20)); if (nrow(negFE)) print(head(negFE, 20))
cat("\n== 3e. calcFE for Estonia (FE / IEA TFC); FE/TFC in 2022: Estonia", round(r22fe[["EST"]], 3), ", median", round(stats::median(r22fe), 3), "\n")
print(r4(feEST[feEST$year %in% c(2005, 2010, 2015, 2020:2023), ]), row.names = FALSE)
cat("\n== 4. the panel's drivers and policy stringency, Estonia and neighbours\n"); print(r4(panW), row.names = FALSE)
cat("\n-> ", file.path(OUT, paste0("estonia-energy-", g, ".rds")), "\n")
