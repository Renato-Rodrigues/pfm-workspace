# The emissions band from the estimation (the GMD model paper's GP-12; design note 0012, decision D12).
#   Rscript analysis/v8/emissionsBand.R [group]          check only: rebuild the two edge anchors and compare with the bootstrap
#   Rscript analysis/v8/emissionsBand.R [group] stage    write output/remind-inputs/<group>-bandLow and <group>-bandHigh
# The country block bootstrap (analysis/v8/frontierBlockBootstrap.R -> output/pfm/<group>/frontier-block-bootstrap.rds)
# kept the two resamples at the 5th and 95th percentile of the world's mean constraint in 2050 (`edges`, their ceiling
# coefficients). Each becomes a Run-Group for one coupled hold-the-price run (scenario-matrix-v8.yml, section v8_band,
# start tag V8BANDEU21): a copy of the group's export whose anchor carries that resample's ceiling coefficients, its
# rebuilt 2023 country anchor (etaAnchor, yAnchor, q, ceilingAnchor, indexAnchor) and its EU21 regional ranking u - exactly
# what the bootstrap evaluated (its anchorFor, reused here), so the two runs are the band's edges in CO2. The slack
# (rents) parameters and everything else stay the group's, as in the bootstrap. EU21 only (the band runs are EU21); the
# staged anchor carries no other resolution, so it cannot be used at one by mistake. Nothing in the group or the package
# changes. Needs output/pfm/<group> (frontier-block-bootstrap.rds, manifest.json, coupling/scen-PFMlevelBfix-<group>.rds),
# the Fit Cache panel and data/madrat/<group>: run where those are (the workstation), then sync the two folders to the
# cluster with the group's remind-inputs.
# BLOCKED (2026-11-23): the high edge (p95, resample 130) gives a NaN share (NES, buildings & transport, 2050), likely a zero
# 2025 gap making the regional strength 0/0; 123 of the bootstrap's 184 resamples have a NaN mean constraint, so the edges
# were chosen from 61; and the bootstrap's central ranking differs from the export's by up to 0.064. Do not stage or run
# V8BANDEU21 until the NaN is handled, the bootstrap re-evaluated (its refits are cached) and the edges re-selected.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); STAGE <- "stage" %in% args; args <- setdiff(args, "stage")
g <- if (length(args)) args[1] else "v8"
GD <- file.path("output/pfm", g); EXP <- file.path("output/remind-inputs", g); modelDir <- "output/pfm/fit-cache"
say <- function(...) message("[emissions-band:", g, "] ", ...)
EDGES <- c(bandLow = "p05", bandHigh = "p95")

# --- the same setup as frontierBlockBootstrap.R -------------------------------------------------------------------------
options(pfm.panel = list(firstYear = 2000L, lastYear = 2023L, movingAverage = 5L, ieaVersion = "latest", geothermal = TRUE,
                         democracy = TRUE, overallAccountability = TRUE, fossilRents = TRUE))
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g)), forcecache = TRUE, .verbose = FALSE)
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path(modelDir, "panels", paste0("panel_", hash, ".rds")))
bb <- readRDS(file.path(GD, "frontier-block-bootstrap.rds"))
if (is.null(bb$edges)) stop("no `edges` in frontier-block-bootstrap.rds - re-run analysis/v8/frontierBlockBootstrap.R")
scen <- readRDS(file.path(GD, "coupling", bb$scenario %||% paste0("scen-PFMlevelBfix-", g, ".rds")))
OPT <- list(strength = "regional")
x0 <- readRDS(file.path(EXP, "phi-anchor.rds")); stopifnot(identical(x0$format, "pfm-anchor/1"))
w <- pfm:::pfmAnchorFor(EXP, "EU21")$weights
anc0 <- computeAnchorGap(g, resultsDir = "output/pfm", modelDir = modelDir, weights = w, histData = panel, verbose = FALSE)

# --- the anchor for a set of ceiling coefficients: frontierBlockBootstrap.R's anchorFor, unchanged ----------------------
etaOrig <- pfm:::.pfmFrontierEta; cache <- new.env()
etaCached <- function(design, data, returnDesign = FALSE) {
  key <- paste(design$sector, paste(dim(data), collapse = "x"))
  if (is.null(cache[[key]])) cache[[key]] <- etaOrig(design, data, returnDesign = TRUE)
  r <- cache[[key]]; f <- r$frame
  f$eta <- as.numeric(r$mm[, names(design$beta), drop = FALSE] %*% design$beta)
  if (isTRUE(returnDesign)) list(frame = f, mm = r$mm) else f
}
assignInNamespace(".pfmFrontierEta", etaCached, ns = "pfm")
ta <- anc0$anchorYear
anchorFor <- function(betas) {
  a <- anc0
  for (sec in names(betas)) {
    a$designs[[sec]]$beta <- betas[[sec]]
    eh <- etaCached(a$designs[[sec]], panel); eh <- eh[eh$year == ta, ]
    etaA <- stats::setNames(eh$eta, eh$region)
    i <- which(a$country$sector == sec); cc <- a$country[i, ]
    sNew <- 10 * stats::plogis(etaA[cc$region]); n <- a$designs[[sec]]$nSqueeze
    sq <- function(p) pfm:::.pfmSqueeze(pmin(pmax(p, 0), 1), n)
    e0 <- pmin((stats::plogis(cc$yAnchor) * n - 0.5) / (n - 1) * 10 / cc$ceilingAnchor, 1)
    y <- ifelse(cc$basis == "observed", cc$yAnchor, stats::qlogis(sq(e0 * sNew / 10)))
    a$country$etaAnchor[i] <- etaA[cc$region]; a$country$yAnchor[i] <- y; a$country$q[i] <- etaA[cc$region] - y
    a$country$ceilingAnchor[i] <- sNew; a$country$indexAnchor[i] <- 10 * stats::plogis(y)
    ok <- is.finite(a$country$q[i])
    path <- data.frame(region = cc$region[ok], year = ta, feasibleIndex = a$country$indexAnchor[i][ok], ceilingIndex = sNew[ok],
                       outOfCoverage = FALSE, stringsAsFactors = FALSE)
    agg <- suppressWarnings(aggregateFeasibilityToRegions(path, a$mapping, weights = a$weights, theta = 0.5))
    agg <- agg[is.finite(agg$relativeGap), ]
    u <- stats::setNames((agg$relativeGap - min(agg$relativeGap)) / diff(range(agg$relativeGap)), agg$region)
    j <- which(a$region$sector == sec); a$region$u[j] <- u[a$region$region[j]]
  }
  a
}
load2050 <- function(a) { s <- pfmV6Shares(a, scen, theta = 0.5, options = OPT)$shares; mean(1 - s$phi[s$year == 2050]) }

# --- checks: the rebuild reproduces the group's anchor, and each edge reproduces the bootstrap's load -------------------
chk <- anchorFor(lapply(anc0$designs, `[[`, "beta"))
stopifnot(max(abs(chk$region$u - anc0$region$u), na.rm = TRUE) < 1e-8)
key <- function(d) paste(d$sector, d$region)
ic <- match(key(x0$country), key(anc0$country)); stopifnot(!anyNA(ic))
dq <- max(abs(x0$country$q - anc0$country$q[ic]), na.rm = TRUE)
say("the group's export and the recomputed anchor: max |q| difference ", signif(dq, 3))
if (dq > 1e-6) stop("the export's country anchor differs from computeAnchorGap's - not the anchor the bootstrap used")
ru <- x0$byResolution$EU21$region; iu <- match(key(ru), key(anc0$region))
du <- max(abs(ru$u - anc0$region$u[iu]), na.rm = TRUE)
if (du > 1e-6) stop("the export's EU21 ranking u differs from computeAnchorGap's (max ", signif(du, 3), ") - not the coupled anchor")
# The staged anchors are the COUPLED runs' anchor (the group's export) with an edge resample's coefficients. The bootstrap
# of 2026-11-15 evaluated its resamples around a central anchor whose u differs from the export's by up to 0.064 (found
# 2026-11-23, cause not identified; its central mean constraint 2050 is 0.1303 against the export's 0.1333). So the edges
# are checked by their offset from each one's own centre, not by their absolute load.
cNow <- load2050(anc0); pb <- bb$phi[bb$phi$year == 2050, ]; cBoot <- mean(1 - pb$central)
say("central mean constraint 2050: the export's anchor ", round(cNow, 4), ", the bootstrap's centre ", round(cBoot, 4))

for (nm in names(EDGES)) {
  e <- bb$edges[[EDGES[[nm]]]]
  a <- anchorFor(e$beta); ld <- load2050(a)
  say(nm, " (", EDGES[[nm]], ", resample ", e$resample, "): mean constraint 2050 ", round(ld, 4), ", offset from the centre ",
      round(ld - cNow, 4), " (bootstrap: ", round(e$load, 4), ", offset ", round(e$load - cBoot, 4), ")")
  if (abs((ld - cNow) - (e$load - cBoot)) > 0.005) stop(nm, ": the edge's offset from the centre moved by more than 0.005")
  if (!STAGE) next
  ng <- paste0(g, "-", nm); dst <- file.path("output/remind-inputs", ng)
  if (!dir.exists(dst)) { dir.create(dst, recursive = TRUE)
    ok <- file.copy(list.files(EXP, full.names = TRUE, all.files = TRUE, no.. = TRUE), dst, recursive = TRUE); stopifnot(all(ok)) }
  x <- x0
  for (sec in names(e$beta)) {
    b <- e$beta[[sec]]; stopifnot(setequal(names(b), names(x$designs[[sec]]$beta)))
    x$designs[[sec]]$beta <- b[names(x$designs[[sec]]$beta)]
  }
  ia <- match(key(x$country), key(a$country))
  for (f in c("etaAnchor", "yAnchor", "q", "ceilingAnchor", "indexAnchor")) x$country[[f]] <- a$country[[f]][ia]
  r <- x$byResolution$EU21$region; j <- match(key(r), key(a$region)); stopifnot(!anyNA(j))
  r$uModel <- r$u; r$u <- a$region$u[j]
  x$byResolution <- list(EU21 = list(mapping = x$byResolution$EU21$mapping, region = r, regionWeights = x$byResolution$EU21$regionWeights))
  x$group <- ng
  x$band <- list(edge = EDGES[[nm]], resample = e$resample, load = e$load, base = g,
                 from = file.path(GD, "frontier-block-bootstrap.rds"), made = format(Sys.time(), "%Y-%m-%d %H:%M"))
  saveRDS(x, file.path(dst, "phi-anchor.rds"))
  ld2 <- load2050(pfm:::pfmAnchorFor(dst, "EU21"))
  if (abs(ld2 - ld) > 1e-6) stop(ng, ": the staged anchor does not reproduce the rebuilt one (", ld2, " vs ", ld, ")")
  say("staged ", dst, ": mean constraint 2050 ", round(ld2, 4), "; rank correlation of u with the group's, by sector: ",
      paste(sprintf("%s %.2f", unique(r$sector), vapply(unique(r$sector), function(s) stats::cor(r$u[r$sector == s], r$uModel[r$sector == s], method = "spearman"), numeric(1))), collapse = ", "))
}
if (!STAGE) say("check only; add 'stage' to write the two Run-Groups")
