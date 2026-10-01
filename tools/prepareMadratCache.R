# Prepare the project madrat cache by hand - the same pfm::pfmPrepareCache() that
# tools/setup.sh and every pfmRun() call. Run from the repository root.
#
#   Rscript tools/prepareMadratCache.R                  # the config's Run-Group
#   Rscript tools/prepareMadratCache.R --group v6       # another group's cache
#   Rscript tools/prepareMadratCache.R --check          # compute nothing; say what is missing
#   Rscript tools/prepareMadratCache.R --force          # re-run the builders even if complete
#   Rscript tools/prepareMadratCache.R --md5            # quick check by md5, not size
#
# Everything else - where the cache is, which caches to copy from, where the raw sources are -
# is config.yml `madrat:`. See ADR 0047, docs/RUNNING.md step 2 and ?pfm::pfmPrepareCache.

args <- commandArgs(TRUE)
opt <- function(k) { i <- match(k, args); if (is.na(i) || i == length(args)) NULL else args[i + 1] }
if (!file.exists("config.yml")) stop("run from the repository root (no config.yml here)")

r <- pfm::pfmPrepareCache("config.yml", group = opt("--group"),
                          compute = if ("--check" %in% args) FALSE else NULL,
                          force = "--force" %in% args,
                          verify = if ("--md5" %in% args) "md5" else "size")
if (identical(r$status, "incomplete")) quit(status = 1)
