# The order of the coupling steps (meeting of 2026-10-09): project the gap first, then normalise, then apply theta.
#   Rscript analysis/v8/gapOrder.R   (repo root) -> output/pfm/v8/gap-order.rds
# Three ways to turn each region's projected gap g_r(t) into its share phi_r(t), on the same inputs as the v8 coupling
# preview (v8 anchor, EU21; the energy system of v7's coupled hold-the-price headline, 1000 Gt; gap-closure institutions;
# theta 0.50), with no erosion and with kappa 2.7% a year:
#   v8 central           phi = 1 - theta * u_r * k_r(t) * f(t),  u_r = (g_r,a - min g_a)/(max g_a - min g_a) at the anchor
#                        year, k_r(t) = g_r(t)/g_r(2025): the 2023 ranking scaled by the region's own gap path
#   gap first, fixed     g^_r(t) = g_r(t) f(t) projected first, then normalised with the ANCHOR-year range (min and max of
#                        2023 held fixed), clipped to [0, 1]: phi = 1 - theta * u_r(t)
#   gap first, re-normed the same, but min and max taken again every year: the most constrained region is always u = 1
# f(t) = (1 - kappa)^(t - 2025). Reported: the final-energy-weighted share of the extra effort held back (1 - phi) by
# sector, phi by region, and how far the forms differ.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
a <- pfmAnchorFor("output/remind-inputs/v8", "EU21")
s <- readRDS("output/pfm/v8/coupling/scen-v7Bfix-gapclosure-v8panel.rds")
o <- pfm:::.pfmV6Options(pfmV6CouplingDefaults())
st <- computeStrengthPath(a, s, holdYear = o$holdYear, theta = 0.5, hold = o$hold)
TH <- 0.5; YY <- seq(2025, 2100, 5)
rg <- st$regions[st$regions$sector %in% c("Bulk", "Diffuse") & st$regions$year %in% YY, c("sector", "region", "year", "g")]
an <- a$region[, c("sector", "region", "g", "u")]; names(an)[3] <- "ga"
rg <- merge(rg, an, by = c("sector", "region"))
g0 <- rg[rg$year == a$t0, c("sector", "region", "g")]; names(g0)[3] <- "g0"
rg <- merge(rg, g0, by = c("sector", "region"))
rng <- do.call(rbind, lapply(split(an, an$sector), function(d) data.frame(sector = d$sector[1], gmin = min(d$ga), gmax = max(d$ga))))
rg <- merge(rg, rng, by = "sector")
clip <- function(x) pmin(pmax(x, 0), 1)
forms <- function(kappa) {
  d <- rg; f <- (1 - kappa)^(d$year - a$t0); gh <- d$g * f
  d$`v8 central` <- clip(1 - TH * d$u * (d$g / d$g0) * f)
  d$`gap first, fixed range` <- clip(1 - TH * clip((gh - d$gmin) / (d$gmax - d$gmin)))
  key <- paste(d$sector, d$year)
  lo <- ave(gh, key, FUN = min); hi <- ave(gh, key, FUN = max)
  d$`gap first, re-normalised each year` <- clip(1 - TH * (gh - lo) / (hi - lo))
  d$kappa <- kappa; d
}
d <- rbind(forms(0), forms(0.027))
F <- c("v8 central", "gap first, fixed range", "gap first, re-normalised each year")
# check: the v8 central form reproduces the coupling's own regional-strength shares
chk <- pfmV6Shares(a, s, theta = TH, options = list(strength = "regional"))$shares
m <- merge(d[d$kappa == 0, c("sector", "region", "year", "v8 central")], chk[, c("sector", "region", "year", "phi")])
stopifnot(max(abs(m$`v8 central` - m$phi)) < 1e-8)
wR <- a$regionWeights
held <- do.call(rbind, lapply(split(d, paste(d$kappa, d$sector, d$year)), function(x) {
  w <- wR[x$region]; data.frame(kappa = x$kappa[1], sector = x$sector[1], year = x$year[1],
    t(sapply(F, function(f) sum((1 - x[[f]]) * w) / sum(w))), check.names = FALSE) }))
held <- held[order(held$kappa, held$sector, held$year), ]
diffs <- do.call(rbind, lapply(split(d, paste(d$kappa, d$sector)), function(x) data.frame(kappa = x$kappa[1], sector = x$sector[1],
  maxAbsFixed = max(abs(x[[F[2]]] - x[[F[1]]])), maxAbsRenorm = max(abs(x[[F[3]]] - x[[F[1]]])),
  rank2100Fixed = stats::cor(x[x$year == 2100, F[1]], x[x$year == 2100, F[2]], method = "spearman"),
  rank2100Renorm = stats::cor(x[x$year == 2100, F[1]], x[x$year == 2100, F[3]], method = "spearman"))))
saveRDS(list(made = format(Sys.time(), "%Y-%m-%d %H:%M"), group = "v8", theta = TH, gdx = attr(s, "gdx"), forms = F,
             phi = d, heldBack = held, differences = diffs, range = rng), "output/pfm/v8/gap-order.rds")
options(width = 200)
cat("share of the extra effort held back (final-energy weighted, EU21):\n")
print(held[held$year %in% c(2030, 2050, 2100), ], digits = 3, row.names = FALSE)
cat("\nhow far the forms differ from v8 central (|phi| max over regions and years; Spearman of 2100 shares):\n"); print(diffs, digits = 3, row.names = FALSE)
for (sec in c("Bulk", "Diffuse")) for (y in c(2050, 2100)) { x <- d[d$kappa == 0 & d$sector == sec & d$year == y, c("region", "u", F)]
  cat("\n", sec, y, "kappa 0: phi by region\n"); print(x[order(-x$u), ], digits = 2, row.names = FALSE) }
