# Option N: what current policies reveal about the severity theta (design note 0012 sec. 7; GMD claims M11, M12, N1).
#   Rscript analysis/v8/thetaRevealed.R [group]          (repo root; default v8) -> output/pfm/<group>/coupling/theta-revealed.rds
#   Rscript analysis/v8/thetaRevealed.R [group] check    reads only the current-policies run and the anchor (before N0 exists)
# N0 (SSP2-EU21-NPi2025-uniformPrice, start tag V8NPIBUDEU21) replaces the current-policy prices from 2030 by one uniform
# price A_cp that meets the same cumulative CO2 2020-2100 (2981 Gt). Then, per EU21 region and year:
#   phi_cp = clip(P_cp / A_cp, 0, 1)     the share of the uniform price that current policy levies
# and the PFM says phi = 1 - theta k u (k = 1 in 2025; the strength on the current-policies pathway later, open-loop-strength).
#   1. converged: N0's cumulative CO2 2020-2100 against the current-policies run's (within 1%).
#   2. N1, the ordering: Spearman correlation of u with 1 - phi_cp, per sector u and the binding (larger) u.
#   3. M11, the revealed severity, two estimators: through the origin, theta = sum(w x y) / sum(w x^2) (the PFM's form: the
#      least limited region pays the full price), and the slope of a weighted regression with an intercept (a shortfall
#      common to all regions goes to the intercept); y = 1 - phi_cp, x = k u, w = the region's CO2, 2030 alone
#      (k = 1 there by construction) and pooled 2030-2050; 5-95% band from 999 resamples of the regions. D7: theta stays
#      declared unless the band excludes zero.
#   4. M12, the cost of uneven prices: consumption and GDP 2020-2100, discounted at 5% a year, current policies against N0.
# The price is economy-wide per region (pm_taxCO2eq); the PFM's two sectors are compared through their u. Exploratory: the
# regional sample is 21, and P_cp is REMIND's current-policy input (held from 2030), not a model of politics.
suppressMessages({ library(gdx); library(magclass) })
args <- commandArgs(trailingOnly = TRUE); CHECK <- "check" %in% args; args <- setdiff(args, "check")
g <- if (length(args)) args[1] else "v8"
RD <- file.path("output/remind-runs", g, "EU21"); OUT <- file.path("output/pfm", g, "coupling")
say <- function(...) message("[theta-revealed:", g, "] ", ...)
TCO2 <- 1000 / (44 / 12); YRS <- c(2030, 2035, 2040, 2045, 2050); set.seed(20261123)
newest <- function(prefix) { d <- sort(Sys.glob(file.path(RD, paste0(prefix, "_*"))), decreasing = TRUE); d <- d[file.exists(file.path(d, "fulldata.gdx"))]
  if (length(d)) file.path(d[1], "fulldata.gdx") else NA_character_ }
fCP <- newest("SSP2-EU21-NPi2025"); fN0 <- newest("SSP2-EU21-NPi2025-uniformPrice")
if (nzchar(Sys.getenv("PFM_N0_GDX"))) { fN0 <- Sys.getenv("PFM_N0_GDX"); say("TEST: N0 replaced by ", fN0) }   # testing the logic only
if (is.na(fCP)) stop("no current-policies run (SSP2-EU21-NPi2025) in ", RD)
if (!CHECK && is.na(fN0)) stop("no N0 run (SSP2-EU21-NPi2025-uniformPrice) in ", RD, " - sync it back first, or add 'check'")

price <- function(f) readGDX(f, "pm_taxCO2eq")[, YRS, ] * TCO2
co2 <- function(f) readGDX(f, "vm_emiAll", field = "l", restore_zeros = FALSE)[, YRS, "co2"]
cumOf <- function(f) as.numeric(readGDX(f, "pm_actualbudgetco2")[, 2100, ])
pCP <- price(fCP); eCP <- co2(fCP)
anc <- readRDS(file.path("output/remind-inputs", g, "phi-anchor.rds"))$byResolution$EU21$region
u <- reshape(anc[, c("sector", "region", "u")], idvar = "region", timevar = "sector", direction = "wide"); names(u) <- sub("^u\\.", "u", names(u))
u$uMax <- pmax(u$uBulk, u$uDiffuse)
ol <- readRDS(file.path(OUT, "open-loop-strength.rds"))$strength
kCP <- ol[ol$pathway == unique(ol$pathway[grepl("current", ol$pathway)])[1], ]
kOf <- function(sec, y) { k <- kCP$k[kCP$sector == sec & kCP$year == y]; if (length(k)) k[1] else stats::approx(kCP$year[kCP$sector == sec], kCP$k[kCP$sector == sec], y)$y }
say("current policies: ", basename(dirname(fCP)), "; anchor u for ", nrow(u), " regions; k on current policies from open-loop-strength.rds")
if (CHECK) {
  cat("current-policy price by region (US$2017/t CO2):\n"); print(round(as.array(pCP)[, , 1], 1))
  cat("cumulative CO2 2020-2100:", round(cumOf(fCP), 1), "Gt\n"); quit(status = 0)
}

# 1. converged?
cum <- c(currentPolicies = cumOf(fCP), N0 = cumOf(fN0)); conv <- abs(cum[["N0"]] / cum[["currentPolicies"]] - 1) < 0.01
say("cumulative CO2 2020-2100: current policies ", round(cum[1], 1), ", N0 ", round(cum[2], 1), " Gt -> ", if (conv) "met" else "NOT MET")
pN0 <- price(fN0)
spread <- max(apply(as.array(pN0)[, , 1], 2, function(x) diff(range(x))))
if (spread > 1) say("WARNING: N0's price differs between regions by up to ", round(spread, 2), " $/t - not uniform")
A <- apply(as.array(pN0)[, , 1], 2, stats::median); names(A) <- sub("^y", "", names(A))

# the panel of regions x years
d <- do.call(rbind, lapply(YRS, function(y) {
  r <- getItems(pCP, dim = 1)
  data.frame(region = r, year = y, Pcp = as.numeric(pCP[r, y, ]), A = A[[as.character(y)]],
             w = pmax(as.numeric(eCP[r, y, ]), 0), stringsAsFactors = FALSE) }))
d$phiCP <- pmin(pmax(d$Pcp / d$A, 0), 1); d$y <- 1 - d$phiCP
d <- merge(d, u[, c("region", "uBulk", "uDiffuse", "uMax")], by = "region")
d$kBulk <- vapply(d$year, function(y) kOf("Bulk", y), 0); d$kDiffuse <- vapply(d$year, function(y) kOf("Diffuse", y), 0)
d$xBulk <- d$kBulk * d$uBulk; d$xDiffuse <- d$kDiffuse * d$uDiffuse; d$xMax <- pmax(d$xBulk, d$xDiffuse)

# 2. N1: the ordering
ord <- do.call(rbind, lapply(YRS, function(y) { s <- d[d$year == y, ]
  data.frame(year = y, uBulk = stats::cor(s$uBulk, s$y, method = "spearman"), uDiffuse = stats::cor(s$uDiffuse, s$y, method = "spearman"),
             uMax = stats::cor(s$uMax, s$y, method = "spearman")) }))
# 3. M11: theta through the origin, with a regional bootstrap
th <- function(s, x) sum(s$w * s[[x]] * s$y) / sum(s$w * s[[x]]^2)
# with an intercept: a shortfall common to every region (all current prices below the uniform one) goes to the intercept,
# and theta is read from how the shortfall varies with the ranking only
thS <- function(s, x) { z <- s[[x]]; if (stats::var(z) == 0) return(NA_real_); unname(stats::coef(stats::lm(s$y ~ z, weights = s$w))[2]) }
band <- function(s, x, f = th) { regs <- unique(s$region)
  b <- replicate(999, { r <- sample(regs, length(regs), replace = TRUE); ss <- do.call(rbind, lapply(r, function(z) s[s$region == z, ])); f(ss, x) })
  stats::quantile(b, c(0.05, 0.5, 0.95), na.rm = TRUE) }
est <- do.call(rbind, lapply(list(c("2030", "2030"), c("2030-2050", "pooled")), function(p) {
  s <- if (p[2] == "2030") d[d$year == 2030, ] else d
  do.call(rbind, lapply(c("xBulk", "xDiffuse", "xMax"), function(x) do.call(rbind, lapply(c("origin", "slope"), function(m) {
    f <- if (m == "origin") th else thS; b <- band(s, x, f)
    data.frame(years = p[1], x = x, estimator = m, theta = f(s, x), p05 = b[[1]], p50 = b[[2]], p95 = b[[3]], excludesZero = b[[1]] > 0) })))) }))
# 4. M12: the cost of uneven prices (same CO2), discounted at 5% a year
npv <- function(f, sym, item = NULL) { x <- readGDX(f, sym, field = "l", restore_zeros = FALSE); if (!is.null(item)) x <- x[, , item]
  yy <- intersect(seq(2020, 2100, 5), getYears(x, as.integer = TRUE)); v <- as.numeric(dimSums(x[, yy, ], dim = c(1, 3)))
  sum(v * 1.05^-(yy - 2020)) }
cost <- data.frame(measure = c("consumption", "GDP"),
                   currentPolicies = c(npv(fCP, "vm_cons"), npv(fCP, "vm_cesIO", "inco")), N0 = c(npv(fN0, "vm_cons"), npv(fN0, "vm_cesIO", "inco")))
cost$N0overCP_pct <- 100 * (cost$N0 / cost$currentPolicies - 1)

out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), runs = c(currentPolicies = fCP, N0 = fN0), cumulative = cum, converged = conv,
            uniformPrice = A, priceSpreadN0 = spread, panel = d, ordering = ord, theta = est, cost = cost,
            note = paste("phi_cp = clip(P_cp/A_cp, 0, 1) per EU21 region; theta = sum(w x y)/sum(w x^2), w = CO2, x = k u; band from 999 regional",
                         "resamples; cost = NPV at 5%/yr 2020-2100. D7: theta stays declared unless the band excludes zero. Exploratory (21 regions)."))
saveRDS(out, file.path(OUT, "theta-revealed.rds")); say("wrote ", file.path(OUT, "theta-revealed.rds"))
options(width = 200)
cat("\nuniform price A_cp (US$2017/t CO2):", paste(names(A), round(A, 1), collapse = " | "), "\n")
cat("\nN1, Spearman of u with 1 - phi_cp:\n"); print(ord, digits = 3, row.names = FALSE)
cat("\nM11, revealed theta:\n"); print(est, digits = 3, row.names = FALSE)
cat("\nM12, N0 against current policies (same CO2):\n"); print(cost, digits = 6, row.names = FALSE)
