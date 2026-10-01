# GP-20 / review-v10 M3: how much does WHEN the feasibility share is read move the ordering?
#
#   Rscript analysis/checks/phiReadingYear.R [group]        # from the project root
#
# WHY. The paper carries three readings of the regional share phi:
#   seed    offline, from the 2022 data, covered countries aggregated to regions (frontier-rung-phi.rds,
#           headline rung; the object Fig. 3b's rank spans describe)
#   offline the PFM-side bound at 2025 with the published lambda as a speed limit and REMIND not
#           re-optimising (coupling-summary.rds$boundAnchor; combined share, min rule)
#   coupled the share REMIND received in the held-price headline run, read at the tier year 2035 after
#           the projection (coupled-runs.rds, -PFMlevelBfix; per sector: ETS pays Bulk, ES pays Diffuse)
# The referee's point: the step from seed to coupled includes a projection whose rate cannot be told
# from a placebo, and it moves at least one large region (China, supply side) from the floor to 1.
#
# WHAT. For each pair of readings, on the regions all of them cover (the 20 EU21 regions with a covered
# country; the USA has none): Spearman rank correlation, median |dphi|, the region that moves most, and
# the floor regions (phi = 1 - theta) in each. Per sector where the reading is per sector; combined
# (the more constrained sector, as the coupling's floor) for all three.
#
# LIMITS. EU21 only: the offline bound exists at that resolution only. The seed uses equal country
# weights (the GDP-weighted variant is reported alongside). Ordinal comparison only - the three objects
# are normalised separately, so their levels are not comparable.

args  <- commandArgs(trailingOnly = TRUE)
GROUP <- if (length(args) >= 1) args[1] else "v5"
GDIR  <- file.path("output/pfm", GROUP)
THETA <- 0.5

fr <- readRDS(file.path(GDIR, "frontier-rung-phi.rds"))
cs <- readRDS(file.path(GDIR, "coupling", "coupling-summary.rds"))
cr <- readRDS(file.path(GDIR, "coupling", "coupled-runs.rds"))
live <- cr$runs[!cr$runs$superseded, ]
sc <- live$scenario[live$resolution == "EU21" & grepl("PkBudg1000-PFMlevelBfix$", live$scenario)]
cp <- cr$phi[cr$phi$resolution == "EU21" & cr$phi$scenario == sc, ]

seed <- function(sector, w) fr$bySector[[sector]]$phi$EU21[[w]]$headline
seedMin <- function(w) fr$minRule$EU21[[w]]$phi$headline
off <- cs$boundAnchor[cs$boundAnchor$year == 2025, ]
offPhi <- setNames(off$phi, off$region)
coupled <- list(Bulk = setNames(cp$phiETS, cp$region), Diffuse = setNames(cp$phiES, cp$region),
                combined = setNames(pmin(cp$phiETS, cp$phiES), cp$region))

cmp <- function(a, b, what, from, to) {
  k <- intersect(names(a), names(b)); a <- a[k]; b <- b[k]
  d <- b - a; i <- which.max(abs(d))
  data.frame(comparison = what, from = from, to = to, n = length(k),
             spearman = stats::cor(a, b, method = "spearman"), medAbsD = stats::median(abs(d)),
             maxMoveRegion = k[i], maxMoveFrom = unname(a[i]), maxMoveTo = unname(b[i]),
             floorFrom = paste(sort(k[abs(a - (1 - THETA)) < 1e-4]), collapse = ","),
             floorTo = paste(sort(k[abs(b - (1 - THETA)) < 1e-4]), collapse = ","),
             stringsAsFactors = FALSE)
}
rows <- list()
for (w in c("equal", "gdp")) {
  for (s in c("Bulk", "Diffuse")) rows[[length(rows) + 1]] <- cmp(seed(s, w), coupled[[s]], s, paste0("seed 2022 (", w, ")"), "coupled 2035")
  rows[[length(rows) + 1]] <- cmp(seedMin(w), offPhi, "combined", paste0("seed 2022 (", w, ")"), "offline 2025")
  rows[[length(rows) + 1]] <- cmp(seedMin(w), coupled$combined, "combined", paste0("seed 2022 (", w, ")"), "coupled 2035")
}
rows[[length(rows) + 1]] <- cmp(offPhi, coupled$combined, "combined", "offline 2025", "coupled 2035")
out <- do.call(rbind, rows)
# China on the supply side, named by the referee: its share in each reading
china <- data.frame(reading = c("seed 2022 (equal)", "coupled 2035"),
                    Bulk = c(unname(seed("Bulk", "equal")["CHA"]), unname(coupled$Bulk["CHA"])),
                    Diffuse = c(unname(seed("Diffuse", "equal")["CHA"]), unname(coupled$Diffuse["CHA"])))
print(out, row.names = FALSE, digits = 3); print(china, row.names = FALSE, digits = 3)
f <- file.path(GDIR, "phi-reading-year.rds")
saveRDS(list(comparisons = out, china = china, theta = THETA, coupledRun = sc, group = GROUP,
             generated = format(Sys.time(), "%Y-%m-%dT%H:%M")), f)
cat("wrote", f, "\n")
