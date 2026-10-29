# The net effect of each actor-power driver and each institution on the ceiling, at every country's own values.
#   Rscript analysis/checks/netEffects.R [group] [scenario panel .rds]   (repo root; default v8)
#     -> output/pfm/<group>/net-effects.rds   (read by the figure `net-effects`)
# A driver d enters the ceiling (logit scale, per SD of the term) as a main effect and through its interactions with the
# institutions k, each weighted by the democracy weight in its scope (.pfmIwFactor). Its effect at a country's own values is
#   m_d = beta_d + sum_k beta_{d x k} z_k f_k          (an interest, given that country's institutions)
#   m_k = beta_k + sum_d beta_{d x k} z_d f_k          (an institution, given that country's interests)
# where z are the standardised (and, for satAP, saturated; for fos5, bounded) terms. A main effect and an interaction of
# opposite sign mean the net effect changes size, and possibly sign, across countries: the table counts how often the net
# effect keeps the main effect's sign. Evaluated on the frontier's estimation rows (2023 and all years) and, with a scenario
# panel, on the projected countries in 2050 and 2100 (the frozen scaling, the trend frozen, the driver guard - as the
# coupling evaluates the ceiling). Shares are of countries; the scenario rows also carry final-energy weights. Standard errors
# of each net effect come from the frontier's vcov (delta method, the slope is linear in beta); 'significant' is |z| > 1.96.
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
args <- commandArgs(trailingOnly = TRUE)
g <- if (length(args)) args[1] else "v8"
SCEN <- if (length(args) >= 2) args[2] else c(v8 = "output/pfm/v8/coupling/scen-v7Bfix-gapclosure-v8panel.rds",
                                             v7 = "output/pfm/v7/coupling/scen-PFMlevelBfix-v7.rds")[[g]] %||% NA
GD <- file.path("output/pfm", g)
hash <- jsonlite::fromJSON(file.path(GD, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
sel <- yaml::read_yaml(pfm:::.pfmSelectedModels(GD))
DRV <- c("Innovator.Power", "Incumbent.Power", "Incumbent.Power.pc")
LAB <- c(Innovator.Power = "clean-energy build-out", Incumbent.Power = "fossil dependence", Incumbent.Power.pc = "fossil interests per person",
         Government.Effectiveness..WGI. = "government effectiveness", Rule.of.Law..VDem. = "rule of law",
         Vertical.Accountability..VDem. = "vertical accountability", Horizontal.Accountability..VDem. = "horizontal accountability",
         Overall.Accountability..VDem. = "overall accountability")
w <- tryCatch(pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")$weights, error = function(e) NULL)

net <- function(b, df, V = NULL) {
  ints <- grep("_x_", names(b), value = TRUE); pr <- do.call(rbind, strsplit(ints, "_x_", fixed = TRUE)); rownames(pr) <- ints
  inst <- unique(pr[, 2]); drv <- intersect(DRV, names(b))
  f <- lapply(stats::setNames(inst, inst), function(k) { v <- rep_len(pfm:::.pfmIwFactor(df, k), nrow(df)); v[!is.finite(v)] <- 1; v })
  grad <- function(t, parts) { A <- matrix(0, nrow(df), length(b), dimnames = list(NULL, names(b))); A[, t] <- 1
    for (i in names(parts)) A[, i] <- parts[[i]]; A }
  out <- list(); se <- list()
  for (t in c(drv, intersect(inst, names(b)))) {
    parts <- if (t %in% drv) lapply(stats::setNames(ints[pr[, 1] == t], ints[pr[, 1] == t]), function(k) df[[pr[k, 2]]] * f[[pr[k, 2]]])
             else lapply(stats::setNames(ints[pr[, 2] == t], ints[pr[, 2] == t]), function(i) df[[pr[i, 1]]] * f[[t]])
    A <- grad(t, parts); out[[t]] <- drop(A %*% b)
    if (!is.null(V)) se[[t]] <- sqrt(pmax(rowSums((A %*% V[names(b), names(b)]) * A), 0))
  }
  # every institution moved by one SD together (the gap-closure rule moves them together, and GE and RoL are collinear)
  instIn <- intersect(inst, names(b))
  if (length(instIn) > 1) { A <- Reduce(`+`, lapply(instIn, function(k) grad(k, lapply(stats::setNames(ints[pr[, 2] == k], ints[pr[, 2] == k]),
                                                                                         function(i) df[[pr[i, 1]]] * f[[k]]))))
    out[["institutions together"]] <- drop(A %*% b)
    if (!is.null(V)) se[["institutions together"]] <- sqrt(pmax(rowSums((A %*% V[names(b), names(b)]) * A), 0)) }
  M <- as.data.frame(out, check.names = FALSE)
  if (length(se)) attr(M, "se") <- as.data.frame(se, check.names = FALSE)
  M
}
summ <- function(M, S, b, wts = NULL, label) {
  do.call(rbind, lapply(names(M), function(t) { m <- M[[t]]; ok <- is.finite(m); zz <- if (is.null(S)) NA else (m / S[[t]])[ok]; m <- m[ok]
    ww <- if (is.null(wts)) rep(1, length(m)) else { x <- wts[ok]; x[!is.finite(x)] <- 0; x }
    ints <- grep(paste0("(^", t, "_x_)|(_x_", t, "$)"), names(b), value = TRUE)
    main <- if (t %in% names(b)) b[[t]] else sum(b[intersect(names(LAB), setdiff(names(M), c(DRV, t)))])
    data.frame(where = label, term = t, label = if (t %in% names(LAB)) LAB[[t]] else t, main = main,
               interactions = paste(sprintf("%s %+.2f", sub(paste0("_x_", t, "$|^", t, "_x_"), "", ints), b[ints]), collapse = "; "),
               nOpposite = sum(sign(b[ints]) != sign(main)), nInteractions = length(ints),
               p10 = unname(stats::quantile(m, 0.1)), median = stats::median(m), p90 = unname(stats::quantile(m, 0.9)),
               shareSameSign = mean(sign(m) == sign(main)), shareNegative = mean(m < 0),
               shareSigSame = mean(sign(m) == sign(main) & abs(zz) > 1.96), shareSigOpposite = mean(sign(m) != sign(main) & abs(zz) > 1.96),
               shareSameSignFE = if (sum(ww) > 0) sum(ww * (sign(m) == sign(main))) / sum(ww) else NA_real_,
               n = length(m), row.names = NULL) }))
}

res <- lapply(c(Bulk = "Bulk", Diffuse = "Diffuse"), function(sec) {
  cfg <- pfm:::.pfmNormSpec(Filter(function(x) identical(x$model_type, paste0("PolicyStringency: ", sec)), sel)[[1]])
  ff <- suppressWarnings(suppressMessages(do.call(estimatePolicyStringencyModel, c(list(data = panel, sector = sec, estimator = "frontier",
                         indexMax = 10, modelDir = NULL, updateIndex = FALSE, verbose = FALSE), pfm:::.pfmSpecArgs(cfg)))))
  b <- pfm:::.pfmCeilingBeta(stats::coef(ff$model)); d <- ff$data
  V <- tryCatch(stats::vcov(ff$model), error = function(e) NULL); if (!is.null(V) && !all(names(b) %in% rownames(V))) V <- NULL
  M <- net(b, d, V)
  rows <- cbind(data.frame(region = as.character(d$region), year = d$year), M)
  rowsSe <- cbind(rows[, 1:2], attr(M, "se"))
  S <- attr(M, "se"); i <- d$year == max(d$year)
  tab <- rbind(summ(M[i, , drop = FALSE], S[i, , drop = FALSE], b, NULL, "estimation sample, 2023"),
               summ(M, S, b, NULL, "estimation sample, all years"))
  scen <- scenSe <- NULL
  if (!is.na(SCEN) && file.exists(SCEN)) {
    s <- readRDS(SCEN)
    sDf <- preparePanelData(data = s[, , setdiff(getNames(s), grep("Policy Stringency", getNames(s), value = TRUE))], sector = sec,
                            actorPowerDrivers = cfg$actorPowerDrivers, actorPowerIndex = cfg$actorPowerIndex,
                            instQualityDrivers = cfg$instQualityDrivers, controlDrivers = setdiff(cfg$controlDrivers, "lagged_ecp"),
                            regionMappingFixedEffects = NULL, driverScaling = ff$driverScaling,
                            trendFreezeYear = max(d$year), outcomeVar = ff$outcomeVar %||% "Policy Stringency")
    sDf <- pfm:::.pfmDriverGuard(sDf, pfm:::.driverSupportRanges(d, ff$driverScaling))$df
    MS <- net(b, sDf, V); SS <- attr(MS, "se")
    scen <- cbind(data.frame(region = as.character(sDf$region), year = sDf$year), MS)
    scenSe <- cbind(scen[, 1:2], SS)
    for (y in c(2050, 2100)) { i <- sDf$year == y
      tab <- rbind(tab, summ(MS[i, , drop = FALSE], SS[i, , drop = FALSE], b, if (!is.null(w)) w[as.character(sDf$region[i])] else NULL, paste("scenario,", y))) }
  }
  ic <- stats::cor(d[, intersect(names(LAB)[4:8], names(d))], use = "pairwise")
  list(table = cbind(sector = sec, tab), instCor = ic, rows = rows, rowsSe = rowsSe, scenario = scen, scenarioSe = scenSe, beta = b, vcov = V)
})
saveRDS(list(group = g, made = format(Sys.time(), "%Y-%m-%d %H:%M"), scenarioPanel = SCEN, labels = LAB, bySector = res),
        file.path(GD, "net-effects.rds"))
options(width = 230)
for (sec in names(res)) { cat("\n==========", sec, "==========\n")
  x <- res[[sec]]$table; print(x[, c("where", "label", "main", "nOpposite", "nInteractions", "p10", "median", "p90", "shareSameSign", "shareSigSame", "shareSigOpposite", "shareSameSignFE")], digits = 2, row.names = FALSE)
  cat("interactions:\n"); y <- unique(x[, c("label", "main", "interactions")]); for (i in seq_len(nrow(y))) cat(sprintf("  %-28s main %+.2f | %s\n", y$label[i], y$main[i], y$interactions[i])) }
