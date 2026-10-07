# PFM's institution drivers against the PoliClim institution forecasts (pol_institutions_forecast.csv):
# is the history the same data, and how do the projections and their assumptions compare?
#   Rscript analysis/checks/policlimInstitutions.R [path to the PoliClim folder]   (from the repo root)
# Default folder: ../PoliClim projections. Output: output/checks/policlim-institutions.{rds,png} and a
# printed summary. Reads the raw sources (V-Dem v16 CSV, WGI 2025, SSP extensions) from the madrat
# sources folder, the cached calcVDem of data/madrat/v6 (the series PFM projects) and, for "PFM as used",
# the v6 SSP2 scenario panel output/pfm/v6/phase1/scen-NPi.rds (built by analysis/v6/phase1.R).
#
# What each column is (established by the history comparison below):
#   PoliClim Rule_of_Law = V-Dem v2xcl_rol (equality before the law and individual liberty);
#       PFM "Rule of Law (VDem)" = V-Dem v2x_rule (rule of law index) - a different index
#   PoliClim acc_ind_osp = V-Dem v2x_accountability_osp (overall accountability, 0-1);
#       PFM "Vertical Accountability (VDem)" = V-Dem v2x_veracc (interval scale; min-max normalised in the panel)
#   PoliClim gov_eff = 0.5 + 0.2 * WGI GE; PFM: WGI GE in history, the SSP extensions'
#       "Governance Index|Government Effectiveness" (Governance Model 2020, 0-1, to 2099) in scenarios
#   PoliClim ele_dem_ind = V-Dem v2x_polyarchy (not a PFM driver)
# Projections are compared on 0-1 scales: v2x_rule as is, v2x_veracc min-max normalised on the global
# country range (as the panel does), the SSP-extension GE as published; "PFM as used" is the panel itself
# (harmonised to history at 2023, fading by 2040).
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass); library(mrpfm) })
`%||%` <- function(a, b) if (is.null(a)) b else a
pcDir <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "../PoliClim projections" })
OUT <- "output/checks"; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
rc <- pfmResolveConfig("config.yml", group = "v6", verbose = FALSE)
src <- getConfig("sourcefolder")
if (!dir.exists(file.path(src, "VDem"))) src <- "C:/_data/work/remind_input_data/sources"
setConfig(cachefolder = rc$cachefolder, forcecache = TRUE, .verbose = FALSE)
SSP <- paste0("SSP", 1:5); YRS <- c(2025, 2030, 2040, 2050, 2060, 2070, 2080, 2090, 2100)
r3 <- function(d) { n <- vapply(d, is.numeric, logical(1)); d[n] <- lapply(d[n], round, 3); d }

# ── PoliClim ──────────────────────────────────────────────────────────────────────────────────
pc <- read.csv2(file.path(pcDir, "pol_institutions_forecast.csv"), stringsAsFactors = FALSE, dec = ".")
pc$iso <- pc$countrycode
pcH <- unique(pc[pc$scenario == "SSP2", c("iso", "year", "forward2", "Rule_of_Law", "acc_ind_osp", "gov_eff", "ele_dem_ind")])

# ── raw sources ───────────────────────────────────────────────────────────────────────────────
vd <- read.csv(file.path(src, "VDem", "V-Dem-CY-Core-v16.csv"), check.names = FALSE, stringsAsFactors = FALSE)
vd <- vd[vd$year >= 1996, c("country_text_id", "year", "v2x_rule", "v2xcl_rol", "v2x_veracc",
                            "v2x_accountability", "v2x_accountability_osp", "v2x_polyarchy")]
names(vd)[1] <- "iso"
vdC <- calcOutput("VDem", aggregate = FALSE)                       # what PFM reads and projects
accMin <- min(vdC[, , "Vertical Accountability (VDem)"], na.rm = TRUE)
accMax <- max(vdC[, , "Vertical Accountability (VDem)"], na.rm = TRUE)
normAcc <- function(v) (v - accMin) / (accMax - accMin)
vd$veraccNorm <- normAcc(vd$v2x_veracc)
wgi <- calcOutput("WGIindicator", aggregate = FALSE)
ge <- as.data.frame(wgi[, , "Government Effectiveness (WGI)"], rev = 2)[, c(1, 2, 4)]
names(ge) <- c("iso", "year", "wgiGE"); ge$iso <- as.character(ge$iso); ge$year <- as.integer(as.character(ge$year))

# ── 1. history: is it the same data? ──────────────────────────────────────────────────────────
h <- merge(merge(pcH, vd, by = c("iso", "year"), all.x = TRUE), ge, by = c("iso", "year"), all.x = TRUE)
geFit <- stats::lm(gov_eff ~ wgiGE, data = h); geMap <- stats::coef(geFit)
cmp <- function(a, b, label, transform = identity) {
  ok <- is.finite(h[[a]]) & is.finite(h[[b]]); x <- h[[a]][ok]; y <- transform(h[[b]][ok])
  data.frame(pair = label, n = sum(ok), countries = length(unique(h$iso[ok])), years = paste(range(h$year[ok]), collapse = "-"),
             cor = stats::cor(x, y), meanDiff = mean(x - y), maxAbsDiff = max(abs(x - y)),
             shareWithin0.005 = mean(abs(x - y) <= 0.005 + 1e-9), stringsAsFactors = FALSE)
}
hist <- rbind(
  cmp("Rule_of_Law", "v2xcl_rol", "Rule_of_Law vs V-Dem v2xcl_rol (equality before law, indiv. liberty)"),
  cmp("Rule_of_Law", "v2x_rule", "Rule_of_Law vs V-Dem v2x_rule (= PFM Rule of Law)"),
  cmp("acc_ind_osp", "v2x_accountability_osp", "acc_ind_osp vs V-Dem v2x_accountability_osp"),
  cmp("acc_ind_osp", "veraccNorm", "acc_ind_osp vs V-Dem v2x_veracc, min-max (= PFM Vertical Acc.)"),
  cmp("gov_eff", "wgiGE", "gov_eff vs WGI GE, linear map", function(v) stats::predict(geFit, data.frame(wgiGE = v))),
  cmp("ele_dem_ind", "v2x_polyarchy", "ele_dem_ind vs V-Dem v2x_polyarchy"))
# the two "rule of law" indices, in 2024: how different is the cross-section?
r24 <- h[h$year == 2024 & is.finite(h$v2x_rule) & is.finite(h$v2xcl_rol), ]
rolGap <- data.frame(meanXclRol = mean(r24$v2xcl_rol), meanXRule = mean(r24$v2x_rule),
                     rankCor = stats::cor(r24$v2xcl_rol, r24$v2x_rule, method = "spearman"),
                     largestGaps = paste(head(r24$iso[order(-abs(r24$v2xcl_rol - r24$v2x_rule))], 8), collapse = ","))

# ── 2. projections ────────────────────────────────────────────────────────────────────────────
pfmV <- do.call(rbind, lapply(c(SSP, "hold"), function(s) {
  p <- pfm:::.pfmProjectInstitutions(vdC, YRS, if (s == "hold") "hold" else "storyline", if (s == "hold") "SSP2" else s)
  d <- as.data.frame(p[, YRS, c("Rule of Law (VDem)", "Vertical Accountability (VDem)")], rev = 2)
  isRoL <- grepl("Rule", d[[3]])
  data.frame(iso = as.character(d[[1]]), year = as.integer(as.character(d[[2]])), scenario = s,
             var = ifelse(isRoL, "RoL", "Acc"), pfm = ifelse(isRoL, d$.value, normAcc(d$.value)), stringsAsFactors = FALSE)
}))
sx <- readxl::read_excel(file.path(src, "SSPextensions", "ssp-extensions_all_data.xlsx"), col_types = "text")
sx <- sx[sx$Variable == "Governance Index|Government Effectiveness" & sx$Scenario %in% SSP, ]
sxModel <- unique(sx$Model)
sxYrs <- c(head(YRS, -1), 2099)                                    # the extension ends in 2099: read as 2100
sxL <- do.call(rbind, lapply(sxYrs, function(yy)
  data.frame(region = sx$Region, scenario = sx$Scenario, year = if (yy == 2099) 2100L else as.integer(yy),
             pfm = suppressWarnings(as.numeric(sx[[as.character(yy)]])))))
sxL$iso <- suppressWarnings(countrycode::countrycode(sxL$region, "country.name", "iso3c"))
pfmG <- data.frame(sxL[!is.na(sxL$iso) & is.finite(sxL$pfm), c("iso", "year", "scenario", "pfm")], var = "GE")
pfmP <- rbind(pfmV, pfmG[, names(pfmV)])
# PFM as used: the v6 SSP2 scenario panel (normalised, harmonised at 2023, fading by 2040)
scenFile <- c("output/pfm/v6/phase1/scen-NPi.rds", Sys.glob("output/pfm/*/phase1*/scen-NPi.rds"))
scenFile <- scenFile[file.exists(scenFile)][1]
if (is.na(scenFile)) stop("no scen-NPi.rds: run analysis/v6/phase1.R first")
message("[policlim] PFM as used: ", scenFile)
scen <- readRDS(scenFile)
used <- c(RoL = "Rule of Law (VDem)", Acc = "Vertical Accountability (VDem)", GE = "Government Effectiveness (WGI)")
pfmU <- do.call(rbind, lapply(names(used), function(k) {
  d <- as.data.frame(scen[, intersect(YRS, getYears(scen, as.integer = TRUE)), used[[k]]], rev = 2)
  data.frame(iso = as.character(d[[1]]), year = as.integer(as.character(d[[2]])), scenario = "SSP2 as used",
             var = k, pfm = d$.value, stringsAsFactors = FALSE)
}))
pfmP <- rbind(pfmP, pfmU)

pcL <- do.call(rbind, lapply(list(c("RoL", "f_Rule_of_law"), c("Acc", "f_acc"), c("GE", "f_gov_eff")), function(p)
  data.frame(iso = pc$iso, year = pc$year, scenario = pc$scenario, region = pc$forward2, var = p[1], pc = pc[[p[2]]],
             stringsAsFactors = FALSE)))
pcL <- pcL[pcL$year %in% YRS, ]

fStart <- do.call(rbind, lapply(list(c("Rule_of_Law", "f_Rule_of_law"), c("acc_ind_osp", "f_acc"), c("gov_eff", "f_gov_eff")), function(p) {
  d <- pc[pc$scenario == "SSP2" & is.finite(pc[[p[1]]]), ]; dd <- abs(d[[p[1]]] - d[[p[2]]]) > 0.005
  data.frame(var = p[2], lastObserved = max(d$year), shareDiffering2023 = mean(dd[d$year == 2023]),
             shareDiffering2024 = mean(dd[d$year == 2024]),
             shareDiffering2025 = if (any(d$year == 2025)) mean(dd[d$year == 2025]) else NA)
}))
common <- intersect(unique(pcL$iso), unique(pfmP$iso[pfmP$var == "RoL"]))
spread <- function(d, val) do.call(rbind, lapply(split(d, list(d$var, d$scenario, d$year), drop = TRUE), function(z)
  data.frame(var = z$var[1], scenario = z$scenario[1], year = z$year[1], n = sum(is.finite(z[[val]])),
             mean = mean(z[[val]], na.rm = TRUE), sd = stats::sd(z[[val]], na.rm = TRUE),
             p10 = unname(stats::quantile(z[[val]], .1, na.rm = TRUE)), p90 = unname(stats::quantile(z[[val]], .9, na.rm = TRUE)))))
paths <- rbind(cbind(spread(pcL[pcL$iso %in% common, ], "pc"), source = "PoliClim"),
               cbind(spread(pfmP[pfmP$iso %in% common, ], "pfm"), source = "PFM"))

both <- merge(pcL, transform(pfmP, scenario = sub(" as used", "", scenario), used = grepl("as used", scenario)),
              by = c("iso", "year", "scenario", "var"))
chg <- do.call(rbind, lapply(split(both, list(both$var, both$scenario, both$used), drop = TRUE), function(d) {
  b <- d[d$year == 2025, c("iso", "pc", "pfm")]; out <- NULL
  for (yy in c(2050, 2100)) {
    e <- merge(b, d[d$year == yy, c("iso", "pc", "pfm")], by = "iso", suffixes = c("0", "1"))
    if (!nrow(e)) next
    dpc <- e$pc1 - e$pc0; dpf <- e$pfm1 - e$pfm0
    out <- rbind(out, data.frame(var = d$var[1], scenario = paste0(d$scenario[1], if (d$used[1]) " as used" else ""), to = yy,
      n = nrow(e), level2025cor = stats::cor(e$pc0, e$pfm0), meanChangePC = mean(dpc), meanChangePFM = mean(dpf),
      changeCor = suppressWarnings(stats::cor(dpc, dpf)), shareDecliningPC = mean(dpc < -0.01),
      shareDecliningPFM = mean(dpf < -0.01), sdRatio = stats::sd(e$pfm1) / stats::sd(e$pc1)))
  }
  out
}))
# PoliClim's regional structure: between-region share of the cross-country variance, 2025 vs 2100
regVar <- do.call(rbind, lapply(split(pcL[pcL$year %in% c(2025, 2100), ], list(pcL$var[pcL$year %in% c(2025, 2100)],
                                pcL$scenario[pcL$year %in% c(2025, 2100)], pcL$year[pcL$year %in% c(2025, 2100)]), drop = TRUE), function(d) {
  m <- stats::ave(d$pc, d$region); data.frame(var = d$var[1], scenario = d$scenario[1], year = d$year[1],
    betweenRegionShare = stats::var(m) / stats::var(d$pc))
}))
regMove <- aggregate(pc ~ var + scenario + region + year, pcL[pcL$year %in% c(2025, 2100), ], mean)

saveRDS(list(history = hist, rolGap = rolGap, geMap = geMap, sxModel = sxModel, forecastStart = fStart,
             paths = paths, change = chg, regionVariance = regVar, regions = regMove), file.path(OUT, "policlim-institutions.rds"))

# ── figure ────────────────────────────────────────────────────────────────────────────────────
library(ggplot2)
hh <- rbind(data.frame(var = "RoL", year = h$year, v = h$Rule_of_Law, iso = h$iso),
            data.frame(var = "Acc", year = h$year, v = h$acc_ind_osp, iso = h$iso),
            data.frame(var = "GE", year = h$year, v = h$gov_eff, iso = h$iso))
hh <- aggregate(v ~ var + year, hh[hh$year <= 2025 & hh$iso %in% common, ], mean)
pp <- paths[paths$scenario %in% c(SSP, "SSP2 as used"), ]
pp$ssp <- sub(" as used", "", pp$scenario)
pp$series <- ifelse(pp$source == "PoliClim", "PoliClim", ifelse(grepl("as used", pp$scenario), "PFM as used (SSP2 panel)", "PFM rule / SSP ext."))
lab <- c(RoL = "Rule of Law: PoliClim v2xcl_rol, PFM v2x_rule", Acc = "Accountability: PoliClim overall, PFM vertical (min-max)",
         GE = "Government Effectiveness (0-1)")
g <- ggplot(pp, aes(year, mean, colour = ssp, linetype = series)) +
  geom_line(data = hh, aes(year, v), inherit.aes = FALSE, colour = "grey40") +
  geom_line(linewidth = 0.7) + facet_wrap(~ var, labeller = as_labeller(lab)) +
  labs(y = "cross-country mean (unweighted, common countries)", x = NULL, colour = NULL, linetype = NULL,
       title = "PFM institution drivers vs PoliClim forecasts", subtitle = "grey: PoliClim history") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(file.path(OUT, "policlim-institutions.png"), g, width = 13, height = 5, dpi = 130)

# ── print ─────────────────────────────────────────────────────────────────────────────────────
options(width = 220)
cat("\n== 1. history: PoliClim vs the raw sources\n"); print(r3(hist), row.names = FALSE)
cat("   gov_eff = ", round(geMap[1], 4), " + ", round(geMap[2], 4), " * WGI GE\n", sep = "")
cat("\n== the two rule-of-law indices, 2024\n"); print(r3(rolGap), row.names = FALSE)
cat("\n== PoliClim forecast columns vs observed (SSP2)\n"); print(r3(fStart), row.names = FALSE)
cat("\n== PFM scenario GE source model:", paste(sxModel, collapse = ", "), "\n")
cat("\n== 2. cross-country mean / sd / p10 / p90\n")
pr <- paths[paths$year %in% c(2025, 2050, 2100), ]
print(r3(pr[order(pr$var, pr$scenario, pr$source, pr$year), c("var", "scenario", "source", "year", "n", "mean", "sd", "p10", "p90")]), row.names = FALSE)
cat("\n== 3. country-level agreement of the change from 2025\n"); print(r3(chg[order(chg$var, chg$scenario, chg$to), ]), row.names = FALSE)
cat("\n== 4. PoliClim: between-region share of variance\n")
print(r3(reshape(regVar, idvar = c("var", "scenario"), timevar = "year", direction = "wide")), row.names = FALSE)
cat("\n-> ", file.path(OUT, "policlim-institutions.{rds,png}"), "\n")
