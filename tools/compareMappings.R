# Compare the region mappings the PFM resolves with the ones REMIND solves on (PITFALLS section 1).
#
#   Rscript tools/compareMappings.R [REMIND config folder]     # default models/remind_pfm/config
#
# For regionmappingH12.csv and regionmapping_21_EU11.csv: mrpfm's bundled copy, the madrat
# mappingfolder copy (what toolPFMMapping() reads first) and the REMIND checkout's config/ copy
# (what REMIND defines its regions with). Prints countries present in only one, and every country
# assigned to a different region.
args <- commandArgs(TRUE)
remindCfg <- if (length(args)) args[1] else "models/remind_pfm/config"
suppressMessages(library(mrpfm))
rd <- function(p) utils::read.csv(p, sep = ";", stringsAsFactors = FALSE)
k <- function(m) stats::setNames(m$RegionCode, m$CountryCode)
cmpMaps <- function(a, b, la, lb) {
  a <- k(a); b <- k(b)
  com <- intersect(names(a), names(b))
  d <- com[a[com] != b[com]]
  cat(sprintf("   %s vs %s: %d vs %d countries | only in %s %d | only in %s %d | reassigned %d%s\n",
              la, lb, length(a), length(b), la, length(setdiff(names(a), names(b))), lb,
              length(setdiff(names(b), names(a))), length(d),
              if (length(d)) paste0(": ", paste(d, a[d], "->", b[d], collapse = ", ")) else ""))
}
for (f in c("regionmappingH12.csv", "regionmapping_21_EU11.csv")) {
  own <- rd(system.file("extdata", "regional", f, package = "mrpfm"))
  mf <- file.path(madrat::getConfig("mappingfolder", verbose = FALSE), "regional", f)
  rem <- file.path(remindCfg, f)
  cat("\n==", f, "\n   mappingfolder copy:", mf, if (file.exists(mf)) "" else "(absent)", "\n")
  if (file.exists(mf)) cmpMaps(own, rd(mf), "mrpfm", "mappingfolder")
  if (file.exists(rem)) cmpMaps(own, rd(rem), "mrpfm", "REMIND")
  if (file.exists(mf) && file.exists(rem)) cmpMaps(rd(mf), rd(rem), "mappingfolder", "REMIND")
}
