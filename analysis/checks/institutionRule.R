# The gap-closure institution rule (design note 0008), computed with the model's own code, for the figures and the
# design note:
#   Rscript analysis/checks/institutionRule.R [group] [PoliClim folder]   (repo root; default v7)
#   -> output/pfm/<group>/institution-rule.rds
# Three parts:
#   1. against PoliClim's SSP2 projections, on PoliClim's own indicators and 2025 values: the rule
#      (pfm::.pfmProjectInstitutions "gapclosure", with the rates of pfmInstitutionGapClosureRates) and the current SSP2
#      rule ("convergence" = "storyline" for SSP2), applied to PoliClim's history 1996-2025; fit per indicator;
#   2. the model's own scenario panels (pfm::panelDataScenario) on the headline coupled energy system (EU21, hold the
#      price, fading limit), under storyline, gapclosure and hold: the institution series as the frontier reads them
#      (normalised, harmonised to the 2023 panel value), and the size of the step from history into the projection;
#   3. the strength k(t) of each sector on those panels (pfm::computeStrengthPath, theta = 0.50): what the rule does to
#      the coupling before any coupled run.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
a <- commandArgs(trailingOnly = TRUE)
g <- if (length(a) > 0) a[1] else "v7"
pcDir <- if (length(a) > 1) a[2] else "../PoliClim projections"
say <- function(...) message("[institution-rule:", g, "] ", ...)
T0 <- 2025
RULES <- c(current = "storyline", `gap closure` = "gapclosure", held = "hold")

# ---- 1. PoliClim ----------------------------------------------------------------------------------------------------
pc <- read.csv2(file.path(pcDir, "pol_institutions_forecast.csv"), stringsAsFactors = FALSE, dec = ".")
IND <- c(rol = "f_Rule_of_law", acc = "f_acc")
NAME <- c(rol = "Rule of Law (VDem)", acc = "Vertical Accountability (VDem)")   # names that select the model's rate
for (k in IND) pc[[k]] <- suppressWarnings(as.numeric(pc[[k]]))
s2 <- pc[pc$scenario == "SSP2", ]
YP <- seq(2025, 2100, 5)
part1 <- do.call(rbind, lapply(names(IND), function(k) {
  h <- s2[s2$year >= 1996 & s2$year <= T0, c("countrycode", "year", IND[[k]])]; names(h) <- c("c", "year", "v")
  cc <- sort(unique(h$c[h$year == T0 & is.finite(h$v)]))
  arr <- array(NA_real_, c(length(cc), length(1996:T0), 1), list(cc, paste0("y", 1996:T0), NAME[[k]]))
  for (i in seq_len(nrow(h))) if (h$c[i] %in% cc) arr[h$c[i], paste0("y", h$year[i]), 1] <- h$v[i]
  x <- as.magpie(arr, spatial = 1, temporal = 2)
  proj <- function(rule) {
    if (rule == "gapclosure") {   # the model's rule (pfm::.pfmGapClosurePath) on PoliClim's scale: top = best value observed
      x0 <- stats::setNames(h$v[h$year == T0], h$c[h$year == T0])[cc]; top <- max(h$v, na.rm = TRUE)
      v <- outer(x0, YP, function(z, t) pfm:::.pfmGapClosurePath(z, t, T0, pfm:::.pfmGapClosureRate(NAME[[k]]), top))
      return(data.frame(c = rep(cc, length(YP)), year = rep(YP, each = length(cc)), v = as.vector(v))) }
    o <- pfm:::.pfmProjectInstitutions(x, YP, rule, "SSP2")
    data.frame(c = rep(cc, length(YP)), year = rep(YP, each = length(cc)), v = as.vector(as.array(o)[, , 1])) }
  pcv <- s2[s2$year %in% YP & s2$countrycode %in% cc, c("countrycode", "year", IND[[k]])]; names(pcv) <- c("c", "year", "v")
  hist <- h[h$c %in% cc, ]
  rbind(data.frame(indicator = k, source = "history", hist),
        data.frame(indicator = k, source = "PoliClim SSP2", pcv),
        data.frame(indicator = k, source = "gap closure", proj("gapclosure")),
        data.frame(indicator = k, source = "current", proj("storyline")))
}))
fit1 <- do.call(rbind, lapply(names(IND), function(k) {
  d <- part1[part1$indicator == k, ]
  w <- function(s, y) { z <- d[d$source == s & d$year == y, c("c", "v")]; stats::setNames(z$v, z$c) }
  x0 <- w("PoliClim SSP2", T0); p1 <- w("PoliClim SSP2", 2100); cc <- names(x0)
  dP <- p1[cc] - x0[cc]
  do.call(rbind, lapply(c("gap closure", "current"), function(s) {
    dR <- w(s, 2100)[cc] - x0[cc]; ok <- is.finite(dP) & is.finite(dR)
    data.frame(indicator = k, rule = s, n = sum(ok), r2Change = 1 - sum((dR - dP)[ok]^2) / sum((dP - mean(dP[ok]))[ok]^2),
               meanChangeRule = mean(dR[ok]), meanChangePoliClim = mean(dP[ok]), declinePoliClim = mean(dP[ok] < -0.005))
  }))
}))
rates <- pfmInstitutionGapClosureRates()
say("part 1: PoliClim, ", length(unique(part1$c)), " countries")

# ---- 2. the model's scenario panels -----------------------------------------------------------------------------------
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"),
                                   forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
pd <- pfm:::.pfmPanelDefForGroup(file.path("output/pfm", g), rc$panel)
options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy",
                                   "overallAccountability"), names(pd))])
CR <- readRDS(file.path("output/pfm", g, "coupling", "coupled-runs.rds"))$runs
run <- CR[!CR$superseded & CR$resolution == "EU21" & CR$scenario == paste0("SSP2-EU21-PkBudg1000-PFMlevelBfix-", g), ]
gdx <- file.path("output/remind-runs", g, "EU21", run$dir, "fulldata.gdx")
hc <- file.path(tempdir(), "inst-rule-hist.rds")
SER <- c("Rule of Law (VDem)", "Vertical Accountability (VDem)", "Freedom of Expression (VDem)",
         "Government Effectiveness (WGI)")
panels <- lapply(RULES, function(r) {
  say("scenario panel, institutions = ", r)
  suppressWarnings(suppressMessages(panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                                                      outputRegionMappingFile = "country", ssp = "SSP2", institutions = r,
                                                      histYears = pfm:::.pfmPanelYears(pd), movingAverage = pfm:::.pfmPanelMA(pd),
                                                      ieaVersion = pd$ieaVersion, geothermal = pd$geothermal, histCache = hc)))
})
# the history the frontier was fitted on (the harmonisation's historical panel: annual, normalised, five-year mean)
hp <- readRDS(hc)$panel
histSer <- do.call(rbind, lapply(SER, function(s) { v <- as.array(hp[, , s])[, , 1]; yy <- as.integer(sub("^y", "", colnames(v)))
  data.frame(series = s, c = rep(rownames(v), length(yy)), year = rep(yy, each = nrow(v)), v = as.vector(v)) }))
histSer <- histSer[is.finite(histSer$v) & histSer$year >= 2010, ]
anc <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")
wts <- anc$weights
part2 <- do.call(rbind, lapply(names(panels), function(rn) {
  p <- panels[[rn]]; yy <- getYears(p, as.integer = TRUE)
  do.call(rbind, lapply(SER, function(s) {
    v <- as.array(p[, , s])[, , 1]
    data.frame(rule = rn, series = s, c = rep(rownames(v), length(yy)), year = rep(yy, each = nrow(v)), v = as.vector(v))
  }))
}))
part2$weight <- unname(wts[part2$c])
# the step into the projection: from the history panel's 2023 value to the scenario's 2025 value, per year, against the
# history's own year-on-year changes 2010-2023 (95th percentiles over countries)
seam <- do.call(rbind, lapply(split(part2, list(part2$rule, part2$series), drop = TRUE), function(d) {
  h <- histSer[histSer$series == d$series[1], ]
  h23 <- h[h$year == 2023, ]; s25 <- d[d$year == 2025, ]; m <- merge(h23, s25, by = "c", suffixes = c(".h", ".s"))
  hs <- unlist(lapply(split(h, h$c), function(z) abs(diff(z$v[order(z$year)]))))
  data.frame(rule = d$rule[1], series = d$series[1], stepP95 = unname(stats::quantile(abs(m$v.s - m$v.h) / 2, .95, na.rm = TRUE)),
             stepMax = max(abs(m$v.s - m$v.h) / 2, na.rm = TRUE), histP95 = unname(stats::quantile(hs, .95, na.rm = TRUE)))
}))

# ---- 3. the strength on those panels ----------------------------------------------------------------------------------
strength <- do.call(rbind, lapply(names(panels), function(rn) {
  s <- computeStrengthPath(anc, panels[[rn]], theta = 0.5)$strength
  cbind(rule = rn, s[, c("sector", "year", "k", "outOfSupportShare")])
}))
say("part 3: strength on ", length(panels), " panels")

# ---- 4. the literature series: government effectiveness and rule of law (Andrijevic et al. 2020) ---------------------
# The model takes government effectiveness from the SSP extensions (Andrijevic et al. 2020), normalises it to [0, 1] by
# the series' own minimum and maximum over the WGI years (panelDataScenario), and harmonises it to the WGI-based panel
# value at 2023, the offset fading by 2040: it uses Andrijevic's changes, anchored to WGI levels. Andrijevic's
# Rule-of-Law Index (SSP1-3) is not used by the model (it uses V-Dem's); it is an independent reference for the rule.
srcDir <- Sys.getenv("PFM_SSPEXT_SOURCES", "C:/_data/work/remind_input_data/sources")
madrat::setConfig(sourcefolder = srcDir, cachefolder = file.path(tempdir(), "sspext"), .verbose = FALSE)
sx <- suppressWarnings(suppressMessages(madrat::readSource("SSPextensions", convert = FALSE)))
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE)
wgi <- suppressWarnings(suppressMessages(madrat::calcOutput("WGIindicator", aggregate = FALSE)))
wgiYears <- getYears(wgi, as.integer = TRUE)
tidy <- function(m, source, ssp, indicator) {
  a <- as.array(m)[, , 1]; yy <- as.integer(sub("^y", "", colnames(a)))
  d <- data.frame(source = source, ssp = ssp, indicator = indicator, c = rep(rownames(a), length(yy)),
                  year = rep(yy, each = nrow(a)), v = as.vector(a))
  d[is.finite(d$v), ]
}
part4 <- list()
for (ind in c(ge = "Governance Index|Government Effectiveness", rol = "Rule-of-Law Index")) {
  key <- if (grepl("Effectiveness", ind)) "ge" else "rol"
  ref <- sx[, intersect(getYears(sx, as.integer = TRUE), wgiYears), grep(paste0("^SSP2\\.", gsub("([|.])", "\\\\\\1", ind)), getNames(sx), value = TRUE)]
  mn <- min(ref, na.rm = TRUE); mx <- max(ref, na.rm = TRUE)    # the model's normalisation (SSP2 = the run's SSP)
  for (s in paste0("SSP", 1:5)) {
    nm <- grep(paste0("^", s, "\\.", gsub("([|.])", "\\\\\\1", ind)), getNames(sx), value = TRUE)
    if (!length(nm)) next
    part4[[length(part4) + 1]] <- tidy((sx[, , nm] - mn) / (mx - mn), "Andrijevic et al. 2020", s, key)
  }
}
wge <- wgi[, , "Government Effectiveness (WGI)"]
part4[[length(part4) + 1]] <- tidy((wge - min(wge, na.rm = TRUE)) / (max(wge, na.rm = TRUE) - min(wge, na.rm = TRUE)),
                                   "WGI (observed)", "history", "ge")
pg <- pc[pc$year >= 1996, c("countrycode", "year", "scenario", "f_gov_eff")]; pg$f_gov_eff <- suppressWarnings(as.numeric(pg$f_gov_eff))
pg$v <- ((pg$f_gov_eff - 0.5) / 0.2 - min(wge, na.rm = TRUE)) / (max(wge, na.rm = TRUE) - min(wge, na.rm = TRUE))  # back to WGI, then the WGI [0, 1] scale
pg <- pg[pg$scenario %in% c("SSP1", "SSP2", "SSP3c", "SSP4c", "SSP5") & is.finite(pg$v), ]
part4[[length(part4) + 1]] <- data.frame(source = "PoliClim", ssp = pg$scenario, indicator = "ge", c = pg$countrycode,
                                         year = pg$year, v = pg$v)
mg <- part2[part2$rule == "gap closure" & part2$series == "Government Effectiveness (WGI)", ]
part4[[length(part4) + 1]] <- data.frame(source = "model (SSP2, harmonised)", ssp = "SSP2", indicator = "ge", c = mg$c,
                                         year = mg$year, v = mg$v)
part4 <- do.call(rbind, part4)
say("part 4: ", paste(unique(part4$source), collapse = ", "))

# ---- 5. government effectiveness under the gap-closure rule (a test, not the model) --------------------------------------
# On the gap-closure panel, the government-effectiveness series after 2023 replaced by the rule from its 2023 panel value:
# at the shared rate of the other series, at the rate that best reproduces Andrijevic's SSP2 path, and held (a bound);
# against the published path the model uses. The strength k(t) is recomputed on each.
geFit <- local({   # the rate that best reproduces Andrijevic's SSP2 government effectiveness (normalised, top = best observed)
  d <- part4[part4$source == "Andrijevic et al. 2020" & part4$ssp == "SSP2" & part4$indicator == "ge", ]
  top <- max(d$v[d$year <= T0], na.rm = TRUE); a <- stats::setNames(d$v[d$year == T0], d$c[d$year == T0])
  dd <- do.call(rbind, lapply(c(seq(2030, 2095, 5), 2099), function(y) { b <- stats::setNames(d$v[d$year == y], d$c[d$year == y])
    cc <- intersect(names(a), names(b)); data.frame(t = y, x0 = a[cc], v = b[cc]) }))
  dd <- dd[is.finite(dd$x0) & is.finite(dd$v), ]
  stats::optimize(function(l) sum((top - (top - dd$x0) * exp(-l * (dd$t - T0)) - dd$v)^2), c(1e-5, 0.05))$minimum
})
GE <- "Government Effectiveness (WGI)"
geVariants <- c(`Andrijevic SSP2 (the model)` = NA, `gap closure, shared rate` = pfm:::.pfmGapClosureRate("Vertical Accountability (VDem)"),
                `gap closure, rate fitted to Andrijevic SSP2` = round(geFit, 4), `held at 2023` = 0)
pg <- panels[["gap closure"]]; yy <- getYears(pg, as.integer = TRUE); after <- yy > 2023
regs <- intersect(getItems(pg, dim = 1), getItems(hp, dim = 1)); g23 <- as.numeric(hp[regs, 2023, GE]); ok <- is.finite(g23)
geRuns <- lapply(names(geVariants), function(nm) {
  p <- pg; lam <- geVariants[[nm]]
  if (is.finite(lam)) p[regs[ok], yy[after], GE] <- outer(g23[ok], yy[after], function(x, t) pfm:::.pfmGapClosurePath(x, t, 2023, lam))
  list(series = data.frame(variant = nm, c = rep(getItems(p, dim = 1), length(yy)), year = rep(yy, each = length(getItems(p, dim = 1))),
                           v = as.vector(as.array(p[, , GE])[, , 1])),
       strength = cbind(variant = nm, computeStrengthPath(anc, p, theta = 0.5)$strength[, c("sector", "year", "k")]))
})
part5 <- list(rates = geVariants, fitAndrijevic = geFit,
              series = do.call(rbind, lapply(geRuns, `[[`, "series")), strength = do.call(rbind, lapply(geRuns, `[[`, "strength")))
say("part 5: government effectiveness under the rule (Andrijevic-fitted rate ", round(100 * geFit, 2), "% a year)")

out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), rates = rates, part1 = part1, fit1 = fit1, part5 = part5,
            part2 = part2, history = histSer, seam = seam, strength = strength, part4 = part4, run = run$dir,
            note = paste("part1: PoliClim SSP2 against the rules, applied to PoliClim's own history 1996-2025;",
                         "part2: the model's scenario panels on the EU21 hold-the-price fading-limit energy system,",
                         "normalised and harmonised; part3: strength k(t), theta = 0.50."))
saveRDS(out, file.path("output/pfm", g, "institution-rule.rds"))
options(width = 160)
print(fit1, digits = 3, row.names = FALSE); print(seam, digits = 3, row.names = FALSE)
print(reshape(strength[strength$year %in% c(2030, 2050, 2070, 2100), c("rule", "sector", "year", "k")],
              idvar = c("rule", "sector"), timevar = "year", direction = "wide"), digits = 3, row.names = FALSE)
say("wrote ", file.path("output/pfm", g, "institution-rule.rds"))
