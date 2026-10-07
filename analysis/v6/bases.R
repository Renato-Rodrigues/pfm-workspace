# The energy systems the offline v6 analyses read, in one place (PITFALLS.md 34).
#   source("analysis/v6/bases.R")   # from the repo root, after pfm is loaded
#
# The bases are the config.yml scenario registry's SSP2 pair: the gating entry (PkBudg1000) and the
# other one (NPi). Nothing in analysis/v6 names a run folder any more: re-point the registry
# (analysis/v6/refreshBases.R does it) and every script follows.
#
# The scenario panels phase1.R caches as output/pfm/<group>/phase1/scen-<role>.rds carry the gdx they
# were built from (attribute "gdx"). v6ScenPanel() refuses a panel built from another gdx than the
# registry's, so a stale cache can no longer stand in for the new bases silently.
`%||%` <- function(a, b) if (is.null(a)) b else a

v6Bases <- function(rc) {
  sc <- rc$scenarios
  if (!length(sc)) stop("config.yml has no scenarios: registry")
  ssp2 <- vapply(sc, function(s) identical(s$ssp %||% "SSP2", "SSP2"), NA)
  gate <- vapply(sc, function(s) isTRUE(s$gating), NA)
  pk <- sc[ssp2 & gate]; npi <- sc[ssp2 & !gate]
  if (length(pk) != 1 || length(npi) != 1) {
    stop("the registry must hold exactly one SSP2 gating entry (PkBudg1000) and one other SSP2 entry (NPi); has ",
         length(pk), " and ", length(npi))
  }
  out <- c(NPi = npi[[1]]$gdx, PkBudg1000 = pk[[1]]$gdx)
  miss <- out[!file.exists(out)]
  if (length(miss)) stop("registry gdx not found: ", paste(miss, collapse = ", "))
  out
}

# The v5 coupled runs phase1.R also reads (k on a coupled energy system), when present on this machine.
v5CoupledRuns <- function(dir = "output/remind-runs/v5/EU21") {
  runs <- c(PFMgate = "SSP2-EU21-PkBudg1000-PFMgate_2026-09-16_08.42.11",
            PFMlevelBfix = "SSP2-EU21-PkBudg1000-PFMlevelBfix_2026-09-17_14.34.22",
            PFMlevelC = "SSP2-EU21-PkBudg1000-PFMlevelC_2026-09-22_16.25.32")
  g <- file.path(dir, runs, "fulldata.gdx"); names(g) <- names(runs)
  g[file.exists(g)]
}

# REMIND's version as the gdx records it (the set c_model_version), e.g. "3-7-1".
remindVersion <- function(gdx) {
  tryCatch({ g <- gamstransfer::Container$new(); g$read(gdx, "c_model_version")
             as.character(g["c_model_version"]$records[[1]][1]) }, error = function(e) NA_character_)
}

# A cached scenario panel, checked against the gdx it must have been built from.
v6ScenPanel <- function(P1, role, gdx) {
  f <- file.path(P1, paste0("scen-", role, ".rds"))
  if (!file.exists(f)) stop(f, " missing - run analysis/v6/phase1.R first")
  s <- readRDS(f)
  built <- attr(s, "gdx") %||% "<unstamped: built before 2026-10-07>"
  if (!identical(normalizePath(built, winslash = "/", mustWork = FALSE), normalizePath(gdx, winslash = "/", mustWork = FALSE))) {
    stop(f, " was built from ", built, ", not from ", gdx, " - re-run analysis/v6/phase1.R (PITFALLS.md 34)")
  }
  s
}
