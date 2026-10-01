# GP-19(b): which release of each institutional and policy dataset a Run-Group's panel was built from,
# and what the panel does to them before estimation.
#
#   Rscript analysis/checks/inputVintages.R [group]        # from the project root, on the workstation
#
# WHY. The Run-Group artifacts record the panel hash, not the source releases. WGI revises its whole
# history in every release and V-Dem re-estimates every country-year in every version, so a paper that
# names the datasets without their release is not reproducible. This script reads the releases off the
# madrat file-hash cache the panel was built through, and then PROVES the link by rebuilding panel
# columns from the cached source reads.
#
# WHAT IT FOUND (v5, 2026-09-22) - and why the proof matters: the panel is not the normalised source.
# panelDataHistorical() applies a centred moving average (movingAverage = 5; the window shrinks at the
# ends, so 2022 averages 2020-2022) to EVERY panel column after normalisation, the outcome included.
# The check below reproduces the panel exactly only with that smoothing; without it the V-Dem column
# is not even a monotone function of the source.
#
# LIMITS. Only countries whose series is complete over the panel years are checked (the smoothing
# ignores NAs and the medians imputed for the rest follow a different path). CAPMF is checked through
# the cached calcPolicyStringency output, not the raw csv, because the stringency aggregation sits in
# between.

suppressMessages(library(magclass))
args  <- commandArgs(trailingOnly = TRUE)
GROUP <- if (length(args) >= 1) args[[1]] else "v5"
GDIR  <- file.path("output/pfm", GROUP)
CACHE <- "data/madrat"
K     <- 5L   # panelDataHistorical(movingAverage = 5), the default every sweep entry point passes

man   <- jsonlite::read_json(file.path(GDIR, "manifest.json"))
panF  <- file.path("output/pfm/fit-cache/panels", paste0("panel_", man$panel_hash, ".rds"))
p     <- readRDS(panF); Y <- getYears(p)

unwrap <- function(f) { x <- readRDS(file.path(CACHE, f)); if (is.magpie(x)) x else x$x }
hashes <- function(src) { d <- readRDS(file.path(CACHE, paste0("fileHashCache", src, ".rds"))); d$src <- src; d }
sma    <- function(v, k = K) { h <- floor(k / 2); n <- length(v)
  vapply(seq_len(n), function(i) mean(v[max(1, i - h):min(n, i + h)], na.rm = TRUE), numeric(1)) }

# ---- releases, from the file names and dates madrat hashed ------------------------------------------
fh <- rbind(hashes("WGIindicator"), hashes("VDem"), hashes("CAPMF"))
pick <- function(src, pat) fh[fh$src == src & grepl(pat, fh$name), ][1, ]
wgi <- pick("WGIindicator", "^wgidataset.*\\.xlsx$")
vd  <- pick("VDem", "\\.csv$")
cap <- pick("CAPMF", "^capmf\\.csv$")
wgiRelease <- as.integer(sub(".*-(\\d{4})\\.xlsx$", "\\1", wgi$name))
vdemVersion <- as.integer(sub(".*-v(\\d+)(_\\d+)?\\.csv$", "\\1", vd$name))

# CAPMF: the SDMX dataflow version and the last year of data, from the file itself
capF <- file.path("C:/_data/work/remind input data/sources/CAPMF", cap$name)
capHead <- utils::read.csv(capF, nrows = 1)
capYears <- range(data.table::fread(capF, select = "TIME_PERIOD")$TIME_PERIOD)

# ---- proof: panel column == sma_K(min-max(source)) --------------------------------------------------
check <- function(x, srcName, panName, normalise = TRUE) {
  cc <- intersect(getItems(x, 1), getItems(p, 1)); yy <- intersect(Y, getYears(x))
  raw <- as.array(x[cc, yy, srcName])[, , 1]; pan <- as.array(p[cc, yy, panName])[, , 1]
  ok  <- apply(raw, 1, function(r) all(is.finite(r))) & apply(pan, 1, function(r) all(is.finite(r)))
  if (normalise) {
    mn <- min(x[, , srcName], na.rm = TRUE); mx <- max(x[, , srcName], na.rm = TRUE)
    raw <- (raw - mn) / (mx - mn)
  }
  sm <- t(apply(raw[ok, , drop = FALSE], 1, sma))
  data.frame(variable = panName, countries = sum(ok),
             maxDiffSmoothed = max(abs(pan[ok, ] - sm)),
             maxDiffUnsmoothed = max(abs(pan[ok, ] - raw[ok, ])))
}
vdem <- unwrap("readVDem.rds")
wgiX <- unwrap("convertWGIindicator.rds")
wgiX <- time_interpolate(wgiX[, , "Government Effectiveness (WGI)"], Y, integrate_interpolated_years = TRUE)
ps   <- unwrap("calcPolicyStringency.rds")
proof <- rbind(
  check(vdem, "Vertical Accountability (VDem)", "Vertical Accountability (VDem)"),
  check(wgiX, "Government Effectiveness (WGI)", "Government Effectiveness (WGI)"),
  check(ps, "bulk", "Policy Stringency|Bulk", normalise = FALSE),
  check(ps, "diffuse", "Policy Stringency|Diffuse", normalise = FALSE))
proof$reproduced <- proof$maxDiffSmoothed < 1e-10
print(proof)
if (!all(proof$reproduced)) stop("panel NOT reproduced from the cached sources - the vintages below are unproven")

out <- list(
  group = GROUP, panelHash = man$panel_hash, created = format(Sys.time(), "%Y-%m-%d %H:%M"),
  wgi  = list(file = wgi$name, release = wgiRelease, downloaded = format(wgi$mtime, "%Y-%m-%d"),
              indicator = "Government Effectiveness (estimate)"),
  vdem = list(file = vd$name, version = vdemVersion, fileDate = format(vd$mtime, "%Y-%m-%d"),
              indicator = "v2x_veracc", datasetDoi = "10.23696/vdemds26"),
  capmf = list(file = cap$name, downloaded = format(cap$mtime, "%Y-%m-%d"),
               dataflow = as.character(capHead$DATAFLOW), firstYear = capYears[1], lastYear = capYears[2]),
  panel = list(years = range(getYears(p, as.integer = TRUE)), movingAverage = K,
               normalisation = "min-max over all country-years of the source, then the moving average"),
  proof = proof)
saveRDS(out, file.path(GDIR, "input-vintages.rds"))
cat(sprintf("WGI %d release | V-Dem v%d | CAPMF %s (%d-%d) | panel smoothed k=%d -> %s\n",
            wgiRelease, vdemVersion, out$capmf$downloaded, capYears[1], capYears[2], K,
            file.path(GDIR, "input-vintages.rds")))
