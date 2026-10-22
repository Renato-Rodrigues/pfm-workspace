# Which specifications of a sweep carry the v6 spec's theory-central terms significantly (design note 0007 section 14).
#   Rscript analysis/checks/theoryTermScreen.R [group]   (repo root; default v7) -> output/pfm/<group>/theory-term-screen.rds
# From sweep.rds `coefficients` (every fit's coefficient table, cluster-robust asymptotic p) and the maximin ranking.
# Per sector and spec, the fossil interest is read on its share form, or on its per-person form when the spec has no
# share form (as the edge gate reads it); accountability is whichever index the spec uses (VerAcc, HorAcc, DiagAcc,
# OvAcc). The pattern of v6's X-1791 (inference.rds, wild bootstrap): fossil dependence lowers the ceiling, and
# accountability strengthens that effect (fossil x accountability < 0), in both sectors.
`%||%` <- function(a, b) if (is.null(a)) b else a
args <- commandArgs(trailingOnly = TRUE); g <- if (length(args)) args[1] else "v7"
GD <- file.path("output/pfm", g)
s <- readRDS(file.path(GD, "sweep.rds")); cf <- s$coefficients; m <- s$maximin$PolicyStringency
cf <- cf[grepl("Incumbent|Innovator", cf$term), ]
key <- function(x) {
  t <- x$term
  fos <- if ("Incumbent.Power" %in% t) "Incumbent.Power" else if ("Incumbent.Power.pc" %in% t) "Incumbent.Power.pc" else NA
  cln <- if ("Innovator.Power" %in% t) "Innovator.Power" else if ("Innovator.Power.pc" %in% t) "Innovator.Power.pc" else NA
  acc <- t[grepl(paste0("^", fos, "_x_.*Accountability"), t)][1]
  get <- function(k, col) if (!is.na(k) && k %in% t) x[[col]][match(k, t)] else NA_real_
  data.frame(fossil = get(fos, "estimate"), pFossil = get(fos, "pValue"), clean = get(cln, "estimate"),
             pClean = get(cln, "pValue"), fossilXacc = get(acc, "estimate"), pFossilXacc = get(acc, "pValue"))
}
sp <- split(cf, list(cf$model, cf$sector), drop = TRUE)
rows <- do.call(rbind, lapply(names(sp), function(k) cbind(model = sp[[k]]$model[1], sector = sp[[k]]$sector[1], key(sp[[k]]))))
wide <- merge(rows[rows$sector == "Bulk", -2], rows[rows$sector == "Diffuse", -2], by = "model", suffixes = c(".PI", ".BT"))
wide <- merge(wide, m[, c("model", "rank", "gatePass")], by = "model")
ok <- function(b, p) is.finite(b) & is.finite(p) & p < 0.05
wide$v6patternBT <- ok(wide$fossilXacc.BT, wide$pFossilXacc.BT) & wide$fossilXacc.BT < 0 & ok(wide$fossil.BT, wide$pFossil.BT) & wide$fossil.BT < 0
wide$v6patternPI <- ok(wide$fossilXacc.PI, wide$pFossilXacc.PI) & wide$fossilXacc.PI < 0
wide$v6pattern <- wide$v6patternBT & wide$v6patternPI
wide <- wide[order(wide$rank), ]
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), table = wide), file.path(GD, "theory-term-screen.rds"))
options(width = 250)
for (top in c(50, 200, 1000, nrow(wide))) {
  x <- wide[wide$rank <= top, ]
  cat(sprintf("top %5d: v6 pattern in B&T %4d (%.0f%%), in P&I %4d, in both %4d\n", top, sum(x$v6patternBT), 100 * mean(x$v6patternBT),
              sum(x$v6patternPI), sum(x$v6pattern)))
}
cat("\nbest-ranked specs with the pattern in both sectors:\n")
show <- c("rank", "model", "fossil.BT", "pFossil.BT", "fossilXacc.BT", "pFossilXacc.BT", "fossilXacc.PI", "pFossilXacc.PI")
print(head(wide[wide$v6pattern, show], 20), row.names = FALSE, digits = 3)
cat("\nthe walk's candidates and the v6 twins:\n")
print(wide[wide$rank <= 11 | grepl("^X-1791 .*(satAP|satInn|satInc)", wide$model), show], row.names = FALSE, digits = 3)
