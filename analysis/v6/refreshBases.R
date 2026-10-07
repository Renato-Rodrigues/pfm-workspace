# Move the offline v6 analyses to new REMIND bases (PITFALLS.md 34), in one call:
#   1. find the newest SSP2-EU21-NPi2025 and SSP2-EU21-PkBudg1000 runs (with fulldata.gdx) in --dir;
#   2. snapshot output/pfm/<group>/phase1/ as phase1-remind-<old version>/ (never overwritten);
#   3. re-point the config.yml registry's SSP2 pair at them (only its two gdx lines change);
#   4. re-run phase1.R, couplingOffline.R, offlineHeadline.R, sspGovernanceSwap.R, ceilingGate.R
#      (with --all also donorAlternatives.R, satShape.R, specBand.R), stopping at the first failure;
#   5. print old vs new: k_s(t) on both energy systems, the offline headline shortfall, the ceiling
#      gate; saved as phase1/base-refresh.rds.
#
#   Rscript analysis/v6/refreshBases.R                      # dry run: what would change
#   Rscript analysis/v6/refreshBases.R --apply              # do it
#   options: --dir output/remind-runs/v6/EU21  --group v6  --all
# Bring the runs over first:  tools/syncFromCluster.sh <user>@<host> <project> v6 --runs 'SSP2-EU21-NPi2025_*'
#                             tools/syncFromCluster.sh <user>@<host> <project> v6 --runs 'SSP2-EU21-PkBudg1000_*'
# Run from the repo root. Takes about as long as phase1.R (the scenario panels are rebuilt).
a <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) { i <- match(paste0("--", name), a); if (is.na(i)) default else a[i + 1] }
apply <- "--apply" %in% a; all <- "--all" %in% a
dir <- opt("dir", "output/remind-runs/v6/EU21"); g <- opt("group", "v6")
suppressMessages(library(pfm))
source("analysis/v6/bases.R")
say <- function(...) cat("[refresh] ", ..., "\n", sep = "")
P1 <- file.path("output/pfm", g, "phase1")

# 1. the new bases
latest <- function(title) {
  hit <- Sys.glob(file.path(dir, paste0(title, "_20*")))
  hit <- hit[file.exists(file.path(hit, "fulldata.gdx"))]
  if (!length(hit)) stop("no finished ", title, " run in ", dir, " - sync it first (see the header)")
  file.path(hit[order(basename(hit), decreasing = TRUE)][1], "fulldata.gdx")
}
new <- c(NPi = latest("SSP2-EU21-NPi2025"), PkBudg1000 = latest("SSP2-EU21-PkBudg1000"))
rc <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
old <- v6Bases(rc)
vOld <- vapply(old, remindVersion, ""); vNew <- vapply(new, remindVersion, "")
for (k in names(new)) say(sprintf("%-10s %s (REMIND %s)\n%-10s -> %s (REMIND %s)", k, old[[k]], vOld[[k]], "", new[[k]], vNew[[k]]))
if (length(unique(vNew)) != 1) stop("the new bases come from different REMIND versions: ", paste(vNew, collapse = " vs "))
same <- identical(normalizePath(old, winslash = "/"), normalizePath(new, winslash = "/"))
if (same) { say("the registry already points at these runs - nothing to do"); quit(save = "no") }
if (!apply) { say("dry run - nothing changed. Re-run with --apply."); quit(save = "no") }

# 2. snapshot the current results
snap <- file.path("output/pfm", g, paste0("phase1-remind-", vOld[[1]]))
if (dir.exists(snap)) {
  say("snapshot ", snap, " exists - kept as it is (the first snapshot of that version wins)")
} else {
  dir.create(snap, recursive = TRUE)
  ok <- file.copy(list.files(P1, full.names = TRUE), snap, copy.date = TRUE)
  if (!all(ok)) stop("snapshot to ", snap, " incomplete")
  say("snapshot: ", length(ok), " files -> ", snap)
}
before <- list(strength = readRDS(file.path(P1, "strength.rds")),
               headline = tryCatch(readRDS(file.path(P1, "offline-headline.rds"))$summary, error = function(e) NULL),
               ceiling = tryCatch(readRDS(file.path(P1, "ceiling-gate.rds"))$deployed, error = function(e) NULL))

# 3. re-point the registry: only the gdx lines of the two entries change
rel <- function(p) sub(paste0("^", normalizePath(".", winslash = "/"), "/"), "", normalizePath(p, winslash = "/"))
y <- readLines("config.yml", warn = FALSE)
for (k in names(new)) {
  i <- grep(paste0('^\\s*gdx:\\s*"', gsub("([.])", "\\\\\\1", rel(old[[k]])), '"'), y)
  if (length(i) != 1) stop("config.yml: expected one gdx line for ", rel(old[[k]]), ", found ", length(i))
  y[i] <- sub('"[^"]*"', paste0('"', rel(new[[k]]), '"'), y[i])
}
writeLines(y, "config.yml")
rc2 <- pfmResolveConfig("config.yml", group = g, verbose = FALSE)
if (!identical(normalizePath(v6Bases(rc2), winslash = "/"), normalizePath(new, winslash = "/"))) stop("config.yml did not resolve to the new bases")
say("config.yml re-pointed (REMIND ", vNew[[1]], ")")

# 4. re-run the offline analyses
steps <- c("phase1.R", "couplingOffline.R", "offlineHeadline.R", "sspGovernanceSwap.R", "ceilingGate.R",
           if (all) c("donorAlternatives.R", "satShape.R", "specBand.R"))
for (s in steps) {
  say("running ", s)
  st <- system2(file.path(R.home("bin"), "Rscript"), c(file.path("analysis/v6", s), g))
  if (st != 0) stop(s, " failed (exit ", st, "). config.yml already points at the new bases; the old results are in ", snap)
}

# 5. old vs new
after <- list(strength = readRDS(file.path(P1, "strength.rds")),
              headline = tryCatch(readRDS(file.path(P1, "offline-headline.rds"))$summary, error = function(e) NULL),
              ceiling = tryCatch(readRDS(file.path(P1, "ceiling-gate.rds"))$deployed, error = function(e) NULL))
kTab <- function(s) { s <- s[s$resolution == "EU21" & s$run %in% c("NPi", "PkBudg1000") & s$year %in% c(2050, 2100), ]
                      stats::setNames(s$k, paste(s$run, s$sector, s$year)) }
kb <- kTab(before$strength); ka <- kTab(after$strength); kk <- intersect(names(kb), names(ka))
cmp <- data.frame(quantity = paste("k", kk), old = round(kb[kk], 3), new = round(ka[kk], 3), row.names = NULL)
if (!is.null(before$headline) && !is.null(after$headline)) {
  hb <- before$headline; ha <- after$headline
  key <- function(h) paste(h$case, h$theta); m <- match(key(hb), key(ha))
  sel <- !is.na(m) & grepl("^v6", hb$case) & abs(hb$theta - 0.5) < 1e-9
  cmp <- rbind(cmp, data.frame(quantity = paste0("shortfall 2050 % | ", hb$case[sel], " | theta 0.5"),
                               old = round(hb$shortfall2050pct[sel], 1), new = round(ha$shortfall2050pct[m[sel]], 1)))
}
if (!is.null(before$ceiling) && !is.null(after$ceiling)) {
  cmp <- rbind(cmp, data.frame(quantity = paste("ceiling gate", names(after$ceiling)),
                               old = round(before$ceiling[names(after$ceiling)], 3), new = round(after$ceiling, 3)))
}
cmp$change <- round(cmp$new - cmp$old, 3)
print(cmp, row.names = FALSE)
saveRDS(list(old = list(gdx = old, remind = vOld), new = list(gdx = new, remind = vNew), comparison = cmp,
             snapshot = snap, created = Sys.time()), file.path(P1, "base-refresh.rds"))
say("done. Old results: ", snap, "; comparison: ", file.path(P1, "base-refresh.rds"))
say("Numbers quoted from phase1/ now describe REMIND ", vNew[[1]], " - re-read them from the artifacts (CLAUDE.md).")
