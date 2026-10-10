# List the REMIND input-data archives a set of runs used, as a record next to the madrat cache lists.
#
#   Rscript tools/listRemindInputsUsed.R <run-folder> [...] --out <records/<group>/remind-inputs-used-runs.tsv>
#   Rscript tools/listRemindInputsUsed.R output/remind-runs/v6/*/* --out records/v6/remind-inputs-used-runs.tsv
#
# A REMIND run reads its input data from archives (rev<x>_<regionscode>_remind.tgz, the validation
# archive, CESparametersAndGDX_<hash>.tgz) fetched from cfg$repositories, typically the shared PIK
# folders /p/projects/rd3mod/inputdata/output and /p/projects/remind/inputdata/CESparametersAndGDX.
# Those folders are cleaned from time to time; without the archives a run cannot be repeated.
# Read from each run's config.Rdata (cfg$input, cfg$repositories). Output columns: file, timesRead,
# repositories (the run's, ';'-separated). tools/archiveRunGroupInputs.sh copies the files.
args <- commandArgs(TRUE)
i <- match("--out", args); if (is.na(i)) stop("--out <tsv> is required")
out <- args[i + 1]; runs <- args[-c(i, i + 1)]
runs <- runs[dir.exists(runs) & file.exists(file.path(runs, "config.Rdata"))]
if (!length(runs)) stop("no run folder with a config.Rdata among the arguments")
rows <- do.call(rbind, lapply(runs, function(r) {
  e <- new.env(); load(file.path(r, "config.Rdata"), envir = e); cfg <- e$cfg
  if (!length(cfg$input)) return(NULL)
  data.frame(file = unname(cfg$input), repositories = paste(names(cfg$repositories), collapse = ";"))
}))
tab <- stats::aggregate(list(timesRead = rep(1L, nrow(rows))), rows["file"], sum)
tab$repositories <- rows$repositories[match(tab$file, rows$file)]
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
utils::write.table(tab, out, sep = "\t", quote = FALSE, row.names = FALSE)
message("[inputs-used] ", nrow(tab), " input archive(s) across ", length(runs), " run(s); wrote ", out)
