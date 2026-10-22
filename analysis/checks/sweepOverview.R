# A specification search ranked along its dimensions (design note 0007 sections 9-12; written for v7).
#   Rscript analysis/checks/sweepOverview.R [group]     (repo root; default v7) -> output/pfm/<group>/sweep-overview.rds
# Reads sweep.rds (maximin ranking, sanity walk). The dimensions are parsed from the spec names: the interaction
# weight (" iw:<w>[@accRoL]"), the accountability slot (VerAcc, HorAcc, DiagAcc, OvAcc, noAcc), the actor-power form
# (bothIncAP, splitAPpc, ...) and its transform (satAP, satInn, satInc, else linear).
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v7"
GD <- file.path("output/pfm", g)
s <- readRDS(file.path(GD, "sweep.rds")); m <- s$maximin$PolicyStringency
tok <- function(x, re, none) { i <- regexpr(re, x); out <- rep(none, length(x)); out[i > 0] <- regmatches(x, i); out }
m$weight <- sub("@accRoL", "", sub("^ iw:", "", tok(m$model, " iw:[a-z]+(@accRoL)?", " iw:none")))
m$scope <- ifelse(grepl("@accRoL", m$model), "A7", ifelse(m$weight == "none", "unweighted", "A3"))
m$accountability <- tok(m$model, "(VerAcc|HorAcc|DiagAcc|OvAcc|noAcc)", "?")
m$institutions <- sub("\\|[A-Za-z]+$", "", sub("^X-[0-9]+ ([^ ]+) .*", "\\1", m$model))   # GE and rule of law in or out
m$apForm <- sub("^ ", "", tok(m$model, " [A-Za-z]*AP[A-Za-z]* ", " other "))
m$apForm <- trimws(m$apForm)
m$apTransform <- tok(m$model, "(satAP|satInn|satInc)", "linear")
tab <- function(var, top) {
  x <- m[m$rank <= top, ]; t <- sort(table(x[[var]]), decreasing = TRUE)
  data.frame(dimension = var, top = top, level = names(t), n = as.integer(t), share = round(as.numeric(t) / nrow(x), 3))
}
dims <- c("weight", "scope", "accountability", "institutions", "apForm", "apTransform")
shares <- do.call(rbind, lapply(dims, function(d) do.call(rbind, lapply(c(50, 500, nrow(m)), function(k) tab(d, k)))))
best <- do.call(rbind, lapply(dims, function(d) do.call(rbind, lapply(split(m, m[[d]]), function(x) {
  b <- x[which.min(x$rank), ]
  data.frame(dimension = d, level = b[[d]], nSpecs = nrow(x), bestRank = b$rank, meanDeltaR2 = b$meanDeltaR2, bestModel = b$model)
}))))
flags <- s$sanity$PolicyStringency$flags
walk <- do.call(rbind, lapply(names(flags), function(nm) {
  f <- flags[[nm]]; sv <- f[f$severity == "severe", ]
  data.frame(rank = m$rank[match(nm, m$model)], model = nm,
             severe = if (nrow(sv)) paste(unique(paste0(sv$rule, " (", sv$sector, ")")), collapse = "; ") else "")
}))
sel <- walk$model[!nzchar(walk$severe)][1]
out <- list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), nSpecs = nrow(m), selected = sel,
            selectedRank = m$rank[match(sel, m$model)], shares = shares, best = best, walk = walk,
            maximinTop = m[m$rank <= 20, c("rank", "model", "meanDeltaR2", "minDeltaR2", "sumBIC")])
saveRDS(out, file.path(GD, "sweep-overview.rds"))
options(width = 250)
cat("specs", nrow(m), "| selected", sel, "| maximin rank", out$selectedRank, "\n\n")
print(best[, c("dimension", "level", "nSpecs", "bestRank", "meanDeltaR2")], row.names = FALSE)
cat("\nshare of the top 50 / top 500 / all specs:\n")
w <- reshape(shares[, c("dimension", "level", "top", "share")], idvar = c("dimension", "level"), timevar = "top", direction = "wide")
print(w, row.names = FALSE)
cat("\nsanity walk:\n"); print(walk, row.names = FALSE)
