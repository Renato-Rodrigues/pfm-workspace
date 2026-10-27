# Government effectiveness and income: how strongly they move together, and which government-effectiveness formulation
# is closest to what SSP2's income growth implies (design note 0008 §6b).
#   Rscript analysis/checks/geIncome.R [group]   (repo root; default v7; run after institutionRule.R)
#   -> output/pfm/<group>/ge-income.rds
# 1. The relationship in history (WGI government effectiveness, normalised as in the panel; GDP per capita, PPP,
#    mrdrivers): across countries in 2023, and within countries over 1996-2023 (country fixed effects, year effects).
# 2. The path SSP2's GDP per capita implies for each country, x(t) = x(2023) + b [ln y(t) - ln y(2023)], clipped to
#    [0, 1], with b the within-country slope (how a country's effectiveness moves as it grows) and the cross-country
#    slope (where richer countries stand today) - a lower and an upper reading.
# 3. Each formulation of institution-rule.rds part 5 against these implied paths: country changes 2023-2100.
suppressMessages(library(mrpfm))
a <- commandArgs(trailingOnly = TRUE); g <- if (length(a)) a[1] else "v7"
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE)
q <- function(e) suppressWarnings(suppressMessages(e))
pop <- q(calcOutput("Population", scenario = "SSP2", aggregate = FALSE))
gdp <- q(calcOutput("GDP", scenario = "SSP2", average2020 = FALSE, aggregate = FALSE))
yy <- intersect(getYears(pop, as.integer = TRUE), getYears(gdp, as.integer = TRUE))
gpc <- gdp[, yy, ] / pop[, yy, ]
lny <- log(as.array(gpc)[, , 1]); colnames(lny) <- sub("^y", "", colnames(lny))
wgi <- q(calcOutput("WGIindicator", aggregate = FALSE))[, , "Government Effectiveness (WGI)"]
ge <- as.array(wgi)[, , 1]; colnames(ge) <- sub("^y", "", colnames(ge)); ge <- (ge - min(ge, na.rm = TRUE)) / (max(ge, na.rm = TRUE) - min(ge, na.rm = TRUE))

# 1. history
hy <- intersect(colnames(ge), colnames(lny)); hy <- hy[as.integer(hy) >= 1996 & as.integer(hy) <= 2023]
cc <- intersect(rownames(ge), rownames(lny))
H <- data.frame(c = rep(cc, length(hy)), year = rep(as.integer(hy), each = length(cc)),
                ge = as.vector(ge[cc, hy]), lny = as.vector(lny[cc, hy]))
H <- H[is.finite(H$ge) & is.finite(H$lny), ]
x23 <- H[H$year == 2023, ]; if (!nrow(x23)) x23 <- H[H$year == max(H$year), ]
cross <- stats::lm(ge ~ lny, x23)
within <- stats::lm(ge ~ lny + factor(c) + factor(year), H)
# within-country correlation of the long change 1996-2023
ch <- merge(H[H$year == min(H$year), ], H[H$year == max(H$year), ], by = "c", suffixes = c(".0", ".1"))
rel <- data.frame(crossR = stats::cor(x23$ge, x23$lny), crossSlope = unname(stats::coef(cross)[2]),
                  withinSlope = unname(stats::coef(within)["lny"]), withinSE = summary(within)$coefficients["lny", 2],
                  changeR = stats::cor(ch$ge.1 - ch$ge.0, ch$lny.1 - ch$lny.0), nCross = nrow(x23), nPanel = nrow(H),
                  years = paste(range(H$year), collapse = "-"))

# 2. the paths SSP2 income implies
x <- readRDS(file.path("output/pfm", g, "institution-rule.rds"))
hist23 <- x$history[x$history$series == "Government Effectiveness (WGI)" & x$history$year == 2023, ]
g23 <- stats::setNames(hist23$v, hist23$c)
cP <- intersect(names(g23), rownames(lny)); YP <- c(2030, 2050, 2070, 2100)
implied <- do.call(rbind, lapply(c(within = rel$withinSlope, cross = rel$crossSlope), function(b) NULL))
implied <- do.call(rbind, lapply(c("within-country slope", "cross-country slope"), function(nm) {
  b <- if (nm == "within-country slope") rel$withinSlope else rel$crossSlope
  do.call(rbind, lapply(YP, function(t) data.frame(variant = paste0("SSP2 income, ", nm), c = cP, year = t,
    v = pmin(1, pmax(0, g23[cP] + b * (lny[cP, as.character(t)] - lny[cP, "2023"]))))))
}))
implied <- implied[is.finite(implied$v), ]

# 3. the formulations against the implied paths: country change 2023-2100
f <- x$part5$series[x$part5$series$year %in% YP, ]
comp <- do.call(rbind, lapply(unique(implied$variant), function(iv) {
  ref <- implied[implied$variant == iv & implied$year == 2100, ]; dRef <- stats::setNames(ref$v - g23[ref$c], ref$c)
  do.call(rbind, lapply(unique(f$variant), function(fv) {
    z <- f[f$variant == fv & f$year == 2100, ]; dF <- stats::setNames(z$v - g23[z$c], z$c)
    k <- intersect(names(dRef), names(dF)); k <- k[is.finite(dRef[k]) & is.finite(dF[k])]
    data.frame(reference = iv, formulation = fv, n = length(k), meanChangeRef = mean(dRef[k]), meanChangeFormulation = mean(dF[k]),
               corChange = stats::cor(dRef[k], dF[k]), rmseChange = sqrt(mean((dF[k] - dRef[k])^2)))
  }))
}))
# does SSP2 income growth itself converge? (poorer countries grow faster)
conv <- data.frame(corGrowthWithGE2023 = stats::cor(lny[cP, "2100"] - lny[cP, "2023"], g23[cP], use = "complete.obs"),
                   meanLogGrowth = mean(lny[cP, "2100"] - lny[cP, "2023"], na.rm = TRUE))
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), relationship = rel, implied = implied, comparison = comp,
             convergence = conv, history = H), file.path("output/pfm", g, "ge-income.rds"))
options(width = 180); print(rel, digits = 3, row.names = FALSE); print(conv, digits = 3, row.names = FALSE)
print(comp, digits = 3, row.names = FALSE)
