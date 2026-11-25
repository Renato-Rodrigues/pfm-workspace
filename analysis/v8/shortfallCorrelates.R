# What does the 2023 shortfall below the ceiling go with? (GMD paper, review v02 M1, optional check)
#   Rscript analysis/v8/shortfallCorrelates.R [group]   (repo root; default v8)
#   -> output/pfm/<group>/shortfall-correlates.rds
# The coupling orders regions by their 2023 distance below the ceiling (the frontier's one-sided residual). Review v02
# M1 asks whether that residual reads as political reluctance or as something non-political. This cross-section of the
# 48 estimation countries in 2023 relates each sector group's shortfall (1 - E, E = observed / ceiling, from
# frontier.rds) to non-political candidates:
#   ets       member of the EU emissions trading system in 2023 (EU27, Norway, Iceland)
#   coverage  the share of the CAPMF's lowest-level instruments (LEV4_*) with a positive stringency score in 2023: how
#             much of the index's instrument list a country uses at all (a measurement reading of the shortfall)
#   energyInt energy intensity of GDP in 2023 (the panel's series, as the selected frontier sees it)
#   gdpPc     GDP per capita in 2023 (log)
# Reported: Spearman correlations one by one, and an OLS of the shortfall on all four with HC1 standard errors, R^2 and
# n. A correlate is not a cause; the check says what the residual carries, not why. Offline; nothing changes upstream.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g)
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [shortfall-correlates:", g, "] ", ...)
CAPMF <- "C:/_data/work/remind_input_data/sources/CAPMF/capmf.csv"
YEAR <- 2023
EU27 <- c("AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST", "FIN", "FRA", "DEU", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "LUX",
          "MLT", "NLD", "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE")
ETS <- c(EU27, "NOR", "ISL", "LIE")
fr <- readRDS(file.path(GD, "frontier.rds")); panel <- .panelForGroup(g)
cp <- utils::read.csv(CAPMF, stringsAsFactors = FALSE)
cp <- cp[cp$TIME_PERIOD == YEAR & startsWith(cp$CLIM_ACT_POL, "LEV4_") & !is.na(cp$OBS_VALUE), ]
cov <- tapply(cp$OBS_VALUE > 0, cp$REF_AREA, mean)
say("CAPMF ", YEAR, ": ", length(unique(cp$CLIM_ACT_POL)), " LEV4 instruments, ", length(cov), " countries")
res <- list(); fits <- list()
for (sec in c("Bulk", "Diffuse")) {
  sc <- fr$bySector[[sec]]$scores; sc <- sc[sc$year == YEAR, ]
  d <- data.frame(region = sc$region, shortfall = 1 - pmin(sc$observedIndex / sc$frontierIndex, 1), stringsAsFactors = FALSE)
  d$ets <- as.numeric(d$region %in% ETS)
  d$coverage <- as.numeric(cov[d$region])
  d$energyInt <- as.numeric(panel[d$region, YEAR, "Energy Intensity"])
  d$gdpPc <- log(as.numeric(panel[d$region, YEAR, "GDP per Capita"]))
  if (anyNA(d)) say(sec, ": missing values for ", paste(d$region[!stats::complete.cases(d)], collapse = ", "))
  d <- d[stats::complete.cases(d), ]
  X <- c("ets", "coverage", "energyInt", "gdpPc")
  sp <- sapply(X, function(x) stats::cor(d$shortfall, d[[x]], method = "spearman"))
  m <- stats::lm(stats::reformulate(X, "shortfall"), data = d)
  V <- sandwich::vcovHC(m, type = "HC1"); se <- sqrt(diag(V)); b <- stats::coef(m)
  tab <- data.frame(term = names(b), estimate = unname(b), seHC1 = unname(se), t = unname(b / se),
                    p = unname(2 * stats::pt(-abs(b / se), df = stats::df.residual(m))), stringsAsFactors = FALSE)
  fits[[sec]] <- list(table = tab, r2 = summary(m)$r.squared, n = nrow(d), spearman = sp)
  res[[sec]] <- cbind(sector = sec, d)
  say(sec, ": n ", nrow(d), ", R^2 ", round(summary(m)$r.squared, 2))
}
out <- list(group = g, year = YEAR, made = format(Sys.time(), "%Y-%m-%d %H:%M"), capmf = c(file = CAPMF, md5 = unname(tools::md5sum(CAPMF))),
            note = "cross-section of the 48 estimation countries in 2023; shortfall = 1 - observed/ceiling; OLS with HC1 standard errors; correlates, not causes",
            data = do.call(rbind, res), fits = fits)
f <- file.path(GD, "shortfall-correlates.rds"); saveRDS(out, f); say("wrote ", f)
