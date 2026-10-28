# v8 test (design note 0009 section 12): a truncated-normal slack, in the scaling form, with and without the rents.
#   Rscript analysis/v8/truncSlack.R [group]   (repo root; default v7) -> output/pfm/<group>/v8-trunc-slack.rds
# The scaling form (Wang & Schmidt 2002): u_it = h_it u*, h_it = exp(c + w z_it), u* ~ N+(tau, 1). The slack's mean and
# spread both scale with h, so the v8 coupling rule q_c(t) = q_c exp(w (z_t - z_2023)) stays exact; tau = 0 is the
# half-normal of v7 / v8. Normal-truncated-normal density (Stevenson 1980) with mu = tau h and sigma_u = h:
#   f(e) = phi((e + mu) / s) Phi(mu* / s*) / (s Phi(mu / sigma_u)),  s^2 = sigma_v^2 + sigma_u^2,
#   mu* = (mu sigma_v^2 - e sigma_u^2) / s^2,  s* = sigma_u sigma_v / s.
# The truncated normal runs to tau -> -inf on this panel (the far tail of a normal: an exponential), so the
# exponential slack is fitted directly too (Meeusen & van den Broeck 1977), in the same scaling form, u = h u*, u* ~ Exp(1):
#   f(e) = (1 / h) Phi(-e / sigma_v - sigma_v / h) exp(e / h + sigma_v^2 / (2 h^2)).
# Models, on the v7 frontier design (no fossil bound: comparable with sections 8-9):
#   P&I: hn (v7), tn, ex;    B&T: hn (v7), hnRents (v8), tn, tnRents, ex, exRents.
# Reported: in-sample logLik, LR, tau, w; E 2023 rank correlation with v7; out of sample as analysis/v8/hetSlackCV.R
# (each covered country left out, every model refitted on the others, scored on its rows), per country.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
if (!exists(".pfmSpecArgs")) source("models/pfm/R/pfmSpecArgs.R")
source("analysis/v8/_rents.R")
g <- local({ a <- commandArgs(trailingOnly = TRUE); if (length(a)) a[1] else "v7" })
GD <- file.path("output/pfm", g)
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
Rh <- v8RentsHistory(getItems(panel, dim = 1), getYears(panel, as.integer = TRUE), file.path(GD, "v8-wdi-rents.rds"))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
norm <- function(s) { for (f in c("actorPowerDrivers", "actorPowerIndex", "instQualityDrivers", "controlDrivers"))
  if (!is.null(s[[f]])) s[[f]] <- unlist(s[[f]]); s }

# p = (beta, log sigma_v, c, w..., tau); Z carries the intercept column
llRows <- function(p, y, X, Z, trunc) {
  kb <- ncol(X); kz <- ncol(Z); b <- p[seq_len(kb)]; sv <- exp(p[kb + 1]); h <- exp(as.numeric(Z %*% p[kb + 1 + seq_len(kz)]))
  if (identical(trunc, "exp")) {
    # stable form: log f = -log h - e^2 / (2 sv^2) + [log Phi(-a) + a^2 / 2], a = e / sv + sv / h; the bracket by its
    # asymptotic expansion for large a (the direct form cancels two huge terms and the optimiser exploits the error)
    e <- y - as.numeric(X %*% b); a <- e / sv + sv / h
    m <- ifelse(a > 25, -log(a) - 0.5 * log(2 * pi) - 1 / a^2 + 2.5 / a^4, stats::pnorm(-pmin(a, 25), log.p = TRUE) + pmin(a, 25)^2 / 2)
    return(-log(h) - e^2 / (2 * sv^2) + m)
  }
  tau <- if (isTRUE(trunc)) p[kb + kz + 2] else 0
  e <- y - as.numeric(X %*% b); mu <- tau * h; s <- sqrt(sv^2 + h^2)
  muS <- (mu * sv^2 - e * h^2) / s^2; sS <- h * sv / s
  -log(s) + stats::dnorm((e + mu) / s, log = TRUE) + stats::pnorm(muS / sS, log.p = TRUE) - stats::pnorm(tau, log.p = TRUE)
}
fitOne <- function(y, X, Z, trunc, start) {
  nll <- function(p) { v <- -sum(llRows(p, y, X, Z, trunc)); if (is.finite(v)) v else 1e10 }
  o <- stats::optim(start, nll, method = "BFGS", control = list(maxit = 5000, reltol = 1e-12))
  list(par = o$par, ll = -o$value, conv = o$convergence)
}

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- norm(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), .pfmSpecArgs(cfg)))))
  d <- ff$data; X <- stats::model.matrix(ff$formula, d); y <- stats::model.response(stats::model.frame(ff$formula, d))
  cty <- as.character(d[rownames(X), "region"]); obs <- as.numeric(ff$outcomeNatural[rownames(X)])
  rr <- Rh[cbind(match(cty, rownames(Rh)), match(as.character(d[rownames(X), "year"] - 1), colnames(Rh)))]
  zR <- (rr - mean(rr, na.rm = TRUE)) / stats::sd(rr, na.rm = TRUE); zR[!is.finite(zR)] <- 0
  one <- rep(1, nrow(X))
  M <- if (sec == "Bulk") list(hn = list(Z = cbind(one), trunc = FALSE), tn = list(Z = cbind(one), trunc = TRUE),
                               ex = list(Z = cbind(one), trunc = "exp")) else
    list(hn = list(Z = cbind(one), trunc = FALSE), hnRents = list(Z = cbind(one, zR), trunc = FALSE),
         tn = list(Z = cbind(one), trunc = TRUE), tnRents = list(Z = cbind(one, zR), trunc = TRUE),
         ex = list(Z = cbind(one), trunc = "exp"), exRents = list(Z = cbind(one, zR), trunc = "exp"))
  b0 <- stats::coef(ff$model); s2 <- b0[["sigmaSq"]]; ga <- b0[["gamma"]]
  st0 <- c(b0[colnames(X)], log(sqrt((1 - ga) * s2)), log(sqrt(ga * s2)))
  startOf <- function(m) c(st0, rep(0, ncol(m$Z) - 1), if (isTRUE(m$trunc)) 0)
  full <- lapply(M, function(m) fitOne(y, X, m$Z, m$trunc, startOf(m)))
  # in-sample table, E 2023
  i23 <- d[rownames(X), "year"] == 2023
  Eof <- function(p) { e <- obs / (10 * stats::plogis(as.numeric(X %*% p[seq_len(ncol(X))]))); stats::setNames(e[i23], cty[i23]) }
  E <- sapply(full, function(f) Eof(f$par))
  kb <- ncol(X)
  tab <- do.call(rbind, lapply(names(M), function(mn) { f <- full[[mn]]; m <- M[[mn]]; kz <- ncol(m$Z)
    data.frame(sector = sec, model = mn, logLik = f$ll, k = length(f$par), LRvsHN = 2 * (f$ll - full$hn$ll), conv = f$conv,
               c = f$par[kb + 2], w = if (kz > 1) f$par[kb + 3] else NA_real_, tau = if (isTRUE(m$trunc)) f$par[length(f$par)] else 0,
               spearmanE = stats::cor(E[, mn], E[, "hn"], method = "spearman"), row.names = NULL) }))
  # out of sample, per country
  ho <- sapply(names(M), function(mn) { m <- M[[mn]]
    vapply(unique(cty), function(c) {
      tr <- cty != c
      keepX <- apply(X[tr, , drop = FALSE], 2, function(v) stats::var(v) > 0) | colnames(X) == "(Intercept)"
      p0 <- full[[mn]]$par; pS <- c(p0[seq_len(kb)][keepX], p0[-seq_len(kb)])
      o <- fitOne(y[tr], X[tr, keepX, drop = FALSE], m$Z[tr, , drop = FALSE], m$trunc, pS)
      pF <- c(replace(numeric(kb), which(keepX), o$par[seq_len(sum(keepX))]), o$par[-seq_len(sum(keepX))])
      sum(llRows(pF, y[!tr], X[!tr, , drop = FALSE], m$Z[!tr, , drop = FALSE], m$trunc))
    }, numeric(1)) })
  message("[trunc] ", sec, " done")
  pairs <- if (sec == "Bulk") list(c("tn", "hn"), c("ex", "hn"), c("ex", "tn")) else
    list(c("hnRents", "hn"), c("tn", "hn"), c("tnRents", "hnRents"), c("ex", "hn"), c("exRents", "hnRents"), c("exRents", "ex"), c("exRents", "tnRents"))
  oos <- do.call(rbind, lapply(pairs, function(pp) { dd <- ho[, pp[1]] - ho[, pp[2]]
    data.frame(sector = sec, model = pp[1], against = pp[2], better = sum(dd > 0), n = length(dd), medianGain = stats::median(dd),
               signP = stats::binom.test(sum(dd > 0), length(dd))$p.value, row.names = NULL) }))
  list(fit = tab, oos = oos, heldOut = ho, E = E)
})
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), bySector = res), file.path(GD, "v8-trunc-slack.rds"))
options(width = 200)
for (sec in names(res)) { r <- res[[sec]]; cat("\n==========", sec, "==========\n")
  print(r$fit, digits = 4, row.names = FALSE); cat("out of sample, per country:\n"); print(r$oos, digits = 3, row.names = FALSE)
  e <- r$E; cat("E 2023, selected countries:\n"); print(round(e[intersect(c("SAU", "RUS", "NOR", "ISL", "IDN", "CHN", "IND", "USA", "DEU"), rownames(e)), ], 2)) }
