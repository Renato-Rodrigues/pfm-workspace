# Write a minimal example of the PFM's gdx interface from one finished coupled run: the input a host must write
# (the symbols of the GMD paper's Table M2, read from the run's fulldata.gdx and the reference run's), with a CSV of
# the set elements the reader uses, next to the output the replay of that run's last call wrote
# (tools/replayCouplingCall.R --keep <dir>). GAMS writes the gdx, so domains, set order and fields are exactly REMIND's.
#
#   Rscript tools/exampleCouplingFiles.R <run-folder> <reference-run-folder> <dir>
#
# <dir> is the --keep folder of the replay (it already holds p45_regiDiff_phi.gdx). Written there:
#   pfm-example-input.gdx      vm_prodPe, vm_prodSe, vm_demFeSector, vm_demFeSector_afterTax, vm_fuExtr, pm_PEPrice,
#                              vm_costFuEx, vm_cesIO, pm_pvp, p45_taxCO2eq_anchor and the sets they are declared over
#   pfm-example-reference.gdx  pm_taxCO2eq of the reference (current-policy) run
#   csv/<symbol>.csv           the records the reader selects (input) and the shares written back (output)
# Added 2026-11-25 (gap plan GP-52 of the GMD paper).
args <- commandArgs(TRUE)
if (length(args) < 3) stop("usage: exampleCouplingFiles.R <run-folder> <reference-run-folder> <dir>")
run <- normalizePath(args[1], mustWork = TRUE); refRun <- normalizePath(args[2], mustWork = TRUE)
dir <- normalizePath(args[3], mustWork = TRUE)
gams <- local({
  cand <- unlist(strsplit(Sys.getenv("GAMSDIR", ""), "[;:]"))
  cand <- c(file.path(cand[nzchar(cand)], "gams.exe"), Sys.which("gams"), "C:/Program Files/GAMS/51/gams.exe")
  cand <- cand[nzchar(cand) & file.exists(cand)]; if (!length(cand)) stop("gams not found; set GAMSDIR"); cand[1]
})
SETS <- c("ttot", "tall", "all_regi", "all_enty", "all_te", "emi_sectors", "all_emiMkt", "rlf", "all_in")
VARS <- c(vm_prodPe = "ttot,all_regi,all_enty", vm_prodSe = "tall,all_regi,all_enty,all_enty,all_te",
          vm_demFeSector = "ttot,all_regi,all_enty,all_enty,emi_sectors,all_emiMkt",
          vm_demFeSector_afterTax = "ttot,all_regi,all_enty,all_enty,emi_sectors,all_emiMkt",
          vm_fuExtr = "ttot,all_regi,all_enty,rlf", vm_costFuEx = "ttot,all_regi,all_enty", vm_cesIO = "tall,all_regi,all_in")
PARS <- c(pm_PEPrice = "ttot,all_regi,all_enty", pm_pvp = "ttot,all_enty", p45_taxCO2eq_anchor = "ttot")
work <- file.path(tempdir(), "pfm-example"); unlink(work, recursive = TRUE); dir.create(work)
file.copy(file.path(run, "fulldata.gdx"), file.path(work, "run.gdx"))
file.copy(file.path(refRun, "fulldata.gdx"), file.path(work, "ref.gdx"))
gms <- c(paste0("Sets ", paste(SETS, collapse = ", "), ";"),
         "$gdxin run.gdx", paste0("$load ", paste(SETS, collapse = " ")),
         paste0("Variables ", paste0(names(VARS), "(", VARS, ")", collapse = ", "), ";"),
         paste0("Parameters ", paste0(names(PARS), "(", PARS, ")", collapse = ", "), ", pm_taxCO2eq(ttot,all_regi);"),
         paste0("$load ", paste(c(names(VARS), names(PARS)), collapse = " ")), "$gdxin",
         "$gdxin ref.gdx", "$load pm_taxCO2eq", "$gdxin",
         paste0("execute_unload 'pfm-example-input.gdx', ", paste(c(SETS, names(VARS), names(PARS)), collapse = ", "), ";"),
         "execute_unload 'pfm-example-reference.gdx', ttot, all_regi, pm_taxCO2eq;")
writeLines(gms, file.path(work, "example.gms"))
owd <- setwd(work); st <- system2(gams, c("example.gms", "lo=2")); setwd(owd)
if (st != 0 || !file.exists(file.path(work, "pfm-example-input.gdx"))) stop("GAMS failed; see ", file.path(work, "example.lst"))
file.copy(file.path(work, c("pfm-example-input.gdx", "pfm-example-reference.gdx")), dir, overwrite = TRUE)

# --- CSVs of what the reader selects, and of the shares written back -------------------------------------------
suppressMessages(library(gdx))
csv <- file.path(dir, "csv"); dir.create(csv, showWarnings = FALSE)
YEARS <- c(seq(2005, 2060, 5), seq(2070, 2110, 10), 2130, 2150)
keep <- list(vm_prodPe = c("pecoal", "peoil", "pegas", "pewin", "pesol", "peur", "pehyd", "pegeo"),
             vm_prodSe = c("windon", "windoff", "spv", "csp", "seel"),
             vm_demFeSector = c("indst", "seel"), vm_demFeSector_afterTax = c("trans"),
             vm_fuExtr = c("pecoal", "peoil", "pegas"), pm_PEPrice = c("pecoal", "peoil", "pegas"),
             vm_costFuEx = c("pecoal", "peoil", "pegas"), vm_cesIO = "inco")
inp <- file.path(dir, "pfm-example-input.gdx")
for (s in names(keep)) {
  x <- if (startsWith(s, "vm_")) readGDX(inp, s, field = "l", restore_zeros = FALSE) else readGDX(inp, s, restore_zeros = FALSE)
  d <- as.data.frame(x, rev = 3)
  ycol <- intersect(c("ttot", "tall"), names(d))[1]; if (is.na(ycol)) stop(s, ": no year column in ", paste(names(d), collapse = ", "))
  d <- d[as.integer(as.character(d[[ycol]])) %in% YEARS, ]
  sel <- Reduce(`|`, lapply(setdiff(names(d), c(ycol, "all_regi", ".value")), function(n) as.character(d[[n]]) %in% keep[[s]]))
  d <- d[sel, ]
  utils::write.csv(d, file.path(csv, paste0(s, ".csv")), row.names = FALSE)
}
for (s in c("p45_taxCO2eq_anchor")) utils::write.csv(as.data.frame(readGDX(inp, s), rev = 3), file.path(csv, paste0(s, ".csv")), row.names = FALSE)
utils::write.csv(as.data.frame(readGDX(file.path(dir, "pfm-example-reference.gdx"), "pm_taxCO2eq"), rev = 3),
                 file.path(csv, "pm_taxCO2eq_reference.csv"), row.names = FALSE)
out <- file.path(dir, "p45_regiDiff_phi.gdx")
if (file.exists(out)) for (s in c("p45_pfmPhiPath", "p45_pfmPhiMktPath", "p45_regiDiff_phi", "p45_pfmPhiMkt", "p45_pfmPriceBound", "p45_pfmPriceBoundMkt")) {
  x <- tryCatch(readGDX(out, s, react = "silent"), error = function(e) NULL)
  if (!is.null(x)) utils::write.csv(as.data.frame(x, rev = 3), file.path(csv, paste0("output_", s, ".csv")), row.names = FALSE)
}
cat("[example] written to", dir, ":", paste(list.files(dir, recursive = TRUE), collapse = ", "), "\n")
