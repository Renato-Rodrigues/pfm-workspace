# The institutional indicators of the PFM against those of PoliClim (IDOS; pol_institutions_forecast.csv):
# does converging on PoliClim's set change the fit, the edge of data, or the ceiling the coupling would see?
#   Rscript analysis/checks/policlimFormulation.R [group] [path to the PoliClim folder]   (repo root; default v6)
# Needs the scenario panel output/pfm/<group>/coupling/scen-PFMlevelBfix-<group>-democracy.rds
# (analysis/checks/edgeGateValidation.R) and the PoliClim CSV (default ../PoliClim projections).
#
# Indicator sets (the state-capability slot is WGI government effectiveness in both; PoliClim's gov_eff is
# 0.5 + 0.2 * WGI GE, analysis/checks/policlimInstitutions.R):
#   pfm        Rule of Law = V-Dem v2x_rule, accountability = V-Dem v2x_veracc (the v6 selection)
#   pcRoL      Rule of Law = V-Dem v2xcl_rol (PoliClim), accountability = v2x_veracc
#   pcAcc      Rule of Law = v2x_rule, accountability = V-Dem v2x_accountability_osp (PoliClim)
#   policlim   both PoliClim indicators
# crossed with the interaction weight: none, electoral democracy (v2x_polyarchy, which PoliClim projects),
# freedom of expression (v2x_freexp_altinf), liberal democracy (v2x_libdem).
# Each variant is the selected specification with only these changes, refitted as a frontier on the group's
# training panel (one fit), then evaluated on several scenario institution paths:
#   asSweep    the coupled hold-the-price panel as the v7 sweep sees it: PFM indicators on the storyline rule
#              (SSP2), added V-Dem indicators and weights held at the last panel year. The edge gate is read here.
#   held       every institution indicator and weight held at its 2025 value
#   pcSSP2/1/3c the PoliClim indicators (v2xcl_rol, v2x_accountability_osp, WGI GE, v2x_polyarchy) moved by
#              PoliClim's change from 2025 in that scenario, added to the panel's 2025 value. v2x_rule and
#              v2x_veracc, which PoliClim does not project, take the change of v2xcl_rol and of overall
#              accountability, rescaled by the ratio of cross-country SDs in 2025 (a declared mapping); freedom of
#              expression and liberal democracy held. Countries without a PoliClim forecast keep the asSweep path.
# Added V-Dem indicators: V-Dem v16 core, a centred 5-year moving average (as analysis/checks/vdemScreen.R), on
# their own 0-1 scale; the estimator standardises drivers, so the fit does not depend on the scale.
# Writes output/pfm/<group>/policlim-formulation.rds and prints the tables.
source("analysis/_common/_loadPfm.R")
suppressMessages({ library(madrat); library(magclass) })
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args) >= 1) args[1] else "v6"
pcDir <- if (length(args) >= 2) args[2] else "../PoliClim projections"
GD <- file.path("output/pfm", g)
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal")])
setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE)
say <- function(...) message("[policlim-formulation:", g, "] ", ...)

GE <- "Government Effectiveness (WGI)"; ROL <- "Rule of Law (VDem)"; VER <- "Vertical Accountability (VDem)"
label <- function(code) paste0(code, " (VDem)")
SETS <- list(pfm = c(GE, ROL, VER), pcRoL = c(GE, label("v2xcl_rol"), VER),
             pcAcc = c(GE, ROL, label("v2x_accountability_osp")),
             policlim = c(GE, label("v2xcl_rol"), label("v2x_accountability_osp")))
WEIGHTS <- c(none = NA, poly = label("v2x_polyarchy"), fexp = label("v2x_freexp_altinf"), libdem = label("v2x_libdem"))
ADD <- c("v2xcl_rol", "v2x_accountability_osp", "v2x_accountability", "v2x_polyarchy", "v2x_freexp_altinf", "v2x_libdem")
SHOW <- c("CHN", "IND", "USA", "DEU", "JPN", "BRA", "IDN", "ZAF", "RUS", "SAU", "TUR", "MEX")

# ---- panels ------------------------------------------------------------------------------------------------
vd <- data.table::fread(Sys.glob("C:/_data/work/remind_input_data/sources/VDem/V-Dem-CY-Core-v16.csv")[1],
                        select = c("country_text_id", "year", ADD, "v2x_rule", "v2x_veracc"))
panel <- loadTrainingPanel(jsonlite::read_json(file.path(GD, "manifest.json"))$panel_hash, rc$modelDir %||% "output/pfm/fit-cache")
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, "-democracy.rds")))
cty <- getItems(panel, 1); yrsP <- getYears(panel, as.integer = TRUE); yrsS <- getYears(scen, as.integer = TRUE)
ma5 <- function(v, yrs) sapply(yrs, function(t) mean(v[abs(as.integer(names(v)) - t) <= 2], na.rm = TRUE))
addP <- list(); addS <- list()
for (code in ADD) {
  mp <- new.magpie(cty, yrsP, label(code), fill = NA); ms <- new.magpie(getItems(scen, 1), yrsS, label(code), fill = NA)
  for (cc in intersect(cty, unique(vd$country_text_id))) {
    xc <- vd[vd$country_text_id == cc & vd$year >= min(yrsP) - 2 & vd$year <= max(yrsP) + 2, c("year", code), with = FALSE]
    s <- ma5(stats::setNames(xc[[code]], xc$year), yrsP); mp[cc, , ] <- s
    if (cc %in% getItems(scen, 1)) ms[cc, , ] <- s[length(s)]                       # held at the last panel year
  }
  med <- stats::median(as.vector(mp[, max(yrsP), ]), na.rm = TRUE)
  mp[is.na(mp)] <- med; ms[is.na(ms)] <- med
  addP[[code]] <- mp; addS[[code]] <- ms
}
panel <- mbind(panel, do.call(mbind, addP)); scenSweep <- mbind(scen, do.call(mbind, addS))

# ---- scenario institution paths ------------------------------------------------------------------------------
INST <- c(GE, ROL, VER, label(ADD))
later <- yrsS[yrsS > 2025]
scenHeld <- scenSweep
for (v in INST) scenHeld[, later, v] <- setYears(scenHeld[, 2025, v], NULL)

pc <- read.csv2(file.path(pcDir, "pol_institutions_forecast.csv"), stringsAsFactors = FALSE, dec = ".")
wgi <- calcOutput("WGIindicator", aggregate = FALSE)
geName <- grep("Government Effectiveness", getNames(wgi), value = TRUE)
geRange <- diff(range(wgi[, , geName], na.rm = TRUE))                                # panel min-max range of WGI GE
sdC <- function(v) stats::sd(as.vector(scenSweep[, 2025, v]), na.rm = TRUE)
# PoliClim projects neither v2x_rule nor v2x_veracc: they take the change of the nearest PoliClim index, rescaled by
# the ratio of the cross-country standard deviations in 2025 (a change of one SD in one is one SD in the other)
PCVAR <- list(c("f_Rule_of_law", label("v2xcl_rol"), 1), c("f_acc", label("v2x_accountability_osp"), 1),
              c("f_gov_eff", GE, 1 / (0.2 * geRange)), c("f_ele_dem", label("v2x_polyarchy"), 1),
              c("f_Rule_of_law", ROL, sdC(ROL) / sdC(label("v2xcl_rol"))),
              c("f_acc", VER, sdC(VER) / sdC(label("v2x_accountability_osp"))))
scenPC <- function(ssp) {
  out <- scenSweep; d <- pc[pc$scenario == ssp, ]
  for (p in PCVAR) {
    for (cc in intersect(getItems(out, 1), unique(d$countrycode))) {
      z <- d[d$countrycode == cc, ]; f <- stats::approx(z$year, z[[p[1]]], xout = c(2025, later), rule = 2)$y
      if (!all(is.finite(f))) next
      out[cc, later, p[2]] <- as.vector(out[cc, 2025, p[2]]) + (f[-1] - f[1]) * as.numeric(p[3])
    }
  }
  out
}
SCEN <- list(asSweep = scenSweep, held = scenHeld, pcSSP2 = scenPC("SSP2"), pcSSP1 = scenPC("SSP1"), pcSSP3c = scenPC("SSP3c"))
pcCovered <- intersect(cty, unique(pc$countrycode))

# ---- fit once, evaluate on each scenario ------------------------------------------------------------------
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
cfg0 <- function(sec) Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
gate <- pfm:::.pfmEdgeGateDefaults()
unl <- function(x) if (is.null(x)) NULL else unlist(x)
evalScen <- function(ff, b, cfg, sector, sd, withGate) {
  sDf <- preparePanelData(
    data = sd, sector = sector, actorPowerDrivers = unl(cfg$actorPowerDrivers), actorPowerIndex = unl(cfg$actorPowerIndex),
    instQualityDrivers = unl(cfg$instQualityDrivers), controlDrivers = setdiff(unl(cfg$controlDrivers), "lagged_ecp"),
    regionMappingFixedEffects = cfg$regionMappingFixedEffects, useMundlak = FALSE, gdpGovInteraction = FALSE,
    driverScaling = ff$driverScaling, trendFreezeYear = max(ff$data$year, na.rm = TRUE),
    outcomeVar = ff$outcomeVar %||% "Policy Stringency", apTransform = cfg$apTransform %||% "linear")
  sDf$lagged_ecp <- 0
  lv <- ff$model$xlevels$regionFE %||% levels(ff$data$regionFE)
  if (!is.null(lv) && "regionFE" %in% names(sDf)) {
    fe <- as.character(sDf$regionFE); fe[!fe %in% lv] <- if ("Other" %in% lv) "Other" else lv[1]
    sDf$regionFE <- factor(fe, levels = lv)
  }
  sDf <- pfm:::.pfmDriverGuard(sDf, pfm:::.driverSupportRanges(ff$data, ff$driverScaling))$df
  tt <- stats::delete.response(stats::terms(ff$formula))
  mm <- stats::model.matrix(tt, stats::model.frame(tt, data = sDf, na.action = stats::na.pass))
  sh <- intersect(colnames(mm), names(b))
  s <- 10 * stats::plogis(as.numeric(mm[, sh, drop = FALSE] %*% b[sh]))
  covered <- unique(as.character(ff$data$region))
  d <- data.frame(region = as.character(sDf$region), year = sDf$year, s = s, stringsAsFactors = FALSE)
  d <- d[d$region %in% covered & is.finite(d$s) & d$year %in% c(2025, 2050, 2100), ]
  w <- reshape(d, idvar = "region", timevar = "year", direction = "wide")
  edge <- if (withGate) tryCatch(pfm:::.pfmEdgeGate(b, sDf, mm, ff$data, years = c(2025, 2100), gate = gate),
                                 error = function(e) list(pass = NA, capShift = NA, against = NULL)) else NULL
  list(country = w, edge = edge)
}
rows <- list(); ctyRows <- list(); coefRows <- list()
for (sec in c("Bulk", "Diffuse")) for (st in names(SETS)) for (wn in names(WEIGHTS)) {
  cf <- cfg0(sec); cf$instQualityDrivers <- SETS[[st]]
  if (!is.na(WEIGHTS[[wn]])) cf$interactionWeight <- WEIGHTS[[wn]]
  say(sec, " ", st, " weight ", wn)
  ff <- tryCatch(do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sec, estimator = "frontier", indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE),
    pfm:::.pfmSpecArgs(cf))), error = function(e) { say("  failed: ", conditionMessage(e)); NULL })
  if (is.null(ff)) next
  cfAll <- stats::coef(ff$model); b <- cfAll[!names(cfAll) %in% c("sigmaSq", "gamma")]
  se <- tryCatch(sqrt(pmax(diag(stats::vcov(ff$model)), 0))[names(b)], error = function(e) rep(NA_real_, length(b)))
  ll <- as.numeric(stats::logLik(ff$model)); gm <- if ("gamma" %in% names(cfAll)) cfAll[["gamma"]] else NA_real_
  inst <- grepl("Effectiveness|Rule|Accountab|accountab|v2x", names(b))
  coefRows[[length(coefRows) + 1]] <- data.frame(sector = sec, set = st, weight = wn, term = names(b)[inst],
                                                 beta = unname(b[inst]), se = unname(se[inst]), stringsAsFactors = FALSE)
  for (sn in names(SCEN)) {
    ev <- evalScen(ff, b, cf, sec, SCEN[[sn]], withGate = sn %in% c("asSweep", "pcSSP2"))
    w <- ev$country
    r <- w$s.2100 / w$s.2025
    rows[[length(rows) + 1]] <- data.frame(
      sector = sec, set = st, weight = wn, scen = sn, logLik = ll, gamma = gm, n = nrow(ff$data),
      gatePass = if (is.null(ev$edge)) NA else isTRUE(ev$edge$pass), capShift = ev$edge$capShift %||% NA_real_,
      against = if (is.null(ev$edge$against)) "" else paste(unique(ev$edge$against$region), collapse = " "),
      med2025 = stats::median(w$s.2025), med2050 = stats::median(w$s.2050), med2100 = stats::median(w$s.2100),
      medRatio = stats::median(w$s.2100) / stats::median(w$s.2025), shareFalling = mean(r < 0.99, na.rm = TRUE),
      sdLog2100 = stats::sd(log(w$s.2100)), stringsAsFactors = FALSE)
    ctyRows[[length(ctyRows) + 1]] <- cbind(data.frame(sector = sec, set = st, weight = wn, scen = sn, stringsAsFactors = FALSE),
                                            w[w$region %in% SHOW, ])
  }
}
res <- do.call(rbind, rows); ctyRes <- do.call(rbind, ctyRows); coefs <- do.call(rbind, coefRows)
base <- unique(res[res$set == "pfm" & res$weight == "none", c("sector", "logLik")]); names(base)[2] <- "logLik0"
res <- merge(res, base, by = "sector"); res$dLogLik <- res$logLik - res$logLik0

# ---- the indicators themselves: overlap and where the sample's autocracies sit (2023) ----------------------
samp <- unique(as.character(readRDS(file.path(GD, "frontier.rds"))$bySector$Bulk$scores$region))
y23 <- max(yrsP)
val <- function(nm) stats::setNames(as.vector(panel[samp, y23, nm]), samp)
IND <- c(pfmRoL = ROL, pcRoL = label("v2xcl_rol"), pfmAcc = VER, pcAcc = label("v2x_accountability_osp"),
         accInterval = label("v2x_accountability"), GE = GE, poly = label("v2x_polyarchy"),
         fexp = label("v2x_freexp_altinf"), libdem = label("v2x_libdem"))
M <- sapply(IND, val)
position <- do.call(rbind, lapply(names(IND), function(k) {
  v <- M[, k]; z <- (v - mean(v)) / stats::sd(v)
  data.frame(indicator = k, var = IND[[k]], zCHN = z[["CHN"]], zSAU = z[["SAU"]], zRUS = z[["RUS"]], zVNM = if ("VNM" %in% samp) z[["VNM"]] else NA,
             neighboursCHN = sum(abs(z[setdiff(samp, c("CHN", "SAU"))] - z[["CHN"]]) <= 1),
             p10 = unname(stats::quantile(v, .1)), p90 = unname(stats::quantile(v, .9)), stringsAsFactors = FALSE)
}))
corr <- stats::cor(M)
# within-country (over time) correlation: how far the two variants move together inside a country
within <- function(a, b) {
  x <- as.array(panel[samp, , IND[[a]]])[, , 1]; y <- as.array(panel[samp, , IND[[b]]])[, , 1]
  stats::cor(as.vector(x - rowMeans(x, na.rm = TRUE)), as.vector(y - rowMeans(y, na.rm = TRUE)), use = "complete.obs")
}
withinCor <- data.frame(pair = c("RoL: v2x_rule vs v2xcl_rol", "Acc: v2x_veracc vs v2x_accountability_osp"),
                        between2023 = c(corr["pfmRoL", "pcRoL"], corr["pfmAcc", "pcAcc"]),
                        within = c(within("pfmRoL", "pcRoL"), within("pfmAcc", "pcAcc")))

saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), sets = SETS, weights = WEIGHTS,
             results = res, country = ctyRes, coefs = coefs, position = position, corr = corr, withinCor = withinCor, indicators2023 = M,
             mapFactor = c(RoL = sdC(ROL) / sdC(label("v2xcl_rol")), Acc = sdC(VER) / sdC(label("v2x_accountability_osp"))),
             sample = samp, pcCovered = pcCovered, missingInPoliClim = setdiff(samp, pcCovered), gate = gate),
        file.path(GD, "policlim-formulation.rds"))

# ---- print -------------------------------------------------------------------------------------------------
options(width = 250)
r3 <- function(d) { n <- vapply(d, is.numeric, logical(1)); d[n] <- lapply(d[n], round, 3); d }
cat("\n== Sample countries without a PoliClim forecast:", paste(setdiff(samp, pcCovered), collapse = " "), "\n")
cat("\n== Indicators (sample, ", y23, "): position of the autocracies and spread\n", sep = ""); print(r3(position), row.names = FALSE)
cat("\n== Correlations (sample, ", y23, ")\n", sep = ""); print(round(corr, 2))
cat("\n== Between- and within-country correlation of each pair\n"); print(r3(withinCor), row.names = FALSE)
cat("\n== Fit and edge gate (asSweep panel)\n")
f <- res[res$scen == "asSweep", c("sector", "set", "weight", "logLik", "dLogLik", "gamma", "gatePass", "capShift", "against")]
print(r3(f[order(f$sector, f$set, f$weight), ]), row.names = FALSE)
cat("\n== Median ceiling (index 0-10) and its change, by scenario institution path\n")
p <- res[, c("sector", "set", "weight", "scen", "med2025", "med2050", "med2100", "medRatio", "shareFalling", "sdLog2100", "gatePass")]
print(r3(p[order(p$sector, p$set, p$weight, p$scen), ]), row.names = FALSE)
cat("\n-> ", file.path(GD, "policlim-formulation.rds"), "\n")
