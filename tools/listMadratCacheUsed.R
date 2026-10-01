# List the madrat cache files a set of runs actually read, as a manifest a later workspace can
# be rebuilt from.
#
#   Rscript tools/listMadratCacheUsed.R <log-or-run-folder> [...] --out <manifest.tsv> [--cachefolder <dir>]
#
#   Rscript tools/listMadratCacheUsed.R output/remind-runs/v5/EU21/* output/remind-runs/v5/H12/* \
#       --out records/v5/madrat-cache-used-runs.tsv
#   Rscript tools/listMadratCacheUsed.R output/pfm/v6/pfm-v6-*.out --out records/v6/madrat-cache-used-pfm.tsv --cachefolder data/madrat/v6
#
# records/<group>/ is tracked in git (records/README.md). A madrat-cache-used-pfm.tsv there is the
# group's PIN: pfm::pfmPrepareCache() rebuilds the cache from exactly those files.
#
# Inputs: REMIND run folders (their log.txt carries the R output of every PFM coupling call) and/or
# any log file of a pfmRun / Rscript session (e.g. the SLURM pfm-<group>-<job>.out files).
# madrat prints "loading cache <file>" for every cached calculation it reads, and
# "cachefolder = <dir>" when it starts; both are collected.
#
# WHY THIS EXISTS. Under forcecache, madrat accepts any cache file whose arguments match, whatever
# its code fingerprint, and among several it takes the one with the newest file modification time
# (madrat:::cacheNames). Which version of the energy, GDP or institution data a run used is
# therefore decided by what sat in the cache folder, and by copy timestamps - not by the code.
# Found 2026-10-01: the v5 coupled runs read /p/projects/rd3mod/inputdata/cache (calcFE-F0d73e4e2,
# calcPE-F6699a843, ...), versions that exist nowhere in the project cache, and a local refit with
# other FE/PE versions moved a regional share by 0.14. Without this list a run cannot be
# reproduced.
#
# Output columns: file, timesRead, cachefolder (as the logs report it), and with --cachefolder the
# size and md5 of each file found there (empty when the file is not in that folder).
# prepareMadratCache.R --manifest <tsv> copies exactly these files into a workspace cache.

args <- commandArgs(TRUE)
take <- function(k) { i <- match(k, args); if (is.na(i)) return(NA_character_); v <- args[i + 1]; args <<- args[-c(i, i + 1)]; v }
out <- take("--out"); cf <- take("--cachefolder")
if (is.na(out)) stop("--out <manifest.tsv> is required")
inputs <- args
if (!length(inputs)) stop("give at least one log file or REMIND run folder")

logs <- unlist(lapply(inputs, function(x) {
  if (dir.exists(x)) { l <- file.path(x, "log.txt"); if (file.exists(l)) l else character(0) } else if (file.exists(x)) x else character(0)
}))
if (!length(logs)) stop("no log files found among the inputs")

hits <- character(0); folders <- character(0)
for (l in logs) {
  txt <- readLines(l, warn = FALSE, encoding = "UTF-8")
  m <- regmatches(txt, regexpr("loading cache [A-Za-z0-9_.-]+[.]rds", txt))
  hits <- c(hits, sub("^loading cache ", "", m))
  f <- regmatches(txt, regexpr("cachefolder = [^ ]+", txt))
  folders <- c(folders, sub("^cachefolder = ", "", f))
}
if (!length(hits)) stop("no 'loading cache' lines in ", length(logs), " log(s) - was madrat's verbosity reduced?")
tab <- as.data.frame(table(file = hits), stringsAsFactors = FALSE)
names(tab)[2] <- "timesRead"
tab$cachefolder <- paste(unique(folders), collapse = " | ")
if (!is.na(cf)) {
  p <- file.path(cf, tab$file)
  tab$size <- ifelse(file.exists(p), file.size(p), NA)
  tab$md5 <- ifelse(file.exists(p), unname(tools::md5sum(p)), "")
}
tab <- tab[order(tab$file), ]
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
utils::write.table(tab, out, sep = "\t", row.names = FALSE, quote = FALSE)
cat(sprintf("[cache-used] %d distinct cache files read across %d log(s); cachefolder(s): %s\n[cache-used] wrote %s\n",
            nrow(tab), length(logs), paste(unique(folders), collapse = ", "), out))
if (!is.na(cf)) cat(sprintf("[cache-used] %d of them present in %s\n", sum(!is.na(tab$size)), cf))
