# The persistence ladder (design note 0006, the paper frames): every result of both closures against how
# long the political drag lasts, one row per rung, rule and resolution.
#   Rscript analysis/v6/persistenceLadder.R [group]          (repo root; default v6)
# Run after runCoupledStage.R <group> and ruleCRelocationDecomp.R: it reads their artifacts and adds only
# the cumulative CO2 path of each run (pm_actualbudgetco2, Gt CO2, the element of each year, PITFALLS 16).
#
# Rungs, from worse than today to fastest erosion (titles -PFMlevel<Bfix|C>[-<arm>]-v6; a rung that has not
# run is left out, so the ladder can be read while the batch lands):
#   backslide  today's strength growing, E hold with kappa < 0 (declared, 0006)
#   Ehold      today's strength held, k close to 1 (the static share, D2 / C5)
#   deployed   the strength fading with the projected drivers (the v6 headline)
#   kappa02 / kappa / kappa05   plus declared erosion of 0.02 / 0.027 / 0.05 a year (ADR 0050)
# Rule B (held price) against -PFMgateBfix: extra cumulative CO2 by year, the year cumulative CO2 peaks,
# GDP and consumption. Rule C (held budget) against -PFMgate: the global price (anchor, 2050), relocated
# abatement by period, the regional price wedge, China's change, GDP and consumption (all regions).
# "dividend" = the static rung minus each rung: what the ladder says politics that develops is worth.
# Writes output/pfm/<group>/coupling/persistence-ladder.{rds,json} and prints both tables.
suppressMessages(library(jsonlite))
`%||%` <- function(a, b) if (is.null(a)) b else a
a <- commandArgs(trailingOnly = TRUE)
GROUP <- if (length(a) >= 1) a[1] else "v6"
CPL <- file.path("output/pfm", GROUP, "coupling")
ex <- new.env(); sys.source("analysis/coupled/extractCoupledResults.R", envir = ex); bin <- ex$gdxdumpBin()
art <- readRDS(file.path(CPL, "coupled-runs.rds"))
R <- art$runs[!art$runs$superseded, ]; R$key <- sub("-v6$", "", sub("^SSP2-(EU21-)?", "", R$scenario))
FA <- fromJSON(file.path(CPL, "coupled-facts.json"), simplifyVector = FALSE)
CO <- fromJSON(file.path(CPL, "coupled-costs.json"), simplifyVector = FALSE)
DEC <- if (file.exists(f <- file.path(CPL, "rulec-relocation-decomp.rds"))) readRDS(f)$summary else NULL
RUNGS <- c(backslide = "today's strength growing", Ehold = "today's strength held", deployed = "fading with the drivers",
           kappa02 = "plus erosion 0.02/yr", kappa = "plus erosion 0.027/yr", kappa05 = "plus erosion 0.05/yr")
YEARS <- c(2030, 2050, 2070, 2100, 2150)
RES <- intersect(c("EU21", "H12"), unique(R$resolution))
num <- function(x) if (is.null(x)) NA_real_ else as.numeric(x)

title <- function(rule, rung) paste0("PkBudg1000-PFMlevel", rule, if (rung != "deployed") paste0("-", rung))
row <- function(res, key) { x <- R[R$resolution == res & R$key == key, , drop = FALSE]; if (nrow(x) == 1) x else NULL }
cumPath <- function(res, x) {
  d <- ex$readSymbol(file.path("output/remind-runs", GROUP, res, x$dir, "fulldata.gdx"), "pm_actualbudgetco2", bin)
  y <- suppressWarnings(as.integer(d[[1]])); v <- as.numeric(d[[ncol(d)]])
  stats::setNames(v[match(YEARS, y)], YEARS)
}
# k of a run: the arms carry it in the facts; the deployed rows sit in the per-run list (rule B) or ruleC
kOf <- function(res, rule, rung) {
  e <- if (rung == "deployed") {
    if (rule == "C") FA$ruleC[[res]][["0.50"]]
    else Filter(function(z) identical(z$scenario, title(rule, rung)), FA$runs[[res]])[[1]]
  } else FA$arms[[res]][[paste0(rule, "-", rung)]]
  c(kBulk2050 = num(e$kBulk2050), kBulk2100 = num(e$kBulk2100), kDiffuse2050 = num(e$kDiffuse2050), kDiffuse2100 = num(e$kDiffuse2100))
}
costOf <- function(res, rule, rung) CO[[res]][[sub("^PkBudg1000-PFM", "", title(rule, rung))]]

B <- list(); C <- list()
for (res in RES) {
  nB <- row(res, "PkBudg1000-PFMgateBfix"); nC <- row(res, "PkBudg1000-PFMgate")
  cB0 <- if (!is.null(nB)) cumPath(res, nB)
  for (rung in names(RUNGS)) {
    x <- row(res, title("Bfix", rung))
    if (!is.null(x) && !is.null(nB)) {
      cp <- cumPath(res, x); co <- costOf(res, "Bfix", rung)
      B[[length(B) + 1]] <- data.frame(res = res, rung = rung, meaning = RUNGS[[rung]], t(kOf(res, "Bfix", rung)),
        t(stats::setNames(round(cp - cB0, 1), paste0("extra", YEARS))), cum2150 = round(cp[["2150"]], 1),
        peakYear = x$peakYear, neverPeaks = x$peakYear >= 2150,
        gdpPct = num(co$gdpChangePct), consPct = num(co$consumptionChangePct), check.names = FALSE)
    }
    x <- row(res, title("C", rung))
    if (!is.null(x) && !is.null(nC)) {
      co <- costOf(res, "C", rung)
      lab <- if (rung == "deployed") GROUP else paste0(GROUP, " C-", rung)
      d <- if (!is.null(DEC)) DEC[DEC$group == lab & DEC$res == res, , drop = FALSE] else NULL
      anc <- if (rung == "deployed") FA$ruleC[[res]][["0.50"]]$anchorOverGate else FA$arms[[res]][[paste0("C-", rung)]]$anchorOverGate
      reg <- co$byRegion %||% list()
      gdpR <- vapply(reg, function(z) num(z$gdpChangePct), 1); dR <- vapply(reg, function(z) num(z$deltaGtCO2eq), 1)
      nm <- vapply(reg, function(z) z$region, "")
      C[[length(C) + 1]] <- data.frame(res = res, rung = rung, meaning = RUNGS[[rung]], t(kOf(res, "C", rung)),
        cum2100 = round(x$cum2100, 1), peakYear = x$peakYear, anchorOverGate = num(anc),
        relocated = if (length(d) && nrow(d)) d$grossRegion else num(co$grossRelocated),
        relocated2050 = if (length(d) && nrow(d)) d$gross2050 else NA_real_,
        relocatedAfter2050 = if (length(d) && nrow(d)) d$gross2100 else NA_real_,
        wedgeSd2030 = if (length(d) && nrow(d)) d$wedgeSd2030 else NA_real_,
        wedgeSd2100 = if (length(d) && nrow(d)) d$wedgeSd2100 else NA_real_,
        chinaDelta = if ("CHA" %in% nm) dR[nm == "CHA"] else NA_real_,
        gdpPct = num(co$gdpChangePct), consPct = num(co$consumptionChangePct),
        gdpWorstRegion = if (length(gdpR)) nm[which.min(gdpR)] else NA_character_,
        gdpWorstPct = if (length(gdpR)) min(gdpR) else NA_real_, check.names = FALSE)
    }
  }
}
B <- if (length(B)) do.call(rbind, B) else NULL; C <- if (length(C)) do.call(rbind, C) else NULL
dividend <- function(t, col) {
  if (is.null(t)) return(NULL)
  do.call(rbind, lapply(split(t, t$res), function(x) {
    s <- x[[col]][x$rung == "Ehold"]
    if (!length(s)) return(NULL)
    data.frame(res = x$res, rung = x$rung, measure = col, value = x[[col]], dividendVsStatic = round(s - x[[col]], 1))
  }))
}
D <- rbind(dividend(B, "extra2100"), dividend(C, "relocated"))
cat("\n== Rule B (held price) against -PFMgateBfix: extra cumulative CO2 (Gt), peak year, discounted GDP / consumption (%)\n")
if (!is.null(B)) print(B[, setdiff(names(B), c("meaning", "kDiffuse2050", "kDiffuse2100"))], row.names = FALSE)
cat("\n== Rule C (held budget) against -PFMgate: global price 2050 (x null), relocated abatement (Gt CO2eq), price wedge SD\n")
if (!is.null(C)) print(C[, setdiff(names(C), c("meaning", "kDiffuse2050", "kDiffuse2100"))], row.names = FALSE)
cat("\n== The dividend: the static rung minus each rung\n"); if (!is.null(D)) print(D, row.names = FALSE)
out <- list(group = GROUP, generated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), rungs = as.list(RUNGS),
            units = list(extra = "Gt CO2, pm_actualbudgetco2 of the run minus -PFMgateBfix in that year",
                         relocated = "Gt CO2eq, 1/2 sum_r |d_r| 2020-2100 (ruleCRelocationDecomp.R)",
                         gdp = "% discounted (5%/yr) 2020-2100 vs the matched null (coupled-costs.json)"),
            ruleB = B, ruleC = C, dividend = D)
saveRDS(out, file.path(CPL, "persistence-ladder.rds"))
write(toJSON(out, auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null", dataframe = "rows"), file.path(CPL, "persistence-ladder.json"))
cat("\nwrote", file.path(CPL, "persistence-ladder.{rds,json}"), "\n")
