# v8 smoke test (design note 0009 section 16): the whole pipeline of Run-Group v8 on a handful of specifications, locally,
# before the cluster sweep. Every stage runs through pfmRun exactly as on the cluster (config.yml group v8: panel with the
# fossil rents, fossil bound, rents slack in B&T, coverage median, theory and edge gates), into scratch folders, so
# output/pfm/v8 and output/remind-inputs/v8 stay empty. The fits go to the Fit Cache as usual (harmless: the cluster finds
# them there only if it shares the store, which it does not).
#   Rscript analysis/v8/smokeTestV8.R [nBases]   (repo root; default 6) -> <scratch>/pfm-smoke-v8/
# The specifications: the base (linear, unweighted) form of v7's selected spec and of the bases of v7's best-ranked
# passing specs; pfmSpecs expands each with v8's axes as the full sweep would.
# Needs data/madrat/v8: seeded from data/madrat/v7, the rents computed by pfmRun's cache preparation from the
# workstation source (WDIRents/wdi-fossil-rents.csv).
source("analysis/_common/_loadPfm.R")
args <- commandArgs(trailingOnly = TRUE); nB <- if (length(args)) as.integer(args[1]) else 6L
SCR <- file.path(Sys.getenv("PFM_SMOKE_DIR", tempdir()), "pfm-smoke-v8")
dir.create(file.path(SCR, "pfm"), recursive = TRUE, showWarnings = FALSE); dir.create(file.path(SCR, "remind-inputs"), showWarnings = FALSE)
if (!dir.exists("data/madrat/v8")) { dir.create("data/madrat/v8", recursive = TRUE)
  invisible(file.copy(list.files("data/madrat/v7", full.names = TRUE), "data/madrat/v8")); message("[smoke] data/madrat/v8 seeded from v7") }

sw <- readRDS("output/pfm/v7/sweep.rds"); mm <- sw$maximin$PolicyStringency
baseOf <- function(n) sub("( iw:[^ ]+)$", "", sub(" (satAP|satInn|satInc)( iw:[^ ]+)?$", "", n))
pass <- mm$model[mm$gatePass]
bases <- unique(c(baseOf(sw$sanity$PolicyStringency$chosen %||% pass[1]), baseOf(pass)))[seq_len(nB)]
specs <- Filter(function(s) s$name %in% bases, sw$specs)
specs <- lapply(specs, function(s) { s$apTransform <- "linear"; s$interactionWeight <- NULL; s })
message("[smoke] ", length(specs), " base specs: ", paste(vapply(specs, `[[`, "", "name"), collapse = " | "))

t0 <- Sys.time()
res <- pfmRun(group = "v8", stage = c("sweep", "diagnostics", "downstream", "remind"), cluster = "local", config = "config.yml",
              resultsDir = file.path(SCR, "pfm"), remindDir = file.path(SCR, "remind-inputs"), specs = specs, ask = FALSE)
message("[smoke] pfmRun finished in ", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " min")

GD <- file.path(SCR, "pfm", "v8")
chk <- function(what, ok, detail = "") message(sprintf("[smoke] %-62s %s %s", what, if (isTRUE(ok)) "ok" else "FAIL", detail))
man <- tryCatch(jsonlite::read_json(file.path(GD, "manifest.json")), error = function(e) NULL)
chk("manifest: panel fossilRents", isTRUE(man$panel$fossilRents))
chk("manifest: sweep fossilFloors 0.05", identical(unlist(man$sweepOptions$fossilFloors), "0.05"))
chk("manifest: sweep slackDrivers Diffuse = Fossil Rents", identical(unlist(man$sweepOptions$slackDrivers$Diffuse), "Fossil Rents"))
sel <- tryCatch(yaml::read_yaml(pfm:::.pfmSelectedModels(GD)), error = function(e) NULL)
chk("selection written", !is.null(sel), if (!is.null(sel)) sel[[1]]$name else "")
if (!is.null(sel)) {
  chk("selected spec carries the fossil bound", isTRUE(all.equal(as.numeric(sel[[1]]$fossilFloor), 0.05)))
  chk("selected spec carries the slack drivers", identical(unlist(sel[[1]]$slackDrivers$Diffuse), "Fossil Rents"))
}
fr <- tryCatch(readRDS(file.path(GD, "frontier.rds")), error = function(e) NULL)
if (!is.null(fr)) {
  ctD <- fr$bySector$Diffuse$coefTable; ctB <- fr$bySector$Bulk$coefTable
  chk("frontier B&T has the rents slack term", "slack_Fossil.Rents" %in% ctD$term,
      if ("slack_Fossil.Rents" %in% ctD$term) sprintf("w = %.3f (z %.1f)", ctD$estimate[ctD$term == "slack_Fossil.Rents"], ctD$zValue[ctD$term == "slack_Fossil.Rents"]) else "")
  chk("frontier P&I has no slack term", !any(startsWith(ctB$term, "slack_")))
  chk("frontier driver scaling carries the fossil floor", any(vapply(fr$bySector$Bulk$driverScaling, function(s) "floor" %in% names(s), logical(1))))
} else chk("frontier.rds written", FALSE)
asg <- tryCatch(readRDS(file.path(GD, "donor-assignment-band-Bulk.rds")), error = function(e) NULL)
chk("coverage rule: every uncovered country at the median (USA as set)", !is.null(asg) && all(asg$basis[asg$region != "USA"] == "median"),
    if (!is.null(asg)) paste(names(table(asg$basis)), table(asg$basis), collapse = " ") else "")
anc <- list.files(file.path(SCR, "remind-inputs", "v8"), recursive = TRUE)
chk("REMIND export written", length(anc) > 0, paste(length(anc), "files"))
a <- tryCatch(pfm:::pfmAnchorFor(file.path(SCR, "remind-inputs", "v8"), "EU21"), error = function(e) NULL)
chk("anchor: B&T design carries the slack, slack shift at the anchor", !is.null(a$designs$Diffuse$slack) && any(is.finite(a$country$slackShiftAnchor[a$country$sector == "Diffuse"])))
message("[smoke] scratch results: ", SCR)
