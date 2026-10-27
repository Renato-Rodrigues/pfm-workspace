# The gap-closure rate from history, without PoliClim (design note 0008 §3a).
#   Rscript analysis/checks/gapClosureHistory.R [group]   (repo root; default v7) -> output/pfm/<group>/gap-closure-history.rds
# The rule x(s + h) = 1 - (1 - x(s)) exp(-lambda h) fitted by least squares to V-Dem's own history, on the panel's
# normalised scale (0 = worst, 1 = best value observed, 1789-2025), every country, for start years s on a five-year grid
# and horizons h of 25 and 50 years. Reported per start-year window, so the rate's stability over the last century
# (and the recent decline) is visible. Two published anchors are converted to the same rate for comparison:
# Andrijevic et al. (2020), SSP2 country effects converging linearly to 2250 (two ways of matching a linear path), and the
# current rule.
suppressMessages(library(mrpfm))
a <- commandArgs(trailingOnly = TRUE); g <- if (length(a)) a[1] else "v7"
madrat::setConfig(cachefolder = normalizePath(file.path("data/madrat", g), winslash = "/"), forcecache = TRUE, .verbose = FALSE)
q <- function(e) suppressWarnings(suppressMessages(e))
vd <- q(calcOutput("VDem", aggregate = FALSE))
SER <- c("Rule of Law (VDem)", "Vertical Accountability (VDem)")
norm <- function(s) { A <- as.array(vd[, , s])[, , 1]; colnames(A) <- sub("^y", "", colnames(A))
  (A - min(A, na.rm = TRUE)) / (max(A, na.rm = TRUE) - min(A, na.rm = TRUE)) }
fitRate <- function(x0, x1, h) {   # least squares on the change, same form as the rule
  ok <- is.finite(x0) & is.finite(x1) & x0 < 1; if (sum(ok) < 10) return(c(lambda = NA, r2 = NA, n = sum(ok)))
  f <- function(l) sum((1 - (1 - x0[ok]) * exp(-l * h) - x1[ok])^2)
  l <- stats::optimize(f, c(-0.05, 0.05))$minimum
  d <- x1[ok] - x0[ok]; p <- (1 - x0[ok]) * (1 - exp(-l * h))
  c(lambda = l, r2 = 1 - sum((p - d)^2) / sum((d - mean(d))^2), n = sum(ok))
}
windows <- list(`1900-1950` = c(1900, 1950), `1950-2000` = c(1950, 2000), `1975-2025` = c(1975, 2025),
                `1990-2025` = c(1990, 2025), `2000-2025` = c(2000, 2025))
res <- do.call(rbind, lapply(SER, function(s) {
  A <- norm(s)
  rbind(
    # pooled: every start year on a 5-year grid, horizon h (overlapping pairs)
    do.call(rbind, lapply(c(25, 50), function(h) {
      st <- seq(1900, 2025 - h, 5)
      x0 <- unlist(lapply(st, function(t) A[, as.character(t)])); x1 <- unlist(lapply(st, function(t) A[, as.character(t + h)]))
      data.frame(series = s, sample = sprintf("pooled 1900-2025, %d-year horizon", h), t(fitRate(x0, x1, h)))
    })),
    # single windows: start to end
    do.call(rbind, lapply(names(windows), function(w) { y <- windows[[w]]
      data.frame(series = s, sample = paste("window", w), t(fitRate(A[, as.character(y[1])], A[, as.character(y[2])], y[2] - y[1]))) })))
}))
res$halfLife <- ifelse(res$lambda > 0, log(2) / res$lambda, NA)
# published anchors, as the same rate. Andrijevic et al. (2020) converge country effects LINEARLY to a common level
# (SSP2: from 2015 to 2250); the rule is exponential, so the match depends on what is matched, from the rule's start in
# 2025: (a) the same share of the 2025 gap closed by 2100, (75 / 225) -> lambda = -ln(1 - share) / 75; (b) the same
# half-way year (2025 + 225 / 2) -> lambda = ln 2 / 112.5. The two bound the rate that represents the assumption.
lin <- function(end) { share <- (2100 - 2025) / (end - 2025); c(sameShare = -log(1 - share) / 75, sameHalfway = log(2) / ((end - 2025) / 2), share = share) }
a2 <- lin(2250); a1 <- lin(2130)
cur <- local({ k <- log(99) / 70; L <- function(y) 1 / (1 + exp(-k * (y - 2080))); (L(2100) - L(2025)) / (L(2150) - L(2025)) })
anchors <- data.frame(
  anchor = c("Andrijevic et al. 2020, SSP2: linear convergence to 2250", "Andrijevic et al. 2020, SSP1: linear convergence to 2130",
             "current rule (SSP2): logistic, half the gap by 2080, complete by 2150"),
  shareOf2025GapClosedBy2100 = c(a2[["share"]], a1[["share"]], cur),
  lambdaSameShare = c(a2[["sameShare"]], a1[["sameShare"]], -log(1 - cur) / 75),
  lambdaSameHalfway = c(a2[["sameHalfway"]], a1[["sameHalfway"]], log(2) / (2080 - 2025)))
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), history = res, anchors = anchors),
        file.path("output/pfm", g, "gap-closure-history.rds"))
options(width = 160); print(res, digits = 3, row.names = FALSE); print(anchors, digits = 3, row.names = FALSE)
