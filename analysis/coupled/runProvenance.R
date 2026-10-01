# Which fork commit, and which uncommitted files, each coupled run was built from.
#
#   Rscript analysis/coupled/runProvenance.R v5 output/remind-runs/v5
#
# REMIND writes "Latest commit: <hash> ..." and the `git status` of its working tree into every run's
# log.txt at submission. This reads both for every run in output/remind-runs/v5/{EU21,H12}/ so the Code availability
# statement can say exactly what each run was built from (referee v09, M4).
#
# One of the two files that appear as modified, core/sets.gms, is REWRITTEN BY REMIND ITSELF at every
# start (scripts/start/prepare.R, updateSets.R: region-dependent sets and the module list), so its
# appearing as modified is a property of how REMIND starts, not a change to the model. The other,
# config/scenario_config_PFM.csv, is the file that defines the runs.

args <- commandArgs(trailingOnly = TRUE)
group <- if (length(args) >= 1) args[1] else "v5"
gdxDir <- if (length(args) >= 2) args[2] else "output/remind-runs/v5"

dirs <- unlist(lapply(file.path(gdxDir, c("EU21", "H12")), list.dirs, recursive = FALSE, full.names = TRUE))
dirs <- dirs[file.exists(file.path(dirs, "log.txt"))]
rows <- lapply(dirs, function(d) {
  lg <- readLines(file.path(d, "log.txt"), warn = FALSE)
  cm <- grep("^Latest commit:", lg, value = TRUE)[1]
  hash <- if (is.na(cm)) NA_character_ else strsplit(sub("^Latest commit:\\s*", "", cm), "\\s+")[[1]][1]
  i <- grep("Changes not staged for commit", lg)[1]
  mod <- character(0)
  if (!is.na(i)) {
    blk <- lg[i:min(length(lg), i + 20)]
    mod <- sub("^\\s*modified:\\s*", "", grep("^\\s*modified:", blk, value = TRUE))
    mod <- sub("^(\\.\\./)+", "", trimws(mod))
  }
  data.frame(resolution = basename(dirname(d)), run = basename(d),
             scenario = sub("_\\d{4}-\\d{2}-\\d{2}_.*$", "", basename(d)), commit = hash,
             modified = paste(sort(unique(mod)), collapse = ";"), stringsAsFactors = FALSE)
})
p <- do.call(rbind, rows)
f <- file.path("output/pfm", group, "coupling", "run-provenance.rds")
saveRDS(list(runs = p, generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
             note = "core/sets.gms is rewritten by REMIND's start scripts at every run"), f)
print(table(p$commit, p$modified))
cat("wrote", f, ":", nrow(p), "run folders\n")
