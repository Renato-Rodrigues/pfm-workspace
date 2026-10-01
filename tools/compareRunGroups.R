# Compare the artifacts of two Run-Groups: did a re-run reproduce a reference?
#
#   Rscript tools/compareRunGroups.R <group> <reference-group> [results-root] [tolerance] [relative-tolerance]
#   Rscript tools/compareRunGroups.R v5-repro v5
#   Rscript tools/compareRunGroups.R v5-repro v5 output/pfm 1e-6
#
#   [results-root]   default output/pfm. A reference elsewhere can be given as an absolute folder:
#                    <group> and <reference-group> may be paths instead of names.
#   [tolerance]      absolute tolerance (default 1e-6)
#   [relative-tolerance]  relative tolerance (default 1e-4): a number is reproduced when
#                    |a - b| <= tolerance + relative-tolerance * |b|. Prices of hundreds of $/t carry
#                    the optimizer's ~1e-5 relative noise from the frontier fit (2026-10-01 test).
#
# For every file present in BOTH groups (recursively):
#   identical   the bytes are the same;
#   equal       not byte-identical, but every number in the object agrees within the tolerance
#               (an .rds re-saved with a new timestamp or a different element order is still equal);
#   DIFFERENT   numbers differ by more than the tolerance: the largest difference and where it is.
# Files only in one group are listed. Writes <group>/reproduction-check.csv and exits non-zero
# if anything is DIFFERENT.

args <- commandArgs(TRUE)
if (length(args) < 2) stop("usage: compareRunGroups.R <group> <reference-group> [results-root] [tolerance]")
root <- if (length(args) >= 3) args[3] else "output/pfm"
tol <- if (length(args) >= 4) as.numeric(args[4]) else 1e-6
rtol <- if (length(args) >= 5) as.numeric(args[5]) else 1e-4
dirOf <- function(g) if (dir.exists(g)) g else file.path(root, g)
A <- dirOf(args[1]); B <- dirOf(args[2])
for (d in c(A, B)) if (!dir.exists(d)) stop("no such Run-Group folder: ", d)

fa <- list.files(A, recursive = TRUE); fb <- list.files(B, recursive = TRUE)
skip <- "(^|/)(logs?|reproduction-check\\.csv|manifest\\.json|recut-provenance\\.json)$|\\.log$"
common <- setdiff(intersect(fa, fb), grep(skip, fa, value = TRUE))

# every number in an object, keyed by its path in the object
numbers <- function(x, path = "") {
  if (is.data.frame(x)) x <- as.list(x)
  if (is.list(x) || is.environment(x)) {
    if (is.environment(x)) x <- as.list(x)
    nm <- names(x); if (is.null(nm)) nm <- seq_along(x)
    out <- list()
    for (i in seq_along(x)) out <- c(out, numbers(x[[i]], paste0(path, "/", nm[i])))
    return(out)
  }
  if (is.numeric(x) || is.logical(x)) return(stats::setNames(list(as.numeric(x)), path))
  if (methods::is(x, "magpie")) return(stats::setNames(list(as.numeric(x)), path))
  list()
}
readAny <- function(f) {
  switch(tolower(tools::file_ext(f)),
         rds = readRDS(f),
         json = jsonlite::fromJSON(f),
         yml = , yaml = yaml::read_yaml(f),
         csv = utils::read.csv(f, comment.char = "#"),   # the exported CSVs open with # header lines
         NULL)
}

res <- do.call(rbind, lapply(common, function(f) {
  pa <- file.path(A, f); pb <- file.path(B, f)
  if (identical(unname(tools::md5sum(pa)), unname(tools::md5sum(pb)))) {
    return(data.frame(file = f, status = "identical", maxDiff = 0, where = "", stringsAsFactors = FALSE))
  }
  xa <- tryCatch(readAny(pa), error = function(e) NULL); xb <- tryCatch(readAny(pb), error = function(e) NULL)
  if (is.null(xa) || is.null(xb)) {
    return(data.frame(file = f, status = "differs (not comparable)", maxDiff = NA, where = "", stringsAsFactors = FALSE))
  }
  na <- numbers(xa); nb <- numbers(xb)
  keys <- intersect(names(na), names(nb))
  worst <- 0; where <- ""; excess <- -Inf
  for (k in keys) {
    a <- na[[k]]; b <- nb[[k]]
    if (length(a) != length(b)) { worst <- Inf; where <- paste0(k, " (length ", length(a), " vs ", length(b), ")"); break }
    d <- suppressWarnings(max(abs(a - b), na.rm = TRUE))
    e <- suppressWarnings(max(abs(a - b) - tol - rtol * abs(b), na.rm = TRUE))
    if (any(is.na(a) != is.na(b))) { d <- Inf; e <- Inf }
    if (is.finite(e) && e > excess || !is.finite(e)) excess <- e
    if (is.finite(d) && d > worst || !is.finite(d)) { worst <- d; where <- k }
  }
  miss <- length(setdiff(union(names(na), names(nb)), keys))
  st <- if ((worst <= tol || excess <= 0) && miss == 0) "equal" else "DIFFERENT"
  if (miss > 0) where <- paste0(where, if (nzchar(where)) "; ", miss, " number paths only in one object")
  data.frame(file = f, status = st, maxDiff = worst, where = where, stringsAsFactors = FALSE)
}))
only <- c(paste0("only in ", basename(A), ": ", setdiff(fa, fb)), paste0("only in ", basename(B), ": ", setdiff(fb, fa)))
only <- only[!grepl(": $", only)]

write.csv(res, file.path(A, "reproduction-check.csv"), row.names = FALSE)
cat(sprintf("[compare] %s vs %s: %d common files - %d identical, %d equal (|diff| <= %g + %g*|ref|), %d DIFFERENT\n",
            A, B, nrow(res), sum(res$status == "identical"), sum(res$status == "equal"), tol, rtol,
            sum(res$status != "identical" & res$status != "equal")))
bad <- res[!res$status %in% c("identical", "equal"), ]
if (nrow(bad)) print(bad, row.names = FALSE)
if (length(only)) cat(paste0("  ", utils::head(only, 30)), sep = "\n")
cat("[compare] details:", file.path(A, "reproduction-check.csv"), "\n")
quit(status = if (nrow(bad)) 1 else 0)
