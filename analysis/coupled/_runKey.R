# The run's internal key from its title. From v8 on, coupled run titles carry the labels the paper uses
# (scenario-matrix-v8.yml; docs/SCENARIOS.md 2.6): -PFM-holdPrice / -PFM-holdBudget / -PFM-noPolitics-..., -theta325,
# -constantLimit, -erosion2p7, -shrinkingFuture2040 ... Every script after the extraction keys on the identifiers of
# the earlier batches (-PFMlevelBfix, -PFMlevelC, -PFMgate, Th325, -Ehold, -kappa ...), so the title is translated to
# that key once, here, and the scripts stay the same for every group. Titles of v7 and earlier pass unchanged.
#   source("analysis/coupled/_runKey.R"); pfmRunKey("SSP2-EU21-PkBudg1000-PFM-holdBudget-theta325-v8")
#   -> "SSP2-EU21-PkBudg1000-PFMlevelCTh325-v8"
pfmRunKey <- function(title) {
  # closure and reference (the longest first: noPolitics-holdPrice before holdPrice)
  rules <- c("-PFM-noPolitics-holdBudget" = "-PFMgate", "-PFM-noPolitics-holdPrice" = "-PFMgateBfix",
             "-PFM-holdPrice" = "-PFMlevelBfix", "-PFM-holdBudget" = "-PFMlevelC")
  # one word per variant, in the order of SCENARIOS.md 2.6
  variants <- c(commonStrength = "common", gapFirst = "gapfirst", rentsWorldPrice = "rentsWorld",
                constantLimit = "Ehold", growingLimit = "backslide", erosion2p7 = "kappa", erosion2 = "kappa02",
                erosion5 = "kappa05", erosionHistorical = "kappaHist", institutionsHeld = "held",
                institutionsAndrijevic = "gcA", institutionsStoryline = "story")
  out <- title
  for (k in names(rules)) out <- sub(k, rules[[k]], out, fixed = TRUE)
  out <- sub("-theta([0-9]+)", "Th\\1", out)                         # -PFMlevelC-theta325 -> -PFMlevelCTh325
  out <- sub("-markupOff", "Min", out, fixed = TRUE)
  for (k in names(variants)) out <- sub(paste0("-", k, "(-|$)"), paste0("-", variants[[k]], "\\1"), out)
  out <- sub("-shrinkingFuture([0-9]{4})", "-seq\\1", out)
  out
}
