# Does the two-way coupling matter? (the model paper's review v02, point M1)
#   Rscript analysis/v8/openLoopStrength.R [group]     (repo root; default v8) -> output/pfm/<group>/coupling/open-loop-strength.rds
# The strength k(t) of every coupled run is recomputed from its final energy system on each iteration; across the
# coupled runs it barely moves (strength-support.rds$support). This script separates the two things k(t) could depend on:
#   (a) the FEEDBACK: the limit changes the pathway, which changes k(t) - compare k on the no-politics 1000 Gt reference
#       pathway (theta = 0, never constrained) with k on the coupled headline (hold the price) and its hold-the-budget twin;
#   (b) the PATHWAY being assessed: k on the current-policies pathway (NPi) and on the uncoupled 1000 Gt pathway.
# k(t) is computed exactly as the coupling computes it (computeStrengthPath on the group's staged anchor, theta 0.50, the
# run's institution rule: gap closure, SSP2), on each gdx's scenario panel. The headline's own panel is the cached
# coupling/scen-PFMlevelBfix-<group>.rds; the others are built from their fulldata.gdx and cached beside it.
# Check: k on the headline panel reproduces the headline run's last recorded k (strength-support.rds) to 1e-2 (that call saw the previous iteration's energy system).
# Offline only: no REMIND run. An open-loop coupled run (k fixed at the reference pathway's path) is what would turn (a)
# into a pathway result; this script shows whether such a run could differ.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v8" })
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [open-loop:", g, "] ", ...)
CPL <- file.path("output/pfm", g, "coupling"); RR <- file.path("output/remind-runs", g, "EU21")
suppressMessages(madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE); pd <- pfm:::.pfmPanelDefForGroup(file.path("output/pfm", g), rc$panel)
options(pfm.panel = pd[intersect(c("firstYear", "lastYear", "movingAverage", "ieaVersion", "geothermal", "democracy", "overallAccountability", "fossilRents"), names(pd))])
a <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")
pick <- function(pat) { d <- sort(Sys.glob(file.path(RR, pat)), decreasing = TRUE); d <- d[file.exists(file.path(d, "fulldata.gdx"))]
  if (!length(d)) stop("no finished run matching ", pat); d[1] }
PATHS <- c(
  "current policies (NPi), uncoupled"            = pick("SSP2-EU21-NPi2025_*"),
  "1000 Gt, uncoupled"                           = pick("SSP2-EU21-PkBudg1000_*"),
  "1000 Gt, no-politics reference (theta 0)"     = pick("SSP2-EU21-PkBudg1000-PFM-noPolitics-holdPrice-v8_*"),
  "1000 Gt, hold the price (headline)"           = pick("SSP2-EU21-PkBudg1000-PFM-holdPrice-v8_*"),
  "1000 Gt, hold the budget"                     = pick("SSP2-EU21-PkBudg1000-PFM-holdBudget-v8_*"),
  "1000 Gt, hold the price, theta 0.675"         = pick("SSP2-EU21-PkBudg1000-PFM-holdPrice-theta675-v8_*"),
  "1000 Gt, hold the price, governance cap fixed" = pick("SSP2-EU21-PkBudg1000-PFM-holdPrice-exoGov6Fixed-v8_*"))
scenOf <- function(lab, d) {
  gdx <- normalizePath(file.path(d, "fulldata.gdx"), winslash = "/")
  cache <- if (grepl("headline", lab)) file.path(CPL, paste0("scen-PFMlevelBfix-", g, ".rds")) else
    file.path(CPL, paste0("scen-openloop-", gsub("[^A-Za-z0-9]+", "-", basename(d)), ".rds"))
  if (file.exists(cache)) { s <- readRDS(cache); if (is.null(attr(s, "gdx")) || identical(attr(s, "gdx"), gdx)) return(s) }
  say("building the scenario panel of ", basename(d))
  s <- panelDataScenario(gdxFile = gdx, aggregate = TRUE, gdxRegionMappingFile = "regionmapping_21_EU11.csv",
                         outputRegionMappingFile = "country", ssp = "SSP2", institutions = "gapclosure", fossilRentsPrice = "regional")
  attr(s, "gdx") <- gdx; saveRDS(s, cache); s
}
YRS <- c(2025, 2030, 2040, 2050, 2060, 2070, 2080, 2090, 2100)
rows <- list(); regs <- list()
for (lab in names(PATHS)) {
  s <- scenOf(lab, PATHS[[lab]]); st <- computeStrengthPath(a, s, theta = 0.5)
  k <- st$strength[st$strength$year %in% YRS, c("sector", "year", "k", "G")]
  rows[[lab]] <- cbind(pathway = lab, run = basename(PATHS[[lab]]), k)
  r <- st$regions[st$regions$year %in% c(2025, 2050, 2100), c("sector", "region", "year", "g")]; regs[[lab]] <- cbind(pathway = lab, r)
  say(lab, ": k(2050) ", paste(sprintf("%s %.3f", k$sector[k$year == 2050], k$k[k$year == 2050]), collapse = ", "))
}
K <- do.call(rbind, rows); R <- do.call(rbind, regs); rownames(K) <- rownames(R) <- NULL
# the check against the headline run's own last call
sup <- readRDS(file.path(CPL, "strength-support.rds"))$support
rec <- sup[sup$resolution == "EU21" & sup$run == paste0("PFMlevelBfix-", g) & sup$year %in% YRS, c("sector", "year", "k")]
h <- K[K$pathway == "1000 Gt, hold the price (headline)", ]; m <- merge(h, rec, by = c("sector", "year"), suffixes = c("", ".run"))
dev <- max(abs(m$k - m$k.run)); say("check: headline k against the run's last call, max |difference| ", signif(dev, 2)); stopifnot(dev < 1e-2)   # the last call saw the energy system of the iteration before the final one
W <- stats::reshape(K[, c("pathway", "sector", "year", "k")], idvar = c("pathway", "sector"), timevar = "year", direction = "wide")
names(W) <- sub("^k\\.", "k", names(W))
ref <- W[W$pathway == "1000 Gt, no-politics reference (theta 0)", ]
W$dk2050 <- W$k2050 - ref$k2050[match(W$sector, ref$sector)]; W$dk2100 <- W$k2100 - ref$k2100[match(W$sector, ref$sector)]
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), strength = K, wide = W, regions = R, check = dev,
            note = paste("k(t) by computeStrengthPath on the group's EU21 anchor, theta 0.50, gap-closure institutions, SSP2, on each run's final",
                         "energy system. dk: against the no-politics 1000 Gt reference (theta 0). The feedback is the difference between the",
                         "coupled runs and the reference; the pathway dependence is the difference between NPi and the 1000 Gt pathways."))
saveRDS(out, file.path(CPL, "open-loop-strength.rds")); say("wrote ", file.path(CPL, "open-loop-strength.rds"))
options(width = 200); print(W[order(W$sector, W$pathway), ], row.names = FALSE, digits = 3)
