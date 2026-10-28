# v8 dry run (design note 0009 section 9.3): the coupling with the heteroscedastic slack, through the package, offline.
#   Rscript analysis/v8/hetCouplingDryRun.R [group] [sectors]   (repo root; default v7 Diffuse; "Bulk,Diffuse" for both)
#     -> output/pfm/<group>/v8-het-coupling-dryrun[-<sectors>].rds
# A throwaway copy of the group (scratch resultsDir) whose selected spec carries slackDrivers = list(Diffuse = "Fossil
# Rents") and whose frontier.rds holds the heteroscedastic buildings & transport frontier, refitted here on the
# training panel with the World Bank rents (analysis/v8/_rents.R). The package then builds the anchor
# (computeAnchorGap) and the share path (pfmV6Shares, theta 0.5) on the coupled hold-the-price headline run's energy
# system (EU21, PkBudg1000), whose scenario panel gets the rents linked to REMIND (.pfmScenarioFossilRents). Against
# the same computation on the unchanged group. Nothing else of v8 (fossil bound, coverage rule) is applied: this
# isolates the slack.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
source("analysis/v8/_rents.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
SECS <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a) >= 2) strsplit(a[2], ",")[[1]] else "Diffuse" })
SUF <- if (identical(SECS, "Diffuse")) "" else paste0("-", paste(SECS, collapse = "-"))
GD <- file.path("output/pfm", g); modelDir <- "output/pfm/fit-cache"
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path(modelDir, "panels", paste0("panel_", hash, ".rds")))
panelR <- v8AddRents(panel, v8RentsHistory(getItems(panel, dim = 1), getYears(panel, as.integer = TRUE), file.path(GD, "v8-wdi-rents.rds")))
panelR <- panelR[, , setdiff(getNames(panelR), c("Fossil Rents|Bulk", "Fossil Rents|Diffuse"))]
scen <- readRDS(file.path(GD, "coupling", paste0("scen-PFMlevelBfix-", g, ".rds"))); gdx <- attr(scen, "gdx")
scenR <- mbind(scen, pfm:::.pfmScenarioFossilRents(panelR, gdx, "regionmapping_21_EU11.csv",
                                                   getYears(scen, as.integer = TRUE), getItems(scen, dim = 1)))
w <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights

# the dry-run group: the spec with slackDrivers, the frontier with the heteroscedastic B&T fit
RD <- file.path(tempdir(), "pfm-dryrun"); DG <- "v8dry"; dir.create(file.path(RD, DG), recursive = TRUE, showWarnings = FALSE)
for (f in c("manifest.json", "donor-assignment-band-Bulk.rds", "donor-assignment-band-Diffuse.rds")) file.copy(file.path(GD, f), file.path(RD, DG, f), overwrite = TRUE)
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
sel <- lapply(sel, function(e) { e$slackDrivers <- stats::setNames(rep(list("Fossil Rents"), length(SECS)), SECS); e })
yaml::write_yaml(sel, file.path(RD, DG, "selected-models-pfm.yml"))
fr <- readRDS(file.path(GD, "frontier.rds"))
cts <- list()
for (sec in SECS) {
  cfgS <- pfm:::.pfmNormSpec(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panelR, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), pfm:::.pfmSpecArgs(cfgS)))))
  ct <- as.data.frame(unclass(ff$coeftest)); names(ct) <- c("estimate", "stdError", "zValue", "pValue"); ct$term <- rownames(ff$coeftest)
  fr$bySector[[sec]]$coefTable <- ct; fr$bySector[[sec]]$driverScaling <- ff$driverScaling; fr$bySector[[sec]]$scores <- ff$frontier
  cts[[sec]] <- cbind(sector = sec, ct[startsWith(ct$term, "slack_"), ])
}
ct <- do.call(rbind, cts)
saveRDS(fr, file.path(RD, DG, "frontier.rds"))

anc <- list(v7 = computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w, histData = panelR, verbose = FALSE),
            het = computeAnchorGap(DG, resultsDir = RD, modelDir = modelDir, weights = w, histData = panelR, verbose = FALSE))
sh <- list(v7 = pfmV6Shares(anc$v7, scenR, theta = 0.5), het = pfmV6Shares(anc$het, scenR, theta = 0.5),
           hetRegional = pfmV6Shares(anc$het, scenR, theta = 0.5, options = list(strength = "regional")))
st <- function(x, sec, y) x$strength$k[x$strength$sector == sec & x$strength$year == y]
kTab <- do.call(rbind, lapply(c("Bulk", "Diffuse"), function(sec) data.frame(sector = sec, year = c(2030, 2050, 2070, 2100),
  k_v7 = sapply(c(2030, 2050, 2070, 2100), function(y) st(sh$v7, sec, y)), k_het = sapply(c(2030, 2050, 2070, 2100), function(y) st(sh$het, sec, y)))))
uOfSec <- function(sec) merge(anc$v7$region[anc$v7$region$sector == sec, c("region", "u")], anc$het$region[anc$het$region$sector == sec, c("region", "u")],
                               by = "region", suffixes = c("_v7", "_het"))
uTab <- uOfSec("Diffuse"); uTabBulk <- uOfSec("Bulk")
phiOf <- function(x, r, y) { s <- x$shares; s$phi[s$sector == "Diffuse" & s$region == r & s$year == y] }
phiTab <- do.call(rbind, lapply(uTab$region, function(r) data.frame(region = r,
  phi2050_v7 = phiOf(sh$v7, r, 2050), phi2050_het = phiOf(sh$het, r, 2050), phi2050_hetRegional = phiOf(sh$hetRegional, r, 2050),
  phi2100_v7 = phiOf(sh$v7, r, 2100), phi2100_het = phiOf(sh$het, r, 2100), phi2100_hetRegional = phiOf(sh$hetRegional, r, 2100))))
# Saudi Arabia's distance multiplier, from the anchor and the scenario's slack shift
sauMult <- do.call(rbind, lapply(SECS, function(sec) {
  es <- pfm:::.pfmFrontierEta(anc$het$designs[[sec]], scenR); es <- es[es$region == "SAU", ]
  sA <- anc$het$country$slackShiftAnchor[anc$het$country$sector == sec & anc$het$country$region == "SAU"]
  m <- data.frame(sector = sec, year = es$year, multiplier = exp(es$slackShift - sA)); m[m$year >= 2025 & m$year <= 2100, ] }))
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), sectors = SECS, gdx = gdx, strength = kTab, u = uTab, uBulk = uTabBulk,
             phi = phiTab, sauMultiplier = sauMult, slackWeight = ct),
        file.path(GD, paste0("v8-het-coupling-dryrun", SUF, ".rds")))
options(width = 200)
cat("slack terms:\n"); print(ct[, c("sector", "term", "estimate", "zValue")], row.names = FALSE, digits = 3)
cat("\nstrength k (common), EU21 hold the price, theta 0.5:\n"); print(kTab, digits = 3, row.names = FALSE)
cat("\nbuildings & transport ranking u and share phi:\n"); print(merge(uTab, phiTab)[order(-uTab$u_het), ], digits = 2, row.names = FALSE)
cat("\npower & industry ranking u (top 10):\n"); print(uTabBulk[order(-uTabBulk$u_het), ][1:10, ], digits = 2, row.names = FALSE)
cat("rank correlation of u with v7, P&I:", round(stats::cor(uTabBulk$u_v7, uTabBulk$u_het, method = "spearman"), 3),
    "| B&T:", round(stats::cor(uTab$u_v7, uTab$u_het, method = "spearman"), 3), "\n")
cat("\nSaudi Arabia, distance kept relative to 2023:\n"); print(sauMult[sauMult$year %in% c(2025, 2030, 2050, 2070, 2100), ], digits = 3, row.names = FALSE)
