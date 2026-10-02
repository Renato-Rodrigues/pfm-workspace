# Is the feasibility ordering institutional, or is it income?
#
# gap-plan GP-8 / referee point M3 on paper2 v02. The objection: the fitted ceiling S* is
# dominated by a declared trend plus log population, the one surviving institutional channel
# (Government Effectiveness) co-moves with income, and therefore the shortfall the coupling
# consumes may be an income ordering wearing an institutional label.
#
# The coupling never sees a coefficient. It sees an ordering: S* -> E = S/S* -> u (min-max across
# units) -> phi = 1 - theta*u. So the question is not whether income belongs in the equation, it is
# whether the ORDERING survives removing it. Two things are computed here:
#
#   1. DESCRIPTIVE - how strongly S* and E track income per capita. S* can be income-graded while
#      E is not, because income cancels between numerator and denominator. That distinction is the
#      whole argument, and it needs no refit.
#   2. THE NO-INCOME TWIN - the deployed spec is X-2079 ... ctl:GDPq.Pop.Hyd; its twin without the
#      income control, X-2076 ... ctl:Pop.Hyd, is already fitted in the v5 sweep. Refit both as
#      frontiers, and compare E, the rank ordering, and a country-level phi proxy.
#
# >>> THIS IS A LOCAL SCREEN, NOT A QUOTABLE NUMBER. It inherits the three approximations of
# >>> analysis/testSectorSpecificSpec.R, and for the same reasons:
# >>>   * region aggregation is skipped entirely - this is country level, while the coupling
# >>>     weights countries into regions by final energy (IEA data, cluster only);
# >>>   * E is the last HISTORICAL year, not the projected tier year the coupling reads;
# >>>   * the out-of-coverage transfer is not modelled, so the 200 uncovered countries and the
# >>>     USA in particular are absent.
# >>> Use it to decide whether the full propagation is worth running, and to see the SIGN and the
# >>> order of magnitude. The quotable version is the full chain (see the footer of this file).
#
# Run from the project root:  Rscript analysis/checks/incomeScreen.R
# Writes: output/pfm/v5/income-screen.rds  (+ a printed summary)

options(repos = c(CRAN = "@CRAN@", pik = "https://rse.pik-potsdam.de/r/packages"))
suppressMessages(devtools::load_all("pfm", quiet = TRUE))
`%||%` <- function(a, b) if (is.null(a)) b else a

GROUP <- "v5"
GDIR  <- file.path("output/pfm", GROUP)

s  <- readRDS(file.path(GDIR, "sweep.rds"))
nm <- vapply(s$specs, function(z) as.character(z$name %||% NA), character(1))
depName <- s$selected$PolicyStringency
altName <- grep("^X-2076 .*ctl:Pop\\.Hyd fe:OECDp$", nm, value = TRUE)[1]
if (is.na(altName)) stop("no no-income twin found in the sweep")
cat("deployed (with income)   :", depName, "\n")
cat("twin     (no income)     :", altName, "\n\n")

norm <- function(x) {
  for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
    if (!is.null(x[[f]])) x[[f]] <- unlist(x[[f]])
  x
}
cfgDep <- norm(s$specs[[which(nm == depName)]])
cfgAlt <- norm(s$specs[[which(nm == altName)]])

suppressMessages(library(magclass))
panel <- pfm:::.pfmHistPanel(GDIR, verbose = FALSE)   # a magpie object, not a data.frame
yrs <- as.integer(gsub("y", "", getItems(panel, 2)))
cat("panel:", length(getItems(panel, 1)), "units |", paste(range(yrs), collapse = "-"),
    "|", length(getItems(panel, 3)), "variables\n\n")

# Raw income per head, not the Q-centred control: the descriptive question is where a country
# sits in the income distribution, and the Q-centring is an estimation device.
INC <- "GDP per Capita"
if (!INC %in% getItems(panel, 3)) stop("no '", INC, "' in the panel")
# State capability enters the same way. The main text claims the unclaimed space is "larger where
# the state is weaker" - that is a statement about the SHORTFALL, and every shipped capability
# number is a coefficient on the CEILING, so it needs its own correlation (referee v03, M5).
CAP <- "Government Effectiveness (WGI)"
if (!CAP %in% getItems(panel, 3)) stop("no '", CAP, "' in the panel")
driversAt <- function(year) {
  v <- panel[, paste0("y", year), c(INC, CAP)]
  data.frame(region = getItems(v, 1),
             income = as.numeric(v[, , INC]),
             capability = as.numeric(v[, , CAP]), stringsAsFactors = FALSE)
}

fitOne <- function(cfg, sector) {
  do.call(estimatePolicyStringencyModel, c(
    list(data = panel, sector = sector, estimator = "frontier", indexMax = 10,
         modelDir = NULL, verbose = FALSE),
    pfm:::.pfmSpecArgs(cfg)))
}

SECT <- c("Bulk", "Diffuse")
out <- list()

for (sec in SECT) {
  cat("=== ", sec, " ===============================================\n", sep = "")
  fD <- fitOne(cfgDep, sec)
  fA <- fitOne(cfgAlt, sec)

  yr <- max(fD$frontier$year)
  keep <- c("region", "year", "efficiencyRatio", "frontierIndex", "observedIndex")
  a <- fD$frontier[fD$frontier$year == yr, intersect(keep, names(fD$frontier))]
  b <- fA$frontier[fA$frontier$year == yr, intersect(keep, names(fA$frontier))]
  names(a)[names(a) == "efficiencyRatio"] <- "E_dep"
  names(a)[names(a) == "frontierIndex"]   <- "S_star_dep"
  names(b)[names(b) == "efficiencyRatio"] <- "E_alt"
  names(b)[names(b) == "frontierIndex"]   <- "S_star_alt"
  m <- merge(a, b[, c("region", "E_alt", "S_star_alt")], by = "region")

  m <- merge(m, driversAt(yr), by = "region")
  m <- m[is.finite(m$income) & is.finite(m$E_dep) & is.finite(m$E_alt), ]

  # Coerce defensively: the frontier frame carries some columns as character depending on how
  # the sector was subset, and a silent NA correlation is worse than a stop.
  sp <- function(x, y) {
    x <- suppressWarnings(as.numeric(x)); y <- suppressWarnings(as.numeric(y))
    if (all(is.na(x)) || all(is.na(y))) return(NA_real_)
    stats::cor(x, y, method = "spearman", use = "complete.obs")
  }

  # --- 1. descriptive: what tracks income, the ceiling or the shortfall? -------------------
  cat(sprintf("  year %s, %d countries\n", yr, nrow(m)))
  cat(sprintf("  Spearman(S*, income)            : %+.3f   <- ceiling level\n", sp(m$S_star_dep, m$income)))
  cat(sprintf("  Spearman(E,  income)            : %+.3f   <- what the coupling consumes\n", sp(m$E_dep, m$income)))
  cat(sprintf("  Spearman(observed S, income)    : %+.3f\n", sp(m$observedIndex, m$income)))
  cat(sprintf("  Spearman(S*, capability)        : %+.3f   <- ceiling level\n", sp(m$S_star_dep, m$capability)))
  cat(sprintf("  Spearman(E,  capability)        : %+.3f   <- is the shortfall smaller where the state is stronger?\n", sp(m$E_dep, m$capability)))
  cat(sprintf("  Spearman(observed S, capability): %+.3f\n", sp(m$observedIndex, m$capability)))

  # --- 2. the no-income twin ---------------------------------------------------------------
  cat(sprintf("  Spearman(E deployed, E no-income): %+.3f\n", sp(m$E_dep, m$E_alt)))
  cat(sprintf("  median |dE| %.4f   max |dE| %.4f\n",
              stats::median(abs(m$E_alt - m$E_dep)), max(abs(m$E_alt - m$E_dep))))
  m$rankDep <- rank(-m$E_dep); m$rankAlt <- rank(-m$E_alt)
  cat(sprintf("  median |rank shift| %.1f of %d   max %d\n",
              stats::median(abs(m$rankAlt - m$rankDep)), nrow(m),
              max(abs(m$rankAlt - m$rankDep))))

  # phi proxy at country level, theta = 0.50 - the object the coupling actually orders
  uOf <- function(e) { g <- 1 - e; (g - min(g)) / (max(g) - min(g)) }
  theta <- 0.50
  m$phi_dep <- 1 - theta * uOf(m$E_dep)
  m$phi_alt <- 1 - theta * uOf(m$E_alt)
  cat(sprintf("  Spearman(phi proxy)             : %+.3f   median |dphi| %.4f  max %.4f\n",
              sp(m$phi_dep, m$phi_alt),
              stats::median(abs(m$phi_alt - m$phi_dep)), max(abs(m$phi_alt - m$phi_dep))))
  cat(sprintf("  Spearman(phi proxy, income)     : %+.3f\n", sp(m$phi_dep, m$income)))
  cat(sprintf("  gamma: deployed %.4f | no-income %.4f\n\n",
              fD$frontierGamma %||% NA, fA$frontierGamma %||% NA))

  m$sector <- sec
  out[[sec]] <- m
}

res <- do.call(rbind, out)
saveRDS(list(byCountry = res, deployed = depName, alternative = altName,
             note = "LOCAL SCREEN - country level, historical year, no out-of-coverage transfer"),
        file.path(GDIR, "income-screen.rds"))
cat("written:", file.path(GDIR, "income-screen.rds"), "\n\n")

cat("--- the quotable version, if this screen says the ordering is worth defending ----------\n")
cat("Rscript analysis/run-groups/makeSpecVariantGroup.R v5 v5-noinc Bulk    \"", altName, "\"\n", sep = "")
cat("Rscript analysis/run-groups/makeSpecVariantGroup.R v5-noinc v5-noinc Diffuse \"", altName, "\"\n", sep = "")
cat("Rscript -e 'library(pfm); pfmRun(group = \"v5-noinc\",\n")
cat("                        steps = c(\"pfm-frontier\",\"pfm-temporal\",\"pfm-donor\",\n")
cat("                                  \"pfm-projection\",\"pfm-coupling-bound\"),\n")
cat("                        cluster = \"slurm\")'\n")
cat("Rscript analysis/checks/compareSpecVariantPhi.R v5 v5-noinc\n")
