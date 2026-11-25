# Does the centred five-year smoothing make the power-and-industry frontier degenerate? (GMD paper, review v01 M4 /
# v02 M8; gap plan GP-26 (update))
#   Rscript analysis/v8/smoothingRefit.R [group]   (repo root; default v8)
#   -> output/pfm/<group>/smoothing-refit.rds
# The v8 panel smooths every series, the outcome included, with a centred five-year mean (pfm::panelDataHistorical,
# movingAverage = 5; the window narrows at the panel's ends). That can remove the year-to-year noise a stochastic
# frontier separates from the shortfall (gamma at its boundary in power and industry), and a centred mean lets t+1 and
# t+2 into regressors. The selected specification is refitted, both sector groups, on four panels:
#   selected  the fitted v8 panel (must reproduce frontier.rds: the check that the refit machinery is the deployed one)
#   annualY   the fitted panel with the outcome replaced by its annual values (drivers smoothed as before)
#   annual    every series annual
#   trailing  every series a trailing five-year mean (t-4 ... t), so no value after t enters year t
# The annual panel is rebuilt from the group's madrat cache with movingAverage = 1 and is accepted only if smoothing
# it with the package's own centred mean reproduces the fitted panel (same countries, same series, same values).
# Reported per panel and sector: rows, log-likelihood, gamma, sigma_u, sigma_v, the fossil-dependence and fossil-per-
# person coefficients, and the 2023 order of the estimation countries by their share of the ceiling used
# (rank correlation with the selected fit). The regional order and k(2050) are not recomputed: the scenario panels are
# harmonised to the smoothed history, and pairing them with an annual fit runs without error and is wrong
# (docs/DATA.md section 3). Fits go to no model directory (modelDir = NULL); nothing in the fit cache or the Run-Group changes.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g)
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [smoothing-refit:", g, "] ", ...)
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE); pd <- pfm:::.pfmPanelDefForGroup(GD, rc$panel)
options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability", "fossilRents"), names(pd))])
P5 <- .panelForGroup(g)
if (!identical(as.integer(pd$movingAverage), 5L)) stop("expected a five-year moving average in the panel definition, got ", pd$movingAverage)

# --- the annual panel, checked against the fitted one -----------------------------------------------------------------
say("rebuilding the annual panel from the madrat cache")
yrs <- getYears(P5, as.integer = TRUE)
P1 <- panelDataHistorical(aggregate = TRUE, y = yrs, outputRegionMappingFile = "country", movingAverage = 1,
                          ieaVersion = pd$ieaVersion, geothermal = pd$geothermal,
                          democracy = pd$democracy %||% pfmPanelDef()$democracy,
                          overallAccountability = pd$overallAccountability %||% pfmPanelDef()$overallAccountability,
                          fossilRents = pd$fossilRents %||% pfmPanelDef()$fossilRents, includePolicyStringency = TRUE)
common <- intersect(getNames(P5), getNames(P1)); regs <- intersect(getItems(P5, dim = 1), getItems(P1, dim = 1))
if (length(regs) < length(getItems(P5, dim = 1))) stop("the rebuilt panel has fewer countries (", length(regs), ") than the fitted one")
sma <- function(v, k) { if (all(is.na(v))) return(v); h <- floor(k / 2); n <- length(v); sapply(seq_len(n), function(i) mean(v[max(1, i - h):min(n, i + h)], na.rm = TRUE)) }
smooth <- function(P, f) { a <- as.array(P); a[, , ] <- aperm(apply(a, c(1, 3), f), c(2, 1, 3)); x <- P; x[, , ] <- a; x }
P1s <- smooth(P1[regs, yrs, common], function(v) sma(v, 5))
dev <- max(abs(as.array(P1s) - as.array(P5[regs, yrs, common])), na.rm = TRUE)
say("re-smoothed annual panel against the fitted panel: ", length(regs), " countries, ", length(common), " series, largest difference ", signif(dev, 3))
if (!is.finite(dev) || dev > 1e-6) stop("the annual rebuild does not reproduce the fitted panel when smoothed (", dev, "): not the same data")
trail <- function(v) { if (all(is.na(v))) return(v); n <- length(v); sapply(seq_len(n), function(i) mean(v[max(1, i - 4):i], na.rm = TRUE)) }
ps <- grep("Policy Stringency", getNames(P5), value = TRUE)
# The fitted panel carries "GDP per Capita Sq", added after the build as the square of the panel's own GDP per capita
# (checked: identical in the fitted panel); each variant gets it the same way, from its own GDP per capita.
addSq <- function(P) { if ("GDP per Capita Sq" %in% getNames(P5) && !"GDP per Capita Sq" %in% getNames(P)) P <- mbind(P, setNames(P[, , "GDP per Capita"]^2, "GDP per Capita Sq")); P[, , getNames(P5)] }
PA <- P5; PA[regs, yrs, ps] <- P1[regs, yrs, ps]
P1c <- P1[regs, yrs, common]
PANELS <- list(selected = P5, annualY = PA, annual = addSq(P1c), trailing = addSq(smooth(P1c, trail)))

# --- the refits -------------------------------------------------------------------------------------------------------
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD)); fr <- readRDS(file.path(GD, "frontier.rds"))
rows <- list(); orders <- list()
for (sec in c("Bulk", "Diffuse")) {
  cfg <- Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]]
  cfg <- pfm:::.pfmNormSpec(cfg)
  stored <- stats::setNames(fr$bySector[[sec]]$coefTable$estimate, fr$bySector[[sec]]$coefTable$term)
  ref <- NULL
  for (v in names(PANELS)) {
    say(sec, " / ", v)
    fit <- tryCatch(R.utils::withTimeout(do.call(estimatePolicyStringencyModel, c(list(data = PANELS[[v]], sector = sec, estimator = "frontier", indexMax = 10,
             modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(cfg))), timeout = 3600, onTimeout = "error"),
             error = function(e) { say(sec, " / ", v, " failed: ", conditionMessage(e)); NULL })
    if (is.null(fit)) { rows[[paste(sec, v)]] <- data.frame(sector = sec, panel = v, ok = FALSE); next }
    cf <- stats::coef(fit$model); cb <- pfm:::.pfmCeilingBeta(cf)
    gam <- unname(cf["gamma"]); s2 <- unname(cf["sigmaSq"])
    devStored <- if (v == "selected") max(abs(cf[names(stored)] - stored), na.rm = TRUE) else NA_real_
    if (v == "selected" && (!is.finite(devStored) || devStored > 1e-3)) stop("the selected refit does not reproduce frontier.rds (", devStored, ")")
    des <- pfm:::.pfmAnchorDesign(cfg, sec, PANELS[[v]], cf, modelDir = NULL, indexMax = 10, slackScaling = fit$driverScaling)
    eh <- pfm:::.pfmFrontierEta(des, PANELS[[v]]); eh <- eh[eh$year == 2023 & is.finite(eh$eta), ]
    fd <- des$fit$data; cov <- fd[fd$year == 2023 & is.finite(fd$ecp), c("region", "ecp")]
    E <- pmin(stats::plogis(cov$ecp) / stats::plogis(eh$eta[match(as.character(cov$region), eh$region)]), 1)
    o <- data.frame(sector = sec, panel = v, region = as.character(cov$region), shareUsed2023 = E, stringsAsFactors = FALSE)
    orders[[paste(sec, v)]] <- o
    if (v == "selected") ref <- o
    rho <- if (!is.null(ref)) { m <- match(ref$region, o$region); stats::cor(ref$shareUsed2023, o$shareUsed2023[m], method = "spearman", use = "complete.obs") } else NA_real_
    rows[[paste(sec, v)]] <- data.frame(sector = sec, panel = v, ok = TRUE, rows = nrow(fit$data), logLik = as.numeric(stats::logLik(fit$model)),
                                        gamma = gam, sigmaU = sqrt(gam * s2), sigmaV = sqrt((1 - gam) * s2),
                                        fossil = cb[["Incumbent.Power"]], fossilPc = cb[["Incumbent.Power.pc"]],
                                        orderRankCorrelation2023 = rho, mostLimited2023 = o$region[which.min(o$shareUsed2023)],
                                        devFromStored = devStored, stringsAsFactors = FALSE)
  }
}
res <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), panelCheck = c(countries = length(regs), series = length(common), maxAbsDiff = dev),
            note = "selected specification refitted on four panels; the 2023 order is the estimation countries' share of the ceiling used; regional order and k(2050) not recomputed (scenario panels are harmonised to the smoothed history)",
            fits = do.call(rbind, lapply(rows, function(r) { for (k in setdiff(names(rows[[which.max(sapply(rows, ncol))]]), names(r))) r[[k]] <- NA; r })),
            orders = do.call(rbind, orders))
f <- file.path(GD, "smoothing-refit.rds"); saveRDS(res, f); say("wrote ", f)
