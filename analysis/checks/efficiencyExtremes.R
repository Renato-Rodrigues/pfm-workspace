# Why some countries sit far from (or on) their feasibility ceiling: the efficiency ratio E = observed / ceiling in 2023,
# and each extreme country's ceiling decomposed into the frontier's terms, against the sample.
#   Rscript analysis/checks/efficiencyExtremes.R [group] [countries...]   (repo root; default v7; ISL ARG SAU IDN RUS PER)
#   -> output/pfm/<group>/efficiency-extremes.rds
# 1. E in 2023 (frontier.rds scores), both sectors, all 48 countries, ranked; the observed index and the ceiling.
# 2. The ceiling's linear predictor (logit scale) split into term groups - clean-energy build-out, fossil dependence,
#    fossil interests per person (each with its interactions), the institution main effects, controls, trend, the
#    OECD / other level - for every country in 2023, each group against its sample mean: what lifts or lowers the
#    country's ceiling relative to a typical country.
#    Also per term (terms), each against its sample mean.
# 3. The country's standardised drivers (z) and whether any lies outside the sample's 5th-95th percentile.
# 4. The observed index over 2015-2023: whether a low E is a low observed policy or a high ceiling.
# The design matrix is rebuilt exactly as the coupling does (pfm:::.pfmFrontierEta's preparePanelData call, the
# anchor's frontier design), on the group's estimation panel (output/pfm/fit-cache/panels/<panel_hash>.rds).
source("analysis/_common/_loadPfm.R"); suppressMessages(library(magclass))
a <- commandArgs(trailingOnly = TRUE)
g <- if (length(a) >= 1) a[1] else "v7"
CTY <- if (length(a) >= 2) a[-1] else c("ISL", "ARG", "SAU", "IDN", "RUS", "PER")
unl <- function(x) if (is.null(x)) NULL else unlist(x)
`%||%` <- function(a, b) if (is.null(a)) b else a
hash <- jsonlite::fromJSON(file.path("output/pfm", g, "manifest.json"))$panel_hash
panel <- readRDS(file.path("output/pfm/fit-cache/panels", paste0("panel_", hash, ".rds")))
if (is.list(panel) && !inherits(panel, "magpie")) panel <- panel$panel %||% panel[[1]]
anc <- pfm:::pfmAnchorFor(file.path("output/remind-inputs", g), "EU21")
fr <- readRDS(file.path("output/pfm", g, "frontier.rds"))$bySector
groupOf <- function(term) {
  if (term == "(Intercept)") return("intercept")
  if (grepl("^regionFE", term)) return("OECD / other level")
  if (term == "logisticTimeTrend") return("trend")
  if (grepl("^Innovator\\.Power", term)) return("clean-energy build-out (incl. interactions)")
  if (grepl("^Incumbent\\.Power\\.pc", term)) return("fossil interests per person (incl. interactions)")
  if (grepl("^Incumbent\\.Power", term)) return("fossil dependence (incl. interactions)")
  if (grepl("GDP|Population|Hydro", term)) return("controls (income, population, clean baseload)")
  "institution main effects"
}
out <- lapply(c("Bulk", "Diffuse"), function(sec) {
  design <- anc$designs[[sec]]; cfg <- design$cfg; fit <- design$fit
  df <- preparePanelData(
    data = panel, sector = design$sector,
    actorPowerDrivers = unl(cfg$actorPowerDrivers), actorPowerIndex = unl(cfg$actorPowerIndex),
    instQualityDrivers = unl(cfg$instQualityDrivers), controlDrivers = setdiff(unl(cfg$controlDrivers), "lagged_ecp"),
    regionMappingFixedEffects = if (isTRUE(cfg$useMundlak)) NULL else cfg$regionMappingFixedEffects,
    useMundlak = isTRUE(cfg$useMundlak), gdpGovInteraction = isTRUE(cfg$gdpGovInteraction),
    driverScaling = fit$driverScaling, trendMidpoint = design$trend[["midpoint"]], trendSteepness = design$trend[["steepness"]],
    trendFreezeYear = if (is.finite(design$lastHist)) design$lastHist else NULL, outcomeVar = fit$outcomeVar %||% "Policy Stringency")
  lv <- fit$model$xlevels$regionFE
  if (!is.null(lv) && "regionFE" %in% names(df)) { fe <- as.character(df$regionFE); fe[!fe %in% lv] <- lv[1]; df$regionFE <- factor(fe, levels = lv) }
  df$lagged_ecp <- 0
  tt <- stats::delete.response(stats::terms(fit$formula))
  mm <- stats::model.matrix(tt, stats::model.frame(tt, data = df, na.action = stats::na.pass))
  b <- design$beta; mm <- mm[, names(b), drop = FALSE]
  contrib <- sweep(mm, 2, b, `*`)
  grp <- vapply(colnames(contrib), groupOf, "")
  G <- sapply(unique(grp), function(k) rowSums(contrib[, grp == k, drop = FALSE]))
  G <- data.frame(region = as.character(df$region), year = df$year, G, check.names = FALSE)
  y23 <- G[G$year == 2023, ]
  rel <- y23; for (k in unique(grp)) rel[[k]] <- y23[[k]] - mean(y23[[k]], na.rm = TRUE)
  rel$eta <- rowSums(y23[, unique(grp)]); rel$etaRel <- rel$eta - mean(rel$eta, na.rm = TRUE)
  # the drivers, standardised (model scale) and their position in the sample
  drv <- intersect(names(fit$driverScaling), names(df))
  Z <- df[df$year == 2023, c("region", drv)]
  pos <- sapply(drv, function(d) { v <- df[[d]]; q <- stats::quantile(v, c(.05, .95), na.rm = TRUE)
    ifelse(Z[[d]] < q[1], "below p5", ifelse(Z[[d]] > q[2], "above p95", "")) })
  sc <- fr[[sec]]$scores; e23 <- sc[sc$year == 2023, c("region", "observedIndex", "frontierIndex", "efficiencyRatio")]
  e23$rankLowE <- rank(e23$efficiencyRatio, ties.method = "min")
  obs <- sc[sc$year >= 2015 & sc$region %in% CTY, c("region", "year", "observedIndex", "frontierIndex", "efficiencyRatio")]
  i23 <- df$year == 2023
  terms <- sweep(contrib[i23, , drop = FALSE], 2, colMeans(contrib[i23, , drop = FALSE], na.rm = TRUE))
  terms <- data.frame(region = as.character(df$region[i23]), terms, check.names = FALSE)
  list(sector = sec, e2023 = e23[order(e23$efficiencyRatio), ], relContrib = rel, terms = terms, drivers = Z,
       position = data.frame(region = Z$region, pos, check.names = FALSE), observed = obs, beta = b)
})
names(out) <- c("Bulk", "Diffuse")
saveRDS(list(group = g, countries = CTY, made = format(Sys.time(), "%Y-%m-%d %H:%M"), bySector = out),
        file.path("output/pfm", g, "efficiency-extremes.rds"))
options(width = 220)
for (sec in names(out)) {
  o <- out[[sec]]; cat("\n==========", sec, "==========\n-- E in 2023, lowest and highest:\n")
  e <- o$e2023; print(rbind(utils::head(e, 8), utils::tail(e, 6)), digits = 3, row.names = FALSE)
  cat("-- the countries asked about:\n"); print(e[e$region %in% CTY, ], digits = 3, row.names = FALSE)
  cat("-- ceiling (logit) relative to the sample mean, by term group, 2023:\n")
  r <- o$relContrib[o$relContrib$region %in% CTY, ]; print(r[, setdiff(names(r), c("year", "eta"))], digits = 2, row.names = FALSE)
  cat("-- drivers outside the sample's 5-95th percentile:\n")
  p <- o$position[o$position$region %in% CTY, ]
  for (i in seq_len(nrow(p))) { f <- names(p)[-1][p[i, -1] != ""]; cat(p$region[i], ":", if (length(f)) paste(f, p[i, f], collapse = "; ") else "none", "\n") }
}
