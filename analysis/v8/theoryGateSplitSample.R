# Split-sample replication of the theory gate (design note 0010 section 9, T1; the model paper's gap plan GP-3).
#   Rscript analysis/v8/theoryGateSplitSample.R [group] fit <i> <n>     worker i of n: fits its share of the pool
#   Rscript analysis/v8/theoryGateSplitSample.R [group] summarise       -> output/pfm/<group>/theory-gate-split-sample.rds
#   (repo root; default group v8; PFM_SPLIT_LIMIT=<k> fits only the first k specifications of the worker's share, for timing)
# How much of H1-H2 is produced by selecting on them? The pool is the specifications that pass every gate before the
# theory gate (as theoryGateFunnel.R). For each, in each sector, the mean regression the gate reads (the satP design,
# least squares on the logit response, country-clustered CR1, normal p, as interactionBlockTest.R) is fitted on two
# random halves of the countries, 200 splits (the same splits for every specification, seed below). The design of
# each specification is prepared ONCE on the full sample (driver scaling, saturation, trend), as in a projection:
# the halves share that scaling, so the replication is of the coefficients, not of the preprocessing.
#   H1  the fossil term (the share, else the per-person form) negative with p < 0.05
#   H2  some fossil x institution term with p < 0.05 / k (k = the number of such terms kept in the fit)
# Workers write chunks to output/pfm/<group>/split-sample-chunks/; a worker skips the specifications already there.
# Nothing in the package, the fit cache or the Run-Group changes.
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args) && !args[1] %in% c("fit", "summarise")) args[1] else "v8"
mode <- intersect(args, c("fit", "summarise"))[1]; if (is.na(mode)) stop("mode: fit <i> <n> | summarise")
GD <- file.path("output/pfm", g); CH <- file.path(GD, "split-sample-chunks"); dir.create(CH, showWarnings = FALSE)
say <- function(...) message(format(Sys.time(), "%H:%M:%S"), " [split-sample:", g, "] ", ...)
NSPLIT <- 200L; SEED <- 20261113L; ALPHA <- 0.05; SECTORS <- c(Bulk = "P&I", Diffuse = "B&T")

sw <- readRDS(file.path(GD, "sweep.rds")); m <- sw$maximin$PolicyStringency
why <- m$gateFailReason; why[is.na(why)] <- ""
pool <- m$model[!nzchar(why) | startsWith(why, "theory: ")]
passed <- m$model[m$gatePass %in% TRUE]

# least squares with the CR1 cluster covariance; aliased columns (a group level empty in a half) are dropped
ols <- function(X, y, cl) {
  qrX <- qr(X); keep <- qrX$pivot[seq_len(qrX$rank)]; X <- X[, sort(keep), drop = FALSE]
  XtXi <- tryCatch(solve(crossprod(X)), error = function(e) NULL); if (is.null(XtXi)) return(NULL)
  b <- drop(XtXi %*% crossprod(X, y)); e <- drop(y - X %*% b); n <- nrow(X); k <- ncol(X); G <- length(unique(cl))
  sc <- rowsum(X * e, cl); V <- XtXi %*% crossprod(sc) %*% XtXi * (G / (G - 1)) * ((n - 1) / (n - k))
  se <- sqrt(pmax(diag(V), 0)); list(b = b, p = 2 * stats::pnorm(-abs(b / se)))
}
# the gate's reading of one fit: the fossil coefficient, its p, and the Bonferroni-scaled smallest interaction p
readGate <- function(o, fos, ints) {
  if (is.null(o) || !fos %in% names(o$b)) return(c(fossil = NA_real_, pFossil = NA_real_, pH2 = NA_real_))
  k <- intersect(ints, names(o$b))
  c(fossil = o$b[[fos]], pFossil = o$p[[fos]], pH2 = if (length(k)) min(o$p[k]) * length(k) else NA_real_)
}

if (mode == "fit") {
  i <- as.integer(args[which(args == "fit") + 1L]); n <- as.integer(args[which(args == "fit") + 2L])
  source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
  options(pfm.panel = list(firstYear = 2000L, lastYear = 2023L, movingAverage = 5L, ieaVersion = "latest", geothermal = TRUE,
                           democracy = TRUE, overallAccountability = TRUE, fossilRents = TRUE))
  madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g)), forcecache = TRUE, .verbose = FALSE)
  hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
  panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
  specByName <- stats::setNames(sw$specs, vapply(sw$specs, `[[`, character(1), "name"))
  mine <- pool[(seq_along(pool) - 1L) %% n == (i - 1L)]
  lim <- suppressWarnings(as.integer(Sys.getenv("PFM_SPLIT_LIMIT", ""))); if (is.finite(lim)) mine <- utils::head(mine, lim)
  done <- unlist(lapply(list.files(CH, pattern = sprintf("^w%02d-", i), full.names = TRUE), function(f) names(readRDS(f))))
  todo <- setdiff(mine, done); say("worker ", i, "/", n, ": ", length(mine), " specifications, ", length(todo), " to fit")
  splits <- NULL; buf <- list(); part <- length(list.files(CH, pattern = sprintf("^w%02d-", i)))
  flush <- function() { if (!length(buf)) return(invisible()); part <<- part + 1L
    saveRDS(buf, file.path(CH, sprintf("w%02d-%04d.rds", i, part))); buf <<- list() }
  t0 <- Sys.time()
  for (j in seq_along(todo)) {
    nm <- todo[j]; res <- list()
    for (sec in names(SECTORS)) {
      r <- tryCatch({
        fit <- do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "satP", indexMax = 10,
                                                             modelDir = NULL, verbose = FALSE), pfm:::.pfmSpecArgs(specByName[[nm]])))
        mf <- stats::model.frame(fit$formula, fit$data); y <- stats::model.response(mf); X <- stats::model.matrix(fit$formula, mf)
        cl <- as.character(fit$data$region)[match(rownames(mf), rownames(fit$data))]
        fos <- pfm:::.pfmFossilTerm(colnames(X))
        ints <- colnames(X)[startsWith(colnames(X), "Incumbent.Power_x_") | startsWith(colnames(X), "Incumbent.Power.pc_x_")]
        cc <- sort(unique(cl))
        # the splits: the same for every specification with the same countries (the 48 of the panel)
        if (is.null(splits) || !identical(attr(splits, "cc"), cc)) { set.seed(SEED)
          splits <- replicate(NSPLIT, sample(cc, floor(length(cc) / 2)), simplify = FALSE); attr(splits, "cc") <- cc }
        full <- readGate(ols(X, y, cl), fos, ints)
        ref <- sw$coefficients[sw$coefficients$model == nm & sw$coefficients$sector == sec, ]
        dev <- abs(full[["fossil"]] - ref$estimate[match(fos, ref$term)])     # the check: the sweep's coefficient
        half <- vapply(splits, function(a) { ia <- cl %in% a
          c(readGate(ols(X[ia, , drop = FALSE], y[ia], cl[ia]), fos, ints), readGate(ols(X[!ia, , drop = FALSE], y[!ia], cl[!ia]), fos, ints)) },
          numeric(6))
        list(fossilTerm = fos, nInt = length(ints), full = full, dev = dev, half = half)
      }, error = function(e) list(error = conditionMessage(e)))
      res[[sec]] <- r
    }
    buf[[nm]] <- res
    if (j %% 25 == 0 || j == length(todo)) { flush()
      say("worker ", i, ": ", j, "/", length(todo), " (", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " min)") }
  }
  say("worker ", i, " done"); quit(status = 0)
}

# ---- summarise -------------------------------------------------------------------------------------------------------
res <- do.call(c, lapply(list.files(CH, full.names = TRUE), readRDS)); res <- res[!duplicated(names(res))]
say(length(res), " of ", length(pool), " specifications fitted")
ok <- function(r) is.null(r$error)
errs <- sum(vapply(res, function(x) !ok(x$Bulk) || !ok(x$Diffuse), logical(1)))
dev <- max(unlist(lapply(res, function(x) c(if (ok(x$Bulk)) x$Bulk$dev, if (ok(x$Diffuse)) x$Diffuse$dev))), na.rm = TRUE)
say("failed fits: ", errs, " | full-sample fossil coefficient against the sweep, max |difference| ", signif(dev, 2))
res <- res[vapply(res, function(x) ok(x$Bulk) && ok(x$Diffuse), logical(1))]
H <- function(v, a = ALPHA) list(H1 = is.finite(v["fossil", ]) & v["fossil", ] < 0 & is.finite(v["pFossil", ]) & v["pFossil", ] < a,
                                 H2 = is.finite(v["pH2", ]) & v["pH2", ] < a)
# per specification and sector: pass on half A, on half B (each split), the coefficient on each
per <- lapply(res, function(x) lapply(x[names(SECTORS)], function(r) {
  A <- r$half[1:3, , drop = FALSE]; B <- r$half[4:6, , drop = FALSE]; rownames(A) <- rownames(B) <- c("fossil", "pFossil", "pH2")
  list(A = H(A), B = H(B), bA = A["fossil", ], bB = B["fossil", ]) }))
repl <- function(pick) {    # pick(x, half) -> logical over splits; replication = P(pass B | pass A), base = P(pass B); both directions pooled
  a <- do.call(rbind, lapply(per, function(x) pick(x, "A"))); b <- do.call(rbind, lapply(per, function(x) pick(x, "B")))
  c(passOneHalf = mean(c(a, b)), replication = (sum(a & b) * 2) / (sum(a) + sum(b)), baseRate = mean(c(a, b)),
    lift = ((sum(a & b) * 2) / (sum(a) + sum(b))) / mean(c(a, b)), nSpecs = nrow(a))
}
reqs <- list("H1 P&I" = function(x, h) x$Bulk[[h]]$H1, "H2 P&I" = function(x, h) x$Bulk[[h]]$H2,
             "H1 B&T" = function(x, h) x$Diffuse[[h]]$H1, "H2 B&T" = function(x, h) x$Diffuse[[h]]$H2,
             "H1-H2 both sectors" = function(x, h) x$Bulk[[h]]$H1 & x$Bulk[[h]]$H2 & x$Diffuse[[h]]$H1 & x$Diffuse[[h]]$H2)
replication <- data.frame(requirement = names(reqs), do.call(rbind, lapply(reqs, repl)), row.names = NULL)
# shrinkage: among specifications passing H1 on one half, the fossil coefficient on the other half over that on the first
shrink <- do.call(rbind, lapply(names(SECTORS), function(sec) {
  r <- unlist(lapply(per, function(x) { s <- x[[sec]]; c((s$bB / s$bA)[s$A$H1], (s$bA / s$bB)[s$B$H1]) }))
  sg <- unlist(lapply(per, function(x) { s <- x[[sec]]; c((s$bB < 0)[s$A$H1], (s$bA < 0)[s$B$H1]) }))
  data.frame(sector = SECTORS[[sec]], n = length(r), shrinkageMedian = stats::median(r, na.rm = TRUE),
             shrinkageMean = mean(pmin(pmax(r, -5), 5), na.rm = TRUE), signHoldsOnOtherHalf = mean(sg, na.rm = TRUE)) }))
# the selected specification, and the 80 that pass the gate on the full sample
SEL <- yaml::read_yaml(file.path(GD, "selected-models-pfm.yml"))[[1]]$name
one <- function(nm) do.call(rbind, lapply(names(SECTORS), function(sec) { s <- per[[nm]][[sec]]
  data.frame(model = nm, sector = SECTORS[[sec]], full = res[[nm]][[sec]]$full[["fossil"]],
             negativeBothHalves = mean(s$bA < 0 & s$bB < 0, na.rm = TRUE), H1bothHalves = mean(s$A$H1 & s$B$H1), H1eitherHalf = mean(s$A$H1 | s$B$H1),
             H2bothHalves = mean(s$A$H2 & s$B$H2), halfCoefP05 = stats::quantile(c(s$bA, s$bB), 0.05, na.rm = TRUE),
             halfCoefMedian = stats::median(c(s$bA, s$bB), na.rm = TRUE), halfCoefP95 = stats::quantile(c(s$bA, s$bB), 0.95, na.rm = TRUE), row.names = NULL) }))
selected <- if (SEL %in% names(per)) one(SEL) else NULL
p80 <- intersect(passed, names(per))
gate80 <- do.call(rbind, lapply(names(SECTORS), function(sec) {
  x <- per[p80]; f <- function(fun) mean(unlist(lapply(x, function(z) fun(z[[sec]]))), na.rm = TRUE)
  data.frame(sector = SECTORS[[sec]], nSpecs = length(p80), negativeBothHalves = f(function(s) s$bA < 0 & s$bB < 0),
             H1oneHalf = f(function(s) c(s$A$H1, s$B$H1)), H2oneHalf = f(function(s) c(s$A$H2, s$B$H2)),
             shrinkageMedian = stats::median(unlist(lapply(x, function(z) { s <- z[[sec]]; c(s$bA, s$bB) / res[[1]][[sec]]$full[["fossil"]] * 0 +
               c(s$bA, s$bB) })) , na.rm = TRUE) / stats::median(vapply(p80, function(nm) res[[nm]][[sec]]$full[["fossil"]], numeric(1)))) }))
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), nPool = length(pool), nFitted = length(res), nFailed = errs, splits = NSPLIT,
            seed = SEED, alpha = ALPHA, maxDevFromSweep = dev, replication = replication, shrinkage = shrink, selected = selected, selectedName = SEL,
            gatePassers = gate80, note = paste("halves of 24 countries; designs scaled on the full sample; H2 Bonferroni over the fossil x institution",
                                               "terms kept in the half's fit; replication = P(pass on the other half | pass on one half), both directions pooled;",
                                               "gatePassers$shrinkageMedian = median half-sample coefficient over the median full-sample one, the 80 gate passers"))
saveRDS(out, file.path(GD, "theory-gate-split-sample.rds")); say("wrote ", file.path(GD, "theory-gate-split-sample.rds"))
options(width = 200)
cat("\n== replication of each requirement across halves (pool) ==\n"); print(replication, row.names = FALSE, digits = 3)
cat("\n== shrinkage of the fossil coefficient, specifications passing H1 on one half ==\n"); print(shrink, row.names = FALSE, digits = 3)
cat("\n== the selected specification ==\n"); print(selected, row.names = FALSE, digits = 3)
cat("\n== the full-sample gate passers, on halves ==\n"); print(gate80, row.names = FALSE, digits = 3)
